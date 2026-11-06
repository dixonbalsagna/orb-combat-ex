extends "res://render/camera/tests/launch_shots_check.gd"
## The flat send's two shots, the reveal in flight and the follow-through (docs/camera/launch-director.md), each on the real rig with launch_shots_check's measures. Staged sends.
##   godot --headless --path . --script res://render/camera/tests/flight_shots_check.gd -- [--measure]
## Ends with `flight_shots_check: N checks passed` or a line per failure.


func _mode_rig(mode: String, reveal: bool = false, ft: bool = false) -> Callable:
	return func(rig: SplitRig) -> void:
		rig.flat_mode = mode
		if reveal:
			rig.set("flight_reveal", true)
		if ft:
			rig.set("follow_through", true)


func _flat(name: String, mode: String, tier: float, speed: float, lost_max: int) -> void:
	var S: SimState = _match(tier)
	var rig: SplitRig = _rig(S, _mode_rig(mode))
	for _t in range(30):
		SimCore.step(S)
		S.out.fx.clear()
		S.out.feed.clear()
		rig.step(S, VW, VH, [])
	_send(S.fighters[1], speed, 12.0)
	var r: Dictionary = _watch(S, rig, 480, Callable(self, "_launched_flier"))
	print("%-26s most width %.0f, ended %s, split %.2f" % [name, float(r.get("maxw", 0.0)), rig._pk_ended, rig.sep])
	var keep: Dictionary = r.duplicate()
	keep.lost_run = 0
	_say(name, keep, 0.12)   # past the eye's ceiling, a layout closing as the shot takes over
	print("    lost run %d (limit %d) at %s" % [r.lost_run, lost_max, r.lost_at])
	if not measure:
		_ok(int(r.lost_run) <= lost_max, "%s: lost for %d ticks" % [name, r.lost_run])
		_ok(rig.peak_shots == 1, "%s: the shot didn't run" % name)


func _reveal() -> void:
	# a long flight opens out, eased, and comes back; a short one doesn't
	for row in [[3.0, 8000.0, 6.0, true], [1.0, 4200.0, 6.0, true], [3.0, 8000.0, 0.7, false], [3.0, 8000.0, 6.0, false, "off"]]:
		var S: SimState = _match(float(row[0]))
		var rig = _rig(S, _mode_rig("", row.size() < 5))
		for f0 in S.fighters:
			f0.state = "launched"
			f0.launchT = 1.0
			f0.vx = 0.0
			f0.vy = 0.0
			f0.y = WorldTerrain.groundY(S, f0.x) + 900.0
		rig.reset(S, VW, VH)
		var stop: int = int(float(row[2]) * 60.0)
		var widest: Array = [0.0]
		var hold := func(St: SimState, r0, t0: int) -> void:
			var fly: bool = t0 < stop
			for f in St.fighters:
				f.state = "launched" if fly else "free"
				f.launchT = 1.0
				f.vx = (6000.0 * minf(1.0, float(t0) / 30.0)) if fly else 0.0
				f.vy = 0.0
				f.y = WorldTerrain.groundY(St, f.x) + (900.0 if fly else 0.0)
			widest[0] = maxf(float(widest[0]), VW / maxf(r0.current().cam_z[0], 0.001))
		var r: Dictionary = _watch(S, rig, stop + 240, Callable(self, "_flier"), hold)
		print("reveal, tier %.0f, %.1f s flight: %d shots, widest %.0f; back %.2f" % [float(row[0]), float(row[2]), rig.reveal_shots, float(widest[0]), rig.reveal_w])
		_say("reveal %.1f s" % float(row[2]), r)
		if measure or row.size() >= 5:
			continue
		_ok((rig.reveal_shots > 0) == bool(row[3]), "the reveal's %d shots on a %.1f s flight" % [rig.reveal_shots, float(row[2])])
		if bool(row[3]):
			_ok(float(widest[0]) >= float(row[1]) * 0.85 and float(widest[0]) <= float(row[1]) * 1.15, "the reveal's width was %f against %f" % [float(widest[0]), float(row[1])])
		_ok(rig.reveal_w == 0.0, "the reveal didn't come back")


func _follow() -> void:
	var S: SimState = _match(2.0)
	var rig = _rig(S, _mode_rig("", false, true))
	for _t in range(30):
		SimCore.step(S)
		S.out.fx.clear()
		S.out.feed.clear()
		rig.step(S, VW, VH, [])
	_send(S.fighters[1], 6000.0, 15.0)
	var peak: Array = [0.0]
	var stop := func(St: SimState, r0, t0: int) -> void:
		peak[0] = maxf(float(peak[0]), r0.ft_offset.length())
		if t0 == 30:
			var f1 = St.fighters[1]
			f1.state = "free"
			f1.vx = 0.0
			f1.vy = 0.0
	var r: Dictionary = _watch(S, rig, 240, Callable(self, "_launched_flier"), stop)
	print("overshoot: %d, peak %.4f of the width, back %.4f" % [rig.overshoots, float(peak[0]), rig.ft_offset.length()])
	_say("a stop", r)
	if measure:
		return
	_ok(rig.overshoots == 1, "the stop didn't overshoot: %d" % rig.overshoots)
	_ok(float(peak[0]) > 0.005 and float(peak[0]) <= CamParams.FT_AMOUNT * 1.01, "the overshoot was %f" % float(peak[0]))
	_ok(rig.ft_offset == Vector2.ZERO, "it didn't settle")


## A locked brawl is close at base power, and the launch out of it stays smooth.
func _close() -> void:
	var S: SimState = _match(0.0, true, 12345)
	var setup := func(rig0) -> void:
		rig0.set("close_brawl", true)
		rig0.set("launch_director", true)
		rig0.set("flat_mode", "wide")
	var rig = _rig(S, setup)
	var sum: Array = [0.0, 0]
	var meter := func(St: SimState, r0, _t: int) -> void:
		if St.fighters[0].state == "locked" and St.fighters[1].state == "locked" and r0._cb_w >= 1.0 and St.fighters[0].tier < 1.5:
			sum[0] = float(sum[0]) + r0.current().cam_z[0] * CamParams.BODY_H / VH
			sum[1] = int(sum[1]) + 1
	var r: Dictionary = _watch(S, rig, 3600, Callable(self, "_who"), meter)
	var mean: float = float(sum[0]) / maxf(float(sum[1]), 1.0)
	print("close brawl: mean size %.3f over %d settled ticks" % [mean, sum[1]])
	_say("close brawl", r, 0.16)
	if not measure:
		_ok(int(sum[1]) > 100 and mean >= CamParams.CLOSE_R * 0.9, "a locked brawl's size was %f" % mean)


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "--measure":
			measure = true
	if "close_brawl" in SplitRig.new():
		_close()
	for row in [[1.0, 10800.0], [2.0, 10800.0], [3.0, 26700.0], [4.0, 26700.0]]:
		_flat("wide, tier %d, %d" % [int(row[0]), int(row[1])], "wide", float(row[0]), float(row[1]), 40)
		_flat("hold, tier %d, %d" % [int(row[0]), int(row[1])], "hold", float(row[0]), float(row[1]), 90)
	var probe := SplitRig.new()
	if "flight_reveal" in probe:
		_reveal()
	if "follow_through" in probe:
		_follow()
	if measure:
		print("flight_shots_check: measured")
	elif fails == 0:
		print("flight_shots_check: %d checks passed" % checks)
	else:
		print("flight_shots_check: %d of %d checks FAILED" % [fails, checks])
	quit(1 if fails > 0 and not measure else 0)
