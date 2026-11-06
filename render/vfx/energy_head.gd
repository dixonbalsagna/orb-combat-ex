class_name VfxEnergyHeads
extends MultiMeshInstance3D
## The heads and the impact shrapnel of one pane's blasts and charged shots in the beam's own language (docs/vfx/energy-language.md; Orb 2026-11-01: "all energy should be consistent"): one MultiMesh and one draw call on
## shaders/energy_head.gdshader, each head a short shape (wedge, needle, lens, jagged slug, capsule: never a ball, a disc or a hoop, Legal RL-225) in its fighter's lane and second tint, with his texture, from the same
## composition the clash uses (VfxClashLook.side: his energy style, form and power). The shots view (shots_view.gd) feeds it between `begin()` and `finish()`, a frame at a time; it holds no state and draws no random number.
## Off unless the hub's `energy_heads_enabled` is on: the shots view then draws its rim, body and core discs as before.

const CAP := 96
const HALO_L := 1.25     # the quad's length over the shape's: it runs on past the head (the halo ahead of it)
const HALO_W := 1.7      # and its width over the shape's (energy_head.gdshader holds the same two)
const STRIDE := 20

var count: int = 0
var _buf := PackedFloat32Array()
var _mat: ShaderMaterial


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
	mm.custom_aabb = AABB(Vector3(-40000.0, -12000.0, -100.0), Vector3(80000.0, 40000.0, 200.0))
	multimesh = mm
	_mat = ShaderMaterial.new()
	_mat.shader = preload("res://render/vfx/shaders/energy_head.gdshader")
	_mat.render_priority = 2
	material_override = _mat
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_buf.resize(CAP * STRIDE)


## The preview's page word: `?heads=1` on a local page (where UI honours its bypass words) turns the heads on. Off the web, with no word, or on a public page: false, and nothing is read.
static func page_on() -> bool:
	if not OS.has_feature("web") or not UiHud.bypass_allowed():
		return false
	for pair in str(JavaScriptBridge.eval("location.search", true)).trim_prefix("?").split("&", false):
		var kv: PackedStringArray = pair.split("=", true, 1)
		if kv[0] == "heads" and not (kv.size() > 1 and (kv[1] == "0" or kv[1] == "false")):
			return true
	return false


func begin() -> void:
	count = 0


## One head: c the centre (this view's x, the world's y), dir the unit direction of flight (tail to head), l its length and w its width in world units, z its depth, `side` the composition (VfxClashLook.side), a its alpha.
func add(c: Vector2, dir: Vector2, l: float, w: float, z: float, side: Dictionary, a: float, seed: float) -> void:
	if count >= CAP:
		return
	var ca: Color = side["tint_a"]
	var cb: Color = side["tint_b"]
	var dh: float = fposmod(cb.h - ca.h + 0.5, 1.0) - 0.5
	var o: int = count * STRIDE
	var l2: float = l * HALO_L
	var w2: float = w * HALO_W
	var c2: Vector2 = c + dir * (l2 - l) * 0.5       # the shape stays where it was; the quad grows ahead of it
	_buf[o] = dir.x * l2
	_buf[o + 1] = -dir.y * w2
	_buf[o + 2] = 0.0
	_buf[o + 3] = c2.x
	_buf[o + 4] = dir.y * l2
	_buf[o + 5] = dir.x * w2
	_buf[o + 6] = 0.0
	_buf[o + 7] = c2.y
	_buf[o + 8] = 0.0
	_buf[o + 9] = 0.0
	_buf[o + 10] = 1.0
	_buf[o + 11] = z
	_buf[o + 12] = ca.r
	_buf[o + 13] = ca.g
	_buf[o + 14] = ca.b
	_buf[o + 15] = a
	_buf[o + 16] = dh
	_buf[o + 17] = float(side["front"]) + 8.0 * float(side["texture"])
	_buf[o + 18] = seed
	_buf[o + 19] = float(side["power"])
	count += 1


func finish(t: float) -> void:
	multimesh.visible_instance_count = count
	if count > 0:
		multimesh.buffer = _buf
		_mat.set_shader_parameter("time", t)


## The shape's size from the fighter's front, in multiples of the shot's radius: (length, width).
static func size_of(front: int, rad: float, scale: float) -> Vector2:
	match front:
		0:
			return Vector2(3.4, 2.4) * rad * scale        # a short thick wedge
		1:
			return Vector2(5.2, 1.5) * rad * scale        # a needle
		2:
			return Vector2(4.2, 1.5) * rad * scale        # a slim lens
		3:
			return Vector2(3.6, 2.4) * rad * scale        # a jagged slug
	return Vector2(3.0, 1.8) * rad * scale                # a capsule


## How many pieces an impact throws, by front: a pressure fan, a sheaf of lances, a few long arcs, a scatter of scrap.
static func burst_n(front: int) -> int:
	match front:
		0:
			return 5
		1:
			return 8
		2:
			return 3
		3:
			return 6
	return 4
