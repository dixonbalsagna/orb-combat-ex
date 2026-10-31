extends SceneTree
# A crater is a record at a planet point on gen 3 (World, sim/world/crater.gd with sim/world/store.gd): dug on a gen 3 state it joins the store; with Simulation's frame on the state the strip's S.deform is not written
# (the ground is the field plus the store); a gen 2 state never touches the store. Needs the state's store fields (sim/core/state.gd).
#   godot --headless --path . --script res://sim/world/tools/field_crater_check.gd -- [--planet=7]
var fails: int = 0


## A great circle through the store's first point: Simulation's frame, as a match on a whole ring has one.
func _realFrame(S: SimState) -> void:
	var p: Array = [S.store[0], S.store[1], S.store[2]]
	var e: Array = [1.0, 0.0, 0.0] if absf(p[0]) < 0.7 else [0.0, 1.0, 0.0]
	var d: float = e[0] * p[0] + e[1] * p[1] + e[2] * p[2]
	var t: Array = [e[0] - d * p[0], e[1] - d * p[1], e[2] - d * p[2]]
	var n: float = sqrt(t[0] * t[0] + t[1] * t[1] + t[2] * t[2])
	SimField.begin(S, int(S.planetRing.seed), p, [t[0] / n, t[1] / n, t[2] / n], S.fighters[0].x)


func ok(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		fails += 1
		print("  FAIL ", what)


func _deform_sum(S: SimState, x: float, half: float) -> float:
	var s: float = 0.0
	var c0: int = int(x / SimConst.COL)
	var n: int = int(half / SimConst.COL)
	for k in range(-n, n + 1):
		s += absf(S.deform[((c0 + k) % SimConst.NC + SimConst.NC) % SimConst.NC])
	return s


func _init() -> void:
	var planet: int = 7
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--planet="):
			planet = int(a.substr(9))
	ok("store" in SimState.new() and "frame" in SimState.new(), "the state has the store's fields and a frame")
	# gen 3, no frame: the crater is dug on the strip as ever and recorded in the store
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {}, {"planet": planet, "touch": 1, "arena": {"cols": 2400}, "planetGen": 3, "intro": false})
	for t in range(20):
		SimCore.step(S)
	ok(S.storeN == 0, "a new gen 3 state starts with an empty store")
	var f = S.fighters[0]
	var x: float = SimWrap.wrap(f.x + 600.0)
	var before: float = _deform_sum(S, x, 500.0)
	var rec = WorldCrater.dig(S, x, 8.0, f, "impact")
	ok(rec != null, "a crater is dug")
	ok(S.storeN == 1 and S.store.size() == WorldStore.STRIDE and S.storeHash != 0, "it is in the store (%d record, hash %d)" % [S.storeN, S.storeHash])
	ok(_deform_sum(S, x, 500.0) > before + 1.0, "with no frame the strip's deform is written as ever")
	# the record is at the planet point of the strip x
	var pr = S.planetRing
	var P := WorldPlanet.make(planet)
	var circ: Dictionary = WorldRingPick.ringFrom(pr.c, int(pr.cols), pr.t)
	var q: Array = [S.store[0], S.store[1], S.store[2]]
	var xs: float = WorldPlan.stripX(P, circ, q)
	ok(absf(WorldPlan.sdx(xs, x, float(SimConst.NC) * SimConst.COL)) < 1.0, "its planet point is the strip x again (%.2f units out)" % absf(WorldPlan.sdx(xs, x, float(SimConst.NC) * SimConst.COL)))
	ok(absf(WorldStore.heightDelta(S, q[0], q[1], q[2]) + rec.depth) < 1.0e-6, "the store reads the bowl's depth at its centre (%.3f)" % WorldStore.heightDelta(S, q[0], q[1], q[2]))
	# with a frame on the state the strip's deform is not written
	_realFrame(S)
	var x2: float = SimWrap.wrap(x + 1500.0)
	var before2: float = _deform_sum(S, x2, 700.0)
	var rec2 = WorldCrater.dig(S, x2, 8.0, f, "impact")
	ok(rec2 != null and S.storeN == 2, "a second crater joins the store")
	ok(absf(_deform_sum(S, x2, 700.0) - before2) < 1.0e-6, "with a frame the strip's deform is not written (the store holds the bowl)")
	ok(S.craters.size() >= 2, "the crater record (events, repeats) is still kept")
	S.frame = null
	# the same hash twice
	var S2 := SimCore.createSim()
	SimCore.newMatch(S2, 1, {}, {"planet": planet, "touch": 1, "arena": {"cols": 2400}, "planetGen": 3, "intro": false})
	for t in range(20):
		SimCore.step(S2)
	WorldCrater.dig(S2, x, 8.0, S2.fighters[0], "impact")
	_realFrame(S2)
	WorldCrater.dig(S2, x2, 8.0, S2.fighters[0], "impact")
	ok(S2.storeHash == S.storeHash and S2.storeN == S.storeN, "the same digs make the same store hash")
	# gen 2: the store is never touched
	var G := SimCore.createSim()
	SimCore.newMatch(G, 1, {}, {"planet": planet, "touch": 1, "arena": {"cols": 2400}, "planetGen": 2, "intro": false})
	for t in range(20):
		SimCore.step(G)
	var gx: float = SimWrap.wrap(G.fighters[0].x + 600.0)
	var gb: float = _deform_sum(G, gx, 500.0)
	WorldCrater.dig(G, gx, 8.0, G.fighters[0], "impact")
	ok(G.storeN == 0 and G.store.size() == 0 and _deform_sum(G, gx, 500.0) > gb + 1.0, "a gen 2 crater writes the strip and never the store")
	print("field_crater_check: %d check(s) failed" % fails)
	quit(0 if fails == 0 else 1)
