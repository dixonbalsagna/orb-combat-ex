class_name WorldFill
extends RefCounted
## Water v2 (docs/world/water-v2.md; data/biomes/water.json, off by default): holes the fight digs fill with water where water would plausibly come from. The sea, a lake and water already standing are sources
## for ground close to them; wet biomes (wetland, beach, jungle, and taiga and tundra near water) have a water table a hole is dug through. The fill is a cheap local rate behind a front, in windows that open only
## where terrain was dug and close when nothing moves; it is a cosmetic backdrop to the fight (it never traps, lifts or slows a fighter, never does damage) with a cue for the renderer: the "water_fill" event.
## Windows are entries of S.waterWin with more than four elements (the flow model's have four, so with the switch off nothing here runs and the state is as it was):
##   fill [c0, half, quiet, age, 1, startTick, startCol, nearLevel, tableDepth, nearCol, doused]    wave [c0, half, quiet, age, 2, startTick, x, push, stepsLeft, surface, 0]
## Deterministic, float64, no draw; the per-tick cost is zero when no window is open and bounded by maxWindows x (2 halfMax + 1) columns every second tick when one is.

const PATH := "res://data/biomes/water.json"
const SCHEMA := "biomes.water/1"
const NONE: float = -1.0e9

static var _d: Dictionary = {}
static var _loaded: bool = false
static var _errors: Array = []
static var K_ON: bool = false
static var _tableD: Dictionary = {}   # biome name -> [depth, near]
static var K_REACH: int = 36
static var K_RISE: float = 40.0
static var K_FRONT: float = 3.0
static var K_RATE: float = 9.0
static var K_MINDUG: float = 6.0
static var K_HALFMAX: int = 120
static var K_PAD: int = 6
static var K_MAXWIN: int = 4
static var K_AGEMAX: int = 400
static var K_SETTLE: int = 3
static var K_WADE: float = 75.0
static var K_WAVE_E: float = 6.0
static var K_WAVE_DEPTH: float = 40.0
static var K_WAVE_R: float = 600.0
static var K_WAVE_BAND: float = 100.0
static var K_WAVE_PUSH: float = 75.0
static var K_WAVE_STEPS: int = 6
static var K_DOUSE: float = 0.3
static var K_SURF_ON: bool = false
static var K_SURF_TICKS: int = 30


static func data() -> Dictionary:
	if not _loaded:
		_load()
	return _d


static func dataErrors() -> Array:
	if not _loaded:
		_load()
	return _errors


static func on() -> bool:
	if not _loaded:
		_load()
	return K_ON


## The surfacing rule (Game Design 2026-10-23b item 7): on, and in how many ticks a body that has gone under surfaces. Independent of the fill's switch.
static func surfaceOn() -> bool:
	if not _loaded:
		_load()
	return K_SURF_ON


static func surfaceTicks() -> int:
	if not _loaded:
		_load()
	return K_SURF_TICKS


## For tools and checks: the surfacing rule's switch for this process (the file is not touched).
static func setSurface(on: bool) -> void:
	if not _loaded:
		_load()
	K_SURF_ON = on


static func parsed() -> Dictionary:
	return data()


## How far below the original ground a biome's water stands (water.json table), or NONE for a dry biome.
static func tableDepth(name: String) -> float:
	if not _loaded:
		_load()
	return float(_tableD[name][0]) if _tableD.has(name) else NONE


static func _load() -> void:
	_loaded = true
	_errors = []
	_d = {}
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return   # no file: the water module is as it was
	var j = JSON.parse_string(f.get_as_text())
	if not (j is Dictionary) or j.get("schema", "") != SCHEMA:
		_errors.append("water.json: not a %s object" % SCHEMA)
		return
	for k in ["enabled", "table", "near", "fill", "wade", "wave", "douse"]:
		if not j.has(k):
			_errors.append("water.json: %s is missing" % k)
	if not _errors.is_empty():
		return
	var names: Array = []
	for g in WorldClimate.data().get("fine", []):
		names.append(String(g.name))
	for k in j.table:
		if not names.has(String(k)):
			_errors.append("water.json: table names %s, which climate.json does not have" % String(k))
	if j.has("surface") and (not (j.surface is Dictionary) or int(j.surface.ticks) < 2):
		_errors.append("water.json: surface is {enabled, ticks} with ticks at least 2")
	if int(j.fill.halfMax) < 4 or int(j.fill.maxWindows) < 1 or float(j.fill.rate) <= 0.0 or int(j.near.reach) < 1 or float(j.near.front) <= 0.0:
		_errors.append("water.json: fill.halfMax at least 4, maxWindows at least 1, rate above 0, near.reach at least 1, near.front above 0")
	if not _errors.is_empty():
		return
	_d = j
	K_ON = bool(j.enabled)
	_tableD = {}
	for k in j.table:
		_tableD[String(k)] = [float(j.table[k].depth), bool(j.table[k].near)]
	K_REACH = int(j.near.reach)
	K_RISE = float(j.near.maxRise)
	K_FRONT = float(j.near.front)
	K_RATE = float(j.fill.rate)
	K_MINDUG = float(j.fill.minDug)
	K_HALFMAX = int(j.fill.halfMax)
	K_PAD = int(j.fill.pad)
	K_MAXWIN = int(j.fill.maxWindows)
	K_AGEMAX = int(j.fill.ageMax)
	K_SETTLE = int(j.fill.settle)
	K_WADE = float(j.wade.below)
	K_WAVE_E = float(j.wave.minE)
	K_WAVE_DEPTH = float(j.wave.minDepth)
	K_WAVE_R = float(j.wave.radius)
	K_WAVE_BAND = float(j.wave.band)
	K_WAVE_PUSH = float(j.wave.push)
	K_WAVE_STEPS = int(j.wave.steps)
	K_DOUSE = float(j.douse.scorchMin)
	K_SURF_ON = bool(j.surface.enabled) if j.has("surface") else false
	K_SURF_TICKS = int(j.surface.ticks) if j.has("surface") else 30


## Water shallower than this at x is waded: a body passing through it is not dragged or sunk (it still skims). Always false with the switch off.
static func wading(S: SimState, x: float) -> bool:
	if not on():
		return false
	var d: float = S.water[int(floor(SimWrap.wrap(x) / SimConst.COL)) % SimConst.NC]
	return d < K_WADE


static func _openLevel(S: SimState, i: int) -> float:
	var NC: int = SimConst.NC
	if S.base[i] < WorldWater.RESERVOIR_BASE:
		return WorldWater.SEA_LEVEL
	if S.water[i] >= WorldWater.MIN_DEPTH:
		return S.base[i] + WorldTerrain.lowD(S)[i] + S.water[i]
	return NONE


## Terrain changed round column c0 (half width cols): if ground in it is dug well below its original height, open (or widen) a fill window.
static func open(S: SimState, c0: int, cols: int) -> void:
	var NC: int = SimConst.NC
	var dfm: PackedFloat32Array = WorldTerrain.lowD(S)
	var deepC: int = -1
	var deepest: float = -K_MINDUG
	for k in range(-cols, cols + 1):
		var i: int = (c0 + k + NC) % NC
		if dfm[i] <= deepest:
			deepest = dfm[i]
			deepC = i
	if deepC < 0:
		return
	var hw: int = mini(K_HALFMAX, cols + K_PAD)
	var nfill: int = 0
	for w in S.waterWin:
		if w.size() > 4 and int(w[4]) == 1:
			nfill += 1
			if absi(WorldWater.colDelta(deepC, int(w[0]))) <= int(w[1]) + hw:
				w[1] = mini(K_HALFMAX, maxi(int(w[1]), absi(WorldWater.colDelta(deepC, int(w[0]))) + hw))
				w[2] = 0
				return
	if nfill >= K_MAXWIN:
		return
	# the biome's water table at the deepest hole, and the open water in reach
	var td: float = NONE
	var needNear: bool = false
	var nm: String = WorldBiomes.fineNameAt((float(deepC) + 0.5) * SimConst.COL)
	if _tableD.has(nm):
		td = _tableD[nm][0]
		needNear = _tableD[nm][1]
	var srcCol: int = -1
	var nearLevel: float = NONE
	var dugLo: int = deepC   # the dug span's two ends: open water in reach of either end feeds the whole run of dug ground (a scar joins the sea to its far end)
	var dugHi: int = deepC
	for k in range(-cols, cols + 1):
		var ik: int = (c0 + k + NC) % NC
		if dfm[ik] <= -K_MINDUG:
			dugLo = ik if absi(WorldWater.colDelta(c0, ik)) >= 0 and (WorldWater.colDelta(c0, ik) < WorldWater.colDelta(c0, dugLo)) else dugLo
			dugHi = ik if (WorldWater.colDelta(c0, ik) > WorldWater.colDelta(c0, dugHi)) else dugHi
	for d in range(0, K_REACH + 1):
		for e in [dugLo, dugHi]:
			for sgn in [1, -1]:
				var j: int = posmod(e + sgn * d, NC)
				var lv: float = _openLevel(S, j)
				if lv != NONE and S.base[deepC] <= lv + K_RISE:
					srcCol = j
					nearLevel = lv
					break
			if srcCol >= 0:
				break
		if srcCol >= 0:
			break
	if srcCol < 0 and (td == NONE or needNear):
		return   # no water would come: a dry hole stays dry
	var entry: Array = [c0, hw, 0, 0, 1, S.tick, srcCol if srcCol >= 0 else deepC, nearLevel, td if (srcCol >= 0 or not needNear) else NONE, srcCol, 0]
	S.waterWin.append(entry)
	_cue(S, entry, deepest)


static func _cue(S: SimState, w: Array, dug: float) -> void:
	var e := SimFx._ev(S, "water_fill")
	var COL: float = SimConst.COL
	var stepS: float = float(WorldWater.STEP_TICKS) * SimConst.DT
	var start: int = int(w[6])
	e.x = (float(start) + 0.5) * COL
	e.y = float(w[7]) if float(w[7]) != NONE else S.base[start] - float(w[8])
	e.n = int(w[1]) * 2 + 1
	e.r = float(w[1]) * COL
	e.spd = K_FRONT * COL / stepS if int(w[9]) >= 0 else 0.0   # a seeping table has no front
	e.k = K_RATE / stepS
	e.amount = absf(dug)
	e.dur = (absf(dug) / K_RATE + (float(w[1]) / K_FRONT if int(w[9]) >= 0 else 0.0)) * stepS
	e.cause = "sea" if (int(w[9]) >= 0 and float(w[7]) == WorldWater.SEA_LEVEL) else ("water" if int(w[9]) >= 0 else "table")


## One step of a fill or wave window; true when it is done and should be dropped.
static func stepWindow(S: SimState, w: Array) -> bool:
	if int(w[4]) == 2:
		return _stepWave(S, w)
	var NC: int = SimConst.NC
	var base: PackedFloat32Array = S.base
	var dfm: PackedFloat32Array = WorldTerrain.lowD(S)
	var wat: PackedFloat32Array = S.water
	var lo: int = int(w[0]) - int(w[1])
	var hi: int = int(w[0]) + int(w[1])
	var age: int = int(w[3])
	var start: int = int(w[6])
	var near: float = float(w[7])
	var td: float = float(w[8])
	var nearCol: int = int(w[9])
	var reach: float = K_FRONT * float(age + 1)
	var moved: float = 0.0
	var wetNew: int = 0
	var scorchHit: bool = false
	var pending: bool = false
	var elig := PackedByteArray()   # near water: a column is fed if it is within reach of the source or in an unbroken run of ground below the source's level that is (a dug scar joins the sea to its far end)
	if near != NONE:
		elig.resize(hi - lo + 1)
		var runStart: int = -1
		var runIn: bool = false
		for j in range(lo, hi + 2):
			var below: bool = false
			if j <= hi:
				var ii: int = posmod(j, NC)
				below = base[ii] >= WorldWater.RESERVOIR_BASE and base[ii] + dfm[ii] < near
			if below:
				if runStart < 0:
					runStart = j
					runIn = false
				if absi(WorldWater.colDelta(nearCol, posmod(j, NC))) <= K_REACH and base[posmod(j, NC)] <= near + K_RISE:
					runIn = true
			elif runStart >= 0:
				if runIn:
					for q in range(runStart, j):
						elig[q - lo] = 1
				runStart = -1
	for j in range(lo, hi + 1):
		var i: int = posmod(j, NC)
		if base[i] < WorldWater.RESERVOIR_BASE:
			continue
		var g: float = base[i] + dfm[i]
		var tl: float = NONE
		if near != NONE and elig[j - lo] == 1:
			tl = near
			if float(absi(WorldWater.colDelta(start, i))) > reach:
				pending = true   # the front has not got here yet: the window stays open for it
				continue
		if td != NONE:
			tl = maxf(tl, base[i] - td)
		if tl == NONE or tl <= g:
			continue
		var want: float = tl - g
		var cur: float = wat[i]
		if cur >= want:
			continue
		var add: float = minf(K_RATE, want - cur)
		if cur < WorldWater.MIN_DEPTH and cur + add >= WorldWater.MIN_DEPTH:
			wetNew += 1
			if S.scorch.size() == NC and S.scorch[i] >= K_DOUSE:
				scorchHit = true
		wat[i] = cur + add
		moved += add
	S.water = wat
	w[3] = age + 1
	if scorchHit and int(w[10]) == 0:
		w[10] = 1
		var e := SimFx._ev(S, "water_douse")   # a fill reached a scorched line: the fire goes out (the renderer's steam)
		e.x = (float(w[6]) + 0.5) * SimConst.COL
		e.w = float(w[1]) * 2.0 * SimConst.COL
		e.n = wetNew
	if moved < 0.05 and not pending:
		w[2] = int(w[2]) + 1
	else:
		w[2] = 0
	return int(w[2]) >= K_SETTLE or int(w[3]) >= K_AGEMAX


## A slam of impact energy E at x: if it lands in water standing deep enough, a ring wave pushes whatever is at the surface near it outward (rule of cool: Game Design 23b row 16), over a few steps.
static func slam(S: SimState, x: float, E: float) -> void:
	if not on() or E < K_WAVE_E:
		return
	var NC: int = SimConst.NC
	var c: int = int(floor(SimWrap.wrap(x) / SimConst.COL)) % NC
	var depth: float = S.water[c]
	if depth < K_WAVE_DEPTH:
		return
	for w in S.waterWin:
		if w.size() > 4 and int(w[4]) == 2 and absi(WorldWater.colDelta(c, int(w[0]))) < 4:
			return   # a wave is already running here
	var surface: float = S.base[c] + WorldTerrain.lowD(S)[c] + depth
	S.waterWin.append([c, int(ceil(K_WAVE_R / SimConst.COL)), 0, 0, 2, S.tick, SimWrap.wrap(x), K_WAVE_PUSH, K_WAVE_STEPS, surface, 0])
	var e := SimFx._ev(S, "water_wave")
	e.x = SimWrap.wrap(x)
	e.y = surface
	e.r = K_WAVE_R
	e.amount = K_WAVE_PUSH
	e.n = K_WAVE_STEPS
	e.dur = float(K_WAVE_STEPS) * float(WorldWater.STEP_TICKS) * SimConst.DT
	e.spd = K_WAVE_R / e.dur


static func _stepWave(S: SimState, w: Array) -> bool:
	var left: int = int(w[8])
	var x0: float = float(w[6])
	var surface: float = float(w[9])
	var per: float = float(w[7]) / float(K_WAVE_STEPS)
	for f in S.fighters:
		var dx: float = SimWrap.sdx(x0, f.x)
		if absf(dx) <= K_WAVE_R and absf(f.y - surface) <= K_WAVE_BAND:
			f.x = SimWrap.wrap(f.x + (1.0 if dx >= 0.0 else -1.0) * per)   # outward, a little each step: never a hold or a lift
	w[8] = left - 1
	w[3] = int(w[3]) + 1
	return int(w[8]) <= 0
