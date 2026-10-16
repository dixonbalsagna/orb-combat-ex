extends SceneTree
## Headless checks for the haptic pulses (sim/input/haptics.gd, docs/controls/haptics.md): what UI's request becomes for a pad, a
## phone, a keyboard and an empty slot, the data behind the numbers, the gap between pulses, the player's option, and that asking
## changes nothing in the intents. From the repo root:
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
	_plan()
	_hub()
	print("haptics_test: %d checks, %d failed" % [checks, fails])
	quit(1 if fails > 0 else 0)


func _data() -> void:
	ok(SimHaptics.kinds().has("launch_open") and SimHaptics.kinds().has("form_prompt") and SimHaptics.kinds().size() == 2, "data: the two kinds UI asks for")
	var lo: Dictionary = SimHaptics.numbers("launch_open")
	ok(absf(float(lo["weak"]) - 0.7) < 1e-9 and float(lo["strong"]) == 0.0 and lo["ms"] == 25 and lo["handheldMs"] == 25, "data: a launch opening is a sharp tick: the high motor, 25 ms")
	var fp: Dictionary = SimHaptics.numbers("form_prompt")
	ok(absf(float(fp["weak"]) - 0.3) < 1e-9 and absf(float(fp["strong"]) - 0.3) < 1e-9 and fp["ms"] == 15, "data: the form prompt is the host's old soft thump (0.3, 0.3, 15 ms), unchanged")
	ok(SimHaptics.numbers("nonsense").is_empty(), "data: an unknown kind has no numbers")
	ok(SimHaptics.min_gap_ms() == 80, "data: pulses for one slot are at least 80 ms apart")
	# The data wins over the defaults, and a value is clamped.
	var saved = SimInputData.timing.get("haptics", null)
	SimInputData.timing["haptics"] = {"launch_open": {"weak": 2.0, "strong": 0.4, "ms": 40, "handheldMs": 30}, "minGapMs": 200}
	var d: Dictionary = SimHaptics.numbers("launch_open")
	ok(float(d["weak"]) == 1.0 and absf(float(d["strong"]) - 0.4) < 1e-9 and d["ms"] == 40 and d["handheldMs"] == 30 and SimHaptics.min_gap_ms() == 200, "data: the file's numbers are used, a motor over 1 is clamped to 1")
	ok(float(SimHaptics.numbers("form_prompt")["weak"]) == 0.3, "data: a kind the file does not name keeps its default")
	if saved == null:
		SimInputData.timing.erase("haptics")
	else:
		SimInputData.timing["haptics"] = saved


func _plan() -> void:
	var pad: Dictionary = {"kind": "pad", "id": 7}
	var p: Dictionary = SimHaptics.plan("launch_open", pad, true, -10000, 1000)
	ok(p.get("via", "") == "pad" and p["id"] == 7 and absf(float(p["weak"]) - 0.7) < 1e-9 and float(p["strong"]) == 0.0 and absf(float(p["seconds"]) - 0.025) < 1e-9, "plan: a pad gets a 25 ms tick on its own device id (7), in seconds for Input.start_joy_vibration")
	var t: Dictionary = SimHaptics.plan("launch_open", {"kind": "touch", "id": -1}, true, -10000, 1000)
	ok(t.get("via", "") == "handheld" and t["ms"] == 25, "plan: a phone gets a 25 ms vibration for Input.vibrate_handheld")
	ok(SimHaptics.plan("launch_open", {"kind": "kb", "id": -1}, true, -10000, 1000).is_empty(), "plan: a keyboard has nothing to vibrate")
	ok(SimHaptics.plan("launch_open", {"kind": "none", "id": -1}, true, -10000, 1000).is_empty(), "plan: a slot nobody holds gets nothing")
	ok(SimHaptics.plan("launch_open", {}, true, -10000, 1000).is_empty(), "plan: no target gets nothing")
	ok(SimHaptics.plan("nonsense", pad, true, -10000, 1000).is_empty(), "plan: an unknown kind gets nothing")
	ok(SimHaptics.plan("launch_open", pad, false, -10000, 1000).is_empty(), "plan: the player's haptics option off gets nothing")
	# The gap: 79 ms is too soon, 80 is not; a clock that went backwards plays.
	ok(SimHaptics.plan("launch_open", pad, true, 1000, 1079).is_empty() and not SimHaptics.plan("launch_open", pad, true, 1000, 1080).is_empty(), "plan: a second pulse inside 80 ms is dropped, at 80 it plays")
	ok(not SimHaptics.plan("launch_open", pad, true, 5000, 100).is_empty(), "plan: a clock that restarted plays rather than muting a slot for ever")
	ok(SimHaptics.allow(-10000, 0) and not SimHaptics.allow(0, 10), "allow: the first pulse plays, one 10 ms after does not")
	# A pulse of no length or no strength is nothing.
	var saved = SimInputData.timing.get("haptics", null)
	SimInputData.timing["haptics"] = {"launch_open": {"weak": 0.0, "strong": 0.0, "ms": 25, "handheldMs": 0}}
	ok(SimHaptics.plan("launch_open", pad, true, -10000, 1000).is_empty() and SimHaptics.plan("launch_open", {"kind": "touch", "id": -1}, true, -10000, 1000).is_empty(), "plan: no strength on a pad, or no length on a phone, is nothing")
	SimInputData.timing["haptics"] = {"launch_open": {"weak": 0.5, "strong": 0.0, "ms": 0, "handheldMs": 10}}
	ok(SimHaptics.plan("launch_open", pad, true, -10000, 1000).is_empty() and SimHaptics.plan("launch_open", {"kind": "touch", "id": -1}, true, -10000, 1000).get("ms", 0) == 10, "plan: a pad pulse of 0 ms is nothing; the phone's own length is its own")
	if saved == null:
		SimInputData.timing.erase("haptics")
	else:
		SimInputData.timing["haptics"] = saved
	# Pure: the same ask, the same plan.
	ok(SimHaptics.plan("launch_open", pad, true, -10000, 1000) == SimHaptics.plan("launch_open", pad, true, -10000, 1000), "plan: the same request gives the same plan")


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
	# Reading it never moves an intent.
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
