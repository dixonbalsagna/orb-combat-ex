class_name VfxBeamStruggle
extends RefCounted
## The beam struggle, carried by the beams themselves (Orb's minimal UI, docs/ep/taste.md; Game Design's docs/design/minimal-hud.md row "The beam struggle"; Research's readable-speed paper): no bar and no marker
## on the screen, the meeting point is the gauge. What the player sees, all in the two beams and nothing else:
##   who pushes     the beam of the one who is winning ground is thicker, his rival's thinner: the beam's width follows the meeting point (eased over `ease_s`, so a surge's 10 to 15% jump is a quick
##                  shift of the point, never a pop)
##   the beat       a swell leaves each fighter's hand 14 ticks before every pulse and runs down his beam to reach the meeting point ON the pulse: the player follows the beat as the swells close on the point
##   a surge        a bigger swell runs down the presser's own beam from his hand to the point, and the meeting point swells a little more (a sharp one bigger)
##   a stray        a pinch runs down his own beam: shape only (the beam narrows for an instant), nothing flickers
##   the point      swells slowly while the struggle lasts (`knot_s`) and each surge adds to it, which decays slowly: never a flash
## All are changes of width (a smooth bulge on the beam's radius) with at most `lum` of alpha on top, so the beam's brightness stays steady (Legal fx03 and fx04 for the struggle's marks). Under Reduce flashing or
## Reduced motion (the register's `reduced`) it keeps the old marks' rate: the beat is shown for every second pulse only and a surge or stray wave is not made within `calm_gap` ticks of the last.
## Presentation only: it reads S.game.clash and the cues, keeps its own clock, draws no random number, writes nothing of the sim. The beams' drawing is BeamView's; the shader (beam_core.gdshaderinc) takes the waves.

class Wave:
	var side: int = 0          # 0 the beam from A's hand, 1 from D's
	var born: float = 0.0      # tick (this model's clock)
	var amp: float = 0.2       # the width it adds at its centre, a share of the radius (negative pinches)
	var big: bool = false

const DEFAULTS: Dictionary = {
	"push_k": 0.3, "ease_s": 0.35, "wave_ticks": 14.0, "surge_amp": 0.8, "sharp_k": 1.4, "beat_amp": 0.34, "stray_amp": -0.4, "wave_half": 0.15, "wave_half_max": 120.0, "lum": 0.08,
	"knot_amp": 0.6, "knot_s": 1.8, "knot_surge": 0.14, "knot_decay_s": 2.5, "calm_gap": 40.0, "amp_calm": 0.8, "flare_k": 0.3, "flare_ease_s": 0.4,
	"lose_min": 1.0, "buck_bulge": 0.7, "buck_bow": 0.09, "buck_bow_max": 70.0, "buck_quiv": 0.03, "buck_quiv_max": 24.0, "buck_bow_hz": 0.7, "buck_quiv_hz": 1.6, "buck_wave": 0.3,
	"buck_wave_min": 130.0, "buck_calm": 0.5, "buck_calm_hz": 0.6,
}

var active: bool = false
var push: float = 0.0              # eased, -1 (D has the point at A's hands) to +1 (A has it at D's)
var knot: float = 0.0              # 0 to 1
var waves: Array = []              # Wave
var clock: float = 0.0             # ticks since the model started (counts its own steps)
var started: float = 0.0
var made: Dictionary = {}          # counters, for the tests
var sched: Array = []              # [pulse tick, k]: the pulses that have a swell to leave
var _scheduled: Dictionary = {}
var _last_mark: float = -1000.0
var _calm: bool = false
var _A = null
var _D = null
var _slots: Array = [-1, -1]      # the fighters' slots (A, D)
var _flare: Array = [0.0, 0.0]    # eased: the aura's flare of the side that is losing ground

static var _data: Dictionary = {}
static var _loaded: bool = false


static func p(key: String) -> float:
	VfxBeamLook.warm()
	var g = VfxBeamLook._data.get("struggle")
	if g is Dictionary and g.has(key):
		return float(g[key])
	return float(DEFAULTS[key])


func reset() -> void:
	active = false
	push = 0.0
	knot = 0.0
	waves.clear()
	sched.clear()
	_scheduled.clear()
	clock = 0.0
	_last_mark = -1000.0
	made = {}
	_A = null
	_D = null
	_slots = [-1, -1]
	_flare = [0.0, 0.0]


## Every tick (dt: the tick's seconds; calm: the register's reduced mode). `S.tick` is the cue clock the beam cues count in.
func step(S: SimState, events: Array, calm: bool, dt: float = 1.0 / 60.0) -> void:
	var c = S.game.clash
	var on: bool = c != null and float(c.mid) >= 0.0
	_calm = calm
	if not on:
		if active:
			reset()
		return
	if not active or c.A != _A or c.D != _D:
		reset()
		active = true
		_A = c.A
		_D = c.D
		_slots = [S.fighters.find(c.A), S.fighters.find(c.D)]
		started = clock
	clock += 1.0
	var target: float = clampf((float(c.mid) - 0.5) * 2.0, -1.0, 1.0)
	push += (target - push) * (1.0 - exp(-dt / maxf(p("ease_s"), 0.02)))
	# the loser digs in: his aura flares in proportion to the ground he has lost (his side of the push), eased
	var ef: float = 1.0 - exp(-dt / maxf(p("flare_ease_s"), 0.02))
	_flare[0] += (maxf(-push, 0.0) - float(_flare[0])) * ef
	_flare[1] += (maxf(push, 0.0) - float(_flare[1])) * ef
	# the knot: a slow swell up over the struggle's first seconds, and a little more for each surge, which fades slowly
	var base: float = smoothstep(0.0, 1.0, (clock - started) * dt / maxf(p("knot_s"), 0.1))
	knot = maxf(knot - dt / maxf(p("knot_decay_s"), 0.1), 0.0)
	for e in events:
		if String(e.type) != "cue":
			continue
		match String(e.kind):
			"beam_pulse":
				_pulse(S, e)
			"beam_surge":
				_surge(S, e)
			"beam_stray":
				_stray(S, e)
			"beam_end":
				waves.clear()
				sched.clear()
	# the swells that are due to leave: a beat's swell is born `wave_ticks` before its pulse and reaches the point on it
	var wt: float = p("wave_ticks")
	var keep: Array = []
	for s in sched:
		if float(S.tick) >= float(s[0]) - wt:
			if float(S.tick) - (float(s[0]) - wt) < wt:
				for side in range(2):
					var w := Wave.new()
					w.side = side
					w.born = clock - (float(S.tick) - (float(s[0]) - wt))
					w.amp = p("beat_amp") * (p("amp_calm") if calm else 1.0)
					waves.append(w)
				made["beat"] = int(made.get("beat", 0)) + 1
		else:
			keep.append(s)
	sched = keep
	var live: Array = []
	for w in waves:
		if clock - w.born <= wt + 4.0:
			live.append(w)
	waves = live
	knot_level = clampf(base + knot, 0.0, 1.0)


var knot_level: float = 0.0


func _pulse(S: SimState, e) -> void:
	var k: int = int(float(VfxHub._g(e, "k", 1.0)))
	var n_at: float = float(VfxHub._g(e, "n", float(S.tick)))
	for j in range(2):
		if j == 1 and k >= 15:
			break
		if _calm and (k + j) % 2 == 0:
			continue       # fx04: every second pulse's swell only
		var tick: float = n_at + float(j) * 20.0
		if _scheduled.has(int(tick)):
			continue
		_scheduled[int(tick)] = true
		sched.append([tick, k + j])


func _slot_side(S: SimState, slot: int) -> int:
	if slot < 0 or slot >= S.fighters.size():
		return -1
	var f = S.fighters[slot]
	if f == _A:
		return 0
	if f == _D:
		return 1
	return -1


func _surge(S: SimState, e) -> void:
	var side: int = _slot_side(S, int(e.actor))
	if side < 0:
		return
	if _calm and clock - _last_mark < p("calm_gap"):
		return
	_last_mark = clock
	var w := Wave.new()
	w.side = side
	w.born = clock
	w.big = String(e.text) == "sharp"
	w.amp = p("surge_amp") * (p("sharp_k") if w.big else 1.0) * (p("amp_calm") if _calm else 1.0)
	waves.append(w)
	knot = minf(knot + p("knot_surge") * (p("sharp_k") if w.big else 1.0), 1.0)
	made["surge"] = int(made.get("surge", 0)) + 1


func _stray(S: SimState, e) -> void:
	var side: int = _slot_side(S, int(e.actor))
	if side < 0:
		return
	if _calm and clock - _last_mark < p("calm_gap"):
		return
	_last_mark = clock
	var w := Wave.new()
	w.side = side
	w.born = clock
	w.amp = p("stray_amp")
	waves.append(w)
	made["stray"] = int(made.get("stray", 0)) + 1


## The width factor of a side's beam: the winner's thicker (1 + push_k at the most); the loser's is never thinner than `lose_min` (1: Orb, 2026-10-22, "instead of thinning out"): he buckles instead (`lost`).
func width_k(side: int) -> float:
	if not active:
		return 1.0
	var s: float = push if side == 0 else -push
	return clampf(1.0 + p("push_k") * s, p("lose_min"), 1.5)


## How much ground a side has lost, 0 to 1, eased: what the buckling grows with (his side of the push, smoothed so it starts gently).
func lost(side: int) -> float:
	if not active:
		return 0.0
	var gain: float = push if side == 0 else -push
	return smoothstep(0.0, 1.0, clampf(-gain, 0.0, 1.0))


## The flare of a fighter's aura (0 to flare_k): the loser's grows with the ground he has lost, the winner's is nil. The standing aura's size and alpha read it (transform_view.gd).
func flare(slot: int) -> float:
	if not active:
		return 0.0
	for side in range(2):
		if _slots[side] == slot:
			return float(_flare[side]) * p("flare_k")
	return 0.0


## A wave's centre along its beam, world units from the hand, for a beam of length `len`.
func wave_pos(w: Wave, len: float) -> float:
	return len * clampf((clock - w.born) / maxf(p("wave_ticks"), 1.0), 0.0, 1.0)


## Sets one layer's wave uniforms on a clash beam's material: up to two swells in `wv0` and `wv1` (x its centre from the hand, y its half length, z the width it adds, w the alpha it adds) and the knot
## at the meeting point in `wv2`. `scale` is the layer's share (the sheath's swell is the largest, the core's the least). A beam with no struggle gets its waves zeroed.
func apply(mat: ShaderMaterial, side: int, len: float, scale: float) -> void:
	var mine: Array = []
	if active:
		for w in waves:
			if w.side == side:
				mine.append(w)
	mine.sort_custom(func(a, b): return a.born > b.born)
	var half: float = minf(len * p("wave_half"), p("wave_half_max"))
	var lum: float = p("lum")
	for i in range(2):
		var v := Vector4(0.0, 1.0, 0.0, 0.0)
		if i < mine.size():
			var w: Wave = mine[i]
			var amp: float = w.amp * scale
			v = Vector4(wave_pos(w, len), half * (1.3 if w.big else 1.0), amp, lum * maxf(amp, 0.0) / maxf(p("surge_amp"), 0.01))
		mat.set_shader_parameter("wv%d" % i, v)
	var kv := Vector4(0.0, 1.0, 0.0, 0.0)
	if active and knot_level > 0.002:
		kv = Vector4(len, minf(len * 0.2, p("wave_half_max") * 1.2), p("knot_amp") * knot_level * scale, 0.0)
	mat.set_shader_parameter("wv2", kv)
	# the loser's buckling: geometry only, in his own beam, growing with the ground he has lost; calm (Reduce flashing or Reduced motion): half the size at 0.6 of the rate
	var ck: float = p("buck_calm") if _calm else 1.0
	var hk: float = p("buck_calm_hz") if _calm else 1.0
	mat.set_shader_parameter("buck", Vector4(lost(side), minf(len * p("buck_bow"), p("buck_bow_max")) * ck, minf(len * p("buck_quiv"), p("buck_quiv_max")) * ck, p("buck_bulge") * ck))
	mat.set_shader_parameter("buck2", Vector4(p("buck_bow_hz") * hk, p("buck_quiv_hz") * hk, maxf(len * p("buck_wave"), p("buck_wave_min")), 1.0 if side == 0 else -1.0))
	# the press: how near the head each surge's swell has got, and the knot, drive the eddies
	var surge: float = 0.0
	for w in mine:
		var near: float = 1.0 - clampf((len - wave_pos(w, len)) / maxf(len * 0.25, 1.0), 0.0, 1.0)
		surge = maxf(surge, near * clampf(w.amp / maxf(p("surge_amp"), 0.01), 0.0, 1.5))
	set_press(mat, side, len, scale, minf(surge, 1.0), clampf(knot_level, 0.0, 1.0), push if side == 0 else -push)


const LAYER_SCALE: Array = [1.15, 1.0, 0.75]
## What the clash's air view last drew (clash_view.gd sets these each frame; a frame behind, which the eased values hide): the clash's rise and fall, each side's power, and whether the press is calm. The beams read them here so the
## press (the heads' flare, sheet and eddies) is one language with the air at the meeting point, from the same composition.
static var press_ck: float = 0.0
static var press_pow: Array = [0.0, 0.0]
static var press_calm: bool = false
static var press_quality: int = 2      # the hub's quality: low draws the lite press (the flare and the sheet only), medium adds the eddies' shape, high their hue
static var press_seed: Array = [0.0, 0.0]


## The press on one layer of a clash beam (render/vfx/shaders/beam_core.gdshaderinc): the head's flare, the flat sheet and the eddies, from this side's power, the struggle's knot and the surges that have reached the head.
## `surge` and `knot` are 0 to 1 (0 with no struggle). Geometry and hue only; the eddies roll back at `eddy_v` units a second, one every `eddy_wl`, so a point of the beam sees one at 0.9 Hz or slower.
static func set_press(mat: ShaderMaterial, side: int, len: float, scale: float, surge: float, knot: float, lead: float) -> void:
	var ck: float = press_ck
	if ck <= 0.001 or not VfxClashLook.on():
		mat.set_shader_parameter("press", Vector4(0.0, 0.0, 110.0, 0.0))
		return
	var pw: float = clampf(float(press_pow[clampi(side, 0, 1)]) / 1.4, 0.0, 1.0)
	var calm: float = VfxClashLook.pp("calm_k") if press_calm else 1.0
	var vk: float = 0.6 if press_calm else 1.0
	var flare: float = VfxClashLook.pp("flare_k") * ck * (0.55 + 0.45 * pw) * (0.85 + 0.15 * clampf(lead, -1.0, 1.0)) * scale * calm
	var sheet: float = VfxClashLook.pp("sheet_k") * ck * (0.45 + 0.35 * pw + 0.2 * knot)
	var depth: float = VfxClashLook.pp("eddy_k") * ck * (0.4 + 0.6 * pw) * (0.55 + 0.45 * knot + VfxClashLook.pp("surge_k") * surge) * calm
	if press_quality <= 0:
		depth = 0.0       # the lite press: the flare and the sheet alone, no eddy noise in the vertex or the fragment stage
	mat.set_shader_parameter("press", Vector4(flare, depth * scale, VfxClashLook.pp("eddy_v") * (0.7 + 0.3 * pw) * vk, sheet * calm))
	mat.set_shader_parameter("press2", Vector4(float(press_seed[clampi(side, 0, 1)]), VfxClashLook.pp("eddy_wl"), minf(len * 0.45, VfxClashLook.pp("reach")), VfxClashLook.pp("hue") if press_quality >= 2 else 0.0))


## The one call BeamView makes per layer of every beam: a clash beam (side 0 or 1) with a struggle on gets its waves, any other beam has them cleared if its material was a clash beam's before.
static func set_on(mat: ShaderMaterial, sk, side: int, len: float, layer: int) -> void:
	if sk != null and side >= 0 and sk.active:
		sk.apply(mat, side, len, float(LAYER_SCALE[layer]))
		mat.set_meta("sw", true)
	elif side >= 0:
		# a clash with no struggle behind it (the sim's glide): the press alone, no surges and no knot
		set_press(mat, side, len, float(LAYER_SCALE[layer]), 0.0, 0.0, 0.0)
		mat.set_meta("sw", true)
	elif mat.has_meta("sw"):
		sk_clear(mat)
		mat.remove_meta("sw")


static func sk_clear(mat: ShaderMaterial) -> void:
	for n in ["wv0", "wv1", "wv2"]:
		mat.set_shader_parameter(n, Vector4(0.0, 1.0, 0.0, 0.0))
	mat.set_shader_parameter("buck", Vector4(0.0, 0.0, 0.0, 0.0))
	mat.set_shader_parameter("press", Vector4(0.0, 0.0, 110.0, 0.0))
