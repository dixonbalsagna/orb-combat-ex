extends SceneTree
# A building remembers under the energy model (World, sim/world/brunt.gd _memory, _outcomePower; Orb, homework 30: a send into a building already marked meets it one tier higher for each mark, up to repeatMarks; Game Design,
# docs/design/buildings.md sections 6.1 and 9). With the model on there is no tier to raise (the check of checks-gw1a found `repeatMarks` inert on Orb's path), so a mark is one tier of the model's own step and shows as the building's
# weakening: it takes energyTop ^ (-tierShare / 3) of its mass per mark (about 0.51, then 0.26) of the body's energy.
#   godot --headless --path . --script res://sim/world/tools/memory_model_check.gd -- [--negative-control]
# --negative-control makes `_memory` 1 (the old behaviour): the memory rows must then fail (the check passes when they do).
var fails: int = 0
var neg: bool = false


func ok(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		fails += 1
		print("  FAIL ", what)


func _match() -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {}, {"intro": false, "power": true})
	return S


## The first standing building of a kind in the front row: "house", "low" (a tower under powerLowTowerMaxH) or "tall".
func _find(S: SimState, kind: String):
	var lim: float = float(WorldBrunt.cfg().powerLowTowerMaxH)
	for b in S.buildings:
		if not b.alive or int(b.row) != 1:
			continue
		var house: bool = WorldBrunt.isHouse(b)
		if (kind == "house" and house) or (kind == "low" and not house and b.h < lim and b.floors >= WorldBrunt.FLOORS_MIN) or (kind == "tall" and not house and b.h >= lim):
			return b
	return null


## The speed that carries energy E in the model's unit.
func _sp(E: float) -> float:
	return SimPower.speedUnit * sqrt(E)


func _hit(S: SimState, b, E: float, marks: int) -> Dictionary:
	b.marks = marks
	return WorldBrunt.outcomeOf(S, b, WorldStructures.baseY(S, b) + 0.5 * b.h, _sp(E), 1.0)


func _init() -> void:
	neg = OS.get_cmdline_user_args().has("--negative-control")
	var S := _match()
	ok(S.powerOn, "the match has the energy model on")
	var c: Dictionary = WorldBrunt.cfg()
	var step: float = SimDetMath.pow(SimPower.energyTop, -(SimPower.tierShare / 3.0))
	var low = _find(S, "low")
	var tall = _find(S, "tall")
	var house = _find(S, "house")
	ok(low != null and tall != null and house != null, "the match has a house, a low tower and a tall tower")
	var mlow: float = WorldBrunt.massOf(low)
	var mtall: float = WorldBrunt.massOf(tall)
	# --- memory off (repeatMarks 0): marks do nothing, bit for bit
	c.repeatMarks = 0
	var a0: Dictionary = _hit(S, low, 3.0, 0)
	var a1: Dictionary = _hit(S, low, 3.0, 2)
	ok(str(a0) == str(a1), "repeatMarks 0: a marked building is met as an unmarked one, bit for bit")
	ok(WorldBrunt._memory(low) == 1.0, "... and its memory factor is exactly 1")
	# --- memory on (repeatMarks 2)
	c.repeatMarks = 2
	if neg:
		WorldBrunt._memoryOff = true
	ok(absf(WorldBrunt._memory(_mark(low, 0)) - 1.0) < 1.0e-12 and absf(WorldBrunt._memory(_mark(low, 1)) - step) < 1.0e-12 and absf(WorldBrunt._memory(_mark(low, 2)) - step * step) < 1.0e-12 and absf(WorldBrunt._memory(_mark(low, 4)) - step * step) < 1.0e-12, "the factor is one model tier a mark (%.3f, %.3f), capped at repeatMarks" % [step, step * step])
	# a send with less energy than a low tower's mass: held; marked once, it has enough
	var E: float = mlow * 0.8   # 80 percent of the mass: held when unmarked
	var h0: Dictionary = _hit(S, low, E, 0)
	var h1: Dictionary = _hit(S, low, E, 1)
	var h2: Dictionary = _hit(S, low, E, 2)
	ok(not bool(h0.pass) and bool(h1.pass) and bool(h2.pass), "a send of %.1f against a low tower's %.1f: held unmarked, through at one mark (mass %.2f) and at two" % [E, mlow, mlow * step])
	ok(float(h2.keep) > float(h1.keep) and float(h1.keep) > 0.0, "and it keeps more of its speed through a twice marked one (%.2f, then %.2f)" % [float(h1.keep), float(h2.keep)])
	# a send a tall tower holds at every mark: the damage it does rises by the step each mark (the hold's damage is energy over mass)
	var Et: float = mtall * step * step * 0.9   # held even at two marks
	var d0: float = float(_hit(S, tall, Et, 0).dmg)
	var d1: float = float(_hit(S, tall, Et, 1).dmg)
	var d2: float = float(_hit(S, tall, Et, 2).dmg)
	var held_all: bool = not bool(_hit(S, tall, Et, 0).pass) and not bool(_hit(S, tall, Et, 1).pass) and not bool(_hit(S, tall, Et, 2).pass)
	ok(held_all and d0 > 0.0 and absf(d1 / d0 - 1.0 / step) < 0.02 * (1.0 / step) and absf(d2 / d0 - 1.0 / (step * step)) < 0.02 / (step * step), "a tall tower that holds at every mark takes %.2fx then %.2fx the first send's damage (1 over the step: %.2f, %.2f)" % [d1 / maxf(d0, 1.0e-9), d2 / maxf(d0, 1.0e-9), 1.0 / step, 1.0 / (step * step)])
	# a house is gone through at every mark (Game Design: houses rarely matter)
	var k0: Dictionary = _hit(S, house, mlow, 0)
	var k2: Dictionary = _hit(S, house, mlow, 2)
	ok(bool(k0.pass) and bool(k2.pass), "a house is gone through unmarked and marked")
	# the hit itself marks the building (repeatMarks above 0), and the next send meets it weaker
	var S2 := _match()
	var lw = _find(S2, "low")
	var A = S2.fighters[1]
	var D = S2.fighters[0]
	lw.marks = 0
	var mm0: float = WorldBrunt._memory(lw)
	A.tier = 2.0
	D.state = "launched"
	D.launchBy = A
	D.launchT = 1.0
	D.vx = _sp(E)
	D.vy = 0.0
	D.x = lw.x - lw.w * 0.5 - 1.0
	D.y = WorldStructures.baseY(S2, lw) + 0.5 * lw.h
	D.z = lw.z
	WorldBrunt.hit(S2, D, lw, D.y, lw.x - lw.w * 0.5, 1.0)
	ok(lw.marks == 1 and WorldBrunt._memory(lw) < mm0, "a send that strikes a building marks it (%d) and the next meets it weaker (factor %.3f)" % [lw.marks, WorldBrunt._memory(lw)])
	# --- the held hit (Game Design, buildings.md section 9: heldMul 2): a held body stops in the building, so the hit is 2 x E over the mass of the covered floors' undamaged strength
	var tf: int = tall.floors
	var s1: Array = _sends(1.0, 1.7, 3)
	var s2: Array = _sends(2.0, 1.7, 3)
	var s3: Array = _sends(2.0, 3.4, 2)
	var s4: Array = _sends(2.0, 7.5, 1)
	ok(s1[2] == tf, "heldMul 1 (as before): three sends of 1.7 break no floor of a mass-15 tower (standing %s of %d)" % [str(s1), tf])
	ok(s2[0] == tf and s2[1] == tf and s2[2] < tf, "heldMul 2: three sends of 1.7 bring the covered floors down, on the third (standing %s of %d)" % [str(s2), tf])
	ok(s3[0] == tf and s3[1] < tf, "heldMul 2: two sends of 3.4 do, on the second (%s of %d)" % [str(s3), tf])
	ok(s4[0] < tf, "heldMul 2: a send of 7.5 breaks them on the first, held (%s of %d)" % [str(s4), tf])
	# houses are unchanged by it, and a low tower still goes through at one mark: the pass flags are the same
	c.repeatMarks = 2
	c.heldMul = 1.0
	var hk1: Dictionary = _hit(S, house, mlow * 0.5, 1)
	var lw1: Array = [bool(_hit(S, low, mlow * 0.8, 0).pass), bool(_hit(S, low, mlow * 0.8, 1).pass), bool(_hit(S, low, mlow * 0.8, 2).pass)]
	c.heldMul = 2.0
	var hk2: Dictionary = _hit(S, house, mlow * 0.5, 1)
	var lw2: Array = [bool(_hit(S, low, mlow * 0.8, 0).pass), bool(_hit(S, low, mlow * 0.8, 1).pass), bool(_hit(S, low, mlow * 0.8, 2).pass)]
	c.heldMul = 1.0
	ok(str(hk1) == str(hk2) and lw1 == lw2, "houses are unchanged by heldMul and a low tower holds, then goes through at one mark and two, as at heldMul 1 (%s)" % str(lw2))

	# a held body stays held when his hit brings the tower down (Game Design, buildings.md, M-03): a tower with 1 hit point left, a send of half its mass. He holds at the face for the hold and is never carried through at keepHi;
	# with the wall-hold data (wallRebound 0) he drops with the rubble at no added speed, and with the shipped wallRebound the face gives back that share of his speed and no more
	var rb0: float = float(c.wallRebound)
	var res: Array = []
	for rb in [0.0, rb0]:
		c.heldMul = 2.0
		c.repeatMarks = 2
		c.wallRebound = rb
		var S3 := _match()
		var t3 = _find(S3, "tall")
		t3.hp = 1.0
		var A3 = S3.fighters[1]
		var D3 = S3.fighters[0]
		A3.tier = 1.0
		D3.state = "launched"
		D3.launchBy = A3
		D3.launchT = 1.0
		var sp3: float = _sp(WorldBrunt.massOf(t3) * 0.5)
		D3.vx = sp3
		D3.vy = 0.0
		D3.x = t3.x - t3.w * 0.5 - 1.0
		D3.y = WorldStructures.baseY(S3, t3) + 0.5 * t3.h
		D3.z = t3.z
		WorldBrunt.hit(S3, D3, t3, D3.y, t3.x - t3.w * 0.5, 1.0)
		res.append([t3.alive, D3.vx, sp3, D3.splashed.size()])
	c.wallRebound = rb0
	ok(not bool(res[0][0]) and float(res[0][1]) == 0.0 and int(res[0][3]) == 0, "wallRebound 0: the tower fell, and he is held at the face with no speed added (vx %.0f, and he did not go through it: %d marks)" % [float(res[0][1]), int(res[0][3])])
	ok(not bool(res[1][0]) and float(res[1][1]) <= 0.0 and absf(float(res[1][1])) <= rb0 * float(res[1][2]) + 1.0e-6 and int(res[1][3]) == 0, "the shipped wallRebound %.2f: he comes off the face by that share of his speed at most (vx %.0f of %.0f) and never forward" % [rb0, float(res[1][1]), float(res[1][2])])
	c.heldMul = 1.0
	c.repeatMarks = 0
	WorldBrunt._memoryOff = false
	if neg:
		ok(fails >= 3, "negative control (no memory): the memory rows fail (%d did)" % fails)
		fails = 0 if fails >= 3 else 1
	print("MEMORYMODEL: %d check(s) failed" % fails)
	quit(0 if fails == 0 else 1)


## n sends of energy E at tower b in turn, each a real WorldBrunt.hit at the covered floors (the middle of the tower); returns the standing floors after each.
func _sends(heldMul: float, E: float, n: int) -> Array:
	var S := _match()
	var tw = _find(S, "tall")
	var c: Dictionary = WorldBrunt.cfg()
	c.heldMul = heldMul
	c.repeatMarks = 2
	tw.marks = 0
	var A = S.fighters[1]
	var D = S.fighters[0]
	var out: Array = []
	for k in range(n):
		A.tier = 1.0
		D.state = "launched"
		D.launchBy = A
		D.launchT = 1.0
		D.vx = _sp(E)
		D.vy = 0.0
		D.x = tw.x - tw.w * 0.5 - 1.0
		D.y = WorldStructures.baseY(S, tw) + 0.5 * tw.h
		D.z = tw.z
		WorldBrunt.hit(S, D, tw, D.y, tw.x - tw.w * 0.5, 1.0)
		var up: int = 0
		for j in range(tw.floors):
			if WorldBrunt.isStanding(tw, j):
				up += 1
		out.append(up if tw.alive else 0)
	c.heldMul = 1.0
	c.repeatMarks = 0
	SimCore.dispose(S)
	return out


func _mark(b, n: int):
	b.marks = n
	return b
