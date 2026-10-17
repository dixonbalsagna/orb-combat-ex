class_name PlanetView
extends Node3D
## The wrapped planet: the ground and water, one surface from the fighter plane to the horizon (the far part is the
## same planet's terrain, fading into the sky), and the buildings, trees and crowd. Everything anchored to the world is
## built once per match in world x [0, W) and drawn as copies one planet apart, placed at k * W - cam.x: the ground
## and water in 2 * PLANET_COPIES + 1 copies (the horizon is wide), the props in three. The copies are identical, so the seam at x = 0 / W can never pop, at any zoom or separation, and a
## view wider than the planet (tiny zoom on an ultra-wide or phone screen) still shows every object at every place it
## appears. Per-frame cost is three node moves plus whatever changed in the sim since the last frame: the ground field
## (render/core/ground_field.gd: round crater bowls in depth, scorch, water) when craters dig, beams scorch or water
## flows, and the instances of damaged buildings, fallen trees and lost civilians, and of props on changed ground.
## Civilians who flee (World's evacuate events) run off as figures (render/core/crowd_flight.gd) instead of vanishing.
## Reads the sim only; never writes it.
##
## One per pane (render/core/pane_world.gd). The first pane's planet owns the world: the ground field, the meshes,
## the props and their logic. A second pane's planet has that one as its `source`: it shares all of that and draws it
## with its own copies and materials (from its pane's RenderMats), which carry its camera, so every change is made
## and uploaded once.

const TERRAIN_SHADER: Shader = preload("res://render/shaders/terrain.gdshader")
const WATER_SHADER: Shader = preload("res://render/shaders/water.gdshader")
const CROWD_SHADER: Shader = preload("res://render/shaders/crowd.gdshader")
const BUILDING_SHADER: Shader = preload("res://render/shaders/building.gdshader")
const STUB_WHOLE := 1.0e9     # a stub height that cuts nothing
const OPEN_OFF := -2.0e9      # stub_tex's b for a building with no lobby (building.gdshader v_open),
const OPEN_SHUT := -1.0e9     # ... and for a tower with one, while this pane has nothing of it open (open, b is the lobby's top)
const STREET_STRIPS := 16     # the ground shader's array sizes (ground.gdshaderinc): three streets of five strips, and one to spare
const STREET_SPANS := 16
const STREET_AVENUES := 24
const BUILDING_TOP: float = 2600.0   # the buildings' culling box reaches this high, in WS (the tallest tower of the re-laid city is under 2,300)
static var row_haze: bool = true     # the rows' haze (building.gdshader); a tool may switch it off to compare

static var streets: bool = true   # paint the lane table's streets on the ground (main's --nostreets, for A/B)
static var windows: bool = true   # draw the buildings' windows (main's --nowindows, for A/B)

var ground := GroundField.new()
var mats: RenderMats = RenderMats.new()   # this pane's material state (PaneWorld sets it)
var source: PlanetView = null         # a second pane's planet: the planet it draws (built first each match)
var _terrain_meshes: Array = []   # [ArrayMesh]: every chunk of the near and middle tiers, then the far tier
var _water_meshes: Array = []
var _crowd_mat: ShaderMaterial
var _terrain_mat: ShaderMaterial
var _water_mat: ShaderMaterial
var _bld: MultiMesh                  # every part of every building that is not in row 0: the bodies by building index, then the other parts
var _tree: MultiMesh
var _tree_mat: ShaderMaterial        # this pane's trees (their own, so the world's light tints them alone)
var _wl: Array = []                  # the world's light (SkyDrive.world_at), kept for materials made later
var _wl_win: float = RenderLook.WINDOW_LIT_SHARE
var _crowd: MultiMesh
var _bld0: MultiMesh                 # row 0, in front of the fighter plane: its own MultiMesh (bodies by row-0 index, then the other parts)
var _parts: Array = []               # per building: its parts as it stands whole (RenderShapes.parts), the body first; shared by panes
var _inst: Array = []                # per building: each part's instance in its MultiMesh (PackedInt32Array, the body's first)
var _look := PackedInt32Array()      # per building: its district's look
var _city := PackedFloat32Array()    # per building: its city look for building.gdshader (RenderShapes.city_code; 0: none)
var _n_inst: int = 1                 # instances in _bld
var _n_inst0: int = 1                # ... and in _bld0
var _row0 := PackedInt32Array()      # per building: its index in _bld0, or -1
var _row0_b := PackedInt32Array()    # per row-0 index: the building
var _front_mat: ShaderMaterial       # this pane's material for row 0 (its holes and stubs, by row-0 index)
var _bld_mat: ShaderMaterial         # ... and for the other rows (by building index)
var _stub_tex: Array = []            # [Image, ImageTexture]: this pane's cut height per building (building.gdshader stub_tex)
var _stub_tex0: Array = []           # ... and per row-0 index
var _stub := PackedFloat32Array()    # this pane's stubs, per building: 0 whole to 1 cut down to its stub
var _stub_live: Dictionary = {}      # the buildings whose stub is not 0, or is wanted
var _stub_t: float = -1.0
var _stub_hold: Dictionary = {}      # a building lowered by the foreground patch -> the tick time before which it does not stand again
var _sink_last: float = -1.0e9       # the tick time a building last sank under the patch (none stands again within the hold of it)
var _crowd_near: bool = false        # the crowd shader has the near-clip rule on (a match with depth on)
var _bld_soft: bool = false          # the rows' material has the patch's soft edge (a match with depth on)
var _focus_z: float = 0.0            # this pane's focus depth as last sent to the building shader
var _gone: Dictionary = {}           # a building Camera's near-clip rule takes out of the picture -> how far gone it is, 0 (its stub) to 1 (under its footing)
var _open: Dictionary = {}           # this pane's lobbies and the towers' shares of the patch (set_open): building -> [the share of its lobby open, its share of the patch, the tick times each was last asked for, the pixels a unit of its height covers, its lobby's floor and top, the two shares wanted now]
var _open_t: float = -1.0
var _open_kind := PackedByteArray()  # per building, in a match with depth on: 1 a tower with a lobby (opens), 2 a tall building without one; 0 any other, and every building with depth off
var open_turned: float = 0.0         # the pixels the openings turned in the last set_open (for tools)
var _top := PackedFloat64Array()     # per building: its top as drawn (-INF when it does not stand), shared by panes
var _cut: Array = []                 # [Image, ImageTexture, dirty]: each building's cut floors (building.gdshader), shared by panes
var _cut0: Array = []                # ... and the row-0 buildings', by row-0 index
var _win: Array = []                 # [Image, ImageTexture, dirty]: each building's windows (building.gdshader win_tex), shared by panes
var _win0: Array = []                # ... and the row-0 buildings'
var _blown: Array = []               # per building: a bit per floor whose windows have gone out (VFX's blow-outs), shared by panes
var _blow_seen: Dictionary = {}      # the blow-outs already taken: Vector2(building, its time)
var _holes_on: bool = false          # a porthole is open in this pane's building materials
var _cues_on: bool = false           # a lane cue shows in this pane's ground materials
var _pair_on: bool = false           # the pair's mark shows in them
var _foot: Array = []                # per building: the lowest and highest ground under its footprint (shared by panes)
var _falls: Dictionary = {}          # building -> [sim time its sink starts, standing height]: implodes in progress
var _spread: Dictionary = {}         # building -> [x from its shell's middle, y over its base, the tick it started, the stage before, sharing]: a stage spreading over it from where it was hit (shared by panes)
var _marks: Dictionary = {}          # building -> its held hits' marks as written: [[first floor, floors, share, side, the share before, the tick it grows from, sharing], ...] (shared by panes)
var _busy: Dictionary = {}           # building -> the tick its spread or its mark's growth is over (shared by panes)
var _drops: Dictionary = {}          # building -> [the height it is coming down from, the tick it started]: a top coming down to its new height (RenderLook.DROP_SPEED)
var _blowing: Dictionary = {}        # building -> [the floors a blow-out has just put out (a bit a floor), x from its shell's middle, y over its base, the tick, sharing]: their panes go out as a wave
var _hit_last: Dictionary = {}       # building -> [x from its shell's middle, y over its base, the tick]: where it was last hit (a blow-out comes some ticks after the hit)
var _hit_at: Dictionary = {}         # building -> [world x or NAN, world y or NAN, rank, side]: where this frame's events hit it (consume; refresh empties it)
var _hit_side: Dictionary = {}       # building -> {floor: the side a held blow came from, -1 its left, 1 its right}
var _share_n: int = 1                # the buildings sharing a wave's area: always one (each building's wave has the whole area a tick; the rows still carry the number)
var _blasts: Array = []              # this frame's craters, [x, y]: a blast's wave starts at its height (consume; refresh empties it)
var _last_tick: int = -1             # the sim's tick at the last refresh (a seek back settles every spread)
var _spread_sent: float = -1.0       # the tick last sent to this pane's building shaders
var _fold: Array = []                # [cx, sim time]: a district of implodes folded into one event this tick
var _copies: Array = []
var _bld_seen: Array = []          # per building: [curH, alive, fmask, hp, stage], the height and stage as it last stood
var _drawn: Array = []             # per building: [height, stage 0 to 3, standing] as drawn (a falling one keeps its last look)
var _grow := PackedInt32Array()    # this refresh's buildings with more people than figures at home
var _tree_seen: Array = []         # per tree: alive
var _tree_z := PackedFloat64Array()
var _crowd_first := PackedInt32Array()
var _crowd_x := PackedFloat64Array()   # world x per person
var _crowd_z := PackedFloat64Array()
var _shown := PackedInt32Array()       # per building: figures standing at home, -1 before the first placement
var flight := CrowdFlight.new()
var _blows: Array = []                 # this frame's blows (x): craters, scorch, building damage
var _startled: Dictionary = {}         # crowd instance -> sim time it calms down (RenderLook.STARTLE_*)
var _calm_at: float = INF              # the earliest of those


## Build the planet for the match in S (after SimCore.newMatch).
func build(S: SimState) -> void:
	for c in _copies:
		remove_child(c)
		c.free()
	_copies.clear()
	if source != null:
		ground = source.ground
		_terrain_meshes = source._terrain_meshes
		_water_meshes = source._water_meshes
	if _terrain_mat == null:
		_make_materials()
		if source == null:
			_make_ground_meshes()
		_tree_mat = mats.flat_named("trees", Color.WHITE)
		_crowd_mat = ShaderMaterial.new()
		_crowd_mat.shader = CROWD_SHADER
		_crowd_mat.set_shader_parameter("outline_col", RenderLook.col(RenderLook.CROWD_OUTLINE))
		_crowd_mat.set_shader_parameter("skin_a", RenderLook.col(RenderLook.CROWD_SKIN[0]))
		_crowd_mat.set_shader_parameter("skin_b", RenderLook.col(RenderLook.CROWD_SKIN[1]))
		_crowd_mat.set_shader_parameter("legs", RenderLook.col(RenderLook.CROWD_LEGS))
		_crowd_mat.set_shader_parameter("run_hz", RenderLook.RUN_STRIDE_HZ)
		_crowd_mat.set_shader_parameter("leg_swing", RenderLook.RUN_LEG_SWING)
		_crowd_mat.set_shader_parameter("arm_swing", RenderLook.RUN_ARM_SWING)
		_crowd_mat.set_shader_parameter("run_lean", RenderLook.RUN_LEAN)
		_crowd_mat.set_shader_parameter("run_bob", RenderLook.RUN_BOB)
		_crowd_mat.set_shader_parameter("startle_arms", RenderLook.STARTLE_ARMS)
		_crowd_mat.set_shader_parameter("startle_crouch", RenderLook.STARTLE_CROUCH)
		_crowd_mat.set_shader_parameter("startle_tremble", RenderLook.STARTLE_TREMBLE)
	if source == null:
		ground.rebuild(S)
		_make_props(S)
	else:
		_bld = source._bld
		_parts = source._parts
		_inst = source._inst
		_look = source._look
		_city = source._city
		_n_inst = source._n_inst
		_n_inst0 = source._n_inst0
		_tree = source._tree
		_crowd = source._crowd
		_bld0 = source._bld0
		_row0 = source._row0
		_row0_b = source._row0_b
		_foot = source._foot
		_top = source._top
		_falls = source._falls
		_cut = source._cut
		_cut0 = source._cut0
		_win = source._win
		_win0 = source._win0
		_blown = source._blown
		_spread = source._spread
		_marks = source._marks
		_busy = source._busy
	if _front_mat == null:
		_front_mat = _building_mat()
		_bld_mat = _building_mat()
	_stub.resize(S.buildings.size())
	_stub.fill(0.0)
	_stub_live.clear()
	_gone.clear()
	_apply_wl()
	_stub_t = -1.0
	_stub_tex = _stub_texture(_bld_mat, _n_inst)
	_stub_tex0 = _stub_texture(_front_mat, _n_inst0)
	_mark_open(S)
	_bld_mat.set_shader_parameter("cut_tex", _cut[1])
	_front_mat.set_shader_parameter("cut_tex", _cut0[1])
	_bld_mat.set_shader_parameter("win_tex", _win[1])
	_front_mat.set_shader_parameter("win_tex", _win0[1])
	for m in [_bld_mat, _front_mat]:
		m.set_shader_parameter("windows", 1.0 if windows else 0.0)
		m.set_shader_parameter("spread_now", 0.0)
	_spread_sent = -1.0
	_set_lanes(S)
	for k in range(-RenderLook.PLANET_COPIES, RenderLook.PLANET_COPIES + 1):
		var n := Node3D.new()
		n.name = "Copy%d" % (k + RenderLook.PLANET_COPIES)
		n.set_meta("k", k)
		add_child(n)
		for m in range(_terrain_meshes.size()):
			_mesh_child(n, "Terrain%d" % m, _terrain_meshes[m], _terrain_mat)
			_mesh_child(n, "Water%d" % m, _water_meshes[m], _water_mat)
		if absi(k) <= 1:
			_mm_child(n, "Buildings", _bld, _bld_mat)
			_mm_child(n, "Buildings0", _bld0, _front_mat)
			_mm_child(n, "Trees", _tree, _tree_mat)
			_mm_child(n, "Crowd", _crowd, _crowd_mat)
		_copies.append(n)
	if source == null:
		refresh(S, true)


## Per frame: place the copies around the camera's wrapped x and apply whatever changed in the world (the first
## pane's planet only; a second pane's draws what that one made). heat is the render-side glow of fresh grooves
## (ImpactFx).
func update(S: SimState, cam_x: float, heat: PackedFloat32Array = PackedFloat32Array(), heat_changed: bool = false) -> void:
	if _terrain_mat != null and _crater_now != S.T:
		# A new crater's age, for its opening (and the calm form's colours): on both materials that draw the ground.
		_crater_now = S.T
		_terrain_mat.set_shader_parameter("crater_now", S.T)
		_water_mat.set_shader_parameter("crater_now", S.T)
	for c in _copies:
		c.position.x = float(c.get_meta("k")) * SimConst.W - cam_x
	if source != null:
		_send_spread(S, source)
		return
	ground.update(S, heat, heat_changed)
	flight.arrive(S, _crowd)
	refresh(S, false)
	flight.step(S, _crowd)
	_startle(S)
	_send_spread(S, self)


## The spread's clock for this pane's building shaders: the sim's tick (it runs through a hit-stop, so a wall slam's
## mark grows while the body is held). Sent only while something spreads, and once when the tick has gone back.
func _send_spread(S: SimState, src: PlanetView) -> void:
	var now: float = float(S.tick)
	if (src._busy.is_empty() and now >= _spread_sent) or now == _spread_sent or _bld_mat == null:
		return
	_spread_sent = now
	for m in [_bld_mat, _front_mat]:
		m.set_shader_parameter("spread_now", now)


## One tick's fx events at sim time T, as the host drains them: the evacuate events start the flight, blows startle
## the crowd, and implodes start their buildings' sink at the ripple's delay.
func consume(events: Array, T: float = 0.0) -> void:
	flight.consume(events)
	for e in events:
		if e.type == "crater" or e.type == "scorch" or e.type == "debris":
			_blows.append(e.x)
			if e.type == "crater":
				_blasts.append([float(e.x), float(e.y)])
		elif e.type == "building_fall" and String(e.mode) == "implode":
			if int(e.b) >= 0:
				_falls[int(e.b)] = [T + float(e.delay), -1.0]
			else:
				_fold = [float(e.cx), T]
		elif e.type == "lodge" or e.type == "building_hit" or e.type == "floor_hit" or e.type == "building_stage":
			_note_hit(e)


## Where one of this frame's events hit a building: a stage spreads from there, and a mark is on the side a held blow
## came from. A lodge says where the body is; a brunt or a shot through floors, the height and the side it came from;
## a stage change alone (a blast), the blast's x, at the building's foot. The best of them is kept until the next
## refresh.
func _note_hit(e) -> void:
	var bi: int = int(e.b)
	if bi < 0 or bi >= _parts.size():
		return
	var at: Array = _hit_at.get(bi, [NAN, NAN, 0, 0.0])
	var side: float = 0.0
	if (e.type == "building_hit" or e.type == "floor_hit") and absf(float(e.ux)) > 0.05:
		side = -1.0 if float(e.ux) > 0.0 else 1.0   # he came in by the side he was flying from
	if e.type == "lodge":
		at = [float(e.x), float(e.y), 3, at[3]]
	elif e.type == "building_stage":
		if int(at[2]) < 1:
			at = [float(e.cx), NAN, 1, at[3]]
	elif int(at[2]) < 2:
		at = [NAN, float(e.y), 2, at[3]]   # x: the edge of the side he came in by (_hit_place)
	if float(at[3]) == 0.0 and side != 0.0:
		at[3] = side
	_hit_at[bi] = at
	if e.type == "floor_hit" and side != 0.0 and (String(e.outcome) == "crack" or String(e.outcome) == "dent"):
		var sides: Dictionary = _hit_side.get(bi, {})
		for k in range(int(e.floor), int(e.floor) + WorldBrunt.HIT_FLOORS):
			sides[k] = side
		_hit_side[bi] = sides


## Where this frame's events hit building bi, for the shader: across from its shell's middle (inside its width) and up
## from its base (the foot when the event had no height).
func _hit_place(S: SimState, bi: int, b) -> Vector2:
	var at: Array = _hit_at[bi]
	var x: float = float(at[0])
	if is_nan(x):
		x = b.x + float(at[3]) * 0.5 * b.w
	var ps: Array = _parts[bi]
	var dx: float = clampf(SimWrap.sdx(b.x, x), -0.5 * b.w, 0.5 * b.w) - float(ps[RenderShapes.shell(ps)][RenderShapes.X])
	var y: float = float(at[1])
	if is_nan(y):
		# A blast: the height of its crater (the nearest of this frame's along x), which is in the picture; the
		# building's own foot may be at the bottom of the bowl.
		var best: float = 400.0
		for bl in _blasts:
			var d: float = absf(SimWrap.sdx(float(bl[0]), x))
			if d < best:
				best = d
				y = float(bl[1])
	return Vector2(dx, 0.0 if is_nan(y) else clampf(y - WorldStructures.baseY(S, b), 0.0, WorldStructures.curH(b)))


## Building b's marks from its floors' damage (a held blow adds to World's fdmg; a floor that breaks is cleared and its
## damage forgotten): each run of standing floors that have taken damage from one side is a mark, [its first floor, its
## floors, the share of its strength the worst of them has taken, the side, the share before this hit, the tick it
## grows from, sharing]; the heaviest RenderLook.MARK_RUNS are kept. A mark that is new or heavier than the one written
## grows from the corner at the spread's pace when an event of this frame hit the building; with no event (a seek, a
## late join) it is whole at once, and its side, which only the event knew, is the building's own choice.
func _marks_of(S: SimState, bi: int, b) -> Array:
	var out: Array = []
	var F: int = int(b.floors)
	if not b.alive or F < WorldBrunt.FLOORS_MIN or b.fdmg.size() < F:
		return out
	var sides: Dictionary = _hit_side.get(bi, {})
	var k: int = 0
	while k < F:
		if b.fdmg[k] <= 0.0 or not WorldBrunt.isStanding(b, k):
			k += 1
			continue
		var side: float = float(sides.get(k, 0.0))
		var f0: int = k
		var q: float = 0.0
		while k < F and b.fdmg[k] > 0.0 and WorldBrunt.isStanding(b, k) and float(sides.get(k, 0.0)) == side:
			q = maxf(q, b.fdmg[k] / maxf(WorldBrunt.floorStr(b, k), 0.001))
			k += 1
		if side == 0.0:
			side = -1.0 if (bi * 7 + f0 * 3) % 2 == 0 else 1.0
		out.append([f0, k - f0, clampf(q, 0.0, 1.0), side, 0.0, -1.0e6, 1])
	out.sort_custom(func(a, c): return a[2] > c[2] or (a[2] == c[2] and a[0] < c[0]))
	if out.size() > RenderLook.MARK_RUNS:
		out.resize(RenderLook.MARK_RUNS)
	var live: bool = RenderLook.SPREAD_ON and _hit_at.has(bi)
	var grew: bool = false
	for run in out:
		var prev: Array = []
		for o in _marks.get(bi, []):
			if int(o[0]) < int(run[0]) + int(run[1]) and int(run[0]) < int(o[0]) + int(o[1]) and float(o[3]) == float(run[3]) and (prev.is_empty() or float(o[2]) > float(prev[2])):
				prev = o
		if not prev.is_empty() and float(prev[2]) >= float(run[2]) and int(prev[0]) == int(run[0]) and int(prev[1]) == int(run[1]):
			run[4] = prev[4]
			run[5] = prev[5]
			run[6] = prev[6]
		elif live:
			run[4] = float(prev[2]) if not prev.is_empty() else 0.0
			run[5] = float(S.tick)
			run[6] = _share_n
			grew = true
	if grew:
		_busy[bi] = maxf(float(_busy.get(bi, 0.0)), float(S.tick) + _spread_ticks())
	return out


## How far a top has come down `ticks` after it started (RenderLook.DROP_SPEED, reached over DROP_RAMP ticks; the
## slower pace with reduced flashing).
static func dropped(ticks: float, calm: bool) -> float:
	var r: float = float(RenderLook.DROP_RAMP)
	var k: float = maxf(ticks, 0.0)
	return RenderLook.DROP_SPEED * (RenderLook.SPREAD_CALM if calm else 1.0) * SimConst.DT * (k * k / (2.0 * r) if k <= r else k - 0.5 * r)


## The ticks a spread is given: RenderLook.SPREAD_TICKS, as many more at the slower pace of reduced flashing.
func _spread_ticks() -> float:
	return float(RenderLook.SPREAD_TICKS) / (RenderLook.SPREAD_CALM if _calm else 1.0)


## Every spread and every growing mark is over: each building as it stands, at once (the sim's tick went back).
func _settle(S: SimState) -> void:
	var all: Dictionary = {}
	for bi in _busy:
		all[bi] = true
	for bi in _marks:
		all[bi] = true
	for bi in _blowing:
		all[bi] = true
	_blowing.clear()
	_hit_last.clear()
	_busy.clear()
	_spread.clear()
	_hit_at.clear()
	for bi in _drops.keys():
		_bld_seen[bi] = [-1.0, _bld_seen[bi][1], _bld_seen[bi][2], -1.0, _bld_seen[bi][4]]   # placed again at its own height
	_drops.clear()
	for bi in all:
		for run in _marks.get(bi, []):
			run[4] = 0.0
			run[5] = -1.0e6
		var b = S.buildings[bi]
		if b.alive and not _falls.has(bi):
			_write_windows(S, bi, b)


## Survivors standing near this frame's blows are startled for STARTLE_S; the calm ones go back to idle. A startled
## figure that starts running takes the flight's colours, and gets idle white again only if it is still home.
func _startle(S: SimState) -> void:
	var R: float = RenderLook.STARTLE_R
	var seen: Dictionary = {}
	for bx in _blows:
		var key: int = int(floor(SimWrap.wrap(bx) / (R * 0.5)))   # a beam's scorch comes in runs of nearby blows
		if seen.has(key):
			continue
		seen[key] = true
		for bi in range(S.buildings.size()):
			var b = S.buildings[bi]
			if absf(SimWrap.sdx(bx, b.x)) > R + b.w + RenderLook.CROWD_SPREAD or _shown[bi] <= 0:
				continue
			for j in range(_shown[bi]):
				var ci: int = _crowd_first[bi] + j
				if absf(SimWrap.sdx(bx, _crowd_x[ci])) < R and not flight.running(ci):
					if not _startled.has(ci):
						_crowd.set_instance_color(ci, Color(0.0, 1.0, 1.0, 1.0))
					_startled[ci] = S.T + RenderLook.STARTLE_S
					_calm_at = minf(_calm_at, S.T + RenderLook.STARTLE_S)
	_blows.clear()
	if S.T < _calm_at:
		return
	var calm: Array = []
	_calm_at = INF
	for ci in _startled:
		if S.T >= _startled[ci]:
			calm.append(ci)
		else:
			_calm_at = minf(_calm_at, _startled[ci])
	for ci in calm:
		_startled.erase(ci)
		if not flight.running(ci):
			_crowd.set_instance_color(ci, Color.WHITE)


## Crowd legibility for this frame: boost scales each figure about its feet; outline is the shell width in units.
## Camera's near-clip rule for the crowd (RenderLook.NEAR_CLIP): on in a match with depth on, when the camera may stand
## in a street. Sent only when it changes.
func set_crowd_near(on: bool) -> void:
	if on == _crowd_near or _crowd_mat == null:
		return
	_crowd_near = on
	_crowd_mat.set_shader_parameter("crowd_near", RenderLook.NEAR_CLIP if on else Vector2.ZERO)


func set_crowd_view(boost: float, outline: float) -> void:
	_crowd_mat.set_shader_parameter("boost", boost)
	_crowd_mat.set_shader_parameter("outline", outline)


## The copy nodes, left to right (for tools and tests).
func copies() -> Array:
	return _copies


## The ground meshes: the near tier's chunks first (they hold the fighter-plane row), then the middle chunks and the
## far tier.
func terrain_meshes() -> Array:
	return _terrain_meshes


## How many of terrain_meshes() are finest-run chunks (the ones holding the fighter-plane row).
func near_chunks() -> int:
	return SimConst.NC / RenderLook.CHUNK_COLS


## Props: buildings, roofs, trees and civilians whose state changed, or whose ground did (they stand on the ground as
## drawn at their own depth, so a bowl in depth does not leave them floating).
func refresh(S: SimState, force: bool) -> void:
	var dirty: PackedByteArray = ground.dirty
	var dchg: bool = force or ground.any_dirty
	_grow.clear()
	if int(S.tick) < _last_tick:
		_settle(S)
	_last_tick = int(S.tick)
	_share_n = 1
	for bi in range(S.buildings.size()):
		var b = S.buildings[bi]
		var h: float = WorldStructures.curH(b)
		var seen: Array = _bld_seen[bi]
		var moved: bool = dchg and (force or _foot_dirty(dirty, b))
		# The figures at home: the people it has, as many as it has figures. Fewer go now (they run or are gone, and the
		# runners may head for a building this loop has passed); more wait for the second pass below.
		var have: int = clampi(int(b.popAlive), 0, _crowd_first[bi + 1] - _crowd_first[bi])
		var show: int = have if _shown[bi] < 0 else mini(have, _shown[bi])
		if have > show:
			_grow.append(bi)
		if b.alive != seen[1] and not b.alive and seen[1] == true:
			# Levelled: an implode sinks from the height it last stood at (a folded one from its distance to the blast).
			if _falls.has(bi):
				_falls[bi][1] = seen[0]
			elif not _fold.is_empty() and absf(float(_fold[1]) - S.T) < 0.5:
				var delay: float = clampf(absf(SimWrap.sdx(float(_fold[0]), b.x)) / WorldStructures.IMPLODE_SPEED, 0.0, WorldStructures.IMPLODE_MAX_DELAY)
				_falls[bi] = [float(_fold[1]) + delay, seen[0]]
		if moved or force:
			_foot[bi] = _footing(S, b)
		# A fallen building is set once, when it falls (and while it sinks): its height is not compared, so the fallen
		# ones cost nothing a frame. A standing one is set again when its height, floors or hit points change (a cut
		# tower's stage moves with its hit points alone).
		if moved or (b.alive and (h != seen[0] or b.hp != seen[3])) or b.alive != seen[1] or b.fmask != seen[2] or _falls.has(bi) or _drops.has(bi):
			var st: int = _set_building(S, bi, b, h)
			_bld_seen[bi] = [h if b.alive else seen[0], b.alive, b.fmask, b.hp, st]
		if moved or show != _shown[bi]:
			_set_crowd(S, bi, b, show)
	# People sheltering in a building (World's RELOCATE) are shown there as their runners arrive: one figure for each
	# arrival (CrowdFlight.arrived), and all it is owed once no one is on the way. A figure that is still running (it
	# left this building a moment ago) is not put back until its run is over.
	for bi in _grow:
		var b = S.buildings[bi]
		var have: int = clampi(int(b.popAlive), 0, _crowd_first[bi + 1] - _crowd_first[bi])
		var want: int = have - _shown[bi]
		if flight.incoming[bi] > 0:
			want = mini(want, flight.arrived[bi])
		var add: int = 0
		while add < want and not flight.running(_crowd_first[bi] + _shown[bi] + add):
			add += 1
		if add > 0:
			flight.arrived[bi] = maxi(0, flight.arrived[bi] - add)
			_set_crowd(S, bi, b, _shown[bi] + add)
	for ti in range(S.trees.size()):
		var t = S.trees[ti]
		if (dchg and (force or dirty[_col(t.x)] == 1)) or t.alive != _tree_seen[ti]:
			_tree_seen[ti] = t.alive
			if t.alive:
				var g: float = ground.ground_at(S, t.x, _tree_z[ti])
				_tree.set_instance_transform(ti, Transform3D(Basis.from_scale(Vector3(RenderLook.TREE_W, t.h, RenderLook.TREE_W)), Vector3(t.x, g + t.h * 0.5, _tree_z[ti])))
			else:
				_tree.set_instance_transform(ti, _hidden(t.x))
	# A wave is over: what it has not reached changes now. A second wave inside it goes on alone; with none, the
	# building is as it stands, its marks whole.
	if not _busy.is_empty():
		for bi in _busy.keys():
			var done: bool = false
			if _spread.has(bi) and float(S.tick) >= float(_spread[bi][2]) + _spread_ticks():
				if (_spread[bi] as Array).size() > 5:
					_spread[bi] = (_spread[bi] as Array).slice(5)
				else:
					_spread.erase(bi)
				done = true
			if _blowing.has(bi) and float(S.tick) >= float(_blowing[bi][3]) + _spread_ticks():
				_blowing.erase(bi)
				done = true
			if float(S.tick) >= float(_busy[bi]):
				_busy.erase(bi)
				_spread.erase(bi)
				_blowing.erase(bi)
				for run in _marks.get(bi, []):
					run[4] = 0.0
					run[5] = -1.0e6
				done = true
			if done and S.buildings[bi].alive and not _falls.has(bi):
				_write_windows(S, bi, S.buildings[bi])
	for bi in _hit_at:
		var hp: Vector2 = _hit_place(S, bi, S.buildings[bi])
		_hit_last[bi] = [hp.x, hp.y, float(S.tick)]
	_hit_at.clear()
	_blasts.clear()
	for ct in [_cut, _cut0, _win, _win0]:
		if ct[2]:
			(ct[1] as ImageTexture).update(ct[0])
			ct[2] = false
	if dchg:
		ground.dirty.fill(0)
		ground.any_dirty = false


static func _col(x: float) -> int:
	return int(floor(SimWrap.wrap(x) / SimConst.COL))


## Whether the ground changed anywhere under a building's footprint (the columns WorldStructures.baseY reads).
static func _foot_dirty(dirty: PackedByteArray, b) -> bool:
	var nc: int = SimConst.NC
	var c0: int = int(floor((b.x - b.w * 0.5) / SimConst.COL))
	var c1: int = int(floor((b.x + b.w * 0.5) / SimConst.COL)) + 1
	for c in range(c0, c1 + 1):
		if dirty[posmod(c, nc)] == 1:
			return true
	return false


## A building's depth: [centre z, footprint depth] from the sim (B1), or the old render-side place if it has none.
static func _depth(b) -> Vector2:
	if b.d > 0.0:
		return Vector2(b.z, b.d)
	var d: float = b.w * (0.8 if b.kind == "tower" else 0.9)
	return Vector2(RenderLook.Z_BUILDING_FRONT - d * 0.5, d)


## The lowest and highest ground under a building's footprint (its corners, edges and centre, as drawn).
func _footing(S: SimState, b) -> Vector2:
	var zd: Vector2 = _depth(b)
	var lo: float = INF
	var hi: float = -INF
	for x in [b.x - b.w * 0.5, b.x, b.x + b.w * 0.5]:
		for z in [zd.x + zd.y * 0.5, zd.x, zd.x - zd.y * 0.5]:
			var g: float = ground.ground_at(S, x, z)
			lo = minf(lo, g)
			hi = maxf(hi, g)
	return Vector2(lo, hi)


## Place building bi at standing height h and hand the shader its look: every part of its shape (RenderShapes), each
## an instance of the one box. Returns World's damage stage it is drawn at (0 to 3: a building that is falling keeps
## the stage it last stood at).
func _set_building(S: SimState, bi: int, b, h: float) -> int:
	var stage: int = mini(WorldStructures.stage(b), 3) if b.alive else int(_bld_seen[bi][4])
	var zd: Vector2 = _depth(b)
	var zc: float = zd.x
	var d: float = zd.y
	var foot: Vector2 = _foot[bi]
	var standing: bool = b.alive
	var sink: float = 0.0
	if _falls.has(bi):
		var f: Array = _falls[bi]
		var u: float = (S.T - float(f[0])) / RenderLook.IMPLODE_S
		if u >= 1.0 or float(f[1]) < 0.0:
			_falls.erase(bi)
		else:
			standing = true
			h = float(f[1])
			var e: float = clampf(u, 0.0, 1.0)
			sink = h * e * e
	var front: bool = _row0[bi] >= 0
	var mm: MultiMesh = _bld0 if front else _bld
	var ct: Array = _cut0 if front else _cut
	var was: Array = _drawn[bi] if bi < _drawn.size() else []
	# A standing building that an event of this frame brought lower comes down to its new height at a set speed (a
	# later hit while it comes down changes where it stops, not its pace).
	if RenderLook.SPREAD_ON and b.alive and not _falls.has(bi) and was.size() == 3 and bool(was[2]):
		if not _drops.has(bi) and _hit_at.has(bi) and float(was[0]) > h + RenderLook.DROP_MIN:
			_drops[bi] = [float(was[0]), float(S.tick)]
		if _drops.has(bi):
			var dr: Array = _drops[bi]
			var at_h: float = float(dr[0]) - dropped(float(S.tick) - float(dr[1]), _calm)
			if at_h > h:
				h = at_h
			else:
				_drops.erase(bi)
	else:
		_drops.erase(bi)
	_drawn[bi] = [h, stage, standing]
	if not b.alive or _falls.has(bi):
		_spread.erase(bi)
		_busy.erase(bi)
		_blowing.erase(bi)
	elif RenderLook.SPREAD_ON and _hit_at.has(bi) and was.size() == 3 and bool(was[2]) and stage > int(was[1]):
		# Its stage went up, and an event of this frame says where it was hit: the new stage spreads from there. A
		# spread still going keeps its wave (what that has not reached stays at the stage before it) and the new stage
		# spreads inside it as a second wave; a third change takes the second wave's place.
		var at: Vector2 = _hit_place(S, bi, b)
		var wave: Array = [at.x, at.y, float(S.tick), float(int(was[1])), _share_n]
		_spread[bi] = ((_spread[bi] as Array).slice(0, 5) + wave) if _spread.has(bi) else wave
		_busy[bi] = float(S.tick) + _spread_ticks()
	# The sim's footing (World's T4): the highest ground under the footprint on the fighter plane. The fighter's brunt
	# geometry uses it, so the drawn top is base + height; a part on the ground runs down to the lowest ground as drawn
	# under it. The parts stay inside the sim's box: none stands higher than base + height.
	var base: float = WorldStructures.baseY(S, b)
	_top[bi] = base + h - sink if standing else -INF
	var ps: Array = _parts[bi]
	var ix: PackedInt32Array = _inst[bi]
	# A tower whose top floors are gone is cut off at its height and loses its caps; any other building is scaled.
	var cut_top: bool = int(b.floors) >= WorldBrunt.FLOORS_MIN and b.fmask != (1 << int(b.floors)) - 1
	var spans: Array = []
	for j in range(ps.size()):
		var p: Array = ps[j]
		var k: int = ix[j]
		var sp: Array = RenderShapes.span(p, j == 0, h, b.h, stage, cut_top) if standing else []
		spans.append(sp)
		# The floors cleared under this part's top (a tunnel): only a part that stands on the ground and has floors.
		var cut: Color = Color(0, 0, 0, 0)
		if b.alive and not sp.is_empty() and float(p[RenderShapes.Y0]) <= 0.0 and (int(p[RenderShapes.FLAGS]) & (RenderShapes.PLAIN | RenderShapes.ROOF)) == 0:
			cut = floor_cut(b) if j == 0 else floor_cut_to(b, int(round(float(sp[1]) / WorldBrunt.floorH(b))) - 1)
		if (ct[0] as Image).get_pixel(k, 0) != cut:
			(ct[0] as Image).set_pixel(k, 0, cut)
			ct[2] = true
		if sp.is_empty():
			mm.set_instance_transform(k, _hidden(b.x))
			continue
		var top: float = base + float(sp[1]) - sink
		var bottom: float = (minf(foot.x, base) if float(sp[0]) <= 0.0 else base + float(sp[0])) - sink
		mm.set_instance_transform(k, Transform3D(Basis.from_scale(Vector3(float(p[RenderShapes.W]), top - bottom, float(p[RenderShapes.D]))), Vector3(b.x + float(p[RenderShapes.X]), (top + bottom) * 0.5, zc + float(p[RenderShapes.Z]))))
		mm.set_instance_color(k, Color(p[RenderShapes.COL] as Color, 0.0 if (int(p[RenderShapes.FLAGS]) & RenderShapes.ROOF) != 0 else 1.0))   # alpha 0: a roof (building.gdshader)
	_write_windows(S, bi, b, sink, spans)
	return stage


## Building bi's crowd: `alive` of its figures stand at home, on the ground as drawn.
func _set_crowd(S: SimState, bi: int, b, alive: int) -> void:
	var first: int = _crowd_first[bi]
	var n: int = _crowd_first[bi + 1] - first
	# Figures that just vanished: the fled share runs (the flight), the rest were casualties and go now.
	var gone_now := {}
	if _shown[bi] > alive:
		var slots: Array = range(first + alive, first + _shown[bi])
		for ci in flight.vanish(S, bi, b.x, slots, _crowd_x, _crowd_z, ground):
			gone_now[ci] = true
	_shown[bi] = alive
	for j in range(n):
		var ci: int = first + j
		var x: float = _crowd_x[ci]
		if j < alive:
			_crowd.set_instance_transform(ci, Transform3D(Basis.from_scale(Vector3.ONE * RenderLook.CROWD_SCALE), Vector3(x, ground.ground_at(S, x, _crowd_z[ci]), _crowd_z[ci])))
		elif gone_now.has(ci) or not flight.running(ci):
			_crowd.set_instance_transform(ci, _hidden(x))


## A building's windows, damage stage and shape for building.gdshader (five texels of win_tex an instance, so one
## for each of its parts; the fourth is the footprint of the building's shell at the street as seen from this part, its
## middle across and in depth and half its width and depth, for a lobby's ceiling and the core; the fifth is the height
## from which this part is the building's outermost wall (RenderShapes.outer_from) and the core's state, whole, cracked
## or broken by the building's hit points (RenderLook.CORE_HP)): a bit per floor whose windows are out (24, 24 and 14 bits, as the floor cut packs them) and
## the height of a floor (0: no windows on this part, or it does not stand); then the wall's base, how many floors
## stand under the part's top, the stage it is drawn at (_drawn) and the rows of windows a floor; then the part's
## shape (its top's width and depth shares, its lean) and its district's look. The shader draws the look's windows from
## these, and the stage's look over them. spans: each part's [bottom, top] as placed (empty: hidden); left out (a
## blow-out, between placements) the last placement's.
func _write_windows(S: SimState, bi: int, b, sink: float = 0.0, spans = null) -> void:
	var wt: Array = _win0 if _row0[bi] >= 0 else _win
	var dr: Array = _drawn[bi]
	var floors: int = maxi(int(b.floors), 1)
	var fh: float = b.h / float(floors)
	var m: int = int(_blown[bi])
	var going: int = int(_blowing[bi][0]) if _blowing.has(bi) else 0   # floors a blow-out is still putting out: not in the first row's mask yet
	m &= ~going
	var base: float = WorldStructures.baseY(S, b) - sink
	var ps: Array = _parts[bi]
	var ix: PackedInt32Array = _inst[bi]
	var img: Image = wt[0]
	var sh: Array = ps[RenderShapes.shell(ps)]
	var left: float = b.hp / maxf(b.maxhp, 1.0)
	var core: float = 2.0 if left < RenderLook.CORE_HP.y else (1.0 if left < RenderLook.CORE_HP.x else 0.0)
	# What a held hit left on it, and a stage spreading over it (rows 5 to 9, the same on each of its parts).
	var runs: Array = _marks_of(S, bi, b)
	if runs.is_empty():
		_marks.erase(bi)
	else:
		_marks[bi] = runs
	var more: Array = [Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(0, 0, 0, 0)]
	var flags: float = 0.0
	if not runs.is_empty():
		flags += 1.0
		for i in range(mini(runs.size(), 4)):
			var run: Array = runs[i]
			more[1 + i] = Color(float(int(run[0]) + 64 * int(run[1]) + 4096 * clampi(int(run[6]), 1, 15)), float(run[2]), float(run[3]) * (1.0 + float(run[4])), float(run[5]))
	if going != 0:
		var bw: Array = _blowing[bi]
		flags += 8.0
		more[6] = Color(float(going & 0xFFFFFF), float((going >> 24) & 0xFFFFFF), float((going >> 48) & 0x3FFF), 0.0)
		more[7] = Color(float(bw[1]), float(bw[2]), float(bw[3]), float(bw[4]))
	if _spread.has(bi):
		var sp: Array = _spread[bi]
		flags += 2.0
		more[0] = Color(float(sp[0]), float(sp[1]), float(sp[2]), float(sp[3]) + 4.0 * float(clampi(int(sp[4]), 1, 15)))
		if sp.size() > 5:
			flags += 4.0
			more[5] = Color(float(sp[5]), float(sp[6]), float(sp[7]), float(sp[8]) + 4.0 * float(clampi(int(sp[9]), 1, 15)))
	for j in range(ps.size()):
		var p: Array = ps[j]
		var k: int = ix[j]
		var plain: bool = (int(p[RenderShapes.FLAGS]) & (RenderShapes.PLAIN | RenderShapes.ROOF)) != 0
		var a := Color(float(m & 0xFFFFFF), float((m >> 24) & 0xFFFFFF), float((m >> 48) & 0x3FFF), fh if dr[2] and not plain else 0.0)
		# The body's floors standing are the building's (the stage check reads them); another part's, those under its top.
		var up: float = float(dr[0])
		if j > 0:
			if spans is Array:
				up = float(spans[j][1]) if not (spans[j] as Array).is_empty() else 0.0
			else:
				up = img.get_pixel(k, 1).g * fh
		var c := Color(base, ceilf(up / maxf(fh, 1.0)), float(dr[1]), float(RenderShapes.rows(fh)))
		var s := Color(float(p[RenderShapes.TX]), float(p[RenderShapes.TZ]), float(p[RenderShapes.LEAN]), float(int(p[RenderShapes.LOOKX]) if int(p[RenderShapes.LOOKX]) >= 0 else _look[bi]))
		var f := Color(float(sh[RenderShapes.X]) - float(p[RenderShapes.X]), float(sh[RenderShapes.Z]) - float(p[RenderShapes.Z]), 0.5 * float(sh[RenderShapes.W]), 0.5 * float(sh[RenderShapes.D]))
		var fr := Color(RenderShapes.outer_from(ps, j), core, flags, _city[bi])
		if img.get_pixel(k, 0) != a or img.get_pixel(k, 1) != c or img.get_pixel(k, 2) != s or img.get_pixel(k, 3) != f or img.get_pixel(k, 4) != fr:
			img.set_pixel(k, 0, a)
			img.set_pixel(k, 1, c)
			img.set_pixel(k, 2, s)
			img.set_pixel(k, 3, f)
			img.set_pixel(k, 4, fr)
			wt[2] = true
		for i in range(8):
			if img.get_pixel(k, 5 + i) != more[i]:
				img.set_pixel(k, 5 + i, more[i])
				wt[2] = true


## Per frame, the first pane's planet: windows going out. VFX throws the glass (render/vfx/react.gd) and lists each
## blow-out as {b: the building, at: the sim time its windows go, strength: 0 to 1, lo, hi: the floor range}, pruned
## six seconds on. From `at` the facade's own windows on the same rows of floors are out, and they stay out for the
## match. The rows are VFX's: round(floors x strength x 0.6) of them, at most its floors_max, spread up the building.
func blow_windows(S: SimState, list: Array) -> void:
	if list.is_empty():
		return
	for w in list:
		var at: float = float(w["at"])
		var bi: int = int(w["b"])
		var key := Vector2(float(bi), at)
		if at > S.T or _blow_seen.has(key) or bi < 0 or bi >= S.buildings.size():
			continue
		_blow_seen[key] = true
		var b = S.buildings[bi]
		var floors: int = maxi(int(b.floors), 1)
		var rows: int = clampi(int(round(float(floors) * float(w["strength"]) * 0.6)), 1, int(VfxReact.p("windows", "floors_max")))
		var m: int = int(_blown[bi])
		for r in range(rows):
			m |= 1 << mini(int(floor((float(r) + 0.5) / float(rows) * float(floors))), mini(floors - 1, 61))
		var fresh: int = m & ~int(_blown[bi])
		_blown[bi] = m
		if RenderLook.SPREAD_ON and fresh != 0 and b.alive and not _falls.has(bi):
			# The floors this blow-out puts out go as a wave from where the building was last hit (the middle of those
			# floors when nothing says where). A wave still going is over at once: its floors are out.
			var src: Array = _hit_last.get(bi, [])
			if src.is_empty() or float(S.tick) - float(src[2]) > 120.0:
				var lo: int = 0
				while ((fresh >> lo) & 1) == 0:
					lo += 1
				var hi: int = 61
				while ((fresh >> hi) & 1) == 0:
					hi -= 1
				src = [0.0, 0.5 * float(lo + hi + 1) * b.h / float(floors), 0.0]
			_blowing[bi] = [fresh, float(src[0]), float(src[1]), float(S.tick), 1]
			_busy[bi] = maxf(float(_busy.get(bi, 0.0)), float(S.tick) + _spread_ticks())
		_write_windows(S, bi, b)
	if _blow_seen.size() > 256:
		for key in _blow_seen.keys():
			if S.T - (key as Vector2).y > 12.0 or (key as Vector2).y > S.T + 12.0:
				_blow_seen.erase(key)


## A skyscraper's cleared floors for building.gdshader (a texel of cut_tex): r and g the floors 0 to 47 (24 bits each),
## b the floors 48 to 61 plus 16,384 times the top standing floor, a the height of a floor. All zero when there is no
## tunnel: no floors (World's FLOORS_MIN), or every floor under the top one stands.
static func floor_cut(b) -> Color:
	if int(b.floors) < WorldBrunt.FLOORS_MIN:
		return Color(0, 0, 0, 0)
	var top: int = WorldBrunt.topFloor(b)
	var m: int = int(b.fmask)
	if top < 1 or (m & ((1 << (top + 1)) - 1)) == (1 << (top + 1)) - 1:
		return Color(0, 0, 0, 0)
	return Color(float(m & 0xFFFFFF), float((m >> 24) & 0xFFFFFF), float((m >> 48) & 0x3FFF) + 16384.0 * float(top), WorldBrunt.floorH(b))


## The same for a part of the tower that ends lower than the tower does (a stepped tower's skirt): the cleared floors
## under floor `top`, the floor whose ceiling is the part's top. All zero when every floor under it stands.
static func floor_cut_to(b, top: int) -> Color:
	if int(b.floors) < WorldBrunt.FLOORS_MIN:
		return Color(0, 0, 0, 0)
	top = mini(top, WorldBrunt.topFloor(b))
	var m: int = int(b.fmask)
	if top < 1 or (m & ((1 << (top + 1)) - 1)) == (1 << (top + 1)) - 1:
		return Color(0, 0, 0, 0)
	return Color(float(m & 0xFFFFFF), float((m >> 24) & 0xFFFFFF), float((m >> 48) & 0x3FFF) + 16384.0 * float(top), WorldBrunt.floorH(b))


static func _hidden(x: float) -> Transform3D:
	return Transform3D(Basis.from_scale(Vector3.ZERO), Vector3(x, 0.0, 0.0))


func _mesh_child(parent: Node3D, n: String, mesh: Mesh, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	mi.name = n
	mi.mesh = mesh
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)


func _mm_child(parent: Node3D, n: String, mm: MultiMesh, mat: Material = null) -> void:
	var mi := MultiMeshInstance3D.new()
	mi.name = n
	mi.multimesh = mm
	mi.material_override = mat if mat != null else mats.flat(Color.WHITE)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)


var _calm: bool = false              # the grooves are drawn calm (set_calm)
var _crater_now: float = -1.0        # the match time last sent to the ground's materials (a new crater's age)


func _make_materials() -> void:
	_terrain_mat = ShaderMaterial.new()
	_terrain_mat.shader = TERRAIN_SHADER
	_water_mat = ShaderMaterial.new()
	_water_mat.shader = WATER_SHADER
	for m in [_terrain_mat, _water_mat]:
		m.set_shader_parameter("heights", ground.tex)
		m.set_shader_parameter("craters", ground.ctex)
		m.set_shader_parameter("nc", SimConst.NC)
		m.set_shader_parameter("tw", ground.tw)
		m.set_shader_parameter("rpl", ground.rpl)
		m.set_shader_parameter("far_scale", RenderLook.WS)
		m.set_shader_parameter("sea_base", WorldWater.RESERVOIR_BASE)
		m.set_shader_parameter("wet_min", WorldWater.MIN_DEPTH)
		m.set_shader_parameter("dent_min", 6.0 * RenderLook.WS)
		m.set_shader_parameter("col_w", SimConst.COL)
		m.set_shader_parameter("world_w", SimConst.W)
		m.set_shader_parameter("rim_in", WorldCrater.RIM_IN)
		m.set_shader_parameter("rim_out", WorldCrater.RIM_OUT)
		m.set_shader_parameter("groove_w0", WorldCrater.SCORCH_HW0)
		m.set_shader_parameter("groove_wp", WorldCrater.SCORCH_HW_P)
		m.set_shader_parameter("groove_i0", WorldCrater.SCORCH_INT0)
		m.set_shader_parameter("groove_ip", WorldCrater.SCORCH_INT_P)
		m.set_shader_parameter("groove_pmin", GroundField.P_MIN)
		m.set_shader_parameter("groove_pmax", GroundField.P_MAX)
		m.set_shader_parameter("spread_w", RenderLook.GROUND_SPREAD)
		m.set_shader_parameter("furrow_wr", RenderLook.FURROW_W_R)
		m.set_shader_parameter("furrow_wmin", RenderLook.FURROW_W_MIN)
		m.set_shader_parameter("z_band_back", RenderLook.Z_TERRAIN_BACK)
		m.set_shader_parameter("far_blend", RenderLook.FAR_BLEND)
		m.set_shader_parameter("meander_amp", RenderLook.MEANDER)
		m.set_shader_parameter("biome_colors", GroundField.BIOME_ORDER.map(func(b): return RenderLook.col(RenderLook.BIOME[b])))
		m.set_shader_parameter("fog_far", RenderLook.FOG_FAR)
		m.set_shader_parameter("fore_drop", RenderLook.FORE_DROP)
		m.set_shader_parameter("fore_span", float(RenderLook.FORE_SPAN))
		m.set_shader_parameter("fore_far", RenderLook.FORE_FAR)
		m.set_shader_parameter("fore_strides", Vector3(RenderLook.STRIDES[0][0], RenderLook.STRIDES[1][0], RenderLook.STRIDES[2][0]))
		m.set_shader_parameter("rubble_edge", RenderLook.RUBBLE_EDGE)
		m.set_shader_parameter("shore_flood", RenderLook.SHORE_FLOOD)
		mats.track(m)
	_terrain_mat.set_shader_parameter("sea_floor", RenderLook.col(RenderLook.SEA_FLOOR))
	_terrain_mat.set_shader_parameter("crater", RenderLook.col(RenderLook.CRATER))
	_terrain_mat.set_shader_parameter("crater_desert", RenderLook.col(RenderLook.CRATER_DESERT))
	_terrain_mat.set_shader_parameter("ejecta", RenderLook.col(RenderLook.EJECTA))
	_terrain_mat.set_shader_parameter("char_col", RenderLook.col(RenderLook.CHAR))
	_terrain_mat.set_shader_parameter("heat_lo", RenderLook.col(RenderLook.HEAT_LO))
	_terrain_mat.set_shader_parameter("heat_hi", RenderLook.col(RenderLook.HEAT_HI))
	_terrain_mat.set_shader_parameter("char_fresh", RenderLook.CHAR_FRESH)
	_terrain_mat.set_shader_parameter("crater_calm_s", RenderLook.CRATER_CALM_S)
	for m in [_terrain_mat, _water_mat]:
		m.set_shader_parameter("crater_open_s", RenderLook.CRATER_OPEN_S)
	_terrain_mat.set_shader_parameter("z_front", RenderLook.Z_TERRAIN_FRONT)
	_terrain_mat.set_shader_parameter("snow", RenderLook.col(RenderLook.SNOW))
	_terrain_mat.set_shader_parameter("snow_from", RenderLook.SNOW_FROM)
	_terrain_mat.set_shader_parameter("snow_full", RenderLook.SNOW_FULL)
	_terrain_mat.set_shader_parameter("cracked", RenderLook.col(RenderLook.CRACKED))
	_terrain_mat.set_shader_parameter("rubble", RenderLook.col(RenderLook.RUBBLE))
	_terrain_mat.set_shader_parameter("rubble_tint_h", RenderLook.RUBBLE_TINT_H)
	_water_mat.set_shader_parameter("water", RenderLook.WATER)
	_water_mat.set_shader_parameter("surface", RenderLook.WATER_SURFACE)
	_water_mat.set_shader_parameter("fall_body", RenderLook.WATER_FALL_BODY)


## The lane table's streets for the ground shader (render/core/lanes.gd: World's S.lanes once L1 lands, a stand-in
## from the plan's numbers until then), per match: the strips of each street and the districts' x intervals.
func _set_lanes(S: SimState) -> void:
	var t: PackedFloat32Array = RenderLanes.table(S)
	var strips: Array = RenderLanes.strips(t, STREET_STRIPS)
	var spans: Array = RenderLanes.districts(t, STREET_SPANS)
	_terrain_mat.set_shader_parameter("street_n", strips.size() if streets else 0)
	_terrain_mat.set_shader_parameter("span_n", spans.size())
	while strips.size() < STREET_STRIPS:
		strips.append(Vector4.ZERO)
	while spans.size() < STREET_SPANS:
		spans.append(Vector4.ZERO)
	_terrain_mat.set_shader_parameter("street_strips", strips)
	_terrain_mat.set_shader_parameter("street_spans", spans)
	_terrain_mat.set_shader_parameter("span_edge", RenderLook.STREET_EDGE)
	# The avenues that cross the blocks, and the blocks' own ground: paved in the looks that are (RenderShapes).
	var av: Array = RenderLanes.avenues(t, STREET_AVENUES)
	_terrain_mat.set_shader_parameter("avenue_n", av.size() if streets else 0)
	while av.size() < STREET_AVENUES:
		av.append(Vector4.ZERO)
	_terrain_mat.set_shader_parameter("avenues", av)
	var bl: Array = RenderLanes.blocks(t)
	_terrain_mat.set_shader_parameter("lot_z", Vector4(bl[0].x if bl.size() > 0 else 0.0, bl[0].y if bl.size() > 0 else 0.0, bl[1].x if bl.size() > 1 else 0.0, bl[1].y if bl.size() > 1 else 0.0))
	_terrain_mat.set_shader_parameter("lot_col", RenderShapes.lot_colours())
	_terrain_mat.set_shader_parameter("avenue_walk", RenderLook.AVENUE_WALK)
	_terrain_mat.set_shader_parameter("street_dash", RenderLook.STREET_DASH)
	_terrain_mat.set_shader_parameter("street_bay", RenderLook.STREET_BAY)
	for k in [["street_walk", RenderLook.STREET_WALK], ["street_road", RenderLook.STREET_ROAD], ["street_kerb", RenderLook.STREET_KERB], ["street_line", RenderLook.STREET_LINE]]:
		_terrain_mat.set_shader_parameter(k[0], RenderLook.col(k[1]))
	for m in [_terrain_mat, _water_mat]:
		m.set_shader_parameter("lane_cue_w", RenderLook.LANE_CUE_W)
		m.set_shader_parameter("pair_mark_v", Vector4(RenderLook.PAIR_MARK_CORE, RenderLook.PAIR_MARK_GRAD, RenderLook.PAIR_MARK_RIM, RenderLook.PAIR_MARK_PALE))


## Per frame, per pane: the lane cues on the ground and the water (ground.gdshaderinc). cues: per fighter [his world
## x, his depth, the strength (0: none), his colour].
func set_lane_cues(cues: Array) -> void:
	var v: Array = []
	var c := PackedColorArray()
	var any: bool = false
	for i in range(2):
		if i < cues.size() and float(cues[i][2]) > 0.0:
			v.append(Vector4(float(cues[i][0]), float(cues[i][1]), RenderLook.LANE_CUE_LEN, float(cues[i][2])))
			c.append(cues[i][3])
			any = true
		else:
			v.append(Vector4.ZERO)
			c.append(Color.BLACK)
	if not any and not _cues_on:
		return
	_cues_on = any
	for m in [_terrain_mat, _water_mat]:
		m.set_shader_parameter("lane_cue", v)
		m.set_shader_parameter("lane_cue_col", c)


## Per frame, per pane: the pair's mark on the ground and the water (ground.gdshaderinc). ends: one fighter's world x
## and depth, then the other's; strength 0 to 1 (0: none); half_px: its half width in pixels at its middle. Nothing is
## set while there is none and there was none.
func set_pair_mark(ends: Vector4, strength: float, half_px: float = 2.5) -> void:
	if strength <= 0.0 and not _pair_on:
		return
	_pair_on = strength > 0.0
	for m in [_terrain_mat, _water_mat]:
		m.set_shader_parameter("pair_mark", ends)
		m.set_shader_parameter("pair_mark_k", maxf(strength, 0.0))
		m.set_shader_parameter("pair_mark_w", Vector2(half_px, RenderLook.PAIR_MARK_TAPER))


## This pane's open lobbies as faces, for VFX's clear query: each [the building's x from the camera, its width, its
## front face's depth, the lobby's floor and its top as world y]. One counts from when half of it is through.
func open_faces(S: SimState, cam_x: float) -> Array:
	var out: Array = []
	for bi in _open:
		var o: Array = _open[bi]
		if float(o[0]) < 0.5:
			continue
		var b = S.buildings[bi]
		var zd: Vector2 = _depth(b)
		out.append([SimWrap.sdx(cam_x, b.x), b.w, zd.x + zd.y * 0.5, float(o[5]), float(o[6])])
	return out


## The camera's world position this frame, for the foreground rule in the ground and water shaders.
## The grooves' calm form, under reduced flashing or reduced motion (PaneWorld.flash_calm): a fainter glow and char.
func set_calm(on: bool) -> void:
	if _terrain_mat == null or on == _calm:
		return
	_calm = on
	_terrain_mat.set_shader_parameter("heat_gain", RenderLook.HEAT_CALM if on else 1.0)
	_terrain_mat.set_shader_parameter("char_gain", RenderLook.CHAR_CALM if on else 1.0)
	_terrain_mat.set_shader_parameter("calm_ease", 1.0 if on else 0.0)   # a new crater's colours spread in (RenderLook.CRATER_CALM_S)
	if _bld_mat != null:
		for m in [_bld_mat, _front_mat]:
			m.set_shader_parameter("spread_area", RenderLook.SPREAD_AREA_TICK * (RenderLook.SPREAD_CALM if on else 1.0))   # a stage spreads at half the pace


## The depth of this pane's focus plane (Camera's dolly; 0: the fighter plane): the rows' haze is measured from it.
## Sent only when it changes, so nothing is set while it stays 0.
func set_focus(z: float) -> void:
	if z == _focus_z or _bld_mat == null:
		return
	_focus_z = z
	for m in [_bld_mat, _front_mat]:
		m.set_shader_parameter("haze_focus", z)


## The world's light on this pane's layers (SkyDrive.world_at: RenderLook.WORLD_LAYERS order, each [mul, add] in linear
## light) and the share of windows lit (SkyDrive.win_at). Kept, so a material made later takes it too.
func set_world_light(world: Array, win: float) -> void:
	_wl = world
	_wl_win = win
	_apply_wl()


func _apply_wl() -> void:
	if _wl.is_empty() or _terrain_mat == null:
		return
	var by: Dictionary = {"ground": [_terrain_mat], "water": [_water_mat], "buildings": [_bld_mat, _front_mat], "trees": [_tree_mat], "civilians": [_crowd_mat]}
	for li in range(RenderLook.WORLD_LAYERS.size()):
		for m in by.get(RenderLook.WORLD_LAYERS[li], []):
			if m != null:
				m.set_shader_parameter("wl_mul", _wl[li][0])
				m.set_shader_parameter("wl_add", _wl[li][1])
	for m in [_bld_mat, _front_mat]:
		if m != null:
			m.set_shader_parameter("wl_lit", _wl_win / RenderLook.WINDOW_LIT_SHARE)


func set_camera(p: Vector3) -> void:
	if _terrain_mat == null:
		return
	_terrain_mat.set_shader_parameter("fore_cam", p)
	_water_mat.set_shader_parameter("fore_cam", p)


## The foreground rule's reading near the lens (RenderLook.FORE_FAR): the fighter plane's lowest ground and top in
## this pane's view, and how far its camera travels along x a tick, both eased by the pane (PaneWorld._fore_low).
func set_fore_low(ground: float, top: float, sweep: float) -> void:
	if _terrain_mat == null:
		return
	for m in [_terrain_mat, _water_mat]:
		m.set_shader_parameter("fore_low", Vector2(ground, top))
		m.set_shader_parameter("fore_sweep", sweep)


static func _planet_aabb(y0: float, y1: float, z0: float, z1: float) -> AABB:
	return AABB(Vector3(-64.0, y0, z0), Vector3(SimConst.W + 128.0, y1 - y0, z1 - z0))


## Row depths from Z_FORE in front to the horizon behind, front to back: spacing ROW_STEP0 at the fighter plane,
## growing by ROW_GROWTH of the distance, with 0 and every stride boundary (either side) included.
static func ground_rows() -> Array:
	var stops: Array = []
	for t in RenderLook.STRIDES:
		if t[0] < RenderLook.FOG_FAR:
			stops.append(t[0])
	var rows: Array = [0.0]
	for side in [1.0, -1.0]:
		var end: float = RenderLook.Z_FORE if side > 0.0 else RenderLook.FOG_FAR
		var d: float = 0.0
		while d < end:
			var nd: float = minf(d + maxf(RenderLook.ROW_STEP0, d * RenderLook.ROW_GROWTH), end)
			for st in stops:
				if st > d and st < nd:
					nd = st
			d = nd
			if side > 0.0:
				rows.push_front(d)
			else:
				rows.append(-d)
	return rows


static func stride_at(z: float) -> int:
	for t in RenderLook.STRIDES:
		if absf(z) <= t[0] + 0.001:
			return int(t[1])
	return int(RenderLook.STRIDES[-1][1])


## The ground and water meshes. The rows split into runs of one column stride (finer near the fighter plane, coarser
## away from it on both sides); a boundary row belongs to both runs and, on the finer side, snaps to the coarser
## stride (UV2.y = that stride) so they meet exactly. The finest run and the middle runs are cut into chunks of
## CHUNK_COLS columns, culled by the frustum; the coarsest runs (far in front and far behind) are one light mesh.
func _make_ground_meshes() -> void:
	var rows: Array = ground_rows()
	var runs: Array = []      # [rows, stride]; neighbouring runs share their boundary row (the row at the limit)
	var start: int = 0
	for i in range(1, rows.size()):
		var a: int = stride_at(rows[i - 1])
		var b: int = stride_at(rows[i])
		if a == b:
			continue
		var bnd: int = i if b < a else i - 1
		runs.append([rows.slice(start, bnd + 1), a])
		start = bnd
	runs.append([rows.slice(start), stride_at(rows[-1])])
	var smallest: int = int(RenderLook.STRIDES[0][1])
	var largest: int = int(RenderLook.STRIDES[-1][1])
	var cc: int = RenderLook.CHUNK_COLS
	for group in ["near", "mid"]:
		for c0 in range(0, SimConst.NC, cc):
			var tv: Array = [[], []]
			for k in range(runs.size()):
				var st: int = runs[k][1]
				if (group == "near") != (st == smallest) or st == largest:
					continue
				var sf: int = runs[k - 1][1] if k > 0 and runs[k - 1][1] > st else 0
				var sl: int = runs[k + 1][1] if k + 1 < runs.size() and runs[k + 1][1] > st else 0
				_grid(tv[0], c0, c0 + cc, runs[k][0], st, sf, sl, false)
				_grid(tv[1], c0, c0 + cc, runs[k][0], st, 0, 0, true)
			if tv[0].is_empty():
				continue
			_terrain_meshes.append(_finish(tv[0], c0 * SimConst.COL, (c0 + cc) * SimConst.COL, false))
			_water_meshes.append(_finish(tv[1], c0 * SimConst.COL, (c0 + cc) * SimConst.COL, true))
	var far: Array = [[], []]
	for k in range(runs.size()):
		if runs[k][1] == largest:
			_grid(far[0], 0, SimConst.NC, runs[k][0], largest, 0, 0, false)
			_grid(far[1], 0, SimConst.NC, runs[k][0], largest, 0, 0, true)
	_terrain_meshes.append(_finish(far[0], 0.0, SimConst.W, false))
	_water_meshes.append(_finish(far[1], 0.0, SimConst.W, true))


## A top grid (ground) or surface grid (water) over columns c0..c1 at the given stride and rows, appended to the
## vertex lists in tv = [verts, uv, uv2, colours, indices]. snap_first, snap_last: the stride the first or last row
## snaps to (0: none).
static func _grid(tv: Array, c0: int, c1: int, rows: Array, stride: int, snap_first: int, snap_last: int, water: bool) -> void:
	if tv.is_empty():
		tv.append_array([PackedVector3Array(), PackedVector2Array(), PackedVector2Array(), PackedColorArray(), PackedInt32Array()])
	var base: int = tv[0].size()
	var nr: int = rows.size()
	var ncols: int = 0
	for c in range(c0, c1 + 1, stride):
		var col: Color = _biome_col(c)
		for r in range(nr):
			var z: float = rows[r]
			var flag: float = 0.0
			if z == 0.0:
				flag = 1.0
			elif not water and r == nr - 1 and snap_last > 1:
				flag = float(snap_last)
			elif not water and r == 0 and snap_first > 1:
				flag = float(snap_first)
			tv[0].append(Vector3(float(c) * SimConst.COL, 0.0, z))
			tv[1].append(Vector2(float(c), 0.0 if water else 1.0))
			tv[2].append(Vector2(1.0, flag))
			tv[3].append(col)
		ncols += 1
	for ci in range(ncols - 1):
		var a: int = base + ci * nr
		var b: int = a + nr
		for r in range(nr - 1):
			tv[4].append_array([a + r, a + r + 1, b + r, b + r, a + r + 1, b + r + 1])


static func _biome_col(c: int) -> Color:
	var biome: String = WorldBiomes.biomeAt(float(posmod(c, SimConst.NC)) * SimConst.COL)
	var col: Color = RenderLook.col(RenderLook.BIOME[biome])
	col.a = 1.0 if biome == "desert" else 0.0
	return col


static func _finish(tv: Array, x0: float, x1: float, water: bool) -> ArrayMesh:
	var m := _mesh(tv[0], tv[1], tv[2], PackedColorArray() if water else tv[3], tv[4])
	var z0: float = INF
	var z1: float = -INF
	for v in tv[0]:
		z0 = minf(z0, v.z)
		z1 = maxf(z1, v.z)
	var y0: float = -4000.0 * RenderLook.WS
	m.custom_aabb = AABB(Vector3(x0 - 64.0, y0, z0 - 1.0), Vector3(x1 - x0 + 128.0, 14000.0 - y0, z1 - z0 + 2.0))
	return m


static func _mesh(v: PackedVector3Array, uv: PackedVector2Array, uv2: PackedVector2Array, cols: PackedColorArray, idx: PackedInt32Array) -> ArrayMesh:
	var arr: Array = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = v
	var nrm := PackedVector3Array()
	nrm.resize(v.size())
	nrm.fill(Vector3(0.0, 0.0, 1.0))
	arr[Mesh.ARRAY_NORMAL] = nrm
	if uv.size():
		arr[Mesh.ARRAY_TEX_UV] = uv
	if uv2.size():
		arr[Mesh.ARRAY_TEX_UV2] = uv2
	if cols.size():
		arr[Mesh.ARRAY_COLOR] = cols
	arr[Mesh.ARRAY_INDEX] = idx
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return m


## custom: per-instance custom data, with instance colours too only if colors (else colours alone).
## z0, z1: the depth the instances span (default: the trees' and old props' band).
static func _multimesh(mesh: Mesh, count: int, y1: float, custom: bool = false, colors: bool = false, z0: float = RenderLook.Z_TREE_MIN * 1.5, z1: float = 100.0) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = colors or not custom
	mm.use_custom_data = custom
	mm.mesh = mesh
	mm.instance_count = count
	mm.custom_aabb = _planet_aabb(-1000.0 * RenderLook.WS, y1 * RenderLook.WS, z0, z1)
	return mm


## The standing buildings that could stand in front of anything between camera-relative x xa and xb at depth z_min
## or nearer: the candidates for this frame's occluders() calls (one bucket query for the frame). m: the widest
## clearance those calls will ask for.
func occluder_candidates(S: SimState, cam_x: float, xa: float, xb: float, z_min: float, m: float) -> Array:
	var out: Array = []
	for bi in WorldStructures.near(S, SimWrap.wrap(cam_x + (xa + xb) * 0.5), absf(xb - xa) * 0.5 + m):
		if _top[bi] == -INF:
			continue
		var zd: Vector2 = _depth(S.buildings[bi])
		if zd.x + zd.y * 0.5 > z_min + 1.0:
			out.append(bi)
	return out


## The buildings among cand that stand between a camera and a point, both in this pane's space (the camera sits at
## x = 0; cam_x is its wrapped world x): every one whose box the sight line passes within m of, nearer the camera than
## the point. Their indices are added to out. skip: a building to leave out (the one a launched fighter is aimed at
## stays whole).
func occluders(S: SimState, cand: Array, eye: Vector3, cam_x: float, p: Vector3, m: float, skip: int, out: Dictionary) -> bool:
	var span: float = eye.z - p.z
	if span < 1.0:
		return false
	var any: bool = false
	for bi in cand:
		if bi == skip:
			continue
		var b = S.buildings[bi]
		var zd: Vector2 = _depth(b)
		var zf: float = zd.x + zd.y * 0.5
		var zb: float = zd.x - zd.y * 0.5
		if zf <= p.z + 1.0 or zb >= eye.z:
			continue
		# The stretch of the sight line inside the building's depth.
		var t0: float = (maxf(zb, p.z) - p.z) / span
		var t1: float = (minf(zf, eye.z) - p.z) / span
		var x0: float = p.x + (eye.x - p.x) * t0
		var x1: float = p.x + (eye.x - p.x) * t1
		var bx: float = SimWrap.sdx(cam_x, b.x)
		if maxf(x0, x1) < bx - b.w * 0.5 - m or minf(x0, x1) > bx + b.w * 0.5 + m:
			continue
		if minf(p.y + (eye.y - p.y) * t0, p.y + (eye.y - p.y) * t1) > _top[bi] + m:
			continue
		out[bi] = true
		any = true
	return any


## The clock the occlusion and the lane cue ease on: the sim's ticks, frozen ones included. It runs through a hit-stop
## and a pausing set piece (Q10: the camera moves then, so a building newly in the way must still open), and stands
## still while the player has the game paused.
static func tick_time(S: SimState) -> float:
	return float(S.tick) * SimConst.DT


## Per frame, per pane: cut the buildings in `want` down to low stubs and let the others stand again, eased on tick
## time (RenderLook.STUB_*). building.gdshader lowers every vertex of a cut building to the height in stub_tex, so the
## box sinks to a solid stub with its own top.
## soft: the buildings the foreground row's patch lowers and how far (0 to 1; PaneWorld._row0_patch). They sink over
## PATCH_SINK_S and stand again over PATCH_RISE_S, and none stands again until PATCH_HOLD_S after the last of them
## sank (Camera's rule: a sink and a stand within a second are a flash).
## gone: the buildings too near the lens to draw at all (Camera's near-clip rule; they are in `soft` at 1 as well):
## each sinks on from its stub to under its footing, at the same pace.
func set_stubs(S: SimState, want: Dictionary, soft: Dictionary = {}, gone: Dictionary = {}) -> void:
	var now: float = tick_time(S)
	var snap: bool = _stub_t < 0.0
	var dt: float = clampf(now - _stub_t, 0.0, 0.1) if not snap else 1.0e3
	_stub_t = now
	for bi in want:
		_stub_live[bi] = true
	for bi in soft:
		if float(soft[bi]) > 0.0:
			_stub_live[bi] = true
	for bi in gone:
		_stub_live[bi] = true
	if _stub_live.is_empty():
		return
	var done: Array = []
	var changed: Array = [false, false]
	for bi in _stub_live:
		var cut: bool = want.has(bi)
		var v: float = _stub[bi]
		if cut or not (soft.has(bi) or _stub_hold.has(bi)):
			v = move_toward(v, 1.0 if cut else 0.0, dt / (RenderLook.STUB_IN_S if cut else RenderLook.STUB_OUT_S))
		else:
			var target: float = float(soft.get(bi, 0.0))
			if target > v:
				v = move_toward(v, target, dt / RenderLook.PATCH_SINK_S)
				_stub_hold[bi] = now + RenderLook.PATCH_HOLD_S
				_sink_last = now
			elif target < v and (snap or (now >= float(_stub_hold.get(bi, -1.0)) and now >= _sink_last + RenderLook.PATCH_HOLD_S)):
				v = move_toward(v, target, dt / RenderLook.PATCH_RISE_S)
			if v <= 0.0:
				_stub_hold.erase(bi)
		_stub[bi] = v
		var y: float = STUB_WHOLE
		if v <= 0.0:
			done.append(bi)
		elif _top[bi] > -INF:
			var top: float = _top[bi]
			var low: float = minf(top, top - WorldStructures.curH(S.buildings[bi]) + RenderLook.STUB_H)
			if gone.has(bi) or _gone.has(bi):
				# Past its stub: on down, under its footing (and back up when it is no longer too near).
				var g: float = move_toward(float(_gone.get(bi, 0.0)), 1.0 if gone.has(bi) and v >= 1.0 else 0.0, (dt if not snap else 1.0e3) / RenderLook.PATCH_SINK_S)
				if g > 0.0:
					_gone[bi] = g
					low = lerpf(low, top - WorldStructures.curH(S.buildings[bi]) - RenderLook.NEAR_SINK, g * g * (3.0 - 2.0 * g))
				else:
					_gone.erase(bi)
			y = lerpf(top, low, v * v * (3.0 - 2.0 * v))
		var row0: bool = _row0[bi] >= 0
		var st: Array = _stub_tex0 if row0 else _stub_tex
		for k in _inst[bi]:   # every part of the building is cut down with it
			var px: Color = (st[0] as Image).get_pixel(k, 0)
			if absf(px.r - y) > 0.01:
				(st[0] as Image).set_pixel(k, 0, Color(y, px.g, px.b, px.a))
				changed[1 if row0 else 0] = true
	for bi in done:
		_stub_live.erase(bi)
	if changed[0]:
		(_stub_tex[1] as ImageTexture).update(_stub_tex[0])
	if changed[1]:
		(_stub_tex0[1] as ImageTexture).update(_stub_tex0[0])


## The next set_stubs jumps to its targets instead of easing (for tools that pose a frame).
func snap_stubs() -> void:
	_stub_t = -1.0


## Whether building b has a lobby to open in this match (RenderLook.OPEN_*): only with depth on, a tower by its shape
## and by its floors as built, so a building is of one kind for the whole match.
static func opens(S: SimState, b) -> bool:
	return S.depthOn and int(b.floors) >= RenderLook.OPEN_FLOORS_MIN and RenderShapes.has_lobby(str(b.shape))


## The same for a building of this pane's world, by its index.
func opens_floors(bi: int) -> bool:
	return bi >= 0 and bi < _open_kind.size() and _open_kind[bi] == 1


## Whether building bi is a tall building in a match with depth on (a tower with a lobby, or a tall building without
## one: a stack, a lighthouse, a hall, a chapel). No tall building is sunk to a stub there.
func stands_tall(bi: int) -> bool:
	return bi >= 0 and bi < _open_kind.size() and _open_kind[bi] != 0


## How many floors tall building b's lobby is: one double-height storey, and on a tower of OPEN_TALL floors or more as
## many floors as reach OPEN_LOBBY_H.
static func lobby_floors(b) -> int:
	var floors: int = maxi(int(b.floors), 1)
	var n: int = RenderLook.OPEN_LOBBY_FLOORS
	if floors >= RenderLook.OPEN_TALL:
		n = clampi(int(ceil(RenderLook.OPEN_LOBBY_H / maxf(b.h / float(floors), 1.0))), RenderLook.OPEN_LOBBY_FLOORS, RenderLook.OPEN_LOBBY_MAX)
	return maxi(1, mini(n, floors - 1))


## Building bi's lobby as it stands in this pane's world: its floor and its top (world y), or ZERO when the building is
## not drawn. Its ceiling is OPEN_BEAM under the top.
func lobby_span(S: SimState, bi: int) -> Vector2:
	if _top[bi] == -INF:
		return Vector2.ZERO
	var b = S.buildings[bi]
	var foot: float = _top[bi] - WorldStructures.curH(b)
	return Vector2(foot, foot + float(lobby_floors(b)) * b.h / float(maxi(int(b.floors), 1)))


## Whether building b may have its lobby open now. Always: standing, with none of the lobby's own floors cleared by a
## brunt (a tunnel there is the tower's damage, and shows as one). With RenderLook.OPEN_DAMAGED off (as committed in
## 60f82149; Orb has the question) also undamaged and whole. With it on a damaged tower's lobby opens and shows its
## stage (building.gdshader). Otherwise the patch shows the fight through the tower.
static func lobby_ok(b) -> bool:
	var need: int = (1 << lobby_floors(b)) - 1
	if not b.alive or (int(b.fmask) & need) != need:
		return false
	return RenderLook.OPEN_DAMAGED or (WorldStructures.stage(b) == 0 and b.fmask == (1 << int(b.floors)) - 1)


## The share of building bi's lobby that is open in this pane (0 to 1).
func lobby_share(bi: int) -> float:
	return float(_open[bi][0]) if _open.has(bi) else 0.0


## Tower bi's share of the patch in this pane (0 to 1): the see-through window on it, when the fight is above its
## lobby's ceiling or it is not whole.
func patch_share(bi: int) -> float:
	return float(_open[bi][1]) if _open.has(bi) else 0.0


## Whether the patch cuts building bi in this pane: any building without a lobby, and a tower by its share.
func takes_patch(bi: int) -> bool:
	return not opens_floors(bi) or patch_share(bi) > 0.5


## This pane's lobby in building bi as drawn: its floor and its top (world y), or (0, 0) while less than half of it is
## through.
func open_now(bi: int) -> Vector2:
	return Vector2(float(_open[bi][5]), float(_open[bi][6])) if _open.has(bi) and float(_open[bi][0]) >= 0.5 else Vector2.ZERO


## At build: every building's kind in this pane's stub textures. With depth off none has a lobby and nothing is written.
func _mark_open(S: SimState) -> void:
	_open.clear()
	_open_t = -1.0
	open_turned = 0.0
	_open_kind.resize(S.buildings.size())
	_open_kind.fill(0)
	if not S.depthOn:
		return
	for bi in range(S.buildings.size()):
		var b = S.buildings[bi]
		if opens(S, b):
			_open_kind[bi] = 1
			_put_open(bi, 0.0, OPEN_SHUT, 0.0)
		elif int(b.floors) >= RenderLook.OPEN_FLOORS_MIN:
			_open_kind[bi] = 2
	(_stub_tex[1] as ImageTexture).update(_stub_tex[0])
	(_stub_tex0[1] as ImageTexture).update(_stub_tex0[0])


## Write building bi's lobby to its parts' texels: the share open (negative on every part but the shell, which alone
## carries the colonnade), the lobby's top, the tower's share of the patch. Returns which texture changed (0 the
## rows', 1 the foreground row's, -1 none).
func _put_open(bi: int, k: float, top: float, p: float) -> int:
	var row0: bool = _row0[bi] >= 0
	var st: Array = _stub_tex0 if row0 else _stub_tex
	var ix: PackedInt32Array = _inst[bi]
	var shell: int = RenderShapes.shell(_parts[bi])
	var hit: int = -1
	for j in range(ix.size()):
		var g: float = k if j == shell else -k
		var px: Color = (st[0] as Image).get_pixel(ix[j], 0)
		if absf(px.g - g) > 0.0001 or absf(px.b - top) > 0.01 or absf(px.a - p) > 0.0001:
			(st[0] as Image).set_pixel(ix[j], 0, Color(px.r, g, top, p))
			hit = 1 if row0 else 0
	return hit


## The area on this pane's screen that a share p of the patch covers (its capsule with the radius scaled by p), in pixels.
## patch: the capsule's length and radius in pixels.
static func _patch_area(patch: Vector2, p: float) -> float:
	return 2.0 * patch.x * patch.y * p + PI * patch.y * patch.y * p * p


## Per frame, per pane: the towers' lobbies and their shares of the patch (building.gdshader's v_open; RenderLook.OPEN_*).
## want: building -> Vector3(1 if the action is seen under its lobby's ceiling, 1 if it is seen over it, the pixels of
## this pane's screen a unit of its height covers across its face). Only a tower with a lobby (opens) is taken.
## patch: the patch on this pane's screen, its length and its radius in pixels.
## - A lobby opens when the action is seen under its ceiling and the tower may open it (lobby_ok). It shuts OPEN_HOLD_S
##   after nothing has asked for it, and with no hold on a tower that may no longer open it.
## - A tower takes its share of the patch when the action is seen over the ceiling, or when it stands in front of the
##   action and may not open its lobby. It gives the share up PATCH_HOLD_S after.
## - Both fade. All of them together turn at most a tick's share of RenderLook.PATCH_AREA_TICK pixels (at 1024 by 768),
##   less what the patch itself turned this frame (`left`: what it left of the budget, under 0 for all of it), a
##   closing at OPEN_CLOSE of that; and none goes faster than over OPEN_FADE_S.
func set_open(S: SimState, want: Dictionary, vp: Vector2, left: float = -1.0, patch: Vector2 = Vector2.ZERO) -> void:
	var now: float = tick_time(S)
	var snap: bool = _open_t < 0.0 or now < _open_t
	var ticks: float = clampf(now - _open_t, 0.0, 0.1) / SimConst.DT if not snap else 0.0
	_open_t = now
	open_turned = 0.0
	for bi in want:
		if not _open.has(bi) and opens_floors(bi) and _top[bi] > -INF:
			# [share open, share of the patch, when the lobby was last asked for, when the patch was, pixels a unit of
			#  height, the lobby's floor, its top, the shares wanted now]
			_open[bi] = [0.0, 0.0, -1.0e9, -1.0e9, 1.0, 0.0, 0.0, 0.0, 0.0]
	if _open.is_empty():
		return
	var budget: float = RenderLook.PATCH_AREA_TICK * (vp.x * vp.y) / (1024.0 * 768.0) * ticks
	if left >= 0.0:
		budget = minf(budget, left)
	# What each wants now, and the area it would turn.
	var need: float = 0.0
	for bi in _open:
		var o: Array = _open[bi]
		var b = S.buildings[bi]
		var span: Vector2 = lobby_span(S, bi)
		var whole: bool = span != Vector2.ZERO and lobby_ok(b)
		var asked: bool = want.has(bi)
		var w: Vector3 = want[bi] if asked else Vector3.ZERO
		if asked:
			o[4] = w.z
		if span != Vector2.ZERO:
			o[5] = span.x
			o[6] = span.y
		if asked and whole and w.x > 0.5:
			o[2] = now
		if asked and (w.y > 0.5 or not whole):
			o[3] = now
		o[7] = 1.0 if whole and now - float(o[2]) < RenderLook.OPEN_HOLD_S else 0.0
		o[8] = 1.0 if span != Vector2.ZERO and now - float(o[3]) < RenderLook.PATCH_HOLD_S else 0.0
		var dk: float = float(o[7]) - float(o[0])
		var da: float = _patch_area(patch, float(o[8])) - _patch_area(patch, float(o[1]))
		var lobby_px: float = float(o[4]) * (float(o[6]) - float(o[5]))
		need += lobby_px * (dk if dk > 0.0 else -dk / RenderLook.OPEN_CLOSE) + (da if da > 0.0 else -da / RenderLook.OPEN_CLOSE)
	var s: float = 1.0 if snap else minf(1.0, budget / maxf(need, 0.001))
	var step: float = 1.0 if snap else ticks * SimConst.DT / RenderLook.OPEN_FADE_S   # no fade is shorter than OPEN_FADE_S
	var changed: Array = [false, false]
	var done: Array = []
	for bi in _open:
		var o: Array = _open[bi]
		var k0: float = float(o[0])
		var p0: float = float(o[1])
		var k1: float = k0 + clampf((float(o[7]) - k0) * s, -step, step)
		var p1: float = float(o[8])
		if patch.y > 0.0 and not snap:
			# By area: the share whose capsule covers what the budget allows of the change.
			var a0: float = _patch_area(patch, p0)
			var a1: float = a0 + (_patch_area(patch, float(o[8])) - a0) * s
			var lr: float = patch.x * patch.y
			var rr: float = PI * patch.y * patch.y
			p1 = (sqrt(maxf(lr * lr + rr * a1, 0.0)) - lr) / rr
			p1 = p0 + clampf(p1 - p0, -step, step)
		if absf(k1 - float(o[7])) < 0.0001:
			k1 = float(o[7])
		if absf(p1 - float(o[8])) < 0.0001:
			p1 = float(o[8])
		open_turned += float(o[4]) * (float(o[6]) - float(o[5])) * absf(k1 - k0) + absf(_patch_area(patch, p1) - _patch_area(patch, p0))
		o[0] = k1
		o[1] = p1
		var gone: bool = k1 <= 0.0 and p1 <= 0.0 and float(o[7]) <= 0.0 and float(o[8]) <= 0.0 and not want.has(bi)
		var hit: int = _put_open(bi, 0.0, OPEN_SHUT, 0.0) if gone else _put_open(bi, k1, float(o[6]), p1)
		if hit >= 0:
			changed[hit] = true
		if gone:
			done.append(bi)
	for bi in done:
		_open.erase(bi)
	if changed[0]:
		(_stub_tex[1] as ImageTexture).update(_stub_tex[0])
	if changed[1]:
		(_stub_tex0[1] as ImageTexture).update(_stub_tex0[0])


## The next set_open jumps to its targets instead of fading (a cut; tools that pose a frame).
func snap_open() -> void:
	_open_t = -1.0


## Per frame, per pane: the cut-away holes around the fighters (building.gdshader). holes: per fighter [his chest as
## drawn (camera-relative world space), the radius in pixels (0: none), the view distance up to which buildings are cut
## there, then the hole's other end (his chest again for a round hole; toward the other fighter for one that covers
## both), the radius and the view distance to cut up to at that end].
## front: the foreground row's own hole, its patch (one entry of the same shape, or empty: row 0 then takes the
## fighters' holes like the rows behind).
## deep (a match with depth on): the holes of the rows behind are the patch too, and take its soft edge.
func set_holes(holes: Array, front: Array = [], deep: bool = false) -> void:
	if deep != _bld_soft:
		_bld_soft = deep
		_bld_mat.set_shader_parameter("hole_edge", RenderLook.PATCH_EDGE if deep else Vector2(0.8, 0.25))
	var sets: Array = [_hole_set(holes), _hole_set([front] if not front.is_empty() else holes)]
	var any: bool = bool(sets[0][3]) or bool(sets[1][3])
	if not any and not _holes_on:
		return
	_holes_on = any
	var k: int = 0
	for m in [_bld_mat, _front_mat]:
		m.set_shader_parameter("hole", sets[k][0])
		m.set_shader_parameter("hole_to", sets[k][1])
		m.set_shader_parameter("hole_near", sets[k][2])
		k += 1
	_front_mat.set_shader_parameter("hole_edge", RenderLook.PATCH_EDGE if not front.is_empty() else Vector2(0.8, 0.25))


## Up to two holes as the shader's three arrays, and whether any is open.
static func _hole_set(holes: Array) -> Array:
	var hv: Array = []
	var ht: Array = []
	var hn := PackedVector2Array()
	var any: bool = false
	for i in range(2):
		if i < holes.size() and float(holes[i][1]) > 0.0:
			var p: Vector3 = holes[i][0]
			var q: Vector3 = holes[i][3]
			hv.append(Vector4(p.x, p.y, p.z, float(holes[i][1])))
			ht.append(Vector4(q.x, q.y, q.z, float(holes[i][4])))
			hn.append(Vector2(float(holes[i][2]), float(holes[i][5])))
			any = true
		else:
			hv.append(Vector4.ZERO)
			ht.append(Vector4.ZERO)
			hn.append(Vector2.ZERO)
	return [hv, ht, hn, any]


## Whether this world has a foreground row.
func has_row0() -> bool:
	return not _row0_b.is_empty()


## The standing buildings of the foreground row within `reach` of the camera's x, for the patch: each [the building,
## its x from the camera, its width, its footing, its top as it stands whole, its front face's depth].
## deep (a match with depth on): every row's buildings, each with its back face's depth as a seventh number, since the
## patch then works through every row in front of the action. A tall building (stands_tall) is never among them: none
## is sunk in a match with depth on.
func row0_faces(S: SimState, cam_x: float, reach: float, deep: bool = false) -> Array:
	var out: Array = []
	for bi in (range(S.buildings.size()) if deep else _row0_b):
		if _top[bi] == -INF or stands_tall(bi):
			continue
		var b = S.buildings[bi]
		var bx: float = SimWrap.sdx(cam_x, b.x)
		if absf(bx) > reach + b.w:
			continue
		var zd: Vector2 = _depth(b)
		var fc: Array = [bi, bx, b.w, _top[bi] - WorldStructures.curH(b), _top[bi], zd.x + zd.y * 0.5]
		if deep and _row0[bi] < 0:
			fc.append(zd.x - zd.y * 0.5)
		out.append(fc)
	return out


func _building_mat() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = BUILDING_SHADER
	m.set_shader_parameter("inside", RenderLook.col(RenderLook.BUILDING_INSIDE))
	m.set_shader_parameter("win_pitch", RenderLook.WINDOW_PITCH)
	m.set_shader_parameter("win_lit_share", RenderLook.WINDOW_LIT_SHARE)
	m.set_shader_parameter("win_lit", RenderLook.col(RenderLook.WINDOW_LIT))
	m.set_shader_parameter("win_glass", RenderLook.col(RenderLook.WINDOW_GLASS))
	m.set_shader_parameter("dmg_bite", RenderLook.DMG_BITE)
	m.set_shader_parameter("dmg_crack", RenderLook.DMG_CRACK)
	m.set_shader_parameter("dmg_soot", RenderLook.DMG_SOOT)
	m.set_shader_parameter("dmg_rag", RenderLook.DMG_RAG)
	m.set_shader_parameter("dmg_panels", RenderLook.DMG_PANELS)
	m.set_shader_parameter("dmg_frame", RenderLook.col(RenderLook.DMG_FRAME))
	m.set_shader_parameter("roof_over", RenderLook.ROOF_OVER)
	m.set_shader_parameter("pan_mix", RenderLook.PAN_HAZE_MIX)
	m.set_shader_parameter("pan_whip_mix", RenderLook.PAN_WHIP_MIX)
	m.set_shader_parameter("dmg_holes", RenderLook.DMG_HOLES)
	m.set_shader_parameter("pattern_budget", RenderLook.PATTERN_BUDGET)
	m.set_shader_parameter("open_col", RenderLook.OPEN_COL)
	m.set_shader_parameter("open_beam", RenderLook.OPEN_BEAM)
	m.set_shader_parameter("open_frame_col", RenderLook.col(RenderLook.OPEN_FRAME_COL))
	m.set_shader_parameter("open_far", RenderLook.OPEN_FAR)
	m.set_shader_parameter("open_ceil", RenderLook.col(RenderLook.OPEN_CEIL))
	m.set_shader_parameter("open_lamp", RenderLook.col(RenderLook.OPEN_LAMP))
	m.set_shader_parameter("open_grid", RenderLook.OPEN_GRID)
	m.set_shader_parameter("open_ghost", RenderLook.OPEN_GHOST)
	m.set_shader_parameter("open_near", RenderLook.NEAR_CLIP)
	m.set_shader_parameter("open_core", RenderLook.OPEN_CORE)
	m.set_shader_parameter("open_core_vary", RenderLook.OPEN_CORE_VARY)
	m.set_shader_parameter("open_core_tone", RenderLook.OPEN_CORE_TONE)
	m.set_shader_parameter("open_door", RenderLook.OPEN_DOOR)
	m.set_shader_parameter("open_core_ghost", RenderLook.OPEN_CORE_GHOST)
	m.set_shader_parameter("cut_plate", RenderLook.CUT_PLATE)
	m.set_shader_parameter("mark_reach", RenderLook.MARK_REACH)
	m.set_shader_parameter("mark_tall", RenderLook.MARK_TALL)
	m.set_shader_parameter("mark_crack", RenderLook.MARK_CRACK)
	m.set_shader_parameter("spread_area", RenderLook.SPREAD_AREA_TICK * (RenderLook.SPREAD_CALM if _calm else 1.0))
	m.set_shader_parameter("spread_lag", RenderLook.SPREAD_LAG)
	m.set_shader_parameter("spread_block", RenderLook.SPREAD_BLOCK)
	m.set_shader_parameter("spread_cell", RenderLook.SPREAD_CELL_PX)
	var lu: Dictionary = RenderShapes.look_uniforms()
	for key in lu:
		m.set_shader_parameter(key, lu[key])
	var cu: Dictionary = RenderShapes.city_uniforms()
	for key in cu:
		m.set_shader_parameter(key, cu[key])
	m.set_shader_parameter("glass_sky", RenderLook.GLASS_SKY if RenderLook.CITY_VARIETY else Vector2(0.0, RenderLook.GLASS_SKY.y))
	m.set_shader_parameter("row_haze", RenderLook.ROW_HAZE if row_haze else Vector3(0.0, RenderLook.ROW_HAZE.y, RenderLook.ROW_HAZE.z))
	mats.track(m)
	return m


## An eleven-row float texture of window, shape and damage data, a column an instance: [image, texture, dirty]. A
## column not written yet is a plain box with no shell. Rows 0 to 4: _write_windows. Row 5: a stage spreading over the
## building (x from its shell's middle, y over its base, the tick it started, the stage before plus four times the
## buildings sharing the area). Rows 6 to 9: its marks (first floor plus 64 times the floors plus 4,096 times the
## sharing; the share of the floor's strength taken; the side, -1 or 1, times one plus the share before; the tick it
## grows from). Row 10: a second wave inside the first, as row 5 (its stage before is the stage inside the first
## wave). Rows 11 and 12: floors a blow-out is putting out (a bit a floor, packed as the first row's; then x, y, the
## tick and the sharing of their wave). The fifth row's blue says which are there: 1 marks, 2 a spread, 4 its second
## wave, 8 a blow-out's wave.
static func _win_texture(n: int) -> Array:
	var img := Image.create_empty(maxi(1, n), 13, false, Image.FORMAT_RGBAF)
	img.fill(Color(0, 0, 0, 0))
	img.fill_rect(Rect2i(0, 2, maxi(1, n), 1), Color(1.0, 1.0, 0.0, 0.0))
	return [img, ImageTexture.create_from_image(img), false]


## A one-row float texture of floor cuts, one texel an instance: [image, texture, dirty].
static func _cut_texture(n: int) -> Array:
	var img := Image.create_empty(maxi(1, n), 1, false, Image.FORMAT_RGBAF)
	img.fill(Color(0, 0, 0, 0))
	return [img, ImageTexture.create_from_image(img), false]


## A one-row float texture of a material's per-pane cuts, one texel an instance: r its stub height (whole), g and b
## its open floors (none, and a building that never opens any): [image, texture].
static func _stub_texture(m: ShaderMaterial, n: int) -> Array:
	var img := Image.create_empty(maxi(1, n), 1, false, Image.FORMAT_RGBAF)
	img.fill(Color(STUB_WHOLE, 0.0, OPEN_OFF, 0.0))
	var tex := ImageTexture.create_from_image(img)
	m.set_shader_parameter("stub_tex", tex)
	return [img, tex]


## Buildings, roofs, trees and the crowd. Placement that the sim doesn't define (tree depth, where each civilian
## stands, their colours) comes from render-side streams seeded from the fixed world seed, never from S.rng.
func _make_props(S: SimState) -> void:
	var nb: int = S.buildings.size()
	var box := BoxMesh.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.5
	cone.height = 1.0
	cone.radial_segments = 6
	cone.rings = 0
	var z0: float = 0.0
	var z1: float = 0.0
	_row0.resize(nb)
	_row0.fill(-1)
	_row0_b.clear()
	for bi in range(nb):
		var b = S.buildings[bi]
		var zd: Vector2 = _depth(b)
		z0 = minf(z0, zd.x - zd.y)
		z1 = maxf(z1, zd.x + zd.y)
		if int(b.row) == 0 and b.d > 0.0:
			_row0[bi] = _row0_b.size()
			_row0_b.append(bi)
	z0 -= RenderLook.CROWD_GAP + RenderLook.CROWD_DEEP + 200.0
	z1 += RenderLook.CROWD_GAP + RenderLook.CROWD_DEEP + 200.0
	# Each building's parts (its shape, in its district's look) and their instances: the bodies keep the building's own
	# index (its row-0 index in row 0), the other parts follow them.
	var lanes: PackedFloat32Array = RenderLanes.table(S)
	_parts.clear()
	_inst.clear()
	_look.resize(nb)
	_city.resize(nb)
	_n_inst = maxi(1, nb)
	_n_inst0 = maxi(1, _row0_b.size())
	for bi in range(nb):
		var b = S.buildings[bi]
		_look[bi] = RenderShapes.look_of(lanes, b)
		var lk: Dictionary = RenderShapes.city_look(b, _look[bi])   # a tower takes Art's tint and facade (city variety)
		_city[bi] = RenderShapes.city_code(lk, int(b.floors))
		var ps: Array = RenderShapes.parts(b, lk, _depth(b).y)
		var ix := PackedInt32Array()
		var front: bool = _row0[bi] >= 0
		ix.append(_row0[bi] if front else bi)
		for j in range(1, ps.size()):
			if front:
				ix.append(_n_inst0)
				_n_inst0 += 1
			else:
				ix.append(_n_inst)
				_n_inst += 1
		_parts.append(ps)
		_inst.append(ix)
	_bld = _multimesh(box, _n_inst, BUILDING_TOP, false, false, z0, z1)
	_bld0 = _multimesh(box, _n_inst0, BUILDING_TOP, false, false, z0, z1)
	for k in range(_n_inst):
		_bld.set_instance_transform(k, _hidden(0.0))
	for k in range(_n_inst0):
		_bld0.set_instance_transform(k, _hidden(0.0))
	_cut = _cut_texture(_n_inst)
	_cut0 = _cut_texture(_n_inst0)
	_win = _win_texture(_n_inst)
	_win0 = _win_texture(_n_inst0)
	_blown.resize(nb)
	_blown.fill(0)
	_blow_seen.clear()
	_tree = _multimesh(cone, S.trees.size(), 400.0)
	_bld_seen.clear()
	_drawn.clear()
	_foot.resize(nb)
	_foot.fill(Vector2.ZERO)
	_top.resize(nb)
	_top.fill(-INF)
	_falls.clear()
	_spread.clear()
	_marks.clear()
	_busy.clear()
	_drops.clear()
	_blowing.clear()
	_hit_last.clear()
	_blasts.clear()
	_hit_at.clear()
	_hit_side.clear()
	_last_tick = -1
	_fold = []
	for bi in range(nb):
		_bld_seen.append([-1.0, false, -1, -1.0, 0])
		_drawn.append([0.0, 0, false])
	var tr := SimRng.new(SimRng.deriveSeed(4242, "render.trees"))
	_tree_seen.clear()
	_tree_z.resize(S.trees.size())
	for ti in range(S.trees.size()):
		_tree_seen.append(null)
		_tree_z[ti] = tr.range_(RenderLook.Z_TREE_MIN, RenderLook.Z_TREE_MAX)
		_tree.set_instance_color(ti, RenderLook.col(RenderLook.TREE if tr.next() < 0.5 else RenderLook.TREE_TOP))
	var cr := SimRng.new(SimRng.deriveSeed(4242, "render.crowd"))
	_crowd_first.resize(nb + 1)
	_crowd_x.clear()
	_crowd_z.clear()
	var looks: Array = []
	for bi in range(nb):
		_crowd_first[bi] = _crowd_x.size()
		var b = S.buildings[bi]
		# On the building's street side: in front of its face for rows 1 to 3, between row 0 and the fighter plane.
		var zd: Vector2 = _depth(b)
		var front: bool = b.d > 0.0 and int(b.row) == 0
		var face: float = zd.x - zd.y * 0.5 if front else zd.x + zd.y * 0.5
		var nf: int = mini(mini(int(b.pop), RenderLook.CROWD_MAX), int(b.w / RenderLook.CROWD_FACE))
		for j in range(nf):
			# Each in its own even slot along the face, jittered within it; the rest of the people are inside.
			_crowd_x.append(SimWrap.wrap(b.x + ((float(j) + cr.next()) / float(nf) - 0.5) * b.w))
			var out: float = RenderLook.CROWD_GAP + cr.next() * RenderLook.CROWD_DEEP
			_crowd_z.append(face - out if front else face + out)
			var shirt: Color = RenderLook.col(RenderLook.CROWD[int(cr.next() * RenderLook.CROWD.size())]).lerp(RenderLook.col(RenderShapes.look(_look[bi])["wall"][1]), RenderLook.CROWD_DISTRICT).srgb_to_linear()
			looks.append(Color(shirt.r, shirt.g, shirt.b, cr.next()))
	_crowd_first[nb] = _crowd_x.size()
	_crowd = _multimesh(CrowdMesh.build(), _crowd_x.size(), 80.0, true, true, z0, z1)
	for ci in range(looks.size()):
		_crowd.set_instance_custom_data(ci, looks[ci])
		_crowd.set_instance_color(ci, Color.WHITE)
	_shown.resize(nb)
	_shown.fill(-1)
	flight.reset(nb)
	_blows.clear()
	_startled.clear()
	_calm_at = INF
