extends SceneTree
## Every press answered, with why (docs/director/pending/refusal-reasons/; the EP 2026-11-07, from Tools' sticks=6 run and the ledger of
## Orb's save on a8bc66e2):
##   godot --headless --path . --script res://sim/director/tools/refusal_reasons_check.gd
## - the stick's refusal while he can't act says why: launched, down, stunned or locked, never a number
## - a flick buffered while he can't act and never let go: one refusal at the end of the buffer, with the hold's reason
## - a newer flick replaces one still on its way, or one buffered, with no knock for the one it replaces
## - a press the full queue lets go of: one press_refused a burst, with why (locked, or queue_full when he's free), and the next after a
##   pause; never the computer's, and nothing with press.refusedCue off
## Ends on the verdict line.

var failed: int = 0


func _init() -> void:
	DirStick.setForce(1)
	var fk0: bool = bool(DirStick.cfg().get("flickKeep", {}).get("enabled", false))
	if DirStick.cfg().has("flickKeep"):
		DirStick.cfg().flickKeep.enabled = false   # the 9-tick buffer and its refusals, as built (flick_keep_check has the keep)
	var sc: Dictionary = DirStick.cfg()
	var buf0: int = int(sc.bufferTicks)
	var pc: Dictionary = DirExchange.pressCfg()
	var cue0: bool = bool(pc.get("refusedCue", false))
	pc["refusedCue"] = true
	sc["bufferTicks"] = 0
	_stickReasons()
	sc["bufferTicks"] = buf0
	_buffered()
	_replaced()
	_fullQueue()
	pc["refusedCue"] = false
	_fullQueueOff()
	pc["refusedCue"] = cue0
	if DirStick.cfg().has("flickKeep"):
		DirStick.cfg().flickKeep.enabled = fk0
	DirStick.setForce(-1)
	print("REFUSAL REASONS: %d check(s) failed" % failed)
	quit(1 if failed > 0 else 0)


func _expect(ok: bool, what: String) -> void:
	print(("ok    " if ok else "FAIL  ") + what)
	if not ok:
		failed += 1


func _fresh(ai: bool = false) -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 31, {"p1": ai, "p2": false}, {"v2": [true, true], "intro": false})
	for _k in range(5):
		SimCore.step(S, [null, null])
	var A = S.fighters[0]
	var D = S.fighters[1]
	D.x = SimWrap.wrap(A.x + 6.0 * 75.0)
	for f in [A, D]:
		f.ki = 100.0
		f.hp = 100000.0
	S.out.fx.clear()
	return S


## One tick on the clocks the stick and the burst read, with nothing else stepped.
func _tick(S: SimState, n: int = 1) -> void:
	S.tick += n
	S.T += float(n) / DirData.TICKS_PER_SEC


func _flickIntent() -> SimIntent:
	var i := SimIntent.new()
	i.rsStart = true
	i.rsDir = SimStrikeRead.RIGHT
	i.rsMask = 0
	return i


## The sources of this tick's cues of a kind for fighter 0, and clears the list.
func _sources(S: SimState, kind: String) -> Array:
	var out: Array = []
	for e in S.out.fx:
		if String(e.type) == "cue" and String(e.kind) == kind and int(e.actor) == 0:
			out.append(String(e.source))
	S.out.fx.clear()
	return out


## A planned exchange that holds both, as a beat-less shell: enough for "can't act" and "locked".
func _hold(S: SimState) -> void:
	var ex = DirExchange.newEx(S.fighters[0], S.fighters[1], "heavy")
	S.dirS.ex = ex
	S.fighters[0].state = "locked"
	S.fighters[1].state = "locked"


func _stickReasons() -> void:
	var got: Dictionary = {}
	for why in ["launched", "down", "stunned", "locked"]:
		var S := _fresh()
		var A = S.fighters[0]
		match why:
			"launched":
				A.state = "launched"
			"down":
				A.state = "down"
			"stunned":
				A.stunTicks = 30
			"locked":
				_hold(S)
		DirStick._start(S, A, _flickIntent())
		got[why] = _sources(S, "stick_refused")
		SimCore.dispose(S)
	print("      the stick's refusals: %s" % str(got))
	for why in got:
		_expect(got[why] == [why], "a flick while %s is refused once, and says %s (not a number)" % [why, why])


func _buffered() -> void:
	var S := _fresh()
	var A = S.fighters[0]
	A.state = "launched"
	DirStick._start(S, A, _flickIntent())
	var early: Array = _sources(S, "stick_refused")
	_tick(S, 2)
	DirStick._start(S, A, _flickIntent())   # a second flick in the buffer replaces the first
	var second: Array = _sources(S, "stick_refused")
	var told: Array = []
	for _k in range(int(DirStick.cfg().bufferTicks) + 4):
		_tick(S)
		DirStick._waiting(S, A)
		told.append_array(_sources(S, "stick_refused"))
	print("      buffered while launched: at the presses %s %s, then %s" % [str(early), str(second), str(told)])
	_expect(early.is_empty() and second.is_empty(), "flicks buffered while launched say nothing yet, and the second replaces the first with no knock")
	_expect(told == ["launched"], "the buffer ends with one refusal for the burst, with the hold's reason: launched")
	SimCore.dispose(S)


func _replaced() -> void:
	var S := _fresh()
	var A = S.fighters[0]
	DirStick._go(S, A, DirStick.TOWARD, 0)
	var first: Array = _sources(S, "stick_refused")
	_tick(S)
	DirStick._go(S, A, DirStick.TOWARD, 0)   # a newer flick while the first is still on its way
	var second: Array = _sources(S, "stick_refused")
	print("      a request replaced on its way: %s %s, pending %d" % [str(first), str(second), DirStick._g(A, DirStick.ST_PEND)])
	_expect(first.is_empty() and second.is_empty() and DirStick._g(A, DirStick.ST_PEND) != 0, "a newer flick replaces one still on its way, and nothing knocks for the one it replaced")
	SimCore.dispose(S)


## Six presses a tick apart on a full queue, then one after a pause; locked in an exchange, then free.
func _mash(S: SimState) -> Array:
	var A = S.fighters[0]
	A.act.queue.clear()
	for k in range(SimAct.queueMax):
		SimAct.push(A, SimAct.SIG, A.act.mode, 0, S.tick)
	var said: Array = []
	for k in range(6):
		_tick(S)
		DirExchange.requestAttack(S, A, "sig")
		said.append_array(_sources(S, "press_refused"))
	_tick(S, int(DirExchange.pressCfg().get("refusedBurstTicks", 2)) + 5)
	DirExchange.requestAttack(S, A, "sig")
	said.append_array(_sources(S, "press_refused"))
	return said


func _fullQueue() -> void:
	var S := _fresh()
	_hold(S)
	var locked: Array = _mash(S)
	SimCore.dispose(S)
	S = _fresh()
	S.dirS.cool = 5.0   # free, but the cooldown keeps his three waiting
	var free: Array = _mash(S)
	SimCore.dispose(S)
	S = _fresh(true)
	_hold(S)
	var ai: Array = _mash(S)
	SimCore.dispose(S)
	print("      the full queue: locked %s, free %s, the computer %s" % [str(locked), str(free), str(ai)])
	_expect(locked == ["locked", "locked"], "locked, a mash on the full queue is one knock, with why (locked), and the next after a pause")
	_expect(free.size() == 2 and free[0] == "queue_full", "free with three waiting, it says queue_full, once a burst (the drain has started one of his by the second)")
	_expect(ai.is_empty(), "never the computer's")


func _fullQueueOff() -> void:
	var S := _fresh()
	_hold(S)
	var said: Array = _mash(S)
	SimCore.dispose(S)
	_expect(said.is_empty(), "with press.refusedCue off, nothing")
