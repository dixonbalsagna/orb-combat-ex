class_name RenderTileGround
extends RefCounted
## The tile ground, one per pane, behind a switch (main's --tiles, ?tiles=1 on a local page; off, nothing here runs and
## nothing the game draws changes): the ground as planet-keyed tiles (RenderTileField) on a true globe at every zoom, in
## place of the strip's terrain, water and far towns. Everything else in the world takes the same placement
## (bend.gdshaderinc globe_place). docs/world/ring-any-angle/rendering.md, research.md T6 stage 4.
##
## A level sets what's drawn, never what the sim computes (ADR 0012). This is Standard: 128 units of data round the pivot,
## on the triangles the sim will read, with finer mesh over those same triangles so a crater has vertices to dig.
##
## The view's frame is the strip's own at the camera, so the world rolls under the camera as a planet does. With no swing
## yet (T6 stage 6), --tilerate=<deg/s> turns the planet about the point the fight stands at, for the view alone: a test.

static var on: bool = false
static var rate: float = 0.0            # the view-only test turn, degrees a second; 0: none
static var quick: bool = false          # ... as small swings
static var near_mode: int = RenderLook.TILE_NEAR_DEFAULT
static var share: float = 1.0           # 1: the true globe. --tileshare=95: 95 percent at the closest zoom, to compare
var _cb: Array = []                    # the store's craters so far: [x, y, z, r, depth, rim, made], planet direction first; made: when it was first seen, by _clock
var _cb_fresh: bool = true            # the list is starting (a new match, or a rollback shortened the store): what it reads now is open already
var _clock: float = 0.0               # the render's own clock (the host's ticks, in seconds) that the bowls open by: S.T stands at 0 through the opening
var _cb_seen: int = 0                  # the store's records read
var _cb_due: int = 0
var _cb_a := PackedVector4Array()
var _cb_b := PackedVector4Array()
var _scar_w := PackedFloat32Array()    # per column: how much of a scar's width is left (scar_tex)
var _scar_on := PackedByteArray()      # the scan in hand: which columns are scar
var _scar_was := PackedByteArray()     # the last whole scan: the table is made again only when it changes
var _scar_i: int = 0
var _scar_img: Image
var _scar_tex: ImageTexture
static var crater_look: bool = false   # Art's crater (docs/art/crater-look.md). --craterlook
static var fore_tone: bool = true      # one tone in front of the plane: the facets there are a swing's flash. --nofore to compare
static var gen: int = 3                 # the world it draws: 3 a field world, on the sim's frame; --tilegen=2 the gen 2 ring, to compare

const TILE_MAX_LEVEL: int = 4           # mesh levels: 12,800 down to 800 across
const EASE: int = 20
const HOLD: int = 40
const MAX_TILES: int = 512

var pane: PaneWorld
var field: RenderTileField
var mat: ShaderMaterial
var mm: MultiMesh
var _node: MultiMeshInstance3D
var _started: bool = false
var _pivot_x: float = 0.0
var _pv0 := Vector3.ZERO
var _pvp := Vector3.ZERO
var _hdp := Vector3.ZERO
var _sdp := Vector3.ZERO
var _turn_sent: float = 1.0e9
var _reff: float = -1.0
var _drawn: int = 0
var _buf := PackedFloat32Array()
var _prof_wait: int = 0
var _prof_x: float = 0.0
var _prof_w: float = -1.0           # the view's width, the store's length, the tiles' version and the heading the sight line was read at
var _prof_n: int = -1
var _prof_v: int = -1
var _prof_hd := Vector3.ZERO
var _fill_at: int = 0
var _fill_dt: float = float(RenderLook.TILE_FILL_TARGET_US)
var _walk_x: float = 1.0e18
var _walk_hd := Vector3.ZERO
var _walk_v: int = -1
var _m_sent := Basis.IDENTITY
var _walk_z: float = -1.0
var _walk_y: float = -1.0
var _world_mats: Array = []
var _chunks: Array = []
var _chunk_x: float = 1.0e18
var _prof := PackedFloat32Array()
var _prof_img: Image
var _prof_tex: ImageTexture
var _q := PackedFloat32Array()
var _copy_t: int = 0
var _hd := Vector3.ZERO
var _sd := Vector3.ZERO
var _pv := Vector3.ZERO
var _hd0 := Vector3.ZERO
var _sd0 := Vector3.ZERO
var _reach: float = 1.0e9
var _ahead_tick: int = -1
var water_mat: ShaderMaterial
var mm_w: MultiMesh
var _node_w: MultiMeshInstance3D
var _buf_w := PackedFloat32Array()
var _drawn_w: int = 0
var _rings: Array = []
var _mark_tick: int = -1
var _mark_y: Dictionary = {}
var _mark_t: Dictionary = {}
var _tan: float = 0.5


func _init(p: PaneWorld, f: RenderTileField) -> void:
	pane = p
	field = f


## The match's setup with the switch on: a Whole ring of a planet (the one great circle a strip can lie on).
static func setup_of(su: Dictionary) -> Dictionary:
	var out: Dictionary = su.duplicate()
	if not out.has("planet"):
		out["planet"] = RenderLook.TILE_PLANET
		out["touch"] = 3
	out["planetGen"] = gen
	out.erase("arena")
	return out


## The frame to draw: the rig's shown heading when it has one (SplitFrame.place), else the sim's.
static var shown: PackedFloat64Array = PackedFloat64Array()


static func _shown_frame(S: SimState):
	if shown.size() != 7 or S.frame == null:
		return S.frame
	var fr := SimState.Frame.new()
	fr.px = shown[0]; fr.py = shown[1]; fr.pz = shown[2]
	fr.tx = shown[3]; fr.ty = shown[4]; fr.tz = shown[5]
	fr.x0 = shown[6]
	return fr


## Reads this frame's camera and places the world. After the planet's update, in place of the split's culling (which
## would put the strip's ground back).
func apply(host: SimHost, cam_x: float, vp: Vector2) -> void:
	var S: SimState = host.S
	if S == null or not (S.planetRing is Dictionary) or S.planetRing.is_empty():
		return
	if not _started:
		_begin()
		_started = true
	var tk: int = host.ticks
	var turned: float = _turn_at(tk)
	var wcx: float = SimWrap.wrap(cam_x)
	var fr: Array = field.frame_at(wcx, _shown_frame(S))
	_pv0 = fr[0]
	_hd0 = fr[1]
	_sd0 = fr[2]
	# Where the world's things were laid: the plan's frame at the same x. The sim's swing is the difference.
	var fp: Array = field.frame_at(wcx, S.frame0) if S.frame != null else fr
	_pvp = fp[0]
	_hdp = fp[1]
	_sdp = fp[2]
	# The turn about the pivot, in the camera's frame (along the line, up, toward the camera). At the camera it is
	# x' = x c - z s, z' = x s + z c.
	if turned == 0.0 or absf(SimWrap.sdx(cam_x, _pivot_x)) > 3000.0:
		_pivot_x = RenderTileField.middle_x(S)
	var ap: float = SimWrap.sdx(cam_x, _pivot_x) / field.R
	var m := Basis.IDENTITY if turned == 0.0 else Basis(Vector3(sin(ap), cos(ap), 0.0).normalized(), -deg_to_rad(turned))
	# On (along the line, up, toward the camera): from the plan's frame to the view's.
	var plan := Basis(Vector3(_hdp.dot(_hd0), _hdp.dot(_pv0), _hdp.dot(_sd0)), Vector3(_pvp.dot(_hd0), _pvp.dot(_pv0), _pvp.dot(_sd0)), Vector3(_sdp.dot(_hd0), _sdp.dot(_pv0), _sdp.dot(_sd0)))
	var world_m: Basis = m * plan
	_hd = (_hd0 * m.x.x + _pv0 * m.y.x + _sd0 * m.z.x).normalized()
	_pv = (_hd0 * m.x.y + _pv0 * m.y.y + _sd0 * m.z.y).normalized()
	_sd = (_hd0 * m.x.z + _pv0 * m.y.z + _sd0 * m.z.z).normalized()
	var width: float = 2.0 * pane.cam_rig.half_width(vp.x)
	var reff: float = field.R / _share_at(width)
	if absf(reff - _reff) > 1.0e-3 * reff:
		_reff = reff
		RenderingServer.global_shader_parameter_set("globe_r", reff)
	pane.mats.set_globe(reff, cam_x, field.off_tex)
	if world_m != _m_sent:
		_m_sent = world_m
		for wm in _world_mats:
			wm.set_shader_parameter("globe_m", world_m)
	if turned != _turn_sent:
		_turn_sent = turned
		if pane._sky_mat != null:
			pane._sky_mat.set_shader_parameter("sky_turn", deg_to_rad(turned))
	var cam_d: float = pane.cam_rig.position.z
	var cam_h: float = maxf(pane.cam_rig.position.y, 1.0)
	mat.set_shader_parameter("pv", _pv)
	mat.set_shader_parameter("pv0", _pv0)
	mat.set_shader_parameter("pvp", _pvp)
	mat.set_shader_parameter("hdp", _hdp)
	mat.set_shader_parameter("sdp", _sdp)
	mat.set_shader_parameter("hd", _hd)
	mat.set_shader_parameter("sd", _sd)
	mat.set_shader_parameter("hd0", _hd0)
	mat.set_shader_parameter("sd0", _sd0)
	mat.set_shader_parameter("strip_x", SimWrap.wrap(cam_x))
	for wk in ["pv", "pv0", "hd", "sd", "hd0", "sd0", "pvp", "hdp", "sdp", "strip_x"]:
		water_mat.set_shader_parameter(wk, mat.get_shader_parameter(wk))
	for k in ["wl_mul", "wl_add", "fore_cam"]:
		mat.set_shader_parameter(k, pane.planet._terrain_mat.get_shader_parameter(k))
		water_mat.set_shader_parameter(k, pane.planet._terrain_mat.get_shader_parameter(k))
	water_mat.set_shader_parameter("crater_now", S.T)
	_water_marks(S, tk)
	pane.planet._tile_foot_slice(S, _pv)
	if crater_look:
		_scar_slice(S)
	_clock = (float(host.ticks) + host.acc / SimConst.DT) * SimConst.DT
	_bowls(S)
	mat.set_shader_parameter("cb_now", _clock)   # by the render's clock: the opening's craters (S.T held at 0) open under the fighters standing in them
	mat.set_shader_parameter("crater_now", S.T)   # a record's colours open by it (crater_new): every frame, not with the ground's copy every 30
	_copy_t += 1
	if _copy_t % 30 == 1:
		_copy_ground(pane.planet._terrain_mat)
		_copy_to(water_mat, pane.planet._water_mat)
	# The tiles again once the view has moved enough to change them.
	if absf(cam_x - _walk_x) > RenderLook.TILE_WALK_STEP or _hd.dot(_walk_hd) < 0.99999 or absf(cam_d - _walk_z) > 0.02 * cam_d or absf(cam_h - _walk_y) > 0.05 * cam_h or field.version != _walk_v:
		_walk_hd = _hd
		_walk_v = field.version
		_walk_x = cam_x
		_walk_z = cam_d
		_walk_y = cam_h
		_select(cam_d, cam_h, reff, vp)
	# The foreground rule's line (_profile). The shader reads it from where the camera is now, so out of a turn it is read again
	# once the camera has moved FORE_PROFILE_STEP along the line or zoomed by FORE_PROFILE_ZOOM, or the ground or the heading
	# under it changed. Read only when the tiles were chosen again, it kept an earlier, wider view's line while the camera
	# eased in, and a fighter landing under it had his feet behind the ground in front (Orb's intro, 2026-11-07). While the
	# line turns: every TILE_PROFILE_FRAMES frames, or on a move of TILE_PROFILE_MOVE, as before.
	_prof_wait -= 1
	var along: float = absf(SimWrap.sdx(_prof_x, cam_x))
	var due: bool = _prof_wait <= 0 or along > RenderLook.TILE_PROFILE_MOVE
	if not (S.swing != null and S.swing.active):
		due = (due and not field.field_world) or along > RenderLook.FORE_PROFILE_STEP or absf(width - _prof_w) > RenderLook.FORE_PROFILE_ZOOM * width or int(S.storeN) != _prof_n or field.version != _prof_v or _hd.dot(_prof_hd) < 0.9999999
	if due:
		_prof_wait = RenderLook.TILE_PROFILE_FRAMES
		_prof_x = cam_x
		_prof_w = width
		_prof_n = int(S.storeN)
		_prof_v = field.version
		_prof_hd = _hd
		_profile(S, cam_x, width)
	_cull_chunks(cam_x, cam_h, reff)
	# The sky's horizon is the globe's, from the camera's height over the ground below it.
	var hz: float = -tan(acos(reff / (reff + cam_h)))
	if pane._sky_mat != null:
		pane._sky_mat.set_shader_parameter("horizon", hz)
	pane.mats.set_sky("horizon", hz)
	if pane.planet.source == null:
		_look_ahead(S, tk)
		field.keep_off(cam_x, RenderLook.TILE_OFF_COLS / 2 if S.swing != null and S.swing.active else RenderLook.TILE_OFF_COLS)
		field.fill(_fill_slice())


## The fill's slice: its least, and a share of the room this machine has under the frame's target, by the frame time smoothed over a few frames.
func _fill_slice() -> int:
	var now: int = Time.get_ticks_usec()
	if _fill_at > 0:
		_fill_dt = lerpf(_fill_dt, float(now - _fill_at), 0.1)
	_fill_at = now
	field.frame_room = RenderTileField.steady_fill or _fill_dt < float(RenderLook.TILE_FILL_TARGET_US)
	return clampi(RenderLook.TILE_FILL_US + int(RenderLook.TILE_FILL_ROOM * (float(RenderLook.TILE_FILL_TARGET_US) - _fill_dt)), RenderLook.TILE_FILL_US, RenderLook.TILE_FILL_MAX_US)


## The bowls the vertex stage draws: World's store is append-only, so a frame reads only what's new, and the nearest few to the camera are chosen again now and then. A rollback that shortens the store starts the list again.
## A bowl opens over TILE_BOWL_OPEN from when the render first saw it, by its own clock (_clock): the record's time is the sim's
## clock, which stands at 0 through the opening, so the first-meteor landing's craters never opened while the fighters stood in
## them (Orb's play, 2026-11-07; World's docs/world/orb-looks-1107.md). Less the record's own age if the sim's clock ran since it
## was dug (a pane that came late); one already there when the list starts is open.
func _bowls(S: SimState) -> void:
	var fresh: bool = false
	if S.storeN < _cb_seen:
		_cb.clear()
		_cb_seen = 0
		_cb_fresh = true
	while _cb_seen < S.storeN:
		var o: int = _cb_seen * WorldStore.STRIDE
		if int(S.store[o]) == WorldStore.KIND_CRATER:
			var made: float = _clock - RenderLook.TILE_BOWL_OPEN - 1.0 if _cb_fresh else _clock - maxf(S.T - float(S.store[o + 8]), 0.0)
			_cb.append([S.store[o + 1], S.store[o + 2], S.store[o + 3], S.store[o + 4], S.store[o + 5], S.store[o + 6], made])
			fresh = true
		_cb_seen += 1
	_cb_fresh = false
	_cb_due -= 1
	if not fresh and _cb_due > 0:
		return
	_cb_due = RenderLook.TILE_BOWL_FRAMES
	var near: Array = []
	for k in range(_cb.size()):
		var e: Array = _cb[k]
		near.append([_pv.distance_squared_to(Vector3(e[0], e[1], e[2])), k])
	near.sort()
	var n: int = mini(near.size(), RenderLook.TILE_BOWLS)
	_cb_a.resize(RenderLook.TILE_BOWLS)
	_cb_b.resize(RenderLook.TILE_BOWLS)
	for k in range(n):
		var e: Array = _cb[int(near[k][1])]
		_cb_a[k] = Vector4(e[0], e[1], e[2], e[3])
		_cb_b[k] = Vector4(e[4], e[5], e[6], 0.0)
	mat.set_shader_parameter("cb_n", n)
	mat.set_shader_parameter("cb_a", _cb_a)
	mat.set_shader_parameter("cb_b", _cb_b)
	mat.set_shader_parameter("cb_rim", Vector2(WorldCrater.RIM_IN, WorldCrater.RIM_OUT))
	mat.set_shader_parameter("cb_open", RenderLook.TILE_BOWL_OPEN)


## Art's scar tapers to a point over the last quarter of its run at both ends. How far a column is from its run's ends isn't in the sim, so the view works it out from the sim's scorch, a slice a frame, and only reads.
func _scar_slice(S: SimState) -> void:
	var n: int = SimConst.NC
	var stop: int = mini(_scar_i + RenderLook.SCAR_SLICE, n)
	while _scar_i < stop:
		_scar_on[_scar_i] = 1 if S.scorch[_scar_i] >= RenderLook.SCAR_MIN else 0
		_scar_i += 1
	if _scar_i < n:
		return
	_scar_i = 0
	if _scar_on == _scar_was:
		return
	_scar_was = _scar_on.duplicate()
	_scar_w.fill(0.0)
	var i: int = 0
	while i < n:
		if _scar_on[i] == 0:
			i += 1
			continue
		var j: int = i
		while j < n and _scar_on[j] != 0:
			j += 1
		var q: float = maxf(float(j - i) * 0.25, 1.0)
		for k in range(i, j):
			_scar_w[k] = minf(1.0, minf(float(k - i) + 0.5, float(j - k) - 0.5) / q)
		i = j
	_scar_img.set_data(n, 1, false, Image.FORMAT_RF, _scar_w.to_byte_array())
	_scar_tex.update(_scar_img)


## Water's A1 (docs/world/low-impact-water.md), view only: a hollow ring where a body crosses or skims the surface, and a short V wake behind one
## flying low and fast. Read from the fighters' places, so nothing here is hashed. Rings no faster than 2 Hz a body.
func _water_marks(S: SimState, tk: int) -> void:
	if tk != _mark_tick:
		_mark_tick = tk
		var wa := PackedVector4Array()
		wa.resize(2)
		var wn: int = 0
		for i in range(S.fighters.size()):
			var f = S.fighters[i]
			var fx: float = float(f.x)
			var top: float = field.water_top(field.dir_at(fx, 0.0, S.frame))
			if top < -1.0e8:
				continue
			var over: float = float(f.y) - top
			var last: float = float(_mark_y.get(i, over))
			_mark_y[i] = over
			if ((last > 0.0) != (over > 0.0) or absf(over) < RenderLook.TILE_RING_NEAR) and absf(last - over) > RenderLook.TILE_RING_MOVE and tk - int(_mark_t.get(i, -1000)) >= RenderLook.TILE_RING_TICKS:
				_mark_t[i] = tk
				_rings.append(Vector4(fx, 0.0, float(S.T), clampf(120.0 + absf(last - over) * 12.0, 120.0, 420.0)))
				if _rings.size() > 6:
					_rings.pop_front()
			if wn < 2 and over > 0.0 and over < RenderLook.TILE_WAKE_UP and absf(float(f.vx)) > RenderLook.TILE_WAKE_SPEED:
				wa[wn] = Vector4(fx, 0.0, signf(float(f.vx)), minf(absf(float(f.vx)) * 0.25, 1500.0) * (1.0 - over / RenderLook.TILE_WAKE_UP))
				wn += 1
		var ra := PackedVector4Array()
		var rb := PackedVector4Array()
		ra.resize(6)
		rb.resize(6)
		var rn: int = 0
		for r in _rings:
			if float(S.T) - float(r.z) < RenderLook.TILE_RING_S:
				ra[rn] = r
				rb[rn] = Vector4(RenderLook.TILE_RING_LIFT, RenderLook.TILE_RING_S, 0.0, 0.0)
				rn += 1
		water_mat.set_shader_parameter("ww_n", rn)
		water_mat.set_shader_parameter("ww_a", ra)
		water_mat.set_shader_parameter("ww_b", rb)
		water_mat.set_shader_parameter("wk_n", wn)
		water_mat.set_shader_parameter("wk_a", wa)


## Anything flying fast will be over ground nothing has asked for yet: ask for it, a couple of seconds ahead of it.
func _look_ahead(S: SimState, tk: int) -> void:
	if tk == _ahead_tick or tk % RenderLook.TILE_AHEAD_TICKS != 0:
		return
	_ahead_tick = tk
	for f in S.fighters:
		if absf(float(f.vx)) > RenderLook.TILE_AHEAD_SPEED:
			field.ask_around(float(f.x) + float(f.vx) * RenderLook.TILE_AHEAD_S, S.frame)


## The planet is being built again, so its copies are going: this drive ends with them.
func drop() -> void:
	field.forget_wants(get_instance_id())
	if _node != null:
		_node.queue_free()
		_node = null
	if _node_w != null:
		_node_w.queue_free()
		_node_w = null
	_chunks.clear()


func _begin() -> void:
	var planet: PlanetView = pane.planet
	var big := AABB(Vector3(-4.0e6, -4.0e6, -4.0e6), Vector3(8.0e6, 8.0e6, 8.0e6))
	for c in planet._copies:
		var k: int = int(c.get_meta("k"))
		for g in c.get_children():
			if not (g is GeometryInstance3D):
				continue
			var nm: String = g.name
			if k != 0 or nm.begins_with("Terrain") or nm.begins_with("Water") or nm.begins_with("FarTowns"):
				(g as GeometryInstance3D).layers = 0
				continue
			var own: AABB = (g as MultiMeshInstance3D).multimesh.custom_aabb if g is MultiMeshInstance3D and (g as MultiMeshInstance3D).multimesh != null else AABB()
			(g as GeometryInstance3D).custom_aabb = big
			if own.size.x > 0.0 and own.size.x < SimConst.W * 0.5:
				_chunks.append([g, own.position.x + own.size.x * 0.5, own.size.x * 0.5])
	_world_mats = [planet._bld_mat, planet._front_mat, planet._tree_mat, planet._cover_mat]
	for m in planet._crowd_mats:
		_world_mats.append(m)
	_world_mats = _world_mats.filter(func(m): return m != null)
	for m in _world_mats:
		m.set_shader_parameter("globe_world", 1.0)
		m.set_shader_parameter("globe_near_mode", near_mode)
		m.set_shader_parameter("globe_band", RenderLook.TILE_BAND)
		m.set_shader_parameter("globe_small", 0.0 if m == planet._bld_mat or m == planet._front_mat else 1.0)
	_make_tiles()


func _make_tiles() -> void:
	mat = ShaderMaterial.new()
	mat.shader = load("res://render/shaders/terrain_tile.gdshader")
	_copy_ground(pane.planet._terrain_mat)
	mat.set_shader_parameter("hts", field.hts)
	mat.set_shader_parameter("ids", field.ids)
	_prof.resize(64)
	_prof_img = Image.create_from_data(64, 1, false, Image.FORMAT_RF, _prof.to_byte_array())
	_prof_tex = ImageTexture.create_from_image(_prof_img)
	mat.set_shader_parameter("plane_tex", _prof_tex)
	water_mat = ShaderMaterial.new()
	water_mat.shader = load("res://render/shaders/water_tile.gdshader")
	_copy_to(water_mat, pane.planet._water_mat)
	water_mat.set_shader_parameter("hts", field.hts)
	water_mat.set_shader_parameter("ids", field.ids)
	water_mat.set_shader_parameter("plane_tex", _prof_tex)
	pane.mats.track(water_mat)
	mat.set_shader_parameter("fore_tone", 1.0 if fore_tone else 0.0)
	mat.set_shader_parameter("crater_look", 1.0 if crater_look else 0.0)
	mat.set_shader_parameter("scar_look", RenderLook.SCAR_LOOK)
	mat.set_shader_parameter("scar_fringe", RenderLook.SCAR_FRINGE)
	mat.set_shader_parameter("ice_cap", RenderLook.TILE_ICE_CAP)
	_scar_w.resize(SimConst.NC)
	_scar_w.fill(0.0)
	_scar_on.resize(SimConst.NC)
	_scar_on.fill(0)
	_scar_was.resize(SimConst.NC)
	_scar_was.fill(0)
	_scar_img = Image.create_from_data(SimConst.NC, 1, false, Image.FORMAT_RF, _scar_w.to_byte_array())
	_scar_tex = ImageTexture.create_from_image(_scar_img)
	mat.set_shader_parameter("scar_tex", _scar_tex)
	mat.set_shader_parameter("crater_rings", RenderLook.CRATER_RINGS)
	mat.set_shader_parameter("crater_steps", RenderLook.CRATER_STEPS)
	pane.mats.track(mat)
	# The tile mesh: 26 by 26 and a ring outside it: the skirt.
	var n: int = RenderTileField.CELLS + 1
	var n2: int = n + 2
	var vs := PackedVector3Array()
	var uv := PackedVector2Array()
	var idx := PackedInt32Array()
	var cells: float = float(RenderTileField.CELLS)
	for b in range(n2):
		for a in range(n2):
			vs.append(Vector3(float(a), 0.0, float(b)))
			uv.append(Vector2(float(a - 1) / cells, float(b - 1) / cells))
	for b in range(n2 - 1):
		for a in range(n2 - 1):
			var q: int = b * n2 + a
			idx.append_array([q, q + 1, q + n2, q + n2, q + 1, q + n2 + 1])
	var arr: Array = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = vs
	arr[Mesh.ARRAY_TEX_UV] = uv
	arr[Mesh.ARRAY_INDEX] = idx
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = am
	mm.instance_count = MAX_TILES
	mm.visible_instance_count = 0
	_node = MultiMeshInstance3D.new()
	_node.multimesh = mm
	_node.material_override = mat
	_node.custom_aabb = AABB(Vector3(-4.0e6, -4.0e6, -4.0e6), Vector3(8.0e6, 8.0e6, 8.0e6))
	pane.planet.add_child(_node)
	_buf.resize(MAX_TILES * 16)
	# The water: the tiles with water in them, a second time, with the water's own shader.
	mm_w = MultiMesh.new()
	mm_w.transform_format = MultiMesh.TRANSFORM_3D
	mm_w.use_custom_data = true
	mm_w.mesh = am
	mm_w.instance_count = MAX_TILES
	mm_w.visible_instance_count = 0
	_node_w = MultiMeshInstance3D.new()
	_node_w.multimesh = mm_w
	_node_w.material_override = water_mat
	_node_w.custom_aabb = _node.custom_aabb
	pane.planet.add_child(_node_w)
	_buf_w.resize(MAX_TILES * 16)


func _copy_ground(src: ShaderMaterial) -> void:
	_copy_to(mat, src)


func _copy_to(to: ShaderMaterial, src: ShaderMaterial) -> void:
	for u in src.shader.get_shader_uniform_list():
		var nm: String = u.name
		if nm in ["ww_n", "ww_a", "ww_b", "wf_n", "wf_a", "wf_b", "wf_c", "fore_tone", "hts", "ids", "plane_tex", "pv", "pv0", "pvp", "hdp", "sdp", "hd", "sd", "hd0", "sd0", "strip_x", "plane_span", "globe_sx", "globe_off", "globe_lift_on", "globe_m"]:
			continue
		var v: Variant = src.get_shader_parameter(nm)
		if v != null:
			to.set_shader_parameter(nm, v)


## The left-out chunks of the crowd and the cover: the turn needs their boxes gone, not the culling, so they go by reach.
func _cull_chunks(cam_x: float, cam_h: float, reff: float) -> void:
	if absf(cam_x - _chunk_x) < RenderLook.TILE_CHUNK_STEP:
		return
	_chunk_x = cam_x
	var reach: float = reff * (acos(reff / (reff + cam_h)) + acos(reff / (reff + RenderLook.TILE_CHUNK_TALL))) + pane.cam_rig.position.z
	for e in _chunks:
		if not is_instance_valid(e[0]):
			continue   # a chunk the view made again (the cover's, for a new world)
		(e[0] as GeometryInstance3D).layers = 1 if absf(SimWrap.sdx(_pivot_x if _turn_sent != 0.0 else cam_x, float(e[1]))) - float(e[2]) < reach else 0


func _share_at(w: float) -> float:
	if share >= 1.0:
		return 1.0
	return lerpf(share, 1.0, clampf((log(w) - log(950.0)) / (log(2700.0) - log(950.0)), 0.0, 1.0))


func _turn_at(t: int) -> float:
	if rate <= 0.0:
		return 0.0
	if quick:
		return _quick_at(t)
	var per: float = rate / 60.0
	var te: int = int(ceil(360.0 / per)) + EASE
	var c: int = t % (te + HOLD)
	if c >= te:
		return 0.0
	var peak: float = 360.0 / float(te - EASE)
	if c < EASE:
		return fposmod(0.5 * peak * float(c * c) / float(EASE), 360.0)
	if c < te - EASE:
		return fposmod(peak * (float(c) - 0.5 * float(EASE)), 360.0)
	var r: int = te - c
	return fposmod(360.0 - 0.5 * peak * float(r * r) / float(EASE), 360.0)


func _quick_at(t: int) -> float:
	if _q.is_empty():
		var per: float = rate / 60.0
		var cur: float = 0.0
		var sgn: float = 1.0
		var sizes: Array = [15.0, 5.0, 10.0]
		var k: int = 0
		while _q.size() < 1600:
			var deg: float = float(sizes[k % 3])
			var n: int = int(ceil(deg / per + 5.0))
			var peak: float = deg / (float(n) - 5.0)
			for c in range(n):
				var a: float
				if c < 5:
					a = 0.5 * peak * float(c * c) / 5.0
				elif c < n - 5:
					a = peak * (float(c) - 2.5)
				else:
					var r2: int = n - c
					a = deg - 0.5 * peak * float(r2 * r2) / 5.0
				_q.append(cur + sgn * a)
			cur += sgn * deg
			for c in range(24):
				_q.append(cur)
			sgn = -sgn
			k += 1
	return fposmod(_q[t % _q.size()], 360.0)


## What this pane's camera can show this frame, for the building sweep (PlanetView.see_cap), before apply: the planet
## under it, its axes, its depth, how far a tile can show from it and the width of its view, as _select and _walk read
## them. [] under a test turn (--tilerate): the sweep then goes by its span.
func view_cap(S: SimState, tk: int, cam_x: float, vp: Vector2) -> Array:
	if _turn_at(tk) != 0.0:
		return []
	var fr: Array = field.frame_at(SimWrap.wrap(cam_x), S.frame)
	var reff: float = field.R / _share_at(2.0 * pane.cam_rig.half_width(vp.x))
	var cam_d: float = pane.cam_rig.position.z
	var cam_h: float = maxf(pane.cam_rig.position.y, 1.0)
	var reach: float = cam_d + reff * (acos(reff / (reff + cam_h)) + acos(reff / (reff + RenderLook.TILE_TALLEST)))
	return [fr[0], fr[1], fr[2], cam_d, reach, tan(deg_to_rad(pane.cam_rig.fov * 0.5)) * vp.x / maxf(vp.y, 1.0)]


func _select(cam_d: float, cam_h: float, reff: float, vp: Vector2) -> void:
	field.begin_wants(get_instance_id())
	_reach = cam_d + reff * (acos(reff / (reff + cam_h)) + acos(reff / (reff + RenderLook.TILE_TALLEST)))
	_tan = tan(deg_to_rad(pane.cam_rig.fov * 0.5)) * vp.x / maxf(vp.y, 1.0)
	_drawn = 0
	_drawn_w = 0
	var n0: int = RenderTileField.LEVEL0
	for f in range(6):
		for j in range(n0):
			for i in range(n0):
				_walk(f, 0, i, j, cam_d)
	mm.visible_instance_count = 0
	mm.buffer = _buf
	mm.visible_instance_count = _drawn
	mm_w.visible_instance_count = 0
	mm_w.buffer = _buf_w
	mm_w.visible_instance_count = _drawn_w


static func _center(f: int, n: int, i: int, j: int) -> Vector3:
	var size: float = 2.0 / float(n)
	var s: float = -1.0 + (float(i) + 0.5) * size
	var t: float = -1.0 + (float(j) + 0.5) * size
	var fc: Array = RenderTileField.FACES[f]
	return ((fc[0] as Vector3) + (fc[1] as Vector3) * tan(s * PI / 4.0) + (fc[2] as Vector3) * tan(t * PI / 4.0)).normalized()


func _walk(f: int, L: int, i: int, j: int, cam_d: float) -> void:
	var n: int = RenderTileField.level_n(L)
	var w: float = 12800.0 / float(1 << L)
	var c: Vector3 = _center(f, n, i, j)
	var a: float = atan2(c.cross(_pv).length(), c.dot(_pv))
	var d: float = a * field.R
	var k: float = a / maxf(sin(a), 1.0e-5) * field.R
	var x: float = c.dot(_hd) * k
	var z: float = c.dot(_sd) * k
	var reach: float = w * 0.8
	var depth: float = cam_d - z
	if depth < -reach or absf(x) - reach > (maxf(depth, 0.0) + reach) * _tan:
		return
	if d - reach > _reach:
		return
	var split: bool = L < TILE_MAX_LEVEL and maxf(d - w * 0.75, 0.0) < RenderLook.TILE_K * w
	if split and L + 1 < RenderTileField.LEVELS:
		# A finer level comes when all four of its data are there; meanwhile the parent draws and they're on their way. Below 128 the mesh
		# goes on anyway, for what lies on the ground, and reads the finest data it has (_emit).
		for q in range(4):
			var ck: int = RenderTileField.key_of(f, L + 1, i * 2 + (q & 1), j * 2 + (q >> 1))
			field.want(ck, d)
			if not field.has(ck) and L < RenderTileField.BASE_LEVEL:
				split = false
	if split:
		for q in range(4):
			_walk(f, L + 1, i * 2 + (q & 1), j * 2 + (q >> 1), cam_d)
		return
	_emit(f, L, i, j, w)


## One tile in the instance buffer: its face, its place on it, its layer and the data level, its morph.
func _emit(f: int, L: int, i: int, j: int, w: float) -> void:
	if _drawn >= MAX_TILES:
		return
	var dl: int = mini(L, RenderTileField.LEVELS - 1)
	var di: int = i >> (L - dl)
	var dj: int = j >> (L - dl)
	var lay: int = field.layer_of(RenderTileField.key_of(f, dl, di, dj))
	while lay < 0 and dl > RenderTileField.BASE_LEVEL:
		dl -= 1
		di = i >> (L - dl)
		dj = j >> (L - dl)
		lay = field.layer_of(RenderTileField.key_of(f, dl, di, dj))
	if lay < 0:
		return
	field.want(RenderTileField.key_of(f, dl, di, dj), 0.0)
	var fc: Array = RenderTileField.FACES[f]
	var nn: Vector3 = fc[0]
	var u: Vector3 = fc[1]
	var v: Vector3 = fc[2]
	var size: float = 2.0 / float(RenderTileField.level_n(L))
	var o: int = _drawn * 16
	_buf[o] = nn.x
	_buf[o + 1] = u.x
	_buf[o + 2] = v.x
	_buf[o + 3] = -1.0 + float(i) * size
	_buf[o + 4] = nn.y
	_buf[o + 5] = u.y
	_buf[o + 6] = v.y
	_buf[o + 7] = -1.0 + float(j) * size
	_buf[o + 8] = nn.z
	_buf[o + 9] = u.z
	_buf[o + 10] = v.z
	_buf[o + 11] = size
	_buf[o + 12] = float(lay)
	_buf[o + 13] = (1.4 * RenderLook.TILE_K * w if L > 0 else 3.0e5) / 1000.0
	_buf[o + 14] = (1.95 * RenderLook.TILE_K * w if L > 0 else 3.1e5) / 1000.0
	_buf[o + 15] = float(dl) * 16.0 + w / 1000.0   # the data level over the width: instance data can be half floats, so a fraction on a large layer number would be lost
	if field.tile_wet(lay):
		var ow: int = _drawn_w * 16
		for q in range(16):
			_buf_w[ow + q] = _buf[o + q]
		_drawn_w += 1
	_drawn += 1


## The line's own ground in view, 64 points: the foreground rule's sight lines end on it.
func _profile(S: SimState, cam_x: float, width: float) -> void:
	var half: float = width * 1.4
	for k in range(64):
		var along: float = lerpf(-half, half, float(k) / 63.0)
		var a: float = along / field.R
		var pd: Vector3 = _pv * cos(a) + _hd * sin(a)
		var h: float = field.height_at(pd)
		# A dent on the line is the sim's, not the tile's: on a field world it's in the store, and a read of the sim's ground here would cost a cold column every time a swing moves the frame.
		_prof[k] = 0.0 if h < 0.0 else (h + minf(WorldStore.heightDelta(S, pd.x, pd.y, pd.z), 0.0) if field.field_world else minf(h, WorldTerrain.groundY(S, SimWrap.wrap(cam_x + along))))
	_prof_img.set_data(64, 1, false, Image.FORMAT_RF, _prof.to_byte_array())
	_prof_tex.update(_prof_img)
	mat.set_shader_parameter("plane_span", half)
