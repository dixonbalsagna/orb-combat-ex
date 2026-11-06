extends SceneTree
## The chase after a launch, by a plain tap (docs/design/power-scale.md section 4): no LT, the first tap free, the price rising, the newest
## press picks the blow, B drives him down, a catch holds him up, the 0.33 s to the next, a knock-back and a stick strike don't start one, a
## tap that reaches a landing lands as he gets up and can be guarded, a meteor's curve goes to the landing, a press made while the send holds
## him waits, off nothing runs. Two runs, one hash.
##   godot --headless --path . --script res://sim/director/tools/chase_tap_check.gd
## Ends on the verdict line.

var failed: int = 0
var _acks: Array = []
var _cues: Array = []


func _init() -> void:
	DirChaseTap.setForce(1)
	_readyCue()
	_free()
	_early()
	_prices()
	_newest()
	_drive()
	_hang()
	_carry()
	_noKi()
	_next()
	_knock()
	_stick()
	_curve()
	_held()
	_noFloat()
	_twice()
	DirChaseTap.setForce(0)
	_off()
	DirChaseTap.setForce(-1)
	print("CHASE: %d check(s) failed" % failed)
	quit(1 if failed > 0 else 0)


func _expect(ok: bool, what: String) -> void:
	print(("ok    " if ok else "FAIL  ") + what)
	if not ok:
		failed += 1


func _fresh(ki: float = 100.0) -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 11, {"p1": false, "p2": false}, {"intro": false})
	for f in S.fighters:
		f.ai = null
		f.act.v2 = true
		f.hp = 100000.0
		f.ki = 100.0
	S.fighters[0].ki = ki
	S.fighters[1].x = SimWrap.wrap(S.fighters[0].x + 60.0)
	S.fighters[1].y = S.fighters[0].y + 600.0
	S.out.fx.clear()
	return S


## Sends the rival up and across, from the first fighter, as a plain launch.
func _send(S: SimState, name_: String = "UPPERCUT") -> void:
	var A = S.fighters[0]
	var D = S.fighters[1]
	DirLaunch.doLaunch(S, A, D, {"name": name_, "ux": 0.6, "uy": 0.8}, 2400.0, false)


func _press(S: SimState, kind: String) -> SimIntent:
	var i := SimIntent.new()
	match kind:
		"light":
			i.light = true
		"heavy":
			i.heavy = true
		"sig":
			i.sig = true
	return i


func _step(S: SimState, i = null, d = null) -> bool:
	_acks = []
	_cues = []
	var live: bool = SimCore.step(S, [i if i != null else SimIntent.new(), d if d != null else SimIntent.new()])
	for e in S.out.fx:
		if e.type == "launch_plan":
			_cues.append("send:" + String(e.chosen))
	for e in S.out.fx:
		if e.type == "cue":
			if e.kind == "press_ack":
				_acks.append(String(e.text))
			else:
				_cues.append(String(e.kind) + ":" + String(e.text))
	S.out.fx.clear()
	S.out.feed.clear()
	return live


## A press, as the hub sends it: it waits out a hit-stop, and goes on the next live tick.
func _tap(S: SimState, kind: String) -> void:
	for _k in range(60):
		if _step(S, _press(S, kind)):
			return


func _gone(S: SimState, ticks: int) -> void:
	for _k in range(ticks):
		_step(S)


## Runs till his chase ends. Returns the ticks it took, or -1.
func _toEnd(S: SimState, limit: int = 600) -> int:
	var A = S.fighters[0]
	for k in range(limit):
		_step(S)
		if not DirChase.chasing(A):
			return k
	return -1


func _free() -> void:
	var S := _fresh(0.0)
	_send(S)
	_gone(S, 30)
	var A = S.fighters[0]
	var D = S.fighters[1]
	var n: int = D.launchN
	var hp: float = D.hp
	_tap(S, "light")
	_expect(DirChase.chasing(A), "a far tap with no LT and no ki chases: the first of a send is free")
	_expect(A.ki < 5.0, "... it cost nothing (%.1f, what comes back by itself)" % A.ki)
	var took: int = _toEnd(S)
	print("      caught after %d ticks; he's %s" % [took, D.state])
	_expect(took >= 0 and D.hp < hp, "... it ends with a blow on him (%.0f to %.0f)" % [hp, D.hp])
	_expect(took <= int(DirChaseTap.cfg().arriveTicks) + 2, "... inside arriveTicks (%d)" % took)
	_expect(D.launchN > n and D.state == "launched", "... and sends him on")
	SimCore.dispose(S)


## A press in the send's own hit-stop goes after him. The rush never jumps, and when he lands first the blow lands where he is.
func _early() -> void:
	var S := _fresh(100.0)
	var A = S.fighters[0]
	var D = S.fighters[1]
	D.x = SimWrap.wrap(A.x + 58.0)
	D.y = A.y + 200.0
	_send(S)
	_tap(S, "light")
	_expect(DirChase.chasing(A), "pressed as the send starts, in reach: it chases")
	var fastest: float = 0.0
	var hp: float = D.hp
	var steps: Array = []
	for _k in range(200):
		var ox: float = A.x
		var oy: float = A.y
		_step(S)
		if DirChase.chasing(A):
			var v: float = SimDetMath.hypot(SimWrap.sdx(ox, A.x), A.y - oy) / SimConst.DT
			fastest = maxf(fastest, v)
			steps.append(v)
	var ease: int = int(DirChaseTap.cfg().easeTicks)
	var built: bool = steps.size() > 3
	for k in range(mini(ease - 2, steps.size())):
		built = built and steps[k] <= float(DirChaseTap.cfg().maxSpeed) * float(k + 3) / float(ease)
	_expect(built, "its start eases: %s" % str(steps.slice(0, 5)))
	print("      fastest %.0f" % fastest)
	print("      (on him, he moves at the body's own speed: that's in this figure)")
	_expect(fastest <= float(DirChaseTap.cfg().maxSpeed) * 1.6, "the rush never jumps (%.0f)" % fastest)
	_expect(D.hp < hp, "... and the blow lands")
	SimCore.dispose(S)
	var took: Array = []
	for guard in [false, true]:
		S = _fresh(0.0)
		A = S.fighters[0]
		D = S.fighters[1]
		_send(S)
		_gone(S, 10)
		D.vx = 0.0
		D.x = SimWrap.wrap(A.x + 9000.0)
		D.vy = -3000.0
		D.y = SimFighter.floorFor(S, D, D.x, D.z) + 700.0
		hp = D.hp
		_tap(S, "heavy")
		var g := SimIntent.new()
		g.guard = guard
		var landed: bool = false
		var downSeen: bool = false
		var k: int = 0
		var at: int = -1
		var state: String = ""
		while k < 240:
			_step(S, null, g)
			if not landed and D.state != "launched":
				landed = true
				hp = D.hp   # (his landing's own impact is taken by now)
			downSeen = downSeen or D.state == "down"
			k += 1
			if _cues.has("chase:rise"):
				at = k
				state = D.state
				break
		took.append(hp - D.hp)
		print("      %s: he'd landed %s, down %s; the blow landed at %d with him %s, %.0f taken" % ["guarding" if guard else "open", str(landed), str(downSeen), at, state, hp - D.hp])
		if not guard:
			_expect(downSeen and state == "free" and D.hp <= hp - float(DirZip.cfg().heavy.damage) * 0.9, "he comes down first: the blow waits, and lands as he gets up (%.0f)" % (hp - D.hp))
		else:
			_expect(float(took[1]) > 0.0 and float(took[1]) < 0.6 * float(took[0]), "... an ordinary blow: his guard takes it (%.0f against %.0f)" % [took[1], took[0]])
		SimCore.dispose(S)


## The hint's cue: once a send, for a player, and not for a knock-back.
func _readyCue() -> void:
	var S := _fresh(100.0)
	_send(S)
	var n: int = 0
	for e in S.out.fx:
		if e.type == "cue" and e.kind == "chase_ready":
			n += 1
	_expect(n == 1, "a send says a chase is ready (%d)" % n)
	S.out.fx.clear()
	DirLaunch.doLaunch(S, S.fighters[0], S.fighters[1], {"name": "KNOCK BACK", "ux": 0.8, "uy": 0.3}, 2400.0, false)
	n = 0
	for e in S.out.fx:
		if e.type == "cue" and e.kind == "chase_ready":
			n += 1
	_expect(n == 0, "... and a knock-back doesn't")
	SimCore.dispose(S)


func _prices() -> void:
	var S := _fresh(100.0)
	_send(S)
	_gone(S, 30)
	var A = S.fighters[0]
	var seen: Array = []
	for _n in range(6):
		var before: float = A.ki
		_tap(S, "light")
		if not DirChase.chasing(A):
			seen.append(-1.0)
			break
		seen.append(before - A.ki)
		_toEnd(S)
		_gone(S, 4)
	print("      X, X, X...: ", str(seen))
	_expect(seen.size() >= 4 and seen[0] < 1.0 and absf(seen[1] - 20.0) < 1.0 and absf(seen[2] - 30.0) < 1.0 and absf(seen[3] - 45.0) < 1.0, "free, 20, 30, 45: the price rises 1.5 times each")
	_expect(seen[seen.size() - 1] == -1.0 and seen.size() <= 6, "from a full bar he runs out at about the fifth")
	SimCore.dispose(S)


func _newest() -> void:
	var S := _fresh(100.0)
	_send(S)
	_gone(S, 30)
	var A = S.fighters[0]
	_tap(S, "light")
	_toEnd(S)
	_gone(S, 2)
	var k0: float = A.ki
	_tap(S, "light")
	_expect(absf(k0 - A.ki - 20.0) < 1.0, "X pays 20")
	_step(S, SimIntent.new())
	_tap(S, "heavy")
	_expect(absf(k0 - A.ki - 30.0) < 1.0, "Y during the rush takes the blow, and pays the difference (%.1f)" % (k0 - A.ki))
	_expect(DirChase._g(A, DirChase.CH_W) == 2, "the newest press is the blow")
	_step(S, SimIntent.new())
	_tap(S, "light")
	_expect(absf(k0 - A.ki - 20.0) < 1.0, "X again gives it back")
	_expect(DirChase._g(A, DirChase.CH_W) == 1, "... and it's the strike")
	_expect(DirChase.chasing(A), "no press ends it or queues another")
	SimCore.dispose(S)


func _drive() -> void:
	var S := _fresh(100.0)
	_send(S)
	_gone(S, 30)
	var A = S.fighters[0]
	var D = S.fighters[1]
	var hp: float = D.hp
	_tap(S, "light")
	_step(S, SimIntent.new())
	_tap(S, "sig")
	_expect(DirChase._g(A, DirChase.CH_W) == 3, "B during the rush is the drive")
	var took: int = _toEnd(S)
	print("      caught after %d ticks, he's sent at %.0f, %.0f, took %.0f" % [took, D.vx, D.vy, hp - D.hp])
	_expect(D.vy < 0.0, "... and it sends him down (vy %.0f)" % D.vy)
	SimCore.dispose(S)


## A catch holds him up: at least minAirTicks in the air after it, on the path the planner gave him. B's drive doesn't.
func _hang() -> void:
	var minAir: int = int(DirChaseTap.cfg().minAirTicks)
	var lands: Array = []
	for mode in [0, 1, 2]:   # a short send down: no hang, the catch's hang, the hang asked for B's drive
		var S2 := _fresh(100.0)
		var A2 = S2.fighters[0]
		var D2 = S2.fighters[1]
		D2.x = SimWrap.wrap(A2.x + 150.0)
		D2.y = SimFighter.floorFor(S2, D2, D2.x, D2.z) + 300.0
		DirLaunch.doLaunch(S2, A2, D2, {"name": "SLAM DOWN", "ux": 0.4, "uy": -0.9}, 1600.0, false)
		if mode > 0:
			DirChaseTap.hang(S2, A2, D2, mode == 2)
		var k2: int = 0
		while D2.state == "launched" and k2 < 300:
			_step(S2)
			k2 += 1
		lands.append([k2, D2.x])
		SimCore.dispose(S2)
	var apart: float = absf(SimWrap.sdx(float(lands[0][1]), float(lands[1][1])))
	print("      a short send down: %d ticks in the air plain, %d with the hang, landing %.1f apart; B's drive %d" % [lands[0][0], lands[1][0], apart, lands[2][0]])
	_expect(int(lands[0][0]) < minAir and int(lands[1][0]) >= minAir and apart < 0.25 * DirInterrupt.BH, "a short send is held up to minAirTicks, and he lands where he would")
	_expect(int(lands[2][0]) == int(lands[0][0]), "B's drive isn't held up")
	for drive in [false]:
		var S := _fresh(100.0)
		_send(S)
		_gone(S, 5)
		var A = S.fighters[0]
		var D = S.fighters[1]
		D.x = SimWrap.wrap(A.x + 150.0)
		D.vx = 0.0
		D.vy = 0.0
		D.y = SimFighter.floorFor(S, D, D.x, D.z) + 450.0   # caught low, so his send is short
		var n0: int = D.launchN
		_tap(S, "light")
		if drive:
			_step(S, SimIntent.new())
			_tap(S, "sig")
		var at: int = -1
		var air: int = -1
		var hung: int = 0
		for k in range(400):
			_step(S)
			if at < 0 and D.launchN > n0:
				at = k
				hung = DirChaseTap._g(D, DirChaseTap.T_HK)
				print("      at the catch: %s, %.0f up, sent at %.0f, %.0f" % [str(_cues.filter(func(c): return String(c).begins_with("send:"))), D.y - SimFighter.floorFor(S, D, D.x, D.z), D.vx, D.vy])
			elif at >= 0 and D.state != "launched":
				air = k - at
				break
		print("      %s: caught at %d, sent at %.0f, %.0f, then %d ticks in the air, hang pace %.2f" % ["a real catch", at, D.vx, D.vy, air, float(hung) / 4096.0])
		_expect(at >= 0 and air >= minAir, "after a real catch he's up at least minAirTicks (%d)" % air)
		SimCore.dispose(S)


## The catch's carry: the chaser doesn't stop dead. His speed the tick after the catch is most of what it was, and it falls to nothing
## over carryTicks with no step bigger than a third of it.
func _carry() -> void:
	var S := _fresh(100.0)
	var A = S.fighters[0]
	var D = S.fighters[1]
	_send(S)
	_gone(S, 20)
	_tap(S, "light")
	var speeds: Array = []
	var at: int = -1
	var ox: float = A.x
	var oy: float = A.y
	for k in range(120):
		var was: bool = DirChase.chasing(A)
		if not _step(S):
			continue   # a hit-stop holds everything: the speeds are of live ticks
		var v: float = SimDetMath.hypot(SimWrap.sdx(ox, A.x), A.y - oy) / SimConst.DT
		ox = A.x
		oy = A.y
		speeds.append(v)
		if was and not DirChase.chasing(A) and at < 0:
			at = speeds.size() - 1
		if at >= 0 and speeds.size() - at > int(DirChaseTap.cfg().carryTicks) + 3:
			break
	var near: Array = speeds.slice(maxi(0, at - 2), mini(speeds.size(), at + int(DirChaseTap.cfg().carryTicks) + 3))
	var steps: Array = []
	for v in near:
		steps.append(snappedf(float(v), 1.0))
	print("      the chaser's speed around the catch: %s" % str(steps))
	var before: float = float(speeds[at - 1]) if at > 0 else 0.0
	var worst: float = 0.0
	for i in range(at, mini(speeds.size() - 1, at + int(DirChaseTap.cfg().carryTicks) + 1)):
		worst = maxf(worst, float(speeds[i]) - float(speeds[i + 1]))
	_expect(at > 0 and before > 0.0 and worst <= before / 3.0, "the catch doesn't stop him dead: no tick falls more than a third (%.0f of %.0f)" % [worst, before])
	SimCore.dispose(S)


func _noKi() -> void:
	var S := _fresh(0.0)
	_send(S)
	_gone(S, 30)
	var A = S.fighters[0]
	_tap(S, "light")
	_toEnd(S)
	_gone(S, 2)
	A.ki = 0.0
	_tap(S, "light")
	_expect(not DirChase.chasing(A) and A.rush == null, "no ki for the second: he doesn't go")
	_expect(_acks.has("chase_no_ki"), "... and the press says why (%s)" % str(_acks))
	SimCore.dispose(S)


func _next() -> void:
	var S := _fresh(100.0)
	_send(S)
	_gone(S, 30)
	var A = S.fighters[0]
	var D = S.fighters[1]
	_tap(S, "light")
	_toEnd(S)
	var live0: int = DirBrawl._now(S)
	_tap(S, "light")
	_expect(DirChase.chasing(A), "a press just after the blow starts the next")
	var hp1: float = D.hp
	var ticks: int = 0
	while DirChase.chasing(A) and ticks < 200:
		_step(S)
		ticks += 1
	_expect(DirBrawl._now(S) - live0 >= int(DirChaseTap.cfg().minCatchTicks), "... and it doesn't land at once, in the blow's own hit-stop (%d live ticks)" % (DirBrawl._now(S) - live0))
	SimCore.dispose(S)
	# No press: he peels off.
	S = _fresh(100.0)
	_send(S)
	_gone(S, 30)
	A = S.fighters[0]
	D = S.fighters[1]
	_tap(S, "light")
	_toEnd(S)
	var x0: float = A.x
	var y0: float = A.y
	_gone(S, 40)
	_expect(not DirChase.chasing(A) and A.rush == null, "no press: he peels off, and nothing carries him")
	print("      moved %.0f in 40 ticks after the blow; the body's %.0f away" % [SimDetMath.hypot(SimWrap.sdx(x0, A.x), A.y - y0), DirBands.dist(A, D)])
	SimCore.dispose(S)


func _knock() -> void:
	var S := _fresh(100.0)
	var A = S.fighters[0]
	var D = S.fighters[1]
	DirLaunch.doLaunch(S, A, D, {"name": "KNOCK BACK", "ux": 0.8, "uy": 0.3}, 2400.0, false)
	_gone(S, 2)
	D.x = SimWrap.wrap(A.x + 3000.0)
	if D.state == "launched":
		_tap(S, "light")
		_expect(not DirChase.chasing(A), "a knock-back isn't a send: no chase")
	else:
		_expect(false, "a knock-back: he's %s after 16 ticks" % D.state)
	SimCore.dispose(S)


func _stick() -> void:
	DirStick.setForce(1)
	var S := _fresh(100.0)
	_send(S)
	_gone(S, 30)
	var A = S.fighters[0]
	var i := SimIntent.new()
	i.rsStart = true
	i.rsHeld = true
	i.rsDir = SimStrikeRead.RIGHT
	_step(S, i)
	_expect(not DirChase.chasing(A) and DirStick._g(A, DirStick.ST_PEND) == 0, "a stick strike at him in the air: no chase, and it never sends")
	_expect(_cues.has("stick_refused:toward") or _cues.has("stick_refused:away"), "... and it says so (%s)" % str(_cues))
	SimCore.dispose(S)
	DirStick.setForce(-1)


func _curve() -> void:
	DirArc.setForce(1)
	var S := _fresh(100.0)
	var A = S.fighters[0]
	var D = S.fighters[1]
	DirArc.send(S, A, D, 0, 1.0)
	var land: Dictionary = DirArc.landing(D)
	_gone(S, 60)
	var hp: float = D.hp
	var left: int = int(DirArc.landing(D).ticks)
	_tap(S, "light")
	_expect(DirChase.chasing(A), "a tap on the curve goes")
	_expect(A.ki == 100.0, "... free")
	var n: int = D.launchN
	var k: int = 0
	var caught: bool = false
	while D.state == "launched" and k < left + 60:
		_step(S)
		caught = caught or _cues.has("chase:catch")
		k += 1
	var off: float = absf(SimWrap.sdx(A.x, float(land.x)))
	print("      %d ticks left when pressed; he's down after %d, the chaser %.0f from the landing" % [left, k, off])
	_expect(off < 400.0, "... he's at the landing as he lands (%.0f)" % off)
	_expect(not caught, "... with no catch on the way")
	var risen: String = ""
	var hp2: float = D.hp
	for _k in range(120):
		_step(S)
		if _cues.has("chase:rise"):
			risen = D.state
			break
	print("      the blow at his landing: %s, %.0f taken" % [risen, hp2 - D.hp])
	_expect(risen == "free", "... and the tap lands as he gets up")
	_expect(not DirChase.chasing(A), "... and it's over")
	SimCore.dispose(S)
	DirArc.setForce(-1)


## A press while an exchange holds him waits for his first free tick. The newest wins, and it lapses.
func _held() -> void:
	var S := _fresh(100.0)
	_send(S)
	var A = S.fighters[0]
	var D = S.fighters[1]
	A.stunTicks = 6
	DirExchange.requestAttack(S, A, "light")
	_expect(_saidThis(S, "chase_held"), "pressed while he can't act: it waits")
	_expect(not DirChase.chasing(A), "... not yet")
	DirExchange.requestAttack(S, A, "heavy")
	var k: int = 0
	while not DirChase.chasing(A) and k < 30:
		_step(S)
		k += 1
	_expect(DirChase.chasing(A) and DirChase._g(A, DirChase.CH_W) == 2, "... it goes when he's free, the newest (%d ticks)" % k)
	SimCore.dispose(S)
	S = _fresh(100.0)
	_send(S)
	A = S.fighters[0]
	A.stunTicks = 200
	DirExchange.requestAttack(S, A, "light")
	var said: bool = false
	for _j in range(40):
		_step(S)
		said = said or _acks.has("chase_late")
	_expect(said and not DirChase.chasing(A), "... and if he's held too long it lapses, and says so")
	SimCore.dispose(S)


func _saidThis(S: SimState, what: String) -> bool:
	for e in S.out.fx:
		if e.type == "cue" and e.kind == "press_ack" and String(e.text) == what:
			return true
	return false


## With the far follow's switch on as well, a far tap at a body in the air never rides along.
func _noFloat() -> void:
	DirFollow.setForce(1)
	var S := _fresh(0.0)
	_send(S)
	_gone(S, 30)
	var A = S.fighters[0]
	var D = S.fighters[1]
	_tap(S, "light")
	_toEnd(S)
	_gone(S, 60)
	_expect(A.rush == null, "with the far follow on, he doesn't ride along")
	_expect(not DirFollow.keepOn(S, A), "... keepOn is off")
	SimCore.dispose(S)
	DirFollow.setForce(-1)


func _twice() -> void:
	var a: String = _run()
	var b: String = _run()
	_expect(a == b, "two runs, one hash (%s)" % a.substr(0, 16))


func _run() -> String:
	var S := _fresh(100.0)
	_send(S)
	_gone(S, 30)
	for k in range(600):
		_step(S, _press(S, ["light", "heavy", "sig"][k % 3]) if k % 17 == 0 else null)
	var h: String = String(SimHash.stateHash(S).gameplay)
	SimCore.dispose(S)
	return h


func _off() -> void:
	var S := _fresh(100.0)
	_send(S)
	_gone(S, 30)
	var A = S.fighters[0]
	var n: int = A.act.dirI.size()
	_tap(S, "light")
	_expect(not DirChase.chasing(A), "off: a tap is what it was")
	_expect(A.act.dirI.size() <= n or A.act.dirI.size() < DirChaseTap._b() + DirChaseTap.T_N, "off: no slot is sized (%d)" % A.act.dirI.size())
	SimCore.dispose(S)
