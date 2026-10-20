extends SceneTree
# Repeats escalate (Orb, homework 30; docs/design/buildings.md section 6.1; brunt.json repeatMarks, repeatCraterGrow):
#   godot --headless --path . --script res://sim/world/tools/repeat_check.gd
# A send into a building already marked meets it one tier higher for each mark, at most two; a send into ground already cratered deepens and widens that crater.
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


func house(S: SimState):
	for b in S.buildings:
		if b.floors < WorldBrunt.FLOORS_MIN and int(b.row) == 1 and b.alive:
			return b
	return null


## One launch into building b at a fixed speed (a straight, shallow send), by a tier-2 launcher; returns the building_hit event.
func send(S: SimState, b, tier: float = 2.0):
	var A = S.fighters[1]
	var D = S.fighters[0]
	A.tier = tier
	A.hp = 1.0e9
	D.hp = 1.0e9
	var dir: float = 1.0
	var edge: float = SimWrap.wrap(b.x - dir * b.w * 0.5)
	D.state = "launched"
	D.launchBy = A
	D.launchT = 1.0
	D.launchSpecial = false
	D.flightHits = 0
	D.splashed = PackedInt32Array()
	D.chainEvt = WorldCollateral.beginEvent(S, "chain", A)
	D.vx = 3000.0
	D.vy = 100.0
	D.x = SimWrap.wrap(edge - 6.0)
	D.y = WorldStructures.baseY(S, b) + b.h * 0.3
	S.out.fx.clear()
	WorldBrunt.hit(S, D, b, D.y, edge, dir)
	var hit = null
	for e in S.out.fx:
		if e.type == "building_hit":
			hit = e
	S.out.fx.clear()
	WorldBrunt.endFlight(S, D)
	D.state = "free"
	return hit


func _init() -> void:
	var c: Dictionary = WorldBrunt.cfg()
	ok(WorldBrunt.dataErrors().is_empty(), "brunt.json loads clean (%s)" % str(WorldBrunt.dataErrors()))
	ok(int(c.repeatMarks) == 0 and float(c.repeatCraterGrow) == 1.25, "the switch is off in the data (repeatMarks %d), the crater factor 1.25" % int(c.repeatMarks))
	# --- off: no mark is kept, the tier is the launch's
	var S0 := fresh(1)
	var h0 = house(S0)
	send(S0, h0)
	ok(h0.marks == 0 and WorldBrunt.tierAt(S0, h0, 2.0) == 2.0, "switch off: a hit leaves no mark and the tier is the launch's")
	# --- on: one tier higher for each mark, at most two
	c.repeatMarks = 2
	var S := fresh(1)
	var tw = null
	for b in S.buildings:
		if b.floors >= 9 and int(b.row) == 1 and b.alive:
			tw = b
			break
	ok(WorldBrunt.tierAt(S, tw, 2.0) == 2.0, "an unmarked building meets the launch's tier (2)")
	var amounts: Array = []
	var hs = house(S)
	var hb: Array = []
	for i in range(4):
		hs.hp = hs.maxhp
		hs.alive = true
		var e = send(S, hs)
		hb.append(e)
	ok(hs.marks == 4, "each hit marks the building (%d marks after four)" % hs.marks)
	var tf: Array = c.tierFactor
	ok(WorldBrunt.tierAt(S, hs, 2.0) == 4.0, "and the tier is one higher per mark, at most two (tier 2 meets 4)")
	var ok2: bool = hb.size() == 4 and hb[0] != null
	if ok2:
		var r1: float = hb[1].amount / hb[0].amount
		var r2: float = hb[2].amount / hb[0].amount
		var r3: float = hb[3].amount / hb[0].amount
		var w1: float = tf[2] / tf[1]
		var w2: float = tf[3] / tf[1]
		ok(absf(r1 - w1) < 0.02 * w1 and absf(r2 - w2) < 0.02 * w2 and absf(r3 - w2) < 0.02 * w2, "the same send does %.2fx, %.2fx, then %.2fx the first one's damage (the ladder's %.2f and %.2f, capped)" % [r1, r2, r3, w1, w2])
	else:
		ok(false, "four sends gave four events")
	# --- the planner reads the same
	var pl: Array = WorldBrunt.chainPlan(S, 2.0, false, hs, {"y": hs.h * 0.3, "spN": 3000.0, "vx": 3000.0, "vy": 100.0, "t": 0.5}, 1.0)
	var dmg_plan: float = pl[0].dmg
	var oc: Dictionary = WorldBrunt.outcomeOf(S, hs, hs.h * 0.3, 3000.0, 4.0, 0, false)
	ok(absf(dmg_plan - oc.dmg) < 0.001, "the planner meets the marked building at the same tier (plan %.1f, outcome %.1f)" % [dmg_plan, oc.dmg])
	# --- the hash: marks fold in only when set
	var Sh := fresh(1)
	var hA: String = str(SimHash.stateHash(Sh).gameplay)
	Sh.buildings[3].marks = 1
	var hB: String = str(SimHash.stateHash(Sh).gameplay)
	Sh.buildings[3].marks = 0
	var hC: String = str(SimHash.stateHash(Sh).gameplay)
	ok(hA != hB and hA == hC, "a mark changes the state hash and none leaves it as it was")
	# --- ground: an impact on cratered ground deepens and widens that crater
	var G := fresh(1)
	var X: float = 4800.0
	var A = G.fighters[1]
	var r0 = WorldCrater.dig(G, X, 1.0, A, "impact", 0.0, 1.0)
	var col0: int = int(floor(SimWrap.wrap(X) / SimConst.COL))
	var floor0: float = G.deform[col0]
	var depthed: Array = [r0.depth] if r0 != null else []
	var radii: Array = [r0.r] if r0 != null else []
	for i in range(3):
		var rn = WorldCrater.dig(G, X + 30.0, 1.0, A, "impact", 0.0, 1.0)
		if rn != null:
			radii.append(rn.r)
			depthed.append(rn.depth)
			ok(absf(SimWrap.sdx(rn.x, r0.x)) < 1.0, "repeat %d digs at the old crater's centre (not %.0f beside it)" % [i + 1, 30.0])
	ok(radii.size() >= 3 and radii[1] > radii[0] * 1.2 and radii[2] > radii[1] * 1.2, "off: see the next line; on, the first two repeats widen it by 1.25 (%s)" % str(radii))
	ok(G.deform[col0] < floor0 - 1.0, "and the ground at its centre is lower than after the first impact (%.1f against %.1f)" % [G.deform[col0], floor0])
	ok(radii.size() < 4 or radii[3] <= radii[2] * 1.001, "the third repeat grows it no more (%s)" % str(radii))
	# the same off
	c.repeatMarks = 0
	var Go := fresh(1)
	var q0 = WorldCrater.dig(Go, X, 1.0, Go.fighters[1], "impact", 0.0, 1.0)
	var q1 = WorldCrater.dig(Go, X + 30.0, 1.0, Go.fighters[1], "impact", 0.0, 1.0)
	ok(q0 != null and (q1 == null or q1.r <= q0.r * 1.001), "off: a second impact beside it is today's (the same size or too dented to dig)")
	c.repeatMarks = 0
	print("REPEAT: %d check(s) failed" % fails)
	quit()
