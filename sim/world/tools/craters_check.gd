extends SceneTree
# A slam's crater by material (docs/world/craters-by-material.md, data/biomes/craters.json, off by default) and W4's props (ground.json provisionalProps, off): each piece staged on a flat gen 2 world and shown
# applied (the bowl's factors and wall, the refill job, the water in a mud and a shingle bowl, a floe broken through, the embed threshold and sink, the crater event's material and eventFor, the props rows);
# the switch off and touchBuilt off leave the hand-made world, a gen 1 planet and a gen 2 match as they were (the switch on adds only after.gd's two zeros); the same slam twice is the same state.
#   godot --headless --path . --script res://sim/world/tools/craters_check.gd     (-- --quick: the staged pieces only, without the matches)
var fails: int = 0
const COL: float = SimConst.COL


func ok(c: bool, w: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", w])
	if not c:
		fails += 1


func fid(name: String) -> int:
	var fine: Array = WorldClimate.data().get("fine", [])
	for k in range(fine.size()):
		if String(fine[k].name) == name:
			return k
	return -1


## A flat gen 2 world, as after_check's: the sea on columns 0 to 299 (floor at -300), plains at 30 from there on.
func world() -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {}, {"intro": false})
	var nc: int = SimConst.NC
	S.base.fill(30.0)
	for i in range(300):
		S.base[i] = -300.0
	S.deform.fill(0.0)
	S.rubble.fill(0.0)
	S.scorch.fill(0.0)
	S.buildings.clear()
	WorldStructures.buildIndex(S)   # the dig asks the index for footings
	S.trees.clear()
	S.craters.clear()
	WorldWater.init(S)
	var pc := PackedByteArray()
	pc.resize(nc)
	pc.fill(1)
	var fc := PackedByteArray()
	fc.resize(nc)
	fc.fill(1)
	for i in range(300):
		pc[i] = 0
		fc[i] = 0
	WorldBiomes.planetCols = pc
	WorldBiomes.fineCols = fc
	WorldBiomes.worldId = WorldBiomes.claim()
	S.worldId = WorldBiomes.worldId
	S.fighters[0].x = 40000.0
	S.fighters[1].x = 41000.0
	return S


func region(S: SimState, c0: int, c1: int, fine: int, base: float = NAN) -> void:
	var fc: PackedByteArray = WorldBiomes.fineCols
	for i in range(c0, c1 + 1):
		fc[i] = fine
		if not is_nan(base):
			S.base[i] = base
	WorldBiomes.fineCols = fc
	WorldBiomes.worldId = WorldBiomes.claim()   # contact's per-column looks are rebuilt for the new layout
	S.worldId = WorldBiomes.worldId


func h(S: SimState) -> String:
	return str(SimHash.stateHash(S).gameplay)


## A slam's dig at column c as contact.gd makes it: the shape read first, the dig, then after(). Returns [record, shape, broke].
func slam(S: SimState, c: int, E: float = 2.0) -> Array:
	var x: float = (float(c) + 0.5) * COL
	var sh: PackedFloat64Array = WorldCraters.shapeAt(S, x)
	var rc = WorldCrater.dig(S, x, E, null, "impact", 0.0, 1.0, false, NAN, sh)
	var broke: bool = WorldCraters.after(S, rc, sh) if sh.size() > 0 else false
	return [rc, sh, broke]


func stepN(S: SimState, n: int) -> void:
	for t in range(n):
		WorldWater.step(S)


func run(setup: Dictionary, ticks: int) -> Array:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {}, setup)
	var shaped: int = 0
	for t in range(ticks):
		SimCore.step(S)
		for e in S.out.fx:
			if e.type == "crater" and e.surface != "":
				shaped += 1
		S.out.fx.clear()   # the host drains them each tick
	return [SimHash.collect(S, "gameplay"), shaped]


func _init() -> void:
	ok(WorldCraters.dataErrors().is_empty(), "craters.json is clean (%s)" % str(WorldCraters.dataErrors()))
	ok(WorldGround.dataErrors().is_empty(), "ground.json is clean (%s)" % str(WorldGround.dataErrors()))
	ok(not WorldCraters.on() and not WorldCraters.K_BUILT and WorldCraters.K_SCALES, "the switches in the data: enabled off, touchBuilt off, embedThresholdScales on")
	ok(not WorldGround.K_PROVISIONAL, "ground.json provisionalProps is off in the data")
	var rows: Dictionary = WorldCraters.data().classes
	ok(rows.size() == 14 and WorldCraters.shapeOf("mud").size() == 11 and WorldCraters.shapeOf("water").is_empty(), "every one of Combat's 14 classes has a row (water, which has none, digs today's bowl)")
	ok(is_equal_approx(float(rows.sand.radius), 1.3) and is_equal_approx(float(rows.mud.embedMul), 1.8) and is_equal_approx(float(rows.snow.refill), 0.2) and int(rows.snow.refillTicks) == 1200 and bool(rows.ice.breakThrough) and String(rows.shingle.fill) == "waterNearSea", "the rows are Combat's numbers (biomes.md section 4.3: sand 1.3 wide, mud x1.8, snow 20% in 20 s, ice breaks through, shingle fills near the sea)")

	# --- off: no shape anywhere, the hand-made world, a gen 1 planet and a gen 2 match play as they did
	WorldCraters.K_ON = false
	var So: SimState = world()
	region(So, 600, 760, fid("wetland"))
	ok(WorldCraters.shapeAt(So, 680.5 * COL).is_empty(), "off: a slam in a wetland reads no shape (today's bowl)")
	var quick: bool = OS.get_cmdline_user_args().has("--quick")
	var cases: Array = [["the hand-made world", {"intro": false}], ["a gen 1 planet", {"planet": 7, "planetGen": 1, "arena": {"cols": 2400}, "intro": false}], ["a gen 2 planet", {"planet": 3, "touch": 0, "planetGen": 2, "arena": {"cols": 2400}, "intro": false}]]
	var off: Array = []
	for k in range(cases.size()):
		off.append(run(cases[k][1], 2400 if k == 2 else 900) if not quick else [])
	# --- on, touchBuilt off: the hand-made world and gen 1 dig today's bowls (their classes are the five built); only after.gd's sizing adds its two zeros
	WorldCraters.K_ON = true
	for k in range(0 if quick else 2):
		var on: Array = run(cases[k][1], 900)
		var vo: Array = off[k][0].duplicate()
		var ext: bool = vo.size() + 2 == on[0].size() or vo.size() == on[0].size()
		var same: bool = ext and on[1] == 0
		if same:
			for q in range(vo.size()):
				if on[0][q] != vo[q]:
					same = false
					break
		ok(same, "on, touchBuilt off: %s plays as with the switch off (900 ticks; the vector is the same %s, no shaped crater)" % [cases[k][0], "plus after.gd's two zeros" if vo.size() + 2 == on[0].size() else "exactly"])
	if not quick:
		var g2: Array = run(cases[2][1], 2400)
		ok(g2[1] > 0 and g2[0] != off[2][0], "on: a gen 2 match (planet 3, 2400 ticks) digs %d shaped crater(s) on its new ground (it slams on snow), and so is a different match" % g2[1])
		WorldCraters.K_ON = false
		var g2off: Array = run(cases[2][1], 2400)
		ok(g2off[0] == off[2][0] and g2off[1] == 0 and off[2][1] == 0, "off again: the gen 2 match is the one it was, with no shaped crater")
		WorldCraters.K_ON = true

	# --- the bowl by material: radius, depth, rim and the wall, against today's bowl at the same spot and energy
	for nm in [["wetland", "mud"], ["taiga", "snow"], ["tundra", "frost"], ["jungle", "litter"], ["volcanic", "crust"], ["savanna", "turf"]]:
		var Sa: SimState = world()
		region(Sa, 600, 760, fid(nm[0]))
		var Sb: SimState = world()
		region(Sb, 600, 760, fid(nm[0]))
		var a: Array = slam(Sa, 680)
		var rb = WorldCrater.dig(Sb, 680.5 * COL, 2.0, null, "impact")
		var row: Dictionary = rows[nm[1]]
		var r: float = a[0].r / rb.r
		var dd: float = a[0].depth / rb.depth
		var rr: float = a[0].rim / maxf(rb.rim, 1.0e-9)
		ok(WorldCraters.lookName(a[1]) == nm[1] and absf(r - float(row.radius)) < 1.0e-6 and absf(dd - float(row.depth)) < 1.0e-6 and absf(rr - float(row.rim)) < 1.0e-6, "%s: a slam in %s digs %.2f x the radius, %.2f x the depth and %.2f x the rim of today's bowl (the row: %s, %s, %s)" % [nm[1], nm[0], r, dd, rr, row.radius, row.depth, row.rim])
	var ws: float = WorldCrater.profile(0.8, 10.0, 0.0, 1.5)
	var w1: float = WorldCrater.profile(0.8, 10.0, 0.0, 1.0)
	var w0: float = WorldCrater.profile(0.8, 10.0, 0.0, 0.6)
	ok(WorldCrater.profile(0.37, 10.0, 2.0) == WorldCrater.profile(0.37, 10.0, 2.0, 1.0) and ws < w1 and w1 < w0 and WorldCrater.profile(0.0, 10.0, 0.0, 1.5) == -10.0, "steep: 1 is today's profile; a steep wall (ice 1.5) is deeper at 0.8 R than today's, a slack one (sand 0.6) shallower (%.2f, %.2f, %.2f), the centre at full depth" % [ws, w1, w0])
	# the strips: an ash strip (burnt grass) and a glaze dig their own rows
	var St: SimState = world()
	region(St, 600, 760, fid("savanna"))
	WorldAfter._ensure(St)
	for i in range(650, 711):
		WorldAfter._put(St, i, WorldAfter.BURNT, 0)
	ok(WorldCraters.lookName(WorldCraters.shapeAt(St, 680.5 * COL)) == "ash" and WorldCraters.lookName(WorldCraters.shapeAt(St, 740.5 * COL)) == "turf", "a beam's strip digs its own row: burnt grass reads ash, the savanna beside it turf")

	# --- touchBuilt: today's five classes only with it on
	var Sp: SimState = world()
	ok(WorldCraters.shapeAt(Sp, 1000.5 * COL).is_empty(), "touchBuilt off: plains (soil) dig today's bowl")
	WorldCraters.K_BUILT = true
	var sp: Array = slam(Sp, 1000)
	ok(WorldCraters.lookName(sp[1]) == "soil" and sp[0] != null, "touchBuilt on: plains dig the soil row")
	WorldCraters.K_BUILT = false

	# --- the crater event carries the material, and eventFor makes crater_shape from it
	var Se: SimState = world()
	region(Se, 600, 760, fid("wetland"))
	Se.out.fx.clear()
	var se: Array = slam(Se, 680)
	var ce = null
	for e in Se.out.fx:
		if e.type == "crater":
			ce = e
	var ev: Dictionary = WorldCraters.eventFor(ce, ce.surface) if ce != null else {}
	ok(ce != null and ce.surface == "mud" and ev.get("surface", "") == "mud" and is_equal_approx(float(ev.r), se[0].r) and is_equal_approx(float(ev.shape.embedMul), 1.8) and String(ev.shape.ejecta) == "mud_splash", "crater_shape: the crater event's surface is the material (mud) and eventFor gives the bowl as dug with its row (embedMul 1.8, mud_splash)")
	ok(not SimHash.FX_FIELDS.crater.has("surface"), "the material is not one of the crater event's hashed fields (no hash.gd line)")

	# --- fill: water stands in a mud bowl (to the wetland's table) and in a shingle bowl near the sea, not in one far from it
	var td: float = WorldFill.tableDepth("wetland")
	ok(se[0].depth > td and Se.water[680] > 0.0 and absf(Se.base[680] + WorldTerrain.lowD(Se)[680] + Se.water[680] - (Se.base[680] - td)) < 0.01 and WorldAfter.kindAt(Se, 680.5 * COL) == WorldAfter.FLOODED, "fill water: the mud bowl (%.1f deep) holds water to the wetland's table (%.1f below the ground), and reads flooded" % [se[0].depth, td])
	var Sh: SimState = world()
	region(Sh, 300, 340, fid("beach"), 8.0)
	region(Sh, 700, 740, fid("beach"), 8.0)
	WorldWater.init(Sh)
	var near: Array = slam(Sh, 312)
	var far: Array = slam(Sh, 720)
	ok(WorldCraters.lookName(near[1]) == "shingle" and Sh.water[312] > 0.0 and Sh.water[720] == 0.0, "fill waterNearSea: a shingle bowl 13 columns from the sea fills to the sea (%.1f deep), one 420 columns away stays dry" % Sh.water[312])

	# --- refill: mud closes 60% in 240 ticks, by the aftermath jobs
	var jobs: int = Se.aftermathJobs.size()
	var d0: float = -Se.deform[680]
	stepN(Se, 120)
	var dHalf: float = -Se.deform[680]
	stepN(Se, 130)
	var d1: float = -Se.deform[680]
	ok(jobs == 1 and int(Se.aftermathJobs.size()) == 0 and dHalf < d0 and absf(d1 - d0 * 0.4) < 0.05 * d0, "refill: the mud bowl's centre fills back from %.1f to %.1f deep (40%%) over 240 ticks by an aftermath job (%.1f at 120), and the job ends" % [d0, d1, dHalf])
	var Sw: SimState = world()
	region(Sw, 600, 760, fid("wetland"))
	slam(Sw, 680)
	var lvl0: float = Sw.base[680] + WorldTerrain.lowD(Sw)[680] + Sw.water[680]
	stepN(Sw, 250)
	var lvl1: float = Sw.base[680] + WorldTerrain.lowD(Sw)[680] + Sw.water[680]
	ok(absf(lvl1 - lvl0) < 0.01 and Sw.water[680] >= 0.0, "refill: the water in a closing mud bowl keeps its level (%.2f, then %.2f)" % [lvl0, lvl1])
	var Sx: SimState = world()
	region(Sx, 600, 760, fid("wetland"))
	var Sy: SimState = world()
	region(Sy, 600, 760, fid("wetland"))
	slam(Sx, 680)
	slam(Sy, 680)
	stepN(Sx, 100)
	stepN(Sy, 100)
	ok(h(Sx) == h(Sy), "the same slam twice, 100 ticks on, is the same state (the job is hashed with after.gd's)")

	# --- breakThrough: a slam deeper than a thin floe breaks it and opens water under him; a thick floe holds
	var Si: SimState = world()
	region(Si, 300, 900, fid("ocean"), -300.0)
	region(Si, 600, 700, fid("sea_ice"), 12.0)
	WorldWater.init(Si)
	var bi: Array = slam(Si, 650)
	var slot: int = 0
	var wet: bool = true
	for i in range(600, 701):
		if WorldAfter.kindAt(Si, (float(i) + 0.5) * COL) == WorldAfter.SPLIT:
			slot += 1
			if Si.water[i] < WorldWater.MIN_DEPTH or Si.base[i] + Si.deform[i] >= 0.0:
				wet = false
	ok(WorldCraters.lookName(bi[1]) == "ice" and bi[2] and slot > 0 and wet and Si.water[650] > 30.0, "breakThrough: a slam on a floe 12 above the sea breaks it: a %d-column slot cut below the sea and filled (%.0f deep at the centre), and contact does not embed him" % [slot, Si.water[650]])
	var Sk: SimState = world()
	region(Sk, 300, 900, fid("ocean"), -300.0)
	region(Sk, 600, 700, fid("sea_ice"), 100.0)
	WorldWater.init(Sk)
	var bk: Array = slam(Sk, 650)
	ok(not bk[2] and Sk.water[650] == 0.0 and bk[0].depth < 100.0, "breakThrough: on a floe 100 above the sea the bowl (%.1f deep) stays in the ice" % bk[0].depth)
	var Sl: SimState = world()
	region(Sl, 300, 900, fid("ocean"), -300.0)
	region(Sl, 600, 700, fid("sea_ice"), 12.0)
	WorldWater.init(Sl)
	WorldCraters.breakThrough(Sl, 650, 2)
	var a2: int = 0
	for i in range(600, 701):
		if WorldAfter.kindAt(Sl, (float(i) + 0.5) * COL) == WorldAfter.SPLIT:
			a2 += 1
	ok(a2 == 2 and Sl.deform[650] == -(12.0 + WorldAfter.splitDepth()) and is_equal_approx(Sl.water[650], WorldAfter.splitDepth()), "the cut is the FLOE SPLIT aftermath's (after.gd split calls breakThrough): 2 columns, %.0f below the sea, filled" % WorldAfter.splitDepth())

	# --- the embed: the threshold scales with the depth (today's rate), embedMul is how deep he sits
	var em: PackedFloat64Array = WorldCraters.shapeOf("mud")
	ok(WorldCraters.threshold(em) == 1.2 and WorldCraters.sink(em) == 1.8 and WorldCraters.threshold(WorldCraters.NONE) == 1.0 and WorldCraters.sink(WorldCraters.NONE) == 1.0 and WorldCraters.threshold(WorldCraters.shapeOf("ice")) == 0.6, "embed: the threshold is the row's depth (mud 1.2, ice 0.6, today's bowl 1) and he sits embedMul deep (mud 1.8)")
	WorldCraters.K_SCALES = false
	ok(WorldCraters.threshold(em) == 1.0, "embedThresholdScales off: the threshold is today's")
	WorldCraters.K_SCALES = true

	# --- props: bergs on sea ice, lone trees on savanna and beach, laid only with provisionalProps on; the other rows lay the same either way
	var nc: int = SimConst.NC
	var fine := PackedByteArray()
	fine.resize(nc)
	var stored := PackedByteArray()
	stored.resize(nc)
	stored.fill(1)
	var base := PackedFloat32Array()
	base.resize(nc)
	base.fill(30.0)
	for i in range(nc):
		fine[i] = [fid("sea_ice"), fid("savanna"), fid("beach")][(i / 800) % 3]
	WorldGround.K_PROVISIONAL = false
	var p0: Array = WorldGround.propsIn(fine, stored, base, 1234, 0, nc)
	WorldGround.K_PROVISIONAL = true
	var p1: Array = WorldGround.propsIn(fine, stored, base, 1234, 0, nc)
	WorldGround.K_PROVISIONAL = false
	var kinds0: Dictionary = {}
	var kinds1: Dictionary = {}
	var rest: Array = []
	for p in p0:
		kinds0[p.kind] = int(kinds0.get(p.kind, 0)) + 1
	for p in p1:
		kinds1[p.kind] = int(kinds1.get(p.kind, 0)) + 1
		if p.kind != "berg" and p.kind != "lone_tree":
			rest.append(p)
	var bergOk: bool = true
	for p in p1:
		if p.kind == "berg" and (int(fine[int(p.col)]) != fid("sea_ice") or float(p.size) < 0.6 or float(p.size) > 2.9):
			bergOk = false
		if p.kind == "lone_tree" and int(fine[int(p.col)]) != fid("savanna") and int(fine[int(p.col)]) != fid("beach"):
			bergOk = false
	ok(not kinds0.has("berg") and not kinds0.has("lone_tree"), "props off: no berg and no lone tree (%s)" % str(kinds0))
	ok(int(kinds1.get("berg", 0)) > 0 and int(kinds1.get("lone_tree", 0)) > 0 and bergOk, "props on: %d bergs on the sea ice and %d lone trees on savanna and beach, each of its own biome and size" % [int(kinds1.get("berg", 0)), int(kinds1.get("lone_tree", 0))])
	ok(str(rest) == str(p0), "props on: the other rows lay exactly what they laid with it off (%d)" % p0.size())

	WorldCraters.K_ON = false
	print("CRATERS CHECK: %d failed" % fails)
	quit(1 if fails > 0 else 0)
