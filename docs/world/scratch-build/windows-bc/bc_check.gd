extends SceneTree
# The wall slam, the lodge event, breaches (B) and the failing state (C): docs/world/destruction-windows-bc.md
#   godot --headless --path . --script res://sim/world/tools/bc_check.gd
var fails: int = 0


func ok(c: bool, w: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", w])
	if not c:
		fails += 1


func fresh(seed: int = 1) -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, seed, {}, {"intro": false})
	S.out.fx.clear()
	return S


func tower(S: SimState, lo: int = 9, hi: int = 15):
	for b in S.buildings:
		if b.floors >= lo and b.floors <= hi and int(b.row) == 1:
			return b
	return null


## Drive one launched flight at a building and return its events.
func fly(S: SimState, A, D, b, tier: float, force: float = 2000.0, stopAtLodge: bool = false) -> Array:
	A.tier = tier
	D.hp = 1.0e9
	A.hp = 1.0e9
	var side: float = 1.0
	D.x = SimWrap.wrap(b.x - side * 3000.0)
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
		if stopAtLodge and ev.any(func(e): return e.type == "lodge"):
			break   # (the pin is read the tick it begins: the flight ends when it runs out)
	return ev


func _init() -> void:
	var c: Dictionary = WorldBrunt.cfg()
	ok(WorldBrunt.dataErrors().is_empty(), "brunt.json loads clean (%s)" % str(WorldBrunt.dataErrors()))
	ok(c.lodgeHold in ["world", "auto"] and c.failHurts == "none", "the homework switches stand at today's behaviour (lodgeHold %s, failHurts %s, towerPunches[0] %d)" % [c.lodgeHold, c.failHurts, int(c.towerPunches[0])])

	# ---- the wall slam: a tier-1 body at a tower
	var S := fresh(1)
	var tw = tower(S)
	var A = S.fighters[1]
	var D = S.fighters[0]
	var hp0: float = 1.0e9
	var ev: Array = fly(S, A, D, tw, 1.0)
	var walls: Array = ev.filter(func(e): return e.type == "building_hit")
	ok(walls.size() == 1 and walls[0].outcome == "wall", "a tier-1 body at a tower is a wall: building_hit outcome wall (%s)" % str(walls.map(func(e): return e.outcome)))
	var fh: Array = ev.filter(func(e): return e.type == "floor_hit")
	ok(fh.size() == 1 and fh[0].outcome in ["crack", "dent"], "and the floor_hit says how it broke (%s)" % str(fh.map(func(e): return e.outcome)))
	ok(D.stunTicks >= int(c.wallStaggerTicks) - 1, "he is staggered at the wall (%d ticks, wallStaggerTicks %d)" % [D.stunTicks, int(c.wallStaggerTicks)])
	# a held hit writes its side into fhole: both ends at the edge he came in by (flying toward +x: the left edge, -1), nothing gone
	var marked: int = 0
	var side_ok: bool = true
	var gone_any: bool = false
	for k in range(tw.floors):
		if tw.fhole.size() == 3 * tw.floors and tw.fhole[3 * k] != 0.0:
			marked += 1
			side_ok = side_ok and tw.fhole[3 * k] == tw.fhole[3 * k + 1] and absf(tw.fhole[3 * k]) == 1.0
			gone_any = gone_any or tw.fhole[3 * k + 2] > 0.0
	ok(marked >= 1 and side_ok and not gone_any, "a held hit writes its side into fhole: %d floors marked at one edge, nothing gone" % marked)
	# the slam doubles the building's hit to the body: compare with wallSlamMul 1
	var S1 := fresh(1)
	var D1 = S1.fighters[0]
	c.wallSlamMul = 1.0
	fly(S1, S1.fighters[1], D1, tower(S1), 1.0)
	c.wallSlamMul = 2.0
	var hurt1: float = 1.0e9 - D1.hp
	var S2 := fresh(1)
	var D2 = S2.fighters[0]
	fly(S2, S2.fighters[1], D2, tower(S2), 1.0)
	var hurt2: float = 1.0e9 - D2.hp
	ok(hurt2 > hurt1 * 1.5 and hurt2 < hurt1 * 2.6, "the wall slam is twice the hit: %.1f against %.1f with wallSlamMul 1" % [hurt2, hurt1])

	# ---- the lodge event
	var S3 := fresh(2)
	var lodges: int = 0
	var lodge_ok: int = 0
	var rg := SimRng.new(3)
	for n in range(60):
		var Sx := fresh(1 + n % 5)
		var Ax = Sx.fighters[1]
		var Dx = Sx.fighters[0]
		var pick = Sx.buildings[int(rg.next() * float(Sx.buildings.size()))]
		var evx: Array = fly(Sx, Ax, Dx, pick, float(1 + n % 4))
		for e in evx:
			if e.type == "lodge":
				lodges += 1
				if e.hold > 0.45 and e.hold < 0.95 and e.x == Dx.x and e.b >= 0.0:
					lodge_ok += 1
	ok(lodges > 5 and lodge_ok == lodges, "a lodge event carries x, y, z and the hold seconds (%d lodges, %d well formed)" % [lodges, lodge_ok])
	# lodgeHold body: no hit-stop of the world, the body is stunned
	c.lodgeHold = "body"
	var Sb := fresh(1)
	var Ab = Sb.fighters[1]
	var Db = Sb.fighters[0]
	var stop_seen: float = 0.0
	for n in range(40):
		var Sy := fresh(1 + n % 5)
		var evy: Array = fly(Sy, Sy.fighters[1], Sy.fighters[0], Sy.buildings[(n * 7) % Sy.buildings.size()], 4.0, 2000.0, true)
		if evy.any(func(e): return e.type == "lodge"):
			Sb = Sy
			Db = Sy.fighters[0]
			break
	ok(Db.stunTicks >= 20 or Db.holdT >= 20, "lodgeHold body: the body is held for the hold (stun %d, pin %d ticks)" % [Db.stunTicks, Db.holdT])
	c.lodgeHold = "world"

	# ---- B: breaches
	var Sk := fresh(1)
	var t2 = tower(Sk)
	var y: float = WorldStructures.baseY(Sk, t2) + (float(t2.floors / 2) + 0.5) * WorldBrunt.floorH(t2)
	var oc: Dictionary = {"k": t2.floors / 2, "hit": [t2.floors / 2, t2.floors / 2 + 1], "ratio": 3.0, "dmg": 900.0}
	var pr: Dictionary = WorldBrunt.punchFloors(t2, oc, 0.0, true)
	var share: float = t2.fhole[3 * (t2.floors / 2) + 2]
	ok(t2.fhole[3 * (t2.floors / 2)] == -1.0 and t2.fhole[3 * (t2.floors / 2) + 1] == 1.0, "a body that crosses the building breaks a slot from side to side of the floor (%.1f to %.1f)" % [t2.fhole[3 * (t2.floors / 2)], t2.fhole[3 * (t2.floors / 2) + 1]])
	ok(pr.cleared == 0 and share > 0.2 and share < float(c.clearAt), "a ratio-3 punch breaks a run of the story and leaves it standing (share %.2f of the width, clearAt %.2f)" % [share, float(c.clearAt)])
	ok(pr.x0 >= t2.x - t2.w * 0.5 and pr.x1 <= t2.x + t2.w * 0.5 and pr.x0 < pr.x1, "floor_hit x0 and x1 are the slot, inside the building (%.0f to %.0f of %.0f +- %.0f)" % [pr.x0, pr.x1, t2.x, t2.w * 0.5])
	oc.ratio = 12.0
	var pr2: Dictionary = WorldBrunt.punchFloors(t2, oc, 0.0, true)
	ok(pr2.cleared == 2, "a ratio-12 punch (tier 4) clears the story (%d floors)" % pr2.cleared)
	var Sm := fresh(1)
	var t3 = tower(Sm)
	var oc3: Dictionary = {"k": 4, "hit": [4, 5], "ratio": 3.0, "dmg": 900.0}
	var tot: int = 0
	var rounds: int = 0
	while tot == 0 and rounds < 6:
		var p3: Dictionary = WorldBrunt.punchFloors(t3, oc3, 0.0, true)
		tot += p3.cleared
		rounds += 1
	ok(tot > 0 and rounds >= 2, "breaches add up: the story goes at the %s punch of ratio 3" % ["second" if rounds == 2 else str(rounds) + "th"])
	var Ss := fresh(1)
	var t5 = tower(Ss)
	var oc5: Dictionary = {"k": 4, "hit": [4, 5], "ratio": 3.0, "dmg": 900.0}
	var ps: Dictionary = WorldBrunt.punchFloors(t5, oc5, 0.5, false)
	ok(ps.x0 > t5.x and ps.x1 <= t5.x + t5.w * 0.5 + 0.01 and ps.x1 - ps.x0 < t5.w * 0.9, "a shot breaks a local slot where it lands (%.0f to %.0f of a building %.0f wide at x %.0f)" % [ps.x0, ps.x1, t5.w, t5.x])
	c.breaches = 0
	var Sz := fresh(1)
	var t4 = tower(Sz)
	var oc4: Dictionary = {"k": 4, "hit": [4, 5], "ratio": 1.2, "dmg": 900.0}
	var p4: Dictionary = WorldBrunt.punchFloors(t4, oc4, 0.0, true)
	ok(p4.cleared == 2, "breaches 0: every punch clears the story as before")
	c.breaches = 1

	# ---- C: the failing state
	var Sf := fresh(1)
	var tf = tower(Sf)
	tf.hp = 1.0
	WorldStructures.damageBuilding(Sf, tf, 100000.0, null, "implode", tf.x, 0.0)
	ok(tf.alive and tf.failK >= 0 and tf.failT <= -1.5 + 0.0001, "a spent tower does not fall in the tick: it warns %.2f s first (>= 1.5) and stays alive" % (-tf.failT))
	var fe: Array = Sf.out.fx.filter(func(e): return e.type == "building_failing")
	ok(fe.size() == 1 and fe[0].t_warn >= 1.5 and fe[0].t_fall >= 2.0 and fe[0].w == tf.w, "building_failing {b, x, y, w, h, t_warn, t_fall}: warn %.2f fall %.2f" % [fe[0].t_warn if fe.size() > 0 else -1.0, fe[0].t_fall if fe.size() > 0 else -1.0])
	var t_start: float = 0.0
	var landed_at: Array = []
	var end_t: float = -1.0
	var floors0: int = WorldBrunt.standingCount(tf)
	var tt: float = 0.0
	for i in range(1200):
		WorldStructures.stepFailing(Sf, SimConst.DT)
		tt += SimConst.DT
		for e in Sf.out.fx:
			if e.type == "floors_fall" and int(e.b) == tf.idx:
				landed_at.append(tt)
		Sf.out.fx.clear()
		if not tf.alive:
			end_t = tt
			break
	ok(end_t > 0.0 and end_t >= 1.5 + 2.0 - 0.1, "the whole tower is down after %.2f s (warning 1.5 + at least 2)" % end_t)
	ok(landed_at.size() == floors0, "a floor lands each step: %d of %d floors" % [landed_at.size(), floors0])
	var fall_time: float = landed_at[landed_at.size() - 1] - landed_at[0] if landed_at.size() > 1 else 0.0
	ok(fall_time >= 1.4, "the floors land over seconds (%.2f s from the first to the last)" % fall_time)

	# the warning is over any hold a fighter under it is in
	var Sw := fresh(1)
	var tw5 = tower(Sw)
	Sw.fighters[0].x = tw5.x
	Sw.fighters[0].z = 0.0
	Sw.fighters[0].y = WorldStructures.baseY(Sw, tw5) + 20.0
	Sw.fighters[0].stunTicks = 150   # 2.5 s
	Sw.fighters[1].x = SimWrap.wrap(tw5.x + 90000.0)
	WorldStructures.startFail(Sw, tw5, 0, Sw.fighters[1], tw5.x)
	ok(absf(-tw5.failT - (2.5 + float(c.failWarnOver))) < 0.05, "a fighter under it held 2.5 s: the warning is 0.6 longer (%.2f s)" % (-tw5.failT))

	# whom it hurts
	var res := {}
	for mode in ["none", "both", "rival"]:
		c.failHurts = mode
		var Sh := fresh(1)
		var th = tower(Sh)
		Sh.fighters[0].x = th.x
		Sh.fighters[0].z = 0.0
		Sh.fighters[0].y = WorldStructures.baseY(Sh, th) + 10.0
		Sh.fighters[0].hp = 1.0e6
		Sh.fighters[1].x = SimWrap.wrap(th.x + 200.0)
		Sh.fighters[1].z = 0.0
		Sh.fighters[1].y = WorldStructures.baseY(Sh, th) + 10.0
		Sh.fighters[1].hp = 1.0e6
		WorldStructures.startFail(Sh, th, 0, Sh.fighters[1], th.x)   # fighter 1 brought it down
		for i in range(1500):
			WorldStructures.stepFailing(Sh, SimConst.DT)
			Sh.fighters[0].stunTicks = 0
			Sh.fighters[1].stunTicks = 0
			if th.failK < 0:
				break
		res[mode] = [1.0e6 - Sh.fighters[0].hp, 1.0e6 - Sh.fighters[1].hp]
	c.failHurts = "none"
	ok(res.none[0] == 0.0 and res.none[1] == 0.0, "failHurts none: nobody is hurt (%s)" % str(res.none))
	ok(res.both[0] > 0.0 and res.both[1] > 0.0 and res.both[0] <= 100.01 and res.both[1] <= 100.01, "failHurts both: either fighter is hurt, at most 100 (%s)" % str(res.both))
	ok(res.rival[0] > 0.0 and res.rival[1] == 0.0, "failHurts rival: only the one who did not bring it down (%s)" % str(res.rival))

	# four bodies: failHurt has a number a body; "rival" is not the causer nor his team
	var rf := {}
	for mode in ["both", "rival"]:
		c.failHurts = mode
		var S4 := fresh(1)
		var order: Array = FighterData.order()
		for i in range(2, 4):
			S4.fighters.append(SimRoster.createFighter(FighterData.def(order[i % 2]), S4.fighters[0].x, "p%d" % (i + 1), true))
		var t4f = tower(S4)
		for i in range(4):
			var fi = S4.fighters[i]
			fi.x = SimWrap.wrap(t4f.x + 60.0 * float(i))
			fi.z = 0.0
			fi.y = WorldStructures.baseY(S4, t4f) + 10.0
			fi.hp = 1.0e6
		WorldStructures.startFail(S4, t4f, 0, S4.fighters[1], t4f.x)   # body 1 brought it down
		ok(t4f.failHurt.size() == 4, "failHurt has one number a body in a four-body match (%d)" % t4f.failHurt.size())
		for i in range(1500):
			WorldStructures.stepFailing(S4, SimConst.DT)
			for fi in S4.fighters:
				fi.stunTicks = 0
			if t4f.failK < 0:
				break
		rf[mode] = [1.0e6 - S4.fighters[0].hp, 1.0e6 - S4.fighters[1].hp, 1.0e6 - S4.fighters[2].hp, 1.0e6 - S4.fighters[3].hp]
	c.failHurts = "none"
	ok(rf.both[2] > 0.0 and rf.both[3] > 0.0 and rf.both[2] <= 100.01 and rf.both[3] <= 100.01, "four bodies, failHurts both: bodies 2 and 3 are hurt, at most 100 (%s)" % str(rf.both))
	ok(rf.rival[0] > 0.0 and rf.rival[1] == 0.0 and rf.rival[2] == 0.0 and rf.rival[3] == 0.0, "four bodies, failHurts rival: only the principal he fights; the causer and his guards are spared (%s)" % str(rf.rival))

	# the switch: failing 0 brings a tower down in the tick as before
	c.failing = 0
	var Sg := fresh(1)
	var tg = tower(Sg)
	tg.hp = 1.0
	WorldStructures.damageBuilding(Sg, tg, 100000.0, null, "implode", tg.x, 0.0)
	ok(not tg.alive and tg.failK < 0, "failing 0: a spent tower falls in the tick, as before")
	c.failing = 1

	# a partial collapse: the stack above a cleared run comes down and the floors below stand
	var Sp := fresh(1)
	var tp = tower(Sp, 10, 16)
	for k in range(3, 6):
		tp.fmask = tp.fmask & ~(1 << k)
	var f1 = Sp.fighters[1]
	var pk: Dictionary = WorldBrunt.pancake(Sp, tp, f1, 0.0, tp.x, null)
	ok(pk.pancake and tp.failK >= 0 and tp.alive, "a cleared run longer than the tunnel starts a failure, not a fall in the tick (failK %d, warn %.2f)" % [tp.failK, -tp.failT])
	for i in range(2400):
		WorldStructures.stepFailing(Sp, SimConst.DT)
		if tp.failK < 0:
			break
	ok(tp.failK < 0 and tp.alive and WorldBrunt.standingCount(tp) > 0, "the stack is down and what stands below stays: %d floors of %d (a partial collapse)" % [WorldBrunt.standingCount(tp), tp.floors])
	print("BC: %d check(s) failed" % fails)
	quit()
