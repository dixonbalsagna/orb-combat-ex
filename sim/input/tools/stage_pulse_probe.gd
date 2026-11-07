extends SceneTree
## The real stick_stage cues of a held beam charge, through SimHaptics.event_requests (docs/controls/stage-pulses.md), on Encounter's beam-move stack (DirBeamMove): a base fighter (tier 1, no power:
## two stages) is told two pulses, the tick then the thud; a top fighter (tier 4, full power: six stages) six, the tick, four climbing knocks and the thud; a fighter who can't pay for the top is
## told the knock. Ends on the verdict line.
##   godot --headless --path . --script res://sim/input/tools/stage_pulse_probe.gd
## Exit 0 if every check passes.

var failed: int = 0
var _got: Array = []


func _expect(ok: bool, what: String) -> void:
	print(("ok    " if ok else "FAIL  ") + what)
	if not ok:
		failed += 1


func _init() -> void:
	SimInputData.load_and_apply()
	SimInputData.clear_overrides()
	var sw: Dictionary = SimInputData.timing.get("switches", {})
	sw["rightStick"] = true
	sw["hapticLadder"] = true
	sw["hapticStages"] = true
	SimInputData.timing["switches"] = sw
	SimInputData.invalidate()
	DirStick.setForce(1)
	DirBeamPlay.setFrontForce(1)
	DirBeamMove.setForce(1)
	_hold(1.0, 0.0, 100.0, 140, 2, "base fighter")
	_hold(4.0, 100.0, 100.0, 140, 6, "top fighter")
	_hold(4.0, 100.0, 20.0, 140, 0, "top fighter with 20 energy")
	DirBeamMove.setForce(-1)
	DirBeamPlay.setFrontForce(-1)
	DirStick.setForce(-1)
	print("STAGE PULSE PROBE: %d check(s) failed" % failed)
	quit(1 if failed > 0 else 0)


func _step(S: SimState, a: SimIntent) -> void:
	SimCore.step(S, [a, SimIntent.new()])
	for e in S.out.fx:
		for r in SimHaptics.event_requests(e):
			_got.append([S.tick, String(r["kind"]), float(r["scale"]), int(r["slot"])])
	S.out.fx.clear()
	S.out.feed.clear()


func _rb(start: bool, held: bool) -> SimIntent:
	var i := SimIntent.new()
	i.rsStart = start
	i.rsHeld = held
	i.rsDir = SimStrikeRead.RIGHT
	i.rsMask = DirStick.RB
	i.stanceMask = DirStick.RB
	return i


func _hold(tier: float, power: float, ki: float, ticks: int, want: int, tag: String) -> void:
	SimHaptics.reset_stage_state()
	_got.clear()
	var S := SimCore.createSim()
	SimCore.newMatch(S, 11, {"p1": false, "p2": false}, {"intro": false})
	for f in S.fighters:
		f.ai = null
		f.act.v2 = true
		f.hp = 100000.0
		f.ki = 100.0
	S.fighters[0].tier = tier
	S.fighters[0].power = power
	S.fighters[0].ki = ki
	S.fighters[1].x = SimWrap.wrap(S.fighters[0].x + 1200.0)
	S.fighters[1].y = S.fighters[0].y
	for _k in range(30):
		_step(S, SimIntent.new())
	_got.clear()
	_step(S, _rb(true, true))
	for _k in range(ticks - 1):
		_step(S, _rb(false, true))
	var kinds: Array = []
	var ticks_: Array = []
	for g in _got:
		kinds.append(g[1])
		ticks_.append(g[0] - _got[0][0])
	if want == 2:
		_expect(kinds == ["ladder_1", "ladder_3"], "%s: two pulses, the tick then the thud: %s at %s" % [tag, str(kinds), str(ticks_)])
	elif want == 6:
		_expect(kinds == ["ladder_1", "ladder_2", "ladder_2", "ladder_2", "ladder_2", "ladder_3"], "%s: six pulses, the tick, four knocks, the thud: %s at %s" % [tag, str(kinds), str(ticks_)])
	else:
		_expect(kinds.has("stick_refused") and not kinds.has("ladder_3"), "%s: climbs, then is told the knock for a stage it can't pay, and never the thud: %s" % [tag, str(kinds)])
	SimCore.dispose(S)
