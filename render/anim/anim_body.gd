class_name AnimBody
extends Node3D
## One view of a mannequin: a Skeleton3D and one rigid-skinned MeshInstance3D (plus the outline pass), in the model's own
## space (feet at the node's origin, facing +x). FighterView puts it in the body node, PANE by pane; the pose comes from
## a per-fighter AnimFighter that is solved once a frame and written to every pane's body. Render only.

var skel: Skeleton3D
var mi: MeshInstance3D
var _mat: ShaderMaterial      # the body (RenderMats.fighter_body); its next_pass is the outline (fighter_hull)
var _hull: ShaderMaterial
var _fingers_l: int
var _fingers_r: int
var _flash: float = 0.0
var _tint: Color = Color.WHITE   # the world's light on the body (see set_tint): white is no change by a pixel
var applied_version: int = -1   # the AnimFighter solve last written to this body (FighterView skips the bone writes when it has not changed)

## Palette keys: body, legs, arms, skin, gear, accent, hair (Colors). game true uses the hybrid projection (the game's
## fighters); false the plain perspective path (tools).
func build(pal: Dictionary, game: bool = true) -> void:
	AnimRig.setup()
	skel = AnimRig.make_skeleton()
	add_child(skel)
	mi = MeshInstance3D.new()
	mi.mesh = AnimRig.mesh_for(pal)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	skel.add_child(mi)
	mi.skin = skel.create_skin_from_rest_transforms()
	mi.skeleton = NodePath("..")
	_mat = RenderMats.fighter_body(Color.WHITE)
	_hull = _mat.next_pass
	if not game:
		_mat.set_shader_parameter("ortho", 0.0)
		_hull.set_shader_parameter("ortho", 0.0)
	mi.material_override = _mat
	_fingers_l = AnimRig.index["fingers_l"]
	_fingers_r = AnimRig.index["fingers_r"]


## Writes a solved pose: local rotations, the pelvis offset, the finger curl of each hand and a cosmetic root offset.
func apply(q: Array[Quaternion], hips: Vector3, curl: Vector2, root_off: Vector3 = Vector3.ZERO) -> void:
	for i in range(AnimRig.N):
		skel.set_bone_pose_rotation(i, q[i])
	skel.set_bone_pose_position(0, root_off)
	skel.set_bone_pose_position(1, AnimRig.rest_local[1] + hips)   # a bone pose is an absolute local transform, not an offset from rest
	skel.set_bone_pose_rotation(_fingers_l, q[_fingers_l] * Quaternion(Vector3(0, 0, 1), curl.x))
	skel.set_bone_pose_rotation(_fingers_r, q[_fingers_r] * Quaternion(Vector3(0, 0, 1), curl.y))


## The hybrid projection's anchor (world space), on both the body and its outline pass.
func set_anchor(a: Vector3) -> void:
	_mat.set_shader_parameter("anchor", a)
	_hull.set_shader_parameter("anchor", a)


## The world's light on the body: one multiply colour (white, the default, changes nothing: the shader's `tint`, which is white unless set, multiplies the body's own colour). The lane colour's parts (the forearms
## and sashes: the palette's `accent`, which FighterView sets to the aura colour or to the colour-vision preset's) carry a 0 alpha in the mesh, and the shader leaves them out of the tint; the outline (the keyline pass),
## the aura and every glow are other materials and are not tinted; the hit flash is not tinted either (the body is drawn untinted for the ticks it flashes). Rendering sets it each frame from its SkyDrive value.
func set_tint(c: Color) -> void:
	if c != _tint:
		_tint = c
		if _flash <= 0.0:
			_mat.set_shader_parameter("tint", c)


## A new palette on the same body (the colour-vision preset changing the lane colour, or a new outfit): the cached mesh of that palette, the skin and the bones as they are. FighterView sets the material's `skin`
## and `gear` from its own palette as it does at build.
func set_palette(pal: Dictionary) -> void:
	mi.mesh = AnimRig.mesh_for(pal)


## The hit flash (0 to 1). (Hidden fighters have no translucent variant on the baked body yet: hiding left the base game.)
func set_look(flash: float, _hidden: bool) -> void:
	if flash != _flash:
		_flash = flash
		_mat.set_shader_parameter("albedo", Color(1, 1, 1) if flash <= 0.0 else Color(8, 8, 8))
		_mat.set_shader_parameter("tint", _tint if flash <= 0.0 else Color.WHITE)   # a flash is never tinted
