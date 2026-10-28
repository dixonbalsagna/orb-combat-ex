class_name SplitFrame
extends RefCounted
## One presentation frame of the dynamic split screen (docs/camera/split-screen.md): what the compositor and the HUD
## need, and nothing else. The rig makes one per sim tick; the host interpolates between the last two.
##
## Pane index equals fighter slot: pane 0 is slot 0's, pane 1 slot 1's. `n` is the unit normal (screen coordinates,
## y down) from pane 0's region toward pane 1's, so pane 1 holds the points with (p - c) . n > 0.

var vw: float = 1280.0
var vh: float = 720.0
var mode: String = "merged"          # merged, opening, split, closing, slam, swing, solo
var sep: float = 0.0                 # 0 one view, 1 two panes (linear; the panes' blend uses smootherstep(sep))
var e: float = 0.0                   # how far one pane has taken the screen (a launch, a cinematic, a slam)
var e_slot: int = -1
var sliver: float = 0.0              # share of the screen the other pane keeps at e = 1
var theta: float = 0.0               # angle of n, radians
var n: Vector2 = Vector2.RIGHT
var c: Vector2 = Vector2(640.0, 360.0)   # a point on the divider, with the expansion applied
var gap: float = 0.0                 # divider line width, px
var feather: float = 0.0             # dissolve blend half-width, px
var line_alpha: float = 0.0
var cam_x: PackedFloat64Array = PackedFloat64Array([0.0, 0.0])   # per pane: the reference camera's x, y, zoom
var cam_y: PackedFloat64Array = PackedFloat64Array([0.0, 0.0])
var cam_z: PackedFloat64Array = PackedFloat64Array([0.5, 0.5])
var anchor: Array = [Vector2.ZERO, Vector2.ZERO]   # where each fighter's chest is meant to sit, px
var active: Array = [true, false]    # which panes must be rendered
var kind: Array = ["normal", "normal"]   # pane_request hook: "normal" or "search"
var swing: float = -1.0              # -1, or 0..1 while the panes trade sides
var sigma: int = 1                   # +1 when slot 1 is to slot 0's right (the layout now shown)
var ring: PackedFloat64Array = PackedFloat64Array([0.0, 0.0])   # both fighters' angles round the planet, radians
var held_u: float = 0.0              # the held signed separation slot 0 to slot 1, units
var flash: float = 0.0               # seconds left of the divider's slam flash
var shake: PackedFloat64Array = PackedFloat64Array([0.0, 0.0])   # each pane's shake amount, px, before the cap and the player's scale
var fade: float = 0.0                # 0..1: a safety cut's brightness dip, fading in (the compositor darkens by CUT_DIM x this)
var pitch: float = 0.0               # the cameras' pitch in degrees (0: straight on); Rendering's CameraRig takes it
var focus_z: PackedFloat64Array = PackedFloat64Array([0.0, 0.0])   # per pane: the depth the zoom is defined at, the pivot of the camera's orbit (units, positive toward the camera). 0 with depth off or the dolly off: the fighter plane
var scroll: Array = [0.0, 0.0]          # per pane: how fast the scenery crosses it, in px a tick at 1024 wide (eased; in one view both are the shared camera's). Rendering fades the windows' and facades' contrast with it
var incoming: Array = [{}, {}]       # per fighter: the other fighter coming at him: {active, aimed, eta, dist_u, dist_bh, closing, side, shown, lost (he is in neither pane: active whether or not he is closing), screen_dir} (the HUD's edge marker reads it)
var panel: Dictionary = {}           # the panel cut-in, or {}: kind, slot, open (0..1), still, rect (px), slant (px, signed), size, cam_x, cam_y, cam_z (the inset's own viewport)
var cutaway: Array = [{}, {}]        # per pane: the occlusion hole's request {request, radius_px, only}
var clear: Array = [{}, {}]          # per pane: what the foreground must open (docs/camera/city-in-depth.md sections 2 and 3): {rect (px, the action's, already held and rate-limited), p (its share of the pane), sigma (0 patch only .. 1 stubs), y_top (world units, the top of the action), x0, x1 (world x of the rect's sides at the focus plane), holding (a hold is running: nothing narrows), cut (true on a cut tick: jump to the target), hole (the floor's radius, px)}
var slam: bool = false               # true on the one frame the slam closes
var many_off: Array = []             # one versus many (docs/camera/one-v-many.md): the bodies outside the frame, each [slot, side (-1 left, +1 right, 0 above)]: UI's markers; empty with two bodies
var cut: bool = true                 # a hard cut: do not interpolate into this frame


func duplicate() -> SplitFrame:
	var f := SplitFrame.new()
	f.vw = vw
	f.vh = vh
	f.mode = mode
	f.sep = sep
	f.e = e
	f.e_slot = e_slot
	f.sliver = sliver
	f.theta = theta
	f.n = n
	f.c = c
	f.gap = gap
	f.feather = feather
	f.line_alpha = line_alpha
	f.cam_x = cam_x.duplicate()
	f.cam_y = cam_y.duplicate()
	f.cam_z = cam_z.duplicate()
	f.focus_z = focus_z.duplicate()
	f.anchor = anchor.duplicate()
	f.active = active.duplicate()
	f.panel = panel.duplicate()
	f.incoming = incoming.duplicate()
	f.scroll = scroll.duplicate()
	f.kind = kind.duplicate()
	f.swing = swing
	f.sigma = sigma
	f.ring = ring.duplicate()
	f.held_u = held_u
	f.flash = flash
	f.slam = slam
	f.many_off = many_off.duplicate(true)
	f.pitch = pitch
	f.cutaway = cutaway.duplicate(true)
	f.clear = clear.duplicate(true)
	f.fade = fade
	f.shake = shake.duplicate()
	f.cut = cut
	return f


## Weight of pane 1 at screen point p (pane 0's is one minus this). Zero or one away from the divider; a smooth blend
## across the feather while the panes dissolve into one view.
## Pane i's visible region on the screen, for culling what lies wholly on the hidden side of the divider (Rendering, the
## split's second terrain draw: Performance, 2026-10-23). {"all": true} when the pane fills the screen, {"none": true} when it
## is not drawn, else {"n": Vector2, "d": float}: a screen point p (px) can show in pane i only if n.dot(p) >= d. Conservative:
## d sits past the divider by its feather, half its line, the largest shake (a pane's camera jitter moves its picture, not the
## divider) and VIS_MARGIN_PX. The same test as weight1, so the compositor never shows a pixel the plane excludes.
func visible_half_plane(i: int) -> Dictionary:
	if not bool(active[i]):
		return {"none": true}
	if not bool(active[1 - i]):
		return {"all": true}
	var m: float = feather + gap * 0.5 + CamParams.SHAKE_CAP * CamParams.SHAKE_PREF_TOP * vh + CamParams.VIS_MARGIN_PX
	var nn: Vector2 = n if i == 1 else -n
	return {"n": nn, "d": nn.dot(c) - m}


func weight1(p: Vector2) -> float:
	if not bool(active[1]):
		return 0.0
	if not bool(active[0]):
		return 1.0
	var s: float = (p - c).dot(n)
	if feather <= 0.001:
		return 1.0 if s > 0.0 else 0.0
	return smoothstep(-feather, feather, s)


## The screen point of a world point as pane i draws it: the reference camera's mapping (docs/rendering/README.md).
## wz is the fighter's depth (Fighter.z, positive toward the camera): a deep fighter draws at s = d / (d + w) of the way
## out from the camera's axis (docs/camera/depth-and-chains.md section 2), d being the camera's distance to the plane.
func screen_pos(i: int, wx: float, wy: float, wz: float = 0.0) -> Vector2:
	wz -= focus_z[i]   # the pane's camera stands at the focus plane's depth (the dolly): a point is placed by its depth from it
	if pitch == 0.0 and wz == 0.0:
		return Vector2(SimWrap.sdx(cam_x[i], wx) * cam_z[i] + vw * 0.5, vh * CamParams.PLANE_Y - (wy - cam_y[i]) * cam_z[i])
	return project(cam_x[i], cam_y[i], cam_z[i], pitch, vw, vh, wx, wy, wz)


## The pinhole projection of CameraRig (render/camera/camera_rig.gd): the camera orbits the fighter-plane point at the
## screen's centre (plane y = cam_y + 0.2 vh / zoom) by `pitch_deg`, at the distance that gives `zoom` pixels per unit there.
## wz is the point's depth from the plane, positive toward the camera. At pitch 0 and wz 0 it is the closed form above.
static func project(cx: float, cy: float, zoom: float, pitch_deg: float, vw_: float, vh_: float, wx: float, wy: float, wz: float) -> Vector2:
	var p: float = deg_to_rad(pitch_deg)
	var dist: float = vh_ / (2.0 * zoom * CamParams.TAN_HALF_FOV)
	var yc: float = cy + 0.2 * vh_ / zoom + dist * sin(p)
	var zc: float = dist * cos(p)
	var vx: float = SimWrap.sdx(cx, wx)
	var vy: float = wy - yc
	var vz: float = wz - zc
	var dz: float = maxf(-vy * sin(p) - vz * cos(p), 1.0)     # along the view direction (0, -sin p, -cos p)
	var up: float = vy * cos(p) - vz * sin(p)                  # along the camera's up (0, cos p, -sin p)
	var f: float = vh_ * 0.5 / CamParams.TAN_HALF_FOV
	return Vector2(vw_ * 0.5 + vx * f / dz, vh_ * 0.5 - up * f / dz)


## The perspective scale of a fighter at depth wz (positive toward the camera) in pane i.
func depth_scale(i: int, wz: float) -> float:
	wz -= focus_z[i]
	var d: float = CamParams.K_FACTOR * vh / cam_z[i]
	return maxf(d / maxf(d - wz, 1.0), CamParams.DEPTH_S_MIN)


## Whether pane i shows any of the screen.
func shows(i: int) -> bool:
	return bool(active[i])


## The HUD anchor record for a fighter (chest point in its own pane), in the shape Rendering's anchor_fn returns.
func apparent_height(i: int, wx: float, wy: float, wz: float = 0.0) -> float:
	return (screen_pos(i, wx, wy, wz) - screen_pos(i, wx, wy + CamParams.BODY_H, wz)).length()


## Whether the fighter's chest point is in pane `slot`'s picture: hud_anchor's "visible" without the rest of the record.
func sees(slot: int, wx: float, wy: float, wz: float = 0.0) -> bool:
	if not shows(slot):
		return false
	var p: Vector2 = screen_pos(slot, wx, wy + CamParams.CHEST, wz)
	var on: bool = Rect2(Vector2(-200.0, -200.0), Vector2(vw, vh) + Vector2(400.0, 400.0)).has_point(p)
	if on and feather <= 0.001:
		var side: float = (p - c).dot(n)
		on = side <= 0.0 if slot == 0 else side > 0.0
	return on


func hud_anchor(slot: int, wx: float, wy: float, wz: float = 0.0) -> Dictionary:
	var p: Vector2 = screen_pos(slot, wx, wy + CamParams.CHEST, wz)
	var on: bool = shows(slot) and Rect2(Vector2(-200.0, -200.0), Vector2(vw, vh) + Vector2(400.0, 400.0)).has_point(p)
	if on and feather <= 0.001:
		var side: float = (p - c).dot(n)
		on = side <= 0.0 if slot == 0 else side > 0.0
	return {"pos": p, "h": apparent_height(slot, wx, wy, wz), "visible": on, "pane": slot}


## The width of the world pane i shows at the fighter plane, in radians of planet angle.
func viewed_arc(i: int) -> float:
	var ss: float = smoothstep(0.0, 1.0, sep)
	var share: float = 1.0 - 0.5 * ss   # one view: the whole width; two panes: about half each
	if e_slot >= 0:
		var take: float = (1.0 - sliver) if i == e_slot else sliver
		share = lerpf(share, take, e)
	return (share * vw / cam_z[i]) / SimConst.W * TAU


## The record UI's HUD reads each frame (UiHud.split_fn, docs/ui/hud-spec.md section 10). Empty when the screen is one
## camera and there is nothing to draw. In one view arc_A and arc_B are the same (the camera's viewed width); UI draws
## a single arc at the fighters' midpoint.
func split_record(pointer_always: bool = false) -> Dictionary:
	var d: Dictionary = {}
	d["sep"] = sep
	d["c"] = c
	d["n"] = n
	d["gap"] = gap
	d["fade"] = line_alpha
	d["slam"] = clampf(flash / CamParams.SLAM_FLASH, 0.0, 1.0)
	d["sigma"] = sigma
	d["dist_bh"] = absf(held_u) / CamParams.BODY_H
	d["pointer"] = "always" if (pointer_always or sep < 0.5) else "split"
	d["incoming"] = incoming
	d["many_off"] = many_off   # the bodies outside the frame, [slot, side]: UI's markers (empty with two bodies)
	d["scroll"] = scroll
	d["ring"] = {
		"angle_A": ring[0], "angle_B": ring[1], "sigma": sigma, "arc_A": viewed_arc(0), "arc_B": viewed_arc(1),
		"swing": swing, "sep": sep, "W": SimConst.W,
	}
	return d


static func lerp_frames(a: SplitFrame, b: SplitFrame, t: float) -> SplitFrame:
	if b.cut or a.vw != b.vw or a.vh != b.vh:
		return b
	var f: SplitFrame = b.duplicate()
	f.sep = lerpf(a.sep, b.sep, t)
	f.e = lerpf(a.e, b.e, t)
	f.theta = a.theta + angle_difference(a.theta, b.theta) * t
	f.n = Vector2(cos(f.theta), sin(f.theta))
	f.c = a.c.lerp(b.c, t)
	f.gap = lerpf(a.gap, b.gap, t)
	f.feather = lerpf(a.feather, b.feather, t)
	f.line_alpha = lerpf(a.line_alpha, b.line_alpha, t)
	for i in range(2):
		f.cam_x[i] = SimWrap.wrap(a.cam_x[i] + SimWrap.sdx(a.cam_x[i], b.cam_x[i]) * t)
		f.cam_y[i] = lerpf(a.cam_y[i], b.cam_y[i], t)
		f.cam_z[i] = exp(lerpf(log(a.cam_z[i]), log(b.cam_z[i]), t))
		f.focus_z[i] = lerpf(a.focus_z[i], b.focus_z[i], t)
		f.anchor[i] = a.anchor[i].lerp(b.anchor[i], t)
		f.ring[i] = a.ring[i] + angle_difference(a.ring[i], b.ring[i]) * t
	f.swing = lerpf(a.swing, b.swing, t) if a.swing >= 0.0 and b.swing >= 0.0 else b.swing
	f.flash = lerpf(a.flash, b.flash, t)
	f.pitch = lerpf(a.pitch, b.pitch, t)
	f.held_u = lerpf(a.held_u, b.held_u, t)
	for i in range(2):
		if not a.clear[i].is_empty() and not b.clear[i].is_empty() and not bool(b.clear[i].get("cut", false)):
			var ra: Rect2 = a.clear[i]["rect"]
			var rb: Rect2 = b.clear[i]["rect"]
			f.clear[i]["rect"] = Rect2(ra.position.lerp(rb.position, t), ra.size.lerp(rb.size, t))
			f.clear[i]["sigma"] = lerpf(float(a.clear[i]["sigma"]), float(b.clear[i]["sigma"]), t)
			f.clear[i]["p"] = lerpf(float(a.clear[i]["p"]), float(b.clear[i]["p"]), t)
	if not a.panel.is_empty() and not b.panel.is_empty() and a.panel["kind"] == b.panel["kind"] and a.panel["slot"] == b.panel["slot"]:
		var pa: Dictionary = a.panel
		var pb: Dictionary = f.panel
		pb["cam_x"] = SimWrap.wrap(float(pa["cam_x"]) + SimWrap.sdx(float(pa["cam_x"]), float(pb["cam_x"])) * t)
		pb["cam_y"] = lerpf(float(pa["cam_y"]), float(pb["cam_y"]), t)
		pb["cam_z"] = exp(lerpf(log(float(pa["cam_z"])), log(float(pb["cam_z"])), t))
		pb["open"] = lerpf(float(pa["open"]), float(pb["open"]), t)
	f.cut = false
	return f
