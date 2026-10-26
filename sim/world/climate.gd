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


## The generation planets are made by now: a tool's or a setup's choice, else the data's.
static func genNow() -> int:
	return curGen if curGen > 0 else int(data().get("gen", 1))


static func useGen(g: int) -> void:
	curGen = g


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

	## Reads up to n more cells' heights, then (once whole) carries the moisture; true when the grid is made.
	func step(n: int) -> bool:
		if done:
			return true
		var total: int = w * h
		var last: int = mini(total, cell + n)
		for i in range(cell, last):
			var r: int = i / w
			var k: int = i - r * w
			var y: float = -1.0 + (float(r) + 0.5) * 2.0 / float(h)
			var c: float = sqrt(1.0 - y * y)
			ht[i] = WorldPlanet.ground(P, c * _cs[k], y, c * _sn[k])
		cell = last
		if cell >= total:
			_carry()
			done = true
		return done

	func finishNow() -> void:
		step(w * h)

	## The wind's moisture, both ways round each row twice (so the carry crosses the seam), then the two blended by the latitude's wind and blurred a little between rows.
	func _carry() -> void:
		var d: Dictionary = WorldClimate.data().moist
		var evap: float = d.evap
		var rain0: float = d.rain0
		var rainOro: float = d.rainOro
		var oroH: float = d.oroH
		var east := PackedFloat32Array()   # wind toward -longitude
		var west := PackedFloat32Array()   # wind toward +longitude
		east.resize(w * h)
		west.resize(w * h)
		for r in range(h):
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
							west[base + k] = m
						else:
							east[base + k] = m
		var mix := PackedFloat32Array()
		mix.resize(w * h)
		for r in range(h):
			var y: float = -1.0 + (float(r) + 0.5) * 2.0 / float(h)
			var we: float = WorldClimate.westerly(y)
			for k in range(w):
				mix[r * w + k] = west[r * w + k] * we + east[r * w + k] * (1.0 - we)
		var b: float = d.blur
		var vb := PackedFloat32Array()
		vb.resize(w * h)
		for r in range(h):
			var ra: int = maxi(0, r - 1)
			var rb: int = mini(h - 1, r + 1)
			for k in range(w):
				vb[r * w + k] = mix[r * w + k] * (1.0 - 2.0 * b) + mix[ra * w + k] * b + mix[rb * w + k] * b
		var bh: float = d.blurLon
		for r in range(h):
			for k in range(w):
				adv[r * w + k] = vb[r * w + k] * (1.0 - 2.0 * bh) + vb[r * w + (k - 1 + w) % w] * bh + vb[r * w + (k + 1) % w] * bh


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
	var d: Dictionary = data()
	var tp: Dictionary = d.temp
	var mp: Dictionary = d.moist
	# the latitude wobbles by up to jit (a slow noise), so the belts of climate are wavy and not ruled lines
	var yj: float = SimMathx.jclamp(py + (WorldPlanet._fbm(P.R, px, py, pz, tp.jitScale, 2, P.seed + int(tp.jitSeed)) - 0.5) * 2.0 * float(tp.jit), -1.0, 1.0)
	var cl: float = sqrt(maxf(0.0, 1.0 - yj * yj))
	var T: float = float(tp.eq) * SimDetMath.pow(cl, float(tp.pow)) - float(tp.lapse) * maxf(h, 0.0) / float(tp.hScale)
	T += (WorldPlanet._fbm(P.R, px, py, pz, tp.noiseScale, int(tp.noiseOct), P.seed + int(tp.seed)) - 0.5) * 2.0 * float(tp.noiseAmp)
	var G: Grid = gridOf(P)
	var M: float = float(mp.wBand) * bandWet(yj) + float(mp.wAdv) * advAt(G, px, py, pz)
	M += float(mp.bias)
	M += (WorldPlanet._fbm(P.R, px, py, pz, mp.noiseScale, int(mp.noiseOct), P.seed + int(mp.seed)) - 0.5) * 2.0 * float(mp.wNoise)
	return [T, SimMathx.jclamp(M, 0.0, 1.0)]


## The fine biome of ordinary land at a point of height h (sea and ice are the surface function's); sets P.outF and returns the stored biome it reads as.
static func plain(P: WorldPlanet.Planet, px: float, py: float, pz: float, h: float) -> int:
	if h < 0.0:
		P.outF = F_OCEAN
		return WorldPlanet.BIO_OCEAN
	var onB: bool = WorldLand.plateB()   # Research's B plates: their volcanic score makes the volcanic fields, in place of the noise (window 13)
	var bv: bool = onB and WorldPlateB.volcAt(P, px, py, pz) > WorldPlateB.K.volcanic
	if h > P.c.mountainAbove and not bv:
		P.outF = F_MOUNTAINS
		return WorldPlanet.BIO_MOUNTAINS
	var d: Dictionary = data()
	var cm: Array = climateAt(P, px, py, pz, h)
	var T: float = cm[0]
	var M: float = cm[1]
	var vc: Dictionary = d.volcanic
	var fine: int
	if bv and T >= float(d.tempEdges[0]) and h >= float(d.coast.beachH):   # not too cold for it, and not a beach (Research's notCold)
		fine = F_VOLCANIC
	elif h > P.c.mountainAbove:
		fine = F_MOUNTAINS
	elif not onB and h >= float(vc.hMin) and WorldPlanet._fbm(P.R, px, py, pz, vc.scale, int(vc.oct), P.seed + int(vc.seed)) > float(vc.above):
		fine = F_VOLCANIC
	elif h >= (float(d.b.highlandH) if onB else float(d.highland.h)):
		fine = F_HIGHLAND
	elif h < float(d.coast.beachH):
		fine = F_BEACH
	elif M >= float(d.wetland.moistMin) and h < float(d.wetland.hMax) and T >= float(d.wetland.tempMin):
		fine = F_WETLAND
	else:
		var ti: int = 0
		for e in d.tempEdges:
			if T >= float(e):
				ti += 1
		var mi: int = 0
		for e in d.moistEdges:
			if M >= float(e):
				mi += 1
		fine = int(d.table[ti][mi])
	P.outF = fine
	return _alias[fine]
