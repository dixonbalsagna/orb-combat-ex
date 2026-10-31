extends SceneTree
# Towns by plan (World, sim/world/plan.gd): the same town on rings of different bearing has the same buildings at the same planet points; every building stands in a lane, no two of a row overlap, the people add up,
# and a gen 3 match with plans on runs and is deterministic.
#   godot --headless --path . --script res://sim/world/tools/field_plan_check.gd -- [--planet=7]
var fails: int = 0


func ok(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		fails += 1
		print("  FAIL ", what)


## A great circle through the place's centre at `ang` radians from east, as the arena's ring of 2,400 columns, touching down at the centre.
func _ring(P: WorldPlanet.Planet, id: int, ang: float) -> Dictionary:
	var c: Array = [P.px[id], P.py[id], P.pz[id]]
	var e: Array = WorldPlanet._unit(WorldPlanet._cross([0.0, 1.0, 0.0], c))
	var n0: Array = WorldPlanet._cross(c, e)
	var t: Array = [SimDetMath.cos(ang) * e[0] + SimDetMath.sin(ang) * n0[0], SimDetMath.cos(ang) * e[1] + SimDetMath.sin(ang) * n0[1], SimDetMath.cos(ang) * e[2] + SimDetMath.sin(ang) * n0[2]]
	var nrm: Array = WorldPlanet._unit(WorldPlanet._cross(c, t))
	var circ: Dictionary = WorldPlanet.circleOf(c, nrm)
	return WorldPlanet.ringThrough(circ, SimConst.NC, 1)


func _init() -> void:
	var planet: int = 7
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--planet="):
			planet = int(a.substr(9))
	WorldClimate.useGen(3)
	WorldPlan.alignOverride = 0   # the keyed yaw for the identity and lane checks; the match-level counts below use the data's
	var P := WorldPlanet.make(planet)
	SimConst.setArena(2400)
	var NC: int = SimConst.NC
	ok(WorldPlan.enabled(), "plans are on in field.json")
	var city: int = -1
	var town: int = -1
	for i in range(P.n):
		if int(P.kind[i]) == WorldPlanet.KIND_CITY and city < 0:
			city = i
		if int(P.kind[i]) == WorldPlanet.KIND_TOWN and town < 0:
			town = i
	var S := SimState.new()
	S.base.resize(NC)
	S.base.fill(WorldTerrain.SETTLE_FLOOR + 1.0)
	var yaw_ok: bool = true
	for id in [city, town]:
		var y: float = WorldPlan.yawOf(P, id)
		yaw_ok = yaw_ok and y >= 0.0 and y < SimMathx.PI and WorldPlan.yawOf(P, id) == y
	ok(yaw_ok, "a place's street axis is keyed and in a half turn")
	for id in [city, town]:
		var geo: Dictionary = WorldPlan.geometry(P, id, 0.0)
		ok(geo.b.size() > 0, "place %d (%s): a plan of %d buildings in %d districts" % [id, "city" if id == city else "town", geo.b.size(), geo.dist.size()])
		ok(WorldPlan.geometry(P, id, 0.0) == geo, "the plan is memoised")
		var sets: Array = []
		var angs: Array = [0.0, 0.2618, 0.5236, 1.5708]
		for ang in angs:
			var circ: Dictionary = _ring(P, id, WorldPlan.yawOf(P, id) + ang)
			var g: Dictionary = WorldPlan.lay(S, P, id, circ, 0.2)
			sets.append(g)
			if g.is_empty():
				print("  info place %d at %.0f degrees to its street: too few stand, the chord layout would be used" % [id, ang * 57.2958])
				continue
			var rows_ok: bool = true
			var overlap: bool = false
			var pop: int = 0
			var span: float = float(NC) * SimConst.COL
			var lanes: Array = WorldPlan._lanes()
			for i in range(g.buildings.size()):
				var b: Dictionary = g.buildings[i]
				pop += int(b.pop)
				var inlane: bool = false
				for l in lanes:
					if int(l.row) == int(b.row) and float(b.z) <= float(l.top) + 1.0 and float(b.z) >= float(l.bottom) - 1.0:
						inlane = true
				rows_ok = rows_ok and inlane
				for j in range(i):
					var o: Dictionary = g.buildings[j]
					if int(o.row) == int(b.row) and absf(WorldPlan.sdx(float(o.x), float(b.x), span)) < (float(o.w) + float(b.w)) * 0.5 - 1.0e-6:
						overlap = true
			ok(rows_ok and not overlap, "  %.0f degrees to the street: %d buildings stand, each in its lane, none overlapping" % [ang * 57.2958, g.buildings.size()])
			ok(pop == int(round(0.2 * float(WorldSettle.data().pop0))), "  %.0f degrees: the people add up (%d)" % [ang * 57.2958, pop])
		# identity across bearings: a plan index seen on two rings is the same building at the same planet point
		var same: int = 0
		var differ: int = 0
		for a in range(sets.size()):
			for b2 in range(a + 1, sets.size()):
				if sets[a].is_empty() or sets[b2].is_empty():
					continue
				var by: Dictionary = {}
				for bb in sets[a].buildings:
					by[int(bb.pi)] = bb
				for bb in sets[b2].buildings:
					if by.has(int(bb.pi)):
						var o: Dictionary = by[int(bb.pi)]
						if o.pdir == bb.pdir and o.w == bb.w and o.h == bb.h and o.kind == bb.kind and o.seed == bb.seed:
							same += 1
						else:
							differ += 1
		ok(differ == 0, "place %d: %d buildings seen on two rings are identical, %d differ" % [id, same, differ])
	# depth sign: on a ring that runs along a place's street, a building stands at the sign of its plan depth (sim z positive toward the camera, away from the ring's centre)
	var geo0: Dictionary = WorldPlan.geometry(P, city)
	var circ0: Dictionary = _ring(P, city, WorldPlan.yawOf(P, city))
	var g0: Dictionary = WorldPlan.lay(S, P, city, circ0, 0.2)
	var agree: int = 0
	var flipped: int = 0
	for b0 in g0.get("buildings", []):
		var zp: float = float(geo0.b[int(b0.pi)].z)
		if zp * float(b0.z) > 0.0:
			agree += 1
		else:
			flipped += 1
	ok(agree > 0 and flipped == 0, "aligned with the street, %d buildings keep the sign of their plan depth, %d flipped (sim z is toward the camera)" % [agree, flipped])
	WorldPlan.alignOverride = -1
	# what plans do to the count on real matches: buildings standing with plans on and off
	for sp in [[7, 1], [7, 2], [3, 1], [3, 2], [11, 1], [25, 1]]:
		var cnt: Array = []
		for on in [0, 1, 2]:
			WorldPlan.overrideOn = 1 if on > 0 else 0
			WorldPlan.alignOverride = 0 if on == 1 else -1
			WorldPlanet.forget()
			var M2 := SimCore.createSim()
			SimCore.newMatch(M2, 1, {}, {"planet": sp[0], "touch": sp[1], "arena": {"cols": 2400}, "planetGen": 3, "intro": false})
			var pp: int = 0
			for b in M2.buildings:
				pp += int(b.pop)
			cnt.append([M2.buildings.size(), pp])
		print("  info planet %d touch %d: chord layout %d buildings, by plan keyed yaw %d, by plan turned to the ring %d (people %d, %d, %d)" % [sp[0], sp[1], cnt[0][0], cnt[1][0], cnt[2][0], cnt[0][1], cnt[1][1], cnt[2][1]])
	WorldPlan.overrideOn = -1
	WorldPlan.alignOverride = -1
	# a match with plans on, twice
	var hashes: Array = []
	var counts: Array = []
	for k in range(2):
		WorldPlanet.forget()
		var M := SimCore.createSim()
		SimCore.newMatch(M, 1, {}, {"planet": planet, "touch": 1, "arena": {"cols": 2400}, "planetGen": 3, "intro": false})
		for t in range(120):
			SimCore.step(M)
		hashes.append(str(SimHash.stateHash(M).gameplay))
		counts.append(M.buildings.size())
	ok(hashes[0] == hashes[1], "a gen 3 match with plans, 120 ticks, is one state twice (%s, %d buildings)" % [hashes[0], counts[0]])
	WorldField.refineOverride = -1
	print("FIELDPLAN: %d check(s) failed" % fails)
	quit(0 if fails == 0 else 1)
