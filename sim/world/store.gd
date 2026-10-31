class_name WorldStore
extends RefCounted
## The planet store, craters first (docs/world/ring-any-angle/research.md T6 stage 7, in part; EP's call of 2026-10-31: a crater stays on the planet through a swing). A mark is a record at a PLANET POINT (a unit
## direction), not at a strip column, so it does not move when the line through the pair turns. On gen 3 the ground is the field's height plus heightDelta here, read at each point's direction.
##
## The records live on the sim state as plain arrays, Simulation's names: S.store (PackedFloat64Array, flat records of STRIDE numbers, append-only), S.storeN (records), S.storeHash (an int folded from the records
## in order, for the state's digest). This module owns the layout and the reads; it holds no state of its own beyond a derived index (a 3D grid of 1,024-unit boxes, a record listed in each box its bowl and apron
## reach), rebuilt from S.store whenever the state's count or hash is not the one it indexed, so a rollback or a fresh state costs a rebuild and never a wrong answer. `S` is any object with those three fields.
##
## Not here yet: the skid furrow (it needs a direction at the point), slides, heaps and beam scorch (stage 7 proper). Once a crater is in the store its S.deform write stops on gen 3 (Simulation's rule), or
## groundY would count it twice. At MAX records add returns -1 and the caller keeps its S.deform write for that crater.

const STRIDE: int = 11               # px, py, pz, r, depth, rim, energy, t, special, cause, owner
const MAX: int = 4096                # records; add refuses past it
const BOX: float = 1024.0            # the grid's box, in units
const REACH_R: float = 2.0           # a record reaches this many bowl radii (the apron ends at 1 + RIM_OUT)

static var _ix: Dictionary = {}      # state instance id -> {n, hash, grid}: the derived index


static func _key(ix: int, iy: int, iz: int) -> int:
	return ((ix + 64) * 128 + (iy + 64)) * 128 + (iz + 64)


static func _box(v: float) -> int:
	return int(floor(v / BOX))


static func _R() -> float:
	return SimConst.PLANET_NC * SimConst.COL / (2.0 * SimMathx.PI)


## The hash after one more record: the old hash and the record's numbers folded in order (an int, two 32-bit lanes).
static func _fold(h0: int, px: float, py: float, pz: float, r: float, depth: float, rim: float, cause: int, owner: int, t: float) -> int:
	var h := SimHash.Hasher.new()
	h.a = (h0 >> 32) & SimRng.MASK if h0 != 0 else 0x811c9dc5
	h.b = h0 & SimRng.MASK if h0 != 0 else 0x9e3779b9
	h.num(px)
	h.num(py)
	h.num(pz)
	h.num(r)
	h.num(depth)
	h.num(rim)
	h.u(cause)
	h.u(owner & SimRng.MASK)
	h.num(t)
	return (h.a << 32) | h.b


static func _list(grid: Dictionary, S, k: int) -> void:
	var o: int = k * STRIDE
	var R: float = _R()
	var reach: float = S.store[o + 3] * REACH_R
	var cx: float = S.store[o] * R
	var cy: float = S.store[o + 1] * R
	var cz: float = S.store[o + 2] * R
	for ix in range(_box(cx - reach), _box(cx + reach) + 1):
		for iy in range(_box(cy - reach), _box(cy + reach) + 1):
			for iz in range(_box(cz - reach), _box(cz + reach) + 1):
				var key: int = _key(ix, iy, iz)
				var lst: PackedInt32Array = grid.get(key, PackedInt32Array())
				lst.append(k)
				grid[key] = lst


## The index of S's store, current: built from the records when the count or hash is not what it last indexed.
static func _index(S) -> Dictionary:
	var id: int = S.get_instance_id()
	var ent: Dictionary = _ix.get(id, {})
	if ent.is_empty() or int(ent.n) != int(S.storeN) or int(ent.hash) != int(S.storeHash):
		var grid: Dictionary = {}
		for k in range(int(S.storeN)):
			_list(grid, S, k)
		ent = {"n": int(S.storeN), "hash": int(S.storeHash), "grid": grid}
		if _ix.size() > 16:
			_ix.clear()
		_ix[id] = ent
	return ent


## Adds a crater at the unit direction (px, py, pz) to S's store; returns its index, or -1 when the store is full (the caller keeps its S.deform write then). `cause`: 0 impact, 1 beam, 2 powerup, 3 other.
static func add(S, px: float, py: float, pz: float, r: float, depth: float, rim: float, energy: float, cause: int, owner: int, t: float, special: int) -> int:
	var n: int = int(S.storeN)
	if n >= MAX:
		return -1
	var live: bool = false
	var id: int = S.get_instance_id()
	if _ix.has(id):
		var e: Dictionary = _ix[id]
		live = int(e.n) == n and int(e.hash) == int(S.storeHash)
	S.store.append(px)
	S.store.append(py)
	S.store.append(pz)
	S.store.append(r)
	S.store.append(depth)
	S.store.append(rim)
	S.store.append(energy)
	S.store.append(t)
	S.store.append(float(special))
	S.store.append(float(cause))
	S.store.append(float(owner))
	S.storeHash = _fold(int(S.storeHash), px, py, pz, r, depth, rim, cause, owner, t)
	S.storeN = n + 1
	if live:   # keep the index current without a rebuild
		var ent: Dictionary = _ix[id]
		_list(ent.grid, S, n)
		ent.n = n + 1
		ent.hash = int(S.storeHash)
	return n


## The height the store adds at a unit direction: the sum of every crater's bowl, rim and apron there.
static func heightDelta(S, qx: float, qy: float, qz: float) -> float:
	if int(S.storeN) == 0:
		return 0.0
	var R: float = _R()
	var ent: Dictionary = _index(S)
	var key: int = _key(_box(qx * R), _box(qy * R), _box(qz * R))
	if not ent.grid.has(key):
		return 0.0
	var lst: PackedInt32Array = ent.grid[key]
	var sum: float = 0.0
	for k in lst:
		var o: int = k * STRIDE
		var dx: float = (qx - S.store[o]) * R
		var dy: float = (qy - S.store[o + 1]) * R
		var dz: float = (qz - S.store[o + 2]) * R
		var u: float = sqrt(dx * dx + dy * dy + dz * dz) / S.store[o + 3]
		if u < 2.0:
			sum += WorldCrater.profile(u, S.store[o + 4], S.store[o + 5])
	return sum
