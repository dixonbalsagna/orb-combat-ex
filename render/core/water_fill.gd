class_name RenderWaterFill
extends RefCounted
## The water window (Orb, 2026-10-23: water should visibly rush into holes, trenches and beam bores, as rule of cool
## and not fluid simulation, costing nothing worth measuring; docs/rendering/water-fill.md). World's fill
## (sim/world/fill.gd, docs/world/water-v2.md) tops a new hole's columns up toward a level behind a front, and says so
## with a cue: water_fill (where the front starts, the surface it heads for, its speed) and water_wave (a slam into
## standing water). S.water stays the truth: the surface stands where the sim has it. This is the drama on top, in
## the water shader from the uniforms here:
## - a crest runs with the front along the hole and is lifted over the water filling behind it;
## - it piles up where it meets the hole's far wall, or another front coming the other way;
## - the pile falls back as a slosh along the pool that settles;
## - a wave's ring runs out over the surface and narrows to nothing.
## Render only. A cue's arrival reads its own run of columns once; per frame nothing changes until a cue comes or goes.

const FILLS: int = 4   # World's maxWindows: at most this many fills at once (the shader's arrays)
const WAVES: int = 2   # rings at once (a wave runs a fifth of a second; two is plenty)

var fills: Array = []   # [x, y, spd, t0, sL, dL, sR, dR, crest, slosh, until]
var waves: Array = []   # [x, y, t0, r, lift, run, until]
var version: int = 0    # bumps when the live set changes: a pane sends its uniforms again


## A new world: no fills or rings.
func clear() -> void:
	if not fills.is_empty() or not waves.is_empty():
		fills.clear()
		waves.clear()
		version += 1


## This tick's water cues, at sim time T, on the ground in S (read only).
func take(S: SimState, e, T: float) -> void:
	if String(e.type) == "water_fill":
		_fill(S, e, T)
	elif String(e.type) == "water_wave":
		_wave(e, T)


## Drop what has run its course by sim time T.
func expire(T: float) -> void:
	var n: int = fills.size() + waves.size()
	fills = fills.filter(func(f): return T < float(f[10]) and T >= float(f[3]) - 1.0)
	waves = waves.filter(func(w): return T < float(w[6]) and T >= float(w[2]) - 1.0)
	if fills.size() + waves.size() != n:
		version += 1


## The live fills and rings on a water material (water.gdshader).
func apply(m: ShaderMaterial) -> void:
	var a := PackedVector4Array()
	var b := PackedVector4Array()
	var c := PackedVector4Array()
	for i in range(FILLS):
		var f: Array = fills[i] if i < fills.size() else [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
		a.append(Vector4(f[0], f[1], f[2], f[3]))
		b.append(Vector4(f[4], f[5], f[6], f[7]))
		c.append(Vector4(f[8], f[9], 0.0, 0.0))
	var wa := PackedVector4Array()
	var wb := PackedVector4Array()
	for i in range(WAVES):
		var w: Array = waves[i] if i < waves.size() else [0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0]
		wa.append(Vector4(w[0], w[1], w[2], w[3]))
		wb.append(Vector4(w[4], w[5], 0.0, 0.0))
	m.set_shader_parameter("wf_n", fills.size())
	m.set_shader_parameter("wf_a", a)
	m.set_shader_parameter("wf_b", b)
	m.set_shader_parameter("wf_c", c)
	m.set_shader_parameter("ww_n", waves.size())
	m.set_shader_parameter("ww_a", wa)
	m.set_shader_parameter("ww_b", wb)


## A fill with a front (a seeping table fills from below with no front: nothing to draw but the water itself). Its run
## either side of the source: the columns below the surface it heads for, past the open sea at the source and up to the
## first ground above it (within the sim's reach of the source a bump does not stop it: World feeds those columns
## too). A front coming the other way from a fill still running meets this one where the two arrive at once: both runs
## end there, so both crests pile up on the same spot.
func _fill(S: SimState, e, T: float) -> void:
	var spd: float = float(e.spd)
	if spd <= 0.0 or fills.size() >= FILLS:
		return
	var nc: int = SimConst.NC
	var col: float = SimConst.COL
	var x: float = SimWrap.wrap(float(e.x))
	var y: float = float(e.y)
	var sc: int = int(floor(x / col)) % nc
	var reach: int = RenderLook.WATER_FILL_REACH
	var most: int = mini(nc / 2 - 1, int(ceil(float(e.r) / col)) * 2 + reach)
	var low_d: PackedFloat32Array = WorldTerrain.lowD(S)   # the ground the sim's water runs on
	var run: Array = []
	for dir in [-1, 1]:
		var s: float = 0.0
		var d: float = 0.0
		var on: bool = false
		for j in range(1, most + 1):
			var i: int = posmod(sc + dir * j, nc)
			if S.base[i] < WorldWater.RESERVOIR_BASE:
				if on:
					break   # open water again on the far side: the run ends there
				continue
			var low: bool = S.base[i] + low_d[i] < y - WorldWater.MIN_DEPTH
			if low:
				if not on:
					on = true
					s = (float(j) - 0.5) * col
				d = (float(j) + 0.5) * col
			elif on and j > reach:
				break   # ground above the surface past the sim's reach: the hole's far wall
		run.append_array([s, d] if on else [0.0, 0.0])
	if run[1] <= run[0] and run[3] <= run[2]:
		return
	var t0: float = T - float(WorldWater.STEP_TICKS) * SimConst.DT   # the sim's front reaches its first columns at the window's first step
	var lift: Vector3 = RenderLook.WATER_CREST
	var crest: float = clampf(float(e.amount) * lift.x, lift.y, lift.z)
	var f: Array = [x, y, spd, t0, run[0], run[1], run[2], run[3], crest, crest * RenderLook.WATER_SLOSH, 0.0]
	for g in fills:
		_meet(f, g)
	f[10] = t0 + maxf(float(f[5]), float(f[7])) / spd + RenderLook.WATER_FILL_T.z * 6.0
	fills.append(f)
	version += 1


## Two fronts coming at each other: each run ends where they arrive together.
static func _meet(a: Array, b: Array) -> void:
	for sa in [-1, 1]:
		var ia: int = 4 if sa < 0 else 6
		if float(a[ia + 1]) <= float(a[ia]):
			continue
		var p: float = SimWrap.sdx(float(a[0]), float(b[0])) * float(sa)   # b's source along a's way
		if p <= 0.0:
			continue
		var ib: int = 6 if sa < 0 else 4   # b's run back toward a
		if float(b[ib + 1]) <= float(b[ib]):
			continue
		var u: float = (float(b[3]) - float(a[3]) + p / float(b[2])) / (1.0 / float(a[2]) + 1.0 / float(b[2]))
		if u > float(a[ia]) and u < float(a[ia + 1]) and p - u > float(b[ib]) and p - u < float(b[ib + 1]):
			a[ia + 1] = u
			b[ib + 1] = p - u


func _wave(e, T: float) -> void:
	if waves.size() >= WAVES:
		waves.pop_front()
	var ring: Vector3 = RenderLook.WATER_RING
	var run: float = maxf(float(e.dur), ring.z)
	waves.append([SimWrap.wrap(float(e.x)), float(e.y), T, float(e.r), ring.x, run, T + run])
	version += 1
