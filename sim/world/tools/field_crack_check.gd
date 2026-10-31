extends SceneTree
# Cracks as planet records (World, sim/world/store.gd KIND_CRACK, sim/world/crater.gd): a slide's paved path is a segment of the planet in the store; the strip's S.crack is written as ever; after the line turns
# layCracks gives the strip the crack where it really is, and none where it hung in the air. Needs the state's store fields (sim/core/state.gd).
#   godot --headless --path . --script res://sim/world/tools/field_crack_check.gd -- [--planet=7]
var fails: int = 0


func ok(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		fails += 1
		print("  FAIL ", what)


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
	var span: float = float(SimConst.NC) * SimConst.COL
	var xa: float = SimWrap.wrap(S.fighters[0].x + 400.0)
	var xb: float = SimWrap.wrap(xa + 480.0)
	ok(S.storeN == 0, "a new gen 3 state starts with an empty store")
	WorldCrater.carveSegment(S, xa, xb, 6.0, true, 0.8)
	ok(S.storeN == 2 and int(S.store[0]) == WorldStore.KIND_CRACK and int(S.store[WorldStore.STRIDE]) == WorldStore.KIND_TRENCH, "a paved slide is a crack record and a trench record in the store")
	var ca: int = int(xa / SimConst.COL) + 3
	ok(S.crack[ca] > 0.79, "and the strip's S.crack is written as ever (%.2f)" % S.crack[ca])
	var qm: Array = WorldPlan.pointAtX(P, circ, SimWrap.wrap(xa + 240.0), 0.0)
	ok(absf(WorldStore.crackAt(S, qm[0], qm[1], qm[2]) - 0.8) < 1.0e-6, "the store reads the crack's intensity on its path")
	var qside: Array = WorldPlan.pointAtX(P, circ, SimWrap.wrap(xa + 240.0), 120.0)
	ok(WorldStore.crackAt(S, qside[0], qside[1], qside[2]) == 0.0, "and nothing 120 units to the side of it")
	var qend: Array = WorldPlan.pointAtX(P, circ, SimWrap.wrap(xb + 500.0), 0.0)
	ok(WorldStore.crackAt(S, qend[0], qend[1], qend[2]) == 0.0, "and nothing past its end")
	# an unpaved slide leaves no crack record
	var n0: int = _cracks(S)
	WorldCrater.carveSegment(S, xb, SimWrap.wrap(xb + 200.0), 6.0, false, 0.8)
	ok(_cracks(S) == n0, "an unpaved slide adds no crack (it still cuts its trench)")
	# the line turns: a ring through the crack's middle at 50 degrees
	var c: Array = qm
	var e: Array = WorldPlanet._unit(WorldPlanet._cross([0.0, 1.0, 0.0], c))
	var nn: Array = WorldPlanet._cross(c, e)
	var t0: Array = ringTangentOf(circ, c)
	var ang: float = 0.8727
	var tv: Array = [t0[0] * SimDetMath.cos(ang) + WorldPlanet._cross(c, t0)[0] * SimDetMath.sin(ang), t0[1] * SimDetMath.cos(ang) + WorldPlanet._cross(c, t0)[1] * SimDetMath.sin(ang), t0[2] * SimDetMath.cos(ang) + WorldPlanet._cross(c, t0)[2] * SimDetMath.sin(ang)]
	var nrm: Array = WorldPlanet._unit(WorldPlanet._cross(c, tv))
	var circ2: Dictionary = WorldPlanet.ringThrough(WorldPlanet.circleOf(c, nrm), SimConst.NC, 1)
	var pointOf2 := func(x: float) -> Array:
		return WorldPlan.pointAtX(P, circ2, x, 0.0)
	var cracked: int = WorldStore.layCracks(S, pointOf2)
	var mid2: int = int(float(SimConst.NC / 2))   # the touch column of the new ring is the crack's middle
	ok(S.crack[mid2] > 0.79 and cracked > 0, "after the turn the crack is under the new line where it was made (%d columns, middle column %.2f)" % [cracked, S.crack[mid2]])
	ok(S.crack[ca] < 0.01 or absf(SimWrap.sdx(float(ca) * SimConst.COL, float(mid2) * SimConst.COL)) < 600.0, "and the old line's columns no longer carry it in the air")
	# the same cracks make the same hash
	var S2 := SimCore.createSim()
	SimCore.newMatch(S2, 1, {}, {"planet": planet, "touch": 1, "arena": {"cols": 2400}, "planetGen": 3, "intro": false})
	for t in range(10):
		SimCore.step(S2)
	WorldCrater.carveSegment(S2, xa, xb, 6.0, true, 0.8)
	WorldCrater.carveSegment(S2, xb, SimWrap.wrap(xb + 200.0), 6.0, false, 0.8)
	ok(S2.storeHash == S.storeHash and S2.storeN == S.storeN, "the same slides make the same store hash")
	# gen 2: never
	var G := SimCore.createSim()
	SimCore.newMatch(G, 1, {}, {"planet": planet, "touch": 1, "arena": {"cols": 2400}, "planetGen": 2, "intro": false})
	WorldCrater.carveSegment(G, 1000.0, 1300.0, 6.0, true, 0.8)
	ok(G.storeN == 0, "a gen 2 slide never touches the store")
	print("FIELDCRACK: %d check(s) failed" % fails)
	quit(0 if fails == 0 else 1)


func ringTangentOf(circ: Dictionary, q: Array) -> Array:
	return WorldPlan.ringTangent(circ, q)


func _cracks(S) -> int:
	var n: int = 0
	for k in range(int(S.storeN)):
		if int(S.store[k * WorldStore.STRIDE]) == WorldStore.KIND_CRACK:
			n += 1
	return n
