class_name VfxShotsView
extends MultiMeshInstance3D
## Draws the energy blasts for one pane (shots.gd; Simulation's docs/architecture/shots.md): every live shot in S.shots each frame,
## interpolated, in its owner's lane colour; the charge on the hand while a charged shot is held; and the short effects the shot
## events call for (a hit's flash, a guard's splash, a deflect's ring, a trade's burst). One MultiMesh, one draw call, on the
## transformation's shader (a streak, a ring, a disc). Reads only; it is a child of the trail view (VfxTrailView), which the layer
## already updates every frame.
##
## A shot is a hard-edged cel disc in the lane colour with a darker rim and a lighter core (never white), a tapering tail behind
## it, and for a shot of power 2 or more a thin halo ring. A bolt is small with a short tail; a charged shot is bigger by its power
## and by its charge. A seeking shot is drawn on a slight arc that is zero at both ends (it leaves and arrives on its true line).
## A deflected shot is seen turning: the sim changes its owner and it flies back, and the colour changes with the owner. A shot that has
## been knocked loose (`deflected` above zero: the sim sends it off, today back at its first owner) also tumbles: a cross of light turning
## on it and a tail that wobbles, with the smoke trail (shots.gd) behind it. The mines of concept (shots.gd `Mine`, look only) are
## drawn here too, in the same draw call, each fighter's own look: the Anti-hero's plates, the others' thin rings.

const CAP := 380
const STRIDE := 20
const SHAPE_STREAK := 0.0
const SHAPE_RING := 1.0
const SHAPE_DISC := 2.0
const SHAPE_HEX := 4.0
const Z_SHOT := 4.0          # in front of the fighter plane, so a shot is not hidden behind a body it passes
const Z_FX := 6.0
const GLARE_HEAD_Y := 68.0   # a standing figure's head centre above its pose (the estimate used when the host has no `fighter_head`)
const GLARE_Z := 26.0        # in front of the face (Rendering's head flashes sit at 24)
const PLAY_LIFT := 30.0     # the beam plays sit in front of the ground dust (its puffs are put up to about z 26)
const Z_HAND := 5.0

var _buf := PackedFloat32Array()
var count: int = 0           # instances drawn last frame (the tests)
var shots_drawn: int = 0     # shots drawn last frame
var charges_drawn: int = 0   # fighters with a charge drawn last frame


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
	var m := ShaderMaterial.new()
	m.shader = preload("res://render/vfx/shaders/transform.gdshader")
	m.render_priority = 1
	material_override = m
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_buf.resize(CAP * STRIDE)


## a: the frame's interpolation between the last two ticks. host: anything with .S and fighter_x / fighter_pose / fighter_z (the
## pane's SimHost; a stub in the tests).
func update(hub: VfxHub, host, a: float, cam_x: float, zoom: float, half_w: float) -> void:
	var n: int = 0
	shots_drawn = 0
	charges_drawn = 0
	var S: SimState = host.S
	var bh: float = VfxLook.BH
	var minpx: float = 1.6 / maxf(zoom, 1e-6)
	var sh: VfxShots = hub.shots
	var alpha: float = VfxShots.p("shots", "alpha")
	var dt: float = SimConst.DT
	# The charge on the hand (behind the shots).
	for i in range(mini(2, S.fighters.size())):
		var c: VfxShots.Charge = sh.charges[i]
		var lvl: float = lerpf(c.prev, c.lvl, a)
		if lvl < 0.02 or n >= CAP - 16:
			continue
		var fx: float = host.fighter_x(i, a)
		var rel: float = SimWrap.sdx(cam_x, fx)
		if absf(rel) > half_w + 4.0 * bh:
			continue
		charges_drawn += 1
		n = _hand(n, S, host, i, c, lvl, rel, a, bh, minpx, alpha)
	# The shots in flight.
	var lim: float = half_w + 6.0 * bh
	var still: bool = sh.last_frozen
	for sp in S.shots:
		if n >= CAP - 24:
			break
		if int(sp.mode) == SimShots.MINE:
			continue          # a mine is not a shot in flight: it is drawn below, by its own look
		var rel: float = SimWrap.sdx(cam_x, sp.x)
		# Where it is at this frame: the state is the end of the last tick, so go back by what is left of the tick unless the shots
		# stood still (a hit-stop, a pause) or it was fired this tick.
		var back: Vector2 = shot_back(sp, a, still)
		var px: float = rel - back.x
		var py: float = sp.y - back.y
		if absf(px) > lim:
			continue
		var dirv: Vector2 = Vector2(sp.vx, sp.vy)
		# A seeking shot: a slight arc, zero at both ends.
		if int(sp.mode) == 1 and sp.total > 0:
			var prog: float = clampf(1.0 - (float(sp.left) + (0.0 if (still or sp.fresh) else 1.0 - a)) / float(sp.total), 0.0, 1.0)
			py += arc_y(prog, sp.total, bh)
			dirv.y += (arc_y(prog + 0.01, sp.total, bh) - arc_y(prog, sp.total, bh)) / (0.01 * maxf(float(sp.total) * dt, 1e-3))
		if dirv.length() < 1.0:
			dirv = Vector2(1.0, 0.0)
		dirv = dirv.normalized()
		var tumbling: bool = (int(sp.deflected) > 0 or bool(sp.wild)) and hub.explosions_enabled
		var spin: float = (float(sh.clock) + a) * 0.55 + float(sp.id)
		if tumbling and not hub.reduced_motion:
			dirv = dirv.rotated(sin(spin * 0.8) * 0.35)
		var pz: float = float(sp.z) + Z_SHOT
		var lane: Color = VfxShots.lane_of(S, int(sp.owner))
		var look: Dictionary = VfxShots.look_of(sp)
		var rad: float = look["rad"]
		var tail: float = look["tail"]
		shots_drawn += 1
		var tcol: Color = lane
		tcol.a = alpha * 0.8
		n = _put(n, Vector2(px, py) - dirv * tail * 0.5, dirv, tail, rad * 1.5, pz - 0.6, tcol, 0.55, 0.04, SHAPE_STREAK)
		if look["halo"]:
			var hc: Color = lane
			hc.a = alpha * 0.7
			n = _put(n, Vector2(px, py), Vector2(1.0, 0.0), rad * 3.0, rad * 3.0, pz - 0.3, hc, maxf(0.06, 1.6 * minpx / (rad * 1.5)), 0.0, SHAPE_RING)
		var rim: Color = lane.darkened(0.35)
		rim.a = alpha
		n = _put(n, Vector2(px, py), Vector2(1.0, 0.0), rad * 2.0, rad * 2.0, pz, rim, 1.0, 0.0, SHAPE_RING)
		var body: Color = lane
		body.a = alpha
		n = _put(n, Vector2(px, py), Vector2(1.0, 0.0), rad * 1.55, rad * 1.55, pz + 0.2, body, 1.0, 0.0, SHAPE_RING)
		var core: Color = lane.lightened(0.18)
		core.a = alpha
		n = _put(n, Vector2(px, py), Vector2(1.0, 0.0), rad * 0.8, rad * 0.8, pz + 0.4, core, 1.0, 0.0, SHAPE_RING)
		if tumbling:
			# Tumbling: a cross of light turning on it (still, at a slant, with reduced motion).
			var ang0: float = 0.6 if hub.reduced_motion else spin
			var xc: Color = lane.lightened(0.1)
			xc.a = alpha * 0.9
			n = _put(n, Vector2(px, py), Vector2(cos(ang0), sin(ang0)), rad * 3.4, rad * 0.5, pz + 0.5, xc, 1.0, 1.0, SHAPE_STREAK)
			n = _put(n, Vector2(px, py), Vector2(cos(ang0 + PI * 0.5), sin(ang0 + PI * 0.5)), rad * 2.2, rad * 0.4, pz + 0.5, xc, 1.0, 1.0, SHAPE_STREAK)
	# The beam plays: a crossing beam's head, the cues' effects, a walk or a wade in progress.
	if hub.beamplay_enabled:
		n = _beamplay(n, S, hub, host, cam_x, half_w, a, bh, minpx, alpha)
	# The melee press styles: each blow's after-image and contact look.
	if hub.press_enabled:
		n = _press(n, S, hub, host, cam_x, half_w, a, bh, minpx, alpha)
		n = _zip(n, S, hub, host, cam_x, half_w, a, bh, minpx, alpha)
		n = _reach(n, S, hub, host, cam_x, half_w, a, bh, minpx, alpha)
	# The rival's glasses glare, over his face.
	if hub.glare_enabled:
		n = _glare(n, S, hub, host, cam_x, half_w, a, bh, minpx)
	# The mines (concept).
	n = _mines(n, S, hub, sh, cam_x, half_w, a, bh, minpx, alpha)
	# The short effects the events call for.
	for e: VfxShots.Fx in sh.fx:
		if n >= CAP - 14:
			break
		var rx: float = SimWrap.sdx(cam_x, e.x)
		if absf(rx) > half_w + e.size * 2.0:
			continue
		var st: float = maxf(e.age - (1.0 - a), 0.0)
		var u: float = clampf(st / e.life, 0.0, 1.0)
		var ez: float = e.z + Z_FX
		var eo: float = 1.0 - pow(1.0 - u, 2.0)
		match e.kind:
			"flash":
				var fr: float = e.size * (0.45 + 0.55 * eo)
				var fc: Color = e.col
				fc.a = alpha * pow(1.0 - u, 1.3)
				n = _put(n, Vector2(rx, e.y), Vector2(1.0, 0.0), fr * 2.0, fr * 2.0, ez, fc, 1.0, 0.0, SHAPE_RING)
			"ring":
				var rr: float = lerpf(e.size * 0.35, e.size, eo)
				var rc: Color = e.col
				rc.a = alpha * 0.85 * pow(1.0 - u, 1.4)
				n = _put(n, Vector2(rx, e.y), Vector2(1.0, 0.0), rr * 2.0, rr * 2.0, ez + 0.2, rc, maxf(0.07, 1.6 * minpx / maxf(rr, 1.0)), 0.0, SHAPE_RING)
			"splash":
				# A fan of short lines running back toward the shooter off the guard.
				for k in range(5):
					var ang: float = (float(k) - 2.0) * 0.42
					var dv: Vector2 = Vector2(e.dx * cos(ang), sin(ang) + 0.15).normalized()
					var d0: float = e.size * (0.25 + 0.75 * eo)
					var ln: float = e.size * 0.55 * (1.0 - u * 0.6)
					var sc: Color = e.col.darkened(0.15)
					sc.a = alpha * 0.9 * (1.0 - u)
					n = _put(n, Vector2(rx, e.y) + dv * (d0 - ln * 0.5), dv, ln, maxf(6.0, minpx * 1.5), ez, sc, 0.5, 0.05, SHAPE_STREAK)
			"burst":
				# A trade: a ring in each colour and eight short lines out of the point.
				var br: float = lerpf(e.size * 0.3, e.size, eo)
				var c1: Color = e.col
				c1.a = alpha * 0.9 * pow(1.0 - u, 1.3)
				var c2: Color = e.col2
				c2.a = c1.a
				n = _put(n, Vector2(rx - 6.0, e.y), Vector2(1.0, 0.0), br * 2.0, br * 2.0, ez, c1, maxf(0.07, 1.6 * minpx / maxf(br, 1.0)), 0.0, SHAPE_RING)
				n = _put(n, Vector2(rx + 6.0, e.y), Vector2(1.0, 0.0), br * 1.7, br * 1.7, ez + 0.2, c2, maxf(0.07, 1.6 * minpx / maxf(br, 1.0)), 0.0, SHAPE_RING)
				for k in range(8):
					var an: float = TAU * float(k) / 8.0 + 0.2
					var dv2: Vector2 = Vector2(cos(an), sin(an))
					var d1: float = e.size * (0.2 + 0.8 * eo)
					var l2: float = e.size * 0.4 * (1.0 - u * 0.5)
					var lc: Color = c1 if k % 2 == 0 else c2
					n = _put(n, Vector2(rx, e.y) + dv2 * (d1 - l2 * 0.5), dv2, l2, maxf(6.0, minpx * 1.5), ez + 0.4, lc, 0.5, 0.05, SHAPE_STREAK)
	count = n
	multimesh.visible_instance_count = n
	if n > 0:
		multimesh.buffer = _buf


## The charge at the forearm of the arm toward the rival: plates stacking along it (the Anti-hero) or thin rings stacking along it
## (the others), more of them as the charge builds; a pulse ring along the forearm when it is full. Never a sphere in a palm.
func _hand(n: int, S: SimState, host, slot: int, c: VfxShots.Charge, lvl: float, rel: float, a: float, bh: float, minpx: float, alpha: float) -> int:
	var f = S.fighters[slot]
	var pose: Vector3 = host.fighter_pose(slot, a)
	var fz: float = host.fighter_z(slot, a)
	var face: float = float(f.face)
	var col: Color = VfxAura.lane_color(String(f.aura))
	var chest: Vector2 = Vector2(rel, pose.y + VfxLook.CHEST_Y)
	var elbow: Vector2 = chest + Vector2(face * 0.16 * bh, -0.10 * bh)
	var hand: Vector2 = chest + Vector2(face * 0.66 * bh, 0.0)
	var along: Vector2 = (hand - elbow).normalized()
	var perp: Vector2 = Vector2(-along.y, along.x)
	var pieces: int = 1 + int(floor(lvl * 5.0 + 0.001))
	var z: float = fz + Z_HAND
	for k in range(pieces):
		if n >= CAP - 8:
			break
		var t: float = (float(k) + 0.5) / 6.0 + 0.05
		var at: Vector2 = elbow.lerp(hand, t)
		var born: float = clampf(lvl * 5.0 - float(k) + 1.0, 0.0, 1.0)          # each arrives over a fifth of the charge
		var pc: Color = col
		pc.a = alpha * (0.5 + 0.5 * born)
		if c.look == "plates":
			# A short plate across the forearm.
			n = _put(n, at, perp, 0.2 * bh * (0.6 + 0.4 * born), 0.075 * bh, z, pc.darkened(0.15), 1.0, 1.0, SHAPE_STREAK)
			var edge: Color = col
			edge.a = alpha * born
			n = _put(n, at + along * 0.02 * bh, perp, 0.16 * bh * born, 0.03 * bh, z + 0.2, edge, 1.0, 1.0, SHAPE_STREAK)
		else:
			# A thin ring round the forearm, seen edge-on as a narrow ellipse across it.
			var rr: float = 0.13 * bh * (0.7 + 0.3 * born)
			n = _put(n, at, along, rr * 0.7, rr * 2.0, z, pc, maxf(0.09, 1.6 * minpx / rr), 0.0, SHAPE_RING)
	if c.full and c.on and c.pulse < 14.0:
		var u: float = c.pulse / 14.0
		var pr: float = lerpf(0.2, 0.55, 1.0 - pow(1.0 - u, 2.0)) * bh
		var qc: Color = col
		qc.a = alpha * 0.8 * (1.0 - u)
		n = _put(n, hand, along, pr * 0.7, pr * 2.0, z + 0.4, qc, maxf(0.07, 1.6 * minpx / pr), 0.0, SHAPE_RING)
	return n


## What is left of this tick's movement at the frame, as an offset to subtract from the state's position: the state is the end of the
## last tick, so a frame between two ticks is a fraction of a tick back along the velocity, unless the shots stood still (a hit-stop,
## a pause) or this one was fired this tick (it sits at its start).
static func shot_back(sp, a: float, still: bool) -> Vector2:
	if still or sp.fresh:
		return Vector2.ZERO
	return Vector2(sp.vx, sp.vy) * ((1.0 - a) * SimConst.DT)


## A seeking shot's arc: how far above its line it is at progress 0..1 of its flight (zero at both ends).
static func arc_y(prog: float, total: int, bh: float) -> float:
	var h: float = VfxShots.p("shots", "arc_bh") * bh * clampf(float(total) / 10.0, VfxShots.p("shots", "arc_min"), VfxShots.p("shots", "arc_max"))
	return h * sin(PI * clampf(prog, 0.0, 1.0))


## A hard-edged wedge: from base, along dir, length l, width w (narrow at the tip, wide at the back, brightest at the tip).
func _wedge(n: int, base: Vector2, dir: Vector2, l: float, w: float, z: float, col: Color) -> int:
	return _put(n, base + dir * (l * 0.5), dir, l, w, z, col, 0.04, 0.5, SHAPE_STREAK)


## A thin ring seen edge-on across dir: an ellipse short along dir (a share of its height) and size tall across it.
func _across(n: int, c: Vector2, dir: Vector2, size: float, along: float, z: float, col: Color, minpx: float) -> int:
	return _put(n, c, dir, size * along, size, z, col, maxf(0.05, 1.6 * minpx / maxf(size * 0.5, 1.0)), 0.0, SHAPE_RING)


## A thin line of uniform width t between two points (a streak at half-width 0.5 both ends: the quad's full height is twice the thickness).
func _line(n: int, a: Vector2, b: Vector2, t: float, z: float, col: Color) -> int:
	var d: Vector2 = b - a
	var l: float = d.length()
	if l < 0.01:
		return n
	return _put(n, (a + b) * 0.5, d / l, l, t * 2.0, z, col, 0.5, 0.5, SHAPE_STREAK)


## A body as a few strokes (a head, a torso, two legs and the striking arm): the prototype's figure. wire = a thin outline (the timed blow's echoes),
## else filled (a ghost). feet is where his feet are in this view; dir the way he faces; fist the striking hand's place in this view.
func _figure(n: int, feet: Vector2, dir: float, lean: float, fist: Vector2, col: Color, wire: bool, z: float, minpx: float, thick: float = 1.0) -> int:
	var t: float = maxf(1.7, minpx * 1.5) if wire else 3.2 * thick
	var hip := Vector2(feet.x, feet.y + VfxPress.HIP)
	var neck := Vector2(feet.x + dir * lean * 0.6, feet.y + VfxPress.SHOULDER + 4.0)
	var head := Vector2(feet.x + dir * lean, feet.y + VfxPress.HEAD_Y)
	if wire:
		n = _put(n, head, Vector2(1.0, 0.0), VfxPress.HEAD_R * 2.0, VfxPress.HEAD_R * 2.0, z, col, maxf(0.16, 2.0 * minpx / VfxPress.HEAD_R), 0.0, SHAPE_RING)
	else:
		n = _put(n, head, Vector2(1.0, 0.0), VfxPress.HEAD_R * 2.0 * thick, VfxPress.HEAD_R * 2.0 * thick, z, col, 1.0, 0.0, SHAPE_RING)
	n = _line(n, hip, neck, t * (1.0 if wire else 1.6), z, col)
	n = _line(n, hip, Vector2(feet.x - dir * 8.0, feet.y), t, z, col)
	n = _line(n, hip, Vector2(feet.x + dir * 10.0, feet.y), t, z, col)
	n = _line(n, Vector2(feet.x + dir * lean * 0.5, feet.y + VfxPress.SHOULDER), fist, t, z + 0.1, col)
	return n


func _dir_of(S: SimState, slot: int) -> float:
	var fc: float = float(S.fighters[slot].face)
	return fc if absf(fc) > 0.5 else 1.0


## A body from a real pose's joints (VfxPress.JOINTS order: Animation's press_pose through the rig's forward kinematics): a head ring, the spine, both arms and both
## legs as thin strokes. base is where the body's anchor (his feet) is in this view; joints are offsets from it. wire = an outline, else a filled ghost.
func _figure_j(n: int, base: Vector2, joints: PackedVector2Array, col: Color, wire: bool, z: float, minpx: float) -> int:
	if joints.size() < 16:
		return n
	var t: float = maxf(1.7, minpx * 1.5) if wire else 3.4
	var head: Vector2 = base + joints[0] + Vector2(0.0, 5.0)
	if wire:
		n = _put(n, head, Vector2(1.0, 0.0), VfxPress.HEAD_R * 2.0, VfxPress.HEAD_R * 2.0, z, col, maxf(0.16, 2.0 * minpx / VfxPress.HEAD_R), 0.0, SHAPE_RING)
	else:
		n = _put(n, head, Vector2(1.0, 0.0), VfxPress.HEAD_R * 2.0, VfxPress.HEAD_R * 2.0, z, col, 1.0, 0.0, SHAPE_RING)
	var tw: float = t if wire else t * 1.7
	n = _line(n, base + joints[3], base + joints[2], tw, z, col)
	n = _line(n, base + joints[2], base + joints[1], tw, z, col)
	n = _line(n, base + joints[1], head, tw * 0.8, z, col)
	for pair in [[4, 5], [5, 6], [7, 8], [8, 9], [10, 11], [11, 12], [13, 14], [14, 15]]:
		n = _line(n, base + joints[pair[0]], base + joints[pair[1]], t, z + 0.1, col)
	return n


## The press styles (press.gd): each blow's after-image and contact look by the way it was pressed. With Animation's hand-off (the blow's real earlier pose and the
## real path of the striking limb's tip) the echoes and ghosts are real poses and the blur, the line and the crescent follow the real fist; without it they are
## estimates (a stand-in figure and a straight guard-to-contact path).
func _press(n: int, S: SimState, hub: VfxHub, host, cam_x: float, half_w: float, a: float, bh: float, minpx: float, alpha: float) -> int:
	var pr: VfxPress = hub.press
	var al: float = alpha * VfxPress.p("alpha")
	pr.shown = 0
	var red: bool = hub.reduced_motion
	for e: VfxPress.Fx in pr.fx:
		if n >= CAP - 60:
			break
		var rx: float = SimWrap.sdx(cam_x, e.ax)
		if absf(rx) > half_w + 6.0 * bh:
			continue
		if e.age < 0.0:
			continue                              # a committed line waits for its last 6 ticks
		var st: float = maxf(e.age - (1.0 - a), 0.0)
		var u: float = clampf(st / e.life, 0.0, 1.0)
		var d: float = e.dir
		var fz: float = host.fighter_z(e.slot, a)
		var zb: float = fz + Z_FX - 12.0          # behind the fighter: the after-images
		var zf: float = fz + Z_FX + 8.0           # in front: the contact marks
		var feet := Vector2(rx, e.ay)
		var contact: Vector2 = feet + Vector2(e.cx, e.cy)
		var guard: Vector2 = feet + Vector2(d * VfxPress.GUARD.x, VfxPress.GUARD.y + (6.0 if e.hand == 1 else -2.0))
		# The fist's path: the real one when Animation gave it, else guard to contact.
		var pts: PackedVector2Array = PackedVector2Array()
		if e.path.size() >= 2:
			for q0 in e.path:
				pts.append(feet + q0)
		else:
			pts.append(guard)
			pts.append(contact)
		var start: Vector2 = pts[0]
		pr.shown += 1
		match e.style:
			"sureline":
				# A sure blow (it cannot be blocked or dodged): the limb's committed path, a thin hard line, in his lane colour, in the last 6 ticks before the contact.
				var sl: Color = e.col
				sl.a = al * 0.9 * (1.0 - 0.5 * u)
				n = _line(n, pts[0], pts[pts.size() - 1], maxf(1.6, minpx * 1.4), zf, sl)
			"brackets":
				# ... and four short corner ticks closing on the target's chest (18 units out to 10), hollow, lane colour: nothing to block, nothing to dodge.
				var bkc: Color = e.col
				bkc.a = al * (1.0 - u)
				var rb: float = lerpf(18.0, 10.0, u)
				for k in range(4):
					var cs := Vector2(1.0 if k % 2 == 0 else -1.0, 1.0 if k < 2 else -1.0)
					var cdir := Vector2(cs.x, cs.y).normalized()
					n = _put(n, contact + Vector2(cs.x * rb, cs.y * rb * 0.9), cdir, 9.0, 3.0, zf, bkc, 0.5, 0.5, SHAPE_STREAK)
			"revecho":
				# The sidestep out of a block: one wire echo of him where he was, popping off over 3 ticks; it trails him and never stands ahead.
				if not red:
					var rc: Color = e.col.darkened(0.3)
					rc.a = al * (1.0 - u)
					n = _figure(n, feet, d, 4.0, feet + Vector2(d * 20.0, 50.0), rc, true, zb + 0.2, minpx)
			"glint":
				# The beat's glint (the option UI's beat ring goes with): a small hard ring and a short streak on the striking limb's tip at the contact tick.
				var gr: float = lerpf(4.0, VfxPress.p("glint_r"), u)
				var gc2: Color = e.col2
				gc2.a = al * (1.0 - u)
				n = _put(n, contact, Vector2(1.0, 0.0), gr * 2.0, gr * 2.0, zf + 0.2, gc2, maxf(0.14, 2.4 * minpx / gr), 0.0, SHAPE_RING)
				var gd: Vector2 = (contact - pts[maxi(pts.size() - 2, 0)])
				if gd.length() > 0.5:
					n = _line(n, contact - gd.normalized() * 14.0, contact, maxf(1.4, minpx * 1.2), zf + 0.2, gc2)
			"speed":
				# A soft, filled, overlapping blur along the fist's path (layered soft discs and one wide soft streak), and a small round ring.
				var fade: float = 1.0 - u
				var bc: Color = e.col.darkened(0.15)
				bc.a = al * 0.55 * fade
				if not red:
					var nd: int = 6 if e.real else 5
					for k in range(nd):
						var f: float = float(k + 1) / float(nd)
						var fi: float = f * float(pts.size() - 1)
						var i0: int = mini(int(fi), pts.size() - 2)
						var pc: Vector2 = pts[i0].lerp(pts[i0 + 1], fi - float(i0))
						n = _put(n, pc, Vector2(1.0, 0.0), 18.0 + 14.0 * f, 18.0 + 14.0 * f, zb, bc, 1.0, 0.0, SHAPE_DISC)
				var sc: Color = e.col.darkened(0.15)
				sc.a = al * 0.45 * fade
				for k in range(pts.size() - 1):
					var seg: Vector2 = pts[k + 1] - pts[k]
					if seg.length() > 0.5:
						n = _put(n, (pts[k] + pts[k + 1]) * 0.5, seg.normalized(), seg.length() * 1.1, VfxPress.p("speed_w") * 2.0, zb - 0.2, sc, 0.9, 0.5, SHAPE_STREAK)
				var rr: float = lerpf(5.0, VfxPress.p("speed_ring_r"), 1.0 - pow(1.0 - clampf(st / VfxPress.p("speed_ring_life"), 0.0, 1.0), 2.0))
				var rc: Color = e.col2
				rc.a = al * (1.0 - clampf(st / VfxPress.p("speed_ring_life"), 0.0, 1.0))
				n = _put(n, contact, Vector2(1.0, 0.0), rr * 2.0, rr * 2.0, zf, rc, maxf(0.16, 3.4 * minpx / rr), 0.0, SHAPE_RING)
			"tech":
				# Echoes between the old pose and the strike (real earlier poses when we have them), popping off one at a time from the back to the front;
				# a thin straight speed line; a hard diamond.
				var pop: float = VfxPress.p("echo_pop")
				var ne: int = e.ghosts if e.ghosts > 0 else 3
				for g in range(ne):
					if red and g != ne - 1:
						continue
					if st >= 2.5 + float(g) * pop:
						continue
					var fr: float = float(g + 1) / float(ne + 1)
					var ec: Color = e.col.darkened(0.3)
					ec.a = al
					if e.real:
						var jj := PackedVector2Array()
						for k in range(e.ja.size()):
							jj.append(e.ja[k].lerp(e.jb[k], fr))
						n = _figure_j(n, Vector2(rx + lerpf(e.old_dx, 0.0, fr), e.ay), jj, ec, true, zf - 2.0 + 0.2 * float(g), minpx)
					else:
						var bx: float = -d * maxf(e.lunge, 24.0) * (1.0 - fr)
						var fist: Vector2 = guard.lerp(contact, fr)
						n = _figure(n, Vector2(feet.x + bx, feet.y), d, 4.0 + 10.0 * fr, Vector2(fist.x + bx, fist.y), ec, true, zf - 2.0 + 0.2 * float(g), minpx)
				var lc: Color = e.col.darkened(0.3)
				lc.a = al * 0.9 * (1.0 - clampf(st / VfxPress.p("line_life"), 0.0, 1.0))
				n = _line(n, start, pts[pts.size() - 1], maxf(1.3, minpx * 1.2), zf - 1.0, lc)
				var dl: float = VfxPress.p("diamond_life")
				if st < dl:
					var dr: float = lerpf(5.0, VfxPress.p("diamond_r"), clampf(st / 4.0, 0.0, 1.0))
					var dc: Color = e.col.darkened(0.3)
					dc.a = al * (1.0 - st / dl)
					n = _put(n, contact, Vector2(1.0, 0.0), dr * 2.0, dr * 2.0, zf, dc, maxf(0.2, 3.6 * minpx / dr), 0.0, 5.0)
			"heavy":
				# The release: stacked body ghosts behind him, a filled crescent along the fist's path, and a double contact ring.
				var gl: float = VfxPress.p("ghost_life")
				var gf: float = 1.0 - clampf(st / gl, 0.0, 1.0)
				if not red and gf > 0.0:
					var ng: int = mini(e.ghosts if e.ghosts > 0 else 3, 5)
					for k in range(ng):
						var fr2: float = float(k + 1) / float(ng + 1)
						var gc: Color = e.col
						gc.a = al * VfxZip.p("ghost_alpha") * float(k + 1) / float(ng) * gf   # one lane tint, 0.35 at most, fainter the older (Legal m05)
						if e.real:
							var jg := PackedVector2Array()
							for q1 in range(e.ja.size()):
								jg.append(e.ja[q1].lerp(e.jb[q1], fr2))
							n = _figure_j(n, Vector2(rx + lerpf(e.old_dx, 0.0, fr2), e.ay), jg, gc, false, zb + 0.1 * float(k), minpx)
						else:
							var bx2: float = -d * e.lunge * (1.0 - fr2) * 1.3
							n = _figure(n, Vector2(feet.x + bx2, feet.y), d, 16.0, Vector2(feet.x + bx2 + d * 30.0, feet.y + 56.0).lerp(contact, fr2), gc, false, zb + 0.1 * float(k), minpx)
				var cl: float = VfxPress.p("crescent_life")
				var cf: float = 1.0 - clampf(st / cl, 0.0, 1.0)
				var cc: Color = e.col
				cc.a = al * 0.75 * cf
				var arc := PackedVector2Array()
				if e.path.size() >= 3:
					arc = pts
				else:
					var back_pt: Vector2 = feet + Vector2(-d * 30.0, 60.0)
					var ctrl: Vector2 = (back_pt + contact) * 0.5 + Vector2(0.0, 34.0)
					arc.append(back_pt)
					var segs0: int = 3 if red else 5
					for k in range(segs0):
						var tq0: float = float(k + 1) / float(segs0)
						arc.append((1.0 - tq0) * (1.0 - tq0) * back_pt + 2.0 * (1.0 - tq0) * tq0 * ctrl + tq0 * tq0 * contact)
				var asegs: int = arc.size() - 1
				for k in range(asegs):
					var seg2: Vector2 = arc[k + 1] - arc[k]
					if seg2.length() < 0.3:
						continue
					var tq: float = (float(k) + 0.5) / float(asegs)
					var wq: float = 6.0 + 28.0 * sin(PI * tq)
					n = _put(n, (arc[k] + arc[k + 1]) * 0.5, seg2.normalized(), seg2.length() * 1.15, wq, zb + 0.3, cc, 0.6, 0.6, SHAPE_STREAK)
				var rl: float = VfxPress.p("ring_life")
				var rt: float = clampf((st - 2.0) / rl, 0.0, 1.0)
				if st >= 2.0 and rt < 1.0:
					var r1: float = lerpf(12.0, VfxPress.p("ring_r"), rt)
					var c1: Color = e.col.darkened(0.2)
					c1.a = al * (1.0 - rt)
					n = _put(n, contact, Vector2(1.0, 0.0), r1 * 2.0, r1 * 2.0, zf, c1, minf(0.5, 9.0 / r1), 0.0, SHAPE_RING)
					var r2: float = lerpf(6.0, VfxPress.p("ring_r") * 0.5, rt)
					n = _put(n, contact, Vector2(1.0, 0.0), r2 * 2.0, r2 * 2.0, zf + 0.1, c1, minf(0.5, 5.0 / r2), 0.0, SHAPE_RING)
			"block":
				# A shield line in front of the defender and a block flash. Never a knock-back (nothing here moves him).
				var sf: float = 1.0 - u
				var shc: Color = e.col
				shc.a = al * (0.35 + 0.5 * sf)
				var sh_h: float = VfxPress.p("shield_h")
				n = _put(n, contact, Vector2(0.0, 1.0), sh_h, maxf(1.4, minpx * 1.6) * 2.0, zf, shc, 0.5, 0.5, SHAPE_STREAK)
				var ft: float = clampf(st / VfxPress.p("flash_life"), 0.0, 1.0)
				if ft < 1.0:
					var fc: Color = e.col2
					fc.a = al * (1.0 - ft)
					var fr1: float = 10.0 + ft * 22.0
					n = _put(n, contact, Vector2(1.0, 0.0), fr1 * 2.0, fr1 * 2.0, zf + 0.1, fc, minf(0.5, 4.0 / fr1), 0.0, SHAPE_RING)
					var fr3: float = 5.0 + ft * 10.0
					n = _put(n, contact, Vector2(1.0, 0.0), fr3 * 2.0, fr3 * 2.0, zf + 0.1, fc, minf(0.5, 2.0 / fr3), 0.0, SHAPE_RING)
	# The heavy's wind-up: a ring that shrinks around the fist as the blow is charged.
	for s in range(mini(2, S.fighters.size())):
		var w: VfxPress.Wind = pr.wind[s]
		if not w.on or n >= CAP - 8:
			continue
		var wrx: float = SimWrap.sdx(cam_x, S.fighters[s].x)
		if absf(wrx) > half_w + 6.0 * bh:
			continue
		# Hollow, thin, lane colour, shrinking only, and only in the last 10 ticks of the wind-up (Legal m07).
		var wrem: float = 24.0 - (w.t + a)
		if wrem > VfxZip.p("ring_ticks"):
			continue
		var wk: float = clampf(1.0 - wrem / VfxZip.p("ring_ticks"), 0.0, 1.0)
		var wr: float = lerpf(VfxPress.p("wind_r"), 9.0, wk)
		var wc: Color = w.col
		wc.a = al * (0.3 + 0.6 * wk)
		var wd: float = _dir_of(S, s)
		n = _put(n, Vector2(wrx + wd * 20.0, S.fighters[s].y + 50.0), Vector2(1.0, 0.0), wr * 2.0, wr * 2.0, host.fighter_z(s, a) + Z_FX + 6.0, wc, minf(0.5, 2.2 / wr), 0.0, SHAPE_RING)
		pr.shown += 1
	# A heavy ender's target flies with ghosts behind him (the sim's knockback): the stretch is the ghosts' reach along the path.
	if not red:
		for s in range(mini(2, S.fighters.size())):
			if float(pr.fly[s]) <= 0.0 or n >= CAP - 24:
				continue
			var vx: float = SimWrap.sdx(cam_x, S.fighters[s].x)
			if absf(vx) > half_w + 6.0 * bh:
				continue
			var gz: float = host.fighter_z(s, a) + Z_FX - 12.0
			var vcol: Color = VfxPress.lane_of(S, s)
			for k in range(1, int(VfxPress.p("fly_ghosts")) + 1):
				var hp: Vector2 = pr.back(S, s, k * 4)
				var hrx: float = SimWrap.sdx(cam_x, hp.x)
				if absf(hrx - vx) < 6.0:
					continue
				var gcol: Color = vcol
				gcol.a = al * (0.34 - 0.09 * float(k))
				n = _figure(n, Vector2(hrx, hp.y), _dir_of(S, s), 6.0, Vector2(hrx + 10.0, hp.y + 52.0), gcol, false, gz - 0.1 * float(k), minpx)
			pr.shown += 1
	return n


## The lead hand's place in this view: Animation's real pose while a blow plays (the hand further toward the rival), else the guard fist estimate (a hand in front of the chest).
func _palm(S: SimState, slot: int, dir: float, gx: float, gy: float) -> Vector2:
	var af = VfxPress.anim_of(S, slot)
	if af != null and not af.press.is_empty() and af.press_ring.size() > 0:
		var js: PackedVector2Array = VfxPress.joints_of(af.press_pose(0), 1.0 if float(af.vface) >= 0.0 else -1.0)
		if js.size() >= 16:
			var hr: Vector2 = js[6]
			var hl: Vector2 = js[9]
			var hd: Vector2 = hr if hr.x * dir >= hl.x * dir else hl
			return Vector2(gx + hd.x, gy + hd.y)
	return Vector2(gx + dir * VfxReach.p("palm_x"), gy + VfxReach.p("palm_y"))


## Energy arts in reach and the launcher's marks (reach.gd; docs/vfx/reach.md). Every mark is a thin hollow ring, a thin line or a short streak in the shooter's lane colour: nothing is a filled
## ball at the hand, nothing is body-wide, and the one soft flash a landing may have is rationed by VfxReach.allow_full (one in each 20 ticks across both fighters).
func _reach(n: int, S: SimState, hub: VfxHub, host, cam_x: float, half_w: float, a: float, bh: float, minpx: float, alpha: float) -> int:
	var rc: VfxReach = hub.inreach
	var pr: VfxPress = hub.press
	var al: float = alpha * VfxReach.p("alpha")
	var red: bool = hub.reduced_motion
	rc.shown = 0
	for e: VfxReach.Fx in rc.fx:
		if n >= CAP - 40:
			break
		var st: float = maxf(e.age - (1.0 - a), 0.0)
		var u: float = clampf(st / e.life, 0.0, 1.0)
		var col: Color = e.col
		match e.style:
			"gather", "lit":
				var gx: float = SimWrap.sdx(cam_x, host.fighter_x(e.slot, a))
				if absf(gx) > half_w + 6.0 * bh:
					continue
				var gy: float = host.fighter_pose(e.slot, a).y
				var gz: float = host.fighter_z(e.slot, a) + Z_FX + 22.0
				var palm: Vector2 = _palm(S, e.slot, e.dir, gx, gy)
				rc.shown += 1
				if e.style == "gather":
					# The blast gathers into the palm: a thin ring closing onto it over the last 10 ticks, and three short streaks converging on it.
					var rem: float = e.life - st
					var gt: float = VfxReach.p("gather_ticks")
					if rem > gt:
						continue
					var k: float = 1.0 - rem / gt
					var r: float = lerpf(VfxReach.p("gather_r"), 7.0, k)
					col.a = al * (0.25 + 0.65 * k)
					n = _put(n, palm, Vector2(1.0, 0.0), r * 2.0, r * 2.0, gz, col, minf(0.5, 2.2 / r), 0.0, SHAPE_RING)
					var ed: Color = e.col.darkened(0.4)
					ed.a = col.a * 0.8
					n = _put(n, palm, Vector2(1.0, 0.0), r * 2.0 + 4.0, r * 2.0 + 4.0, gz - 0.1, ed, minf(0.5, 2.0 / (r + 2.0)), 0.0, SHAPE_RING)
					if not red:
						for i in range(3):
							var ang: float = float(i - 1) * 0.9
							var v := Vector2(e.dir * cos(ang), sin(ang))
							n = _put(n, palm + v * (r + 8.0), v, 9.0, 4.4, gz, col, 0.5, 0.5, SHAPE_STREAK)
				else:
					# A bolt's palm comes up with the blow: a small hollow ring and two short streaks forward, gone at the contact.
					var kk: float = clampf(st / maxf(e.life - 1.0, 1.0), 0.0, 1.0)
					var rr: float = lerpf(4.0, 9.0, kk)
					col.a = al * (0.4 + 0.6 * kk)
					n = _put(n, palm, Vector2(1.0, 0.0), rr * 2.0, rr * 2.0, gz, col, minf(0.5, 2.4 / rr), 0.0, SHAPE_RING)
					var ed2: Color = e.col.darkened(0.4)
					ed2.a = col.a * 0.8
					n = _put(n, palm, Vector2(1.0, 0.0), rr * 2.0 + 4.0, rr * 2.0 + 4.0, gz - 0.1, ed2, minf(0.5, 2.0 / (rr + 2.0)), 0.0, SHAPE_RING)
					if not red:
						n = _put(n, palm + Vector2(e.dir * 9.0, 3.0), Vector2(e.dir, 0.0), 14.0, 4.0, gz, col, 0.5, 0.5, SHAPE_STREAK)
						n = _put(n, palm + Vector2(e.dir * 7.0, -3.0), Vector2(e.dir, 0.0), 10.0, 3.0, gz, col, 0.5, 0.5, SHAPE_STREAK)
			"land":
				var lx: float = SimWrap.sdx(cam_x, e.x)
				if absf(lx) > half_w + 6.0 * bh:
					continue
				var c := Vector2(lx, e.y)
				var lz: float = host.fighter_z(e.vic, a) + Z_FX + 22.0
				var sc: float = 0.6 if e.guard else 1.0
				rc.shown += 1
				# The crack: two crossed thin lines, hard, the shot's own mark (the fist's smear and thud are the press look).
				var cl: float = (56.0 if e.blast else 34.0) * sc
				var glow: Color = e.col.lightened(0.45)
				glow.a = al * 0.75 * (1.0 - u * u)
				col = e.col.darkened(0.5)
				col.a = al * (1.0 - u * u)
				for sg in [1.0, -1.0]:
					n = _put(n, c, Vector2(0.707, 0.707 * sg), cl, 9.0 if e.blast else 7.0, lz - 0.05, glow, 0.5, 0.5, SHAPE_STREAK)
					n = _put(n, c, Vector2(0.707, 0.707 * sg), cl, 4.0 if e.blast else 3.0, lz, col, 0.5, 0.5, SHAPE_STREAK)
				# The ring: hollow, widening.
				var r0: float = (10.0 if e.blast else 6.0) * sc
				var r1: float = (36.0 if e.blast else 20.0) * sc
				var rg: float = lerpf(r0, r1, 1.0 - pow(1.0 - u, 2.0))
				var rcol: Color = e.col.darkened(0.15)
				rcol.a = al * (1.0 - u)
				n = _put(n, c, Vector2(1.0, 0.0), rg * 2.0, rg * 2.0, lz + 0.1, rcol, minf(0.5, 2.6 / rg), 0.0, SHAPE_RING)
				if e.big and st < VfxReach.p("flash_life"):
					# The full flash, rationed: one soft disc for 3 ticks (never over a body: it is the size of the contact).
					var fk: float = st / VfxReach.p("flash_life")
					var fs: float = (56.0 if e.blast else 38.0) * (1.0 - 0.4 * fk)    # it collapses as it fades: a flash, not an orb
					var fc: Color = e.col.lightened(0.3)
					fc.a = al * 0.42 * (1.0 - fk)
					n = _put(n, c, Vector2(1.0, 0.0), fs, fs, lz - 0.4, fc, 1.0, 0.0, SHAPE_DISC)
				elif not red or e.guard:
					# No full flash this time: sparks at the contact, three short streaks flying off.
					var scol: Color = e.col.lightened(0.3)
					scol.a = al * (1.0 - u)
					for i in range(3):
						var sa: float = float(i - 1) * 0.8
						var sv := Vector2(-e.dir * cos(sa), sin(sa))
						n = _put(n, c + sv * (8.0 + 14.0 * u), sv, 9.0, 3.0, lz + 0.2, scol, 0.5, 0.5, SHAPE_STREAK)
			"rim":
				var rx: float = SimWrap.sdx(cam_x, host.fighter_x(e.vic, a))
				if absf(rx) > half_w + 6.0 * bh:
					continue
				var ry: float = host.fighter_pose(e.vic, a).y
				var rz: float = host.fighter_z(e.vic, a) + Z_FX + 2.0
				var rcl: Color = e.col.lightened(0.3)
				rcl.a = al * VfxReach.p("rim_alpha") * (1.0 - u) * (0.6 if red else 1.0)
				rc.shown += 1
				n = _put(n, Vector2(rx + e.dir * 11.0, ry + 38.0), Vector2(0.0, 1.0), 52.0, 5.0, rz, rcl, 0.5, 0.5, SHAPE_STREAK)
			"spill":
				var ox: float = SimWrap.sdx(cam_x, e.x)
				if absf(ox) > half_w + 8.0 * bh:
					continue
				var oz: float = host.fighter_z(e.vic, a) + Z_FX + 6.0
				var offs: Array = [-0.42, -0.21, 0.0, 0.21, 0.42] if e.blast else [-0.05, 0.05]
				if red:
					offs = [-0.3, 0.0, 0.3] if e.blast else [0.0]
				var maxlen: float = (VfxReach.p("spill_blast_bh") if e.blast else VfxReach.p("spill_bolt_bh")) * bh
				var travel: float = maxlen * (1.0 - pow(1.0 - u, 2.0))
				var ll: float = 70.0 if e.blast else 36.0
				var tail: float = maxf(0.0, travel - ll)
				var scl: Color = e.col.lightened(0.25)
				scl.a = al * 0.9 * (1.0 - u)
				var o2 := Vector2(ox, e.y)
				rc.shown += 1
				for off in offs:
					var v2: Vector2 = e.lean.rotated(float(off))
					n = _line(n, o2 + v2 * (14.0 + tail), o2 + v2 * (14.0 + travel), 2.6 if e.blast else 2.0, oz, scl)
			"scorch":
				var zx: float = SimWrap.sdx(cam_x, e.x)
				if absf(zx) > half_w + 6.0 * bh:
					continue
				var rs: float = 30.0 if e.blast else 14.0
				var dk := Color(0.10, 0.08, 0.07, 0.38 * pow(1.0 - u, 1.5) * al)
				rc.shown += 1
				n = _put(n, Vector2(zx, e.y + 1.0), Vector2(1.0, 0.0), rs * 2.0, rs * 2.0 * 0.3, Z_FX - 2.0, dk, 1.0, 0.0, SHAPE_DISC)
			"carry", "send":
				var tx: float = SimWrap.sdx(cam_x, host.fighter_x(e.vic, a))
				if absf(tx) > half_w + 12.0 * bh:
					continue
				var tz: float = host.fighter_z(e.vic, a) + Z_FX + 8.0
				var segs: int = (3 if red else 5) if e.style == "carry" else (4 if red else 7)
				var w0: float = 12.0 if e.style == "carry" else 11.0
				var prev := Vector2(tx, host.fighter_pose(e.vic, a).y + 45.0)
				rc.shown += 1
				for i in range(1, segs + 1):
					var bp: Vector2 = pr.back(S, e.vic, i * 2)
					var cur := Vector2(SimWrap.sdx(cam_x, bp.x), bp.y + 45.0)
					var tcol: Color = e.col
					tcol.a = al * 1.0 * (1.0 - 0.7 * float(i - 1) / float(segs)) * (1.0 - u * u)
					n = _line(n, prev, cur, lerpf(w0, 2.0, float(i) / float(segs)), tz, tcol)
					prev = cur
				if e.style == "send":
					# The send-off: a flat ring on the ground where he left it, and three short streaks lifting off.
					var sx2: float = SimWrap.sdx(cam_x, e.x)
					var ring_r: float = lerpf(8.0, 42.0, 1.0 - pow(1.0 - u, 2.0))
					var qcol: Color = e.col
					qcol.a = al * 0.8 * (1.0 - u)
					n = _put(n, Vector2(sx2, e.y + 3.0), Vector2(1.0, 0.0), ring_r * 2.0, ring_r * 2.0 * 0.28, tz, qcol, minf(0.5, 3.0 / ring_r), 0.0, SHAPE_RING)
					if not red:
						for off2 in [-12.0, 0.0, 12.0]:
							n = _put(n, Vector2(sx2 + off2, e.y + 12.0 + 22.0 * u), Vector2(0.0, 1.0), 22.0 * (1.0 - u * 0.5), 3.0, tz, qcol, 0.5, 0.5, SHAPE_STREAK)
			"stagger":
				# B now, without a word: a chevron rising on each side of the staggered fighter, half a beat apart, in the attacker's colour, for as long as the stagger lasts.
				var vx: float = SimWrap.sdx(cam_x, host.fighter_x(e.vic, a))
				if absf(vx) > half_w + 6.0 * bh:
					continue
				var vy: float = host.fighter_pose(e.vic, a).y
				var vz: float = host.fighter_z(e.vic, a) + Z_FX + 24.0
				var per: float = VfxReach.p("chev_period")
				rc.shown += 1
				for k2 in range(2):
					var ph: float = fmod(st / per + 0.5 * float(k2), 1.0) if not red else (0.3 + 0.4 * float(k2))
					var y0: float = vy + 8.0 + ph * 40.0
					var ccol: Color = e.col.darkened(0.3)
					ccol.a = al * sin(PI * ph)
					var ecol: Color = e.col.lightened(0.5)
					ecol.a = ccol.a * 0.8
					var tw: float = maxf(3.0, minpx * 1.8)
					for pass_i in range(2):
						var pc: Color = ecol if pass_i == 0 else ccol
						var pw: float = tw * (2.0 if pass_i == 0 else 1.0)
						var cx0: float = vx + (-26.0 if k2 == 0 else 26.0)
						n = _line(n, Vector2(cx0 - 11.0, y0), Vector2(cx0, y0 + 10.0), pw, vz + (0.0 if pass_i == 1 else -0.1), pc)
						n = _line(n, Vector2(cx0, y0 + 10.0), Vector2(cx0 + 11.0, y0), pw, vz + (0.0 if pass_i == 1 else -0.1), pc)
	return n


## The LT zip (zip.gd): the tell, the travel in and out per reading, and the outcome marks. All of it is drawn between points, so it works in any direction.
## Legal's motion rules (docs/legal/zip-screen.md, movegen-banned.json m01 to m08): the real body is never hidden or replaced (nothing here draws over it: the ghosts and
## echoes are behind it and trail it); an echo is never ahead of the body; a ghost is one flat lane-colour tint at 0.35 or less, fainter for older ones, at most 5, on the
## body's real recent path, each overlapping the next by about a third, drawn only while he travels (gone the tick the zip ends); the heavy's ring is thin, hollow and
## shrinking, in the last 10 ticks of the wind-up; the outcome marks sit below the face.
func _zip(n: int, S: SimState, hub: VfxHub, host, cam_x: float, half_w: float, a: float, bh: float, minpx: float, alpha: float) -> int:
	var zp: VfxZip = hub.zip
	var pr: VfxPress = hub.press
	var al: float = alpha * VfxZip.p("alpha")
	var red: bool = hub.reduced_motion
	zp.shown = 0
	for z: VfxZip.Zip in zp.zips:
		if n >= CAP - 50:
			break
		var f = S.fighters[z.slot]
		var cur: Vector2 = Vector2(SimWrap.sdx(cam_x, host.fighter_x(z.slot, a)), host.fighter_pose(z.slot, a).y)
		if absf(cur.x) > half_w + 40.0 * bh and absf(SimWrap.sdx(cam_x, z.ox)) > half_w + 40.0 * bh:
			continue
		var age: float = maxf(z.age - (1.0 - a), 0.0)
		var look: float = 1.0 if SimWrap.sdx(f.x, S.fighters[z.target].x) >= 0.0 else -1.0
		var fz: float = host.fighter_z(z.slot, a)
		var zb: float = fz + Z_FX - 12.0          # behind the fighter: ghosts and echoes never cover him
		var zf: float = fz + Z_FX + 8.0
		var col: Color = z.col
		var o := Vector2(SimWrap.sdx(cam_x, z.ox), z.oy)
		var pt := Vector2(SimWrap.sdx(cam_x, z.px), z.py)
		var arr: Vector2 = Vector2(SimWrap.sdx(cam_x, z.ax), z.ay) if z.have_a else pt
		zp.shown += 1
		if age < z.t1():
			# The tell: a thin line along the ground toward the arrival point, and a tick where it ends; the heavy's ring (hollow, thin, shrinking, the last 10 ticks).
			var k: float = age / z.t1()
			var tc: Color = col
			tc.a = al * VfxZip.p("tell_alpha") * (0.35 + 0.65 * k)
			var go: float = WorldTerrain.groundY(S, z.ox) + 3.0
			var gp: float = WorldTerrain.groundY(S, z.px) + 3.0
			var tw: float = maxf(VfxZip.p("ground_line_w"), minpx * 1.2)
			var nseg: int = clampi(int(ceil(absf(pt.x - o.x) / 24.0)), 1, 24)      # it follows the ground, so a dune between them never hides it
			var tp: Vector2 = Vector2(o.x, go)
			for sg in range(1, nseg + 1):
				var kx: float = float(sg) / float(nseg)
				var sx: float = lerpf(o.x, pt.x, kx)
				var tq := Vector2(sx, WorldTerrain.groundY(S, SimWrap.wrap(cam_x + sx)) + 3.0)
				n = _line(n, tp, tq, tw, zb, tc)
				tp = tq
			n = _line(n, Vector2(pt.x, gp), Vector2(pt.x, gp + 12.0), maxf(VfxZip.p("ground_line_w"), minpx * 1.2), zb, tc)
			var rem: float = z.t1() - age
			if z.style == "heavy" and rem <= VfxZip.p("ring_ticks"):
				var kr: float = 1.0 - rem / VfxZip.p("ring_ticks")
				var rr: float = lerpf(40.0, 12.0, kr)
				var hc: Color = col
				hc.a = al * (0.3 + 0.6 * kr)
				n = _put(n, Vector2(cur.x + look * 20.0, cur.y + 50.0), Vector2(1.0, 0.0), rr * 2.0, rr * 2.0, zf, hc, minf(0.5, 2.2 / rr), 0.0, SHAPE_RING)
			continue
		var in_phase: bool = age < z.t2()
		var out_phase: bool = age >= z.t3() and age < z.t4() and not z.stopped
		if z.stopped and age >= z.t2():
			continue
		var style: String = z.style
		if out_phase and style == "heavy":
			style = "speed"                  # a heavy leaves as a speed zip
		if style == "tech":
			# Wire echoes between where this leg began and the body, popping off one at a time from the back to the front, and a thin line at head height. They are
			# strung between the start and the BODY, so none stands ahead of him or at the arrival point before he gets there.
			var p0: Vector2 = o if age < z.t3() else arr
			var tt: float = (age - z.t1()) if age < z.t3() else (age - z.t3())
			if tt >= 0.0 and tt < 12.0 and (cur - p0).length() > 8.0:
				var ne: int = int(VfxZip.p("echoes"))
				var pop: float = VfxZip.p("echo_pop")
				var ep: Array = VfxZip.echo_points(p0, cur, ne)
				for g in range(ne):
					if red and g != ne - 1:
						continue
					if tt >= 2.0 + float(g) * pop:
						continue
					var ec: Color = col.darkened(0.3)
					ec.a = al
					var fp: Vector2 = ep[g]
					n = _figure(n, fp, look, 12.0, fp + Vector2(look * 24.0, 50.0), ec, true, zb + 0.2 * float(g), minpx)
				var lc: Color = col.darkened(0.3)
				lc.a = al * 0.6 * (1.0 - clampf(tt / 10.0, 0.0, 1.0))
				n = _line(n, p0 + Vector2(0.0, 74.0), cur + Vector2(0.0, 74.0), maxf(1.3, minpx * 1.2), zb - 0.1, lc)
			continue
		if not (in_phase or out_phase):
			continue
		# Speed and heavy: a smear of up to 5 ghosts on the body's real recent path, each overlapping the next by about a third, one flat lane-colour tint at 0.35 or
		# less and fainter the older. Nothing is drawn where he has not been; a stationary body has no ghosts.
		var heavy: bool = style == "heavy"
		var ng: int = 1 if red else mini(int(VfxZip.p("ghosts")), 5)
		var trail: Array = VfxZip.trail_points(pr.hist[z.slot], VfxZip.p("ghost_gap"), ng)
		var oldest: Vector2 = cur
		for g in range(trail.size()):
			var tp: Vector2 = trail[g]
			var gp2 := Vector2(SimWrap.sdx(cam_x, tp.x), tp.y)
			oldest = gp2
			var gc: Color = col
			gc.a = al * VfxZip.p("ghost_alpha") * (1.0 - float(g) / float(ng))
			n = _figure(n, gp2, look, 16.0 if heavy else 8.0, gp2 + Vector2(look * 30.0, 56.0), gc, false, zb + 0.1 * float(ng - g), minpx, 1.5 if heavy else 1.0)
		var d: Vector2 = cur - oldest
		if d.length() > 4.0:
			var bc: Color = col
			bc.a = al * 0.30
			if heavy:
				n = _put(n, (oldest + cur) * 0.5 + Vector2(0.0, 48.0), d.normalized(), d.length(), VfxZip.p("wide_w") * 2.0, zb - 0.3, bc, 0.9, 0.5, SHAPE_STREAK)
			else:
				n = _put(n, (oldest + cur) * 0.5 + Vector2(0.0, 74.0), d.normalized(), d.length(), VfxZip.p("band_w") * 2.0, zb - 0.3, bc, 0.9, 0.5, SHAPE_STREAK)
				if not red:
					bc.a = al * 0.22
					n = _put(n, (oldest + cur) * 0.5 + Vector2(0.0, 36.0), d.normalized(), d.length(), VfxZip.p("band_w2") * 2.0, zb - 0.3, bc, 0.9, 0.5, SHAPE_STREAK)
	# The outcome marks (no text, nothing on the face, nothing body-wide): all of them sit at or below the chest, and none is white, gold or red.
	for m: VfxZip.Mark in zp.marks:
		if n >= CAP - 14:
			break
		var mx: float = SimWrap.sdx(cam_x, m.x)
		if absf(mx) > half_w + 6.0 * bh:
			continue
		var ms: float = maxf(m.age - (1.0 - a), 0.0)
		var u: float = clampf(ms / m.life, 0.0, 1.0)
		var c := Vector2(mx, m.y)
		var dv := Vector2(m.dx, m.dy)
		var pv := Vector2(-m.dy, m.dx)
		var zm: float = host.fighter_z(m.slot, a) + Z_FX + 8.0
		zp.shown += 1
		match m.kind:
			"counter":
				# A hard bar across his path where he is stopped (below the face), and the counter's own mark: a diamond (tech) or a double ring (heavy).
				var bk: Color = m.col
				bk.a = al * (1.0 - u)
				n = _put(n, c, pv, VfxZip.p("mark_h"), 7.0 * 2.0, zm, bk, 0.5, 0.5, SHAPE_STREAK)
				var rr: float = lerpf(10.0, VfxZip.p("mark_r"), 1.0 - pow(1.0 - u, 2.0))
				var mk: Color = m.col
				mk.a = al * (1.0 - u)
				if m.style == "heavy":
					n = _put(n, c, Vector2(1.0, 0.0), rr * 2.0, rr * 2.0, zm + 0.1, mk, minf(0.5, 5.0 / rr), 0.0, SHAPE_RING)
					n = _put(n, c, Vector2(1.0, 0.0), rr, rr, zm + 0.1, mk, minf(0.5, 3.0 / (rr * 0.5)), 0.0, SHAPE_RING)
				else:
					n = _put(n, c, Vector2(1.0, 0.0), rr * 2.0, rr * 2.0, zm + 0.1, mk, maxf(0.16, 4.0 * minpx / rr), 0.0, 5.0)
			"caught":
				# He is held in reach: a ring closing on him (round the chest, under the face) and two brackets beside him.
				var cr: float = lerpf(VfxZip.p("mark_r"), 14.0, 1.0 - pow(1.0 - clampf(ms / 8.0, 0.0, 1.0), 2.0))
				var cc: Color = m.col
				cc.a = al * (1.0 - smoothstep(0.6, 1.0, u))
				n = _put(n, c, Vector2(1.0, 0.0), cr * 2.0, cr * 2.0, zm, cc, minf(0.5, 3.0 / cr), 0.0, SHAPE_RING)
				for sg in [-1.0, 1.0]:
					n = _put(n, c + pv * (sg * (cr + 6.0)), dv, 20.0, 4.0, zm, cc, 0.5, 0.5, SHAPE_STREAK)
			"zipblow":
				# The zip's blow lands: a hard bar across the line of his approach (a zip strike), two bars side by side (a zip heavy), low on the body, in his lane colour.
				var zk: Color = m.col
				zk.a = al * (1.0 - u)
				var zlen: float = 60.0 if m.style == "heavy" else 54.0
				var zdir := Vector2(m.dx, 0.0)
				var zperp := Vector2(0.0, 1.0)
				if m.style == "heavy":
					n = _put(n, c - zdir * 6.0, zperp, zlen, 6.0 * 2.0, zm, zk, 0.5, 0.5, SHAPE_STREAK)
					n = _put(n, c + zdir * 6.0, zperp, zlen * 0.8, 4.0 * 2.0, zm, zk, 0.5, 0.5, SHAPE_STREAK)
				else:
					n = _put(n, c, zperp, zlen, 4.0 * 2.0, zm, zk, 0.5, 0.5, SHAPE_STREAK)
			"shot":
				# The zipper is shot down out of his zip: four short hard spokes and a ring, low on the body.
				var sk: Color = m.col
				sk.a = al * (1.0 - u)
				for k in range(4):
					var sang: float = float(k) * PI * 0.5 + PI * 0.25
					var sd := Vector2(cos(sang), sin(sang))
					n = _put(n, c + sd * (10.0 + 14.0 * u), sd, 14.0, 4.0, zm, sk, 0.5, 0.5, SHAPE_STREAK)
				var sr: float = lerpf(8.0, 22.0, u)
				n = _put(n, c, Vector2(1.0, 0.0), sr * 2.0, sr * 2.0, zm + 0.1, sk, minf(0.5, 3.0 / sr), 0.0, SHAPE_RING)
			"down":
				# He is down after a shot on the way out: a flat ring on the ground under him, widening.
				var dk: Color = m.col
				dk.a = al * 0.8 * (1.0 - u)
				var dr: float = lerpf(10.0, 44.0, 1.0 - pow(1.0 - u, 2.0))
				n = _put(n, c, Vector2(1.0, 0.0), dr * 2.0, dr * 2.0 * 0.28, zm, dk, minf(0.5, 3.0 / dr), 0.0, SHAPE_RING)
			"gbreak":
				# The shield line breaks into fragments that fly out, with a small flash ring (low on the body, in the lane colour).
				var gk: Color = m.col
				gk.a = al * (1.0 - u)
				for k in range(4):
					var ang: float = (float(k) - 1.5) * 0.6
					var fd := Vector2(dv.x * cos(ang) - dv.y * sin(ang), dv.x * sin(ang) + dv.y * cos(ang))
					n = _put(n, c + fd * (14.0 + 30.0 * u), fd, 12.0, 4.0, zm, gk, 0.5, 0.5, SHAPE_STREAK)
				var fr3: float = lerpf(8.0, 22.0, u)
				n = _put(n, c, Vector2(1.0, 0.0), fr3 * 2.0, fr3 * 2.0, zm + 0.1, gk, minf(0.5, 4.0 / fr3), 0.0, SHAPE_RING)
	return n


## Where a fighter's head is and which way he looks: the host's `fighter_head(i, a)` (Vector3: world x, y, z of the head's centre) when Rendering has
## one, otherwise an estimate from the pose (the head a standing figure's height above the pose, turned with the body's roll); he looks toward the other.
func _head_of(S: SimState, host, i: int, a: float) -> Vector4:
	var o: int = 1 - i
	var fc: float = float(S.fighters[i].face)      # the sim's facing: 1 right, -1 left
	var look: float = fc if absf(fc) > 0.5 else (1.0 if SimWrap.sdx(host.fighter_x(i, a), host.fighter_x(o, a)) >= 0.0 else -1.0)
	if host.has_method("fighter_head"):
		var hv: Vector3 = host.fighter_head(i, a)
		return Vector4(hv.x, hv.y, hv.z, look)
	var ps: Vector3 = host.fighter_pose(i, a)
	var hh: float = GLARE_HEAD_Y
	return Vector4(ps.x + hh * sin(ps.z), ps.y + hh * cos(ps.z), host.fighter_z(i, a), look)


## The glare (glare.gd): the lens goes opaque in a pale violet wedge (frame C, the bare wedge), a lighter wedge cut across it, and a deeper violet rim.
## A glint (a signature's wind-up) is a slash crossing a half-opaque lens; a seal break adds a crack. Every shape is hard-edged and in his violet.
func _glare(n: int, S: SimState, hub: VfxHub, host, cam_x: float, half_w: float, a: float, bh: float, minpx: float) -> int:
	var gl: VfxGlare = hub.glare
	for i in range(mini(2, S.fighters.size())):
		var s: VfxGlare.State = gl.st[i]
		if s.t < 0.0 or n >= CAP - 8:
			continue
		var lvl: float = gl.level(i, a, hub.reduced_motion)
		if lvl <= 0.01 or S.fighters[i].hidden:
			continue
		var hd: Vector4 = _head_of(S, host, i, a)
		var rx: float = SimWrap.sdx(cam_x, hd.x)
		if absf(rx) > half_w + 4.0 * bh:
			continue
		var look: float = hd.w
		var fw: float = VfxGlare.p("w")
		var fh: float = VfxGlare.p("h")
		var base := Vector2(rx + look * VfxGlare.p("fwd"), hd.y + VfxGlare.p("up"))
		var dirv := Vector2(look, 0.0)
		var z: float = hd.z + GLARE_Z
		var al: float = VfxGlare.p("alpha") * lvl
		var full: bool = s.kind == "full"
		var fill: float = 1.0 if full else VfxGlare.p("glint_fill")
		# The lens: a wedge, narrow toward where he looks, in a pale violet. A deeper violet rim keeps it a lens against a light sky.
		var halo: Color = VfxGlare.col("halo")
		halo.a = 0.85 * lvl
		n = _put(n, base, dirv, fw * 1.0 + minpx * 3.0, fh + minpx * 3.0, z - 0.2, halo, 0.3, 0.5, SHAPE_STREAK)
		var lens: Color = VfxGlare.col("lens")
		lens.a = al * fill
		n = _put(n, base, dirv, fw, fh, z, lens, 0.3, 0.5, SHAPE_STREAK)
		# The slash: a slanted band of the lighter violet, cut across the lens (it crosses once on a glint).
		var sw: float = gl.sweep(i, a) if not full else 0.5
		var sl: Vector2 = Vector2(look * 0.55, 1.0).normalized()
		var wc: Color = VfxGlare.col("wedge")
		wc.a = al
		var slash_c: Vector2 = base + dirv * lerpf(-fw * 0.3, fw * 0.3, sw)
		n = _put(n, slash_c, sl, fh * 1.25, maxf(fh * 0.26, minpx * 1.5), z + 0.2, wc, 0.5, 0.5, SHAPE_STREAK)
		if s.crack:
			var kc: Color = VfxGlare.col("crack")
			kc.a = al * 0.9
			var cd: Vector2 = Vector2(look * 0.35, -1.0).normalized()
			n = _put(n, base + dirv * fw * 0.05, cd, fh * 1.1, maxf(fh * 0.07, minpx * 0.9), z + 0.4, kc, 0.5, 0.5, SHAPE_STREAK)
		gl.shown += 1
	return n


## The beam plays (beamplay.gd). All hard-edged wedges and thin rings in the lane colour of whose they are.
func _beamplay(n: int, S: SimState, hub: VfxHub, host, cam_x: float, half_w: float, a: float, bh: float, minpx: float, alpha: float) -> int:
	var bp: VfxBeamPlay = hub.beamplay
	var al: float = alpha * VfxBeamPlay.p("beamplay", "alpha")
	var z0: float = Z_FX + 1.0 + PLAY_LIFT
	# A beam crossing: its head leads it, so it is seen to travel.
	for b in S.beams:
		if n >= CAP - 30:
			break
		if not VfxBeamPlay.crossing(b):
			continue
		var slot: int = S.fighters.find(b.A)
		var lane: Color = VfxBeamPlay.lane_of(S, slot)
		var s0: float = float(b.p) * float(b.len)
		var rx0: float = SimWrap.sdx(cam_x, float(b.ox)) + float(b.ux) * s0
		if absf(rx0) > half_w + 8.0 * bh:
			continue
		var hd := Vector2(rx0, float(b.oy) + float(b.uy) * s0)
		var dv := Vector2(float(b.ux), float(b.uy))
		var pulse: float = 1.0 if hub.reduced_motion else 0.8 + 0.2 * sin(TAU * (float(bp.clock) + a) / 6.0)
		var c1: Color = lane
		c1.a = al * 0.85 * pulse
		n = _wedge(n, hd - dv * 24.0, dv, VfxBeamPlay.p("beamplay", "head_len"), VfxBeamPlay.p("beamplay", "head_w") * (0.8 + 0.1 * float(b.pw)), float(b.oz) + z0, c1)
		var c2: Color = lane.lightened(0.18)
		c2.a = al * pulse
		n = _wedge(n, hd - dv * 10.0, dv, VfxBeamPlay.p("beamplay", "head_len") * 0.62, VfxBeamPlay.p("beamplay", "head_w") * 0.4, float(b.oz) + z0 + 0.1, c2)
		var c3: Color = lane
		c3.a = al * 0.6
		n = _across(n, hd + dv * 6.0, dv, VfxBeamPlay.p("beamplay", "head_ring"), 0.34, float(b.oz) + z0 - 0.2, c3, minpx)
	# The effects the cues made.
	for e: VfxBeamPlay.Fx in bp.fx:
		if n >= CAP - 14:
			break
		var rx: float = SimWrap.sdx(cam_x, e.x)
		if absf(rx) > half_w + 6.0 * bh:
			continue
		var st: float = maxf(e.age - (1.0 - a), 0.0)
		var u: float = clampf(st / e.life, 0.0, 1.0)
		var eo: float = 1.0 - pow(1.0 - u, 2.0)
		var c := Vector2(rx, e.y)
		var dv2 := Vector2(e.dx, e.dy)
		var pv := Vector2(-e.dy, e.dx)
		var ez: float = e.z + z0
		var fa: float = al * (1.0 - u)
		match e.kind:
			"wake":
				var wc: Color = e.col
				wc.a = al * 0.5 * (1.0 - u)
				n = _across(n, c, dv2, e.size * lerpf(0.8, 1.3, eo), 0.3, ez - 0.4, wc, minpx)
			"launch":
				var lc: Color = e.col
				lc.a = fa
				n = _wedge(n, c, dv2, lerpf(40.0, e.size, eo), 54.0 * (1.0 - 0.6 * u), ez, lc)
				var lr: Color = e.col
				lr.a = fa * 0.7
				n = _across(n, c + dv2 * 20.0, dv2, lerpf(60.0, 130.0, eo), 0.3, ez - 0.2, lr, minpx)
			"sweep":
				# A slash: wedges at the angles it has swept through, the newest the brightest, then a ring at his hand.
				for k in range(4):
					var tk: float = clampf(eo - 0.14 * float(k), 0.0, 1.0)
					var ang: float = lerpf(e.a0, e.a1, tk)
					var sd := Vector2(cos(ang), sin(ang))
					if k == 0:
						n = _wedge(n, c + sd * 30.0, sd, e.size + 14.0, 50.0, ez - 0.5, Color(0.04, 0.02, 0.1, al * (1.0 - u) * 0.6))
					var sc: Color = e.col if k == 0 else e.col.lerp(e.col2, 0.35)
					sc.a = al * (1.0 - u * 0.7) * (1.0 - 0.22 * float(k))
					n = _wedge(n, c + sd * 36.0, sd, e.size * (1.0 - 0.1 * float(k)), 34.0 * (1.0 - 0.15 * float(k)), ez + 0.05 * float(k), sc)
				var sr: Color = e.col2
				sr.a = fa * 0.6
				n = _across(n, c, Vector2(cos(e.a1), sin(e.a1)), lerpf(70.0, 150.0, eo), 0.35, ez - 0.3, sr, minpx)
			"part":
				# The beam parts round him: two wedges slide apart along the forks' lines, with a tall ring across him.
				var ang0: float = atan2(e.dy, e.dx)
				for sg in [-1.0, 1.0]:
					var pa: float = ang0 + sg * 20.0 * PI / 180.0
					var pd := Vector2(cos(pa), sin(pa))
					n = _wedge(n, c + pv * (sg * 50.0 * eo) - pd * 6.0, pd, lerpf(60.0, e.size * 1.6 + 12.0, eo), 64.0, ez - 0.5, Color(0.04, 0.02, 0.1, fa * 0.65))
					var pc: Color = e.col
					pc.a = fa
					n = _wedge(n, c + pv * (sg * 50.0 * eo), pd, lerpf(54.0, e.size * 1.6, eo), 70.0, ez, pc)
					var pw: Color = Color(1.0, 1.0, 1.0, fa * 0.9)
					n = _wedge(n, c + pv * (sg * 50.0 * eo), pd, lerpf(40.0, e.size * 1.2, eo), 26.0, ez + 0.2, pw)
				var pr: Color = e.col2
				pr.a = fa * 0.7
				n = _across(n, c, dv2, lerpf(90.0, 170.0, eo), 0.3, ez - 0.3, pr, minpx)
			"land":
				# He arrives against the attacker: a flat ring on the ground and a second inside it.
				var rr: float = lerpf(e.size * 0.4, e.size, eo)
				var lr2: Color = e.col
				lr2.a = fa
				n = _put(n, c, Vector2(1.0, 0.0), rr * 2.0, rr * 2.0 * 0.28, ez, lr2, maxf(0.05, 1.6 * minpx / maxf(rr, 1.0)), 0.0, SHAPE_RING)
				var lr3: Color = e.col2
				lr3.a = fa * 0.6
				n = _put(n, c, Vector2(1.0, 0.0), rr * 1.2, rr * 1.2 * 0.28, ez + 0.1, lr3, maxf(0.07, 1.6 * minpx / maxf(rr * 0.6, 1.0)), 0.0, SHAPE_RING)
			"cut":
				# The beam is cut where it had got to: lines burst back from the cut and a ring across it.
				for k in range(5):
					var ca: float = atan2(e.dy, e.dx) + (float(k) - 2.0) * 0.45
					var cd := Vector2(cos(ca), sin(ca))
					var cc: Color = e.col if k % 2 == 0 else e.col2
					cc.a = fa
					n = _wedge(n, c + cd * lerpf(10.0, 40.0, eo), cd, lerpf(24.0, e.size * 0.8, eo), 14.0, ez, cc)
				var cr: Color = e.col
				cr.a = fa * 0.8
				n = _across(n, c, Vector2(-e.dx, -e.dy), lerpf(70.0, 150.0, eo), 0.3, ez - 0.2, cr, minpx)
			"answer":
				# His answer runs out along the line to where the beam was cut.
				var to := Vector2(SimWrap.sdx(cam_x, e.x1), e.y1)
				var dd: Vector2 = to - c
				var dl: float = maxf(dd.length(), 1.0)
				var ad: Vector2 = dd / dl
				var head: Vector2 = c + ad * (dl * eo)
				var ac: Color = e.col
				ac.a = al * (1.0 - smoothstep(0.7, 1.0, u))
				n = _wedge(n, head - ad * minf(e.size, dl * eo), ad, minf(e.size, dl * eo + 10.0), 32.0, ez, ac)
	# A walk or a wade in progress, on the defender and following him.
	for si in range(mini(2, S.fighters.size())):
		var w: VfxBeamPlay.Walk = bp.walks[si]
		if not (w.on or w.fade > 0.0):
			continue
		if n >= CAP - 14:
			break
		var fx: float = host.fighter_x(si, a)
		var rxw: float = SimWrap.sdx(cam_x, fx)
		if absf(rxw) > half_w + 6.0 * bh:
			continue
		var pose: Vector3 = host.fighter_pose(si, a)
		var fzw: float = host.fighter_z(si, a)
		var toward: float = 1.0 if SimWrap.sdx(S.fighters[si].x, S.fighters[1 - si].x) >= 0.0 else -1.0
		var fwd := Vector2(toward, 0.0)
		var chest: Vector2 = Vector2(rxw, pose.y + VfxLook.CHEST_Y)
		var vis: float = 1.0 if w.on else w.fade / 6.0
		var beamc: Color = VfxBeamPlay.lane_of(S, 1 - si)
		var selfc: Color = VfxBeamPlay.lane_of(S, si)
		var ww: float = (float(bp.clock) + a)
		var zw: float = fzw + z0
		if w.look == "walk":
			# Clean: a tall thin bow wave in front of him and the beam parting round him in two long wedges.
			var bc: Color = beamc
			bc.a = al * 0.75 * vis
			n = _across(n, chest + fwd * 34.0, fwd, VfxBeamPlay.p("beamplay", "wave_h"), 0.3, zw, bc, minpx)
			for sg in [-1.0, 1.0]:
				var pd2 := Vector2(-toward * cos(0.42), sg * sin(0.42)).normalized()
				var wc2: Color = beamc
				wc2.a = al * 0.6 * vis
				n = _wedge(n, chest + fwd * 40.0 + Vector2(0.0, sg * 26.0), pd2, 150.0, 22.0, zw - 0.1, wc2)
		else:
			# Rough: a fan of short guard blades in front of him, jittering, and a spray of short lines peeling back along the beam.
			for k in range(3):
				var ja: float = (float(k) - 1.0) * 0.8 + (0.0 if hub.reduced_motion else sin(ww * 1.7 + float(k) * 2.0) * 0.12)
				var gd := Vector2(toward * cos(ja), sin(ja))
				var gc: Color = selfc
				gc.a = al * 0.9 * vis
				n = _wedge(n, chest + gd * 26.0, gd, 84.0, 24.0, zw, gc)
			for k in range(4):
				var ra: float = (float(k) - 1.5) * 0.55
				var jit: float = 0.0 if hub.reduced_motion else fposmod(ww * 0.37 + float(k) * 0.31, 1.0)
				var rd2 := Vector2(-toward * cos(ra), sin(ra))
				var rc2: Color = beamc
				rc2.a = al * 0.7 * vis * (1.0 - jit * 0.5)
				n = _wedge(n, chest + fwd * 30.0 + rd2 * (20.0 + 60.0 * jit), rd2, 56.0, 9.0, zw - 0.1, rc2)
	return n


## The mines, each fighter's own look, and never a sphere (Legal, RL-062): the others' is a hexagonal plate (a flat hexagon with a raised
## inner hexagon, a thin ring round it), the Anti-hero's a faceted caltrop (three tapering spikes round a small hexagonal hub). A hovering
## one bobs, with a faint line down to a flat shadow on the ground, face-on; a ground one lies flat (the plate squashed) or stands on its
## spikes. Arming: the plate's ring and the spikes close in from far out while they fade up (dim, then bright); armed: a slow breathing
## of the inner hexagon; the fuse (about to go): a quick blink, the inner hexagon swelling, and one thin warning ring running out to the
## blast's radius. One mine at a time per spot: no row of matching shapes is staged. The lane colour only, never white, gold or red.
func _mines(n: int, S: SimState, hub: VfxHub, sh: VfxShots, cam_x: float, half_w: float, a: float, bh: float, minpx: float, alpha: float) -> int:
	# The concept list (tools and the events a sim may send), then the real ones: every entry of S.shots whose mode is MINE.
	for m: VfxShots.Mine in sh.mines:
		n = _draw_mine(n, m, 1.0, S, hub, sh, cam_x, half_w, a, bh, minpx, alpha)
	for sp in S.shots:
		if int(sp.mode) != SimShots.MINE:
			continue
		var m := VfxShots.mine_of(S, sp, sh)
		var life_k: float = lerpf(0.35, 1.0, smoothstep(0.0, 0.08, float(sp.left) / maxf(float(sp.total), 1.0)))    # it dims over its last seconds, then fizzles
		n = _draw_mine(n, m, life_k, S, hub, sh, cam_x, half_w, a, bh, minpx, alpha)
	return n


## One mine. life_k: how bright it is for its age (1 until its last seconds).
func _draw_mine(n: int, m: VfxShots.Mine, life_k: float, S: SimState, hub: VfxHub, sh: VfxShots, cam_x: float, half_w: float, a: float, bh: float, minpx: float, alpha: float) -> int:
	if n >= CAP - 16:
		return n
	var rx: float = SimWrap.sdx(cam_x, m.x)
	if absf(rx) > half_w + 3.0 * bh:
		return n
	var lane: Color = VfxShots.lane_of(S, m.owner)
	var villain: bool = String(S.fighters[m.owner].role) == "villain"
	var age: float = m.age + (0.0 if sh.last_frozen else a)
	var hover: bool = m.mode == "hover"
	var gy: float = WorldTerrain.groundY(S, m.x)
	var bob: float = 0.0 if (not hover or hub.reduced_motion) else sin(TAU * (float(sh.clock) + a) / 90.0 + float(m.id)) * 5.0
	var c := Vector2(rx, m.y + bob)
	var z: float = m.z + Z_SHOT - 0.5
	var close: float = 1.0
	var ak: float = 1.0
	var core_k: float = 1.0
	var blink: float = 1.0
	var grow: float = 1.0
	match m.state:
		"arming":
			var u: float = clampf(age / VfxShots.MINE_ARM_TICKS, 0.0, 1.0)
			close = lerpf(2.4, 1.0, 1.0 - pow(1.0 - u, 2.0))
			ak = lerpf(0.25, 1.0, u)
			grow = lerpf(0.4, 1.0, u)
		"armed":
			var br: float = 0.0 if hub.reduced_motion else sin(TAU * age / 60.0)
			close = 1.0 + 0.03 * br
			core_k = 0.9 + 0.1 * br
		"trigger":
			var uf: float = clampf(age / VfxShots.MINE_FUSE_TICKS, 0.0, 1.0)
			close = lerpf(1.0, 0.8, uf)
			core_k = lerpf(1.0, 1.4, uf)
			blink = 1.0 if (hub.reduced_motion or int(age / 4.0) % 2 == 0) else 0.45
			var wr: float = lerpf(40.0, m.radius, 1.0 - pow(1.0 - uf, 2.0))
			var wc: Color = lane
			wc.a = alpha * 0.55 * (1.0 - uf * 0.5)
			n = _put(n, Vector2(rx, m.y) if hover else Vector2(rx, gy + 12.0), Vector2(1.0, 0.0), wr * 2.0, wr * (2.0 if hover else 0.5), z - 0.6, wc, maxf(0.03, 1.6 * minpx / wr), 0.0, SHAPE_RING)
	var a_all: float = alpha * ak * blink * life_k
	# What shows it hovers, or sits.
	if hover:
		var sc: Color = lane.darkened(0.55)
		sc.a = alpha * 0.28
		n = _put(n, Vector2(rx, gy + 5.0), Vector2(1.0, 0.0), 96.0, 22.0, z - 1.4, sc, 1.0, 0.0, SHAPE_RING)
		var gap: float = maxf((c.y - 30.0) - (gy + 8.0), 0.0)
		var steps: int = clampi(int(gap / 34.0), 0, 4)
		for k in range(steps):
			var lc: Color = lane
			lc.a = alpha * 0.32 * (1.0 - float(k) / float(maxi(steps, 1)) * 0.6)
			n = _put(n, Vector2(rx, c.y - 32.0 - float(k) * 34.0 - 9.0), Vector2(0.0, 1.0), 18.0, maxf(3.0, minpx), z - 1.0, lc, 0.5, 0.5, SHAPE_STREAK)
	var flat_k: float = 1.0 if hover else 0.3          # a plate on the ground lies flat
	var base: Vector2 = c if hover else Vector2(rx, gy + 9.0)
	var plate: Color = lane.darkened(0.45)
	plate.a = a_all * 0.92
	var rimc: Color = lane
	rimc.a = a_all
	var inner: Color = lane.lightened(0.14 + 0.12 * (core_k - 1.0))
	inner.a = a_all
	if villain:
		# A faceted caltrop: three tapering spikes round a small hexagonal hub; in the air a spike up and two down, on the ground one up and two
		# low to the sides.
		var angs: Array = [PI * 0.5, PI * 1.17, PI * 1.83] if hover else [PI * 0.5, PI * 0.12, PI * 0.88]
		var ln: float = 40.0 * grow
		for an in angs:
			var dv: Vector2 = Vector2(cos(an), sin(an))
			var sp0: Color = lane.darkened(0.2)
			sp0.a = a_all
			n = _put(n, base + dv * (ln * 0.5 + 6.0), dv, ln, 15.0, z + 0.1, sp0, 0.04, 0.5, SHAPE_STREAK)
			var sp1: Color = lane
			sp1.a = a_all * 0.9
			n = _put(n, base + dv * (ln * 0.5 + 8.0), dv, ln * 0.8, 5.0, z + 0.2, sp1, 0.04, 0.5, SHAPE_STREAK)
		n = _put(n, base, Vector2(1.0, 0.0), 30.0 * close, 30.0 * 0.866 * close, z + 0.3, plate, maxf(0.09, 1.6 * minpx / 15.0), 1.0, SHAPE_HEX)
		n = _put(n, base, Vector2(1.0, 0.0), 30.0 * close, 30.0 * 0.866 * close, z + 0.35, rimc, maxf(0.14, 1.6 * minpx / 15.0), 0.0, SHAPE_HEX)
		n = _put(n, base, Vector2(1.0, 0.0), 14.0 * core_k, 14.0 * 0.866 * core_k, z + 0.4, inner, 0.15, 1.0, SHAPE_HEX)
	else:
		# A hexagonal plate with a raised inner hexagon and a thin ring round it (flat on the ground, face-on in the air).
		var rr: float = 46.0 * close
		var rc: Color = lane
		rc.a = a_all * 0.55
		n = _put(n, base, Vector2(1.0, 0.0), rr * 2.0, rr * 2.0 * flat_k, z - 0.2, rc, maxf(0.04, 1.6 * minpx / rr), 0.0, SHAPE_RING)
		n = _put(n, base, Vector2(1.0, 0.0), 54.0, 54.0 * 0.866 * flat_k, z + 0.1, plate, maxf(0.07, 1.6 * minpx / 27.0), 1.0, SHAPE_HEX)
		n = _put(n, base, Vector2(1.0, 0.0), 54.0, 54.0 * 0.866 * flat_k, z + 0.15, rimc, maxf(0.1, 1.6 * minpx / 27.0), 0.0, SHAPE_HEX)
		n = _put(n, base, Vector2(1.0, 0.0), 28.0 * core_k, 28.0 * 0.866 * core_k * flat_k, z + 0.3, inner, 0.14, 1.0, SHAPE_HEX)
	return n


## One quad: centre c (camera-relative x, world y), unit direction dir for its x axis, size l by w, depth z.
func _put(n: int, c: Vector2, dir: Vector2, l: float, w: float, z: float, col: Color, cx: float, cy: float, shape: float) -> int:
	if n >= CAP:
		return n
	var o: int = n * STRIDE
	_buf[o] = dir.x * l
	_buf[o + 1] = -dir.y * w
	_buf[o + 2] = 0.0
	_buf[o + 3] = c.x
	_buf[o + 4] = dir.y * l
	_buf[o + 5] = dir.x * w
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
	_buf[o + 16] = cx
	_buf[o + 17] = cy
	_buf[o + 18] = shape
	_buf[o + 19] = 0.0
	return n + 1
