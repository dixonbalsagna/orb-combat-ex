extends SceneTree
## The skeleton capsule read (docs/animation/capsule-read.md; render/anim/anim_capsules.gd). Headless: no picture. It stages a fighter standing, flying, dashing, launched and turning, in a beam struggle and through a transformation,
## draws him through the real FighterView, and measures every vertex of the mannequin's mesh (as skinned, then put through the shader's own projection) against the union of the ten capsules, in world units (a fighter is
## about 75 tall). A vertex outside by more than the part's bound fails. Cloth (the pack and the sashes) is not body and is not measured. It also asserts that reading changes no sim hash and no pose.
##     bash tools/godot-run.sh --path . --script res://render/anim/tools/capsule_check.gd
const DT: float = 1.0 / 60.0
## how far outside the union a part of the body may be drawn: the hands' flat fists and the feet's toes stick out of a round capsule, the shoulders' plates sit between the torso and the arm
const BOUND := {"head": 1.5, "torso": 4.5, "arm": 1.5, "hand": 3.5, "leg": 2.0, "foot": 4.0}
const PART := {"head": "head", "neck": "torso", "pelvis": "torso", "spine_1": "torso", "spine_2": "torso", "clavicle_l": "torso", "clavicle_r": "torso",
	"upper_arm_l": "arm", "upper_arm_r": "arm", "forearm_l": "arm", "forearm_r": "arm", "hand_l": "hand", "hand_r": "hand", "fingers_l": "hand", "fingers_r": "hand",
	"thigh_l": "leg", "thigh_r": "leg", "shin_l": "leg", "shin_r": "leg", "foot_l": "foot", "foot_r": "foot"}
var fails: Array = []
var checks: int = 0
var main: Node


func _initialize() -> void:
	RenderAnim.is_enabled()
	DirData.templatesProfile = "dynamic"
	var vp := SubViewport.new()
	vp.size = Vector2i(1280, 720)
	root.add_child(vp)
	main = load("res://render/main.tscn").instantiate()
	main.manual = true
	vp.add_child(main)
	_run.call_deferred()


func _expect(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		fails.append(what)


func _run() -> void:
	for who in [0, 1]:
		_poses(who)
	_pane()
	_no_anim()
	for f in fails:
		print("FAIL ", f)
	print("capsule check %s (%d checks)" % ["passed" if fails.is_empty() else "FAILED", checks])
	quit(0 if fails.is_empty() else 1)


## A match, 30 ticks in, then one fighter staged and drawn through a view of its own.
func _poses(slot: int) -> void:
	main.start_match(4, {"p1": false, "p2": false})
	for i in range(30):
		main.frame(DT)
	var S: SimState = main.host.S
	var f = S.fighters[slot]
	var o = S.fighters[1 - slot]
	var holder := Node3D.new()
	root.add_child(holder)
	var view := FighterView.new()
	holder.add_child(view)
	view.build(f)
	view.flashes_on = false
	var caps := AnimCapsules.Caps.new()
	var cams := {"level": Basis.IDENTITY, "pitched": Basis(Vector3.RIGHT, deg_to_rad(-9.0))}
	var tick: int = 8000
	var f_slot: int = slot
	# [name, ticks, face, a per-tick setter]
	var poses: Array = [
		["standing", 40, 1.0, func(_k): f.state = "free"; f.vx = 0.0; f.vy = 0.0; f.y = WorldWater.floorAt(S, f.x)],
		["standing, mirrored", 40, -1.0, func(_k): f.state = "free"; f.vx = 0.0; f.vy = 0.0; f.y = WorldWater.floorAt(S, f.x)],
		["flying", 40, 1.0, func(_k): f.state = "free"; f.vx = 500.0; f.vy = 60.0; f.y = WorldWater.floorAt(S, f.x) + 600.0],
		["dashing", 30, -1.0, func(_k): f.state = "free"; f.vx = -2200.0; f.vy = -300.0; f.y = WorldWater.floorAt(S, f.x) + 900.0],
		["charging", 40, 1.0, func(_k): f.state = "charging"; f.vx = 0.0; f.vy = 0.0; f.y = WorldWater.floorAt(S, f.x)],
		["launched, turning", 50, 1.0, func(k): f.state = "launched"; f.vx = -900.0; f.vy = 300.0; f.spin = 7.0; f.rot = 0.12 * k; f.y = WorldWater.floorAt(S, f.x) + 700.0],
		["struggling, losing", 70, 1.0, func(_k): f.state = "free"; f.vx = 0.0; f.vy = 0.0; f.rot = 0.0; f.spin = 0.0; f.y = WorldWater.floorAt(S, f.x); _clash(S, o, f, 0.9)],
		["struggling, winning", 70, 1.0, func(_k): f.state = "free"; f.y = WorldWater.floorAt(S, f.x); _clash(S, f, o, 0.9)],
		# the whole transformation as play runs it: inside the sim's pause, whose own ticks are its clock (gather 60, break 30, settle 90)
		["transforming", 180, 1.0, func(k): f.state = "free"; S.game.clash = null; f.y = WorldWater.floorAt(S, f.x); S.pause.actor = f_slot; S.pause.left = 180 - k; if k == 0: RenderAnim.fighter(S, f).on_transform(S.T, "full")],
	]
	for row in poses:
		var worst: Dictionary = {}
		var at: Dictionary = {}
		var seen_ticks: int = 0
		var moved: bool = false
		var staged: bool = false     # the pose was really on: the launch spun the pivot, the struggle's dig-in or lean ran, the transformation played
		var size := Vector2.ZERO
		f.face = row[2]
		o.x = SimWrap.wrap(f.x + 180.0 * float(row[2]))
		for k in range(int(row[1])):
			tick += 1
			S.tick = tick
			S.T = float(tick) / 60.0
			(row[3] as Callable).call(k)
			var te := SimState.FxEvent.new()
			te.type = "tick"
			te.dt = DT
			te.frozen = false
			RenderAnim.consume(S, [te])
			view.update(S, f, Vector3(f.x, f.y, f.rot), 120.0, 1.0)
			if k % 5 != 4:
				continue
			var af: AnimFighter = RenderAnim.fighter(S, f)
			var h0: String = str(SimHash.stateHash(S).gameplay)
			var q0: Array = af.q.duplicate()
			for cn in cams:
				var cam: Basis = cams[cn]
				AnimCapsules.read(view, cam, 0.0, caps)
				var got: Dictionary = _outside(view, caps, cam)
				for p in got:
					if float(got[p]) > float(worst.get(p, -1.0)):
						worst[p] = got[p]
						at[p] = "tick %d, %s camera" % [k, cn]
			seen_ticks += 1
			size = size.max(caps.box.size)
			match String(row[0]):
				"launched, turning": staged = staged or absf(view.pivot.rotation.z) > 0.5
				"struggling, losing": staged = staged or af._str_w > 0.5
				"struggling, winning": staged = staged or af._str_lead > 0.5
				"transforming": staged = staged or not af._form.is_empty()
				_: staged = true
			if str(SimHash.stateHash(S).gameplay) != h0 or af.q != q0:
				moved = true
		S.game.clash = null
		S.pause.left = 0
		var line: Array = []
		for p in BOUND:
			line.append("%s %.1f" % [p, float(worst.get(p, 0.0))])
			_expect(float(worst.get(p, 0.0)) <= float(BOUND[p]), "slot %d, %s: the %s is drawn %.1f outside the capsules (%.1f at most; %s)" % [slot, row[0], p, float(worst.get(p, 0.0)), float(BOUND[p]), at.get(p, "")])
		_expect(seen_ticks > 0 and not moved, "slot %d, %s: reading changed the sim hash or the pose" % [slot, row[0]])
		_expect(staged, "slot %d, %s: the pose never came on, so it was not measured" % [slot, row[0]])
		print("slot %d %-20s outside, worst: %s; box up to %s" % [slot, row[0], ", ".join(line), str(size.round())])
	holder.queue_free()


func _clash(S: SimState, a, d, mid: float) -> void:
	if S.game.clash == null or S.game.clash.A != a:
		var c := SimState.Clash.new()
		c.A = a
		c.D = d
		c.t0 = S.T
		c.dur = 30.0
		S.game.clash = c
	S.game.clash.mid = mid


## Every body vertex as it is drawn (skinned on one bone, then the shader's projection) against the capsules' union: the worst distance outside, per part.
func _outside(view: FighterView, caps: AnimCapsules.Caps, cam: Basis) -> Dictionary:
	var body: AnimBody = view.anim_body
	var arr: Array = body.mi.mesh.surface_get_arrays(0)
	var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var bs: PackedInt32Array = arr[Mesh.ARRAY_BONES]
	var per: int = bs.size() / vs.size()
	var xf: Transform3D = body.skel.global_transform
	var pose: Array = []
	var part: Array = []
	for i in range(AnimRig.N):
		pose.append(xf * body.skel.get_bone_global_pose(i) * Transform3D(Basis.IDENTITY, -AnimRig.rest_global[i]))
		part.append(PART.get(String(AnimRig.BONES[i][0]), ""))
	var worst: Dictionary = {}
	for k in range(vs.size()):
		var bi: int = bs[k * per]
		var p: String = part[bi]
		if p == "":
			continue
		var d: Vector2 = AnimCapsules.project((pose[bi] as Transform3D) * vs[k], caps.anchor, cam, 0.0)
		var best: float = INF
		for i in range(AnimCapsules.N):
			var s: Vector4 = caps.seg[i]
			var a := Vector2(s.x, s.y)
			var ab := Vector2(s.z, s.w) - a
			var h: float = clampf((d - a).dot(ab) / maxf(ab.length_squared(), 1.0e-6), 0.0, 1.0)
			best = minf(best, (d - a - ab * h).length() - caps.rad[i])
		best = maxf(best, 0.0)
		if best > float(worst.get(p, -1.0)):
			worst[p] = best
	return worst


## The call VFX makes: a slot of a real pane, in a live match on the default ground.
func _pane() -> void:
	main.start_match(7, {"p1": false, "p2": false})
	for i in range(120):
		main.frame(DT)
	var S: SimState = main.host.S
	var pane: PaneWorld = main.pane
	var caps := AnimCapsules.Caps.new()
	var h0: String = str(SimHash.stateHash(S).gameplay)
	var line: Array = []
	for slot in range(S.fighters.size()):
		var ok: bool = AnimCapsules.read_slot(pane, slot, caps)
		var v: FighterView = pane.fighter_views[slot]
		_expect(ok == v.visible, "pane, slot %d: ok is %s with the view %s" % [slot, str(ok), "shown" if v.visible else "hidden"])
		if not ok:
			continue
		var size: Vector2 = caps.box.size
		var mid: Vector2 = caps.box.get_center()
		_expect(caps.anchor.is_equal_approx(v.pivot.global_position) and mid.length() < 60.0 and size.x > 10.0 and size.x < 130.0 and size.y > 10.0 and size.y < 130.0,
			"pane, slot %d: the capsules are not round the body (middle %s, size %s)" % [slot, str(mid), str(size)])
		var nan: bool = false
		for i in range(AnimCapsules.N):
			nan = nan or is_nan(caps.seg[i].x) or is_nan(caps.seg[i].w) or not (caps.rad[i] > 1.0)
		_expect(not nan, "pane, slot %d: a capsule is NaN or has no radius" % slot)
		line.append("slot %d box %s at %s, globe_r %.0f" % [slot, str(size.round()), str(mid.round()), pane.mats._globe_r])
	_expect(str(SimHash.stateHash(S).gameplay) == h0, "pane: reading changed the sim hash")
	_expect(not AnimCapsules.read_slot(pane, 9, caps) and not caps.ok, "pane: a slot that is not there reads as ok")
	var t0: int = Time.get_ticks_usec()
	for k in range(500):
		AnimCapsules.read_slot(pane, 0, caps)
	print("pane: %s; %.1f us a read" % ["; ".join(line), float(Time.get_ticks_usec() - t0) / 500.0])


## With animation off there is no skeleton: a plain standing outline, still ten capsules round the figure.
func _no_anim() -> void:
	var was: bool = RenderAnim.enabled
	RenderAnim.enabled = false
	main.start_match(4, {"p1": false, "p2": false})
	for i in range(10):
		main.frame(DT)
	var S: SimState = main.host.S
	var holder := Node3D.new()
	root.add_child(holder)
	var view := FighterView.new()
	holder.add_child(view)
	view.build(S.fighters[0])
	view.update(S, S.fighters[0], Vector3(0.0, 0.0, 0.0), 0.0, 1.0)
	var caps := AnimCapsules.Caps.new()
	var ok: bool = AnimCapsules.read(view, Basis.IDENTITY, 0.0, caps)
	_expect(ok and view.anim_body == null and caps.box.size.y > 60.0 and caps.box.size.y < 100.0, "animation off: no plain standing outline (ok %s, box %s)" % [str(ok), str(caps.box)])
	print("animation off: box %s" % str(caps.box.size.round()))
	holder.queue_free()
	RenderAnim.enabled = was
