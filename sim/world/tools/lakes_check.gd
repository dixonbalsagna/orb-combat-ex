extends SceneTree
# Planet generation 2, window 5: lakes (WorldLakes, data/biomes/lakes.json): the valleys of a gen 2 match's ring that hold water.
#   godot --headless --path . --script res://sim/world/tools/lakes_check.gd
var fails: int = 0


func ok(c: bool, w: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", w])
	if not c:
		fails += 1


func gen2_match(sd: int, touch: int, turn: bool) -> SimState:
	var arena: Dictionary = {"cols": 2400}
	if turn:
		arena["turn"] = true
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {}, {"planet": sd, "touch": touch, "arena": arena, "planetGen": 2, "intro": false})
	return S


func _init() -> void:
	ok(WorldLakes.dataErrors().is_empty() and int(WorldClimate.data().gen) == 1, "lakes.json is clean (%s) and the data's generation is still 1" % str(WorldLakes.dataErrors()))
	# a hand-made profile: one valley between two crests, one pit too shallow, one valley by a town, one in a desert
	var n: int = 600
	var base := PackedFloat32Array()
	base.resize(n)
	for i in range(n):
		base[i] = 400.0
	for i in range(100, 160):   # a valley: floor 200, walls climbing to 400 and 460 crests
		base[i] = 200.0 + 4.0 * absf(float(i) - 130.0)
	base[99] = 460.0
	base[98] = 450.0
	for i in range(220, 240):   # too shallow: 20 deep
		base[i] = 380.0 + 2.0 * absf(float(i) - 230.0)
	for i in range(300, 360):   # a valley with a town on its shore
		base[i] = 200.0 + 4.0 * absf(float(i) - 330.0)
	for i in range(420, 480):   # a valley in a desert
		base[i] = 200.0 + 4.0 * absf(float(i) - 450.0)
	var fine := PackedByteArray()
	fine.resize(n)
	fine.fill(WorldClimate.F_PLAINS)
	for i in range(400, 500):
		fine[i] = WorldClimate.F_DESERT
	var stored := PackedByteArray()
	stored.resize(n)
	stored.fill(1)
	var chords: Array = [[0, 1, 365, 380]]   # a town 5 columns from the second valley's right shore
	var lakes: Array = WorldLakes.plan(base, chords, fine, stored)
	ok(lakes.size() == 1 and int(lakes[0][0]) >= 100 and int(lakes[0][1]) <= 159, "a hand-made ring: of four valleys only the open one holds a lake (the shallow pit, the one by a town and the one in a desert do not): %s" % str(lakes))
	if lakes.size() == 1:
		var lk: Array = lakes[0]
		var lvl: float = float(lk[2])
		ok(absf(lvl - 400.0) < 1.0e-6 and int(lk[3]) == int(lk[1]) - int(lk[0]) + 1, "the lake stands at the lower crest (400, not 460) and covers the columns whose ground is under it (%d to %d, %d wide)" % [int(lk[0]), int(lk[1]), int(lk[3])])
		var flat: bool = true
		for c in range(int(lk[0]), int(lk[1]) + 1):
			if base[c] >= lvl:
				flat = false
		ok(flat and base[int(lk[0]) - 1] >= lvl - 1.0e-6 and base[int(lk[1]) + 1] >= lvl - 1.0e-6, "every lake column is lower than the level and the columns just outside it are not")
	var again: Array = WorldLakes.plan(base, chords, fine, stored)
	ok(str(again) == str(lakes), "a plan is a pure function of the ground, the places and the biomes")
	# --- real rings
	var withLake: int = 0
	var rings: int = 0
	var total: int = 0
	var worst: String = ""
	var strip: int = 0
	var sample: SimState = null
	var sampleLakes: int = 0
	for sd in [7, 3, 11, 25, 42, 101]:
		for touch in [0, 1, 2]:
			var S: SimState = gen2_match(sd, touch, false)
			rings += 1
			var NC: int = SimConst.NC
			var pl: Array = WorldLakes.plan(S.base, [], WorldBiomes.fineCols, WorldBiomes.planetCols)
			# the match's own water: every wet column that is not sea is part of a planned lake's flat surface
			var wet: int = 0
			var lakeCols: int = 0
			for i in range(NC):
				if S.base[i] >= 5.0 and S.water[i] >= WorldWater.MIN_DEPTH:
					wet += 1
			var surfaces: Dictionary = {}
			for i in range(NC):
				if S.base[i] >= 5.0 and S.water[i] >= WorldWater.MIN_DEPTH:
					surfaces[snappedf(S.base[i] + S.water[i], 0.5)] = true
			if wet > 0:
				withLake += 1
				if sample == null:
					sample = S
					sampleLakes = surfaces.size()
			total += wet
			for t in S.trees:
				var col: int = int(floor(SimWrap.wrap(t.x) / SimConst.COL)) % NC
				if S.base[col] >= 5.0 and S.water[col] >= WorldWater.MIN_DEPTH:
					worst = "a tree in the water at %d (seed %d touch %d)" % [col, sd, touch]
			for t2 in S.trees:
				var col2: int = int(floor(SimWrap.wrap(t2.x) / SimConst.COL)) % NC
				if WorldLakes.flooded(S.planetRing.get("lakes", []), S.base, col2, NC):
					strip += 1
					if worst == "":
						worst = "a tree on a lake's flood strip at %d (seed %d touch %d)" % [col2, sd, touch]
			if wet > 0 and surfaces.size() > 12:
				worst += " seed %d touch %d: %d surfaces" % [sd, touch, surfaces.size()]
	ok(worst == "", "no tree stands in a lake or on the dry strip the sheet is drawn over, and a ring's lakes are few flat surfaces (%d on a strip) %s" % [strip, worst])
	ok(withLake >= 2 and withLake <= rings, "%d of %d rings hold a lake (%d wet columns in all)" % [withLake, rings, total])
	# --- the match: determinism, the water module and cover
	if sample != null:
		var S1: SimState = sample
		var h1: String = str(SimHash.stateHash(S1).gameplay)
		for t in range(120):
			SimCore.step(S1)
		var wetAfter: int = 0
		for i in range(SimConst.NC):
			if S1.base[i] >= 5.0 and S1.water[i] >= WorldWater.MIN_DEPTH:
				wetAfter += 1
		ok(wetAfter > 0, "a lake stands through 120 ticks (the flow leaves inland water alone): %d wet columns" % wetAfter)
		var deep: int = -1
		for i in range(SimConst.NC):
			if S1.base[i] >= 5.0 and S1.water[i] >= WorldWater.HIDE_MIN_DEPTH:
				deep = i
				break
		if deep >= 0:
			var xs: float = (float(deep) + 0.5) * SimConst.COL
			var f = {"x": xs, "y": WorldWater.surfaceAt(S1, xs) - 80.0}
			ok(WorldCover.coverAt(S1, f) == "submerged", "a fighter low in a deep lake (%.0f deep) is submerged: hidden by the water rules" % S1.water[deep])
		var S2: SimState = gen2_match(7, 0, false)
		var S3: SimState = gen2_match(7, 0, false)
		ok(str(SimHash.stateHash(S2).gameplay) == str(SimHash.stateHash(S3).gameplay), "a gen 2 match with its lakes is the same twice (%s)" % h1.substr(0, 8))
	# --- the turn: the new ring's lakes
	var T := gen2_match(7, 1, true)
	for t in range(30):
		SimCore.step(T)
	T.T = 100.0
	var mid: float = 0.5 * (T.fighters[0].x + T.fighters[1].x)
	if not WorldEpoch.ask(T, "t", mid, 1, 0).is_empty():
		WorldEpoch.choose(T, 3)
		T.epoch.next.k = 100000
		var warm: int = 0
		while WorldEpoch.warmAngles(T).size() < T.epoch.warm.size() and warm < 100:
			WorldEpoch.tick(T, false)
			warm += 1
		WorldEpoch.tick(T, true)
	for t in range(60):
		SimCore.step(T)
	var treesDry: bool = true
	for t in T.trees:
		var col2: int = int(floor(SimWrap.wrap(t.x) / SimConst.COL)) % SimConst.NC
		if T.base[col2] >= 5.0 and T.water[col2] >= WorldWater.MIN_DEPTH:
			treesDry = false
	var turnStrip: int = 0
	for t3 in T.trees:
		if WorldLakes.flooded(T.planetRing.get("lakes", []), T.base, int(floor(SimWrap.wrap(t3.x) / SimConst.COL)) % SimConst.NC, SimConst.NC):
			turnStrip += 1
	ok(int(T.epoch.n) == 1 and treesDry and turnStrip == 0, "after a turn the new ring's trees stand out of the water and off the strip (epoch %d, %d on a strip)" % [int(T.epoch.n), turnStrip])
	WorldClimate.useGen(0)
	print("LAKES: %d check(s) failed" % fails)
	quit()
