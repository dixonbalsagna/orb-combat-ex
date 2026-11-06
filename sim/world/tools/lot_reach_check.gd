extends SceneTree
# A lot answers only near itself (World, sim/world/field.gd applyRecords, docs/world/lot-reach.md): a lot's flat is a footprint on its street's plane, and the tests along and across the street say nothing of the distance
# off that plane, so a big lot also answered in a tube through the planet (Simulation: on planet 11 it raised the ground to its own height at points 28,000 to 49,000 units from its centre). Each lot is read alone, with the
# record index out of the way (a lot is handed to the state by itself and then by a record list that lists it for every point): nothing it does beyond its own reach (its half diagonal, its blends, and what the sphere's curve
# adds) changes the ground; a very big lot (a 17,000-unit half diagonal, past the index's coarse grid) too.
#   godot --headless --path . --script res://sim/world/tools/lot_reach_check.gd -- [--planet=11] [--touch=1]
var fails: int = 0
var R: float = SimConst.PLANET_NC * SimConst.COL / (2.0 * SimMathx.PI)


func ok(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		fails += 1
		print("  FAIL ", what)


## Read one lot against points from beside it to the far side of the planet; returns [points read, points beyond its reach where it changed the ground, the farthest such chord].
func _probe(probe: SimState, lot: Dictionary) -> Array:
	probe.fieldRecs = [lot]
	var c: Array = lot.c
	var t: Array = lot.t
	var s: Array = lot.s
	var reach: float = float(lot.r) + float(lot.blend) + float(lot.get("bs", lot.blend))
	var quarter: float = SimMathx.f64("3fe921fb54442d18")
	var n: int = 0
	var acting: int = 0
	var worst: float = 0.0
	for ang in [0.3, 0.6, 1.0, 1.5, 2.0, 2.5, 3.0, 3.14]:   # the angle round the planet from the lot's centre, to the far side
		for psi in range(8):
			var az: float = quarter * float(psi)
			var d0: float = SimDetMath.cos(az)
			var d1: float = SimDetMath.sin(az)
			var q: Array = []
			for k in range(3):
				q.append(float(c[k]) * SimDetMath.cos(float(ang)) + (d0 * float(t[k]) + d1 * float(s[k])) * SimDetMath.sin(float(ang)))
			var dx: float = (float(q[0]) - float(c[0])) * R
			var dy: float = (float(q[1]) - float(c[1])) * R
			var dz: float = (float(q[2]) - float(c[2])) * R
			var chord: float = sqrt(dx * dx + dy * dy + dz * dz)
			var out: float = WorldField.applyRecords(probe, q[0], q[1], q[2], 5000.0)
			n += 1
			if chord > 1.3 * reach + 400.0 and absf(out - 5000.0) > 1.0e-6:
				acting += 1
				worst = maxf(worst, chord)
	return [n, acting, worst]


func _init() -> void:
	var planet: int = 11
	var touch: int = 1
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--planet="):
			planet = int(a.substr(9))
		elif a.begins_with("--touch="):
			touch = int(a.substr(8))
	WorldClimate.useGen(3)
	WorldPlan.everywhereOverride = 1
	WorldPlanet.forget()
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {}, {"intro": false, "planet": planet, "touch": touch, "planetGen": 3})
	var lots: Array = []
	for rec in S.fieldRecs:
		if String(rec.k) == "lot":
			lots.append(rec)
	ok(lots.size() > 20, "planet %d has %d lots" % [planet, lots.size()])
	var probe := SimCore.createSim()
	var tested: int = 0
	var acting: int = 0
	var worst: float = 0.0
	var near_missing: int = 0
	var step: int = maxi(lots.size() / 60, 1)
	for li in range(0, lots.size(), step):
		var r: Array = _probe(probe, lots[li])
		tested += int(r[0])
		acting += int(r[1])
		worst = maxf(worst, float(r[2]))
		probe.fieldRecs = [lots[li]]
		if absf(WorldField.applyRecords(probe, lots[li].c[0], lots[li].c[1], lots[li].c[2], 5000.0) - 5000.0) < 1.0e-6:
			near_missing += 1
	ok(tested > 1000, "%d points read against single lots, from beside them to the far side of the planet" % tested)
	ok(acting == 0, "no lot of the planet changes the ground beyond its reach (%d points did, to %.0f units)" % [acting, worst])
	ok(near_missing == 0, "every lot still sets the ground at its own centre (%d did not)" % near_missing)
	# a very big lot (past the index's coarse grid): a 12,000-unit half width and length, the same street, listed for every point
	var big: Dictionary = lots[0].duplicate(true)
	big["hl"] = 12000.0
	big["hd"] = 12000.0
	big["r"] = sqrt(2.0) * 12000.0
	var rb: Array = _probe(probe, big)
	ok(int(rb[1]) == 0, "a very big lot does not answer in a tube through the planet either (%d of %d points did, to %.0f units)" % [int(rb[1]), int(rb[0]), float(rb[2])])
	probe.fieldRecs = [big]
	ok(absf(WorldField.applyRecords(probe, big.c[0], big.c[1], big.c[2], 5000.0) - 5000.0) > 1.0e-6, "and it still sets the ground at its own centre")
	print("LOTREACH: %d check(s) failed" % fails)
	quit(0 if fails == 0 else 1)
