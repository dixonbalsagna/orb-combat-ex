class_name VfxCloudView
extends MultiMeshInstance3D
## The blast cloud for one pane (docs/vfx/catastrophe-plan.md section 2; blast_cloud.gd has the rules): the body is this MultiMesh, at most 400 sprites in one draw call, and the fireball and the crater
## floor's glow are a second, additive MultiMesh of 16 (`core`), also one draw call. The sprites' instance data never changes after a layout is written: every position is a closed-form curve of
## the cloud's age in the vertex shader (shaders/cloud_curves.gdshaderinc), so the CPU writes a handful of uniforms a frame and rebuilds the buffer only when the sprite budget steps.
## The ladder (the fill rate is the cost): 400 sprites at high quality, 260 at medium, 140 at low, and 24 larger sprites when the cloud is far from the camera (an impostor of its silhouette).
## A child of the trail view, like the dust and shots views. Reads only. Draws nothing until a `blast_cloud` cue has landed.

const CAP: int = 400
const STRIDE: int = 20
const CORE_CAP: int = 16

var core := MultiMeshInstance3D.new()
var count: int = 0                  # the body's sprites drawn
var far: bool = false
var _sig: int = -1                  # the layout the buffer holds: n * 2 + far
var _buf := PackedFloat32Array()
var _cbuf := PackedFloat32Array()


func _ready() -> void:
	multimesh = _mm(CAP)
	var m := ShaderMaterial.new()
	m.shader = preload("res://render/vfx/shaders/cloud.gdshader")
	m.render_priority = 0
	_constants(m)
	material_override = m
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	core.name = "Core"
	core.multimesh = _mm(CORE_CAP)
	var cm := ShaderMaterial.new()
	cm.shader = preload("res://render/vfx/shaders/cloud_core.gdshader")
	cm.render_priority = 1
	_constants(cm)
	cm.set_shader_parameter("core_alpha", float(VfxBlastCloud.p("core_alpha")))
	core.material_override = cm
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(core)
	_buf.resize(CAP * STRIDE)
	_cbuf.resize(CORE_CAP * STRIDE)
	_write_core()


func _mm(n: int) -> MultiMesh:
	var q := QuadMesh.new()
	q.size = Vector2.ONE
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	mm.mesh = q
	mm.instance_count = n
	mm.visible_instance_count = 0
	mm.custom_aabb = AABB(Vector3(-60000.0, -12000.0, -300.0), Vector3(120000.0, 80000.0, 600.0))
	return mm


## The curve constants and the colours, from the data file (the same numbers the CPU mirror reads).
func _constants(m: ShaderMaterial) -> void:
	var sw: Array = VfxBlastCloud.p("stem_width")
	var sh: Array = VfxBlastCloud.p("skirt_height")
	m.set_shader_parameter("height_max", float(VfxBlastCloud.p("height_max")))
	m.set_shader_parameter("height_tau", float(VfxBlastCloud.p("height_tau_s")))
	m.set_shader_parameter("cap_major", float(VfxBlastCloud.p("cap_major")))
	m.set_shader_parameter("cap_major_tau", float(VfxBlastCloud.p("cap_major_tau_s")))
	m.set_shader_parameter("cap_minor", float(VfxBlastCloud.p("cap_minor")))
	m.set_shader_parameter("cap_minor_rise", float(VfxBlastCloud.p("cap_minor_rise_s")))
	m.set_shader_parameter("cap_omega", float(VfxBlastCloud.p("cap_omega")))
	m.set_shader_parameter("stem_w_top", float(sw[0]))
	m.set_shader_parameter("stem_w_base", float(sw[1]))
	m.set_shader_parameter("skirt_reach", float(VfxBlastCloud.p("skirt_reach")))
	m.set_shader_parameter("skirt_tau", float(VfxBlastCloud.p("skirt_tau_s")))
	m.set_shader_parameter("skirt_h_lo", float(sh[0]))
	m.set_shader_parameter("skirt_h_hi", float(sh[1]))
	m.set_shader_parameter("heat_tau_core", float(VfxBlastCloud.p("heat_tau_core_s")))
	m.set_shader_parameter("heat_tau_stem", float(VfxBlastCloud.p("heat_tau_stem_s")))
	m.set_shader_parameter("colour_hot", Color(String(VfxBlastCloud.p("colour_hot"))))
	m.set_shader_parameter("colour_amber", Color(String(VfxBlastCloud.p("colour_amber"))))
	m.set_shader_parameter("colour_ember", Color(String(VfxBlastCloud.p("colour_ember"))))
	m.set_shader_parameter("colour_smoke", Color(String(VfxBlastCloud.p("colour_smoke"))))


## How many sprites for a quality level (0 low, 1 medium, 2 high), or the impostor's when `is_far`.
static func sprites_for(quality: int, is_far: bool) -> int:
	if is_far:
		return int(VfxBlastCloud.p("far_sprites"))
	var a: Array = VfxBlastCloud.p("sprites")
	return mini(int(a[clampi(quality, 0, 2)]), CAP)


## The groups' sprite counts for a budget n: the stem a quarter to a third, the cap half, the ground wall the rest.
static func split(n: int) -> Array:
	var ns: int = int(round(float(n) * 0.3))
	var nc: int = int(round(float(n) * 0.5))
	return [ns, nc, n - ns - nc]


## The sprites of a layout, as [group, u, seed, jitter]: u runs 0 to 1 along each group (a hashed jitter inside each step), the seed and the jitter are hashes of the group and the index. Pure.
static func layout(n: int) -> Array:
	var out: Array = []
	var sp: Array = split(n)
	for g in range(3):
		var cnt: int = int(sp[g])
		for i in range(cnt):
			var u: float = (float(i) + VfxTremor.hash01(i, g * 101 + 7)) / float(maxi(cnt, 1))
			out.append([float(g), u, VfxTremor.hash01(i, g * 101 + 8), VfxTremor.hash01(i, g * 101 + 9)])
	return out


func _write(buf: PackedFloat32Array, i: int, g: float, u: float, sd: float, jt: float) -> void:
	var o: int = i * STRIDE
	for k in range(STRIDE):
		buf[o + k] = 0.0
	buf[o] = 1.0
	buf[o + 5] = 1.0
	buf[o + 10] = 1.0
	buf[o + 12] = 1.0
	buf[o + 13] = 1.0
	buf[o + 14] = 1.0
	buf[o + 15] = 1.0
	buf[o + 16] = g
	buf[o + 17] = u
	buf[o + 18] = sd
	buf[o + 19] = jt


func _write_core() -> void:
	var n: int = mini(int(VfxBlastCloud.p("core_sprites")), CORE_CAP - 4)
	for i in range(n):
		_write(_cbuf, i, 3.0, (float(i) + VfxTremor.hash01(i, 301)) / float(n), VfxTremor.hash01(i, 302), VfxTremor.hash01(i, 303))
	for i in range(4):
		_write(_cbuf, n + i, 4.0, (float(i) + 0.5) / 4.0, VfxTremor.hash01(i, 304), VfxTremor.hash01(i, 305))
	core.multimesh.buffer = _cbuf
	_core_n = n + 4


var _core_n: int = 0


## cam_x: this pane's wrapped camera x. The latest landed cloud is drawn.
func update(hub: VfxHub, _host: SimHost, cam_x: float) -> void:
	var bc: VfxBlastCloud = hub.blastcloud
	var r = null
	for run in bc.runs:
		if bc.now >= int(run["land"]) and bool(run["asked"]):
			r = run
	if r == null:
		multimesh.visible_instance_count = 0
		core.multimesh.visible_instance_count = 0
		count = 0
		return
	var t: float = bc.age_s(r)
	if t > float(VfxBlastCloud.p("life_s")) + 0.5:
		multimesh.visible_instance_count = 0
		core.multimesh.visible_instance_count = 0
		count = 0
		return
	var ox: float = SimWrap.sdx(cam_x, float(r["x"]))
	far = absf(ox) > float(VfxBlastCloud.p("far_distance"))
	var n: int = sprites_for(hub.quality, far)
	var sig: int = n * 2 + (1 if far else 0)
	if sig != _sig:
		_sig = sig
		var lay: Array = layout(n)
		for i in range(lay.size()):
			_write(_buf, i, float(lay[i][0]), float(lay[i][1]), float(lay[i][2]), float(lay[i][3]))
		multimesh.buffer = _buf
	count = n
	multimesh.visible_instance_count = n
	var sc: float = VfxBlastCloud.scale_of(float(r["amount"]))
	var m: ShaderMaterial = material_override
	var cm: ShaderMaterial = core.material_override
	var org := Vector2(ox, float(r["gy"]))
	var sk: float = float(VfxBlastCloud.p("far_size_k")) if far else 1.0
	for mm in [m, cm]:
		mm.set_shader_parameter("age", t)
		mm.set_shader_parameter("origin", org)
		mm.set_shader_parameter("scale", sc)
		mm.set_shader_parameter("size_k", sk)
		mm.set_shader_parameter("lit", 1.0 if bool(r["ok"]) else 0.0)
	m.set_shader_parameter("body_a", VfxBlastCloud.body_alpha(t))
	cm.set_shader_parameter("light", bc.light(r))
	cm.set_shader_parameter("core_radius", float(VfxBlastCloud.p("core_radius_k")) * VfxBlastCloud.cap_major(1.0e9, sc))
	core.multimesh.visible_instance_count = _core_n if bc.light(r) > 0.001 else 0
