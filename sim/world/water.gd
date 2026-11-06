class_name WorldWater
## A one-dimensional water model over the terrain columns. GDScript only.
##
## S.water holds the water depth of every column, so the surface is ground + depth, and the surface of standing water
## is sea level. The sea is a reservoir: a column whose original ground is below RESERVOIR_BASE (the prototype's sea
## rule, seaAt) is always full to sea level, and its depth follows the ground when a crater digs the sea floor. Every
## other column is dynamic. Water gets into a dynamic column only by flowing from a wet neighbour, and only if the
## column's ground is below WET_GROUND (the same -30 the sea rule uses, so a shore looks as it always did). So a hole
## fills only when an unbroken run of ground below WET_GROUND connects it to the sea: an inland crater stays dry
## however deep, and a bay dug at the coast fills. That is the whole "no flooding inland" argument;
## docs/world/craters-scorch-water.md has the proof and the test.
##
## Flow is a saturated two-column exchange, computed from the old state and applied afterwards (order-free). It runs
## only in windows around terrain that was just changed below sea level, every WATER_STEP_TICKS unfrozen ticks, and a
## window closes once it has settled. Nothing here draws a random number.

const SEA_LEVEL: float = 0.0
const WS: float = SimConst.WS
const RESERVOIR_BASE: float = -30.0 * WS   # base ground below this is open sea (WorldTerrain.seaAt)
## The sea fills every sea-connected column whose ground is below SHORE_WET (a quarter of a fighter height under sea
## level), so the waterline sits on the shore and no slab of dry land below sea level stands beside the sea
## (docs/world/cities.md, the waterline). WET_GROUND is the same number under its old name.
const SHORE_WET: float = -0.25 * 75.0
const WET_GROUND: float = SHORE_WET
const MIN_DEPTH: float = 0.5 * WS     # less than this counts as dry
const FLOW_K: float = 0.4             # a link moves this share of the surface difference per step ...
const FLOW_MAX: float = 14.0 * WS          # ... at most this much depth per step ...
const FLOW_MIN: float = 0.25 * WS          # ... at least this much (or half the difference, if smaller), so the tail is not endless ...
const DONOR_SHARE: float = 0.5        # ... and at most this share of the donor column's water
const FLOW_EPS: float = 0.05 * WS          # surface differences below this do not flow
const STEP_TICKS: int = 2             # a flow step every this many unfrozen ticks
const PAD_COLS: int = 6               # a window extends this far past the changed columns
const SETTLE_EPS: float = 0.05 * WS        # a step that moves less than this in total counts as quiet
const SETTLE_STEPS: int = 3           # a window closes after this many quiet steps in a row
const MAX_AGE_STEPS: int = 900        # ... or after this many steps whatever happens (a bound on the cost)
const MAX_WINDOWS: int = 8            # more than this and the oldest window is dropped
const MAX_HALF: int = 240             # widest a window may grow (columns each side of its centre)
const MAX_WARM_STEPS: int = 16        # flowWarm: the most steps a new window waits before its water moves, however far merges widen it
## Submerged hiding (cover.gd): 60 units under the surface, in water at least 100 deep. The prototype's rule for the sea.
const HIDE_BELOW_SURFACE: float = 60.0
const HIDE_MIN_DEPTH: float = 100.0
const DRY: float = -1e9               # surfaceAt() of a dry column
## Launched fighters skim: a descent shallower than SKIM_MAX_TAN (rise over run), faster than SKIM_MIN_SPEED, skips off
## the surface with vy reversed and scaled by SKIM_LIFT and vx scaled by SKIM_KEEP, up to SKIM_MAX times in a flight
## (docs/world/knockback-slide.md section 5). Fighter-scale, so not multiplied by WS.
const SKIM_MIN_SPEED: float = 500.0
const SKIM_MAX_TAN: float = 0.6
const SKIM_LIFT: float = 0.65
const SKIM_KEEP: float = 0.85
const SKIM_MAX: float = 6.0


static func isReservoir(S: SimState, i: int) -> bool:
	return WorldTerrain.baseAt(S, i) < RESERVOIR_BASE


## Depth of the water at x (the column it falls in), 0 when dry.
static func depthAt(S: SimState, x: float) -> float:
	var d: float = depthOf(S, int(floor(SimWrap.wrap(x) / SimConst.COL)))
	return d if d >= MIN_DEPTH else 0.0


## The water at a column: S.water, and on a field world the sea and World's lake and river records through the line as well (S.water then holds only what a fight made: a swing moves the world's water under it).
static func depthOf(S: SimState, i: int) -> float:
	if S.frame == null:
		return S.water[i]
	return maxf(S.water[i], SimField.nativeDepth(S, i, WorldTerrain.lowD(S)[i]))


## Height of the water surface at x, or DRY.
static func surfaceAt(S: SimState, x: float) -> float:
	var i: int = int(floor(SimWrap.wrap(x) / SimConst.COL))
	var d: float = depthOf(S, i)
	return WorldTerrain.baseAt(S, i) + WorldTerrain.lowD(S)[i] + d if d >= MIN_DEPTH else DRY


const NO_SEA: float = -1.0e18   # seaTop where there is no sea-like water: nothing is below it


## The depth at which a lake is sea to every rule that asks (seaAt, seaTop): HIDE_MIN_DEPTH, hiding's leftover; with the floor on, the one line for a lake, wade.below (Game Design rulings 2026-10-30 row 4).
static func seaMin() -> float:
	return WorldFill.wadeBelow() if WorldFill.floorOn() else HIDE_MIN_DEPTH


## Does a column of at least seaMin() deep water count as sea to the rules that ask? On a gen 2 world always (its lakes, and the shore slope of its sea); with the floor on, in every world, so that the sheet a fighter
## stands on in the hand-made world's shore slope is the surface those rules ask about (Game Design rulings 2026-10-30 row 7: one switch, every world). Off, a gen 1 and the hand-made world are as they were.
static func deepIsSea() -> bool:
	return WorldFill.floorOn() or WorldGround.live()


## The surface the sea's rules measure from at x: the sea level over the sea, a gen 2 lake deep enough to hide in: its own surface (Game Design 23b row 13: lakes follow the sea's rules), and NO_SEA where there
## is neither. On any world without a lake it is 0 over the sea and NO_SEA elsewhere, which is `y < 0 and seaAt` as the rules were written.
static func seaTop(S: SimState, x: float) -> float:
	var i: int = int(floor(SimWrap.wrap(x) / SimConst.COL)) % SimConst.NC
	if WorldTerrain.baseAt(S, i) < RESERVOIR_BASE:
		return SEA_LEVEL
	if depthOf(S, i) >= seaMin() and deepIsSea():
		return WorldTerrain.baseAt(S, i) + WorldTerrain.lowD(S)[i] + depthOf(S, i)
	return NO_SEA


const NO_LEVEL: float = -1.0e9   # nativeLevel where the column's water is not the ring's own
const SHEET_SNAP: float = 0.001  # on the sheet the floor is seaTop's value to the bit when the interpolated level is within this of it (float32 columns of one flat lake differ by a few 1e-4)


## The ring's own water at column i, as a level: ground plus depth, where the column is the sea or its shallows (the original ground under SHORE_WET) or a planned lake or river, and stands at least MIN_DEPTH.
## NO_LEVEL for dry ground, and for water a fight dug (a fill, a flow into a hole): the floor never lifts or holds a fighter in that (rulings 2026-10-30 row 5).
static func nativeLevel(S: SimState, i: int) -> float:
	if S.frame != null:   # a field world: its own water is the sea and the records, never a fight's
		var low: float = WorldTerrain.lowD(S)[i]
		var nd: float = SimField.nativeDepth(S, i, low)
		return WorldTerrain.baseAt(S, i) + low + nd if nd >= MIN_DEPTH else NO_LEVEL
	var d: float = S.water[i]
	if d < MIN_DEPTH:
		return NO_LEVEL
	if WorldTerrain.baseAt(S, i) >= SHORE_WET:
		var lakes: Array = S.planetRing.get("lakes", [])
		if lakes.is_empty() or not WorldLakes.inLake(lakes, i, SimConst.NC):
			return NO_LEVEL
	return WorldTerrain.baseAt(S, i) + WorldTerrain.lowD(S)[i] + d


## The ring's own water level at x (the two nearest columns' levels, a dry one counting as its ground, so it is continuous), or NO_LEVEL where there is none.
static func floorLevel(S: SimState, x: float) -> float:
	var NC: int = SimConst.NC
	var c: float = SimWrap.wrap(x) / SimConst.COL
	var fi: float = floor(c)
	var i: int = int(fi) % NC
	var j: int = (i + 1) % NC
	var li: float = nativeLevel(S, i)
	var lj: float = nativeLevel(S, j)
	if li == NO_LEVEL and lj == NO_LEVEL:
		return NO_LEVEL
	var low: PackedFloat32Array = WorldTerrain.lowD(S)
	if li == NO_LEVEL:
		li = WorldTerrain.baseAt(S, i) + low[i]
	if lj == NO_LEVEL:
		lj = WorldTerrain.baseAt(S, j) + low[j]
	return li + (lj - li) * (c - fi)


## The ring's original ground at x (the two nearest columns' base): what the floor measures depth from, so a crater a fight dug in a lake's bed is not water he can stand in or fall through (the lake refills level over the hole).
static func undugAt(S: SimState, x: float) -> float:
	var c: float = SimWrap.wrap(x) / SimConst.COL
	var fi: float = floor(c)
	var i: int = int(fi) % SimConst.NC
	var j: int = (i + 1) % SimConst.NC
	return WorldTerrain.baseAt(S, i) + (WorldTerrain.baseAt(S, j) - WorldTerrain.baseAt(S, i)) * (c - fi)


## The depth of the ring's own water at x, from the undug bed: its level there less the original ground. 0 where there is none. (z: kept for the callers that name a depth; the original ground is the same on every row.)
static func floorDepth(S: SimState, x: float, z: float = 0.0) -> float:
	var L: float = floorLevel(S, x)
	if L == NO_LEVEL:
		return 0.0
	return maxf(0.0, L - undugAt(S, x))


## How much of a fighter is under the water he stands in: all of him to half of wade.below, then less as the bottom falls away, none from wade.below down (rulings 2026-10-30 row 1: one curve, no step).
static func feet(d: float) -> float:
	return maxf(0.0, minf(d, WorldFill.wadeBelow() - d))


## The most a waded body under his floor rises in a tick: wade.below over the surfacing's riseTicks (Encounter's interrupts.json water.riseTicks, read through SimDir.waterRiseTicks), the surfacing's own rate over its
## full depth; so the deepest lift (to the sheet from the bed at wade.below) takes riseTicks ticks (Game Design rulings 2026-10-30 row 9).
static func riseMax(riseTicks: int) -> float:
	return WorldFill.wadeBelow() / float(maxi(1, riseTicks))


## Can a burial start at x? With the floor on it needs water under half of wade.below at his column, measured from the undug bed (Game Design rulings 2026-10-30 row 11: on the bed, not on the sheet): deeper, no embed (an ordinary one or a MARSH SWALLOW's) and no follow-up; an impact there still digs the bed and he comes up by the surfacing. Always true with the floor off.
static func burialOK(S: SimState, x: float) -> bool:
	return not WorldFill.floorOn() or floorDepth(S, x) < WorldFill.wadeBelow() * 0.5


## The floor of a fighter under his own control at x, depth z: the ground, and in the ring's own water its surface less his feet. With the floor off, exactly the ground. On the sheet it is seaTop's value to the bit, so a fighter on
## it is never "below" the surface that rules ask (y < seaTop) by the rounding of a float32 column.
static func floorAt(S: SimState, x: float, z: float = 0.0) -> float:
	var g: float = WorldTerrain.groundY(S, x, z)
	if not WorldFill.floorOn():
		return g
	var L: float = floorLevel(S, x)
	if L == NO_LEVEL:
		return g
	var u: float = undugAt(S, x)   # depth from the undug bed (rulings 2026-10-30 row 5's rule for fills, for a crater a fight dug in a lake); never under the actual ground: a berm lifts the floor
	if L <= u:
		return g
	var d: float = L - u
	var fe: float = feet(d)
	if fe >= d:
		return maxf(g, u)
	if fe <= 0.0:
		var top: float = seaTop(S, x)
		return maxf(g, top if top != NO_SEA and absf(top - L) < SHEET_SNAP else L)
	return maxf(g, L - fe)


## Start of a match: reservoir columns full to sea level, and the shallows connected to them (an unbroken run of ground
## below SHORE_WET) full to the same level; nothing else is wet, and only craters make new water.
static func init(S: SimState) -> void:
	var NC: int = SimConst.NC
	S.water = PackedFloat32Array()
	S.water.resize(NC)
	S.water.fill(0.0)
	S.waterWin.clear()
	S.waterTick = 0.0
	var base: PackedFloat32Array = S.base
	var low: PackedFloat32Array = WorldTerrain.lowD(S)
	var any: bool = false
	if S.frame != null:   # a field world: the sea is read from the ground (depthOf); only a fight's water is kept
		return
	for i in range(NC):
		if WorldTerrain.baseAt(S, i) < RESERVOIR_BASE:
			any = true
			S.water[i] = maxf(0.0, SEA_LEVEL - (WorldTerrain.baseAt(S, i) + low[i]))
	if not any:
		return   # no sea on this ring: nothing for the laps to carry
	for dir in [1, -1]:
		var wet: bool = false
		for lap in range(2 * NC):   # two laps carry the fill across the seam
			var i2: int = lap % NC if dir == 1 else NC - 1 - (lap % NC)
			if WorldTerrain.baseAt(S, i2) < RESERVOIR_BASE:
				wet = true
			elif wet:
				var g: float = WorldTerrain.baseAt(S, i2) + low[i2]
				if g < SHORE_WET:
					S.water[i2] = SEA_LEVEL - g
				else:
					wet = false


## The columns a new flow window reads a step before any water moves in it (data/biomes/water.json flowWarm.cols; 0, the default, is today: the window's whole span is read in its first step, 300 to 420 cold ground reads,
## 19 to 27 ms on Orb's replay). With it on, a new window starts at a negative age: each step it reads `cols` more of its span (WorldTerrain.baseAt, which only warms the ground memo and changes no state) and no water moves
## until the whole span is read, so the first flow starts ceil(span / cols) steps later (2 ticks a step) and no tick reads more than `cols` columns. docs/world/water-window-warm.md.
static func warmCols() -> int:
	var w: Variant = WorldFill.data().get("flowWarm", {})
	return int(w.get("cols", 0)) if w is Dictionary else 0


## Terrain changed around column c0 (half width cols) and the lowest ground there is minG: keep the reservoir
## columns full, and open a flow window if any of it is below sea level.
static func touched(S: SimState, c0: int, cols: int, minG: float) -> void:
	var NC: int = SimConst.NC
	var base: PackedFloat32Array = S.base
	var dfm: PackedFloat32Array = WorldTerrain.lowD(S)
	# each column's ground is read once here, not once a loop (a scorch calls this every beam sample: hundreds of ground reads a call, a quarter of a millisecond a loop): the span of the first loops, then (only if the
	# window is wanted, below) the rest of the widest span
	var hw: int = mini(MAX_HALF, cols + PAD_COLS)
	var wide: int = maxi(cols, hw)
	var bs := PackedFloat64Array()
	bs.resize(2 * wide + 1)
	for k in range(-cols, cols + 1):
		bs[k + wide] = WorldTerrain.baseAt(S, (c0 + k + NC) % NC)
	if S.depthOn:   # the lowest ground over all the rows, in the window
		for k in range(-cols, cols + 1):
			var ic: int = (c0 + k + NC) % NC
			minG = minf(minG, bs[k + wide] + dfm[ic])
	for k in range(-cols, cols + 1):
		var i: int = (c0 + k + NC) % NC
		if bs[k + wide] < RESERVOIR_BASE:
			S.water[i] = maxf(0.0, SEA_LEVEL - (bs[k + wide] + dfm[i]))
	if not S.planetRing.is_empty():
		WorldLakes.refill(S, c0, cols)   # a gen 2 ring's lakes stand flat when their bed is dug
	if WorldFill.on():
		WorldFill.open(S, c0, cols)   # water v2: a hole dug where water would come fills (its own windows)
	if minG >= WET_GROUND:
		return
	# Water can only spread from water, and only into a dynamic column that is low enough: worth a window only if the
	# reach holds both some water and some such column.
	for k in range(-wide, -cols):
		bs[k + wide] = WorldTerrain.baseAt(S, (c0 + k + NC) % NC)
	for k in range(cols + 1, wide + 1):
		bs[k + wide] = WorldTerrain.baseAt(S, (c0 + k + NC) % NC)
	var near: bool = false
	var hole: bool = false
	for k in range(-hw, hw + 1):
		var i2: int = (c0 + k + NC) % NC
		if S.water[i2] >= MIN_DEPTH:
			near = true
		if bs[k + wide] >= RESERVOIR_BASE and bs[k + wide] + dfm[i2] < WET_GROUND:
			hole = true
	if not (near and hole):
		return
	for w in S.waterWin:
		if w.size() > 4:
			continue   # a fill or wave window (WorldFill) is not a flow window
		var dc: int = absi(colDelta(c0, w[0]))
		if dc <= w[1] + hw:
			var w1_old: int = w[1]
			w[1] = mini(MAX_HALF, maxi(w[1], dc + hw))
			var wcm: int = warmCols()
			if wcm > 0 and int(w[3]) < 0 and w[1] > w1_old:   # flowWarm: a window still warming that a merge widens reads the new columns too (the steps it still owes grow by what they need, to at most MAX_WARM_STEPS)
				w[3] = maxi(int(w[3]) - (2 * (int(w[1]) - w1_old) + wcm - 1) / wcm, -MAX_WARM_STEPS)
			w[2] = 0
			return
	var wc: int = warmCols()
	S.waterWin.append([c0, hw, 0, -((2 * hw + wc) / wc) if wc > 0 else 0])   # flowWarm: a negative age is the steps left to read the span (the span, 2 hw + 1, over wc, rounded up)
	if S.waterWin.size() > MAX_WINDOWS:
		S.waterWin.remove_at(0)


## Shortest signed column distance on the wrapped ring.
static func colDelta(a: int, b: int) -> int:
	var NC: int = SimConst.NC
	var d: int = posmod(b - a, NC)
	return d - NC if d * 2 > NC else d


## One tick of the water model. Call it once per unfrozen tick.
static func step(S: SimState) -> void:
	S.waterTick += 1.0
	if S.aftermathJobs.size() > 0:
		WorldAfter.step(S)   # a beam's aftermath (after.gd): its timed jobs, every unfrozen tick
	if WorldFire.on():   # window 18: the burning trees, a tick (nothing runs when none burns)
		WorldFire.step(S)
	if S.frame != null and (SimSwing.waterHeld(S) or (warmCols() > 0 and S.swing != null and S.swing.active)):   # flowWarm: the line is turning, or paused with its strip just re-posed: every ground read of a window is cold (a swing's first tick read 1,067 columns, 21 to 31 ms), so the water waits for the swing to end and for its own warm
		return
	if S.waterWin.is_empty() or int(S.waterTick) % STEP_TICKS != 0:
		return
	var NC: int = SimConst.NC
	var base: PackedFloat32Array = S.base
	var dfm: PackedFloat32Array = WorldTerrain.lowD(S)
	var wat: PackedFloat32Array = S.water
	var wc: int = maxi(warmCols(), 1)
	var wi: int = 0
	while wi < S.waterWin.size():
		var w: Array = S.waterWin[wi]
		if w.size() > 4:
			if WorldFill.stepWindow(S, w):
				S.waterWin.remove_at(wi)
			else:
				wi += 1
			continue
		if int(w[3]) < 0:   # flowWarm: the span is read a chunk a step first, and no water moves in this window until it is read
			_warmChunk(S, w, wc)
			w[3] += 1
			wi += 1
			continue
		var lo: int = w[0] - w[1]
		var hi: int = w[0] + w[1]
		var flux := PackedFloat32Array()
		flux.resize(hi - lo + 1)   # flux[j - lo]: depth moving from column j to column j + 1 (negative: the other way)
		var bs := PackedFloat64Array()   # each column's base, read once: on a field world a read walks the line
		bs.resize(hi - lo + 1)
		for j in range(lo, hi + 1):
			bs[j - lo] = WorldTerrain.baseAt(S, posmod(j, NC))
		var b: int = posmod(lo, NC)
		var gb: float = bs[0] + dfm[b]
		var rb: bool = bs[0] < RESERVOIR_BASE
		var sb: float = SEA_LEVEL if rb and gb < SEA_LEVEL else gb + wat[b]
		for j in range(lo, hi):
			var a: int = b
			var ga: float = gb
			var ra: bool = rb
			var sa: float = sb
			b = posmod(j + 1, NC)
			gb = bs[j + 1 - lo] + dfm[b]
			rb = bs[j + 1 - lo] < RESERVOIR_BASE
			sb = SEA_LEVEL if rb and gb < SEA_LEVEL else gb + wat[b]
			if ra and rb:
				continue
			var diff: float = sa - sb
			if absf(diff) < FLOW_EPS:
				continue
			var ad: float = absf(diff)
			var f: float = clampf(FLOW_K * ad, minf(FLOW_MIN, 0.5 * ad), FLOW_MAX)
			if diff > 0.0:   # a to b
				if not ra:
					f = minf(f, DONOR_SHARE * wat[a])
				if not rb and gb >= WET_GROUND:
					f = 0.0
				flux[j - lo] = f
			else:            # b to a
				if not rb:
					f = minf(f, DONOR_SHARE * wat[b])
				if not ra and ga >= WET_GROUND:
					f = 0.0
				flux[j - lo] = -f
		var moved: float = 0.0
		for j in range(lo, hi + 1):
			var i: int = posmod(j, NC)
			if bs[j - lo] < RESERVOIR_BASE:
				continue
			var inflow: float = 0.0
			if j > lo:
				inflow += flux[j - 1 - lo]
			if j < hi:
				inflow -= flux[j - lo]
			if inflow != 0.0:
				wat[i] = maxf(0.0, wat[i] + inflow)
				moved += absf(inflow)
		S.water = wat
		w[3] += 1
		w[2] = w[2] + 1 if moved < SETTLE_EPS else 0
		if w[1] < MAX_HALF and (wat[posmod(lo, NC)] >= MIN_DEPTH or wat[posmod(hi, NC)] >= MIN_DEPTH):
			w[1] = mini(MAX_HALF, w[1] + PAD_COLS)   # the front reached the edge: follow it
		if w[2] >= SETTLE_STEPS or w[3] >= MAX_AGE_STEPS:
			S.waterWin.remove_at(wi)
		else:
			wi += 1


## One step of a warming window (flowWarm): read the next `wc` columns of its span. Which columns are read never changes a result (a ground read is a pure function that only fills the memo), only when the window's flow
## starts, which the age sets. The chunk is the one the steps left leave: the first step reads the first.
static func _warmChunk(S: SimState, w: Array, wc: int) -> void:
	var NC: int = SimConst.NC
	var span: int = 2 * int(w[1]) + 1
	var chunks: int = (span + wc - 1) / wc
	var idx: int = clampi(chunks + int(w[3]), 0, chunks - 1)   # w[3] is minus the steps left: the last step reads the last chunk
	var lo: int = int(w[0]) - int(w[1]) + idx * wc
	var hi: int = mini(lo + wc, int(w[0]) + int(w[1]) + 1)
	for j in range(lo, hi):
		WorldTerrain.baseAt(S, posmod(j, NC))
