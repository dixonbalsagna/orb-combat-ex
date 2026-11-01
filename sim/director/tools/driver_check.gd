extends SceneTree
## RB + B: a tap, each level, a full send at level 3, a guard, a dodge dropping it, a press with no ki, off. Ends on the verdict line.
##   godot --headless --path . --script res://sim/director/tools/driver_check.gd

var failed: int = 0
var _cues: Array = []


func _init() -> void:
	DirDriver.setForce(0)
	_off()
	DirDriver.setForce(1)
	_levels()
	_guard()
	_drop()
	_noKi()
	DirDriver.setForce(-1)
	print("DRIVER: %d check(s) failed" % failed)
	quit(1 if failed > 0 else 0)


func _expect(ok: bool, what: String) -> void:
	print(("ok    " if ok else "FAIL  ") + what)
	if not ok:
		failed += 1


func _fresh(gap: float = 1500.0) -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 11, {"p1": false, "p2": false}, {"planet": 7, "touch": 2, "planetGen": 3, "intro": false, "startTier": 4})
	for f in S.fighters:
		f.ai = null
		f.ki = 100.0
		f.hp = 100000.0
		f.act.v2 = true
	var A = S.fighters[0]
	var D = S.fighters[1]
	D.x = SimWrap.wrap(A.x + gap)
	D.y = A.y
	for _k in range(10):
		_step(S)
	A.ki = 100.0
	return S


func _step(S: SimState, a: SimIntent = null, b: SimIntent = null) -> void:
	SimCore.step(S, [a if a != null else SimIntent.new(), b if b != null else SimIntent.new()])
	for e in S.out.fx:
		if e.type == "cue" and e.actor == 0.0 and (String(e.kind).begins_with("driver") or String(e.kind).begins_with("charge_")):
			_cues.append(String(e.kind) + ":" + String(e.text))
	S.out.fx.clear()
	S.out.feed.clear()


func _b(press: bool, held: bool) -> SimIntent:
	var i := SimIntent.new()
	i.stanceMask = 2
	i.sig = press
	i.sigHeld = held
	return i


## B held for `hold` ticks, and let go. Returns [ki spent, damage, D's state a little later, how far he went].
func _shot(hold: int, guard: bool = false) -> Array:
	var S := _fresh()
	var A = S.fighters[0]
	var D = S.fighters[1]
	var hp: float = D.hp
	var x0: float = D.x
	var ki0: float = A.ki
	_cues.clear()
	var g := SimIntent.new()
	if guard:
		g.guard = true
		D.stance = 1.0
	_step(S, _b(true, true), g)
	for _k in range(hold):
		_step(S, _b(false, true), g)
	var left: float = A.ki
	var far: float = 0.0
	var st: String = ""
	for k in range(90):
		_step(S, null, g)
		far = maxf(far, absf(SimWrap.sdx(x0, D.x)))
		if k == 30:
			st = String(D.state)
	var r: Array = [ki0 - left, hp - D.hp, st, far, _cues.duplicate()]
	SimCore.dispose(S)
	return r


func _off() -> void:
	var S := _fresh()
	_step(S, _b(true, true))
	_expect(DirDriver._g(S.fighters[0], DirDriver.D_AT) == 0, "off: it isn't the Driver's")
	SimCore.dispose(S)


func _levels() -> void:
	var last: float = 0.0
	var dm: Array = []
	for row in [[6, 0], [36, 1], [60, 2], [90, 3]]:
		var r: Array = _shot(int(row[0]))
		print("      held %d: level %d, %.1f damage, %s after 30 ticks, %.0f away at most, %s" % [row[0], row[1], r[1], r[2], r[3], str(r[4]).substr(0, 110)])
		dm.append(float(r[1]))
		_expect(float(r[1]) > 0.0, "level %d lands" % int(row[1]))
		_expect(float(r[3]) > 50.0, "level %d moves him (%.0f)" % [int(row[1]), r[3]])
	_expect(float(dm[0]) < float(dm[1]) and float(dm[1]) < float(dm[2]) and float(dm[2]) < float(dm[3]), "each level hits harder (%s)" % str(dm))
	var tap: Array = _shot(6)
	var full: Array = _shot(90)
	_expect(String(full[2]) == "launched", "level 3 is a full send (%s)" % full[2])
	_expect(float(full[3]) > float(tap[3]) * 2.0, "and goes far further than a tap (%.0f against %.0f)" % [full[3], tap[3]])


func _guard() -> void:
	var low: Array = _shot(6, true)
	var high: Array = _shot(90, true)
	print("      guarded: tap %.1f, %s; level 3 %.1f, %s" % [low[1], low[2], high[1], high[2]])
	_expect(String(high[2]) == "launched" and String(low[2]) != "launched", "level 3 breaks a guard, a tap doesn't")


func _drop() -> void:
	var S := _fresh()
	var A = S.fighters[0]
	var ki0: float = A.ki
	_cues.clear()
	_step(S, _b(true, true))
	for _k in range(20):
		_step(S, _b(false, true))
	var d := _b(false, true)
	d.dodge = true
	_step(S, d)
	_expect(DirDriver._g(A, DirDriver.D_AT) == 0 and A.ki >= ki0 - 0.01, "a dodge drops it for nothing")
	SimCore.dispose(S)


func _noKi() -> void:
	var S := _fresh()
	S.fighters[0].ki = 1.0
	_cues.clear()
	_step(S, _b(true, true))
	_expect(DirDriver._g(S.fighters[0], DirDriver.D_AT) == 0 and _cues.has("driver_refused:ki"), "no ki: refused, and it says so")
	SimCore.dispose(S)
