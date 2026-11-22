extends SceneTree
## A knock-back that aims at a wall (docs/world/ring-any-angle/game-design.md section 15), staged on a field world: off, it never
## aims; on, a standing building inside the knock's own distance on his side takes him; one past it, or behind him, doesn't. A
## tier-1 body never goes through a tower.
##   godot --headless --path . --script res://sim/director/tools/knock_wall_check.gd
## Ends on the verdict line.

var failed: int = 0


func _init() -> void:
	_rows()
	_cone()
	_visit()
	DirLaunch.setWallForce(-1)
	DirVisit.setForce(-1)
	print("KNOCK WALL: %d check(s) failed" % failed)
	quit(1 if failed > 0 else 0)


func _expect(ok: bool, what: String) -> void:
	print(("ok    " if ok else "FAIL  ") + what)
	if not ok:
		failed += 1


func _start() -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 11, {"p1": false, "p2": false}, {"planet": 7, "touch": 2, "planetGen": 3, "intro": false})
	S.out.fx.clear()
	return S


## The standing building nearest the fighters' start, by depth first, so its face is close to the plane: one of the index, as a knock aims
## (DirLaunch._wall reads WorldStructures.near; a building toward the camera past plans.indexFrontBH is not in it: World's everywhere_check rows).
func _front(S: SimState) -> int:
	var best: int = -1
	var bd: float = 1.0e18
	for i in WorldStructures.near(S, S.fighters[0].x, 3000.0):
		var b = S.buildings[i]
		if not b.alive or WorldSettle.noTarget(b.landmark):
			continue
		var fz: float = absf(WorldBrunt.faceZ(b))
		var d: float = fz * 100.0 + absf(SimWrap.sdx(S.fighters[0].x, b.x)) * 0.001
		if d < bd:
			bd = d
			best = i
	return best


## The wall a knock from A on D should aim at, as World's everywhere_check reads it: the indexed buildings ahead of him inside the knock's reach
## and its depth window, nearest along the line first, the first of up to three that a flight reaches (DirLaunch._wallPlan); -1 with none.
func _firstWall(S: SimState, A, D) -> int:
	var wd: Dictionary = DirLaunch.data().knockBack.wall
	var reach: float = minf(float(wd.reach), float(DirLaunch.data().knockBack.distBh[3]) * DirLaunch.BH * float(wd.distMul))
	var s: float = SimMathx.jsign(SimWrap.sdx(A.x, D.x))
	var cands: Array = []
	for bi in WorldStructures.near(S, D.x, reach):
		var q = S.buildings[bi]
		if not q.alive or WorldSettle.noTarget(q.landmark):
			continue
		var dx: float = SimWrap.sdx(D.x, q.x)
		var gap: float = absf(dx) - q.w * 0.5
		var dz: float = float(q.z) - float(D.z)
		if dx * s > 0.0 and gap > 0.0 and gap <= reach and dz <= WorldBrunt.BR_Z_FRONT and -dz <= WorldBrunt.BR_Z_BACK and D.y <= WorldStructures.baseY(S, q) + WorldStructures.curH(q):
			var wa: PackedFloat64Array = DirLaunch._wallAt(D, q, s, DirLaunch._lineSlope(A, D))
			if DirLaunch._inCone(wd, wa):   # (Game Design, buildings.md section 10: inside the blow's cone, nearest by true distance)
				cands.append([wa[2] if String(wd.get("wallBy", "line")) == "trueDistance" else gap, bi, gap])
	cands.sort()
	for ci in range(mini(cands.size(), 3)):
		if DirLaunch._wallPlan(S, A, D, s, wd, S.buildings[int(cands[ci][1])], float(cands[ci][2])) != null:
			return int(cands[ci][1])
	return -1


## Game Design's QA row (buildings.md section 10): knocks staged along the street, beside each indexed building near the start in turn,
## each aim measured against the blow's line: none more than wallCone off it. Negative control: the cone off and the order along the line
## (today's rule) aims some far off it, into the background.
func _coneRun(cone: float, by: String) -> Array:
	var wd: Dictionary = DirLaunch.data().knockBack.wall
	var keep: Array = [wd.get("wallCone", 0.0), wd.get("wallBy", "line")]
	wd["wallCone"] = cone
	wd["wallBy"] = by
	DirLaunch.setWallForce(1)
	var S := _start()
	var ids: Array = WorldStructures.near(S, S.fighters[0].x, 6000.0)
	SimCore.dispose(S)
	var aims: int = 0
	var wide: int = 0
	var worst: float = 0.0
	var k: int = 0
	for bi in ids:
		if k >= 24:
			break
		S = _start()
		var b = S.buildings[bi]
		if not b.alive or WorldSettle.noTarget(b.landmark):
			SimCore.dispose(S)
			continue
		k += 1
		_place(S, bi, 300.0, 1.0, false)
		var A = S.fighters[0]
		var D = S.fighters[1]
		A.tier = 4.0
		var tx: float = D.x
		var tz: float = D.z
		var s: float = SimMathx.jsign(SimWrap.sdx(A.x, D.x))
		DirLaunch.knock(S, A, D)
		if int(D.aimB) >= 0:
			aims += 1
			var q = S.buildings[int(D.aimB)]
			var along: float = SimWrap.sdx(tx, q.x) * s - q.w * 0.5
			var off: float = maxf(0.0, absf(float(q.z) - tz) - float(q.d) * 0.5)
			var deg: float = atan2(off, maxf(along, 0.001)) * 180.0 / PI
			worst = maxf(worst, deg)
			if deg > 20.01:
				wide += 1
		SimCore.dispose(S)
	wd["wallCone"] = keep[0]
	wd["wallBy"] = keep[1]
	return [k, aims, wide, worst]


func _cone() -> void:
	var on: Array = _coneRun(20.0, "trueDistance")
	var off: Array = _coneRun(0.0, "line")
	print("      knocks staged beside %d buildings: with the cone %d aimed, %d more than 20 degrees off the line (worst %.1f); today's rule %d aimed, %d more than 20 off (worst %.1f)" % [on[0], on[1], on[2], on[3], off[1], off[2], off[3]])
	_expect(on[1] > 0 and on[2] == 0, "the cone: knocks aimed at a wall more than 20 degrees off the blow's line, 0 (Game Design's QA row; %d aimed)" % on[1])
	_expect(off[2] > 0, "negative control, today's rule (no cone, along the line): some aim more than 20 degrees off (%d)" % off[2])


## The "in reach" staging: [building, gap from its near side, the rule's wall there, its face's depth, buildings tried]; building -1 when none
## near the start has a wall inside the cone that a tier-4 flight reaches. The row's own building first, then the index near the start.
func _inReach(first: int, reach: float, cone: float) -> Array:
	var S := _start()
	var ids: Array = [first]
	for bi in WorldStructures.near(S, S.fighters[0].x, 6000.0):
		if not ids.has(bi):
			ids.append(bi)
	SimCore.dispose(S)
	var tried: int = 0
	for bi in ids:
		if tried >= 24:
			break
		S = _start()
		var b = S.buildings[bi]
		if not b.alive or WorldSettle.noTarget(b.landmark):
			SimCore.dispose(S)
			continue
		tried += 1
		var fz: float = absf(WorldBrunt.faceZ(b))
		var gap: float = maxf(80.0, fz / tan(cone) + 20.0) if cone > 0.0 else 80.0
		if gap > reach:
			SimCore.dispose(S)
			continue
		_place(S, bi, gap, 1.0, false)
		S.fighters[0].tier = 4.0
		var want: int = _firstWall(S, S.fighters[0], S.fighters[1])
		SimCore.dispose(S)
		if want >= 0:
			return [bi, gap, want, fz, tried]
	return [-1, 0.0, -1, 0.0, tried]


## Puts the target `gap` from the building's near side, with the attacker behind him, side -1 or 1 the way he'd go.
func _place(S: SimState, i: int, gap: float, side: float, behind: bool = false) -> void:
	var b = S.buildings[i]
	var A = S.fighters[0]
	var D = S.fighters[1]
	D.x = SimWrap.wrap(b.x - side * (b.w * 0.5 + gap))
	D.y = WorldTerrain.groundY(S, D.x)
	D.z = 0.0
	A.x = SimWrap.wrap(D.x + (side * 58.0 if behind else -side * 58.0))
	A.y = D.y
	A.z = 0.0
	A.face = -side if behind else side
	A.tier = 1.0


func _rows() -> void:
	var S := _start()
	var i: int = _front(S)
	var fz: float = absf(WorldBrunt.faceZ(S.buildings[i]))
	var reach: float = float(DirLaunch.data().knockBack.distBh[3]) * DirLaunch.BH
	SimCore.dispose(S)
	print("      the building: %d, its face %.0f off the plane; a tier-4 knock's reach %.0f" % [i, fz, reach])
	# The "in reach" rows (the GW1b review's B-18): staged where a wall is inside the cone and a tier-4 flight reaches it, the indexed
	# buildings near the start tried in turn (Game Design's cone: a building fz deep is aimed at only from fz / tan(cone) along). None
	# found fails the row: it never passes with no wall to aim at.
	var cone: float = float(DirLaunch.data().knockBack.wall.get("wallCone", 0.0)) * PI / 180.0
	var st: Array = _inReach(i, reach, cone)
	if int(st[0]) >= 0:
		print("      in reach, inside the cone: building %d (its face %.0f off the plane), %.0f from its near side; the rule's wall %d (%d tried)" % [int(st[0]), float(st[3]), float(st[1]), int(st[2]), int(st[4])])
	else:
		_expect(false, "in reach: no wall inside the cone that a tier-4 flight reaches, among %d indexed buildings near the start: the rows can't be staged" % int(st[4]))
	for row in [["off, in reach", 0, float(st[1]), false, false, int(st[0])], ["on, in reach", 1, float(st[1]), false, true, int(st[0])], ["on, past its reach", 1, 1800.0, false, false, i], ["on, 1,200 away at tier 4", 1, 1200.0, false, true, i], ["on, behind him", 1, 80.0, true, false, i]]:
		if int(row[5]) < 0:
			continue
		DirLaunch.setWallForce(int(row[1]))
		S = _start()
		_place(S, int(row[5]), float(row[2]), 1.0, bool(row[3]))
		var A = S.fighters[0]
		var D = S.fighters[1]
		A.tier = 4.0
		var want: int = _firstWall(S, A, D)
		DirLaunch.knock(S, A, D)
		var aim0: int = int(D.aimB)   # read now: the flight clears it when it ends
		var aimed: bool = aim0 == int(row[5]) if String(row[0]) != "on, 1,200 away at tier 4" else aim0 >= 0   # at that range a nearer wall may take him
		if String(row[0]) == "off, in reach":
			aimed = aim0 >= 0   # off: no wall at all
		if String(row[0]) == "on, in reach":
			aimed = want >= 0 and aim0 == want   # (the nearest indexed wall by true distance inside the cone that a flight reaches; the staging guarantees one)
			print("      on, in reach: the rule's wall %d, aimed at %d" % [want, aim0])
		var hit: int = 0
		var guard: int = 0
		while D.state == "launched" and guard < 600:
			S.dirS.stop = 0.0
			SimFighter.stepLaunched(S, D, SimConst.DT)
			for e in S.out.fx:
				if e.type == "building_hit":
					hit += 1
			S.out.fx.clear()
			guard += 1
		_expect(aimed == bool(row[4]), "%s: aimed %s" % [row[0], str(aimed)])
		if bool(row[4]) and aim0 >= 0:
			_expect(hit > 0, "%s: the wall takes him (%d)" % [row[0], hit])
		SimCore.dispose(S)
	# a tier-1 body meets a tower and stays out of it
	DirLaunch.setWallForce(1)
	var outcome: String = ""
	for pl in [7, 3, 11, 13]:
		for tc in [2, 0, 1, 3]:
			if outcome != "":
				break
			S = SimCore.createSim()
			SimCore.newMatch(S, 11, {"p1": false, "p2": false}, {"planet": pl, "touch": tc, "planetGen": 3, "intro": false})
			S.out.fx.clear()
			var tower: int = -1
			for k in range(S.buildings.size()):
				var b = S.buildings[k]
				if b.alive and b.kind == "tower" and absf(WorldBrunt.faceZ(b)) < 200.0 and not WorldSettle.noTarget(b.landmark):
					tower = k
					break
			if tower >= 0:
				_place(S, tower, 60.0, 1.0)
				var D = S.fighters[1]
				DirLaunch.knock(S, S.fighters[0], D)
				var guard: int = 0
				while D.state == "launched" and guard < 600:
					S.dirS.stop = 0.0
					SimFighter.stepLaunched(S, D, SimConst.DT)
					for e in S.out.fx:
						if e.type == "building_hit" and outcome == "":
							outcome = String(e.outcome)
					S.out.fx.clear()
					guard += 1
			SimCore.dispose(S)
	_expect(outcome != "" and outcome != "punch", "tier 1 on a tower: not through it (%s)" % outcome)


## A town's a visit: off, no slot and no cost; on, leaving an unused town costs and landing in it doesn't; after 2 sends it's the
## other way round; a place on the line is a candidate, and its solved carry lands near it.
func _visit() -> void:
	var S := _start()
	var A = S.fighters[0]
	var D = S.fighters[1]
	var i: int = _front(S)
	var bx: float = S.buildings[i].x
	D.x = SimWrap.wrap(bx - 800.0)
	D.y = WorldTerrain.groundY(S, D.x) + 80.0
	A.x = SimWrap.wrap(D.x - 58.0)
	A.y = D.y
	A.face = 1.0
	var v: Dictionary = DirVisit.cfg()
	var town: bool = DirVisit.inTown(D)
	var away: float = 0.0
	for k in range(1, 40):
		var x: float = SimWrap.wrap(D.x + float(k) * 3000.0)
		if not DirVisit._built(S, x):
			away = x
			break
	DirVisit.setForce(0)
	var n0: int = A.act.dirI.size()
	DirVisit.sent(S)
	_expect(A.act.dirI.size() == n0 and DirVisit.cost(S, D, away) == 0.0, "visit off: no slot, no cost")
	DirVisit.setForce(1)
	print("      in town by biome: %s" % str(town))
	if town:
		_expect(DirVisit.cost(S, D, away) == -float(v.leave), "an unused town: leaving costs")
		_expect(DirVisit.cost(S, D, bx) == 0.0, "landing in it doesn't")
		for _k in range(int(v.sends)):
			DirVisit.sent(S)
		_expect(DirVisit.cost(S, D, away) == 0.0, "after its sends, leaving costs nothing")
		_expect(DirVisit.cost(S, D, bx) == -float(v.mark), "and it's marked down")
	SimCore.dispose(S)
	# a place on the line
	S = _start()
	A = S.fighters[0]
	D = S.fighters[1]
	A.tier = 4.0
	var P = DirSwing._planet(S)
	var found: int = 0
	var best: float = -1.0
	var bestErr: float = 0.0
	for pl in DirSwing.places(S, P, DirSwing._frame(S, D.x), 25600.0):
		if float(pl.d) < float(v.minD):
			continue
		var fr = S.frame.copy()
		SimSwing._applyTurn(fr, float(D.x), float(pl.phi))
		var was = S.frame
		DirSwing._planOn(S, fr, float(D.x))
		A.face = 1.0
		var r: Dictionary = DirLaunch.chooseLaunch(S, A, D, 3000.0)
		for k in r.all:
			if k.has("arrive") and int(k.arrive) == int(pl.id):
				found += 1
				var err: float = absf(float(k.travel) - float(pl.d)) / float(pl.d)
				bestErr = maxf(bestErr, err)
				best = float(pl.d)
		DirSwing._planOff(S)
		S.out.fx.clear()
		S.out.feed.clear()
		_expect(S.frame == was, "the frame is back")
	_expect(found > 0, "a built place on the line is a candidate (%d)" % found)
	print("      worst carry against the place: %.1f%% (last place %.0f away)" % [bestErr * 100.0, best])
	SimCore.dispose(S)
