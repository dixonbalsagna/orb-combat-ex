class_name WorldAfter
extends RefCounted
## What a signature beam leaves in the ground (docs/world/after.md; data/biomes/after.json, off by default): Combat's nine aftermath kinds and the ocean's parted sea (docs/combat/biomes.md section 2).
## The director calls lay() once a beam has carved its groove, with the row's own aftermath dictionary (World never reads Combat's data or the director's); a kind then works on the groove's columns in the
## variant's own fine biome and nowhere else: the columns the beam scorched (S.scorch above 0) between the path's two ends, padded for the groove's width. Where the beam carved on into the next biome the groove is plain.
##
## The state is S.aftermath (a kind byte a column), S.aftermathT (the waterTick a timed kind ends at, 0 for a kind that stays) and S.aftermathJobs (the timed kinds' work: plain numbers,
## [centre column, half width, 0, age, job kind, start waterTick, z, ...the kind's numbers]); all three are sized only with the switch on and hashed (hash.gd) only when they exist. The clock is S.waterTick, so a hit-stop
## or a cinematic freezes the jobs with the water. With the switch off lay() does nothing, nothing is allocated and the hash is the hash it was.
##
## What each kind leaves, for VFX and Rendering to draw (kindAt, or S.aftermath[column] by the codes below):
##   glaze GLAZE (the strip reads ice for the match; contact's brake takes the ice profile's grip) | clearing CLEARED (no canopy cover; the felled trunks are trunksIn) | heave PLATES (a step of two columns each
##   side, raised in S.deform) | fireLine BURNING while a column burns (aftermathT is when it goes out), then BURNT (look ash); hazardAt is true while it burns | snowDump SNOW while the powder curtain is up
##   (S.deform refilled by `refill`) | flood FLOODED (water stands in S.water) | scree SCREE (a rubble strip: S.rubble, so contact reads surface "rubble") | ember EMBER while it glows (hazardAt; aftermathT is
##   when it cools; look crust), then CRUST (look crust) | split SPLIT (the slot: open water in S.water) | part OPEN while the trench stands, the water_wave cue at the release, then WET on the shore the wave ran up (look only).

const PATH := "res://data/biomes/after.json"
const SCHEMA := "biomes.after/1"

const NONE: int = 0
const GLAZE: int = 1
const CLEARED: int = 2
const PLATES: int = 3
const BURNING: int = 4
const BURNT: int = 5
const EMBER: int = 6
const CRUST: int = 7
const SNOW: int = 8
const FLOODED: int = 9
const SCREE: int = 10
const WET: int = 11
const SPLIT: int = 12
const OPEN: int = 13
const KIND_NAMES: Array = ["", "glaze", "cleared", "plates", "burning", "burnt", "ember", "crust", "snow", "flooded", "scree", "wet", "split", "open"]

const J_FIRE: int = 3     # job kinds in S.aftermathJobs
const J_EMBER: int = 4
const J_SNOW: int = 5
const J_SCREE: int = 6
const J_PART: int = 7
const I_T0: int = 5       # job layout: [c0, half, 0, age, kind, t0, z, ...]
const I_Z: int = 6
const I_P: int = 7        # the first of the kind's numbers
const PAD: int = 48       # columns either side of the path the groove can reach (the widest groove, half width about 42)
const WALL_MARGIN: float = 1.25   # a heave's step is this much steeper than the slide's wall rule asks

static var _d: Dictionary = {}
static var _loaded: bool = false
static var _errors: Array = []
static var K_ON: bool = false
static var K_BH: float = 75.0
static var K_BERM: float = 0.3
static var K_SCREE_HEAP: float = 1.5
static var K_SCREE_TAIL: float = 1.0
static var K_SPLIT_DEPTH: float = 40.0
static var K_WET_TICKS: int = 240
static var K_RUNUP: int = 12
static var K_WAVE_STEPS: int = 6
static var K_BAND: float = 100.0
static var K_GLAZE: String = "sea_ice"


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


static func _load() -> void:
	_loaded = true
	_errors = []
	_d = {}
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return   # no file: the module is off
	var j = JSON.parse_string(f.get_as_text())
	if not (j is Dictionary) or j.get("schema", "") != SCHEMA:
		_errors.append("after.json: not a %s object" % SCHEMA)
		return
	for k in ["enabled", "bh", "berm", "screeHeap", "screeTail", "splitDepth", "wetTicks", "runUpCols", "waveSteps", "band", "glaze"]:
		if not j.has(k):
			_errors.append("after.json: %s is missing" % k)
	if not _errors.is_empty():
		return
	var names: Array = []
	for g in WorldClimate.data().get("fine", []):
		names.append(String(g.name))
	if not names.has(String(j.glaze)):
		_errors.append("after.json: glaze names %s, which climate.json does not have" % String(j.glaze))
	if float(j.bh) < 1.0 or float(j.berm) < 0.0 or float(j.screeHeap) < 1.0 or float(j.screeTail) < 1.0 or float(j.splitDepth) < 1.0 or int(j.wetTicks) < 1 or int(j.runUpCols) < 1 or int(j.waveSteps) < 1 or float(j.band) < 1.0:
		_errors.append("after.json: bh, screeHeap, screeTail, splitDepth, band at least 1, berm at least 0, wetTicks, runUpCols, waveSteps at least 1")
	if not _errors.is_empty():
		return
	_d = j
	K_ON = bool(j.enabled)
	K_BH = float(j.bh)
	K_BERM = float(j.berm)
	K_SCREE_HEAP = float(j.screeHeap)
	K_SCREE_TAIL = float(j.screeTail)
	K_SPLIT_DEPTH = float(j.splitDepth)
	K_WET_TICKS = int(j.wetTicks)
	K_RUNUP = int(j.runUpCols)
	K_WAVE_STEPS = int(j.waveSteps)
	K_BAND = float(j.band)
	K_GLAZE = String(j.glaze)


static func _col(x: float) -> int:
	return int(floor(SimWrap.wrap(x) / SimConst.COL)) % SimConst.NC


## Sizes the state for a match (genWorld and the planet world call it where S.scorch is sized, only with the switch on): the two column arrays to SimConst.NC, clear, and no jobs.
static func size(S: SimState) -> void:
	S.aftermath = PackedByteArray()
	S.aftermath.resize(SimConst.NC)
	S.aftermath.fill(0)
	S.aftermathT = PackedInt32Array()
	S.aftermathT.resize(SimConst.NC)
	S.aftermathT.fill(0)
	S.aftermathJobs = []


static func _ensure(S: SimState) -> void:
	if S.aftermath.size() != SimConst.NC or S.aftermathT.size() != SimConst.NC:
		size(S)


## Sets a column's kind and when it ends (a waterTick; 0 for a kind that stays).
static func _put(S: SimState, i: int, kind: int, until: int = 0) -> void:
	S.aftermath[i] = kind
	S.aftermathT[i] = until


# ===================================================================== queries

## The aftermath kind in the column at x (the codes above), 0 for none or when the module is not sized.
static func kindAt(S: SimState, x: float) -> int:
	if S.aftermath.size() != SimConst.NC:
		return NONE
	return S.aftermath[_col(x)]


static func kindName(k: int) -> String:
	return KIND_NAMES[k] if k >= 0 and k < KIND_NAMES.size() else ""


## True where fire's hazard wear applies: a column of a fire line that is burning and a strip of ember that is glowing. Flying over costs nothing: a caller checks the fighter's height. The wear itself is the
## Wounds system's (living-destruction-numbers.md, hazards at most 15% of a match's wear); this is only where the land is lit.
static func hazardAt(S: SimState, x: float) -> bool:
	var k: int = kindAt(S, x)
	return k == BURNING or k == EMBER


## True where the canopy is gone for the match (clearing): the forest cover finder skips the column.
static func clearedAt(S: SimState, x: float) -> bool:
	return kindAt(S, x) == CLEARED


## The look class a strip reads as (Combat's stripLooks), or "" when the ground's own stands: ice (glaze), ash (burnt grass), crust (a glowing ember strip and the cooled one: the glow is the hazard and the cue),
## water (a flooded groove). Scree reads rubble through the surface (S.rubble), not here.
static func lookAt(S: SimState, x: float) -> String:
	match kindAt(S, x):
		GLAZE:
			return "ice"
		BURNT:
			return "ash"
		EMBER, CRUST:
			return "crust"
		FLOODED:
			return "water"
	return ""


## The contact surface class a strip makes, or "" when the ground's own stands: ice and crust are rock (ground.json: sea_ice and volcanic are rock), as the look classes' "reads as" rows say.
static func surfaceAt(S: SimState, x: float) -> String:
	match kindAt(S, x):
		GLAZE, EMBER, CRUST:
			return "rock"
	return ""


## The grip contact's brake takes on a glazed strip: the ice profile's grip times its roughness (ground.json), in place of the column's own.
static func glazeGrip() -> float:
	if not _loaded:
		_load()
	return WorldGround.profileGrip(K_GLAZE)


## The trunks a clearing left: the felled trees on cleared columns between x0 and x1 (a ricochet can plant on them): [{"x", "h"}].
static func trunksIn(S: SimState, x0: float, x1: float) -> Array:
	var out: Array = []
	if S.aftermath.size() != SimConst.NC:
		return out
	for t in S.trees:
		if t.alive or t.burn > 0.0 or S.aftermath[_col(t.x)] != CLEARED:
			continue
		var d0: float = SimWrap.sdx(x0, t.x)
		var d1: float = SimWrap.sdx(x0, x1)
		if d0 >= minf(0.0, d1) and d0 <= maxf(0.0, d1):
			out.append({"x": t.x, "h": t.h})
	return out


## How many timed jobs are running (0 once everything has settled: the step costs nothing then). A live job does not hold the calm turn back (epoch.calm reads the water's flow windows only); the swap drops the jobs
## whose centre is in ground the new ring replaces and keeps the rest.
static func jobs(S: SimState) -> int:
	return S.aftermathJobs.size()


# ===================================================================== laying

## A beam's aftermath. `a`: the row's aftermath dictionary ({"kind": "glaze" | "split" | "clearing" | "fireLine" | "heave" | "snowDump" | "flood" | "scree" | "ember" | "part", ...its numbers}), `x0`,
## `x1`: where the path began (the firer's side) and ended, `fineId`: the variant's own fine biome (climate.json's F_*; -1 on a world without fine biomes: every scorched column), `z`: the depth row, `defX`: where the
## defender stands (split cuts the floe he stands on at his column; NAN: every floe at its middle). Returns the columns it worked on (0 with the switch off, an unknown kind or no scorched column of the biome on the path).
static func lay(S: SimState, a: Dictionary, x0: float, x1: float, fineId: int, z: float = 0.0, defX: float = NAN) -> int:
	if not on() or not a.has("kind"):
		return 0
	if not S.depthOn:
		return _lay(S, a, x0, x1, fineId, z, defX)
	var k: int = WorldTerrain.enterRow(S, WorldTerrain.rowOfZ(z))
	var n: int = _lay(S, a, x0, x1, fineId, z, defX)
	WorldTerrain.leaveRow(S, k)
	return n


static func _groove(S: SimState, x0: float, x1: float, fineId: int) -> PackedInt32Array:
	var NC: int = SimConst.NC
	var ca: int = _col(x0)
	var cb: int = _col(x1)
	var d: int = WorldWater.colDelta(ca, cb)
	var lo: int = (ca if d >= 0 else cb) - PAD
	var n: int = mini(NC, absi(d) + 1 + 2 * PAD)
	var fc: PackedByteArray = WorldBiomes.fineCols
	var useFine: bool = fineId >= 0 and fc.size() == NC
	var out := PackedInt32Array()
	for k in range(n):
		var i: int = posmod(lo + k, NC)
		if S.scorch[i] <= 0.0:
			continue
		if useFine and int(fc[i]) != fineId:
			continue
		out.append(i)
	return out


static func _lay(S: SimState, a: Dictionary, x0: float, x1: float, fineId: int, z: float, defX: float) -> int:
	var cols: PackedInt32Array = _groove(S, x0, x1, fineId)
	if cols.is_empty():
		return 0
	_ensure(S)
	var NC: int = SimConst.NC
	var cL: int = cols[0]
	var span: int = WorldWater.colDelta(cL, cols[cols.size() - 1]) + 1
	var now: int = int(S.waterTick)
	var done: bool = true
	match String(a.kind):
		"glaze":
			_markAll(S, cols, GLAZE, 0)
		"clearing":
			_clearing(S, cols)
		"heave":
			_heave(S, cols, cL, span, float(a.get("rimMul", 2.0)))
		"split":
			_split(S, cols, float(a.get("gapBh", 1.0)), defX)
		"flood":
			_flood(S, cols, String(a.get("source", "waterTable")), int(a.get("seaCols", 30)))
		"fireLine":
			var reach: int = int(a.get("reachCols", 12))
			var spread: int = maxi(1, int(a.get("spreadTicks", 15)))
			var dur: int = int(a.get("durTicks", 240))
			S.aftermathJobs.append([posmod(cL + span / 2, NC), span / 2 + reach, 0, 0, J_FIRE, now, z, cL, span, reach, spread, dur, fineId])
			_markAll(S, cols, BURNING, now + dur)
		"ember":
			var dur2: int = int(a.get("durTicks", 600))
			S.aftermathJobs.append([posmod(cL + span / 2, NC), span / 2, 0, 0, J_EMBER, now, z, cL, span, dur2])
			_markAll(S, cols, EMBER, now + dur2)
		"snowDump":
			var dur3: int = maxi(1, int(a.get("durTicks", 120)))
			S.aftermathJobs.append([posmod(cL + span / 2, NC), span / 2, 0, 0, J_SNOW, now, z, cL, span, dur3, minf(0.95, float(a.get("refill", 0.4))), 0.0])
			_markAll(S, cols, SNOW, now + dur3)
		"scree":
			done = _scree(S, cols, z, float(a.get("minSlope", 0.25)), int(a.get("reachCols", 10)), maxi(1, int(a.get("durTicks", 180))))
		"part":
			done = _part(S, cols, cL, span, z, a, SimWrap.sdx(x0, x1))
		_:
			return 0
	if not done:
		return 0
	return cols.size()


static func _markAll(S: SimState, cols: PackedInt32Array, k: int, until: int) -> void:
	for i in cols:
		_put(S, i, k, until)


static func _refresh(S: SimState, cL: int, span: int, pad: int = 4) -> void:
	WorldTerrain.lowRefresh(S, posmod(cL + span / 2, SimConst.NC), span / 2 + pad)


# ---- the instant kinds

static func _clearing(S: SimState, cols: PackedInt32Array) -> void:
	var mask := {}
	for i in cols:
		mask[i] = true
	for t in S.trees:
		if t.alive and mask.has(_col(t.x)):
			t.alive = false   # felled: alive false and burn 0, as the beam's own tree damage leaves it; the trunks lie across the cut (trunksIn)
	_markAll(S, cols, CLEARED, 0)


## The groove's rims thrown up as frozen plates: a step, not the berm's slope. Two columns each side at the full height rimMul x 0.3 x the groove's depth, and never a rise under 1.25 x the slide's wall rule
## (WorldSlide.WALL, rise over run) across one column, so a push-back meets a wall (contact's skate and the slide both stop against ground steeper than that). The columns outside the plates are untouched.
static func _heave(S: SimState, cols: PackedInt32Array, cL: int, span: int, rimMul: float) -> void:
	var NC: int = SimConst.NC
	var depth: float = 0.0
	for i in cols:
		depth = maxf(depth, -S.deform[i])
	if depth < 0.5:
		return
	var h: float = maxf(rimMul * K_BERM * depth, WALL_MARGIN * WorldSlide.WALL * SimConst.COL)
	for k in range(2):
		for i in [posmod(cL - 1 - k, NC), posmod(cL + span + k, NC)]:
			S.deform[i] = minf(WorldCrater.DEFORM_CEIL, S.deform[i] + h)
			_put(S, i, PLATES, 0)
	_refresh(S, cL, span + 8)


static func _split(S: SimState, cols: PackedInt32Array, gapBh: float, defX: float) -> void:
	var NC: int = SimConst.NC
	var low: PackedFloat32Array = WorldTerrain.lowD(S)
	var wcols: int = maxi(1, int(round(gapBh * K_BH / SimConst.COL)))
	var run: Array = []   # the floe columns of the groove, in order; a break in the run, or ground that is not above the water, ends a floe
	var floes: Array = []
	for i in cols:
		var above: bool = S.base[i] + low[i] > WorldWater.SEA_LEVEL and S.water[i] < WorldWater.MIN_DEPTH
		if above and (run.is_empty() or posmod(int(i) - int(run[run.size() - 1]), NC) == 1):
			run.append(int(i))
			continue
		if not run.is_empty():
			floes.append(run)
			run = []
		if above:
			run.append(int(i))
	if not run.is_empty():
		floes.append(run)
	var dc: int = -1 if is_nan(defX) else _col(defX)
	for fl in floes:
		var mid: int = int(fl[fl.size() / 2])
		if dc >= 0 and fl.has(dc):
			mid = dc   # the floe he stands on breaks under him
		for q in range(wcols):
			var i2: int = posmod(mid - (wcols - 1) / 2 + q, NC)
			S.deform[i2] = minf(S.deform[i2], -(S.base[i2] + K_SPLIT_DEPTH))
			S.rubble[i2] = 0.0
			S.water[i2] = maxf(S.water[i2], -(S.base[i2] + S.deform[i2]) + WorldWater.SEA_LEVEL)
			_put(S, i2, SPLIT, 0)
	var c0: int = int(cols[0])
	_refresh(S, c0, WorldWater.colDelta(c0, int(cols[cols.size() - 1])) + 1)


static func _level(S: SimState, j: int) -> float:
	if S.base[j] < WorldWater.RESERVOIR_BASE:
		return WorldWater.SEA_LEVEL
	if S.water[j] >= WorldWater.MIN_DEPTH:
		return S.base[j] + WorldTerrain.lowD(S)[j] + S.water[j]
	return WorldFill.NONE


static func _flood(S: SimState, cols: PackedInt32Array, source: String, seaCols: int) -> void:
	var NC: int = SimConst.NC
	var low: PackedFloat32Array = WorldTerrain.lowD(S)
	for i in cols:
		var g: float = S.base[i] + low[i]
		var level: float = WorldFill.NONE
		if source == "sea":
			if g >= WorldWater.SEA_LEVEL:
				continue   # the floor must be below sea level
			for d in range(0, seaCols + 1):   # open water in reach, nearest first
				for sgn in [1, -1]:
					level = _level(S, posmod(int(i) + sgn * d, NC))
					if level != WorldFill.NONE:
						break
				if level != WorldFill.NONE:
					break
		else:
			var td: float = WorldFill.tableDepth(WorldBiomes.fineNameAt((float(i) + 0.5) * SimConst.COL))
			if td != WorldFill.NONE:
				level = S.base[i] - td   # the biome's water table: below the original ground
		if level != WorldFill.NONE and level > g:
			S.water[i] = maxf(S.water[i], level - g)
			_put(S, i, FLOODED, 0)


# ---- the timed kinds

## Rubble runs downhill from the groove's steep columns and stops where the slope flattens below `minSlope`, even short of `reach` columns. The groove's columns steeper than the row's minSlope are the sources;
## beyond them the run goes on only while each next column is still that steep, the same way down. The strip counts as surface rubble (S.rubble), so a slide over it tumbles.
static func _scree(S: SimState, cols: PackedInt32Array, z: float, minSlope: float, reach: int, dur: int) -> bool:
	var NC: int = SimConst.NC
	var up: Array = []     # steep columns whose downhill is +x
	var down: Array = []   # ... and -x
	for i in cols:
		var gr: float = _slope(S, int(i))
		if absf(gr) > minSlope:
			(down if gr > 0.0 else up).append(int(i))
	if up.is_empty() and down.is_empty():
		return false
	WorldContact.data()   # loads contact.json's numbers
	var heap: float = K_SCREE_HEAP * WorldContact.K_RUBBLE_MIN
	var tail: float = K_SCREE_TAIL * WorldContact.K_RUBBLE_MIN
	var now: int = int(S.waterTick)
	if not up.is_empty():   # downhill is +x: the run reads from the lowest index on
		var s0: int = int(up[0])
		var n: int = WorldWater.colDelta(s0, int(up[up.size() - 1])) + 1
		var lim: int = _runLimit(S, s0 + n - 1, 1, minSlope, reach)
		S.aftermathJobs.append([posmod(s0 + n / 2, NC), n / 2 + reach, 0, 0, J_SCREE, now, z, s0, 1, n, reach, dur, heap, tail, lim])
	if not down.is_empty():   # downhill is -x: from the highest index on, going down
		var s1: int = int(down[down.size() - 1])
		var n2: int = WorldWater.colDelta(int(down[0]), s1) + 1
		var lim2: int = _runLimit(S, s1 - n2 + 1, -1, minSlope, reach)
		S.aftermathJobs.append([posmod(s1 - n2 / 2, NC), n2 / 2 + reach, 0, 0, J_SCREE, now, z, s1, -1, n2, reach, dur, heap, tail, lim2])
	return true


## The ground's slope at column i (rise over run, positive when it rises toward +x), on the ground as it stands.
static func _slope(S: SimState, i: int) -> float:
	var NC: int = SimConst.NC
	var low: PackedFloat32Array = WorldTerrain.lowD(S)
	var a: int = posmod(i + 1, NC)
	var b: int = posmod(i - 1, NC)
	return (S.base[a] + low[a] - S.base[b] - low[b]) / (2.0 * SimConst.COL)


## How many columns past the last source (at `last`, going `dir`) the run goes before the slope flattens below minSlope or turns the other way: at most `reach`.
static func _runLimit(S: SimState, last: int, dir: int, minSlope: float, reach: int) -> int:
	var NC: int = SimConst.NC
	for d in range(1, reach + 1):
		var gr: float = _slope(S, posmod(last + dir * d, NC))
		if (gr * float(dir)) > -minSlope:   # downhill toward dir means the ground falls that way: gr x dir below -minSlope
			return d - 1
	return reach


static func _part(S: SimState, cols: PackedInt32Array, cL: int, span: int, z: float, a: Dictionary, dx: float) -> bool:
	var NC: int = SimConst.NC
	var any: bool = false
	for i in cols:
		if S.base[i] < WorldWater.RESERVOIR_BASE:
			any = true
			break
	if not any:
		return false   # the sea is the open ocean's reservoir; shallows and lakes do not part
	var open: int = maxi(1, int(a.get("openTicks", 90)))
	var now: int = int(S.waterTick)
	# the push goes along the beam's line, away from the firer (the path's first end): dir is the sign of x0 to x1
	S.aftermathJobs.append([posmod(cL + span / 2, NC), span / 2 + int(a.get("shoreCols", 40)), 0, 0, J_PART, now, z, cL, span, open, float(a.get("pushBh", 2.0)) * K_BH, int(a.get("shoreCols", 40)), 1 if dx >= 0.0 else -1, 0, 0, 0])
	for q in range(span):
		var i2: int = posmod(cL + q, NC)
		if S.base[i2] < WorldWater.RESERVOIR_BASE:
			_put(S, i2, OPEN, now + open)
	return true


# ===================================================================== stepping

## One tick of the timed jobs (WorldWater.step calls it after the water's clock has moved; it costs nothing when no job runs).
static func step(S: SimState) -> void:
	var q: int = 0
	while q < S.aftermathJobs.size():
		if _stepJob(S, S.aftermathJobs[q]):
			S.aftermathJobs.remove_at(q)
		else:
			q += 1


## One tick of a job; true when it is done and should be dropped.
static func _stepJob(S: SimState, w: Array) -> bool:
	var k: int = -1
	if S.depthOn:
		k = WorldTerrain.enterRow(S, WorldTerrain.rowOfZ(float(w[I_Z])))
	var done: bool = false
	match int(w[4]):
		J_FIRE:
			done = _stepFire(S, w)
		J_EMBER:
			done = _stepEmber(S, w)
		J_SNOW:
			done = _stepSnow(S, w)
		J_SCREE:
			done = _stepScree(S, w)
		J_PART:
			done = _stepPart(S, w)
		_:
			done = true
	w[3] = int(w[3]) + 1
	if S.depthOn:
		WorldTerrain.leaveRow(S, k)
	return done


static func _clock(S: SimState, w: Array) -> int:
	return int(S.waterTick) - int(w[I_T0])


static func _stepFire(S: SimState, w: Array) -> bool:
	var NC: int = SimConst.NC
	var clock: int = _clock(S, w)
	var cL: int = int(w[I_P])
	var span: int = int(w[I_P + 1])
	var reach: int = int(w[I_P + 2])
	var spread: int = int(w[I_P + 3])
	var dur: int = int(w[I_P + 4])
	var fid: int = int(w[I_P + 5])
	var fc: PackedByteArray = WorldBiomes.fineCols
	var useFine: bool = fid >= 0 and fc.size() == NC
	var front: int = mini(reach, clock / spread)
	var t0w: int = int(w[I_T0])
	for k in range(-reach, span + reach):
		var d: int = -k if k < 0 else (k - span + 1 if k >= span else 0)
		if d > front:
			continue
		var i: int = posmod(cL + k, NC)
		if useFine and int(fc[i]) != fid:
			continue   # grass of the variant's own biome only
		if d > 0 and S.water[i] >= WorldWater.MIN_DEPTH:
			continue   # fire does not run over water
		var cur: int = S.aftermath[i]
		if cur != NONE and cur != BURNING and cur != BURNT:
			continue
		var ti: int = d * spread
		if clock >= ti + dur:
			if cur != BURNT:
				_put(S, i, BURNT, 0)
		elif clock >= ti and cur != BURNING:
			_put(S, i, BURNING, t0w + ti + dur)
	return clock >= reach * spread + dur


static func _stepEmber(S: SimState, w: Array) -> bool:
	if _clock(S, w) < int(w[I_P + 2]):
		return false
	var NC: int = SimConst.NC
	var cL: int = int(w[I_P])
	for q in range(int(w[I_P + 1])):
		var i: int = posmod(cL + q, NC)
		if S.aftermath[i] == EMBER:
			_put(S, i, CRUST, 0)
	return true


static func _stepSnow(S: SimState, w: Array) -> bool:
	var NC: int = SimConst.NC
	var clock: int = _clock(S, w)
	var cL: int = int(w[I_P])
	var span: int = int(w[I_P + 1])
	var dur: int = int(w[I_P + 2])
	var refill: float = float(w[I_P + 3])
	var f0: float = float(w[I_P + 4])
	var f1: float = refill * minf(1.0, float(clock) / float(dur))
	if f1 > f0:
		var r: float = (1.0 - f1) / (1.0 - f0)   # the groove's remaining depth, from the share already refilled to the share now
		for q in range(span):
			var i: int = posmod(cL + q, NC)
			if S.aftermath[i] == SNOW and S.deform[i] < 0.0:
				S.deform[i] = S.deform[i] * r
		w[I_P + 4] = f1
		_refresh(S, cL, span)
	if clock < dur:
		return false
	for q2 in range(span):
		var i2: int = posmod(cL + q2, NC)
		if S.aftermath[i2] == SNOW:
			_put(S, i2, NONE, 0)
	return true


static func _stepScree(S: SimState, w: Array) -> bool:
	var NC: int = SimConst.NC
	var clock: int = _clock(S, w)
	var s0: int = int(w[I_P])
	var dir: int = int(w[I_P + 1])
	var n: int = int(w[I_P + 2])
	var reach: int = int(w[I_P + 3])
	var dur: int = int(w[I_P + 4])
	var heap: float = float(w[I_P + 5])
	var tail: float = float(w[I_P + 6])
	var lim: int = int(w[I_P + 7])
	var front: int = mini(lim, (clock * reach) / dur)
	for j in range(n + front):
		var i: int = posmod(s0 + dir * j, NC)
		var dist: int = maxi(0, j - n + 1)
		var want: float = heap + (tail - heap) * float(dist) / float(reach)
		if S.rubble[i] < want:
			var add: float = want - S.rubble[i]
			S.rubble[i] = want
			S.deform[i] = minf(WorldCrater.DEFORM_CEIL, S.deform[i] + add)
		_put(S, i, SCREE, 0)
	_refresh(S, posmod(s0 + dir * (n / 2), NC), n + front)
	return clock >= dur


static func _stepPart(S: SimState, w: Array) -> bool:
	var NC: int = SimConst.NC
	var COL: float = SimConst.COL
	var clock: int = _clock(S, w)
	var cL: int = int(w[I_P])
	var span: int = int(w[I_P + 1])
	var open: int = int(w[I_P + 2])
	var push: float = float(w[I_P + 3])
	var shore: int = int(w[I_P + 4])
	var dir: int = int(w[I_P + 5])
	var phase: int = int(w[I_P + 6])
	if phase == 0:
		if clock < open:   # the trench stands: the sea's columns on the path held at no water
			for q in range(span):
				var i: int = posmod(cL + q, NC)
				if S.base[i] < WorldWater.RESERVOIR_BASE:
					S.water[i] = 0.0
			return false
		for q1 in range(span):   # the sea rushes back: the water model refills its reservoir columns, and the wave runs
			var iq: int = posmod(cL + q1, NC)
			if S.aftermath[iq] == OPEN:
				_put(S, iq, NONE, 0)
		var minG: float = 1.0e9
		var low: PackedFloat32Array = WorldTerrain.lowD(S)
		for q2 in range(span):
			var i2: int = posmod(cL + q2, NC)
			minG = minf(minG, S.base[i2] + low[i2])
		WorldWater.touched(S, posmod(cL + span / 2, NC), span / 2 + 4, minG)
		var e := SimFx._ev(S, "water_wave")
		e.x = SimWrap.wrap((float(cL) + float(span) * 0.5) * COL)
		e.y = WorldWater.SEA_LEVEL
		e.r = float(span) * 0.5 * COL
		e.amount = push
		e.n = K_WAVE_STEPS
		e.dur = float(K_WAVE_STEPS) * float(WorldWater.STEP_TICKS) * SimConst.DT
		e.spd = float(e.r) / maxf(e.dur, 0.001)
		w[I_P + 6] = 1
		w[I_P + 7] = K_WAVE_STEPS * WorldWater.STEP_TICKS
		return false
	if phase == 1:   # the wave: whatever is at the surface along the beam's line is pushed a little each tick, away from the firer, never held or lifted
		var left: int = int(w[I_P + 7])
		var xm: float = (float(cL) + float(span) * 0.5) * COL
		var half: float = float(span) * 0.5 * COL + K_BH
		var per: float = push / float(K_WAVE_STEPS * WorldWater.STEP_TICKS)
		for f in S.fighters:
			if absf(SimWrap.sdx(xm, f.x)) <= half and absf(f.y - WorldWater.SEA_LEVEL) <= K_BAND:
				f.x = SimWrap.wrap(f.x + float(dir) * per)
		w[I_P + 7] = left - 1
		if left - 1 > 0:
			return false
		var wetEnd: int = int(S.waterTick) + K_WET_TICKS
		_runUp(S, cL, span, shore, wetEnd)
		w[I_P + 6] = 2
		w[I_P + 8] = wetEnd
		return false
	if int(S.waterTick) < int(w[I_P + 8]):   # phase 2: the shore stays wet for a while
		return false
	for d3 in range(-(shore + K_RUNUP), span + shore + K_RUNUP + 1):
		var i3: int = posmod(cL + d3, NC)
		if S.aftermath[i3] == WET:
			_put(S, i3, NONE, 0)
	return true


## Where the wave's line meets land within `shore` columns of the trench's two ends it runs up the shore: the first K_RUNUP land columns inland read wet (a look, and props knocked over: no water rules).
static func _runUp(S: SimState, cL: int, span: int, shore: int, wetEnd: int) -> void:
	var NC: int = SimConst.NC
	for side in [-1, 1]:
		var start: int = (cL - 1) if side < 0 else (cL + span)
		var hit: int = -1
		for d in range(0, shore):
			var i: int = posmod(start + side * d, NC)
			if S.base[i] >= WorldWater.RESERVOIR_BASE and S.water[i] < WorldWater.MIN_DEPTH:
				hit = d
				break
		if hit < 0:
			continue
		for d in range(hit, mini(shore, hit + K_RUNUP)):
			var j: int = posmod(start + side * d, NC)
			if S.water[j] < WorldWater.MIN_DEPTH and S.aftermath[j] == NONE:
				_put(S, j, WET, wetEnd)
