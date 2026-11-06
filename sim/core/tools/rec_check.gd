extends SceneTree
## World's records by a coarser grid for the big ones, and the place table's coarse pass (sim/world/waterrec.gd, sim/director/swing.gd): godot --headless --path . --script res://sim/core/tools/rec_check.gd
## Neither may change an answer. At points on and off the line, on five planets, with buildings at every place and without: the ground with the records, the water on them, and the set of records
## in reach, against every big record scanned as before the coarse grid (water-read); and the place table against the plain walk. --negative-control drops the big records from the read, and the comparison must see it.

var fails: int = 0


func ok(c: bool, what: String) -> void:
	if not c:
		fails += 1
		print("FAIL  " + what)


func _plainPlaces(S: SimState, P) -> PackedByteArray:
	var out := PackedByteArray()
	out.resize(P.n)
	var least: float = SimDetMath.cos(float(DirSwing.cfg().buildings.placeNear) / SimField.R)
	for i in range(P.n):
		for b in range(S.bDir.size() / 3):
			if P.px[i] * S.bDir[b * 3] + P.py[i] * S.bDir[b * 3 + 1] + P.pz[i] * S.bDir[b * 3 + 2] >= least:
				out[i] = 1
				break
	return out


func _one(planet: int, touch: int, everywhere: int, negative: bool) -> int:
	WorldPlan.everywhereOverride = everywhere
	WorldPlanet.forget()
	WorldField.bakeStep(WorldField.of(WorldPlanet.make(planet)), 1 << 40)
	var S := SimCore.createSim()
	SimCore.newMatch(S, 77, {"p1": false, "p2": false}, {"intro": false, "planet": planet, "touch": touch, "planetGen": 3})
	var bad: int = 0
	var n: int = 0
	var sumNear: int = 0
	var sumAll: int = 0
	var rng := SimRng.new(planet * 7919 + everywhere)
	var pts: Array = []
	for k in range(600):
		SimField.pointAt(S, float(k * 8) * SimConst.COL)
		pts.append([SimField.ox, SimField.oy, SimField.oz])
	for rec in S.fieldRecs:   # ... and just inside and outside each big record's reach
		var reach: float = float(rec.get("r", 0.0)) + maxf(float(rec.get("blend", 0.0)), float(rec.get("bs", 0.0)))
		if float(rec.get("r", 0.0)) + float(rec.get("blend", 0.0)) <= WorldWaterRec.BIG:
			continue
		var c: Array = rec.get("c", [rec.get("px", 0.0), rec.get("py", 0.0), rec.get("pz", 0.0)])
		for u in [0.0, 0.5, 0.98, 1.02]:
			var a: float = rng.next() * SimMathx.PI * 2.0
			var ex: Array = [SimDetMath.cos(a), SimDetMath.sin(a), 0.3]
			var d: float = reach * u / SimField.R
			var q: Array = [float(c[0]) + ex[0] * d, float(c[1]) + ex[1] * d, float(c[2]) + ex[2] * d]
			var l: float = sqrt(q[0] * q[0] + q[1] * q[1] + q[2] * q[2])
			pts.append([q[0] / l, q[1] / l, q[2] / l])
	for q in pts:
		for h in [-200.0, 100.0, 600.0, 3000.0, WorldTerrain.TRIM_G + 1.0, WorldTerrain.SETTLE_FLOOR - 1.0]:
			WorldWaterRec.scanBig = false
			if negative:
				S.fieldRecs.size()
			var g1: float = WorldField.applyRecords(S, q[0], q[1], q[2], h)
			var w1: float = WorldField.recordWater(S, q[0], q[1], q[2], h)
			WorldWaterRec.scanBig = true
			var g0: float = WorldField.applyRecords(S, q[0], q[1], q[2], h)
			var w0: float = WorldField.recordWater(S, q[0], q[1], q[2], h)
			WorldWaterRec.scanBig = false
			n += 1
			if g0 != g1 or w0 != w1:
				bad += 1
		sumNear += WorldWaterRec.near(S, q[0], q[1], q[2]).size()
		WorldWaterRec.scanBig = true
		sumAll += WorldWaterRec.near(S, q[0], q[1], q[2]).size()
		WorldWaterRec.scanBig = false
	var P = DirSwing._planet(S)
	var built: PackedByteArray = DirSwing._builtPlaces(S, P)
	var plain: PackedByteArray = _plainPlaces(S, P)
	var count: int = 0
	for i in range(P.n):
		count += plain[i]
	print("planet %d, everywhere %d: %d reads, %d differ; %.1f records a point, %.1f before; %d of %d places built, %s" % [planet, everywhere, n, bad, float(sumNear) / float(pts.size()), float(sumAll) / float(pts.size()), count, P.n, "same" if built == plain else "DIFFERENT"])
	ok(bad == 0, "planet %d, everywhere %d: the same ground and water at every point (%d differ)" % [planet, everywhere, bad])
	ok(built == plain, "planet %d, everywhere %d: the same places" % [planet, everywhere])
	ok(n > 0, "there were reads")
	SimCore.dispose(S)
	return bad


func _init() -> void:
	WorldClimate.useGen(3)
	var neg: bool = false
	for a in OS.get_cmdline_user_args():
		if a == "--negative-control":
			neg = true
	if neg:
		# the break: an empty coarse grid. A big record is then missing from the read
		var S := SimCore.createSim()
		WorldPlan.everywhereOverride = 1
		SimCore.newMatch(S, 77, {"p1": false, "p2": false}, {"intro": false, "planet": 7, "touch": 3, "planetGen": 3})
		WorldWaterRec.near(S, 1.0, 0.0, 0.0)
		var ent: Dictionary = WorldWaterRec._index(S)
		ent.bgrid.clear()   # World's coarse grid ...
		ent.merged.clear()  # ... and the lists made from it
		var seen: int = 0
		for rec in S.fieldRecs:
			if String(rec.k) == "platform":
				var q: Array = [float(rec.px), float(rec.py), float(rec.pz)]
				var h: float = WorldTerrain.TRIM_G + 1.0   # under the floor, where a platform lifts the ground
				var g1: float = WorldField.applyRecords(S, q[0], q[1], q[2], h)
				WorldWaterRec.scanBig = true
				var g0: float = WorldField.applyRecords(S, q[0], q[1], q[2], h)
				WorldWaterRec.scanBig = false
				if g0 != g1:
					seen += 1
		print("negative: the coarse grid emptied, %d platforms read differently" % seen)
		ok(seen > 0, "the comparison sees a big record gone")
		SimCore.dispose(S)
		WorldPlan.everywhereOverride = -1
		print("REC negative control: %d check(s) failed" % fails)
		quit(1 if fails > 0 else 0)
		return
	for row in [[7, 3], [12, 3], [3, 2], [11, 3], [25, 4]]:
		_one(row[0], row[1], 1, false)
		_one(row[0], row[1], 0, false)
	WorldPlan.everywhereOverride = -1
	print("REC: %d check(s) failed" % fails)
	quit(1 if fails > 0 else 0)
