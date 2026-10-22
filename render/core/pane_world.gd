class_name PaneWorld
extends Node3D
## One camera's view of the world (docs/camera/split-screen.md section 11): the camera rig, the planet, the fighters,
## the beams, the particles and the sky, and the per-camera material state they draw with (RenderMats). The main
## scene holds one in its own world. Camera's split screen puts two in SubViewports with a World3D each
## (main.gd make_pane and move_pane0).
##
## The first pane runs the world's render-side logic: the ground uploads, the props, the flight and the startle, and
## the head flashes' state machines with their hooks to Audio and UI. A second pane has it as its `source`: it shares
## the planet's meshes, ground data and props, and its fighters' flashes follow the first pane's. Its own nodes and
## materials carry its camera (the floating origin, the curvature, the sky, the fore rule, the crowd's boost, the
## fighters' anchors), so a second pane costs nodes and draw submission, not memory or logic.

const SHADOW_SHADER: Shader = preload("res://render/shaders/shadow.gdshader")
## How a building between the camera and a fighter is opened (docs/rendering/README.md, "Occlusion").
const OCCL_HOLE := 0     # a round hole around him (Orb's pick)
const OCCL_STUB := 1     # the building cut down to a low stub

var mats := RenderMats.new()
var cam_rig := CameraRig.new()
var env := WorldEnvironment.new()
var planet := PlanetView.new()
var fighters_root := Node3D.new()
var beams := BeamView.new()
var particles := ParticleView.new()
var vfx_layer := VfxLayer.new()    # VFX's drawing for this pane (render/vfx/); main sets its hub, which every pane shares
var fighter_views: Array = []
var shadows: Array = []            # per fighter: the ground shadow under him (render/shaders/shadow.gdshader)
var source: PaneWorld = null       # a second pane: the first, whose world it draws
var view_cam_x: float = 0.0        # this frame's camera's wrapped world x
var drift: float = 0.0             # the slow drift's angle this frame (radians; World's window 2), set by main; 0 off
var markers: bool = true           # the fighters' head markers (the stance badge); main's inset pane has none
var occlusion: int = OCCL_HOLE     # main sets it (a debug toggle)
## Camera's request for this pane's cut-away, each frame (docs/camera/camera-v2.md section 6). Every key is optional:
## request (false: no cut-away, for a shot that wants the wall whole), radius_px (the hole's radius; 0 or absent:
## RenderLook's rule), only (a fighter slot: only his; absent or -1: both fighters').
var cutaway: Dictionary = {}
var focus_z: float = 0.0            # the depth of this pane's focus plane this frame (Camera's dolly: SplitFrame.focus_z, which main hands over when the frame carries it). 0: the fighter plane, as ever
var near_lobbies: bool = false       # Camera's depth follow is on (main sets it each frame): a tower near the lens in the middle of the view opens its lobby whether or not the fight is behind it (_open_floors)
var occluded: Array = []           # per fighter: a building stands between this pane's camera and him (for Camera)
var _join: float = 0.0             # 0 to 1: the two fighters' holes grown into one
var _join_t: float = -1.0
## The foreground row's patch as drawn (RenderLook.PATCH_*): the fighters' ends of it (wrapped world x, y), its reach
## past each, its radius in world units, the tick times before which each reach and the radius do not shrink, and the
## tick time it was last set (-1: the next one snaps). `patch` is this frame's, for tools and for Camera: {a, b: its ends in this pane's pixels, r: its
## radius in pixels, size: its area in square fighter heights, sink: {building: how far it is lowered, 0 to 1}}.
var _patch_a := Vector2.ZERO
var _patch_b := Vector2.ZERO
var _patch_ext := Vector2.ZERO
var _patch_r: float = 0.0
var _patch_hold := Vector3(-1.0, -1.0, -1.0)
var _patch_t: float = -1.0
var patch: Dictionary = {}
var _cue := PackedFloat32Array()   # per fighter: his lane cue, 0 to 1
var _cue_z := PackedFloat32Array() # ... his depth at the last tick seen,
var _cue_want: Array = []          # ... and whether the cue was wanted then
var _cue_t: float = -1.0
var _pair: float = 0.0             # the pair's mark: how far it is up, 0 to 1,
var _pair_t: float = -1.0
var _pair_lvl: float = 0.0         # ... its strength (steady, loud after a turn, quieter beside the lane cues),
var _pair_hold: float = -1.0e9     # ... the tick time it stays up to,
var _pair_ang: float = 0.0         # ... the line's angle when it last spoke up, in degrees,
var _pair_loud: float = -1.0e9     # ... and the tick time it is loud until
var _clear: Dictionary = {}        # this pane's see-through region for VFX's clear query (clear_at): the patch's capsule and the opened floors, on its screen
static var _drawing: PaneWorld = null   # the pane whose effects are being drawn: VFX's clear query is asked of it
static var _clear_live: Array = []      # the panes with a see-through region (a query outside a draw asks them all)
static var clouds_on: bool = true          # the sky's clouds (main's --noclouds)
static var sky_calm: bool = false          # reduced motion: the clouds stand still and nothing parts (main sets it)
static var sky_react_on: bool = false      # the clouds part for a fighter at tier 3 or more: off unless asked for (main's --skyreact; QA's GB-002)
static var flash_calm: bool = false        # reduced flashing or reduced motion: the grooves' glow and char are drawn calm (main sets it)
static var pan_haze_on: bool = RenderLook.PAN_HAZE_DEFAULT   # the buildings melt toward the sky while this pane's camera travels fast (main's --panhaze and --nopanhaze)
var pan_haze: float = 0.0                  # 0 to 1, this frame
var pan_whip: float = 0.0                  # 0 to 1, this frame: the whip haze (RenderLook.PAN_WHIP), in every match
var fore_low := Vector2(NAN, NAN)          # the fighter plane's lowest ground and top in this pane's view, eased (RenderLook.FORE_FAR)
var fore_sweep: float = 0.0                # how far this pane's camera travels along x a tick, eased
var _fl_x: float = NAN                     # the camera's x and the time at the last frame the rule's reading saw
var _fl_t: float = NAN
var _sky_glows: int = 0                    # the town glows handed to the sky last frame
var _glow_seen: Dictionary = {}            # a town's index -> how far its glow has come into this pane's view, 0 to 1 (it comes in over SKY_GLOW_IN_S)
var _glow_t: float = NAN
var _pan_x: float = NAN                    # the camera's x and the time at the last frame seen
var _pan_t: float = NAN
var _pan_ground := Color.BLACK             # the ground's colour under the camera, eased (what a hazed wall melts toward below the horizon)
var _react := PackedFloat32Array()         # per fighter: the sky's reaction to him, 0 to 1 (tier 3 half, tier 4 full)
var _react_t: float = -1.0
var _sky_mat: ShaderMaterial
var _sky_st: Dictionary = {}               # this pane's place in the dynamic sky (SkyDrive.pane)
var _wl_body: Array = []                   # the world's light on the fighters' bodies, [mul, add] (SkyDrive.world_at)
var _wl_seen: Array = []                   # the world's light this pane last handed on (SkyDrive.world, shared by every pane)


func _init() -> void:
	name = "Pane"
	cam_rig.name = "Camera"
	env.name = "Environment"
	planet.name = "Planet"
	fighters_root.name = "Fighters"
	beams.name = "Beams"
	particles.name = "Particles"
	vfx_layer.name = "Vfx"
	planet.mats = mats
	for n in [cam_rig, env, planet, fighters_root, beams, particles, vfx_layer]:
		add_child(n)
	_setup_environment()


## A new match: the planet and the fighters. A second pane builds after the first.
func build(S: SimState) -> void:
	planet.source = source.planet if source != null else null
	planet.build(S)
	build_fighters(S)
	vfx_layer.build(S)


## The fighters' views, built from the sim's fighters for a new match. (A lane colour that changes later, a
## colour-blind preset, is taken by the same views: FighterView.set_lane.)
func build_fighters(S: SimState) -> void:
	for v in fighter_views:
		fighters_root.remove_child(v)
		v.free()
	fighter_views.clear()
	for i in range(S.fighters.size()):
		var v := FighterView.new()
		fighters_root.add_child(v)
		v.markers = markers
		v.build(S.fighters[i])
		if source != null and i < source.fighter_views.size():
			v.flash_view.set_leader(source.fighter_views[i].flash_view)
		fighter_views.append(v)
		if i >= shadows.size():
			# kept across matches (its material is tracked for the pane's bend once)
			var sh := MeshInstance3D.new()
			sh.name = "Shadow%d" % i
			sh.mesh = _shadow_mesh()
			var sm := ShaderMaterial.new()
			sm.shader = SHADOW_SHADER
			mats.track(sm)
			sh.material_override = sm
			sh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			fighters_root.add_child(sh)
			shadows.append(sh)


## Draw one frame from a camera: its wrapped world x (float64), cam.y and cam.z (the reference camera's height and
## zoom, as SimHost.camera gives them), its screen shake in pixels and its pitch in degrees (CameraRig). The first pane
## also applies the world's changes.
func render(host: SimHost, a: float, cam_x: float, cam: Vector3, jitter: Vector2, pitch: float = 0.0, roll: float = 0.0) -> void:
	var S: SimState = host.S
	var vp: Vector2 = get_viewport().get_visible_rect().size
	view_cam_x = cam_x
	cam_rig.frame(cam.y, cam.z, jitter, vp.y, pitch, focus_z)
	if roll != 0.0:
		cam_rig.basis = cam_rig.basis * Basis(Vector3.BACK, deg_to_rad(roll))   # the climaxes' dutch tilt (RenderCameraRoll), about the view axis
	planet.set_focus(focus_z)
	planet.set_drift(tan(drift))
	if _sky_mat != null:
		_sky_mat.set_shader_parameter("sky_turn", drift)
	planet.set_crowd_near(S.depthOn)
	_pan_haze(host, a, cam_x, vp)
	_sky_drive(host, a, cam_x)
	planet.set_camera(cam_rig.position)
	_fore_low(host, a, cam_x, vp)
	planet.set_calm(flash_calm)
	_view_cues(cam, vp)
	if source == null and host.vfx.enabled and host.vfx.react_enabled:
		planet.blow_windows(S, host.vfx.react.blowouts)   # the facades' windows go out with VFX's glass
	planet.update(S, cam_x, host.impact.heat, host.impact.heat_changed)
	for i in range(fighter_views.size()):
		var v: FighterView = fighter_views[i]
		var pose: Vector3 = host.fighter_pose(i, a)
		var wx: float = host.fighter_x(i, a)
		var vx: float = SimWrap.sdx(cam_x, wx)
		v.depth = host.fighter_z(i, a)
		v.sag = mats.sag(vx, v.depth)
		v.markers = markers and not host.intro_running()   # no head badge before the clock: UI's HUD is hidden too
		# The intro: a fighter is out of sight until his fall starts (the sim holds him high above his spot until
		# then), and so is his shadow on the ground he will land on.
		v.visible = not host.intro_held(i)
		v.hit_white_T = host.hit_flash_T[i] if i < host.hit_flash_T.size() else -INF
		v.update(S, S.fighters[i], pose, vx, cam.z)
		_place_shadow(S, i, wx, vx, pose.y, v.depth, v.visible)
	_occlusion(S, cam_x, vp)
	_lane_cues(host, a)
	_pair_mark(host, a)
	_sky_react(host, cam_x)
	_drawing = self   # VFX's clear query is this pane's while its effects are drawn
	vfx_layer.update(host, a, cam_x, cam.z, vp.x)
	_drawing = null
	beams.update(S, cam_x, cam.z, host)
	particles.deep = S.depthOn
	particles.widen = cam_rig.half_width(vp.x) / maxf(cam_rig.dist, 1.0) if S.depthOn else 0.0
	particles.update(host.fxv, host.impact, cam_x, cam.z, cam_rig.half_width(vp.x, RenderLook.Z_PARTICLES - focus_z), fighter_views)


## The dynamic sky for this pane's camera (render/core/sky_drive.gd; docs/rendering/dynamic-sky.md): the four bands'
## colours for its place round the planet, the drift and the mood, rate limited, to the sky and to every material that
## fogs toward it; the stars' strength; and the glow of up to two wrecked towns on its screen.
func _sky_drive(host: SimHost, a: float, cam_x: float) -> void:
	var out: Dictionary = host.sky.pane(_sky_st, cam_x, (float(host.ticks) + a) * SimConst.DT)
	if out.changed:
		for bi in range(4):
			_sky_mat.set_shader_parameter(SkyDrive.UNIFORMS[bi], out.cols[bi])
			mats.set_sky(SkyDrive.UNIFORMS[bi], out.cols[bi])
		_sky_mat.set_shader_parameter("star_low", out.star_low)
		_sky_mat.set_shader_parameter("star_turn", RenderLook.STAR_TURN * float(_sky_st.p))
	if host.sky.world != _wl_seen:   # the world's light, one for every pane (SkyDrive._light)
		_wl_seen = host.sky.world
		planet.set_world_light(host.sky.world, host.sky.win)
		_wl_body = host.sky.world[RenderLook.WORLD_LAYERS.find("bodies")]
	for v in fighter_views:
		v.set_world_light(_wl_body)
	# A town's glow comes into view over at least SKY_GLOW_IN_S, however fast the camera brings the town onto the
	# screen, and leaves the same way; a pane that was not being drawn starts from what is in front of it.
	var now: float = (float(host.ticks) + a) * SimConst.DT
	var gdt: float = now - _glow_t
	var snap: bool = is_nan(gdt) or gdt < 0.0 or gdt > 0.5
	_glow_t = now
	var glows: Array = [Vector4(0.0, 0.0, -1.0, 0.0), Vector4(0.0, 0.0, -1.0, 0.0)]
	var n: int = 0
	for ti in range(host.sky.towns.size()):
		var tw: Dictionary = host.sky.towns[ti]
		var at := Vector3(SimWrap.sdx(cam_x, float(tw.x)), 0.0, 0.0)
		var on: float = _on_screen(at) if float(tw.glow) > 0.004 else 0.0
		var seen: float = on if snap else move_toward(float(_glow_seen.get(ti, 0.0)), on, gdt / RenderLook.SKY_GLOW_IN_S)
		_glow_seen[ti] = seen
		var w: float = float(tw.glow) * minf(seen, on)   # never more than is on the screen now
		if w > 0.0 and n < 2:
			var d: Vector3 = (at - cam_rig.position).normalized()
			glows[n] = Vector4(d.x, d.y, d.z, w)
			n += 1
	if n > 0 or _sky_glows > 0:
		_sky_mat.set_shader_parameter("sky_glow", glows)
	_sky_glows = n


## The foreground rule's reading near the lens (RenderLook.FORE_FAR): the fighter plane's lowest ground and top within
## FORE_LOW_REACH half widths of this pane's camera, and how far the camera travels along x a tick, each eased over
## FORE_LOW_S of match time (a new match or a seek takes them at once). Presentation only: it reads the sim's profile.
func _fore_low(host: SimHost, a: float, cam_x: float, vp: Vector2) -> void:
	var S: SimState = host.S
	var t: float = (float(host.ticks) + a) * SimConst.DT
	var dt: float = t - _fl_t
	if not is_nan(_fl_t) and dt == 0.0:
		return   # the same instant again (a frozen tick)
	var reach: float = RenderLook.FORE_LOW_REACH * cam_rig.half_width(vp.x)
	var nc: int = SimConst.NC
	var c0: int = int(floor((cam_x - reach) / SimConst.COL))
	var c1: int = int(ceil((cam_x + reach) / SimConst.COL))
	var lo_g: float = INF
	var lo_t: float = INF
	for c in range(c0, c1 + 1):
		var i: int = posmod(c, nc)
		var gy: float = S.base[i] + S.deform[i]
		var wd: float = S.water[i]
		lo_g = minf(lo_g, gy)
		lo_t = minf(lo_t, gy + (wd if wd >= WorldWater.MIN_DEPTH else 0.0))
	var sweep: float = 0.0
	if is_nan(_fl_x) or dt < 0.0 or dt > 0.5:
		fore_low = Vector2(lo_g, lo_t)
		fore_sweep = 0.0
	else:
		sweep = absf(SimWrap.sdx(_fl_x, cam_x)) / dt * SimConst.DT
		var k: float = clampf(dt / RenderLook.FORE_LOW_S, 0.0, 1.0)
		fore_low = fore_low.lerp(Vector2(lo_g, lo_t), k)
		fore_sweep = lerpf(fore_sweep, sweep, k)
	_fl_x = cam_x
	_fl_t = t
	planet.set_fore_low(fore_low.x, fore_low.y, fore_sweep)


## The pan haze (RenderLook.PAN_HAZE_*; docs/rendering/flash-sources.md): how fast this pane's camera travels along the
## ground, in screen widths a second of match time, eased in quickly and out slowly, for building.gdshader. A facade
## that sweeps past flips its window grid and its edge against the sky many times a second; hazed, it does not.
## Presentation only: it reads the camera this pane was given and writes a shader parameter.
func _pan_haze(host: SimHost, a: float, cam_x: float, vp: Vector2) -> void:
	var t: float = (float(host.ticks) + a) * SimConst.DT
	var dt: float = t - _pan_t
	var ground: Color = RenderLook.col(RenderLook.BIOME[WorldBiomes.biomeAt(SimWrap.wrap(cam_x))])
	if is_nan(_pan_x) or dt < 0.0 or dt > 0.5:
		pan_haze = 0.0   # a new match, or a seek
		pan_whip = 0.0
		_pan_ground = ground
	elif dt > 0.0:
		_pan_ground = _pan_ground.lerp(ground, clampf(dt / RenderLook.PAN_HAZE_OUT_S, 0.0, 1.0))
		var speed: float = absf(SimWrap.sdx(_pan_x, cam_x)) / maxf(2.0 * cam_rig.half_width(vp.x), 1.0) / dt
		if speed < RenderLook.PAN_HAZE_CUT:
			var want: float = smoothstep(RenderLook.PAN_HAZE_FROM, RenderLook.PAN_HAZE_FULL, speed) if pan_haze_on else 0.0
			pan_haze = move_toward(pan_haze, want, dt / (RenderLook.PAN_HAZE_IN_S if want > pan_haze else RenderLook.PAN_HAZE_OUT_S))
			var whip: float = smoothstep(RenderLook.PAN_WHIP.x, RenderLook.PAN_WHIP.y, speed) if RenderLook.PAN_WHIP_ON else 0.0
			pan_whip = move_toward(pan_whip, whip, dt / (RenderLook.PAN_HAZE_IN_S if whip > pan_whip else RenderLook.PAN_HAZE_OUT_S))
	else:
		return   # the same instant again (a frozen tick): nothing moves
	_pan_x = cam_x
	_pan_t = t
	mats.set_haze(pan_haze, _pan_ground, pan_whip)


## A pane's cut-away request for this frame, from Camera's frame: its `cutaway` a pane (request, only, radius_px), with
## `cut` set when its `clear` a pane says the picture has cut (docs/camera/city-in-depth.md section 3): on that frame
## the patch, the stubs, the lobbies and the towers' shares are at their targets. The rest of `clear` is not read yet.
## The dictionary given is not changed.
static func request(cutaway_i: Dictionary, clear_i) -> Dictionary:
	if clear_i is Dictionary and bool((clear_i as Dictionary).get("cut", false)) and not bool(cutaway_i.get("cut", false)):
		var r: Dictionary = cutaway_i.duplicate()
		r["cut"] = true
		return r
	return cutaway_i


## Keep the fighters in view behind buildings, by this pane's method. Either way a building counts as in front of a
## fighter when it stands between this pane's camera and his chest, and the building a launched fighter is aimed at
## stays whole (its cut floors show him inside).
## The hole: a dithered circle around each fighter, cutting whatever of a building is nearer the camera than he is. It
## is always there, so a wall is eaten as he passes behind it and nothing pops. When both fighters are in view within
## HOLE_JOIN of the screen's width and buildings are in front of at least two of the three points (each fighter and
## the point between them), each hole stretches to the other fighter, so one opening shows both and the gap between
## them. A fighter behind a wall and one out in the open keep two round holes.
## The stub: the buildings near a fighter's sight line, and those in front of the stretch between two fighters in view
## together, sink to low stubs and stand again when no longer in the way.
func _occlusion(S: SimState, cam_x: float, vp: Vector2) -> void:
	var n: int = fighter_views.size()
	var eye: Vector3 = cam_rig.position
	var on: bool = bool(cutaway.get("request", true))
	var only: int = int(cutaway.get("only", -1))
	if bool(cutaway.get("cut", false)):
		# Camera's cut flag: nothing eases across a cut. The patch, the stubs and the open floors are at their targets
		# on this frame.
		planet.snap_stubs()
		planet.snap_open()
		_patch_t = -1.0
		_join_t = -1.0
	var chest: Array = []
	var px: Array = []
	var tall := PackedFloat32Array()
	var seen: Array = []
	var aim := PackedInt32Array()
	var near_view := Rect2(-0.25 * vp, 1.5 * vp)
	var xa: float = eye.x
	var xb: float = eye.x
	var z_min: float = INF
	for i in range(n):
		var v: FighterView = fighter_views[i]
		var c: Vector3 = v.position + Vector3(0.0, FighterView.HEIGHT * 0.5, 0.0)
		var vis: bool = not cam_rig.is_position_behind(c)
		var p: Vector2 = cam_rig.unproject_position(c) if vis else Vector2.ZERO
		vis = vis and near_view.has_point(p)
		chest.append(c)
		px.append(p)
		tall.append(absf(cam_rig.unproject_position(v.position + Vector3(0.0, FighterView.HEIGHT, 0.0)).y - cam_rig.unproject_position(v.position).y) if vis else 0.0)
		seen.append(vis)
		var f = S.fighters[i]
		aim.append(int(f.aimB) if int(f.aimB) >= 0 and int(f.aimB) < S.buildings.size() else -1)
		if vis:
			xa = minf(xa, c.x)
			xb = maxf(xb, c.x)
			z_min = minf(z_min, c.z)
	var cand: Array = planet.occluder_candidates(S, cam_x, xa, xb, z_min, RenderLook.STUB_MARGIN) if z_min < INF else []
	occluded.resize(n)
	for i in range(n):
		occluded[i] = seen[i] and not cand.is_empty() and planet.occluders(S, cand, eye, cam_x, chest[i], RenderLook.OCCL_MARGIN, aim[i], {})
	var pair: bool = n == 2 and only < 0 and seen[0] and seen[1] and (px[0] as Vector2).distance_to(px[1]) < RenderLook.HOLE_JOIN * vp.x
	# The stubs.
	var want: Dictionary = {}
	if on and occlusion == OCCL_STUB and not cand.is_empty():
		for i in range(n):
			if seen[i] and (only < 0 or only == i):
				planet.occluders(S, cand, eye, cam_x, chest[i], RenderLook.STUB_MARGIN, aim[i], want)
		if pair:
			var steps: int = clampi(int((chest[0] as Vector3).distance_to(chest[1]) / RenderLook.STUB_SPAN), 1, 8)
			for k in range(1, steps):
				planet.occluders(S, cand, eye, cam_x, (chest[0] as Vector3).lerp(chest[1], float(k) / steps), RenderLook.OCCL_MARGIN, -1, want)
			for bi in aim:
				want.erase(bi)
	# Row 0, the foreground: one patch for the whole action, and the buildings under a big one lowered.
	# With depth on the same patch works through every row in front of the action, and a tall building opens floors
	# (RenderLook.OPEN_*): the pane's own hole and stubs are for a match with depth off.
	var soft: Dictionary = {}
	var deep: bool = S.depthOn
	var front: Array = _row0_patch(S, cam_x, vp, chest, seen, tall, soft, only, aim) if on and (deep or planet.has_row0()) else []
	if front.is_empty():
		patch = {}
		_patch_t = -1.0
	var gone: Dictionary = {}
	if deep:
		want.clear()
		# Camera's near-clip rule (RenderLook.NEAR_CLIP): a building of the patch's kind too near the lens is not
		# something to open. Nearer than the first distance it is not drawn; nearer than the second it is its stub.
		for fc in planet.row0_faces(S, cam_x, cam_rig.half_width(vp.x) + 600.0, true):
			var d_lens: float = eye.z - float(fc[5])
			if d_lens < RenderLook.NEAR_CLIP.y:
				soft[int(fc[0])] = 1.0
				if d_lens < RenderLook.NEAR_CLIP.x:
					gone[int(fc[0])] = true
	planet.set_stubs(S, want, soft, gone)
	_open_floors(S, cam_x, vp, aim)
	_clear_region(S, cam_x, cand, eye, chest, seen, front)
	# The holes.
	var holes: Array = []
	var inv: Transform3D = cam_rig.transform.affine_inverse()
	for i in range(n):
		if not on or occlusion != OCCL_HOLE or not seen[i] or (only >= 0 and only != i):
			holes.append([Vector3.ZERO, 0.0, 0.0, Vector3.ZERO, 0.0, 0.0])
			continue
		var r: float = float(cutaway.get("radius_px", 0.0))
		if r <= 0.0:
			r = maxf(RenderLook.HOLE_PX, RenderLook.HOLE_BODY * tall[i])
		var near: float = -(inv * (chest[i] as Vector3)).z - RenderLook.HOLE_GAP
		if aim[i] >= 0:
			var b = S.buildings[aim[i]]
			if b.d > 0.0:
				near = minf(near, -(inv * Vector3(SimWrap.sdx(cam_x, b.x), (chest[i] as Vector3).y, b.z + b.d * 0.5)).z - RenderLook.HOLE_GAP)
		holes.append([chest[i], r, near, chest[i], r, near])
	var join: bool = false
	if pair and on and occlusion == OCCL_HOLE and not cand.is_empty() and (occluded[0] or occluded[1]):
		var mid: bool = planet.occluders(S, cand, eye, cam_x, ((chest[0] as Vector3) + chest[1]) * 0.5, RenderLook.OCCL_MARGIN, -1, {})
		join = int(occluded[0]) + int(occluded[1]) + int(mid) >= 2
	var dt: float = clampf(PlanetView.tick_time(S) - _join_t, 0.0, 0.1) if _join_t >= 0.0 else 1.0e3
	_join_t = PlanetView.tick_time(S)
	_join = move_toward(_join, 1.0 if join else 0.0, dt / RenderLook.HOLE_JOIN_S)
	if _join > 0.0 and n == 2 and float(holes[0][1]) > 0.0 and float(holes[1][1]) > 0.0:
		# Each hole reaches toward the other fighter, its radius and its depth easing to his along the way.
		var e: float = _join * _join * (3.0 - 2.0 * _join)
		var r0: Array = [holes[0][1], holes[0][2]]
		var r1: Array = [holes[1][1], holes[1][2]]
		holes[0][3] = (chest[0] as Vector3).lerp(chest[1], e)
		holes[0][4] = lerpf(r0[0], r1[0], e)
		holes[0][5] = lerpf(r0[1], r1[1], e)
		holes[1][3] = (chest[1] as Vector3).lerp(chest[0], e)
		holes[1][4] = lerpf(r1[0], r0[0], e)
		holes[1][5] = lerpf(r1[1], r0[1], e)
	if deep:
		var none: Array = [Vector3.ZERO, 0.0, 0.0, Vector3.ZERO, 0.0, 0.0]
		holes = [front if not front.is_empty() else none, none]
	planet.set_holes(holes, front, deep)


## This pane's see-through region, for VFX's clear query (docs/vfx/depth.md section 4; clear_at): the patch's capsule on
## this pane's screen, if a building of the patch's kind stands in front of a fighter (the patch is then a window
## through it), and the face of every opened floor. None with depth off, or with nothing opened and nothing in front.
func _clear_region(S: SimState, cam_x: float, cand: Array, eye: Vector3, chest: Array, seen: Array, front: Array) -> void:
	_clear = {}
	if not S.depthOn or not patch.has("wa"):
		_clear_live.erase(self)
		return
	var hide: Dictionary = {}
	for i in range(chest.size()):
		if seen[i]:
			planet.occluders(S, cand, eye, cam_x, chest[i], RenderLook.OCCL_MARGIN, -1, hide)
	var cuts: bool = false
	for bi in hide:
		cuts = cuts or planet.takes_patch(bi)
	var rects: Array = []
	for f in planet.open_faces(S, cam_x):
		var r := Rect2()
		var n: int = 0
		for sx in [-0.5, 0.5]:
			for y in [float(f[3]), float(f[4])]:
				var w := Vector3(float(f[0]) + sx * float(f[1]), y, float(f[2]))
				if cam_rig.is_position_behind(w):
					continue
				var s: Vector2 = cam_rig.unproject_position(w)
				r = Rect2(s, Vector2.ZERO) if n == 0 else r.expand(s)
				n += 1
		if n == 4:
			rects.append(r)
	if not cuts and rects.is_empty():
		_clear_live.erase(self)
		return
	_clear = {"wa": patch["wa"], "wb": patch["wb"], "pa": patch["a"], "pb": patch["b"], "pr": patch["r"], "patch": cuts and not front.is_empty(), "rects": rects}
	if not _clear_live.has(self):
		_clear_live.append(self)


## What this pane's see-through region leaves to be seen of a thing at world point p that a building threw (glass,
## cladding, stage dust): 1 all of it, 0 none. A point at the fight's depth or behind it is always 1: the fight's own
## effects are never hidden. Nearer the camera than the fight, a point over an opened floor's face is 0, and one inside
## the patch fades out toward its middle as the patch's own edge does.
func clear_at(p: Vector3) -> float:
	if _clear.is_empty():
		return 1.0
	var v := Vector3(SimWrap.sdx(view_cam_x, p.x), p.y, p.z)
	var wa: Vector3 = _clear["wa"]
	var wb: Vector3 = _clear["wb"]
	var t: float = clampf((v.x - wa.x) / (wb.x - wa.x), 0.0, 1.0) if absf(wb.x - wa.x) > 1.0 else 0.5
	if v.z <= lerpf(wa.z, wb.z, t) + RenderLook.CLEAR_GAP or cam_rig.is_position_behind(v):
		return 1.0
	var s: Vector2 = cam_rig.unproject_position(v)
	for r in _clear["rects"]:
		if (r as Rect2).has_point(s):
			return 0.0
	if bool(_clear["patch"]):
		var a: Vector2 = _clear["pa"]
		var ab: Vector2 = (_clear["pb"] as Vector2) - a
		var u: float = clampf((s - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
		return smoothstep(RenderLook.PATCH_EDGE.x, RenderLook.PATCH_EDGE.x + RenderLook.PATCH_EDGE.y, (s - a - ab * u).length() / maxf(float(_clear["pr"]), 0.001))
	return 1.0


## VFX's clear query (VfxHub.clear_query; main sets it in a match with depth on): the pane being drawn answers. Asked
## outside a draw (a thing about to be thrown), the most any pane with a region would show of it; 1 with none.
static func clear_query(p: Vector3) -> float:
	if _drawing != null:
		return _drawing.clear_at(p)
	var best: float = -1.0
	for pw in _clear_live:
		if is_instance_valid(pw):
			best = maxf(best, (pw as PaneWorld).clear_at(p))
	return best if best >= 0.0 else 1.0


## The towers' lobbies (RenderLook.OPEN_*; Orb, 2026-10-12): with depth on, every tower with a lobby
## (PlanetView.opens) standing between this pane's camera and the line of the patch's capsule is asked two things.
## Is the action seen under its lobby's ceiling (the sight line to a fighter's feet passes under it): then the lobby
## opens. Is it seen over the ceiling (the sight line to OPEN_HEAD above his head passes over it): then the tower takes
## its share of the patch, as a low building does. The capsule is the patch's own as drawn (both fighters, the gap, what
## is travelling), so the two follow one action. A tower answers for the line itself (within OPEN_SIDE), not for the
## room the patch leaves round it: a pair standing clear in an avenue opens neither corner. No patch (no fighter in
## view, or Camera's request off): nothing is asked, and lobbies shut and shares fall after their holds. The building a
## launched fighter is aimed at stays whole. Presentation only.
func _open_floors(S: SimState, cam_x: float, vp: Vector2, aim: PackedInt32Array) -> void:
	if not S.depthOn:
		return
	var want: Dictionary = {}
	var left: float = -1.0
	var patch_px := Vector2.ZERO
	if patch.has("wa"):
		var eye: Vector3 = cam_rig.position
		var wa: Vector3 = patch["wa"]
		var wb: Vector3 = patch["wb"]
		var r: float = float(patch["wr"])
		left = float(patch["left"])
		patch_px = Vector2((patch["a"] as Vector2).distance_to(patch["b"]), float(patch["r"]))
		var feet: float = 0.5 * FighterView.HEIGHT
		var head: float = 0.5 * FighterView.HEIGHT + RenderLook.OPEN_HEAD
		for bi in planet.occluder_candidates(S, cam_x, minf(eye.x, minf(wa.x, wb.x) - r), maxf(eye.x, maxf(wa.x, wb.x) + r), minf(wa.z, wb.z), 0.0):
			if not planet.opens_floors(bi) or aim.has(bi):
				continue
			var span: Vector2 = planet.lobby_span(S, bi)
			if span == Vector2.ZERO:
				continue
			var ceil_y: float = span.y - RenderLook.OPEN_BEAM
			var b = S.buildings[bi]
			var zd: Vector2 = PlanetView._depth(b)
			var zf: float = zd.x + zd.y * 0.5
			var bx: float = SimWrap.sdx(cam_x, b.x)
			var hit: bool = false
			var under: bool = false
			var over: bool = false
			for k in range(7):
				var p: Vector3 = wa.lerp(wb, float(k) / 6.0)
				if zf <= p.z + 1.0 or eye.z - p.z < 1.0:
					continue   # the building does not stand in front of this part of the action
				for zface in [zf, maxf(zd.x - zd.y * 0.5, p.z)]:
					var s: float = (zface - p.z) / (eye.z - p.z)
					if absf(p.x + (eye.x - p.x) * s - bx) > 0.5 * b.w + RenderLook.OPEN_SIDE * (1.0 - s):
						continue
					hit = true
					under = under or lerpf(p.y - feet, eye.y, s) < ceil_y
					over = over or lerpf(p.y + head, eye.y, s) > ceil_y
			if hit:
				# The pixels a unit of its height covers on this pane's screen: its face's width in view, times the scale there.
				var c0: Vector2 = cam_rig.unproject_position(Vector3(bx - 0.5 * b.w, eye.y, zf))
				var c1: Vector2 = cam_rig.unproject_position(Vector3(bx + 0.5 * b.w, eye.y, zf))
				var wpx: float = maxf(minf(c1.x, vp.x) - maxf(c0.x, 0.0), 0.0)
				var ppu: float = absf(cam_rig.unproject_position(Vector3(bx, eye.y + 100.0, zf)).y - cam_rig.unproject_position(Vector3(bx, eye.y, zf)).y) / 100.0
				want[bi] = Vector3(1.0 if under else 0.0, 1.0 if over else 0.0, maxf(wpx * ppu, 0.001))
	if near_lobbies:
		# Camera's rule for a near tower (2026-10-13): its dolly brings the lens into the rows, and a face 340 units
		# from the lens is wider than the screen. A tower with a lobby whose near face is inside NEAR_CLIP.y of the
		# lens, and which stands in the middle NEAR_MID of the view, opens its lobby whether or not the fight is behind
		# it (one the fight is behind is in `want` already). One wholly behind the lens is not drawn at all.
		var lens: Vector3 = cam_rig.position
		var reach: float = RenderLook.NEAR_CLIP.y
		var mid: float = RenderLook.NEAR_MID * cam_rig.half_width(vp.x, lens.z - reach - focus_z)
		for bi in planet.occluder_candidates(S, cam_x, lens.x - mid, lens.x + mid, lens.z - reach, 400.0):
			if want.has(bi) or not planet.opens_floors(bi) or aim.has(bi) or planet.lobby_span(S, bi) == Vector2.ZERO:
				continue
			var b = S.buildings[bi]
			var zd: Vector2 = PlanetView._depth(b)
			if zd.x - zd.y * 0.5 >= lens.z:
				continue
			var far: float = maxf(lens.z - (zd.x + zd.y * 0.5), 60.0)   # the lens to its near face (the lens may stand inside it)
			var half: float = cam_rig.half_width(vp.x, lens.z - far - focus_z)
			if absf(SimWrap.sdx(cam_x, b.x) - lens.x) > 0.5 * b.w + RenderLook.NEAR_MID * half:
				continue
			var ppu: float = 0.5 * vp.x / maxf(half, 1.0)
			want[bi] = Vector3(1.0, 0.0, maxf(minf(b.w * ppu, vp.x) * ppu, 0.001))
	planet.set_open(S, want, vp, left, patch_px)


## The next frame's stubs, joined hole and lane cues jump to their targets instead of easing (for tools that pose a
## frame).
## The foreground row's patch (RenderLook.PATCH_*; Orb, 2026-10-11): one dithered window through row 0 for the whole
## action in this pane. Returns it as a hole for the row's material ([] when no fighter is in view), and fills `soft`
## with the buildings a big patch lowers ({building: 0 to 1}). chest, seen, tall: per fighter, his chest as drawn, whether
## this pane sees him, his drawn height in pixels; only: Camera's request (a fighter slot: the patch is his alone).
## Presentation only: it reads the sim and this pane's camera.
## With depth on (S.depthOn) it is the patch for every row: each end lies at its own fighter's depth, so the patch cuts
## what stands in front of their line, the building a launched fighter is aimed at stays whole (aim: per fighter, as for
## his own hole), and a big patch lowers the low buildings of any row that it covers in front of that line.
func _row0_patch(S: SimState, cam_x: float, vp: Vector2, chest: Array, seen: Array, tall: PackedFloat32Array, soft: Dictionary, only: int = -1, aim: PackedInt32Array = PackedInt32Array()) -> Array:
	var deep: bool = S.depthOn
	var ppu: float = 0.0
	var pts: Array = []
	var ends: Array = []   # per point: [his depth, his slot]
	var extra: Array = []
	var z_plane: float = -INF
	for i in range(chest.size()):
		if not seen[i] or (only >= 0 and only != i):
			continue
		var c: Vector3 = chest[i]
		pts.append(Vector2(c.x, c.y))
		ends.append([c.z, i])
		ppu = maxf(ppu, tall[i] / FighterView.HEIGHT)
		z_plane = maxf(z_plane, c.z)
		# Where he will be: a rush, a launch and a zip are in his velocity.
		var f = S.fighters[i]
		var ahead := Vector2(f.vx, f.vy) * RenderLook.PATCH_LOOK_S
		extra.append(Vector2(c.x, c.y) + ahead.limit_length(RenderLook.PATCH_LOOK_MAX))
	if pts.is_empty() or ppu <= 0.0:
		return []
	var hw: float = 0.5 * vp.x / ppu
	# What is travelling: each beam's stretch inside the view, each shot.
	for b in S.beams:
		var o := Vector2(SimWrap.sdx(cam_x, b.ox), b.oy)
		var d := Vector2(b.ux, b.uy)
		var s1: float = b.p * b.len
		var t0: float = 0.0
		var t1: float = s1
		if absf(d.x) > 0.001:
			var ta: float = (-hw - o.x) / d.x
			var tb: float = (hw - o.x) / d.x
			t0 = maxf(t0, minf(ta, tb))
			t1 = minf(t1, maxf(ta, tb))
		elif absf(o.x) > hw:
			continue
		if t1 > t0:
			extra.append(o + d * t0)
			extra.append(o + d * t1)
	for sh in S.shots:
		var sx: float = SimWrap.sdx(cam_x, sh.x)
		if absf(sx) < hw:
			extra.append(Vector2(sx, sh.y))
	# What is wanted: the fighters at its ends, reaching along their line for whatever lies past them, as wide as
	# whatever lies off it.
	var a: Vector2 = pts[0]
	var b2: Vector2 = pts[pts.size() - 1]
	var ea: Array = ends[0]
	var eb: Array = ends[ends.size() - 1]
	if b2.x < a.x:
		var tmp: Vector2 = a
		a = b2
		b2 = tmp
		var etmp: Array = ea
		ea = eb
		eb = etmp
	var u: Vector2 = (b2 - a).normalized() if a.distance_to(b2) > 1.0 else Vector2.RIGHT
	var len0: float = a.distance_to(b2)
	var r_min: float = RenderLook.PATCH_BODY * FighterView.HEIGHT
	var r_want: float = r_min
	var ext_want := Vector2.ZERO
	for p in extra:
		var q: Vector2 = p
		var t: float = (q - a).dot(u)
		ext_want.x = maxf(ext_want.x, -t)
		ext_want.y = maxf(ext_want.y, t - len0)
		r_want = maxf(r_want, absf((q - a).dot(Vector2(-u.y, u.x))) + RenderLook.PATCH_PAD)
	r_want = minf(r_want, maxf(r_min, RenderLook.PATCH_R_MAX * vp.y / ppu))
	ext_want = Vector2(minf(ext_want.x, 2.4 * hw), minf(ext_want.y, 2.4 * hw))
	# As drawn. Each end follows its fighter, and the reach past him and the radius grow, by area: never more than
	# PATCH_AREA_TICK pixels a tick in all, shared by what each asks for. A reach and the radius shrink the same way,
	# but only once nothing has asked them to grow for PATCH_HOLD_S.
	var now: float = PlanetView.tick_time(S)
	var da: Vector2 = Vector2(SimWrap.sdx(cam_x, _patch_a.x), _patch_a.y)
	var db: Vector2 = Vector2(SimWrap.sdx(cam_x, _patch_b.x), _patch_b.y)
	var ext: Vector2 = _patch_ext
	var dr: float = _patch_r
	var left: float = -1.0   # what this frame's area budget has left for the open floors (under 0: the patch jumped; all of theirs)
	var far: float = RenderLook.PATCH_RESEAT * hw
	if _patch_t < 0.0 or now < _patch_t or now - _patch_t > 0.5 or minf(da.x, db.x) > far or maxf(da.x, db.x) < -far:
		da = a
		db = b2
		ext = ext_want
		dr = r_want
		_patch_hold = Vector3(now, now, now)
	else:
		var ticks: float = (now - _patch_t) / SimConst.DT
		var budget: float = RenderLook.PATCH_AREA_TICK * (vp.x * vp.y) / (1024.0 * 768.0) * ticks   # pixels of area this frame
		var r_px: float = maxf(dr * ppu, 1.0)
		# What each part asks for: an end to follow its fighter, a reach to grow or (past its hold) shrink, the radius.
		var ask_a: float = da.distance_to(a)
		var ask_b: float = db.distance_to(b2)
		var grow := Vector3(ext_want.x - ext.x, ext_want.y - ext.y, r_want - dr)
		if grow.x > 0.5:
			_patch_hold.x = now + RenderLook.PATCH_HOLD_S
		elif now < _patch_hold.x:
			grow.x = 0.0
		if grow.y > 0.5:
			_patch_hold.y = now + RenderLook.PATCH_HOLD_S
		elif now < _patch_hold.y:
			grow.y = 0.0
		if grow.z > 0.25:
			_patch_hold.z = now + RenderLook.PATCH_HOLD_S
		elif now < _patch_hold.z:
			grow.z = 0.0
		# The area all of it would turn, and the share of it this frame's budget allows.
		var edge: float = 2.0 * (da.distance_to(db) + ext.x + ext.y) * ppu + TAU * r_px
		var need: float = (ask_a + ask_b + absf(grow.x) + absf(grow.y)) * ppu * 2.0 * r_px + absf(grow.z) * ppu * edge
		var k: float = minf(1.0, budget / maxf(need, 0.001))
		da = da.lerp(a, k)
		db = db.lerp(b2, k)
		ext += Vector2(grow.x, grow.y) * k
		dr += grow.z * k
		left = maxf(budget - need * k, 0.0)
	_patch_t = now
	_patch_a = Vector2(SimWrap.wrap(cam_x + da.x), da.y)
	_patch_b = Vector2(SimWrap.wrap(cam_x + db.x), db.y)
	_patch_ext = ext
	_patch_r = dr
	# Its two ends as drawn: each fighter's, pushed out along their line by its reach.
	var ud: Vector2 = (db - da).normalized() if da.distance_to(db) > 1.0 else Vector2.RIGHT
	da -= ud * ext.x
	db += ud * ext.y
	# Each end's depth: the nearer fighter's for the foreground row's patch; with depth on, its own fighter's.
	var za: float = float(ea[0]) if deep else z_plane
	var zb: float = float(eb[0]) if deep else z_plane
	# On this pane's screen.
	var pa: Vector2 = cam_rig.unproject_position(Vector3(da.x, da.y, za))
	var pb: Vector2 = cam_rig.unproject_position(Vector3(db.x, db.y, zb))
	var pr: float = dr * ppu
	var size: float = (2.0 * dr * da.distance_to(db) + PI * dr * dr) / (FighterView.HEIGHT * FighterView.HEIGHT)
	# The hybrid: a big patch lowers the buildings it covers.
	var big: float = smoothstep(RenderLook.PATCH_BIG.x, RenderLook.PATCH_BIG.y, size)
	var sink: Dictionary = {}
	if big > 0.0:
		var ab: Vector2 = pb - pa
		for fc in planet.row0_faces(S, cam_x, hw, deep):
			if fc.size() > 6:
				# A building of the rows behind: only if it stands in front of the fighters' line there.
				var tz: float = clampf((float(fc[1]) - da.x) / (db.x - da.x), 0.0, 1.0) if absf(db.x - da.x) > 1.0 else 0.5
				if float(fc[6]) <= lerpf(za, zb, tz) + 1.0:
					continue
			var inside: int = 0
			var shown: int = 0
			for ix in range(5):
				for iy in range(5):
					var wp := Vector3(float(fc[1]) + (float(ix) / 4.0 - 0.5) * float(fc[2]), lerpf(float(fc[3]), float(fc[4]), (float(iy) + 0.5) / 5.0), float(fc[5]))
					if cam_rig.is_position_behind(wp):
						continue
					var sp: Vector2 = cam_rig.unproject_position(wp)
					if sp.x < 0.0 or sp.x > vp.x or sp.y < 0.0 or sp.y > vp.y:
						continue
					shown += 1
					var t: float = clampf((sp - pa).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
					if (sp - pa - ab * t).length() < pr * 0.8:
						inside += 1
			if shown >= 4:
				var under: float = smoothstep(RenderLook.PATCH_UNDER.x, RenderLook.PATCH_UNDER.y, float(inside) / float(shown))
				if big * under > 0.0:
					soft[int(fc[0])] = big * under
					sink[int(fc[0])] = big * under
	patch = {"a": pa, "b": pb, "r": pr, "size": size, "sink": sink, "wa": Vector3(da.x, da.y, za), "wb": Vector3(db.x, db.y, zb), "wr": dr, "left": left}
	var inv: Transform3D = cam_rig.transform.affine_inverse()
	var near_a: float = -(inv * Vector3(da.x, da.y, za)).z - RenderLook.HOLE_GAP
	var near_b: float = near_a
	if deep:
		near_b = -(inv * Vector3(db.x, db.y, zb)).z - RenderLook.HOLE_GAP
		for e in [ea, eb]:
			var slot: int = int(e[1])
			if slot < aim.size() and aim[slot] >= 0:
				var ab = S.buildings[aim[slot]]
				if ab.d > 0.0:
					var lim: float = -(inv * Vector3(SimWrap.sdx(cam_x, ab.x), da.y, ab.z + ab.d * 0.5)).z - RenderLook.HOLE_GAP
					if e == ea:
						near_a = minf(near_a, lim)
					if e == eb:
						near_b = minf(near_b, lim)
	return [Vector3(da.x, da.y, za), pr, near_a, Vector3(db.x, db.y, zb), pr, near_b]


func snap_occlusion() -> void:
	planet.snap_stubs()
	planet.snap_open()
	_patch_t = -1.0
	_join_t = -1.0
	_cue_t = -1.0
	_pair_t = -1.0
	_react_t = -1.0
	for v in fighter_views:
		v.snap_damage()


## The sky (render/shaders/sky.gdshader): its clouds drift with the camera's place round the planet and a slow wind.
## That is all of it unless sky_react_on is set (off by default since QA's GB-002 came back: a gap that follows a
## fighter read as a glowing patch over him; docs/rendering/sky-gap-anchored.md is the version that would not follow).
## With it on, from tier 3 the clouds part for a fighter (docs/design/rule-of-cool.md feature 12; nothing below tier 3): a gap
## in the cloud band above him with its edge lit in his colour, half at tier 3 and full at tier 4, easing over
## SKY_REACT_S of tick time. Only for a fighter this pane shows: it fades out as he leaves the screen, so no gap hangs
## in the sky for someone the player cannot see (QA's GB-002). It never darkens the sky (Legal). It stands down while
## he charges or transforms, as VFX's rubble and cracks do (the stacking rule, rule 9 of the list: his own show has
## the moment). With reduced motion (sky_calm) nothing parts.
func _sky_react(host: SimHost, cam_x: float) -> void:
	var S: SimState = host.S
	var n: int = fighter_views.size()
	var now: float = PlanetView.tick_time(S)
	var snap: bool = _react_t < 0.0 or _react.size() != n
	var dt: float = 0.0 if snap else clampf(now - _react_t, 0.0, 0.1)
	_react_t = now
	if _react.size() != n:
		_react.resize(n)
		_react.fill(0.0)
	var dirs: Array = []
	var cols := PackedColorArray()
	for i in range(2):
		var w: float = 0.0
		var d := Vector3(0.0, 0.0, -1.0)
		var c := Color.BLACK
		if i < n:
			var f = S.fighters[i]
			var want: float = 0.0 if not sky_react_on or _busy(host, i) else clampf((float(f.tier) - 2.0) / 2.0, 0.0, 1.0)
			_react[i] = want if snap else move_toward(_react[i], want, dt / RenderLook.SKY_REACT_S)
			var v: FighterView = fighter_views[i]
			var chest: Vector3 = v.position + Vector3(0.0, FighterView.HEIGHT * 0.5, 0.0)
			d = (chest - cam_rig.position).normalized()
			c = v._aura_col
			w = _react[i] * _on_screen(chest)
		dirs.append(Vector4(d.x, d.y, d.z, w))
		cols.append(c)
	_sky_mat.set_shader_parameter("sky_react", dirs)
	_sky_mat.set_shader_parameter("sky_react_col", cols)
	_sky_mat.set_shader_parameter("cloud_on", 1.0 if clouds_on else 0.0)
	_sky_mat.set_shader_parameter("cloud_part", 1.0 if sky_react_on and not sky_calm else 0.0)
	_sky_mat.set_shader_parameter("cloud_shift", SimWrap.wrap(cam_x) / SimConst.W * RenderLook.CLOUD_PERIOD + (0.0 if sky_calm else now * RenderLook.CLOUD_WIND))


## How far a point of this pane's world is on its screen: 1 on it, falling to 0 over SKY_REACT_OFF of the screen's
## width past an edge (0 behind the camera).
func _on_screen(at: Vector3) -> float:
	if cam_rig.is_position_behind(at):
		return 0.0
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var p: Vector2 = cam_rig.unproject_position(at)
	var out: float = maxf(maxf(-p.x, p.x - vp.x), maxf(-p.y, p.y - vp.y))
	return 1.0 - smoothstep(0.0, RenderLook.SKY_REACT_OFF * vp.x, out)


## Whether fighter i is charging or transforming now (VFX's own test, render/vfx/react.gd, plus the sim's state for a
## build with VFX off).
static func _busy(host: SimHost, i: int) -> bool:
	var S: SimState = host.S
	var f = S.fighters[i]
	if f.state == "charging" or f.beamCharge != null or ("breakIn" in f.act and int(f.act.breakIn) >= 0) or (S.pause.left > 0 and int(S.pause.actor) == i):
		return true
	if host.vfx.enabled:
		for fm in host.vfx.xform.forms:
			if int(fm.slot) == i:
				return true
	return false


## The lane cue (RenderLook.LANE_CUE_*): a stripe on the ground at a fighter's depth, in his colour, while it says
## something: the two fighters are at different depths, or his own depth is changing. It eases on tick time (PlanetView.tick_time), from the
## sim's depths tick by tick (the drawn stripe follows his interpolated position).
func _lane_cues(host: SimHost, a: float) -> void:
	var S: SimState = host.S
	var n: int = fighter_views.size()
	if _cue.size() != n:
		_cue.resize(n)
		_cue.fill(0.0)
		_cue_z.resize(n)
		_cue_want.resize(n)
		_cue_want.fill(false)
		_cue_t = -1.0
	var snap: bool = _cue_t < 0.0
	var dt: float = 0.0 if snap else clampf(PlanetView.tick_time(S) - _cue_t, 0.0, 0.1)
	_cue_t = PlanetView.tick_time(S)
	var apart: bool = n == 2 and absf(S.fighters[0].z - S.fighters[1].z) > RenderLook.LANE_CUE_DZ
	var cues: Array = []
	for i in range(n):
		var z: float = S.fighters[i].z
		if snap:
			_cue_want[i] = apart
			_cue[i] = 1.0 if apart else 0.0
		elif dt > 0.0:
			_cue_want[i] = apart or absf(z - _cue_z[i]) / dt > RenderLook.LANE_CUE_VZ
			_cue[i] = move_toward(_cue[i], 1.0 if _cue_want[i] else 0.0, dt / (RenderLook.LANE_CUE_IN_S if _cue_want[i] else RenderLook.LANE_CUE_OUT_S))
		if snap or dt > 0.0:
			_cue_z[i] = z
		var v: FighterView = fighter_views[i]
		cues.append([host.fighter_x(i, a), v.depth, (_cue[i] if v.visible else 0.0) * RenderLook.LANE_CUE_ALPHA, v._aura_col])
	planet.set_lane_cues(cues)


## The pair's mark (RenderLook.PAIR_MARK_*): only in a match with depth on, a stroke on the ground between the two
## fighters while they are close, near the ground and at different depths. Its look and its timing are VFX's
## (docs/vfx/depth.md section 6): it fades on tick time, holds once up, is quiet while the line is steady and speaks up
## when the line turns. Presentation only: it reads the sim. With depth off it sets nothing.
func _pair_mark(host: SimHost, a: float) -> void:
	var S: SimState = host.S
	if not S.depthOn or fighter_views.size() != 2:
		if _pair_t >= 0.0:
			_pair = 0.0
			_pair_t = -1.0
			planet.set_pair_mark(Vector4.ZERO, 0.0)
		return
	var snap: bool = _pair_t < 0.0
	var now: float = PlanetView.tick_time(S)
	var dt: float = 0.0 if snap else clampf(now - _pair_t, 0.0, 0.1)
	_pair_t = now
	var x := PackedFloat64Array()
	var up := PackedFloat32Array()
	var shown: bool = true
	for i in range(2):
		var v: FighterView = fighter_views[i]
		var wx: float = host.fighter_x(i, a)
		x.append(wx)
		up.append(host.fighter_pose(i, a).y - maxf(planet.ground.ground_at(S, wx, v.depth), WorldWater.surfaceAt(S, wx)))
		shown = shown and v.visible
	var z0: float = (fighter_views[0] as FighterView).depth
	var z1: float = (fighter_views[1] as FighterView).depth
	var dx: float = SimWrap.sdx(x[0], x[1])
	# Up while they are a pair at an angle, and for PAIR_MARK_HOLD_S after the angle goes (a drift across the threshold
	# and back does not blink it); gone at once in its fade when they part or one leaves the ground.
	var near_pair: bool = shown and pair_wants(dx, RenderLook.PAIR_MARK_DZ, up[0], up[1])
	if near_pair and absf(z1 - z0) >= RenderLook.PAIR_MARK_DZ:
		_pair_hold = now + RenderLook.PAIR_MARK_HOLD_S
	var show: bool = near_pair and now < _pair_hold
	# Its strength: quiet while the line is steady, full for a moment when it turns, quieter beside the lane cues;
	# steady and unfaded in the calm modes.
	var ang: float = rad_to_deg(atan2((z1 - z0) * signf(dx), absf(dx)))
	if not show or _pair <= 0.0:
		_pair_ang = ang
	elif absf(ang - _pair_ang) >= RenderLook.PAIR_MARK_TURN_DEG:
		_pair_ang = ang
		_pair_loud = now + RenderLook.PAIR_MARK_LOUD_S
	var cues_up: bool = false
	for w in _cue_want:
		cues_up = cues_up or bool(w)
	var lvl: float = RenderLook.PAIR_MARK_CALM if flash_calm else (RenderLook.PAIR_MARK_CUES if cues_up else (1.0 if now < _pair_loud else RenderLook.PAIR_MARK_STEADY))
	if snap or flash_calm:
		_pair = 1.0 if show else 0.0
		_pair_lvl = lvl
	elif dt > 0.0:
		if _pair <= 0.0:
			_pair_lvl = lvl   # coming up: at its strength from the start
		else:
			_pair_lvl = move_toward(_pair_lvl, lvl, dt / (RenderLook.PAIR_MARK_LEVEL_S.x if lvl > _pair_lvl else RenderLook.PAIR_MARK_LEVEL_S.y))
		_pair = move_toward(_pair, 1.0 if show else 0.0, dt / (RenderLook.PAIR_MARK_IN_S if show else RenderLook.PAIR_MARK_OUT_S))
	# Its width by the nearer fighter's size against his size on the plane.
	var size: float = cam_rig.dist / maxf(cam_rig.dist - (maxf(z0, z1) - focus_z), 0.2 * cam_rig.dist)
	planet.set_pair_mark(Vector4(x[0], z0, x[1], z1), _pair * _pair_lvl, 0.5 * (RenderLook.PAIR_MARK_W.x + RenderLook.PAIR_MARK_W.y * size))


## Whether two fighters are a pair to mark: dx along the street and dz in depth between them, and each one's height above
## his ground.
static func pair_wants(dx: float, dz: float, up0: float, up1: float) -> bool:
	return absf(dx) <= RenderLook.PAIR_MARK_SEP and absf(dz) >= RenderLook.PAIR_MARK_DZ and maxf(up0, up1) <= RenderLook.PAIR_MARK_H


static func _shadow_mesh() -> PlaneMesh:
	var m := PlaneMesh.new()
	m.size = Vector2.ONE
	return m


## A fighter's ground shadow: on the ground as drawn under him at his depth (or the water over it), fainter and wider
## the higher he flies. It is what shows where he is over the ground when a launch carries him into the rows.
func _place_shadow(S: SimState, i: int, wx: float, vx: float, y: float, z: float, shown: bool = true) -> void:
	var sh: MeshInstance3D = shadows[i]
	var g: float = maxf(planet.ground.ground_at(S, wx, z), WorldWater.surfaceAt(S, wx))
	if S.depthOn:
		# Over a roof his shadow lies on the roof (World's standingAt), not on the ground under the building.
		var st: Dictionary = WorldStructures.standingAt(S, wx, y, z, 0.3 * FighterView.HEIGHT)
		if str(st.get("kind", "")) == "roof":
			g = maxf(g, float(st["y"]))
	var up: float = clampf((y - g) / RenderLook.SHADOW_FADE_H, 0.0, 1.0)
	sh.visible = shown and y >= g - 1.0
	sh.position = Vector3(vx, g + RenderLook.SHADOW_LIFT, z)
	sh.scale = Vector3(RenderLook.SHADOW_W * (1.0 + 0.5 * up), 1.0, RenderLook.SHADOW_D * (1.0 + 0.5 * up))
	(sh.material_override as ShaderMaterial).set_shader_parameter("strength", RenderLook.SHADOW_ALPHA * lerpf(1.0, 0.25, up))


## A fighter's rectangle on this pane's screen (feet to the top of the head, a body's width), a little grown. (For
## Animation's tools.)
func _screen_rect(v: FighterView) -> Rect2:
	var feet: Vector3 = v.global_position
	var top: Vector3 = feet + Vector3(0.0, FighterView.HEIGHT, 0.0)
	if cam_rig.is_position_behind(feet):
		return Rect2()
	var a: Vector2 = cam_rig.unproject_position(feet)
	var b: Vector2 = cam_rig.unproject_position(top)
	var h: float = absf(a.y - b.y)
	return Rect2(Vector2(a.x - 0.3 * h, minf(a.y, b.y)), Vector2(0.6 * h, h)).grow(0.1 * h)


## Planet-scale cues and crowd legibility for this frame, from the zoom and the camera height (presentation only).
func _view_cues(c: Vector3, vp: Vector2) -> void:
	var wide: float = smoothstep(log(RenderLook.ZOOM_CLOSE), log(RenderLook.ZOOM_WIDE), log(maxf(c.z, 1e-6)))
	var high: float = smoothstep(RenderLook.HIGH_FROM, RenderLook.HIGH_TO, c.y)
	var d: float = lerpf(RenderLook.CURVE_NEAR, RenderLook.CURVE_WIDE, wide) + RenderLook.CURVE_HIGH * high
	# Every layer from full depth weight back sags d * vh pixels at its screen edge (bend.gdshaderinc).
	mats.set_bend(4.0 * d * vp.y * c.z / (vp.x * vp.x), cam_rig.dist, focus_z)
	# The horizon is the far edge of the ground: its elevation from the camera anchors the sky and the fog.
	var hz: float = (0.0 - cam_rig.position.y) / (cam_rig.position.z + RenderLook.FOG_FAR)
	for k in [["space", high], ["horizon", hz]]:
		_sky_mat.set_shader_parameter(k[0], k[1])
		mats.set_sky(k[0], k[1])
	var boost: float = clampf(RenderLook.CROWD_MIN_PX / (CrowdMesh.HEIGHT * RenderLook.CROWD_SCALE * c.z), 1.0, RenderLook.CROWD_BOOST_MAX)
	# The shell's push directions are unit corner diagonals, so each axis moves 1/sqrt(3) of the width.
	planet.set_crowd_view(boost, 1.732 * RenderLook.CROWD_OUTLINE_PX / (c.z * RenderLook.CROWD_SCALE))


func _setup_environment() -> void:
	_sky_mat = ShaderMaterial.new()
	_sky_mat.shader = preload("res://render/shaders/sky.gdshader")
	var skyp: Dictionary = {
		"sky_top": RenderLook.col(RenderLook.SKY[0]), "sky_upper": RenderLook.col(RenderLook.SKY[1]),
		"sky_lower": RenderLook.col(RenderLook.SKY[2]), "sky_horizon": RenderLook.col(RenderLook.SKY[3]),
		"sky_tan": tan(deg_to_rad(RenderLook.FOV_DEG) * 0.5), "sky_lower_at": RenderLook.SKY_LOWER_AT,
		"sky_upper_at": RenderLook.SKY_UPPER_AT, "sky_top_at": RenderLook.SKY_TOP_AT, "sky_thin": RenderLook.SKY_THIN,
		"haze_at": RenderLook.HAZE_AT, "haze_mix": RenderLook.HAZE_MIX, "haze_line": RenderLook.HAZE_LINE, "haze_sea": RenderLook.HAZE_SEA,
		"haze_value": RenderLook.HAZE_VALUE, "haze_sat": RenderLook.HAZE_SAT, "haze_sky": RenderLook.HAZE_SKY,
	}
	SkyDrive.ensure()
	_sky_mat.set_shader_parameter("glow_col", SkyDrive.ember)
	_sky_mat.set_shader_parameter("star_floor", RenderLook.STAR_FLOOR)
	_sky_mat.set_shader_parameter("star_period", RenderLook.STAR_TURN)
	_sky_mat.set_shader_parameter("star_dark", RenderLook.STAR_DARK)
	_sky_mat.set_shader_parameter("glow_mix", RenderLook.SKY_GLOW_MIX)
	_sky_mat.set_shader_parameter("glow_shape", RenderLook.SKY_GLOW_SHAPE)
	for k in [["cloud_period", RenderLook.CLOUD_PERIOD], ["cloud_cover", RenderLook.CLOUD_COVER], ["react_r", RenderLook.SKY_REACT_R], ["react_at", RenderLook.SKY_REACT_AT]]:
		_sky_mat.set_shader_parameter(k[0], k[1])
	for k in skyp:
		_sky_mat.set_shader_parameter(k, skyp[k])
		mats.set_sky(k, skyp[k])
	var sky := Sky.new()
	sky.sky_material = _sky_mat
	sky.radiance_size = Sky.RADIANCE_SIZE_32
	sky.process_mode = Sky.PROCESS_MODE_REALTIME
	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_DISABLED
	e.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	e.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.environment = e
