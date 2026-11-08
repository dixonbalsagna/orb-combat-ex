extends SceneTree
## Headless checks for the director's refusal cues read as they are sent (docs/controls/refusal-cues.md; Encounter's morning fixes): the reason is the cue's `source` (its `text` is the stick's direction),
## and an answered press, by stick_start, stick_refused or press_refused, ends the hub's wait so a director refusal is knocked once, not again 30 ticks later as "no answer". From the repo root:
##   godot --headless --path . --script res://sim/input/test/refusal_cue_test.gd
## Exit 0 if every check passes.

var fails: int = 0
var checks: int = 0


func ok(c: bool, what: String) -> void:
	checks += 1
	if not c:
		fails += 1
		print("FAIL  ", what)


func _init() -> void:
	SimInputData.load_and_apply()
	SimInputData.clear_overrides()
	var sw: Dictionary = SimInputData.timing.get("switches", {})
	sw["rightStick"] = true
	sw["hapticRefused"] = true
	sw["hapticStages"] = false
	sw["hapticImpact"] = false
	SimInputData.timing["switches"] = sw
	SimInputData.clear_overrides()
	SimInputData.invalidate()
	_source()
	_reasons()
	_table()
	_hub()
	print("refusal_cue_test: %d checks, %d failed" % [checks, fails])
	quit(1 if fails > 0 else 0)


func _reason(name: String, text: String, source: String) -> String:
	var r: Array = SimHaptics.requests(name, 0, -1, text, 0.0, -1, source)
	return String(r[0]["reason"]) if r.size() == 1 else "(none)"


func _source() -> void:
	# The director's real shape: text the stick's direction, source the reason.
	var cases: Array = [["ki", "no_energy"], ["taken", "hit"], ["hit", "hit"], ["late", "too_late"], ["cancel", "cancelled"], ["refused", "not_yours"], ["close", "too_close"], ["cooling", "cooling"], ["dodged", "dodged"]]
	for c in cases:
		ok(_reason("stick_refused", "right", c[0]) == c[1], "source: a stick_refused cue of direction right with source '%s' reads %s (got %s)" % [c[0], c[1], _reason("stick_refused", "right", c[0])])
	for code in ["stun_limit", "queue_expired", "block_lockout"]:
		ok(_reason("press_refused", "", code) == code, "source: a press_refused cue with source %s reads %s" % [code, code])
	ok(_reason("stick_refused", "right", "soon") == "(none)", "source: a stick_refused cue with source soon (a release waiting on the gate) knocks nothing: the screen word is enough")
	ok(SimHaptics.refusal_code("soon") == "soon", "source: soon is still a code, for the word")
	# A blow that stopped the charge (source hit): knocked with the impact rumble off, silent with it on (hit_taken is the same news); a beam charge taken (source taken) knocks either way.
	var sw: Dictionary = SimInputData.timing.get("switches", {})
	sw["hapticImpact"] = true
	SimInputData.timing["switches"] = sw
	SimInputData.clear_overrides()
	SimInputData.invalidate()
	ok(_reason("stick_refused", "right", "hit") == "(none)", "source: a blow that stopped the charge knocks nothing with the impact rumble on (hit_taken is the same news)")
	ok(_reason("stick_refused", "beam", "taken") == "hit", "source: a beam charge taken still knocks, with the impact rumble on")
	sw["hapticImpact"] = false
	SimInputData.timing["switches"] = sw
	SimInputData.clear_overrides()
	SimInputData.invalidate()
	ok(_reason("stick_refused", "right", "") == "other", "source: a stick_refused cue with a direction and no source reads other, not the direction")
	# An older caller that puts the reason in the text still reads.
	ok(_reason("stick_refused", "ki", "") == "no_energy" and _reason("press_refused", "stun_limit", "") == "stun_limit", "source: the reason in text with no source still reads (the old shape)")
	# The source wins over the text.
	ok(_reason("stick_refused", "late", "ki") == "no_energy", "source: the source wins over the text")
	# The mapping is unchanged otherwise: one knock, to the presser's pad.
	var r: Array = SimHaptics.requests("stick_refused", 1, -1, "right", 0.0, -1, "ki")
	ok(r.size() == 1 and r[0]["kind"] == "stick_refused" and int(r[0]["slot"]) == 1 and absf(float(r[0]["scale"]) - 1.0) < 0.001, "source: one stick_refused knock to slot 1")


## The reasons the director's refusal-reasons park sends (docs/director/pending/refusal-reasons): what holds him is named, never a number, and every code is knocked once to the presser and says itself.
func _reasons() -> void:
	for code in ["launched", "down", "stunned", "locked"]:
		ok(_reason("stick_refused", "right", code) == code, "reasons: a stick_refused cue with source %s reads %s, not busy or other" % [code, code])
		ok(_reason("press_refused", "", code) == code, "reasons: a press_refused cue with source %s reads %s" % [code, code])
	ok(_reason("press_refused", "", "queue_full") == "queue_full", "reasons: a full queue reads queue_full")
	ok(_reason("stick_refused", "right", "not_yours") == "not_yours", "reasons: not_yours (the rival's first move) reads itself")
	for code in ["launched", "down", "stunned", "locked", "queue_full"]:
		ok(SimHaptics.REFUSALS.has(code) and SimHaptics.refusal_word(code) != SimHaptics.refusal_word("other"), "reasons: %s has a word of its own" % code)
	# Only a refusal knocks: a landed blow, a hit-stop, a stage, a launch or a landing never maps to the refusal knock.
	for kind in ["damage", "launch", "land", "rush", "stick_hit", "stick_start", "stick_stage", "press_ack"]:
		for r in SimHaptics.requests(kind, 0, 1, "", 0.0, -1, ""):
			ok(String(r.get("kind", "")) != "stick_refused", "reasons: the cue %s never knocks as a refusal" % kind)


func _table() -> void:
	for code in ["too_close", "cooling", "soon"]:
		ok(SimHaptics.REFUSALS.has(code) and String(SimHaptics.REFUSALS[code]["word"]) != "", "table: %s has its word" % code)
	ok(SimHaptics.refusal_word("too_close") == "Too close" and SimHaptics.refusal_word("cooling") == "Cooling" and SimHaptics.refusal_word("soon") == "Soon", "table: the words are Game Design's and UI's (Too close, Cooling, Soon)")


func _hub_run(answer: String) -> Array:
	# A stick flick the director never starts, answered (or not) at tick 14 by `answer`: "" none, "start", "stick_refused", "press_refused".
	var hub := SimInputHub.new()
	hub.set_humans(true, false)
	hub.pad_button(7, "south", true)
	hub.pad_button(7, "south", false)
	hub.take_joins()
	hub.set_humans(true, false)
	var refusals: Array = []
	var knocks: int = 0
	for t in range(80):
		if t == 10:
			hub.pad_stick_right(7, 1.0, 0.0)
		if t == 14:
			hub.pad_stick_right(7, 0.0, 0.0)
		hub.intent(0)
		if t == 16 and answer != "":
			if answer == "start":
				hub.note_stick_started(0)
			else:
				hub.note_press_answered(0)
		for h in hub.take_haptics():
			if str(h.get("kind", "")) == "stick_refused":
				knocks += 1
		refusals.append_array(hub.take_refusals())
		hub.consumed()
	return [refusals, knocks]


## switches.flickKept: the hub waits refuseTicksKept (120), above the director's 90-tick keep. Before the first knock it says nothing, so a held flick that fires at tick 60 is told nothing; one nothing ever
## answers is still told, at 96. The director's own refusals (stick_refused, press_refused) end the wait at once, so their knocks do not move. Off, the wait is refuseTicks (30) as ever.
func _kept() -> void:
	var sw: Dictionary = SimInputData.timing.get("switches", {})
	sw["flickKept"] = true
	SimInputData.timing["switches"] = sw
	SimInputData.invalidate()
	var k: int = SimInputData.ti(["strike", "refuseTicksKept"], 120)
	ok(k >= 91 and SimInputData.flick_kept_on(), "kept: refuseTicksKept is above the director's 90-tick keep (%d) and the switch reads on" % k)
	var held: Array = _kept_run(60, "start")
	ok((held[0] as Array).is_empty() and int(held[1]) == 0, "kept: a flick the director held for 60 ticks and then started is told nothing (no 'Didn't start'): %s" % str(held))
	var late: Array = _kept_run(112, "start")
	ok((late[0] as Array).is_empty() and int(late[1]) == 0, "kept: held 112 ticks, the longest answer the probe saw (113),  it is still told nothing: %s" % str(late))
	var cue: Array = _kept_run(60, "stick_refused")
	ok((cue[0] as Array).is_empty() and int(cue[1]) == 0, "kept: a refusal the director says at 60 is the director's knock alone, the hub adds none: %s" % str(cue))
	var none: Array = _kept_run(-1, "")
	ok((none[0] as Array).size() == 1 and str(none[0][0]["code"]) == "no_answer" and int(none[1]) == 1, "kept: a flick nothing ever answers is still told 'no answer', once: %s" % str(none))
	ok(int(none[2]) >= 10 + k and int(none[2]) <= 10 + k + 6, "kept: ... at refuseTicksKept live ticks after the request (request about tick 12, told at %d)" % int(none[2]))
	sw["flickKept"] = false
	SimInputData.timing["switches"] = sw
	SimInputData.invalidate()
	var off: Array = _kept_run(-1, "")
	var r: int = SimInputData.ti(["strike", "refuseTicks"], 30)
	ok((off[0] as Array).size() == 1 and int(off[2]) >= 10 + r and int(off[2]) <= 10 + r + 6, "kept off (the control): the unanswered flick is told at refuseTicks = %d, told at %d: %s" % [r, int(off[2]), str(off)])
	var held_off: Array = _kept_run(60, "start")
	ok((held_off[0] as Array).size() == 1 and str(held_off[0][0]["code"]) == "no_answer", "kept off (the control): the same held flick is told 'Didn't start' at %d, then it fires anyway: %s" % [r, str(held_off)])


## One flick on a pad through the hub (request at tick 10), answered by `answer` at `at` ticks after the request (-1: never); run 200 ticks. Returns [refusals, knocks, the tick of the first knock].
func _kept_run(at: int, answer: String) -> Array:
	var hub := SimInputHub.new()
	hub.set_humans(true, false)
	hub.pad_button(7, "south", true)
	hub.pad_button(7, "south", false)
	hub.take_joins()
	hub.set_humans(true, false)
	var refusals: Array = []
	var knocks: int = 0
	var first: int = -1
	var req: int = -1
	for t in range(200):
		if t == 10:
			hub.pad_stick_right(7, 1.0, 0.0)
		if t == 14:
			hub.pad_stick_right(7, 0.0, 0.0)
		var i: SimIntent = hub.intent(0)
		if i.rsStart and req < 0:
			req = t
		if req >= 0 and at >= 0 and t == req + at:
			if answer == "start":
				hub.note_stick_started(0)
			else:
				hub.note_press_answered(0)
		for h in hub.take_haptics():
			if str(h.get("kind", "")) == "stick_refused":
				knocks += 1
				if first < 0:
					first = t
		refusals.append_array(hub.take_refusals())
		hub.consumed()
	return [refusals, knocks, first]


func _hub() -> void:
	var none: Array = _hub_run("")
	ok((none[0] as Array).size() == 1 and str(none[0][0]["code"]) == "no_answer" and int(none[1]) == 1, "hub: an unanswered flick is one 'no answer' and one knock after refuseTicks (the control): %s" % str(none))
	for a in ["start", "stick_refused", "press_refused"]:
		var r: Array = _hub_run(a)
		ok((r[0] as Array).is_empty() and int(r[1]) == 0, "hub: answered by %s, the hub's wait ends: no 'no answer', no second knock: %s" % [a, str(r)])
	_kept()
	# An answer for the other slot, or none, changes nothing for this one.
	var hub := SimInputHub.new()
	hub.note_press_answered(-1)
	hub.note_press_answered(2)
	ok(true, "hub: a slot outside 0 and 1 is ignored")
