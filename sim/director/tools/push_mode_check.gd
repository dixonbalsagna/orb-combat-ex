extends SceneTree
## struggle.pushMode per player (DirBeam.pushModes; docs/director/beams-own-move-plan.md step 4; playable-build.md section 3):
##   godot --headless --path . --script res://sim/director/tools/push_mode_check.gd
## - the setup's modes: a list by slot, one word for all, none, a reserved word (the default); off, face for everyone
## - in a struggle, with the first player on face and the second on stick (setup.pushMode): his flick toward on the beat pushes, his face
##   press does nothing, and his flick starts no strike; her face press on the beat pushes. Each is told his mode as it starts.
## Ends on the verdict line.

var failed: int = 0
var _cues: Array = []


func _init() -> void:
	var bs: Dictionary = DirBeam._bs()
	bs["enabled"] = true
	var pm: Dictionary = bs.pushMode
	pm["enabled"] = true
	DirStick.setForce(1)
	DirBeamPlay.setFrontForce(1)
	_modes()
	_struggle()
	pm["enabled"] = false
	_off()
	DirBeamPlay.setFrontForce(-1)
	DirStick.setForce(-1)
	bs["enabled"] = false
	print("PUSH MODE: %d check(s) failed" % failed)
	quit(1 if failed > 0 else 0)


func _expect(ok: bool, what: String) -> void:
	print(("ok    " if ok else "FAIL  ") + what)
	if not ok:
		failed += 1


func _fresh(gap: float, modes) -> SimState:
	var S := SimCore.createSim()
	var su: Dictionary = {"intro": false}
	if modes != null:
		su["pushMode"] = modes
	SimCore.newMatch(S, 11, {"p1": false, "p2": false}, su)
	for f in S.fighters:
		f.ai = null
		f.act.v2 = true
		f.hp = 100000.0
		f.ki = 100.0
	S.fighters[1].x = SimWrap.wrap(S.fighters[0].x + gap)
	S.fighters[1].y = S.fighters[0].y
	for _k in range(20):
		_step(S)
	return S


func _step(S: SimState, a: SimIntent = null, b: SimIntent = null) -> void:
	SimCore.step(S, [a if a != null else SimIntent.new(), b if b != null else SimIntent.new()])
	for e in S.out.fx:
		if e.type == "cue":
			_cues.append([S.tick, String(e.kind), String(e.text), int(e.actor)])
	S.out.fx.clear()
	S.out.feed.clear()


func _modes() -> void:
	var S := _fresh(800.0, ["face", "stick"])
	var a: String = DirBeam.pushModeOf(S, S.fighters[0])
	var b: String = DirBeam.pushModeOf(S, S.fighters[1])
	SimCore.dispose(S)
	S = _fresh(800.0, "face")
	var c: String = DirBeam.pushModeOf(S, S.fighters[1])
	SimCore.dispose(S)
	S = _fresh(800.0, null)
	var d: String = DirBeam.pushModeOf(S, S.fighters[0])
	SimCore.dispose(S)
	S = _fresh(800.0, ["third", "stick"])
	var e: String = DirBeam.pushModeOf(S, S.fighters[0])
	SimCore.dispose(S)
	_expect(a == "face" and b == "stick" and c == "face" and d == "stick" and e == "stick", "the setup's modes: by slot (%s, %s), one for all (%s), none is the default (%s), the reserved third is the default (%s)" % [a, b, c, d, e])


## The first player's signature, answered in its window by the second's stick fire-back: a struggle. Returns S in it, or null.
func _toStruggle(S: SimState) -> bool:
	var A = S.fighters[0]
	var D = S.fighters[1]
	var sg := SimIntent.new()
	sg.sig = true
	sg.stanceMask = 4   # the charging stance: B is the signature
	_step(S, sg)
	for _k in range(240):
		if DirBeamPlay.windowOpen(S, D):
			break
		_step(S)
	if not DirBeamPlay.windowOpen(S, D):
		return false
	var w := SimIntent.new()
	w.rsStart = true
	w.rsHeld = true
	w.rsMask = DirStick.RB
	w.stanceMask = DirStick.RB
	w.rsDir = SimStrikeRead.RIGHT if SimWrap.sdx(D.x, A.x) >= 0.0 else SimStrikeRead.LEFT
	_step(S, null, w)
	for _k in range(3):
		_step(S)
	return S.game.clash != null and DirBeam._struggleBeat(S.dirS.ex) != null


func _struggle() -> void:
	_cues.clear()
	var S := _fresh(2400.0, ["face", "stick"])
	var A = S.fighters[0]
	var D = S.fighters[1]
	var inIt: bool = _toStruggle(S)
	_expect(inIt, "a signature answered by the stick's fire-back: a struggle")
	if not inIt:
		SimCore.dispose(S)
		return
	var toward: int = SimStrikeRead.RIGHT if SimWrap.sdx(D.x, A.x) >= 0.0 else SimStrikeRead.LEFT
	var plan: Array = ["dStick", "dFace", "aFace", "dStick"]
	var step_: int = 0
	var surges: Dictionary = {"dStick": 0, "dFace": 0, "aFace": 0}
	var strays: Dictionary = {"dStick": 0, "dFace": 0, "aFace": 0}
	var stickStarts: int = 0
	var pulseSeen: bool = false
	for _k in range(400):
		if S.game.clash == null or step_ >= plan.size():
			break
		var a: SimIntent = null
		var b: SimIntent = null
		var what: String = ""
		if pulseSeen:
			what = String(plan[step_])
			step_ += 1
			if what == "dStick":
				b = SimIntent.new()
				b.rsStart = true
				b.rsHeld = true
				b.rsDir = toward
			elif what == "dFace":
				b = SimIntent.new()
				b.light = true
				b.lightHeld = true   # (an auto-mode slot's push is read from the held level, as the reader has it)
			else:
				a = SimIntent.new()
				a.light = true
				a.lightHeld = true
		var n0: int = _cues.size()
		_step(S, a, b)
		pulseSeen = false
		for c in _cues.slice(n0):
			if c[1] == "beam_pulse":
				pulseSeen = true
			if what != "" and c[1] == "beam_surge" and c[3] == (1 if what.begins_with("d") else 0):
				surges[what] += 1
			if what != "" and c[1] == "beam_stray" and c[3] == (1 if what.begins_with("d") else 0):
				strays[what] += 1
			if c[1] == "stick_start" and c[3] == 1:
				stickStarts += 1
		if what == "dStick":
			var hb := SimIntent.new()   # back under the release line before the next
			_step(S, a, hb)
	var told: Array = []
	for c in _cues:
		if c[1] == "push_mode":
			told.append([c[3], c[2]])
	_expect(surges.dStick >= 2, "on stick, his flick toward on the beat pushes (%d surges)" % surges.dStick)
	_expect(surges.dFace == 0 and strays.dFace == 0, "on stick, his face press does nothing: no surge, no stray")
	_expect(surges.aFace == 1, "on face, her X on the beat pushes (%d)" % surges.aFace)
	_expect(stickStarts == 0, "in the struggle his flick starts no strike and no beam")
	_expect(told.has([0, "face"]) and told.has([1, "stick"]), "each is told his mode as it starts: %s" % str(told))
	SimCore.dispose(S)


func _off() -> void:
	var S := _fresh(800.0, ["stick", "stick"])
	var a: String = DirBeam.pushModeOf(S, S.fighters[0])
	_expect(a == "face", "off, face for everyone, whatever the setup says (%s)" % a)
	SimCore.dispose(S)
