extends SceneTree
## The planet's height ceiling (SimField.planetCeilAt): godot --headless --path . --script res://sim/core/tools/ceil_check.gd
## It must be a true upper bound: never under groundCeilAt on any line, and never under a far read of the ground or the sea it stands for. Tried in AI fights on the line and on turned
## lines, after craters with rims, across a rollback and on a second state. A match hashes the same with the table on or off. --negative-control breaks the bound three ways and the
## comparison must see each.

var fails: int = 0
var negative: bool = false
const FIELD: Dictionary = {"intro": false, "planet": 7, "touch": 1, "planetGen": 3}


func ok(c: bool, what: String) -> void:
	if not c:
		fails += 1
		print("FAIL  " + what)


func _new(ai: bool, su: Dictionary = FIELD) -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 77, {"p1": ai, "p2": ai}, su)
	return S


## A stretch it says something for, near the fight, and the point at its middle.
func _said(S: SimState) -> int:
	var n: int = int(SimField.data().ceilCols)
	var c0: int = int(S.fighters[0].x / SimConst.COL) / n * n
	for k in range(SimConst.NC / n):
		var c: int = posmod(c0 + k * n, SimConst.NC)
		if SimField.planetCeilAt(S, c) != INF:
			return c
	return -1


## The table whole, now.
func _ready_(S: SimState) -> void:
	SimField._fresh(S)
	WorldField.bakeStep(SimField._F, 1 << 40)
	for k in range(6000):
		SimField._ceilStep(S, 64)
		if SimField._ctK >= 6 * SimField._ctN * SimField._ctN and SimField._crI >= SimField._crN:
			break


## Every stretch of the line S is on: [stretches it says something for, under groundCeilAt, under a far read, the worst of those].
func _walk(S: SimState, step: int = 1) -> Array:
	var n: int = int(SimField.data().ceilCols)
	var said: int = 0
	var underC: int = 0
	var underR: int = 0
	var worst: float = 0.0
	var slack: float = 0.0
	var c: int = 0
	var low: int = 0
	while c < SimConst.NC:
		var b: float = SimField.planetCeilAt(S, c)
		if b != INF:
			said += 1
			SimField.far()
			var e: float = SimField.groundCeilAt(S, c)
			if b < e:
				underC += 1
				worst = maxf(worst, e - b)
			slack += b - e
			var k: int = 0
			while k < n:
				var x: float = float(c + k) * SimConst.COL
				var top: float = maxf(WorldTerrain.groundY(S, x), WorldWater.seaTop(S, x))
				if top > b:
					underR += 1
					worst = maxf(worst, top - b)
				k += step
			SimField.near()
		low += 1
		c += n
	return [said, underC, underR, worst, low, slack / float(maxi(said, 1))]


func _turned(S: SimState, deg: float, f: Callable) -> Array:
	var was = S.frame
	var fr = S.frame.copy()
	SimSwing._applyTurn(fr, S.fighters[0].x, deg)
	S.frame = fr
	var out: Array = f.call()
	S.frame = was
	return out


## AI fights, swings on: the line and three turned lines, again and again as the store grows.
func _fights(su: Dictionary) -> void:
	DirSwing.setForce(1)
	var S := _new(true, su)
	_ready_(S)
	var said: int = 0
	var all: int = 0
	var underC: int = 0
	var underR: int = 0
	var worst: float = 0.0
	var slack: float = 0.0
	var walks: int = 0
	for t in range(2400):
		SimCore.step(S)
		S.out.fx.clear()
		S.out.feed.clear()
		if t % 120 == 0:
			var lines: Array = [_walk(S, 8)]
			for deg in [17.0, -41.0, 88.0]:
				lines.append(_turned(S, deg, func(): return _walk(S, 8)))
			for r in lines:
				said += r[0]
				underC += r[1]
				underR += r[2]
				worst = maxf(worst, r[3])
				all += r[4]
				slack += r[5]
				walks += 1
	print("fight planet %d: %d of %d stretches said, %d under the read's ceiling, %d under a far read, worst %.3f; it stands %.0f above the read's ceiling on average; %d records" % [int(su.planet), said, all, underC, underR, worst, slack / float(maxi(walks, 1)), S.storeN])
	ok(underC == 0 and underR == 0, "planet %d: a true upper bound in a fight (%d, %d, worst %.3f)" % [int(su.planet), underC, underR, worst])
	ok(said > all / 2, "planet %d: it says something over most of the planet (%d of %d)" % [int(su.planet), said, all])
	SimCore.dispose(S)
	DirSwing.setForce(-1)


## Craters with rims, big and small, stacked on one place and at the highest ground near: the bound moves up with them, and a rollback takes it down again, still true.
func _craters() -> void:
	var S := _new(false)
	_ready_(S)
	var col: int = _said(S)
	ok(col >= 0, "it says something somewhere")
	var x: float = float(col + 32) * SimConst.COL
	var b0: float = SimField.planetCeilAt(S, col)
	var snap: NetSnapshot = NetSnapshot.take(S)
	SimField.placeAt(S, x, 0.0)
	var q: Array = [SimField.ox, SimField.oy, SimField.oz]
	for rim in [40.0, 400.0, 900.0, 900.0, 2500.0]:
		WorldStore.add(S, q[0], q[1], q[2], 500.0, 100.0, rim, 1.0, 0, 0, 0.0, 0)
		var r: Array = _walk(S, 4)
		ok(r[1] == 0 and r[2] == 0, "true after a rim of %.0f (%d, %d, worst %.3f)" % [rim, r[1], r[2], r[3]])
	var b1: float = SimField.planetCeilAt(S, col)
	ok(b1 > b0 + 4000.0, "the rims lift it (%.0f to %.0f)" % [b0, b1])
	NetSnapshot.restore(S, snap)
	ok(SimField.planetCeilAt(S, col) == b0, "a rollback takes them off (%.0f, %.0f)" % [SimField.planetCeilAt(S, col), b0])
	var r2: Array = _walk(S, 4)
	ok(r2[1] == 0 and r2[2] == 0, "true after the rollback (%d, %d)" % [r2[1], r2[2]])
	WorldStore.add(S, q[0], q[1], q[2], 500.0, 100.0, 1500.0, 1.0, 0, 0, 0.0, 0)
	var r3: Array = _walk(S, 4)
	ok(r3[1] == 0 and r3[2] == 0, "true after a crater on the rolled back store (%d, %d)" % [r3[1], r3[2]])
	# a second state, its store its own
	var B := _new(false)
	_ready_(B)
	var r4: Array = _walk(B, 8)
	ok(r4[1] == 0 and r4[2] == 0, "true on a second state (%d, %d)" % [r4[1], r4[2]])
	var r5: Array = _walk(S, 8)
	ok(r5[1] == 0 and r5[2] == 0, "and on the first, read after it (%d, %d)" % [r5[1], r5[2]])
	SimCore.dispose(S)
	SimCore.dispose(B)


## With the table on, off, or half built, one hash; and a rollback across a launch.
func _sameHash() -> void:
	var run := func(mode: int) -> String:
		var A := _new(true)
		if mode == 2:
			_ready_(A)
		else:
			SimField._fresh(A)
			WorldField.bakeStep(SimField._F, 1 << 40)
		if mode == 0:
			SimField._ctF = null
			SimField._crW = -1
		var keep: int = 0 if mode == 0 else 1
		for t in range(2400):
			if keep == 0:
				SimField._ctF = null
				SimField._crW = -1
			SimCore.step(A)
			A.out.fx.clear()
			A.out.feed.clear()
		var h: String = str(SimHash.stateHash(A).gameplay)
		SimCore.dispose(A)
		return h
	DirSwing.setForce(1)
	var a: String = run.call(1)
	var b: String = run.call(2)
	var c: String = run.call(0)
	print("hash: as it fills %s, whole from the start %s, never there %s" % [a, b, c])
	ok(a == b and b == c, "the table changes nothing in a match")
	var S := _new(true)
	_ready_(S)
	var snap: NetSnapshot = null
	var hs: Array = []
	for t in range(1500):
		if t == 800:
			snap = NetSnapshot.take(S)
		SimCore.step(S)
		S.out.fx.clear()
		S.out.feed.clear()
		if t >= 800:
			hs.append(str(SimHash.stateHash(S).gameplay))
	NetSnapshot.restore(S, snap)
	var bad: int = 0
	for t in range(hs.size()):
		SimCore.step(S)
		S.out.fx.clear()
		S.out.feed.clear()
		if str(SimHash.stateHash(S).gameplay) != hs[t]:
			bad += 1
	print("rollback: %d ticks, %d differ" % [hs.size(), bad])
	ok(bad == 0, "a rollback across fights is the same (%d differ)" % bad)
	SimCore.dispose(S)
	DirSwing.setForce(-1)


## The breaks: rims forgotten, the table cut, the records dropped. Each must show.
func _negative() -> void:
	var S := _new(false)
	_ready_(S)
	var x: float = float(_said(S) + 32) * SimConst.COL
	SimField.placeAt(S, x, 0.0)
	var q: Array = [SimField.ox, SimField.oy, SimField.oz]
	WorldStore.add(S, q[0], q[1], q[2], 500.0, 100.0, 6000.0, 1.0, 0, 0, 0.0, 0)
	ok(_walk(S, 4)[2] == 0, "clean before the breaks")
	SimField._rise.clear()
	var a: Array = _walk(S, 4)
	print("negative: rims forgotten, %d under the read's ceiling, %d under a read" % [a[1], a[2]])
	ok(a[1] > 0 and a[2] > 0, "forgotten rims are seen")
	SimField._riseBuild(S)
	ok(_walk(S, 4)[2] == 0, "clean again")
	var keep: PackedFloat32Array = SimField._ct.duplicate()
	for i in range(SimField._ct.size()):
		SimField._ct[i] -= 1500.0
	var b: Array = _walk(S, 4)
	print("negative: the table cut, %d under the read's ceiling, %d under a read" % [b[1], b[2]])
	ok(b[1] > 0 and b[2] > 0, "a cut table is seen")
	SimField._ct = keep
	var S2 := _new(false)
	_ready_(S2)
	SimField._cr.clear()
	for i in range(SimField._ct.size()):
		SimField._ct[i] -= 300.0
	var c: Array = _walk(S2, 4)
	print("negative: the records dropped and the table cut a little, %d under the read's ceiling, %d under a read" % [c[1], c[2]])
	ok(c[1] > 0, "dropped records are seen")
	SimField._ctF = null
	SimCore.dispose(S)
	SimCore.dispose(S2)
	print("CEIL negative control: %d check(s) failed" % fails)
	quit(1 if fails > 0 else 0)


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "--negative-control":
			negative = true
	WorldClimate.useGen(3)
	if negative:
		_negative()
		return
	_craters()
	_fights(FIELD)
	_fights({"intro": false, "planet": 12, "touch": 1, "planetGen": 3})
	_sameHash()
	print("CEIL: %d check(s) failed" % fails)
	quit(1 if fails > 0 else 0)
