extends SceneTree
## World catastrophe, the sim side (Research & Prototyping, 2026-10-16). A scratch probe: it runs only in a clean
## export of HEAD (git archive), never in the shared tree, and changes nothing in sim/. Prototype models live here.
##   godot --headless --path <head copy> -s res://docs/research/world-catastrophe/sim_probe.gd -- [magma] [atmo] [collapse]
## Prints one JSON line per part (PROBE {...}). Times are wall clock on whatever machine runs it: read the load note.

var parts: Array = []


func _init() -> void:
	parts = OS.get_cmdline_user_args()
	if parts.is_empty():
		parts = ["magma", "atmo", "collapse"]
	if parts.has("magma"):
		_magma()
	if parts.has("atmo"):
		_atmo()
	if parts.has("collapse"):
		_collapse()
	quit(0)


func _out(name: String, d: Dictionary) -> void:
	d["part"] = name
	print("PROBE " + JSON.stringify(d))


func fresh(seed: int = 1) -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, seed, {}, {"intro": false})
	S.out.fx.clear()
	return S


func ground(S: SimState, i: int) -> float:
	return float(S.base[i]) + float(S.deform[i])


# ---------------------------------------------------------------------------------------------------------------- magma
## The crust-cut model. A column dug down to the deformation floor has broken the crust. Magma rises there from the
## mantle toward a head (a share of the cut's depth below the old surface), flows along the cut by the same saturated
## two-column exchange the water model uses (old state in, deltas out: order-free and deterministic), carries its heat,
## cools, and solidifies into new rock (back into deform) when cold. No random draw. All float64 scalars.
const M_HEAD_FRAC: float = 0.35     # magma stands this share of the floor's depth below the original surface
const M_RATE: float = 120.0         # units of rise a second at a breached column (a fast, visible bubbling up)
const M_K: float = 0.25             # share of a surface difference exchanged per step (the water model's saturated rule)
const M_COOL: float = 1.0 / 90.0    # heat lost a second in the open (a lit trench glows for about a minute and a half)
const M_SOLID: float = 0.15         # below this heat it sets into rock
const M_STEP_TICKS: int = 2         # the flow runs every second tick, as the water model runs on its own cadence


func _magma() -> void:
	var S := fresh(1)
	var NC: int = SimConst.NC
	var floor_d: float = WorldCrater.DEFORM_FLOOR
	# find 160 columns of dry land (about 5,100 units, 68 fighter heights) for the cut
	var i0: int = -1
	var run: int = 0
	for i in NC:
		if float(S.base[i]) > 100.0 and float(S.water[i]) <= 0.0:
			run += 1
			if run >= 200:
				i0 = i - 180
				break
		else:
			run = 0
	var L: int = 160
	var xa: float = float(i0) * SimConst.COL
	var xb: float = float(i0 + L) * SimConst.COL
	# How deep can a cut go today? carveSegment asked for far more than the floor allows.
	var t0: int = Time.get_ticks_usec()
	WorldCrater.carveSegment(S, xa, xb, 6000.0, false, 0.0)
	var carve_us: int = Time.get_ticks_usec() - t0
	var deepest: float = 0.0
	var at_floor: int = 0
	for i in range(i0, i0 + L):
		deepest = minf(deepest, float(S.deform[i]))
		if float(S.deform[i]) <= floor_d + 1.0:
			at_floor += 1
	var mag := PackedFloat64Array()
	var heat := PackedFloat64Array()
	mag.resize(NC)
	heat.resize(NC)
	var pad: int = 120
	var w0: int = maxi(0, i0 - pad)
	var w1: int = mini(NC - 1, i0 + L + pad)
	var dt: float = SimConst.DT * float(M_STEP_TICKS)
	var steps: int = 1800   # one simulated minute at M_STEP_TICKS 2
	var us: Array = []
	var lit_max: int = 0
	var rock: float = 0.0
	var surf_hi: float = -1.0e9
	var dmag := PackedFloat64Array()
	var dheat := PackedFloat64Array()
	dmag.resize(NC)
	dheat.resize(NC)
	for s in steps:
		var a: int = Time.get_ticks_usec()
		for i in range(w0, w1 + 1):
			dmag[i] = 0.0
			dheat[i] = 0.0
		# the mantle's push at breached columns: the source stops once the surface stands at its head
		for i in range(w0, w1 + 1):
			if float(S.deform[i]) <= floor_d + 1.0 and s < 900:   # the vent runs for the first half minute
				var head: float = float(S.base[i]) + floor_d * M_HEAD_FRAC
				var surf: float = ground(S, i) + mag[i]
				if surf < head:
					var add: float = minf(M_RATE * dt, head - surf)
					dmag[i] += add
					dheat[i] += add * 1.0
		# the exchange, from the old state
		for i in range(w0, w1):
			var j: int = i + 1
			var si: float = ground(S, i) + mag[i]
			var sj: float = ground(S, j) + mag[j]
			var diff: float = si - sj
			if diff > 0.0 and mag[i] > 0.0:
				var mv: float = minf(diff * M_K, mag[i] * 0.5)
				var hv: float = heat[i] / mag[i] * mv
				dmag[i] -= mv
				dmag[j] += mv
				dheat[i] -= hv
				dheat[j] += hv
			elif diff < 0.0 and mag[j] > 0.0:
				var mv2: float = minf(-diff * M_K, mag[j] * 0.5)
				var hv2: float = heat[j] / mag[j] * mv2
				dmag[j] -= mv2
				dmag[i] += mv2
				dheat[j] -= hv2
				dheat[i] += hv2
		var lit: int = 0
		for i in range(w0, w1 + 1):
			mag[i] += dmag[i]
			heat[i] += dheat[i]
			if mag[i] > 0.0:
				heat[i] = maxf(0.0, heat[i] - mag[i] * M_COOL * dt)   # heat is carried as heat x depth
				var h01: float = heat[i] / mag[i]
				if h01 < M_SOLID:
					S.deform[i] = float(S.deform[i]) + mag[i] * 0.95   # it sets into rock (a little shrinks)
					rock += mag[i] * 0.95
					mag[i] = 0.0
					heat[i] = 0.0
				else:
					lit += 1
					surf_hi = maxf(surf_hi, ground(S, i) + mag[i] - float(S.base[i]))
		lit_max = maxi(lit_max, lit)
		us.append(Time.get_ticks_usec() - a)
	us.sort()
	# the same step over all 4,800 columns (a planet-wide pass, the cost a windowless model would pay)
	var full_us: Array = []
	for s in 120:
		var a2: int = Time.get_ticks_usec()
		for i in range(0, NC - 1):
			var si2: float = ground(S, i) + mag[i]
			var sj2: float = ground(S, i + 1) + mag[i + 1]
			dmag[i] = (si2 - sj2) * 0.0
		full_us.append(Time.get_ticks_usec() - a2)
	full_us.sort()
	_out("magma", {
		"cutColumns": L, "cutUnits": L * SimConst.COL, "askedDepth": 6000.0, "deepestDeform": deepest, "floor": floor_d,
		"columnsAtFloor": at_floor, "carveUs": carve_us, "window": w1 - w0 + 1, "stepTicks": M_STEP_TICKS,
		"stepUsMedian": us[us.size() / 2], "stepUsP95": us[int(us.size() * 0.95)], "stepUsMax": us[-1],
		"perTickUsMedian": float(us[us.size() / 2]) / float(M_STEP_TICKS), "litMax": lit_max,
		"magmaTopBelowSurface": -surf_hi if surf_hi > -1.0e8 else null, "rockFormed": rock,
		"fullBandPassUsMedian": full_us[full_us.size() / 2],
	})


# ------------------------------------------------------------------------------------------------------------ atmosphere
## A planet-wide atmosphere state: 64 cells round the lap (2,400 units each) with a low smoke layer that a planetary
## wind carries and that rains out in minutes, a high layer that spreads round the whole planet in about three minutes,
## and a global stratospheric load that decays over half an hour. A mushroom cloud injects into its cell. 129 floats in
## all; a fixed-step update; nothing random. The sky reads darkness = 1 - exp(-(a low + b high + c strato)).
const A_CELLS: int = 64
const A_WIND: float = 1.0 / 20.0      # cells a second the low smoke drifts (a lap in about 21 minutes)
const A_LOW_DIFF: float = 0.02        # low-layer spread a second (share exchanged with each neighbour)
const A_HIGH_DIFF: float = 0.10       # high-layer spread a second
const A_LOW_HALF: float = 300.0       # low smoke rains out with this half-life (s)
const A_HIGH_HALF: float = 900.0
const A_STRATO_HALF: float = 1800.0
const A_LOFT: float = 0.4             # share of a cloud's smoke that reaches the high layer
const A_HI_WIND: float = 0.5          # cells a second the high layer is carried (a jet stream: a lap in about two minutes)
const A_TO_STRATO: float = 1.0 / 240.0   # share of the high layer that settles into the planet-wide veil, a second


func _atmo() -> void:
	var low := PackedFloat64Array()
	var hi := PackedFloat64Array()
	low.resize(A_CELLS)
	hi.resize(A_CELLS)
	var strato: float = 0.0
	var dt: float = 1.0
	var curve: Array = []
	var us_total: int = 0
	var n_steps: int = 0
	var src: int = 10
	for t in range(0, 1201):   # 20 minutes in 1 s steps (the real model would run on a slow cadence too)
		if t == 0 or t == 240 or t == 480:   # three mushroom clouds, four minutes apart, from the same place
			low[src] += 1.0 - A_LOFT
			hi[src] += A_LOFT
		var a: int = Time.get_ticks_usec()
		# wind: a fractional shift of the low layer, by linear interpolation (mass conserving)
		var shifted := PackedFloat64Array()
		shifted.resize(A_CELLS)
		var sh: float = A_WIND * dt
		for c in A_CELLS:
			shifted[(c + 1) % A_CELLS] += low[c] * sh
			shifted[c] += low[c] * (1.0 - sh)
		low = shifted
		var shifted_h := PackedFloat64Array()
		shifted_h.resize(A_CELLS)
		var shh: float = A_HI_WIND * dt
		for c in A_CELLS:
			shifted_h[(c + 1) % A_CELLS] += hi[c] * shh
			shifted_h[c] += hi[c] * (1.0 - shh)
		hi = shifted_h
		for c in A_CELLS:
			var mv: float = hi[c] * A_TO_STRATO * dt
			hi[c] -= mv
			strato += mv / float(A_CELLS)
		var nl := low.duplicate()
		var nh := hi.duplicate()
		for c in A_CELLS:
			var l: int = (c + A_CELLS - 1) % A_CELLS
			var r: int = (c + 1) % A_CELLS
			nl[c] += A_LOW_DIFF * dt * (low[l] + low[r] - 2.0 * low[c])
			nh[c] += A_HIGH_DIFF * dt * (hi[l] + hi[r] - 2.0 * hi[c])
		var kl: float = pow(0.5, dt / A_LOW_HALF)
		var kh: float = pow(0.5, dt / A_HIGH_HALF)
		for c in A_CELLS:
			nl[c] *= kl
			nh[c] *= kh
		low = nl
		hi = nh
		strato *= pow(0.5, dt / A_STRATO_HALF)
		us_total += Time.get_ticks_usec() - a
		n_steps += 1
		if t % 60 == 0:
			var row := {"t": t}
			for pair in [["source", src], ["quarter", (src + A_CELLS / 4) % A_CELLS], ["antipode", (src + A_CELLS / 2) % A_CELLS]]:
				var c2: int = pair[1]
				var load: float = 1.0 * low[c2] + 1.6 * hi[c2] + 40.0 * strato
				row[pair[0]] = snappedf(1.0 - exp(-load), 0.001)
			curve.append(row)
	_out("atmo", {"cells": A_CELLS, "floats": A_CELLS * 2 + 1, "stepUsMean": float(us_total) / float(n_steps),
		"note": "darkness 0..1 by minute after three clouds at t = 0, 4 and 8 min (pow here is a prototype; the sim would use SimDetMath or a fixed table)",
		"curve": curve})


# ------------------------------------------------------------------------------------------------------------- collapse
func _collapse() -> void:
	var S0 := fresh(1)
	var towers: Array = []
	var total: int = S0.buildings.size()
	for b in S0.buildings:
		if b.kind == "tower" and b.alive:
			towers.append(b.idx)
	towers.sort_custom(func(a, b): return S0.buildings[a].h > S0.buildings[b].h)
	var rows: Array = []
	for K in [1, 5, 10, 20, 40]:
		if K > towers.size():
			continue
		var S := fresh(1)
		S.fighters[0].tier = 4.0
		S.world.maxTier = 4.0
		var cause = S.fighters[0]
		var cx: float = S.buildings[towers[0]].x
		var cas0: float = S.world.casualties
		var a: int = Time.get_ticks_usec()
		for k in K:
			WorldStructures.collapse(S, S.buildings[towers[k]], cause, "implode", cx, 0.0)
		var us: int = Time.get_ticks_usec() - a
		var fx: int = S.out.fx.size()
		var falls: int = 0
		for e in S.out.fx:
			if typeof(e) == TYPE_OBJECT and "type" in e and String(e.type) == "building_fall":
				falls += 1
		# the ticks right after: does the sim stall?
		var tick_us: Array = []
		for t in 120:
			var b0: int = Time.get_ticks_usec()
			SimCore.step(S)
			tick_us.append(Time.get_ticks_usec() - b0)
		tick_us.sort()
		rows.append({"towers": K, "collapseUs": us, "fxEvents": fx, "fallEvents": falls, "fold": S.world.fallFold,
			"casualties": snappedf(S.world.casualties - cas0, 0.1), "evacuated": snappedf(S.world.evacuated, 0.1),
			"pop0": snappedf(S.world.pop0, 1.0), "tickUsMedianAfter": tick_us[60], "tickUsMaxAfter": tick_us[-1]})
	# a city-scale blast, and the largest crater, at tier 4
	var blasts: Array = []
	for r in [3000.0, 6000.0, 12000.0]:
		var S2 := fresh(1)
		S2.fighters[0].tier = 4.0
		S2.world.maxTier = 4.0
		var cx2: float = S2.buildings[towers[0]].x
		var lost0: float = S2.world.structuresLost
		var a2: int = Time.get_ticks_usec()
		WorldStructures.explode(S2, cx2, 400.0, r, S2.fighters[0], 1.0)
		var us2: int = Time.get_ticks_usec() - a2
		blasts.append({"radius": r, "us": us2, "levelled": S2.world.structuresLost - lost0, "casualties": snappedf(S2.world.casualties, 0.1), "evacuated": snappedf(S2.world.evacuated, 0.1)})
	var S3 := fresh(1)
	S3.fighters[0].tier = 4.0
	var e_max: float = pow(WorldCrater.R_MAX / WorldCrater.R_BASE, 2.0)
	var a3: int = Time.get_ticks_usec()
	var rec = WorldCrater.dig(S3, S3.buildings[towers[0]].x, e_max, S3.fighters[0], "special", 0.0, 1.0, true)
	var us3: int = Time.get_ticks_usec() - a3
	_out("collapse", {"buildings": total, "towers": towers.size(), "byTowers": rows, "blasts": blasts,
		"maxCrater": {"energy": e_max, "us": us3, "r": rec.r if rec != null and "r" in rec else null, "depth": rec.depth if rec != null and "depth" in rec else null}})
