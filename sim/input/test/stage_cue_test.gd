extends SceneTree
## Headless checks for the charge's stages on the pad (docs/controls/stage-pulses.md): Encounter's cue stick_stage through SimHaptics.event_requests, behind switches.hapticStages, and the hub's own
## three rungs stepping aside while it is on. From the repo root:
##   godot --headless --path . --script res://sim/input/test/stage_cue_test.gd
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
	_sw(true, true, true, true)
	_ladder()
	_steps()
	_switches()
	_hub()
	print("stage_cue_test: %d checks, %d failed" % [checks, fails])
	quit(1 if fails > 0 else 0)


func _sw(right: bool, ladder: bool, stages: bool, impact: bool) -> void:
	var sw: Dictionary = SimInputData.timing.get("switches", {})
	sw["rightStick"] = right
	sw["hapticLadder"] = ladder
	sw["hapticStages"] = stages
	sw["hapticImpact"] = impact
	sw["hapticRefused"] = false
	SimInputData.timing["switches"] = sw
	SimInputData.clear_overrides()
	SimInputData.invalidate()
	SimHaptics.reset_stage_state()


func _cue(actor: int, k: int, n: int, source: String = "") -> SimState.FxEvent:
	var e := SimState.FxEvent.new()
	e.type = "cue"
	e.kind = "stick_stage"
	e.actor = float(actor)
	e.text = str(k)
	e.source = source
	e.k = float(k)
	e.n = n
	return e


## The kinds a charge to its top is told, one cue per stage.
func _climb(actor: int, n: int) -> Array:
	var out: Array = []
	for k in range(1, n + 1):
		for r in SimHaptics.event_requests(_cue(actor, k, n)):
			out.append(r)
	return out


func _kinds(a: Array) -> Array:
	var out: Array = []
	for r in a:
		out.append(String(r["kind"]))
	return out


func _ladder() -> void:
	var two: Array = _climb(0, 2)
	ok(_kinds(two) == ["ladder_1", "ladder_3"], "a base fighter's two stages are the tick and the thud, no more: %s" % str(_kinds(two)))
	SimHaptics.reset_stage_state()
	var six: Array = _climb(1, 6)
	ok(_kinds(six) == ["ladder_1", "ladder_2", "ladder_2", "ladder_2", "ladder_2", "ladder_3"], "six stages: the tick, four knocks, the thud: %s" % str(_kinds(six)))
	var sc: Array = []
	for r in six:
		sc.append(float(r["scale"]))
	ok(sc[1] < sc[2] and sc[2] < sc[3] and sc[3] < sc[4] and sc[5] == 1.0 and sc[1] >= 0.7, "the knocks climb and none is louder than the thud: %s" % str(sc))
	ok(int(six[0]["slot"]) == 1, "to the charger's pad (slot 1)")
	SimHaptics.reset_stage_state()
	var three: Array = _climb(0, 3)
	ok(_kinds(three) == ["ladder_1", "ladder_2", "ladder_3"], "three stages are the old ladder: %s" % str(_kinds(three)))
	SimHaptics.reset_stage_state()
	var one: Array = _climb(0, 1)
	ok(_kinds(one) == ["ladder_3"], "a one-stage charge is the thud: %s" % str(_kinds(one)))


func _steps() -> void:
	SimHaptics.reset_stage_state()
	var a: Array = []
	a.append_array(SimHaptics.event_requests(_cue(0, 1, 4)))
	a.append_array(SimHaptics.event_requests(_cue(0, 2, 4)))
	a.append_array(SimHaptics.event_requests(_cue(0, 3, 4)))
	ok(a.size() == 3, "three stages climbed: three pulses")
	ok(SimHaptics.event_requests(_cue(0, 2, 4)).is_empty(), "a step down (3 to 2) says nothing")
	ok(_kinds(SimHaptics.event_requests(_cue(0, 3, 4))) == ["ladder_2"], "climbing back to 3 is told again")
	ok(SimHaptics.event_requests(_cue(0, 3, 4)).is_empty(), "the same stage twice is told once")
	var cap: Array = SimHaptics.event_requests(_cue(0, 3, 4, "capped"))
	ok(_kinds(cap) == ["stick_refused"] and absf(float(cap[0]["scale"]) - 0.6) < 0.001, "capped is the knock of a press that went nowhere, 0.6, and no stage pulse: %s" % str(cap))
	# A new charge starts at the root even when the last one ended high.
	ok(_kinds(SimHaptics.event_requests(_cue(0, 1, 4))) == ["ladder_1"], "a new charge's first stage is a tick whatever the last reached")
	ok(_kinds(SimHaptics.event_requests(_cue(0, 2, 4))) == ["ladder_2"], "and its second a knock")
	# The other pad has its own last stage.
	SimHaptics.reset_stage_state()
	SimHaptics.event_requests(_cue(0, 1, 4))
	SimHaptics.event_requests(_cue(0, 2, 4))
	ok(_kinds(SimHaptics.event_requests(_cue(1, 2, 4))) == ["ladder_2"], "a second pad's stage 2 is told on its own")
	# Out-of-range cues are nothing.
	ok(SimHaptics.event_requests(_cue(-1, 1, 4)).is_empty() and SimHaptics.event_requests(_cue(2, 1, 4)).is_empty(), "a cue with no pad is nothing")
	ok(SimHaptics.event_requests(_cue(0, 0, 4)).is_empty() and SimHaptics.event_requests(_cue(0, 5, 4)).is_empty(), "stage 0, or a stage past the count, is nothing")


func _switches() -> void:
	_sw(true, true, false, true)
	ok(_climb(0, 4).is_empty(), "hapticStages off: no stage pulses")
	_sw(true, false, true, true)
	ok(_climb(0, 4).is_empty(), "hapticLadder off: none either (the ladder switch is the pad's charge rumble)")
	_sw(false, true, true, true)
	ok(_climb(0, 4).is_empty(), "rightStick off: none")
	_sw(true, true, true, false)
	ok(_climb(0, 2).size() == 2, "hapticImpact off does not silence the stages")
	# Impact events still behave as they did.
	var l := SimState.FxEvent.new()
	l.type = "land"
	l.actor = 0.0
	l.spd = 3000.0
	ok(SimHaptics.event_requests(l).is_empty(), "with hapticImpact off a landing is still nothing")
	_sw(true, true, true, true)
	ok(SimHaptics.event_requests(l).size() == 1, "and with it on a landing is one request, as before")
	var other := SimState.FxEvent.new()
	other.type = "cue"
	other.kind = "stick_start"
	other.actor = 0.0
	ok(SimHaptics.event_requests(other).is_empty(), "another cue is nothing")


func _hub() -> void:
	# A held stick through the hub for 60 ticks: with hapticStages the hub's own rungs are silent, and the throw's thump still answers.
	for stages in [false, true]:
		_sw(true, true, stages, true)
		var hub := SimInputHub.new()
		hub.set_humans(true, false)
		hub.pad_button(7, "south", true)
		hub.pad_button(7, "south", false)
		hub.take_joins()
		hub.set_humans(true, false)
		var kinds: Array = []
		for t in range(100):
			hub.pad_stick_right(7, 1.0 if (t >= 10 and t < 70) else 0.0, 0.0)
			hub.intent(0)
			for r in hub.take_haptics():
				kinds.append(String(r["kind"]))
			hub.consumed()
		if stages:
			ok(kinds == ["release_thump"], "hub, hapticStages on: no rungs of its own, the throw's thump stays: %s" % str(kinds))
		else:
			ok(kinds == ["ladder_1", "ladder_2", "ladder_3", "release_thump"], "hub, hapticStages off: the three rungs as before: %s" % str(kinds))
	_sw(true, true, true, true)
