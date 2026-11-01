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


## From point blank he kicks back with his rise, so the front has somewhere to cross; from far off he doesn't.
func _standoff() -> void:
	for row in [[58.0, true], [3000.0, false]]:
		var S := _fresh(float(row[0]))
		var A = S.fighters[0]
		var x0: float = A.x
		_fire(S)
		var gap: float = absf(SimWrap.sdx(A.x, S.fighters[1].x))
		print("      fired from %.0f: %.0f apart as it leaves, moved %.0f, %d ticks to arrive" % [row[0], gap, absf(SimWrap.sdx(x0, A.x)), _openN - _fireAt])
		if bool(row[1]):
			_expect(gap >= float(DirBeamPlay.frontCfg().standoffBh) * 75.0 - 40.0, "point blank: he's kicked back to the stand-off (%.0f)" % gap)
		else:
			_expect(absf(SimWrap.sdx(x0, A.x)) < 1.0, "from far off: he stays where he is")
		SimCore.dispose(S)


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

