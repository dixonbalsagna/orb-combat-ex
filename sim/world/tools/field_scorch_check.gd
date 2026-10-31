extends SceneTree
# Scorch as planet records (World, sim/world/store.gd KIND_SCORCH, sim/world/crater.gd): a beam sample is a burn and a groove at a planet point; a sample a recent one covers is not added; the groove is never
# deeper than its target however often a beam crosses it; under a frame the strip's groove is not dug (the store holds it); after the line turns layScorch puts the burn where it was made. Needs the state's store fields.
#   godot --headless --path . --script res://sim/world/tools/field_scorch_check.gd -- [--planet=7]
var fails: int = 0


func ok(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		fails += 1
		print("  FAIL ", what)


func _sum(S: SimState, x: float, half: float) -> float:
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
	WorldClimate.useGen(3)
	WorldPlanet.forget()
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {}, {"planet": planet, "touch": 1, "arena": {"cols": 2400}, "planetGen": 3, "intro": false})
	for t in range(10):
		SimCore.step(S)
	var P := WorldPlanet.make(planet)
	var circ: Dictionary = WorldRingPick.ringFrom(S.planetRing.c, int(S.planetRing.cols), S.planetRing.t)
	var f = S.fighters[0]
	var x: float = SimWrap.wrap(f.x + 700.0)
	var before: float = _sum(S, x, 400.0)
	WorldCrater.scorch(S, x, 3.0, "plain", f, 0.0)
	ok(S.storeN == 1 and int(S.store[0]) == WorldStore.KIND_SCORCH, "a beam sample is a scorch record")
	ok(_sum(S, x, 400.0) > before + 0.5 and S.scorch[int(x / SimConst.COL)] > 0.3, "with no frame the strip's groove and burn are written as ever")
	for k in range(5):
		WorldCrater.scorch(S, x, 3.0, "plain", f, 0.0)
	ok(S.storeN == 1, "the same sample again, five times, adds no record")
	WorldCrater.scorch(S, SimWrap.wrap(x + 200.0), 3.0, "plain", f, 0.0)
	ok(S.storeN == 2, "a sample 200 units on is a record")
	var q: Array = WorldPlan.pointAtX(P, circ, x, 0.0)
	var sc: Array = WorldStore.scorchAt(S, q[0], q[1], q[2])
	var hw: float = (WorldCrater.SCORCH_HW0 + WorldCrater.SCORCH_HW_P * 3.0)
	var depth: float = (WorldCrater.SCORCH_D0 + WorldCrater.SCORCH_D_P * 3.0)
	ok(absf(float(sc[1]) + depth) < 1.0e-6 and float(sc[0]) > 0.3, "the store reads the burn and the groove's target depth at the sample (%.2f, %.2f)" % [sc[0], sc[1]])
	var hd: float = WorldStore.heightDelta(S, q[0], q[1], q[2])
	ok(absf(hd + depth) < 1.0e-6, "and the ground delta is the groove, never deeper however often it is crossed (%.2f)" % hd)
	var qfar: Array = WorldPlan.pointAtX(P, circ, x, hw * 1.5)
	ok(WorldStore.scorchAt(S, qfar[0], qfar[1], qfar[2])[0] == 0.0, "nothing beyond its half width")
	# a frame on the state: the groove is the store's
	_realFrame(S)
	var x2: float = SimWrap.wrap(x + 1500.0)
	var b2: float = _sum(S, x2, 400.0)
	WorldCrater.scorch(S, x2, 3.0, "plain", f, 0.0)
	ok(absf(_sum(S, x2, 400.0) - b2) < 1.0e-6 and S.scorch[int(x2 / SimConst.COL)] > 0.3, "with a frame the strip's groove is not dug, and the burn is still written")
	S.frame = null
	# the line turns
	var t0: Array = WorldPlan.ringTangent(circ, q)
	var ang: float = 0.9
	var cr: Array = WorldPlanet._cross(q, t0)
	var tv: Array = [t0[0] * SimDetMath.cos(ang) + cr[0] * SimDetMath.sin(ang), t0[1] * SimDetMath.cos(ang) + cr[1] * SimDetMath.sin(ang), t0[2] * SimDetMath.cos(ang) + cr[2] * SimDetMath.sin(ang)]
	var circ2: Dictionary = WorldPlanet.ringThrough(WorldPlanet.circleOf(q, WorldPlanet._unit(WorldPlanet._cross(q, tv))), SimConst.NC, 1)
	var n: int = WorldStore.layScorch(S, func(xx: float) -> Array: return WorldPlan.pointAtX(P, circ2, xx, 0.0))
	ok(n > 0 and S.scorch[SimConst.NC / 2] > 0.3, "after the turn the burn is under the new line where it was made (%d columns)" % n)
	var S2 := SimCore.createSim()
	SimCore.newMatch(S2, 1, {}, {"planet": planet, "touch": 1, "arena": {"cols": 2400}, "planetGen": 3, "intro": false})
	for t in range(10):
		SimCore.step(S2)
	WorldCrater.scorch(S2, x, 3.0, "plain", S2.fighters[0], 0.0)
	for k in range(5):
		WorldCrater.scorch(S2, x, 3.0, "plain", S2.fighters[0], 0.0)
	WorldCrater.scorch(S2, SimWrap.wrap(x + 200.0), 3.0, "plain", S2.fighters[0], 0.0)
	_realFrame(S2)
	WorldCrater.scorch(S2, x2, 3.0, "plain", S2.fighters[0], 0.0)
	ok(S2.storeHash == S.storeHash and S2.storeN == S.storeN, "the same beam makes the same store hash")
	var G := SimCore.createSim()
	SimCore.newMatch(G, 1, {}, {"planet": planet, "touch": 1, "arena": {"cols": 2400}, "planetGen": 2, "intro": false})
	WorldCrater.scorch(G, 1000.0, 3.0, "plain", G.fighters[0], 0.0)
	ok(G.storeN == 0, "a gen 2 beam never touches the store")
	print("FIELDSCORCH: %d check(s) failed" % fails)
	quit(0 if fails == 0 else 1)


## A great circle through the store's first point: Simulation's frame, as a match on a whole ring has one (a stand-in object has none of its fields).
func _realFrame(S: SimState) -> void:
	var p: Array = [S.store[1], S.store[2], S.store[3]]   # [kind, px, py, pz, ...]
	var e: Array = [1.0, 0.0, 0.0] if absf(p[0]) < 0.7 else [0.0, 1.0, 0.0]
	var d: float = e[0] * p[0] + e[1] * p[1] + e[2] * p[2]
	var t: Array = [e[0] - d * p[0], e[1] - d * p[1], e[2] - d * p[2]]
	var n: float = sqrt(t[0] * t[0] + t[1] * t[1] + t[2] * t[2])
	SimField.begin(S, int(S.planetRing.seed), p, [t[0] / n, t[1] / n, t[2] / n], S.fighters[0].x)
