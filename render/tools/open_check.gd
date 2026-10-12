extends SceneTree
## Open floors (headless, through the real main scene; RenderLook.OPEN_*, docs/rendering/open-floors.md): what the pane
## asks of the planet view and what the planet view hands the building shader. No picture is judged here.
## - depth off, a real match: no building is of the kind that opens floors, nothing opens, and every texel says so;
## - depth on (the tool's own match): a building opens floors by its floors as built and by nothing else;
## - a pair in the front street in front of a tower: nothing opens;
## - the pair suddenly in the middle street behind the tower: the tower opens from the ground to a floor line above the
##   sight line to their heads, across its width, by no more than the area budget a tick, and it does not sink;
## - the pair back in the front street: the opening holds for OPEN_HOLD_S, then closes at no more than OPEN_CLOSE of
##   the budget a tick, and is shut;
## - Camera's request off: nothing is asked, and what was open closes;
## - behind a low building the low building does not open floors: the patch is handed to the blocks' material;
## - on every tick of all of it, no building both opens floors and sinks or is of the patch's kind.
##   godot --headless --path . --script res://render/tools/open_check.gd

const DT: float = 1.0 / 60.0

var main: Node
var fails: int = 0
var fx: Array = [0.0, 0.0]
var fz: Array = [0.0, 0.0]
var both: bool = false          # a building was seen doing both
var most: float = 0.0           # the most pixels the openings turned in a tick since it was last cleared


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
		f.y = WorldTerrain.groundY(S, f.x) + 2.0
		f.vx = 0.0
		f.vy = 0.0


## n ticks with the fighters held where the tool has them. Returns the openings' turned pixels, tick by tick.
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
			if P.opens_floors(bi) and P._stub[bi] > 0.0:
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


func _texel(bi: int) -> Color:
	var P: PlanetView = main.planet
	var st: Array = P._stub_tex0 if P._row0[bi] >= 0 else P._stub_tex
	return (st[0] as Image).get_pixel((P._inst[bi] as PackedInt32Array)[0], 0)


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
		var t: Color = _texel(bi)
		off = off and not P.opens_floors(bi) and t.g == 0.0 and t.b == PlanetView.OPEN_OFF
	_expect(not S.depthOn and not any and off, "depth off, a real match of 300 ticks: no building is of the kind that opens floors, nothing opens, and all %d buildings' texels say so" % S.buildings.size())
	# --- depth on
	main.start_match(4, {"p1": false, "p2": false}, {"intro": "skip", "depth": true})
	host = main.host
	S = host.S
	P = main.planet
	if main.split_view != null and main.split_view.is_attached():
		main.split_view.detach()
	var kinds: bool = true
	var n_open: int = 0
	for bi in range(S.buildings.size()):
		var b = S.buildings[bi]
		var k: bool = int(b.floors) >= RenderLook.OPEN_FLOORS_MIN
		n_open += 1 if k else 0
		kinds = kinds and P.opens_floors(bi) == k and _texel(bi).b == (PlanetView.OPEN_SHUT if k else PlanetView.OPEN_OFF)
	_expect(S.depthOn and kinds and n_open > 0 and n_open < S.buildings.size(), "depth on: a building opens floors by its floors as built (%d or more: %d of %d buildings), and its texel says which kind it is" % [RenderLook.OPEN_FLOORS_MIN, n_open, S.buildings.size()])
	var lanes: PackedFloat32Array = S.lanes
	var streets: Array = []
	for k in range(int(lanes[1])):
		var o: int = int(lanes[10]) + 4 * k
		if int(lanes[o + 2]) == 0:
			streets.append(0.5 * (lanes[o] + lanes[o + 1]))
	var tower = null
	var low = null
	for b in S.buildings:
		if int(b.row) != 1 or int(b.landmark) != 0:
			continue
		if int(b.floors) >= 10 and (tower == null or b.w > tower.w):
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
	# In front of the tower.
	fx = [tower.x - 60.0, tower.x + 60.0]
	fz = [0.0, 0.0]
	_settle()
	_expect(P._open.is_empty() and _texel(ti).b == PlanetView.OPEN_SHUT, "a pair in the front street in front of a tower: nothing opens")
	# Behind it, at once.
	fz = [z_mid, z_mid]
	most = 0.0
	var turned: PackedFloat32Array = _ticks(150)
	var took: int = 0
	for k in range(turned.size()):
		if turned[k] > 0.5:
			took = k + 1
	var o: Vector2 = P.open_now(ti)
	var foot: float = P._top[ti] - WorldStructures.curH(tower)
	var fh: float = tower.h / float(tower.floors)
	var eye: Vector3 = main.pane.cam_rig.position
	var zf: float = tower.z + tower.d * 0.5
	var need: float = -INF
	for v in main.pane.fighter_views:
		var head: Vector3 = (v as FighterView).position + Vector3(0.0, 75.0, 0.0)
		need = maxf(need, lerpf(head.y, eye.y, (zf - head.z) / (eye.z - head.z)))
	var floors_open: float = (o.y - foot) / fh
	var tx: Color = _texel(ti)
	_expect(absf(o.x - foot) < 0.01 and o.y >= need and o.y < P._top[ti] - fh and absf(floors_open - roundf(floors_open)) < 0.001 and tx.g == PlanetView.OPEN_GROUND and absf(tx.b - o.y) < 0.01, "the pair suddenly in the middle street behind the tower: it opens from the ground to a floor line (%d floors of %.0f units, to %.0f) above the sight line to their heads (%.0f), with %.0f of the tower standing over it" % [int(roundf(floors_open)), fh, o.y - foot, need - foot, P._top[ti] - o.y])
	_expect(most <= budget + 1.0 and took > 1, "it opens by area: at most %.0f pixels a tick (the budget is %.0f), over %d ticks" % [most, budget, took])
	_expect(P._stub[ti] == 0.0 and not (main.pane.patch as Dictionary).get("sink", {}).has(ti), "the tower does not sink and is not among the buildings the patch lowers")
	# Back in front: the hold, then the close.
	fz = [0.0, 0.0]
	var hold_ticks: int = int(RenderLook.OPEN_HOLD_S / DT)
	_ticks(hold_ticks - 3)
	var held: Vector2 = P.open_now(ti)
	most = 0.0
	turned = _ticks(240)
	took = 0
	for k in range(turned.size()):
		if turned[k] > 0.5:
			took = k + 1
	_expect(held.is_equal_approx(o) and most <= RenderLook.OPEN_CLOSE * budget + 1.0 and took > 1 and not P._open.has(ti) and _texel(ti).b == PlanetView.OPEN_SHUT and _texel(ti).g == 0.0, "the pair back in the front street: the opening holds for %.2f s, then closes at no more than %.0f pixels a tick (%.0f is half the budget) over %d ticks, and is shut" % [RenderLook.OPEN_HOLD_S, most, RenderLook.OPEN_CLOSE * budget, took])
	# Camera's request.
	fz = [z_mid, z_mid]
	_ticks(60)
	var was: Vector2 = P.open_now(ti)
	_pane_ticks(hold_ticks + 240, {"request": false})
	var shut: bool = not P._open.has(ti)
	_pane_ticks(120, {})
	_expect(was.y > was.x and shut and P.open_now(ti).y > P.open_now(ti).x, "Camera's request off: nothing is asked and the opening closes; on again, it opens")
	# Behind a low building.
	fx = [low.x - 50.0, low.x + 50.0]
	fz = [z_mid, z_mid]
	_settle(240)
	var li: int = int(low.idx)
	var pt: Dictionary = main.pane.patch
	var hole = P._bld_mat.get_shader_parameter("hole")
	var hw: float = (hole[0] as Vector4).w if hole is Array and (hole as Array).size() > 0 else 0.0
	_expect(not P.opens_floors(li) and not P._open.has(li) and _texel(li).b == PlanetView.OPEN_OFF and pt.has("wa") and hw > 0.0, "behind a low building (%s, %d floors) in the middle street: it does not open floors; the patch is handed to the blocks' material (radius %.0f pixels)" % [str(low.shape), int(low.floors), hw])
	_expect(not both, "on every tick of all of it, no building both opens floors and sinks, and none of the patch's kind opens floors")
	print("open check %s" % ("passed" if fails == 0 else "FAILED: %d" % fails))
	quit(0 if fails == 0 else 1)
