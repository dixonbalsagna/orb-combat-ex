extends SceneTree
## The swing's camera in real AI fights with DirSwing on (docs/camera/swing-view.md): gen 3, whole ring, the choreographer's own swings. It asks
## for nothing and writes nothing. Run with data/director/swing.json enabled true; off it says so and skips.
##   godot --headless --path . --script res://render/camera/tests/swing_fight_check.gd -- [--seeds=3] [--ticks=7200]
## Ends with `swing_fight_check: N checks passed` or a line per failure.

const VW: float = 1280.0
const VH: float = 720.0
const PLANETS: Array = [7, 3, 11, 25]

var fails: int = 0
var checks: int = 0


func _ok(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		fails += 1
		print("FAIL ", what)


func _run(seed: int, ticks: int, reduced: bool) -> Dictionary:
	var S: SimState = SimCore.createSim()
	SimCore.newMatch(S, seed, {"p1": true, "p2": true}, {"planet": int(PLANETS[seed % PLANETS.size()]), "touch": 1, "planetGen": 3, "intro": false})
	S.dt = SplitRig.DT
	var rig := SplitRig.new()
	rig.swing_view = true
	rig.peak_launch = true
	rig.reduced_motion = reduced
	rig.reset(S, VW, VH)
	var r: Dictionary = {"swings": 0, "ticks": 0, "big": 0, "shot": 0, "cuts_in": 0, "cuts": [], "stepmax": 0.0, "shown": 0.0, "off": 0, "off_shot": 0, "peaks": 0, "peak": 0.0, "rate": 0.0, "causes": {}, "fade": 0.0, "corr": 0, "stepown": 0.0, "step_at": "", "fade_at": "", "fade_mine": 0.0}
	var last_p: float = (rig._shot_pitch + rig.swing_angle)
	var was: bool = false
	var last_cause: String = ""
	for _t in range(ticks):
		SimCore.step(S)
		var ev: Array = S.out.fx.duplicate()
		S.out.fx.clear()
		S.out.feed.clear()
		rig.step(S, VW, VH, ev)
		var f: SplitFrame = rig.current()
		var on: bool = bool(S.swing.active)
		if on and not was:
			r.swings += 1
			var c: String = String(S.swing.cause)
			r.causes[c] = int(r.causes.get(c, 0)) + 1
		was = on
		if on:
			r.ticks += 1
			r.rate = maxf(float(r.rate), absf(rig.swing_deg))
		if rig.swing_gesture > 0.0:
			r.shot += 1
		if f.cut and on:
			r.cuts_in += 1
		if f.cut and reduced and rig._sw_cut_t == rig.time and rig._sw_cause != "launch":
			r.cuts.append(S.tick)   # the swing's own cuts outside a launch: Accessibility's 4 s
		var st: float = absf((rig._shot_pitch + rig.swing_angle) - last_p)
		if st > float(r.stepmax):
			r.stepmax = st
			r.step_at = "tick %d, shot %s, gesture %.2f, solo %s %s, angle %s, turn %.2f, pitch %.2f to %.2f" % [S.tick, f.mode, rig.swing_gesture, rig.solo_kind, rig.solo_phase, rig.angle_now, rig._turn_t, last_p, (rig._shot_pitch + rig.swing_angle)]
		r.stepown = maxf(float(r.stepown), absf(rig.swing_angle - float(r.get("la", 0.0))))
		r.la = rig.swing_angle
		last_p = (rig._shot_pitch + rig.swing_angle)
		r.shown = maxf(float(r.shown), absf(rig.swing_shown))
		if f.fade > float(r.fade):
			r.fade = f.fade
			r.fade_at = "tick %d, solo %s, swing cut this tick %s" % [S.tick, rig.solo_kind, rig._sw_cut_t == rig.time]
		if rig._sw_cut_t == rig.time:
			r.fade_mine = maxf(float(r.fade_mine), f.fade)
		if rig.peak_width > 0.0:
			r.peak = maxf(float(r.peak), rig.peak_width)
		# a fighter a pane is for, off the frame while the world turns
		if on and not reduced:
			for i in range(2):
				if f.shows(i) and (rig.solo_kind != "launch" or rig.solo_slot == i):   # (a launch-follow shot leaves the launcher behind, as it does with no swing)
					var fi = S.fighters[i]
					var s: Vector2 = f.screen_pos(i, fi.x, fi.y + CamParams.CHEST, float(fi.z))
					if s.x < 0.0 or s.x > VW or s.y < 0.0 or s.y > VH:
						r.off += 1
						if int(r.off) % 10 == 1:
							print("   off the frame: tick %d, pane %d, %s, y over ground %.0f, at %s, mode %s, solo %s %s, cut %s, rate %.0f, sep %.2f" % [S.tick, i, fi.state, float(fi.y) - WorldTerrain.groundY(S, fi.x), s, f.mode, rig.solo_kind, rig.solo_phase, f.cut, rig.swing_deg, rig.sep])
		if S.game.ko != null and S.game.koT > 3.0:
			break
	r["peak_shots"] = rig.peak_shots
	return r


func _initialize() -> void:
	var seeds: int = 3
	var ticks: int = 7200
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seeds="):
			seeds = int(a.substr(8))
		elif a.begins_with("--ticks="):
			ticks = int(a.substr(8))
	var j = JSON.parse_string(FileAccess.get_file_as_string("res://data/director/swing.json"))
	if not (j is Dictionary) or not bool(j.get("enabled", false)):
		print("swing_fight_check: DirSwing is off in this build, skipped")
		quit(0)
		return
	var total: int = 0
	for seed in range(1, seeds + 1):
		var n: Dictionary = _run(seed, ticks, false)
		total += int(n.swings)
		print("seed %d normal: %d swings %s, on %d ticks, shot in %d, fastest %.0f deg/s, cuts in a swing %d, worst angle step %.3f, off the frame %d, shown off %.4f, peak shots %d (widest %.0f)" % [seed, n.swings, n.causes, n.ticks, n.shot, n.rate, n.cuts_in, n.stepmax, n.off, n.shown, n.peak_shots, n.peak])
		print("   worst angle step: %s; the swing's own worst %.3f" % [n.step_at, n.stepown])
		_ok(float(n.stepown) <= CamParams.PITCH_CUT_DEG, "seed %d: the swing's angle stepped %f a tick, which the rig calls a cut" % [seed, n.stepown])
		var m: Dictionary = _run(seed, ticks, true)
		var gap: int = 100000
		for i in range(1, m.cuts.size()):
			gap = mini(gap, int(m.cuts[i]) - int(m.cuts[i - 1]))
		print("seed %d motion: %d swings, %d of the swing's own cuts outside a launch, shortest gap %d ticks, shown off up to %.1f deg, fade %.3f" % [seed, m.swings, m.cuts.size(), gap, rad_to_deg(float(m.shown)), m.fade])
		print("   worst fade: %s; on the swing's own cuts %.3f" % [m.fade_at, m.fade_mine])
		_ok(gap >= 240, "seed %d: the swing's cuts are %d ticks apart" % [seed, gap])
		_ok(float(m.fade_mine) == 0.0, "seed %d: a swing's cut dissolved: %f" % [seed, m.fade_mine])
	_ok(total > 0, "no swing ran: is DirSwing on, on a field world?")
	if fails == 0:
		print("swing_fight_check: %d checks passed" % checks)
	else:
		print("swing_fight_check: %d of %d checks FAILED" % [fails, checks])
	quit(1 if fails > 0 else 0)
