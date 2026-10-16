extends SceneTree
# World, paper-only prototype: generate a planet, pick slices the constructive way, count what they hold, dump JSON for the diagrams.
#   godot --headless --path . --script res://sim/world/tools/planet_dump.gd -- <out.json> [seed]
const Lib = preload("res://sim/world/tools/planet2_lib.gd")
var P
var places: Array = []   # {kind, v: Vector3, r}
var NC: int = 8
var NT: int = 28
var RC: float = 8000.0
var RT: float = 3000.0


func try_place(r: SimRng, sp: Array, ypolar: bool) -> bool:
	var best = null
	var bs: float = -1.0e9
	for c in range(int(sp[3])):
		var p: Vector3 = P.randunit(r)
		var h: float = P.ground(p)
		if h < 60.0 or h > 1800.0 or (ypolar and absf(p.y) > 0.80):
			continue
		var dmin: float = 1.0e9
		for o in places:
			dmin = minf(dmin, P.arc(p, o.v) - o.r - float(sp[2]))
		if dmin < 400.0:
			continue
		var sc: float = dmin * 0.001 - absf(h - 300.0) * 0.002 + r.next()
		if sc > bs:
			bs = sc
			best = p
	if best != null:
		places.append({"kind": sp[0], "v": best, "r": sp[2]})
		return true
	return false


## Picture A's places exactly (the same stream and rule on the ordinary ground), then the ones that fell in a polar cap are placed again outside it from a second stream.
func place_all() -> void:
	var r := SimRng.new(P.seed * 31 + 1)
	var spec := [["city", NC, RC, 80], ["town", NT, RT, 40]]
	for sp in spec:
		for k in range(int(sp[1])):
			try_place(r, sp, false)
	var kept: Array = []
	var dropped := {"city": 0, "town": 0}
	for o in places:
		if absf(o.v.y) > 0.80:
			dropped[o.kind] += 1
		else:
			kept.append(o)
	places = kept
	var r2 := SimRng.new(P.seed * 31 + 2)
	for sp in spec:
		for k in range(int(dropped[sp[0]])):
			var sp2: Array = [sp[0], sp[1], sp[2], 800]   # more candidates: the caps and the old cities leave little room
			try_place(r2, sp2, true)
	print("places of picture A that fell inside a polar cap and were placed again: %d cities, %d towns" % [dropped["city"], dropped["town"]])


## What the great circle with normal nn, starting at q (a point on it), holds. Returns a dictionary.
func read_slice(nn: Vector3, q: Vector3, samples: int, with_profile: bool) -> Dictionary:
	var u: Vector3 = (q - nn * q.dot(nn)).normalized()
	var v: Vector3 = nn.cross(u).normalized()
	var held: Array = []
	var cities: int = 0
	var towns: int = 0
	var settled: float = 0.0
	for i in range(places.size()):
		var o = places[i]
		var d: float = P.R * asin(clampf(nn.dot(o.v), -1.0, 1.0))
		var reach: float = 0.6 * o.r if o.kind == "city" else 0.7 * o.r
		if absf(d) < reach:
			var s: float = P.R * atan2(o.v.dot(v), o.v.dot(u))
			if s < 0.0:
				s += P.L
			var half: float = sqrt(maxf(0.0, o.r * o.r - d * d))
			held.append({"i": i, "kind": o.kind, "s": s, "d": d, "half": half})
			settled += 2.0 * half
			if o.kind == "city":
				cities += 1
			else:
				towns += 1
	var seen := [0, 0, 0, 0, 0, 0, 0]
	var prof: Array = []
	var cnt: int = samples
	for k in range(cnt):
		var p: Vector3 = P.rot(u, v, float(k) / float(cnt) * 2.0 * PI)
		var h: float = P.elev(p)
		var b: int = P.biome(p, h)
		seen[b] += 1
		if with_profile:
			prof.append([snappedf(h, 1.0), b])
	var kinds: int = 0
	for s in seen:
		if float(s) / float(cnt) >= 0.08:
			kinds += 1
	return {"cities": cities, "towns": towns, "biomes": kinds, "land": 1.0 - float(seen[0] + seen[6]) / float(cnt), "ice": float(seen[5] + seen[6]) / float(cnt), "sheet": float(seen[5]) / float(cnt), "seaice": float(seen[6]) / float(cnt), "settled": settled / P.L, "held": held, "profile": prof, "seen": seen}


func meets(r: Dictionary) -> bool:
	return r.cities >= 2 and r.towns >= 3 and r.biomes >= 3 and r.land >= 0.5


## A touch-down point: the candidates are the great circles through it and each city, and a few of random bearing. The first that meets the minimum, in a seeded order.
func pick(touch: Vector3, rr: SimRng, quick: int) -> Dictionary:
	var cand: Array = []
	for o in places:
		if o.kind == "city":
			var nn: Vector3 = touch.cross(o.v)
			if nn.length() > 0.15:
				cand.append(nn.normalized())
	for k in range(4):
		var t: Vector3 = P.randunit(rr)
		var nn2: Vector3 = touch.cross(t)
		if nn2.length() > 0.3:
			cand.append(nn2.normalized())
	# a seeded shuffle
	for i in range(cand.size() - 1, 0, -1):
		var j: int = int(rr.next() * float(i + 1))
		var tmp = cand[i]
		cand[i] = cand[j]
		cand[j] = tmp
	var tried: int = 0
	for nn3 in cand:
		tried += 1
		var res: Dictionary = read_slice(nn3, touch, quick, false)
		if meets(res):
			res["tried"] = tried
			res["n"] = nn3
			return res
	return {"tried": tried, "n": Vector3.ZERO, "cities": 0}


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var out_path: String = args[0] if args.size() > 0 else "planet.json"
	P = Lib.new()
	if args.size() > 1:
		P.seed = int(args[1])
	if args.size() > 4:
		NC = int(args[2])
		NT = int(args[3])
		RC = float(args[4])
		RT = RC * 0.375
	var t0: int = Time.get_ticks_usec()
	place_all()
	var nc: int = 0
	for o in places:
		if o.kind == "city":
			nc += 1
	print("places: %d cities, %d towns (%.0f ms)" % [nc, places.size() - nc, float(Time.get_ticks_usec() - t0) / 1000.0])
	# the grid for the map: 5 degree cells
	var grid: Array = []
	for j in range(60):
		var row: Array = []
		var la: float = (-88.5 + 3.0 * float(j)) * PI / 180.0
		for i in range(120):
			var lo: float = (-178.5 + 3.0 * float(i)) * PI / 180.0
			var p := Vector3(cos(la) * cos(lo), sin(la), cos(la) * sin(lo))
			row.append(P.biome(p, P.elev(p)))
		grid.append(row)
	# slices from random touch-downs
	var rr := SimRng.new(2026)
	var N: int = 300
	var okq: int = 0
	var tried_sum: int = 0
	var fall: int = 0
	var acc := {"cities": 0.0, "towns": 0.0, "biomes": 0.0, "land": 0.0, "settled": 0.0}
	var t1: int = Time.get_ticks_usec()
	var good: Array = []
	for t in range(N):
		var touch: Vector3 = P.randunit(rr)
		var h: float = P.elev(touch)
		if h < 0.0:
			t -= 0   # an ocean touch-down is allowed here; the note asks whether it should be
		var res: Dictionary = pick(touch, rr, 96)
		tried_sum += int(res.tried)
		if res.cities >= 2:
			okq += 1
			for k in acc:
				acc[k] += float(res[k])
			if good.size() < 6:
				good.append({"touch": [touch.x, touch.y, touch.z], "n": [res.n.x, res.n.y, res.n.z], "cities": res.cities, "towns": res.towns})
		else:
			fall += 1
	var t2: int = Time.get_ticks_usec()
	print("touch-downs %d: a slice meeting the minimum found for %.0f%% (candidates tried a touch-down: %.1f); accepted arenas hold %.1f cities, %.1f towns, %.1f biomes, land %.0f%%, settled %.0f%% of the length" % [N, 100.0 * float(okq) / float(N), float(tried_sum) / float(N), acc.cities / okq, acc.towns / okq, acc.biomes / okq, 100.0 * acc.land / okq, 100.0 * acc.settled / okq])
	print("pick cost: %.1f ms a touch-down" % (float(t2 - t1) / 1000.0 / float(N)))
	# the polar discs: 60 rings of 0.75 degrees from the pole out to 45 degrees, 240 sectors
	var polar := {}
	for pole in [1.0, -1.0]:
		var rings: Array = []
		for ri in range(60):
			var col: float = (0.375 + 0.75 * float(ri)) * PI / 180.0
			var row2: Array = []
			for ai in range(240):
				var az: float = (float(ai) + 0.5) / 240.0 * 2.0 * PI
				var p := Vector3(sin(col) * cos(az), pole * cos(col), sin(col) * sin(az))
				row2.append(P.biome(p, P.elev(p)))
			rings.append(row2)
		polar["n" if pole > 0 else "s"] = rings
	# statistics: how often ice is on the slice, and what it does to the minimum
	var rr3 := SimRng.new(4242)
	var cnt_all: int = 0
	var cnt_ok: int = 0
	var cnt_ice: int = 0
	var cnt_ice_ok: int = 0
	var cnt_noice: int = 0
	var cnt_noice_ok: int = 0
	var ice_len := 0.0
	var mer_ok: int = 0
	var mer_n: int = 0
	var mer_relaxed: int = 0
	var mer_cities := 0.0
	var mer_ice := 0.0
	var poles := Vector3(0, 1, 0)
	for t in range(240):
		var touch3: Vector3 = P.randunit(rr3)
		# an ordinary random circle through the point (no preference): does it cross ice, does it meet the minimum
		var tt: Vector3 = P.randunit(rr3)
		var nn3: Vector3 = touch3.cross(tt)
		if nn3.length() < 0.3:
			continue
		nn3 = nn3.normalized()
		var rs: Dictionary = read_slice(nn3, touch3, 96, false)
		cnt_all += 1
		var has_ice: bool = rs.ice >= 0.08
		if has_ice:
			cnt_ice += 1
			ice_len += rs.ice
		else:
			cnt_noice += 1
		if meets(rs):
			cnt_ok += 1
			if has_ice:
				cnt_ice_ok += 1
			else:
				cnt_noice_ok += 1
		# the circle through the point and both poles
		var nm: Vector3 = touch3.cross(poles)
		if nm.length() > 0.2:
			var rm: Dictionary = read_slice(nm.normalized(), touch3, 96, false)
			mer_n += 1
			mer_cities += rm.cities
			mer_ice += rm.ice
			if meets(rm):
				mer_ok += 1
			if rm.cities >= 1 and rm.towns >= 2 and rm.biomes >= 3 and rm.land >= 0.4:
				mer_relaxed += 1
	print("random circles: %d; %.0f%% carry ice on at least 8%% of their length (mean ice share of those %.0f%%); the minimum is met by %.0f%% of ice circles and %.0f%% of the others" % [cnt_all, 100.0 * cnt_ice / cnt_all, 100.0 * ice_len / maxf(1.0, cnt_ice), 100.0 * cnt_ice_ok / maxf(1.0, cnt_ice), 100.0 * cnt_noice_ok / maxf(1.0, cnt_noice)])
	print("through both poles: the minimum is met by %.1f%%, a relaxed one (1 city, 2 towns, 3 biomes, 40%% land) by %.0f%% (mean %.1f cities, ice %.0f%% of the length)" % [100.0 * mer_ok / mer_n, 100.0 * mer_relaxed / mer_n, mer_cities / mer_n, 100.0 * mer_ice / mer_n])
	# the picker over touch-downs: success rate, and with the polar share
	var rp = SimRng.new(2026)
	var NP: int = 300
	var okp: int = 0
	var acc_ice: float = 0.0
	var acc_n: int = 0
	var trp: int = 0
	var ice_pick: int = 0
	var cities_acc: float = 0.0
	var cities_ice: float = 0.0
	var best_ex := {}
	for t in range(NP):
		var touch: Vector3 = P.randunit(rp)
		var res: Dictionary = pick(touch, rp, 96)
		trp += int(res.tried)
		if res.cities >= 2:
			okp += 1
			var full0: Dictionary = read_slice(res.n, touch, 96, false)
			acc_ice += full0.ice
			cities_acc += res.cities
			if full0.ice >= 0.08:
				ice_pick += 1
				cities_ice += res.cities
				if not best_ex.has("clip") and absf(res.n.y) > 0.15 and absf(res.n.y) < 0.45 and P.elev(touch) > 0.0:
					best_ex["clip"] = [touch, res.n]
	print("picker: %d touch-downs, minimum met for %.0f%%; accepted arenas carry ice on average %.0f%% of their length, %.0f%% of arenas have at least 8%% ice (they hold %.1f cities, the rest %.1f)" % [NP, 100.0 * okp / NP, 100.0 * acc_ice / okp, 100.0 * ice_pick / okp, cities_ice / maxf(1.0, ice_pick), (cities_acc - cities_ice) / maxf(1.0, okp - ice_pick)])
	# the three example slices
	var ex: Array = []
	var rr2 := SimRng.new(5)
	# 1. a temperate slice
	var tries: int = 0
	while tries < 80:
		tries += 1
		var tch: Vector3 = P.randunit(rr2)
		if P.elev(tch) < 100.0 or absf(tch.y) > 0.5:
			continue
		var r1: Dictionary = pick(tch, rr2, 96)
		if r1.cities >= 2:
			var f1: Dictionary = read_slice(r1.n, tch, 600, true)
			if f1.ice < 0.02:
				f1["touch"] = [tch.x, tch.y, tch.z]
				f1["n"] = [r1.n.x, r1.n.y, r1.n.z]
				f1["name"] = "temperate"
				ex.append(f1)
				break
	# 2. through both poles: the circle through a land touch-down and the poles with the most places on it, both ice kinds present
	var best_m = null
	var best_sc: float = -1.0
	tries = 0
	while tries < 300:
		tries += 1
		var tch2: Vector3 = P.randunit(rr2)
		if P.elev(tch2) < 100.0 or absf(tch2.y) > 0.6:
			continue
		var nm2: Vector3 = tch2.cross(poles)
		if nm2.length() < 0.3:
			continue
		nm2 = nm2.normalized()
		var f2: Dictionary = read_slice(nm2, tch2, 96, false)
		if f2.sheet > 0.05 and f2.seaice > 0.05:
			var sc2: float = float(f2.cities) * 2.0 + float(f2.towns) + f2.land
			if sc2 > best_sc:
				best_sc = sc2
				best_m = [tch2, nm2]
	if best_m != null:
		var tch2b: Vector3 = best_m[0]
		var nm2b: Vector3 = best_m[1]
		var f2b: Dictionary = read_slice(nm2b, tch2b, 600, true)
		f2b["touch"] = [tch2b.x, tch2b.y, tch2b.z]
		f2b["n"] = [nm2b.x, nm2b.y, nm2b.z]
		f2b["name"] = "meridian"
		var u2: Vector3 = (tch2b - nm2b * tch2b.dot(nm2b)).normalized()
		var v2: Vector3 = nm2b.cross(u2).normalized()
		for pn in [["zoomN", 1.0], ["zoomS", -1.0]]:
			var Y := Vector3(0, pn[1], 0)
			var a0: float = atan2(Y.dot(v2), Y.dot(u2))
			var zz: Array = []
			for k in range(1000):
				var s_: float = (float(k) / 999.0 * 2.0 - 1.0) * 24000.0
				var pz: Vector3 = P.rot(u2, v2, a0 + s_ / P.R)
				var sf: Array = P.surf(pz)
				zz.append([snappedf(sf[0], 1.0), P.biome(pz, sf[0])])
			f2b[pn[0]] = zz
			f2b[pn[0] + "_a"] = a0
			var wins: Array = []
			for off in ([3000.0, 8000.0, 12500.0] if pn[1] > 0 else [3000.0, 8500.0, 10500.0, 12500.0]):
				var wz: Array = []
				for k in range(1000):
					var s2: float = off + (float(k) - 500.0) * 3.0
					var pz2: Vector3 = P.rot(u2, v2, a0 + s2 / P.R)
					var sf2: Array = P.surf(pz2)
					wz.append([snappedf(sf2[0], 1.0), P.biome(pz2, sf2[0])])
				wins.append({"off": off, "p": wz})
			f2b[pn[0] + "_win"] = wins
		ex.append(f2b)
	# 3. a circle that clips a cap
	if best_ex.has("clip"):
		var tc: Vector3 = best_ex["clip"][0]
		var ncl: Vector3 = best_ex["clip"][1]
		var f3: Dictionary = read_slice(ncl, tc, 600, true)
		f3["touch"] = [tc.x, tc.y, tc.z]
		f3["n"] = [ncl.x, ncl.y, ncl.z]
		f3["name"] = "clip"
		ex.append(f3)
	var pl: Array = []
	for o in places:
		pl.append({"kind": o.kind, "v": [o.v.x, o.v.y, o.v.z], "r": o.r})
	var js := JSON.stringify({"seed": P.seed, "R": P.R, "L": P.L, "grid": grid, "polar": polar, "places": pl, "slices": ex, "stats": {"N": N, "ok": okq, "ice_pick": ice_pick, "circles": cnt_all, "ice_circles": cnt_ice, "mer_ok": mer_ok, "mer_n": mer_n, "mer_relaxed": mer_relaxed}})
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	f.store_string(js)
	f.close()
	print("wrote %s (%d bytes, %d example slices)" % [out_path, js.length(), ex.size()])
	quit()
