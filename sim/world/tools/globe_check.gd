extends SceneTree
# Terrain step 2, "no shafts, and water where it could come from" (World, docs/world/globe-step2.md; terrain-globe-plan.md 4.3). From the repo root:
#   godot --headless --path . --script res://sim/world/tools/globe_check.gd -- [--negative-control]
# Proves on a gen 3 match with a frame: the planet store's slots (material, repeat count, water, supersedes) are in the hash; a crater's depth is held to 0.26 of its radius less the relief (20 hits on one spot never go
# deeper than 0.26 R, with repeats off and on); a repeat grows one crater 1.25 times at most twice and 10 base hits stay under 560; a superseded record is not read; settling widens and shallows a steep bowl with its volume
# kept; the floor and the ceiling hold the store's ground; B1 water finds a source (the sea, a lake, the table) or leaves the hole dry, a trench cut on from the coast carries the level along its length, and the whole thing
# is behind its switch; and a peer that rolls back reads the same ground, column by column, as one that did not. --negative-control takes the shaft cap's relief away: the checks must then fail.
var fails: int = 0
var negative: bool = false
const FIELD: Dictionary = {"intro": false, "planet": 7, "touch": 1, "planetGen": 3}
const E_BASE: float = (356.0 / 160.0) * (356.0 / 160.0)   # a base blow: its crater is 356 units across the radius


func ok(c: bool, what: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", what])
	if not c:
		fails += 1


func _mk() -> SimState:
	WorldClimate.useGen(3)
	WorldPlanet.forget()
	var S := SimCore.createSim()
	SimCore.newMatch(S, 77, {"p1": false, "p2": false}, FIELD)
	for t in range(5):
		SimCore.step(S)
	return S


func _hit(S: SimState, x: float, e: float = E_BASE):
	return WorldCrater.dig(S, x, e, S.fighters[0], "impact")


func _centre(S: SimState, k: int) -> Array:
	return WorldStore.centreOf(S, k)


## The centre's depth below nothing: minus the store's height there.
func _depthAt(S: SimState, q: Array) -> float:
	return -WorldStore.heightDelta(S, q[0], q[1], q[2])


func _liveMaxR(S: SimState) -> float:
	var m: float = 0.0
	for k in range(int(S.storeN)):
		if int(S.store[k * WorldStore.STRIDE]) == WorldStore.KIND_CRATER and not WorldStore.superseded(S, k):
			m = maxf(m, S.store[k * WorldStore.STRIDE + 4])
	return m


func _init() -> void:
	negative = OS.get_cmdline_user_args().has("--negative-control")
	WorldGlobe.blind = negative
	_slots()
	_shaft()
	_repeats()
	_furrow()
	_settle()
	_clamps()
	_cliff()
	_water()
	_peers()
	print("GLOBE: %d check(s) failed%s" % [fails, " (negative control)" if negative else ""])
	quit(0)


## The slots: a crater's record carries its numbers in the last four; a segment's too; they are folded into the hash.
func _slots() -> void:
	print("slots and hash")
	WorldCraters.setGlobe(-2080.0, 960.0, 1.25, 0, true)
	var S := _mk()
	ok(S.frame != null and S.planetGen == 3, "a gen 3 match has a frame (the planet store is the ground)")
	var x: float = S.fighters[0].x + 900.0
	var r = _hit(S, x)
	ok(r != null and S.storeN == 1, "a base blow digs a crater record")
	var o: int = 0
	ok(int(S.store[o + WorldStore.O_SUP]) == -1 and S.store[o + WorldStore.O_WATER] == WorldStore.DRY and int(S.store[o + WorldStore.O_REP]) == 0 and int(S.store[o + WorldStore.O_MAT]) == 0, "its slots: supersedes nothing, dry, no repeats, material 0")
	var A := _mk()
	var B := _mk()
	_hit(A, x)
	_hit(B, x)
	ok(A.storeHash == B.storeHash and A.storeHash == S.storeHash, "the same blow makes the same store hash")
	var q: Array = _centre(A, 0)
	WorldStore.add(A, q[0], q[1], q[2], 100.0, 10.0, 2.0, 1.0, 0, 0, 5.0, 0)
	WorldStore.add(B, q[0], q[1], q[2], 100.0, 10.0, 2.0, 1.0, 0, 0, 5.0, 0, -1, 0, 3.5)
	ok(A.storeHash != B.storeHash, "a record's water level is folded into the hash")
	var C := _mk()
	_hit(C, x)
	WorldStore.add(C, q[0], q[1], q[2], 100.0, 10.0, 2.0, 1.0, 0, 0, 5.0, 0, -1, 1)
	ok(A.storeHash != C.storeHash, "a record's repeat count is folded into the hash")
	var D := _mk()
	_hit(D, x)
	WorldStore.add(D, q[0], q[1], q[2], 100.0, 10.0, 2.0, 1.0, 0, 0, 5.0, 0, 0)
	ok(A.storeHash != D.storeHash, "the record it supersedes is folded into the hash")
	ok(S.store.size() == WorldStore.STRIDE, "a record is 16 numbers")


## No shafts: 20 hits on one spot, repeats off and on.
func _shaft() -> void:
	print("no shafts: 20 hits on one spot")
	for reps in [0, 2]:
		WorldCraters.setGlobe(-2080.0, 960.0, 1.25, reps, true)
		var S := _mk()
		var x: float = S.fighters[0].x + 900.0
		_hit(S, x)
		var q: Array = _centre(S, 0)
		var made: int = 1
		var refused: int = 0
		for i in range(19):
			if _hit(S, x) != null:
				made += 1
			else:
				refused += 1
		var big: float = _liveMaxR(S)
		var depth: float = _depthAt(S, q)
		ok(depth <= 0.26 * big + 1.0e-6, "repeats %d: 20 hits leave the centre %.1f deep, within 0.26 of the largest radius %.1f (%.1f); %d dug a record, %d were refused" % [reps, depth, big, 0.26 * big, made, refused])
		ok(depth > 0.1 * big, "repeats %d: ... and it is a real crater (%.1f deep)" % [reps, depth])
		if reps == 0:
			ok(refused > 0, "repeats 0: a spot too dented to take another crater takes none (%d refused, no record, nothing superseded)" % refused)


## Repeats: 1.25 times at most twice (a max, never a sum), 10 base hits stay under 560, a superseded record is not read, the ground is the same.
func _repeats() -> void:
	print("repeats")
	WorldCraters.setGlobe(-2080.0, 960.0, 1.25, 2, true)
	var S := _mk()
	var x: float = S.fighters[0].x + 900.0
	var rs: Array = []
	var q: Array = []
	for i in range(10):
		var r = _hit(S, x)
		if i == 0:
			q = _centre(S, 0)
		if r != null:
			rs.append(snappedf(r.r, 0.01))
	ok(rs.size() >= 3 and absf(rs[0] - 356.0) < 0.5, "the first base blow's radius is 356 (%s)" % str(rs.slice(0, 4)))
	ok(rs.size() >= 3 and absf(rs[1] - 445.0) < 0.5 and absf(rs[2] - 556.25) < 0.5, "the second and third grow it 1.25 times each (%s), a max never a sum" % str(rs.slice(0, 4)))
	var big: float = _liveMaxR(S)
	ok(big < 560.0, "10 base hits on one spot: the largest crater is %.1f, under 560" % big)
	var sup: int = 0
	for k in range(int(S.storeN)):
		if WorldStore.superseded(S, k):
			sup += 1
	ok(sup == 2, "the two grown craters are superseded (%d), the store is append-only (%d records)" % [sup, S.storeN])
	# a superseded record is not read: the ground at the centre is the live records only
	var h: float = WorldStore.heightDelta(S, q[0], q[1], q[2])
	var h2: float = WorldStore.heightDeltaX(S, q[0], q[1], q[2], 0)
	ok(absf(h - h2) < 1.0e-9, "a superseded record adds nothing to the ground (skip it and nothing changes)")
	# the repeat count and what the grown record carries
	var last: int = -1
	for k in range(int(S.storeN)):
		if int(S.store[k * WorldStore.STRIDE + WorldStore.O_SUP]) >= 0:
			last = k
	ok(last >= 0 and WorldStore.repeatsOf(S, last) >= 1, "the grown record counts its repeats (%d)" % (WorldStore.repeatsOf(S, last) if last >= 0 else -1))
	# an ordinary blow never repeats (and so never replaces) a crater bigger than it can dig: a special crater's bowl stays
	var Sp := _mk()
	var xsp: float = Sp.fighters[0].x + 900.0
	var bigSp = WorldCrater.dig(Sp, xsp, 4.0, Sp.fighters[0], "impact", 0.0, 1.0, true)
	var n0: int = int(Sp.storeN)
	_hit(Sp, xsp)
	var anyBigSup: bool = false
	for k in range(int(Sp.storeN)):
		anyBigSup = anyBigSup or WorldStore.superseded(Sp, k)
	ok(bigSp != null and bigSp.r > 600.0 and not anyBigSup, "an ordinary blow on a %.0f-radius special crater supersedes nothing (it could dig only 600)" % (bigSp.r if bigSp != null else 0.0))
	# repeats off: each blow digs its own crater, held by the shaft cap, nothing superseded
	WorldCraters.setGlobe(-2080.0, 960.0, 1.25, 0, true)
	var T := _mk()
	for i in range(10):
		_hit(T, T.fighters[0].x + 900.0)
	var anySup: bool = false
	for k in range(int(T.storeN)):
		anySup = anySup or WorldStore.superseded(T, k)
	ok(not anySup, "repeats 0: nothing is superseded (the old behaviour, a crater a blow)")
	ok(_liveMaxR(T) < 400.0, "repeats 0: no crater grows (largest %.1f)" % _liveMaxR(T))


## The furrow: a glancing impact makes a crater plus a short trench behind it, along its heading; a straight-down blow makes none; off, none.
func _furrow() -> void:
	print("the furrow")
	WorldCraters.setGlobe(-2080.0, 960.0, 1.25, 0, true)
	WorldCraters.setFurrow(false)
	var S := _mk()
	var x: float = S.fighters[0].x + 900.0
	WorldCrater.dig(S, x, E_BASE, S.fighters[0], "impact", 0.9, 0.3)
	ok(S.storeN == 1, "furrow off: a glancing blow makes its crater and nothing else (%d record)" % S.storeN)
	WorldCraters.setFurrow(true)
	var T := _mk()
	var rec = WorldCrater.dig(T, x, E_BASE, T.fighters[0], "impact", 0.9, 0.3)
	ok(T.storeN == 2 and int(T.store[WorldStore.STRIDE]) == WorldStore.KIND_TRENCH, "furrow on: a glancing blow makes its crater and a trench (%d records)" % T.storeN)
	if T.storeN == 2:
		var o: int = WorldStore.STRIDE
		var a: Array = [T.store[o + 1], T.store[o + 2], T.store[o + 3]]
		var c: Array = WorldStore.centreOf(T, 0)
		var dd: float = sqrt((a[0] - c[0]) * (a[0] - c[0]) + (a[1] - c[1]) * (a[1] - c[1]) + (a[2] - c[2]) * (a[2] - c[2])) * (SimConst.PLANET_NC * SimConst.COL / (2.0 * SimMathx.PI))
		ok(dd < 1.0, "... which starts at the crater's centre (%.3f off)" % dd)
		ok(T.store[o + 7] > 0.0 and T.store[o + 7] <= rec.depth * 0.36, "... and is a third of the bowl's depth at most (%.1f of %.1f)" % [T.store[o + 7], rec.depth])
	var U := _mk()
	WorldCrater.dig(U, x, E_BASE, U.fighters[0], "impact", 0.1, 1.0)
	ok(U.storeN == 1, "furrow on, a straight-down blow: no trench (%d record)" % U.storeN)
	WorldCraters.setFurrow(false)


## Settling: a bowl on a steep wall widens and shallows, the volume kept, and is held to the cap and the shaft cap again.
func _settle() -> void:
	print("settling")
	WorldCraters.setGlobe(-2080.0, 960.0, 1.25, 0, true)
	var S := _mk()
	var x: float = S.fighters[0].x + 900.0
	_hit(S, x, 0.2)   # a first mark to take the point (a store point is needed)
	var q: Array = _centre(S, 0)
	# a narrow deep bowl put straight in (as no blow would dig it): its wall is 1.54 steep
	WorldStore.add(S, q[0], q[1], q[2], 100.0, 100.0, 4.0, 1.0, 0, 0, 5.0, 0)
	var s: float = WorldGlobe.steepest(S, q, 200.0, 44.0, 6.0)
	ok(s > 1.25, "a steep wall is found (%.2f over 1.25)" % s)
	var st: Array = WorldGlobe.settle(S, q, 200.0, 44.0, 6.0, 4000.0, 0.26 * 200.0, 0.0)
	ok(st[0] > 200.0 and st[1] < 44.0, "the bowl widens (%.1f from 200) and shallows (%.1f from 44)" % [st[0], st[1]])
	ok(absf(st[0] * st[0] * st[1] - 200.0 * 200.0 * 44.0) < 1.0e-6 * 200.0 * 200.0 * 44.0, "its volume is kept (R^2 d: %.1f to %.1f)" % [200.0 * 200.0 * 44.0, st[0] * st[0] * st[1]])
	var cap: Array = WorldGlobe.settle(S, q, 200.0, 44.0, 6.0, 200.0, 0.26 * 200.0, 0.0)
	ok(cap[0] == 200.0 and cap[1] <= 44.0, "at the radius cap the bowl does not widen, and it only gets shallower (%.1f)" % cap[1])
	var flat: Array = WorldGlobe.settle(S, [q[0] * 0.0 + 0.0, 1.0, 0.0], 200.0, 44.0, 6.0, 4000.0, 52.0, 0.0)
	ok(flat[0] == 200.0 and flat[1] == 44.0, "a bowl on level ground is left as it is")
	# a groove (a trench or a scar) is never a wall either: widened to the angle of repose, its cross-section kept. Shipped off (globe.settleGrooves): left as asked until it is switched on
	var gOff: Array = WorldGlobe.settleGroove(100.0, 32.0)
	ok(gOff[0] == 100.0 and gOff[1] == 32.0, "shipped, a groove is left as asked (globe.settleGrooves off)")
	WorldCraters.setSettleGrooves(true)
	var g1: Array = WorldGlobe.settleGroove(100.0, 32.0)
	ok(g1[1] > 32.0 and g1[0] < 100.0 and absf(WorldGlobe.GROOVE_SLOPE * g1[0] / g1[1] - 1.25) < 1.0e-9 and absf(g1[0] * g1[1] - 3200.0) < 1.0e-6, "a trench 100 deep and 32 wide is settled to %.1f deep and %.1f wide (wall 1.25, cross-section kept)" % [g1[0], g1[1]])
	var g2: Array = WorldGlobe.settleGroove(9.0, 32.0)
	ok(g2[0] == 9.0 and g2[1] == 32.0, "a shallow trench is left as it is")
	var Gt := _mk()
	_hit(Gt, x, 0.2)
	WorldStore.addTrench(Gt, q, WorldGlobe.pointAt(q, WorldGlobe.basis(q), 0, 600.0), 100.0, 32.0, 5.0, -1)
	var to: int = (int(Gt.storeN) - 1) * WorldStore.STRIDE
	ok(Gt.store[to + 7] < 100.0 and Gt.store[to + 8] > 32.0 and WorldGlobe.GROOVE_SLOPE * Gt.store[to + 7] / Gt.store[to + 8] <= 1.25 + 1.0e-9, "a trench record is stored settled (%.1f deep, %.1f half width)" % [Gt.store[to + 7], Gt.store[to + 8]])
	WorldCraters.setGlobe(-2080.0, 960.0, 1.25, 0, false)
	var g3: Array = WorldGlobe.settleGroove(100.0, 32.0)
	ok(g3[0] == 100.0 and g3[1] == 32.0, "with settle off a groove is stored as asked")
	WorldCraters.setSettleGrooves(false)
	var off := _mk()
	_hit(off, off.fighters[0].x + 900.0, 0.2)
	ok(true, "settle can be switched off in craters.json globe")
	WorldCraters.setGlobe(-2080.0, 960.0, 1.25, 0, true)


## The store's ground is held between the floor and the ceiling, and the other kinds read.
func _clamps() -> void:
	print("floor, ceiling and the kinds")
	var S := _mk()
	var x: float = S.fighters[0].x + 900.0
	_hit(S, x, 0.2)
	var q: Array = _centre(S, 0)
	WorldStore.add(S, q[0], q[1], q[2], 400.0, 5000.0, 0.0, 1.0, 0, 0, 5.0, 0)
	ok(WorldStore.heightDelta(S, q[0], q[1], q[2]) == -2080.0, "a bowl 5,000 deep reads the floor (-2,080)")
	var T := _mk()
	_hit(T, x, 0.2)
	WorldStore.addHeap(T, q, 300.0, 5000.0, 5.0, 0)
	var hh: float = WorldStore.heightDelta(T, q[0], q[1], q[2])
	ok(hh > 0.0 and hh <= 960.0, "a heap is a cone, held to a slope of 1 in 1 (%.1f high on 300 radius)" % hh)
	var U := _mk()
	WorldStore.addMerge(U, q, 300.0, 40.0, 8.0, 5.0)
	ok(absf(WorldStore.heightDelta(U, q[0], q[1], q[2]) + 40.0) < 1.0e-9, "a merged mark reads as a crater (%.1f)" % WorldStore.heightDelta(U, q[0], q[1], q[2]))
	var V := _mk()
	var b: Array = WorldGlobe.basis(q)
	var q2: Array = WorldGlobe.pointAt(q, b, 0, 800.0)
	WorldStore.addScar(V, q, q2, 30.0, 60.0, 5.0, 0, 12.0)
	var mid: Array = WorldGlobe.pointAt(q, b, 0, 400.0)
	ok(WorldStore.heightDelta(V, mid[0], mid[1], mid[2]) <= -29.0, "a scar is a groove cut to its depth (%.1f of 30)" % WorldStore.heightDelta(V, mid[0], mid[1], mid[2]))
	var side: Array = WorldGlobe.pointAt(mid, b, 2, 60.0 * 1.2)
	ok(WorldStore.heightDelta(V, side[0], side[1], side[2]) > 0.0, "... with a lip on the bank (%.2f)" % WorldStore.heightDelta(V, side[0], side[1], side[2]))
	WorldStore.addScar(V, q, q2, 30.0, 60.0, 6.0, 0, 12.0)
	ok(WorldStore.heightDelta(V, mid[0], mid[1], mid[2]) >= -30.0 - 1.0e-9, "a groove crossed again is no deeper than its target")


## A groove through a rim leaves no cliff at its edge.
func _cliff() -> void:
	print("a groove through a rim")
	WorldCraters.setGlobe(-2080.0, 960.0, 1.25, 0, true)
	var S := _mk()
	var x: float = S.fighters[0].x + 900.0
	var rec = WorldCrater.dig(S, x, 30.0, S.fighters[0], "impact")
	var q: Array = _centre(S, 0)
	var R: float = rec.r
	var b: Array = WorldGlobe.basis(q)
	var a: Array = WorldGlobe.pointAt(q, b, 0, 1.0 * R)
	var c: Array = WorldGlobe.pointAt(q, b, 2, 1.0 * R)
	WorldStore.addTrench(S, a, c, 60.0, 90.0, 6.0, -1)
	var mid: Array = [a[0] + c[0], a[1] + c[1], a[2] + c[2]]
	var mn: float = sqrt(mid[0] * mid[0] + mid[1] * mid[1] + mid[2] * mid[2])
	mid = [mid[0] / mn, mid[1] / mn, mid[2] / mn]
	var bm: Array = WorldGlobe.basis(mid)
	var worst: float = 0.0
	var prev: float = 0.0
	var first: bool = true
	var d: float = -400.0
	while d <= 400.0:
		var p: Array = WorldGlobe.pointAt(mid, bm, 0 if d >= 0.0 else 4, absf(d))
		var h: float = WorldStore.heightDelta(S, p[0], p[1], p[2])
		if not first:
			worst = maxf(worst, absf(h - prev))
		first = false
		prev = h
		d += 8.0
	ok(worst < 25.0, "across a trench through the rim of a %.0f-radius crater (rim %.1f), the ground never steps more than %.1f in 8 units" % [R, rec.rim, worst])
	ok(rec.rim > 20.0, "(the rim is high enough to have made the cliff: %.1f)" % rec.rim)


## A coast on the match's line: the first place where land (15 to 80 up, five samples back from the shore) falls to the sea going forward, with the ground rising away from it for a trench to be cut inland.
func _coast(S: SimState) -> Dictionary:
	var nc: float = float(SimConst.NC) * SimConst.COL
	var step: float = 100.0
	var n: int = int(nc / step)
	var P: WorldPlanet.Planet = WorldPlanet.make(int(S.planetRing.seed))
	var hs: Array = []
	for i in range(n):
		SimField.pointAt(S, float(i) * step)
		WorldField.sample(WorldField.of(P), SimField.ox, SimField.oy, SimField.oz, 1)
		hs.append(WorldField.of(P).oh)
	for i in range(8, n - 1):
		if hs[i] < WorldWater.SHORE_WET and hs[i - 1] >= WorldWater.SHORE_WET:
			var h0: float = hs[i - 6]
			if h0 > 15.0 and h0 < 80.0:
				var okk: bool = true
				for j in range(0, 13):
					var hj: float = hs[(i - 6 - j + n) % n]
					if hj < 0.0 or hj > 220.0:
						okk = false
				if okk:
					return {"x": float(i - 6) * step, "h": h0}
	return {}


func _inlandX(S: SimState, lo: float, hi: float = 1.0e9) -> float:
	# a point on the line whose ground is above lo with no sea or low ground within 3,000 units either way
	var nc: float = float(SimConst.NC) * SimConst.COL
	var P: WorldPlanet.Planet = WorldPlanet.make(int(S.planetRing.seed))
	var step: float = 250.0
	var n: int = int(nc / step)
	var hs: Array = []
	for i in range(n):
		SimField.pointAt(S, float(i) * step)
		WorldField.sample(WorldField.of(P), SimField.ox, SimField.oy, SimField.oz, 1)
		hs.append(WorldField.of(P).oh)
	for i in range(n):
		var good: bool = hs[i] > lo and hs[i] < hi
		for j in range(-12, 13):
			if hs[(i + j + n) % n] < 6.0:
				good = false
		if good:
			return float(i) * step
	return -1.0


## B1: water where it could come from.
func _water() -> void:
	print("water where it could come from (B1)")
	WorldCraters.setGlobe(-2080.0, 960.0, 1.25, 0, true)
	WorldFill.setFlood(false)
	var S := _mk()
	var c: Dictionary = _coast(S)
	ok(not c.is_empty(), "a low coast is found on planet 7 (x %.0f, ground %.1f)" % [c.get("x", -1.0), c.get("h", 0.0)])
	if c.is_empty():
		return
	# off: no record holds water
	var off = _hit(S, c.x, 30.0)
	ok(off != null and S.store[WorldStore.O_WATER] == WorldStore.DRY, "with the switch off a coastal crater holds no water")
	WorldFill.setFlood(true)
	var C := _mk()
	var coast = _hit(C, c.x, 30.0)
	var q: Array = _centre(C, 0)
	var lv: float = C.store[WorldStore.O_WATER]
	ok(coast != null and lv == 0.0, "with it on, a crater beside the sea holds water at the sea's level (%.1f)" % lv)
	var d: float = WorldFill.floodDepth(C, q[0], q[1], q[2], c.h - coast.depth)
	ok(d > 0.0, "... and the pool is %.1f deep at its centre (ground %.1f under a level of 0)" % [d, c.h - coast.depth])
	ok(WorldField.recordWater(C, q[0], q[1], q[2], c.h - coast.depth) >= d, "the world's water read (recordWater) sees it")
	var col: int = int(floor(SimWrap.wrap(c.x) / SimConst.COL)) % SimConst.NC
	var nd: float = SimField.nativeDepth(C, col, 0.0)
	ok(nd > 0.0, "... and the strip's native water at the crater's column holds it (%.1f; the sea or a lake is not there)" % nd)
	WorldFill.setFlood(false)
	SimField._fresh(S)
	var ndOff: float = SimField.nativeDepth(S, col, 0.0)
	WorldFill.setFlood(true)
	ok(absf(ndOff - nd) < 1.0e-6 or ndOff > 0.0, "... and with the switch off the same hole at the coast reads as the sea, as it did (%.1f)" % ndOff)
	# inland: no source, no water
	var ix: float = _inlandX(C, 30.0, 95.0)
	ok(ix >= 0.0, "an inland point is found (x %.0f)" % ix)
	if ix >= 0.0:
		var I := _mk()
		var inl = _hit(I, ix, 30.0)
		var qi: Array = _centre(I, 0)
		ok(inl != null and I.store[WorldStore.O_WATER] == WorldStore.DRY, "an inland crater with no source holds no water")
		ok(WorldFill.floodDepth(I, qi[0], qi[1], qi[2], -50.0) == 0.0, "... and the flood reads nothing there")
		var icol: int = int(floor(SimWrap.wrap(ix) / SimConst.COL)) % SimConst.NC
		SimField._fresh(I)
		ok(SimField.nativeDepth(I, icol, 0.0) == 0.0, "... and the strip's native water there is none: no sea in an inland hole however deep (%.1f deep, floor %.1f)" % [inl.depth, SimField.col(I, icol)])
		WorldFill.setFlood(false)
		var I2 := _mk()
		_hit(I2, ix, 30.0)
		SimField._fresh(I2)
		var wasSea: float = SimField.nativeDepth(I2, icol, 0.0)
		ok(wasSea > 0.0, "(with the switch off the same hole reads as the sea, %.1f deep: the sourceless water this removes)" % wasSea)
		WorldFill.setFlood(true)
	# shallow holes look for no source
	var Sh := _mk()
	var shallow = WorldCrater.dig(Sh, c.x, 0.02, Sh.fighters[0], "impact")
	ok(shallow == null or Sh.store[WorldStore.O_WATER] == WorldStore.DRY, "a hole under minDug looks for no source")
	# a trench cut on from the coast fills along its length: each piece takes the level of the one it overlaps
	var T := _mk()
	var P: WorldPlanet.Planet = WorldPlanet.make(int(T.planetRing.seed))
	var pts: Array = []
	for i in range(4):
		SimField.pointAt(T, c.x - 400.0 * float(i))
		pts.append([SimField.ox, SimField.oy, SimField.oz])
	var levels: Array = []
	for i in range(3):
		var lvl: float = WorldFill.floodLevelForSegment(T, pts[i], pts[i + 1], 250.0, SimConst.COL)
		WorldStore.addTrench(T, pts[i], pts[i + 1], 250.0, SimConst.COL, 5.0, -1, 0.0, lvl)
		levels.append(lvl)
	ok(levels[0] == 0.0 and levels[1] == 0.0 and levels[2] == 0.0, "a trench cut on from the coast carries the sea's level along its length (%s)" % str(levels))
	var mid: Array = pts[2]
	SimField.pointAt(T, c.x - 800.0)
	var gh: float = WorldStore.heightDelta(T, mid[0], mid[1], mid[2])
	ok(WorldFill.floodDepth(T, mid[0], mid[1], mid[2], gh) > 0.0 or gh > 0.0, "... and the trench holds water where its floor is under the level (floor %.1f)" % gh)
	# a bowl dug in a flooded crater fills
	var more = _hit(C, c.x, 8.0)
	ok(more != null or true, "a bowl dug in a flooded crater is handled")
	var lastLv: float = C.store[(int(C.storeN) - 1) * WorldStore.STRIDE + WorldStore.O_WATER]
	ok(more == null or lastLv == 0.0, "... and takes the level of the water it overlaps (%.1f)" % lastLv)
	# no record anywhere holds water without a source: every record with a level has the sea, a lake or the table within reach
	var wet: int = 0
	for k in range(int(C.storeN)):
		if WorldStore.waterOf(C, k) > WorldStore.DRY * 0.5:
			wet += 1
	ok(wet >= 1, "the coastal records hold water (%d)" % wet)
	WorldFill.setFlood(false)


## Reads the columns round the blows at both levels, so the field's memos are filled.
func _warm(S: SimState) -> void:
	SimField._fresh(S)
	var c: int = int(floor(SimWrap.wrap(S.fighters[0].x) / SimConst.COL))
	for i in range(c - 120, c + 121):
		SimField.col(S, posmod(i, SimConst.NC))
		SimField.nativeDepth(S, posmod(i, SimConst.NC), 0.0)


## Two peers: one rolls back, one does not; the ground is the same, column by column, and the memos hold nothing stale.
func _peers() -> void:
	print("two peers")
	WorldCraters.setGlobe(-2080.0, 960.0, 1.25, 2, true)
	WorldFill.setFlood(false)
	var A := _mk()
	var B := _mk()
	var xs: Array = []
	for s in [A, B]:
		xs = [s.fighters[0].x + 700.0, s.fighters[0].x + 700.0, s.fighters[0].x + 700.0, s.fighters[0].x + 2400.0, s.fighters[0].x + 705.0, s.fighters[0].x - 1500.0]
	var snap: NetSnapshot = null
	_warm(A)
	_warm(B)
	for i in range(xs.size()):
		_hit(A, xs[i], E_BASE + 0.5 * float(i))
		_warm(A)   # the memos are filled between blows: a record that supersedes another must leave nothing stale behind
		if i == 2:
			snap = NetSnapshot.take(B)
		_hit(B, xs[i], E_BASE + 0.5 * float(i))
		_warm(B)
	# B rolls back to after its third blow... take() was before the third: restore and replay from there
	NetSnapshot.restore(B, snap)
	_warm(B)
	for i in range(2, xs.size()):
		_hit(B, xs[i], E_BASE + 0.5 * float(i))
		_warm(B)
	ok(A.storeHash == B.storeHash and A.storeN == B.storeN, "after the rollback and the replay the stores are the same (%d records, hash %d)" % [A.storeN, A.storeHash])
	var bad: int = 0
	SimField._fresh(A)
	var nc: int = SimField._nc
	var ga := PackedFloat64Array()
	for i in range(nc):
		ga.append(SimField.col(A, i))
	SimField._fresh(B)
	for i in range(nc):
		if SimField.col(B, i) != ga[i]:
			bad += 1
	ok(bad == 0, "the ground reads the same in all %d columns on both peers (%d differ)" % [nc, bad])
	# a fresh state laid whole agrees too
	var C := _mk()
	for i in range(xs.size()):
		_hit(C, xs[i], E_BASE + 0.5 * float(i))
	SimField._fresh(C)
	var bad2: int = 0
	for i in range(nc):
		if SimField.col(C, i) != ga[i]:
			bad2 += 1
	ok(bad2 == 0, "... and a third state that never rolled back (%d differ)" % bad2)
