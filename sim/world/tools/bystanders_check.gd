extends SceneTree
## Nobody dies, and no meter reads a person (Orb, 2026-11-07, CD-05; docs/design/bystanders.md; Legal RL-257): the proof Legal reads.
##   1. scatter by each fighter and by nobody: people ran (so it is not vacuous), the count is 0, the population is conserved, and no menace, power, anguish or Witness rose;
##   2. a thrown set's speed and bounces are keyed (the same twice), in the data's range;
##   3. a building that falls kills no one and leaves no one inside; the meters rise by the destruction (its mass, its size), exactly as in a world with every person taken out: the same meters either way;
##   4. the whole world brought down by the villain: the same, summed; the budget and the ceiling fill with mass and isOver says so;
##   5. craters (3 body heights across or more, by his send or beam, never powering up), the combat trauma (a region broken, the brink), the anguish within reach and the failing to protect;
##   6. a match played on, AI against AI, with and without every person: the same fighters, meters, structures and craters at every look (the civilians-removed identity), and the count never moves;
##   7. the code: no kill, no feed, nothing writes the count, and a meter is written only by the four functions that read destruction.
## Controls: the detector flags a gain in each meter put back by hand; the lint finds the old text and a write in scatter; a meter gain and a count put back inside scatter fail the check (run by hand, docs/world/runs); and with
## the structure reads switched to read a person (WorldCollateral.blindPeople) the identity digest differs between the two worlds. A check that cannot fail proves nothing.
##   godot --headless --path . --script res://sim/world/tools/bystanders_check.gd

var _fails: int = 0
const NAMES: Array = ["menace", "power", "anguish", "witness"]


func ok(c: bool, msg: String) -> void:
	if not c:
		_fails += 1
		print("  FAIL: ", msg)


func fresh(seed_: int) -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, seed_, {}, {"intro": false})
	S.out.fx.clear()
	return S


func low(S: SimState) -> void:
	for f in S.fighters:
		f.menace = 10.0
		f.power = 10.0
		f.anguish = 10.0


func snap(S: SimState) -> Array:
	var a: Array = []
	for f in S.fighters:
		var wit: float = float(f.form.witness) if SimForms.has(S, f) else 0.0
		a.append([float(f.menace), float(f.power), float(f.anguish), wit])
	return a


func raised(S: SimState, before: Array) -> Array:
	var now: Array = snap(S)
	var out: Array = []
	for i in range(now.size()):
		for k in range(4):
			if float(now[i][k]) > float(before[i][k]):
				out.append("fighter %d %s %.4f -> %.4f" % [i, NAMES[k], before[i][k], now[i][k]])
	return out


func total_pop(S: SimState) -> float:
	var t: float = 0.0
	for b in S.buildings:
		t += float(b.popAlive)
	return t


func evac_events(S: SimState) -> Array:
	var out: Array = []
	for e in S.out.fx:
		if e.type == "evacuate":
			out.append(e)
	return out


func populated(S: SimState, atLeast: float):
	for b in S.buildings:
		if b.alive and b.popAlive >= atLeast and not WorldCollateral.isFar(S, b.idx):
			return b
	return null


## A lived-in standing building of a size class (0 house, 1 low tower, 2 tall tower), not far.
func of_class(S: SimState, cls: int):
	for b in S.buildings:
		if b.alive and b.pop > 0.0 and b.hp >= b.maxhp and not WorldCollateral.isFar(S, b.idx) and WorldBrunt.sizeClass(b) == cls:
			return b
	return null


## Bring down up to n of the standing buildings within r of x (the nearest first), as a blow would.
func bring_down(S: SimState, x: float, r: float, cause, n: int) -> void:
	var rows: Array = []
	for bi in WorldStructures.near(S, x, r):
		var b = S.buildings[bi]
		if b.alive and not WorldCollateral.isFar(S, bi):
			rows.append([absf(SimWrap.sdx(x, b.x)), bi])
	rows.sort()
	for i in range(mini(n, rows.size())):
		var b2 = S.buildings[int(rows[i][1])]
		WorldStructures.damageBuilding(S, b2, float(b2.maxhp) * 3.0, cause, "implode", b2.x)


## Every person taken out, as a setup would: nobody in any building, nobody in flight.
func no_people(S: SimState) -> void:
	for b in S.buildings:
		b.popAlive = 0.0
		b.fled = 0.0


## What the match is, with no person in it: fighters, meters, structures, craters, the lure's mass and what the planner's reads see.
func digest(S: SimState) -> int:
	var parts: Array = [S.tick]
	for f in S.fighters:
		parts.append([snappedf(f.x, 0.001), snappedf(f.y, 0.001), snappedf(f.z, 0.001), snappedf(f.hp, 0.001), snappedf(f.ki, 0.001), snappedf(f.menace, 0.0001), snappedf(f.power, 0.0001), snappedf(f.anguish, 0.0001), f.tier, f.state])
	var hp: float = 0.0
	var alive: int = 0
	for b in S.buildings:
		hp += float(b.hp)
		alive += 1 if b.alive else 0
	var hist: float = 0.0
	for v in S.popHist:
		hist += float(v)
	var lm: float = 0.0
	for b in S.buildings:
		lm += WorldCollateral.livedMass(S, b)
	parts.append([snappedf(lm, 0.001), snappedf(hp, 0.001), alive, S.world.structuresLost, S.world.craters, S.world.massLost, S.craters.size(), snappedf(hist, 0.001), S.world.casualties])
	for f in S.fighters:
		parts.append(snappedf(WorldStructures.livedNear(S, f.x, 3000.0), 0.00001))
	return str(parts).hash()


func writes_by_function(src: String) -> Dictionary:
	var out: Dictionary = {}
	var chunks: PackedStringArray = src.split("\nstatic func ")
	for i in range(1, chunks.size()):
		var name: String = chunks[i].substr(0, chunks[i].find("("))
		var n: int = 0
		for l in chunks[i].split("\n"):
			var t: String = l.strip_edges()
			if t.begins_with("#"):
				continue
			if l.contains(".casualties +=") or l.contains(".casualties =") or l.contains(".menace =") or l.contains(".power =") or l.contains(".anguish ="):
				n += 1
		if n > 0:
			out[name] = n
	return out


func _init() -> void:
	SimInputData.load_and_apply()
	var ran_total: float = 0.0
	# ---- 1. scatter: nothing rises, nobody is removed
	for seed_ in [1, 2, 3]:
		for who in [0, 1, -1]:
			var S := fresh(seed_)
			low(S)
			var cause = S.fighters[who] if who >= 0 else null
			var b = populated(S, 8.0)
			ok(b != null, "seed %d: a building with people" % seed_)
			if b == null:
				continue
			var before: Array = snap(S)
			var pop0: float = total_pop(S)
			var in0: float = b.popAlive
			var ran: float = WorldCollateral.scatter(S, b.idx, minf(b.popAlive, 30.0), cause, 0.0, b.x)
			ran_total += ran
			var ev: Array = evac_events(S)
			ok(ran > 0.0 and ev.size() == 1 and String(ev[0].reason) == "scatter" and absf(float(ev[0].n) - ran) < 1.0e-6, "seed %d cause %d: %.1f people ran, one evacuate event, reason scatter" % [seed_, who, ran])
			ok(S.world.casualties == 0.0, "seed %d cause %d: nothing counted (%.3f)" % [seed_, who, S.world.casualties])
			ok(absf(b.popAlive - (in0 - ran)) < 1.0e-6, "seed %d cause %d: the people left the building" % [seed_, who])
			if ev.size() == 1 and int(ev[0].dest) >= 0:
				ok(absf(total_pop(S) - pop0) < 1.0e-6, "seed %d cause %d: a shelter took them all, the population is conserved" % [seed_, who])
			ok(raised(S, before).is_empty(), "seed %d cause %d: no meter rose %s" % [seed_, who, str(raised(S, before))])
	# ---- 2. flung: keyed
	var sf1 := fresh(4)
	var sf2 := fresh(4)
	var bf1 = populated(sf1, 8.0)
	var bf2 = populated(sf2, 8.0)
	if bf1 != null and bf2 != null:
		WorldCollateral.scatter(sf1, bf1.idx, 20.0, sf1.fighters[1], 0.0, bf1.x, 3, "flung")
		WorldCollateral.scatter(sf2, bf2.idx, 20.0, sf2.fighters[1], 0.0, bf2.x, 3, "flung")
		var e1: Array = evac_events(sf1)
		var e2: Array = evac_events(sf2)
		ok(e1.size() == 1 and e2.size() == 1 and String(e1[0].reason) == "flung", "a hit flings: one evacuate event, reason flung")
		if e1.size() == 1 and e2.size() == 1:
			ok(float(e1[0].spd) >= WorldCollateral.FLING_LO and float(e1[0].spd) <= WorldCollateral.FLING_HI, "the thrown speed is in the data's range (%.0f)" % e1[0].spd)
			ok(int(e1[0].k) >= 0 and int(e1[0].k) <= WorldCollateral.BOUNCES_MAX and float(e1[0].dur) == WorldCollateral.UP_WITHIN_S, "at most bouncesMax bounces (%d), up within upWithinSec" % int(e1[0].k))
			ok(float(e1[0].spd) == float(e2[0].spd) and e1[0].k == e2[0].k, "the same world twice throws them the same (keyed, seeded)")
	# ---- 3. a building that falls: kills no one, leaves no one, and the meters read its mass and size, the same with or without people
	var Ra := fresh(5)
	var Rb := fresh(5)
	no_people(Rb)
	for cls in [0, 1, 2]:
		var ba = of_class(Ra, cls)
		var bb = of_class(Rb, cls)
		ok(ba != null and bb != null and ba.idx == bb.idx, "class %d: a lived-in building of the size" % cls)
		if ba == null or bb == null:
			continue
		for S in [Ra, Rb]:
			low(S)
			S.out.fx.clear()
			S.world.massLost = 0.0
		var inside: float = ba.popAlive
		var lost0: float = Ra.world.structuresLost
		WorldStructures.damageBuilding(Ra, ba, float(ba.maxhp) * 3.0, Ra.fighters[1], "implode", ba.x)
		WorldStructures.damageBuilding(Rb, bb, float(bb.maxhp) * 3.0, Rb.fighters[1], "implode", bb.x)
		var run_n: float = 0.0
		for e in evac_events(Ra):
			run_n += float(e.n)
		var m: float = WorldBrunt.massOf(ba)
		var nm: float = WorldCollateral.norm(Ra)
		var vil = Ra.fighters[1]
		var want_menace: float = 10.0 + m * vil.md.menaceDestroyed * nm + vil.md.menaceEmptied[cls] * nm
		var want_power: float = 10.0 + m * vil.md.worldPower * nm
		ok(Ra.world.structuresLost == lost0 + 1.0 and not ba.alive and Ra.world.casualties == 0.0 and ba.popAlive == 0.0, "class %d: it fell, killed no one and left no one inside" % cls)
		ok(absf(run_n - inside) < 1.0e-6, "class %d: all of them ran (%.1f of %.1f)" % [cls, run_n, inside])
		ok(absf(Ra.fighters[1].menace - want_menace) < 1.0e-6 and absf(Ra.fighters[1].power - want_power) < 1.0e-6, "class %d: his menace %.4f (want %.4f) and power %.4f (want %.4f) rose by its mass %.0f and its size" % [cls, Ra.fighters[1].menace, want_menace, Ra.fighters[1].power, want_power, m])
		ok(snap(Ra) == snap(Rb), "class %d: the same meters with every person taken out %s %s" % [cls, str(snap(Ra)), str(snap(Rb))])
		ok(absf(Ra.world.massLost - m) < 1.0e-9, "class %d: its mass joined the total (%.1f)" % [cls, Ra.world.massLost])
	# ---- 4. the whole world, and the budget on mass
	var Wa := fresh(6)
	var Wb := fresh(6)
	no_people(Wb)
	for S in [Wa, Wb]:
		low(S)
	var sum_m: float = 0.0
	for bb in Wa.buildings:
		if bb.alive and not WorldCollateral.isFar(Wa, bb.idx):
			sum_m += WorldBrunt.massOf(bb)
	ok(absf(sum_m - Wa.world.mass0) < 1.0e-6 and Wa.world.mass0 > 100.0, "mass0 is the arena's structure mass (%.0f)" % Wa.world.mass0)
	ok(absf(WorldCollateral.budget(Wa) - WorldCollateral.BUDGET[0] * Wa.world.mass0) < 1.0e-9 and not WorldCollateral.isOver(Wa), "the budget is a share of that mass, and nothing is over it yet")
	for S in [Wa, Wb]:
		for bb in S.buildings:
			if bb.alive and not WorldCollateral.isFar(S, bb.idx):
				WorldStructures.damageBuilding(S, bb, float(bb.maxhp) * 3.0, S.fighters[1], "implode", bb.x)
	ok(Wa.world.casualties == 0.0 and absf(Wa.world.massLost - sum_m) < 1.0e-6, "the whole world brought down by the villain: the count is 0, the mass lost is all of it (%.0f)" % Wa.world.massLost)
	ok(snap(Wa) == snap(Wb), "the same meters with every person taken out")
	ok(WorldCollateral.isOver(Wa) and WorldCollateral.ceilingLeft(Wa) == 0.0 and WorldCollateral.room(Wa) == 0.0, "the window and the ceiling are spent: isOver")
	ok(Wa.fighters[1].menace > 10.0 and Wa.fighters[1].power > 10.0 and Wa.fighters[1].menace <= 100.0, "the villain fed on the wreck, capped (%.1f menace)" % Wa.fighters[1].menace)
	# ---- 5. craters, trauma, anguish
	var Sc := fresh(1)
	low(Sc)
	var vc = Sc.fighters[1]
	var hero = Sc.fighters[0]
	var nc: float = WorldCollateral.norm(Sc)
	var m0: float = vc.menace
	WorldCollateral.dug(Sc, 300.0, "impact", vc)
	ok(absf(vc.menace - (m0 + vc.md.menaceCrater * nc)) < 1.0e-9, "a crater of 300 across (4 body heights) by his send feeds him")
	m0 = vc.menace
	WorldCollateral.dug(Sc, 200.0, "impact", vc)
	WorldCollateral.dug(Sc, 300.0, "powerup", vc)
	WorldCollateral.dug(Sc, 300.0, "beam", null)
	ok(vc.menace == m0, "a crater under 3 body heights across, powering up on the ground, or nobody's: nothing")
	SimFx.regionBroken(Sc, hero, "head")
	SimFx.brinkEnter(Sc, hero)
	WorldCollateral._trauma(Sc)
	ok(absf(vc.menace - (m0 + vc.md.menaceBreak + vc.md.menaceBrink)) < 1.0e-9, "the opposing fighter's region broken and his brink feed the villain (%.1f)" % (vc.menace - m0))
	m0 = vc.menace
	Sc.out.fx.clear()
	SimFx.regionBroken(Sc, vc, "head")
	WorldCollateral._trauma(Sc)
	ok(vc.menace == m0, "his own region broken feeds no one")
	# anguish: a fall within 3,000 units of the hero by the villain, then by the hero; the failing to protect when he is the nearer
	var Sa := fresh(2)
	low(Sa)
	var ha = Sa.fighters[0]
	var ba2 = of_class(Sa, 1)
	ok(ba2 != null, "a building to bring down")
	if ba2 != null:
		ha.x = SimWrap.wrap(ba2.x - 1500.0)   # the hero 1,500 units from it, and nearer to it than the villain
		Sa.fighters[1].x = SimWrap.wrap(ba2.x + 6000.0)
	if ba2 != null:
		var nm2: float = WorldCollateral.norm(Sa)
		var mm2: float = WorldBrunt.massOf(ba2)
		var a0: float = ha.anguish
		WorldCollateral.fell(Sa, ba2, Sa.fighters[1])
		var gain_other: float = ha.anguish - a0
		var nearest: bool = absf(SimWrap.sdx(ha.x, ba2.x)) <= absf(SimWrap.sdx(Sa.fighters[1].x, ba2.x))
		var want_other: float = mm2 * ha.md.anguishDestroyedOther * nm2
		ok(gain_other >= want_other - 1.0e-9 and (gain_other <= want_other + mm2 * ha.md.anguishFailed * nm2 + 1.0e-9), "a fall near him by the villain costs him %.3f (at least %.3f)" % [gain_other, want_other])
		ok(nearest or absf(gain_other - want_other) < 1.0e-9, "the failing to protect only when he is the nearer fighter")
		a0 = ha.anguish
		WorldCollateral.fell(Sa, ba2, ha)
		ok(ha.anguish - a0 >= mm2 * ha.md.anguishDestroyedSelf * nm2 - 1.0e-9, "a fall by his own hand costs him more per unit (%.3f)" % (ha.anguish - a0))
		var far_f = null
		for f in Sa.fighters:
			if f != ha:
				far_f = f
		var saved_x: float = ha.x
		ha.x = SimWrap.wrap(ba2.x + 5000.0)
		a0 = ha.anguish
		WorldCollateral.fell(Sa, ba2, Sa.fighters[1])
		ok(ha.anguish == a0, "a fall more than 3,000 units from him costs him nothing")
		ha.x = saved_x
	# ---- 6. a match played on, with and without every person: the identity
	var seeds_with_falls: int = 0
	for seed_ in [7, 8]:
		var Ma := fresh(seed_)
		var Mb := fresh(seed_)
		no_people(Mb)
		var same: bool = true
		var worst: float = 0.0
		for t in range(2400):
			if t % 300 == 150:   # the villain brings some of the city down in both worlds (the AI alone may not in this many ticks), so the identity is not vacuous
				bring_down(Ma, Ma.fighters[1].x, 15000.0, Ma.fighters[1], 2)
				bring_down(Mb, Mb.fighters[1].x, 15000.0, Mb.fighters[1], 2)
			SimCore.step(Ma, null)
			SimCore.step(Mb, null)
			Ma.out.fx.clear()
			Mb.out.fx.clear()
			worst = maxf(worst, Ma.world.casualties)
			if t % 200 == 199 and digest(Ma) != digest(Mb):
				same = false
				break
		ok(same, "seed %d: AI against AI for 2400 ticks, with every person taken out: the same fighters, meters, structures and craters at every look" % seed_)
		ok(worst == 0.0, "seed %d: the count never moved" % seed_)
		seeds_with_falls += 1 if Ma.world.structuresLost > 0.0 else 0
		print("  seed %d: %d structures lost, villain menace %.1f power %.1f, mass lost %.0f of %.0f" % [seed_, int(Ma.world.structuresLost), Ma.fighters[1].menace, Ma.fighters[1].power, Ma.world.massLost, Ma.world.mass0])
	ok(seeds_with_falls >= 1, "at least one of the matches brought a building down, so the identity is not vacuous")
	# the control: a structure read switched to read a person makes the two worlds differ
	WorldCollateral.blindPeople = true
	var Ca := fresh(7)
	var Cb := fresh(7)
	no_people(Cb)
	ok(digest(Ca) != digest(Cb), "control: with the structure reads switched to read a person, the world with no one in it digests differently")
	WorldCollateral.blindPeople = false
	# ---- 7. the code
	var src: String = FileAccess.get_file_as_string("res://sim/world/collateral.gd")
	var wr: Dictionary = writes_by_function(src)
	var allowed: Array = ["fell", "emptied", "dug", "_trauma"]
	var stray: Array = []
	for k in wr:
		if not allowed.has(k):
			stray.append(k)
	ok(stray.is_empty() and not src.contains("func kill(") and not src.contains("func _feed(") and not src.contains(".casualties +=") and not src.contains(".casualties ="), "collateral.gd: no kill, no feed, nothing writes the count, and a meter is written only by fell, emptied, dug and _trauma (%s)" % str(stray))
	var old_text: String = "
static func scatter(S, bi, want):\n\tcause.menace = jmin(100.0, cause.menace + 1.0)\nstatic func fell(S, b):\n\tcause.menace = 1\n"
	var cwr: Dictionary = writes_by_function(old_text)
	ok(cwr.has("scatter") and cwr.has("fell"), "control: the lint finds a meter written inside scatter (%s)" % str(cwr))
	# the detector's controls
	var Sn := fresh(1)
	low(Sn)
	var nb: Array = snap(Sn)
	Sn.fighters[1].menace = 11.0
	Sn.fighters[1].power = 11.0
	Sn.fighters[0].anguish = 11.0
	ok(raised(Sn, nb).size() == 3, "control: a gain in menace, power and anguish put back by hand is flagged (%s)" % str(raised(Sn, nb)))
	var Sfw := fresh(1)
	var wb2: Array = snap(Sfw)
	for f in Sfw.fighters:
		if SimForms.has(Sfw, f):
			f.form.witness += 1.0
	var forms_in: bool = false
	for f in Sfw.fighters:
		forms_in = forms_in or SimForms.has(Sfw, f)
	ok(not forms_in or raised(Sfw, wb2).size() >= 1, "control: a gain in Witness put back by hand is flagged")
	print("BYSTANDERS: %.1f people ran in the scatter runs, none died" % ran_total)
	print("BYSTANDERS: %d check(s) failed" % _fails)
	quit(1 if _fails > 0 else 0)
