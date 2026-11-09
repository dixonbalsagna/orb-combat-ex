extends SceneTree
## Headless checks for "B never fires a beam" (docs/controls/b-no-beam.md; timing.json switches.bNoBeam, off; Orb's rule of 2026-11-01: beams come only from the right stick). The real hub into the sim, a standing rival:
## with the switch on, B with no layer held, with LB, RB, LT (past the flight strike's take-back window, the flight strikes on) or RT, tapped or held, starts no beam; the right stick's own beam (RB + stick, released) still does.
## Off (the control), RT + B and LT + B (flight strikes on, past the window) are the signature beam, as they were. From the repo root:
##   godot --headless --path . --script res://sim/input/test/b_no_beam_test.gd
## Exit 0 if every check passes.

var fails: int = 0
var checks: int = 0
var zip_fs0: bool = false


func ok(c: bool, what: String) -> void:
	checks += 1
	if not c:
		fails += 1
		print("FAIL  ", what)


func _init() -> void:
	SimInputData.load_and_apply()
	SimInputData.pin_switches_off()
	zip_fs0 = bool(DirZip.fsCfg().get("enabled", false))
	DirZip.fsCfg()["enabled"] = true   # the Sunday build's flight strikes row: one key in interrupts.json, two in timing.json
	_sw(true)
	_on()
	_stick()
	_sw(true, true)
	_interim()
	_sw(false)
	_off()
	DirZip.fsCfg()["enabled"] = zip_fs0
	SimInputData.pin_switches_off()
	print("b_no_beam_test: %d checks, %d failed" % [checks, fails])
	quit(1 if fails > 0 else 0)


func _sw(on: bool, keep_rt: bool = false) -> void:
	var sw: Dictionary = SimInputData.timing.get("switches", {})
	sw["rightStick"] = true
	sw["signatureRtOnly"] = true
	sw["flightStrikeB"] = true
	sw["dodgeHeld"] = true
	sw["bNoBeam"] = on
	sw["bNoBeamKeepRt"] = keep_rt
	SimInputData.timing["switches"] = sw
	SimInputData.clear_overrides()
	SimInputData.invalidate()


## What slot 0 did after a B press: the names of its events in 120 ticks. `pre` is a list of [kind, name] held 10 ticks before B (a button or a trigger); `stick` is a right-stick hold (RB + the stick) instead of B.
func _run(pre: Array, hold_b: bool, dist: float = 212.0, stick: bool = false, lead: int = 10) -> Dictionary:
	var hub := SimInputHub.new()
	hub.set_humans(true, false)
	hub.pad_button(7, "south", true)
	hub.pad_button(7, "south", false)
	hub.take_joins()
	hub.set_humans(true, false)
	var su: Dictionary = hub.setup()
	su["intro"] = false
	var S := SimCore.createSim()
	SimCore.newMatch(S, 5, {"p1": false, "p2": false}, su)
	var a = S.fighters[0]
	var b = S.fighters[1]
	b.x = SimWrap.wrap(a.x + dist)
	b.y = a.y
	var quiet := SimIntent.new()
	for t in range(30):
		SimCore.step(S, [hub.intent(0), quiet])
		hub.consumed()
		S.out.fx.clear()
	for e in pre:
		if e[0] == "b":
			hub.pad_button(7, e[1], true)
		else:
			hub.pad_trigger(7, e[1], 1.0)
	for t in range(lead):
		SimCore.step(S, [hub.intent(0), quiet])
		hub.consumed()
		S.out.fx.clear()
	var names: Dictionary = {}
	if stick:
		hub.pad_stick_right(7, 1.0, 0.0)
	else:
		hub.pad_button(7, "east", true)
	for t in range(120):
		if stick:
			if t == 40:
				hub.pad_stick_right(7, 0.0, 0.0)
		elif t == (24 if hold_b else 3):
			hub.pad_button(7, "east", false)
		SimCore.step(S, [hub.intent(0), quiet])
		hub.consumed()
		for e in S.out.fx:
			var nm: String = String(e.kind) if String(e.type) == "cue" else String(e.type)
			if int(e.actor) == 0:
				names[nm] = true
		S.out.fx.clear()
	SimCore.dispose(S)
	return names


func _beam(n: Dictionary) -> bool:
	return n.has("beam_fire") or n.has("beam_charge") or n.has("beam_outcome")


func _on() -> void:
	var layers: Array = [["B alone", []], ["LB + B", [["b", "lb"]]], ["RB + B", [["b", "rb"]]], ["LT + B (past the take-back window)", [["t", "lt"]]], ["RT + B", [["t", "rt"]]], ["LT + LB + B", [["t", "lt"], ["b", "lb"]]]]
	for lay in layers:
		for hold_b in [false, true]:
			for dist in [80.0, 212.0, 800.0]:
				var n: Dictionary = _run(lay[1], hold_b, dist)
				ok(not _beam(n), "on: %s (%s, %d units) starts no beam: %s" % [lay[0], "held" if hold_b else "tap", int(dist), str(n.keys())])
	var alone: Dictionary = _run([], false, 212.0)
	ok(alone.has("blow") or alone.has("windup") or alone.has("rush"), "on: B alone is still a blow (the heavy), not nothing: %s" % str(alone.keys()))
	var rt: Dictionary = _run([["t", "rt"]], false, 212.0)
	ok(rt.has("blow") or rt.has("windup") or rt.has("rush") or rt.has("lunge_heavy"), "on: RT + B is the big blow, not nothing: %s" % str(rt.keys()))


## The interim (bNoBeamKeepRt, the EP's decision of 2026-11-08): until RT + right stick is built, B with RT held is still the signature, so it can always be fired. Everything else stays out: B alone, LB, RB, LT past the window, LT + LB.
func _interim() -> void:
	var layers: Array = [["B alone", []], ["LB + B", [["b", "lb"]]], ["RB + B", [["b", "rb"]]], ["LT + B (past the take-back window)", [["t", "lt"]]], ["LT + LB + B", [["t", "lt"], ["b", "lb"]]]]
	for lay in layers:
		for hold_b in [false, true]:
			for dist in [80.0, 212.0, 800.0]:
				var n: Dictionary = _run(lay[1], hold_b, dist)
				ok(not _beam(n), "interim: %s (%s, %d units) starts no beam: %s" % [lay[0], "held" if hold_b else "tap", int(dist), str(n.keys())])
	for hold_b in [false, true]:
		for dist in [80.0, 212.0, 800.0]:
			var r: Dictionary = _run([["t", "rt"]], hold_b, dist)
			ok(_beam(r), "interim: RT + B (%s, %d units) is still the signature beam: %s" % ["held" if hold_b else "tap", int(dist), str(r.keys())])
	var s: Dictionary = _run([["b", "rb"]], false, 400.0, true)
	ok(_beam(s), "interim: the right stick's own beam still fires: %s" % str(s.keys()))
	# Game Design's condition: RT + B is the signature only as a chord, B within tapHold.holdStart (12) ticks of RT's press; a B during an RT channel is not.
	var hs: int = SimInputData.ti(["tapHold", "holdStart"], 12)
	for lead in [1, 3, hs - 3]:
		for hold_b in [false, true]:
			var c: Dictionary = _run([["t", "rt"]], hold_b, 212.0, false, lead)
			ok(_beam(c), "interim: RT, then B %d ticks later (inside the %d-tick chord window, %s) is the signature: %s" % [lead, hs, "held" if hold_b else "tap", str(c.keys())])
	for lead in [hs + 3, 20, 40]:
		for hold_b in [false, true]:
			for dist in [80.0, 212.0, 800.0]:
				var ch: Dictionary = _run([["t", "rt"]], hold_b, dist, false, lead)
				ok(not _beam(ch), "interim: B %d ticks into an RT channel (past the %d-tick window, %s, %d units) fires no signature: %s" % [lead, hs, "held" if hold_b else "tap", int(dist), str(ch.keys())])


func _stick() -> void:
	var s: Dictionary = _run([["b", "rb"]], false, 400.0, true)
	ok(_beam(s), "on: the right stick's own beam (RB held, the stick pushed and released) still fires: %s" % str(s.keys()))


## Off, the control: the leaks are there. RT + B and LT + B past the window (flight strikes on) are the signature beam.
func _off() -> void:
	var rt: Dictionary = _run([["t", "rt"]], false, 212.0)
	ok(_beam(rt), "off (the control): RT + B is the signature beam: %s" % str(rt.keys()))
	var lt: Dictionary = _run([["t", "lt"]], false, 212.0)
	ok(_beam(lt), "off (the control): LT + B past the take-back window, flight strikes on, is the signature beam: %s" % str(lt.keys()))
	var alone: Dictionary = _run([], false, 212.0)
	ok(not _beam(alone), "off: B alone is not a beam (it never was): %s" % str(alone.keys()))
