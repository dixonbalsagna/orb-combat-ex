extends SceneTree
## The third stray beam: a stick throw its release never fired doesn't aim the next beam (docs/director/pending/stray-beams/, A1; the stand-in's
## read of beam_aim.gd and stick.gd). The beam's own move and the stick's aim on, as Orb's build plays them:
##   godot --headless --path . --script res://sim/director/tools/aim_throw_check.gd
## A player holds RB with the stick straight up (sector 8, 90 degrees off the line to his rival) without the energy for a stage, and lets
## go: refused ("ki"), no beam. Then RT + B, a signature, which is always aimed at him.
## - the negative control (the throw read as before): the signature fires wide, straight up (the bug)
## - fixed: the signature fires at him
## - with no refused release first: the signature fires at him either way
## - a stick beam aimed up that does fire still goes up, wide (the throw is its own)
## Ends on the verdict line.

var failed: int = 0
var _cues: Array = []


func _init() -> void:
	DirStick.setForce(1)
	DirBeamPlay.setFrontForce(1)
	DirBeamMove.setForce(1)
	DirBeamAim.setForce(1)
	DirBeamAim.blindBind = true
	var bugOld: Dictionary = _run(true, false)
	DirBeamAim.blindBind = false
	var bugNew: Dictionary = _run(true, false)
	var clean: Dictionary = _run(false, false)
	var own: Dictionary = _run(false, true)
	for r in [bugOld, bugNew, clean, own]:
		print("      %s: refused %d, beams fired %d, fired wide %d" % [r.name, r.refused, r.fired, r.wide])
	_expect(bugOld.refused == 1 and bugOld.fired == 1 and bugOld.wide == 1, "negative control (the throw read as before): after a refused release aimed up, the signature fires wide")
	_expect(bugNew.refused == 1 and bugNew.fired == 1 and bugNew.wide == 0, "fixed: after a refused release aimed up, the signature fires at him")
	_expect(clean.fired == 1 and clean.wide == 0, "no refused release first: the signature fires at him")
	_expect(own.fired == 1 and own.wide == 1, "a stick beam aimed up that fires still goes where it was aimed (wide)")
	DirBeamAim.setForce(-1)
	DirBeamMove.setForce(-1)
	DirBeamPlay.setFrontForce(-1)
	DirStick.setForce(-1)
	print("AIM THROW: %d check(s) failed" % failed)
	quit(1 if failed > 0 else 0)


func _expect(ok: bool, what: String) -> void:
	print(("ok    " if ok else "FAIL  ") + what)
	if not ok:
		failed += 1


func _step(S: SimState, a: SimIntent = null) -> void:
	SimCore.step(S, [a if a != null else SimIntent.new(), SimIntent.new()])
	for e in S.out.fx:
		if e.type == "cue":
			_cues.append([S.tick, String(e.kind), String(e.text), String(e.source), int(e.actor)])
	S.out.fx.clear()
	S.out.feed.clear()


func _count(kind: String, src: String = "", actor: int = 0) -> int:
	var n: int = 0
	for c in _cues:
		if c[1] == kind and (src == "" or c[3] == src) and c[4] == actor:
			n += 1
	return n


func _rb(start: bool, release: bool, held: bool) -> SimIntent:
	var i := SimIntent.new()
	i.rsStart = start
	i.rsRelease = release
	i.rsHeld = held
	i.rsDir = SimStrikeRead.RIGHT
	i.rsAim = 8   # straight up
	i.rsMask = DirStick.RB
	i.stanceMask = DirStick.RB
	return i


## refused: a stick hold aimed up let go without the energy for a stage first. ownFire: instead, a stick beam aimed up that fires (and
## no signature after).
func _run(refused: bool, ownFire: bool) -> Dictionary:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 11, {"p1": false, "p2": false}, {"intro": false})
	for f in S.fighters:
		f.ai = null
		f.act.v2 = true
		f.hp = 100000.0
		f.ki = 100.0
	var A = S.fighters[0]
	var D = S.fighters[1]
	D.x = SimWrap.wrap(A.x + 1200.0)
	D.y = A.y
	for _k in range(40):
		_step(S)
	_cues.clear()
	if refused or ownFire:
		if refused:
			A.ki = 5.0   # not enough for stage 1 (12): the release is refused, "ki"
		_step(S, _rb(true, false, true))
		for _k in range(14):
			_step(S, _rb(false, false, true))
		_step(S, _rb(false, true, false))
		for _k in range(20):
			_step(S)
		A.ki = 100.0
	if not ownFire:
		for _k in range(70):   # (the stick beam's own move and the signature both clear by now)
			_step(S)
		var sig := SimIntent.new()
		sig.sig = true
		sig.power = true
		sig.stanceMask = 4   # RT held: B is the signature
		sig.powerPress = true   # RT pressed on this tick: with bNoBeamKeepRt, RT + B is the signature inside RT's window after its press (stray-beams)
		_step(S, sig)
	for _k in range(200):
		_step(S)
		if _count("beam_fire") > 0:
			for _j in range(3):
				_step(S)
			break
	var out := {"name": ("%s, %s" % ["after a refused release" if refused else ("a stick beam that fires" if ownFire else "no refused release"), "blind" if DirBeamAim.blindBind else "fixed"]), "refused": _count("stick_refused", "ki"), "fired": _count("beam_fire"), "wide": _count("beam_wide")}
	SimCore.dispose(S)
	return out
