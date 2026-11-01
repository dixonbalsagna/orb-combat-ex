extends SceneTree
## A knock-back that aims at a wall (docs/world/ring-any-angle/game-design.md section 15), staged on a field world: off, it never
## aims; on, a standing building inside the knock's own distance on his side takes him; one past it, or behind him, doesn't. A
## tier-1 body never goes through a tower.
##   godot --headless --path . --script res://sim/director/tools/knock_wall_check.gd
## Ends on the verdict line.

var failed: int = 0


func _init() -> void:
	_rows()
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


## The standing building nearest the fighters' start, by depth first, so its face is close to the plane.
func _front(S: SimState) -> int:
	var best: int = -1
	var bd: float = 1.0e18
	for i in range(S.buildings.size()):
		var b = S.buildings[i]
		if not b.alive or WorldSettle.noTarget(b.landmark):
			continue
		var fz: float = absf(WorldBrunt.faceZ(b))
		var d: float = fz * 100.0 + absf(SimWrap.sdx(S.fighters[0].x, b.x)) * 0.001
		if d < bd:
			bd = d
			best = i
	return best


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
	for row in [["off, in reach", 0, 80.0, false, false], ["on, in reach", 1, 80.0, false, true], ["on, past its reach", 1, 1800.0, false, false], ["on, 1,200 away at tier 4", 1, 1200.0, false, true], ["on, behind him", 1, 80.0, true, false]]:
		DirLaunch.setWallForce(int(row[1]))
		S = _start()
		_place(S, i, float(row[2]), 1.0, bool(row[3]))
		var A = S.fighters[0]
		var D = S.fighters[1]
		A.tier = 4.0
		DirLaunch.knock(S, A, D)
		var aimed: bool = int(D.aimB) == i if String(row[0]) != "on, 1,200 away at tier 4" else int(D.aimB) >= 0   # at that range a nearer wall may take him
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
		if bool(row[4]):
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
