extends SceneTree
# World's side of more than two bodies (scratch): a set-piece token a flight, the launcher by foe, the per-body lodge hold.
#   godot --headless --path . --script res://sim/world/tools/nbody_check.gd
var fails: int = 0


class TeamBody:
	var team: int = 0
	var launchBy = null
	var x: float = 0.0


func ok(c: bool, w: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", w])
	if not c:
		fails += 1


func fresh(seed: int = 1, bodies: int = 2) -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, seed, {}, {"intro": false})
	S.out.fx.clear()
	var order: Array = FighterData.order()
	for i in range(2, bodies):
		var nf = SimRoster.createFighter(FighterData.def(order[i % 2]), S.fighters[0].x + 300.0 * float(i), "p%d" % (i + 1), true)
		S.fighters.append(nf)
	return S


func fly(S: SimState, A, D, b, tier: float, force: float = 2000.0) -> Array:
	A.tier = tier
	D.hp = 1.0e9
	A.hp = 1.0e9
	D.x = SimWrap.wrap(b.x - 3000.0)
	D.y = WorldTerrain.groundY(S, D.x) + 100.0
	var plan = WorldBrunt.aim(S, A, D, b, force, 1.0 + A.ld.launch * (tier - 1.0), false)
	if plan == null:
		return []
	DirLaunch.doLaunch(S, A, D, plan, force)
	var ev: Array = []
	var g: int = 0
	while D.state == "launched" and g < 900:
		S.dirS.stop = 0.0
		SimFighter.stepLaunched(S, D, SimConst.DT)
		for e in S.out.fx:
			ev.append(e)
		S.out.fx.clear()
		g += 1
		if D.holdT > 0 and g > 30:
			break
	return ev


func _init() -> void:
	# ---- 1. the set-piece token per flight
	var S := fresh(1)
	S.fighters[0].tier = 4.0
	var w: SimState.World = S.world
	var tA: float = WorldCollateral.beginEvent(S, "chain", S.fighters[0])
	S.fighters[0].chainEvt = tA   # a token is held by the flight that opened it (a token nobody holds is closed by the next beginEvent)
	var tB: float = WorldCollateral.beginEvent(S, "chain", S.fighters[1])
	S.fighters[1].chainEvt = tB
	var tC: float = WorldCollateral.beginEvent(S, "slide", S.fighters[1])
	S.fighters[0].slideEvt = tC
	ok(tA != tB and tB != tC and tA == w.evtToken and w.evtMore.size() == 10, "three set pieces open at once keep their own slots (tokens %.0f %.0f %.0f, %d numbers beyond the first)" % [tA, tB, tC, w.evtMore.size()])
	var allow: float = WorldCollateral.EVENT_ALLOW["chain"][3] * w.pop0
	var bi: int = 0
	for i in range(S.buildings.size()):
		if S.buildings[i].popAlive >= 6.0:
			bi = i
			break
	# use up the window so that only an allowance can grant
	w.cbSum = WorldCollateral.budget(S)
	var g1: float = WorldCollateral.kill(S, bi, 3.0, S.fighters[0], tA, S.buildings[bi].x)
	var g2: float = WorldCollateral.kill(S, bi, 2.0, S.fighters[1], tB, S.buildings[bi].x)
	ok(g1 > 0.0 and g2 > 0.0, "each flight borrows from its own allowance when the window is spent (%.1f and %.1f of %.0f)" % [g1, g2, allow])
	var rA: Dictionary = WorldCollateral.endEvent(S, tA)
	var rB: Dictionary = WorldCollateral.endEvent(S, tB)
	ok(absf(rA.dead - g1) < 0.001 and absf(rB.dead - g2) < 0.001, "each token returns its own casualties (%.1f for the first, %.1f for the second)" % [rA.dead, rB.dead])
	var rC: Dictionary = WorldCollateral.endEvent(S, tC)
	ok(rC.dead == 0.0 and w.evtToken == 0.0 and w.evtMore.size() == 0, "the last token closes and nothing stays open")
	ok(WorldCollateral.endEvent(S, 999.0).dead == 0.0, "an unknown token returns zeros")
	# one set piece: exactly as before
	var S1 := fresh(1)
	var t1: float = WorldCollateral.beginEvent(S1, "chain", S1.fighters[0])
	S1.fighters[0].chainEvt = t1
	# a token that nobody holds any more is closed by the next one, as the old single slot overwrote it
	var tStale: float = WorldCollateral.beginEvent(S1, "slide", S1.fighters[1])
	ok(S1.world.evtToken == t1 and S1.world.evtMore.size() == 5, "a second set piece opens beside the first")
	S1.fighters[0].chainEvt = 0.0
	var tNew: float = WorldCollateral.beginEvent(S1, "chain", S1.fighters[1])
	ok(S1.world.evtToken == tNew and S1.world.evtMore.size() == 0, "when nobody holds the open ones they are closed and the new one takes the first slot (the old behaviour)")
	S1.fighters[0].chainEvt = 0.0
	S1 = fresh(1)
	t1 = WorldCollateral.beginEvent(S1, "chain", S1.fighters[0])
	ok(S1.world.evtToken == t1 and S1.world.evtMore.size() == 0 and S1.world.evtKind == "chain", "one set piece lives in the scalar slot, as before")

	# ---- 2. the launcher of a flight
	var S2 := fresh(1, 2)
	ok(WorldCollateral.launcherOf(S2, S2.fighters[0]) == S2.fighters[1] and WorldCollateral.launcherOf(S2, S2.fighters[1]) == S2.fighters[0], "with two bodies the launcher of one is the other (SimRoster.opp's answer)")
	var S4 := fresh(1, 4)
	S4.fighters[0].x = 1000.0
	S4.fighters[1].x = 5000.0
	S4.fighters[2].x = 1300.0
	S4.fighters[3].x = 9000.0
	ok(S4.fighters.size() == 4 and WorldCollateral.launcherOf(S4, S4.fighters[0]) == S4.fighters[2], "with four, the nearest foe: body 2 for body 0 (not 'the other of two')")
	S4.fighters[0].launchBy = S4.fighters[3]
	ok(WorldCollateral.launcherOf(S4, S4.fighters[0]) == S4.fighters[3], "launchBy wins when it is set")
	var a := TeamBody.new()
	var b2 := TeamBody.new()
	var c3 := TeamBody.new()
	b2.team = 1
	c3.team = 0
	ok(WorldCollateral.foes(S4, a, b2) and not WorldCollateral.foes(S4, a, c3) and not WorldCollateral.foes(S4, a, a), "foes by team when bodies have one, never a body to himself")

	# ---- 3. the lodge hold: a hit-stop with two bodies, a pin with more
	var lodgeOk: int = 0
	var lodgeN: int = 0
	var rg := SimRng.new(5)
	for mode in [2, 3]:
		var seenStop: bool = false
		var seenHold: bool = false
		var pinned_ok: bool = true
		var found: int = 0
		for n in range(80):
			var Sx := fresh(1 + n % 5, mode)
			var D = Sx.fighters[0]
			var pick = Sx.buildings[int(rg.next() * float(Sx.buildings.size()))]
			Sx.dirS.stop = 0.0
			var evx: Array = []
			var A = Sx.fighters[1]
			A.tier = 4.0
			D.hp = 1.0e9
			A.hp = 1.0e9
			D.x = SimWrap.wrap(pick.x - 3000.0)
			D.y = WorldTerrain.groundY(Sx, D.x) + 100.0
			var plan = WorldBrunt.aim(Sx, A, D, pick, 2000.0, 1.0 + A.ld.launch * 3.0, false)
			if plan == null:
				continue
			DirLaunch.doLaunch(Sx, A, D, plan, 2000.0)
			var g: int = 0
			var lodged: bool = false
			var stop_at_lodge: float = 0.0
			while D.state == "launched" and g < 900:
				Sx.dirS.stop = 0.0
				SimFighter.stepLaunched(Sx, D, SimConst.DT)
				for e in Sx.out.fx:
					if e.type == "lodge":
						lodged = true
						stop_at_lodge = Sx.dirS.stop
				Sx.out.fx.clear()
				g += 1
				if lodged:
					break
			if not lodged:
				continue
			found += 1
			if mode == 2:
				seenStop = seenStop or stop_at_lodge >= WorldBrunt.lodgeSeconds(4.0, false) - 0.001
				pinned_ok = pinned_ok and D.holdT == 0
			else:
				seenHold = seenHold or D.holdT > 0
				pinned_ok = pinned_ok and stop_at_lodge <= WorldBrunt.STOP_FIRST + 0.001 and D.holdT > 0   # (only the impact's own short stop, not the lodge's hold)
				# pinned: he stays put for the hold, then falls
				var x0: float = D.x
				var y0: float = D.y
				var held: int = D.holdT
				var moved: bool = false
				for k in range(held):
					SimFighter.stepLaunched(Sx, D, SimConst.DT)
					if absf(D.x - x0) > 0.001 or absf(D.y - y0) > 0.001:
						moved = true
				pinned_ok = pinned_ok and not moved
				SimFighter.stepLaunched(Sx, D, SimConst.DT)
				SimFighter.stepLaunched(Sx, D, SimConst.DT)
				pinned_ok = pinned_ok and (D.y < y0 or D.state != "launched")
			if found >= 6:
				break
		if mode == 2:
			ok(found > 0 and seenStop and pinned_ok, "two bodies: the lodge is a hit-stop of the whole sim and no pin (%d lodges)" % found)
		else:
			ok(found > 0 and seenHold and pinned_ok, "three bodies: the lodge pins only the body, the sim is not stopped, he stays put for the hold and then falls (%d lodges)" % found)
	print("NBODY: %d check(s) failed" % fails)
	quit()
