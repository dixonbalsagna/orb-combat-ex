extends SceneTree
## The stick beam as its own move (DirBeamMove; docs/director/beams-own-move-plan.md step 1), by scripted RB holds on idle fighters:
##   godot --headless --path . --script res://sim/director/tools/beam_move_check.gd
## - the stage count by tier and power (power-scale.md's level); the stages by the clock, capped by what he can pay; the top's price,
##   stepping down; a hold that never fires by itself
## - nobody is locked by the charge; the release pays its stage, with no 45 and no signature wait, and fires; in a brawl the brawl gives
##   way at the release; the point-blank throw-back
## - the 0.3 s gate on a target who wasn't free, and the lit hand refused past its wait
## - a beam's hold armoured from its first tick; the beam's length by stage
## - with the switch off, the stick's beam is the signature's request, as it was
## Ends on the verdict line.

var failed: int = 0
var _cues: Array = []


func _init() -> void:
	DirStick.setForce(1)
	DirBeamPlay.setFrontForce(1)
	DirBeamMove.setForce(1)
	_counts()
	_stages()
	_afford()
	_top()
	_free()
	_refillStrike()
	_brawl()
	_gate()
	_late()
	_armour()
	DirBeamMove.setForce(0)
	_off()
	DirBeamMove.setForce(-1)
	DirBeamPlay.setFrontForce(-1)
	DirStick.setForce(-1)
	print("BEAM MOVE: %d check(s) failed" % failed)
	quit(1 if failed > 0 else 0)


func _expect(ok: bool, what: String) -> void:
	print(("ok    " if ok else "FAIL  ") + what)
	if not ok:
		failed += 1


func _fresh(gap: float, ki: float = 100.0) -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 11, {"p1": false, "p2": false}, {"intro": false})
	for f in S.fighters:
		f.ai = null
		f.act.v2 = true
		f.hp = 100000.0
		f.ki = 100.0
	S.fighters[0].ki = ki
	S.fighters[1].x = SimWrap.wrap(S.fighters[0].x + gap)
	S.fighters[1].y = S.fighters[0].y
	S.out.fx.clear()
	for _k in range(30):
		_step(S)   # long enough that both have been free 0.3 s
	return S


func _step(S: SimState, a: SimIntent = null, b: SimIntent = null) -> void:
	SimCore.step(S, [a if a != null else SimIntent.new(), b if b != null else SimIntent.new()])
	for e in S.out.fx:
		if e.type == "cue":
			_cues.append([S.tick, String(e.kind), String(e.text), String(e.source), int(e.actor)])
	S.out.fx.clear()
	S.out.feed.clear()


func _rb(start: bool, release: bool, held: bool, lvl: int = 0) -> SimIntent:
	var i := SimIntent.new()
	i.rsStart = start
	i.rsRelease = release
	i.rsHeld = held
	i.rsDir = SimStrikeRead.RIGHT
	i.rsLevel = lvl
	i.rsMask = DirStick.RB
	i.stanceMask = DirStick.RB
	return i


## Holds RB and the stick for n live ticks (the start is the first); b: the other's intent each tick, or null.
func _hold(S: SimState, n: int, b = null) -> void:
	_step(S, _rb(true, false, true), b)
	for _k in range(n - 1):
		_step(S, _rb(false, false, true), b)


func _release(S: SimState) -> void:
	_step(S, _rb(false, true, false, 3))


func _count(kind: String, text: String = "") -> int:
	var n: int = 0
	for c in _cues:
		if c[1] == kind and (text == "" or c[2] == text or c[3] == text):
			n += 1
	return n


func _counts() -> void:
	var S := _fresh(800.0)
	var A = S.fighters[0]
	var rows: Array = [[1.0, 0.0, 2], [1.0, 100.0, 3], [2.0, 35.0, 3], [3.0, 65.0, 5], [4.0, 100.0, 6], [4.0, 0.0, 5]]
	var ok: bool = true
	var got: Array = []
	for r in rows:
		A.tier = float(r[0])
		A.power = float(r[1])
		got.append(DirBeamMove.stageCount(A))
		ok = ok and DirBeamMove.stageCount(A) == int(r[2])
	_expect(ok, "the stage count by tier and power, 2 + round(4 x level): %s (base 2, base at full power 3, tier 2 at 35%% 3, tier 3 at 65%% 5, the top 6)" % str(got))
	SimCore.dispose(S)


func _stages() -> void:
	_cues.clear()
	var S := _fresh(1200.0)
	var A = S.fighters[0]
	var D = S.fighters[1]
	A.tier = 4.0
	A.power = 100.0
	_hold(S, 125)
	var ups: Array = []
	for c in _cues:
		if c[1] == "stick_stage":
			ups.append(int(c[2]))
	var locked: bool = D.state != "free" or (S.dirS.ex != null)
	_expect(ups == [1, 2, 3, 4, 5, 6] and DirBeamMove.stage(A) == 6, "a top fighter's hold climbs six stages by the clock (12 to 120 ticks): %s" % str(ups))
	_expect(not locked, "nobody is locked while he charges: no exchange, his rival is free (%s)" % D.state)
	var ki0: float = A.ki
	var tick0: int = S.tick
	_release(S)
	var paid: float = ki0 - A.ki
	var started: bool = S.dirS.ex != null and S.dirS.ex.kind == "sig" and S.dirS.ex.A == A
	var fireAt: int = -1
	for _k in range(40):
		_step(S)
		if fireAt < 0 and _count("beam_fire") > 0:
			fireAt = S.tick
	_expect(started and absf(paid - 50.0) < 0.1 and A.sigReadyT <= 0.0, "the release starts the beam's exchange at once, for stage 6's 50 (paid %.1f), with no signature wait (ready at %.2f)" % [paid, A.sigReadyT])
	_expect(fireAt > 0 and fireAt - tick0 <= int(DirBeamPlay.frontCfg().releaseTell) + 2, "it fires on the release: %d ticks after it" % (fireAt - tick0))
	_expect(absf(DirBeamMove.hitDamage(A, 230.0) - 345.6) < 0.01 and absf(DirBeamMove.hitDamage(A, 200.0) - 300.52) < 0.01, "stage 6's hit is 96 x 3.6 = %.1f, its guarded hit the same share of the guard's (%.1f)" % [DirBeamMove.hitDamage(A, 230.0), DirBeamMove.hitDamage(A, 200.0)])
	SimCore.dispose(S)


func _afford() -> void:
	_cues.clear()
	var S := _fresh(1200.0, 25.0)
	var A = S.fighters[0]
	A.tier = 4.0
	A.power = 100.0
	_hold(S, 47)
	_expect(DirBeamMove.stage(A) == 2 and A.ki < 32.0 and _count("stick_stage", "capped") == 1, "with %.1f energy, under stage 3's 32, the stages stop at 2 as the clock reaches 3, told once: stage %d, told %d" % [A.ki, DirBeamMove.stage(A), _count("stick_stage", "capped")])
	SimCore.dispose(S)


func _top() -> void:
	# The top's price, against a twin holding with the move off (energy refills 5 a second while he's free, on both).
	var spent: Array = []
	for force in [1, 0]:
		_cues.clear()
		DirBeamMove.setForce(force)
		var S := _fresh(1200.0, 30.0)
		var A = S.fighters[0]
		A.tier = 1.0
		A.power = 0.0
		_hold(S, 29)
		var ki0: float = A.ki
		_hold_on(S, 60)
		spent.append(ki0 - A.ki)
		if force == 1:
			var st0: int = DirBeamMove.stage(A)
			A.ki = 19.5   # under the top's 20
			_hold_on(S, 1)
			var down: int = DirBeamMove.stage(A)
			_hold_on(S, 300)
			_expect(st0 == 2 and down == 1, "at the top (2 of 2) with less than its price, it steps down a stage: %d to %d" % [st0, down])
			_expect(DirStick._g(A, DirStick.ST_ON) == 3 and _count("beam_fire") == 0, "held for 6 s, it never fires by itself")
		SimCore.dispose(S)
	DirBeamMove.setForce(1)
	_expect(absf(float(spent[0]) - 4.0) < 0.01 and float(spent[1]) < -4.0, "a second at the top costs 4, with no refill while he holds it (%.2f); the same hold without the move refills (%.2f)" % [spent[0], spent[1]])


func _refillStrike() -> void:
	# A plain strike's hold doesn't refill either, from the press to the release (Game Design, playable-build.md section 2).
	var got: Array = []
	for force in [1, 0]:
		DirBeamMove.setForce(force)
		var S := _fresh(58.0, 60.0)
		var A = S.fighters[0]
		var light := SimIntent.new()
		light.light = true
		_step(S, light)
		for _k in range(8):
			_step(S)
		var w := SimIntent.new()
		w.rsStart = true
		w.rsHeld = true
		w.rsDir = SimStrikeRead.RIGHT
		_step(S, w)
		var ki0: float = A.ki
		for _k in range(40):
			var h := SimIntent.new()
			h.rsHeld = true
			h.rsDir = SimStrikeRead.RIGHT
			_step(S, h)
		got.append(A.ki - ki0)
		SimCore.dispose(S)
	DirBeamMove.setForce(1)
	_expect(absf(float(got[0])) < 0.001 and float(got[1]) > 2.0, "a plain strike's hold doesn't refill with the move on (%+.2f in 40 ticks), and does off (%+.2f)" % [got[0], got[1]])


func _hold_on(S: SimState, n: int) -> void:
	for _k in range(n):
		_step(S, _rb(false, false, true))


func _free() -> void:
	# His rival can still hit him, guard and move while he charges: a light starts the brawl on him.
	_cues.clear()
	var S := _fresh(58.0)
	var A = S.fighters[0]
	var D = S.fighters[1]
	var light := SimIntent.new()
	light.light = true
	_hold(S, 20)
	_step(S, _rb(false, false, true), light)
	for _k in range(10):
		_step(S, _rb(false, false, true))
	var ex = S.dirS.ex
	_expect(ex != null and DirBrawl.isBrawl(ex) and ex.A == D, "his rival's light starts a brawl on the charger: he isn't locked out of it")
	SimCore.dispose(S)


func _brawl() -> void:
	_cues.clear()
	var S := _fresh(58.0)
	var A = S.fighters[0]
	var D = S.fighters[1]
	var light := SimIntent.new()
	light.light = true
	_step(S, light)
	for _k in range(8):
		_step(S)
	var inBrawl: bool = S.dirS.ex != null and DirBrawl.isBrawl(S.dirS.ex)
	_hold(S, 40)
	var stillBrawl: bool = S.dirS.ex != null and DirBrawl.isBrawl(S.dirS.ex)
	var x0: float = SimWrap.sdx(A.x, D.x)
	_release(S)
	var beam: bool = S.dirS.ex != null and S.dirS.ex.kind == "sig"
	for _k in range(30):
		_step(S)
	var x1: float = SimWrap.sdx(A.x, D.x)
	_expect(inBrawl and stillBrawl, "in a brawl the charge doesn't end the brawl")
	_expect(beam, "the release ends the brawl and starts the beam's exchange (point blank)")
	_expect(_count("beam_shove") >= 1 and absf(x1) > absf(x0) + 100.0 and signf(x1) == signf(x0), "the firing throws him back the way he already was, never through: %.0f to %.0f" % [x0, x1])
	SimCore.dispose(S)


func _gate() -> void:
	_cues.clear()
	var S := _fresh(1200.0)
	var A = S.fighters[0]
	var D = S.fighters[1]
	_hold(S, 40)
	D.stunTicks = 10   # something holds him: not free to act
	var t0: int = S.tick
	_release(S)
	var fireStart: int = -1
	for _k in range(60):
		if fireStart < 0 and S.dirS.ex != null and S.dirS.ex.kind == "sig":
			fireStart = S.tick
		_step(S)
	var freeAt: int = t0 + 10
	_expect(fireStart > 0 and fireStart - freeAt >= int(DirBeamMove.cfg().freeTicks) - 1 and fireStart - freeAt <= int(DirBeamMove.cfg().freeTicks) + 3, "a target held when the release came: the lit hand waits till he's been free 0.3 s (fired %d ticks after he was free)" % (fireStart - freeAt))
	_expect(_count("stick_refused", "soon") == 1, "and it says why as it starts waiting, once: soon (%d)" % _count("stick_refused", "soon"))
	SimCore.dispose(S)


func _late() -> void:
	_cues.clear()
	var S := _fresh(1200.0)
	var A = S.fighters[0]
	var D = S.fighters[1]
	_hold(S, 40)
	var ki0: float = A.ki
	D.stunTicks = 200
	_release(S)
	for _k in range(120):
		_step(S)
	_expect(_count("stick_refused", "late") == 1 and _count("beam_fire") == 0 and A.ki >= ki0 - 0.001, "held past its wait, it's refused and says so, and costs nothing (%d told)" % _count("stick_refused", "late"))
	SimCore.dispose(S)


func _armour() -> void:
	# Unforced: armour's own switch is off in the data, as on the page; the beam's hold is armoured by the move alone.
	var S := _fresh(1200.0)
	var A = S.fighters[0]
	_hold(S, 2)
	var on: bool = DirStick.armoured(S, A)
	DirBeamMove.setForce(0)
	var off: bool = DirStick.armoured(S, A)
	DirBeamMove.setForce(1)
	_expect(on and not off and not DirStick.armourOn(), "with armour's own switch off, a beam's hold is armoured from its first tick by the move (%s), and not without it (%s)" % [str(on), str(off)])
	SimCore.dispose(S)
	# A light on a beam's hold in a brawl, armour's switch off: the hold goes on.
	var S2 := _fresh(58.0)
	var A2 = S2.fighters[0]
	var light := SimIntent.new()
	light.light = true
	_step(S2, light)
	for _k in range(8):
		_step(S2)
	_hold(S2, 4)
	for k in range(30):
		_step(S2, _rb(false, false, true), light if k == 2 else null)
	_expect(DirStick._g(A2, DirStick.ST_ON) == 3, "a jab on a beam's hold in a brawl, armour's switch off: it holds")
	SimCore.dispose(S2)


func _off() -> void:
	_cues.clear()
	var S := _fresh(1200.0)
	var A = S.fighters[0]
	_hold(S, 40)
	var ki0: float = A.ki
	_release(S)
	var sig: bool = S.dirS.ex != null and S.dirS.ex.kind == "sig"
	_expect(sig and absf(ki0 - A.ki - 45.0) < 0.2 and A.sigReadyT > 0.0, "off, the stick's beam is the signature's request: 45 and its wait (paid %.1f)" % (ki0 - A.ki))
	SimCore.dispose(S)
