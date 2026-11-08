extends SceneTree
## The three blows against a foe who reacts, and off. Ends on the verdict line.
##   godot --headless --path . --script res://sim/director/tools/stance_check.gd

var failed: int = 0


func _init() -> void:
	DirZip.setFsForce(0)   # the flight strikes off: with them on, LT pressed and a face button inside 4 ticks is a flight strike (flight_strike_check has that)
	DirStick.setForce(1)
	DirStance.setForce(0)
	var off: Array = _run("x", "x", 1)
	DirStance.setForce(1)
	_rows(off)
	DirStance.setForce(-1)
	DirStick.setForce(-1)
	print("STANCE: %d check(s) failed" % failed)
	DirZip.setFsForce(-1)
	quit(1 if failed > 0 else 0)


func _expect(ok: bool, what: String) -> void:
	print(("ok    " if ok else "FAIL  ") + what)
	if not ok:
		failed += 1


## Returns [he took, foe took, gap at the end, side at the start, side at the end, in the brawl]. The foe presses a tick before, so his blow lands inside this one's wind-up.
func _run(foe: String, mine: String, mask: int) -> Array:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 11, {"p1": false, "p2": false}, {"planet": 7, "touch": 2, "planetGen": 3, "intro": false, "startTier": 2})
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
	var l := SimIntent.new()
	l.light = true
	_st(S, l)
	for _k in range(30):
		_st(S)
	var hp0: float = A.hp
	var hp1: float = D.hp
	var side0: float = signf(SimWrap.sdx(A.x, D.x))
	for t in range(40):
		var a := SimIntent.new()
		var b := SimIntent.new()
		a.stanceMask = mask
		if mask == DirStick.LB:
			a.guard = true
			a.stance = 1
		if t == 1:
			if mine == "x":
				a.light = true
			else:
				a.heavy = true
		if foe == "x" and t == 0:
			b.light = true
		_st(S, a, b)
	var r: Array = [hp0 - A.hp, hp1 - D.hp, absf(SimWrap.sdx(A.x, D.x)), side0, signf(SimWrap.sdx(A.x, D.x)), S.dirS.ex != null and DirBrawl.isBrawl(S.dirS.ex)]
	SimCore.dispose(S)
	return r


func _st(S: SimState, a: SimIntent = null, b: SimIntent = null) -> void:
	SimCore.step(S, [a if a != null else SimIntent.new(), b if b != null else SimIntent.new()])
	S.out.fx.clear()
	S.out.feed.clear()


func _rows(off: Array) -> void:
	var plain: Array = _run("x", "x", 0)
	var check: Array = _run("x", "x", DirStick.LB)
	print("      a foe's X inside it: plain X, he took %.1f, gave %.1f; off, LB + X %.1f, %.1f; LB + X %.1f, %.1f" % [plain[0], plain[1], off[0], off[1], check[0], check[1]])
	_expect(float(check[0]) < float(off[0]) and float(check[1]) > 0.0, "the check: his guard's up through it, and it lands")
	var y: Array = _run("", "y", 0)
	var push: Array = _run("", "y", DirStick.LB)
	print("      gap after Y %.0f; after LB + Y %.0f, worth %.1f against %.1f" % [y[2], push[2], push[1], y[1]])
	_expect(float(push[2]) > float(y[2]) + 60.0, "the push: he's shoved back")
	_expect(absf(float(push[1]) - float(y[1])) < 0.01, "at the same worth")
	_expect(bool(push[5]), "and the brawl holds")
	var x: Array = _run("", "x", 0)
	var step: Array = _run("", "x", DirStick.LT)
	print("      side after X %.0f; after LT + X %.0f (was %.0f), gap %.0f" % [x[4], step[4], step[3], step[2]])
	_expect(float(x[4]) == float(x[3]), "plain X: the same side")
	_expect(float(step[4]) != float(step[3]), "the step strike: he comes out past him")
	_expect(absf(float(step[1]) - float(x[1])) < 0.01, "at the same worth")
	_expect(bool(step[5]), "and the brawl holds")
