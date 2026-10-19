class_name SplitView
extends Control
## The split-screen compositor (docs/camera/split-screen.md section 11), Camera's half of the plug-in contract in
## docs/rendering/README.md, "Panes and the split screen". Rendering's main scene owns the rig and the panes and draws
## each pane from the rig's camera for it; this control takes the two panes' SubViewports, blends their textures on one
## rect with the mask shader, and answers main's two calls:
##   pane_jitter(i) -> Vector2   the shake for pane i in px (pane 0: the host's jitter; pane 1: a cosmetic stream of
##                               its own), capped at CamParams.SHAKE_CAP of the screen height and scaled by the
##                               player's setting
##   present(frame)              switch off the pane nobody sees, set the mask from the divider
## It sits under UI's HUD (a plain Control in the default canvas layer; the HUD is a CanvasLayer above it), and UI
## draws the divider line, the ring map and the pointer chips over it from the same frame (UiHud.split_fn).
##
##   var view := SplitView.new()
##   main.add_child(view)
##   view.attach(main)          # moves pane 0 into a SubViewport, makes pane 1, sets main.compositor = view
##   view.detach()              # back to one view from the reference camera

const MASK: Shader = preload("res://render/camera/split_mask.gdshader")
const PANEL_MASK: Shader = preload("res://render/camera/panel_mask.gdshader")

var main = null            # Rendering's main scene, or a stand-in with the same calls (render/camera/tests/split_test_main.gd)
var viewports: Array = [null, null]
var shake_pref: float = CamParams.SHAKE_PREF_DEFAULT   # the player's shake setting, 0 to 10 (default 2)
var shake_scale: float = 1.0          # the player's shake scale, 0 to 1 (default 1)
var reduced_motion: bool = false      # the player's reduced-motion setting: shake at a quarter of the scale
var shake_a := PaneShake.new()        # pane 0's cosmetic shake stream ("camera", the host's name for it)
var shake_b := PaneShake.new()        # pane 1's ("camera_b")
var last_frame: SplitFrame = null
var _rect: ColorRect                  # the mask rect: two panes blended by the divider
var _solo: TextureRect                # one pane, no shader: what the screen is when only one pane shows
var _mat: ShaderMaterial
var panel_colors: Array = [Color(0.95, 0.55, 0.2), Color(0.25, 0.7, 0.95)]   # the strip's border by slot, until UI and Art give the lane colours
var _panel_vp: SubViewport = null     # the inset pane's viewport, made when the first panel opens
var _panel_rect: TextureRect          # the strip
var _panel_mat: ShaderMaterial
var _panel_frames: int = 0            # frames the current panel has been drawn (a still strip is drawn twice, then frozen)
var _host_ticks: int = -1
var _host_seed: int = -1
var _attached: bool = false
var flash_reduced: bool = false      # the reduced-flashing setting: the host's flash register's `reduced`, read each tick
var _panel_asked: bool = false
var _panel_blocked: bool = false      # the flash register refused the strip now running: it is not drawn
var _dip_prev: float = 0.0            # the last frame's fade (a safety cut's brightness dip)
var _dip_ok: bool = true              # whether the dip now running was granted by the flash register
var cut_dissolve: bool = false        # a cut under Reduce flashing or reduced motion is a cross-dissolve of CamParams.CUT_DISSOLVE_S (a build-time switch; false: the old dip; OFF on Orb's word 2026-10-18: "the dissolve is terrible... don't dissolve the screen")
var _xf: TextureRect                  # the last picture before a cut, faded out over the new one
var _xf_start: float = -1.0           # the rig's time (seconds) the dissolve began; -1 none


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _ready() -> void:
	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mat = ShaderMaterial.new()
	_mat.shader = MASK
	_rect.material = _mat
	_rect.visible = false       # nothing to show until pane 0 has been moved into a SubViewport
	add_child(_rect)
	_solo = TextureRect.new()
	_solo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_solo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_solo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_solo.stretch_mode = TextureRect.STRETCH_SCALE
	_solo.visible = false
	add_child(_solo)
	_xf = TextureRect.new()
	_xf.set_anchors_preset(Control.PRESET_FULL_RECT)
	_xf.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_xf.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_xf.stretch_mode = TextureRect.STRETCH_SCALE
	_xf.visible = false
	add_child(_xf)
	_panel_rect = TextureRect.new()
	_panel_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_panel_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_panel_mat = ShaderMaterial.new()
	_panel_mat.shader = PANEL_MASK
	_panel_rect.material = _panel_mat
	_panel_rect.visible = false
	add_child(_panel_rect)
	resized.connect(_on_resized)


## Plug into Rendering's main scene: take pane 0 out of the main world into a SubViewport, make pane 1, and set
## main.compositor. From then on main steps the rig every tick and draws the panes from its cameras.
func attach(m) -> void:
	if _attached:
		return
	main = m
	# The panes are made once. Attaching again after a detach (F9 twice) takes the ones it has: making them again left
	# two empty viewports on screen (QA's GB-001).
	if viewports[0] == null:
		var sz := Vector2i(maxi(2, int(get_viewport().get_visible_rect().size.x)), maxi(2, int(get_viewport().get_visible_rect().size.y)))
		viewports = [main.move_pane0(sz), main.make_pane(sz)]
		add_child(viewports[0])
		add_child(viewports[1])
	if main.host != null and not main.host.ticked.is_connected(_on_ticked):
		main.host.ticked.connect(_on_ticked)
	_attached = true
	_ensure_panel_viewport(_panel_size())   # made now so main's inset exists before the first strip opens
	if _solo != null:
		_solo.texture = viewports[0].get_texture()
		_solo.visible = true
	main.compositor = self
	main.split_rig.flash_ask = Callable(self, "ask_register")
	_on_resized()


## Back to one view. Pane 0 stays in its SubViewport and is shown unmasked.
func detach() -> void:
	if main != null:
		main.compositor = null
	_attached = false
	if _rect != null:
		_rect.visible = false
		_solo.texture = viewports[0].get_texture()
		_solo.visible = true
	if viewports[0] != null:
		viewports[0].render_target_update_mode = SubViewport.UPDATE_ALWAYS
	if viewports[1] != null:
		viewports[1].render_target_update_mode = SubViewport.UPDATE_DISABLED


func is_attached() -> bool:
	return _attached


## A safety cut's brightness dip is a whole-screen change, so it asks the shared flash register (Rendering's
## SimHost.ask_flash, source "cut_dip", a big-event source) as it begins: granted, it plays; refused, the cut has no dip. A new
## dip is a fade that rises from nothing or by a fifth or more over the last frame's. A host with no register (a tool's
## stand-in) grants every dip.
func _dip_gate(fade: float, depth: float) -> float:
	if fade <= 0.0:
		_dip_ok = true
	elif fade > _dip_prev + 0.2:
		_dip_ok = ask_register("cut_dip", 1.0, depth)   # the whole frame, at its real step: under 0.10 it costs nothing
	_dip_prev = fade
	return fade if _dip_ok else 0.0


## One ask of the shared flash register for a change of `area` (a fraction of the screen) by `step` (the change in relative
## luminance, or -1 when unknown): the weighted ask (VFX's `ask(source, colour, tick, area_px, step)`, areas counted at 1024 by
## 768 as the register does). A host with no register (a tool's stand-in) grants every one. The rig's own calm choices
## (the transformation's break) come through here too: `main.split_rig.flash_ask`.
func ask_register(source: String, area: float, step: float = -1.0) -> bool:
	if main == null or main.get("host") == null:
		return true
	var h = main.host
	if h.get("vfx") == null or h.vfx.get("flashes") == null:
		return true
	return bool(h.vfx.flashes.ask(source, Color(0.3, 0.3, 0.35), int(h.S.tick), area * 1024.0 * 768.0, step))


## The dolly (docs/camera/city-in-depth.md section 6): the camera's focus plane follows the pair's depth, so a fight in the middle
## or the back street is drawn at the plane's size. Takes effect on the picture when Rendering's panes pass `frame.focus_z[i]` to
## CameraRig.frame. Off: focus_z is 0 and the picture is today's, bit for bit. Build-time switch, not a player option.
func set_depth_dolly(on: bool) -> void:
	if main != null:
		main.split_rig.depth_dolly = on


## The launch rule engages sooner under reduced flashing (docs/camera/buildings-in-frame.md section 15): after 0.25 of the width
## covered, or at a step of 0.05 of the width a tick, where the ordinary mode takes 0.6 and 0.15 (the reduced line is 0.03 where the
## ordinary is 0.045). Acts only with the launch rule on. Off by default. A build-time switch.
## One versus many (docs/camera/one-v-many.md): with more than two bodies the shared view frames the principals first and
## then as many of the others as keep the zoom at three quarters of the principals' own, the pixel floor applies, and the
## bodies left out are listed in the frame (`many_off`) for UI's markers. Off by default; with two bodies it changes
## nothing. A build-time switch.
func set_many_framing(on: bool) -> void:
	if main != null:
		main.split_rig.many_framing = on


## The flash bundle (docs/camera/buildings-in-frame.md section 15): the launch hold, its eager engage under reduced flashing, the merge
## zoom limit at a closing and the slam's door off under reduced flashing, together. `reduced_only` keeps all of it to the
## reduced-flashing setting, so the ordinary mode is exactly what it was. Off by default. A build-time switch.
func set_flash_bundle(on: bool, reduced_only: bool = false) -> void:
	if main != null:
		main.split_rig.flash_bundle = on
		main.split_rig.flash_bundle_reduced_only = reduced_only


## The beam struggle's framing (docs/camera/beam-struggle.md): the shared view leans toward the meeting point (`Clash.mid`), tightens as it nears a
## fighter and punches at each surge; a detonation pulls the view out. Needs Encounter's struggle and Simulation's `Clash.mid`; without them there is
## nothing to read and the switch does nothing. Off by default. A build-time switch.
func set_struggle_framing(on: bool) -> void:
	if main != null:
		main.split_rig.struggle_framing = on


## A pair moving apart fast is not merged on its present separation but on the one it will have a second on (docs/camera/rushcity.md): the merge
## and the split that follows it within two seconds, with a pan between them, are what rushcity's standing area failure is. Off by default. A build-time switch.
func set_merge_lookahead(on: bool) -> void:
	if main != null:
		main.split_rig.merge_lookahead = on


func set_launch_hold_eager(on: bool) -> void:
	if main != null:
		main.split_rig.launch_hold_eager = on


## No divider slam under reduced flashing (docs/camera/buildings-in-frame.md section 15): a rush's contact does not close the
## door over the pane (the 0.14 s slam: the pane's camera sweeping into the shared one, the divider shut in 8 ticks); the panes
## merge the ordinary way, by the closing. In the ordinary mode the slam stays: it is the feel, and ai 12345 in it reads worse
## without. Off by default. A build-time switch.
func set_slam_off(on: bool) -> void:
	if main != null:
		main.split_rig.slam_off = on


## The zoom comes in slowly while the panes merge (docs/camera/buildings-in-frame.md section 13): no faster than 0.21 of a log unit
## a second, from a launch shot's end to two seconds after the layout is one view. Off by default until Tools has run it. A
## build-time switch.
func set_merge_zoom_limit(on: bool) -> void:
	if main != null:
		main.split_rig.merge_zoom_limit = on


## A launch too fast to follow (docs/camera/buildings-in-frame.md section 7): a body whose speed would move the picture by more than
## 0.03 of the width a tick at the launch floor's zoom is not followed. The pane holds its frame, he leaves it, and after 0.6 s of
## his being gone (or his landing) the pane pans to him at 0.03 a tick, or cuts when he is farther than 20,000 units. Off by default
## until Tools has run collapse-normal both ways. A build-time switch.
func set_launch_hold(on: bool) -> void:
	if main != null:
		main.split_rig.launch_hold = on


## The travel budget (docs/camera/split-screen.md section 24h): a pane's picture changes by at most 0.045 of the width a tick
## (0.03 under reduced flashing), and the pane cuts when a subject has been gone for 0.6 s. Off by default until the flash set has
## measured it. Not a player option: a build-time switch (`camera_travel_budget` in the debug options).
func set_travel_budget(on: bool) -> void:
	if main != null:
		main.split_rig.travel_budget = on


## The feathered sweep of a layout change (a switch, off by default): 0 off, 1 only under reduced flashing or reduced motion,
## 2 always. Option name for UI, when it ships: `camera_feathered_sweeps`.
func set_feathered_sweeps(v: int) -> void:
	if main != null:
		main.split_rig.feather_mode = clampi(v, 0, 2)


## The player's settings (docs/camera/split-screen.md sections 2 and 13). Solo against the AI: split like two players
## (default) or follow the human fighter alone when far. Reduced motion: quicker swing, no tier push, no launch follow.
func set_solo_split(on: bool) -> void:
	if main != null:
		main.split_rig.solo_split = on


## The player's zoom setting, 0 to 10 (default 7): every size target is multiplied by exp(0.08 (pref - 7)). The floor is
## not scaled. Option name for UI: `camera_zoom`, an integer slider 0 to 10, default 7.
func set_zoom_pref(v: float) -> void:
	if main != null:
		main.split_rig.zoom_pref = clampf(v, 0.0, 10.0)


## The player's shake setting, 0 to 10 (default 2). Option name for UI: `camera_shake`, an integer slider 0 to 10, default 2.
func set_shake_pref(v: float) -> void:
	shake_pref = clampf(v, 0.0, 10.0)


## Who the camera follows on a launch: "auto" (the hybrid: stay with the human who launched, chase the human who was
## launched, split for two humans), "chase" or "split". Option name for UI: `camera_launch_follow`.
func set_launch_follow(v: String) -> void:
	if main != null:
		main.split_rig.launch_follow = v


## The panel cut-in (Orb's pick B): "full", "still" (a frozen strip) or "off". Reduced motion means still. Option name
## for UI: `camera_panels`, a choice of full, still and off, default full.
func set_panel_mode(v: String) -> void:
	if main != null:
		main.split_rig.panel_mode = v if v in ["full", "still", "off"] else "full"


## A cut under Reduce flashing or reduced motion cross-dissolves (default on); false keeps the old dip. Build-time switch.
func set_cut_dissolve(on: bool) -> void:
	cut_dissolve = on


## The strips (CamParams.PANEL_KINDS names) that do not open while Reduce flashing is on: ["signature"] by default, [] for the player's
## setting alone, all the names for none at all. A build-time switch, not a player option (docs/camera/panel-flash.md).
func set_panel_flash_off(kinds: Array) -> void:
	if main != null:
		main.split_rig.panel_flash_off = kinds.duplicate()


## UI's lowest HUD edge at the top, in pixels (UiHud.panel_floor_y()): the strip's top band starts below it, and falls to
## the bottom band where it no longer fits. Call it when the layout changes.
func set_panel_floor(y: float) -> void:
	if main != null:
		main.split_rig.panel_floor = maxf(y, 0.0)


## The border colours of the two fighters' strips (the lane colours).
func set_panel_colors(a: Color, b: Color) -> void:
	panel_colors = [a, b]


func set_reduced_motion(on: bool) -> void:
	reduced_motion = on
	if main != null:
		main.split_rig.reduced_motion = on


## Main asks for the inset's camera each displayed frame before it draws the inset: {cam_x, cam_y, cam_z (px per world
## unit in the inset's own viewport), pitch, cutaway}, or {} when there is no panel (or a still strip is already drawn).
func inset_view(_a: float) -> Dictionary:
	var fr = main.get("split_frame") if main != null else null
	if fr == null or fr.panel.is_empty() or not _attached:
		return {}
	var p: Dictionary = fr.panel
	if not _ensure_panel_viewport(p["size"]):
		return {}
	if bool(p["still"]) and _panel_frames >= 2:
		return {}
	return {"cam_x": p["cam_x"], "cam_y": p["cam_y"], "cam_z": p["cam_z"], "pitch": 0.0,
		"cutaway": {"request": true, "radius_px": 0.9 * float(p["size"].y), "only": -1}}


## The strip's viewport size for this screen: the frame's panel size (SplitRig._panel_frame) from the same numbers.
func _panel_size() -> Vector2i:
	var ph: float = maxf(size.y, 2.0) * CamParams.PANEL_H
	return Vector2i(int(ceil(maxf(size.x, 2.0) * CamParams.PANEL_W + ph * CamParams.PANEL_SLANT)), int(ceil(ph)))


## The inset's viewport, made once through main.make_inset and made again when the strip's size changes (a resized window).
func _ensure_panel_viewport(sz: Vector2i) -> bool:
	if main == null or not main.has_method("make_inset"):
		return false
	if _panel_vp != null and _panel_vp.size == sz:
		return true
	if _panel_vp != null:
		_panel_vp.queue_free()
	_panel_vp = main.make_inset(sz)
	_panel_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED   # drawn only while a strip is up
	add_child(_panel_vp)
	_panel_rect.texture = _panel_vp.get_texture()
	_panel_frames = 0
	return true


## The strip: placed from the frame's panel, shown while its wipe is open, and the inset only renders while it is up.
func _present_panel(fr: SplitFrame) -> void:
	var p: Dictionary = fr.panel
	# A strip that opens and shuts is a change over a tenth of the screen and then another: it asks the shared flash register
	# as it begins (source "cut_in_panel", a big-event source) and is not drawn when refused (the beam's white and the
	# explosion before it have asked first). Tools' recount found the strip opening and closing between a beam's flashes.
	if p.is_empty():
		_panel_blocked = false
		_panel_asked = false
	elif not _panel_asked and float(p["open"]) > 0.001:
		_panel_asked = true
		var pr: Rect2 = p["rect"]
		_panel_blocked = not ask_register("cut_in_panel", clampf(pr.size.x * pr.size.y / maxf(size.x * size.y, 1.0), 0.0, 1.0))
	if p.is_empty() or _panel_blocked or _panel_vp == null or float(p["open"]) <= 0.001:
		_panel_rect.visible = false
		if _panel_vp != null:
			_panel_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
		if p.is_empty():
			_panel_frames = 0
		return
	var r: Rect2 = p["rect"]
	_panel_rect.position = r.position
	_panel_rect.size = r.size
	_panel_rect.visible = true
	_panel_mat.set_shader_parameter("box", r.size)
	_panel_mat.set_shader_parameter("slant", float(p["slant"]))
	_panel_mat.set_shader_parameter("open", float(p["open"]))
	_panel_mat.set_shader_parameter("wipe_dir", 1.0 if int(p["slot"]) == 0 else -1.0)
	_panel_mat.set_shader_parameter("edge_col", panel_colors[int(p["slot"])])
	_panel_frames += 1
	var frozen: bool = bool(p["still"]) and _panel_frames > 2
	_panel_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED if frozen else SubViewport.UPDATE_ALWAYS


## Once per sim tick (the host's `ticked`): pane 1's shake stream advances, reseeded for a new match.
func _on_ticked(n: int) -> void:
	var h = main.host
	if n < _host_ticks or int(h.seed) != _host_seed:
		shake_a.reset(int(h.seed), "camera")
		shake_b.reset(int(h.seed))
		_host_seed = int(h.seed)
	_host_ticks = n
	if h.get("vfx") != null and h.vfx.get("flashes") != null:
		flash_reduced = bool(h.vfx.flashes.reduced)
		main.split_rig.flash_reduced = flash_reduced
	var vh: float = maxf(get_viewport().get_visible_rect().size.y, 1.0)
	var amounts: PackedFloat64Array = main.split_rig.current().shake
	shake_a.scale = _shake()
	shake_b.scale = _shake()
	shake_a.tick(amounts[0], vh)
	shake_b.tick(amounts[1], vh)


## Called by main for each pane's shake. Pane 0 is the host's jitter; pane 1 has this view's own stream.
func pane_jitter(i: int) -> Vector2:
	return shake_a.jitter if i == 0 else shake_b.jitter


func _shake() -> float:
	# shake_scale is the legacy 0 to 1 multiplier (1 by default); the setting is the strength: 10 of 10 is the old
	# prototype's, so 2 of 10 (the default) is 0.28 of Controls' table, and reduced motion takes a quarter of that.
	return shake_scale * (shake_pref / 10.0 * CamParams.SHAKE_PREF_TOP) * (0.25 if reduced_motion else 1.0)


func _on_resized() -> void:
	if _attached:
		_ensure_panel_viewport(_panel_size())
	var sz := Vector2i(maxi(2, int(size.x)), maxi(2, int(size.y)))
	for v in viewports:
		if v != null and v.size != sz:
			v.size = sz
	if _mat != null:
		_mat.set_shader_parameter("res", size)


## A cut under Reduce flashing or reduced motion is a cross-dissolve, not a step (Legal: a whole-frame cut counts as a whole-screen
## change): the picture on the screen when the cut frame arrives (the root viewport's last drawn frame, which is the frame before)
## is copied once and faded out over the new one in CamParams.CUT_DISSOLVE_S of the rig's sim time. A host that draws nothing (a headless
## test) has no image: the old dip stays. Returns whether a dissolve is showing, so the dip stays out of it.
func _dissolve(fr: SplitFrame, had_prev: bool) -> bool:
	if _xf == null or main == null or main.host == null:
		return false
	var now_t: float = float(main.split_rig.time)   # the rig's sim seconds (a tick-stepped capture draws one frame a tick)
	if cut_dissolve and had_prev and fr.cut and (reduced_motion or flash_reduced):
		var img: Image = get_viewport().get_texture().get_image()
		if img != null and not img.is_empty():
			img.convert(Image.FORMAT_RGB8)   # the root's image may carry no alpha worth keeping
			_xf.texture = ImageTexture.create_from_image(img)
			_xf_start = now_t
	if _xf_start < 0.0:
		return false
	var a: float = 1.0 - (now_t - _xf_start) / CamParams.CUT_DISSOLVE_S
	if a <= 0.0 or a > 1.0:
		_xf.visible = false
		_xf_start = -1.0
		return false
	_xf.visible = true
	_xf.modulate = Color(1.0, 1.0, 1.0, a)
	return true


## Called by main once per displayed frame, after the panes are drawn: pane 1 only renders while it shows, and the
## mask follows the divider. Pane 0 is always drawn (it applies the world's changes).
func present(fr: SplitFrame) -> void:
	var had_prev: bool = last_frame != null
	last_frame = fr
	if _mat == null:
		return
	var xf_on: bool = _dissolve(fr, had_prev)
	var v0 = viewports[0]
	var v1 = viewports[1]
	# One pane on the screen: draw its texture as it is, with no mask pass. Two: the mask blends them.
	var two: bool = fr.shows(0) and fr.shows(1) and v1 != null
	_rect.visible = two
	_solo.visible = not two
	if not two:
		var only = v1 if (not fr.shows(0) and v1 != null) else v0
		if _solo.texture != only.get_texture():
			_solo.texture = only.get_texture()
	if v0 != null:
		# Pane 0 always runs the world's updates on the CPU (main calls its render), but its GPU frame is skipped
		# while another pane has the whole screen.
		v0.render_target_update_mode = SubViewport.UPDATE_ALWAYS if fr.shows(0) else SubViewport.UPDATE_DISABLED
		_mat.set_shader_parameter("tex0", v0.get_texture())
	if v1 != null:
		v1.render_target_update_mode = SubViewport.UPDATE_ALWAYS if fr.shows(1) else SubViewport.UPDATE_DISABLED
		_mat.set_shader_parameter("tex1", v1.get_texture())
	_mat.set_shader_parameter("c", fr.c)
	_mat.set_shader_parameter("n", fr.n)
	_mat.set_shader_parameter("feather", fr.feather)
	_mat.set_shader_parameter("gap", fr.gap)
	_mat.set_shader_parameter("gap_alpha", fr.line_alpha)
	var depth: float = CamParams.REDUCED_CUT_DIM if (reduced_motion or flash_reduced) else CamParams.CUT_DIM
	var dim: float = 0.0 if xf_on else depth * _dip_gate(fr.fade, depth)
	_mat.set_shader_parameter("dim0", dim)
	_mat.set_shader_parameter("dim1", dim)
	_solo.modulate = Color(1.0 - dim, 1.0 - dim, 1.0 - dim)
	_mat.set_shader_parameter("active0", 1.0 if fr.shows(0) else 0.0)
	_mat.set_shader_parameter("active1", 1.0 if (fr.shows(1) and v1 != null) else 0.0)
	_present_panel(fr)
