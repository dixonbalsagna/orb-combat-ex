extends SceneTree
## The swing's shot on the real rig (docs/camera/swing-view.md): a staged frame turned by the curve the sim will run, on a real match
## with the fighters idle. Nothing here writes the sim.
##   godot --headless --path . --script res://render/camera/tests/swing_shot_check.gd
## Ends with `swing_shot_check: N checks passed` or a line per failure.

const VW: float = 1280.0
const VH: float = 720.0

var fails: int = 0
var checks: int = 0
var theta: float = 0.0
var px: float = 0.0
var sw: Dictionary = {}


func _ok(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		fails += 1
		print("FAIL ", what)


func _frame(_S = null) -> PackedFloat64Array:
	return CamPlaces.turned(_rest(), theta)


func _rest(_S = null) -> PackedFloat64Array:
	return PackedFloat64Array([1.0, 0.0, 0.0, 0.0, 1.0, 0.0, px])


func _swing(_S = null) -> Dictionary:
	return sw


func _new_rig(S: SimState, reduced: bool = false) -> SplitRig:
	S.dt = SplitRig.DT
	var rig := SplitRig.new()
	rig.swing_view = true
	rig.reduced_motion = reduced
	rig.reset(S, VW, VH)
	return rig


func _match() -> SimState:
	var S: SimState = SimCore.createSim()
	SimCore.newMatch(S, 7, {"p1": false, "p2": false}, {})
	return S


func _tick(S: SimState, rig: SplitRig) -> void:
	SimCore.step(S)
	var ev: Array = S.out.fx.duplicate()
	S.out.fx.clear()
	S.out.feed.clear()
	rig.step(S, VW, VH, ev)


## A launch's turn: 60 degrees a second on a 20-tick ramp in and a 10-tick ramp out.
func _launch_curve(total_deg: float) -> PackedFloat64Array:
	var a: PackedFloat64Array = PackedFloat64Array()
	var n: int = int(total_deg) + 15
	for t in range(n):
		var r: float = 1.0
		if t < 20:
			r = smoothstep(0.0, 20.0, float(t))
		elif t >= n - 10:
			r = smoothstep(0.0, 10.0, float(n - t))
		a.append(r)
	var sum: float = 0.0
	for v in a:
		sum += v
	for i in range(a.size()):
		a[i] = a[i] * total_deg / sum
	return a


func _initialize() -> void:
	CamPlaces.frame_source = Callable(self, "_frame")
	CamPlaces.swing_source = Callable(self, "_swing")
	_the_shot()
	_a_jolt()
	_a_correction()
	_motion_launch()
	_motion_form()
	_motion_brawl()
	_a_strip()
	_off()
	CamPlaces.frame_source = Callable()
	CamPlaces.swing_source = Callable()
	CamPlaces.land_source = Callable()
	if fails == 0:
		print("swing_shot_check: %d checks passed" % checks)
	else:
		print("swing_shot_check: %d of %d checks FAILED" % [fails, checks])
	quit(1 if fails > 0 else 0)


## The world turns 90: the rate is read, the angle comes in eased and goes out after the rest, no other shot starts, no cut is made.
func _the_shot() -> void:
	var S: SimState = _match()
	theta = 0.0
	sw = {}
	px = S.fighters[0].x
	var rig: SplitRig = _new_rig(S)
	for _t in range(60):
		_tick(S, rig)
	var curve: PackedFloat64Array = _launch_curve(90.0)
	var peak: float = 0.0
	var min_pitch: float = 0.0
	var worst_pitch_step: float = 0.0
	var cuts: int = 0
	var a0: int = rig.angle_shots
	var s0: int = rig.scape_shots
	var last_pitch: float = rig.swing_angle
	for t in range(curve.size()):
		theta += deg_to_rad(curve[t])
		sw = {"cause": "launch", "toGo": deg_to_rad(90.0) - theta}
		_tick(S, rig)
		peak = maxf(peak, absf(rig.swing_deg))
		if t < CamParams.SWING_SHOT_TICKS - 1:
			_ok(rig.swing_gesture == 0.0, "the shot came in before it was a swing at tick %d" % t)
		min_pitch = minf(min_pitch, rig.swing_angle)
		worst_pitch_step = maxf(worst_pitch_step, absf(rig.swing_angle - last_pitch))
		last_pitch = rig.swing_angle
		cuts += 1 if rig.current().cut else 0
	print("the shot: peak %.1f deg/s, angle %.2f, worst angle step %.3f a tick, cuts %d" % [peak, min_pitch, worst_pitch_step, cuts])
	_ok(absf(peak - 60.0) < 8.0, "peak read %f" % peak)
	_ok(absf(min_pitch - CamParams.SWING_PITCH) < 0.5, "the low angle reached %f" % min_pitch)
	_ok(worst_pitch_step < CamParams.PITCH_CUT_DEG * 0.5, "the angle stepped %f a tick" % worst_pitch_step)
	_ok(cuts == 0, "%d cuts in the shot" % cuts)
	_ok(rig.angle_shots == a0 and rig.scape_shots == s0, "another shot started in the swing")
	# It holds, then eases out and hands the angle back.
	sw = {}
	var held: float = rig.swing_angle
	for _t in range(int(CamParams.SWING_REST_HOLD / SplitRig.DT) - 2):
		_tick(S, rig)
	_ok(rig.swing_angle == held, "the angle didn't hold through the landing's hold")
	for _t in range(int((CamParams.SWING_OUT + 0.2) / SplitRig.DT)):
		_tick(S, rig)
	_ok(rig.swing_angle == 0.0 and rig.swing_gesture == 0.0, "the shot didn't end: %f" % rig.swing_angle)
	for _t in range(70):
		_tick(S, rig)
	_ok(rig._sw_ticks == 0, "the swing didn't end")


func _a_jolt() -> void:
	var S: SimState = _match()
	theta = 0.0
	sw = {}
	px = S.fighters[0].x
	var rig: SplitRig = _new_rig(S)
	for _t in range(30):
		_tick(S, rig)
	var peak: float = 0.0
	var T: int = 8
	for t in range(T):
		var u: float = float(t + 1) / T
		theta = deg_to_rad(10.0) * (1.0 - (1.0 - u) * (1.0 - u) * (1.0 - u))
		sw = {"cause": "small", "toGo": deg_to_rad(10.0) - theta}
		_tick(S, rig)
		peak = maxf(peak, absf(rig.swing_deg))
		_ok(rig.swing_shown == 0.0, "a jolt was taken for a correction at %d" % t)
	sw = {}
	for _t in range(10):
		_tick(S, rig)
		_ok(rig.swing_gesture == 0.0, "a jolt got the shot")
	print("a jolt: peak %.0f deg/s" % peak)
	_ok(peak > 150.0, "the jolt's rate read %f" % peak)


## A rollback moves the sim's heading 20 degrees at once: the shown heading doesn't jump, it eases over, no faster than a swing.
func _a_correction() -> void:
	var S: SimState = _match()
	theta = 0.0
	sw = {}
	px = S.fighters[0].x
	var rig: SplitRig = _new_rig(S)
	for _t in range(30):
		_tick(S, rig)
	var prev: PackedFloat64Array = rig.current().place
	theta = deg_to_rad(20.0)
	var worst: float = 0.0
	var ticks: int = 0
	for _t in range(120):
		_tick(S, rig)
		var now: PackedFloat64Array = rig.current().place
		worst = maxf(worst, absf(CamPlaces.turn_between(prev, now)))
		prev = now
		if absf(rig.swing_shown) > 1.0e-3:
			ticks += 1
	print("a correction: worst %.2f deg a tick, gone in %d ticks" % [rad_to_deg(worst), ticks])
	_ok(rad_to_deg(worst) <= 1.05, "the shown heading moved %f a tick" % rad_to_deg(worst))
	_ok(absf(rig.swing_shown) < 1.0e-3, "the correction didn't finish: %f" % rig.swing_shown)
	_ok(absf(CamPlaces.turn_between(prev, _frame())) < 2.0e-3, "the shown heading ended off the sim's")


## Motion setting, a launch: a cut on its start to the end bearing, then held, and no gestures.
func _motion_launch() -> void:
	var S: SimState = _match()
	theta = 0.0
	sw = {}
	px = S.fighters[0].x
	var rig: SplitRig = _new_rig(S, true)
	for _t in range(30):
		_tick(S, rig)
	var curve: PackedFloat64Array = _launch_curve(90.0)
	var cut_ticks: Array = []
	var first: PackedFloat64Array = PackedFloat64Array()
	var worst: float = 0.0
	for t in range(curve.size()):
		theta += deg_to_rad(curve[t])
		sw = {"cause": "launch", "toGo": deg_to_rad(90.0) - theta}
		_tick(S, rig)
		var f: SplitFrame = rig.current()
		if f.cut:
			cut_ticks.append(t)
		if t == 0:
			first = f.place
		else:
			worst = maxf(worst, absf(CamPlaces.turn_between(first, f.place)))
		_ok(rig.swing_gesture == 0.0 and rig.swing_angle == 0.0, "the motion setting got a gesture")
	sw = {}
	_tick(S, rig)
	print("motion, launch: cuts at %s, shown moved %.4f deg after" % [cut_ticks, rad_to_deg(worst)])
	_ok(cut_ticks == [0], "cuts at %s" % [cut_ticks])
	_ok(rad_to_deg(worst) < 0.01, "the shown heading moved %f" % rad_to_deg(worst))
	_ok(absf(rig.swing_shown) < 1.0e-6, "shown and sim ended apart: %f" % rig.swing_shown)
	var end: float = CamPlaces.turn_between(_frame(), first)
	_ok(absf(end) < 1.0e-3, "the cut wasn't to the end bearing: %f" % end)


## Motion setting, a form's pause: still, then a cut at its end.
func _motion_form() -> void:
	var S: SimState = _match()
	theta = 0.0
	sw = {}
	px = S.fighters[0].x
	var rig: SplitRig = _new_rig(S, true)
	for _t in range(30):
		_tick(S, rig)
	var start: PackedFloat64Array = rig.current().place
	var cuts: int = 0
	var worst: float = 0.0
	for _t in range(90):
		theta += deg_to_rad(0.5)
		sw = {"cause": "form", "toGo": deg_to_rad(45.0) - theta}
		_tick(S, rig)
		cuts += 1 if rig.current().cut else 0
		worst = maxf(worst, absf(CamPlaces.turn_between(start, rig.current().place)))
	_ok(cuts == 0 and rad_to_deg(worst) < 0.01, "a form's pause moved: %f, %d cuts" % [rad_to_deg(worst), cuts])
	sw = {}
	_tick(S, rig)
	_ok(rig.current().cut, "no cut at the pause's end")
	_ok(absf(CamPlaces.turn_between(rig.current().place, _frame())) < 1.0e-6, "the cut didn't reach the sim's heading")


## Motion setting, a brawl's slow swing: still; past a standing fighter's foot limit it waits for a hit-stop, and never cuts on its own.
func _motion_brawl() -> void:
	var S: SimState = _match()
	theta = 0.0
	sw = {}
	px = S.fighters[1].x   # the pivot on the other fighter, so one stands off it
	var rig: SplitRig = _new_rig(S, true)
	for _t in range(30):
		_tick(S, rig)
	var r: float = absf(SimWrap.sdx(px, S.fighters[0].x))
	var limit: float = rad_to_deg(CamParams.SWING_FOOT / (maxf(r, 1.0) * CamParams.SWING_SLOPE))
	var cuts: int = 0
	for _t in range(int(limit * 2.0 * 6.0)):   # twice the limit, at 10 degrees a second
		theta += deg_to_rad(10.0 / 60.0)
		sw = {"cause": "brawl", "toGo": 1.0}
		_tick(S, rig)
		cuts += 1 if rig.current().cut else 0
	_ok(cuts == 0, "a hold cut on its own: %d" % cuts)
	_ok(rig._sw_due, "the limit wasn't noticed, %.0f units from the pivot, limit %.1f" % [r, limit])
	var f0 = S.dirS.stop
	S.dirS.stop = 0.1
	rig.step(S, VW, VH, [])
	S.dirS.stop = f0
	print("motion, brawl: %.0f units from the pivot, limit %.1f deg, held to %.1f, cut on the hit-stop: %s" % [r, limit, rad_to_deg(theta), rig.current().cut])
	_ok(rig.current().cut and rig.swing_shown == 0.0, "the hit-stop didn't take the cut")


func _a_strip() -> void:
	var S: SimState = _match()
	theta = 0.0
	sw = {}
	px = S.fighters[0].x
	var rig: SplitRig = _new_rig(S)
	for _t in range(30):
		_tick(S, rig)
	rig._pn = {"t": 0.1, "dur": 3.0, "kind": "signature", "slot": 0, "band": 0}
	for _t in range(CamParams.SWING_SHOT_TICKS + 1):
		theta += deg_to_rad(1.0)
		sw = {"cause": "launch", "toGo": 1.0}
		_tick(S, rig)
	_ok(rig._pn.is_empty() or float(rig._pn["dur"]) < 1.0, "a strip stayed up in a swing")
	sw = {}


## Off: a frame present with the switch off isn't read.
func _off() -> void:
	var S: SimState = _match()
	S.dt = SplitRig.DT
	var rig := SplitRig.new()
	rig.reset(S, VW, VH)
	theta = 1.0
	for _t in range(10):
		_tick(S, rig)
	_ok(rig.current().place.is_empty() and rig.swing_gesture == 0.0 and rig._sw_ticks == 0, "the switch off read the frame")
	theta = 0.0
