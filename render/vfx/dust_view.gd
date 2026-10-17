class_name VfxDustView
extends MultiMeshInstance3D
## The tremor's dust curtains for one pane (docs/vfx/catastrophe-plan.md section 5): at most 160 soft sprites of warm grey (shaders/dust.gdshader) spread across the visible slice, standing on
## the ground and rising with the tremor's envelope (tremor.gd), one MultiMesh and one draw call, behind the fighters' plane. A child of the trail view, like the shots view. Reads only.
## The alpha of each sprite is small on purpose: the sprites overlap, and the layout is built so that the sum of every overlap in any column is at most `alpha_max` (0.5): `unit_alpha` and
## `worst_column` are what effects_check holds it to. No rhythm: a slow wander and a small irregular shiver of incommensurate slow sines (both off in the calm form and in Reduced motion).

const CAP: int = 160
const STRIDE: int = 20
const SOFT: float = 0.44           # the share of a sprite's box its soft profile covers on average, over x and over the heights the curtains stand at: measured by worst_column

var _buf := PackedFloat32Array()
var count: int = 0
var tint: Color = Color.WHITE


func _ready() -> void:
	var q := QuadMesh.new()
	q.size = Vector2.ONE
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	mm.mesh = q
	mm.instance_count = CAP
	mm.visible_instance_count = 0
	mm.custom_aabb = AABB(Vector3(-40000.0, -12000.0, -300.0), Vector3(80000.0, 60000.0, 600.0))
	multimesh = mm
	var m := ShaderMaterial.new()
	m.shader = preload("res://render/vfx/shaders/dust.gdshader")
	m.render_priority = 0
	material_override = m
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_buf.resize(CAP * STRIDE)
	tint = Color(String(VfxTremor.p("colour")))


## How many sprites for a quality level (0 low, 1 medium, 2 high).
static func sprites_for(quality: int) -> int:
	var a: Array = VfxTremor.p("sprites")
	return mini(int(a[clampi(quality, 0, 2)]), CAP)


## The alpha one full-strength sprite takes so that the layout's overlaps sum to at most alpha_max: the expected number of sprites over a column is n times the mean width over the span, and the
## alpha is set for 1.6 times that (a margin for the hash's clumps), so a column of `k` overlaps reaches 1 - (1 - a)^k <= alpha_max.
static func unit_alpha(n: int, half_w: float) -> float:
	var wk: Array = VfxTremor.p("width_k")
	var mean_w: float = 0.5 * (float(wk[0]) + float(wk[1])) * 0.1 * half_w          # width_k is a tenth of half_w
	var span: float = half_w * 1.15
	var over: float = maxf(1.0, ceil(1.1 * SOFT * float(n) * mean_w / (2.0 * span)))
	return 1.0 - pow(1.0 - float(VfxTremor.p("alpha_max")), 1.0 / over)


## One sprite of the layout: {vx (view x), w, h, a (its alpha at full strength, before the envelope and the shiver), z, col (brightness), seed, ph1, ph2}. Pure: the same inputs, the same sprite.
static func sprite(i: int, n: int, half_w: float, seed: int) -> Dictionary:
	var hk: Array = VfxTremor.p("height_k")
	var wk: Array = VfxTremor.p("width_k")
	var zr: Array = VfxTremor.p("z")
	var span: float = half_w * 1.15
	var h1: float = VfxTremor.hash01(i, seed)
	return {
		"vx": ((float(i) + h1 * 0.9) / float(n) - 0.5) * 2.0 * span,
		"w": lerpf(float(wk[0]), float(wk[1]), VfxTremor.hash01(i, seed + 11)) * 0.1 * half_w,
		"h": lerpf(float(hk[0]), float(hk[1]), VfxTremor.hash01(i, seed + 12)) * half_w,
		"m": 0.55 + 0.45 * VfxTremor.hash01(i, seed + 13),                          # this sprite's share of the unit alpha
		"z": lerpf(float(zr[0]), float(zr[1]), VfxTremor.hash01(i, seed + 14)),
		"col": 0.92 + 0.16 * VfxTremor.hash01(i, seed + 15),
		"seed": VfxTremor.hash01(i, seed + 16),
		"ph1": VfxTremor.hash01(i, seed + 17) * TAU,
		"ph2": VfxTremor.hash01(i, seed + 18) * TAU,
	}


## The most opacity any point of the layout reaches at full strength: 1 minus the product of (1 - alpha times the shader's soft profile) over every sprite that covers the point, sampled over `cols`
## columns and three heights above the ground (at 0.15, 0.4 and 0.7 of the mean sprite height, where the curtains are thickest), the profile being the shader's own (full out to a quarter of the
## half size, a smoothstep to nothing at the edge, the quad's height stretched by 1.35). The check holds it to alpha_max.
static func worst_column(n: int, half_w: float, seed: int, cols: int = 96) -> float:
	var ua: float = unit_alpha(n, half_w)
	var sp: Array = []
	for i in range(n):
		sp.append(sprite(i, n, half_w, seed))
	var hk: Array = VfxTremor.p("height_k")
	var mean_h: float = 0.5 * (float(hk[0]) + float(hk[1])) * half_w
	var span: float = half_w * 1.15
	var worst: float = 0.0
	for c in range(cols):
		var x: float = ((float(c) + 0.5) / float(cols) - 0.5) * 2.0 * span
		for fy in [0.15, 0.4, 0.7]:
			var y: float = fy * mean_h
			var keep: float = 1.0
			for s in sp:
				var ux: float = (x - float(s["vx"])) / (float(s["w"]) * 0.5)
				var uy: float = (y - float(s["h"]) * 0.5) / (float(s["h"]) * 0.5)
				var r: float = sqrt(ux * ux + 1.35 * 1.35 * uy * uy)
				if r < 1.0:
					keep *= 1.0 - ua * float(s["m"]) * (1.0 - smoothstep(0.25, 1.0, r))
			worst = maxf(worst, 1.0 - keep)
	return worst


## cam_x: this pane's wrapped camera x; half_w: half the visible width in world units. calm: the register's reduced mode (Reduce flashing or Reduced motion).
func update(hub: VfxHub, host: SimHost, cam_x: float, half_w: float) -> void:
	var tr: VfxTremor = hub.tremor
	var calm: bool = hub.flashes.reduced
	var env: float = tr.strength(calm) if tr.active() else 0.0
	if env <= 0.002:
		multimesh.visible_instance_count = 0
		count = 0
		return
	var n: int = sprites_for(hub.quality)
	var ua: float = unit_alpha(n, half_w)
	var seed: int = int(tr.runs[tr.runs.size() - 1]["seed"])
	var t: float = float(tr.now) / 60.0
	var still: bool = calm or hub.reduced_motion
	var wander: float = 0.0 if still else float(VfxTremor.p("wander"))
	var shiver: float = 0.0 if still else float(VfxTremor.p("shiver"))
	var env_h: float = pow(env, 0.7)
	for i in range(n):
		var s: Dictionary = sprite(i, n, half_w, seed)
		var vx: float = float(s["vx"]) + wander * float(s["w"]) * 0.25 * sin(t * 0.31 + float(s["ph1"])) * sin(t * 0.17 + float(s["ph2"]))
		var xw: float = SimWrap.wrap(cam_x + vx)
		var g: float = WorldTerrain.groundY(host.S, xw)
		var h: float = float(s["h"]) * env_h
		var sh: float = 1.0 + shiver * sin(t * 0.83 + float(s["ph1"])) * sin(t * 1.37 + float(s["ph2"]))
		var a: float = ua * float(s["m"]) * env * sh
		var c: Color = Color(tint.r * float(s["col"]), tint.g * float(s["col"]), tint.b * float(s["col"]), a)
		_put(i, Vector2(vx, g + h * 0.5), float(s["w"]), maxf(h, 4.0), float(s["z"]), c, float(s["seed"]))
	count = n
	multimesh.visible_instance_count = n
	multimesh.buffer = _buf


func _put(i: int, c: Vector2, sx: float, sy: float, z: float, col: Color, sd: float) -> void:
	var o: int = i * STRIDE
	_buf[o] = sx
	_buf[o + 1] = 0.0
	_buf[o + 2] = 0.0
	_buf[o + 3] = c.x
	_buf[o + 4] = 0.0
	_buf[o + 5] = sy
	_buf[o + 6] = 0.0
	_buf[o + 7] = c.y
	_buf[o + 8] = 0.0
	_buf[o + 9] = 0.0
	_buf[o + 10] = 1.0
	_buf[o + 11] = z
	_buf[o + 12] = col.r
	_buf[o + 13] = col.g
	_buf[o + 14] = col.b
	_buf[o + 15] = col.a
	_buf[o + 16] = sd
	_buf[o + 17] = 0.0
	_buf[o + 18] = 0.0
	_buf[o + 19] = 0.0
