extends SceneTree
## Beams that travel (docs/design/rule-of-cool-map.md section 5, row 40): arrival by the table at any range; the window's cues; a dodge
## counts only near arrival; a fire-back inside the window starts a struggle where the fronts meet, later nearer his hands; off, today's
## 20 ticks; two runs, one hash.
##   godot --headless --path . --script res://sim/director/tools/beam_front_check.gd
## Ends on the verdict line.

var failed: int = 0
var _open: int = 0
var _close: int = 0
var _openN: int = 0
var _outcome: String = ""
var _fireAt: int = -1


func _init() -> void:
	var bs: Dictionary = DirBeam._bs()
	bs["enabled"] = true
	DirBeamPlay.setFrontForce(1)
	_table()
	_arrives()
	_dodges()
	_dodgeEdges()
	_litHand()
	_standoff()
	_cantPay()
	_fireBack()
	_twice()
	DirBeamPlay.setFrontForce(0)
	_off()
	DirBeamPlay.setFrontForce(-1)
	bs["enabled"] = false
	print("FRONT: %d check(s) failed" % failed)
	quit(1 if failed > 0 else 0)


func _expect(ok: bool, what: String) -> void:
	print(("ok    " if ok else "FAIL  ") + what)
	if not ok:
		failed += 1


func _fresh(gap: float) -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 11, {"p1": false, "p2": false}, {"intro": false})
	for f in S.fighters:
		f.ai = null
		f.act.v2 = true   # a player's slot: the dodge and the queue are read
		f.hp = 100000.0
		f.ki = 100.0
	S.fighters[1].x = SimWrap.wrap(S.fighters[0].x + gap)
	S.fighters[1].y = S.fighters[0].y
	S.out.fx.clear()
	_open = 0
	_close = 0
	_openN = 0
	_outcome = ""
	_fireAt = -1
	return S


func _step(S: SimState, a: SimIntent = null, d: SimIntent = null) -> void:
	SimCore.step(S, [a if a != null else SimIntent.new(), d if d != null else SimIntent.new()])
	for e in S.out.fx:
		if e.type == "cue" and e.kind == "beam_window":
			if e.text == "start":
				_open += 1
				_openN = S.tick + int(e.n)
				_fireAt = S.tick
			else:
				_close += 1
		elif e.type == "beam_outcome" or e.type == "beamOutcome":
			_outcome = String(e.get("outcome")) if "outcome" in e else _outcome
	S.out.fx.clear()
	S.out.feed.clear()


func _fire(S: SimState) -> void:
	var a := SimIntent.new()
	a.sig = true
	a.stanceMask = 4   # the charging stance: B is the signature, and RB's is the Driver's
	_step(S, a)
	var guard: int = 0
	while _fireAt < 0 and guard < 400:
		_step(S)
		guard += 1


func _table() -> void:
	print("      plays on %s, at fire %s, front on %s" % [str(DirBeamPlay.on()), str(DirData.beamAtFire()), str(DirBeamPlay.frontOn())])
	_expect(DirBeamPlay.frontTicks(0.0, "signature") == 36, "the floor at no distance")
	_expect(DirBeamPlay.frontTicks(2400.0, "signature") == 54, "the floor plus the distance at its speed (%d)" % DirBeamPlay.frontTicks(2400.0, "signature"))
	_expect(DirBeamPlay.frontTicks(100000.0, "signature") == 60, "the ceiling across a planet")
	_expect(DirBeamPlay.frontTicks(100000.0, "snap") == 20, "the snap's ceiling")


func _arrives() -> void:
	for gap in [600.0, 2400.0, 9000.0]:
		var S := _fresh(gap)
		_fire(S)
		var want: int = DirBeamPlay.frontTicks(absf(SimWrap.sdx(S.fighters[0].x, S.fighters[1].x)), "signature")
		_expect(_open == 1 and _openN - _fireAt >= 36 and _openN - _fireAt <= 60, "%.0f away: the window opens, %d ticks to arrival" % [gap, _openN - _fireAt])
		var hp: float = S.fighters[1].hp
		var early: bool = false
		for _k in range(_openN - _fireAt - 1):
			_step(S)
			early = early or S.fighters[1].hp < hp
		_expect(not early, "%.0f away: nothing lands before the front" % gap)
		for _k in range(12):
			_step(S)
		_expect(_close == 1, "%.0f away: the window closes once (%d)" % [gap, _close])
		_expect(S.fighters[1].hp < hp, "%.0f away: it lands on arrival" % gap)
		SimCore.dispose(S)


func _tap() -> SimIntent:
	var i := SimIntent.new()
	i.dodge = true
	return i


func _dodges() -> void:
	# a tap too early is followed; one in the last ticks takes him clear
	for row in [["too early", false], ["near arrival", true]]:
		var S := _fresh(9000.0)
		_fire(S)
		var tv: int = _openN - _fireAt
		var hp: float = S.fighters[1].hp
		var tapAt: int = 3 if not bool(row[1]) else tv - 6
		for k in range(tv + 14):
			_step(S, null, _tap() if k == tapAt else null)
		var hit: bool = S.fighters[1].hp < hp
		_expect(hit != bool(row[1]), "a dodge %s: %s" % [row[0], "he takes it" if hit else "he's clear"])
		SimCore.dispose(S)


func _midAfter(k: int) -> float:
	var S := _fresh(9000.0)
	_fire(S)
	for _n in range(k):
		_step(S)
	var y := SimIntent.new()
	y.sig = true
	y.stanceMask = 2
	S.fighters[1].sigReadyT = 0.0
	_step(S, null, y)
	_step(S)
	_step(S)
	var mid: float = float(S.game.clash.mid) if S.game.clash != null else -1.0
	SimCore.dispose(S)
	return mid


func _fireBack() -> void:
	var soon: float = _midAfter(2)
	var late: float = _midAfter(40)
	print("      the struggle's start: answered at once %.3f, late %.3f" % [soon, late])
	_expect(soon >= 0.0, "a fire-back starts a struggle")
	_expect(late > soon + 0.05, "a late one meets nearer his hands")
	_expect(late <= 0.5 + float(DirBeamPlay.frontCfg().meetMax) + float(DirBeam._bs().headMax) + 0.001, "and no further than the data lets it")
	var S := _fresh(9000.0)
	_fire(S)
	S.fighters[1].ki = 0.0
	_expect(not DirBeamPlay.fireBack(S, S.fighters[1]), "can't pay, no answer")
	S.fighters[1].ki = 100.0
	_expect(DirBeamPlay.windowOpen(S, S.fighters[1]), "the window's open on the receiver")
	_expect(not DirBeamPlay.windowOpen(S, S.fighters[0]), "and not on the shooter")
	_expect(DirBeamPlay.fireBack(S, S.fighters[1]), "the stick's fire-back, at level 1's ki")
	_expect(S.game.clash != null, "and that's a struggle")
	_expect(S.fighters[1].ki == 100.0 - float(DirBeamPlay.frontCfg().answerKi), "at its price")
	SimCore.dispose(S)


func _run():
	var S := _fresh(2400.0)
	_fire(S)
	for _k in range(80):
		_step(S)
	var h = SimHash.stateHash(S)
	SimCore.dispose(S)
	return h


func _twice() -> void:
	_expect(_run() == _run(), "two runs, one hash")


func _off() -> void:
	var S := _fresh(9000.0)
	_fire(S)
	_expect(_open == 0, "off: no window cue")
	_expect(DirBeamPlay.frontOn() == false, "off: it's off")
	SimCore.dispose(S)


## Game Design's window: 18 before the front's arrival, 2 after, and the hit lands 2 past it.
func _dodgeEdges() -> void:
	var fr: Dictionary = DirBeamPlay.data().front
	_expect(int(fr.dodgeBefore) == 18 and int(fr.dodgeAfter) == 2, "the front's dodge: 18 before, 2 after")
	for row in [[-int(fr.dodgeBefore) - 1, false], [-int(fr.dodgeBefore), true], [int(fr.dodgeAfter) - 1, true]]:
		var off: int = int(row[0])
		var clear: bool = bool(row[1])
		var hit: bool = _tapAtArrival(off)
		_expect(hit != clear, "a dodge %d from arrival: %s" % [off, "he takes it" if hit else "he's clear"])


## Did he take it, with a dodge tap this many ticks from the front's arrival?
func _tapAtArrival(off: int) -> bool:
	var S := _fresh(9000.0)
	_fire(S)
	var at: int = DirBeamPlay._arrival(S.fighters[1], S.fighters[0])
	var hp: float = S.fighters[1].hp
	while S.tick < at + 16:
		_step(S, null, _tap() if S.tick + 1 == at + off else null)
	var hit: bool = S.fighters[1].hp < hp
	SimCore.dispose(S)
	return hit


## The charge's press: 30 and 10 ticks before he fires, RT + B, RB + B or RB and the stick, it's held and goes as he fires. ([press] ticks after his.)
func _litHand() -> void:
	DirStick.setForce(1)
	for row in [[18, 4, "sig"], [38, 4, "sig"], [18, 2, "sig"], [38, 2, "sig"], [18, 2, "stick"], [38, 2, "stick"]]:
		var S := _fresh(2400.0)
		var a := SimIntent.new()
		a.sig = true
		a.stanceMask = 4
		_step(S, a)
		S.fighters[1].sigReadyT = 0.0
		for _k in range(int(row[0]) - 1):
			_step(S)
		var y := SimIntent.new()
		y.stanceMask = int(row[1])
		if String(row[2]) == "sig":
			y.sig = true
		else:
			y.rsStart = true
			y.rsHeld = true
			y.rsDir = SimStrikeRead.LEFT if SimWrap.sdx(S.fighters[1].x, S.fighters[0].x) < 0.0 else SimStrikeRead.RIGHT
			y.rsMask = int(row[1])
		_step(S, null, y)
		var clashAt: int = -1
		for k in range(120):
			_step(S)
			if clashAt < 0 and S.game.clash != null:
				clashAt = k + int(row[0])
				break
		print("      pressed %d after his, mask %d, %s: the struggle starts %d after his press (he fires at about 48)" % [row[0], row[1], row[2], clashAt])
		_expect(clashAt >= 40 and clashAt <= 60, "a %s pressed %d ticks into the charge answers it as he fires (%d)" % [row[2], row[0], clashAt])
		SimCore.dispose(S)
	DirStick.setForce(-1)


## Stationary (Orb, first play): nothing moves him in the charge. With it off, the old rise and the stand-off.
func _standoff() -> void:
	var cfg: Dictionary = DirBeamPlay.frontCfg()
	for row in [[58.0, true], [3000.0, true], [58.0, false]]:
		cfg["stationary"] = bool(row[1])
		var S := _fresh(float(row[0]))
		var A = S.fighters[0]
		S.fighters[1].y = A.y + 200.0
		var x0: float = A.x
		var y0: float = A.y
		_fire(S)
		var gap: float = absf(SimWrap.sdx(A.x, S.fighters[1].x))
		var moved: float = SimDetMath.hypot(SimWrap.sdx(x0, A.x), A.y - y0)
		print("      stationary %s, fired from %.0f: moved %.0f in the charge, %.0f apart as it leaves, %d ticks to arrive" % [str(row[1]), row[0], moved, gap, _openN - _fireAt])
		if bool(row[1]):
			_expect(moved < 1.0, "stationary, from %.0f: he stays where he is (%.0f)" % [row[0], moved])
		else:
			_expect(gap >= float(cfg.standoffBh) * 75.0 - 40.0, "off, point blank: the stand-off's kick (%.0f)" % gap)
		SimCore.dispose(S)
	cfg["stationary"] = true
	_release()
	_holdMoves()
	_kite()
	_shoved()
	_aimed()


## The stick: the hold's the charge and shows, and it fires on the release, after what's left of the warning.
func _release() -> void:
	DirStick.setForce(1)
	for hold in [36, 60]:
		var S := _fresh(2400.0)
		var A = S.fighters[0]
		var x0: float = A.x
		var y0: float = A.y
		var w := SimIntent.new()
		w.rsStart = true
		w.rsHeld = true
		w.rsDir = SimStrikeRead.RIGHT
		w.rsMask = DirStick.RB
		w.stanceMask = DirStick.RB
		_step(S, w)
		var showing: bool = true
		for _k in range(hold - 1):
			var h := SimIntent.new()
			h.rsHeld = true
			h.rsDir = SimStrikeRead.RIGHT
			h.rsMask = DirStick.RB
			h.stanceMask = DirStick.RB
			_step(S, h)
			showing = showing and A.beamCharge != null
		_expect(showing, "held %d: the hold shows as the charge" % hold)
		var r := SimIntent.new()
		r.rsRelease = true
		r.rsDir = SimStrikeRead.RIGHT
		r.rsMask = DirStick.RB
		r.rsLevel = 2
		r.stanceMask = DirStick.RB
		_fireAt = -1
		_step(S, r)
		var n: int = 0
		while _fireAt < 0 and n < 80:
			_step(S)
			n += 1
		var moved: float = SimDetMath.hypot(SimWrap.sdx(x0, A.x), A.y - y0)
		print("      held %d: it fires %d ticks after the release, moved %.0f" % [hold, n, moved])
		_expect(n <= maxi(int(DirBeamPlay.frontCfg().releaseTell), 48 - hold) + 2, "held %d: it fires on the release (%d)" % [hold, n])
		_expect(moved < 1.0, "held %d: he stays where he is (%.0f)" % [hold, moved])
		SimCore.dispose(S)
	DirStick.setForce(-1)


func _cantPay() -> void:
	var S := _fresh(2400.0)
	var a := SimIntent.new()
	a.sig = true
	a.stanceMask = 4
	_step(S, a)
	for _k in range(10):
		_step(S)
	S.fighters[1].ki = 1.0
	var y := SimIntent.new()
	y.sig = true
	y.stanceMask = 4
	SimCore.step(S, [SimIntent.new(), y])
	var said: bool = false
	for e in S.out.fx:
		if e.type == "cue" and e.kind == "answer_refused" and String(e.source) == "ki" and e.actor == 1.0:
			said = true
	S.out.fx.clear()
	S.out.feed.clear()
	_expect(said, "can't pay: no answer, and the press says why")
	SimCore.dispose(S)


## Past 0.2 s he barely moves, with no dash; a flick's first ticks move as ever.
func _holdMoves() -> void:
	DirStick.setForce(1)
	var S := _fresh(6000.0)
	var A = S.fighters[0]
	var w := SimIntent.new()
	w.rsStart = true
	w.rsHeld = true
	w.rsDir = SimStrikeRead.RIGHT
	w.rsMask = DirStick.RB
	w.stanceMask = DirStick.RB
	w.mx = -1.0
	w.dash = true
	_step(S, w)
	for _k in range(90):
		var h := SimIntent.new()
		h.rsHeld = true
		h.rsDir = SimStrikeRead.RIGHT
		h.rsMask = DirStick.RB
		h.stanceMask = DirStick.RB
		h.mx = -1.0
		h.dash = true
		_step(S, h)
	var x0: float = A.x
	var top: float = SimFighter.flightSpeed(S, A, true)
	for _k in range(30):
		var h := SimIntent.new()
		h.rsHeld = true
		h.rsDir = SimStrikeRead.RIGHT
		h.rsMask = DirStick.RB
		h.stanceMask = DirStick.RB
		h.mx = -1.0
		h.dash = true
		_step(S, h)
	var went: float = absf(SimWrap.sdx(x0, A.x)) * 2.0
	_expect(A.beamCharge != null, "the hold shows as the charge")
	var free: float = 430.0 * A.spd * SimForms.speedMul(S, A)
	print("      holding, flat out: %.0f u/s, against %.0f with no hold or dash" % [went, free])
	_expect(top <= free * 0.1 * 1.4, "he barely moves, and the dash does nothing (%.0f of %.0f)" % [top, free])
	_expect(went <= free * 0.2, "... as he flies, with the kick's overspeed on or off (%.0f)" % went)
	var cn := SimIntent.new()
	cn.rsCancel = true
	cn.rsDir = SimStrikeRead.RIGHT
	cn.rsMask = DirStick.RB
	_step(S, cn)
	_expect(A.beamCharge == null and DirStick._g(A, DirStick.ST_ON) == 0, "a dodge or guard press drops it, and it stops showing")
	_expect(SimFighter.flightSpeed(S, A, false) > free * 0.5, "... and he has his speed back")
	SimCore.dispose(S)
	DirStick.setForce(-1)


## The kite (LT + RB): a hold charges nothing, and the release is the quick blast.
func _kite() -> void:
	DirStick.setForce(1)
	var S := _fresh(2400.0)
	var A = S.fighters[0]
	var m: int = DirStick.RB | DirStick.LT
	var w := SimIntent.new()
	w.rsStart = true
	w.rsHeld = true
	w.rsDir = SimStrikeRead.RIGHT
	w.rsMask = m
	w.stanceMask = m
	_step(S, w)
	for _k in range(60):
		var h := SimIntent.new()
		h.rsHeld = true
		h.rsDir = SimStrikeRead.RIGHT
		h.rsMask = m
		h.stanceMask = m
		_step(S, h)
	_expect(A.beamCharge == null, "the kite's hold isn't a charge")
	var r := SimIntent.new()
	r.rsRelease = true
	r.rsDir = SimStrikeRead.RIGHT
	r.rsMask = m
	r.rsLevel = 3
	r.stanceMask = m
	_fireAt = -1
	_step(S, r)
	for _k in range(80):
		_step(S)
	_expect(_fireAt < 0, "... and no beam comes of it")
	SimCore.dispose(S)
	DirStick.setForce(-1)


## Up close the firing throws the other back to 9 bh over 0.25 s: no damage and no stun, and he can still answer. Far off, nothing.
func _shoved() -> void:
	var need: float = float(DirBeamPlay.frontCfg().standoffBh) * DirInterrupt.BH
	var S := _fresh(58.0)
	var A = S.fighters[0]
	var D = S.fighters[1]
	var x0: float = A.x
	var hp: float = D.hp
	_fire(S)
	var t0: int = S.tick
	for _k in range(16):
		_step(S)
	var gap: float = absf(SimWrap.sdx(A.x, D.x))
	print("      from 58: %.0f apart 16 ticks after the fire, %d ticks to arrive" % [gap, _openN - t0])
	_expect(gap >= need - 40.0, "up close, the firing throws him back to the stand-off (%.0f)" % gap)
	_expect(absf(SimWrap.sdx(x0, A.x)) < 1.0, "... and the shooter stays put")
	_expect(D.hp == hp and D.stunTicks == 0, "... no damage, no stun")
	_expect(DirBeamPlay.fireBack(S, D), "... he keeps his hands: he can fire back")
	SimCore.dispose(S)
	var S2 := _fresh(3000.0)
	var d2 = S2.fighters[1]
	var x2: float = d2.x
	_fire(S2)
	for _k in range(16):
		_step(S2)
	_expect(absf(SimWrap.sdx(x2, d2.x)) < 1.0, "from far off, nothing moves him")
	SimCore.dispose(S2)


## The stick aims an RB beam: near him it's a shot at him; up, it goes up and he's untouched; the charge's aim follows the stick. Off, at him.
func _aimed() -> void:
	DirStick.setForce(1)
	for row in [[true, 0, true], [true, 8, false], [true, 2, true], [true, 4, false], [false, 8, true]]:
		DirBeamAim.setForce(1 if bool(row[0]) else 0)
		var S := _fresh(2400.0)
		var A = S.fighters[0]
		var D = S.fighters[1]
		var hp: float = D.hp
		var w := SimIntent.new()
		w.rsStart = true
		w.rsHeld = true
		w.rsDir = SimStrikeRead.RIGHT
		w.rsMask = DirStick.RB
		w.stanceMask = DirStick.RB
		w.rsAim = int(row[1])
		_step(S, w)
		var seen: int = -1
		for _k in range(50):
			var h := SimIntent.new()
			h.rsHeld = true
			h.rsDir = SimStrikeRead.RIGHT
			h.rsMask = DirStick.RB
			h.stanceMask = DirStick.RB
			h.rsAim = int(row[1])
			_step(S, h)
			seen = int(DirBeamAim.aimDeg(A)) if not is_nan(DirBeamAim.aimDeg(A)) else seen
		var r := SimIntent.new()
		r.rsRelease = true
		r.rsDir = SimStrikeRead.RIGHT
		r.rsMask = DirStick.RB
		r.rsLevel = 2
		r.rsAim = int(row[1])
		r.stanceMask = DirStick.RB
		_step(S, r)
		var uy: float = 0.0
		for _k in range(120):
			_step(S)
			if not S.beams.is_empty():
				uy = maxf(uy, float(S.beams[0].uy))
		var at: bool = D.hp < hp or _open > 0
		print("      aim %s, sector %d: held %d deg, beam's rise %.2f, at him %s, he took %.0f" % [str(row[0]), row[1], seen, uy, str(at), hp - D.hp])
		_expect(at == bool(row[2]), "aim %s, sector %d: %s" % [str(row[0]), row[1], "a shot at him" if bool(row[2]) else "it goes where it was aimed, wide of him"])
		if bool(row[0]):
			_expect(seen == int(row[1]) * 11 + int(int(row[1]) * 0.25), "the charge's aim follows the stick (%d)" % seen)
		if bool(row[0]) and not bool(row[2]):
			_expect(uy >= SimDetMath.sin(float(row[1]) * 11.25 * SimMathx.PI / 180.0) - 0.05 and S.dirS.ex == null, "... it rises as aimed, and the exchange is over (%.2f)" % uy)
		SimCore.dispose(S)
	DirBeamAim.setForce(-1)
	DirStick.setForce(-1)
