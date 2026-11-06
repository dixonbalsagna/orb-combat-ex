extends SceneTree
## The unequal split (docs/camera/split-unequal.md): against a CPU the player's pane takes the larger share, each fighter stays in his own pane, the line eases with the panes, and two humans or the switch off stay even.
##   godot --headless --path . --script res://render/camera/tests/split_share_check.gd

var fails: int = 0
var checks: int = 0


func _ok(c: bool, what: String) -> void:
	checks += 1
	if not c:
		fails += 1
		print("FAIL ", what)


## A staged flight apart and back: returns what the divider and the fighters did.
func _run(share: float, human: int, side: float) -> Dictionary:
	var S: SimState = SimCore.createSim()
	SimCore.newMatch(S, 12345, {"p1": false, "p2": false}, {"planet": 7, "touch": 1, "planetGen": 3, "intro": false})
	S.dt = SplitRig.DT
	var rig := SplitRig.new()
	rig.split_share = share
	rig.test_human_slot = human
	rig.reset(S, 1280.0, 720.0)
	var x0: float = S.fighters[0].x
	var out: Dictionary = {"biggest": 0.0, "wide": 0.0, "in0": 0, "in1": 0, "split": 0, "merged_end": false, "largest_share": 0.0}
	var last_c: float = NAN
	for t in range(900):
		var d: float = 300.0
		if t > 200 and t <= 500:
			d = 300.0 + (t - 200) * 20.0
		elif t > 500:
			d = maxf(300.0, 6300.0 - (t - 500) * 20.0)
		var i: int = 0
		for f in S.fighters:
			f.ai = null
			f.state = "free"
			f.vx = 0.0
			f.vy = 0.0
			f.x = SimWrap.wrap(x0 + side * (-0.5 if i == 0 else 0.5) * d)
			f.y = WorldTerrain.groundY(S, f.x) + 500.0
			i += 1
		SimCore.step(S)
		S.out.fx.clear()
		S.out.feed.clear()
		rig.step(S, 1280.0, 720.0, [])
		var fr: SplitFrame = rig.current()
		if not is_nan(last_c):
			out.biggest = maxf(float(out.biggest), absf(fr.c.x - last_c) / 1280.0)
		last_c = fr.c.x
		if fr.sep >= 0.999 and fr.e <= 0.001:
			out.split = int(out.split) + 1
			var a: Vector2 = fr.screen_pos(0, S.fighters[0].x, S.fighters[0].y + CamParams.CHEST)
			var b: Vector2 = fr.screen_pos(1, S.fighters[1].x, S.fighters[1].y + CamParams.CHEST)
			if fr.weight1(a) == 0.0 and a.x > 0.0 and a.x < 1280.0:
				out.in0 = int(out.in0) + 1
			if fr.weight1(b) == 1.0 and b.x > 0.0 and b.x < 1280.0:
				out.in1 = int(out.in1) + 1
			# pane 1's share of the middle row, at the line
			var share1: float = 1.0 - fr.c.x / 1280.0 if fr.n.x >= 0.0 else fr.c.x / 1280.0
			out.largest_share = share1
		out.merged_end = fr.sep <= 0.001
	return out


## Real AI fights at 70/30, the player in slot 0: he never leaves his own pane. The CPU's narrow pane is reported, not failed: he can leave it for a moment.
func _real() -> void:
	var worst: Array = [0, 0]
	for seed in [1, 2, 3]:
		var S: SimState = SimCore.createSim()
		SimCore.newMatch(S, seed, {"p1": true, "p2": true}, {"planet": [7, 3, 11, 25][seed % 4], "touch": 1, "planetGen": 3, "intro": false})
		S.dt = SplitRig.DT
		var rig := SplitRig.new()
		rig.swing_view = true
		rig.peak_launch = true
		rig.launch_director = true
		rig.readable = true
		rig.split_share = 0.7
		rig.test_human_slot = 0
		rig.reset(S, 1280.0, 720.0)
		var run: Array = [0, 0]
		for t in range(3600):
			SimCore.step(S)
			var ev: Array = S.out.fx.duplicate()
			S.out.fx.clear()
			S.out.feed.clear()
			rig.step(S, 1280.0, 720.0, ev)
			var fr: SplitFrame = rig.current()
			for i in range(2):
				var gone: bool = false
				if fr.sep >= 0.999 and fr.e <= 0.001 and rig._slam_slot < 0 and rig._pk_phase == "":
					var f = S.fighters[i]
					var sp: Vector2 = fr.screen_pos(i, f.x, f.y + CamParams.CHEST)
					gone = sp.x < 0.0 or sp.x > 1280.0 or sp.y < 0.0 or sp.y > 720.0 or fr.weight1(sp) != (1.0 if i == 1 else 0.0)
				run[i] = int(run[i]) + 1 if gone else 0
				worst[i] = maxi(int(worst[i]), int(run[i]))
	print("real fights at 70/30: the player out of his pane at most %d ticks, the CPU out of his at most %d" % [worst[0], worst[1]])
	_ok(int(worst[0]) <= 15, "the player out of his pane for %d ticks" % worst[0])


## A beam struggle: the line eases back to the middle, and out again after.
func _even() -> void:
	var S: SimState = SimCore.createSim()
	SimCore.newMatch(S, 12345, {"p1": false, "p2": false}, {"planet": 7, "touch": 1, "planetGen": 3, "intro": false})
	var rig := SplitRig.new()
	rig.split_share = 0.7
	rig.test_human_slot = 1
	rig.reset(S, 1280.0, 720.0)
	rig.sep = 1.0
	rig.split_wanted = true
	var n := Vector2(1.0, 0.0)
	rig.r_now = 0.01
	rig._sh_slot = 1
	var far: float = absf(rig._share_delta(n))
	_ok(far > 200.0, "the share moves the line: %.0f" % far)
	rig._sh_w = 0.0
	_ok(rig._share_delta(n) == 0.0, "in a struggle the line is in the middle")
	var rec: Dictionary = SplitFrame.new().split_record()
	_ok(rec.has("share") and rec.has("share_slot") and float(rec["share"]) == 0.0 and int(rec["share_slot"]) == -1, "the record carries the share")
	rig._sh_w = 0.5
	_ok(absf(rig._share_delta(n)) < far and absf(rig._share_delta(n)) > 0.0, "and it eases between")


func _initialize() -> void:
	var off: Dictionary = _run(0.0, 1, 1.0)
	var even: Dictionary = _run(0.7, -1, 1.0)
	_ok(absf(float(even.largest_share) - 0.5) < 0.03, "two humans stay even: pane 1 has %.2f" % even.largest_share)
	for row in [[1, 1.0], [0, 1.0], [1, -1.0], [0, -1.0]]:
		var r: Dictionary = _run(0.7, int(row[0]), float(row[1]))
		var mine: float = float(r.largest_share) if int(row[0]) == 1 else 1.0 - float(r.largest_share)
		print("player %d, side %+.0f: his pane %.2f of the width, line's biggest step %.4f, in his pane %d and %d of %d, merged at the end %s" % [row[0], row[1], mine, r.biggest, r.in0, r.in1, r.split, r.merged_end])
		_ok(int(r.split) > 200, "a real split: %d ticks" % r.split)
		_ok(mine > 0.62 and mine < 0.78, "his pane %.2f" % mine)
		_ok(int(r.in0) >= int(r.split) - 2 and int(r.in1) >= int(r.split) - 2, "each in his own pane: %d, %d of %d" % [r.in0, r.in1, r.split])
		_ok(float(r.biggest) < 0.03, "the line stepped %.4f of the width in a tick" % r.biggest)
		_ok(bool(r.merged_end), "merged at the end")
	print("line's biggest step, off: %.4f" % off.biggest)
	_even()
	_real()
	print("split_share_check: %d checks, %d failed" % [checks, fails] if fails > 0 else "split_share_check: %d checks passed" % checks)
	quit(1 if fails > 0 else 0)
