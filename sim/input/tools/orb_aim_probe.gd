extends SceneTree
## Plays the raw right-stick samples of a black-box first-play file through the real strike reader, once with switches.beamAim off and once on, and prints counts only:
## how far the aim on the release step is from the direction the thumb held (the rim mean), and how often the shown aim changes while the stick is held.
## The file is Orb's and stays private (homework/Files/...): nothing of the samples is printed or written.
##   godot --headless --path . --script res://sim/input/tools/orb_aim_probe.gd -- file=<path to the json>
## (a path without spaces; the harness' own runner passes it as a user argument)

func _init() -> void:
	SimInputData.load_and_apply()
	var path: String = ""
	for a in OS.get_cmdline_user_args() + OS.get_cmdline_args():
		if str(a).begins_with("file="):
			path = str(a).substr(5)
	if path == "" or not FileAccess.file_exists(path):
		print("orb_aim_probe: no file (pass file=<path>)")
		quit(1)
		return
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	var samples: Array = d["rawRightStick"]["samples"]
	# one sample a tick (the last), like the sim's read; the ticks between two samples more than one apart are at rest
	var steps: Array = []
	var last_t: int = -1
	for s in samples:
		var t: int = int(s[0])
		if last_t >= 0 and t - last_t > 1:
			for k in range(last_t + 1, t):
				steps.append([k, 0.0, 0.0])
		if t == last_t:
			steps[steps.size() - 1] = [t, float(s[2]), -float(s[3])]
		else:
			steps.append([t, float(s[2]), -float(s[3])])
		last_t = t
	for mode in [false, true]:
		var sw: Dictionary = SimInputData.timing.get("switches", {})
		sw["rightStick"] = true
		sw["beamAim"] = mode
		SimInputData.timing["switches"] = sw
		SimInputData.clear_overrides()
		SimInputData.invalidate()
		_run(steps, mode)
	quit(0)


func _run(steps: Array, mode: bool) -> void:
	var r: SimStrikeRead = SimStrikeRead.new()
	var holds: int = 0
	var rel_err: Array = []
	var changes: int = 0
	var zero_rel: int = 0
	var cur: Array = []        # the vectors of the current hold at the rim (85% of its peak)
	var peak_r: float = 0.0
	var hold_vecs: Array = []
	var last_aim: int = -1
	var in_hold: bool = false
	for st in steps:
		var tick: int = int(st[0])
		var x: float = st[1]
		var y: float = st[2]
		r.step(x, y, 0, tick, tick)
		if r.down:
			if not in_hold:
				in_hold = true
				hold_vecs = []
				peak_r = 0.0
				last_aim = -1
			var rr: float = r.deflection(x, y)
			peak_r = maxf(peak_r, rr)
			hold_vecs.append([rr, Vector2(x, y), r.aim])
			if last_aim >= 0 and r.aim != last_aim and r.phase == SimStrikeRead.ACTIVE:
				changes += 1
			last_aim = r.aim
		if r.release:
			holds += 1
			var v: Vector2 = Vector2.ZERO
			for h in hold_vecs:
				if h[0] >= 0.85 * peak_r:
					v += h[1]
			if v != Vector2.ZERO:
				var want: float = rad_to_deg(atan2(v.y, v.x))
				var got: float = float(r.aim) * 11.25
				var e: float = absf(fposmod(got - want + 180.0, 360.0) - 180.0)
				rel_err.append(e)
			if r.aim == 0:
				zero_rel += 1
		if not r.down:
			in_hold = false
		r.clear_edges()
	rel_err.sort()
	var n: int = rel_err.size()
	var p50: float = rel_err[n / 2] if n > 0 else -1.0
	var p90: float = rel_err[mini(n - 1, int(n * 0.9))] if n > 0 else -1.0
	var worst: float = rel_err[n - 1] if n > 0 else -1.0
	print("beamAim %s: %d releases, %d carry aim 0; |release aim - rim mean| deg p50 %.1f p90 %.1f max %.1f; aim changes while a charge is held: %d" % ["ON " if mode else "OFF", holds, zero_rel, p50, p90, worst, changes])
