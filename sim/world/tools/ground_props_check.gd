extends SceneTree
# W5, the provisional props on gen 2 planets (docs/world/props-w5.md; data/biomes/ground.json provisionalProps, off): bergs on the planet's berg cells, on the floes and in open water near the pack; lone
# trees on savanna and beach keeping their gap; WorldGround.propsNear for PROP SMASH. Each kind staged on a gen 2 world and shown placed, pure (twice, any split of the ring, across the seam, across a turn's
# kept columns) and read by nothing in the sim:
#   godot --headless --path . --script res://sim/world/tools/ground_props_check.gd
var fails: int = 0
const N: int = 2400
const SEEDS: int = 24


func ok(c: bool, w: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", w])
	if not c:
		fails += 1


func arc(a: float, b: float, n: int) -> float:
	var L: float = float(n) * SimConst.COL
	var d: float = fmod(absf(a - b), L)
	return minf(d, L - d)


func key(p: Dictionary) -> String:
	return "%05d %s %.6f %.6f" % [int(p.col), String(p.kind), float(p.x), float(p.size)]


func sorted(a: Array) -> Array:
	var k: Array = []
	for p in a:
		k.append(key(p))
	k.sort()
	return k


func rowOf(f: int, kind: String) -> Dictionary:
	for p in WorldGround.data().grounds[f].props:
		if String(p.kind) == kind:
			return p
	return {}


func rowIndex(f: int, kind: String) -> int:
	var pr: Array = WorldGround.data().grounds[f].props
	for k in range(pr.size()):
		if String(pr[k].kind) == kind:
			return k
	return -1


# The staged world: floes with two berg cells (one astride the seam, peak at column 1; one with a tied peak at 102 and 103), savanna with a lake, beach, then open water near the pack and far from it.
func stage() -> Array:
	var fine := PackedByteArray()
	var stored := PackedByteArray()
	var base := PackedFloat32Array()
	fine.resize(N)
	stored.resize(N)
	base.resize(N)
	for i in range(N):
		if i < 200:
			fine[i] = WorldClimate.F_SEA_ICE
			stored[i] = 2
			base[i] = 20.0
		elif i < 1000:
			fine[i] = WorldClimate.F_SAVANNA
			stored[i] = 1
			base[i] = 30.0
		elif i < 1600:
			fine[i] = WorldClimate.F_BEACH
			stored[i] = 1
			base[i] = 10.0
		elif i < 2396:
			fine[i] = WorldClimate.F_OCEAN
			stored[i] = 0
			base[i] = -40.0
		else:
			fine[i] = WorldClimate.F_SEA_ICE
			stored[i] = 2
			base[i] = 20.0
	var cellA: Dictionary = {2396: 60.0, 2397: 90.0, 2398: 120.0, 2399: 150.0, 0: 180.0, 1: 200.0, 2: 140.0, 3: 70.0}
	for c in cellA:
		base[c] = cellA[c]
	var cellB: Dictionary = {100: 50.0, 101: 80.0, 102: 110.0, 103: 110.0, 104: 60.0}
	for c in cellB:
		base[c] = cellB[c]
	return [fine, stored, base]


## The PROP SMASH row's `props` list wherever it stands in launch_biome.json.
func _smashProps(v) -> Array:
	if v is Dictionary:
		if v.has("PROP SMASH") and v["PROP SMASH"] is Dictionary and v["PROP SMASH"].has("props"):
			return Array(v["PROP SMASH"]["props"])
		for k in v:
			var r: Array = _smashProps(v[k])
			if not r.is_empty():
				return r
	return []


func _init() -> void:
	ok(WorldGround.dataErrors().is_empty(), "ground.json loads clean (%s)" % str(WorldGround.dataErrors()))
	ok(not WorldGround.K_PROVISIONAL, "provisionalProps is off in the data")
	var st: Array = stage()
	var fine: PackedByteArray = st[0]
	var stored: PackedByteArray = st[1]
	var base: PackedFloat32Array = st[2]
	var lakes: Array = [[400, 0.0, 0.0, 40]]
	var h0: float = float(WorldPlanet.cfg().bergH0)
	var band: int = int(ceil(float(WorldPlanet.cfg().bergCell) / SimConst.COL))
	var bergRow: Dictionary = rowOf(WorldClimate.F_SEA_ICE, "berg")
	var clear: int = int(ceil(float(bergRow.size[1]) * 75.0 / SimConst.COL))
	var nearIce: Dictionary = {}
	for i in range(N):
		for dd in range(-band, band + 1):
			if int(fine[(i + dd + N) % N]) == WorldClimate.F_SEA_ICE:
				nearIce[i] = true
				break

	# --- off: the new kinds are not laid, the other rows are the same with and without the new arguments
	var t0: Array = WorldGround.layTrees(fine, stored, base, 11)
	var off0: Array = WorldGround.propsIn(fine, stored, base, 11, 0, N)
	var off1: Array = WorldGround.propsIn(fine, stored, base, 11, 0, N, t0, lakes)
	var newKinds: bool = false
	for p in off0:
		if p.kind == "berg" or p.kind == "lone_tree":
			newKinds = true
	ok(not newKinds and str(off0) == str(off1), "off: no berg and no lone tree, and the trees and lakes change nothing (%d props)" % off0.size())

	# --- on: each kind over SEEDS seeds
	WorldGround.K_PROVISIONAL = true
	var cellBergs: int = 0
	var cellRight: bool = true
	var floeBergs: int = 0
	var waterBergs: int = 0
	var bergPlace: bool = true
	var lone: int = 0
	var lonePlace: bool = true
	var loneGap: bool = true
	var byTrees: int = 0
	var byLone: int = 0
	var byLake: int = 0
	var twice: bool = true
	var splits: bool = true
	var turn: bool = true
	var turnKept: int = 0
	var restSame: bool = true
	for sd in range(SEEDS):
		var seed: int = 1000 + sd * 7919
		var trees: Array = WorldGround.layTrees(fine, stored, base, seed)
		var all: Array = WorldGround.propsIn(fine, stored, base, seed, 0, N, trees, lakes)
		twice = twice and str(all) == str(WorldGround.propsIn(fine, stored, base, seed, 0, N, trees, lakes))
		var cells: Array = []
		var lones: Array = []
		for p in all:
			var c: int = int(p.col)
			if p.kind == "berg":
				if p.get("cell", false):
					cells.append(p)
				elif int(fine[c]) == WorldClimate.F_SEA_ICE:
					floeBergs += 1
				else:
					waterBergs += 1
				var nearCell: bool = false
				for dd in range(-clear, clear + 1):
					var j: int = (c + dd + N) % N
					if int(fine[j]) == WorldClimate.F_SEA_ICE and base[j] >= h0:
						nearCell = true
				if not p.get("cell", false) and (nearCell or not nearIce.has(c) or not (int(fine[c]) == WorldClimate.F_SEA_ICE or (int(fine[c]) == WorldClimate.F_OCEAN and base[c] < 0.0))):
					bergPlace = false
			elif p.kind == "lone_tree":
				lones.append(p)
		cellBergs += cells.size()
		if cells.size() != 2 or int(cells[0].col) != 1 or int(cells[1].col) != 102 or absf(float(cells[0].size) - 200.0 / 75.0) > 0.0001 or absf(float(cells[1].size) - 110.0 / 75.0) > 0.0001:
			cellRight = false
		# lone trees: their own ground, dry, no lake, the gap held to the ring's trees and to each other
		for p in lones:
			var c: int = int(p.col)
			var f: int = fine[c]
			if (f != WorldClimate.F_SAVANNA and f != WorldClimate.F_BEACH) or base[c] < 6.0 or WorldLakes.inLake(lakes, c, N):
				lonePlace = false
			var g: Dictionary = rowOf(f, "lone_tree")
			var k: int = rowIndex(f, "lone_tree")
			var gp: float = (float(g.gap[0]) + (float(g.gap[1]) - float(g.gap[0])) * SimRng.keyed(seed, "ground.prop.g%d" % k, c)) * SimConst.WS
			for t in trees:
				if arc(float(p.x), float(t.x), N) < gp:
					loneGap = false
			for q in lones:
				if q != p and arc(float(p.x), float(q.x), N) < gp:
					loneGap = false
		lone += lones.size()
		# the draws the gap rule turned down (counted from the draws themselves)
		for c in range(200, 1600):
			var f: int = fine[c]
			var k: int = rowIndex(f, "lone_tree")
			var g: Dictionary = rowOf(f, "lone_tree")
			if SimRng.keyed(seed, "ground.prop.%d" % k, c) >= float(g.per) * SimConst.COL / 1000.0:
				continue
			var stands: bool = false
			for p in lones:
				if int(p.col) == c:
					stands = true
			if stands:
				continue
			if WorldLakes.inLake(lakes, c, N):
				byLake += 1
				continue
			var x: float = (float(c) + SimRng.keyed(seed, "ground.prop.x%d" % k, c)) * SimConst.COL
			var gp: float = (float(g.gap[0]) + (float(g.gap[1]) - float(g.gap[0])) * SimRng.keyed(seed, "ground.prop.g%d" % k, c)) * SimConst.WS
			var hit: bool = false
			for t in trees:
				if arc(x, float(t.x), N) < gp:
					hit = true
			if hit:
				byTrees += 1
			else:
				byLone += 1
		# any split of the ring lays the same props, including a window astride the seam
		var whole: Array = sorted(all)
		for a in [1, 101, 777, 1000, 1599, 2398, 1 + (seed % (N - 2))]:
			if sorted(WorldGround.propsIn(fine, stored, base, seed, 0, a, trees, lakes) + WorldGround.propsIn(fine, stored, base, seed, a, N, trees, lakes)) != whole:
				splits = false
		var seamWin: Array = WorldGround.propsIn(fine, stored, base, seed, 2300, N, trees, lakes) + WorldGround.propsIn(fine, stored, base, seed, 0, 120, trees, lakes)
		var want: Array = []
		for p in all:
			if int(p.col) >= 2300 or int(p.col) < 120:
				want.append(p)
		if sorted(seamWin) != sorted(want):
			splits = false
		# a turn: the kept columns (here 300 to 1300) keep their ground and their trees, the rest is a new ring's; the props well inside the kept zone are the same
		var fine2: PackedByteArray = fine.duplicate()
		var base2: PackedFloat32Array = base.duplicate()
		var wt := PackedFloat32Array()
		wt.resize(N)
		for i in range(N):
			if i < 300 or i >= 1300:
				fine2[i] = [WorldClimate.F_SAVANNA, WorldClimate.F_BEACH, WorldClimate.F_SEA_ICE][(i / 97) % 3]
				base2[i] = 25.0 + float(i % 13)
				wt[i] = 1.0
		var trees2: Array = []
		for t in trees:
			var c: int = int(floor(float(t.x) / SimConst.COL))
			if wt[c] < 0.5:
				trees2.append(t)
		trees2 = trees2 + WorldGround.layTrees(fine2, stored, base2, seed ^ 0x5a5a, wt)
		var after: Array = WorldGround.propsIn(fine2, stored, base2, seed, 0, N, trees2, lakes)
		var m: int = int(ceil(100.0 * 2.0 * SimConst.WS / SimConst.COL)) + 2   # two of the widest gaps: what the zone's edge can reach
		var inA: Array = []
		var inB: Array = []
		for p in all:
			if int(p.col) >= 300 + m and int(p.col) < 1300 - m:
				inA.append(p)
		for p in after:
			if int(p.col) >= 300 + m and int(p.col) < 1300 - m:
				inB.append(p)
		turnKept += inA.size()
		if sorted(inA) != sorted(inB):
			turn = false
		# the rows W4 laid before stay exactly as they were
		var rest: Array = []
		for p in all:
			if p.kind != "berg" and p.kind != "lone_tree":
				rest.append(p)
		WorldGround.K_PROVISIONAL = false
		if str(rest) != str(WorldGround.propsIn(fine, stored, base, seed, 0, N)):
			restSame = false
		WorldGround.K_PROVISIONAL = true
	ok(cellRight and cellBergs == 2 * SEEDS, "berg cells: one berg on each, at its peak (column 1 across the seam; the tie at 102 and 103 goes west), sized by its height (%d)" % cellBergs)
	ok(floeBergs > 0 and waterBergs > 0 and bergPlace, "drawn bergs: %d on floes and %d in open water within one berg cell (%d columns) of the pack, none far out and none within %d columns of a cell" % [floeBergs, waterBergs, band, clear])
	ok(lone > 0 and lonePlace, "lone trees: %d over %d seeds, each on savanna or beach, dry and out of the lake" % [lone, SEEDS])
	ok(loneGap and byTrees > 0 and byLone > 0, "the gap rule holds: every lone tree is clear of the ring's trees and of each other by its own gap; it turned down %d draws for a ring tree, %d for a nearer lone tree, %d for the lake" % [byTrees, byLone, byLake])
	ok(twice, "the same twice")
	ok(splits, "any split of the ring lays the same props, and a window astride the seam (2300 to 120) lays what the whole ring lays there")
	ok(turn and turnKept > 0, "a turn's kept columns keep their props (%d well inside the zone over %d seeds)" % [turnKept, SEEDS])
	ok(restSame, "the other rows lay exactly what they laid with the switch off")
	WorldGround.K_PROVISIONAL = false

	# --- a real gen 2 planet (seed 8, touch 3: berg cells, savanna and beach), and the worlds that have no fine ground
	var S := SimState.new()
	SimCore.newMatch(S, 1, {}, {"intro": false})
	WorldGround.K_PROVISIONAL = true
	ok(WorldGround.propsNear(S, 1000.0, 400.0).is_empty(), "the hand-made world: propsNear is [] even with the switch on")
	SimCore.newMatch(S, 1, {}, {"planet": 7, "planetGen": 1, "arena": {"cols": 2400}, "intro": false})
	ok(WorldGround.propsNear(S, 1000.0, 400.0).is_empty(), "a gen 1 planet: propsNear is [] even with the switch on")
	WorldGround.K_PROVISIONAL = false
	var setup: Dictionary = {"planet": 8, "touch": 3, "planetGen": 2, "arena": {"cols": 2400}, "intro": false}
	SimCore.newMatch(S, 1, {}, setup)
	ok(WorldGround.propsNear(S, 1000.0, 4000.0).is_empty(), "gen 2 with the switch off: propsNear is []")
	WorldGround.K_PROVISIONAL = true
	var fc: PackedByteArray = WorldBiomes.fineCols
	var pc: PackedByteArray = WorldBiomes.planetCols
	var n: int = fc.size()
	var seedP: int = int(S.planetRing.seed)
	var lakesP: Array = S.planetRing.get("lakes", [])
	var allP: Array = WorldGround.propsIn(fc, pc, S.base, seedP, 0, n, S.trees, lakesP)
	var runs: int = 0
	for i in range(n):
		if int(fc[i]) == WorldClimate.F_SEA_ICE and int(pc[i]) < 7 and S.base[i] >= h0:
			var j: int = (i - 1 + n) % n
			if not (int(fc[j]) == WorldClimate.F_SEA_ICE and int(pc[j]) < 7 and S.base[j] >= h0):
				runs += 1
	var kinds: Dictionary = {}
	var cellsP: int = 0
	for p in allP:
		kinds[p.kind] = int(kinds.get(p.kind, 0)) + 1
		if p.get("cell", false):
			cellsP += 1
	ok(runs > 0 and cellsP == runs, "planet 8: %d berg cell(s) in the ring, %d berg(s) on them; %d bergs, %d lone trees, %d boulders in all" % [runs, cellsP, int(kinds.get("berg", 0)), int(kinds.get("lone_tree", 0)), int(kinds.get("boulder", 0))])
	# planet 6, touch 2: open savanna, where the ring's trees leave room for lone trees
	setup = {"planet": 6, "touch": 2, "planetGen": 2, "arena": {"cols": 2400}, "intro": false}
	SimCore.newMatch(S, 1, {}, setup)
	fc = WorldBiomes.fineCols
	pc = WorldBiomes.planetCols
	n = fc.size()
	seedP = int(S.planetRing.seed)
	lakesP = S.planetRing.get("lakes", [])
	allP = WorldGround.propsIn(fc, pc, S.base, seedP, 0, n, S.trees, lakesP)
	var lonesP: Array = []
	var smashP: int = 0
	for p in allP:
		if p.kind == "lone_tree":
			lonesP.append(p)
		if WorldGround.SMASH.has(String(p.kind)):
			smashP += 1
	var gapP: bool = true
	for p in lonesP:
		var f: int = fc[int(p.col)]
		var g: Dictionary = rowOf(f, "lone_tree")
		var gp: float = (float(g.gap[0]) + (float(g.gap[1]) - float(g.gap[0])) * SimRng.keyed(seedP, "ground.prop.g%d" % rowIndex(f, "lone_tree"), int(p.col))) * SimConst.WS
		for t in S.trees:
			gapP = gapP and arc(float(p.x), float(t.x), n) >= gp
		for q in lonesP:
			gapP = gapP and (q == p or arc(float(p.x), float(q.x), n) >= gp)
		gapP = gapP and (f == WorldClimate.F_SAVANNA or f == WorldClimate.F_BEACH) and not WorldLakes.inLake(lakesP, int(p.col), n)
	ok(lonesP.size() > 0 and gapP, "planet 6: %d lone trees on savanna and beach, each clear of the ring's %d trees and of each other by its gap, none in a lake; %d smash targets in all" % [lonesP.size(), S.trees.size(), smashP])
	# propsNear: the smash targets within reach by shortest arc, nearest first; the same as the whole ring filtered, at the seam too
	var near: bool = true
	var seamSeen: bool = false
	for x in [0.0, 16.0, float(n) * SimConst.COL - 16.0, 12345.0, 40000.0, 1900.5 * SimConst.COL]:
		for r in [40.0, 300.0, 600.0]:
			var got: Array = WorldGround.propsNear(S, x, r)
			var want: Array = []
			for p in allP:
				if WorldGround.SMASH.has(String(p.kind)) and absf(SimWrap.sdx(x, float(p.x))) <= r * 75.0:
					want.append(p)
			if sorted(got) != sorted(want):
				near = false
			for i in range(got.size()):
				if absf(float(got[i].d) - SimWrap.sdx(x, float(got[i].x))) > 0.0001 or (i > 0 and absf(float(got[i].d)) < absf(float(got[i - 1].d))):
					near = false
			for p in got:   # one found across the seam: its plain difference is more than half the ring, its shortest arc within reach
				seamSeen = seamSeen or (r <= 300.0 and absf(float(p.x) - x) > SimConst.HALF)
	ok(near and seamSeen, "propsNear: the targets within reach by shortest arc, nearest first, the whole ring's; and one across the seam")
	WorldGround.K_PROVISIONAL = false
	# nothing in the sim reads them: a match plays the same with the switch on
	var hs: Array = []
	for on in [false, true]:
		WorldGround.K_PROVISIONAL = on
		var T := SimState.new()
		SimCore.newMatch(T, 1, {}, setup)
		for _t in range(600):
			SimCore.step(T)
		hs.append(str(SimHash.stateHash(T).gameplay))
	WorldGround.K_PROVISIONAL = false
	ok(hs[0] == hs[1], "a gen 2 match (planet 6, 600 ticks) is the same match with provisionalProps on (%s)" % hs[0])
	# --- PROP SMASH's kinds follow Combat's launch_biome.json, and a broken column loses only its smashable prop
	var lb = JSON.parse_string(FileAccess.get_file_as_string("res://data/combat/launch_biome.json"))
	var want: Array = _smashProps(lb)
	var have: Array = WorldGround.SMASH.duplicate()
	want.sort()
	have.sort()
	ok(not want.is_empty() and want == have, "ground.json's smash list equals launch_biome.json's PROP SMASH props (%s)" % str(have))
	var pk: Array = [{"x": 100.0, "kind": "scrub", "size": 0.9, "col": 3}, {"x": 110.0, "kind": "boulder", "size": 1.4, "col": 3}, {"x": 112.0, "kind": "scrub", "size": 1.2, "col": 3}, {"x": 140.0, "kind": "boulder", "size": 1.1, "col": 4}]
	ok(WorldGround.smashIn(pk) == 1 and WorldGround.smashIn([pk[0], pk[2]]) == -1 and WorldGround.smashIn([pk[3], {"x": 1.0, "kind": "lichen_rock", "size": 1.1, "col": 4}]) == 0, "smashIn picks the biggest smashable prop of a column, the first of two as big, and none where nothing is smashable (a scrub is never the target)")
	print("GROUNDPROPS: %d check(s) failed" % fails)
	quit(1 if fails > 0 else 0)
