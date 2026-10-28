class_name WorldCraters
extends RefCounted
## A slam's crater by material (docs/world/craters-by-material.md; data/biomes/craters.json, off by default): Combat's rows of docs/combat/biomes.md section 4.3, keyed by the look class the slam lands on
## (WorldContact.lookAt, the beam strips included). contact.gd's slam asks shapeAt() before it digs and hands the shape to WorldCrater.dig, which scales today's bowl by it (radius, depth, rim, the wall's
## steep); then after() lays what the material does next: the floe breaking (breakThrough, the same cut as the FLOE SPLIT aftermath), water standing in the bowl (fill) and the bowl filling back (refill, an
## aftermath job on S.aftermathJobs). The embed's threshold scales with the row's depth (ruling 3: today's embed rate on every surface) and embedMul is how deep he sits (the embed event's depth).
##
## State: none of its own. The jobs, the floe's slot (SPLIT) and the flooded bowl (FLOODED) are after.gd's state (S.aftermath, S.aftermathT, S.aftermathJobs), which a match sizes with this switch on as with
## after.json's. The crater event of a shaped bowl carries the material in its `surface` field (not one of the event's hashed fields); the director sends crater_shape from it with eventFor(). With the switch
## off shapeAt() is empty, the dig is today's to the bit and nothing is allocated.

const PATH := "res://data/biomes/craters.json"
const SCHEMA := "biomes.craters/1"
const BUILT: Array = ["paving", "rock", "soil", "sand", "rubble"]   # today's five classes: their rows apply only with touchBuilt on
const S_R: int = 0          # a shape: [radius, depth, rim, steep, refill, refillTicks, embedMul, fill, seaCols, breakThrough, look]
const S_D: int = 1
const S_RIM: int = 2
const S_STEEP: int = 3
const S_REFILL: int = 4
const S_RT: int = 5
const S_EMB: int = 6
const S_FILL: int = 7       # 0 none, 1 the biome's water table (fill "water"), 2 the sea within seaCols (fill "waterNearSea")
const S_SEA: int = 8
const S_BREAK: int = 9
const S_LOOK: int = 10      # the look class, a code into WorldGround.LOOKS
const FILLS: Array = ["", "water", "waterNearSea"]
static var NONE := PackedFloat64Array()   # no shape: today's bowl (packed arrays are copied on write, so handing it out is safe)

static var _d: Dictionary = {}
static var _parsed: Dictionary = {}
static var _loaded: bool = false
static var _errors: Array = []
static var K_ON: bool = false
static var K_BUILT: bool = false
static var K_SCALES: bool = true
static var _shapes: Array = []   # per look code: the shape, or an empty array for no row (today's bowl)


static func data() -> Dictionary:
	if not _loaded:
		_load()
	return _d


static func parsed() -> Dictionary:
	if not _loaded:
		_load()
	return _parsed


static func dataErrors() -> Array:
	if not _loaded:
		_load()
	return _errors


static func on() -> bool:
	if not _loaded:
		_load()
	return K_ON


static func _load() -> void:
	_loaded = true
	_errors = []
	_d = {}
	_shapes = []
	for k in range(WorldGround.LOOKS.size()):
		_shapes.append(NONE)
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return   # no file: the module is off
	var j = JSON.parse_string(f.get_as_text())
	if not (j is Dictionary) or j.get("schema", "") != SCHEMA:
		_errors.append("craters.json: not a %s object" % SCHEMA)
		return
	for k in ["enabled", "touchBuilt", "embedThresholdScales", "classes"]:
		if not j.has(k):
			_errors.append("craters.json: %s is missing" % k)
	if not _errors.is_empty():
		return
	for name in j.classes:
		var r: Dictionary = j.classes[name]
		var code: int = WorldGround.LOOKS.find(String(name))
		if code < 0:
			_errors.append("craters.json: %s is not a look class (%s)" % [name, str(WorldGround.LOOKS)])
			continue
		for k in ["radius", "depth", "rim", "steep"]:
			if not r.has(k):
				_errors.append("craters.json: %s: %s is missing" % [name, k])
		if not _errors.is_empty():
			continue
		if float(r.radius) <= 0.0 or float(r.depth) <= 0.0 or float(r.rim) < 0.0 or float(r.steep) < 0.25:
			_errors.append("craters.json: %s: radius and depth above 0, rim at least 0, steep at least 0.25" % name)
		if r.has("refill") != r.has("refillTicks") or float(r.get("refill", 0.5)) <= 0.0 or float(r.get("refill", 0.5)) > 0.95 or int(r.get("refillTicks", 1)) < 1:
			_errors.append("craters.json: %s: refill (above 0, at most 0.95) and refillTicks (at least 1) come together" % name)
		var fill: int = FILLS.find(String(r.get("fill", "")))
		if fill < 0 or r.has("seaCols") != (fill == 2) or int(r.get("seaCols", 1)) < 1:
			_errors.append("craters.json: %s: fill is water or waterNearSea, and seaCols (at least 1) comes with waterNearSea only" % name)
		if not _errors.is_empty():
			continue
		_shapes[code] = PackedFloat64Array([float(r.radius), float(r.depth), float(r.rim), float(r.steep), float(r.get("refill", 0.0)), float(r.get("refillTicks", 0)), float(r.get("embedMul", 1.0)),
			float(fill), float(r.get("seaCols", 0)), 1.0 if bool(r.get("breakThrough", false)) else 0.0, float(code)])
	if not _errors.is_empty():
		for k in range(_shapes.size()):
			_shapes[k] = NONE
		return
	_d = j
	_parsed = j
	K_ON = bool(j.enabled)
	K_BUILT = bool(j.touchBuilt)
	K_SCALES = bool(j.embedThresholdScales)


# ===================================================================== queries

## The shape a slam at x digs: the row of the look class there (WorldContact.lookAt: a gen 2 world's look, a beam's strip, or today's surface), or NONE (empty: today's bowl) with the switch off, for a class
## without a row, and for today's five classes while touchBuilt is off. Call it before the dig: the dig changes the ground (a heap is dug away, paving is dug through).
static func shapeAt(S: SimState, x: float) -> PackedFloat64Array:
	if not on():
		return NONE
	var look: String = WorldContact.lookAt(S, x)
	if not K_BUILT and BUILT.has(look):
		return NONE
	var code: int = WorldGround.LOOKS.find(look)
	return _shapes[code] if code >= 0 else NONE


## A look class's shape (NONE for none), whatever the switches: for the checks and the director's preview.
static func shapeOf(look: String) -> PackedFloat64Array:
	if not _loaded:
		_load()
	var code: int = WorldGround.LOOKS.find(look)
	return _shapes[code] if code >= 0 else NONE


static func lookName(shape: PackedFloat64Array) -> String:
	return String(WorldGround.LOOKS[int(shape[S_LOOK])]) if shape.size() > 0 else ""


## The embed's threshold multiplier for this shape: the row's depth (embedThresholdScales on, ruling 3), else 1. The bowl is that much deeper or shallower, so the rate is today's.
static func threshold(shape: PackedFloat64Array) -> float:
	return shape[S_D] if shape.size() > 0 and K_SCALES else 1.0


## How deep an embedded body sits, as a multiple of the bowl's depth: the row's embedMul, else 1. A look (the embed event's depth), never how often.
static func sink(shape: PackedFloat64Array) -> float:
	return shape[S_EMB] if shape.size() > 0 else 1.0


## The crater_shape event's fields for a shaped crater: `c` is the crater record or its crater fx event (x, y, r, depth, rim, owner: the bowl as dug), `surface` the material (the crater event's `surface`),
## and `shape` the material's row (its factors, refill, embedMul, fill, breakThrough, and the looks: cracks, ejecta, rimKind, treesLean, glowTicks). The director sends
## it (the event is the director's, as biomes.md section 4.3 has it, and is not one of World's hashed events); {} for a material without a row.
static func eventFor(c, surface: String) -> Dictionary:
	var row: Dictionary = data().get("classes", {}).get(surface, {})
	if row.is_empty():
		return {}
	var shape: Dictionary = {}
	for k in ["radius", "depth", "rim", "steep", "refill", "refillTicks", "embedMul", "fill", "seaCols", "breakThrough", "cracks", "ejecta", "rimKind", "treesLean", "glowTicks"]:
		if row.has(k):
			shape[k] = row[k]
	return {"x": float(c.x), "y": float(c.y), "r": float(c.r), "depth": float(c.depth), "rim": float(c.rim), "owner": float(c.owner), "surface": surface, "shape": shape}


# ===================================================================== after the dig

## What the material does once its bowl is dug (contact.gd calls it with the record dig returned and the shape it dug with): on sea ice a bowl whose floor reaches below the sea breaks the floe (and the
## rest is water: no fill and no refill); else water stands in it (fill) and it fills back (refill, a job). True when the floe broke (contact then does not embed him: there is no bowl to sit in).
static func after(S: SimState, rec, shape: PackedFloat64Array, z: float = 0.0) -> bool:
	if shape.size() == 0 or rec == null:
		return false
	WorldAfter._ensure(S)
	var k: int = -1
	if S.depthOn:
		k = WorldTerrain.enterRow(S, WorldTerrain.rowOfZ(z))
	var broke: bool = false
	if shape[S_BREAK] > 0.0:
		broke = _floe(S, rec)
	if not broke:
		if shape[S_FILL] > 0.0:
			WorldAfter.flood(S, _bowlCols(rec), "waterTable" if int(shape[S_FILL]) == 1 else "sea", int(shape[S_SEA]))
		if shape[S_REFILL] > 0.0:
			var c0: int = _col(rec.x)
			S.aftermathJobs.append([c0, int(ceil(rec.r / SimConst.COL)) + 1, 0, 0, WorldAfter.J_REFILL, int(S.waterTick), z, rec.x, rec.r, rec.depth, shape[S_STEEP], shape[S_REFILL], int(shape[S_RT]), 0.0])
	if S.depthOn:
		WorldTerrain.leaveRow(S, k)
	return broke


static func _col(x: float) -> int:
	return int(floor(SimWrap.wrap(x) / SimConst.COL)) % SimConst.NC


## The columns inside the bowl's lip (u below 1), in order.
static func _bowlCols(rec) -> PackedInt32Array:
	var NC: int = SimConst.NC
	var c0: int = _col(rec.x)
	var n: int = int(ceil(rec.r / SimConst.COL)) + 1
	var out := PackedInt32Array()
	for q in range(-n, n + 1):
		var i: int = posmod(c0 + q, NC)
		if absf(SimWrap.sdx(rec.x, float(i) * SimConst.COL)) < rec.r:
			out.append(i)
	return out


## breakThrough on sea ice: the bowl's columns on the floe (sea ice whose ground was above the sea: S.base) whose floor is now below the sea. If any, the floe breaks: a slot that many columns wide at the
## crater's centre, cut and filled as the FLOE SPLIT aftermath cuts it (breakThrough). False when the bowl stayed inside the floe.
static func _floe(S: SimState, rec) -> bool:
	var fc: PackedByteArray = WorldBiomes.fineCols
	if fc.size() != SimConst.NC:
		return false
	var sid: int = WorldClimate.F_SEA_ICE
	var low: PackedFloat32Array = WorldTerrain.lowD(S)
	var n: int = 0
	for i in _bowlCols(rec):
		if int(fc[i]) == sid and S.base[i] > WorldWater.SEA_LEVEL and S.base[i] + low[i] < WorldWater.SEA_LEVEL:
			n += 1
	if n == 0:
		return false
	breakThrough(S, _col(rec.x), n)
	return true


## The floe's slot (shared by a slam's breakThrough and the FLOE SPLIT aftermath, after.gd split): wcols columns centred on `mid`, cut to after.json's splitDepth below the sea, its heap cleared, filled with
## the sea, and marked SPLIT. The plates either side do not move after.
static func breakThrough(S: SimState, mid: int, wcols: int) -> void:
	var NC: int = SimConst.NC
	var dep: float = WorldAfter.splitDepth()
	for q in range(wcols):
		var i2: int = posmod(mid - (wcols - 1) / 2 + q, NC)
		S.deform[i2] = minf(S.deform[i2], -(S.base[i2] + dep))
		S.rubble[i2] = 0.0
		S.water[i2] = maxf(S.water[i2], -(S.base[i2] + S.deform[i2]) + WorldWater.SEA_LEVEL)
		WorldAfter._put(S, i2, WorldAfter.SPLIT, 0)


## One tick of a refill job ([c0, half, 0, age, J_REFILL, t0, z, x, r, depth, steep, refill, ticks, share done]): the bowl rises by the share of its own depth due by now, column by column in the bowl's own
## shape (sand slumps, mud closes, snow drifts), never above the deform ceiling; standing water keeps its level (the rise comes off its depth). True when it has run its ticks.
static func stepRefill(S: SimState, w: Array) -> bool:
	var I: int = WorldAfter.I_P
	var clock: int = int(S.waterTick) - int(w[WorldAfter.I_T0])
	var dur: int = maxi(1, int(w[I + 5]))
	var f0: float = float(w[I + 6])
	var f1: float = float(w[I + 4]) * minf(1.0, float(clock) / float(dur))
	if f1 > f0:
		var NC: int = SimConst.NC
		var x: float = float(w[I])
		var R: float = float(w[I + 1])
		var dk: float = (f1 - f0) * float(w[I + 2])
		var steep: float = float(w[I + 3])
		var c0: int = _col(x)
		var n: int = int(ceil(R / SimConst.COL)) + 1
		for q in range(-n, n + 1):
			var i: int = posmod(c0 + q, NC)
			var u: float = absf(SimWrap.sdx(x, float(i) * SimConst.COL)) / R
			if u >= 1.0:
				continue
			var t: float = WorldCrater.bowlT(u, steep)
			var old: float = S.deform[i]
			S.deform[i] = minf(WorldCrater.DEFORM_CEIL, old + dk * t * t)
			if S.water[i] > 0.0:
				S.water[i] = maxf(0.0, S.water[i] - (S.deform[i] - old))
		w[I + 6] = f1
		WorldTerrain.lowRefresh(S, c0, n + 2)
	return clock >= dur
