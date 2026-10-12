extends SceneTree
# a demo start at a crossing: the pair stands astride a crossing in downtown; the default start is unchanged; the match plays on
var fails: int = 0


func ok(c: bool, w: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", w])
	if not c:
		fails += 1


func _init() -> void:
	var S0 := SimCore.createSim()
	SimCore.newMatch(S0, 3, {}, {"intro": false})
	ok(S0.fighters[0].x == SimConst.START_X and S0.fighters[1].x == SimConst.START_X + SimConst.START_GAP, "the default start is START_X (%.0f) and the gap as before" % S0.fighters[0].x)
	var S := SimCore.createSim()
	SimCore.newMatch(S, 3, {}, {"intro": false, "start": "crossing"})
	var mid: float = (S.fighters[0].x + S.fighters[1].x) * 0.5
	var c: Array = WorldLanes.crossingNear(S, mid, 0.0, 200.0)
	ok(c.size() == 3, "a crossing lies within 200 units of the pair's middle (x %.0f, crossing %s)" % [mid, str(c)])
	ok(absf(S.fighters[1].x - S.fighters[0].x - SimConst.START_GAP) < 0.01, "the gap between them is START_GAP (%.0f)" % (S.fighters[1].x - S.fighters[0].x))
	var near_b: float = 1.0e30
	for b in S.buildings:
		near_b = minf(near_b, absf(SimWrap.sdx(mid, b.x)) - b.w * 0.5)
	print("  nearest building edge to the pair's middle: %.0f units" % near_b)
	var falls: int = 0
	var t: int = 0
	while t < 3600 and S.game.ko == null:
		SimCore.step(S, null)
		t += 1
	for ev in S.out.fx:
		pass
	print("  ran %d ticks, ko %s, tick %d" % [t, str(S.game.ko != null), S.tick])
	var gone: int = 0
	for b in S.buildings:
		if not b.alive:
			gone += 1
	print("  buildings gone after %d ticks: %d of %d" % [t, gone, S.buildings.size()])
	for f in S.fighters:
		ok(not is_nan(f.x) and not is_nan(f.y), "no NaN in a fighter's position")
	print("DEMOSTART: %d check(s) failed" % fails)
	quit()
