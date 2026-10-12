extends SceneTree
## The foreground row's patch (headless, through the real main scene): what PaneWorld._row0_patch hands the shader and
## the planet view (RenderLook.PATCH_*; docs/rendering/foreground-patch.md). No picture is judged here.
## - with the data as it is (no foreground row) there is no patch and nothing is lowered;
## - with a house standing in the foreground row (the tool moves one there in its own state):
##   a small skirmish behind it has a patch that holds both fighters in its solid part, with the radius of the rule,
##   under the size that lowers buildings, and the house stands whole;
## - a fighter suddenly far away: the patch reaches him by growing no more than PATCH_AREA_TICK pixels a tick, and once
##   it is big the house under it sinks, no faster than PATCH_SINK_S allows;
## - a reach asked for and dropped (a fighter's speed for a few ticks) is held for PATCH_HOLD_S before it shrinks;
## - the fight small again: the house does not stand again inside the hold, and then rises no faster than PATCH_RISE_S.
##   godot --headless --path . --script res://render/tools/patch_check.gd

const DT: float = 1.0 / 60.0

var main: Node
var fails: int = 0
var fx: Array = [0.0, 0.0]
var fy: float = 0.0


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


## One tick with the fighters held where the tool has them (vx: the second fighter's speed, for the patch's reach).
func _tick(vx: float = 0.0) -> void:
	var host: SimHost = main.host
	var S: SimState = host.S
	for i in range(2):
		var f = S.fighters[i]
		f.x = SimWrap.wrap(fx[i])
		f.y = fy
		f.vx = vx if i == 1 else 0.0
		f.vy = 0.0
	host.acc = DT * 0.9999
	main.frame(DT)
	for i in range(2):
		S.fighters[i].x = SimWrap.wrap(fx[i])
		S.fighters[i].y = fy
		S.fighters[i].vx = vx if i == 1 else 0.0


## The patch's area in pixels at the register's scale (1024 by 768).
func _area(p: Dictionary, vp: Vector2) -> float:
	var r: float = float(p["r"])
	return (2.0 * r * (p["a"] as Vector2).distance_to(p["b"]) + PI * r * r) * (1024.0 * 768.0) / (vp.x * vp.y)


## How far a point is from the patch's axis, as a share of its radius.
func _in(p: Dictionary, q: Vector2) -> float:
	var a: Vector2 = p["a"]
	var ab: Vector2 = (p["b"] as Vector2) - a
	var t: float = clampf((q - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
	return (q - a - ab * t).length() / maxf(float(p["r"]), 0.001)


func _chests() -> Array:
	var out: Array = []
	for v in main.pane.fighter_views:
		out.append(main.pane.cam_rig.unproject_position(v.position + Vector3(0.0, FighterView.HEIGHT * 0.5, 0.0)))
	return out


func _run() -> void:
	await process_frame
	main.started = true
	# The data as it is: no foreground row.
	main.start_match(4, {"p1": true, "p2": true}, {"intro": "skip"})
	var host: SimHost = main.host
	var S: SimState = host.S
	var any: bool = false
	for k in range(240):
		host.acc = DT * 0.9999
		main.frame(DT)
		any = any or not (main.pane.patch as Dictionary).is_empty()
	_expect(not main.planet.has_row0() and not any and (main.planet._stub_hold as Dictionary).is_empty(), "the data as it is has no foreground row: no patch is made and nothing is lowered")
	# A house in the foreground row (the tool's own state), a small skirmish behind it.
	main.start_match(4, {"p1": false, "p2": false}, {"intro": "skip"})
	host = main.host
	S = host.S
	var house = null
	for b in S.buildings:
		if int(b.row) == 1 and str(b.kind) == "house" and (house == null or b.h < house.h):
			house = b
	if house == null:
		_expect(false, "this world has a house to stand in the foreground")
		quit(1)
		return
	house.row = 0.0
	house.z = 750.0
	for p in main.all_panes():
		p.build(S)
	if main.split_view != null and main.split_view.is_attached():
		main.split_view.detach()
	var P: PlanetView = main.planet
	var bi: int = int(house.idx)
	fx = [house.x - 90.0, house.x + 90.0]
	fy = WorldTerrain.groundY(S, house.x) + 2.0
	main.pane.snap_occlusion()
	for k in range(90):
		_tick()
	var vp: Vector2 = main.get_viewport().get_visible_rect().size
	var pt: Dictionary = main.pane.patch
	var ch: Array = _chests()
	var tall: float = absf((main.pane.cam_rig.unproject_position(main.pane.fighter_views[0].position + Vector3(0.0, FighterView.HEIGHT, 0.0)) as Vector2).y - (main.pane.cam_rig.unproject_position(main.pane.fighter_views[0].position) as Vector2).y)
	var small_ok: bool = P.has_row0() and not pt.is_empty()
	if small_ok:
		small_ok = _in(pt, ch[0]) <= RenderLook.PATCH_EDGE.x and _in(pt, ch[1]) <= RenderLook.PATCH_EDGE.x and absf(float(pt["r"]) - RenderLook.PATCH_BODY * tall) < 0.02 * tall and float(pt["size"]) < RenderLook.PATCH_BIG.x and (pt["sink"] as Dictionary).is_empty() and P._stub[bi] == 0.0
	_expect(small_ok, "a small skirmish behind a foreground house: one patch holds both fighters in its solid part, its radius %.1f of a fighter's height, %.0f square heights (under the %.0f that lowers a building), and the house stands whole" % [float(pt.get("r", 0.0)) / maxf(tall, 1.0), float(pt.get("size", 0.0)), RenderLook.PATCH_BIG.x])
	# A fighter suddenly far away: growth by area, then the house sinks.
	fx[1] = house.x + 90.0 + 760.0
	var worst: float = 0.0
	var last: float = _area(pt, vp)
	var sink_rate: float = 0.0
	var prev_stub: float = P._stub[bi]
	var reached: int = -1
	for k in range(150):
		_tick()
		pt = main.pane.patch
		var a: float = _area(pt, vp)
		worst = maxf(worst, a - last)
		last = a
		sink_rate = maxf(sink_rate, P._stub[bi] - prev_stub)
		prev_stub = P._stub[bi]
		ch = _chests()
		if reached < 0 and _in(pt, ch[1]) <= RenderLook.PATCH_EDGE.x:
			reached = k
	_expect(worst <= RenderLook.PATCH_AREA_TICK * 1.05 and reached >= 0 and float(pt["size"]) > RenderLook.PATCH_BIG.x and P._stub[bi] > 0.2 and sink_rate <= DT / RenderLook.PATCH_SINK_S * 1.05, "a fighter moved 760 units off: the patch reaches him in %d ticks, growing at most %.0f pixels a tick (%.0f allowed, the analyser's area threshold is 21,824); at %.0f square heights the house under it has sunk %.0f%%, never faster than %.2f s for the whole of it" % [reached, worst, RenderLook.PATCH_AREA_TICK, float(pt["size"]), 100.0 * P._stub[bi], RenderLook.PATCH_SINK_S])
	# A reach asked for and dropped: held, then let go.
	var s0: float = float(pt["size"])
	for k in range(8):
		_tick(2400.0)
	_tick()   # his speed gone: the sim has put him back where the tool holds him, and only the reach is left
	var s_reach: float = float(main.pane.patch["size"])
	var held: bool = true
	for k in range(int(RenderLook.PATCH_HOLD_S / DT) - 6):
		_tick()
		held = held and float(main.pane.patch["size"]) >= s_reach - 0.01
	for k in range(120):
		_tick()
	_expect(s_reach > s0 + 0.2 and held and float(main.pane.patch["size"]) < s_reach - 0.2, "a reach asked for and dropped (a speed of 2,400 for eight ticks): %.1f to %.1f square heights, held for %.2f s, then let go (%.1f)" % [s0, s_reach, RenderLook.PATCH_HOLD_S, float(main.pane.patch["size"])])
	# Small again: the house holds, then stands.
	fx[1] = house.x + 90.0
	var top: float = P._stub[bi]
	var early: bool = true
	var rise: float = 0.0
	prev_stub = top
	for k in range(int(RenderLook.PATCH_HOLD_S / DT) - 4):
		_tick()
		early = early and P._stub[bi] >= prev_stub - 1.0e-6
		prev_stub = P._stub[bi]
	for k in range(260):
		_tick()
		rise = maxf(rise, prev_stub - P._stub[bi])
		prev_stub = P._stub[bi]
	_expect(top > 0.2 and early and P._stub[bi] == 0.0 and rise <= DT / RenderLook.PATCH_RISE_S * 1.05 and (main.pane.patch["sink"] as Dictionary).is_empty(), "the fight small again: the house does not stand again inside the hold (%.2f s), then rises over %.1f s at the fastest and stands whole" % [RenderLook.PATCH_HOLD_S, RenderLook.PATCH_RISE_S])
	print("patch check %s" % ("passed" if fails == 0 else "FAILED (%d)" % fails))
	quit(0 if fails == 0 else 1)
