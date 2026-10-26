extends SceneTree
# Planet generation 2, window 12: Research's B plates (WorldPlateB, data/biomes/plates-b.json) against the JS reference (b_vectors.json, made by b_vectors.mjs from research/planet-gen/gen/plates.mjs), and the ground's own properties.
#   godot --headless --path . --script res://sim/world/tools/b_check.gd
var fails: int = 0


func ok(c: bool, w: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", w])
	if not c:
		fails += 1


func _init() -> void:
	ok(WorldPlateB.dataErrors().is_empty(), "plates-b.json is clean (%s)" % str(WorldPlateB.dataErrors()))
	ok(not WorldLand.plateB(), "land.json ships with b off")
	var pm := WorldPlateB.Prm.new()
	var d = JSON.parse_string(FileAccess.get_file_as_string("res://data/biomes/plates-b.json"))
	var same: bool = true
	for k in d.params.keys():
		var cur = pm.get(k)
		if (cur is int and int(d.params[k]) != cur) or (cur is float and absf(float(d.params[k]) - cur) > 0.0):
			same = false
	ok(same, "the file's numbers are the class defaults (Research's PB)")
	# gen 1 first: the same planet reads the same with the switch on
	WorldClimate.useGen(1)
	var P1 := WorldPlanet.make(5)
	var h1a := PackedFloat64Array()
	var rng := SimRng.new(77)
	var pts1: Array = []
	for k in range(200):
		pts1.append(WorldPlanet._randUnit(rng))
	for p in pts1:
		h1a.append(WorldPlanet.ground(P1, p[0], p[1], p[2]))
	WorldLand.setB(true)
	ok(WorldLand.plateB(), "setB turns the switch on in this process")
	var g1same: bool = true
	for k in range(pts1.size()):
		if WorldPlanet.ground(P1, pts1[k][0], pts1[k][1], pts1[k][2]) != h1a[k]:
			g1same = false
	ok(g1same, "a gen 1 planet's ground is the same bit for bit with the switch on")
	WorldClimate.useGen(2)
	# the reference
	var ref = JSON.parse_string(FileAccess.get_file_as_string("res://sim/world/tools/b_vectors.json"))
	for rs in ref.seeds:
		var seed: int = int(rs.seed)
		var P := WorldPlanet.make(seed)
		var S: WorldPlateB.State = WorldPlateB.stateOf(P)
		var plateOk: bool = S.plate.size() == rs.plate.size()
		for i in range(mini(S.plate.size(), rs.plate.size())):
			if S.plate[i] != int(rs.plate[i]):
				plateOk = false
		var cdiff: float = maxf(absf(S.cf[0] - float(rs.c0[0])), maxf(absf(S.cf[1] - float(rs.c0[1])), absf(S.cf[2] - float(rs.c0[2]))))
		ok(plateOk and absf(S.lift - float(rs.lift)) < 1.0e-12 and cdiff < 1.0e-12 and absf(S.hot[0] - float(rs.hot0[0])) < 1.0e-12, "seed %d: the plates (cells' plates, crust lift %.6f, first centre, first hotspot) are Research's" % [seed, S.lift])
		var maxh: float = 0.0
		var maxv: float = 0.0
		var exact: int = 0
		var n: int = 0
		var land: int = 0
		for pt in rs.pts:
			var u: Array = WorldPlateB._randUnit(seed, 9999, int(pt[0]))
			var h: float = WorldPlateB.ground(P, u[0], u[1], u[2])
			var hd: float = absf(h - float(pt[1]))
			maxh = maxf(maxh, hd)
			maxv = maxf(maxv, absf(S.volc - float(pt[2])))
			if hd == 0.0:
				exact += 1
			if h > 0.0:
				land += 1
			n += 1
		ok(n == rs.pts.size() and maxh < 1.0e-6 and maxv < 1.0e-9, "seed %d: %d points of the ground agree with the JS (largest height difference %s, volcanic %s, %d exactly equal, %d percent land)" % [seed, n, String.num_scientific(maxh), String.num_scientific(maxv), exact, 100 * land / maxi(1, n)])
	# determinism and the planet's own use
	var Pa := WorldPlanet.make(3)
	var u0: Array = WorldPlateB._randUnit(3, 9999, 0)
	var ha: float = WorldPlanet.ground(Pa, u0[0], u0[1], u0[2])
	var Pc := WorldPlanet.Planet.new()
	Pc.seed = 3
	Pc.gen = 2
	Pc.R = Pa.R
	Pc.c = Pa.c
	ok(WorldPlanet.ground(Pc, u0[0], u0[1], u0[2]) == ha, "a fresh planet object of the same seed reads the same (a pure function of the seed)")
	# the ring: a planet's slice is read column by column; no step in the ground along it and its cost
	var worst: float = 0.0
	var wi: int = -1
	var t0: int = Time.get_ticks_usec()
	for sd in [3, 7, 11]:
		var Pq := WorldPlanet.make(sd)
		for lat in [-0.9, -0.5, -0.2, 0.0, 0.3, 0.6]:
			var y: float = SimDetMath.sin(lat)
			var c: float = SimDetMath.cos(lat)
			var prev: float = 0.0
			for i in range(0, 4800):
				var lon: float = float(i) / 4800.0 * SimMathx.TAU
				var h: float = WorldPlanet.ground(Pq, c * SimDetMath.cos(lon), y, c * SimDetMath.sin(lon))
				if i > 0 and absf(h - prev) > worst:
					worst = absf(h - prev)
					wi = i
				prev = h
	var per: float = float(Time.get_ticks_usec() - t0) / (3.0 * 6.0 * 4800.0)
	ok(worst < 900.0, "along 18 rings (3 seeds, 6 latitudes) the largest step between neighbouring columns is %.0f units (column %d); a ground read costs %.0f us" % [worst, wi, per])
	print("B: %d check(s) failed" % fails)
	quit()
