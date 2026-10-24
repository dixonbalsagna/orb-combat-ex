extends SceneTree
# Planet generation 2, window 3: the landforms (WorldLand, data/biomes/land.json): plates, ranges where they close, rifts where they part, a moved shoreline, plateaus and canyons.
#   godot --headless --path . --script res://sim/world/tools/land_check.gd
var fails: int = 0


func ok(c: bool, w: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", w])
	if not c:
		fails += 1


func unit_from(rng: SimRng) -> Array:
	return WorldPlanet._randUnit(rng)


func _init() -> void:
	ok(WorldLand.dataErrors().is_empty() and int(WorldClimate.data().gen) == 1, "land.json is clean and the data's generation is still 1 (%s)" % str(WorldLand.dataErrors()))
	WorldClimate.useGen(1)
	var P1 := WorldPlanet.make(7)
	WorldClimate.useGen(2)
	var P2 := WorldPlanet.make(7)
	var P2b := WorldPlanet.make(7)
	ok(P1.gen == 1 and P2.gen == 2 and P2 == P2b and P1 != P2, "a planet is made by its generation (memoised apart)")
	# --- the plates
	var pl: WorldLand.Plates = WorldLand.platesOf(P2)
	var unitOk: bool = pl.n == int(WorldLand.data().plates.n)
	var tanOk: bool = true
	var minSep: float = 9.0
	var vmin: float = 9.0
	var vmax: float = 0.0
	for i in range(pl.n):
		if absf(pl.cx[i] * pl.cx[i] + pl.cy[i] * pl.cy[i] + pl.cz[i] * pl.cz[i] - 1.0) > 1.0e-9:
			unitOk = false
		var dv: float = pl.vx[i] * pl.cx[i] + pl.vy[i] * pl.cy[i] + pl.vz[i] * pl.cz[i]
		if absf(dv) > 1.0e-9:
			tanOk = false
		var sp: float = sqrt(pl.vx[i] * pl.vx[i] + pl.vy[i] * pl.vy[i] + pl.vz[i] * pl.vz[i])
		vmin = minf(vmin, sp)
		vmax = maxf(vmax, sp)
		for j in range(i):
			minSep = minf(minSep, 1.0 - (pl.cx[i] * pl.cx[j] + pl.cy[i] * pl.cy[j] + pl.cz[i] * pl.cz[j]))
	ok(unitOk and tanOk and vmin >= float(WorldLand.data().plates.speedMin) - 1.0e-9 and vmax <= 1.0 + 1.0e-9 and minSep > 0.05, "%d plates: unit centres, drifts along the ground at %.2f to %.2f, the closest pair %.2f apart (1 - dot)" % [pl.n, vmin, vmax, minSep])
	var Pn := WorldPlanet.Planet.new()
	Pn.seed = 7
	var pl2: WorldLand.Plates = WorldLand.platesOf(Pn)
	var same: bool = pl2.n == pl.n
	for i in range(pl.n):
		if pl2.cx[i] != pl.cx[i] or pl2.vz[i] != pl.vz[i]:
			same = false
	var Po := WorldPlanet.make(11)
	ok(same and WorldLand.platesOf(Po).cx[0] != pl.cx[0], "the plates are a pure function of the seed (a fresh planet object makes the same, another seed other plates)")
	# --- sampling
	var rng := SimRng.new(4242)
	var N: int = 6000
	var pts: Array = []
	for k in range(N):
		pts.append(unit_from(rng))
	var h1 := PackedFloat64Array()
	var h2 := PackedFloat64Array()
	var b1 := PackedByteArray()
	var b2 := PackedByteArray()
	h1.resize(N)
	h2.resize(N)
	b1.resize(N)
	b2.resize(N)
	WorldClimate.useGen(1)
	var t0: int = Time.get_ticks_usec()
	for k in range(N):
		WorldPlanet.surfAt(P1, pts[k][0], pts[k][1], pts[k][2])
		h1[k] = P1.outH
		b1[k] = P1.outB
	var us1: float = float(Time.get_ticks_usec() - t0) / float(N)
	WorldClimate.useGen(2)
	t0 = Time.get_ticks_usec()
	WorldClimate.gridOf(P2)   # the climate grid and the plates are made once a planet: timed apart from the points
	WorldLand.platesOf(P2)
	var setupMs: float = float(Time.get_ticks_usec() - t0) / 1000.0
	t0 = Time.get_ticks_usec()
	for k in range(N):
		WorldPlanet.surfAt(P2, pts[k][0], pts[k][1], pts[k][2])
		h2[k] = P2.outH
		b2[k] = P2.outB
	var us2: float = float(Time.get_ticks_usec() - t0) / float(N)
	var again: bool = true
	var Pf := WorldPlanet.Planet.new()
	Pf.seed = 7
	Pf.gen = 2
	Pf.c = P2.c
	Pf.R = P2.R
	Pf.L = P2.L
	for k in range(0, N, 60):
		WorldPlanet.surfAt(Pf, pts[k][0], pts[k][1], pts[k][2])
		if Pf.outH != h2[k] or Pf.outB != b2[k]:
			again = false
	ok(again, "gen 2 height and biome are a pure function of the point (a fresh planet object reads the same)")
	var l1: int = 0
	var l2: int = 0
	var diff: int = 0
	for k in range(N):
		if h1[k] > 0.0:
			l1 += 1
		if h2[k] > 0.0:
			l2 += 1
		if (h1[k] > 0.0) != (h2[k] > 0.0):
			diff += 1
	var lf1: float = float(l1) / float(N)
	var lf2: float = float(l2) / float(N)
	ok(absf(lf2 - lf1) < 0.22 and lf2 > 0.35 and lf2 < 0.85, "land share %.0f%% in gen 1, %.0f%% in gen 2 (window 1's smaller polar caps alone add about 12); %.0f%% of points change between land and sea" % [lf1 * 100.0, lf2 * 100.0, 100.0 * float(diff) / float(N)])
	# --- ranges where plates close: higher than gen 1 there; rifts where they part: lower on land
	var rs: float = 0.0
	var rn: int = 0
	var fs: float = 0.0
	var fn: int = 0
	var rng2 := SimRng.new(777)
	for k in range(30000):
		var p: Array = unit_from(rng2)
		if absf(p[1]) > 0.7:
			continue
		WorldClimate.useGen(2)
		WorldLand._edge(P2, p[0], p[1], p[2])
		var ee: float = WorldLand._eEdge
		var cv: float = WorldLand._eConv
		if absf(ee) > 0.02:
			continue
		WorldClimate.useGen(1)
		WorldPlanet.surfAt(P1, p[0], p[1], p[2])
		var g1: float = P1.outH
		WorldClimate.useGen(2)
		WorldPlanet.surfAt(P2, p[0], p[1], p[2])
		var g2: float = P2.outH
		if cv > 0.3:
			rs += g2 - g1
			rn += 1
		elif cv < -0.3 and g1 > 0.0:
			fs += g2 - g1
			fn += 1
	ok(rn > 40 and rs / float(maxi(rn, 1)) > 700.0, "where plates close, on their edge, the ground stands %.0f units above gen 1's on average (%d points)" % [rs / float(maxi(rn, 1)), rn])
	ok(fn > 20 and fs / float(maxi(fn, 1)) < -150.0, "where plates part on land the ground stands %.0f units below gen 1's (a rift valley; %d points)" % [fs / float(maxi(fn, 1)), fn])
	# --- no jump across a plate edge, and slopes stay in range
	var jump: float = 0.0
	var jumps: int = 0
	var maxSlope2: float = 0.0
	var sl2 := PackedFloat64Array()
	var sl1 := PackedFloat64Array()
	var above0: float = float(WorldLand.data().plateaus.above)
	var hiP1: int = 0
	var hiP2: int = 0
	var flatP1: int = 0
	var flatP2: int = 0
	var rng3 := SimRng.new(31337)
	WorldClimate.useGen(2)
	for k in range(12000):
		var p: Array = unit_from(rng3)
		if absf(p[1]) > 0.7:
			continue
		var q: Array = unit_from(rng3)
		var dp: float = p[0] * q[0] + p[1] * q[1] + p[2] * q[2]
		var tx: float = q[0] - dp * p[0]
		var ty: float = q[1] - dp * p[1]
		var tz: float = q[2] - dp * p[2]
		var tl: float = sqrt(tx * tx + ty * ty + tz * tz)
		var a: float = 32.0 / P2.R   # one column of arc
		var cs: float = 1.0 - 0.5 * a * a
		var p2: Array = [p[0] * cs + tx / tl * a, p[1] * cs + ty / tl * a, p[2] * cs + tz / tl * a]
		var pn: float = sqrt(p2[0] * p2[0] + p2[1] * p2[1] + p2[2] * p2[2])
		p2 = [p2[0] / pn, p2[1] / pn, p2[2] / pn]
		WorldPlanet.surfAt(P2, p[0], p[1], p[2])
		var ha: float = P2.outH
		WorldPlanet.surfAt(P2, p2[0], p2[1], p2[2])
		var hb: float = P2.outH
		WorldClimate.useGen(1)
		WorldPlanet.surfAt(P1, p[0], p[1], p[2])
		var g1a: float = P1.outH
		WorldPlanet.surfAt(P1, p2[0], p2[1], p2[2])
		var g1b: float = P1.outH
		WorldClimate.useGen(2)
		sl1.append(absf(g1b - g1a) / 32.0)
		var s2: float = absf(hb - ha) / 32.0
		if ha > above0:
			hiP2 += 1
			if s2 < 0.03:
				flatP2 += 1
		if g1a > above0:
			hiP1 += 1
			if absf(g1b - g1a) / 32.0 < 0.03:
				flatP1 += 1
		sl2.append(s2)
		maxSlope2 = maxf(maxSlope2, s2)
		if WorldLand.nearest(P2, p[0], p[1], p[2]) != WorldLand.nearest(P2, p2[0], p2[1], p2[2]):
			jump = maxf(jump, absf(hb - ha))
			jumps += 1
	sl2.sort()
	sl1.sort()
	var p999: float = sl2[int(float(sl2.size()) * 0.999)]
	var q999: float = sl1[int(float(sl1.size()) * 0.999)]
	print("  (adjacent-column slopes, 99th / 99.9th / steepest: gen 1 %.2f / %.2f / %.2f, gen 2 %.2f / %.2f / %.2f)" % [sl1[int(float(sl1.size()) * 0.99)], q999, sl1[sl1.size() - 1], sl2[int(float(sl2.size()) * 0.99)], p999, maxSlope2])
	ok(jumps > 3 and jump < 150.0, "across a plate edge the ground does not jump: %d adjacent columns straddle an edge, the largest step is %.0f units" % [jumps, jump])
	ok(p999 < 4.0 and maxSlope2 < 10.0, "slopes between adjacent columns: 99.9%% under %.2f, the steepest %.2f (units of height per unit along)" % [p999, maxSlope2])
	ok(WorldLand._bump(0.0, 260.0) == 1.0 and WorldLand._bump(1300.0, 260.0) == 0.0, "the shoreline term is full at sea level and zero past two and a half bands")
	# --- plateaus: more of the high ground is flat (adjacent columns within 0.03 of level) than in gen 1
	var ff1: float = float(flatP1) / float(maxi(hiP1, 1))
	var ff2: float = float(flatP2) / float(maxi(hiP2, 1))
	ok(hiP2 > 800 and ff2 > ff1 + 0.04, "plateaus: %.0f%% of adjacent high-ground columns (%d pairs) are level to 0.03 in gen 2, %.0f%% in gen 1" % [ff2 * 100.0, hiP2, ff1 * 100.0])
	# --- the polar edge is ragged: the zone's edge moves with the noise and stays within bounds, so the ground gives way to the poles along no ruled latitude
	var wmin: float = 9.0
	var wmax: float = -9.0
	var rngp := SimRng.new(2468)
	for k in range(4000):
		var p: Array = unit_from(rngp)
		var wv: float = WorldLand.polarWob(P2, p[0], p[1], p[2])
		wmin = minf(wmin, wv)
		wmax = maxf(wmax, wv)
	var po: float = float(WorldLand.data().polar.amp)
	ok(wmax - wmin > 0.6 * po and wmin >= -po - 1.0e-9 and wmax <= po + 1.0e-9 and float(P2.c.polarY) - po > 0.7, "the polar zone's edge wobbles by %.3f to %.3f in the sine of the latitude (amp %.2f): no ruled line, and it stays between %.2f and %.2f" % [wmin, wmax, po, float(P2.c.polarY) + wmin, float(P2.c.polarY) + wmax])
	# --- places and cost
	var placesOk: bool = P2.n > 20
	var c2: Dictionary = P2.c
	for i in range(P2.n):
		var gh: float = WorldPlanet.ground(P2, P2.px[i], P2.py[i], P2.pz[i])
		if gh < float(c2.placeHMin) - 1.0e-6 or gh > float(c2.placeHMax) + 1.0e-6:
			placesOk = false
	ok(placesOk, "%d places stand on ground between placeHMin and placeHMax in gen 2 (they moved with the land)" % P2.n)
	print("  (surfAt: %.1f us a point in gen 1, %.1f in gen 2: %.2fx; the gen 2 planet's one-off grid %.0f ms)" % [us1, us2, us2 / us1, setupMs])
	ok(us2 < us1 * 3.5, "a gen 2 point costs under 3.5x a gen 1 point (%.2fx; the whole of gen 2, climate included, once the grid is made)" % [us2 / us1])
	WorldClimate.useGen(0)
	print("LAND: %d check(s) failed" % fails)
	quit()
