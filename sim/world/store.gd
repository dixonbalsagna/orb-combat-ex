class_name WorldStore
extends RefCounted
## The planet store of marks (docs/world/ring-any-angle/research.md T6 stage 7; the EP's call of 2026-10-31 for craters and of 2026-11-01 for cracks, then scorch, beam scars, slides and heaps). A mark is a record at
## PLANET POINTS (unit directions), not at strip columns, so it stays where it was made when the line through the fighters turns. On gen 3 the ground is the field's height plus heightDelta here, and a strip's crack
## column is crackAt at the column's point.
##
## The records live on the sim state as plain arrays, Simulation's names: S.store (PackedFloat64Array, flat records of STRIDE numbers, append-only), S.storeN (records), S.storeHash (an int folded from the records in
## order, for the state's digest). A record is [kind, then up to 15 numbers] by kind:
##   KIND_CRATER 0: px, py, pz, r, depth, rim, energy, t, special, cause, owner
##   KIND_CRACK  1: ax, ay, az, bx, by, bz, intensity, halfWidth, t, owner      (a segment of the planet, the path of a knockback slide on paved ground)
##   KIND_SCORCH 2: px, py, pz, halfWidth, depth, intensity, t, owner               (a beam sample's burn and groove)
##   KIND_TRENCH 3: ax, ay, az, bx, by, bz, depth, halfWidth, t, owner                 (the groove a knockback slide cuts along its path; never deeper than its target)
## The grid index is derived and rebuilt when the state's count or hash is not the one it indexed. A kind is added here with its reader; the later kinds (scorch, beam scars, slides, heaps) follow the same way.
## Once a mark is in the store its strip write stops on gen 3 only where the state has a frame (Simulation's read-through); until then the strip is written as ever. At MAX records add returns -1 and the caller
## keeps its strip write for that mark.

const KIND_CRATER: int = 0
const KIND_CRACK: int = 1
const KIND_SCORCH: int = 2
const KIND_TRENCH: int = 3
const STRIDE: int = 16
const MAX: int = 16384               # records; add refuses past it
const BOX: float = 1024.0            # the grid's box, in units
const REACH_R: float = 2.0           # a crater reaches this many bowl radii (the apron ends at 1 + RIM_OUT)
const CRACK_WIDTH: float = 24.0      # a crack's half width in units: full intensity within it, falling to nothing at twice it

static var _ix: Dictionary = {}      # state instance id -> {n, hash, grid}: the derived index


static func _key(ix: int, iy: int, iz: int) -> int:
	return ((ix + 64) * 128 + (iy + 64)) * 128 + (iz + 64)


static func _box(v: float) -> int:
	return int(floor(v / BOX))


static func _R() -> float:
	return SimConst.PLANET_NC * SimConst.COL / (2.0 * SimMathx.PI)


## The hash after one more record: the old hash and the record's numbers folded in order (an int, two 32-bit lanes).
static func _fold(h0: int, rec: Array) -> int:
	var h := SimHash.Hasher.new()
	h.a = (h0 >> 32) & SimRng.MASK if h0 != 0 else 0x811c9dc5
	h.b = h0 & SimRng.MASK if h0 != 0 else 0x9e3779b9
	for v in rec:
		h.num(float(v))
	return (h.a << 32) | h.b


## Lists record k in every grid box its reach touches.
static func _list(grid: Dictionary, S, k: int) -> void:
	var o: int = k * STRIDE
	var R: float = _R()
	var kind: int = int(S.store[o])
	var lo := [0.0, 0.0, 0.0]
	var hi := [0.0, 0.0, 0.0]
	if kind == KIND_SCORCH:
		var reach3: float = S.store[o + 4]
		for a in range(3):
			var c3: float = S.store[o + 1 + a] * R
			lo[a] = c3 - reach3
			hi[a] = c3 + reach3
	elif kind == KIND_CRACK or kind == KIND_TRENCH:
		var reach: float = S.store[o + 8] * 2.0
		for a in range(3):
			var p: float = S.store[o + 1 + a] * R
			var q: float = S.store[o + 4 + a] * R
			lo[a] = minf(p, q) - reach
			hi[a] = maxf(p, q) + reach
	else:
		var reach2: float = S.store[o + 4] * REACH_R
		for a in range(3):
			var c: float = S.store[o + 1 + a] * R
			lo[a] = c - reach2
			hi[a] = c + reach2
	for ix in range(_box(lo[0]), _box(hi[0]) + 1):
		for iy in range(_box(lo[1]), _box(hi[1]) + 1):
			for iz in range(_box(lo[2]), _box(hi[2]) + 1):
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


## Appends one record (kind first) to S's store, keeps the index current and the hash folded; returns its index or -1 when the store is full.
static func _push(S, rec: Array) -> int:
	var n: int = int(S.storeN)
	if n >= MAX:
		return -1
	var live: bool = false
	var id: int = S.get_instance_id()
	if _ix.has(id):
		var e: Dictionary = _ix[id]
		live = int(e.n) == n and int(e.hash) == int(S.storeHash)
	for k in range(STRIDE):
		S.store.append(float(rec[k]) if k < rec.size() else 0.0)
	S.storeHash = _fold(int(S.storeHash), rec)
	S.storeN = n + 1
	if live:
		var ent: Dictionary = _ix[id]
		_list(ent.grid, S, n)
		ent.n = n + 1
		ent.hash = int(S.storeHash)
	return n


## Adds a crater at the unit direction (px, py, pz) to S's store; returns its index, or -1 when the store is full (the caller keeps its S.deform write then). `cause`: 0 impact, 1 beam, 2 powerup, 3 other.
static func add(S, px: float, py: float, pz: float, r: float, depth: float, rim: float, energy: float, cause: int, owner: int, t: float, special: int) -> int:
	return _push(S, [KIND_CRATER, px, py, pz, r, depth, rim, energy, t, special, cause, owner])


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
	var groove: float = 0.0
	for k in lst:
		var o: int = k * STRIDE
		var kd: int = int(S.store[o])
		if kd == KIND_TRENCH:
			groove = minf(groove, _trench(S, o, qx, qy, qz, R))
			continue
		if kd != KIND_CRATER and kd != KIND_SCORCH:
			continue
		var dx: float = (qx - S.store[o + 1]) * R
		var dy: float = (qy - S.store[o + 2]) * R
		var dz: float = (qz - S.store[o + 3]) * R
		var d: float = sqrt(dx * dx + dy * dy + dz * dz)
		if kd == KIND_CRATER:
			var u: float = d / S.store[o + 4]
			if u < 2.0:
				sum += WorldCrater.profile(u, S.store[o + 5], S.store[o + 6])
		else:
			var us: float = d / S.store[o + 4]
			if us < 1.0:
				var ts: float = 1.0 - us * us
				groove = minf(groove, -S.store[o + 5] * ts * ts)
	return minf(sum, groove) if groove < 0.0 else sum


## ===================================================================== cracks
## A crack: the path of a knockback slide on paved ground, from planet point a to planet point b, at `intensity` (S.crack's value), `halfWidth` wide. Returns the record's index, or -1 when the store is full.
static func addCrack(S, a: Array, b: Array, intensity: float, halfWidth: float, t: float, owner: int) -> int:
	return _push(S, [KIND_CRACK, a[0], a[1], a[2], b[0], b[1], b[2], intensity, halfWidth, t, owner])


## The crack intensity at a unit direction: the largest of the cracks reaching it, each its intensity inside the half width of its segment, falling smoothly to nothing at twice it. 0 for none.
static func crackAt(S, qx: float, qy: float, qz: float) -> float:
	if int(S.storeN) == 0:
		return 0.0
	var R: float = _R()
	var ent: Dictionary = _index(S)
	var key: int = _key(_box(qx * R), _box(qy * R), _box(qz * R))
	if not ent.grid.has(key):
		return 0.0
	var best: float = 0.0
	for k in ent.grid[key]:
		var o: int = k * STRIDE
		if int(S.store[o]) != KIND_CRACK:
			continue
		var ex: float = S.store[o + 4] - S.store[o + 1]
		var ey: float = S.store[o + 5] - S.store[o + 2]
		var ez: float = S.store[o + 6] - S.store[o + 3]
		var e2: float = ex * ex + ey * ey + ez * ez
		var t: float = 0.0
		if e2 > 1.0e-24:
			t = clampf(((qx - S.store[o + 1]) * ex + (qy - S.store[o + 2]) * ey + (qz - S.store[o + 3]) * ez) / e2, 0.0, 1.0)
		var dx: float = (qx - (S.store[o + 1] + ex * t)) * R
		var dy: float = (qy - (S.store[o + 2] + ey * t)) * R
		var dz: float = (qz - (S.store[o + 3] + ez * t)) * R
		var d: float = sqrt(dx * dx + dy * dy + dz * dz)
		var hw: float = S.store[o + 8]
		if d >= 2.0 * hw:
			continue
		var f: float = 1.0 if d <= hw else 1.0 - (d - hw) / hw
		f = f * f * (3.0 - 2.0 * f)
		best = maxf(best, f * S.store[o + 7])
	return best


## Lays the strip's cracks from the store: S.crack at each column is crackAt at the column's planet point. `pointOfX` is Simulation's map from a strip x to the planet direction on the line now
## (func(x: float) -> [x, y, z]); call it after the line has moved or come to rest. Columns with no crack are set to 0, so cracks that hung in the air at the old line's x are gone. Returns the columns cracked.
static func layCracks(S, pointOfX: Callable) -> int:
	var nc: int = SimConst.NC
	var n: int = 0
	for c in range(nc):
		var q: Array = pointOfX.call((float(c) + 0.5) * SimConst.COL)
		var v: float = crackAt(S, q[0], q[1], q[2])
		S.crack[c] = v
		if v > 0.0:
			n += 1
	return n


static func count(S) -> int:
	return int(S.storeN)


## ===================================================================== scorch
## A beam sample's burn and groove: planet point, half width, target depth, burn intensity. S.scorch at a column is the largest intensity x (1 - u^2) over the samples (u: distance over half width); the groove is
## the deepest of -depth x (1 - u^2)^2, never summed (a groove is never deeper than its target however often a beam crosses it), and the ground is the lower of the craters' sum and the groove.
## A sample that a recent one already covers (within a quarter of its half width, no weaker) is not added: a beam holds one sample's worth of record for a stationary strike, not one a tick.
static func addScorch(S, q: Array, hw: float, depth: float, inten: float, t: float, owner: int) -> int:
	var n: int = int(S.storeN)
	var R: float = _R()
	for back in range(1, mini(n, 8) + 1):
		var o: int = (n - back) * STRIDE
		if int(S.store[o]) != KIND_SCORCH:
			continue
		var dx: float = (q[0] - S.store[o + 1]) * R
		var dy: float = (q[1] - S.store[o + 2]) * R
		var dz: float = (q[2] - S.store[o + 3]) * R
		if sqrt(dx * dx + dy * dy + dz * dz) <= 0.25 * hw and S.store[o + 4] >= hw * 0.99 and S.store[o + 5] >= depth * 0.99 and S.store[o + 6] >= inten * 0.99:
			return n - back
	return _push(S, [KIND_SCORCH, q[0], q[1], q[2], hw, depth, inten, t, owner])


## Scorch at a unit direction: [burn intensity, groove depth (<= 0)] from the samples that reach it.
static func scorchAt(S, qx: float, qy: float, qz: float) -> Array:
	if int(S.storeN) == 0:
		return [0.0, 0.0]
	var R: float = _R()
	var ent: Dictionary = _index(S)
	var key: int = _key(_box(qx * R), _box(qy * R), _box(qz * R))
	var burn: float = 0.0
	var groove: float = 0.0
	if ent.grid.has(key):
		for k in ent.grid[key]:
			var o: int = k * STRIDE
			if int(S.store[o]) != KIND_SCORCH:
				continue
			var dx: float = (qx - S.store[o + 1]) * R
			var dy: float = (qy - S.store[o + 2]) * R
			var dz: float = (qz - S.store[o + 3]) * R
			var u: float = sqrt(dx * dx + dy * dy + dz * dz) / S.store[o + 4]
			if u >= 1.0:
				continue
			var t: float = 1.0 - u * u
			burn = maxf(burn, S.store[o + 6] * t)
			groove = minf(groove, -S.store[o + 5] * t * t)
	return [burn, groove]


## Lays the strip's burn marks from the store (S.scorch at each column), as layCracks does for cracks. Returns the columns burnt.
static func layScorch(S, pointOfX: Callable) -> int:
	var nc: int = SimConst.NC
	var n: int = 0
	for c in range(nc):
		var q: Array = pointOfX.call((float(c) + 0.5) * SimConst.COL)
		var v: float = scorchAt(S, q[0], q[1], q[2])[0]
		S.scorch[c] = v
		if v > 0.0:
			n += 1
	return n


## ===================================================================== trenches
## The groove a knockback slide cuts along its path (WorldCrater.carveSegment): from planet point a to b, `depth` deep (a target, never exceeded), `halfWidth` wide. The ground is the lower of the craters' sum and the
## deepest trench or scorch groove there (heightDelta). Returns the record's index, or -1 when the store is full.
static func addTrench(S, a: Array, b: Array, depth: float, halfWidth: float, t: float, owner: int) -> int:
	return _push(S, [KIND_TRENCH, a[0], a[1], a[2], b[0], b[1], b[2], depth, halfWidth, t, owner])


## The trench groove at a unit direction (<= 0): -depth x the smoothed fall-off over the half width, the deepest of the trenches reaching it.
static func trenchAt(S, qx: float, qy: float, qz: float) -> float:
	if int(S.storeN) == 0:
		return 0.0
	var R: float = _R()
	var ent: Dictionary = _index(S)
	var key: int = _key(_box(qx * R), _box(qy * R), _box(qz * R))
	if not ent.grid.has(key):
		return 0.0
	var best: float = 0.0
	for k in ent.grid[key]:
		var o: int = k * STRIDE
		if int(S.store[o]) != KIND_TRENCH:
			continue
		best = minf(best, _trench(S, o, qx, qy, qz, R))
	return best


static func _trench(S, o: int, qx: float, qy: float, qz: float, R: float) -> float:
	var ex: float = S.store[o + 4] - S.store[o + 1]
	var ey: float = S.store[o + 5] - S.store[o + 2]
	var ez: float = S.store[o + 6] - S.store[o + 3]
	var e2: float = ex * ex + ey * ey + ez * ez
	var t: float = 0.0
	if e2 > 1.0e-24:
		t = clampf(((qx - S.store[o + 1]) * ex + (qy - S.store[o + 2]) * ey + (qz - S.store[o + 3]) * ez) / e2, 0.0, 1.0)
	var dx: float = (qx - (S.store[o + 1] + ex * t)) * R
	var dy: float = (qy - (S.store[o + 2] + ey * t)) * R
	var dz: float = (qz - (S.store[o + 3] + ez * t)) * R
	var u: float = sqrt(dx * dx + dy * dy + dz * dz) / S.store[o + 8]
	if u >= 1.0:
		return 0.0
	var s: float = 1.0 - u * u
	return -S.store[o + 7] * s * s
