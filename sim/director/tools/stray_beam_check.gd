extends SceneTree
## The two stray-beam fixes from Orb's 1646 play (docs/director/pending/stray-beams/; QA, docs/qa/runs/6a30b4c9/README.md; A-COMBAT-05,
## A-COMBAT-11). The beam's own move on, as Orb's build plays it:
##   godot --headless --path . --script res://sim/director/tools/stray_beam_check.gd
## Tick 5220 (ownMove.dropOnPress): a stage 1 release whose target isn't free waits (the lit hand holds); then
## - on: a Y press after the release drops it (stick_refused beam replaced) and no beam comes in the next 100 ticks; a guard press too
## - on: with nothing pressed it still fires once the target is free; a press on the release's own tick is part of it (it still waits)
## - on, at close range (Orb's case): a Y that begins a brawl after the release: no beam ends that brawl
## - off (the negative control): after a guard press, or the brawl's Y, the waiting beam fires later anyway
## Tick 6617 (bNoBeamKeepRt's window, with Controls' bNoBeam and bNoBeamKeepRt on): RT pressed, held, then B
## - B on RT's own tick, and 12 live ticks after, is still the signature; 13 after, and 26 (Orb's), is the heavy (B never beams)
## - the negative control (the window unread: the old rule, RT held and not charging): 26 after is still the signature
## - the switches off: nothing is written for RT
## Ends on the verdict line.

var failed: int = 0
var _cues: Array = []


func _init() -> void:
	DirStick.setForce(1)
	DirBeamPlay.setFrontForce(1)
	DirBeamMove.setForce(1)
	var om: Dictionary = DirBeamMove.cfg()
	var was = om.get("dropOnPress", false)
	om["dropOnPress"] = true
	var yDrop: Dictionary = _wait(1200.0, "heavy")
	var gDrop: Dictionary = _wait(1200.0, "guard")
	var none: Dictionary = _wait(1200.0, "")
	var sameTick: Dictionary = _wait(1200.0, "same")
	var brawlOn: Dictionary = _wait(60.0, "heavy")
	om["dropOnPress"] = false
	var gOff: Dictionary = _wait(1200.0, "guard")
	var brawlOff: Dictionary = _wait(60.0, "heavy")
	om["dropOnPress"] = was
	for r in [yDrop, gDrop, none, sameTick, brawlOn, gOff, brawlOff]:
		print("      %s: waiting at the press %s, waiting after %s, replaced %d, beam %s (at +%d), brawl began %s, brawl ended by the beam %s" % [r.name, str(r.waiting), str(r.after), r.replaced, str(r.fired), r.firedAt, str(r.brawl), str(r.brawlBeam)])
	_expect(yDrop.waiting and not yDrop.after and yDrop.replaced == 1 and not yDrop.fired, "on: a Y press after the release drops the waiting beam (replaced), and no beam comes")
	_expect(gDrop.waiting and not gDrop.after and gDrop.replaced == 1 and not gDrop.fired, "on: a guard press after the release drops it too")
	_expect(none.waiting and none.fired and none.replaced == 0, "on: with nothing pressed it still fires once the target is free (+%d ticks)" % none.firedAt)
	_expect(sameTick.waiting and sameTick.after and sameTick.replaced == 0, "on: a press on the release's own tick is part of the release: it still waits")
	_expect(brawlOn.brawl and not brawlOn.brawlBeam and not brawlOn.fired and brawlOn.replaced == 1, "on, at close range: a Y that begins a brawl after the release: the beam is dropped and doesn't end the brawl")
	_expect(gOff.fired and gOff.replaced == 0, "negative control, off: after a guard press the waiting beam fires later anyway (+%d ticks)" % gOff.firedAt)
	_expect(brawlOff.brawl and brawlOff.fired, "negative control, off: after the brawl's Y the waiting beam fires later (brawl ended by it %s)" % str(brawlOff.brawlBeam))
	DirBeamMove.setForce(-1)
	DirBeamPlay.setFrontForce(-1)
	DirStick.setForce(-1)
	_rtRows()
	print("STRAY BEAMS: %d check(s) failed" % failed)
	quit(1 if failed > 0 else 0)


func _expect(ok: bool, what: String) -> void:
	print(("ok    " if ok else "FAIL  ") + what)
	if not ok:
		failed += 1


func _fresh(gap: float) -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 11, {"p1": false, "p2": false}, {"intro": false})
	for f in S.fighters:
		f.ai = null
		f.act.v2 = true
		f.hp = 100000.0
		f.ki = 100.0
	S.fighters[1].x = SimWrap.wrap(S.fighters[0].x + gap)
	S.fighters[1].y = S.fighters[0].y
	for _k in range(30):
		_step(S)
	_cues.clear()
	return S


func _step(S: SimState, a: SimIntent = null, b: SimIntent = null) -> void:
	SimCore.step(S, [a if a != null else SimIntent.new(), b if b != null else SimIntent.new()])
	for e in S.out.fx:
		if e.type == "cue":
			_cues.append([S.tick, String(e.kind), String(e.text), String(e.source), int(e.actor)])
	S.out.fx.clear()
	S.out.feed.clear()


func _count(kind: String, text: String = "", src: String = "", actor: int = -1) -> int:
	var n: int = 0
	for c in _cues:
		if c[1] == kind and (text == "" or c[2] == text) and (src == "" or c[3] == src) and (actor < 0 or c[4] == actor):
			n += 1
	return n


func _rb(start: bool, release: bool, held: bool, dir: int = SimStrikeRead.RIGHT) -> SimIntent:
	var i := SimIntent.new()
	i.rsStart = start
	i.rsRelease = release
	i.rsHeld = held
	i.rsDir = dir
	i.rsMask = DirStick.RB
	i.stanceMask = DirStick.RB
	return i


## A stage 1 hold, let go while the target is held (stunned 40 ticks): it waits. Then press ("heavy": Y, "guard": a guard press, "":
## nothing, "same": a Y on the release's own tick) 8 ticks after the release (at once for "same"), and play 110 ticks.
func _wait(gap: float, press: String) -> Dictionary:
	var S := _fresh(gap)
	var A = S.fighters[0]
	var D = S.fighters[1]
	_step(S, _rb(true, false, true))
	for _k in range(30):
		_step(S, _rb(false, false, true))
	D.stunTicks = 40   # his target held: the release waits on the gate
	var rel := _rb(false, true, false)
	if press == "same":
		rel.heavy = true
	_step(S, rel)
	var out := {"name": "%s, %s, %s" % ["dropOnPress" if bool(DirBeamMove.cfg().get("dropOnPress", false)) else "off", "close" if gap < 200.0 else "far", press if press != "" else "nothing"], "waiting": DirBeamMove.pending(A), "after": false, "replaced": 0, "fired": false, "firedAt": -1, "brawl": false, "brawlBeam": false}
	var t0: int = S.tick
	_cues.clear()
	for k in range(110):
		var i := SimIntent.new()
		if k == 7 and press == "heavy":
			i.heavy = true
		if k == 7 and press == "guard":
			i.guardPress = true
			i.guard = true
		_step(S, i)
		if k == 7 or (press == "same" and k == 0):
			out.after = DirBeamMove.pending(A)
		if DirBrawl.inBrawl(S, A):
			out.brawl = true
		if not out.fired and (_count("beam_stage", "", "", 0) > 0 or _count("beam_fire", "", "", 0) > 0):
			out.fired = true
			out.firedAt = S.tick - t0
	out.replaced = _count("stick_refused", "beam", "replaced", 0)
	out.brawlBeam = _count("brawl_end", "beam") > 0
	SimCore.dispose(S)
	return out


## RT's window for RT + B (isB read directly at the tick B is pressed, with RT pressed k live ticks before and held since).
func _rtRows() -> void:
	SimInputData.t(["tapHold", "holdStart"], 12)   # (the timing loaded)
	var sw: Dictionary = SimInputData.timing["switches"]
	var b0 = sw.get("bNoBeam", false)
	var k0 = sw.get("bNoBeamKeepRt", false)
	sw["bNoBeam"] = true
	sw["bNoBeamKeepRt"] = true
	SimInputData.invalidate()
	var hs: int = int(SimInputData.t(["tapHold", "holdStart"], 12))
	var r: Dictionary = {}
	for k in [0, hs, hs + 1, 26]:
		r[k] = _rtB(k)
	DirBrawl.blindRt = true
	var old26: bool = _rtB(26)
	DirBrawl.blindRt = false
	print("      RT + B, isB (true: B is the heavy, never a beam; false: the signature) with B %s live ticks after RT: %s; the old rule at 26: %s" % [str([0, hs, hs + 1, 26]), str([r[0], r[hs], r[hs + 1], r[26]]), str(old26)])
	_expect(not r[0] and not r[hs], "RT + B on RT's own tick, and %d live ticks after, is still the signature" % hs)
	_expect(r[hs + 1] and r[26], "B %d live ticks after RT, and 26 (Orb's 6617), is the heavy" % (hs + 1))
	_expect(not old26, "negative control, the window unread (RT held, not charging): 26 after is still the signature")
	sw["bNoBeam"] = false
	sw["bNoBeamKeepRt"] = false
	SimInputData.invalidate()
	var S := _fresh(1200.0)
	var A = S.fighters[0]
	var n0: int = A.act.dirI.size()
	_step(S, _rt(true, false))
	for _k in range(5):
		_step(S, _rt(false, false))
	_expect(A.act.dirI.size() == n0, "the switches off: nothing is written for RT (%d slots before and after)" % n0)
	SimCore.dispose(S)
	sw["bNoBeam"] = b0
	sw["bNoBeamKeepRt"] = k0
	SimInputData.invalidate()


func _rt(press: bool, sig: bool) -> SimIntent:
	var i := SimIntent.new()
	i.power = true
	i.powerPress = press
	i.stanceMask = 4
	i.sig = sig
	return i


## isB at the tick B comes, k live ticks after RT's press (0: the same tick).
func _rtB(k: int) -> bool:
	var S := _fresh(1200.0)
	var A = S.fighters[0]
	if k > 0:
		_step(S, _rt(true, false))
		for _j in range(k - 1):
			_step(S, _rt(false, false))
	A.input = _rt(k == 0, true)
	var b: bool = DirBrawl.isB(A, "sig")
	SimCore.dispose(S)
	return b
