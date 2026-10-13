extends SceneTree
## The towers' lobbies (headless, through the real main scene; RenderLook.OPEN_*, docs/rendering/open-floors.md): what
## the pane asks of the planet view and what the planet view hands the building shader. No picture is judged here.
## - depth off, a real match: no building has a lobby, nothing opens, and every texel says so;
## - depth on (the tool's own match): a building has a lobby by its shape and its floors as built and by nothing else;
##   a tall building of another shape has none and is never among those the patch sinks;
## - a pair in the front street in front of a tower: nothing opens;
## - the pair suddenly in the middle street behind the tower: its lobby fades in, one storey from the ground to a floor
##   line, by no more than the area budget a tick and over no less than OPEN_FADE_S; the tower takes no share of the
##   patch (the sight line to their heads passes under the ceiling) and does not sink;
## - the pair back in the front street: the lobby holds for OPEN_HOLD_S, then fades out at no more than OPEN_CLOSE of
##   the budget a tick, and is shut;
## - Camera's request off: nothing is asked, and what was open shuts;
## - Camera's cut flag: a lobby is open on that frame;
## - the pair moved far along the street between two ticks under a camera already there: the patch's ends are on the
##   fighters on that frame, and the lobby opens;
## - the pair lifted over the lobby's ceiling behind the tower: the tower takes its share of the patch, by area; back
##   on the ground it gives the share up after its hold;
## - the tower damaged while its lobby is open: by RenderLook.OPEN_DAMAGED the lobby stays open at every stage (the
##   shader shows the stage) or shuts with no hold and the tower takes the patch; a floor of the lobby cleared by a
##   brunt: the lobby shuts with no hold and the tower takes the patch, either way;
## - Camera's cut flag reaches a pane's request from the frame's `clear`, and the frame's own dictionary is not changed;
## - what holds a cleared floor up: each part knows from what height it is the building's outermost wall, and the
##   core's state follows the building's hit points;
## - a stepped tower's lobby: one part, its shell at the street, carries the colonnade, and the others are marked
##   as inside it;
## - behind a low building the low building has no lobby: the patch is handed to the blocks' material;
## - VFX's clear query: behind an open lobby a point on the lobby's face is hidden and one above it, one at the fight's
##   depth and one behind the fight are not; behind a low building a point in front of the fight inside the patch is
##   hidden;
## - Camera's near-clip rule: a low building nearer the lens than NEAR_CLIP.y stands as its stub, nearer than
##   NEAR_CLIP.x it is under its footing, and a tower as near is neither;
## - on every tick of all of it, no tall building sinks and no building without a lobby opens one.
##   godot --headless --path . --script res://render/tools/open_check.gd

const DT: float = 1.0 / 60.0

var main: Node
var fails: int = 0
var fx: Array = [0.0, 0.0]
var fz: Array = [0.0, 0.0]
var lift: float = 0.0           # the pair's height above its ground
var both: bool = false          # a tall building was seen sinking, or a building without a lobby with one
var most: float = 0.0           # the most pixels the lobbies and the towers' shares turned in a tick since it was last cleared


func _initialize() -> void:
	var vpn := SubViewport.new()
	vpn.size = Vector2i(1280, 720)
	root.add_child(vpn)
	main = load("res://render/main.tscn").instantiate()
	main.manual = true
	vpn.add_child(main)
	_run.call_deferred()


func _expect(ok: bool, what: String) -> void:
	print("%s %s" % ["ok   " if ok else "FAIL ", what])
	if not ok:
		fails += 1


func _hold() -> void:
	var S: SimState = main.host.S
	for i in range(2):
		var f = S.fighters[i]
		f.x = SimWrap.wrap(fx[i])
		f.z = fz[i]
		f.y = WorldTerrain.groundY(S, f.x) + 2.0 + lift
		f.vx = 0.0
		f.vy = 0.0


## n ticks with the fighters held where the tool has them. Returns the pixels turned, tick by tick.
func _ticks(n: int) -> PackedFloat32Array:
	var host: SimHost = main.host
	var P: PlanetView = main.planet
	var out := PackedFloat32Array()
	for k in range(n):
		_hold()
		host.acc = DT * 0.9999
		main.frame(DT)
		_hold()
		out.append(P.open_turned)
		most = maxf(most, P.open_turned)
		for bi in range(host.S.buildings.size()):
			if P.stands_tall(bi) and P._stub[bi] > 0.0:
				both = true
			if not P.opens_floors(bi) and P._open.has(bi):
				both = true
	return out


## n ticks of the pane alone with Camera's cut-away request `cut` (main gives its one view an empty request every
## frame, so the tool draws the pane itself and counts the ticks in its own state).
func _pane_ticks(n: int, cut: Dictionary) -> void:
	var host: SimHost = main.host
	for k in range(n):
		host.S.tick += 1
		main.pane.cutaway = cut
		main.pane.render(host, 1.0, host.camera_x(1.0), host.camera(1.0), Vector2.ZERO)
		most = maxf(most, main.planet.open_turned)


## The camera at once where the fight is, and every eased cut at its target.
func _settle(n: int = 90) -> void:
	main.pane.snap_occlusion()
	_ticks(n)
	main.pane.snap_occlusion()
	_ticks(2)


## The texel of building bi's part j in this pane's stub texture (j under 0: its shell at the street).
func _texel(bi: int, j: int = -1) -> Color:
	var P: PlanetView = main.planet
	var st: Array = P._stub_tex0 if P._row0[bi] >= 0 else P._stub_tex
	var part: int = RenderShapes.shell(P._parts[bi]) if j < 0 else j
	return (st[0] as Image).get_pixel((P._inst[bi] as PackedInt32Array)[part], 0)


## How many ticks of a run turned anything.
static func _took(turned: PackedFloat32Array) -> int:
	var n: int = 0
	for k in range(turned.size()):
		if turned[k] > 0.5:
			n = k + 1
	return n


func _run() -> void:
	await process_frame
	main.started = true
	# --- depth off
	main.start_match(4, {"p1": true, "p2": true}, {"intro": "skip"})
	var host: SimHost = main.host
	var S: SimState = host.S
	var P: PlanetView = main.planet
	var any: bool = false
	for k in range(300):
		host.acc = DT * 0.9999
		main.frame(DT)
		any = any or not P._open.is_empty() or P.open_turned != 0.0
	var off: bool = true
	for bi in range(S.buildings.size()):
		for j in range((P._inst[bi] as PackedInt32Array).size()):
			var t: Color = _texel(bi, j)
			off = off and not P.opens_floors(bi) and not P.stands_tall(bi) and t.g == 0.0 and t.b == PlanetView.OPEN_OFF and t.a == 0.0
	_expect(not S.depthOn and not any and off, "depth off, a real match of 300 ticks: no building has a lobby, nothing opens, and every part of all %d buildings says so" % S.buildings.size())
	# --- depth on
	main.start_match(4, {"p1": false, "p2": false}, {"intro": "skip", "depth": true})
	host = main.host
	S = host.S
	P = main.planet
	if main.split_view != null and main.split_view.is_attached():
		main.split_view.detach()
	var kinds: bool = true
	var n_open: int = 0
	var n_tall: int = 0
	for bi in range(S.buildings.size()):
		var b = S.buildings[bi]
		var tall_b: bool = int(b.floors) >= RenderLook.OPEN_FLOORS_MIN
		var k: bool = tall_b and RenderLook.OPEN_SHAPES.has(str(b.shape))
		n_open += 1 if k else 0
		n_tall += 1 if tall_b and not k else 0
		kinds = kinds and P.opens_floors(bi) == k and P.stands_tall(bi) == tall_b and _texel(bi).b == (PlanetView.OPEN_SHUT if k else PlanetView.OPEN_OFF) and _texel(bi).g == 0.0
	var sunk: Array = []
	for fc in P.row0_faces(S, host.camera_x(1.0), 1.0e9, true):
		if int(S.buildings[int(fc[0])].floors) >= RenderLook.OPEN_FLOORS_MIN:
			sunk.append(int(fc[0]))
	_expect(S.depthOn and kinds and n_open > 0 and n_open < S.buildings.size() and sunk.is_empty(), "depth on: a building has a lobby by its shape and its floors as built (%d or more: %d of %d buildings), and its texel says which kind it is; %d tall buildings of other shapes have none; no tall building is among those the patch may sink" % [RenderLook.OPEN_FLOORS_MIN, n_open, S.buildings.size(), n_tall])
	var lanes: PackedFloat32Array = S.lanes
	var streets: Array = []
	for k in range(int(lanes[1])):
		var o: int = int(lanes[10]) + 4 * k
		if int(lanes[o + 2]) == 0:
			streets.append(0.5 * (lanes[o] + lanes[o + 1]))
	var tower = null
	var low = null
	var stepped = null
	for b in S.buildings:
		if int(b.row) != 1:
			continue
		if str(b.shape) == "stepped" and P.opens_floors(int(b.idx)):
			stepped = b
		if int(b.landmark) != 0:
			continue
		if int(b.floors) >= 10 and P.opens_floors(int(b.idx)) and RenderShapes.shell(P._parts[int(b.idx)]) == 0 and (tower == null or b.w > tower.w):
			tower = b
		if int(b.floors) < RenderLook.OPEN_FLOORS_MIN and (low == null or b.w > low.w):
			low = b
	if streets.size() < 2 or tower == null or low == null:
		_expect(false, "this world has two streets, a tower and a low building in the front block")
		quit(1)
		return
	var z_mid: float = streets[1]
	var ti: int = int(tower.idx)
	var budget: float = RenderLook.PATCH_AREA_TICK * (1280.0 * 720.0) / (1024.0 * 768.0)
	var fade_ticks: int = int(ceil(RenderLook.OPEN_FADE_S / DT))
	# In front of the tower.
	fx = [tower.x - 60.0, tower.x + 60.0]
	fz = [0.0, 0.0]
	_settle()
	_expect(P._open.is_empty() and _texel(ti).b == PlanetView.OPEN_SHUT and _texel(ti).g == 0.0, "a pair in the front street in front of a tower: nothing opens")
	# Camera's rule for a near tower: the lens brought to 300 units from the tower's near face (the pair still in front
	# of it), with Camera's depth follow on and off.
	var near_zf: float = PlanetView._depth(tower).x + 0.5 * PlanetView._depth(tower).y
	var lens_gap: float = main.pane.cam_rig.position.z - near_zf
	main.pane.focus_z = -(lens_gap - 300.0)
	_pane_ticks(3, {})
	var off_shut: bool = P._open.is_empty() and absf(main.pane.cam_rig.position.z - near_zf - 300.0) < 1.0
	main.pane.near_lobbies = true
	_pane_ticks(260, {})
	var near_open: float = P.lobby_share(ti)
	main.pane.focus_z = -(lens_gap - 700.0)
	_pane_ticks(460, {})
	var far_shut: bool = not P._open.has(ti)
	main.pane.focus_z = 0.0
	main.pane.near_lobbies = false
	_settle()
	_expect(off_shut and near_open == 1.0 and far_shut and P._open.is_empty(), "Camera's rule for a near tower: the lens 300 units from its near face and the pair in front of it, nothing opens; with Camera's depth follow on its lobby opens (%.2f); the lens back at 700 units, it shuts" % near_open)
	# Behind it, at once.
	fz = [z_mid, z_mid]
	most = 0.0
	var turned: PackedFloat32Array = _ticks(150)
	var took: int = _took(turned)
	var o: Vector2 = P.open_now(ti)
	var foot: float = P._top[ti] - WorldStructures.curH(tower)
	var fh: float = tower.h / float(tower.floors)
	var n_fl: int = PlanetView.lobby_floors(tower)
	var eye: Vector3 = main.pane.cam_rig.position
	var zf: float = tower.z + tower.d * 0.5
	var need: float = -INF
	for v in main.pane.fighter_views:
		var head: Vector3 = (v as FighterView).position + Vector3(0.0, 75.0 + RenderLook.OPEN_HEAD, 0.0)
		need = maxf(need, lerpf(head.y, eye.y, (zf - head.z) / (eye.z - head.z)))
	var tx: Color = _texel(ti)
	_expect(P.lobby_share(ti) == 1.0 and absf(o.x - foot) < 0.01 and absf(o.y - (foot + float(n_fl) * fh)) < 0.01 and o.y - RenderLook.OPEN_BEAM > need and tx.g == 1.0 and absf(tx.b - o.y) < 0.01 and tx.a == 0.0 and P.patch_share(ti) == 0.0, "the pair suddenly in the middle street behind the tower: its lobby opens, one storey of %d floors (%.0f units) from the ground; the sight line to %.0f units over their heads passes at %.0f, under its ceiling at %.0f, and the tower takes no share of the patch" % [n_fl, o.y - foot, RenderLook.OPEN_HEAD, need - foot, o.y - RenderLook.OPEN_BEAM - foot])
	_expect(most <= budget + 1.0 and took >= fade_ticks, "it fades in: at most %.0f pixels a tick (the budget is %.0f), over %d ticks (no fewer than %d)" % [most, budget, took, fade_ticks])
	_expect(P._stub[ti] == 0.0 and not (main.pane.patch as Dictionary).get("sink", {}).has(ti), "the tower does not sink and is not among the buildings the patch lowers")
	# VFX's clear query, behind the open lobby.
	PaneWorld._drawing = main.pane
	var face_z: float = tower.z + tower.d * 0.5
	var q_open: float = PaneWorld.clear_query(Vector3(tower.x, foot + 0.5 * fh, face_z))
	var q_above: float = PaneWorld.clear_query(Vector3(tower.x, o.y + 0.5 * fh, face_z))
	var q_fight: float = PaneWorld.clear_query(Vector3(tower.x, foot + 40.0, z_mid))
	var q_behind: float = PaneWorld.clear_query(Vector3(tower.x, foot + 40.0, z_mid - 300.0))
	PaneWorld._drawing = null
	var q_any: float = PaneWorld.clear_query(Vector3(tower.x, foot + 0.5 * fh, face_z))
	_expect(q_open == 0.0 and q_above == 1.0 and q_fight == 1.0 and q_behind == 1.0 and q_any == 0.0 and host.vfx.clear_query.is_valid() and float(host.vfx.clear_query.call(Vector3(tower.x, foot + 0.5 * fh, face_z))) == 0.0, "VFX's clear query behind the open lobby: a point on the lobby's face is hidden (%.0f), one on the wall above it is not (%.0f), nor one at the fight's depth (%.0f) or behind the fight (%.0f); the hub's callable answers the same" % [q_open, q_above, q_fight, q_behind])
	# Back in front: the hold, then the fade out.
	fz = [0.0, 0.0]
	var hold_ticks: int = int(RenderLook.OPEN_HOLD_S / DT)
	_ticks(hold_ticks - 3)
	var held: float = P.lobby_share(ti)
	most = 0.0
	turned = _ticks(240)
	took = _took(turned)
	_expect(held == 1.0 and most <= RenderLook.OPEN_CLOSE * budget + 1.0 and took >= fade_ticks and not P._open.has(ti) and _texel(ti).b == PlanetView.OPEN_SHUT and _texel(ti).g == 0.0, "the pair back in the front street: the lobby holds for %.2f s, then fades out at no more than %.0f pixels a tick (%.0f is half the budget) over %d ticks, and is shut" % [RenderLook.OPEN_HOLD_S, most, RenderLook.OPEN_CLOSE * budget, took])
	# Camera's request.
	fz = [z_mid, z_mid]
	_ticks(60)
	var was: float = P.lobby_share(ti)
	_pane_ticks(hold_ticks + 240, {"request": false})
	var shut: bool = not P._open.has(ti)
	_pane_ticks(120, {})
	_expect(was == 1.0 and shut and P.lobby_share(ti) == 1.0, "Camera's request off: nothing is asked and the lobby shuts; on again, it opens")
	# Camera's cut flag: in front (shut), then behind with a cut on the next frame.
	fz = [0.0, 0.0]
	_ticks(hold_ticks + 240)
	var shut2: bool = not P._open.has(ti)
	fz = [z_mid, z_mid]
	_ticks(1)
	var part: float = P.lobby_share(ti)
	_pane_ticks(1, {"cut": true})
	_expect(shut2 and part > 0.0 and part < 0.2 and P.lobby_share(ti) == 1.0, "Camera's cut flag: one tick after the pair is behind the tower %.0f%% of its lobby is through; on a cut the next frame all of it is" % (100.0 * part))
	# The pair moved along the street between two ticks, under a camera that is already where they now stand (a seek, a
	# tool's pose): the patch's ends are put on them, not walked there by the budget.
	var jump: float = 12000.0
	fx = [tower.x - jump - 60.0, tower.x - jump + 60.0]
	fz = [0.0, 0.0]
	host.cam.x = SimWrap.wrap(tower.x - jump)
	_settle()
	var had: bool = (main.pane.patch as Dictionary).has("wa")
	fx = [tower.x - 60.0, tower.x + 60.0]
	fz = [z_mid, z_mid]
	host.cam.x = tower.x
	_ticks(1)
	var pj: Dictionary = main.pane.patch
	var end_off: float = maxf(absf((pj["wa"] as Vector3).x), absf((pj["wb"] as Vector3).x)) if pj.has("wa") else INF
	_ticks(40)
	_expect(had and end_off < 400.0 and P.lobby_share(ti) == 1.0, "the pair moved %.0f units along the street between two ticks under a camera already there: the patch's ends are within %.0f units of the camera on that frame, and the lobby opens" % [jump, end_off])
	# Over the lobby's ceiling: the patch takes the tower.
	lift = o.y - foot + 80.0
	most = 0.0
	turned = _ticks(180)
	took = _took(turned)
	var p_up: float = P.patch_share(ti)
	var k_up: float = P.lobby_share(ti)
	var a_up: float = _texel(ti).a
	lift = 0.0
	_ticks(int(RenderLook.PATCH_HOLD_S / DT) + 120)
	_expect(p_up == 1.0 and a_up == 1.0 and most <= budget + 1.0 and took > 1 and P.patch_share(ti) == 0.0 and _texel(ti).a == 0.0 and P.lobby_share(ti) == 1.0, "the pair lifted %.0f units, over the lobby's ceiling: the tower takes its share of the patch, at most %.0f pixels a tick (the lobby is %.0f%% open meanwhile); back on the ground it gives the share up and its lobby is open" % [o.y - foot + 80.0, most, 100.0 * k_up])
	# Damaged while its lobby is open. By the switch the lobby stays (the shader shows the stage) or goes at once. A
	# lobby floor cleared: the patch, either way.
	WorldStructures.stage(tower)   # loads the stages' thresholds
	var at: Array = WorldStructures._hpAt
	var hp_was: float = tower.hp
	var mask_was: int = int(tower.fmask)
	var stages: Array = []
	var kept: bool = true
	var gone: bool = true
	for frac in [(float(at[0]) + float(at[1])) * 0.5, (float(at[1]) + float(at[2])) * 0.5, float(at[2]) * 0.5]:
		tower.hp = tower.maxhp * float(frac)
		_ticks(2)
		var k2: float = P.lobby_share(ti)
		_ticks(120)
		stages.append(WorldStructures.stage(tower))
		kept = kept and PlanetView.lobby_ok(tower) and P.lobby_share(ti) == 1.0 and P.patch_share(ti) == 0.0
		gone = gone and not PlanetView.lobby_ok(tower) and P.lobby_share(ti) == 0.0 and P.patch_share(ti) == 1.0 and (stages.size() > 1 or k2 < 1.0)
	tower.hp = hp_was
	_ticks(hold_ticks + 240)
	var back: bool = P.lobby_share(ti) == 1.0 and P.patch_share(ti) == 0.0
	_expect(stages == [1, 2, 3] and back and (kept if RenderLook.OPEN_DAMAGED else gone), "the tower damaged to stages %s while its lobby is open, with RenderLook.OPEN_DAMAGED %s: %s; whole again (the tool's own state), its lobby is open" % [str(stages), "on" if RenderLook.OPEN_DAMAGED else "off", "the lobby stays open at each and the tower takes no share of the patch" if RenderLook.OPEN_DAMAGED else "the lobby starts to shut on the first tick and is shut, and the tower takes the patch"])
	tower.fmask = mask_was & ~1   # the ground floor cleared (the tool's own state)
	_ticks(2)
	var k_first: float = P.lobby_share(ti)
	_ticks(120)
	var k_cut: float = P.lobby_share(ti)
	var p_cut: float = P.patch_share(ti)
	fz = [0.0, 0.0]
	_ticks(hold_ticks + 240)
	fz = [z_mid, z_mid]
	_ticks(120)
	_expect(not PlanetView.lobby_ok(tower) and k_first < 1.0 and k_cut == 0.0 and p_cut == 1.0 and P.lobby_share(ti) == 0.0 and P.patch_share(ti) == 1.0 and _texel(ti).g == 0.0, "the tower's ground floor cleared by a brunt: the lobby starts to shut at once (%.0f%% two ticks on) and is shut, the tower takes the patch, and with the pair gone and back behind it, it does not open" % (100.0 * k_first))
	# What holds a cleared floor up: the core's state by the hit points, on the tower's own texel.
	var wi: int = (P._inst[ti] as PackedInt32Array)[0]
	var fr0: Color = (P._win[0] as Image).get_pixel(wi, 4)
	tower.hp = tower.maxhp * (RenderLook.CORE_HP.x - 0.05)
	_ticks(2)
	var fr1: Color = (P._win[0] as Image).get_pixel(wi, 4)
	tower.hp = tower.maxhp * (RenderLook.CORE_HP.y - 0.05)
	_ticks(2)
	var fr2: Color = (P._win[0] as Image).get_pixel(wi, 4)
	tower.hp = hp_was
	tower.fmask = mask_was
	_ticks(2)
	var frame_ok: bool = fr0.r == 0.0 and fr0.g == 0.0 and fr1.g == 1.0 and fr2.g == 2.0 and (P._win[0] as Image).get_pixel(wi, 4).g == 0.0
	if stepped != null:
		# A stepped tower: its skirts are outermost from the ground, its core only above the taller skirt.
		var sps: Array = P._parts[int(stepped.idx)]
		var tops: Array = []
		for j in range(sps.size()):
			if (int(sps[j][RenderShapes.FLAGS]) & (RenderShapes.ROOF | RenderShapes.PLAIN)) == 0 and float(sps[j][RenderShapes.Y0]) <= 0.0:
				tops.append([float(sps[j][RenderShapes.W]), float(sps[j][RenderShapes.Y1]), RenderShapes.outer_from(sps, j)])
		tops.sort_custom(func(p, q): return p[0] > q[0])
		frame_ok = frame_ok and tops.size() == 3 and tops[0][2] == 0.0 and tops[1][2] == tops[0][1] and tops[2][2] == tops[1][1]
		for j in range(sps.size()):
			frame_ok = frame_ok and absf((P._win[0] as Image).get_pixel((P._inst[int(stepped.idx)] as PackedInt32Array)[j], 4).r - RenderShapes.outer_from(sps, j)) < 0.5
	_expect(frame_ok, "what holds a cleared floor up: the tower's wall is its outermost from the ground; its core reads whole, cracked under %.0f%% of its hit points and broken under %.0f%%; a stepped tower's widest skirt is outermost from the ground, the next from the first one's top, its core from the second's" % [100.0 * RenderLook.CORE_HP.x, 100.0 * RenderLook.CORE_HP.y])
	# Camera's cut flag, from the frame's clear to the pane's request.
	var given: Dictionary = {"only": 1, "radius_px": 40.0}
	var with_cut: Dictionary = PaneWorld.request(given, {"cut": true, "p": 0.2})
	_expect(with_cut.get("cut", false) == true and int(with_cut["only"]) == 1 and not given.has("cut") and PaneWorld.request(given, {"cut": false}) == given and PaneWorld.request(given, null) == given and PaneWorld.request(given, {}) == given, "Camera's cut flag: a pane's request carries `cut` when the frame's clear says so, keeps the rest of its request, and the frame's own dictionary is not changed; with no cut, or no clear, the request is as given")
	fz = [0.0, 0.0]
	_ticks(hold_ticks + 240)
	# A stepped tower: its shell at the street carries the colonnade.
	if stepped != null:
		var si: int = int(stepped.idx)
		fx = [stepped.x - 60.0, stepped.x + 60.0]
		fz = [z_mid, z_mid]
		_settle(120)
		var ps: Array = P._parts[si]
		var sh: int = RenderShapes.shell(ps)
		var widest: bool = true
		var marks: bool = true
		for j in range(ps.size()):
			var pj2: Array = ps[j]
			if float(pj2[RenderShapes.Y0]) <= 0.0 and (int(pj2[RenderShapes.FLAGS]) & RenderShapes.ROOF) == 0 and absf(float(pj2[RenderShapes.X])) <= 1.0 and absf(float(pj2[RenderShapes.Z])) <= 1.0:
				widest = widest and float(pj2[RenderShapes.W]) * float(pj2[RenderShapes.D]) <= float(ps[sh][RenderShapes.W]) * float(ps[sh][RenderShapes.D])
			marks = marks and (_texel(si, j).g == (1.0 if j == sh else -1.0))
		var wt: Color = (P._win[0] as Image).get_pixel((P._inst[si] as PackedInt32Array)[0], 3)
		_expect(P.lobby_share(si) == 1.0 and widest and marks and sh != 0 and absf(wt.b - 0.5 * float(ps[sh][RenderShapes.W])) < 0.01 and absf(wt.a - 0.5 * float(ps[sh][RenderShapes.D])) < 0.01, "a stepped tower (%s, %d parts): its lobby is open, its widest part on the ground is the shell that carries the colonnade (part %d, not the core), every other part is marked as inside it, and each part knows the shell's footprint (%.0f by %.0f)" % ["a landmark" if int(stepped.landmark) != 0 else "plain", ps.size(), sh, 2.0 * wt.b, 2.0 * wt.a])
	else:
		_expect(true, "(no stepped tower in the front block of this world: the shell is not checked)")
	# Behind a low building.
	fx = [low.x - 50.0, low.x + 50.0]
	fz = [z_mid, z_mid]
	_settle(240)
	var li: int = int(low.idx)
	var pt: Dictionary = main.pane.patch
	var hole = P._bld_mat.get_shader_parameter("hole")
	var hw: float = (hole[0] as Vector4).w if hole is Array and (hole as Array).size() > 0 else 0.0
	_expect(not P.opens_floors(li) and not P._open.has(li) and _texel(li).b == PlanetView.OPEN_OFF and pt.has("wa") and hw > 0.0, "behind a low building (%s, %d floors) in the middle street: it has no lobby; the patch is handed to the blocks' material (radius %.0f pixels)" % [str(low.shape), int(low.floors), hw])
	PaneWorld._drawing = main.pane
	var lz: float = low.z + low.d * 0.5
	var q_patch: float = PaneWorld.clear_query(Vector3(low.x, WorldTerrain.groundY(S, low.x) + 40.0, lz))
	var q_own: float = PaneWorld.clear_query(Vector3(low.x, WorldTerrain.groundY(S, low.x) + 40.0, z_mid))
	PaneWorld._drawing = null
	_expect(q_patch < 0.5 and q_own == 1.0, "behind the low building a thing on its face in front of the fight, inside the patch, is hidden (%.2f left), and one at the fight's depth is not (%.0f)" % [q_patch, q_own])
	# Camera's near-clip rule: the tool moves the low building toward the lens in its own state.
	var eye_n: Vector3 = main.pane.cam_rig.position
	fx = [low.x - 50.0, low.x + 50.0]
	fz = [0.0, 0.0]
	var keep: Array = [low.row, low.z, tower.row, tower.z, tower.x]
	low.z = eye_n.z - 0.5 * (RenderLook.NEAR_CLIP.x + RenderLook.NEAR_CLIP.y) - low.d * 0.5
	low.row = 0.0
	tower.z = low.z
	tower.row = 0.0
	tower.x = SimWrap.wrap(low.x + 0.5 * (low.w + tower.w) + 60.0)
	for p in main.all_panes():
		p.build(S)
	_settle(120)
	var sink_ticks: int = int((RenderLook.PATCH_SINK_S * 2.0 + RenderLook.PATCH_HOLD_S) / DT) + 30
	_ticks(sink_ticks)
	var eye2: Vector3 = main.pane.cam_rig.position
	var d_low: float = eye2.z - (low.z + low.d * 0.5)
	var stub_y: float = _texel(li).r
	var foot_low: float = P._top[li] - WorldStructures.curH(low)
	var as_stub: bool = P._stub[li] == 1.0 and not P._gone.has(li) and absf(stub_y - (foot_low + RenderLook.STUB_H)) < 0.5
	low.z = eye2.z - 0.5 * RenderLook.NEAR_CLIP.x - low.d * 0.5
	for p in main.all_panes():
		p.build(S)
	_settle(120)
	_ticks(sink_ticks)
	var d_low2: float = main.pane.cam_rig.position.z - (low.z + low.d * 0.5)
	var gone_y: float = _texel(li).r
	var foot2: float = P._top[li] - WorldStructures.curH(low)
	_expect(d_low > RenderLook.NEAR_CLIP.x and d_low < RenderLook.NEAR_CLIP.y and as_stub and d_low2 < RenderLook.NEAR_CLIP.x and float(P._gone.get(li, 0.0)) == 1.0 and gone_y < foot2 and P._stub[ti] == 0.0 and not P._gone.has(ti), "Camera's near-clip rule: a low building %.0f units from the lens stands as its stub, and %.0f units from it is under its footing; a tower as near is neither" % [d_low, d_low2])
	low.row = keep[0]
	low.z = keep[1]
	tower.row = keep[2]
	tower.z = keep[3]
	tower.x = keep[4]
	_expect(not both, "on every tick of all of it, no tall building sinks, and no building without a lobby opens one")
	print("open check %s" % ("passed" if fails == 0 else "FAILED: %d" % fails))
	quit(0 if fails == 0 else 1)
