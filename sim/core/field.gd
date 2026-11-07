class_name SimField
extends RefCounted
## The sim's read of a field world (setup.planetGen 3 on a whole ring; docs/architecture/field-ground.md). World's WorldField holds the ground, a pure function of the planet's direction; this is the
## sim's line through it, S.frame, a great circle, and every ground read goes through that, so a swing (SimSwing) needs no re-lay: W, NC, sdx and wrap stay, as a ring buffer of the circle. With any other
## generation, or a ring that isn't a great circle, S.frame is null, nothing here runs, and S.base is the ground as it always was.
##
## The reader's rule: which level a read takes is fixed by the reader, never by what is ready. Inside far() ... near() (a forecast, a planner) reads take the 512 bake; outside, the 128 ground, computing a
## missing node on the spot. Two machines read the same bits whatever each has computed already. All of it float64 arithmetic on three plain numbers; never a Vector3, which is float32.
## A far read takes every farStride-th column and interpolates: the bake's nodes are 16 columns apart, so a plan's line costs about an eighth of the field reads and loses nothing a forecast can use (Performance: a launch's plan read 710 cold columns, 20 ms).

const FILE: String = "res://data/fight/swing.json"

static var _d = null

## The radius of the line: the planet's circumference in columns closes the circle exactly.
static var R: float = float(SimConst.PLANET_NC) * SimConst.COL / SimMathx.TAU

## Outputs, as the planet read's P.outH: pointIn and placeIn set ox, oy, oz; strip sets sx, sz.
static var ox: float = 0.0
static var oy: float = 0.0
static var oz: float = 0.0
static var sx: float = 0.0
static var sz: float = 0.0

static var _far: int = 0                    # far() scopes open; SimCore.step closes any a tick left open
static var cur: SimState = null             # the field match stepping now (WorldBiomes has no S to read); null off a field world
static var _keyOf: Dictionary = {}          # seed * 4 + gen: the match key's hash
# The memo of a frame's columns (outside the state): valid while these are the frame's own numbers and the store's hash, so a restored state, or another state's frame, can never read another's columns.
static var _kp := PackedFloat64Array([2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 0.0])
static var _kSeed: int = -1
static var _sh: int = 0
static var _serial: int = 0
static var _ctF = null                     # planetCeilAt's table of the bake: the highest node of each tile of each face, for this field; pure, so it isn't state
static var _ct := PackedFloat32Array()
static var _ctK: int = 0                   # ... its tiles done (warmStep fills it, a few a tick)
static var _ctT: int = 0                   # ... a tile's side in bake cells
static var _ctN: int = 0                   # ... tiles to a face's side
static var _crW: int = -1                  # ... the highest World's records can make the ground, by box of the planet: for this world and this many records
static var _crN: int = -1
static var _crI: int = 0
static var _cr: Dictionary = {}
static var _riseH: int = -1                # ... what the store's rims can add, by box: for the store with this hash
static var _rise: Dictionary = {}
static var _changes: int = 0               # counts every change a memo keyed on serialOf must see: a bind, and a record joining the store
static var _nc: int = 0
static var _wCur: int = 0                   # the warm-up (warmStep): the next coarse column, the next building ...
static var _wB: int = 0
static var _wSer: int = -1                  # ... of the memos as laid at this serial ...
static var _wQ: int = 0                     # ... and the ticks they've been quiet
static var _F = null                        # the frame's field
static var _stride: int = 4
static var _st: int = 8                     # farStride, the data's
static var _bKey: int = 0                   # buildingGround's memo (outside the state): a building's ground, by index and level, for one state's points and store
static var _bHave: Dictionary = {}
static var _m0 := PackedFloat64Array()
static var _m1 := PackedFloat64Array()
static var _s0 := PackedInt32Array()
static var _s1 := PackedInt32Array()
static var _w0 := PackedFloat64Array()      # ... and each level's record water at a column
static var _w1 := PackedFloat64Array()
static var _t0 := PackedInt32Array()
static var _t1 := PackedInt32Array()
static var _fs: int = 0                     # the frame's serial: a column's ground before the store keys on it (World's request), so a record joining the store, or a
static var _recs = null                     # rollback's store, doesn't move it; a new frame, planet, level or set of records does
static var _recN: int = -1
static var _m0f := PackedFloat64Array()     # ... that ground, the field and World's records, by coarse and fine column
static var _m1f := PackedFloat64Array()
static var _f0 := PackedInt32Array()
static var _f1 := PackedInt32Array()
static var splitOff: bool = false           # tests only: every column read whole, as before (field_static_check)
static var blindStore: bool = false         # tests only: a kept ground read without the store's delta (its negative control)
static var kept: int = 0                    # tests only: reads that found a kept ground


static func data() -> Dictionary:
	if _d == null:
		var j = JSON.parse_string(FileAccess.get_file_as_string(FILE))
		_d = j if j is Dictionary else {}
	return _d


## The swing's data: a replay on another rate law is refused.
static func dataHash() -> String:
	var h := SimHash.Hasher.new()
	FighterData._canon(h, data())
	return h.hex()


## The planet of a seed by this generation, without changing the one in force.
static func _planet(seed: int, gen: int):
	var was: int = WorldClimate.curGen
	WorldClimate.useGen(gen)
	var P = WorldPlanet.make(seed)
	WorldClimate.useGen(was)
	return P


## The hash a gen 3 setup adds to the replay's data and so to the match key: the bake's, and keySample seeded canonical nodes', each read fresh from the planet's function and as this machine holds it, so a build that computes the field differently, or a cache that stale, is refused at the handshake. Finishes the bake if it isn't yet (a replay's header, a tool's); a host's load has done it.
static func keyHash(seed: int, gen: int = 3) -> String:
	var k: int = seed * 4 + gen
	var c = _keyOf.get(k)
	if c != null:
		return c
	var P = _planet(seed, gen)
	var F = WorldField.of(P)
	WorldField.bakeStep(F, 1 << 40)
	var h := SimHash.Hasher.new()
	h.text(F.bakeHash)
	var N: int = WorldField.cells()
	var st: int = WorldField.bakeStride()
	for n in range(int(data().get("keySample", 64))):
		var f: int = int(SimRng.keyed(seed, "field-f", n) * 6.0)
		var i: int = int(SimRng.keyed(seed, "field-i", n) * float(N))
		var j: int = int(SimRng.keyed(seed, "field-j", n) * float(N))
		if i % st == 0 and j % st == 0:
			i += 1   # a bake node would add nothing
		var fresh: Array = WorldField.nodeFresh(P, f, i, j)
		h.num(fresh[0])
		h.u(int(fresh[1]))
		h.u(int(fresh[2]))
		h.num(WorldField.nodeH(P, f, i, j))
	c = h.hex()
	_keyOf[k] = c
	return c


## ===================================================================== the frame
## Start a match's line: a great circle through unit p with unit heading t, strip x0 standing at p. A pure read of the planet from here on.
static func begin(S: SimState, seed: int, p: Array, t: Array, x0: float) -> void:
	var fr := SimState.Frame.new()
	fr.px = p[0]; fr.py = p[1]; fr.pz = p[2]
	fr.tx = t[0]; fr.ty = t[1]; fr.tz = t[2]
	fr.x0 = x0
	fr.seed = seed
	fr.gen = 3
	S.frame = fr
	S.frame0 = fr.copy()
	S.swing = SimState.Swing.new()
	cur = S


## The direction of strip x on the line: sets ox, oy, oz.
static func pointAt(S: SimState, x: float) -> void:
	pointIn(S.frame, x)


static func pointIn(fr, x: float) -> void:
	var a: float = SimWrap.sdx(fr.x0, x) / R
	var c: float = SimDetMath.cos(a)
	var s: float = SimDetMath.sin(a)
	ox = fr.px * c + fr.tx * s
	oy = fr.py * c + fr.ty * s
	oz = fr.pz * c + fr.tz * s


## The direction of strip x at depth z: the line's point turned about the line by z / R, toward the camera for z above 0: heading x point, Rendering's sd, the same at every x of a great circle. Sets ox, oy, oz.
static func placeAt(S: SimState, x: float, z: float) -> void:
	placeIn(S.frame, x, z)


static func placeIn(fr, x: float, z: float) -> void:
	pointIn(fr, x)
	if z == 0.0:
		return
	var b: float = z / R
	var c: float = SimDetMath.cos(b)
	var s: float = SimDetMath.sin(b)
	var nx: float = fr.ty * fr.pz - fr.tz * fr.py
	var ny: float = fr.tz * fr.px - fr.tx * fr.pz
	var nz: float = fr.tx * fr.py - fr.ty * fr.px
	ox = ox * c + nx * s
	oy = oy * c + ny * s
	oz = oz * c + nz * s


## The inverse: a planet direction's strip x and depth in S.frame. Sets sx, sz.
static func strip(S: SimState, qx: float, qy: float, qz: float) -> void:
	stripIn(S.frame, qx, qy, qz)


## The same in any frame (SimSwing.frameAt's: where a building will stand when the swing rests).
static func stripIn(fr, qx: float, qy: float, qz: float) -> void:
	var nx: float = fr.ty * fr.pz - fr.tz * fr.py
	var ny: float = fr.tz * fr.px - fr.tx * fr.pz
	var nz: float = fr.tx * fr.py - fr.ty * fr.px
	sz = R * WorldPlanet.asinf(qx * nx + qy * ny + qz * nz)
	sx = SimWrap.wrap(fr.x0 + R * WorldPlanet.atan2f(qx * fr.tx + qy * fr.ty + qz * fr.tz, qx * fr.px + qy * fr.py + qz * fr.pz))


## ===================================================================== the read
static func far() -> void:
	_far += 1


static func near() -> void:
	_far -= 1


## The tick's start: a scope a tick left open is closed, and this match is the one reading.
static func bindStep(S: SimState) -> void:
	_far = 0
	cur = S if S.frame != null else null


## The memo is the frame's and the store's, or it is laid again.
static func _fresh(S: SimState) -> void:
	var fr = S.frame
	if fr.tx != _kp[3] or fr.ty != _kp[4] or fr.tz != _kp[5] or fr.px != _kp[0] or fr.py != _kp[1] or fr.pz != _kp[2] or fr.x0 != _kp[6] or fr.seed != _kSeed or S.storeHash != _sh or _nc != SimConst.NC:
		_bind(S)


static func _bind(S: SimState) -> void:
	var fr = S.frame
	var F = WorldField.of(_planet(fr.seed, fr.gen))
	var same: bool = _nc == SimConst.NC and is_same(F, _F) and _stride == WorldField.bakeStride() and fr.px == _kp[0] and fr.py == _kp[1] and fr.pz == _kp[2] and fr.tx == _kp[3] and fr.ty == _kp[4] and fr.tz == _kp[5] and fr.x0 == _kp[6] and is_same(S.fieldRecs, _recs) and S.fieldRecs.size() == _recN
	if not same:   # only the store moved, or the ground before it is laid again too
		_fs += 1
		_recs = S.fieldRecs
		_recN = S.fieldRecs.size()
	_kp[0] = fr.px; _kp[1] = fr.py; _kp[2] = fr.pz; _kp[3] = fr.tx; _kp[4] = fr.ty; _kp[5] = fr.tz; _kp[6] = fr.x0
	_kSeed = fr.seed
	_sh = S.storeHash
	_serial += 1
	_changes += 1
	_F = F
	_stride = WorldField.bakeStride()
	_st = int(data().get("farStride", 8))
	if _nc != SimConst.NC:
		_nc = SimConst.NC
		_m0.resize(_nc)
		_m1.resize(_nc)
		_s0.resize(_nc)
		_s1.resize(_nc)
		_s0.fill(-1)
		_s1.fill(-1)
		_w0.resize(_nc)
		_w1.resize(_nc)
		_t0.resize(_nc)
		_t1.resize(_nc)
		_t0.fill(-1)
		_t1.fill(-1)
		_m0f.resize(_nc)
		_m1f.resize(_nc)
		_f0.resize(_nc)
		_f1.resize(_nc)
		_f0.fill(-1)
		_f1.fill(-1)


## A record joined the store (WorldStore._push; h0 is the store's hash before it). If the memos are this store's, on this line, what the record can't reach is still right: its
## term in WorldStore.heightDelta is exactly nothing there, so a read would give the same bits. Only the columns and buildings it can reach are read again. Any other state, a
## rollback or another line doesn't match h0 or the frame, and _fresh lays the memos again whole, as ever. A kind that adds no height (a crack) changes no ground.
static func storeGrew(S: SimState, h0: int, o: int) -> void:
	var fr = S.frame
	if fr == null:
		return
	var kind: int = int(S.store[o])
	if _riseH == h0:   # the rims, the same way: only the store they were added up for moves on
		_riseH = S.storeHash
		if kind == WorldStore.KIND_CRATER:
			_riseAdd(S, o)
	var height: bool = kind != WorldStore.KIND_CRACK
	var same: bool = h0 == _sh and _nc == SimConst.NC and fr.seed == _kSeed and fr.tx == _kp[3] and fr.ty == _kp[4] and fr.tz == _kp[5] and fr.px == _kp[0] and fr.py == _kp[1] and fr.pz == _kp[2] and fr.x0 == _kp[6]
	var bk0: int = h0 ^ (S.get_instance_id() << 8) ^ S.bDir.size()
	var bSame: bool = bk0 == _bKey
	if not same and not bSame:
		return
	if same:
		_sh = S.storeHash
		_changes += 1
		if height:
			_clearColumns(S, o, kind)
	if bSame:
		_bKey = S.storeHash ^ (S.get_instance_id() << 8) ^ S.bDir.size()
		if height and not _bHave.is_empty():
			_clearBuildings(S, o, kind)


## How far from its point (or its segment) a record's height reaches, in chord units, as heightDelta tests it.
static func _reachOf(S: SimState, o: int, kind: int) -> float:
	if kind == WorldStore.KIND_CRATER:
		return S.store[o + 4] * WorldStore.REACH_R
	if kind == WorldStore.KIND_SCORCH:
		return S.store[o + 4]
	return S.store[o + 8]   # a trench's half width


## Forget the columns a record can reach. A point at chord distance d from another has both its arc along the line and its depth at most 2R asin(d / 2R), under 1.05 d while d is
## under R; past that, or for a segment too long to read as straight on the strip, everything goes.
static func _clearColumns(S: SimState, o: int, kind: int) -> void:
	var reach: float = _reachOf(S, o, kind)
	var seg: bool = kind == WorldStore.KIND_TRENCH
	var len: float = 0.0
	if seg:
		var ex: float = S.store[o + 4] - S.store[o + 1]
		var ey: float = S.store[o + 5] - S.store[o + 2]
		var ez: float = S.store[o + 6] - S.store[o + 3]
		len = sqrt(ex * ex + ey * ey + ez * ez) * R
	if reach + len >= R * 0.25:
		_serial += 1
		return
	var pad: float = reach * 1.05 + 2.0 * SimConst.COL
	var sx0: float = sx   # a caller's strip read stays as it was: a store's add can come between it and its use
	var sz0: float = sz
	strip(S, S.store[o + 1], S.store[o + 2], S.store[o + 3])
	var xa: float = sx
	var za: float = sz
	var way: float = 0.0
	if seg:
		strip(S, S.store[o + 4], S.store[o + 5], S.store[o + 6])
		way = SimWrap.sdx(xa, sx)
	var zb: float = sz
	sx = sx0
	sz = sz0
	var off: float = (reach + len) * 1.05
	if absf(za) > off and absf(zb) > off:
		return
	var c0: int = int(floor((xa + minf(way, 0.0) - pad) / SimConst.COL))
	var c1: int = int(ceil((xa + maxf(way, 0.0) + pad) / SimConst.COL))
	if c1 - c0 >= _nc:
		_serial += 1
		return
	for c in range(c0, c1 + 1):
		var i: int = posmod(c, _nc)
		_s0[i] = -1
		_s1[i] = -1
		_t0[i] = -1
		_t1[i] = -1


## Forget the buildings' ground a record can reach: a building reads one point, its own.
static func _clearBuildings(S: SimState, o: int, kind: int) -> void:
	var reach: float = _reachOf(S, o, kind) * 1.001 / R
	var r2: float = reach * reach
	var ax: float = S.store[o + 1]
	var ay: float = S.store[o + 2]
	var az: float = S.store[o + 3]
	var ex: float = 0.0
	var ey: float = 0.0
	var ez: float = 0.0
	var e2: float = 0.0
	if kind == WorldStore.KIND_TRENCH:
		ex = S.store[o + 4] - ax
		ey = S.store[o + 5] - ay
		ez = S.store[o + 6] - az
		e2 = ex * ex + ey * ey + ez * ez
	for k in _bHave.keys():
		var i: int = int(k) >> 1
		var dx: float = S.bDir[i * 3] - ax
		var dy: float = S.bDir[i * 3 + 1] - ay
		var dz: float = S.bDir[i * 3 + 2] - az
		if e2 > 0.0:
			var t: float = clampf((dx * ex + dy * ey + dz * ez) / e2, 0.0, 1.0)
			dx -= ex * t
			dy -= ey * t
			dz -= ez * t
		if dx * dx + dy * dy + dz * dz < r2:
			_bHave.erase(k)


## The ground the sim stands on at direction ox, oy, oz, before a fight's strip marks: the field's height by the reader's level, World's records, the planet store.
static func _ground(S: SimState, step: int) -> float:
	var qx: float = ox
	var qy: float = oy
	var qz: float = oz
	WorldField.sample(_F, qx, qy, qz, step)
	var h: float = _F.oh
	if not S.fieldRecs.is_empty():
		h = WorldField.applyRecords(S, qx, qy, qz, h)
	if S.storeN > 0:
		h += WorldStore.heightDelta(S, qx, qy, qz)
	return h


## _ground at column c, with the part before the store's delta kept for the frame and the records (_fs): a record joining the store forgets the columns it reaches
## (storeGrew), and a re-read of one adds the store's delta to what's kept. The same bits as _ground's: the field, then the records, then the store, in that order.
static func _split(S: SimState, c: int, step: int, fine: bool) -> float:
	var qx: float = ox
	var qy: float = oy
	var qz: float = oz
	var h: float
	var have: bool = (_f1[c] if fine else _f0[c]) == _fs
	if have:
		h = _m1f[c] if fine else _m0f[c]
		kept += 1
	else:
		WorldField.sample(_F, qx, qy, qz, step)
		h = _F.oh
		if not S.fieldRecs.is_empty():
			h = WorldField.applyRecords(S, qx, qy, qz, h)
		if fine:
			_m1f[c] = h
			_f1[c] = _fs
		else:
			_m0f[c] = h
			_f0[c] = _fs
	if S.storeN > 0 and not (have and blindStore):
		h += WorldStore.heightDelta(S, qx, qy, qz)
	return h


## The untouched ground at strip column i through the frame, at the reader's level. A frame's column is read once: the memo holds for one frame and one store.
static func col(S: SimState, i: int) -> float:
	_fresh(S)
	if i < 0 or i >= _nc:
		i = posmod(i, _nc)
	if _far > 0:
		var r: int = i % _st
		var a: float = _coarse(S, i - r)
		if r == 0:
			return a
		return a + (_coarse(S, (i - r + _st) % _nc) - a) * float(r) / float(_st)
	if _s1[i] == _serial:
		return _m1[i]
	pointAt(S, float(i) * SimConst.COL)
	var h1: float = _ground(S, 1) if splitOff else _split(S, i, 1, true)
	_m1[i] = h1
	_s1[i] = _serial
	return h1


## A far read's column, on the stride: read once a frame.
static func _coarse(S: SimState, c: int) -> float:
	if _s0[c] == _serial:
		return _m0[c]
	pointAt(S, float(c) * SimConst.COL)
	var h: float = _ground(S, _stride) if splitOff else _split(S, c, _stride, false)
	_m0[c] = h
	_s0[c] = _serial
	return h


## The water the world itself holds at strip column i, at the reader's level, above the ground as it is now (`low`: the column's strip marks): the sea, derived from the ground, and World's lake and river records. A fight's own water isn't in it (S.water).
static func nativeDepth(S: SimState, i: int, low: float) -> float:
	var h: float = col(S, i)
	if i < 0 or i >= _nc:
		i = posmod(i, _nc)
	var w: float
	if S.fieldRecs.is_empty():
		w = 0.0
	elif _far > 0:
		var c0: int = i - i % _st
		if _t0[c0] != _serial:
			var hc: float = _coarse(S, c0)
			pointAt(S, float(c0) * SimConst.COL)
			_w0[c0] = WorldField.recordWater(S, ox, oy, oz, hc)
			_t0[c0] = _serial
		w = _w0[c0]
	else:
		if _t1[i] != _serial:
			pointAt(S, float(i) * SimConst.COL)
			_w1[i] = WorldField.recordWater(S, ox, oy, oz, h)
			_t1[i] = _serial
		w = _w1[i]
	var g: float = h + low
	var sea: float = WorldWater.SEA_LEVEL - g if g < WorldWater.SHORE_WET else 0.0
	return maxf(sea, w - low if w > 0.0 else 0.0)


## The untouched ground at strip x, depth z, through the frame: the depth rows' read on a field world (no memo: only with depth on).
static func atDepth(S: SimState, x: float, z: float) -> float:
	_fresh(S)
	placeAt(S, x, z)
	return _ground(S, _stride if _far > 0 else 1)


## The ground at strip x through another frame (SimSwing.frameAt's, or its one tick ahead), level 1 unless a far() scope is open, or the bake with bake true. Marks in the strip aren't in it. Writes nothing the state holds.
static func groundIn(S: SimState, fr, x: float, bake: bool = true) -> float:
	_fresh(S)
	pointIn(fr, x)
	return _ground(S, _stride if bake or _far > 0 else 1)


## The ground a building stands on at its own planet point, at the reader's level: the field, World's records (its pad) and the planet store. The same at any bearing; the line's ground under its x isn't (World: on planet 7, 91 of 173 buildings over 50 units off). Read once a store and a level.
static func buildingGround(S: SimState, i: int) -> float:
	_fresh(S)
	var key: int = S.storeHash ^ (S.get_instance_id() << 8) ^ S.bDir.size()
	if key != _bKey:
		_bKey = key
		_bHave.clear()
	var k: int = i * 2 + (1 if _far > 0 else 0)
	var v = _bHave.get(k)
	if v != null:
		return v
	ox = S.bDir[i * 3]
	oy = S.bDir[i * 3 + 1]
	oz = S.bDir[i * 3 + 2]
	var h: float = _ground(S, _stride if _far > 0 else 1)
	_bHave[k] = h
	return h


## Fills the memos a launch's plan would read cold, a few a tick, once they've been quiet for warmQuiet ticks: the coarse ground and the record water on it (groundCeilAt), then the
## buildings' ground (WorldBrunt.candidates). Two thirds of a launch tick was these first reads (Performance, docs/perf/launch-ticks-2026-11-01.md). Nothing here is state: a value is
## what the read would compute in the same state, so a match is the same to the bit, warm or cold, whatever a rollback does. A swing lays the memos again (a crater only forgets the columns it reaches) and it starts over.
static func warmStep(S: SimState) -> void:
	if S.frame == null or S.depthOn:
		return
	var d: Dictionary = data()
	_ceilStep(S, int(d.warmCeil))
	var nw: int = int(d.warmN)
	var nb: int = int(d.warmB)
	if nw <= 0 and nb <= 0:
		return
	_fresh(S)
	if _serial != _wSer:
		_wSer = _serial
		_wCur = 0
		_wB = 0
		_wQ = 0
		return
	_wQ += 1
	if _wQ < int(d.warmQuiet):
		return
	var total: int = _nc / _st
	_far += 1
	var k: int = 0
	while k < nw and _wCur < total:
		var cw: int = _wCur * _st
		_wCur += 1
		var hc: float = _coarse(S, cw)
		if not S.fieldRecs.is_empty() and _t0[cw] != _serial:
			pointAt(S, float(cw) * SimConst.COL)
			_w0[cw] = WorldField.recordWater(S, ox, oy, oz, hc)
			_t0[cw] = _serial
		k += 1
	if (_wCur >= total or nw <= 0) and nb > 0 and S.bDir.size() == S.buildings.size() * 3:
		var near: bool = S.bFirst > 0   # with places everywhere, those the pose list holds: a plan only asks about buildings near the pair
		var n: int = S.bList.size() if near else S.buildings.size()
		k = 0
		while k < nb and _wB < n:
			buildingGround(S, S.bList[_wB] if near else _wB)
			_wB += 1
			k += 1
	_far -= 1


## The highest a far read's ground, or the water on it, can be over the stretch of ceilCols columns that holds column col: on the stride's samples, with World's records and the store, the record water there, the strip's marks and a fight's water. A forecast above it over its stretch needn't read the ground or the sea at all: skipping those reads changes nothing it would compute (Combat: 98% and 93% of predictFlight's reads, where a planet-wide ceiling skipped 70% and 0%). A far level's bound, for this tick and this frame: it reads the strip, about 30 us. Infinity off a field world, or with depth on, whose rows it doesn't bound.
static func groundCeilAt(S: SimState, col_: int) -> float:
	if S.frame == null or S.depthOn:
		return INF
	return _ceilRead(S, col_)


## A box of the planet, as WorldStore's grid keys one. Any point of a stretch is in the box of the stretch's middle or one beside it, so a box is at least half a stretch.
const CEIL_BOX: float = 2048.0


static func _boxKey(ix: int, iy: int, iz: int) -> int:
	return ((ix + 64) * 128 + (iy + 64)) * 128 + (iz + 64)


## An upper bound on the same far reads as groundCeilAt, on any line, with no read of the ground: a flight above this is above all of them, whatever line the plan is on. INF where
## it can't say: the table not built yet, or a river near (its water follows the ground there). Near a face's edge it takes the tiles of every face the reads reach, and a lake
## its water's level. Whether it can say changes nothing: it's only ever
## asked first, and a flight under it asks groundCeilAt, so a match is the same to the bit with it or without it.
## The ground of a far read is a triangle of bake nodes, then World's records, then the store: the most of the nodes near, the most the records can make it, and all the rims that reach.
static func planetCeilAt(S: SimState, col_: int) -> float:
	if S.frame == null or S.depthOn:
		return INF
	_fresh(S)
	if _ctF != _F or _ctK < 6 * _ctN * _ctN or _crW != S.worldId or _crN != S.fieldRecs.size() or _crI < _crN:
		return INF
	var n: int = int(data().ceilCols)
	var c0: int = posmod(col_, _nc)
	c0 -= c0 % n
	pointAt(S, (float(c0) + 0.5 * float(n)) * SimConst.COL)
	var qx: float = ox
	var qy: float = oy
	var qz: float = oz
	var nb: int = _F.N / _F.stride
	var t: float = float(_ctT)
	var hi: float = -1.0e18
	# Each face the stretch's reads can reach: the middle put on that face by its own map (WorldField._locate's, the face forced), and the tiles round it. A read is within
	# _ctT cells of the middle on any face's map, so a face whose put middle is further out than that isn't reached, and on one that is, the tiles round the nearest
	# hold every read that falls on it. Near no edge that's the middle's own face alone, as before.
	var p4: float = SimMathx.PI / 4.0
	for face in range(6):
		var fc: Array = WorldField.FACES[face]
		var nn: Array = fc[0]
		var e1: Array = fc[1]
		var e2: Array = fc[2]
		var w: float = nn[0] * qx + nn[1] * qy + nn[2] * qz
		if w <= 0.0:
			continue
		var a: float = (WorldPlanet.atanf((e1[0] * qx + e1[1] * qy + e1[2] * qz) / w) / p4 + 1.0) * 0.5 * float(nb)
		var b: float = (WorldPlanet.atanf((e2[0] * qx + e2[1] * qy + e2[2] * qz) / w) / p4 + 1.0) * 0.5 * float(nb)
		if a < -t or b < -t or a > float(nb) + t or b > float(nb) + t:
			continue
		var ti: int = clampi(int(floor(a / t)), 0, _ctN - 1)
		var tj: int = clampi(int(floor(b / t)), 0, _ctN - 1)
		for j in range(maxi(tj - 1, 0), mini(tj + 2, _ctN)):
			for i in range(maxi(ti - 1, 0), mini(ti + 2, _ctN)):
				hi = maxf(hi, _ct[(face * _ctN + j) * _ctN + i])
	if hi == -1.0e18:
		return INF
	if _riseH != S.storeHash:
		_riseBuild(S)
	var r: float = _R_BOX()
	var ix: int = int(floor(qx * r))
	var iy: int = int(floor(qy * r))
	var iz: int = int(floor(qz * r))
	var rise: float = 0.0
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			for dz in range(-1, 2):
				var key: int = _boxKey(ix + dx, iy + dy, iz + dz)
				var v = _cr.get(key)
				if v != null:
					if v == INF:
						return INF
					hi = maxf(hi, v)
				var w = _rise.get(key)
				if w != null:
					rise = maxf(rise, w)
	return maxf(hi + rise + _marksOver(S, c0, n), WorldWater.SEA_LEVEL)


## Boxes to a unit direction's number.
static func _R_BOX() -> float:
	return R / CEIL_BOX


## The most the strip's own marks and made water add over a stretch.
static func _marksOver(S: SimState, c0: int, n: int) -> float:
	var low: PackedFloat32Array = WorldTerrain.lowD(S)
	var mark: float = 0.0
	var made: float = 0.0
	for k in range(c0, c0 + n + 1):
		var cw2: int = k % _nc
		mark = maxf(mark, S.deform[cw2])
		mark = maxf(mark, low[cw2])
		made = maxf(made, S.water[cw2])
	return mark + made


## Every box a reach of `reach` round a unit direction touches, as WorldStore._list lists a record.
static func _boxesOf(qx: float, qy: float, qz: float, reach: float) -> Array:
	var r: float = reach / CEIL_BOX
	var q: float = _R_BOX()
	var x0: int = int(floor(qx * q - r))
	var x1: int = int(floor(qx * q + r))
	var y0: int = int(floor(qy * q - r))
	var y1: int = int(floor(qy * q + r))
	var z0: int = int(floor(qz * q - r))
	var z1: int = int(floor(qz * q + r))
	var out: Array = []
	for ix in range(x0, x1 + 1):
		for iy in range(y0, y1 + 1):
			for iz in range(z0, z1 + 1):
				out.append(_boxKey(ix, iy, iz))
	return out


## A crater's rim added to the boxes it reaches. Past u = 2 a crater adds nothing, and nowhere does it add more than its rim (WorldCrater.profile). The scorches and trenches only dig.
static func _riseAdd(S: SimState, o: int) -> void:
	var hr: float = S.store[o + 6]
	if hr <= 0.0:
		return
	for key in _boxesOf(S.store[o + 1], S.store[o + 2], S.store[o + 3], S.store[o + 4] * WorldStore.REACH_R):
		_rise[key] = float(_rise.get(key, 0.0)) + hr


static func _riseBuild(S: SimState) -> void:
	_rise.clear()
	for k in range(S.storeN):
		var o: int = k * WorldStore.STRIDE
		if int(S.store[o]) == WorldStore.KIND_CRATER:
			_riseAdd(S, o)
	_riseH = S.storeHash


## The tiles and the records, `budget` tiles and four times that many records a tick: a flight over ground it hasn't reached yet reads it, as ever.
static func _ceilStep(S: SimState, budget: int) -> void:
	if budget <= 0:
		return
	_fresh(S)
	if not _F.bakeDone:
		return   # a node the bake hasn't reached isn't in the arrays yet
	if _ctF != _F:
		_ctF = _F
		_ctK = 0
		var nb: int = _F.N / _F.stride
		# A stretch's half and the cell its read interpolates, in bake cells: a cell is never under 0.6 of its middle's arc, by the cube's map.
		_ctT = int(ceil((0.5 * float(data().ceilCols) * SimConst.COL + SimConst.COL) / (R * SimMathx.PI * 0.5 / float(nb) * 0.6))) + 1
		_ctN = (nb + _ctT - 1) / _ctT
		_ct.resize(6 * _ctN * _ctN)
	var total: int = 6 * _ctN * _ctN
	var nb2: int = _F.N / _F.stride
	var left: int = budget
	while left > 0 and _ctK < total:
		var k: int = _ctK
		var i: int = k % _ctN
		var r: int = k / _ctN
		var j: int = r % _ctN
		var face: int = r / _ctN
		var hi: float = -1.0e18
		var side2: int = _F.side
		var base: int = face * side2 * side2
		for bj in range(j * _ctT, mini((j + 1) * _ctT, nb2) + 1):
			var row: int = base + bj * _F.stride * side2
			for bi in range(i * _ctT, mini((i + 1) * _ctT, nb2) + 1):
				hi = maxf(hi, _F.h[row + bi * _F.stride])
		_ct[k] = hi
		_ctK += 1
		left -= 1
	if _crW != S.worldId or _crN != S.fieldRecs.size():
		_crW = S.worldId
		_crN = S.fieldRecs.size()
		_crI = 0
		_cr.clear()
	var m: int = budget * 4
	while m > 0 and _crI < _crN:
		_ceilRec(S.fieldRecs[_crI])
		_crI += 1
		m -= 1


## One of World's records: the most it can make the ground (WorldField.applyRecords), or INF for water, which a read takes from the ground under it.
static func _ceilRec(rec: Dictionary) -> void:
	var kind: String = rec.k
	if kind == "far":
		return
	var top: float = INF
	var reach: float = 0.0
	var c: Array = rec.get("c", [0.0, 0.0, 0.0])
	if kind == "platform":
		top = float(rec.floor)
		reach = float(rec.r) + float(rec.blend)
		c = [rec.px, rec.py, rec.pz]
	elif kind == "pad":
		top = float(rec.h)
		reach = float(rec.r) + float(rec.blend)
	elif kind == "lot":
		top = float(rec.h) + absf(float(rec.get("gt", 0.0))) * float(rec.hl) + absf(float(rec.get("gs", 0.0))) * float(rec.hd)
		reach = float(rec.hl) + float(rec.hd) + float(rec.blend) + float(rec.get("bs", rec.blend))
	elif kind == "lake":   # it changes no ground, and its water stands no higher than its level (WorldWaterRec.lakeDepth), where the index lists it
		top = float(rec.level)
		reach = float(rec.r) + float(rec.get("blend", 0.0))
		if not rec.has("c"):
			c = [rec.get("px", 0.0), rec.get("py", 0.0), rec.get("pz", 0.0)]
	else:
		reach = float(rec.get("r", 1.0e18))   # a lake, a river, a kind not known here: this ground isn't the table's to say
	if reach >= 2.0 * R:
		reach = 2.0 * R
	for key in _boxesOf(c[0], c[1], c[2], reach):
		var v = _cr.get(key)
		_cr[key] = maxf(float(v), top) if v != null else top


static func _ceilRead(S: SimState, col_: int) -> float:
	_fresh(S)
	var n: int = int(data().ceilCols)
	var c0: int = posmod(col_, _nc)
	c0 -= c0 % n
	_far += 1
	var hi: float = -1.0e18
	var wet: float = 0.0
	var c: int = c0
	while c <= c0 + n:
		var cw: int = c % _nc
		hi = maxf(hi, _coarse(S, cw))
		if not S.fieldRecs.is_empty() and c < c0 + n:
			if _t0[cw] != _serial:
				var hc: float = _coarse(S, cw)
				pointAt(S, float(cw) * SimConst.COL)
				_w0[cw] = WorldField.recordWater(S, ox, oy, oz, hc)
				_t0[cw] = _serial
			wet = maxf(wet, _w0[cw])
		c += _st
	_far -= 1
	return maxf(hi + wet + _marksOver(S, c0, n), WorldWater.SEA_LEVEL)


## The ground at a direction by level, 0 the bake, 1 the 128 ground: pure, no frame, no records, no store (Rendering's CPU twin, Camera's tall land).
static func heightOf(seed: int, gen: int, level: int, qx: float, qy: float, qz: float) -> float:
	var P = _planet(seed, gen)
	return WorldField.height(P, qx, qy, qz) if level == 1 else WorldField.heightBake(P, qx, qy, qz)


## The memo's serial once bound to S: moves whenever the frame, the swing or the store the memo reads changes (World's contact table memoises a column's ground on it).
static func serialOf(S: SimState) -> int:
	_fresh(S)
	return _changes


## The stored biome (WorldPlanet.BIO_*, an index into WorldPlanetWorld.BIOME_NAME) at strip x through the frame, on the bake: Camera's biome by strip x, and WorldBiomes once the line has swung, so a swing changes the biome under a fight.
static func biomeAt(S: SimState, x: float) -> int:
	_fresh(S)
	pointAt(S, x)
	WorldField.sample(_F, ox, oy, oz, _stride)
	return _F.ob


## The fine biome at strip x through the frame, on the bake.
static func fineAt(S: SimState, x: float) -> int:
	_fresh(S)
	pointAt(S, x)
	WorldField.sample(_F, ox, oy, oz, _stride)
	return _F.ofine


## True on a field world once a swing has moved the line: the columns a match was laid on no longer name what's under it.
static func swung() -> bool:
	return cur != null and cur.swing.n > 0


## The whole strip through the frame at the reader's level, for a tool or the old ground renderer: a new array, not the sim's. A view may call this any time; it writes only the memo.
static func layStrip(S: SimState) -> PackedFloat32Array:
	var a := PackedFloat32Array()
	a.resize(SimConst.NC)
	for i in range(SimConst.NC):
		a[i] = col(S, i)
	return a
