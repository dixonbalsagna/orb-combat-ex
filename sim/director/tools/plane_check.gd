extends SceneTree
## Back to the plane (DirPlane; rulings-2026-10-30f.md row 9): the ease's curve, what delays it, the close, and off.
##   godot --headless --path . --script res://sim/director/tools/plane_check.gd

var failed: int = 0


func _init() -> void:
	var rate: float = DirPlane.rate()
	_expect(rate == 20.0, "the data's number is 20 (%.1f)" % rate)
	_curve(1200.0, 60)
	_curve(300.0, 15)
	_curve(-1200.0, 60)
	_heldCases()
	_rush()
	_pair()
	DirPlane.setRate(0.0)
	var S := _sim()
	S.fighters[0].z = -300.0
	_run(S, 30)
	_expect(S.fighters[0].z == -300.0, "the number at 0: he stays, as main does")
	SimCore.dispose(S)
	DirPlane.setRate(rate)
	print("plane_check: %s" % ("passed" if failed == 0 else "FAILED (%d)" % failed))
	quit(1 if failed > 0 else 0)


func _expect(ok: bool, what: String) -> void:
	print(("ok    " if ok else "FAIL  ") + what)
	if not ok:
		failed += 1


## A match with no AI and nobody near, the exchange empty.
func _sim() -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {"p1": false, "p2": false}, {"intro": false})
	for f in S.fighters:
		f.ai = null
		f.rush = null
		f.state = "free"
		f.vx = 0.0
		f.vy = 0.0
	S.fighters[1].x = SimWrap.wrap(S.fighters[0].x + 4000.0)
	return S


func _run(S: SimState, n: int) -> void:
	for _k in range(n):
		SimCore.step(S)
		S.out.fx.clear()
		S.out.feed.clear()


func _curve(z0: float, ticks: int) -> void:
	var S := _sim()
	var f = S.fighters[0]
	f.z = z0
	var prev: float = z0
	var biggest: float = 0.0
	var first: float = 0.0
	var mono: bool = true
	var done: int = -1
	for t in range(ticks + 5):
		SimCore.step(S)
		S.out.fx.clear()
		S.out.feed.clear()
		var d: float = absf(f.z - prev)
		if t == 0:
			first = d
		biggest = maxf(biggest, d)
		if absf(f.z) > absf(prev):
			mono = false
		prev = f.z
		if f.z == 0.0 and done < 0:
			done = t + 1
	_expect(done == ticks, "from %.0f, home in %d ticks (%d)" % [z0, ticks, done])
	_expect(mono, "from %.0f, he only ever comes closer" % z0)
	_expect(first < biggest / 3.0, "from %.0f, it eases in: the first step is %.2f of a peak of %.1f" % [z0, first, biggest])
	_expect(biggest <= 31.0, "from %.0f, the most in a tick is %.1f: a smoothstep's 1.5 x 20, no snap" % [z0, biggest])
	SimCore.dispose(S)


func _heldCases() -> void:
	var S := _sim()
	var f = S.fighters[0]
	f.z = -300.0
	f.state = "launched"
	DirPlane.tick(S, SimConst.DT)
	_expect(f.z == -300.0, "in a flight, the flight has him: the ease waits")
	SimCore.dispose(S)
	S = _sim()
	f = S.fighters[0]
	f.z = -300.0
	f.state = "down"
	f.embedT = 40
	f.y = WorldTerrain.groundY(S, f.x)
	var before: float = f.z
	DirPlane.tick(S, SimConst.DT)
	_expect(f.z == before, "buried, he waits")
	f.embedT = 0
	DirPlane.tick(S, SimConst.DT)
	_expect(f.z != before, "let go, he eases (%.2f)" % f.z)
	SimCore.dispose(S)


func _rush() -> void:
	var S := _sim()
	var a = S.fighters[0]
	var d = S.fighters[1]
	d.z = -600.0
	var r := SimState.Rush.new()
	r.tgt = d
	r.off = 58.0
	r.end = S.T + 20.0 * SimConst.DT
	a.rush = r
	d.state = "down"   # buried, so he holds still and the arrival's depth is plain
	d.embedT = 60
	d.y = WorldTerrain.groundY(S, d.x)
	var ok := false
	for _k in range(25):
		SimCore.step(S)
		S.out.fx.clear()
		S.out.feed.clear()
		if a.rush == null:
			ok = true
			break
	_expect(ok and absf(a.z - d.z) <= 3.0, "a rush arrives at his target's depth, and his own ease has just begun (a %.1f, d %.1f)" % [a.z, d.z])
	SimCore.dispose(S)


func _pair() -> void:
	var S := _sim()
	var a = S.fighters[0]
	var d = S.fighters[1]
	d.x = SimWrap.wrap(a.x + 58.0)
	d.z = -1200.0
	var ex := SimState.Exchange.new()
	ex.A = a
	ex.D = d
	ex.kind = "light"
	ex.tpl = "plane_check"
	ex.branch = ""
	a.state = "locked"
	d.state = "locked"
	var cap: float = float(DirBrawl.cfg().give.closeMaxBh) * DirInterrupt.BH
	S.dirS.ex = ex
	var gap0: float = absf(a.z - d.z)
	DirPlane.tick(S, SimConst.DT)
	_expect(absf(a.z) == cap, "locked, the one nearer the plane follows in at the close's limit (%.1f)" % a.z)
	for _k in range(40):
		DirPlane.tick(S, SimConst.DT)
	_expect(a.z == d.z, "... until the two are level (%.1f, %.1f, from a gap of %.0f)" % [a.z, d.z, gap0])
	for _k in range(70):
		DirPlane.tick(S, SimConst.DT)
	_expect(a.z == 0.0 and d.z == 0.0, "then they come home together")
	S.dirS.ex = null
	SimCore.dispose(S)
