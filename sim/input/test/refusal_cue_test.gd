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
	SimInputData.timing["switches"] = sw
	SimInputData.clear_overrides()
	SimInputData.invalidate()
	_source()
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
	ok(_reason("stick_refused", "right", "") == "other", "source: a stick_refused cue with a direction and no source reads other, not the direction")
	# An older caller that puts the reason in the text still reads.
	ok(_reason("stick_refused", "ki", "") == "no_energy" and _reason("press_refused", "stun_limit", "") == "stun_limit", "source: the reason in text with no source still reads (the old shape)")
	# The source wins over the text.
	ok(_reason("stick_refused", "late", "ki") == "no_energy", "source: the source wins over the text")
	# The mapping is unchanged otherwise: one knock, to the presser's pad.
	var r: Array = SimHaptics.requests("stick_refused", 1, -1, "right", 0.0, -1, "ki")
	ok(r.size() == 1 and r[0]["kind"] == "stick_refused" and int(r[0]["slot"]) == 1 and absf(float(r[0]["scale"]) - 1.0) < 0.001, "source: one stick_refused knock to slot 1")


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


func _hub() -> void:
	var none: Array = _hub_run("")
	ok((none[0] as Array).size() == 1 and str(none[0][0]["code"]) == "no_answer" and int(none[1]) == 1, "hub: an unanswered flick is one 'no answer' and one knock after refuseTicks (the control): %s" % str(none))
	for a in ["start", "stick_refused", "press_refused"]:
		var r: Array = _hub_run(a)
		ok((r[0] as Array).is_empty() and int(r[1]) == 0, "hub: answered by %s, the hub's wait ends: no 'no answer', no second knock: %s" % [a, str(r)])
	# An answer for the other slot, or none, changes nothing for this one.
	var hub := SimInputHub.new()
	hub.note_press_answered(-1)
	hub.note_press_answered(2)
	ok(true, "hub: a slot outside 0 and 1 is ignored")
