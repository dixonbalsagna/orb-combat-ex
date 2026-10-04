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
func _figure(n: int, feet: Vector2, dir: float, lean: float, fist: Vector2, col: Color, wire: bool, z: float, minpx: float) -> int:
	var t: float = maxf(1.7, minpx * 1.5) if wire else 3.2
	var hip := Vector2(feet.x, feet.y + VfxPress.HIP)
	var neck := Vector2(feet.x + dir * lean * 0.6, feet.y + VfxPress.SHOULDER + 4.0)
	var head := Vector2(feet.x + dir * lean, feet.y + VfxPress.HEAD_Y)
	if wire:
		n = _put(n, head, Vector2(1.0, 0.0), VfxPress.HEAD_R * 2.0, VfxPress.HEAD_R * 2.0, z, col, maxf(0.16, 2.0 * minpx / VfxPress.HEAD_R), 0.0, SHAPE_RING)
	else:
		n = _put(n, head, Vector2(1.0, 0.0), VfxPress.HEAD_R * 2.0, VfxPress.HEAD_R * 2.0, z, col, 1.0, 0.0, SHAPE_RING)
	n = _line(n, hip, neck, t * (1.0 if wire else 1.6), z, col)
	n = _line(n, hip, Vector2(feet.x - dir * 8.0, feet.y), t, z, col)
	n = _line(n, hip, Vector2(feet.x + dir * 10.0, feet.y), t, z, col)
	n = _line(n, Vector2(feet.x + dir * lean * 0.5, feet.y + VfxPress.SHOULDER), fist, t, z + 0.1, col)
	return n


func _dir_of(S: SimState, slot: int) -> float:
	var fc: float = float(S.fighters[slot].face)
	return fc if absf(fc) > 0.5 else 1.0


## The press styles (press.gd): each blow's after-image and contact look by the way it was pressed.
func _press(n: int, S: SimState, hub: VfxHub, host, cam_x: float, half_w: float, a: float, bh: float, minpx: float, alpha: float) -> int:
	var pr: VfxPress = hub.press
	var al: float = alpha * VfxPress.p("alpha")
	pr.shown = 0
	var red: bool = hub.reduced_motion
	for e: VfxPress.Fx in pr.fx:
		if n >= CAP - 40:
			break
		var rx: float = SimWrap.sdx(cam_x, e.ax)
		if absf(rx) > half_w + 6.0 * bh:
			continue
		var st: float = maxf(e.age - (1.0 - a), 0.0)
		var u: float = clampf(st / e.life, 0.0, 1.0)
		var d: float = e.dir
		var fz: float = host.fighter_z(e.slot, a)
		var zb: float = fz + Z_FX - 12.0          # behind the fighter: the after-images
		var zf: float = fz + Z_FX + 8.0           # in front: the contact marks
		var feet := Vector2(rx, e.ay)
		var contact: Vector2 = feet + Vector2(e.cx, e.cy)
		var guard: Vector2 = feet + Vector2(d * VfxPress.GUARD.x, VfxPress.GUARD.y + (6.0 if e.hand == 1 else -2.0))
		pr.shown += 1
		match e.style:
			"speed":
				# A soft, filled, overlapping blur along the fist's path (layered soft discs and one wide soft streak), and a small round ring.
				var fade: float = 1.0 - u
				var bc: Color = e.col.darkened(0.15)
				bc.a = al * 0.55 * fade
				if not red:
					for k in range(5):
						var f: float = float(k + 1) / 5.0
						var pc: Vector2 = guard.lerp(contact, f)
						n = _put(n, pc, Vector2(1.0, 0.0), 18.0 + 14.0 * f, 18.0 + 14.0 * f, zb, bc, 1.0, 0.0, SHAPE_DISC)
				var path: Vector2 = contact - guard
				if path.length() > 1.0:
					var sc: Color = e.col
					sc.a = al * 0.45 * fade
					n = _put(n, (guard + contact) * 0.5, path.normalized(), path.length(), VfxPress.p("speed_w") * 2.0, zb - 0.2, sc, 0.9, 0.5, SHAPE_STREAK)
				var rr: float = lerpf(5.0, VfxPress.p("speed_ring_r"), 1.0 - pow(1.0 - clampf(st / VfxPress.p("speed_ring_life"), 0.0, 1.0), 2.0))
				var rc: Color = e.col2
				rc.a = al * (1.0 - clampf(st / VfxPress.p("speed_ring_life"), 0.0, 1.0))
				n = _put(n, contact, Vector2(1.0, 0.0), rr * 2.0, rr * 2.0, zf, rc, maxf(0.16, 3.4 * minpx / rr), 0.0, SHAPE_RING)
			"tech":
				# Three sharp wireframe echoes between the old pose and the strike, popping off one at a time from the back to the front;
				# a thin straight speed line; a hard diamond.
				var pop: float = VfxPress.p("echo_pop")
				for g in range(3):
					if red and g != 2:
						continue
					if st >= 2.5 + float(g) * pop:
						continue
					var fr: float = float(g + 1) / 4.0
					var bx: float = -d * maxf(e.lunge, 24.0) * (1.0 - fr)
					var ec: Color = e.col.darkened(0.3)
					ec.a = al
					var fist: Vector2 = guard.lerp(contact, fr)
					n = _figure(n, Vector2(feet.x + bx, feet.y), d, 4.0 + 10.0 * fr, Vector2(fist.x + bx, fist.y), ec, true, zf - 2.0 + 0.2 * float(g), minpx)
				var lc: Color = e.col.darkened(0.3)
				lc.a = al * 0.9 * (1.0 - clampf(st / VfxPress.p("line_life"), 0.0, 1.0))
				n = _line(n, guard, contact, maxf(1.3, minpx * 1.2), zf - 1.0, lc)
				var dl: float = VfxPress.p("diamond_life")
				if st < dl:
					var dr: float = lerpf(5.0, VfxPress.p("diamond_r"), clampf(st / 4.0, 0.0, 1.0))
					var dc: Color = e.col.darkened(0.3)
					dc.a = al * (1.0 - st / dl)
					n = _put(n, contact, Vector2(1.0, 0.0), dr * 2.0, dr * 2.0, zf, dc, maxf(0.2, 3.6 * minpx / dr), 0.0, 5.0)
			"heavy":
				# The release: stacked body ghosts behind him, a filled crescent from the back-swing to the contact, and a double contact ring.
				var gl: float = VfxPress.p("ghost_life")
				var gf: float = 1.0 - clampf(st / gl, 0.0, 1.0)
				if not red:
					for k in range(4):
						var fr2: float = float(k + 1) / 5.0
						var bx2: float = -d * e.lunge * (1.0 - fr2) * 1.3
						var gc: Color = e.col
						gc.a = al * (0.20 + 0.08 * float(k)) * gf
						n = _figure(n, Vector2(feet.x + bx2, feet.y), d, 16.0, Vector2(feet.x + bx2 + d * 30.0, feet.y + 56.0).lerp(contact, fr2), gc, false, zb + 0.1 * float(k), minpx)
				var back_pt: Vector2 = feet + Vector2(-d * 30.0, 60.0)
				var ctrl: Vector2 = (back_pt + contact) * 0.5 + Vector2(0.0, 34.0)
				var cl: float = VfxPress.p("crescent_life")
				var cf: float = 1.0 - clampf(st / cl, 0.0, 1.0)
				var cc: Color = e.col
				cc.a = al * 0.75 * cf
				var segs: int = 3 if red else 5
				var prev: Vector2 = back_pt
				for k in range(segs):
					var tq: float = float(k + 1) / float(segs)
					var q: Vector2 = (1.0 - tq) * (1.0 - tq) * back_pt + 2.0 * (1.0 - tq) * tq * ctrl + tq * tq * contact
					var wq: float = 6.0 + 28.0 * sin(PI * (tq - 0.5 / float(segs)))
					n = _put(n, (prev + q) * 0.5, (q - prev).normalized(), (q - prev).length() * 1.15, wq, zb + 0.3, cc, 0.6, 0.6, SHAPE_STREAK)
					prev = q
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
		var wk: float = clampf((w.t + a) / 24.0, 0.0, 1.0)
		var wr: float = lerpf(VfxPress.p("wind_r"), 9.0, 1.0 - pow(1.0 - wk, 1.5))
		var wc: Color = w.col
		wc.a = al * (0.35 + 0.65 * wk)
		var wd: float = _dir_of(S, s)
		n = _put(n, Vector2(wrx + wd * 14.0, S.fighters[s].y + 54.0), Vector2(1.0, 0.0), wr * 2.0, wr * 2.0, host.fighter_z(s, a) + Z_FX + 6.0, wc, minf(0.5, (3.0 + 3.0 * wk) / wr), 0.0, SHAPE_RING)
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
