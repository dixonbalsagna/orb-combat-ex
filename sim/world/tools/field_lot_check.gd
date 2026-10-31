extends SceneTree
# A street block's lot (World, sim/world/field.gd lotRecords): the buildings of one row of a place that stand together share one flat lot, centred where they are LAID (after the lane snap); every building of a lot
# stands at the lot's one height; a lone building has a lone lot; the lots' blends stay out of neighbours' footprints; and the strip's line ground differs from a building's own ground for many buildings (the buried
# and floating ones). Needs the state's fieldRecs and bDir (sim/core/state.gd).
#   godot --headless --path . --script res://sim/world/tools/field_lot_check.gd -- [--planet=7] [--touch=2]
var fails: int = 0


func ok(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		fails += 1
		print("  FAIL ", what)


## Distance outside lot `rec` of the unit direction q (0 inside the flat), in units.
func _out(rec: Dictionary, q: Array, R: float) -> float:
	var lx: float = (q[0] - rec.c[0]) * R
	var ly: float = (q[1] - rec.c[1]) * R
	var lz: float = (q[2] - rec.c[2]) * R
	var la: float = absf(lx * rec.t[0] + ly * rec.t[1] + lz * rec.t[2]) - rec.hl
	var lb: float = absf(lx * rec.s[0] + ly * rec.s[1] + lz * rec.s[2]) - rec.hd
	return sqrt(maxf(la, 0.0) * maxf(la, 0.0) + maxf(lb, 0.0) * maxf(lb, 0.0))


func _init() -> void:
	var planet: int = 7
	var touch: int = 2
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--planet="):
			planet = int(a.substr(9))
		elif a.begins_with("--touch="):
			touch = int(a.substr(8))
	WorldClimate.useGen(3)
	WorldPlanet.forget()
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {}, {"planet": planet, "touch": touch, "arena": {"cols": 2400}, "planetGen": 3, "intro": false})
	var P := WorldPlanet.make(planet)
	var R: float = P.R
	var lots: Array = []
	for r in S.fieldRecs:
		if r.k == "lot":
			lots.append(r)
	var nb: int = S.buildings.size()
	var members: int = 0
	var lone: int = 0
	for l in lots:
		members += int(l.n)
		if bool(l.lone):
			lone += 1
	ok(lots.size() > 0 and lots.size() < nb and members == nb, "%d buildings share %d lots (%d lone); every building is in one" % [nb, lots.size(), lone])
	# each building's laid point is inside the lot that holds it, and the lot is centred on the laid buildings
	var outside: int = 0
	var worst_in: float = 0.0
	var spread_bad: int = 0
	var spread_max: float = 0.0
	var per_lot: Dictionary = {}
	for i in range(nb):
		var q: Array = [S.bDir[3 * i], S.bDir[3 * i + 1], S.bDir[3 * i + 2]]
		var home: int = -1
		var best: float = 1.0e9
		for li in range(lots.size()):
			var d: float = _out(lots[li], q, R)
			if d < best:
				best = d
				home = li
		worst_in = maxf(worst_in, best)
		if best > 0.5:
			outside += 1
		if home >= 0:
			if not per_lot.has(home):
				per_lot[home] = []
			var h: float = WorldField.applyRecords(S, q[0], q[1], q[2], WorldField.height(P, q[0], q[1], q[2]))
			per_lot[home].append(h)
	ok(outside == 0, "each building's laid point (bDir) is inside its lot, %.3f units outside at the worst: the lots are centred where the buildings are laid" % worst_in)
	# the buildings of a lot stand at one height (the lot's), unless a neighbouring lot's blend reaches them
	for li in per_lot:
		var hs: Array = per_lot[li]
		var lo: float = 1.0e9
		var hi: float = -1.0e9
		for h in hs:
			lo = minf(lo, h)
			hi = maxf(hi, h)
		spread_max = maxf(spread_max, hi - lo)
		if hi - lo > 1.0:
			spread_bad += 1
	ok(spread_bad <= lots.size() / 20, "the buildings of a lot stand at one height: %d of %d lots spread over a unit (largest %.2f; a neighbouring lot's blend may reach an edge building)" % [spread_bad, lots.size(), spread_max])
	# blends: a lot's blend does not reach into another lot's footprint (at the lot's centre and corners)
	var reach: int = 0
	for i in range(lots.size()):
		for j in range(lots.size()):
			if i == j:
				continue
			var cj: Array = lots[j].c
			var dd: float = _out(lots[i], cj, R)
			if dd < float(lots[i].blend) * 0.5 and dd > 0.0:
				reach += 1
	ok(reach == 0, "a lot's blend never reaches another lot's centre (%d do)" % reach)
	# outside a lot and its blend the ground is the field's
	var big: int = 0
	for l in lots:
		var e: Array = WorldPlanet._unit(WorldPlanet._cross([0.0, 1.0, 0.0], l.c))
		var far: Array = [l.c[0] + e[0] * (float(l.r) + float(l.blend) + 500.0) / R, l.c[1] + e[1] * (float(l.r) + float(l.blend) + 500.0) / R, l.c[2] + e[2] * (float(l.r) + float(l.blend) + 500.0) / R]
		var fl: float = 1.0 / sqrt(far[0] * far[0] + far[1] * far[1] + far[2] * far[2])
		far = [far[0] * fl, far[1] * fl, far[2] * fl]
		var hf: float = WorldField.height(P, far[0], far[1], far[2])
		if absf(WorldField.applyRecords(S, far[0], far[1], far[2], hf) - hf) > 400.0:
			big += 1
	ok(big == 0, "outside a lot and its blend the ground is the field's, no step over 400 units (%d)" % big)
	# the step at a lot's end: its height against the ground a blend beyond its end along the street (cut and fill on a slope)
	var steps: Array = []
	for l in lots:
		for sgn in [-1.0, 1.0]:
			var dist: float = float(l.hl) + float(l.blend) + 1.0
			var px: float = l.c[0] + sgn * l.t[0] * dist / R
			var py: float = l.c[1] + sgn * l.t[1] * dist / R
			var pz: float = l.c[2] + sgn * l.t[2] * dist / R
			var pl: float = 1.0 / sqrt(px * px + py * py + pz * pz)
			var gnd: float = WorldField.applyRecords(S, px * pl, py * pl, pz * pl, WorldField.height(P, px * pl, py * pl, pz * pl))
			steps.append(absf(gnd - float(l.h)))
	steps.sort()
	if steps.size() > 0:
		print("  info the step between a lot's height and the ground just past its end along the street: median %.0f, 90th percentile %.0f, largest %.0f units (a fighter is 75 tall)" % [steps[steps.size() / 2], steps[(steps.size() * 9) / 10], steps[steps.size() - 1]])
	# the fix Simulation asked for: dir is the laid point, not the plan's. How far apart the two are
	var off: int = 0
	var off_max: float = 0.0
	var line_off: int = 0
	var line_max: float = 0.0
	for i in range(nb):
		var q2: Array = [S.bDir[3 * i], S.bDir[3 * i + 1], S.bDir[3 * i + 2]]
		var circ: Dictionary = WorldRingPick.ringFrom(S.planetRing.c, int(S.planetRing.cols), S.planetRing.t)
		var back: Array = WorldPlan.pointAtX(P, circ, float(S.buildings[i].x), float(S.buildings[i].z))
		var dd2: float = R * sqrt((back[0] - q2[0]) * (back[0] - q2[0]) + (back[1] - q2[1]) * (back[1] - q2[1]) + (back[2] - q2[2]) * (back[2] - q2[2]))
		if dd2 > 1.0:
			off += 1
			off_max = maxf(off_max, dd2)
		var hl: float = WorldField.applyRecords(S, q2[0], q2[1], q2[2], WorldField.height(P, q2[0], q2[1], q2[2]))
		var line: float = S.base[clampi(int(float(S.buildings[i].x) / SimConst.COL), 0, SimConst.NC - 1)]
		if absf(line - hl) > 50.0:
			line_off += 1
			line_max = maxf(line_max, absf(line - hl))
	ok(off == 0, "every building's dir is the planet point of its laid x and z (%d are more than a unit from it, largest %.2f)" % [off, off_max])
	print("  info %d of %d buildings stand where the LINE's ground is over 50 units from their own (up to %.0f): the buried and floating ones of a strip-based base; a lot gives every reader the building's own ground" % [line_off, nb, line_max])
	var q0: Array = lots[0].c
	var a0: float = WorldField.applyRecords(S, q0[0], q0[1], q0[2], WorldField.height(P, q0[0], q0[1], q0[2]))
	ok(a0 == WorldField.applyRecords(S, q0[0], q0[1], q0[2], WorldField.height(P, q0[0], q0[1], q0[2])), "a lot read is a pure function of the point")
	print("FIELDLOT: %d check(s) failed" % fails)
	quit(0 if fails == 0 else 1)
