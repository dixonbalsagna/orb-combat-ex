class_name VfxBeamLook
extends RefCounted
## The look of a signature beam (docs/vfx/beam-look.md; Orb, 2026-10-16: "the beams are too thin ... cool, rippling, glowing, fluid-looking shaders, each character should have their own flavor").
## Rendering's BeamView draws a beam as three additive prisms (a sheath, a body and a core); this gives each of them its material and its size:
##   - a real width by default (the sheath 4 times the sim's beam width, the body 2.2, the core 0.9, times the fighter's `width_k`): one fighter may keep a thin beam as his particular move
##   - the beam shader (shaders/beam.gdshader): a slow travelling hue ripple between two tints of the SAME luminance, so it looks fluid while its brightness stays steady; turbulence on the soft edge
##     only; rounded ends and a swelling heel. Never a white core: the core is the lane colour lightened, as Art's aura rule has it (core at most L* 86)
##   - each fighter's flavour (data/vfx/energy.json): the colour is the fighter's lane colour (so a colour-vision preset follows), the second tint a hue shift of it at the same luminance, and the
##     motion character (ripple wavelength and rate, edge turbulence, the heel) is his
## Legal fx03: the beam stays a plain straight line (nothing goes round its axis), its ripple is 2 Hz or slower with a luminance step under 10%, and its start and end flashes are the register's
## (SimHost.beam_flash: unchanged). Presentation only: reads the beam and its owner, draws no random number, writes nothing.

const DEFAULTS: Dictionary = {
	"beam": {
		"default": {"width_k": 1.0, "hue_shift": 28.0, "hz": 1.0, "wavelength": 130.0, "flow": 70.0, "turb": 0.15, "heel": 0.5, "seed": 0.0, "wob_k": 1.0, "fil": 0.6, "soft_k": 1.0, "pat": 0.0, "pat_k": 0.0, "pat_a": 0.0, "pat_scale": 90.0},
		"protagonist": {"width_k": 1.15, "hue_shift": 30.0, "hue_shift_tritan": -30.0, "hz": 1.1, "wavelength": 150.0, "flow": 80.0, "turb": 0.12, "heel": 0.7, "seed": 0.0, "wob_k": 0.9, "fil": 0.7, "soft_k": 0.9, "pat": 1.0, "pat_k": 0.03, "pat_a": 0.18, "pat_scale": 95.0},
		"rival": {"width_k": 1.1, "hue_shift": 34.0, "hue_max": 320.0, "hz": 0.8, "wavelength": 80.0, "flow": 60.0, "turb": 0.05, "heel": 0.25, "seed": 2.1, "wob_k": 0.25, "fil": 0.9, "soft_k": 1.35, "pat": 2.0, "pat_k": 0.03, "pat_a": 0.2, "pat_scale": 64.0},
		"rival_short": {"width_k": 0.4, "hue_shift": 34.0, "hue_max": 320.0, "hz": 0.8, "wavelength": 80.0, "flow": 60.0, "turb": 0.0, "heel": 0.1, "seed": 2.1, "wob_k": 0.0, "fil": 0.0, "soft_k": 1.35},
		"reference": {"width_k": 0.8, "hue_shift": 12.0, "hz": 0.5, "wavelength": 160.0, "flow": 40.0, "turb": 0.04, "heel": 0.1, "seed": 5.3, "wob_k": 0.2, "fil": 0.2, "soft_k": 1.0},
	},
	"layers": [
		{"k": 1.8, "px": 2.0, "alpha": 0.12, "soft": 1.0, "len_k": 0.3, "turb_k": 1.6, "lum_amp": 0.16, "sat": 2.2, "val": 0.7, "lighten": 0.0, "flow_k": 0.8, "wob": 0.22, "pat_w": 0.0},
		{"k": 1.4, "px": 2.0, "alpha": 0.95, "soft": 0.4, "len_k": 0.26, "turb_k": 1.0, "lum_amp": 0.07, "sat": 2.0, "val": 0.88, "lighten": 0.0, "flow_k": 1.0, "wob": 0.12, "pat_w": 1.0},
		{"k": 0.6, "px": 2.0, "alpha": 1.0, "soft": 0.3, "len_k": 0.14, "turb_k": 0.0, "lum_amp": 0.04, "sat": 0.85, "val": 1.0, "lighten": 0.1, "flow_k": 1.4, "wob": 0.05, "pat_w": 0.6},
	],
	"calm": {"strength": 0.86, "rise_s": 0.3},
	"cap": 40.0,
}

static var _data: Dictionary = {}
static var _loaded: bool = false


static func warm() -> void:
	if _loaded:
		return
	_loaded = true
	var path := "res://data/vfx/energy.json"
	if FileAccess.file_exists(path):
		var v = JSON.parse_string(FileAccess.get_file_as_string(path))
		if v is Dictionary:
			_data = v


static func _group(name: String):
	warm()
	var g = _data.get(name)
	return g if g != null else DEFAULTS[name]


## A fighter's flavour key: his roster id, lower case (`protagonist`, `rival`, `reference`: the Anti-hero is the roster's RIVAL); `default` for any id with no flavour of its own, and for no fighter.
## `short` (a short beam, see is_short) asks for the id's `_short` flavour if it has one: the Anti-hero's thin beam is the one particular beam attack of the roster that is thin (Orb, 2026-10-16).
static func key_of(f, short: bool = false) -> String:
	if f == null:
		return "default"
	var raw = f.get("id")
	var id: String = String(raw).to_lower().replace("-", "_").replace(" ", "_") if raw != null else ""
	var beams = _group("beam")
	if short and beams is Dictionary and beams.has(id + "_short"):
		return id + "_short"
	return id if (id != "" and beams is Dictionary and beams.has(id)) else "default"


## A short beam: the energy stance's beam of about half a second (agency-pass.md), against the signature's 0.95 s. Today only a signature beam is in the sim, so nothing is short yet;
## a beam that carries a `short` field (Simulation may add it) says so itself.
static func is_short(b) -> bool:
	if b == null:
		return false
	var sf = b.get("short")
	if sf != null:
		return bool(sf)
	return float(b.life) > 0.0 and float(b.life) < 0.7


static var _fcache: Dictionary = {}


static func flavour(f, short: bool = false) -> Dictionary:
	var key: String = key_of(f, short)
	if _fcache.has(key):
		return _fcache[key]
	var beams = _group("beam")
	var base: Dictionary = DEFAULTS["beam"]["default"].duplicate()
	if beams is Dictionary:
		if beams.has("default"):
			base.merge(beams["default"], true)
		if key != "default" and beams.has(key):
			base.merge(beams[key], true)
	_fcache[key] = base
	return base


static func layer(i: int) -> Dictionary:
	var ls = _group("layers")
	if ls is Array and i >= 0 and i < ls.size():
		return ls[i]
	return DEFAULTS["layers"][clampi(i, 0, 2)]


## How wide the body layer is against the sim's beam width for this fighter: what the flash register weighs a beam's area by (SimHost.beam_px) and what its tail is paced by.
static func body_k(f, short: bool = false) -> float:
	return float(layer(1)["k"]) * float(flavour(f, short)["width_k"])


static func luma(c: Color) -> float:
	return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b


## The second tint: the colour's hue turned by `deg`, at the same luminance (a search on the value, then on the saturation where the hue cannot be as bright), so the ripple between the two moves
## hue and not brightness.
static func shifted(c: Color, deg: float) -> Color:
	var h: float = fposmod(c.h + deg / 360.0, 1.0)
	var target: float = luma(c)
	var sat: float = c.s
	for k in range(14):
		if luma(Color.from_hsv(h, sat, 1.0)) >= target or sat < 0.05:
			break
		sat *= 0.9
	var lo: float = 0.0
	var hi: float = 1.0
	for k in range(12):
		var mid: float = (lo + hi) * 0.5
		if luma(Color.from_hsv(h, sat, mid)) > target:
			hi = mid
		else:
			lo = mid
	var d: Color = Color.from_hsv(h, sat, (lo + hi) * 0.5)
	d.a = 1.0
	return d


## A layer's tints: the lane colour with the layer's own saturation and value (the sheath deeper, the core the lane colour itself, lightened by a tenth at most, never white), and the shifted one at the same luminance.
static func tints(f, lane: Color, i: int, short: bool = false) -> Array:
	var fl: Dictionary = flavour(f, short)
	var ly: Dictionary = layer(i)
	var a: Color = Color.from_hsv(lane.h, clampf(lane.s * float(ly["sat"]), 0.0, 1.0), clampf(lane.v * float(ly["val"]), 0.0, 1.0)).lightened(float(ly["lighten"]))
	a.a = 1.0
	var deg: float = float(fl["hue_shift"])
	if VfxAura.vision_mode == "tritan" and fl.has("hue_shift_tritan"):
		deg = float(fl["hue_shift_tritan"])         # the Protagonist's tritan lane is a violet-blue: +30 would land on the Anti-hero's violet (Art, docs/art/beam-colours.md)
	if fl.has("hue_max") and deg > 0.0:
		deg = clampf(minf(deg, float(fl["hue_max"]) - a.h * 360.0), 0.0, deg)   # the Rival's second tint stays at 320 degrees or less (Legal's range for him is 260 to 320)
	var b: Color = shifted(a, deg)
	return [a, b]


## The thickness of layer i of a beam of the sim's width w, in world units, at the view's zoom z (the glow's own pixel allowance added).
static func thickness(f, w: float, i: int, z: float, short: bool = false, length: float = -1.0) -> float:
	var fl: Dictionary = flavour(f, short)
	var ly: Dictionary = layer(i)
	var th: float = w * float(ly["k"]) * float(fl["width_k"])
	if length > 0.0:
		th = minf(th, length * float(ly.get("len_k", 9.0)))      # a beam is never wider than a share of its own length: a short, point-blank beam is a bright thin shaft, not a block
	return th + float(ly["px"]) / z


## The slower rise a calm beam takes (seconds): a beam the register refused, or under reduced flashing, comes up over this instead of the tenth of a second.
static func calm_rise() -> float:
	return float(_group("calm")["rise_s"])


static func new_material(layer_index: int = 0) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = preload("res://render/vfx/shaders/beam_glow.gdshader") if layer_index == 0 else preload("res://render/vfx/shaders/beam.gdshader")
	m.render_priority = layer_index       # the sheath first, the body over it, the core last (alpha blending is order-dependent)
	return m


## Everything a layer's material needs this frame. k: the beam's strength 0..1 (its own rise and fall); calm: the register refused it or reduced flashing is on (the same look at `calm.strength`
## and a slower rise, never a thinner beam); t: the sim's clock; length: the beam's drawn length in world units; at_heel: the firer's end is still the beam's tail.
static func set_layer(m: ShaderMaterial, f, lane: Color, i: int, k: float, calm: bool, t: float, length: float, at_heel: bool, beam_id: float = 0.0, short: bool = false) -> void:
	var fl: Dictionary = flavour(f, short)
	var ly: Dictionary = layer(i)
	var tt: Array = tints(f, lane, i, short)
	var calm_k: float = float(_group("calm")["strength"]) if calm else 1.0
	m.set_shader_parameter("tint_a", tt[0])
	m.set_shader_parameter("tint_b", tt[1])
	m.set_shader_parameter("strength", float(ly["alpha"]) * k * calm_k)
	m.set_shader_parameter("soft", float(ly["soft"]) * float(fl["soft_k"]))
	m.set_shader_parameter("time", t)
	m.set_shader_parameter("len", maxf(length, 1.0))
	m.set_shader_parameter("flow", float(fl["flow"]) * float(ly["flow_k"]))
	m.set_shader_parameter("wavelength", float(fl["wavelength"]))
	m.set_shader_parameter("hz", minf(float(fl["hz"]), 2.0))
	m.set_shader_parameter("turb", clampf(float(fl["turb"]) * float(ly["turb_k"]), 0.0, 1.0))
	m.set_shader_parameter("lum_amp", float(ly["lum_amp"]))
	m.set_shader_parameter("cap", float(_group("cap")))
	m.set_shader_parameter("heel", float(fl["heel"]) if at_heel else 0.0)
	m.set_shader_parameter("seed", float(fl["seed"]) + beam_id * 1.37)
	m.set_shader_parameter("wob", float(ly["wob"]) * float(fl["wob_k"]))
	m.set_shader_parameter("fil", float(fl["fil"]))
	# the fighter's own pattern (the Protagonist's boil, the Anti-hero's facets): the sheath's soft glow has none; the calm form halves the texture and keeps the silhouette
	var pw: float = float(ly.get("pat_w", 0.0))
	m.set_shader_parameter("pat", float(fl["pat"]) if pw > 0.0 else 0.0)
	m.set_shader_parameter("pat_k", float(fl["pat_k"]) * pw * (0.5 if calm else 1.0))
	m.set_shader_parameter("pat_a", float(fl["pat_a"]) * pw)
	m.set_shader_parameter("pat_scale", float(fl["pat_scale"]))
