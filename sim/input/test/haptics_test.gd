extends SceneTree
## Headless checks for the haptic pulses (sim/input/haptics.gd, docs/controls/haptics.md): the steps for each kind on a pad and a phone,
## the hardware floors, the data behind the numbers, the gap between requests, the player's option, and that asking changes nothing in
## the intents. From the repo root:
##   godot --headless --path . --script res://sim/input/test/haptics_test.gd
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
	_data()
	_steps()
	_plan()
	_hub()
	print("haptics_test: %d checks, %d failed" % [checks, fails])
	quit(1 if fails > 0 else 0)


func _with(block, f: Callable) -> void:
	var saved = SimInputData.timing.get("haptics", null)
	if block == null:
		SimInputData.timing.erase("haptics")
	else:
		SimInputData.timing["haptics"] = block
	f.call()
	if saved == null:
		SimInputData.timing.erase("haptics")
	else:
		SimInputData.timing["haptics"] = saved


func _data() -> void:
	var ks: Array = SimHaptics.kinds()
	ok(ks.size() == 5 and ks.has("launch_open") and ks.has("form_prompt") and ks.has("struggle_pulse") and ks.has("struggle_surge") and ks.has("struggle_lose"), "data: the five kinds (UI's two and the struggle's three)")
	ok(SimHaptics.min_gap_ms() == 80, "data: requests for one slot are at least 80 ms apart")
	# The data file and the code defaults agree.
	var same: bool = true
	for k in ks:
		for dev in ["pad", "handheld"]:
			var from_data: Array = SimHaptics.steps(k, dev)
			var holder: Array = []
			_with(null, func(): holder.append(SimHaptics.steps(k, dev)))
			same = same and from_data == holder[0]
	ok(same, "data: timing.json and the code defaults give the same steps for every kind and device")


func _steps() -> void:
	# launch_open: Audio's shape, a thump and a ring after it.
	var lp: Array = SimHaptics.steps("launch_open", "pad")
	ok(lp.size() == 2 and lp[0]["at"] == 0 and absf(float(lp[0]["weak"]) - 0.3) < 1e-9 and absf(float(lp[0]["strong"]) - 0.7) < 1e-9 and lp[0]["ms"] == 80, "steps: a launch opening is a thump first (strong 0.7, weak 0.3, 80 ms)")
	ok(lp[1]["at"] == 90 and absf(float(lp[1]["weak"]) - 0.2) < 1e-9 and float(lp[1]["strong"]) == 0.0 and lp[1]["ms"] == 60, "steps: and the ring 90 ms later (weak 0.2, 60 ms)")
	var lh: Array = SimHaptics.steps("launch_open", "handheld")
	ok(lh.size() == 2 and lh[0]["ms"] == 25 and lh[1]["at"] == 85 and lh[1]["ms"] == 10, "steps: on a phone 25 ms, a 60 ms gap, then 10 ms")
	# The struggle's three: lengthened to the hardware floor, never dropped.
	var sp: Array = SimHaptics.steps("struggle_pulse", "pad")
	ok(sp.size() == 1 and sp[0]["ms"] == 20 and float(sp[0]["weak"]) == 0.0 and absf(float(sp[0]["strong"]) - 0.4) < 1e-9, "steps: the beat is a low thud of at least the 20 ms floor")
	ok(SimHaptics.steps("struggle_surge", "pad")[0]["ms"] == 30 and SimHaptics.steps("struggle_lose", "pad")[0]["ms"] == 60, "steps: a player's own surge 30 ms, the loser's end 60 ms")
	ok(SimHaptics.steps("struggle_pulse", "handheld")[0]["ms"] == 10 and SimHaptics.steps("struggle_surge", "handheld")[0]["ms"] == 15 and SimHaptics.steps("struggle_lose", "handheld")[0]["ms"] == 40, "steps: on a phone 10, 15 and 40 ms")
	ok(SimHaptics.steps("nonsense", "pad").is_empty() and SimHaptics.steps("launch_open", "keyboard").is_empty(), "steps: an unknown kind or device has none")
	# Audio asked for 8 ms on each beat: a request under the floor is lengthened to it (a pad motor needs 20 to 40 ms to spin up) ...
	_with({"struggle_pulse": {"pad": [{"at": 0, "weak": 0.0, "strong": 0.4, "ms": 8}], "handheld": [{"at": 0, "ms": 4}]}}, func():
		ok(SimHaptics.steps("struggle_pulse", "pad")[0]["ms"] == 20 and SimHaptics.steps("struggle_pulse", "handheld")[0]["ms"] == 10, "floor: 8 ms on a pad is raised to 20, and 4 ms on a phone to 10"))
	# ... the floors are data ...
	_with({"padMinMs": 30, "handheldMinMs": 12, "struggle_pulse": {"pad": [{"at": 0, "weak": 0.0, "strong": 0.4, "ms": 8}], "handheld": [{"at": 0, "ms": 4}]}}, func():
		ok(SimHaptics.steps("struggle_pulse", "pad")[0]["ms"] == 30 and SimHaptics.steps("struggle_pulse", "handheld")[0]["ms"] == 12, "floor: the floors are data (30 and 12 here)"))
	# ... a pulse of no length or, on a pad, no strength is left out (and a length of 0 is never handed on: Godot reads 0 as "as long as it can") ...
	_with({"launch_open": {"pad": [{"at": 0, "weak": 0.5, "strong": 0.5, "ms": 0}, {"at": 10, "weak": 0.0, "strong": 0.0, "ms": 50}, {"at": 20, "weak": 0.1, "strong": 0.0, "ms": 50}], "handheld": [{"at": 0, "ms": 0}]}}, func():
		var s: Array = SimHaptics.steps("launch_open", "pad")
		ok(s.size() == 1 and s[0]["at"] == 20 and SimHaptics.steps("launch_open", "handheld").is_empty(), "floor: no length, or no strength on a pad, is left out; nothing is passed as 0 ms"))
	# ... motors are clamped, steps are in order and at most four, and a later `at` is capped at a second.
	_with({"launch_open": {"pad": [{"at": 50, "weak": 2.0, "strong": -1.0, "ms": 40}, {"at": 0, "weak": 0.4, "strong": 0.0, "ms": 40}, {"at": 5000, "weak": 0.4, "strong": 0.0, "ms": 40}, {"at": 10, "weak": 0.4, "strong": 0.0, "ms": 40}, {"at": 20, "weak": 0.4, "strong": 0.0, "ms": 40}]}}, func():
		var s2: Array = SimHaptics.steps("launch_open", "pad")
		ok(s2.size() == 4 and s2[0]["at"] == 0 and s2[1]["at"] == 10 and s2[2]["at"] == 20 and s2[3]["at"] == 50 and float(s2[3]["weak"]) == 1.0 and float(s2[3]["strong"]) == 0.0, "steps: sorted by time, at most four, motors clamped to 0 to 1 (the 5000 ms one was the fifth and is dropped)"))
	_with({"launch_open": {"pad": [{"at": 5000, "weak": 0.4, "strong": 0.0, "ms": 40}]}}, func():
		ok(SimHaptics.steps("launch_open", "pad")[0]["at"] == 1000, "steps: a start later than a second is capped at a second"))
	# A bad entry in the data falls back and never throws.
	_with({"launch_open": {"pad": "nonsense", "handheld": [3, {"ms": 20}]}}, func():
		ok(SimHaptics.steps("launch_open", "pad").size() == 2 and SimHaptics.steps("launch_open", "handheld").size() == 1, "steps: a malformed list falls back to the defaults, a non-step entry is skipped"))


func _plan() -> void:
	var pad: Dictionary = {"kind": "pad", "id": 7}
	var p: Dictionary = SimHaptics.plan("launch_open", pad, true, -10000, 1000)
	ok(p.get("via", "") == "pad" and p["id"] == 7 and p["steps"].size() == 2, "plan: a pad gets the two steps on its own device id (7)")
	ok(absf(float(p["steps"][0]["seconds"]) - 0.08) < 1e-9 and absf(float(p["steps"][0]["strong"]) - 0.7) < 1e-9 and p["steps"][1]["at"] == 90 and absf(float(p["steps"][1]["seconds"]) - 0.06) < 1e-9, "plan: in seconds for Input.start_joy_vibration, the ring 90 ms later")
	var t: Dictionary = SimHaptics.plan("launch_open", {"kind": "touch", "id": -1}, true, -10000, 1000)
	ok(t.get("via", "") == "handheld" and t["steps"].size() == 2 and t["steps"][0]["ms"] == 25 and t["steps"][1]["at"] == 85, "plan: a phone gets 25 ms, then 10 ms 85 ms later, for Input.vibrate_handheld")
	ok(SimHaptics.plan("launch_open", {"kind": "kb", "id": -1}, true, -10000, 1000).is_empty(), "plan: a keyboard has nothing to vibrate")
	ok(SimHaptics.plan("launch_open", {"kind": "none", "id": -1}, true, -10000, 1000).is_empty(), "plan: a slot nobody holds gets nothing")
	ok(SimHaptics.plan("launch_open", {}, true, -10000, 1000).is_empty(), "plan: no target gets nothing")
	ok(SimHaptics.plan("nonsense", pad, true, -10000, 1000).is_empty(), "plan: an unknown kind gets nothing")
	ok(SimHaptics.plan("launch_open", pad, false, -10000, 1000).is_empty(), "plan: the player's haptics option off gets nothing")
	ok(SimHaptics.plan("launch_open", pad, true, 1000, 1079).is_empty() and not SimHaptics.plan("launch_open", pad, true, 1000, 1080).is_empty(), "plan: a second request inside 80 ms is dropped, at 80 it plays")
	ok(not SimHaptics.plan("launch_open", pad, true, 5000, 100).is_empty(), "plan: a clock that restarted plays rather than muting a slot for ever")
	ok(SimHaptics.allow(-10000, 0) and not SimHaptics.allow(0, 10), "allow: the first request plays, one 10 ms after does not")
	# The struggle's beat comes 3 times a second: well outside the gap.
	ok(not SimHaptics.plan("struggle_pulse", pad, true, 0, 333).is_empty(), "plan: the struggle's beat, 333 ms apart, always plays")
	# Every kind plans for both devices.
	var all_ok: bool = true
	for k in SimHaptics.kinds():
		all_ok = all_ok and not SimHaptics.plan(k, pad, true, -10000, 1000).is_empty() and not SimHaptics.plan(k, {"kind": "touch", "id": -1}, true, -10000, 1000).is_empty()
	ok(all_ok, "plan: every kind plays on a pad and on a phone")
	ok(SimHaptics.plan("launch_open", pad, true, -10000, 1000) == SimHaptics.plan("launch_open", pad, true, -10000, 1000), "plan: the same request gives the same plan")
	# The total length of a launch opening is Audio's 150 ms; no step starts a pulse of 0 seconds.
	var zero: bool = false
	for k in SimHaptics.kinds():
		for s in SimHaptics.plan(k, pad, true, -10000, 1000)["steps"]:
			zero = zero or float(s["seconds"]) <= 0.0
	ok(not zero and int(p["steps"][1]["at"]) + int(round(float(p["steps"][1]["seconds"]) * 1000.0)) == 150, "plan: no pad step has 0 seconds, and a launch opening is 150 ms in all")


## With the hub: each slot's own device is where its pulse goes; asking changes no intent.
func _hub() -> void:
	var hub := SimInputHub.new()
	hub.set_humans(true, false)
	hub.key("KeyJ", true)
	hub.key("KeyJ", false)
	hub.intent(0)
	hub.consumed()
	ok(SimHaptics.plan("launch_open", hub.rumble_target(0), true, -10000, 1000).is_empty(), "hub: a keyboard player gets no pulse")
	hub.pad_button(7, "south", true)
	hub.pad_button(7, "south", false)
	hub.take_joins()
	hub.set_humans(true, true)
	hub.intent(1)
	hub.consumed()
	var p1: Dictionary = SimHaptics.plan("launch_open", hub.rumble_target(1), true, -10000, 1000)
	ok(p1.get("via", "") == "pad" and p1["id"] == 7, "hub: player two's pad gets the pulse on its own id, and player one's keyboard none")
	var h1 := SimInputHub.new()
	var h2 := SimInputHub.new()
	for h in [h1, h2]:
		h.set_humans(true, false)
		h.pad_button(5, "west", true)
	var same: bool = true
	for k in range(40):
		var a: int = SimIntent.pack(h1.intent(0))
		SimHaptics.plan("launch_open", h2.rumble_target(0), true, -10000, k * 100)
		var b: int = SimIntent.pack(h2.intent(0))
		h1.consumed()
		h2.consumed()
		same = same and a == b
	ok(same, "hub: asking for a pulse changes nothing in the intents")
