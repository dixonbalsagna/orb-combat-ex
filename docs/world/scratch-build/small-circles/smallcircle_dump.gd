extends SceneTree
# World, paper prototype: a small-circle arena (a loop round a centre point) on WorldPlanet's planet 7: what it holds, how often the minimum is met, strips for the pictures.
#   godot --headless --path . --script res://sim/world/tools/smallcircle_dump.gd -- <out.json>
# Uses the module's float64 functions; a small circle is the set of points at angular distance theta from a centre c: p(a) = cos(theta) c + sin(theta) (cos a u + sin a v).
var P
var R: float
var COL: float = 32.0


func cross(a: Array, b: Array) -> Array:
	return [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]


func unit(a: Array) -> Array:
	var l: float = sqrt(a[0] * a[0] + a[1] * a[1] + a[2] * a[2])
	return [a[0] / l, a[1] / l, a[2] / l]


func dot(a: Array, b: Array) -> float:
	return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]


## The frame of a loop round c at angular radius theta from a start direction (which way a = 0 points).
func frame(c: Array, bearing: float) -> Dictionary:
	var ref: Array = [0.0, 1.0, 0.0] if absf(c[1]) < 0.9 else [1.0, 0.0, 0.0]
	var u0: Array = unit(cross(ref, c))
	var v0: Array = cross(c, u0)
	var co: float = SimDetMath.cos(bearing)
	var si: float = SimDetMath.sin(bearing)
	var u: Array = [u0[0] * co + v0[0] * si, u0[1] * co + v0[1] * si, u0[2] * co + v0[2] * si]
	var v: Array = cross(c, u)
	return {"c": c, "u": u, "v": v}


func loopPoint(f: Dictionary, theta: float, a: float) -> Array:
	var ct: float = SimDetMath.cos(theta)
	var st: float = SimDetMath.sin(theta)
	var ca: float = SimDetMath.cos(a)
	var sa: float = SimDetMath.sin(a)
	var c: Array = f.c
	var u: Array = f.u
	var v: Array = f.v
	return [ct * c[0] + st * (ca * u[0] + sa * v[0]), ct * c[1] + st * (ca * u[1] + sa * v[1]), ct * c[2] + st * (ca * u[2] + sa * v[2])]


## Reads a loop: the length L (units) fixes theta: 2 pi R sin(theta) = L. Returns what it holds.
func readLoop(c: Array, L: float, bearing: float, profile: int) -> Dictionary:
	var sinT: float = L / (2.0 * PI * R)
	var theta: float = WorldPlanet.asinf(minf(sinT, 1.0))
	var f: Dictionary = frame(c, bearing)
	var r: float = R * sinT                       # the loop's own radius, units
	var cols: int = int(round(L / COL))
	var seen := [0, 0, 0, 0, 0, 0, 0]
	var prof: Array = []
	var samples: int = 96 if profile == 0 else profile
	for k in range(samples):
		var a: float = float(k) / float(samples) * 2.0 * PI
		var p: Array = loopPoint(f, theta, a)
		WorldPlanet.surfAt(P, p[0], p[1], p[2])
		seen[P.outB] += 1
		if profile > 0:
			prof.append([snappedf(P.outH, 1.0), P.outB])
	var held: Array = []
	var cities: int = 0
	var towns: int = 0
	for i in range(P.n):
		var o: Array = [P.px[i], P.py[i], P.pz[i]]
		var delta: float = WorldPlanet.acosf(dot(o, c))
		var lat: float = R * (delta - theta)         # signed: negative is toward the centre
		var reach: float = (WorldPlanet.cfg().cityReach if P.kind[i] == 0 else WorldPlanet.cfg().townReach) * P.rad[i]
		if absf(lat) < reach:
			var along: float = WorldPlanet.atan2f(dot(o, f.v), dot(o, f.u))
			if along < 0.0:
				along += 2.0 * PI
			held.append({"id": i, "kind": int(P.kind[i]), "s": along * r, "d": lat, "half": sqrt(maxf(0.0, P.rad[i] * P.rad[i] - lat * lat)), "r": P.rad[i]})
			if P.kind[i] == 0:
				cities += 1
			else:
				towns += 1
	var kinds: int = 0
	for s in seen:
		if float(s) / float(samples) >= 0.08:
			kinds += 1
	var settled: float = 0.0
	for h in held:
		settled += 2.0 * h.half
	return {"L": L, "theta": theta, "r": r, "toCentre": R * theta, "cols": cols, "cities": cities, "towns": towns, "biomes": kinds,
		"land": 1.0 - float(seen[0] + seen[6]) / float(samples), "ice": float(seen[5] + seen[6]) / float(samples),
		"settled": settled / L, "held": held, "profile": prof, "bearing": bearing, "c": c}


func meets(e: Dictionary, L: float) -> bool:
	# the minimum scaled by length: at the full length 2 cities, 3 towns, 3 biomes, half land; a short loop asks for 1 city, 1 or 2 towns, 2 biomes
	var share: float = L / 153600.0
	var minC: int = 2 if share > 0.6 else 1
	var minT: int = maxi(1, int(round(3.0 * share)))
	var minB: int = 3 if share > 0.6 else 2
	return e.cities >= minC and e.towns >= minT and e.biomes >= minB and e.land >= 0.5


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	P = WorldPlanet.make(7)
	R = P.R
	var out := {"seed": 7, "R": R}
	var rr := SimRng.new(77)
	var stats: Array = []
	for L in [38400.0, 76800.0, 153600.0]:
		var okAll: int = 0
		var nAll: int = 0
		var okCity: int = 0
		var nCity: int = 0
		var okRand: int = 0
		var nRand: int = 0
		var cities: float = 0.0
		var towns: float = 0.0
		var settled: float = 0.0
		var firstOk: int = 0
		var ringOnCity: float = 0.0
		# loops round each place's centre
		for i in range(P.n):
			for b in range(3):
				var c: Array = [P.px[i], P.py[i], P.pz[i]]
				var e: Dictionary = readLoop(c, L, float(b) * 2.0, 0)
				nAll += 1
				nCity += 1 if P.kind[i] == 0 else 0
				if meets(e, L):
					okAll += 1
					okCity += 1 if P.kind[i] == 0 else 0
					cities += e.cities
					towns += e.towns
					settled += e.settled
		# loops round random points
		for k in range(60):
			var c2: Array = WorldPlanet.unitFromDraws(rr.next(), rr.next())
			var e2: Dictionary = readLoop(c2, L, rr.range_(0.0, 6.28), 0)
			nRand += 1
			if meets(e2, L):
				okRand += 1
				okAll += 1
				cities += e2.cities
				towns += e2.towns
				settled += e2.settled
			nAll += 1
		stats.append({"L": L, "ringsPlaces": P.n * 3, "okPlaces": okAll - okRand, "randN": nRand, "okRand": okRand, "meanCities": cities / maxf(1.0, float(okAll)), "meanTowns": towns / maxf(1.0, float(okAll)), "meanSettled": settled / maxf(1.0, float(okAll)),
			"ok": okAll, "n": nAll})
		print("L %6d: loop radius %5d, centre %5d away; minimum met by %.0f%% of loops round places (%d), %.0f%% round random points (%d); accepted hold %.1f cities, %.1f towns, %.0f%% settled" % [L, int(R * L / (2.0 * PI * R)), int(R * WorldPlanet.asinf(L / (2.0 * PI * R))), 100.0 * float(okAll - okRand) / float(P.n * 3), P.n * 3, 100.0 * float(okRand) / 60.0, 60, cities / maxf(1.0, float(okAll)), towns / maxf(1.0, float(okAll)), 100.0 * settled / maxf(1.0, float(okAll))])
	out["stats"] = stats
	# examples with full profiles: the best loop of 76,800 and of 38,400 that meets the scaled minimum (searched over loops round places and random points), and the poles at 38,400
	var ex: Array = []
	for L in [76800.0, 38400.0]:
		var bestE = null
		var bestS: float = -1.0
		var rs := SimRng.new(5 + int(L))
		for k in range(260):
			var c3: Array
			var cid: int = -1
			if k < P.n * 2:
				cid = k % P.n
				c3 = [P.px[cid], P.py[cid], P.pz[cid]]
			else:
				c3 = WorldPlanet.unitFromDraws(rs.next(), rs.next())
			var bearing: float = rs.range_(0.0, 6.28)
			var e5: Dictionary = readLoop(c3, L, bearing, 0)
			if meets(e5, L):
				var sc: float = float(e5.towns) * 2.0 + float(e5.biomes) * 1.5 + float(e5.cities) * 3.0 + e5.land
				if sc > bestS:
					bestS = sc
					bestE = [c3, bearing, cid]
		if bestE != null:
			var eb: Dictionary = readLoop(bestE[0], L, bestE[1], 600)
			eb["name"] = "best loop, %d" % int(L)
			eb["centreId"] = bestE[2]
			ex.append(eb)
	for pole in [-1.0, 1.0]:
		var ep: Dictionary = readLoop([0.0, pole, 0.0], 38400.0, 0.0, 600)
		ep["name"] = "round the %s pole, 38,400" % ("south" if pole < 0.0 else "north")
		ep["centreId"] = -1
		ex.append(ep)
	out["examples"] = ex
	var biomesAt: Array = []
	for i in range(P.n):
		WorldPlanet.surfAt(P, P.px[i], P.py[i], P.pz[i])
		biomesAt.append([int(P.outB), snappedf(P.outH, 1.0)])
	out["placeBiome"] = biomesAt
	# the grid and places for the globe
	var grid: Array = []
	for j in range(60):
		var row: Array = []
		var la: float = (-88.5 + 3.0 * float(j)) * PI / 180.0
		for i in range(120):
			var lo: float = (-178.5 + 3.0 * float(i)) * PI / 180.0
			var q: Array = [cos(la) * cos(lo), sin(la), cos(la) * sin(lo)]
			WorldPlanet.surfAt(P, q[0], q[1], q[2])
			row.append(P.outB)
		grid.append(row)
	out["grid"] = grid
	var pl: Array = []
	for i in range(P.n):
		pl.append({"kind": int(P.kind[i]), "v": [P.px[i], P.py[i], P.pz[i]], "r": P.rad[i]})
	out["places"] = pl
	var f := FileAccess.open(args[0], FileAccess.WRITE)
	f.store_string(JSON.stringify(out))
	f.close()
	print("wrote ", args[0])
	quit()
