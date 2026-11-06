extends SceneTree
## The camera's read for the swing's score (docs/camera/swing-view.md). AI matches, with the read asked on the tick and the rig watching
## alongside, so the model can be checked against the camera it models: offline and one way, nothing goes back.
##   godot --headless --path . --script res://render/camera/tests/swing_read_check.gd -- [--seeds=4] [--ticks=3600]
## Ends with `swing_read_check: N checks passed` or a line per failure.

var fails: int = 0
var checks: int = 0


func _ok(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		fails += 1
		print("FAIL ", what)


func _no_people() -> void:
	# the read's own source: nothing from render/, and no word of people
	var src: String = FileAccess.get_file_as_string("res://sim/director/swing_read.gd").to_lower()
	var code: String = ""
	for line in src.split("\n"):
		if not line.strip_edges().begins_with("##"):
			code += line + "\n"
	for w in ["civilian", "people", "crowd", "casualt", "person", "toll", "menace", "anguish", "camparams", "splitrig", "render", "camplaces"]:
		_ok(code.find(w) < 0, "the read mentions %s" % w)


func _initialize() -> void:
	var seeds: int = 4
	var ticks: int = 3600
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seeds="):
			seeds = int(a.substr(8))
		elif a.begins_with("--ticks="):
			ticks = int(a.substr(8))
	_no_people()
	var counts: Dictionary = {}
	var hist: Array = [0, 0, 0, 0, 0]
	var n: int = 0
	var agree: Dictionary = {"split": [0, 0], "launch": [0, 0], "ant": [0, 0]}
	var worst_us: int = 0
	var sum_us: int = 0
	for seed in range(1, seeds + 1):
		# the read changes nothing and repeats exactly: the same match with it and without it, by the digest
		var S: SimState = SimCore.createSim()
		SimCore.newMatch(S, seed, {"p1": true, "p2": true}, {})
		S.dt = SplitRig.DT
		var S2: SimState = SimCore.createSim()
		SimCore.newMatch(S2, seed, {"p1": true, "p2": true}, {})
		S2.dt = SplitRig.DT
		var rig := SplitRig.new()
		rig.reset(S, 1280.0, 720.0)
		var same: bool = true
		for t in range(ticks):
			SimCore.step(S)
			var ev: Array = S.out.fx.duplicate()
			S.out.fx.clear()
			S.out.feed.clear()
			rig.step(S, 1280.0, 720.0, ev)
			SimCore.step(S2)
			S2.out.fx.clear()
			S2.out.feed.clear()
			var dir: int = 1 if t % 2 == 0 else -1
			var t0: int = Time.get_ticks_usec()
			var r: Dictionary = DirSwingRead.read(S, float(t % 400) / 60.0, 1.0, dir)
			var us: int = Time.get_ticks_usec() - t0
			worst_us = maxi(worst_us, us)
			sum_us += us
			var r2: Dictionary = DirSwingRead.read(S, float(t % 400) / 60.0, 1.0, dir)
			if str(r) != str(r2):
				same = false
			_ok(float(r.value) >= -1.0 and float(r.value) <= 1.0, "out of range")
			n += 1
			var names: Dictionary = {}
			for x in r.terms:
				counts[x[0]] = int(counts.get(x[0], 0)) + 1
				names[x[0]] = true
			hist[clampi(int(floor((float(r.value) + 1.0) * 2.5)), 0, 4)] += 1
			# the model against the camera: does its idea of a split, a launch and a tightening match the rig's?
			var gap: float = absf(SimWrap.sdx(S.fighters[0].x, S.fighters[1].x))
			var apart: bool = gap > 2000.0
			agree["split"][0] += 1 if apart == (rig.sep > 0.5) else 0
			agree["split"][1] += 1
			if names.has("launch_release"):
				agree["launch"][0] += 1 if (rig.solo_kind == "launch" or rig.solo_kind == "hold" or rig.sep > 0.5 or rig.chase_slot >= 0) else 0
				agree["launch"][1] += 1
			if names.has("anticipation"):
				agree["ant"][0] += 1 if rig._ant_w > 0.0 else 0
				agree["ant"][1] += 1
		_ok(same, "seed %d: the same state read two ways" % seed)
		_ok(str(SimHash.stateHash(S).gameplay) == str(SimHash.stateHash(S2).gameplay), "seed %d: asking the read changed the match" % seed)
	print("reads %d, mean %.1f us, worst %d us" % [n, float(sum_us) / maxf(float(n), 1.0), worst_us])
	print("values -1 to -0.6, to -0.2, to 0.2, to 0.6, to 1: %s" % [hist])
	print("terms: %s" % [counts])
	for k in agree:
		var a: Array = agree[k]
		print("the model and the rig, %s: agree on %d of %d (%.0f%%)" % [k, a[0], a[1], 100.0 * float(a[0]) / maxf(float(a[1]), 1.0)])
	print("a line for the feed: ", DirSwingRead.text({"value": 0.7, "terms": [["launch_release", 0.6], ["flight_room", 0.3], ["near_split", -0.3]]}))
	if fails == 0:
		print("swing_read_check: %d checks passed" % checks)
	else:
		print("swing_read_check: %d of %d checks FAILED" % [fails, checks])
	quit(1 if fails > 0 else 0)
