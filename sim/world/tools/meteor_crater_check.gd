extends SceneTree
# The meteor's crater (World, sim/world/crater.gd dig's meteor argument, data/biomes/craters.json meteor; docs/world/meteor-crater.md): the same landing energy digs an ordinary bowl (capped at 8 bh) or, with
# meteor on, a bowl of its own size from the data; the size is data; the ground follows the bowl; nothing else about the dig changes.
#   godot --headless --path . --script res://sim/world/tools/meteor_crater_check.gd -- [--planet=7] [--touch=1]
var fails: int = 0


func ok(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		fails += 1
		print("  FAIL ", what)


func _match(planet: int, touch: int) -> SimState:
	WorldClimate.useGen(3)
	WorldPlanet.forget()
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {}, {"intro": false, "planet": planet, "touch": touch, "planetGen": 3})
	for i in range(30):
		SimCore.step(S)
	return S


func _init() -> void:
	var planet: int = 7
	var touch: int = 1
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--planet="):
			planet = int(a.substr(9))
		elif a.begins_with("--touch="):
			touch = int(a.substr(8))
	var E: float = WorldCrater.impactEnergy(8570.0, 4.0)
	var want_r: float = minf(WorldCraters.meteorRMax(), WorldCrater.R_BASE * sqrt(E * WorldCraters.meteorEMult()))
	ok(is_equal_approx(WorldCraters.meteorEMult(), 9.0) and is_equal_approx(WorldCraters.meteorRMax(), 6100.0), "the data's first values: eMult 9, rMax 6,100")
	ok(want_r > 5500.0 and want_r < 6100.0, "a tier-4 landing at 8,570 units a second (E %.1f) wants a bowl of %.0f" % [E, want_r])
	# an ordinary dig of the same energy is capped at 8 bh
	var S := _match(planet, touch)
	var x: float = S.fighters[0].x
	var ord = WorldCrater.dig(S, x, E, S.fighters[0], "impact", 0.0, 1.0, false)
	ok(ord != null and absf(ord.r - WorldCrater.ORD_R_MAX) < 0.5, "an ordinary dig of that energy is held to 8 bh (%.0f)" % (ord.r if ord != null else -1.0))
	# the meteor's
	S = _match(planet, touch)
	x = S.fighters[0].x
	var n0: int = S.craters.size()
	var g0: float = WorldTerrain.groundY(S, x)
	var far0: float = WorldTerrain.groundY(S, x + 2.2 * want_r)
	var met = WorldCrater.dig(S, x, E, S.fighters[0], "impact", 0.0, 1.0, false, NAN, PackedFloat64Array(), true)
	ok(met != null and absf(met.r - want_r) < 0.5, "the meteor's bowl is %.0f wide in radius (%.0f)" % [want_r, met.r if met != null else -1.0])
	ok(met != null and absf(met.depth - WorldCrater.DEPTH_RATIO * want_r) < 1.0, "its depth is the bowl's ratio (%.0f of %.0f)" % [met.depth if met != null else -1.0, WorldCrater.DEPTH_RATIO * want_r])
	ok(S.craters.size() == n0 + 1 and met.cause == "impact", "one crater record, an impact")
	var g1: float = WorldTerrain.groundY(S, x)
	ok(g1 < g0 - 0.8 * met.depth, "the ground at its centre is lower by the depth (%.0f to %.0f)" % [g0, g1])
	var far1: float = WorldTerrain.groundY(S, x + 2.2 * want_r)
	ok(absf(far1 - far0) < 0.5, "past its apron (2.2 radii) the ground is as it was (%.1f to %.1f)" % [far0, far1])
	var steps_ok: bool = true
	for i in range(60):
		SimCore.step(S)
	ok(steps_ok and is_finite(S.fighters[0].x) and is_finite(S.fighters[0].y), "the match steps on over it (60 ticks, fighters finite)")
	# the size is data
	var d: Dictionary = WorldCraters.data()
	var keep: Dictionary = d.get("meteor", {}).duplicate()
	d["meteor"] = {"eMult": 9.0, "rMax": 3000.0}
	var S2 := _match(planet, touch)
	var small = WorldCrater.dig(S2, S2.fighters[0].x, E, S2.fighters[0], "impact", 0.0, 1.0, false, NAN, PackedFloat64Array(), true)
	ok(small != null and absf(small.r - 3000.0) < 0.5, "lowering rMax lowers the bowl (%.0f)" % (small.r if small != null else -1.0))
	d["meteor"] = keep
	# the default is the ordinary dig, byte for byte: the same call without the argument, twice, gives the same record
	var S3 := _match(planet, touch)
	var a3 = WorldCrater.dig(S3, S3.fighters[0].x, 9.0, S3.fighters[0], "impact", 0.0, 1.0, true)
	var S4 := _match(planet, touch)
	var a4 = WorldCrater.dig(S4, S4.fighters[0].x, 9.0, S4.fighters[0], "impact", 0.0, 1.0, true, NAN, PackedFloat64Array(), false)
	ok(a3 != null and a4 != null and a3.r == a4.r and a3.depth == a4.depth and a3.rim == a4.rim, "meteor off is the old dig (special r %.0f both ways)" % (a3.r if a3 != null else -1.0))
	print("METEORCRATER: %d check(s) failed" % fails)
	quit(0 if fails == 0 else 1)
