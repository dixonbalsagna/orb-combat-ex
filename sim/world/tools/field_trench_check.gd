extends SceneTree
# A slide's trench as a planet record (World, sim/world/store.gd KIND_TRENCH, crater.gd carveSegment): the groove along the path is a record; the ground is the lower of it and the craters; with a frame the strip's
# groove is not dug. Needs the state's store fields.
#   godot --headless --path . --script res://sim/world/tools/field_trench_check.gd -- [--planet=7]
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
	WorldClimate.useGen(3)
	WorldPlanet.forget()
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {}, {"planet": planet, "touch": 1, "arena": {"cols": 2400}, "planetGen": 3, "intro": false})
	for t in range(10):
		SimCore.step(S)
	var P := WorldPlanet.make(planet)
	var circ: Dictionary = WorldRingPick.ringFrom(S.planetRing.c, int(S.planetRing.cols), S.planetRing.t)
	var xa: float = SimWrap.wrap(S.fighters[0].x + 500.0)
	var xb: float = SimWrap.wrap(xa + 600.0)
	var before: float = _sum(S, xa + 300.0, 500.0)
	WorldCrater.carveSegment(S, xa, xb, 9.0, false, 0.0)
	ok(S.storeN == 1 and int(S.store[0]) == WorldStore.KIND_TRENCH, "a slide's groove is a trench record")
	ok(_sum(S, xa + 300.0, 500.0) > before + 1.0, "with no frame the strip's groove is dug as ever")
	var qm: Array = WorldPlan.pointAtX(P, circ, SimWrap.wrap(xa + 300.0), 0.0)
	var tr: float = WorldStore.trenchAt(S, qm[0], qm[1], qm[2])
	ok(tr <= -8.0 and tr >= -9.0 - 1.0e-6, "the store reads the target depth on the path (%.2f of 9; the path is the chord of the ring's arc, a few units off the line)" % tr)
	ok(WorldStore.heightDelta(S, qm[0], qm[1], qm[2]) == tr, "and the ground delta is the groove")
	var qs: Array = WorldPlan.pointAtX(P, circ, SimWrap.wrap(xa + 300.0), 200.0)
	ok(WorldStore.trenchAt(S, qs[0], qs[1], qs[2]) == 0.0, "nothing 200 units to the side")
	WorldCrater.carveSegment(S, xa, xb, 9.0, false, 0.0)
	ok(WorldStore.heightDelta(S, qm[0], qm[1], qm[2]) >= -9.0 - 1.0e-6 and WorldStore.heightDelta(S, qm[0], qm[1], qm[2]) == tr, "crossed again, a trench is no deeper than its target")
	_realFrame(S)
	var xc: float = SimWrap.wrap(xb + 900.0)
	var b2: float = _sum(S, xc + 300.0, 500.0)
	WorldCrater.carveSegment(S, xc, SimWrap.wrap(xc + 600.0), 9.0, false, 0.0)
	ok(absf(_sum(S, xc + 300.0, 500.0) - b2) < 1.0e-6, "with a frame the strip's groove is not dug (the store's trench is the ground)")
	S.frame = null
	var G := SimCore.createSim()
	SimCore.newMatch(G, 1, {}, {"planet": planet, "touch": 1, "arena": {"cols": 2400}, "planetGen": 2, "intro": false})
	WorldCrater.carveSegment(G, 1000.0, 1300.0, 9.0, true, 0.8)
	ok(G.storeN == 0, "a gen 2 slide never touches the store")
	print("FIELDTRENCH: %d check(s) failed" % fails)
	quit(0 if fails == 0 else 1)


## A great circle through the store's first point: Simulation's frame, as a match on a whole ring has one (a stand-in object has none of its fields).
func _realFrame(S: SimState) -> void:
	var p: Array = [S.store[1], S.store[2], S.store[3]]   # [kind, px, py, pz, ...]
	var e: Array = [1.0, 0.0, 0.0] if absf(p[0]) < 0.7 else [0.0, 1.0, 0.0]
	var d: float = e[0] * p[0] + e[1] * p[1] + e[2] * p[2]
	var t: Array = [e[0] - d * p[0], e[1] - d * p[1], e[2] - d * p[2]]
	var n: float = sqrt(t[0] * t[0] + t[1] * t[1] + t[2] * t[2])
	SimField.begin(S, int(S.planetRing.seed), p, [t[0] / n, t[1] / n, t[2] / n], S.fighters[0].x)
