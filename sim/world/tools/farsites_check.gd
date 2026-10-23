extends SceneTree
# The far land's two follow-ups: the match's ring in unhashed state (S.planetRing) and the settlements in the far map (WorldPlanet.farPlaces, WorldFarMap.sites):
#   godot --headless --path . --script res://sim/world/tools/farsites_check.gd
var fails: int = 0


func ok(c: bool, w: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", w])
	if not c:
		fails += 1


func ring_of(P: WorldPlanet.Planet, cols: int, a: float, b: float) -> Dictionary:
	SimConst.setArena(cols)
	var T: Array = WorldPlanet.unitFromDraws(a, b)
	var spec: Dictionary = WorldRingPick.roundSpec(T, cols, 0.9) if cols < 4800 else WorldRingPick.throughSpec(T, cols, 0.9)
	return WorldRingPick.ringFrom(spec.c, cols, spec.t)


func _init() -> void:
	# --- the places beside a ring: farColumn(ring, col, z) is where the place stands
	var worst: float = 0.0
	var listed: int = 0
	var sortedOk: bool = true
	for pl in [7, 3, 25]:
		var P := WorldPlanet.make(pl)
		for cols in [4800, 2400, 1200]:
			var ring: Dictionary = ring_of(P, cols, 0.37 + 0.05 * float(pl % 7), 0.62)
			var ps: Array = WorldPlanet.farPlaces(P, ring)
			if ps.size() != P.n:
				sortedOk = false
			var last: int = -1
			var m: Array = ring.get("c", ring.n)
			for q in ps:
				if int(q.id) <= last:
					sortedOk = false
				last = int(q.id)
				var ci: int = int(round(q.col)) % cols
				var p: Array = WorldPlanet.columnPoint(P, ring, ci)
				var d: float = m[0] * p[0] + m[1] * p[1] + m[2] * p[2]
				var t: Array = WorldPlanet._unit([m[0] - p[0] * d, m[1] - p[1] * d, m[2] - p[2] * d])
				var a: float = q.z / P.R
				var qx: float = p[0] * cos(a) + t[0] * sin(a)
				var qy: float = p[1] * cos(a) + t[1] * sin(a)
				var qz: float = p[2] * cos(a) + t[2] * sin(a)
				var dist: float = P.R * sqrt(pow(qx - q.dir[0], 2) + pow(qy - q.dir[1], 2) + pow(qz - q.dir[2], 2))
				worst = maxf(worst, dist)
				listed += 1
			var near: Array = WorldPlanet.farPlaces(P, ring, 20000.0)
			for q in near:
				if absf(q.z) > 20000.0:
					sortedOk = false
	ok(sortedOk and listed > 100 and worst < 90.0, "farPlaces lists every place of 3 planets x 3 rings (%d), by id, and farColumn's (column, z) is where each stands: the worst miss is %.1f units, from rounding the column to a whole one (a column is 32 units on the ring and fans out with the lateral offset); the lateral limit holds" % [listed, worst])
	# --- the map's settlement layer
	var P7 := WorldPlanet.make(7)
	var fm := WorldFarMap.new(P7, 128)
	var centres: bool = true
	var cityMax: int = 0
	var towns: int = 0
	var cities: int = 0
	for i in range(P7.n):
		var d: Array = [P7.px[i], P7.py[i], P7.pz[i]]
		var want: int = 2 if int(P7.kind[i]) == WorldPlanet.KIND_CITY else 1
		if fm.site(d[0], d[1], d[2]) < want:
			centres = false
		if want == 2:
			cities += 1
		else:
			towns += 1
	var marked: int = 0
	var inside: bool = true
	for k in range(fm.sites.size()):
		if fm.sites[k] == 0:
			continue
		marked += 1
		var dd: Array = WorldFarMap.decode((float(k % 128) + 0.5) / 128.0, (float(k / 128) + 0.5) / 128.0)
		var best: float = 1.0e18
		for i in range(P7.n):
			var want2: int = 2 if int(P7.kind[i]) == WorldPlanet.KIND_CITY else 1
			if want2 < int(fm.sites[k]):
				continue
			var dist2: float = P7.R * sqrt(pow(dd[0] - P7.px[i], 2) + pow(dd[1] - P7.py[i], 2) + pow(dd[2] - P7.pz[i], 2)) - P7.rad[i]
			best = minf(best, dist2)
		if best > 1.0:   # a marked texel is within some place's radius, or is the texel that holds a place's centre (a place smaller than a texel)
			var holds: bool = false
			for i in range(P7.n):
				var t: Vector2 = fm._uv(P7.px[i], P7.py[i], P7.pz[i])
				if int(floor(t.x + 0.5)) + 128 * int(floor(t.y + 0.5)) == k:
					holds = true
			if not holds:
				inside = false
	ok(centres and inside and marked > P7.n, "the settlement layer (128 square): the texel under every place's centre is marked as its kind or better (%d towns, %d cities), and every marked texel is inside a place's radius or holds a centre; %d texels marked of %d" % [towns, cities, marked, 128 * 128])
	var ring7: Dictionary = ring_of(P7, 2400, 0.37, 0.62)
	var fm2 := WorldFarMap.new(P7, 64)
	fm2.step(100000)
	var f: Dictionary = fm2.field(ring7, 100, 60, 8, PackedFloat64Array([-6000.0, 0.0, 6000.0, 20000.0]))
	ok(f.has("s") and f.s.size() == f.h.size() and fm2.places(ring7, 30000.0).size() <= P7.n, "the map's field also returns the settlement under each sample (\"s\", same layout as \"h\"), and places() is farPlaces")
	# --- the match's ring, in unhashed state
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {}, {"planet": 7, "touch": 3, "arena": {"cols": 2400}, "intro": false})
	var Se := SimCore.createSim()
	SimCore.newMatch(Se, 1, {}, {"planet": 7, "touch": 3, "arena": {"cols": 2400, "turn": true}, "intro": false})
	var same: bool = S.epoch == null and Se.epoch != null and not S.planetRing.is_empty() and S.planetRing.cols == 2400 and S.planetRing.seed == 7
	for k in range(3):
		if S.planetRing.c[k] != Se.epoch.ring.c[k] or S.planetRing.t[k] != Se.epoch.ring.t[k]:
			same = false
	ok(same, "a planet match with the turn off keeps its ring in S.planetRing, the one a turning match keeps in its epoch (the axis, the touch-down point, the columns, the seed)")
	var h0: String = str(SimHash.stateHash(S).gameplay)
	S.planetRing = {}
	ok(h0 == str(SimHash.stateHash(S).gameplay), "S.planetRing is not hashed")
	var Sg := SimCore.createSim()
	SimCore.newMatch(Sg, 1, {}, {"planet": 7, "touch": 3, "arena": {"cols": 4800}, "intro": false})
	var Sh := SimCore.createSim()
	SimCore.newMatch(Sh, 1, {}, {"intro": false})
	ok(Sg.planetRing.cols == 4800 and Sh.planetRing.is_empty(), "a Whole ring's too (a great circle, 4,800 columns); the hand-made world has none")
	# --- and it follows a turn
	var before: Array = Se.epoch.ring.c.duplicate()
	for t in range(30):
		SimCore.step(Se)
	Se.T = 100.0
	var mid: float = 0.5 * (Se.fighters[0].x + Se.fighters[1].x)
	if not WorldEpoch.ask(Se, "t", mid, 1, 0).is_empty():
		WorldEpoch.choose(Se, 3)
		Se.epoch.next.k = 100000
		var warmG: int = 0
		while WorldEpoch.warmAngles(Se).size() < Se.epoch.warm.size() and warmG < 100:   # read at once; a ring counts as warm prepTicks ticks later
			WorldEpoch.tick(Se, false)
			warmG += 1
		WorldEpoch.tick(Se, true)
	var moved: bool = Se.epoch.n == 1 and (Se.planetRing.c[0] != before[0] or Se.planetRing.c[1] != before[1] or Se.planetRing.c[2] != before[2])
	for k in range(3):
		if Se.planetRing.c[k] != Se.epoch.ring.c[k] or Se.planetRing.t[k] != Se.epoch.ring.t[k]:
			moved = false
	ok(moved, "after a turn S.planetRing is the new ring (the epoch's)")
	print("FARSITES: %d check(s) failed" % fails)
	quit()
