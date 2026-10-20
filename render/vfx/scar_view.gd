class_name VfxScarView
extends MultiMeshInstance3D
## The scars the beams leave in the air for one pane (render/vfx/beam_scar.gd, shaders/beam_scar.gdshader, docs/vfx/beam-scar.md): one quad along each beam's line, one MultiMesh and one draw call,
## in the world behind the fighters' plane (a scar never covers a fighter: Orb, nothing obscures the fighters). A child of the trail view, like the shots view. Reads only.

const CAP: int = 12
const STRIDE: int = 20
const Z_BACK: float = -3.0          # behind the fighters' plane (0), in front of the dust and the terrain

var _buf := PackedFloat32Array()
var count: int = 0                  # for the tests: scars written last frame


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
	m.shader = preload("res://render/vfx/shaders/beam_scar.gdshader")
	m.render_priority = 0
	m.set_shader_parameter("heal_s", VfxBeamScar.p("heal_s"))
	m.set_shader_parameter("cell", VfxBeamScar.p("cell"))
	m.set_shader_parameter("cool_s", VfxBeamScar.p("cool_s"))
	m.set_shader_parameter("grow_s", VfxBeamScar.p("grow_s"))
	m.set_shader_parameter("alpha_core", VfxBeamScar.p("alpha_core"))
	m.set_shader_parameter("alpha_rim", VfxBeamScar.p("alpha_rim"))
	m.set_shader_parameter("dark", VfxBeamScar.p("dark"))
	material_override = m
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_buf.resize(CAP * STRIDE)


## cam_x: this pane's wrapped camera x; zoom: its pixels per unit on the fighters' plane.
func update(hub: VfxHub, cam_x: float, zoom: float) -> void:
	var sc: VfxBeamScar = hub.scars
	var n: int = 0
	for s in sc.list:
		if n >= CAP:
			break
		if s.reach < 2.0:
			continue
		var hw: float = VfxBeamScar.half_width(s, zoom)
		var hwmax: float = hw / 0.8
		var a := Vector2(SimWrap.sdx(cam_x, s.ox), s.oy)
		var u := Vector2(s.ux, s.uy)
		var side := Vector3(u.y, -u.x, 0.0)
		var dir := Vector3(u.x * s.reach, u.y * s.reach, s.zs * s.reach)
		var l3: float = dir.length()
		var dn: Vector3 = dir / l3
		var bz: Vector3 = side.cross(dn)
		var c := Vector3(a.x + dir.x * 0.5, a.y + dir.y * 0.5, Z_BACK + s.oz + dir.z * 0.5)
		var bx: Vector3 = dn * l3
		var by: Vector3 = side * (2.0 * hwmax)
		var col: Color = VfxAura.lane_color(s.hex)
		var rim: float = clampf(VfxBeamScar.p("rim_px") / maxf(zoom * hwmax, 0.05), 0.04, 0.6)
		var age0: float = sc.clock - VfxBeamScar.burn_time(s, 0.0)
		var slope: float = maxf(s.life - 0.4, 0.05) / maxf(s.len, 1.0)
		_put(n, bx, by, bz, c, Color(col.r, col.g, col.b, rim), Color(age0, slope, s.seed, s.reach))
		n += 1
	count = n
	multimesh.visible_instance_count = n
	if n > 0:
		multimesh.buffer = _buf


func _put(i: int, bx: Vector3, by: Vector3, bz: Vector3, c: Vector3, col: Color, cu: Color) -> void:
	var o: int = i * STRIDE
	_buf[o] = bx.x
	_buf[o + 1] = by.x
	_buf[o + 2] = bz.x
	_buf[o + 3] = c.x
	_buf[o + 4] = bx.y
	_buf[o + 5] = by.y
	_buf[o + 6] = bz.y
	_buf[o + 7] = c.y
	_buf[o + 8] = bx.z
	_buf[o + 9] = by.z
	_buf[o + 10] = bz.z
	_buf[o + 11] = c.z
	_buf[o + 12] = col.r
	_buf[o + 13] = col.g
	_buf[o + 14] = col.b
	_buf[o + 15] = col.a
	_buf[o + 16] = cu.r
	_buf[o + 17] = cu.g
	_buf[o + 18] = cu.b
	_buf[o + 19] = cu.a
