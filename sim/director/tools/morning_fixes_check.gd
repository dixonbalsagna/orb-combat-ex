extends SceneTree
## The stand-in's pre-play fixes for Orb's morning build (docs/director/pending/morning-fixes/), with the beam's own move on and armour's own
## switch off, as on the page:
##   godot --headless --path . --script res://sim/director/tools/morning_fixes_check.gd
## - a short hold fires releaseTell after its release; let go and waiting on the gate, he moves at full speed
## - a quick RB flick in a brawl says "close"; out of one it's the heavy blast
## - a working fire-back is answered (stick_start), one it can't pay says "ki", and it costs the smallest stage's 12
## - press_refused: none for a stick stun held back (the flick lands: it's no refusal), queue_expired on a request that runs out; the stick's "hit" when a blow ends its
##   wind-up. Off (press.refusedCue false), none of the new cues
## Ends on the verdict line.

var failed: int = 0
var _cues: Array = []


func _init() -> void:
	DirStick.setForce(1)
	DirStick.setArmourForce(0)
	DirBeamPlay.setFrontForce(1)
	DirBeamMove.setForce(1)
	var pc: Dictionary = DirExchange.pressCfg()
	pc["refusedCue"] = true
	_shortHold()
	_pendingMoves()
	_quickFlick()
	_fireBack()
	_stunLimit()
	_queueExpired()
	pc["refusedCue"] = false
	_off()
	DirBeamMove.setForce(-1)
	DirBeamPlay.setFrontForce(-1)
	DirStick.setArmourForce(-1)
	DirStick.setForce(-1)
	print("MORNING FIXES: %d check(s) failed" % failed)
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


func _count(kind: String, src: String = "", actor: int = -1) -> int:
	var n: int = 0
	for c in _cues:
		if c[1] == kind and (src == "" or c[3] == src) and (actor < 0 or c[4] == actor):
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


func _shortHold() -> void:
	var S := _fresh(1200.0)
	_step(S, _rb(true, false, true))
	for _k in range(13):
		_step(S, _rb(false, false, true))
	var t0: int = S.tick
	_step(S, _rb(false, true, false))
	var at: int = -1
	for _k in range(60):
		_step(S)
		if at < 0 and _count("beam_fire") > 0:
			at = S.tick
	_expect(at > 0 and at - t0 <= int(DirBeamPlay.frontCfg().releaseTell) + 2, "a stage 1 hold of 14 ticks fires releaseTell after its release: %d ticks" % (at - t0))
	SimCore.dispose(S)


func _pendingMoves() -> void:
	var S := _fresh(1200.0)
	var A = S.fighters[0]
	var D = S.fighters[1]
	_step(S, _rb(true, false, true))
	for _k in range(30):
		_step(S, _rb(false, false, true))
	var held: float = DirStick.holdMove(S, A)
	D.stunTicks = 40   # his target held: the release waits on the gate
	_step(S, _rb(false, true, false))
	var waiting: bool = DirBeamMove.pending(A)
	var after: float = DirStick.holdMove(S, A)
	_expect(held < 1.0 and waiting and after == 1.0, "holding he's slowed (%.2f); let go and waiting on the gate, full speed again (%.2f)" % [held, after])
	SimCore.dispose(S)


func _quickFlick() -> void:
	var S := _fresh(58.0)
	var light := SimIntent.new()
	light.light = true
	_step(S, light)
	for _k in range(8):
		_step(S)
	var brawl: bool = S.dirS.ex != null and DirBrawl.isBrawl(S.dirS.ex)
	_step(S, _rb(true, false, true))
	_step(S, _rb(false, false, true))
	_step(S, _rb(false, true, false))
	for _k in range(5):
		_step(S)
	_expect(brawl and _count("stick_refused", "close", 0) == 1, "a quick RB flick in a brawl says why: close (%d)" % _count("stick_refused", "close", 0))
	SimCore.dispose(S)
	var S2 := _fresh(1200.0)
	var ki0: float = S2.fighters[0].ki
	_step(S2, _rb(true, false, true))
	_step(S2, _rb(false, false, true))
	_step(S2, _rb(false, true, false))
	var req: int = DirInterrupt.gi(S2.fighters[0], DirInterrupt.BLAST_REQ)
	for _k in range(5):
		_step(S2)
	_expect((req & 1) == SimAct.HEAVY and _count("stick_refused", "", 0) == 0, "out of one it's the heavy blast (request %d), and nothing's refused" % req)
	SimCore.dispose(S2)


func _fireBack() -> void:
	for ki in [100.0, 5.0]:
		var S := _fresh(2400.0)
		var A = S.fighters[0]
		var D = S.fighters[1]
		var sg := SimIntent.new()
		sg.sig = true
		sg.stanceMask = 4
		_step(S, sg)
		for _k in range(240):
			if DirBeamPlay.windowOpen(S, D):
				break
			_step(S)
		D.ki = ki
		_cues.clear()
		var toward: int = SimStrikeRead.RIGHT if SimWrap.sdx(D.x, A.x) >= 0.0 else SimStrikeRead.LEFT
		_step(S, null, _rb(true, false, true, toward))
		if ki > 50.0:
			_expect(S.game.clash != null and _count("stick_start", "", 1) == 1 and _count("stick_refused", "", 1) == 0, "a working fire-back is answered: a struggle, stick_start, no refusal")
			_expect(absf((ki - D.ki) - 12.0) < 0.2, "it costs the smallest stage's 12 (%.1f)" % (ki - D.ki))
		else:
			_expect(_count("stick_refused", "ki", 1) == 1 and _count("stick_start", "", 1) == 0, "one it can't pay says ki, once, and isn't answered")
		SimCore.dispose(S)


func _stunLimit() -> void:
	var S := _fresh(58.0)
	var light := SimIntent.new()
	light.light = true
	_step(S, light)
	for _k in range(30):
		_step(S)
	for d in [SimStrikeRead.LEFT, SimStrikeRead.UP]:   # stick_check's one-stun-a-string script: two flicks, 14 ticks apart
		var w := SimIntent.new()
		w.rsStart = true
		w.rsHeld = true
		w.rsDir = d
		_step(S, w)
		for _k in range(3):
			var h := SimIntent.new()
			h.rsHeld = true
			h.rsDir = d
			_step(S, h)
		var r := SimIntent.new()
		r.rsRelease = true
		r.rsDir = d
		_step(S, r)
		for _k in range(14):
			_step(S)
	_expect(_count("press_refused", "stun_limit", 0) == 0 and _count("stick_hit", "", 0) >= 2, "a second stick stun in one string is held back, and the flick lands: no refusal (stun_limit %d, hits %d)" % [_count("press_refused", "stun_limit", 0), _count("stick_hit", "", 0)])
	SimCore.dispose(S)


func _queueExpired() -> void:
	var S := _fresh(1200.0)
	var A = S.fighters[0]
	SimAct.push(A, SimAct.HEAVY, 0, 0, S.tick - 200)   # a request long past its life
	DirExchange._queues(S)
	_step(S)   # (its cue is collected with the tick's)
	_expect(_count("press_refused", "queue_expired", 0) == 1, "a request that runs out is said: queue_expired")
	SimCore.dispose(S)


func _off() -> void:
	var S := _fresh(1200.0)
	var A = S.fighters[0]
	SimAct.push(A, SimAct.HEAVY, 0, 0, S.tick - 200)
	DirExchange._queues(S)
	_step(S)
	_expect(_count("press_refused") == 0, "off (press.refusedCue false): no press_refused")
	SimCore.dispose(S)
