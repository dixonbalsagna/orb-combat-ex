extends SceneTree
## The flight strike's arc as a true loop (SimFighter.loopRush; Game Design's docs/design/playable-build.md section 1):
##   godot --headless --path . --script res://sim/core/tools/loop_check.gd
## With the arc's numbers (its top 1.3 bh over his head, its centre 0.5 bh up, 24 ticks, Legal's floor of 4 ticks and 3 bh a
## tick), from up close and from the band's edge, in the air and on the ground, over and under, on a flat world and a field one:
## - it takes the ticks asked, never fewer than the floor, and never moves more than 3 bh in a tick
## - it ends at his far side, behind him, at the centre's height (on a fighter on the ground, under is a low sweep held by it)
## - at loopApex it's at the top (over) or the bottom (under), and through the loop it keeps the circle's radius from him: over
##   him, never through him
## - it follows him as he moves
## - two runs, one path; a rollback in the middle of a loop runs it the same
## --negative-control drops the loop's half circle (it rushes straight through him), and the checks have to see it.

var fails: int = 0
var BH: float = 75.0
const FIELD: Dictionary = {"intro": false, "planet": 7, "touch": 1, "planetGen": 3}
const FLAT: Dictionary = {"intro": false}


func ok(c: bool, what: String) -> void:
	if not c:
		fails += 1
		print("FAIL  " + what)


func _new(world: Dictionary) -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 77, {"p1": false, "p2": false}, world)
	for t in range(30):
		SimCore.step(S)
		S.out.fx.clear()
		S.out.feed.clear()
	return S


## A loop by p1 round p2 from d along the line (signed) and h over his feet. walk: p2 moves this far a tick. Returns what it saw.
func _run(world: Dictionary, d: float, h: float, over: bool, ticks: int, walk: float = 0.0) -> Dictionary:
	var S := _new(world)
	var A = S.fighters[0]
	var D = S.fighters[1]
	A.x = SimWrap.wrap(D.x + d)
	A.y = D.y + h
	A.vx = 0.0
	A.vy = 0.0
	var top: float = 2.3 * BH
	var mid: float = 0.5 * BH
	var n: int = SimFighter.loopRush(S, A, D, over, top, mid, ticks, 4, 3.0 * BH)
	var apex: float = SimFighter.loopApex(A)
	var lu: float = A.rush.lu
	var side: float = A.rush.ls
	var lr: float = A.rush.lr
	var px: float = A.x
	var py: float = A.y
	var most: float = 0.0
	var arrived: int = -1
	var apexY: float = 0.0
	var apexGap: float = INF
	var nearest: float = INF   # the least distance from his centre through the half circle
	var path: Array = []
	for t in range(n + 6):
		if walk != 0.0 and A.rush != null:
			D.x = SimWrap.wrap(D.x + walk)
		var u0: float = SimFighter.rushU(S, A)
		SimCore.step(S)
		S.out.fx.clear()
		S.out.feed.clear()
		var step: float = SimDetMath.hypot(SimWrap.sdx(px, A.x), A.y - py)
		if arrived < 0:
			most = maxf(most, step)
		px = A.x
		py = A.y
		path.append([A.x, A.y])
		if arrived < 0 and A.rush == null:
			arrived = t + 1
		if arrived < 0 and absf(S.T - apex) < apexGap:
			apexGap = absf(S.T - apex)
			apexY = A.y - D.y
		if arrived < 0 and A.rush != null and SimFighter.rushU(S, A) > lu + 0.02:
			var gx: float = SimWrap.sdx(D.x, A.x)
			var gy: float = A.y - (D.y + mid)
			if A.y > SimFighter.floorFor(S, A, A.x, A.z) + 1.0:   # where the ground holds an under loop up, it's the ground's
				nearest = minf(nearest, SimDetMath.hypot(gx, gy))
	var end: Dictionary = {"n": n, "arrived": arrived, "most": most, "apexY": apexY, "nearest": nearest, "lr": lr,
		"side": side, "endX": SimWrap.sdx(D.x, A.x), "endY": A.y - D.y, "path": path, "floor": SimFighter.floorFor(S, A, A.x, A.z) - D.y}
	SimCore.dispose(S)
	return end


func _cases(world: Dictionary, name: String) -> void:
	var top: float = 2.3 * BH
	var mid: float = 0.5 * BH
	for c in [[1.5, 3.0, "up close, in the air"], [12.0, 3.0, "from the band's edge, in the air"], [-2.0, 3.0, "from his other side"]]:
		for over in [true, false]:
			var d: float = float(c[0]) * BH
			var r: Dictionary = _run(world, d, float(c[1]) * BH, over, 24)
			var what: String = "%s, %s, %s" % [name, c[2], "over" if over else "under"]
			ok(r.arrived == r.n and r.n >= 24, "%s: it takes the ticks asked (%d of %d)" % [what, r.arrived, r.n])
			ok(r.most <= 3.0 * BH + 0.01, "%s: never more than 3 bh a tick (%.1f)" % [what, r.most / BH])
			ok(signf(r.endX) == -r.side and absf(absf(r.endX) - r.lr) < 1.0, "%s: it ends at his far side, behind him (%.1f bh)" % [what, r.endX / BH])
			ok(absf(r.endY - maxf(mid, r.floor)) < 1.0, "%s: ... at the centre's height (%.1f bh)" % [what, r.endY / BH])
			var want: float = top if over else maxf(mid - (top - mid), r.floor)
			ok(absf(r.apexY - want) <= 0.35 * BH, "%s: at its apex it's at the %s (%.2f bh, %.2f wanted)" % [what, "top" if over else "bottom", r.apexY / BH, want / BH])
			ok(r.nearest >= r.lr - 1.0, "%s: through the loop it keeps the circle from him, never through him (%.2f of %.2f bh)" % [what, r.nearest / BH, r.lr / BH])
	# on the ground, under: a low sweep held by the ground
	var g: Dictionary = _run(world, 2.0 * BH, 0.0, false, 24)
	ok(g.arrived == g.n and signf(g.endX) == -g.side, "%s: under, on the ground: a low sweep round him to his far side" % name)
	# Legal's floor: asked for 1 tick, it takes at least 4 and at most 3 bh a tick
	var f: Dictionary = _run(world, 12.0 * BH, 2.0 * BH, true, 1)
	ok(f.n >= 4 and f.arrived == f.n and f.most <= 3.0 * BH + 0.01, "%s: asked for 1 tick, Legal's floor holds (%d ticks, %.1f bh a tick)" % [name, f.n, f.most / BH])
	# it follows him: he walks 6 units a tick through the loop
	var w: Dictionary = _run(world, 4.0 * BH, 3.0 * BH, true, 24, 6.0)
	ok(signf(w.endX) == -w.side and absf(absf(w.endX) - w.lr) < 1.0, "%s: it follows him as he moves, and ends behind him (%.1f bh)" % [name, w.endX / BH])


## Two runs one path, and a rollback from the middle of a loop runs the rest the same, by hash.
func _again() -> void:
	var a: Dictionary = _run(FIELD, 6.0 * BH, 2.0 * BH, true, 24)
	var b: Dictionary = _run(FIELD, 6.0 * BH, 2.0 * BH, true, 24)
	ok(a.path == b.path, "two runs, one path")
	var S := _new(FIELD)
	var A = S.fighters[0]
	var D = S.fighters[1]
	A.x = SimWrap.wrap(D.x + 6.0 * BH)
	A.y = D.y + 2.0 * BH
	var n: int = SimFighter.loopRush(S, A, D, true, 2.3 * BH, 0.5 * BH, 24, 4, 3.0 * BH)
	for t in range(10):
		SimCore.step(S)
		S.out.fx.clear()
		S.out.feed.clear()
	var snap: NetSnapshot = NetSnapshot.take(S)
	var hs: Array = []
	for t in range(n):
		SimCore.step(S)
		S.out.fx.clear()
		S.out.feed.clear()
		hs.append(str(SimHash.stateHash(S).gameplay))
	NetSnapshot.restore(S, snap)
	var differ: int = 0
	for t in range(n):
		SimCore.step(S)
		S.out.fx.clear()
		S.out.feed.clear()
		if str(SimHash.stateHash(S).gameplay) != hs[t]:
			differ += 1
	ok(differ == 0, "a rollback from the middle of a loop: %d ticks, %d differ" % [n, differ])
	SimCore.dispose(S)


func _init() -> void:
	BH = DirInterrupt.BH
	var neg: bool = OS.get_cmdline_user_args().has("--negative-control")
	SimFighter.loopBlind = neg
	_cases(FLAT, "flat")
	_cases(FIELD, "field")
	_again()
	SimFighter.loopBlind = false
	if neg:
		var seen: int = fails
		fails = 0
		ok(seen > 0, "the negative control's loop with no half circle is seen (%d checks)" % seen)
		print("LOOP negative control: %d check(s) failed" % fails)
	else:
		print("LOOP: %d check(s) failed" % fails)
	quit(1 if fails > 0 else 0)
