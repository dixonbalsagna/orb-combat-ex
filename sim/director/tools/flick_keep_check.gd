extends SceneTree
## Orb's scheme, to Game Design's rulings (docs/design/gauntlet-plan.md section 5): a flick that can't start now is held (stick.json
## flickKeep, off; docs/director/pending/refusal-reasons/), and the first move's refusal of a stick press is told once:
##   godot --headless --path . --script res://sim/director/tools/flick_keep_check.gd
## - off: a flick made while he's launched is refused when the buffer runs out (bufferTicks), as before
## - on, launched: kept past the buffer, it goes on his first free tick if it's at most recoverTicks old, with no refusal; older, it's
##   refused "recovering"; still launched past pendFollow.maxTicks, refused once, with why
## - on, stunned: held past recoverTicks, it goes when the stun ends (the 20 is for recovering only), its direction read then
## - on: a request a planned exchange of his rival's takes is held, not told "answered", and goes when he's free
## - on: a request of his own that starts a planned exchange is its first strike: told it started (stick_start), nothing kept, no
##   refusal, nothing goes again when it ends, and nothing's refused while it runs past pendFollow.maxTicks; a hold the same
## - on: in a set piece (a finisher planned) it's refused at once, "set_piece"
## - a stick press the first move refuses is told once: stick_refused not_yours, and no press_ack refused (no face button crossed)
## Ends on the verdict line.

var failed: int = 0


func _init() -> void:
	DirStick.setForce(1)
	var sc: Dictionary = DirStick.cfg()
	var keep0: bool = bool(sc.flickKeep.enabled)
	var pf0: bool = bool(sc.pendFollow.enabled)
	sc.flickKeep.enabled = false
	_launchedOff()
	_firstMoveOnce()
	sc.flickKeep.enabled = true
	_launchedOn()
	_recoveringOld()
	_keptTooLong()
	_stunnedHeld()
	_setPiece()
	sc.pendFollow.enabled = true
	_answered()
	_ownExchange(false)
	_ownExchange(true)
	sc.pendFollow.enabled = pf0
	sc.flickKeep.enabled = keep0
	DirStick.setForce(-1)
	print("FLICK KEEP: %d check(s) failed" % failed)
	quit(1 if failed > 0 else 0)


func _expect(ok: bool, what: String) -> void:
	print(("ok    " if ok else "FAIL  ") + what)
	if not ok:
		failed += 1


func _fresh(gap: float = 450.0) -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 31, {"p1": false, "p2": false}, {"v2": [true, true], "intro": false})
	for _k in range(5):
		SimCore.step(S, [null, null])
	var A = S.fighters[0]
	var D = S.fighters[1]
	D.x = SimWrap.wrap(A.x + gap)
	D.y = A.y
	for f in [A, D]:
		f.ki = 100.0
		f.hp = 100000.0
	S.out.fx.clear()
	return S


func _tick(S: SimState, n: int = 1) -> void:
	S.tick += n
	S.T += float(n) / DirData.TICKS_PER_SEC


func _flick() -> SimIntent:
	var i := SimIntent.new()
	i.rsStart = true
	i.rsDir = SimStrikeRead.RIGHT
	i.rsMask = 0
	return i


## This tick's refusals for fighter 0 (stick_refused, press_refused, press_ack refused), as "kind/source", and clears the list.
func _said(S: SimState) -> Array:
	var out: Array = []
	for e in S.out.fx:
		if String(e.type) == "cue" and int(e.actor) == 0 and (String(e.kind) == "stick_refused" or (String(e.kind) == "press_ack" and String(e.text) == "refused") or String(e.kind) == "press_refused"):
			out.append(String(e.kind) + "/" + (String(e.source) if String(e.kind) != "press_ack" else String(e.text)))
	S.out.fx.clear()
	return out


## n ticks of the buffer's own step; returns what was said.
func _wait(S: SimState, A, n: int) -> Array:
	var said: Array = []
	for _k in range(n):
		_tick(S)
		DirStick._waiting(S, A)
		said.append_array(_said(S))
	return said


func _went(S: SimState, A) -> bool:
	return DirStick._g(A, DirStick.ST_PEND) != 0 or S.dirS.ex != null


func _launchedOff() -> void:
	var S := _fresh()
	var A = S.fighters[0]
	A.state = "launched"
	DirStick._start(S, A, _flick())
	var said: Array = _said(S)
	said.append_array(_wait(S, A, int(DirStick.cfg().bufferTicks) + 2))
	print("      off, launched: %s" % str(said))
	_expect(said == ["stick_refused/launched"], "off: a flick while launched is refused as the buffer runs out, with why")
	SimCore.dispose(S)


func _launchedOn() -> void:
	var S := _fresh()
	var A = S.fighters[0]
	A.state = "launched"
	DirStick._start(S, A, _flick())
	var said: Array = _said(S)
	said.append_array(_wait(S, A, int(DirStick.cfg().bufferTicks) + 6))
	var kept: bool = DirStick._g(A, DirStick.ST_BUF) != 0
	A.state = "free"
	said.append_array(_wait(S, A, 1))
	print("      on, launched for %d ticks, then free: said %s, kept %s, went %s" % [int(DirStick.cfg().bufferTicks) + 6, str(said), str(kept), str(_went(S, A))])
	_expect(said.is_empty() and kept and _went(S, A), "on: launched, kept past the buffer, and it goes on his first free tick, with no refusal")
	SimCore.dispose(S)


func _keptTooLong() -> void:
	var S := _fresh()
	var A = S.fighters[0]
	A.state = "launched"
	DirStick._start(S, A, _flick())
	var said: Array = _said(S)
	said.append_array(_wait(S, A, int(DirStick.cfg().pendFollow.maxTicks) + 4))
	print("      on, launched past pendFollow.maxTicks: %s" % str(said))
	_expect(said == ["stick_refused/launched"], "on: still launched past pendFollow.maxTicks, it's refused once, with why")
	SimCore.dispose(S)


func _answered() -> void:
	var S := _fresh(1200.0)
	var A = S.fighters[0]
	var D = S.fighters[1]
	DirStick._go(S, A, DirStick.TOWARD, 0)
	_said(S)
	var pend: bool = DirStick._g(A, DirStick.ST_PEND) != 0
	S.dirS.ex = null
	var ex = DirExchange.newEx(D, A, "heavy")   # the rival's planned exchange takes him
	S.dirS.ex = ex
	A.state = "locked"
	D.state = "locked"
	DirStick._followed(S, A, DirBrawl._now(S))
	var said: Array = _said(S)
	var kept: bool = DirStick._g(A, DirStick.ST_BUF) != 0
	S.dirS.ex = null
	A.state = "free"
	D.state = "free"
	said.append_array(_wait(S, A, 1))
	print("      on, answered: pending %s, said %s, kept %s, went %s" % [str(pend), str(said), str(kept), str(_went(S, A))])
	_expect(pend and said.is_empty() and kept and _went(S, A), "on: a request the rival's planned exchange took is kept, not told answered, and goes when he's free")
	SimCore.dispose(S)



## His own request starts the planned exchange (he's its attacker): the flick is its first strike (ruling 2). held: the stick still held.
func _ownExchange(held: bool) -> void:
	var S := _fresh(1200.0)
	var A = S.fighters[0]
	var D = S.fighters[1]
	DirStick._go(S, A, DirStick.TOWARD, 0)
	_said(S)
	var pend: bool = DirStick._g(A, DirStick.ST_PEND) != 0
	S.dirS.ex = null
	var ex = DirExchange.newEx(A, D, "heavy")   # his own request's planned exchange
	S.dirS.ex = ex
	A.state = "locked"
	D.state = "locked"
	A.input = SimIntent.new()
	A.input.rsHeld = held
	DirStick._followed(S, A, DirBrawl._now(S))
	var started: bool = false
	for e in S.out.fx:
		if String(e.type) == "cue" and int(e.actor) == 0 and String(e.kind) == "stick_start" and String(e.text) == DirStick.NAMES[DirStick.TOWARD]:
			started = true
	var said: Array = _said(S)
	var kept: bool = DirStick._g(A, DirStick.ST_BUF) != 0 or DirStick._g(A, DirStick.ST_PEND) != 0
	said.append_array(_wait(S, A, int(DirStick.cfg().pendFollow.maxTicks) + 4))   # the exchange runs long: nothing's refused "locked"
	S.dirS.ex = null
	A.state = "free"
	D.state = "free"
	A.input.rsHeld = false
	said.append_array(_wait(S, A, 1))
	var again: bool = _went(S, A)
	print("      on, his own exchange%s: pending %s, started %s, said %s, kept %s, went again %s" % [" (held)" if held else "", str(pend), str(started), str(said), str(kept), str(again)])
	_expect(pend and started and said.is_empty() and not kept and not again, "on: a request of his own that starts a planned exchange%s is its first strike: told it started, nothing kept, no refusal, nothing goes again" % (", the stick held," if held else ""))
	SimCore.dispose(S)


func _recoveringOld() -> void:
	var S := _fresh()
	var A = S.fighters[0]
	A.state = "launched"
	DirStick._start(S, A, _flick())
	var said: Array = _said(S)
	said.append_array(_wait(S, A, int(DirStick.cfg().flickKeep.recoverTicks) + 10))
	A.state = "free"
	said.append_array(_wait(S, A, 1))
	print("      on, launched for %d ticks, then free: %s, went %s" % [int(DirStick.cfg().flickKeep.recoverTicks) + 10, str(said), str(_went(S, A))])
	_expect(said == ["stick_refused/recovering"] and not _went(S, A), "on: made early in his flight, it's too old when he's free: refused recovering")
	SimCore.dispose(S)


func _stunnedHeld() -> void:
	var S := _fresh()
	var A = S.fighters[0]
	var D = S.fighters[1]
	A.stunTicks = 200
	DirStick._start(S, A, _flick())   # toward him: he's on A's right
	var said: Array = _said(S)
	said.append_array(_wait(S, A, int(DirStick.cfg().flickKeep.recoverTicks) + 20))
	D.x = SimWrap.wrap(A.x - 450.0)   # he's moved to A's left while the stun held A: the same stick now points away from him
	A.stunTicks = 0
	said.append_array(_wait(S, A, 1))
	var dir: int = DirStick._g(A, DirStick.ST_PEND) & 7
	print("      on, stunned %d ticks, the rival moved across: said %s, went %s, direction %d (away %d)" % [int(DirStick.cfg().flickKeep.recoverTicks) + 20, str(said), str(_went(S, A)), dir, DirStick.AWAY])
	_expect(said.is_empty() and _went(S, A), "on: stunned past recoverTicks, it's held and goes when the stun ends")
	_expect(dir == DirStick.AWAY, "on: its direction is read as it goes: the rival crossed over, so the same stick is away")
	SimCore.dispose(S)


func _setPiece() -> void:
	var S := _fresh(120.0)
	var A = S.fighters[0]
	var D = S.fighters[1]
	var ex = DirExchange.newEx(D, A, "heavy")
	S.dirS.ex = ex
	A.state = "locked"
	D.state = "locked"
	DirExchange.schedule(ex, ex.t + 1.0, "finisher", {})
	DirStick._start(S, A, _flick())
	var said: Array = _said(S)
	var held: bool = DirStick._g(A, DirStick.ST_BUF) != 0
	print("      on, a finisher planned: said %s, held %s" % [str(said), str(held)])
	_expect(said == ["stick_refused/set_piece"] and not held, "on: in a set piece it's refused at once, set_piece, and not held")
	SimCore.dispose(S)


func _firstMoveOnce() -> void:
	var S := _fresh(450.0)
	var A = S.fighters[0]
	DirBrawl._s(A, DirBrawl.MOVE_AT, S.tick + 300)
	DirStick._start(S, A, _flick())
	var said: Array = _said(S)
	print("      off, the rival's first move: %s" % str(said))
	_expect(said == ["stick_refused/not_yours"], "a stick press the first move refuses is told once: stick_refused not_yours, and no press_ack refused")
	SimCore.dispose(S)
