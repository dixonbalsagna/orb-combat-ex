extends SceneTree
## Headless checks for the brake-ready tick on the sim's REAL event (sim/core/brake.gd: air_brake, text "ready", once a send at the first tick
## the sent fighter could brake; docs/controls/haptics.md): a staged send is run through SimCore, the events it emits go through the same
## call the host makes (`SimHaptics.requests(name, actor, target, text, amount, firer)`), and the plan lands on the sent fighter's own pad
## and nowhere else. From the repo root:
##   godot --headless --path . --script res://sim/input/test/brake_ready_test.gd
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
	_staged()
	_devices()
	print("brake_ready_test: %d checks, %d failed" % [checks, fails])
	quit(1 if fails > 0 else 0)


## What the host does with one event: its name (a cue's kind, or the event's type) and the mapper.
func _host_requests(e) -> Array:
	var name: String = String(e.kind) if String(e.type) == "cue" else String(e.type)
	return SimHaptics.requests(name, int(e.actor), int(e.target), String(e.text), float(e.amount), -1)


## Run a send on fighter 1 (the sent body) with the brake switched on; return {ready_ticks, reqs, window, events}.
func _run(special: bool, hold: bool, sends: int) -> Dictionary:
	var M := SimCore.createSim()
	SimCore.newMatch(M, 5, {"p1": false, "p2": false}, {"brake": true})
	var A = M.fighters[0]
	var D = M.fighters[1]
	D.y = WorldTerrain.groundY(M, D.x) + 400.0
	M.out.fx.clear()
	var out := {"ready": [], "reqs": [], "starts": 0, "ends": 0, "at": -1, "events": 0}
	var held := SimIntent.new()
	held.stanceMask = SimBrake.BIT
	for n in range(sends):
		DirLaunch.doLaunch(M, A, D, {"ux": 0.6, "uy": 0.8}, 2400.0, special)
		for t in range(1, 70):
			SimCore.step(M, [null, held if hold else null])
			if n == 0 and t == 1:
				out.at = D.brk.at
			for e in M.out.fx:
				out.events += 1
				if String(e.type) == "air_brake":
					if String(e.text) == "ready":
						out.ready.append(t)
					elif String(e.text) == "start":
						out.starts += 1
					elif String(e.text) == "end":
						out.ends += 1
				out.reqs.append_array(_host_requests(e))
			M.out.fx.clear()
			M.out.feed.clear()
			if D.state != "launched" and t > 2:
				break
		if D.state == "launched":
			break
	SimCore.dispose(M)
	return out


func _staged() -> void:
	var r: Dictionary = _run(false, false, 1)
	ok(r.ready.size() == 1, "real event: a send tells ready once (%d)" % r.ready.size())
	ok(r.ready.size() == 1 and r.ready[0] == r.at and r.at >= 8 and r.at <= 20, "real event: on the tick the start window opens (tick %d, window %d)" % [r.ready[0] if r.ready.size() == 1 else -1, r.at])
	var tick_reqs: Array = []
	for q in r.reqs:
		if q["kind"] == "brake_ready":
			tick_reqs.append(q)
	ok(tick_reqs.size() == 1 and tick_reqs[0]["slot"] == 1 and float(tick_reqs[0]["scale"]) == 1.0, "mapper: exactly one brake_ready request, for the sent fighter (slot 1), at full scale")
	var other_kinds: int = 0
	for q in r.reqs:
		if q["kind"] != "brake_ready":
			other_kinds += 1
	ok(other_kinds == 0, "mapper: nothing else in a staged send's events rumbles (%d other requests)" % other_kinds)
	# holding the brake: ready is still told once, then start; the end and the start rumble nothing of their own
	var h: Dictionary = _run(false, true, 1)
	var ht: int = 0
	for q in h.reqs:
		ht += 1 if q["kind"] == "brake_ready" else 0
	ok(h.ready.size() == 1 and h.starts == 1 and h.ends >= 1 and ht == 1 and h.reqs.size() == 1, "real event: a brake held through the window tells ready once, then starts and ends; only the ready rumbles (%d requests)" % h.reqs.size())
	ok(h.ready.size() == 1 and h.ready[0] == h.at, "real event: and it is still the window's tick")
	# a set piece's send never brakes and tells nothing
	var s: Dictionary = _run(true, false, 1)
	ok(s.ready.is_empty() and s.reqs.is_empty(), "real event: a set piece's send tells no ready and rumbles nothing")
	# the brake off: no state, no event, no rumble
	var M := SimCore.createSim()
	SimCore.newMatch(M, 5, {"p1": false, "p2": false})
	var D = M.fighters[1]
	D.y = WorldTerrain.groundY(M, D.x) + 400.0
	M.out.fx.clear()
	DirLaunch.doLaunch(M, M.fighters[0], D, {"ux": 0.6, "uy": 0.8}, 2400.0, false)
	var any: int = 0
	for t in range(1, 40):
		SimCore.step(M, [null, null])
		for e in M.out.fx:
			any += _host_requests(e).size() if String(e.type) == "air_brake" else 0
		M.out.fx.clear()
		M.out.feed.clear()
	SimCore.dispose(M)
	ok(any == 0, "real event: with the brake off nothing rumbles")
	# the mapper keeps the brake's start and end silent (a real start/end pair is in the held run above), and the actor is required
	ok(SimHaptics.requests("air_brake", 1, -1, "start", 800.0).is_empty() and SimHaptics.requests("air_brake", 1, -1, "end", 200.0).is_empty() and SimHaptics.requests("air_brake", -1, -1, "ready", 0.0).is_empty(), "mapper: start, end and an actor-less ready rumble nothing")


## The tick reaches the sent fighter's own device and only that.
func _devices() -> void:
	var req: Dictionary = SimHaptics.requests("air_brake", 1, -1, "ready", 0.0)[0]
	var hub := SimInputHub.new()
	hub.set_humans(true, false)   # player one on the keyboard, a pad joins as player two (the sent body is slot 1)
	hub.key("KeyJ", true)
	hub.key("KeyJ", false)
	hub.intent(0)
	hub.consumed()
	hub.pad_button(7, "south", true)
	hub.pad_button(7, "south", false)
	hub.take_joins()
	hub.set_humans(true, true)
	hub.intent(1)
	hub.consumed()
	var tgt: Dictionary = hub.rumble_target(int(req["slot"]))
	var p: Dictionary = SimHaptics.plan(req["kind"], tgt, true, -10000, 1000, req["scale"])
	var pad_ok: bool = tgt.get("kind", "") == "pad" and p.get("via", "") == "pad" and p["steps"].size() == 1 and float(p["steps"][0]["strong"]) == 0.0 and float(p["steps"][0]["weak"]) > 0.0
	ok(pad_ok, "device: a human on a pad gets the sharp high-motor tick on their own pad")
	ok(SimHaptics.plan(req["kind"], {"kind": "touch", "id": -1}, true, -10000, 1000, req["scale"])["steps"][0]["ms"] == 10, "device: a phone gets a 10 ms buzz")
	ok(SimHaptics.plan(req["kind"], {"kind": "kb", "id": -1}, true, -10000, 1000, req["scale"]).is_empty(), "device: a keyboard player gets nothing (Audio's carry and the fighter's own skid say it)")
	ok(SimHaptics.plan(req["kind"], {"kind": "none", "id": -1}, true, -10000, 1000, req["scale"]).is_empty(), "device: an AI-held body gets nothing")
	ok(SimHaptics.plan(req["kind"], tgt, false, -10000, 1000, req["scale"]).is_empty(), "device: the haptics option off silences it")
	# two sends 120 ms apart (a re-launch in a combo) both tick; inside the kind's 200 ms gap the second is dropped, never constant
	var first: Dictionary = SimHaptics.plan(req["kind"], tgt, true, -10000, 1000, 1.0, -1000000)
	ok(not first.is_empty() and SimHaptics.plan(req["kind"], tgt, true, 1000, 1120, 1.0, 1000).is_empty() and not SimHaptics.plan(req["kind"], tgt, true, 1000, 1200, 1.0, 1000).is_empty(), "device: the kind's own 200 ms gap holds between two sends")
