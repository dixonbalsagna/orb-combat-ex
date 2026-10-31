extends SceneTree
# The planet store's craters (World, sim/world/store.gd) on a state-shaped stand-in (S.store, S.storeN, S.storeHash): a crater is at a planet point, so every line through it reads the same bowl; the sum is independent of the
# order of adds; a restored state reads its own records whatever the index last held; the cap refuses.
#   godot --headless --path . --script res://sim/world/tools/store_check.gd
var fails: int = 0


class Fake extends RefCounted:
	var store := PackedFloat64Array()
	var storeN: int = 0
	var storeHash: int = 0
	var fieldRecs: Array = []


func ok(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		fails += 1
		print("  FAIL ", what)


func _pt(face: int, i: int, j: int) -> Array:
	return WorldField.dirOf(face, i, j, 300)


func _crater(S, p: Array, r: float, d: float, rim: float, e: float, cause: int, owner: int, t: float, sp: int) -> int:
	return WorldStore.add(S, p[0], p[1], p[2], r, d, rim, e, cause, owner, t, sp)


func _init() -> void:
	var R: float = SimConst.PLANET_NC * SimConst.COL / (2.0 * SimMathx.PI)
	var st := Fake.new()
	var c0: Array = _pt(0, 150, 150)
	var c1: Array = _pt(0, 154, 150)
	_crater(st, c0, 300.0, 40.0, 12.0, 4.0, 0, 1, 10.0, 0)
	_crater(st, c1, 200.0, 30.0, 8.0, 2.0, 1, 0, 11.0, 1)
	ok(st.storeN == 2 and st.store.size() == 2 * WorldStore.STRIDE, "two records, %d numbers each" % WorldStore.STRIDE)
	var d01: float = sqrt(pow((c0[0] - c1[0]) * R, 2) + pow((c0[1] - c1[1]) * R, 2) + pow((c0[2] - c1[2]) * R, 2))
	ok(absf(WorldStore.heightDelta(st, c0[0], c0[1], c0[2]) - (WorldCrater.profile(0.0, 40.0, 12.0) + WorldCrater.profile(d01 / 200.0, 30.0, 8.0))) < 1.0e-9, "at a centre: its own bowl plus the other's apron")
	var far: Array = _pt(0, 150, 170)
	ok(WorldStore.heightDelta(st, far[0], far[1], far[2]) == 0.0, "far away the store adds nothing")
	# a ring of points 250 units from one crater, in the tangent plane: one height whichever way the line runs
	var s1 := Fake.new()
	_crater(s1, c0, 300.0, 40.0, 12.0, 4.0, 0, 1, 10.0, 0)
	var ref: float = 0.0
	var spread: float = 0.0
	for k in range(36):
		var ang: float = float(k) * SimMathx.PI / 18.0
		var d: float = 250.0 / R
		var px: float = c0[0]
		var py: float = c0[1] + SimDetMath.cos(ang) * d
		var pz: float = c0[2] + SimDetMath.sin(ang) * d
		var l: float = 1.0 / sqrt(px * px + py * py + pz * pz)
		var h: float = WorldStore.heightDelta(s1, px * l, py * l, pz * l)
		if k == 0:
			ref = h
		spread = maxf(spread, absf(h - ref))
	ok(spread < 0.5, "points 250 units round a crater read one height whichever way the line runs (%.4f spread)" % spread)
	# the order of adds: the same ground, another hash
	var sa := Fake.new()
	var sb := Fake.new()
	_crater(sa, c0, 300.0, 40.0, 12.0, 4.0, 0, 1, 10.0, 0)
	_crater(sa, c1, 200.0, 30.0, 8.0, 2.0, 1, 0, 11.0, 1)
	_crater(sb, c1, 200.0, 30.0, 8.0, 2.0, 1, 0, 11.0, 1)
	_crater(sb, c0, 300.0, 40.0, 12.0, 4.0, 0, 1, 10.0, 0)
	var mid: Array = _pt(0, 152, 150)
	ok(WorldStore.heightDelta(sa, mid[0], mid[1], mid[2]) == WorldStore.heightDelta(sb, mid[0], mid[1], mid[2]), "the ground is the sum, whatever the order")
	ok(sa.storeHash != sb.storeHash and sa.storeHash == st.storeHash and sa.storeHash != 0, "the running hash follows the order of adds")
	# a restored state: copy the arrays into another state (a snapshot), then roll the first one back and forward
	var snap := Fake.new()
	snap.store = sa.store.duplicate()
	snap.storeN = sa.storeN
	snap.storeHash = sa.storeHash
	var before: float = WorldStore.heightDelta(sa, mid[0], mid[1], mid[2])
	_crater(sa, far, 100.0, 10.0, 3.0, 1.0, 0, 0, 12.0, 0)
	ok(WorldStore.heightDelta(sa, far[0], far[1], far[2]) != 0.0, "a crater added is read at once (the index follows an add)")
	sa.store = snap.store.duplicate()
	sa.storeN = snap.storeN
	sa.storeHash = snap.storeHash
	ok(WorldStore.heightDelta(sa, far[0], far[1], far[2]) == 0.0 and WorldStore.heightDelta(sa, mid[0], mid[1], mid[2]) == before, "a state restored to an older store reads the older store")
	ok(WorldStore.heightDelta(snap, mid[0], mid[1], mid[2]) == before, "the snapshot reads its own records")
	# the field's platform records
	var pf := Fake.new()
	pf.fieldRecs = [{"k": "platform", "id": 3, "px": c0[0], "py": c0[1], "pz": c0[2], "r": 400.0, "floor": WorldTerrain.SETTLE_FLOOR, "blend": 100.0}, {"k": "lake", "id": 1}]
	var lo: float = WorldTerrain.TRIM_G + 5.0
	ok(absf(WorldField.applyRecords(pf, c0[0], c0[1], c0[2], lo) - WorldTerrain.SETTLE_FLOOR) < 1.0e-9, "inside a platform the ground is lifted to the floor")
	ok(WorldField.applyRecords(pf, c0[0], c0[1], c0[2], WorldTerrain.SETTLE_FLOOR + 50.0) == WorldTerrain.SETTLE_FLOOR + 50.0, "ground above the floor is left")
	ok(WorldField.applyRecords(pf, c0[0], c0[1], c0[2], WorldTerrain.TRIM_G - 50.0) == WorldTerrain.TRIM_G - 50.0, "the sea is not filled in")
	ok(WorldField.applyRecords(pf, far[0], far[1], far[2], lo) == lo, "outside the platform and its blend the ground is the field's")
	var edge: Array = _pt(0, 150 + 3, 150)   # about 384 units out, inside the blend
	var he: float = WorldField.applyRecords(pf, edge[0], edge[1], edge[2], lo)
	ok(he > lo and he < WorldTerrain.SETTLE_FLOOR, "across the blend the lift falls off smoothly (%.2f of %.2f to %.2f)" % [he, lo, WorldTerrain.SETTLE_FLOOR])
	# the cap
	var big := Fake.new()
	var refused: int = 0
	for k in range(WorldStore.MAX + 5):
		var p: Array = WorldField.dirOf(2, 20 + (k % 250), 20 + (k / 250), 300)
		if WorldStore.add(big, p[0], p[1], p[2], 50.0, 5.0, 1.0, 1.0, 0, 0, float(k), 0) < 0:
			refused += 1
	ok(big.storeN == WorldStore.MAX and refused == 5, "the store holds %d and refuses the rest (%d refused)" % [WorldStore.MAX, refused])
	print("STORE: %d check(s) failed" % fails)
	quit(0 if fails == 0 else 1)
