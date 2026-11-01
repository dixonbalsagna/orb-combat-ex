extends SceneTree
# Buildings at every place (World, sim/world/plan.gd layFree and freeLots, planet_world.gd settleFree; docs/world/places-everywhere.md): with plans.everywhere on, every place the first ring does not hold stands as the whole of
# its plan, planet-fixed; the first ring is laid exactly as it is with the switch off; the far places hold no people; each building is a pose of its planet point; each is in a lot; the same setup lays the same state twice.
#   godot --headless --path . --script res://sim/world/tools/everywhere_check.gd -- [--planet=7] [--touch=1]
var fails: int = 0


func ok(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		fails += 1
		print("  FAIL ", what)


func _match(planet: int, touch: int, on: bool) -> SimState:
	WorldClimate.useGen(3)
	WorldPlan.everywhereOverride = 1 if on else 0
	WorldPlanet.forget()
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {}, {"intro": false, "planet": planet, "touch": touch, "planetGen": 3})
	return S


func _init() -> void:
	var planet: int = 7
	var touch: int = 1
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--planet="):
			planet = int(a.substr(9))
		elif a.begins_with("--touch="):
			touch = int(a.substr(8))
	var off := _match(planet, touch, false)
	var n_off: int = off.buildings.size()
	var pop_off: float = off.world.pop0
	var on := _match(planet, touch, true)
	var P := WorldPlanet.make(planet)
	var nb: int = on.buildings.size()
	ok(nb > n_off * 5, "with everywhere on the planet holds %d buildings against %d on the first ring alone" % [nb, n_off])
	# the first ring is laid exactly as it is with the switch off
	var same: bool = true
	for i in range(n_off):
		var a = off.buildings[i]
		var b = on.buildings[i]
		if a.place != b.place or a.plan != b.plan or a.x != b.x or a.z != b.z or a.w != b.w or a.h != b.h or a.pop != b.pop or a.row != b.row or a.district != b.district:
			same = false
			break
	ok(same, "the first ring's %d buildings are the same, in the same slots, with the switch on" % n_off)
	ok(on.world.pop0 == pop_off, "S.world.pop0 is the first ring's (%d)" % int(pop_off))
	# the first ring's places stand whole too: their plan beyond the lanes is laid
	var held_whole: int = 0
	var held_n: int = 0
	var per_off: Dictionary = {}
	for i in range(n_off):
		per_off[off.buildings[i].place] = int(per_off.get(off.buildings[i].place, 0)) + 1
	var per_on: Dictionary = {}
	for i in range(nb):
		per_on[on.buildings[i].place] = int(per_on.get(on.buildings[i].place, 0)) + 1
	for pid in per_off:
		held_n += 1
		var geo_n: int = WorldPlan.geometry(P, pid, 0.0).b.size()
		if int(per_on[pid]) > int(per_off[pid]) and int(per_on[pid]) >= geo_n * 3 / 4:
			held_whole += 1
	ok(held_n > 0 and held_whole == held_n, "each of the first ring's %d places stands whole: %d have more than their lanes' buildings and three quarters of their plan" % [held_n, held_whole])
	# every place has buildings
	var per: Dictionary = {}
	for i in range(nb):
		var pid: int = on.buildings[i].place
		per[pid] = int(per.get(pid, 0)) + 1
	var missing: Array = []
	for pid in range(P.n):
		if not per.has(pid):
			missing.append(pid)
	ok(missing.size() <= P.n / 20, "%d of %d places have buildings (%d have none: %s; a place wholly in the sea has none)" % [P.n - missing.size(), P.n, missing.size(), str(missing.slice(0, 6))])
	# the far places hold no people; the lure buckets are the first ring's
	var far_pop: float = 0.0
	var popHist_same: bool = off.popHist.size() == on.popHist.size()
	for i in range(n_off, nb):
		far_pop += on.buildings[i].pop
	for i in range(mini(off.popHist.size(), on.popHist.size())):
		if off.popHist[i] != on.popHist[i]:
			popHist_same = false
	ok(far_pop == 0.0, "the far places hold no people")
	ok(popHist_same, "the lure buckets are the first ring's")
	# each far building stands at its planet point, inside the place's radius, and is a pose of that point
	var R: float = P.R
	var out_r: int = 0
	var off_pose: int = 0
	var nonunit: int = 0
	var bound: bool = on.bDir.size() == nb * 3
	ok(bound, "every building has its planet point (bDir: %d numbers)" % on.bDir.size())
	for i in range(n_off, nb):
		var b = on.buildings[i]
		var q: Array = [on.bDir[3 * i], on.bDir[3 * i + 1], on.bDir[3 * i + 2]]
		if absf(sqrt(q[0] * q[0] + q[1] * q[1] + q[2] * q[2]) - 1.0) > 1.0e-9:
			nonunit += 1
		var d: float = R * sqrt(pow(q[0] - P.px[b.place], 2) + pow(q[1] - P.py[b.place], 2) + pow(q[2] - P.pz[b.place], 2))
		if d > P.rad[b.place] * 1.5 + 2600.0:
			out_r += 1
		if on.bX.size() == nb:
			SimField.strip(on, q[0], q[1], q[2])
			if absf(SimWrap.sdx(on.bX[i], SimField.sx)) > 1.0 or absf(on.bZ[i] - SimField.sz) > 1.0:
				off_pose += 1
	ok(nonunit == 0, "every planet point is a unit direction")
	ok(out_r == 0, "every far building stands within its place's radius and the lanes' depth beyond it (%d outside)" % out_r)
	ok(on.bX.size() == nb and off_pose == 0, "every far building's pose is its planet point through the frame (%d off)" % off_pose)
	# every far building is inside a lot, and a building of a lot stands at the lot's height
	var lots: Array = []
	for r in on.fieldRecs:
		if r.k == "lot":
			lots.append(r)
	var no_lot: int = 0
	var spread_bad: int = 0
	for i in range(n_off, nb):
		var q2: Array = [on.bDir[3 * i], on.bDir[3 * i + 1], on.bDir[3 * i + 2]]
		var inside: bool = false
		for l in lots:
			var lx: float = (q2[0] - l.c[0]) * R
			var ly: float = (q2[1] - l.c[1]) * R
			var lz: float = (q2[2] - l.c[2]) * R
			if absf(lx * l.t[0] + ly * l.t[1] + lz * l.t[2]) <= l.hl + 0.5 and absf(lx * l.s[0] + ly * l.s[1] + lz * l.s[2]) <= l.hd + 0.5:
				inside = true
				break
		if not inside:
			no_lot += 1
		if i % 16 == 0 and inside:
			var g: float = WorldField.applyRecords(on, q2[0], q2[1], q2[2], WorldField.height(P, q2[0], q2[1], q2[2]))
			if g < WorldTerrain.TRIM_G:
				spread_bad += 1
	ok(no_lot == 0, "every far building is inside a lot (%d are not; %d lots in all)" % [no_lot, lots.size()])
	ok(spread_bad == 0, "no sampled far building stands in the sea (%d do)" % spread_bad)
	# the front limit (plans.indexFrontBH): the index holds no building whose front face is in front of the front limit, and loses none of the first ring's
	var lane_bottom: float = 1.0e30
	for l in WorldPlan._lanes():
		lane_bottom = minf(lane_bottom, float(l.bottom))
	ok(WorldPlan.indexBack(float(SimSwing.data().indexBand)) >= -lane_bottom, "the back limit (%.0f) reaches the farthest lane's edge (%.0f)" % [WorldPlan.indexBack(float(SimSwing.data().indexBand)), -lane_bottom])
	var indexed: Dictionary = {}
	for bk in on.bIdx:
		for ii in bk:
			indexed[int(ii)] = true
	var front_in: int = 0
	var front_out: int = 0
	var ring_lost: int = 0
	for i in range(nb):
		var zb: float = (float(on.bZ[i]) if on.bZ.size() == nb else float(on.buildings[i].z)) + 0.5 * float(on.buildings[i].d)   # the front face
		if i < n_off and not indexed.has(i):
			ring_lost += 1
		if zb > WorldPlan.indexFront() + 1.0e-6:
			if indexed.has(i):
				front_in += 1
			else:
				front_out += 1
	ok(front_in == 0, "no building with its front face past the front limit is in the index (%d are)" % front_in)
	ok(front_out > 0, "the limit is at work: %d far buildings in front of it are left out of the index" % front_out)
	ok(ring_lost == 0, "the first ring loses none of its buildings from the index (%d)" % ring_lost)
	# the footprint slope (plans.maxFootSlope): a free building on ground steeper than that between its centre and the circle round its footprint (a cliff) is not laid; every place laid again with no limit stands more
	var pr = on.planetRing
	var circ2: Dictionary = WorldRingPick.ringFrom(pr.c, int(pr.cols), pr.t)
	var n_lim: int = 0
	var n_all: int = 0
	var cliffed: int = 0
	WorldPlan.footSlopeOverride = -1.0
	var lim: float = WorldPlan.maxFootSlope()
	for pid in range(P.n):
		var gl: Dictionary = WorldPlan.layFree(on, P, pid, circ2)
		n_lim += gl.buildings.size()
		cliffed += int(gl.get("cliffed", 0))
	WorldPlan.footSlopeOverride = 0.0
	for pid in range(P.n):
		n_all += WorldPlan.layFree(on, P, pid, circ2).buildings.size()
	WorldPlan.footSlopeOverride = -1.0
	ok(lim > 0.0 and n_lim < n_all and n_all - n_lim == cliffed, "with the footprint slope at %.2f, %d of %d buildings are not laid (%d counted)" % [lim, n_all - n_lim, n_all, cliffed])
	# the same setup lays the same state
	var again := _match(planet, touch, true)
	ok(again.buildings.size() == nb and str(SimHash.stateHash(again).gameplay) == str(SimHash.stateHash(on).gameplay), "the same setup lays the same state twice")
	WorldPlan.everywhereOverride = -1
	print("EVERYWHERE: %d check(s) failed" % fails)
	quit(0 if fails == 0 else 1)
