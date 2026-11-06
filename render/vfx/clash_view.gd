class_name VfxClashView
extends Node3D
## The meeting point of a beam clash, drawn as rippling, glowing air (docs/vfx/clash-look.md): two camera-facing quads at the point, one mixed over the scene (the glow: pressure rings, each side's own front and texture, rays erupting, the
## knot) and one mixed (the air: the screen behind it displaced by the rings, or, with no screen read, dark lens bands). It replaces BeamView's solid white flare sphere. BeamView (Rendering's) owns the node and calls `update`
## once a frame; this file composes the two sides from data (clash_look.gd, data/vfx/clash.json), keeps no sim state and draws no random number. Everything is driven by the sim's clock (`S.T`), so a capture of the same
## ticks is the same pictures.
##
## The distortion reads the screen (`hint_screen_texture`): the Compatibility renderer copies the whole frame once for it, while a clash is on and only then. `screen_read` picks: -1 follows the hub's quality (the lite
## form at Q_LOW), 0 forces the lite form (no screen read), 1 forces the distortion.

var screen_read: int = -1

var _glow: MeshInstance3D
var _air: MeshInstance3D
var _glow_mat: ShaderMaterial
var _air_full: ShaderMaterial
var _air_lite: ShaderMaterial
var _clash = null
var _bursts: Array = []
var _seen: Dictionary = {}
var last: Dictionary = {}      # the last frame's composition, for the tests and the debug feed


func _init() -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(2.0, 2.0)
	_glow_mat = ShaderMaterial.new()
	_glow_mat.shader = preload("res://render/vfx/shaders/clash_glow.gdshader")
	_glow_mat.render_priority = 5
	_air_full = ShaderMaterial.new()
	_air_full.shader = preload("res://render/vfx/shaders/clash_air.gdshader")
	_air_full.render_priority = -4       # the air reads the screen, which holds only the opaque pass: drawn over the beams it painted the scene back over their ends. It is drawn BEFORE them (their priorities are 0 to 2); the shine (no screen read) is drawn in front, clear of their strip
	_air_lite = ShaderMaterial.new()
	_air_lite.shader = preload("res://render/vfx/shaders/clash_air_lite.gdshader")
	_air_lite.render_priority = -4
	_air = MeshInstance3D.new()
	_air.mesh = quad
	_air.material_override = _air_lite
	_air.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_air)
	_glow = MeshInstance3D.new()
	_glow.mesh = quad
	_glow.material_override = _glow_mat
	_glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_glow)
	visible = false


## Both materials built and their shaders compiled once, hidden, at boot: the first clash's frame would otherwise pay for three shader compiles.
func warm_materials() -> Array:
	return [_glow_mat, _air_full, _air_lite]


## Whether the distortion (the screen read) is in use for this hub quality.
func uses_screen(quality: int) -> bool:
	if screen_read >= 0:
		return screen_read == 1
	return quality > VfxLook.Q_LOW


## One frame. c: the sim's clash (S.game.clash, or null); a_pos and d_pos: the two beams' origins in the view's x and the world's y; m: the meeting point; mz: its depth; mid: the point along the line (0 at A, 1 at D;
## the glide's own, or Encounter's `Clash.mid`); ck: the clash's rise and fall (0 to 1); calm: the register refused the bright form, or reduced flashing; z: the view's zoom; host: the SimHost (its hub's struggle model
## and quality), null in a tool.
func update(S: SimState, c, a_pos: Vector2, d_pos: Vector2, m: Vector2, mz: float, mid: float, ck: float, calm: bool, z: float, host = null) -> void:
	if c == null or not VfxClashLook.on():
		visible = false
		_clash = null
		VfxBeamStruggle.press_ck = 0.0
		return
	if c != _clash:
		_clash = c
		_bursts.clear()
		_seen.clear()
	var hub = host.vfx if host != null else null
	var sk = hub.struggle if hub != null else null
	var quality: int = hub.quality if hub != null else VfxLook.Q_HIGH
	var soft: bool = calm or (hub != null and (hub.reduced_motion or hub.reduced_flashing))
	var sa: Dictionary = VfxClashLook.side(c.A, String(c.A.aura))
	var sd: Dictionary = VfxClashLook.side(c.D, String(c.D.aura))
	var on_struggle: bool = sk != null and sk.active
	var lead: float = sk.push if on_struggle else clampf((mid - 0.5) * 2.0, -1.0, 1.0)
	var knot: float = sk.knot_level if on_struggle else smoothstep(0.0, 0.8, S.T - c.t0) * 0.5
	var R: float = VfxClashLook.radius_of(sa["power"], sd["power"]) * (1.0 + 0.15 * knot) + 30.0 / maxf(z, 0.05)
	visible = true
	position = Vector3(m.x, m.y, RenderLook.Z_BEAMS + VfxClashLook.fp("z_off") + mz)      # behind the beams' own prisms (z_off below 0): the two heads press in front of the air, not under it
	scale = Vector3(R, R, R)
	var ax: Vector2 = d_pos - a_pos
	ax = ax.normalized() if ax.length() > 0.001 else Vector2.RIGHT
	var ka: Vector2 = Vector2(a_pos.x - m.x, a_pos.y - 38.0 + VfxClashLook.fp("keep_y") - m.y) / R
	var kd: Vector2 = Vector2(d_pos.x - m.x, d_pos.y - 38.0 + VfxClashLook.fp("keep_y") - m.y) / R
	var kr: float = VfxClashLook.fp("keep_r") / R
	if sk != null and on_struggle:
		_bursts = VfxClashLook.plan_bursts(sk.waves, sk.clock, S.T, VfxBeamStruggle.p("wave_ticks"), SimConst.DT, _bursts, _seen, VfxClashLook.fp("burst_gap_calm") if soft else VfxClashLook.fp("burst_gap"), VfxClashLook.fp("burst_s"), 0.5)
	else:
		_bursts.clear()
		_seen.clear()
	# The shine is drawn in front of the beams but keeps clear of their strip through the point, which widens as the heads flare: it lies on the air beside the pressed heads, never over them (`strip_k` 0 puts it over again)
	var bw: float = (26.0 + maxf(float(c.A.tier), float(c.D.tier)) * 8.0) * 1.25
	var strip_hw: float = bw * (1.0 + 0.8 * VfxClashLook.pp("flare_k") * ck) / R
	var screen: bool = uses_screen(quality)
	_air.material_override = _air_full if screen else _air_lite
	var age: float = S.T - c.t0
	var envelope: float = smoothstep(0.0, maxf(VfxClashLook.fp("rise_s"), 0.05), age) * (1.0 - smoothstep(c.dur - VfxClashLook.fp("fall_s"), c.dur, age))   # up over `rise_s` and down over `fall_s`: slower than the beams' own, so the air never steps
	var strength: float = minf(ck, envelope) * (VfxClashLook.fp("calm_strength") if soft else 1.0)
	var life: float = VfxClashLook.fp("burst_s")
	var b0: Vector4 = Vector4(-1.0, 0.0, 0.0, 0.0)
	var b1: Vector4 = Vector4(-1.0, 0.0, 0.0, 0.0)
	var live: Array = _bursts.filter(func(bu): return S.T >= float(bu["t0"]) and S.T - float(bu["t0"]) <= life)
	if live.size() > 0:
		var bu0 = live[live.size() - 1]
		b0 = Vector4((S.T - float(bu0["t0"])) / life, float(bu0["amp"]) * VfxClashLook.fp("burst_amp"), float(bu0["side"]), 0.0)
	if live.size() > 1:
		var bu1 = live[live.size() - 2]
		b1 = Vector4((S.T - float(bu1["t0"])) / life, float(bu1["amp"]) * VfxClashLook.fp("burst_amp"), float(bu1["side"]), 0.0)
	var mix: Color = VfxClashLook.mix_tint(sa["tint_a"], sd["tint_a"])
	var seed_v: float = float((String(sa["key"]) + String(sd["key"])).hash() % 1000) * 0.013
	var ring_hz: float = VfxClashLook.fp("ring_hz_calm") if soft else VfxClashLook.fp("ring_hz")
	var front_hz: float = VfxClashLook.fp("front_hz") * (0.7 if soft else 1.0)
	var distort: float = VfxClashLook.fp("distort_calm") if soft else VfxClashLook.fp("distort")
	for mat in [_glow_mat, _air_full if screen else _air_lite]:
		mat.set_shader_parameter("ca0", sa["tint_a"])
		mat.set_shader_parameter("ca1", sa["tint_b"])
		mat.set_shader_parameter("cd0", sd["tint_a"])
		mat.set_shader_parameter("cd1", sd["tint_b"])
		mat.set_shader_parameter("acc_a", sa["accent"])
		mat.set_shader_parameter("acc_d", sd["accent"])
		mat.set_shader_parameter("cmix", mix)
		mat.set_shader_parameter("axis", ax)
		mat.set_shader_parameter("strength", strength)
		mat.set_shader_parameter("time", S.T)
		mat.set_shader_parameter("lead", lead)
		mat.set_shader_parameter("lean", VfxClashLook.fp("lean"))
		mat.set_shader_parameter("pwr_a", float(sa["power"]))
		mat.set_shader_parameter("pwr_d", float(sd["power"]))
		mat.set_shader_parameter("look_a", Vector4(float(sa["front"]), float(sa["texture"]), float(sa["scale"]), float(sa["ring_k"])))
		mat.set_shader_parameter("look_d", Vector4(float(sd["front"]), float(sd["texture"]), float(sd["scale"]), float(sd["ring_k"])))
		mat.set_shader_parameter("spike", Vector2(float(sa["spike_k"]), float(sd["spike_k"])))
		mat.set_shader_parameter("ring_n", VfxClashLook.fp("ring_n"))
		mat.set_shader_parameter("ring_n_pp", VfxClashLook.fp("ring_n_per_power"))
		mat.set_shader_parameter("ring_hz", ring_hz)
		mat.set_shader_parameter("front_hz", front_hz)
		mat.set_shader_parameter("knot", knot)
		mat.set_shader_parameter("core_r", VfxClashLook.fp("core_r"))
		mat.set_shader_parameter("core_pk", VfxClashLook.fp("core_per_knot"))
		mat.set_shader_parameter("glow", VfxClashLook.fp("glow"))
		mat.set_shader_parameter("glow_cap", VfxClashLook.fp("glow_cap"))
		mat.set_shader_parameter("lighten", VfxClashLook.fp("lighten"))
		mat.set_shader_parameter("spikes", VfxClashLook.fp("spikes"))
		mat.set_shader_parameter("spikes_pp", VfxClashLook.fp("spikes_per_power"))
		mat.set_shader_parameter("distort", distort)
		mat.set_shader_parameter("lens", VfxClashLook.fp("lens"))
		mat.set_shader_parameter("keep_a", Vector4(ka.x, ka.y, kr, 0.0))
		mat.set_shader_parameter("keep_d", Vector4(kd.x, kd.y, kr, 0.0))
		mat.set_shader_parameter("bst0", b0)
		mat.set_shader_parameter("bst1", b1)
		mat.set_shader_parameter("seed", seed_v)
		mat.set_shader_parameter("strip", Vector4(strip_hw, 0.0, VfxClashLook.fp("strip_k"), 0.0))
	VfxBeamStruggle.press_ck = strength if ck > 0.0 else 0.0
	VfxBeamStruggle.press_pow = [float(sa["power"]), float(sd["power"])]
	VfxBeamStruggle.press_calm = soft
	VfxBeamStruggle.press_quality = quality
	VfxBeamStruggle.press_seed = [seed_v, seed_v + 7.3]
	last = {"a": sa, "d": sd, "lead": lead, "knot": knot, "radius": R, "screen": screen, "bursts": live.size(), "soft": soft, "strength": strength, "ring_hz": ring_hz, "front_hz": front_hz}
