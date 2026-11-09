extends SceneTree
## The launch cuts (docs/design/buildings.md section 8; docs/director/pending/launch-cuts/; launch.json aimCuts, off).
##   godot --headless --path . --script res://sim/director/tools/launch_cuts_check.gd
## - the cap: at most aimMax buildings, the best by World's cheap score, at least one a side when each side has one
## - one flight an arc (World's aimShared, when its grant is in): every building's plan the same as aim's, on a flat world
## - the cost: chooseLaunch timed off and on (printed)
## Ends on the verdict line.

var failed: int = 0


func _init() -> void:
	_cap()
	_shared()
	_cost()
	DirLaunch.setCutsForce(-1)
	print("LAUNCH CUTS: %d check(s) failed" % failed)
	quit(1 if failed > 0 else 0)


func _expect(ok: bool, what: String) -> void:
	print(("ok    " if ok else "FAIL  ") + what)
	if not ok:
		failed += 1


## A match with the pair over the densest stretch of buildings: [S, the x it found].
func _town(seed: int, setup: Dictionary, k: int = 0) -> Array:
	var S := SimCore.createSim()
	SimCore.newMatch(S, seed, {"p1": false, "p2": false}, setup)
	for _i in range(3):
		SimCore.step(S, [null, null])
	var best: float = -1.0
	var bx: float = 0.0
	var xs: Array = []
	for b in S.buildings:
		if b.alive:
			xs.append(float(b.x))
	for i in range(0, xs.size(), 3):
		var n: int = 0
		for x2 in xs:
			if absf(SimWrap.sdx(float(xs[i]), float(x2))) < 900.0 * SimConst.WS:
				n += 1
		if n > best:
			best = n
			bx = float(xs[i])
	return [S, SimWrap.wrap(bx + float(k) * 37.0 * SimConst.WS)]


## The pair at x: D there in the air, A a step behind him, at tier and care.
func _place(S: SimState, x: float, tier: float, care: float, up: float = 220.0) -> void:
	var A = S.fighters[0]
	var D = S.fighters[1]
	D.x = x
	D.y = WorldTerrain.groundY(S, x) + up
	A.x = SimWrap.wrap(x - 60.0)
	A.y = D.y
	A.face = 1.0
	A.tier = tier
	A.care = care
	for f in [A, D]:
		f.vx = 0.0
		f.vy = 0.0
		f.state = "free"


func _cap() -> void:
	var r: Array = _town(11, {"intro": false})
	var S: SimState = r[0]
	var D = S.fighters[1]
	var popRef: float = WorldStructures.buildingMassRef(S)
	var seen: int = 0
	var good: int = 0
	for k in range(40):
		_place(S, SimWrap.wrap(float(r[1]) + float(k - 20) * 41.0 * SimConst.WS), 2.0, 0.0)
		var cands: Array = WorldBrunt.candidates(S, D)
		if cands.size() <= int(DirLaunch.cutsCfg().get("aimMax", 3)):
			continue
		seen += 1
		var kept: Array = DirLaunch._capAimed(S, D, cands)
		var sides: Array = [0, 0]
		var side: Dictionary = {}
		for bi in cands:
			var sd: int = 0 if SimWrap.sdx(D.x, S.buildings[bi].x) < 0.0 else 1
			side[bi] = sd
			sides[sd] += 1
		var ok: bool = kept.size() == int(DirLaunch.cutsCfg().get("aimMax", 3))
		var ks: Array = [0, 0]
		for bi in kept:
			ks[side[bi]] += 1
			ok = ok and cands.has(bi)
		if sides[0] > 0 and sides[1] > 0:
			ok = ok and ks[0] >= 1 and ks[1] >= 1
		# every building left out scores no better than the worst kept on its own side, or the side rule took its place
		var worstKept: float = INF
		for bi in kept:
			worstKept = minf(worstKept, WorldBrunt._cheap(S, S.buildings[bi], popRef))
		for bi in cands:
			if not kept.has(bi):
				var cs: float = WorldBrunt._cheap(S, S.buildings[bi], popRef)
				var sideKeptMin: float = INF
				for bj in kept:
					if side[bj] == side[bi]:
						sideKeptMin = minf(sideKeptMin, WorldBrunt._cheap(S, S.buildings[bj], popRef))
				ok = ok and (cs <= sideKeptMin or cs <= worstKept)
		# the order is World's
		var last: int = -1
		for bi in kept:
			var at: int = cands.find(bi)
			ok = ok and at > last
			last = at
		if ok:
			good += 1
	print("      %d places with more than 3 candidates" % seen)
	_expect(seen > 0 and good == seen, "the cap keeps 3, the best by the cheap score, at least one a side, in World's order (%d of %d)" % [good, seen])
	SimCore.dispose(S)


## World's aimShared against aim, building by building, on a flat world.
func _shared() -> void:
	var f := Callable(WorldBrunt, "aimShared")
	if not f.is_valid():
		print("      (World's aimShared isn't in: skipped)")
		return
	var r: Array = _town(13, {"intro": false})
	var S: SimState = r[0]
	var A = S.fighters[0]
	var D = S.fighters[1]
	var n: int = 0
	var plans: int = 0
	var same: int = 0
	for k in range(60):
		_place(S, SimWrap.wrap(float(r[1]) + float(k - 30) * 29.0 * SimConst.WS), 1.0 + float(k % 4), 0.0, 120.0 + float(k % 5) * 90.0)
		var cands: Array = WorldBrunt.candidates(S, D)
		for force in [900.0, 1600.0, 2600.0]:
			var sh: Dictionary = f.call(S, A, D, cands, force, 1.0, false)
			for bi in cands:
				var one = WorldBrunt.aim(S, A, D, S.buildings[bi], force, 1.0, false)
				n += 1
				if one != null:
					plans += 1
				if JSON.stringify(one) == JSON.stringify(sh.get(bi, "missing")):
					same += 1
	print("      depth on: %s; %d aims, %d plans" % [str(S.depthOn), n, plans])
	_expect(n > 0 and plans > 0 and same == n, "one flight an arc gives every building the plan aim gives it (%d of %d)" % [same, n])
	SimCore.dispose(S)


## The cost: chooseLaunch over the same launches, off and on (printed, not a check).
func _cost() -> void:
	for setup in [{"intro": false}, {"intro": false, "planet": 7, "touch": 1, "planetGen": 3}]:
		var us: Array = [0, 0]
		var sims: Array = [_town(23, setup), _town(23, setup)]
		for k in range(40):
			for on in [0, 1]:
				var S: SimState = sims[on][0]
				DirLaunch.setCutsForce(on)
				_place(S, SimWrap.wrap(float(sims[on][1]) + float(k - 20) * 33.0 * SimConst.WS), 1.0 + float(k % 4), [1.0, 0.0, -1.0][k % 3], 160.0)
				var t0: int = Time.get_ticks_usec()
				DirLaunch.chooseLaunch(S, S.fighters[0], S.fighters[1], 1600.0)
				us[on] += Time.get_ticks_usec() - t0
		for sm in sims:
			SimCore.dispose(sm[0])
		print("      chooseLaunch, 40 launches over a town on %s (depth off): off %.2f ms, on %.2f ms a launch" % ["a gen-3 planet" if setup.has("planetGen") else "a flat ring", float(us[0]) / 40000.0, float(us[1]) / 40000.0])
	DirLaunch.setCutsForce(-1)
