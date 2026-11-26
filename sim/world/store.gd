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
const KIND_SCAR: int = 5             # a directed beam groove A to B: a groove cut to its depth, like a trench (nothing makes one yet: terrain step 3)
const KIND_HEAP: int = 6             # a rubble cone at a planet point (nothing makes one yet: step 5)
const KIND_MERGE: int = 7            # appended at the cap for older small marks far from every fighter (nothing makes one yet: step 6); a bowl, read as a crater
const STRIDE: int = 16
## The numbers every record keeps at the end of its 16 (terrain-globe-plan.md 4.2), all folded into storeHash with the rest of the record:
const O_LIP: int = 11                # a trench's or scar's lip height: the raised bank at its edge (0 until step 3)
const O_MAT: int = 12                # a crater's material class, a code into WorldGround.LOOKS (0 until craters-by-material feeds it)
const O_REP: int = 13                # a crater's repeat count: 0 for a first blow, one more than the record it supersedes
const O_WATER: int = 14              # the level this record's water stands at (B1, WorldFill.levelFor), DRY when it has no source
const O_SUP: int = 15                # the record this one supersedes, or -1 for none
const DRY: float = -1.0e9            # the water slot of a record that holds none
const MAX: int = 16384               # records; add refuses past it
const BOX: float = 1024.0            # the grid's box, in units
const REACH_R: float = 2.0           # a crater reaches this many bowl radii (the apron ends at 1 + RIM_OUT)
const CRACK_WIDTH: float = 24.0      # a crack's half width in units: full intensity within it, falling to nothing at twice it

static var _ix: Dictionary = {}      # state instance id -> {n, hash, grid, sup}: the derived index (sup: the records another supersedes, a pure function of the store)


## The grid's box key: the box's three indices packed 20 bits each, offset so none is negative. It is exact for any box within 524,288 boxes of the centre (half a billion units), so no planet size and no reach can give two boxes one key (the offset that grew with the radius left a margin of two boxes, and a record is listed out to twice its own radius: at huge a crater wider than about 1,280 units near an axis listed past it, and from about 2,300 its key was a real box's on the far side; GW1c readiness C-24). The same packing as SimField's box key. A key is only looked up, never walked or hashed, so its values change nothing a match computes.
const _KOFF: int = 1 << 19
const _KM: int = 1 << 20
static var oldKeyOffset: int = 0   # tests only: above 0, the old key (this offset, twice its width an index), so a check can show the aliasing the packing removes (size_check --negative-control)


static func _key(ix: int, iy: int, iz: int) -> int:
	if oldKeyOffset > 0:
		var m: int = oldKeyOffset * 2
		return ((ix + oldKeyOffset) * m + (iy + oldKeyOffset)) * m + (iz + oldKeyOffset)
	return ((ix + _KOFF) * _KM + (iy + _KOFF)) * _KM + (iz + _KOFF)


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
	elif kind == KIND_CRACK or kind == KIND_TRENCH or kind == KIND_SCAR:
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
		var sup: Dictionary = {}
		for k in range(int(S.storeN)):
			_list(grid, S, k)
			var sk: int = int(S.store[k * STRIDE + O_SUP])
			if sk >= 0:
				sup[sk] = true
		ent = {"n": int(S.storeN), "hash": int(S.storeHash), "grid": grid, "sup": sup}
		if _ix.size() > 16:
			_ix.clear()
		_ix[id] = ent
	return ent


## Appends one record (kind first) to S's store, keeps the index current and the hash folded; returns its index or -1 when the store is full.
## The records [0, mid) and [mid, n) change places (Simulation's grant, GW1b: SimIntro keeps the two entrance craters in the order of the start spots whoever landed first, and a landing's dig can add more than its crater). With the
## planet store (globe-step2) a record folds all STRIDE of its numbers into the hash and carries O_SUP, the index of the record it supersedes: the running hash is folded again from the first record over the whole stride, as _push folds
## it, and every O_SUP is moved with the records it names (a head record moves up by n - mid, a tail record down by mid). The index is dropped and rebuilt on its next read; SimField's memos see the new hash and rebuild.
static func swapBlocks(S, mid: int) -> void:
	var n: int = int(S.storeN)
	if mid <= 0 or mid >= n:
		return
	var head = S.store.slice(0, mid * STRIDE)
	var tail = S.store.slice(mid * STRIDE, n * STRIDE)
	var k: int = 0
	for v in tail:
		S.store[k] = v
		k += 1
	for v in head:
		S.store[k] = v
		k += 1
	var h: int = 0
	for i in range(n):
		var o: int = i * STRIDE
		var s: int = int(S.store[o + O_SUP])
		if s >= 0:   # the record it supersedes moved with its block
			S.store[o + O_SUP] = float(s + (n - mid) if s < mid else s - mid)
		h = _fold(h, Array(S.store.slice(o, o + STRIDE)))   # (the store is packed; the fold takes Array; _push folds all STRIDE numbers)
	S.storeHash = h
	_ix.erase(S.get_instance_id())


static func _push(S, rec: Array) -> int:
	var n: int = int(S.storeN)
	if n >= MAX:
		return -1
	var live: bool = false
	var id: int = S.get_instance_id()
	if _ix.has(id):
		var e: Dictionary = _ix[id]
		live = int(e.n) == n and int(e.hash) == int(S.storeHash)
	var full: Array = []   # all STRIDE numbers, the slots at their defaults (no water, supersedes nothing) when the caller gave fewer: what is folded into the hash is what is stored
	for k in range(STRIDE):
		if k < rec.size():
			full.append(float(rec[k]))
		else:
			full.append(DRY if k == O_WATER else (-1.0 if k == O_SUP else 0.0))
	for k in range(STRIDE):
		S.store.append(full[k])
	var h0: int = int(S.storeHash)
	S.storeHash = _fold(h0, full)
	S.storeN = n + 1
	if S is SimState:   # (a check's fake state has no line)
		SimField.storeGrew(S, h0, n * STRIDE)   # Simulation's memos: only what this record can reach is read again (a record that supersedes another reaches at least as far as it, so its reach is the union)
	if live:
		var ent: Dictionary = _ix[id]
		_list(ent.grid, S, n)
		if full[O_SUP] >= 0.0:
			ent.sup[int(full[O_SUP])] = true
		ent.n = n + 1
		ent.hash = int(S.storeHash)
	return n


## Adds a crater at the unit direction (px, py, pz) to S's store; returns its index, or -1 when the store is full (the caller keeps its S.deform write then). `cause`: 0 impact, 1 beam, 2 powerup, 3 other.
## sup: the record this one supersedes (a repeat blow grown into the old crater), or -1; rep: its repeat count; water: the level its water stands at (WorldFill.levelFor), or DRY; mat: its material class.
static func add(S, px: float, py: float, pz: float, r: float, depth: float, rim: float, energy: float, cause: int, owner: int, t: float, special: int, sup: int = -1, rep: int = 0, water: float = DRY, mat: int = 0) -> int:
	return _push(S, [KIND_CRATER, px, py, pz, r, depth, rim, energy, t, special, cause, owner, mat, rep, water, sup])


## The height the store adds at a unit direction: the bowls, rims and aprons of the craters (and merged marks) there, a heap's cone, the deepest groove of the trenches, scars and scorch (grooves never sum) and the
## highest lip of a trench; a record another supersedes is not read. Held between the floor and the ceiling (the strip's, craters.json globe).
static func heightDelta(S, qx: float, qy: float, qz: float) -> float:
	return heightDeltaX(S, qx, qy, qz, -1)


## heightDelta as if record `skip` were not in the store (the shaft cap and the settling read the ground without the record the new crater supersedes). -1 skips nothing.
static func heightDeltaX(S, qx: float, qy: float, qz: float, skip: int) -> float:
	var sum: float = _scan(S, qx, qy, qz, skip)
	return combine(sum, _pg, _pl)


## heightDelta's parts at a unit direction, read only, before they are combined: [sum, groove, lip, bowls]. sum: the marks' sum (the bowls, rims and aprons of the craters and merged marks, a heap's cone, and, with craters.json
## globe.flatten on, the level floor's lift); groove: the deepest groove (trench, scar, scorch; 0 for none); lip: the highest lip of a trench; bowls: the crater records' profile alone (what a vertex stage that draws craters
## draws: no merged mark, no heap, no flatten lift), so sum - bowls is what the tiles must carry besides the grooves. `combine` turns the first three into the height; heightDelta is combine(parts).
## Rendering (A1): the tiles carry heightDelta less the sum, the part the vertex stage's bowls do not draw. Not clamped here (combine holds the floor and the ceiling). A PackedFloat64Array, not a Vector3: a Vector3 is
## 32-bit and the store's height is read at 64 bits.
static func parts(S, qx: float, qy: float, qz: float) -> PackedFloat64Array:
	return partsX(S, qx, qy, qz, -1)


## parts as if record `skip` were not in the store, as heightDeltaX.
static func partsX(S, qx: float, qy: float, qz: float, skip: int) -> PackedFloat64Array:
	var sum: float = _scan(S, qx, qy, qz, skip)
	return PackedFloat64Array([sum, _pg, _pl, _pb])


## The height three parts make: a groove is cut to its depth below the ground: where the marks are below the original ground (sum <= 0) it takes the lower of the two, where they stand above it (a rim, an apron, a heap) it
## cuts down from there; the lip is added; held between the floor and the ceiling (craters.json globe). The one place the formula is written.
static func combine(sum: float, groove: float, lip: float) -> float:
	var h: float = ((minf(sum, groove) if sum <= 0.0 else sum + groove) if groove < 0.0 else sum) + lip
	return clampf(h, WorldCraters.globeFloor(), WorldCraters.globeCeil())


## The deepest groove, the highest lip and the crater bowls alone of the last _scan (its other results: the sum is the return value). Written at the very end of a scan, after any read inside it, and read at once by the caller: no
## allocation on the height's hot path.
static var _pg: float = 0.0
static var _pl: float = 0.0
static var _pb: float = 0.0   # the crater records' profile alone (partsX's fourth)


## The one scan of the records at a point (heightDeltaX and partsX are its two readers): returns the marks' sum and leaves the groove and the lip in _pg and _pl.
static func _scan(S, qx: float, qy: float, qz: float, skip: int) -> float:
	_pg = 0.0
	_pl = 0.0
	_pb = 0.0
	if int(S.storeN) == 0:
		return 0.0
	var R: float = _R()
	var ent: Dictionary = _index(S)
	var key: int = _key(_box(qx * R), _box(qy * R), _box(qz * R))
	if not ent.grid.has(key):
		return 0.0
	var lst: PackedInt32Array = ent.grid[key]
	var sup: Dictionary = ent.sup
	var sum: float = 0.0
	var groove: float = 0.0
	var lip: float = 0.0
	var bowls: float = 0.0
	var flat: bool = WorldCraters.globeFlatten()
	var fk: int = -1        # the crater whose level floor holds here most (flatten)
	var fw: float = 0.0
	for k in lst:
		if k == skip or (not sup.is_empty() and sup.has(k)):
			continue
		var o: int = k * STRIDE
		var kd: int = int(S.store[o])
		if kd == KIND_TRENCH or kd == KIND_SCAR:
			groove = minf(groove, _trench(S, o, qx, qy, qz, R))
			if S.store[o + O_LIP] > 0.0:
				lip = maxf(lip, _lip(S, o, qx, qy, qz, R))
			continue
		if kd != KIND_CRATER and kd != KIND_SCORCH and kd != KIND_MERGE and kd != KIND_HEAP:
			continue
		var dx: float = (qx - S.store[o + 1]) * R
		var dy: float = (qy - S.store[o + 2]) * R
		var dz: float = (qz - S.store[o + 3]) * R
		var d: float = sqrt(dx * dx + dy * dy + dz * dz)
		if kd == KIND_CRATER or kd == KIND_MERGE:
			var u: float = d / S.store[o + 4]
			if u < 2.0:
				var pu: float = WorldCrater.profile(u, S.store[o + 5], S.store[o + 6])
				sum += pu
				if kd == KIND_CRATER:
					bowls += pu
				if flat and kd == KIND_CRATER and u < WorldCraters.globeFlattenFade():   # the weight of the level floor: 1 inside the lip, easing to 0 at flattenFade
					var fu: float = 1.0 - clampf((u - 1.0) / (WorldCraters.globeFlattenFade() - 1.0), 0.0, 1.0)
					var wk: float = fu * fu * (3.0 - 2.0 * fu)
					if wk > fw:
						fw = wk
						fk = k
		elif kd == KIND_HEAP:
			var uh: float = d / S.store[o + 4]
			if uh < 1.0:
				var th: float = 1.0 - uh * uh
				sum += S.store[o + 5] * th * th
		else:
			var us: float = d / S.store[o + 4]
			if us < 1.0:
				var ts: float = 1.0 - us * us
				groove = minf(groove, -S.store[o + 5] * ts * ts)
	# (combine: the lower of the groove and the marks alone left a cliff as high as the rim at the groove's edge, where the groove (about 0) took over from a rim (up to 0.4 of a bowl's depth).)
	if fk >= 0:   # the level floor: the ground there is the ground at the crater's centre, not the hills under the bowl (delta = w x (the centre's ground - the ground here); the bowl's profile is already in sum)
		sum += fw * (_centreGround(S, ent, fk) - _fieldH(S, qx, qy, qz))
	_pg = groove   # set last: the flatten above reads the field, which may read the store again
	_pl = lip
	_pb = bowls
	return sum


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
## lip: the height of the raised bank at its edge (0: none, as ever); water: the level its water stands at (WorldFill.levelForSegment), or DRY.
static func addTrench(S, a: Array, b: Array, depth: float, halfWidth: float, t: float, owner: int, lip: float = 0.0, water: float = DRY) -> int:
	var sg: Array = WorldGlobe.settleGroove(depth, halfWidth)   # a groove on the planet is never a wall: widened to the angle of repose (craters.json globe.repose)
	depth = sg[0]
	halfWidth = sg[1]
	return _push(S, [KIND_TRENCH, a[0], a[1], a[2], b[0], b[1], b[2], depth, halfWidth, t, owner, lip, 0.0, 0.0, water, -1.0])


## A directed beam groove from planet point a to b (KIND_SCAR): the same groove as a trench (depth cut to its target, never summed), `halfWidth` wide. Nothing writes one yet (terrain step 3).
static func addScar(S, a: Array, b: Array, depth: float, halfWidth: float, t: float, owner: int, lip: float = 0.0, water: float = DRY) -> int:
	var sg: Array = WorldGlobe.settleGroove(depth, halfWidth)
	depth = sg[0]
	halfWidth = sg[1]
	return _push(S, [KIND_SCAR, a[0], a[1], a[2], b[0], b[1], b[2], depth, halfWidth, t, owner, lip, 0.0, 0.0, water, -1.0])


## A rubble cone at planet point p (KIND_HEAP): `height` at the centre falling to nothing at `radius`, held to a slope of 1 in 1 (the cone is height x (1 - u^2)^2, steepest at 1.54 height / radius). Nothing writes one yet (step 5).
static func addHeap(S, p: Array, radius: float, height: float, t: float, owner: int) -> int:
	return _push(S, [KIND_HEAP, p[0], p[1], p[2], radius, minf(height, radius / 1.54), 0.0, 0.0, t, 0.0, 3.0, owner, 0.0, 0.0, DRY, -1.0])


## A merged mark (KIND_MERGE): a bowl standing for older small marks (step 6); read as a crater.
static func addMerge(S, p: Array, r: float, depth: float, rim: float, t: float) -> int:
	return _push(S, [KIND_MERGE, p[0], p[1], p[2], r, depth, rim, 0.0, t, 0.0, 3.0, -1.0, 0.0, 0.0, DRY, -1.0])


## The index of the newest crater a blow at unit direction (qx, qy, qz) repeats: an impact crater (not superseded) whose centre is within `frac` of its own radius of the point, or -1.
static func recentImpact(S, qx: float, qy: float, qz: float, frac: float) -> int:
	if int(S.storeN) == 0:
		return -1
	var R: float = _R()
	var ent: Dictionary = _index(S)
	var key: int = _key(_box(qx * R), _box(qy * R), _box(qz * R))
	if not ent.grid.has(key):
		return -1
	var best: int = -1
	for k in ent.grid[key]:
		var o: int = k * STRIDE
		if int(S.store[o]) != KIND_CRATER or int(S.store[o + 10]) != 0 or ent.sup.has(k) or k <= best:
			continue
		var dx: float = (qx - S.store[o + 1]) * R
		var dy: float = (qy - S.store[o + 2]) * R
		var dz: float = (qz - S.store[o + 3]) * R
		if sqrt(dx * dx + dy * dy + dz * dz) <= frac * S.store[o + 4]:
			best = k
	return best


## A record's centre (for a segment, its start) and its radius (a crater's, a trench's half width).
static func centreOf(S, k: int) -> Array:
	var o: int = k * STRIDE
	return [S.store[o + 1], S.store[o + 2], S.store[o + 3]]


static func radiusOf(S, k: int) -> float:
	var o: int = k * STRIDE
	return S.store[o + 8] if int(S.store[o]) == KIND_TRENCH or int(S.store[o]) == KIND_SCAR else S.store[o + 4]


static func repeatsOf(S, k: int) -> int:
	return int(S.store[k * STRIDE + O_REP])


## The level record k's water stands at, or DRY.
static func waterOf(S, k: int) -> float:
	return S.store[k * STRIDE + O_WATER]


## True when another record supersedes record k.
static func superseded(S, k: int) -> bool:
	return _index(S).sup.has(k)


## The records whose reach touches the unit direction (their indices, in order, the superseded ones left out): what is under a point, for the water's level and a check's reading.
static func at(S, qx: float, qy: float, qz: float) -> PackedInt32Array:
	var out := PackedInt32Array()
	if int(S.storeN) == 0:
		return out
	var R: float = _R()
	var ent: Dictionary = _index(S)
	var key: int = _key(_box(qx * R), _box(qy * R), _box(qz * R))
	if not ent.grid.has(key):
		return out
	for k in ent.grid[key]:
		if not ent.sup.has(k):
			out.append(k)
	return out


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


## The raised bank at the edge of a groove (a trench's or a scar's lip slot): `lip` high on a ring from 0.85 to 1.6 half widths from the segment, a parabola with its crest at 1.225 half widths.
static func _lip(S, o: int, qx: float, qy: float, qz: float, R: float) -> float:
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
	if u <= 0.85 or u >= 1.6:
		return 0.0
	var w: float = (u - 0.85) / 0.75
	return S.store[o + O_LIP] * 4.0 * w * (1.0 - w)


## The distance in units from the unit direction to a segment record's line (a trench's or a scar's A to B).
static func _segDist(S, o: int, qx: float, qy: float, qz: float, R: float) -> float:
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
	return sqrt(dx * dx + dy * dy + dz * dz)


## True when the unit direction is inside record k's hole: within a crater's lip, or within a groove's half width of its line.
static func _inside(S, k: int, qx: float, qy: float, qz: float, R: float) -> bool:
	var o: int = k * STRIDE
	var kd: int = int(S.store[o])
	if kd == KIND_TRENCH or kd == KIND_SCAR:
		return _segDist(S, o, qx, qy, qz, R) < S.store[o + 8]
	if kd == KIND_CRATER or kd == KIND_MERGE:
		var dx: float = (qx - S.store[o + 1]) * R
		var dy: float = (qy - S.store[o + 2]) * R
		var dz: float = (qz - S.store[o + 3]) * R
		return sqrt(dx * dx + dy * dy + dz * dz) < S.store[o + 4]
	return false


## The level the water stands at in the holes that reach the unit direction (the highest of the records there that hold water), or DRY. A record holds water only if WorldFill.floodLevelFor found a source when it was made.
static func waterLevelAt(S, qx: float, qy: float, qz: float) -> float:
	if int(S.storeN) == 0:
		return DRY
	var R: float = _R()
	var ent: Dictionary = _index(S)
	var key: int = _key(_box(qx * R), _box(qy * R), _box(qz * R))
	if not ent.grid.has(key):
		return DRY
	var best: float = DRY
	for k in ent.grid[key]:
		var lv: float = S.store[k * STRIDE + O_WATER]
		if lv <= DRY * 0.5 or ent.sup.has(k) or lv <= best:
			continue
		if _inside(S, k, qx, qy, qz, R):
			best = lv
	return best


## The level of the highest water held by a record whose hole overlaps a new one of radius `radius` at unit direction q (their reaches closer than the two radii together), or DRY: a trench cut on from a flooded one, or a bowl dug in a flooded crater, takes its level.
static func overlappingWater(S, q: Array, radius: float) -> float:
	if int(S.storeN) == 0:
		return DRY
	var R: float = _R()
	var ent: Dictionary = _index(S)
	var best: float = DRY
	var seen: Dictionary = {}
	var cx: float = q[0] * R
	var cy: float = q[1] * R
	var cz: float = q[2] * R
	for ix in range(_box(cx - radius), _box(cx + radius) + 1):
		for iy in range(_box(cy - radius), _box(cy + radius) + 1):
			for iz in range(_box(cz - radius), _box(cz + radius) + 1):
				var key: int = _key(ix, iy, iz)
				if not ent.grid.has(key):
					continue
				for k in ent.grid[key]:
					if seen.has(k):
						continue
					seen[k] = true
					var o: int = k * STRIDE
					var lv: float = S.store[o + O_WATER]
					if lv <= DRY * 0.5 or ent.sup.has(k) or lv <= best:
						continue
					var d: float = _segDist(S, o, q[0], q[1], q[2], R) if (int(S.store[o]) == KIND_TRENCH or int(S.store[o]) == KIND_SCAR) else _chord(S, o, q, R)
					if d < radius + radiusOf(S, k):
						best = lv
	return best


static func _chord(S, o: int, q: Array, R: float) -> float:
	var dx: float = (q[0] - S.store[o + 1]) * R
	var dy: float = (q[1] - S.store[o + 2]) * R
	var dz: float = (q[2] - S.store[o + 3]) * R
	return sqrt(dx * dx + dy * dy + dz * dz)


## The field's own ground at a unit direction, as SimField reads it before the store (the field and World's records, the finest level): what a level floor is measured against. Pure in the planet and the records.
static func _fieldH(S, qx: float, qy: float, qz: float) -> float:
	var P: WorldPlanet.Planet = WorldPlanet.make(int(S.planetRing.seed))
	var F = WorldField.of(P)
	WorldField.sample(F, qx, qy, qz, 1)
	var h: float = F.oh
	if not S.fieldRecs.is_empty():
		h = WorldField.applyRecords(S, qx, qy, qz, h)
	return h


## The ground at crater k's centre before the store (memoised in the derived index: a pure function of the record and the field, so a rebuild finds the same number).
static func _centreGround(S, ent: Dictionary, k: int) -> float:
	var fc: Dictionary = ent.get("fc", {})
	if not ent.has("fc"):
		ent["fc"] = fc
	if fc.has(k):
		return fc[k]
	var o: int = k * STRIDE
	var h: float = _fieldH(S, S.store[o + 1], S.store[o + 2], S.store[o + 3])
	fc[k] = h
	return h
