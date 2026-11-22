extends SceneTree
# The wall slam without ping-pong (World, sim/world/brunt.gd, data/biomes/brunt.json wallRebound, wallStop, wallDepthHold with lodgeHold body and repeatMarks; docs/world/wall-hold.md): Orb, 2026-11-06,
# "the fighter that collided with a building bounced back into the plane like a ping pong ball". Today a face that holds him freezes the whole fight (the hit-stop and the lodge's seconds), throws him back at a quarter of his
# speed and eases his depth home in a third of a second. Set on, only he is held, he stays at the face for the hold and his depth with him, and the building remembers, so repeats break it. Defaults are today's behaviour.
#   godot --headless --path . --script res://sim/world/tools/wall_hold_check.gd
var fails: int = 0


func ok(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		fails += 1
		print("  FAIL ", what)


func _setv(on: bool) -> void:
	var c: Dictionary = WorldBrunt.cfg()
	c.lodgeHold = "body" if on else "world"
	c.wallRebound = 0.0 if on else 0.25
	c.wallStop = 0.0 if on else 1.0
	c.wallDepthHold = 1 if on else 0


func _tower(S: SimState):
	for b in S.buildings:
		if b.floors >= 9 and b.floors <= 15 and int(b.row) == 1:
			return b
	return null


## One slam at a tower, then 150 ticks: [freeze seconds at the hit, peak distance off the face while he is stunned, ticks until his depth is within 20 of the line, hash], or [] when it was not a wall.
func _slam(seed: int, tier: float) -> Array:
	var S := SimCore.createSim()
	SimCore.newMatch(S, seed, {}, {"intro": false})
	S.out.fx.clear()
	var A = S.fighters[1]
	var D = S.fighters[0]
	var tw = _tower(S)
	if tw == null:
		return []
	A.tier = tier
	D.hp = 1.0e9
	A.hp = 1.0e9
	D.x = SimWrap.wrap(tw.x - 3000.0)
	D.y = WorldTerrain.groundY(S, D.x) + 100.0
	var plan = WorldBrunt.aim(S, A, D, tw, 2000.0, 1.0 + A.ld.launch * (tier - 1.0), false)
	if plan == null:
		return []
	DirLaunch.doLaunch(S, A, D, plan, 2000.0)
	var wall: bool = false
	var hit: bool = false
	var g: int = 0
	while g < 900 and not hit:
		SimCore.step(S, null)
		g += 1
		for e in S.out.fx:
			if e.type == "building_hit":
				hit = true
				wall = wall or String(e.outcome) == "wall"
	if not wall:
		SimCore.dispose(S)
		return []
	var freeze: float = float(S.dirS.stop)
	var tHit: int = S.tick
	var faceX: float = tw.x - tw.w * 0.5
	var peak: float = 0.0
	var home: int = -1
	var stunned: bool = true
	for t in range(150):
		SimCore.step(S, null)
		if stunned and D.stunTicks <= 0:
			stunned = false
		if stunned:
			peak = maxf(peak, faceX - D.x)
		if home < 0 and absf(D.z) < 20.0:
			home = S.tick - tHit
	var h: String = str(SimHash.stateHash(S).gameplay)
	SimCore.dispose(S)
	return [freeze, peak, home, h]


## Three sends at one tower: [how many of the 24 towers fell].
var _broken: int = 0   # the last _repeats's towers that lost a floor or fell (a held hit under the energy model breaks the covered floors; the tower stands until its core goes)


func _repeats(marks: int) -> int:
	_broken = 0
	WorldBrunt.cfg().repeatMarks = marks
	var down: int = 0
	for sd in range(1, 13):
		for tier in [1.0, 2.0]:
			var S := SimCore.createSim()
			SimCore.newMatch(S, sd, {}, {"intro": false})
			S.out.fx.clear()
			WorldBrunt.cfg().heldMul = 2.0 if S.powerOn else 1.0   # Game Design's held hit (buildings.md section 9): with the model on, twice E over the mass
			var tw = _tower(S)
			if tw == null:
				continue
			var A = S.fighters[1]
			var D = S.fighters[0]
			var up0: int = 0
			for j in range(tw.floors):
				if WorldBrunt.isStanding(tw, j):
					up0 += 1
			for k in range(3):
				if not tw.alive:
					break
				A.tier = tier
				D.hp = 1.0e9
				A.hp = 1.0e9
				D.state = "free"
				D.stunTicks = 0
				D.x = SimWrap.wrap(tw.x - 3000.0)
				D.y = WorldTerrain.groundY(S, D.x) + 100.0
				D.vx = 0.0
				D.vy = 0.0
				var plan = WorldBrunt.aim(S, A, D, tw, 2000.0, 1.0 + A.ld.launch * (tier - 1.0), false)
				if plan == null:
					break
				DirLaunch.doLaunch(S, A, D, plan, 2000.0)
				var g: int = 0
				while D.state == "launched" and g < 1800:
					S.dirS.stop = 0.0
					SimFighter.stepLaunched(S, D, SimConst.DT)
					S.out.fx.clear()
					g += 1
			if not tw.alive:
				down += 1
			var up1: int = 0
			for j in range(tw.floors):
				if tw.alive and WorldBrunt.isStanding(tw, j):
					up1 += 1
			if up1 < up0:
				_broken += 1
			SimCore.dispose(S)
	WorldBrunt.cfg().repeatMarks = 0
	WorldBrunt.cfg().heldMul = 1.0
	return down


func _run(model: bool) -> void:
	WorldPin.launchTravelOld()   # GW1b: the staged send at a tower 3,000 units away was written for the launch travel 2.0 (now 1.5): memory only
	WorldPin.shipped(model)   # GW1a: run twice, with the energy model and the dash off (the path main shipped before the data went on) and on (Orb's real path); docs/world/pins-and-the-model.md
	print("--- the energy model and the dash %s" % ("ON (Orb's real path)" if model else "OFF (main before GW1a)"))
	var c: Dictionary = WorldBrunt.cfg()
	ok(WorldBrunt.dataErrors().is_empty(), "brunt.json loads clean (%s)" % str(WorldBrunt.dataErrors()))
	ok(c.lodgeHold == "world" and absf(float(c.wallRebound) - 0.25) < 1.0e-9 and float(c.wallStop) == 1.0 and int(c.wallDepthHold) == 0 and int(c.repeatMarks) == 0, "the data's defaults are today's behaviour (lodgeHold %s, wallRebound %s, wallStop %s, wallDepthHold %s, repeatMarks %s)" % [c.lodgeHold, str(c.wallRebound), str(c.wallStop), str(c.wallDepthHold), str(c.repeatMarks)])
	var offN: int = 0
	var onN: int = 0
	var offFreeze: float = 0.0
	var onFreeze: float = 0.0
	var offFar: int = 0
	var onFar: int = 0
	var offHome: float = 0.0
	var onHome: float = 0.0
	var offPeak: float = 0.0
	var onPeak: float = 0.0
	var twice: bool = true
	for sd in range(1, 9):
		for tier in [1.0, 2.0, 3.0]:
			_setv(false)
			var a: Array = _slam(sd, tier)
			_setv(true)
			var b: Array = _slam(sd, tier)
			var b2: Array = _slam(sd, tier)
			if a.is_empty() or b.is_empty():
				continue
			twice = twice and str(b[3]) == str(b2[3])
			offN += 1
			onN += 1
			offFreeze += a[0]
			onFreeze += b[0]
			offPeak += a[1]
			onPeak += b[1]
			offHome += float(a[2])
			onHome += float(b[2])
			if a[1] > 150.0:
				offFar += 1
			if b[1] > 150.0:
				onFar += 1
	_setv(false)
	ok(offN >= 12, "%d wall slams staged on towers (seeds 1 to 8, tiers 1 to 3)" % offN)
	print("      today: the whole fight frozen %.2f s at the hit; pushed %.0f units off the face (more than 150 off in %d of %d); depth home in %.0f ticks" % [offFreeze / float(offN), offPeak / float(offN), offFar, offN, offHome / float(offN)])
	print("      set on: the whole fight frozen %.2f s; pushed %.0f units off the face (more than 150 off in %d of %d); depth home in %.0f ticks" % [onFreeze / float(onN), onPeak / float(onN), onFar, onN, onHome / float(onN)])
	if not model:
		ok(offFreeze / float(offN) >= 0.45 and offFar == offN, "today the fight freezes at the hit and he is thrown off the face (%d of %d)" % [offFar, offN])
	else:
		ok(offFreeze / float(offN) >= 0.45 and offPeak / float(offN) <= 150.0, "with the energy model on, until the wall-hold data: the fight still freezes at the hit (%.2f s) and he is pushed %.0f units off the face (the throw is no longer the 1,154 of the old path; ceiling 150 on the average, it may only come down)" % [offFreeze / float(offN), offPeak / float(offN)])
	ok(onFreeze == 0.0, "set on: nothing freezes the whole fight (only he is held)")
	ok(onFar == 0 and onPeak / float(onN) <= 40.0, "set on: he stays at the face for the hold (%.0f units off on average)" % [onPeak / float(onN)])
	ok(onHome / float(onN) > 28.0, "set on: his depth stays for the hold and then eases home (%.0f ticks)" % [onHome / float(onN)])
	ok(twice, "the same slam twice gives one hash")
	var d0: int = _repeats(0)
	var b0: int = _broken
	var d2: int = _repeats(2)
	var b2: int = _broken
	print("      three sends at one tower, 24 towers: %d fall with the building's memory off, %d with repeatMarks 2; %d and %d lost a floor or fell" % [d0, d2, b0, b2])
	if not model:
		ok(d0 == 0 and d2 >= 20, "the building remembers: repeats break it (0 fall off, %d of 24 with repeatMarks 2)" % d2)
	else:
		ok(b2 > b0 and d2 >= d0, "with the energy model on a mark is one model tier of the building's mass and a held hit does heldMul 2 (Game Design, buildings.md section 9; memory_model_check): three sends at the model's energy break the covered floors of %d of 24 towers with the memory against %d without (%d and %d fall)" % [b2, b0, d2, d0])


func _init() -> void:
	_run(false)
	_run(true)
	print("WALLHOLD: %d check(s) failed" % fails)
	quit(0 if fails == 0 else 1)
