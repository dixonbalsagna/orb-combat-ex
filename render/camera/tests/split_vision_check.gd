extends SceneTree
## The split vision's two switches (docs/camera/split-vision.md). eased_merge: two pictures are never blended, in real AI fights. split_ignores_power: the split opens at the same distance at any power, and the line moves over time.
##   godot --headless --path . --script res://render/camera/tests/split_vision_check.gd

var fails: int = 0
var checks: int = 0


func _ok(c: bool, what: String) -> void:
	checks += 1
	if not c:
		fails += 1
		print("FAIL ", what)


func _match(seed: int) -> SimState:
	var S: SimState = SimCore.createSim()
	SimCore.newMatch(S, seed, {"p1": true, "p2": true}, {"planet": 7, "touch": 1, "planetGen": 3, "intro": false})
	S.dt = SplitRig.DT
	return S


func _step(S: SimState, rig: SplitRig) -> SplitFrame:
	SimCore.step(S)
	var ev: Array = S.out.fx.duplicate()
	S.out.fx.clear()
	S.out.feed.clear()
	rig.step(S, 1280.0, 720.0, ev)
	return rig.current()


func _merge() -> void:
	var closings: int = 0
	var left_apart: float = 0.0
	for seed in [12345, 2]:
		var S: SimState = _match(seed)
		var rig := SplitRig.new()
		rig.eased_merge = true
		rig.reset(S, 1280.0, 720.0)
		var soft: int = 0
		var part: int = 0
		var prev_mode: String = "merged"
		var last_gap: float = 0.0
		for t in range(3600):
			var f: SplitFrame = _step(S, rig)
			if f.feather > 0.0:
				soft += 1
			if f.line_alpha != 0.0 and f.line_alpha != 1.0:
				part += 1
			if f.mode == "merged" and prev_mode == "closing":
				closings += 1
				left_apart = maxf(left_apart, last_gap)
			var A = S.fighters[0]
			var mx: float = SimWrap.wrap(A.x + 0.5 * SimWrap.sdx(A.x, S.fighters[1].x))
			var my: float = 0.5 * (A.y + S.fighters[1].y)
			last_gap = (f.screen_pos(0, mx, my) - f.screen_pos(1, mx, my)).length()
			prev_mode = f.mode
		_ok(soft == 0, "seed %d: %d ticks with a soft edge" % [seed, soft])
		_ok(part == 0, "seed %d: %d ticks with a part-faded line" % [seed, part])
	_ok(closings >= 2, "only %d merges to judge" % closings)
	_ok(left_apart < 3.0, "the line went with the pictures still %.1f px apart" % left_apart)
	print("merge: %d merges, the pictures at most %.1f px apart when the line goes" % [closings, left_apart])


func _power() -> void:
	# one flight, both at power 4: the split must open at about the same distance as at power 1
	var at: Array = []
	for tier in [1.0, 4.0]:
		var S: SimState = _match(12345)
		var rig := SplitRig.new()
		rig.split_ignores_power = true
		rig.reset(S, 1280.0, 720.0)
		var open_at: float = -1.0
		var x0: float = S.fighters[0].x
		var biggest: float = 0.0
		var last: float = rig._r_split()
		for t in range(900):
			S.fighters[0].tier = tier
			S.fighters[1].tier = tier
			var d: float = 300.0 if t < 500 else 300.0 + (t - 500) * 8.0
			S.fighters[0].ai = null
			S.fighters[1].ai = null
			S.fighters[0].state = "free"
			S.fighters[1].state = "free"
			S.fighters[0].x = SimWrap.wrap(x0 - d * 0.5)
			S.fighters[1].x = SimWrap.wrap(x0 + d * 0.5)
			S.fighters[0].y = WorldTerrain.groundY(S, S.fighters[0].x) + 500.0
			S.fighters[1].y = WorldTerrain.groundY(S, S.fighters[1].x) + 500.0
			S.fighters[0].vx = 0.0
			S.fighters[1].vx = 0.0
			var f: SplitFrame = _step(S, rig)
			biggest = maxf(biggest, absf(rig._r_split() - last))
			last = rig._r_split()
			if t >= 500 and open_at < 0.0 and rig.split_wanted:
				open_at = d
		at.append(open_at)
		_ok(open_at > 0.0, "power %.0f: the split never opened" % tier)
		_ok(biggest <= CamParams.R_SPLIT * SplitRig.DT / CamParams.SPLIT_POWER_EASE + 1e-9, "the line jumped %f in a tick" % biggest)
	print("the split opened at %.0f apart at power 1, %.0f at power 4" % [at[0], at[1]])
	_ok(absf(float(at[0]) - float(at[1])) < 0.1 * float(at[0]), "the split's distance moved with power: %.0f and %.0f" % [at[0], at[1]])


func _initialize() -> void:
	_merge()
	_power()
	print("split_vision_check: %d checks, %d failed" % [checks, fails] if fails > 0 else "split_vision_check: %d checks passed" % checks)
	quit(1 if fails > 0 else 0)
