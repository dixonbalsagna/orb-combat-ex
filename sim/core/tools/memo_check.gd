extends SceneTree
## The field's memos by place (sim/core/field.gd): godot --headless --path . --script res://sim/core/tools/memo_check.gd
## A record joining the store forgets only the columns and buildings it can reach, so what's left must be what a read would give, to the bit. Everything the memos hold is compared
## with a fresh read: after records of each kind, size and place, including across the strip's wrap, and on every checked tick of an AI fight. A rollback and a second state lay them whole.
## --negative-control puts stale numbers back, and the comparison must see them.

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


## What the memos hold that a fresh read wouldn't: the columns at both levels, the water on them, the buildings at both levels.
func _stale(S: SimState) -> int:
	SimField._fresh(S)
	var bad: int = 0
	var ser: int = SimField._serial
	for i in range(SimField._nc):
		if SimField._s1[i] == ser:
			SimField.pointAt(S, float(i) * SimConst.COL)
			var h1: float = SimField._ground(S, 1)
			if h1 != SimField._m1[i]:
				bad += 1
			if SimField._t1[i] == ser:
				SimField.pointAt(S, float(i) * SimConst.COL)
				if WorldField.recordWater(S, SimField.ox, SimField.oy, SimField.oz, h1) != SimField._w1[i]:
					bad += 1
		if SimField._s0[i] == ser:
			SimField.pointAt(S, float(i) * SimConst.COL)
			var h0: float = SimField._ground(S, SimField._stride)
			if h0 != SimField._m0[i]:
				bad += 1
			if SimField._t0[i] == ser:
				SimField.pointAt(S, float(i) * SimConst.COL)
				if WorldField.recordWater(S, SimField.ox, SimField.oy, SimField.oz, h0) != SimField._w0[i]:
					bad += 1
	if SimField._bKey == S.storeHash ^ (S.get_instance_id() << 8) ^ S.bDir.size():
		for k in SimField._bHave:
			var i: int = int(k) >> 1
			SimField.ox = S.bDir[i * 3]
			SimField.oy = S.bDir[i * 3 + 1]
			SimField.oz = S.bDir[i * 3 + 2]
			if SimField._ground(S, SimField._stride if int(k) & 1 else 1) != SimField._bHave[k]:
				bad += 1
	return bad


## Every memo filled: the coarse ring, the near columns and water around where the record lands, every building at both levels.
func _fill(S: SimState, x: float) -> void:
	SimField._fresh(S)
	SimField.far()
	for c in range(0, SimField._nc, SimField._st):
		SimField.nativeDepth(S, c, 0.0)
	SimField.near()
	var mid: int = int(x / SimConst.COL)
	for c in range(mid - 300, mid + 301):
		SimField.nativeDepth(S, posmod(c, SimField._nc), 0.0)
	for i in range(S.buildings.size()):
		SimField.buildingGround(S, i)
		SimField.far()
		SimField.buildingGround(S, i)
		SimField.near()


func _at(S: SimState, x: float, z: float) -> Array:
	SimField.placeAt(S, x, z)
	return [SimField.ox, SimField.oy, SimField.oz]


func _cold(S: SimState) -> int:
	var n: int = 0
	var ser: int = SimField._serial
	for c in range(0, SimField._nc, SimField._st):
		if SimField._s0[c] != ser:
			n += 1
	return n


## One record of each kind, size and place, against every memo. The serial must stand still, and few columns go cold.
func _records() -> void:
	var S := _new(false)
	var x0: float = S.fighters[0].x
	var wrap: float = SimWrap.wrap(S.frame.x0 + SimConst.W * 0.5)
	var cases: Array = []
	for at in [x0, wrap, 16.0, SimConst.W - 16.0]:
		for z in [0.0, 200.0, -900.0, 5000.0]:
			for r in [40.0, 300.0, 1500.0]:
				cases.append(["crater", at, z, r])
			cases.append(["scorch", at, z, 90.0])
			cases.append(["trench", at, z, 60.0])
			cases.append(["crack", at, z, 24.0])
	var worstCold: int = 0
	var bad: int = 0
	var ser0: int = 0
	var bound: int = 0
	for cs in cases:
		_fill(S, float(cs[1]))
		ser0 = SimField._serial
		var q: Array = _at(S, float(cs[1]), float(cs[2]))
		var e: Array = _at(S, SimWrap.wrap(float(cs[1]) + 700.0), float(cs[2]) + 150.0)
		var r: float = float(cs[3])
		match String(cs[0]):
			"crater":
				WorldStore.add(S, q[0], q[1], q[2], r, r * 0.3, r * 0.1, 1.0, 0, 0, 0.0, 0)
			"scorch":
				WorldStore._push(S, [WorldStore.KIND_SCORCH, q[0], q[1], q[2], r, 12.0, 1.0, 0.0, 0])
			"trench":
				WorldStore.addTrench(S, q, e, 20.0, r, 0.0, 0)
			"crack":
				WorldStore.addCrack(S, q, e, 1.0, r, 0.0, 0)
		SimField._fresh(S)
		if SimField._serial != ser0:
			bound += 1
		worstCold = maxi(worstCold, _cold(S))
		bad += _stale(S)
	print("records: %d cases, %d stale, %d laid whole, at most %d of %d coarse columns cold" % [cases.size(), bad, bound, worstCold, SimField._nc / SimField._st])
	ok(bad == 0, "what a record can't reach is what a read gives (%d stale)" % bad)
	ok(bound == 0, "no record lays the memos whole (%d)" % bound)
	ok(worstCold < SimField._nc / SimField._st / 4, "a record leaves most of the ring warm (%d cold)" % worstCold)
	SimCore.dispose(S)


## An AI fight: every memo against a fresh read, every 4th tick, and the binds it took against the records.
func _fight(su: Dictionary) -> void:
	var S := _new(true, su)
	var bad: int = 0
	var n0: int = S.storeN
	var b0: int = SimField._serial
	var checks: int = 0
	var worst: int = 0
	for t in range(3000):
		SimCore.step(S)
		S.out.fx.clear()
		S.out.feed.clear()
		if t % 4 == 0:
			var a: int = _stale(S)
			bad += a
			checks += 1
			if a > 0 and worst == 0:
				worst = t
	print("fight planet %d: %d ticks checked, %d stale (first %d); %d records, %d binds" % [int(su.planet), checks, bad, worst, S.storeN - n0, SimField._serial - b0])
	ok(bad == 0, "planet %d: an AI fight's memos are what a read gives (%d stale, first at tick %d)" % [int(su.planet), bad, worst])
	ok(S.storeN - n0 > 0, "planet %d: it wrote records" % int(su.planet))
	SimCore.dispose(S)


## A rollback across records and a second state on another history: the memos are laid again, and they're right.
func _forks() -> void:
	var A := _new(false)
	var x: float = A.fighters[0].x
	_fill(A, x)
	var snap: NetSnapshot = NetSnapshot.take(A)
	var q: Array = _at(A, x, 0.0)
	WorldStore.add(A, q[0], q[1], q[2], 300.0, 90.0, 30.0, 1.0, 0, 0, 0.0, 0)
	var after: float = SimField.col(A, int(x / SimConst.COL))
	NetSnapshot.restore(A, snap)
	var back: float = SimField.col(A, int(x / SimConst.COL))
	ok(back != after, "a rollback across a crater reads the ground without it (%.3f, %.3f)" % [back, after])
	ok(_stale(A) == 0, "and every memo is right")
	var B := _new(false)   # the same match, another state
	_fill(A, x)
	q = _at(B, x + 40.0, 0.0)
	WorldStore.add(B, q[0], q[1], q[2], 200.0, 60.0, 20.0, 1.0, 0, 0, 0.0, 0)   # B's history moves on, A's stands
	ok(_stale(B) == 0, "a second state's record: its memos are right")
	ok(_stale(A) == 0, "and the first's, read after it")
	q = _at(A, x - 60.0, 0.0)
	WorldStore.add(A, q[0], q[1], q[2], 200.0, 60.0, 20.0, 1.0, 0, 0, 0.0, 0)   # A's own, on another history
	ok(_stale(A) == 0, "the first's own record")
	ok(_stale(B) == 0, "and the second's, read after it")
	SimCore.dispose(A)
	SimCore.dispose(B)


## The break: the numbers from before a record, put back. The comparison must see them.
func _negative() -> void:
	var S := _new(false)
	var x: float = S.fighters[0].x
	_fill(S, x)
	var s1: PackedInt32Array = SimField._s1.duplicate()
	var s0: PackedInt32Array = SimField._s0.duplicate()
	var q: Array = _at(S, x, 0.0)
	var have: Dictionary = SimField._bHave.duplicate()
	WorldStore.add(S, q[0], q[1], q[2], 600.0, 180.0, 60.0, 1.0, 0, 0, 0.0, 0)
	SimField._fresh(S)
	ok(_stale(S) == 0, "clean before the break")
	SimField._s1 = s1
	SimField._s0 = s0
	var bad: int = _stale(S)
	print("negative: columns put back, %d stale" % bad)
	ok(bad > 0, "stale columns are seen")
	var S2 := _new(false)
	_fill(S2, x)
	have = SimField._bHave.duplicate()
	q = _at(S2, S2.buildings[0].x, S2.buildings[0].z)
	WorldStore.add(S2, S2.bDir[0], S2.bDir[1], S2.bDir[2], 600.0, 180.0, 60.0, 1.0, 0, 0, 0.0, 0)
	SimField._fresh(S2)
	SimField._bHave = have
	var bb: int = _stale(S2)
	print("negative: buildings put back, %d stale" % bb)
	ok(bb > 0, "stale buildings are seen")
	SimCore.dispose(S)
	SimCore.dispose(S2)
	print("MEMO negative control: %d check(s) failed" % fails)
	quit(1 if fails > 0 else 0)


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "--negative-control":
			negative = true
	WorldClimate.useGen(3)
	if negative:
		_negative()
		return
	_records()
	_forks()
	_fight(FIELD)
	_fight({"intro": false, "planet": 12, "touch": 1, "planetGen": 3})
	print("MEMO: %d check(s) failed" % fails)
	quit(1 if fails > 0 else 0)
