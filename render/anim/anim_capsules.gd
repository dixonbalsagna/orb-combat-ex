class_name AnimCapsules
extends RefCounted
## The skeleton capsule read (docs/animation/capsule-read.md; the Look Profile spec, section 6): ten capsules round the body a pane is drawing, for the energy shader to hang its outline on. READ ONLY: it reads the pane's
## FighterView and its Skeleton3D (the pose actually written to the mesh this frame, on twos included) and writes nothing but the caller's own `Caps`. No sim state is read or written.
##
##     var caps := AnimCapsules.Caps.new()                      # one per fighter per pane, kept
##     AnimCapsules.read_slot(pane, slot, caps)                  # after the pane's fighters are updated (VfxLayer.update is)
##     caps.seg[i] = (ax, ay, bx, by), caps.rad[i]               # world units from caps.anchor, in the camera's right and up: what the body's own shader draws (ortho.gdshaderinc)
##
## The numbers below are the rig's own (anim_rig.gd `_parts`; a shin's lower end sits 2.5 forward of the ankle, into the foot): an end is a bone and an offset in it, the radius is the mesh's half-width, elliptical for the head and the torso (their depth and their breadth differ, so
## the radius follows how far the body is turned to the camera).

const N: int = 10
enum { HEAD, TORSO, UPPER_ARM_L, FOREARM_L, UPPER_ARM_R, FOREARM_R, THIGH_L, SHIN_L, THIGH_R, SHIN_R }
## [bone of end a, offset in it, bone of end b, offset in it, half-width along the bone's x (front to back), along its z (side to side)]
const SPEC: Array = [
	["head", Vector3(0, 4.0, 0), "head", Vector3(0, 8.0, 0), 6.8, 5.8],
	["pelvis", Vector3(0, 2.0, 0), "spine_2", Vector3(0, 7.0, 0), 6.8, 10.5],
	["upper_arm_l", Vector3.ZERO, "forearm_l", Vector3.ZERO, 3.5, 3.5],
	["forearm_l", Vector3.ZERO, "fingers_l", Vector3(0, -3.0, 0), 3.2, 3.2],
	["upper_arm_r", Vector3.ZERO, "forearm_r", Vector3.ZERO, 3.5, 3.5],
	["forearm_r", Vector3.ZERO, "fingers_r", Vector3(0, -3.0, 0), 3.2, 3.2],
	["thigh_l", Vector3.ZERO, "shin_l", Vector3.ZERO, 4.3, 4.3],
	["shin_l", Vector3.ZERO, "foot_l", Vector3(2.5, 0, 0), 3.3, 3.3],
	["thigh_r", Vector3.ZERO, "shin_r", Vector3.ZERO, 4.3, 4.3],
	["shin_r", Vector3.ZERO, "foot_r", Vector3(2.5, 0, 0), 3.3, 3.3],
]


## What a read fills. `seg` and `rad` go straight into shader uniforms (vec4 [10], float [10]).
class Caps:
	var ok: bool = false                 # false: there is no body to wrap (no view, or it is not shown): draw nothing
	var seg := PackedVector4Array()      # per capsule (ax, ay, bx, by): offsets from `anchor` in the camera's right and up, world units, as the body is drawn
	var rad := PackedFloat32Array()      # per capsule, world units
	var anchor := Vector3.ZERO           # the body's projection anchor (the pivot), pane world: the shader's `anchor`
	var box := Rect2()                   # round all ten, radii included, in the same offsets: size the effect's rectangle from it (plus the aura's reach)
	var a := PackedVector3Array()        # the ends in pane world space BEFORE the projection (for anything that is placed in the world instead)
	var b := PackedVector3Array()

	func _init() -> void:
		seg.resize(AnimCapsules.N)
		rad.resize(AnimCapsules.N)
		a.resize(AnimCapsules.N)
		b.resize(AnimCapsules.N)


## SPEC unpacked once, so a read does no lookups by name: bone indices, offsets, half-widths.
static var _bone_a := PackedInt32Array()
static var _bone_b := PackedInt32Array()
static var _off_a := PackedVector3Array()
static var _off_b := PackedVector3Array()
static var _rx := PackedFloat32Array()
static var _rz := PackedFloat32Array()


static func _setup() -> void:
	if not _bone_a.is_empty():
		return
	AnimRig.setup()
	for c in SPEC:
		_bone_a.append(int(AnimRig.index[c[0]]))
		_off_a.append(c[1])
		_bone_b.append(int(AnimRig.index[c[2]]))
		_off_b.append(c[3])
		_rx.append(c[4])
		_rz.append(c[5])


## The capsules of the fighter in `slot` as this pane draws him. The pane's camera and ground mode are read from the pane.
static func read_slot(pane: PaneWorld, slot: int, out: Caps) -> bool:
	if pane == null or slot < 0 or slot >= pane.fighter_views.size():
		out.ok = false
		return false
	return read(pane.fighter_views[slot], pane.cam_rig.global_transform.basis, pane.mats._globe_r, out)


## The capsules of one view (a staged match's other bodies have views too). `cam_basis` is the camera's, `globe_r` the tile ground's radius (0 on the strip ground).
static func read(view: FighterView, cam_basis: Basis, globe_r: float, out: Caps) -> bool:
	out.ok = view != null and view.is_inside_tree() and view.visible
	if not out.ok:
		return false
	_setup()
	var body: AnimBody = view.anim_body
	var skel: Skeleton3D = body.skel if body != null else null
	# model space to the pane's world: position, depth and sag, the launch spin, the turn and the mirror, the body's yaw
	var xf: Transform3D = skel.global_transform if skel != null else view.body.global_transform * Transform3D(Basis.IDENTITY, Vector3(0.0, -FighterView.PIVOT_Y, 0.0))
	var scale: float = xf.basis.x.length()
	var inv: Basis = xf.basis.inverse()
	var right: Vector3 = cam_basis.x.normalized()
	var up: Vector3 = cam_basis.y.normalized()
	var look: Vector3 = cam_basis.z.normalized()       # toward the camera
	var anchor: Vector3 = view.pivot.global_position
	out.anchor = anchor
	var sag0: float = _globe_sag(anchor, globe_r) if globe_r > 0.0 else 0.0
	var low_x: float = INF
	var low_y: float = INF
	var high_x: float = -INF
	var high_y: float = -INF
	var last: int = -1            # a limb's capsules share joints: the bone just read is kept
	var last_t := Transform3D.IDENTITY
	for i in range(N):
		var ia: int = _bone_a[i]
		var ib: int = _bone_b[i]
		var ta: Transform3D = last_t if ia == last else (skel.get_bone_global_pose(ia) if skel != null else Transform3D(Basis.IDENTITY, AnimRig.rest_global[ia]))
		var tb: Transform3D = ta if ib == ia else (skel.get_bone_global_pose(ib) if skel != null else Transform3D(Basis.IDENTITY, AnimRig.rest_global[ib]))
		last = ib
		last_t = tb
		var wa: Vector3 = xf * (ta * _off_a[i])
		var wb: Vector3 = xf * (tb * _off_b[i])
		out.a[i] = wa
		out.b[i] = wb
		var r: float = _rx[i]
		var rz: float = _rz[i]
		if r != rz:
			# the half-width across the capsule on screen: an ellipse in the bone's own x and z
			var m: Vector3 = ta.basis.inverse() * (inv * look.cross(wb - wa))
			var mm: float = m.x * m.x + m.z * m.z
			r = sqrt((r * r * m.x * m.x + rz * rz * m.z * m.z) / mm) if mm > 1.0e-8 else (r + rz) * 0.5
		r *= scale
		out.rad[i] = r
		# `project`, inline
		var da: Vector3 = wa - anchor
		var db: Vector3 = wb - anchor
		if globe_r > 0.0:
			da.y -= _globe_sag(wa, globe_r) - sag0
			db.y -= _globe_sag(wb, globe_r) - sag0
		var ax: float = right.dot(da)
		var ay: float = up.dot(da)
		var bx: float = right.dot(db)
		var by: float = up.dot(db)
		out.seg[i] = Vector4(ax, ay, bx, by)
		low_x = minf(low_x, minf(ax, bx) - r)
		low_y = minf(low_y, minf(ay, by) - r)
		high_x = maxf(high_x, maxf(ax, bx) + r)
		high_y = maxf(high_y, maxf(ay, by) + r)
	out.box = Rect2(low_x, low_y, high_x - low_x, high_y - low_y)
	return true


## The CPU twin of ortho_clip's `d` (render/shaders/ortho.gdshaderinc): where a point of a fighter is drawn, as an offset from his anchor in the camera's right and up, in world units at the anchor's own scale.
static func project(w: Vector3, anchor: Vector3, cam_basis: Basis, globe_r: float) -> Vector2:
	var d: Vector3 = w - anchor
	if globe_r > 0.0:
		d.y -= _globe_sag(w, globe_r) - _globe_sag(anchor, globe_r)
	return Vector2(cam_basis.x.normalized().dot(d), cam_basis.y.normalized().dot(d))


static func _globe_sag(w: Vector3, r: float) -> float:
	return r * (1.0 - cos(w.x / r) * cos(w.z / r))
