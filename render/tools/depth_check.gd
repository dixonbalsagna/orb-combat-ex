extends SceneTree
## Fighters in depth (headless, through the real main scene; docs/rendering/fighters-in-depth.md): what the renderer
## places off the fighter plane, and that a match with depth off is drawn as it always was. No picture is judged here.
## - depth off: the pair's mark is never set, and a beam's prisms are placed by the old formula, to the bit;
## - depth on (the tool's own match, `"depth": true`): a fighter is drawn at the sim's depth and so is his shadow;
##   the two at different depths show their lane cues; a close pair near the ground at different depths has the pair's
##   mark from one to the other, and it goes when they are apart, level in depth, or in the air;
## - a beam in depth (the sim's Beam.oz and zs) lies along its true line: its middle and its axis are the line's;
## - a particle is drawn at the depth it was made at (SimFxView.Part.z) in a match with depth on, and on the plane with
##   depth off whatever depth it carries;
## - a fighter in the middle street behind a block counts as hidden (so the pane opens the block), and one standing in
##   a crossing, seen down the avenue, does not.
##   godot --headless --path . --script res://render/tools/depth_check.gd

const DT: float = 1.0 / 60.0
const NEAR: float = 4.0   # the sim moves a held fighter a little inside its own tick (the depth magnet, the carry)

var main: Node
var fails: int = 0
var fx: Array = [0.0, 0.0]
var fz: Array = [0.0, 0.0]
var lift: Array = [0.0, 0.0]


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
		f.y = WorldTerrain.groundY(S, f.x) + 2.0 + float(lift[i])
		f.vx = 0.0
		f.vy = 0.0


## n ticks with the fighters held where the tool has them (the sim may move them inside a tick; they are put back).
func _ticks(n: int) -> void:
	var host: SimHost = main.host
	for k in range(n):
		_hold()
		host.acc = DT * 0.9999
		main.frame(DT)
		_hold()
	main.render_view(1.0)


func _mark() -> float:
	var c = main.planet._terrain_mat.get_shader_parameter("pair_mark_col")
	return (c as Color).a if c is Color else 0.0


func _one_view() -> void:
	if main.split_view != null and main.split_view.is_attached():
		main.split_view.detach()


func _run() -> void:
	await process_frame
	main.started = true
	# --- depth off: nothing of this is drawn
	main.start_match(4, {"p1": true, "p2": true}, {"intro": "skip"})
	var host: SimHost = main.host
	var set_any: bool = false
	for k in range(300):
		host.acc = DT * 0.9999
		main.frame(DT)
		set_any = set_any or main.planet._terrain_mat.get_shader_parameter("pair_mark_col") != null or main.planet._pair_on
	_expect(not host.S.depthOn and not set_any, "depth off, a real match of 300 ticks: the pair's mark is never set")
	var bv: BeamView = main.pane.beams
	var a := Vector2(-140.0, 260.0)
	var e := Vector2(910.0, 388.0)
	bv._beam(0, a, e, 30.0, Color.WHITE, 1.0, 1.15, true)
	var same: bool = true
	var d: Vector2 = e - a
	var u: Vector2 = d / d.length()
	for j in range(BeamView.LAYERS.size()):
		var th: float = 30.0 * BeamView.LAYERS[j][0] + BeamView.LAYERS[j][1] / 1.15
		var old := Transform3D(Basis(Vector3(u.y, -u.x, 0.0) * th, Vector3(u.x, u.y, 0.0) * (d.length() + th * 0.5), Vector3(0.0, 0.0, th)), Vector3((a.x + e.x) * 0.5, (a.y + e.y) * 0.5, RenderLook.Z_BEAMS))
		same = same and (bv._pool[0][j] as MeshInstance3D).transform == old
	_expect(same, "a beam with no depth is placed by the old formula, to the bit (%d layers)" % BeamView.LAYERS.size())
	# --- a beam in depth
	var za: float = -40.0
	var ze: float = -640.0
	bv._beam(0, a, e, 30.0, Color.WHITE, 1.0, 1.15, true, za, ze)
	var ok: bool = true
	var a3 := Vector3(a.x, a.y, RenderLook.Z_BEAMS + za)
	var e3 := Vector3(e.x, e.y, RenderLook.Z_BEAMS + ze)
	for j in range(BeamView.LAYERS.size()):
		var t: Transform3D = (bv._pool[0][j] as MeshInstance3D).transform
		var ax: Vector3 = t.basis.y.normalized()
		ok = ok and t.origin.distance_to((a3 + e3) * 0.5) < 0.01 and ax.distance_to((e3 - a3).normalized()) < 0.0001
		ok = ok and absf(t.basis.x.dot(t.basis.y)) < 0.01 and absf(t.basis.z.dot(t.basis.y)) < 0.01 and absf(t.basis.x.dot(t.basis.z)) < 0.01
		ok = ok and t.basis.y.length() >= a3.distance_to(e3) and t.basis.determinant() > 0.0
		ok = ok and is_equal_approx(t.basis.x.length(), t.basis.z.length()) and t.basis.x.z == 0.0
	_expect(ok, "a beam in depth (from %.0f to %.0f) lies along its true line: each layer's middle and axis are the line's, its section square and across the screen" % [za, ze])
	# --- a particle at a depth
	var pv: ParticleView = main.pane.particles
	var part := SimFxView.Part.new()
	part.type = "spark"
	part.x = host.camera_x(1.0)
	part.y = 200.0
	part.vx = 100.0
	var fake := SimFxView.new(1)
	fake.parts = [part]
	part.z = -300.0
	var was_deep: bool = pv.deep
	pv.deep = false
	pv.update(fake, null, host.camera_x(1.0), 1.15, 4000.0, [])
	var flat: float = pv._buf[11]
	pv.deep = true
	pv.update(fake, null, host.camera_x(1.0), 1.15, 4000.0, [])
	_expect(pv.count == 1 and not was_deep and flat == RenderLook.Z_PARTICLES and is_equal_approx(pv._buf[11], RenderLook.Z_PARTICLES - 300.0), "a particle made at depth -300: with depth off it is drawn on the plane as ever (%.0f), with depth on at its depth (%.0f); the pane had depth off" % [flat, pv._buf[11]])
	pv.deep = was_deep
	# --- depth on: the tool's own match
	main.start_match(4, {"p1": false, "p2": false}, {"intro": "skip", "depth": true})
	host = main.host
	var S: SimState = host.S
	_expect(S.depthOn, "the tool's match has depth on")
	_one_view()
	# A spot in the middle of a downtown block, and a crossing.
	var lanes: PackedFloat32Array = S.lanes
	var streets: Array = []
	for k in range(int(lanes[1])):
		var o: int = int(lanes[10]) + 4 * k
		if int(lanes[o + 2]) == 0:
			streets.append(0.5 * (lanes[o] + lanes[o + 1]))
	var tower = null
	for b in S.buildings:
		if int(b.row) == 1 and str(b.kind) == "tower" and int(b.landmark) == 0 and (tower == null or b.w > tower.w):
			tower = b
	var av: Array = RenderLanes.avenues(lanes, 64)
	if streets.size() < 2 or tower == null or av.is_empty():
		_expect(false, "this world has two streets, a tower in the front block and an avenue (%d, %s, %d)" % [streets.size(), str(tower != null), av.size()])
		quit(1)
		return
	var z_mid: float = streets[1]
	fx = [tower.x - 60.0, tower.x + 60.0]
	fz = [22.0, -22.0]
	lift = [0.0, 0.0]
	main.pane.snap_occlusion()
	_ticks(30)
	var P: PaneWorld = main.pane
	var placed: bool = true
	var drawn: Array = []
	for i in range(2):
		var v: FighterView = P.fighter_views[i]
		drawn.append(v.position.z)
		placed = placed and absf(v.position.z - host.fighter_z(i, 1.0)) < 0.001 and absf(v.position.z - float(fz[i])) < NEAR and (P.shadows[i] as MeshInstance3D).position.z == v.position.z
	_expect(placed, "depth on: each fighter is drawn at the sim's depth and his shadow lies at it (set to %.0f and %.0f, drawn at %.1f and %.1f after the sim's own tick)" % [fz[0], fz[1], drawn[0], drawn[1]])
	var pm = main.planet._terrain_mat.get_shader_parameter("pair_mark")
	var ends_ok: bool = pm is Vector4 and absf(SimWrap.sdx((pm as Vector4).x, fx[0])) < NEAR and absf((pm as Vector4).y - float(drawn[0])) < 0.001 and absf(SimWrap.sdx((pm as Vector4).z, fx[1])) < NEAR and absf((pm as Vector4).w - float(drawn[1])) < 0.001
	_expect(is_equal_approx(_mark(), RenderLook.PAIR_MARK_ALPHA) and ends_ok, "a close pair on the ground at different depths has the pair's mark at full, from one fighter's place to the other's (strength %.2f)" % _mark())
	fz = [0.0, 0.0]
	_ticks(2)
	var falling: float = _mark()
	_ticks(int(RenderLook.PAIR_MARK_OUT_S / DT) + 4)
	_expect(falling > 0.0 and falling < RenderLook.PAIR_MARK_ALPHA and _mark() == 0.0, "level in depth, the mark goes over %.1f s and not at once (%.2f after two ticks, then %.2f)" % [RenderLook.PAIR_MARK_OUT_S, falling, _mark()])
	fz = [22.0, -22.0]
	_ticks(int(RenderLook.PAIR_MARK_IN_S / DT) + 4)
	var back: float = _mark()
	lift = [0.0, RenderLook.PAIR_MARK_H + 80.0]
	_ticks(int(RenderLook.PAIR_MARK_OUT_S / DT) + 4)
	var air: float = _mark()
	lift = [0.0, 0.0]
	fx = [tower.x - 60.0, tower.x + RenderLook.PAIR_MARK_SEP + 40.0]
	_ticks(int(RenderLook.PAIR_MARK_OUT_S / DT) + 4)
	_expect(is_equal_approx(back, RenderLook.PAIR_MARK_ALPHA) and air == 0.0 and _mark() == 0.0, "it comes back when they are angled again (%.2f), and goes with one of them in the air (%.2f) or the two apart (%.2f)" % [back, air, _mark()])
	# The lane cues.
	fx = [tower.x - 200.0, tower.x + 200.0]
	fz = [0.0, -(RenderLook.LANE_CUE_DZ + 60.0)]
	_ticks(int(RenderLook.LANE_CUE_IN_S / DT) + 4)
	var lc = main.planet._terrain_mat.get_shader_parameter("lane_cue")
	_expect(lc is Array and (lc as Array).size() == 2 and (lc[0] as Vector4).w > 0.0 and (lc[1] as Vector4).w > 0.0 and absf((lc[1] as Vector4).y - (P.fighter_views[1] as FighterView).depth) < 0.001 and absf((lc[0] as Vector4).y - (P.fighter_views[0] as FighterView).depth) < 0.001, "two fighters at different depths each have a lane cue, at the depth he is drawn at")
	# Hidden behind the block, and clear down an avenue.
	fx = [tower.x - 60.0, tower.x + 60.0]
	fz = [z_mid, z_mid]
	main.pane.snap_occlusion()
	_ticks(20)
	var hid: Array = [P.occluded[0], P.occluded[1]]
	var small: float = (P.cam_rig.unproject_position((P.fighter_views[0] as FighterView).position).y - P.cam_rig.unproject_position((P.fighter_views[0] as FighterView).position + Vector3(0.0, 75.0, 0.0)).y)
	var ax0: float = 0.5 * (float((av[0] as Vector4).x) + float((av[0] as Vector4).y))
	for v4 in av:
		var c: float = 0.5 * (float((v4 as Vector4).x) + float((v4 as Vector4).y))
		if absf(SimWrap.sdx(tower.x, c)) < absf(SimWrap.sdx(tower.x, ax0)):
			ax0 = c
	fx = [ax0 - 45.0, ax0 + 45.0]
	main.pane.snap_occlusion()
	_ticks(120)
	_expect(hid[0] and hid[1] and not P.occluded[0] and not P.occluded[1], "in the middle street (depth %.0f) behind a tower both fighters count as hidden, so the pane opens it; in the crossing of the nearest avenue, seen down it, neither does" % z_mid)
	print("     at depth %.0f a fighter of 75 units is %.0f pixels tall at 720p (the camera does not follow depth yet)" % [z_mid, small])
	print("depth check %s" % ("passed" if fails == 0 else "FAILED: %d" % fails))
	quit(0 if fails == 0 else 1)
