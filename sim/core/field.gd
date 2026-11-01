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
static var _nc: int = 0
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
	_kp[0] = fr.px; _kp[1] = fr.py; _kp[2] = fr.pz; _kp[3] = fr.tx; _kp[4] = fr.ty; _kp[5] = fr.tz; _kp[6] = fr.x0
	_kSeed = fr.seed
	_sh = S.storeHash
	_serial += 1
	_F = WorldField.of(_planet(fr.seed, fr.gen))
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
	pointIn(S.frame, float(i) * SimConst.COL)
	var h1: float = _ground(S, 1)
	_m1[i] = h1
	_s1[i] = _serial
	return h1


## A far read's column, on the stride: read once a frame.
static func _coarse(S: SimState, c: int) -> float:
	if _s0[c] == _serial:
		return _m0[c]
	pointIn(S.frame, float(c) * SimConst.COL)
	var h: float = _ground(S, _stride)
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
			pointIn(S.frame, float(c0) * SimConst.COL)
			_w0[c0] = WorldField.recordWater(S, ox, oy, oz, hc)
			_t0[c0] = _serial
		w = _w0[c0]
	else:
		if _t1[i] != _serial:
			pointIn(S.frame, float(i) * SimConst.COL)
			_w1[i] = WorldField.recordWater(S, ox, oy, oz, h)
			_t1[i] = _serial
		w = _w1[i]
	var g: float = h + low
	var sea: float = WorldWater.SEA_LEVEL - g if g < WorldWater.SHORE_WET else 0.0
	return maxf(sea, w - low if w > 0.0 else 0.0)


## The untouched ground at strip x, depth z, through the frame: the depth rows' read on a field world (no memo: only with depth on).
static func atDepth(S: SimState, x: float, z: float) -> float:
	_fresh(S)
	placeIn(S.frame, x, z)
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


## The highest a far read's ground, or the water on it, can be over the stretch of ceilCols columns that holds column col: on the stride's samples, with World's records and the store, the record water there, the strip's marks and a fight's water. A forecast above it over its stretch needn't read the ground or the sea at all: skipping those reads changes nothing it would compute (Combat: 98% and 93% of predictFlight's reads, where a planet-wide ceiling skipped 70% and 0%). A far level's bound, for this tick and this frame: it reads the strip, about 30 us. Infinity off a field world, or with depth on, whose rows it doesn't bound.
static func groundCeilAt(S: SimState, col_: int) -> float:
	if S.frame == null or S.depthOn:
		return INF
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
				pointIn(S.frame, float(cw) * SimConst.COL)
				_w0[cw] = WorldField.recordWater(S, ox, oy, oz, hc)
				_t0[cw] = _serial
			wet = maxf(wet, _w0[cw])
		c += _st
	_far -= 1
	var low: PackedFloat32Array = WorldTerrain.lowD(S)
	var mark: float = 0.0
	var made: float = 0.0
	for k in range(c0, c0 + n + 1):
		var cw2: int = k % _nc
		mark = maxf(mark, S.deform[cw2])
		mark = maxf(mark, low[cw2])
		made = maxf(made, S.water[cw2])
	return maxf(hi + wet + mark + made, WorldWater.SEA_LEVEL)


## The ground at a direction by level, 0 the bake, 1 the 128 ground: pure, no frame, no records, no store (Rendering's CPU twin, Camera's tall land).
static func heightOf(seed: int, gen: int, level: int, qx: float, qy: float, qz: float) -> float:
	var P = _planet(seed, gen)
	return WorldField.height(P, qx, qy, qz) if level == 1 else WorldField.heightBake(P, qx, qy, qz)


## The memo's serial once bound to S: moves whenever the frame, the swing or the store the memo reads changes (World's contact table memoises a column's ground on it).
static func serialOf(S: SimState) -> int:
	_fresh(S)
	return _serial


## The stored biome (WorldPlanet.BIO_*, an index into WorldPlanetWorld.BIOME_NAME) at strip x through the frame, on the bake: Camera's biome by strip x, and WorldBiomes once the line has swung, so a swing changes the biome under a fight.
static func biomeAt(S: SimState, x: float) -> int:
	_fresh(S)
	pointIn(S.frame, x)
	WorldField.sample(_F, ox, oy, oz, _stride)
	return _F.ob


## The fine biome at strip x through the frame, on the bake.
static func fineAt(S: SimState, x: float) -> int:
	_fresh(S)
	pointIn(S.frame, x)
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
