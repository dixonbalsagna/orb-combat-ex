class_name WorldPlanet
## The stored procedural planet: a seed, a pure function of the point on the sphere, a short places list, the slice picker, the slice read and a run's wear list
## (docs/world/planet-slice.md, planet-ice.md, planet-module.md). Window 1: nothing in the game reads it yet.
##
## Determinism (docs/architecture/planet-slice-core.md section 3, planet-proof/p64lib.gd): float64 scalars only (no Vector3, no Vector2: they are float32),
## + - * / sqrt floor, SimDetMath.sin cos pow, SimRng, integer hashing; and our own atan, asin and acos below, fixed series built from + - * / only. Heights are
## computed in float64 and stored as float32, as S.base is. Every number is in data/biomes/planet.json. A planet is memoised (its places and its cell caches):
## a cache never changes a result, it only stops work being done twice.
##
## A point is three floats (px, py, pz), a unit vector; y is the axis (the poles are y = 1 north, y = -1 south).

const SCHEMA := "biomes.planet/1"
const PATH := "res://data/biomes/planet.json"
const BIO_OCEAN := 0
const BIO_PLAINS := 1
const BIO_FOREST := 2
const BIO_DESERT := 3
const BIO_MOUNTAINS := 4
const BIO_ICE_SHEET := 5
const BIO_SEA_ICE := 6
const KIND_CITY := 0
const KIND_TOWN := 1
## The touch-down is the middle column of its slice (the seam is the antipode); the slice is the arena's columns (SimConst.NC).
static func touchCol() -> int:
	return SimConst.NC / 2
const MASK := 0xFFFFFFFF

static var _TAN_PI_8: float = SimMathx.f64("3fda827999fcef32")   # tan(pi/8) = sqrt(2) - 1, from its bits (the parity lint allows no float literal over 15 digits)

static var _c: Dictionary = {}
static var _cLoaded: bool = false
static var _cErrors: Array = []
static var _cHash: String = ""
static var _planets: Dictionary = {}     # seed -> Planet
static var _slices: Dictionary = {}      # memo of slices (outside the sim state), a few entries


## ===================================================================== the data
static func cfg() -> Dictionary:
	if not _cLoaded:
		_cLoad()
	return _c


static func dataErrors() -> Array:
	if not _cLoaded:
		_cLoad()
	return _cErrors


## Folded into the replay's data hash when a planet is used.
static func dataHash() -> String:
	if not _cLoaded:
		_cLoad()
	if WorldClimate.genNow() >= 2:
		return _cHash + "/g2/" + WorldClimate.dataHash() + "/" + WorldLand.dataHash() + "/" + WorldSites.dataHash()   # a gen 2 planet's slices are not a gen 1 planet's, and follow climate.json and land.json
	return _cHash


static func _cLoad() -> void:
	_cLoaded = true
	_cErrors = []
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		_cErrors.append("planet.json: cannot open " + PATH)
		return
	var text: String = f.get_as_text()
	var j = JSON.parse_string(text)
	if not (j is Dictionary) or j.get("schema", "") != SCHEMA:
		_cErrors.append("planet.json: schema is not " + SCHEMA)
		return
	_c = j
	for k in j:
		if str(k).begins_with("_") or k == "schema" or k == "story":
			continue
		if not (j[k] is float or j[k] is int):
			_cErrors.append("planet.json: %s is not a number" % k)
	_cHash = str(text.hash())


## ===================================================================== our own inverse trig (fixed series, + - * / only)
## atan to about 1e-11: reduce to [0, 0.4143] by 1/x and by (x - 1) / (x + 1), then twelve terms of the series.
static func atanf(x: float) -> float:
	var a: float = absf(x)
	var inv: bool = a > 1.0
	if inv:
		a = 1.0 / a
	var off: float = 0.0
	if a > _TAN_PI_8:
		a = (a - 1.0) / (a + 1.0)
		off = SimMathx.PI / 4.0
	var a2: float = a * a
	var s: float = a
	var t: float = a
	for k in range(1, 12):
		t = -t * a2
		s += t / float(2 * k + 1)
	var r: float = off + s
	if inv:
		r = SimMathx.PI / 2.0 - r
	return -r if x < 0.0 else r


static func atan2f(y: float, x: float) -> float:
	if x > 0.0:
		return atanf(y / x)
	if x < 0.0:
		if y >= 0.0:
			return atanf(y / x) + SimMathx.PI
		return atanf(y / x) - SimMathx.PI
	if y > 0.0:
		return SimMathx.PI / 2.0
	if y < 0.0:
		return -SimMathx.PI / 2.0
	return 0.0


static func asinf(x: float) -> float:
	var c: float = x
	if c > 1.0:
		c = 1.0
	if c < -1.0:
		c = -1.0
	return atan2f(c, sqrt(1.0 - c * c))


static func acosf(x: float) -> float:
	var c: float = x
	if c > 1.0:
		c = 1.0
	if c < -1.0:
		c = -1.0
	return atan2f(sqrt(1.0 - c * c), c)


## ===================================================================== the noise (integer lattice hash, as the proof's p64lib)
static func _fm(x: int) -> int:   # SimRng.imul written out (one call, not three): the same bits
	x &= MASK
	x ^= x >> 16
	x = (x * 0xca6b + (((x * 0x85eb) & 0xFFFF) << 16)) & MASK
	x ^= x >> 13
	x = (x * 0xae35 + (((x * 0xc2b2) & 0xFFFF) << 16)) & MASK
	x ^= x >> 16
	return x & MASK


static func _lat(ix: int, iy: int, iz: int, s: int) -> float:
	return float(_fm(_fm(_fm(s ^ (ix & MASK)) ^ (iy & MASK)) ^ (iz & MASK))) / 4294967296.0


## The lattice corners of the cell last read at each noise (a slot a seed; the planet read walks a ring column by column, 32 units at a time, so most columns are in the cell of the one before): derived data
## outside the sim state, a pure memo of _lat, so the numbers are the hash's own.
static var _vcSlot: Dictionary = {}
static var _vcKey := PackedInt64Array()    # ix, iy, iz of each slot's cell
static var _vcVal := PackedFloat64Array()  # its 8 corners: c000 c100 c010 c110 c001 c101 c011 c111


static func _vcNew(s: int) -> int:
	if _vcSlot.size() >= 4096:
		_vcSlot.clear()
		_vcKey.resize(0)
		_vcVal.resize(0)
	var slot: int = _vcSlot.size()
	_vcSlot[s] = slot
	_vcKey.resize((slot + 1) * 3)
	_vcVal.resize((slot + 1) * 8)
	_vcKey[slot * 3] = -4611686018427387904   # no cell yet
	return slot


## The 8 corner values of the cell (ix, iy, iz): _lat of each corner, the hash of the shared prefixes done once (14 hashes, not 24).
static func _vcFill(slot: int, ix: int, iy: int, iz: int, s: int) -> void:
	var mx0: int = ix & MASK
	var mx1: int = (ix + 1) & MASK
	var my0: int = iy & MASK
	var my1: int = (iy + 1) & MASK
	var mz0: int = iz & MASK
	var mz1: int = (iz + 1) & MASK
	var a0: int = _fm(s ^ mx0)
	var a1: int = _fm(s ^ mx1)
	var b00: int = _fm(a0 ^ my0)
	var b10: int = _fm(a1 ^ my0)
	var b01: int = _fm(a0 ^ my1)
	var b11: int = _fm(a1 ^ my1)
	var vb: int = slot * 8
	_vcVal[vb] = float(_fm(b00 ^ mz0)) / 4294967296.0
	_vcVal[vb + 1] = float(_fm(b10 ^ mz0)) / 4294967296.0
	_vcVal[vb + 2] = float(_fm(b01 ^ mz0)) / 4294967296.0
	_vcVal[vb + 3] = float(_fm(b11 ^ mz0)) / 4294967296.0
	_vcVal[vb + 4] = float(_fm(b00 ^ mz1)) / 4294967296.0
	_vcVal[vb + 5] = float(_fm(b10 ^ mz1)) / 4294967296.0
	_vcVal[vb + 6] = float(_fm(b01 ^ mz1)) / 4294967296.0
	_vcVal[vb + 7] = float(_fm(b11 ^ mz1)) / 4294967296.0
	var kb: int = slot * 3
	_vcKey[kb] = ix
	_vcKey[kb + 1] = iy
	_vcKey[kb + 2] = iz


static func _vn(x: float, y: float, z: float, s: int) -> float:
	var fx: float = floor(x)
	var fy: float = floor(y)
	var fz: float = floor(z)
	var ix: int = int(fx)
	var iy: int = int(fy)
	var iz: int = int(fz)
	var tx: float = x - fx
	var ty: float = y - fy
	var tz: float = z - fz
	tx = tx * tx * (3.0 - 2.0 * tx)
	ty = ty * ty * (3.0 - 2.0 * ty)
	tz = tz * tz * (3.0 - 2.0 * tz)
	var slot: int = _vcSlot.get(s, -1)
	if slot < 0:
		slot = _vcNew(s)
	var kb: int = slot * 3
	if _vcKey[kb] != ix or _vcKey[kb + 1] != iy or _vcKey[kb + 2] != iz:
		_vcFill(slot, ix, iy, iz, s)
	var vb: int = slot * 8
	var c000: float = _vcVal[vb]
	var c100: float = _vcVal[vb + 1]
	var c010: float = _vcVal[vb + 2]
	var c110: float = _vcVal[vb + 3]
	var c001: float = _vcVal[vb + 4]
	var c101: float = _vcVal[vb + 5]
	var c011: float = _vcVal[vb + 6]
	var c111: float = _vcVal[vb + 7]
	var a: float = c000 + (c100 - c000) * tx
	var b: float = c010 + (c110 - c010) * tx
	var c: float = c001 + (c101 - c001) * tx
	var d: float = c011 + (c111 - c011) * tx
	var e: float = a + (b - a) * ty
	var f: float = c + (d - c) * ty
	return e + (f - e) * tz


## Octaves left out of every _fbm, for farField's coarse read only (set and reset inside it); 0 everywhere else.
static var _octOff: int = 0


static func _fbm(R: float, px: float, py: float, pz: float, scale: float, oct: int, s: int) -> float:
	var sum: float = 0.0
	var amp: float = 0.5
	var tot: float = 0.0
	var k: float = R / scale
	for o in range(maxi(1, oct - _octOff)):
		sum += amp * _vn(px * k, py * k, pz * k, s + o * 101)
		tot += amp
		amp *= 0.5
		k *= 2.0
	return sum / tot


static func _ss(a: float) -> float:
	var t: float = a
	if t < 0.0:
		t = 0.0
	if t > 1.0:
		t = 1.0
	return t * t * (3.0 - 2.0 * t)


## ===================================================================== a planet
class Planet extends RefCounted:
	var seed: int = 0
	var R: float = 0.0
	var L: float = 0.0
	var c: Dictionary = {}
	var n: int = 0                           # places
	var kind := PackedByteArray()
	var px := PackedFloat64Array()
	var py := PackedFloat64Array()
	var pz := PackedFloat64Array()
	var rad := PackedFloat64Array()
	var people := PackedInt32Array()         # a place's share of a full slice's people, per ten thousand of the planet's weight (see WorldPlanet.placeWeight)
	var wf: Dictionary = {}                  # cell caches for the cellular noise (floes, bergs)
	var wb: Dictionary = {}
	var wd: float = 0.0                      # the last cellular noise result: distance in cells and the cell's random
	var wr: float = 0.0
	var outH: float = 0.0
	var outB: int = 0
	var outF: int = -1                       # gen 2: the fine biome of the last surfAt (WorldClimate.F_*); -1 where the stored biome is the fine one (sea, ice, a dome)
	var gen: int = 1                         # the generation this planet is made by (WorldClimate.genNow)
	var grid = null                          # gen 2: the climate grid (WorldClimate.Grid), made when first asked
	var plates = null                        # gen 2: the plates (WorldLand.Plates), made when first asked


## Memoised by the seed: the planet is a pure function of it and of the data.
static func make(seed: int) -> Planet:
	var gn: int = WorldClimate.genNow()
	var key: int = seed * 4 + gn
	if _planets.has(key):
		return _planets[key]
	var P: Planet = _newPlanet(seed, gn)
	if gn >= 2:
		WorldClimate.gridOf(P)   # the climate grid before the places are scored
	_placeAll(P)
	_memoPlanet(key, P)
	return P


static func _newPlanet(seed: int, gn: int) -> Planet:
	var P := Planet.new()
	P.seed = seed
	P.gen = gn
	P.c = cfg()
	if gn >= 2:   # gen 2's own numbers over the stored ones (the polar caps are smaller: there is room for cold biomes)
		P.c = cfg().duplicate()
		for k in WorldClimate.data().planet:
			P.c[k] = WorldClimate.data().planet[k]
	P.L = float(SimConst.PLANET_NC) * SimConst.COL
	P.R = P.L / (2.0 * SimMathx.PI)
	return P


static func _memoPlanet(key: int, P: Planet) -> void:
	if _planets.size() > 6:
		_planets.clear()
	_planets[key] = P


## A planet made in steps (a host spends a budget a frame; the module owns no clock): the climate grid of a gen 2 planet first (a budget unit is a grid cell, about 20 microseconds), then the places, a try-set
## (cost PLACE_COST units, about 20 ms) at a time. `step(budget)` returns true when `P` is whole and memoised, where make(seed) then finds it at once. make(seed) is this job run to the end.
class PlanetJob extends RefCounted:
	const PLACE_COST: int = 1000
	var seed: int = 0
	var key: int = 0
	var P: WorldPlanet.Planet
	var done: bool = false
	var _grid = null
	var _st: Dictionary = {}

	func _init(sd: int) -> void:
		seed = sd
		var gn: int = WorldClimate.genNow()
		key = sd * 4 + gn
		if WorldPlanet._planets.has(key):
			P = WorldPlanet._planets[key]
			done = true
			return
		P = WorldPlanet._newPlanet(sd, gn)
		if gn >= 2:
			_grid = WorldClimate.Grid.new(P)
		_st = WorldPlanet._placeBegin(P)

	func step(budget: int) -> bool:
		if done:
			return true
		var left: int = budget
		if _grid != null:
			var before: int = _grid.cell
			_grid.step(left)
			left -= _grid.cell - before
			if not _grid.done:
				return false
			P.grid = _grid
			_grid = null
		while true:
			if WorldPlanet._placeStep(P, _st):
				WorldPlanet._memoPlanet(key, P)
				done = true
				return true
			left -= PLACE_COST
			if left <= 0:
				return false
		return done


static func makeJob(seed: int) -> PlanetJob:
	return PlanetJob.new(seed)


static func forget() -> void:
	_planets.clear()
	_slices.clear()


## ===================================================================== the surface at a point
static func _worley(P: Planet, which: int, px: float, py: float, pz: float, cell: float, s: int) -> void:
	var cache: Dictionary = P.wf if which == 0 else P.wb
	var k: float = P.R / cell
	var qx: float = px * k
	var qy: float = py * k
	var qz: float = pz * k
	var ix: int = int(floor(qx))
	var iy: int = int(floor(qy))
	var iz: int = int(floor(qz))
	var best: float = 1.0e9
	var br: float = 0.0
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			for dz in range(-1, 2):
				var cx: int = ix + dx
				var cy: int = iy + dy
				var cz: int = iz + dz
				var key: int = ((cx + 4096) << 26) | ((cy + 4096) << 13) | (cz + 4096)
				var fp = cache.get(key)
				if fp == null:
					fp = [float(cx) + _lat(cx, cy, cz, s), float(cy) + _lat(cx, cy, cz, s + 11), float(cz) + _lat(cx, cy, cz, s + 23), _lat(cx, cy, cz, s + 37)]
					cache[key] = fp
				var d: float = sqrt((fp[0] - qx) * (fp[0] - qx) + (fp[1] - qy) * (fp[1] - qy) + (fp[2] - qz) * (fp[2] - qz))
				if d < best:
					best = d
					br = fp[3]
	P.wd = best
	P.wr = br
	if cache.size() > 30000:
		cache.clear()


## The ordinary ground (no ice): the continents and the ranges. Height in units.
static func ground(P: Planet, px: float, py: float, pz: float) -> float:
	var c: Dictionary = P.c
	var s: int = P.seed
	var e: float = (_fbm(P.R, px, py, pz, c.contScale, int(c.contOct), s) - 0.5) * 2.0
	var h: float = (e + c.seaShift) * c.hMul
	if e > c.rangeFrom:
		var m: float = _fbm(P.R, px, py, pz, c.reliefScale, int(c.reliefOct), s + int(c.sRelief))
		if P.gen >= 2:
			h += (e - c.rangeFrom) * c.rangeMul * (c.reliefBase + m) * WorldLand.keep()   # gen 2: the plates build the ranges, the stored blobs are weaker
		else:
			h += (e - c.rangeFrom) * c.rangeMul * (c.reliefBase + m)
	if P.gen >= 2:
		h = WorldLand.shape(P, px, py, pz, h)   # ranges and rifts along the plate edges, the shoreline, plateaus and canyons (window 3)
	return h


static func _plainBiome(P: Planet, px: float, py: float, pz: float, h: float) -> int:
	if P.gen >= 2:
		return WorldClimate.plain(P, px, py, pz, h)
	var c: Dictionary = P.c
	if h < 0.0:
		return BIO_OCEAN
	if h > c.mountainAbove:
		return BIO_MOUNTAINS
	var s: int = P.seed
	var w: float = _fbm(P.R, px, py, pz, c.wetScale, int(c.wetOct), s + int(c.sWet))
	var t: float = 1.0 - absf(py) * c.tempLat + (_fbm(P.R, px, py, pz, c.tempScale, int(c.tempOct), s + int(c.sTemp)) - 0.5) * c.tempNoise
	if w < c.desertWet and t > c.desertTemp:
		return BIO_DESERT
	if w > c.forestWet:
		return BIO_FOREST
	return BIO_PLAINS


## The surface at a point, one call: sets P.outH (height, units, float64) and P.outB (the biome). One call a column (the saving the EP asked for); the cellular
## noise's cells are cached per planet (the coarse floe field): the cache returns exactly what a fresh read would.
static func surfAt(P: Planet, px: float, py: float, pz: float) -> void:
	var c: Dictionary = P.c
	var s: int = P.seed
	var y: float = py
	P.outF = -1
	var base: float = ground(P, px, py, pz)
	var polarY: float = c.polarY
	if P.gen >= 2:
		polarY += WorldLand.polarWob(P, px, py, pz)   # a ragged edge to the polar zone, not a ruled latitude (window 3)
	if absf(y) < polarY:
		P.outH = base
		P.outB = _plainBiome(P, px, py, pz, base)
		return
	if y > 0.0:
		var wN: float = _ss((y - polarY) / c.blend)
		var sea: float = c.seaNorth + (_fbm(P.R, px, py, pz, c.seaNoiseScale, int(c.seaNoiseOct), s + int(c.sSea)) - 0.5) * c.seaNoiseAmp
		var conc: float = (y - c.packEdgeY) / c.packWidth + (_fbm(P.R, px, py, pz, c.packNoiseScale, int(c.packNoiseOct), s + int(c.sPackEdge)) - 0.5) * c.packNoiseAmp
		if conc > c.packMin:
			_worley(P, 0, px, py, pz, c.floeCell, s + int(c.sFloe))
			var cc: float = conc
			if cc < 0.0:
				cc = 0.0
			if cc > 1.0:
				cc = 1.0
			if P.wr < SimDetMath.pow(cc, c.floePow) * c.floeCap and P.wd < c.floeR0 + c.floeR1 * cc:
				P.outH = (c.floeH0 + c.floeH1 * P.wr) * (c.floeThin0 + c.floeThin1 * cc)
				P.outB = BIO_SEA_ICE
				return
		if conc > c.bergBandLo and conc < c.bergBandHi:
			_worley(P, 1, px, py, pz, c.bergCell, s + int(c.sBerg))
			var dm: float = absf(conc - c.bergBandMid) * c.bergBandSlope
			if dm > 1.0:
				dm = 1.0
			var rate: float = c.bergRate * (1.0 - dm)
			if P.wr < rate and P.wd < c.bergRadius:
				P.outH = c.bergH0 + c.bergH1 * (P.wr / (rate if rate > 0.001 else 0.001))
				P.outB = BIO_SEA_ICE
				return
		P.outH = base + (sea - base) * wN
		P.outB = BIO_OCEAN if wN >= 1.0 else _plainBiome(P, px, py, pz, P.outH)
		return
	var ys: float = -y
	var wS: float = _ss((ys - polarY) / c.blend)
	var seaS: float = c.seaSouth + (_fbm(P.R, px, py, pz, c.seaNoiseScale, int(c.seaNoiseOct), s + int(c.sSea)) - 0.5) * c.seaNoiseAmp
	var m: float = (ys - c.southMaskY) / c.southWidth + (_fbm(P.R, px, py, pz, c.southMaskScale, int(c.southMaskOct), s + int(c.sSouthMask)) - 0.5) * c.southMaskAmp
	if m > 0.0:
		var mm: float = m if m < c.domeMax else c.domeMax
		var h: float = c.domeBase + mm * c.domeMul + (_fbm(P.R, px, py, pz, c.domeReliefScale, int(c.domeReliefOct), s + int(c.sSouthRelief)) - 0.5) * c.domeReliefAmp
		if h < c.shelfH:
			h = c.shelfH   # the continent never dips below the shelf it stands on
		P.outH = h
		P.outB = BIO_ICE_SHEET
		if h > c.rockHeight and _fbm(P.R, px, py, pz, c.rockScale, int(c.rockOct), s + int(c.sRock)) > c.rockNoise:
			P.outB = BIO_MOUNTAINS
		return
	if m > c.shelfFrom:
		P.outH = c.shelfH + (_fbm(P.R, px, py, pz, c.shelfNoiseScale, int(c.shelfNoiseOct), s + int(c.sShelf)) - 0.5) * c.shelfNoiseAmp
		P.outB = BIO_ICE_SHEET
		return
	if m > c.southBergFrom:
		_worley(P, 1, px, py, pz, c.bergCell, s + int(c.sBerg))
		if P.wr < c.southBergRate and P.wd < c.bergRadius:
			P.outH = c.bergH0 + c.bergH1 * (P.wr / c.southBergRate)
			P.outB = BIO_SEA_ICE
			return
	P.outH = base + (seaS - base) * wS
	P.outB = BIO_OCEAN if wS >= 1.0 else _plainBiome(P, px, py, pz, P.outH)


## Height and biome as a pair, for tests and tools (the hot paths use surfAt).
static func surf(P: Planet, px: float, py: float, pz: float) -> Array:
	surfAt(P, px, py, pz)
	return [P.outH, P.outB]


## ===================================================================== points and circles
static func unitFromDraws(a: float, b: float) -> Array:
	var z: float = -1.0 + 2.0 * a
	var ang: float = 2.0 * SimMathx.PI * b
	var q: float = sqrt(1.0 - z * z)
	return [q * SimDetMath.cos(ang), z, q * SimDetMath.sin(ang)]


static func _cross(a: Array, b: Array) -> Array:
	return [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]


static func _unit(a: Array) -> Array:
	var l: float = sqrt(a[0] * a[0] + a[1] * a[1] + a[2] * a[2])
	return [a[0] / l, a[1] / l, a[2] / l]


## The great circle through T with normal n (n perpendicular to T): u = T, v = n x T. Returns {u, v, n}.
static func circleOf(T: Array, n: Array) -> Dictionary:
	var u: Array = _unit(T)
	# remove the part of T along n (the normal is only nearly perpendicular), so u is exactly on the circle
	var d: float = u[0] * n[0] + u[1] * n[1] + u[2] * n[2]
	u = _unit([u[0] - n[0] * d, u[1] - n[1] * d, u[2] - n[2] * d])
	var v: Array = _unit(_cross(n, u))
	return {"u": u, "v": v, "n": n}


## A ring of the arena's length (docs/world/shifting-arena-design.md section 1): the small circle through the great circle's touch-down T (= circ.u), tangent to it there, of
## `cols` columns, on the left (side 1, towards the great circle's normal) or the right of it. Its radius is sin(theta) = cols / 4,800 of the planet's, so a column is exactly
## SimConst.COL of arc and the ring closes. Returns the same dictionary shape as circleOf (u: the direction from the centre to T, v: the travel direction, n: the axis) plus
## c (the axis), st and ct (sin and cos of the angular radius), th (the radius) and s (the side), which read as "a ring". cols of 4,800 or more is the great circle itself.
static func ringThrough(circ: Dictionary, cols: int, side: int) -> Dictionary:
	var st: float = float(cols) / float(SimConst.PLANET_NC)
	if st >= 1.0:
		return circ
	var ct: float = sqrt(1.0 - st * st)
	var s: float = 1.0 if side >= 0 else -1.0
	var n: Array = circ.n
	var t: Array = circ.u
	var c: Array = _unit([t[0] * ct + n[0] * (s * st), t[1] * ct + n[1] * (s * st), t[2] * ct + n[2] * (s * st)])
	var e1: Array = _unit([t[0] * st - n[0] * (s * ct), t[1] * st - n[1] * (s * ct), t[2] * st - n[2] * (s * ct)])
	return {"u": e1, "v": circ.v, "n": c, "c": c, "st": st, "ct": ct, "th": asinf(st), "s": s}


## A place's signed lateral offset from the line (units, left of the line positive): from a great circle by its normal, from a ring by its angular radius.
static func lateral(P: Planet, circ: Dictionary, x: float, y: float, z: float) -> float:
	if circ.has("st"):
		var c: Array = circ.c
		return circ.s * P.R * (circ.th - acosf(SimMathx.jclamp(c[0] * x + c[1] * y + c[2] * z, -1.0, 1.0)))
	var n: Array = circ.n
	return P.R * asinf(n[0] * x + n[1] * y + n[2] * z)


## The point at column i of the circle: the middle column is T, a column is SimConst.COL units of arc.
static func columnPoint(P: Planet, circ: Dictionary, i: int) -> Array:
	var stf: float = circ.get("st", 1.0)
	var ang: float = float(i - touchCol()) * SimConst.COL / (P.R * stf)
	var co: float = SimDetMath.cos(ang)
	var si: float = SimDetMath.sin(ang)
	var u: Array = circ.u
	var v: Array = circ.v
	if circ.has("st"):
		var c: Array = circ.c
		var ct: float = circ.ct
		return [c[0] * ct + stf * (u[0] * co + v[0] * si), c[1] * ct + stf * (u[1] * co + v[1] * si), c[2] * ct + stf * (u[2] * co + v[2] * si)]
	return [u[0] * co + v[0] * si, u[1] * co + v[1] * si, u[2] * co + v[2] * si]


## ===================================================================== the places
static func _randUnit(r: SimRng) -> Array:
	var z: float = r.range_(-1.0, 1.0)
	var a: float = r.range_(0.0, 2.0 * SimMathx.PI)
	var q: float = sqrt(1.0 - z * z)
	return [q * SimDetMath.cos(a), z, q * SimDetMath.sin(a)]


static func _arc(P: Planet, a: Array, bx: float, by: float, bz: float) -> float:
	return P.R * acosf(a[0] * bx + a[1] * by + a[2] * bz)


static func _tryPlace(P: Planet, r: SimRng, kind: int, radius: float, tries: int, polar: bool) -> bool:
	var c: Dictionary = P.c
	var best = null
	var bs: float = -1.0e9
	for k in range(tries):
		var p: Array = _randUnit(r)
		var h: float = ground(P, p[0], p[1], p[2])
		if h < c.placeHMin or h > c.placeHMax or (polar and absf(p[1]) > c.placeYMax):
			continue
		var dmin: float = 1.0e9
		for i in range(P.n):
			var g: float = _arc(P, p, P.px[i], P.py[i], P.pz[i]) - P.rad[i] - radius
			if g < dmin:
				dmin = g
		if dmin < c.placeGap:
			continue
		var sc: float = dmin * c.scoreGap - absf(h - c.scoreH0) * c.scoreHW + r.next()
		if P.gen >= 2:   # window 4: a harbour for a city, a fertile biome, nothing on ice, in the sea or on a range
			if sc + WorldSites.maxBonus(kind) <= bs:
				continue   # the climate term cannot lift it past the best so far
			var bonus: float = WorldSites.score(P, kind, p[0], p[1], p[2], bs - sc)
			if bonus <= -1.0e8:
				continue
			sc += bonus
		if sc > bs:
			bs = sc
			best = p
	if best != null:
		P.kind.append(kind)
		P.px.append(best[0])
		P.py.append(best[1])
		P.pz.append(best[2])
		P.rad.append(radius)
		P.n += 1
		return true
	return false


## The places of a planet: first as picture A placed them (one stream, the ordinary ground), then the ones that fell inside a polar cap are placed again outside it
## from a second stream. Cities first, then towns. A state machine (_placeBegin, _placeStep) so a host can step it (PlanetJob); _placeAll is it run to the end, draw for draw as before.
static func _placeAll(P: Planet) -> void:
	var st: Dictionary = _placeBegin(P)
	while not _placeStep(P, st):
		pass


static func _placeBegin(P: Planet) -> Dictionary:
	return {"r": SimRng.new(P.seed * int(P.c.placeSeedMul) + 1), "r2": null, "i": 0, "phase": 0, "dropped": [0, 0]}


## One _tryPlace (or the step between the two streams, or the last step); true when the places are all made.
static func _placeStep(P: Planet, st: Dictionary) -> bool:
	var c: Dictionary = P.c
	var nc: int = int(c.cities)
	var nt: int = int(c.towns)
	if int(st.phase) == 0:
		var i: int = st.i
		if i < nc:
			_tryPlace(P, st.r, KIND_CITY, c.cityRadius, int(c.cityTries), false)
		elif i < nc + nt:
			_tryPlace(P, st.r, KIND_TOWN, c.townRadius, int(c.townTries), false)
		st.i = i + 1
		if int(st.i) < nc + nt:
			return false
		var kept := PackedInt32Array()
		var dropped := [0, 0]
		for k in range(P.n):
			if absf(P.py[k]) > c.placeYMax:
				dropped[P.kind[k]] += 1
			else:
				kept.append(k)
		var kind2 := PackedByteArray()
		var px2 := PackedFloat64Array()
		var py2 := PackedFloat64Array()
		var pz2 := PackedFloat64Array()
		var rad2 := PackedFloat64Array()
		for k in kept:
			kind2.append(P.kind[k])
			px2.append(P.px[k])
			py2.append(P.py[k])
			pz2.append(P.pz[k])
			rad2.append(P.rad[k])
		P.kind = kind2
		P.px = px2
		P.py = py2
		P.pz = pz2
		P.rad = rad2
		P.n = kept.size()
		st.dropped = dropped
		st.r2 = SimRng.new(P.seed * int(c.placeSeedMul) + 2)
		st.phase = 1
		st.i = 0
		return false
	var dr: Array = st.dropped
	var nd: int = int(dr[KIND_CITY]) + int(dr[KIND_TOWN])
	var j: int = st.i
	if j < nd:
		if j < int(dr[KIND_CITY]):
			_tryPlace(P, st.r2, KIND_CITY, c.cityRadius, int(c.replaceTries), true)
		else:
			_tryPlace(P, st.r2, KIND_TOWN, c.townRadius, int(c.replaceTries), true)
		st.i = j + 1
		if int(st.i) < nd:
			return false
	# people: a place's weight is its area (radius squared), so a city holds about seven towns' people (as Bellgate and the villages do)
	P.people.resize(P.n)
	for k in range(P.n):
		P.people[k] = int(P.rad[k] * P.rad[k] / 1000000.0 * 100.0)
	return true


## The people of a place at full, by weight (relative). A slice's people are these over its held places, normalised to the slice's total (slicePeople).
static func placeWeight(P: Planet, id: int) -> int:
	return P.people[id]


## ===================================================================== reading a circle: the minimum
## What the circle (normal n, frame u v) holds. standing: PackedByteArray of 1 for a place that has not fallen (empty: all stand). Returns a dictionary.
static func evalCircle(P: Planet, circ: Dictionary, standing: PackedByteArray, minCities: int = 0, minTowns: int = 0) -> Dictionary:
	var c: Dictionary = P.c
	var n: Array = circ.n
	var cities: int = 0
	var towns: int = 0
	for i in range(P.n):
		if standing.size() > 0 and standing[i] == 0:
			continue
		var d: float = P.R * asinf(n[0] * P.px[i] + n[1] * P.py[i] + n[2] * P.pz[i])
		var reach: float = (c.cityReach if P.kind[i] == KIND_CITY else c.townReach) * P.rad[i]
		if absf(d) < reach:
			if P.kind[i] == KIND_CITY:
				cities += 1
			else:
				towns += 1
	if cities < minCities or towns < minTowns:
		return {"cities": cities, "towns": towns, "biomes": 0, "land": 0.0, "ice": 0.0, "seen": [], "skipped": true}   # the counts already fail: no surface is read
	var seen := [0, 0, 0, 0, 0, 0, 0]
	var cnt: int = int(c.samples)
	var u: Array = circ.u
	var v: Array = circ.v
	for k in range(cnt):
		var ang: float = float(k) / float(cnt) * 2.0 * SimMathx.PI
		var co: float = SimDetMath.cos(ang)
		var si: float = SimDetMath.sin(ang)
		surfAt(P, u[0] * co + v[0] * si, u[1] * co + v[1] * si, u[2] * co + v[2] * si)
		seen[P.outB] += 1
	var kinds: int = 0
	for s in seen:
		if float(s) / float(cnt) >= c.biomeShare:
			kinds += 1
	var land: float = 1.0 - float(seen[BIO_OCEAN] + seen[BIO_SEA_ICE]) / float(cnt)
	var ice: float = float(seen[BIO_ICE_SHEET] + seen[BIO_SEA_ICE]) / float(cnt)
	return {"cities": cities, "towns": towns, "biomes": kinds, "land": land, "ice": ice, "seen": seen}


static func meets(c: Dictionary, e: Dictionary, relaxed: bool) -> bool:
	if relaxed:
		return e.cities >= int(c.relaxCities) and e.towns >= int(c.relaxTowns) and e.biomes >= int(c.relaxBiomes) and e.land >= c.relaxLand
	return e.cities >= int(c.minCities) and e.towns >= int(c.minTowns) and e.biomes >= int(c.minBiomes) and e.land >= c.minLand


## ===================================================================== the picker
## A touch-down point from the draw `touch` (an integer): uniform on the sphere, redrawn (up to touchTries) until it is on land when touchLand is 1.
static func touchPoint(P: Planet, touch: int) -> Array:
	var c: Dictionary = P.c
	var tries: int = int(c.touchTries) if int(c.touchLand) != 0 else 1
	var p: Array = []
	for k in range(tries):
		var a: float = SimRng.keyed(P.seed, "touch-a", touch * 64 + k)
		var b: float = SimRng.keyed(P.seed, "touch-b", touch * 64 + k)
		p = unitFromDraws(a, b)
		if tries == 1:
			return p
		surfAt(P, p[0], p[1], p[2])
		if P.outH >= 0.0 and P.outB != BIO_SEA_ICE:
			return p
	return p


## The candidate circles through T, in a seeded order: through each standing city, and randomBearings of random bearing. Each is {n, u, v, idx} (idx: the order drawn).
static func candidates(P: Planet, T: Array, touch: int, standing: PackedByteArray) -> Array:
	var c: Dictionary = P.c
	var out: Array = []
	for i in range(P.n):
		if P.kind[i] != KIND_CITY:
			continue
		if standing.size() > 0 and standing[i] == 0:
			continue
		var nn: Array = _cross(T, [P.px[i], P.py[i], P.pz[i]])
		var l: float = sqrt(nn[0] * nn[0] + nn[1] * nn[1] + nn[2] * nn[2])
		if l > c.nMinCity:
			out.append(circleOf(T, [nn[0] / l, nn[1] / l, nn[2] / l]))
	for k in range(int(c.randomBearings)):
		var t: Array = unitFromDraws(SimRng.keyed(P.seed, "bear-a", touch * 64 + k), SimRng.keyed(P.seed, "bear-b", touch * 64 + k))
		var nn2: Array = _cross(T, t)
		var l2: float = sqrt(nn2[0] * nn2[0] + nn2[1] * nn2[1] + nn2[2] * nn2[2])
		if l2 > c.nMinRandom:
			out.append(circleOf(T, [nn2[0] / l2, nn2[1] / l2, nn2[2] / l2]))
	# a seeded shuffle (Fisher-Yates on keyed draws)
	for i in range(out.size() - 1, 0, -1):
		var j: int = int(SimRng.keyed(P.seed, "shuffle", touch * 256 + i) * float(i + 1))
		var tmp = out[i]
		out[i] = out[j]
		out[j] = tmp
	return out


## The picker: the first candidate that meets the minimum (strict; relaxed if `relaxed`). Returns {ok, circle, tried, eval, touch point T}.
static func pick(P: Planet, touch: int, standing: PackedByteArray = PackedByteArray(), relaxed: bool = false) -> Dictionary:
	var T: Array = touchPoint(P, touch)
	return pickThrough(P, T, touch, standing, relaxed)


## The same through a given point (a story level names its place).
static func pickThrough(P: Planet, T: Array, touch: int, standing: PackedByteArray = PackedByteArray(), relaxed: bool = false) -> Dictionary:
	var c: Dictionary = P.c
	var cand: Array = candidates(P, T, touch, standing)
	var tried: int = 0
	var needC: int = int(c.relaxCities) if relaxed else int(c.minCities)
	var needT: int = int(c.relaxTowns) if relaxed else int(c.minTowns)
	for circ in cand:
		tried += 1
		var e: Dictionary = evalCircle(P, circ, standing, needC, needT)
		if meets(c, e, relaxed):
			return {"ok": true, "circle": circ, "tried": tried, "eval": e, "T": T, "index": tried - 1}
	return {"ok": false, "circle": {}, "tried": tried, "eval": {}, "T": T, "index": -1}


## Strict if any candidate meets it, else the first that meets the relaxed minimum: each candidate's surface is read once, and only if its counts could satisfy one of the two.
static func pickEither(P: Planet, touch: int, standing: PackedByteArray = PackedByteArray()) -> Dictionary:
	var c: Dictionary = P.c
	var T: Array = touchPoint(P, touch)
	var cand: Array = candidates(P, T, touch, standing)
	var tried: int = 0
	var rel: Dictionary = {}
	var needC: int = mini(int(c.relaxCities), int(c.minCities))
	var needT: int = mini(int(c.relaxTowns), int(c.minTowns))
	for circ in cand:
		tried += 1
		var e: Dictionary = evalCircle(P, circ, standing, needC, needT)
		if meets(c, e, false):
			return {"ok": true, "relaxed": false, "circle": circ, "tried": tried, "eval": e, "T": T, "index": tried - 1}
		if rel.is_empty() and meets(c, e, true):
			rel = {"ok": true, "relaxed": true, "circle": circ, "tried": tried, "eval": e, "T": T, "index": tried - 1}
	if not rel.is_empty():
		return rel
	return {"ok": false, "relaxed": false, "circle": {}, "tried": tried, "eval": {}, "T": T, "index": -1}


## ===================================================================== the slice: 4,800 columns and what stands on them
class Slice extends RefCounted:
	var heights := PackedFloat32Array()       # stored as S.base is: float32
	var biomes := PackedByteArray()
	var fine := PackedByteArray()             # gen 2: the fine biome of each column (WorldClimate.F_*); empty for gen 1
	var held: Array = []                      # {id, kind, col, d, half, r}: the places the line passes (d: signed lateral offset, units, left of the line positive)
	var circ: Dictionary = {}
	var T: Array = []
	var seed: int = 0


## Reads the circle as columns. One surfAt a column; the fine relief only on ordinary land (and a quarter of it on an ice sheet). The held places, with their
## nearest column (our own atan2 of the place's point in the circle's frame) and their lateral offset (our own asin).
static func readSlice(P: Planet, circ: Dictionary, T: Array, standing: PackedByteArray = PackedByteArray()) -> Slice:
	var S: Slice = readBegin(P, circ, T)
	readColumns(P, S, 0, SimConst.NC)
	readHeld(P, S, standing)
	return S


## The read in three steps (a host spends a few columns a frame: RingJob; the module owns no clock). readSlice is these three in order, so a stepped read is the same slice.
static func readBegin(P: Planet, circ: Dictionary, T: Array) -> Slice:
	var S := Slice.new()
	S.seed = P.seed
	S.circ = circ
	S.T = T
	var nc: int = SimConst.NC
	S.heights.resize(nc)
	S.biomes.resize(nc)
	if P.gen >= 2:
		S.fine.resize(nc)
	return S


## Columns i0 up to i1 (exclusive) of the slice.
static func readColumns(P: Planet, S: Slice, i0: int, i1: int) -> void:
	var c: Dictionary = P.c
	var circ: Dictionary = S.circ
	var u: Array = circ.u
	var v: Array = circ.v
	var small: bool = circ.has("st")
	var stf: float = circ.get("st", 1.0)
	var ct: float = circ.get("ct", 0.0)
	var ca: Array = circ.get("c", u)
	var tc: int = touchCol()
	var fine2: bool = P.gen >= 2
	for i in range(i0, i1):
		var ang: float = float(i - tc) * SimConst.COL / (P.R * stf)
		var co: float = SimDetMath.cos(ang)
		var si: float = SimDetMath.sin(ang)
		var qx: float = u[0] * co + v[0] * si
		var qy: float = u[1] * co + v[1] * si
		var qz: float = u[2] * co + v[2] * si
		if small:
			qx = ca[0] * ct + stf * qx
			qy = ca[1] * ct + stf * qy
			qz = ca[2] * ct + stf * qz
		surfAt(P, qx, qy, qz)
		var h: float = P.outH
		var b: int = P.outB
		if b >= BIO_PLAINS and b <= BIO_MOUNTAINS:
			h += (_fbm(P.R, qx, qy, qz, c.detailScale, int(c.detailOct), P.seed + int(c.sDetail)) - 0.5) * c.detailAmp
		elif b == BIO_ICE_SHEET and h > 100.0:
			h += (_fbm(P.R, qx, qy, qz, c.detailScale, int(c.detailOct), P.seed + int(c.sDetail)) - 0.5) * c.detailAmp * c.detailSheet
		S.heights[i] = h
		S.biomes[i] = b
		if fine2:
			S.fine[i] = P.outF if P.outF >= 0 else b


## The places the line holds, with their nearest column and lateral offset.
static func readHeld(P: Planet, S: Slice, standing: PackedByteArray = PackedByteArray()) -> void:
	if P.gen >= 2:
		WorldSites.blend(P, S)   # window 4: the fine biomes meet in a ragged band (the last step of every read, whole or stepped, before anything hashes the biomes)
	var c: Dictionary = P.c
	var circ: Dictionary = S.circ
	var u: Array = circ.u
	var v: Array = circ.v
	var stf: float = circ.get("st", 1.0)
	var nc: int = SimConst.NC
	var tc: int = touchCol()
	for i in range(P.n):
		var lat: float = lateral(P, circ, P.px[i], P.py[i], P.pz[i])
		var reach: float = (c.cityReach if P.kind[i] == KIND_CITY else c.townReach) * P.rad[i]
		if absf(lat) >= reach:
			continue
		var along: float = atan2f(P.px[i] * v[0] + P.py[i] * v[1] + P.pz[i] * v[2], P.px[i] * u[0] + P.py[i] * u[1] + P.pz[i] * u[2])
		var col: int = tc + int(floor(along * (P.R * stf) / SimConst.COL + 0.5))
		col = ((col % nc) + nc) % nc
		var half: float = sqrt(maxf(0.0, P.rad[i] * P.rad[i] - lat * lat))
		S.held.append({"id": i, "kind": int(P.kind[i]), "col": col, "d": lat, "half": half, "r": P.rad[i],
			"standing": standing.size() == 0 or standing[i] != 0})


## A stepped read of a ring (WorldEpoch.prewarm): `step(n)` reads n more columns; at the end the places. `slice` is readSlice's answer once `done`.
class RingJob extends RefCounted:
	var P: WorldPlanet.Planet
	var ring: Dictionary
	var slice: WorldPlanet.Slice
	var i: int = 0
	var done: bool = false

	func _init(p: WorldPlanet.Planet, r: Dictionary) -> void:
		P = p
		ring = r
		slice = WorldPlanet.readBegin(P, ring, ring.u)

	func step(n: int) -> bool:
		if done:
			return true
		var j: int = mini(SimConst.NC, i + n)
		WorldPlanet.readColumns(P, slice, i, j)
		i = j
		if i >= SimConst.NC:
			WorldPlanet.readHeld(P, slice)
			done = true
		return done


## The slice memoised outside the sim state: keyed by the planet, the touch, the pick index and the data hash. The read is pure, so the cache cannot change a match.
static func sliceFor(seed: int, touch: int, standing: PackedByteArray = PackedByteArray(), relaxed: bool = false, side: int = 1) -> Slice:
	var key: String = "%d/%d/%s/%d/%s/%d/%d" % [seed, touch, str(standing.hex_encode()), 1 if relaxed else 0, dataHash(), SimConst.NC, side]
	if _slices.has(key):
		return _slices[key]
	var P: Planet = make(seed)
	var r: Dictionary = pick(P, touch, standing, relaxed)
	if not r.ok:
		return null
	var S: Slice = readSlice(P, ringThrough(r.circle, SimConst.NC, side), r.T, standing)   # the arena's columns: the great circle itself at 4,800, else a ring through the touch-down
	if _slices.size() > 4:
		_slices.clear()
	_slices[key] = S
	return S


## The ground beside a ring (window 2, the slow drift: Rendering's far land and sky read the planet's own ground, not a wander): the height and biome at column i of the ring, moved `z` units
## sideways over the surface (z positive toward the ring's centre, negative away from it, along the great circle through the column at right angles to the ring). At z = 0 it is the slice's
## own column, height and biome to the bit. Returns [height, biome]. A pure function of the planet and the ring: no state, no clock.
static func farColumn(P: Planet, ring: Dictionary, i: int, z: float) -> Array:
	var c: Dictionary = P.c
	var p: Array = columnPoint(P, ring, i)
	var qx: float = p[0]
	var qy: float = p[1]
	var qz: float = p[2]
	if z != 0.0:
		var m: Array = ring.get("c", ring.n)
		var d: float = m[0] * p[0] + m[1] * p[1] + m[2] * p[2]
		var t: Array = _unit([m[0] - p[0] * d, m[1] - p[1] * d, m[2] - p[2] * d])   # the way to the centre (for a great circle, towards its normal's side)
		var a: float = z / P.R
		var co: float = SimDetMath.cos(a)
		var si: float = SimDetMath.sin(a)
		qx = p[0] * co + t[0] * si
		qy = p[1] * co + t[1] * si
		qz = p[2] * co + t[2] * si
	surfAt(P, qx, qy, qz)
	var h: float = P.outH
	var b: int = P.outB
	if b >= BIO_PLAINS and b <= BIO_MOUNTAINS:
		h += (_fbm(P.R, qx, qy, qz, c.detailScale, int(c.detailOct), P.seed + int(c.sDetail)) - 0.5) * c.detailAmp
	elif b == BIO_ICE_SHEET and h > 100.0:
		h += (_fbm(P.R, qx, qy, qz, c.detailScale, int(c.detailOct), P.seed + int(c.sDetail)) - 0.5) * c.detailAmp * c.detailSheet
	return [h, b]


## A block of the ground beside a ring, for a renderer's far land (window 2's slow drift and the far land at a turn): the height and biome at `ncols` columns of the ring, from column c0 every `stride`,
## each moved sideways by each of `depths` (farColumn's z). It is farColumn read in bulk and in a better order: depth by depth, so that consecutive samples are 32 x stride units apart and sit in the
## noise cell of the one before (the memo of _vn hits), a column's point and its way to the centre are worked out once, and a depth's rotation once. Index di * ncols + ci. Every sample is
## farColumn's own, bit for bit, where |z| <= coarseFrom (the default is everywhere). Past coarseFrom the read is COARSE, for a hazed far land: every noise has one octave fewer (the finest, an eighth to
## a sixteenth of its swing) and the surface detail is not added; heights are then off by up to a few hundred units in mountains and the odd biome border moves a column or two. About half the work, and
## nothing in the sim reads it. Returns {"h": heights (float64), "b": biomes}. A pure function of the planet and the ring.
static func farField(P: Planet, ring: Dictionary, c0: int, ncols: int, stride: int, depths: PackedFloat64Array, coarseFrom: float = 1.0e18) -> Dictionary:
	var c: Dictionary = P.c
	var m: Array = ring.get("c", ring.n)
	var px := PackedFloat64Array()
	var py := PackedFloat64Array()
	var pz := PackedFloat64Array()
	var tx := PackedFloat64Array()
	var ty := PackedFloat64Array()
	var tz := PackedFloat64Array()
	px.resize(ncols)
	py.resize(ncols)
	pz.resize(ncols)
	tx.resize(ncols)
	ty.resize(ncols)
	tz.resize(ncols)
	for ci in range(ncols):
		var p: Array = columnPoint(P, ring, c0 + ci * stride)
		px[ci] = p[0]
		py[ci] = p[1]
		pz[ci] = p[2]
		var d: float = m[0] * p[0] + m[1] * p[1] + m[2] * p[2]
		var t: Array = _unit([m[0] - p[0] * d, m[1] - p[1] * d, m[2] - p[2] * d])
		tx[ci] = t[0]
		ty[ci] = t[1]
		tz[ci] = t[2]
	var hs := PackedFloat64Array()
	var bs := PackedByteArray()
	hs.resize(ncols * depths.size())
	bs.resize(ncols * depths.size())
	var detSeed: int = P.seed + int(c.sDetail)
	for di in range(depths.size()):
		var z: float = depths[di]
		var co: float = 1.0
		var si: float = 0.0
		if z != 0.0:
			var a: float = z / P.R
			co = SimDetMath.cos(a)
			si = SimDetMath.sin(a)
		var detail: bool = absf(z) <= coarseFrom
		_octOff = 0 if detail else 1
		for ci in range(ncols):
			var qx: float = px[ci]
			var qy: float = py[ci]
			var qz: float = pz[ci]
			if z != 0.0:
				qx = px[ci] * co + tx[ci] * si
				qy = py[ci] * co + ty[ci] * si
				qz = pz[ci] * co + tz[ci] * si
			surfAt(P, qx, qy, qz)
			var h: float = P.outH
			var b: int = P.outB
			if detail:
				if b >= BIO_PLAINS and b <= BIO_MOUNTAINS:
					h += (_fbm(P.R, qx, qy, qz, c.detailScale, int(c.detailOct), detSeed) - 0.5) * c.detailAmp
				elif b == BIO_ICE_SHEET and h > 100.0:
					h += (_fbm(P.R, qx, qy, qz, c.detailScale, int(c.detailOct), detSeed) - 0.5) * c.detailAmp * c.detailSheet
			hs[di * ncols + ci] = h
			bs[di * ncols + ci] = b
	_octOff = 0
	return {"h": hs, "b": bs}


## The places beside a ring, for a renderer's far land (the towns and cities past the arena, which the map's heights and biomes do not show): every place within `maxLateral` units of the ring, as
## {id, kind (KIND_CITY or KIND_TOWN), col (its column along the ring, a float in [0, NC)), z (its signed lateral offset, farColumn's z: positive toward the ring's centre, so farColumn(ring, col, z)
## is at its centre), rad (its radius in units), dir ([x, y, z], the unit vector of its centre), people (the place's weight)}. Sorted by id. A pure function of the planet and the ring.
static func farPlaces(P: Planet, ring: Dictionary, maxLateral: float = 1.0e18) -> Array:
	var out: Array = []
	var stf: float = ring.get("st", 1.0)
	var tc: int = touchCol()
	var nc: float = float(SimConst.NC)
	var u: Array = ring.u
	var v: Array = ring.v
	for i in range(P.n):
		var lat: float = lateral(P, ring, P.px[i], P.py[i], P.pz[i])
		if absf(lat) > maxLateral:
			continue
		var along: float = atan2f(P.px[i] * v[0] + P.py[i] * v[1] + P.pz[i] * v[2], P.px[i] * u[0] + P.py[i] * u[1] + P.pz[i] * u[2])
		var col: float = float(tc) + along * (P.R * stf) / SimConst.COL
		col -= floor(col / nc) * nc
		out.append({"id": i, "kind": int(P.kind[i]), "col": col, "z": lat, "rad": P.rad[i], "dir": [P.px[i], P.py[i], P.pz[i]], "people": int(P.people[i])})
	return out


## The slice of an explicit ring (WorldRingPick: an axis, the columns, a touch-down), memoised outside the state like sliceFor's. The ring is the arena's, so its columns are SimConst.NC.
static func _ringKey(seed: int, ring: Dictionary, standing: PackedByteArray) -> String:
	return "ring/%d/%s/%s/%s/%d/%s" % [seed, str(ring.c), str(ring.u), str(standing.hex_encode()), SimConst.NC, dataHash()]   # dataHash carries the generation: a gen 2 slice is never handed to a gen 1 match


## A ring's slice read in steps is put where sliceRing finds it.
static func memoRing(seed: int, ring: Dictionary, slice: Slice) -> void:
	if _slices.size() > 4:
		_slices.clear()
	_slices[_ringKey(seed, ring, PackedByteArray())] = slice


static func sliceRing(seed: int, ring: Dictionary, standing: PackedByteArray = PackedByteArray()) -> Slice:
	var key: String = _ringKey(seed, ring, standing)
	if _slices.has(key):
		return _slices[key]
	var P: Planet = make(seed)
	var S: Slice = readSlice(P, ring, ring.u, standing)
	if _slices.size() > 4:
		_slices.clear()
	_slices[key] = S
	return S


## A hash of what the read produced (the heights as stored, the biomes): Simulation's `world` hash reads it. FNV-1a over the bytes.
static func sliceHash(S: Slice) -> int:
	var h: int = 0x811c9dc5
	var hb: PackedByteArray = S.heights.to_byte_array()
	for i in range(hb.size()):
		h = SimRng.imul((h ^ hb[i]) & MASK, 0x01000193)
	for i in range(S.biomes.size()):
		h = SimRng.imul((h ^ S.biomes[i]) & MASK, 0x01000193)
	for i in range(S.fine.size()):   # gen 2 only
		h = SimRng.imul((h ^ S.fine[i]) & MASK, 0x01000193)
	return h & MASK


## The offers of a chapter: `count` slices from different touch-downs, each on a different set of held cities, strict minimum, relaxed if strict finds none.
## `stream` is the offer stream (an integer); returns an Array of {touch, relaxed, pick, cities (ids)}.
static func offers(P: Planet, stream: int, standing: PackedByteArray, count: int = -1) -> Array:
	var c: Dictionary = P.c
	var want: int = int(c.offerCount) if count < 0 else count
	var out: Array = []
	var sets: Array = []
	for t in range(int(c.offerTries)):
		if out.size() >= want:
			break
		var touch: int = stream * 4096 + t
		var r: Dictionary = pickEither(P, touch, standing)
		var rel: bool = r.relaxed
		if not r.ok:
			continue
		var T: Array = r.T
		var far: bool = true
		for o in out:
			var d: float = _arc(P, T, o.T[0], o.T[1], o.T[2])
			if d < c.offerMinSep:
				far = false
		if not far:
			continue
		var ids: Array = _heldCities(P, r.circle, standing)
		var key: String = str(ids)
		if sets.has(key):
			continue
		sets.append(key)
		out.append({"touch": touch, "relaxed": rel, "pick": r.index, "cities": ids, "T": T, "circle": r.circle})
	return out


static func _heldCities(P: Planet, circ: Dictionary, standing: PackedByteArray) -> Array:
	var c: Dictionary = P.c
	var n: Array = circ.n
	var ids: Array = []
	for i in range(P.n):
		if P.kind[i] != KIND_CITY or (standing.size() > 0 and standing[i] == 0):
			continue
		var d: float = P.R * asinf(n[0] * P.px[i] + n[1] * P.py[i] + n[2] * P.pz[i])
		if absf(d) < c.cityReach * P.rad[i]:
			ids.append(i)
	return ids


## ===================================================================== a run's wear list: damage per place, in the place's frame, in whole numbers
## wear = {"v": 1, "pl": {"<place id>": {"cr": [[east, north, radius16, depth16, cause], ...], "bl": [[building index, stage], ...], "lost": permille, "gone": permille}},
##         "open": [[x6, y6, z6, radius16, depth16, cause], ...]}
## A crater's depth16 is positive; a negative depth16 is a raised mound (cooled magma becomes rock that raises the ground: Research's magma, run-core.md).
## All integers: exact in JSON, the same in any language. Lengths in units are whole units; radius16 and depth16 are 1/16 units. A place's frame: its centre c, east e = norm(Y x c),
## north = c x e; an offset (east, north) in units is the point c sqrt(1 - (x^2 + y^2) / R^2) + e (x / R) + north (y / R). An open-country crater is the point x 1,000,000, rounded.
static func wearNew() -> Dictionary:
	return {"v": 1, "pl": {}, "open": []}


static func _rec(wear: Dictionary, id: int) -> Dictionary:
	var k: String = str(id)
	if not wear.pl.has(k):
		wear.pl[k] = {"cr": [], "bl": [], "lost": 0, "gone": 0}
	return wear.pl[k]


static func _frame(P: Planet, id: int) -> Array:
	var cx: float = P.px[id]
	var cy: float = P.py[id]
	var cz: float = P.pz[id]
	var e: Array = _unit(_cross([0.0, 1.0, 0.0], [cx, cy, cz]))
	var nrt: Array = _cross([cx, cy, cz], e)
	return [[cx, cy, cz], e, nrt]


## A point of the sphere into a place's frame: whole units east and north.
static func toFrame(P: Planet, id: int, qx: float, qy: float, qz: float) -> Array:
	var f: Array = _frame(P, id)
	var e: Array = f[1]
	var n: Array = f[2]
	return [int(floor(P.R * (qx * e[0] + qy * e[1] + qz * e[2]) + 0.5)), int(floor(P.R * (qx * n[0] + qy * n[1] + qz * n[2]) + 0.5))]


static func fromFrame(P: Planet, id: int, east: int, north: int) -> Array:
	var f: Array = _frame(P, id)
	var c0: Array = f[0]
	var e: Array = f[1]
	var n: Array = f[2]
	var x: float = float(east) / P.R
	var y: float = float(north) / P.R
	var z: float = sqrt(maxf(0.0, 1.0 - x * x - y * y))
	return _unit([c0[0] * z + e[0] * x + n[0] * y, c0[1] * z + e[1] * x + n[1] * y, c0[2] * z + e[2] * x + n[2] * y])


## The place whose disc holds the point, or -1 (the nearest by the chord, within its radius).
static func placeAt(P: Planet, qx: float, qy: float, qz: float) -> int:
	var best: int = -1
	var bd: float = 1.0e30
	for i in range(P.n):
		var dx: float = qx - P.px[i]
		var dy: float = qy - P.py[i]
		var dz: float = qz - P.pz[i]
		var chord: float = P.R * sqrt(dx * dx + dy * dy + dz * dz)
		if chord < P.rad[i] and chord < bd:
			bd = chord
			best = i
	return best


## Records a crater at a point of the sphere (a stage's end writes these from the match's marks). Inside a place: its frame; else an open-country point.
static func wearCrater(P: Planet, wear: Dictionary, qx: float, qy: float, qz: float, radius16: int, depth16: int, cause: int) -> void:
	var id: int = placeAt(P, qx, qy, qz)
	if id < 0:
		wear.open.append([int(floor(qx * 1000000.0 + 0.5)), int(floor(qy * 1000000.0 + 0.5)), int(floor(qz * 1000000.0 + 0.5)), radius16, depth16, cause])
		return
	var ef: Array = toFrame(P, id, qx, qy, qz)
	var rec: Dictionary = _rec(wear, id)
	rec.cr.append([ef[0], ef[1], radius16, depth16, cause])
	_fold(P, rec)


## Past the cap the two oldest craters merge: the midpoint, the larger radius, the sum of the depths up to a cap.
static func _fold(P: Planet, rec: Dictionary) -> void:
	var c: Dictionary = P.c
	while rec.cr.size() > int(c.craterCap):
		var a: Array = rec.cr[0]
		var b: Array = rec.cr[1]
		var m: Array = [int(floor(float(a[0] + b[0]) / 2.0)), int(floor(float(a[1] + b[1]) / 2.0)), maxi(a[2], b[2]), mini(a[3] + b[3], int(c.foldDepthMax)), maxi(a[4], b[4])]
		rec.cr.remove_at(0)
		rec.cr[0] = m


## A wear list read back from JSON: every number is an int again (JSON gives floats).
static func wearFromJson(j: Dictionary) -> Dictionary:
	var out: Dictionary = wearNew()
	for k in j.pl:
		var r: Dictionary = j.pl[k]
		var o: Dictionary = {"cr": [], "bl": [], "lost": int(r.lost), "gone": int(r.gone)}
		for cr in r.cr:
			o.cr.append([int(cr[0]), int(cr[1]), int(cr[2]), int(cr[3]), int(cr[4])])
		for b in r.bl:
			o.bl.append([int(b[0]), int(b[1])])
		out.pl[k] = o
	for o2 in j.open:
		out.open.append([int(o2[0]), int(o2[1]), int(o2[2]), int(o2[3]), int(o2[4]), int(o2[5])])
	return out


## A building's stage in its place's plan (0 standing, 1 damaged, 2 breached, 3 down, 4 rubble): the highest stage kept.
static func wearBuilding(wear: Dictionary, id: int, building: int, stage: int) -> void:
	var rec: Dictionary = _rec(wear, id)
	for b in rec.bl:
		if b[0] == building:
			b[1] = maxi(b[1], stage)
			return
	rec.bl.append([building, stage])


## People lost and fled for good, in thousandths of the place's people; both only grow, and never past a thousand together.
static func wearPeople(wear: Dictionary, id: int, lostPermille: int, gonePermille: int) -> void:
	var rec: Dictionary = _rec(wear, id)
	rec.lost = mini(1000, rec.lost + lostPermille)
	rec.gone = mini(1000 - rec.lost, rec.gone + gonePermille)


## Fresh 0, damaged 1, fallen 2, from the buildings down (of `nBuildings` in the plan; stage 3 and 4 count as down) and the people present.
static func placeStatus(wear: Dictionary, id: int, nBuildings: int) -> int:
	var c: Dictionary = cfg()
	var k: String = str(id)
	if not wear.pl.has(k):
		return 0
	var rec: Dictionary = wear.pl[k]
	var down: int = 0
	for b in rec.bl:
		if b[1] >= 3:
			down += 1
	var downP: int = int(floor(float(down) * 1000.0 / float(maxi(1, nBuildings))))
	var present: int = 1000 - rec.lost - rec.gone
	if (1000 - downP) < int(c.fallenPermille) or present < int(c.fallenPermille):
		return 2
	if downP >= int(c.damagedPermille) or rec.lost + rec.gone >= int(c.damagedPermille):
		return 1
	return 0


## Which places stand (1) and which have fallen (0): the picker's mask. nBuildings(id) comes from the plan; the estimate stands in until the plan exists.
static func standingMask(P: Planet, wear: Dictionary, nBuildings: Array = []) -> PackedByteArray:
	var m := PackedByteArray()
	m.resize(P.n)
	for i in range(P.n):
		var nb: int = nBuildings[i] if i < nBuildings.size() else estimateBuildings(P, i)
		m[i] = 0 if placeStatus(wear, i, nb) == 2 else 1
	return m


## Until a city's plan exists: buildings by the settled length, 2.6 per thousand units of a place's chord through the middle (today's 118 buildings on 46,000 units).
static func estimateBuildings(P: Planet, id: int) -> int:
	return maxi(4, int(floor(2.0 * P.rad[id] * 2.6 / 1000.0 * 0.8)))


## The people of each held place of a slice, whole numbers summing to slicePeople at full: by the places' weights (largest remainder), less each place's lost and gone.
static func slicePeople(P: Planet, S: Slice, wear: Dictionary) -> Array:
	var c: Dictionary = P.c
	var total: int = int(c.slicePeople)
	var wsum: int = 0
	for h in S.held:
		wsum += placeWeight(P, h.id)
	var out: Array = []
	if wsum == 0:
		return out
	var given: int = 0
	var rem: Array = []
	for i in range(S.held.size()):
		var w: int = placeWeight(P, S.held[i].id)
		var exact: float = float(total) * float(w) / float(wsum)
		var whole: int = int(floor(exact))
		out.append(whole)
		given += whole
		rem.append([exact - float(whole), i])
	rem.sort_custom(func(a, b): return a[0] > b[0] or (a[0] == b[0] and a[1] < b[1]))
	for k in range(total - given):
		out[rem[k][1]] += 1
	for i in range(S.held.size()):
		var k2: String = str(S.held[i].id)
		if wear.pl.has(k2):
			var rec: Dictionary = wear.pl[k2]
			out[i] = int(floor(float(out[i]) * float(1000 - rec.lost - rec.gone) / 1000.0))
	return out


## Read-back: the marks a slice carries from the wear list. Each is {col, lateral, radius16, depth16, cause, place}: its column along the line and its lateral offset (units),
## for the craters whose centre is within bandUnits + their radius of the line. Open-country craters are read as points too.
static func wearMarks(P: Planet, wear: Dictionary, S: Slice) -> Array:
	var c: Dictionary = P.c
	var out: Array = []
	var u: Array = S.circ.u
	var v: Array = S.circ.v
	var stf: float = S.circ.get("st", 1.0)
	var nc: int = SimConst.NC
	var band: float = c.bandUnits
	var pts: Array = []   # [x, y, z, radius16, depth16, cause, place]
	for h in S.held:
		var k: String = str(h.id)
		if not wear.pl.has(k):
			continue
		for cr in wear.pl[k].cr:
			var q: Array = fromFrame(P, h.id, cr[0], cr[1])
			pts.append([q[0], q[1], q[2], cr[2], cr[3], cr[4], h.id])
	for o in wear.open:
		pts.append([float(o[0]) / 1000000.0, float(o[1]) / 1000000.0, float(o[2]) / 1000000.0, o[3], o[4], o[5], -1])
	for q in pts:
		var lat: float = lateral(P, S.circ, q[0], q[1], q[2])
		if absf(lat) > band + float(q[3]) / 16.0:
			continue
		var along: float = atan2f(q[0] * v[0] + q[1] * v[1] + q[2] * v[2], q[0] * u[0] + q[1] * u[1] + q[2] * u[2])
		var col: int = touchCol() + int(floor(along * (P.R * stf) / SimConst.COL + 0.5))
		col = ((col % nc) + nc) % nc
		out.append({"col": col, "lateral": int(floor(lat + 0.5)), "radius16": q[3], "depth16": q[4], "cause": q[5], "place": q[6]})
	return out


## Lays the marks on the slice's heights as bowls (a squared falloff to the rim), stored float32 as S.base is. Window 2 swaps this for WorldCrater's own shape.
static func applyBowls(S: Slice, marks: Array) -> void:
	var nc: int = SimConst.NC
	for m in marks:
		var r: float = float(m.radius16) / 16.0
		var dep: float = float(m.depth16) / 16.0
		var lat: float = float(m.lateral)
		if absf(lat) >= r:
			continue
		var half: float = sqrt(r * r - lat * lat)
		var c0: int = m.col
		var span: int = int(ceil(half / SimConst.COL))
		for k in range(-span, span + 1):
			var col: int = ((c0 + k) % nc + nc) % nc
			var dx: float = float(k) * SimConst.COL
			var t: float = 1.0 - (dx * dx + lat * lat) / (r * r)
			if t > 0.0:
				S.heights[col] = S.heights[col] - dep * t * t
