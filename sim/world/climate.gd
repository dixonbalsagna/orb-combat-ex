class_name WorldClimate
extends RefCounted
## Planet generation 2: a point's biome from its climate (docs/world/planet-gen2.md; data/biomes/climate.json). Generation 1, the stored planet, is untouched: nothing here runs unless a planet is made
## by gen 2 (the data's `gen`, or a setup's planetGen, or a tool's useGen).
##
## Temperature falls with latitude and height; moisture is the sea's reach carried downwind on a coarse grid, row by row, the sea recharging it and the land raining it out (more on a climb, so a range
## casts a rain shadow), blended with the latitude bands and a little noise; the biome is the table's cell for the two, with coast, wetland, highland, mountain and volcanic overrides. All of it float64
## arithmetic (+ - * / sqrt floor, SimDetMath, the planet's own noise), so the same on every platform; the grid is a pure function of the planet and the data, built once for a planet.

const PATH := "res://data/biomes/climate.json"
const SCHEMA := "biomes.climate/1"

# the fine biomes (ids 0 to 6 are the stored planet's, WorldPlanet.BIO_*)
const F_OCEAN := 0
const F_PLAINS := 1
const F_FOREST := 2
const F_DESERT := 3
const F_MOUNTAINS := 4
const F_ICE_SHEET := 5
const F_SEA_ICE := 6
const F_JUNGLE := 7
const F_SAVANNA := 8
const F_TUNDRA := 9
const F_TAIGA := 10
const F_WETLAND := 11
const F_BEACH := 12
const F_HIGHLAND := 13
const F_VOLCANIC := 14

static var _d: Dictionary = {}
static var _loaded: bool = false
static var _errors: Array = []
static var _hash: String = ""
static var _alias := PackedByteArray()
static var curGen: int = 0   # 0: the data's gen; a tool or a match's setup sets it (useGen)
# The data's numbers the column read uses, as typed statics (made by _cache when the file is loaded; the data is never changed after): a dictionary read of each, a column, was a fifth of the read (window 20).
static var _kJitScale: float = 0.0
static var _kJitSeed: int = 0
static var _kJit: float = 0.0
static var _kEq: float = 0.0
static var _kPow: float = 1.0
static var _kLapse: float = 0.0
static var _kHScale: float = 1.0
static var _kNScale: float = 0.0
static var _kNOct: int = 1
static var _kNAmp: float = 0.0
static var _kTSeed: int = 0
static var _kWBand: float = 0.0
static var _kWAdv: float = 0.0
static var _kBias: float = 0.0
static var _kMScale: float = 0.0
static var _kMOct: int = 1
static var _kMSeed: int = 0
static var _kWNoise: float = 0.0
static var _kVHMin: float = 0.0
static var _kVScale: float = 0.0
static var _kVOct: int = 1
static var _kVSeed: int = 0
static var _kVAbove: float = 0.0
static var _kBeachH: float = 0.0
static var _kHighB: float = 0.0
static var _kHighH: float = 0.0
static var _kWetMoist: float = 0.0
static var _kWetH: float = 0.0
static var _kWetTemp: float = 0.0
static var _kTE := PackedFloat64Array()
static var _kME := PackedFloat64Array()
static var _kTab := PackedInt32Array()
static var _kNM: int = 1
static var _cT: float = 0.0   # climateAt's answer, for plain (which would build an Array to read two numbers)
static var _cM: float = 0.0


static func data() -> Dictionary:
	if not _loaded:
		_load()
	return _d


static func dataErrors() -> Array:
	if not _loaded:
		_load()
	return _errors


static func dataHash() -> String:
	if not _loaded:
		_load()
	return _hash


static func _load() -> void:
	_loaded = true
	_errors = []
	_d = {}
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		_errors.append("climate.json: cannot open " + PATH)
		return
	var text: String = f.get_as_text()
	var j = JSON.parse_string(text)
	if not (j is Dictionary) or j.get("schema", "") != SCHEMA:
		_errors.append("climate.json: not a %s object" % SCHEMA)
		return
	for k in ["gen", "grid", "planet", "temp", "moist", "tempEdges", "moistEdges", "table", "coast", "wetland", "highland", "volcanic", "fine"]:
		if not j.has(k):
			_errors.append("climate.json: %s is missing" % k)
	if _errors.is_empty():
		var nt: int = j.tempEdges.size() + 1
		var nm: int = j.moistEdges.size() + 1
		if j.table.size() != nt:
			_errors.append("climate.json: table has a row for each of the %d temperature bands" % nt)
		for row in j.table:
			if row.size() != nm:
				_errors.append("climate.json: each table row has a cell for each of the %d moisture bands" % nm)
		for k in range(j.fine.size()):
			if int(j.fine[k].id) != k:
				_errors.append("climate.json: fine[%d] has id %d (ids run 0, 1, 2 ...)" % [k, int(j.fine[k].id)])
		for row in j.table:
			for id in row:
				if int(id) < 0 or int(id) >= j.fine.size():
					_errors.append("climate.json: table names a biome (%d) that is not in fine" % int(id))
	if not _errors.is_empty():
		return
	_d = j
	_hash = str(text.hash())
	_alias.resize(j.fine.size())
	for k in range(j.fine.size()):
		_alias[k] = int(j.fine[k].alias)
	_cache(j)


static func _cache(j: Dictionary) -> void:
	var tp: Dictionary = j.temp
	var mp: Dictionary = j.moist
	_kJitScale = float(tp.jitScale)
	_kJitSeed = int(tp.jitSeed)
	_kJit = float(tp.jit)
	_kEq = float(tp.eq)
	_kPow = float(tp.pow)
	_kLapse = float(tp.lapse)
	_kHScale = float(tp.hScale)
	_kNScale = float(tp.noiseScale)
	_kNOct = int(tp.noiseOct)
	_kNAmp = float(tp.noiseAmp)
	_kTSeed = int(tp.seed)
	_kWBand = float(mp.wBand)
	_kWAdv = float(mp.wAdv)
	_kBias = float(mp.bias)
	_kMScale = float(mp.noiseScale)
	_kMOct = int(mp.noiseOct)
	_kMSeed = int(mp.seed)
	_kWNoise = float(mp.wNoise)
	var vc: Dictionary = j.volcanic
	_kVHMin = float(vc.hMin)
	_kVScale = float(vc.scale)
	_kVOct = int(vc.oct)
	_kVSeed = int(vc.seed)
	_kVAbove = float(vc.above)
	_kBeachH = float(j.coast.beachH)
	_kHighB = float(j.b.highlandH)
	_kHighH = float(j.highland.h)
	_kWetMoist = float(j.wetland.moistMin)
	_kWetH = float(j.wetland.hMax)
	_kWetTemp = float(j.wetland.tempMin)
	_kTE.resize(j.tempEdges.size())
	for k in range(j.tempEdges.size()):
		_kTE[k] = float(j.tempEdges[k])
	_kME.resize(j.moistEdges.size())
	for k in range(j.moistEdges.size()):
		_kME[k] = float(j.moistEdges[k])
	_kNM = j.moistEdges.size() + 1
	_kTab.resize((j.tempEdges.size() + 1) * _kNM)
	for ti in range(j.tempEdges.size() + 1):
		for mi in range(_kNM):
			_kTab[ti * _kNM + mi] = int(j.table[ti][mi])


## The generation planets are made by now: a tool's or a setup's choice, else the data's.
static func genNow() -> int:
	return curGen if curGen > 0 else int(data().get("gen", 1))


static func useGen(g: int) -> void:
	curGen = g


## The generation a setup's planet is made by: its planetGen, else the data's (WorldPlanetWorld.gen's rule). Never genNow(), which is a tool's choice in force or the last match's: a replay header is made before the match.
static func genFor(setup: Dictionary) -> int:
	var g: int = int(setup.get("planetGen", 0))
	return g if g > 0 else int(data().get("gen", 1))


## The stored biome (WorldPlanet.BIO_*) a fine biome reads as for a consumer that knows only those.
static func aliasOf(fine: int) -> int:
	if not _loaded:
		_load()
	return _alias[fine] if fine >= 0 and fine < _alias.size() else 0


static func fineName(fine: int) -> String:
	return String(data().fine[fine].name)


# ===================================================================== the lookup

static var _HALF_PI: float = SimMathx.PI * 0.5


## The longitude of (x, z) in [0, 2 pi), to about 1e-5 radians, in + - * / only: for reading a smooth field, the same on every platform.
static func _lon(z: float, x: float) -> float:
	var ax: float = absf(x)
	var az: float = absf(z)
	var mx: float = maxf(ax, az)
	if mx < 1.0e-12:
		return 0.0
	var t: float = minf(ax, az) / mx
	var t2: float = t * t
	var a: float = t * (0.9998660 + t2 * (-0.3302995 + t2 * (0.1801410 + t2 * (-0.0851330 + t2 * 0.0208351))))
	if az > ax:
		a = _HALF_PI - a
	if x < 0.0:
		a = SimMathx.PI - a
	if z < 0.0:
		a = SimMathx.TAU - a
	return a


## 0.5 + 0.5 cos(6 phi) of the latitude whose sine is y: wet at the equator, dry near 30 degrees, wet near 60, dry at the poles. A polynomial in y.
static func bandWet(y: float) -> float:
	var c: float = sqrt(maxf(0.0, 1.0 - y * y))
	var c3: float = 4.0 * c * c * c - 3.0 * c   # cos 3 phi
	return 0.5 + 0.5 * (2.0 * c3 * c3 - 1.0)


## How much the wind blows from the west at latitude sine y: 0.5 - 0.5 sin(6 phi): trade winds near the equator and the poles, westerlies between.
static func westerly(y: float) -> float:
	var c: float = sqrt(maxf(0.0, 1.0 - y * y))
	var s3: float = 3.0 * y - 4.0 * y * y * y   # sin 3 phi
	var c3: float = 4.0 * c * c * c - 3.0 * c
	return 0.5 - 0.5 * (2.0 * s3 * c3)


# ===================================================================== the grid

## The planet's moisture grid, rows uniform in the sine of the latitude (equal areas), columns in longitude: what the wind carries (0 to 1), the sea recharging it and the land raining it out.
class Grid extends RefCounted:
	var P: WorldPlanet.Planet
	var w: int = 192
	var h: int = 96
	var adv := PackedFloat32Array()     # the carried moisture at each cell
	var ht := PackedFloat32Array()      # the ground's height at each cell (the continents' function: sea below 0)
	var _cs := PackedFloat64Array()
	var _sn := PackedFloat64Array()
	var cell: int = 0
	var done: bool = false

	func _init(p: WorldPlanet.Planet) -> void:
		P = p
		var g: Dictionary = WorldClimate.data().grid
		w = int(g.w)
		h = int(g.h)
		adv.resize(w * h)
		ht.resize(w * h)
		_cs.resize(w)
		_sn.resize(w)
		for k in range(w):
			var th: float = SimMathx.TAU * (float(k) + 0.5) / float(w)
			_cs[k] = SimDetMath.cos(th)
			_sn[k] = SimDetMath.sin(th)

	var spent: int = 0         # units spent: a cell a unit, then the carry's rows (the job's budget is told in these)
	var _cph: int = 0          # the carry's phase: 0 not begun, 1 the wind's rows, 2 the blend by the wind, 3 the blend between rows, 4 the blend along the rows, 5 made
	var _crow: int = 0
	var _east := PackedFloat32Array()   # wind toward -longitude
	var _west := PackedFloat32Array()   # wind toward +longitude
	var _mix := PackedFloat32Array()
	var _vb := PackedFloat32Array()

	## Does up to n more units of the work: the cells' heights (a unit a cell), then (once whole) the moisture's carry (ten units a row of the wind, one a row of each blend); true when the grid is made. A budget
	## of the whole job or more goes through it in the one call.
	func step(n: int) -> bool:
		if done:
			return true
		var left: int = n
		var total: int = w * h
		if cell < total:
			var cu: int = 3 if WorldLand.plateB() else 1   # a cell on the B plates' ground costs about 65 us, on the stored continents' about 20
			var last: int = mini(total, cell + maxi(1, n / cu))
			for i in range(cell, last):
				var r: int = i / w
				var k: int = i - r * w
				var y: float = -1.0 + (float(r) + 0.5) * 2.0 / float(h)
				var c: float = sqrt(1.0 - y * y)
				ht[i] = WorldPlanet.ground(P, c * _cs[k], y, c * _sn[k])
			left -= (last - cell) * cu
			spent += (last - cell) * cu
			cell = last
			if cell < total:
				return false
			_cph = 1
			_crow = 0
			_east.resize(total)
			_west.resize(total)
			_mix.resize(total)
			_vb.resize(total)
		if left > 0 or n >= total:
			_carry(left)
		return done

	func finishNow() -> void:
		step(1 << 40)

	## The wind's moisture, both ways round each row twice (so the carry crosses the seam), then the two blended by the latitude's wind and blurred a little between rows; stepped by rows, the same arithmetic.
	func _carry(left0: int) -> void:
		var left: int = left0
		var d: Dictionary = WorldClimate.data().moist
		var evap: float = d.evap
		var rain0: float = d.rain0
		var rainOro: float = d.rainOro
		var oroH: float = d.oroH
		var b: float = d.blur
		var bh: float = d.blurLon
		while _cph < 5 and (left > 0 or left0 >= (1 << 30)):
			if _cph == 1:
				var r: int = _crow
				var base: int = r * w
				for dir in range(2):
					var m: float = 0.0
					for lap in range(2 * w):
						var k: int = lap % w if dir == 0 else w - 1 - (lap % w)
						var kp: int = (k - 1 + w) % w if dir == 0 else (k + 1) % w
						var hh: float = ht[base + k]
						if hh < 0.0:
							m = minf(1.0, m + evap)
						else:
							var rise: float = maxf(0.0, hh - maxf(ht[base + kp], 0.0))
							m = maxf(0.0, m - rain0 - rainOro * rise / oroH)
						if lap >= w:
							if dir == 0:
								_west[base + k] = m
							else:
								_east[base + k] = m
				_crow += 1
				left -= 10
				spent += 10
				if _crow >= h:
					_cph = 2
					_crow = 0
			elif _cph == 2:
				var r: int = _crow
				var y: float = -1.0 + (float(r) + 0.5) * 2.0 / float(h)
				var we: float = WorldClimate.westerly(y)
				for k in range(w):
					_mix[r * w + k] = _west[r * w + k] * we + _east[r * w + k] * (1.0 - we)
				_crow += 1
				left -= 1
				spent += 1
				if _crow >= h:
					_cph = 3
					_crow = 0
			elif _cph == 3:
				var r: int = _crow
				var ra: int = maxi(0, r - 1)
				var rb: int = mini(h - 1, r + 1)
				for k in range(w):
					_vb[r * w + k] = _mix[r * w + k] * (1.0 - 2.0 * b) + _mix[ra * w + k] * b + _mix[rb * w + k] * b
				_crow += 1
				left -= 1
				spent += 1
				if _crow >= h:
					_cph = 4
					_crow = 0
			else:
				var r: int = _crow
				for k in range(w):
					adv[r * w + k] = _vb[r * w + k] * (1.0 - 2.0 * bh) + _vb[r * w + (k - 1 + w) % w] * bh + _vb[r * w + (k + 1) % w] * bh
				_crow += 1
				left -= 1
				spent += 1
				if _crow >= h:
					_cph = 5
					done = true
					_east = PackedFloat32Array()
					_west = PackedFloat32Array()
					_mix = PackedFloat32Array()
					_vb = PackedFloat32Array()


## The planet's grid (built when first asked: about the cost of a few hundred ring columns, once a planet).
static func gridOf(P: WorldPlanet.Planet) -> Grid:
	if P.grid == null:
		var G := Grid.new(P)
		G.finishNow()
		P.grid = G
	return P.grid


## The carried moisture at a point (a unit vector): bilinear on the grid, rows by the sine of the latitude, columns by longitude.
static func advAt(G: Grid, px: float, py: float, pz: float) -> float:
	var w: int = G.w
	var h: int = G.h
	var fr: float = (py + 1.0) * 0.5 * float(h) - 0.5
	var r0: int = int(floor(fr))
	var tr: float = fr - float(r0)
	var ra: int = clampi(r0, 0, h - 1)
	var rb: int = clampi(r0 + 1, 0, h - 1)
	var fk: float = _lon(pz, px) / SimMathx.TAU * float(w) - 0.5
	var k0: int = int(floor(fk))
	var tk: float = fk - float(k0)
	var ka: int = posmod(k0, w)
	var kb: int = posmod(k0 + 1, w)
	var a: float = G.adv[ra * w + ka] * (1.0 - tk) + G.adv[ra * w + kb] * tk
	var b: float = G.adv[rb * w + ka] * (1.0 - tk) + G.adv[rb * w + kb] * tk
	return a * (1.0 - tr) + b * tr


## The temperature (about 0 to 1) and moisture (0 to 1) at a point of height h.
static func climateAt(P: WorldPlanet.Planet, px: float, py: float, pz: float, h: float) -> Array:
	_climTM(P, px, py, pz, h)
	return [_cT, _cM]


## climateAt's arithmetic, its two numbers left in _cT and _cM.
static func _climTM(P: WorldPlanet.Planet, px: float, py: float, pz: float, h: float) -> void:
	if not _loaded:
		_load()
	# the latitude wobbles by up to jit (a slow noise), so the belts of climate are wavy and not ruled lines
	var yj: float = SimMathx.jclamp(py + (WorldPlanet._fbm(P.R, px, py, pz, _kJitScale, 2, P.seed + _kJitSeed) - 0.5) * 2.0 * _kJit, -1.0, 1.0)
	var cl: float = sqrt(maxf(0.0, 1.0 - yj * yj))
	var T: float = _kEq * SimDetMath.pow(cl, _kPow) - _kLapse * maxf(h, 0.0) / _kHScale
	T += (WorldPlanet._fbm(P.R, px, py, pz, _kNScale, _kNOct, P.seed + _kTSeed) - 0.5) * 2.0 * _kNAmp
	var G: Grid = gridOf(P)
	var M: float = _kWBand * bandWet(yj) + _kWAdv * advAt(G, px, py, pz)
	M += _kBias
	M += (WorldPlanet._fbm(P.R, px, py, pz, _kMScale, _kMOct, P.seed + _kMSeed) - 0.5) * 2.0 * _kWNoise
	_cT = T
	_cM = SimMathx.jclamp(M, 0.0, 1.0)


## The fine biome of ordinary land at a point of height h (sea and ice are the surface function's); sets P.outF and returns the stored biome it reads as.
static func plain(P: WorldPlanet.Planet, px: float, py: float, pz: float, h: float) -> int:
	if h < 0.0:
		P.outF = F_OCEAN
		return WorldPlanet.BIO_OCEAN
	if not _loaded:
		_load()
	var onB: bool = WorldLand.plateB()   # Research's B plates: their volcanic score makes the volcanic fields, in place of the noise (window 13)
	var bv: bool = onB and WorldPlateB.volcAt(P, px, py, pz) > WorldPlateB.K.volcanic
	var above: float = P.c.mountainAbove
	if h > above and not bv:
		P.outF = F_MOUNTAINS
		return WorldPlanet.BIO_MOUNTAINS
	_climTM(P, px, py, pz, h)
	var T: float = _cT
	var M: float = _cM
	var fine: int
	if bv and T >= _kTE[0] and h >= _kBeachH:   # not too cold for it, and not a beach (Research's notCold)
		fine = F_VOLCANIC
	elif h > above:
		fine = F_MOUNTAINS
	elif not onB and h >= _kVHMin and WorldPlanet._fbm(P.R, px, py, pz, _kVScale, _kVOct, P.seed + _kVSeed) > _kVAbove:
		fine = F_VOLCANIC
	elif h >= (_kHighB if onB else _kHighH):
		fine = F_HIGHLAND
	elif h < _kBeachH:
		fine = F_BEACH
	elif M >= _kWetMoist and h < _kWetH and T >= _kWetTemp:
		fine = F_WETLAND
	else:
		var ti: int = 0
		for e in _kTE:
			if T >= e:
				ti += 1
		var mi: int = 0
		for e in _kME:
			if M >= e:
				mi += 1
		fine = _kTab[ti * _kNM + mi]
	P.outF = fine
	return _alias[fine]
