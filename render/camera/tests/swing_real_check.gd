extends SceneTree
## The rig on Simulation's real frame and swing (docs/camera/swing-view.md; docs/architecture/field-ground.md): a gen 3 match on a whole ring,
## with SimSwing.ask, so nothing here is staged but the ask. Skips with a line if the build has no SimField.
##   godot --headless --path . --script res://render/camera/tests/swing_real_check.gd
## Ends with `swing_real_check: N checks passed` or a line per failure.

const VW: float = 1280.0
const VH: float = 720.0

var fails: int = 0
var checks: int = 0


func _ok(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		fails += 1
		print("FAIL ", what)


func _match(ai: bool = false) -> SimState:
	var S: SimState = SimCore.createSim()
	SimCore.newMatch(S, 77, {"p1": ai, "p2": ai}, {"planet": 7, "touch": 1, "planetGen": 3, "intro": false})
	S.dt = SplitRig.DT
	return S


func _tick(S: SimState, rig: SplitRig) -> void:
	SimCore.step(S)
	var ev: Array = S.out.fx.duplicate()
	S.out.fx.clear()
	S.out.feed.clear()
	rig.step(S, VW, VH, ev)


func _rig(S: SimState, reduced: bool = false) -> SplitRig:
	var rig := SplitRig.new()
	rig.swing_view = true
	rig.reduced_motion = reduced
	rig.reset(S, VW, VH)
	return rig


func _initialize() -> void:
	var F = null
	for c in ProjectSettings.get_global_class_list():
		if String(c["class"]) == "SimField":
			F = load(String(c["path"]))
	if F == null:
		print("swing_real_check: no SimField in this build, skipped")
		quit(0)
		return
	_door()
	_far_poses()
	_sign()
	_the_shot()
	_motion()
	_gates()
	if fails == 0:
		print("swing_real_check: %d checks passed" % checks)
	else:
		print("swing_real_check: %d of %d checks FAILED" % [fails, checks])
	quit(1 if fails > 0 else 0)


## The door's closed forms against SimField's own, before and after a real turn.
func _door() -> void:
	var S: SimState = _match()
	var rig: SplitRig = _rig(S)
	for _t in range(5):
		_tick(S, rig)
	SimSwing.ask(S, {"deg": 70.0, "cause": "launch"})
	for pass_i in range(2):
		var f: PackedFloat64Array = CamPlaces.frame_of(S)
		_ok(f.size() == 7, "no frame on gen 3")
		_ok(absf(CamPlaces.radius() - SimField.R) < 1.0e-6, "the line's radius isn't the field's: %f, %f" % [CamPlaces.radius(), SimField.R])
		for x in [0.0, 300.0, S.fighters[1].x, 0.2 * SimConst.W, 0.7 * SimConst.W]:
			SimField.pointAt(S, x)
			var q: PackedFloat64Array = CamPlaces.on_line(f, x)
			_ok(absf(q[0] - SimField.ox) + absf(q[1] - SimField.oy) + absf(q[2] - SimField.oz) < 1.0e-9, "the line's point at %f differs" % x)
		# depth: SimField's place and the door's view agree on which way is toward the camera
		SimField.placeAt(S, S.fighters[0].x, 900.0)
		var v: Vector2 = CamPlaces.view_of(f, S.fighters[0].x, [SimField.ox, SimField.oy, SimField.oz])
		_ok(absf(v.x) < 1.0e-3 and absf(v.y - 900.0) < 1.0e-3, "a place 900 toward the camera read %s" % v)
		for _t in range(45):
			_tick(S, rig)


## Mid-swing, every building reads where it really is, however far past the sim's pose reach; at rest it reads the sim's pose, the same place.
func _far_poses() -> void:
	var S: SimState = _match()
	var rig: SplitRig = _rig(S)
	for _t in range(5):
		_tick(S, rig)
	SimSwing.ask(S, {"deg": 120.0, "cause": "launch"})
	for _t in range(60):
		_tick(S, rig)
	_ok(S.swing.active, "the swing ended early")
	var f: PackedFloat64Array = CamPlaces.frame_of(S)
	var from_x: float = S.fighters[0].x
	var n: int = 0
	var stale: int = 0
	var worst: float = 0.0
	for b in S.buildings:
		var i: int = int(b.idx) * 3
		var v: Vector2 = CamPlaces.place(S, f, from_x, b, b.x, b.z)
		var w: Vector2 = CamPlaces.view_of(f, from_x, [S.bDir[i], S.bDir[i + 1], S.bDir[i + 2]])
		worst = maxf(worst, v.distance_to(w))
		n += 1
		SimField.strip(S, S.bDir[i], S.bDir[i + 1], S.bDir[i + 2])
		if absf(SimWrap.sdx(SimField.sx, b.x)) > 50.0:
			stale += 1
	print("mid-swing: %d buildings, %d with a stale pose, the door's read off by at most %.3f" % [n, stale, worst])
	_ok(n > 0 and worst < 1.0e-6, "the door read a building off by %f" % worst)
	var cnt: int = 0
	while S.swing.active and cnt < 600:
		_tick(S, rig)
		cnt += 1
	for _t in range(3):
		_tick(S, rig)
	f = CamPlaces.frame_of(S)
	var off: float = 0.0
	for b in S.buildings:
		var i: int = int(b.idx) * 3
		var v2: Vector2 = CamPlaces.view_of(f, from_x, [S.bDir[i], S.bDir[i + 1], S.bDir[i + 2]])
		if v2.length() < 6000.0:
			off = maxf(off, v2.distance_to(CamPlaces.place(S, f, from_x, b, b.x, b.z)))
	print("at rest: the sim's pose against the planet point within 6,000: at most %.1f" % off)
	_ok(off < 120.0, "at rest the pose is %f from the point" % off)


## The sign, read from the real thing: left above 0 turns as CamPlaces.turned, and left counts down what's still to turn.
func _sign() -> void:
	for deg in [40.0, -40.0]:
		var S: SimState = _match()
		var rig: SplitRig = _rig(S)
		for _t in range(5):
			_tick(S, rig)
		var f0: PackedFloat64Array = CamPlaces.frame_of(S)
		_ok(SimSwing.ask(S, {"deg": deg, "cause": "launch"}), "the ask was refused")
		var left0: float = float(S.swing.left)
		_ok(signf(left0) == signf(deg), "left's sign is %f for %f" % [left0, deg])
		var sum: float = 0.0
		var f1: PackedFloat64Array = f0
		var worst_left: float = 0.0
		var n: int = 0
		while S.swing.active and n < 400:
			_tick(S, rig)
			var f2: PackedFloat64Array = CamPlaces.frame_of(S)
			sum += CamPlaces.turn_between(f1, f2)
			f1 = f2
			# left is the live count: what's turned so far and what's left make the asked angle, every tick
			worst_left = maxf(worst_left, absf(rad_to_deg(sum) + float(S.swing.left) - deg) if S.swing.active else 0.0)
			n += 1
		print("asked %.0f: the frame turned %.2f by turn_between in %d ticks, rig's rate at the end %.1f" % [deg, rad_to_deg(sum), n, rig.swing_deg])
		_ok(absf(rad_to_deg(sum) - deg) < 0.5, "asked %f, the frame turned %f" % [deg, rad_to_deg(sum)])
		print("   left against the frame's own count: off by at most %.3f deg" % worst_left)
		_ok(worst_left < 0.5, "left parts from the frame by %f" % worst_left)
		var want: PackedFloat64Array = CamPlaces.turned(f0, deg_to_rad(deg))
		_ok(absf(CamPlaces.turn_between(want, f1)) < 0.01, "turned() and the sim's turn part: %f" % CamPlaces.turn_between(want, f1))


func _the_shot() -> void:
	var S: SimState = _match()
	var rig: SplitRig = _rig(S)
	for _t in range(60):
		_tick(S, rig)
	SimSwing.ask(S, {"deg": 90.0, "cause": "launch"})
	var peak: float = 0.0
	var min_p: float = 0.0
	var step_p: float = 0.0
	var last: float = rig.swing_angle
	var cuts: int = 0
	var n: int = 0
	var worst_shown: float = 0.0
	while S.swing.active and n < 400:
		_tick(S, rig)
		peak = maxf(peak, absf(rig.swing_deg))
		min_p = minf(min_p, rig.swing_angle)
		step_p = maxf(step_p, absf(rig.swing_angle - last))
		last = rig.swing_angle
		cuts += 1 if rig.current().cut else 0
		worst_shown = maxf(worst_shown, absf(rig.swing_shown))
		n += 1
	print("real 90: %d ticks, peak %.1f deg/s (the law may slow it), angle %.2f, worst angle step %.3f, cuts %d, shown off the sim's %.4f" % [n, peak, min_p, step_p, cuts, worst_shown])
	_ok(n > 18, "the swing ran %d ticks" % n)
	_ok(peak > 1.0, "no rate read")
	_ok(min_p < -1.0, "the low angle didn't come in: %f" % min_p)
	_ok(cuts == 0, "%d cuts" % cuts)
	_ok(worst_shown == 0.0, "the shown heading parted from the sim's by %f on a plain swing" % worst_shown)


## The motion setting on real swings: a launch's cut, then at most one cut per 4 s outside a launch, small ones folded.
func _motion() -> void:
	var S: SimState = _match()
	var rig: SplitRig = _rig(S, true)
	for _t in range(30):
		_tick(S, rig)
	var cuts: Array = []
	var asks: Array = [[10, {"deg": 40.0, "cause": "launch"}], [100, {"deg": 8.0, "cause": "small"}], [160, {"deg": 40.0, "cause": "chase"}], [340, {"deg": 40.0, "cause": "chase"}], [600, {"deg": 30.0, "cause": "form"}]]
	var worst_fade: float = 0.0
	var worst_roll: float = 0.0
	for t in range(1000):
		for a in asks:
			if int(a[0]) == t:
				SimSwing.ask(S, a[1])
		_tick(S, rig)
		var f: SplitFrame = rig.current()
		if f.cut:
			cuts.append(t)
		worst_fade = maxf(worst_fade, f.fade)
		worst_roll = maxf(worst_roll, absf(rig.swing_angle))
	print("motion: cuts at ticks %s, fade %.3f, gesture angle %.3f" % [cuts, worst_fade, worst_roll])
	_ok(worst_fade == 0.0, "a cut dissolved: %f" % worst_fade)
	_ok(worst_roll == 0.0, "a tilt under the setting: %f" % worst_roll)
	for i in range(1, cuts.size()):
		_ok(int(cuts[i]) - int(cuts[i - 1]) >= 240, "cuts %d and %d are under 4 s apart" % [cuts[i - 1], cuts[i]])
	_ok(cuts.size() >= 2, "too few cuts: %s" % [cuts])
	_ok(absf(CamPlaces.turn_between(rig.current().place, CamPlaces.frame_of(S))) < 0.9, "the shown heading was left far behind")
	# above 1x every swing is a cut, setting or no
	S = _match()
	rig = _rig(S)
	rig.playback = 2.0
	for _t in range(30):
		_tick(S, rig)
	SimSwing.ask(S, {"deg": 40.0, "cause": "launch"})
	var c2: int = 0
	var worst: float = 0.0
	var first: PackedFloat64Array = PackedFloat64Array()
	for t in range(120):
		_tick(S, rig)
		c2 += 1 if rig.current().cut else 0
		if t == 0:
			first = rig.current().place
		else:
			worst = maxf(worst, absf(CamPlaces.turn_between(first, rig.current().place)))
	_ok(c2 == 1 and rad_to_deg(worst) < 0.01, "at 2x: %d cuts, shown moved %f" % [c2, rad_to_deg(worst)])
	# UI's option: cut cuts with no setting, full turns even under Reduced motion
	S = _match()
	rig = _rig(S)
	rig.world_turning = "cut"
	for _t in range(30):
		_tick(S, rig)
	SimSwing.ask(S, {"deg": 40.0, "cause": "launch"})
	_tick(S, rig)
	_ok(rig.current().cut, "world_turning cut didn't cut")
	S = _match()
	rig = _rig(S, true)
	rig.world_turning = "full"
	for _t in range(30):
		_tick(S, rig)
	SimSwing.ask(S, {"deg": 40.0, "cause": "launch"})
	var cf: int = 0
	for _t in range(60):
		_tick(S, rig)
		cf += 1 if rig.current().cut else 0
	_ok(cf == 0 and rig.swing_shown == 0.0, "world_turning full didn't turn: %d cuts" % cf)
	# a seek snaps the heading, with no catch-up
	rig.swing_shown = 0.5
	theta_jump(S)
	rig.cut(S)
	_ok(rig.swing_shown == 0.0 and absf(CamPlaces.turn_between(rig.current().place, CamPlaces.frame_of(S))) < 1.0e-9, "a seek left the heading off")
	_ok(rig.current().cut, "a seek isn't a cut")


func theta_jump(S: SimState) -> void:
	SimField.pointAt(S, 0.0)


## The door's other reads on real data: the peak rate is a data number, tall land comes off the bake, and the biome follows the line.
func _gates() -> void:
	_ok(float(CamPlaces.data().get("peakRate", 0.0)) == 3.0, "the peak's rate isn't in data")
	var S: SimState = _match()
	var rig: SplitRig = _rig(S)
	for _t in range(5):
		_tick(S, rig)
	var any: int = 0
	var none: int = 0
	var x: float = 0.0
	while x < SimConst.W:
		if CamPlaces.land_tall(S, x, 4000.0, 1500.0):
			any += 1
		else:
			none += 1
		x += 3000.0
	print("tall land by the bake, round the line: %d of %d" % [any, any + none])
	_ok(any + none > 0 and none > 0, "land_tall answers yes everywhere")
	var b0: String = CamPlaces.biome(S, S.fighters[0].x)
	_ok(b0 != "", "no biome")
	_ok(SimField.cur == S, "the biome read isn't this match's")
