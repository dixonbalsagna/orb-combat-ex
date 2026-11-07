extends SceneTree
## A scripted pad pushes in a real beam struggle (docs/controls/push-stick.md): the whole path, pad -> hub -> layout -> intent -> the director's DirBeam.clashTick, on Encounter's push-mode stack
## (beam-move, strike-stages, beam-ai, push-mode, with struggle.pushMode on and the setup's modes). The first fighter is the pad's, on `stick`; the second fires a signature and the pad answers with RB + the
## stick (the fire-back), the clash begins, and then each pulse the pad flicks toward the rival (a surge), X on a beat (nothing), a flick away (the let-go). Ends on the verdict line.
##   godot --headless --path . --script res://sim/input/tools/push_stick_probe.gd
## Exit 0 if every check passes.

var failed: int = 0
var _cues: Array = []


func _expect(ok: bool, what: String) -> void:
	print(("ok    " if ok else "FAIL  ") + what)
	if not ok:
		failed += 1


func _init() -> void:
	SimInputData.load_and_apply()
	SimInputData.clear_overrides()
	var sw: Dictionary = SimInputData.timing.get("switches", {})
	sw["rightStick"] = true
	sw["hapticRefused"] = true
	SimInputData.timing["switches"] = sw
	SimInputData.invalidate()
	var bs: Dictionary = DirBeam._bs()
	bs["enabled"] = true
	var pm: Dictionary = bs.pushMode
	pm["enabled"] = true
	DirStick.setForce(1)
	DirBeamPlay.setFrontForce(1)
	_run(["stick", "face"], true)
	_run(["face", "face"], false)
	pm["enabled"] = false
	bs["enabled"] = false
	DirBeamPlay.setFrontForce(-1)
	DirStick.setForce(-1)
	print("PUSH STICK PROBE: %d check(s) failed" % failed)
	quit(1 if failed > 0 else 0)


func _step(S: SimState, a: SimIntent, b: SimIntent) -> void:
	SimCore.step(S, [a, b if b != null else SimIntent.new()])
	for e in S.out.fx:
		if e.type == "cue":
			_cues.append([S.tick, String(e.kind), String(e.text), int(e.actor)])
	S.out.fx.clear()
	S.out.feed.clear()


func _hub() -> SimInputHub:
	var hub := SimInputHub.new()
	hub.set_humans(true, false)
	hub.pad_button(7, "south", true)
	hub.pad_button(7, "south", false)
	hub.take_joins()
	hub.set_humans(true, false)
	return hub


## One tick of the host: the struggle words for the pad's slot, the intent, the sim step, the hub's consumed, the cues the hub cares about.
func _tick(S: SimState, hub: SimInputHub, b: SimIntent = null) -> void:
	var f0 = S.fighters[0]
	hub.set_struggle(0, SimDir.inStruggle(S, f0), DirBeam.pushModeOf(S, f0) == "stick")
	var i: SimIntent = hub.intent(0)
	var n0: int = _cues.size()
	_step(S, i, b)
	for c in _cues.slice(n0):
		if c[1] == "stick_start" and c[3] == 0:
			hub.note_stick_started(0)
	hub.consumed()


func _run(modes: Array, stick_mode: bool) -> void:
	_cues.clear()
	var S := SimCore.createSim()
	SimCore.newMatch(S, 11, {"p1": false, "p2": false}, {"intro": false, "pushMode": modes})
	for f in S.fighters:
		f.ai = null
		f.act.v2 = true
		f.hp = 100000.0
		f.ki = 100.0
	S.fighters[1].x = SimWrap.wrap(S.fighters[0].x + 2400.0)
	S.fighters[1].y = S.fighters[0].y
	var hub: SimInputHub = _hub()
	for _k in range(20):
		_tick(S, hub)
	var A = S.fighters[1]   # fires
	var D = S.fighters[0]   # the pad's
	var sg := SimIntent.new()
	sg.sig = true
	sg.stanceMask = 4
	_tick(S, hub, sg)
	var guard: int = 0
	while not DirBeamPlay.windowOpen(S, D) and guard < 240:
		_tick(S, hub)
		guard += 1
	_expect(DirBeamPlay.windowOpen(S, D), "[%s] the rival's signature opens the pad's answer window" % modes[0])
	var toward_x: float = 1.0 if SimWrap.sdx(D.x, A.x) >= 0.0 else -1.0
	# The fire-back: RB and the stick toward, held a few ticks, then let go.
	hub.pad_button(7, "rb", true)
	hub.pad_stick_right(7, toward_x, 0.0)
	for _k in range(6):
		_tick(S, hub)
	hub.pad_stick_right(7, 0.0, 0.0)
	hub.pad_button(7, "rb", false)
	for _k in range(8):
		_tick(S, hub)
	_expect(S.game.clash != null and DirBeam._struggleBeat(S.dirS.ex) != null, "[%s] the pad's RB + stick fire-back is answered: a struggle" % modes[0])
	if S.game.clash == null:
		SimCore.dispose(S)
		return
	var surges: int = 0
	var strays: int = 0
	var starts: int = 0
	var refusals: int = 0
	var knocks: int = 0
	var phase: int = 0   # 0 wait for a pulse then flick toward; 1 returning; 2 face press on a pulse
	var plan: Array = ["flick", "flick", "face", "flick"]
	var step_: int = 0
	var flick_left: int = 0
	var rest_left: int = 0
	var face_left: int = 0
	for _k in range(500):
		if S.game.clash == null or step_ > plan.size():
			break
		var n0: int = _cues.size()
		_tick(S, hub)
		for c in _cues.slice(n0):
			if c[1] == "beam_pulse" and flick_left == 0 and rest_left == 0 and face_left == 0 and step_ < plan.size():
				if plan[step_] == "flick":
					hub.pad_stick_right(7, toward_x, 0.0)
					flick_left = 3
				else:
					hub.pad_button(7, "west", true)
					face_left = 2
				step_ += 1
			if c[1] == "beam_surge" and c[3] == 0:
				surges += 1
			if c[1] == "beam_stray" and c[3] == 0:
				strays += 1
			if c[1] == "stick_start" and c[3] == 0 and S.game.clash != null:
				starts += 1
		if flick_left > 0:
			flick_left -= 1
			if flick_left == 0:
				hub.pad_stick_right(7, 0.0, 0.0)
				rest_left = 6
		elif rest_left > 0:
			rest_left -= 1
		if face_left > 0:
			face_left -= 1
			if face_left == 0:
				hub.pad_button(7, "west", false)
		for r in hub.take_refusals():
			refusals += 1
		for h in hub.take_haptics():
			if str(h.get("kind", "")) == "stick_refused":
				knocks += 1
	var told: Array = []
	for c in _cues:
		if c[1] == "push_mode":
			told.append([c[3], c[2]])
	if stick_mode:
		_expect(surges >= 3, "[stick] the pad's flicks toward on the beat are surges (%d)" % surges)
		_expect(strays == 0, "[stick] and none is a stray (%d)" % strays)
		_expect(starts == 0, "[stick] a flick starts no strike or beam (%d stick_start)" % starts)
		_expect(refusals == 0 and knocks == 0, "[stick] no 'no answer' and no stick_refused knock for a push (%d refusals, %d knocks)" % [refusals, knocks])
		_expect(told.has([0, "stick"]), "[stick] told its mode as the struggle starts: %s" % str(told))
	else:
		_expect(surges >= 1, "[face] the same pad on face: its X on a beat is a surge (%d)" % surges)
		_expect(told.has([0, "face"]), "[face] told face: %s" % str(told))
	SimCore.dispose(S)
