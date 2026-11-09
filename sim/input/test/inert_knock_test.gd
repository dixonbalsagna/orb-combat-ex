extends SceneTree
## Headless checks for the inert-layer knock (docs/controls/inert-knock.md; timing.json switches.inertKnock, off): the right stick does nothing while RT is held (the charge owns it) or LB and RB are both held (strike.inertMasks),
## and said nothing. With the switch each push there is told once: the refusal code "charging" (RT) or "warding" (LB + RB), one pad knock and one row for UI. From the repo root:
##   godot --headless --path . --script res://sim/input/test/inert_knock_test.gd
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
	_on()
	_sw(false)
	_off()
	SimInputData.pin_switches_off()
	print("inert_knock_test: %d checks, %d failed" % [checks, fails])
	quit(1 if fails > 0 else 0)


func _sw(on: bool) -> void:
	var sw: Dictionary = SimInputData.timing.get("switches", {})
	sw["rightStick"] = true
	sw["hapticRefused"] = true
	sw["inertKnock"] = on
	SimInputData.timing["switches"] = sw
	SimInputData.clear_overrides()
	SimInputData.invalidate()


## One pad through the hub: hold the buttons / triggers in `held` (pairs [kind, name]), push the right stick for `push` ticks (0 none), rest, `again` pushes after a rest.
## Returns {knocks: [reasons], rows: [codes], start: bool (an rsStart seen)}.
func _run(held: Array, push: int, again: int = 0) -> Dictionary:
	var hub := SimInputHub.new()
	hub.set_humans(true, false)
	hub.pad_button(7, "south", true)
	hub.pad_button(7, "south", false)
	hub.take_joins()
	hub.set_humans(true, false)
	var out := {"knocks": [], "rows": [], "start": false}
	var t: int = 0
	for k in range(8):
		_tick(hub, out)
	for h in held:
		if h[0] == "b":
			hub.pad_button(7, h[1], true)
		else:
			hub.pad_trigger(7, h[1], 1.0)
	for k in range(14):
		_tick(hub, out)
	for n in [push, again]:
		if n <= 0:
			continue
		hub.pad_stick_right(7, 1.0, 0.0)
		for k in range(n):
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
		if str(h.get("kind", "")) == "stick_refused" and str(h.get("reason", "")) != "no_answer":   # (no director here: a strike request goes unanswered and the hub says so after refuseTicks, which is not this test's business)
			(out["knocks"] as Array).append(str(h.get("reason", "")))
	for r in hub.take_refusals():
		if str(r["code"]) != "no_answer":
			(out["rows"] as Array).append(str(r["code"]))
	hub.consumed()


func _on() -> void:
	var rt: Dictionary = _run([["t", "rt"]], 20)
	ok(rt["knocks"] == ["charging"] and rt["rows"] == ["charging"] and not rt["start"], "on: a push with RT held is told once: one knock and one row, code charging, and no strike started: %s" % str(rt))
	var held: Dictionary = _run([["t", "rt"]], 90)
	ok(held["knocks"] == ["charging"] and held["rows"] == ["charging"], "on: the stick held out the whole time is still one: %s" % str(held))
	var twice: Dictionary = _run([["t", "rt"]], 20, 20)
	ok(twice["knocks"] == ["charging", "charging"] and twice["rows"] == ["charging", "charging"], "on: a second push after the stick rests is a second knock: %s" % str(twice))
	var ward: Dictionary = _run([["b", "lb"], ["b", "rb"]], 20)
	ok(ward["knocks"] == ["warding"] and ward["rows"] == ["warding"] and not ward["start"], "on: a push with LB and RB both held is told once, code warding: %s" % str(ward))
	var free: Dictionary = _run([], 20)
	ok(free["knocks"].is_empty() and free["rows"].is_empty() and free["start"], "on: a push with no layer held is a strike request, told nothing: %s" % str(free))
	var rb: Dictionary = _run([["b", "rb"]], 20)
	ok(rb["knocks"].is_empty() and rb["rows"].is_empty() and rb["start"], "on: a push with RB held (the beam layer) is a strike request, told nothing: %s" % str(rb))
	var lb: Dictionary = _run([["b", "lb"]], 20)
	ok(lb["knocks"].is_empty() and lb["rows"].is_empty(), "on: a push with LB held alone is not told here: %s" % str(lb))
	var nostick: Dictionary = _run([["t", "rt"]], 0)
	ok(nostick["knocks"].is_empty() and nostick["rows"].is_empty(), "on: RT held with no push says nothing: %s" % str(nostick))
	ok(SimHaptics.REFUSALS.has("charging") and SimHaptics.refusal_word("charging") == "Charging" and SimHaptics.refusal_word("warding") == "Warding", "on: both codes have their word")


## Off, the control: the same push says nothing (it never did).
func _off() -> void:
	var rt: Dictionary = _run([["t", "rt"]], 20)
	ok(rt["knocks"].is_empty() and rt["rows"].is_empty() and not rt["start"], "off (the control): a push with RT held starts nothing and says nothing: %s" % str(rt))
	var ward: Dictionary = _run([["b", "lb"], ["b", "rb"]], 20)
	ok(ward["knocks"].is_empty() and ward["rows"].is_empty(), "off (the control): LB + RB the same: %s" % str(ward))
