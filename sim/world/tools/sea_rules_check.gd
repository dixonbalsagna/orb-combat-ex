extends SceneTree
# Window 11: the sea's rules measure from the water's surface, not from absolute zero, so a deep lake at altitude follows them (Game Design 23b rows 13 and 15) and the sea is exactly as it was.
#   godot --headless --path . --script res://sim/world/tools/sea_rules_check.gd
var fails: int = 0


func ok(c: bool, w: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", w])
	if not c:
		fails += 1


func _init() -> void:
	# the hand-made world (no lake): seaTop is 0 over its sea and nothing elsewhere, as `y < 0 and seaAt` was
	var S1 := SimCore.createSim()
	SimCore.newMatch(S1, 1, {}, {"intro": false})
	var seaOk: bool = true
	var landOk: bool = true
	var sea_x: float = -1.0
	for i in range(0, SimConst.NC, 7):
		var x: float = (float(i) + 0.5) * SimConst.COL
		var top: float = WorldWater.seaTop(S1, x)
		if WorldTerrain.seaAt(S1, x):
			if sea_x < 0.0:
				sea_x = x
			if top != 0.0:
				seaOk = false
		elif top != WorldWater.NO_SEA:
			landOk = false
	ok(seaOk and landOk and sea_x >= 0.0, "on a world without a lake seaTop is exactly 0 over the sea and NO_SEA elsewhere (so every line reads as it did)")
	var f1 = S1.fighters[0]
	f1.x = sea_x
	f1.y = -50.0
	var sp_in: float = SimFighter.flightSpeed(S1, f1, false)
	f1.y = 50.0
	var sp_out: float = SimFighter.flightSpeed(S1, f1, false)
	ok(absf(sp_in - 0.55 * sp_out) < 1.0e-9, "over the sea a fighter below 0 flies at 0.55 of his speed, above it at full (as before)")
	# a gen 2 lake at altitude
	var S2 := SimCore.createSim()
	SimCore.newMatch(S2, 1, {}, {"intro": false})
	var nc: int = SimConst.NC
	S2.base.fill(800.0)
	S2.deform.fill(0.0)
	for i in range(1000, 1101):
		S2.base[i] = 500.0
	WorldWater.init(S2)
	for i in range(1000, 1101):
		S2.water[i] = 300.0   # a lake: floor 500, surface 800
	var pc := PackedByteArray()
	pc.resize(nc)
	pc.fill(1)
	var fc := PackedByteArray()
	fc.resize(nc)
	fc.fill(WorldClimate.F_PLAINS)
	WorldBiomes.planetCols = pc
	WorldBiomes.fineCols = fc
	WorldBiomes.worldId = WorldBiomes.claim()
	S2.worldId = WorldBiomes.worldId
	var xl: float = 1050.5 * SimConst.COL
	ok(WorldTerrain.seaAt(S2, xl) and absf(WorldWater.seaTop(S2, xl) - 800.0) < 1.0e-6 and WorldWater.seaTop(S2, 500.5 * SimConst.COL) == WorldWater.NO_SEA, "a deep lake at altitude: seaTop is its surface (800), and dry land beside it has none")
	var f2 = S2.fighters[0]
	f2.x = xl
	f2.y = 750.0   # 50 below the lake's surface, 250 above its floor: absolute y is far above 0
	var lake_in: float = SimFighter.flightSpeed(S2, f2, false)
	f2.y = 850.0
	var lake_out: float = SimFighter.flightSpeed(S2, f2, false)
	ok(absf(lake_in - 0.55 * lake_out) < 1.0e-9, "a fighter below a lake's surface flies at 0.55 of his speed as in the sea, and above it at full")
	var pf: Dictionary = DirLaunch.predictFlight(S2, xl, 900.0, 0.0, -200.0, 1.0)
	ok(bool(pf.water), "a launch that falls into a deep lake is predicted to end in water, as one into the sea is")
	print("SEARULES: %d check(s) failed" % fails)
	quit()
