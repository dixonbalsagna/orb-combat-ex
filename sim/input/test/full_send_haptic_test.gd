extends SceneTree
## Headless checks for the stick's full-send haptic (docs/controls/full-send-haptic.md; Encounter's cue stick_full_send, docs/director/pending/stick-slam/): the sender's pad gets one `full_send` (the
## heaviest thing the pad does), scaled by the family (slam 1.0, bury 0.9, the rest 0.8), behind switches.hapticLadder with the right stick. From the repo root:
##   godot --headless --path . --script res://sim/input/test/full_send_haptic_test.gd
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
	_cue()
	_shape()
	_sw(false)
	_off()
	SimInputData.pin_switches_off()
	print("full_send_haptic_test: %d checks, %d failed" % [checks, fails])
	quit(1 if fails > 0 else 0)


func _sw(on: bool) -> void:
	var sw: Dictionary = SimInputData.timing.get("switches", {})
	sw["rightStick"] = true
	sw["hapticLadder"] = on
	sw["hapticImpact"] = false
	SimInputData.timing["switches"] = sw
	SimInputData.clear_overrides()
	SimInputData.invalidate()


func _e(actor: int, source: String) -> SimState.FxEvent:
	var e := SimState.FxEvent.new()
	e.type = "cue"
	e.kind = "stick_full_send"
	e.actor = actor
	e.text = "down"
	e.source = source
	return e


func _cue() -> void:
	var want: Dictionary = {"slamDown": 1.0, "bury": 0.9, "skyward": 0.8, "across": 0.8, "acrossBehind": 0.8}
	for fam in want.keys():
		var r: Array = SimHaptics.event_requests(_e(0, fam))
		ok(r.size() == 1 and r[0]["kind"] == "full_send" and int(r[0]["slot"]) == 0 and absf(float(r[0]["scale"]) - float(want[fam])) < 0.001, "cue: %s is one full_send to the sender at %.1f: %s" % [fam, want[fam], str(r)])
	var r1: Array = SimHaptics.event_requests(_e(1, "slamDown"))
	ok(r1.size() == 1 and int(r1[0]["slot"]) == 1, "cue: the sender is the slot, either one")
	ok(SimHaptics.event_requests(_e(2, "slamDown")).is_empty() and SimHaptics.event_requests(_e(-1, "slamDown")).is_empty(), "cue: only slots 0 and 1 are knocked")
	ok(float(SimHaptics.event_requests(_e(0, "something"))[0]["scale"]) == 0.8, "cue: an unknown family is 0.8")


func _shape() -> void:
	ok(SimHaptics.kinds().has("full_send"), "shape: full_send is a kind")
	var pad: Array = SimHaptics.steps("full_send", "pad", 1.0)
	ok(pad.size() == 3 and float(pad[0]["strong"]) >= 0.99, "shape: three steps, the first at full strength on the low motor (%s)" % str(pad))
	var best: float = 0.0
	for k in ["release_thump", "launch_felt", "landing_thud", "hit_taken", "ladder_3", "blow_land"]:
		var sum_k: float = 0.0
		for st in SimHaptics.steps(k, "pad", 1.0):
			sum_k += float(st["strong"]) * float(st["ms"])
		best = maxf(best, sum_k)
	var mine: float = 0.0
	for st in pad:
		mine += float(st["strong"]) * float(st["ms"])
	ok(mine > best, "shape: it carries the most low-motor weight of any kind (%.1f against %.1f)" % [mine, best])
	ok(SimHaptics.steps("full_send", "handheld", 1.0).size() == 2, "shape: the phone gets two pulses")
	ok(SimHaptics.kind_gap_ms("full_send") >= 400, "shape: a full send is rate-limited (400 ms), so two in a row never buzz")


func _off() -> void:
	ok(SimHaptics.event_requests(_e(0, "slamDown")).is_empty(), "off: with the ladder rumble off the cue asks for nothing")
