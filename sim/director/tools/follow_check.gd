extends SceneTree
## Row 42, on a real far send at both tier 4: a far tap inside the window flies after him and lands, a late one is the taunt, a far tap with
## no send is the taunt, and off nothing changes. Ends on the verdict line.
##   godot --headless --path . --script res://sim/director/tools/follow_check.gd

var failed: int = 0
var _taunts: int = 0
var _hits: int = 0
var _hp: float = 100000.0


func _init() -> void:
	DirChaseTap.setForce(0)
	for f0 in [0, 1]:
		DirFollow.setForce(f0)
		_rows(f0 == 1)
	DirFollow.setForce(1)
	_noSend()
	_masher()
	DirArc.setForce(1)
	_rows(true)
	DirArc.setForce(-1)
	DirFollow.setForce(-1)
	print("FOLLOW: %d check(s) failed" % failed)
	quit(1 if failed > 0 else 0)


func _expect(ok: bool, what: String) -> void:
	print(("ok    " if ok else "FAIL  ") + what)
	if not ok:
		failed += 1


func _st(S: SimState, a: SimIntent = null) -> void:
	SimCore.step(S, [a if a != null else SimIntent.new(), SimIntent.new()])
	for e in S.out.fx:
		if e.type == "cue" and e.kind == "taunt_start" and e.actor == 0.0:
			_taunts += 1
	if S.fighters[1].hp < _hp and SimDetMath.hypot(SimWrap.sdx(S.fighters[0].x, S.fighters[1].x), S.fighters[0].y - S.fighters[1].y) < 200.0:
		_hits += 1   # a blow of his, not the ground
	_hp = S.fighters[1].hp
	S.out.fx.clear()
	S.out.feed.clear()


func _x() -> SimIntent:
	var l := SimIntent.new()
	l.light = true
	return l


## A real send: both at tier 4, B to the flash. It returns with him just launched.
func _sent(seed: int = 11) -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, seed, {"p1": false, "p2": false}, {"planet": 7, "touch": 2, "planetGen": 3, "intro": false, "startTier": 4})
	for f in S.fighters:
		f.ai = null
		f.hp = 100000.0
		f.ki = 100.0
		f.act.v2 = true
	var A = S.fighters[0]
	var D = S.fighters[1]
	D.x = SimWrap.wrap(A.x + 58.0)
	D.y = A.y
	for _k in range(5):
		_st(S)
	_st(S, _x())
	for _k in range(24):
		_st(S)
	D.stunTicks = 120
	var y := SimIntent.new()
	y.sig = true
	y.sigHeld = true
	_st(S, y)
	for _k in range(46):
		var h := SimIntent.new()
		h.sigHeld = true
		_st(S, h)
	for _k in range(120):
		_st(S)
		if D.state == "launched":
			break
	return S


func _rows(on: bool) -> void:
	for off in [18, 60, 120, 240]:
		var S := _sent()
		var A = S.fighters[0]
		var D = S.fighters[1]
		for _k in range(off):
			_st(S)
		var d0: float = SimDetMath.hypot(SimWrap.sdx(A.x, D.x), A.y - D.y)
		_taunts = 0
		_hits = 0
		_st(S, _x())
		var flying: bool = DirBands.who(S) == 0
		var at: int = -1
		var closest: float = d0
		for k in range(800):
			_st(S)
			closest = minf(closest, SimDetMath.hypot(SimWrap.sdx(A.x, D.x), A.y - D.y))
			if _hits > 0 and at < 0:
				at = k
				break
		print("      %s, %d after the send, %.0f away: flying %s, taunts %d, closest %.0f, struck at %d, D %s" % ["on" if on else "off", off, d0, str(flying), _taunts, closest, at, D.state])
		var inWindow: bool = on and off <= int(DirFollow.cfg().ticks)
		if inWindow:
			_expect(flying and _taunts == 0, "%d after the send: the tap flies after him" % off)
			_expect(at >= 0, "%d after the send: and the blow lands (%d)" % [off, at])
		else:
			_expect(not flying and _taunts == 1, "%s, %d after the send: the taunt" % ["on" if on else "off", off])
		SimCore.dispose(S)


func _noSend() -> void:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 11, {"p1": false, "p2": false}, {"planet": 7, "touch": 2, "planetGen": 3, "intro": false, "startTier": 4})
	for f in S.fighters:
		f.ai = null
		f.act.v2 = true
	S.fighters[1].x = SimWrap.wrap(S.fighters[0].x + 3000.0)
	for _k in range(30):
		_st(S)
	_taunts = 0
	_st(S, _x())
	_expect(_taunts == 1 and DirBands.who(S) != 0, "no send: a far tap is the taunt")
	SimCore.dispose(S)


## A scripted masher: X every 12 ticks from the send on.
func _masher() -> void:
	var S := _sent(12)
	var A = S.fighters[0]
	var D = S.fighters[1]
	_hits = 0
	var closest: float = 1000000.0
	for k in range(360):
		_st(S, _x() if k % 12 == 0 else null)
		closest = minf(closest, SimDetMath.hypot(SimWrap.sdx(A.x, D.x), A.y - D.y))
	print("      the masher: closest %.0f, %d blows landed" % [closest, _hits])
	_expect(closest < 150.0, "a masher closes on a sent rival (%.0f)" % closest)
	SimCore.dispose(S)
