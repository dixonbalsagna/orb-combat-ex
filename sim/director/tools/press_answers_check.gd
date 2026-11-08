extends SceneTree
## Every press answered: the power press and the transform (docs/director/pending/press-answers/; Tools' corrected ledger of Orb's 1229
## play):
##   godot --headless --path . --script res://sim/director/tools/press_answers_check.gd
## - a power press that begins a charge is told (power_start); one whose burst fired is told (power_burst)
## - a power press while launched or locked is refused with why; free with nothing to say, nothing
## - a transform press with no form ready is refused not_ready; one that transforms is told by its own event, with no refusal
## - with press.refusedCue off, nothing; never the computer's
## Ends on the verdict line.

var failed: int = 0


func _init() -> void:
	var pc: Dictionary = DirExchange.pressCfg()
	var cue0: bool = bool(pc.get("refusedCue", false))
	pc["refusedCue"] = true
	var charge: Array = _power("charge")
	var burst: Array = _power("burst")
	var launched: Array = _power("launched")
	var locked: Array = _power("locked")
	var free: Array = _power("free")
	var notReady: Array = _form(false)
	var ready: Array = _form(true)
	var ai: Array = _power("launched", true)
	pc["refusedCue"] = false
	var off: Array = _power("launched")
	pc["refusedCue"] = cue0
	print("      power: charge %s, burst %s, launched %s, locked %s, free %s; transform: not ready %s, ready %s; computer %s; off %s" % [str(charge), str(burst), str(launched), str(locked), str(free), str(notReady), str(ready), str(ai), str(off)])
	_expect(charge == ["cue/power_start"], "a power press that begins a charge is told: power_start")
	_expect(burst == ["cue/power_burst"], "a power press whose burst fired is told: power_burst")
	_expect(launched == ["press_refused/launched"] and locked == ["press_refused/locked"], "a power press while launched or locked is refused, with why")
	_expect(free.is_empty(), "free, with nothing to say: nothing (no false knock)")
	_expect(notReady == ["press_refused/not_ready"], "a transform press with no form ready is refused: not_ready")
	_expect(ready.is_empty(), "a transform press that transforms is told by its own event, with no refusal")
	_expect(ai.is_empty() and off.is_empty(), "never the computer's, and nothing with refusedCue off")
	print("PRESS ANSWERS: %d check(s) failed" % failed)
	quit(1 if failed > 0 else 0)


func _expect(ok: bool, what: String) -> void:
	print(("ok    " if ok else "FAIL  ") + what)
	if not ok:
		failed += 1


func _fresh(ai: bool = false) -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 5, {"p1": ai, "p2": false}, {"v2": [true, true], "intro": false})
	for _k in range(5):
		SimCore.step(S, [null, null])
	S.out.fx.clear()
	return S


## What fighter 0's answers were this tick: "cue/<kind>" for the two new cues, "press_refused/<code>".
func _said(S: SimState) -> Array:
	var out: Array = []
	for e in S.out.fx:
		if String(e.type) == "cue" and int(e.actor) == 0:
			if String(e.kind) == "power_start" or String(e.kind) == "power_burst":
				out.append("cue/" + String(e.kind))
			elif String(e.kind) == "press_refused":
				out.append("press_refused/" + String(e.source))
	return out


func _power(how: String, ai: bool = false) -> Array:
	var S := _fresh(ai)
	var A = S.fighters[0]
	A.input = SimIntent.new()
	A.input.powerPress = true
	match how:
		"charge":
			A.state = "charging"
		"burst":
			A.act.burstFired = true
		"launched":
			A.state = "launched"
		"locked":
			S.dirS.ex = DirExchange.newEx(S.fighters[1], A, "heavy")
			A.state = "locked"
	DirRefuse.presses(S)
	var r: Array = _said(S)
	SimCore.dispose(S)
	return r


func _form(ready: bool) -> Array:
	var S := _fresh()
	var A = S.fighters[0]
	A.input = SimIntent.new()
	A.input.transform = true
	A.act.formReady = ready
	if ready:
		DirExchange._transforms(S)
	DirRefuse.presses(S)
	var r: Array = _said(S)
	SimCore.dispose(S)
	return r
