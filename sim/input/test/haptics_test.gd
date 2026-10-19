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
	_scale()
	_signatures()
	_requests()
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
	var want: Array = ["launch_open", "form_prompt", "brake_ready", "charge_full", "clinch_pulse", "struggle_push", "struggle_pushed", "struggle_lose"]
	var has_all: bool = ks.size() == want.size()
	for w in want:
		has_all = has_all and ks.has(w)
	ok(has_all, "data: the eight kinds (the six asked for, the struggle's push and being pushed, and the loser's end)")
	ok(not ks.has("struggle_pulse") and not ks.has("struggle_surge"), "data: the beat-aligned struggle kinds are retired (Orb: not on the beat)")
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
	# The struggle's push and being pushed: lengthened to the hardware floor, never dropped.
	var sp: Array = SimHaptics.steps("struggle_push", "pad")
	ok(sp.size() == 1 and sp[0]["ms"] == 25 and absf(float(sp[0]["weak"]) - 0.5) < 1e-9 and absf(float(sp[0]["strong"]) - 0.1) < 1e-9, "steps: your own surge is a bright tick on the high motor (25 ms)")
	var pd: Array = SimHaptics.steps("struggle_pushed", "pad")
	ok(pd.size() == 1 and pd[0]["ms"] == 40 and float(pd[0]["weak"]) == 0.0 and absf(float(pd[0]["strong"]) - 0.6) < 1e-9, "steps: a surge made against you is a heavy low push (40 ms, low motor only)")
	ok(SimHaptics.steps("struggle_lose", "pad")[0]["ms"] == 60, "steps: the loser's end 60 ms")
	ok(SimHaptics.steps("struggle_push", "handheld")[0]["ms"] == 20 and SimHaptics.steps("struggle_pushed", "handheld")[0]["ms"] == 30 and SimHaptics.steps("struggle_lose", "handheld")[0]["ms"] == 40, "steps: on a phone 20, 30 and 40 ms")
	var cp: Array = SimHaptics.steps("clinch_pulse", "pad")
	ok(cp.size() == 2 and float(cp[0]["weak"]) == 0.0 and float(cp[0]["strong"]) > 0.0 and cp[1]["at"] == 50 and float(cp[1]["strong"]) == 0.0, "steps: the clinch is a low creak then a faint scrape")
	var br: Array = SimHaptics.steps("brake_ready", "pad")
	ok(br.size() == 1 and float(br[0]["strong"]) == 0.0 and float(br[0]["weak"]) >= 0.5 and br[0]["ms"] == 20, "steps: the brake is one sharp tick on the high motor alone")
	var cf: Array = SimHaptics.steps("charge_full", "pad")
	ok(cf.size() == 1 and float(cf[0]["weak"]) > 0.0 and float(cf[0]["strong"]) > 0.0 and cf[0]["ms"] == 40, "steps: a full charge is one firm snap on both motors")
	var fp: Array = SimHaptics.steps("form_prompt", "pad")
	ok(fp.size() == 2 and float(fp[1]["strong"]) > float(fp[0]["strong"]) and fp[1]["at"] == 70, "steps: the ready form is two taps, the second firmer")
	ok(SimHaptics.steps("nonsense", "pad").is_empty() and SimHaptics.steps("launch_open", "keyboard").is_empty(), "steps: an unknown kind or device has none")
	# Audio asked for 8 ms on each beat: a request under the floor is lengthened to it (a pad motor needs 20 to 40 ms to spin up) ...
	_with({"struggle_push": {"pad": [{"at": 0, "weak": 0.0, "strong": 0.4, "ms": 8}], "handheld": [{"at": 0, "ms": 4}]}}, func():
		ok(SimHaptics.steps("struggle_push", "pad")[0]["ms"] == 20 and SimHaptics.steps("struggle_push", "handheld")[0]["ms"] == 10, "floor: 8 ms on a pad is raised to 20, and 4 ms on a phone to 10"))
	# ... the floors are data ...
	_with({"padMinMs": 30, "handheldMinMs": 12, "struggle_push": {"pad": [{"at": 0, "weak": 0.0, "strong": 0.4, "ms": 8}], "handheld": [{"at": 0, "ms": 4}]}}, func():
		ok(SimHaptics.steps("struggle_push", "pad")[0]["ms"] == 30 and SimHaptics.steps("struggle_push", "handheld")[0]["ms"] == 12, "floor: the floors are data (30 and 12 here)"))
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
	# The clinch's pulse comes every 20 ticks (333 ms): well outside its own gap.
	ok(not SimHaptics.plan("clinch_pulse", pad, true, 0, 333, 1.0, 0).is_empty(), "plan: the clinch's pulse, 333 ms apart, always plays")
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


## The scale: the struggle's share and the clinch's grip.
func _scale() -> void:
	var f0: float = SimHaptics.scale_factor(0.0)
	ok(absf(f0 - 0.35) < 1e-9 and SimHaptics.scale_factor(1.0) == 1.0 and absf(SimHaptics.scale_factor(0.5) - 0.675) < 1e-9, "scale: 0 gives scaleMin (0.35), 1 gives the data as written, the middle between")
	ok(SimHaptics.scale_factor(-3.0) == f0 and SimHaptics.scale_factor(9.0) == 1.0, "scale: clamped to 0 to 1")
	ok(SimHaptics.steps("struggle_pushed", "pad", 1.0) == SimHaptics.steps("struggle_pushed", "pad"), "scale: 1 is the unscaled steps")
	var lo: Array = SimHaptics.steps("struggle_pushed", "pad", 0.0)
	var hi: Array = SimHaptics.steps("struggle_pushed", "pad", 1.0)
	var mid: Array = SimHaptics.steps("struggle_pushed", "pad", 0.5)
	ok(float(lo[0]["strong"]) < float(mid[0]["strong"]) and float(mid[0]["strong"]) < float(hi[0]["strong"]), "scale: a bigger share is a stronger push (low < middle < full)")
	ok(absf(float(lo[0]["strong"]) - 0.6 * 0.35) < 1e-9 and lo[0]["ms"] == hi[0]["ms"] and float(lo[0]["weak"]) == 0.0, "scale: only strength changes on a pad (length kept) and a motor that was off stays off")
	# a scaled motor is never under what can be felt
	_with({"struggle_pushed": {"pad": [{"at": 0, "weak": 0.0, "strong": 0.2, "ms": 40}]}}, func():
		ok(absf(float(SimHaptics.steps("struggle_pushed", "pad", 0.0)[0]["strong"]) - 0.15) < 1e-9, "scale: raised to padMinStrength (0.15) rather than vanishing"))
	_with({"padMinStrength": 0.3, "struggle_pushed": {"pad": [{"at": 0, "weak": 0.0, "strong": 0.5, "ms": 40}]}}, func():
		ok(absf(float(SimHaptics.steps("struggle_pushed", "pad", 0.0)[0]["strong"]) - 0.3) < 1e-9, "scale: padMinStrength is data"))
	# a phone has no strength: a smaller scale is a shorter buzz, never under the floor
	var hl: Array = SimHaptics.steps("struggle_pushed", "handheld", 0.0)
	var hh: Array = SimHaptics.steps("struggle_pushed", "handheld", 1.0)
	ok(hh[0]["ms"] == 30 and hl[0]["ms"] == 11, "scale: on a phone 30 ms at full and 11 ms at the least (30 x 0.35)")
	_with({"scaleMin": 0.0, "struggle_pushed": {"handheld": [{"at": 0, "ms": 30}]}}, func():
		ok(SimHaptics.steps("struggle_pushed", "handheld", 0.0)[0]["ms"] == 10, "scale: a phone's floor holds even at a scale factor of 0"))
	var pl: Dictionary = SimHaptics.plan("struggle_pushed", {"kind": "pad", "id": 3}, true, -10000, 1000, 0.0)
	ok(float(pl["steps"][0]["seconds"]) > 0.0 and float(pl["steps"][0]["strong"]) > 0.0, "scale: a scaled plan is still a real pulse (seconds above 0, motor above 0)")
	var ph: Dictionary = SimHaptics.plan("struggle_pushed", {"kind": "touch", "id": -1}, true, -10000, 1000, 0.0)
	ok(ph.get("via", "") == "handheld" and ph["steps"][0]["ms"] >= 10, "scale: touch plays a scaled pulse")
	ok(SimHaptics.plan("struggle_pushed", {"kind": "kb", "id": -1}, true, -10000, 1000, 1.0).is_empty() and SimHaptics.plan("struggle_pushed", {"kind": "pad", "id": 3}, false, -10000, 1000, 1.0).is_empty(), "scale: a keyboard and the haptics option off still get nothing")


## Distinct, short, never constant.
func _signatures() -> void:
	var pad: Dictionary = {"kind": "pad", "id": 7}
	var seen: Dictionary = {}
	var distinct: bool = true
	var short: bool = true
	var duty_ok: bool = true
	var floor_ok: bool = true
	for k in SimHaptics.kinds():
		var ps: Array = SimHaptics.steps(k, "pad")
		var sig: String = ""
		var total: int = 0
		var span: int = 0
		for s in ps:
			sig += "%d/%.2f/%.2f/%d;" % [int(s["at"]), float(s["weak"]), float(s["strong"]), int(s["ms"])]
			total += int(s["ms"])
			span = maxi(span, int(s["at"]) + int(s["ms"]))
			floor_ok = floor_ok and int(s["ms"]) >= 20
		distinct = distinct and not seen.has(sig)
		seen[sig] = k
		short = short and span <= 160
		# the most one slot can be shaken: motor-on time over the kind's own least gap
		duty_ok = duty_ok and float(total) / float(SimHaptics.kind_gap_ms(k)) <= 0.5
	ok(distinct, "signature: no two kinds have the same pad steps")
	ok(short, "signature: every kind is over within 160 ms")
	ok(duty_ok, "signature: the motor is on at most half the time even if a kind is asked for as fast as its gap allows")
	ok(floor_ok, "signature: no pad step is under the 20 ms floor")
	# the brake's tick is the one kind that is the high motor alone
	var high_only: Array = []
	for k in SimHaptics.kinds():
		var all_high: bool = true
		for s in SimHaptics.steps(k, "pad"):
			all_high = all_high and float(s["strong"]) == 0.0
		if all_high:
			high_only.append(k)
	ok(high_only == ["brake_ready"], "signature: only the brake's tick is the high motor alone")
	# a phone has only lengths, so each kind's pattern of lengths differs
	var hseen: Dictionary = {}
	var hdistinct: bool = true
	var hshort: bool = true
	for k in SimHaptics.kinds():
		var sig2: String = ""
		var hspan: int = 0
		for s in SimHaptics.steps(k, "handheld"):
			sig2 += "%d/%d;" % [int(s["at"]), int(s["ms"])]
			hspan = maxi(hspan, int(s["at"]) + int(s["ms"]))
		hdistinct = hdistinct and not hseen.has(sig2)
		hseen[sig2] = k
		hshort = hshort and hspan <= 160
	ok(hdistinct and hshort, "signature: no two kinds buzz a phone alike, and each is over within 160 ms")
	# a mash: a button pressed every 40 ms for two seconds is asked for 50 times and plays far fewer, the motor off more than on
	var last: int = -100000
	var last_kind: int = -100000
	var played: int = 0
	var on_ms: int = 0
	for i in range(50):
		var now: int = i * 40
		var pl: Dictionary = SimHaptics.plan("struggle_push", pad, true, last, now, 1.0, last_kind)
		if not pl.is_empty():
			played += 1
			last = now
			last_kind = now
			for s in pl["steps"]:
				on_ms += int(round(float(s["seconds"]) * 1000.0))
	ok(played >= 15 and played <= 20 and on_ms * 2 <= 2000, "signature: a surge mashed every 40 ms for two seconds plays %d times, motor on %d ms of 2000 (never constant)" % [played, on_ms])
	# the kind's gap is against its own last, not the slot's: a launch right after a push is not swallowed
	ok(not SimHaptics.plan("launch_open", pad, true, 1000, 1100, 1.0, -100000).is_empty(), "signature: a different kind 100 ms after a push plays (only the slot-wide 80 ms applies)")
	ok(SimHaptics.plan("launch_open", pad, true, 1000, 1100, 1.0, 1000).is_empty() and SimHaptics.plan("clinch_pulse", pad, true, 0, 200, 1.0, 0).is_empty() and not SimHaptics.plan("clinch_pulse", pad, true, 0, 250, 1.0, 0).is_empty(), "signature: a kind's own gap holds (launch 300, clinch 250)")
	ok(SimHaptics.kind_gap_ms("nonsense") == 0 and SimHaptics.kind_gap_ms("struggle_push") == 100, "signature: kind_gap_ms")


## The mapper: who feels what for each cue.
func _requests() -> void:
	var r: Array = SimHaptics.requests("launcher_open", 1, 0, "guard_break", 0.0)
	ok(r.size() == 1 and r[0]["slot"] == 1 and r[0]["kind"] == "launch_open", "requests: the launcher alone (the cue's actor) feels the opening, not the staggered fighter")
	r = SimHaptics.requests("transform_ready", 0, -1, "", 0.0)
	ok(r.size() == 1 and r[0]["slot"] == 0 and r[0]["kind"] == "form_prompt", "requests: the ready form is the actor's")
	r = SimHaptics.requests("charge_full", 1, -1, "", 0.0)
	ok(r.size() == 1 and r[0]["slot"] == 1 and r[0]["kind"] == "charge_full", "requests: a full charge is the charger's")
	r = SimHaptics.requests("air_brake", 0, -1, "ready", 0.0)
	ok(r.size() == 1 and r[0]["kind"] == "brake_ready" and r[0]["slot"] == 0, "requests: the brake becoming available is the actor's tick")
	ok(SimHaptics.requests("air_brake", 0, -1, "start", 400.0).is_empty() and SimHaptics.requests("air_brake", 0, -1, "end", 0.0).is_empty(), "requests: the brake's start and end rumble nothing")
	r = SimHaptics.requests("grapple_pulse", 0, 1, "", 3.0)
	ok(r.size() == 2 and r[0]["kind"] == "clinch_pulse" and r[1]["kind"] == "clinch_pulse" and r[0]["slot"] == 0 and r[1]["slot"] == 1 and absf(float(r[0]["scale"]) - 0.6) < 1e-9, "requests: both in the clinch feel its pulse, scaled by the grip (3 of 5 steps = 0.6)")
	ok(absf(float(SimHaptics.requests("grapple_pulse", 0, 1, "", -5.0)[0]["scale"]) - 1.0) < 1e-9 and float(SimHaptics.requests("grapple_pulse", 0, 1, "", 0.0)[0]["scale"]) == 0.0 and float(SimHaptics.requests("grapple_pulse", 0, 1, "", 99.0)[0]["scale"]) == 1.0, "requests: a negative grip counts by size, and the scale is clamped")
	# the struggle: firer 0. A surge by the firer with the point at 0.7 (he is ahead): 0.7 for both.
	r = SimHaptics.requests("beam_surge", 0, 1, "surge", 0.7, 0)
	ok(r.size() == 2 and r[0]["slot"] == 0 and r[0]["kind"] == "struggle_push" and r[1]["slot"] == 1 and r[1]["kind"] == "struggle_pushed" and absf(float(r[0]["scale"]) - 0.7) < 1e-9 and absf(float(r[1]["scale"]) - 0.7) < 1e-9, "requests: the pusher feels his own tick and the other the push, both at the pusher's share (0.7)")
	r = SimHaptics.requests("beam_surge", 1, 0, "surge", 0.7, 0)
	ok(absf(float(r[0]["scale"]) - 0.3) < 1e-9 and r[0]["slot"] == 1 and r[1]["slot"] == 0, "requests: the other's surge with the point at 0.7 is his 0.3 share: a weak push against him")
	r = SimHaptics.requests("beam_surge", 1, 0, "sharp", 0.7, 0)
	ok(absf(float(r[0]["scale"]) - 0.55) < 1e-9, "requests: a sharp surge adds sharpBoost (0.3 + 0.25)")
	r = SimHaptics.requests("beam_surge", 0, 1, "sharp", 0.95, 0)
	ok(float(r[0]["scale"]) == 1.0, "requests: the scale never passes 1")
	r = SimHaptics.requests("beam_surge", 1, 0, "surge", 0.6, -1)
	ok(r[0]["kind"] == "struggle_push" and absf(float(r[0]["scale"]) - 0.6) < 1e-9, "requests: with no firer known the surge's actor is taken as the firer")
	ok(SimHaptics.requests("beam_stray", 0, 1, "", 0.4, 0).is_empty() and SimHaptics.requests("beam_pulse", 0, 1, "", 0.5, 0).is_empty() and SimHaptics.requests("beam_struggle", 0, 1, "start", 0.5, 0).is_empty(), "requests: a stray, the beat and the start rumble nothing (nothing on the beat)")
	r = SimHaptics.requests("beam_end", 0, 1, "overwhelmed", 1.0, 0)
	ok(r.size() == 1 and r[0]["slot"] == 1 and r[0]["kind"] == "struggle_lose", "requests: the overwhelmed fighter (the target) feels the end")
	ok(SimHaptics.requests("beam_end", 0, 1, "detonate", 0.5, 0).is_empty() and SimHaptics.requests("beam_end", 0, 1, "time", 0.5, 0).is_empty(), "requests: a detonation or a time loss rumbles nothing")
	ok(SimHaptics.requests("nonsense", 0, 1, "", 0.0).is_empty() and SimHaptics.requests("launcher_open", -1, -1, "", 0.0).is_empty(), "requests: an unknown cue or no actor rumbles nothing")
	# every request names a kind this knows and a scale in 0 to 1
	var sane: bool = true
	for nm in ["launcher_open", "transform_ready", "charge_full", "grapple_pulse", "beam_surge", "beam_end"]:
		for q in SimHaptics.requests(nm, 0, 1, "overwhelmed", 0.5, 0):
			sane = sane and SimHaptics.kinds().has(q["kind"]) and float(q["scale"]) >= 0.0 and float(q["scale"]) <= 1.0 and int(q["slot"]) >= 0
	ok(sane, "requests: every request names a known kind and a scale from 0 to 1")
	# a mapped request plays on its own device, scaled
	var rq: Dictionary = SimHaptics.requests("beam_surge", 0, 1, "surge", 0.8, 0)[0]
	var pp: Dictionary = SimHaptics.plan(rq["kind"], {"kind": "pad", "id": 4}, true, -10000, 1000, rq["scale"])
	ok(pp.get("via", "") == "pad" and pp["id"] == 4 and absf(float(pp["steps"][0]["weak"]) - 0.5 * SimHaptics.scale_factor(0.8)) < 1e-9, "requests: a mapped surge plays on the pad scaled by its share")
