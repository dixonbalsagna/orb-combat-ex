extends SceneTree
## The rig reading places through the sim's frame (docs/camera/swing-view.md). Until Simulation's frame lands this makes its own, on
## the real rig and a real match: the line's frame turned about the pair by a test's angle, and a building posed as the sim would pose
## it. Nothing here writes the sim except what the check says it stages (a building's pose and a landmark's flag).
##   godot --headless --path . --script res://render/camera/tests/swing_places_check.gd
## Ends with `swing_places_check: N checks passed` or a line per failure.

const VW: float = 1280.0
const VH: float = 720.0

var fails: int = 0
var checks: int = 0
var rest: PackedFloat64Array = PackedFloat64Array([1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0])
var theta: float = 0.0
var pivot_x: float = 0.0


func _ok(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		fails += 1
		print("FAIL ", what)


## The rest line turned by theta about its point at pivot_x: the frame the sim would hold mid-swing.
func _turned(_S = null) -> PackedFloat64Array:
	var q: PackedFloat64Array = CamPlaces.on_line(rest, pivot_x)
	var h := Vector3(q[3], q[4], q[5])
	var sd: Vector3 = CamPlaces.side(rest)
	var c: float = cos(theta)
	var s: float = sin(theta)
	return PackedFloat64Array([q[0], q[1], q[2], c * h.x + s * sd.x, c * h.y + s * sd.y, c * h.z + s * sd.z, pivot_x])


func _rest_frame(_S = null) -> PackedFloat64Array:
	return rest


func _initialize() -> void:
	_math()
	_rig_same_at_rest()
	_rig_turned()
	CamPlaces.frame_source = Callable()
	CamPlaces.biome_source = Callable()
	if fails == 0:
		print("swing_places_check: %d checks passed" % checks)
	else:
		print("swing_places_check: %d of %d checks FAILED" % [fails, checks])
	quit(1 if fails > 0 else 0)


func _math() -> void:
	var r: float = CamPlaces.radius()
	# the line carries itself: a point on it reads its own distance, depth 0, either way round and across the seam
	for x in [0.0, 500.0, SimConst.W - 700.0, 0.25 * SimConst.W, 0.45 * SimConst.W]:
		var q: PackedFloat64Array = CamPlaces.on_line(rest, x)
		var v: Vector2 = CamPlaces.view_of(rest, 300.0, [q[0], q[1], q[2]])
		_ok(absf(v.x - SimWrap.sdx(300.0, x)) < 1.0e-3 and absf(v.y) < 1.0e-3, "a point on the line at %f reads %s" % [x, v])
	# a turn about the pivot is rigid at any radius and turns by its angle: the same as Rendering's frame uniform
	pivot_x = 1000.0
	var p := CamPlaces.on_line(rest, 4000.0)
	var pt: Array = [p[0], p[1], p[2]]
	for deg in [0.0, 30.0, 90.0, 137.0, 180.0, 360.0]:
		theta = deg_to_rad(deg)
		var v: Vector2 = CamPlaces.view_of(_turned(), 1000.0, pt)
		_ok(absf(v.length() - 3000.0) < 1.0e-3, "radius moved at %f degrees: %f" % [deg, v.length()])
		_ok(absf(v.x - 3000.0 * cos(theta)) < 1.0e-3 and absf(absf(v.y) - 3000.0 * absf(sin(theta))) < 1.0e-3, "wrong angle at %f: %s" % [deg, v])
	theta = deg_to_rad(90.0)
	var side_sign: float = CamPlaces.view_of(_turned(), 1000.0, pt).y
	_ok(side_sign < 0.0, "a heading turned toward the camera puts what lay ahead behind the plane: %f" % side_sign)
	# a thing without an anchor is where the sim poses it; one with its own point reads through the frame
	theta = 0.0
	var S: SimState = SimCore.createSim()
	var strip: Vector2 = CamPlaces.place(S, rest, 2000.0, {"x": 2500.0}, 2500.0, -1500.0)
	_ok(strip.distance_to(Vector2(500.0, -1500.0)) < 1.0e-6, "a posed building read %s" % strip)
	var own: Vector2 = CamPlaces.place(S, rest, 1000.0, {"anchor": pt}, 9999.0, 0.0)
	_ok(absf(own.x - 3000.0) < 1.0e-3 and absf(own.y) < 1.0e-3, "an anchor wasn't read through the frame: %s" % own)
	# the frame between two ticks, on Rendering's basis
	var f := SplitFrame.new()
	theta = 0.0
	pivot_x = 300.0
	f.place = _turned()
	var b: Dictionary = f.pane_basis(300.0)
	_ok(absf(Vector3(b.pv).dot(b.hd)) < 1.0e-6 and absf(Vector3(b.pv).dot(b.sd)) < 1.0e-6 and absf(Vector3(b.hd).dot(b.sd)) < 1.0e-6, "the basis isn't square")
	_ok(Vector3(b.hd).cross(b.pv).distance_to(b.sd) < 1.0e-5, "side isn't Rendering's head cross pivot")
	var f2 := SplitFrame.new()
	f2.vw = f.vw
	f2.vh = f.vh
	f2.cut = false
	theta = deg_to_rad(2.0)
	f2.place = _turned()
	var m: SplitFrame = SplitFrame.lerp_frames(f, f2, 0.5)
	theta = deg_to_rad(1.0)
	var want: PackedFloat64Array = _turned()
	_ok(Vector3(m.place[3], m.place[4], m.place[5]).distance_to(Vector3(want[3], want[4], want[5])) < 1.0e-3, "the frame between ticks is off")
	_ok(SplitFrame.new().pane_basis(0.0).is_empty(), "no frame should give no basis")
	theta = 0.0


## A frame that hasn't turned tells the rig what the strip does, near the fight: the same layouts on a real AI match.
func _rig_same_at_rest() -> void:
	CamPlaces.frame_source = Callable(self, "_rest_frame")
	CamPlaces.biome_source = Callable(self, "_strip_biome")
	var res: Array = []
	for on in [false, true]:
		var S: SimState = SimCore.createSim()
		SimCore.newMatch(S, 7, {"p1": true, "p2": true}, {})
		S.dt = SplitRig.DT
		var rig := SplitRig.new()
		rig.swing_view = on
		rig.reset(S, VW, VH)
		var worst: float = 0.0
		var cams: Array = []
		for _t in range(3600):
			SimCore.step(S)
			var ev: Array = S.out.fx.duplicate()
			S.out.fx.clear()
			S.out.feed.clear()
			rig.step(S, VW, VH, ev)
			var c: SplitFrame = rig.current()
			cams.append(Vector3(c.cam_x[0], c.cam_y[0], c.cam_z[0]))
		res.append(cams)
	var off_ticks: int = 0
	var worst_dx: float = 0.0
	for i in range(res[0].size()):
		var d: float = absf(SimWrap.sdx(res[0][i].x, res[1][i].x))
		worst_dx = maxf(worst_dx, d)
		if d > 1.0:
			off_ticks += 1
	print("at rest: camera differs by over 1 unit on %d of %d ticks, worst %.2f" % [off_ticks, res[0].size(), worst_dx])
	_ok(off_ticks * 50 < res[0].size(), "a frame at rest moved the camera on %d ticks" % off_ticks)


func _strip_biome(_S, x: float) -> String:
	return WorldBiomes.biomeAt(x)


## Turned a quarter: what lay along the line now stands in depth, on the rig's own reads.
func _rig_turned() -> void:
	var S: SimState = SimCore.createSim()
	SimCore.newMatch(S, 7, {"p1": true, "p2": true}, {})
	S.dt = SplitRig.DT
	var rig := SplitRig.new()
	rig.swing_view = true
	rig.reset(S, VW, VH)
	CamPlaces.frame_source = Callable(self, "_turned")
	var A = S.fighters[0]
	pivot_x = A.x
	var bld = null
	for b in S.buildings:
		if b.alive and b.h >= 150.0:
			bld = b
			break
	_ok(bld != null, "this world has a tall building")
	if bld == null:
		return
	# On gen 3 the sim poses a building near the fighters as the line turns (simulation.md section 11): this stages its pose.
	# The near-tower rule looks where the tower is now: 1,000 in front of the plane, right in front of the lens.
	theta = deg_to_rad(-90.0)
	rig.step(S, VW, VH, [])
	bld.x = A.x
	bld.z = 1000.0
	var half_bld: float = 0.5 * sqrt(bld.w * bld.w + bld.d * bld.d)
	var lens: float = 1000.0 + half_bld + 200.0
	var face: float = rig._face_ahead(S, A.x, lens)
	_ok(absf(face - 200.0) < 40.0, "a tower turned in front of the lens isn't seen: %f" % face)
	# A landmark in front of the plane isn't in the frame, whatever its x says; behind the plane it is, and the frame is wider there.
	for b in S.buildings:
		b.landmark = 0
	bld.landmark = 1
	rig._scape_seen = {}
	rig._lm_src = []
	rig._scape_tick(S)
	_ok(not rig._scape_seen.has(bld.idx), "a landmark in front of the plane was shown")
	bld.z = -1000.0
	rig._scape_seen = {}
	rig._scape_tick(S)
	_ok(rig._scape_seen.has(bld.idx), "a landmark behind the plane wasn't seen")
	var half_w: float = 0.5 * VW / maxf(rig._mz, 0.001)
	var dist: float = CamParams.K_FACTOR * VH / maxf(rig._mz, 0.001)
	bld.x = SimWrap.wrap(rig._scape_mid + half_w * (dist + 3000.0) / dist)
	bld.z = -3000.0
	rig._scape_seen = {}
	rig._scape_tick(S)
	_ok(rig._scape_seen.has(bld.idx), "a landmark at the wider edge, far behind the plane, wasn't seen")
	bld.z = -200.0
	rig._scape_seen = {}
	rig._scape_tick(S)
	_ok(not rig._scape_seen.has(bld.idx), "a landmark outside the frame's width at its depth was seen")
	# the frame reaches Rendering through SplitFrame, each pane on its own fighter
	var f: SplitFrame = rig.current()
	_ok(f.place.size() == 7, "the frame didn't reach SplitFrame")
	var basis: Dictionary = f.pane_basis(A.x)
	_ok(absf(Vector3(basis.pv).length() - 1.0) < 1.0e-5, "a pane's pivot isn't on the sphere")
	theta = 0.0
