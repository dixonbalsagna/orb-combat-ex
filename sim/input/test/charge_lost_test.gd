extends SceneTree
## Headless checks for a lost charge being felt (docs/controls/charge-lost.md; timing.json switches.chargeLostCue, off): the heavy's charge (the director's windup cue, text end, source b) taken by the foe's blow (k 2) or lost to a
## stagger or the brawl's end (k 3), a stick strike's or a beam hold's charge taken by a blow (stick_refused, source hit or taken), and a right-stick hold let go of before stage 1 (the hub). One pad buzz of its own for each, a refusal
## code for UI's word, the charger's pad only. From the repo root:
##   godot --headless --path . --script res://sim/input/test/charge_lost_test.gd
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
	SimInputData.pin_switches_off()
	_sw(true)
	_cues()
	_stick_cues()
	_plan()
	_hold()
	_sw(false)
	_off()
	SimInputData.pin_switches_off()
	print("charge_lost_test: %d checks, %d failed" % [checks, fails])
	quit(1 if fails > 0 else 0)


func _sw(on: bool) -> void:
	var sw: Dictionary = SimInputData.timing.get("switches", {})
	sw["rightStick"] = true
	sw["hapticRefused"] = true
	sw["hapticImpact"] = true
	sw["chargeLostCue"] = on
	SimInputData.timing["switches"] = sw
	SimInputData.clear_overrides()
	SimInputData.invalidate()


func _wu(actor: int, text: String, source: String, k: int) -> SimState.FxEvent:
	var e := SimState.FxEvent.new()
	e.type = "cue"
	e.kind = "windup"
	e.actor = float(actor)
	e.text = text
	e.source = source
	e.k = float(k)
	return e


func _kinds(a: Array) -> Array:
	var out: Array = []
	for r in a:
		out.append(String(r["kind"]))
	return out


func _cues() -> void:
	var broken: Array = SimHaptics.event_requests(_wu(0, "end", "b", 2))
	ok(broken.size() == 1 and broken[0]["kind"] == "charge_broken" and int(broken[0]["slot"]) == 0 and broken[0]["reason"] == "charge_broken", "on: a heavy's wind-up stopped by a blow (k 2) is charge_broken on the charger's pad: %s" % str(broken))
	var lapsed: Array = SimHaptics.event_requests(_wu(1, "end", "b", 3))
	ok(lapsed.size() == 1 and lapsed[0]["kind"] == "charge_lapsed" and int(lapsed[0]["slot"]) == 1 and lapsed[0]["reason"] == "charge_lapsed", "on: lost to a stagger or the brawl's end (k 3) is charge_lapsed, on slot 1's pad: %s" % str(lapsed))
	ok(SimHaptics.event_requests(_wu(0, "end", "b", 1)).is_empty(), "on: a thrown heavy (k 1) says nothing here: it was the player's")
	ok(SimHaptics.event_requests(_wu(0, "end", "b", 4)).is_empty(), "on: a heavy that missed (k 4) says nothing here: the blow was thrown")
	ok(SimHaptics.event_requests(_wu(0, "end", "y", 2)).is_empty() and SimHaptics.event_requests(_wu(0, "end", "y", 3)).is_empty(), "on: a medium's wind-up (Y) has no charge, so losing it is only the blow's thud")
	ok(SimHaptics.event_requests(_wu(0, "start", "b", 2)).is_empty() and SimHaptics.event_requests(_wu(0, "charge", "b", 2)).is_empty(), "on: a wind-up's start and its charge begin say nothing")
	ok(SimHaptics.event_requests(_wu(-1, "end", "b", 2)).is_empty() and SimHaptics.event_requests(_wu(2, "end", "b", 2)).is_empty(), "on: only slots 0 and 1")
	ok(SimHaptics.requests("windup", 0, 1, "end", 0.0, -1, "b").is_empty(), "on: the cue-name path says nothing for windup (the event path owns it, once)")
	# the three have a word of their own, and the words differ
	var words: Dictionary = {}
	for code in ["charge_broken", "charge_lapsed", "hold_short"]:
		ok(SimHaptics.REFUSALS.has(code) and String(SimHaptics.REFUSALS[code]["word"]) != "" and SimHaptics.refusal_code(code) == code, "on: %s is a code with its word" % code)
		words[SimHaptics.refusal_word(code)] = true
	ok(words.size() == 3, "on: and the three words differ")


func _stick_cues() -> void:
	# a stick strike's charge stopped by a blow ("hit") or a beam hold lost to one ("taken"): the lost charge, not the old knock and not silence
	for src in ["hit", "taken"]:
		var r: Array = SimHaptics.requests("stick_refused", 0, -1, "up", 0.0, -1, src)
		ok(r.size() == 1 and r[0]["kind"] == "charge_broken" and int(r[0]["slot"]) == 0, "on: a stick_refused '%s' (a blow took the charge) is charge_broken, even with hapticImpact on: %s" % [src, str(r)])
	var ki: Array = SimHaptics.requests("stick_refused", 1, -1, "up", 0.0, -1, "ki")
	ok(ki.size() == 1 and ki[0]["kind"] == "stick_refused" and ki[0]["reason"] == "no_energy", "on: the other refusals are untouched (ki is still the knock)")
	var cancel: Array = SimHaptics.requests("stick_refused", 0, -1, "up", 0.0, -1, "cancel")
	ok(cancel.size() == 1 and cancel[0]["kind"] == "stick_refused" and cancel[0]["reason"] == "cancelled", "on: and the player's own guard or dodge ending a charge is not called a lost charge")
	ok(SimHaptics.requests("stick_refused", 1, -1, "up", 0.0, -1, "soon").is_empty(), "on: the wait for a free target stays silent")


func _plan() -> void:
	var pad: Dictionary = {"kind": "pad", "id": 3}
	var hit: Dictionary = SimHaptics.plan("hit_taken", pad, true, -100000, 1000)
	ok(not hit.is_empty(), "plan: the blow's own thud plays")
	# the lost charge arrives on the same tick as the thud (1 ms later on the host's clock): it plays over it
	var over: Dictionary = SimHaptics.plan("charge_broken", pad, true, 1000, 1001)
	ok(not over.is_empty() and over["via"] == "pad" and over["steps"].size() == 3 and int(over["steps"][0]["at"]) == 0, "plan: charge_broken plays inside the slot gap of the thud that came with it (and replaces it): %s" % str(over))
	var lap: Dictionary = SimHaptics.plan("charge_lapsed", pad, true, 1000, 1001)
	ok(not lap.is_empty(), "plan: so does charge_lapsed")
	ok(SimHaptics.plan("stick_refused", pad, true, 1000, 1001).is_empty(), "plan: a kind that does not override still waits out the slot gap (the control)")
	ok(SimHaptics.plan("hold_short", pad, true, 1000, 1001).is_empty(), "plan: hold_short waits too: the faintest tap never covers another pulse")
	# but never twice in a row: the kind's own gap
	ok(SimHaptics.plan("charge_broken", pad, true, 1001, 1100, 1.0, 1001).is_empty(), "plan: a second charge_broken 100 ms after the first is dropped (gapMs 300)")
	ok(not SimHaptics.plan("charge_broken", pad, true, 1001, 1400, 1.0, 1001).is_empty(), "plan: and 400 ms later it plays")
	ok(SimHaptics.plan("charge_broken", {"kind": "none"}, true, -100000, 1000).is_empty() and SimHaptics.plan("charge_broken", pad, false, -100000, 1000).is_empty(), "plan: a keyboard and the haptics option off are silent")
	ok(SimHaptics.plan("charge_broken", {"kind": "touch"}, true, -100000, 1000)["via"] == "handheld", "plan: a phone buzzes it by lengths")
	# the three are told apart on the pad and none is the high motor alone
	var sigs: Dictionary = {}
	for k in ["charge_broken", "charge_lapsed", "hold_short", "hit_taken", "stick_refused", "release_thump"]:
		var sig: String = ""
		var low_only: bool = true
		for s in SimHaptics.steps(k, "pad"):
			sig += "%d/%.2f/%.2f/%d;" % [int(s["at"]), float(s["weak"]), float(s["strong"]), int(s["ms"])]
			low_only = low_only and float(s["strong"]) > 0.0
		sigs[sig] = true
		ok(low_only or k == "stick_refused", "kinds: %s has a low motor in every step (chunky, never tinny)" % k)
	ok(sigs.size() == 6, "kinds: none of them buzzes the pad like the thud, the knock or the throw")


## One pad through the hub: hold RB (the beam layer) or nothing, push the right stick for `push` ticks, rest. Returns {kinds: [haptic kinds], rows: [codes]}.
func _run(push: int, held_rb: bool = false) -> Dictionary:
	var hub := SimInputHub.new()
	hub.set_humans(true, false)
	hub.pad_button(7, "south", true)
	hub.pad_button(7, "south", false)
	hub.take_joins()
	hub.set_humans(true, false)
	var out := {"kinds": [], "rows": [], "start": false}
	for k in range(8):
		_tick(hub, out)
	if held_rb:
		hub.pad_button(7, "rb", true)
	for k in range(14):
		_tick(hub, out)
	hub.pad_stick_right(7, 1.0, 0.0)
	for k in range(push):
		_tick(hub, out)
	hub.pad_stick_right(7, 0.0, 0.0)
	for k in range(24):
		_tick(hub, out)
	return out


func _tick(hub: SimInputHub, out: Dictionary) -> void:
	var i: SimIntent = hub.intent(0)
	if i.rsStart:
		out["start"] = true
	for h in hub.take_haptics():
		var kd: String = str(h.get("kind", ""))
		if kd == "hold_short" or kd == "stick_refused" and str(h.get("reason", "")) != "no_answer":
			(out["kinds"] as Array).append(kd)
	for r in hub.take_refusals():
		if str(r["code"]) != "no_answer":
			(out["rows"] as Array).append(str(r["code"]))
	hub.consumed()


func _hold() -> void:
	var shortest: int = SimInputData.short_hold_ticks()
	ok(shortest == 6, "hold: the data's least hold is 6 ticks")
	var flick: Dictionary = _run(3)
	ok(flick["start"] and flick["kinds"].is_empty() and flick["rows"].is_empty(), "hold: a 3-tick push is a flick: a strike request and no word: %s" % str(flick))
	var just_under: Dictionary = _run(shortest + 1)   # a push is the stick out for the settle (2 ticks) and then the hold
	var edge: Dictionary = _run(shortest + 2)
	var n8: Dictionary = _run(8)
	ok(n8["kinds"] == ["hold_short"] and n8["rows"] == ["hold_short"], "hold: an 8-tick hold let go of before stage 1 taps once, one row, code hold_short: %s" % str(n8))
	var n10: Dictionary = _run(10)
	ok(n10["kinds"] == ["hold_short"], "hold: and a 10-tick hold the same: %s" % str(n10))
	ok(just_under["kinds"].is_empty() and edge["kinds"] == ["hold_short"], "hold: held 5 ticks is a flick and says nothing; held 6 (the data's least) is told: %s / %s" % [str(just_under), str(edge)])
	var full: Dictionary = _run(20)
	ok(full["kinds"].is_empty() and full["rows"].is_empty(), "hold: a 20-tick push reached stage 1 (it does from 14): the ladder's own pulse, no short-hold tap: %s" % str(full))
	var rb: Dictionary = _run(8, true)
	ok(rb["kinds"] == ["hold_short"], "hold: with RB held (a quick beam let go early) the same: %s" % str(rb))
	var twice: Dictionary = _run(8)
	var hub := SimInputHub.new()
	ok(twice["rows"].size() == 1 and hub.take_refusals().is_empty(), "hold: one tap per hold, and a fresh hub has no rows")


## Off, the control: nothing new, and the old paths are as they were.
func _off() -> void:
	ok(SimHaptics.event_requests(_wu(0, "end", "b", 2)).is_empty() and SimHaptics.event_requests(_wu(0, "end", "b", 3)).is_empty(), "off (the control): a lost heavy charge says nothing new")
	var hit: Array = SimHaptics.requests("stick_refused", 0, -1, "up", 0.0, -1, "hit")
	ok(hit.is_empty(), "off (the control): a stick charge stopped by a blow is the blow's thud alone, as before (hapticImpact on)")
	var taken: Array = SimHaptics.requests("stick_refused", 0, -1, "up", 0.0, -1, "taken")
	ok(taken.size() == 1 and taken[0]["kind"] == "stick_refused" and taken[0]["reason"] == "hit", "off (the control): a beam hold taken is the old knock with the reason hit")
	var n8: Dictionary = _run(8)
	ok(n8["kinds"].is_empty() and n8["rows"].is_empty() and n8["start"], "off (the control): an 8-tick hold let go of early starts a strike and says nothing")
