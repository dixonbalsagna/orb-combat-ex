extends SceneTree
## The per-tick cost bench (docs/animation/tick-cost.md): the same seeded AI match run with the per-tick work worked out once a tick (RenderAnim.tick_fast, the default) and as it was before (--no-tick-fast),
## alternating round by round, with the microseconds a consume and a solve cost and a hash of every drawn pose (the bone rotations, the hips, the root offset, the ragdoll's angles and speeds, the follow-through
## and cloth springs). The two hashes are equal when the poses are the same bit for bit; machine noise is large, so the minimum of the rounds is reported with the mean.
##   godot --headless --path . --script res://render/anim/tools/tick_bench.gd [-- --seed=4 --ticks=1800 --skip=300 --rounds=3]

const DT := 1.0 / 60.0

var seed_: int = 4
var ticks: int = 1800
var skip: int = 300
var rounds: int = 3
var main: Node


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seed="):
			seed_ = int(a.substr(7))
		elif a.begins_with("--ticks="):
			ticks = int(a.substr(8))
		elif a.begins_with("--skip="):
			skip = int(a.substr(7))
		elif a.begins_with("--rounds="):
			rounds = int(a.substr(9))
	DirData.templatesProfile = "dynamic"
	var vpn := SubViewport.new()
	vpn.size = Vector2i(1280, 720)
	root.add_child(vpn)
	main = load("res://render/main.tscn").instantiate()
	main.manual = true
	vpn.add_child(main)
	_run.call_deferred()


func _mix(h: int, v) -> int:
	return (h * 1000003 + hash(v)) & 0x7fffffffffff


## One match: the consume and solve microseconds a call after the first `skip` ticks, and the pose hash over all of them.
func _one(fast: bool) -> Array:
	RenderAnim.tick_fast = fast
	RenderAnim.enabled = true
	main.start_match(seed_, {"p1": true, "p2": true})
	var h: int = 7
	var launched: int = 0
	var c_us: int = 0
	var c_n: int = 0
	var s_us: int = 0
	var s_n: int = 0
	while main.host.ticks < ticks:
		if main.host.ticks == skip:
			RenderAnim.consume_usec = 0
			RenderAnim.consume_count = 0
			RenderAnim.solve_usec = 0
			RenderAnim.solve_count = 0
		main.frame(DT)
		var S = main.host.S
		for f in S.fighters:
			var af: AnimFighter = RenderAnim.fighter(S, f)
			for qq in af.q:
				h = _mix(h, qq)
			h = _mix(h, af.hips)
			h = _mix(h, af.root_off)
			for v in af._rd.th:
				h = _mix(h, v)
			for v in af._rd.om:
				h = _mix(h, v)
			for v in af._fw_x:
				h = _mix(h, v)
			for v in af._fw_v:
				h = _mix(h, v)
			for v in af._sx:
				h = _mix(h, v)
			for v in af._sv:
				h = _mix(h, v)
			if String(f.state) == "launched":
				launched += 1
	c_us = RenderAnim.consume_usec
	c_n = RenderAnim.consume_count
	s_us = RenderAnim.solve_usec
	s_n = RenderAnim.solve_count
	return [float(c_us) / maxf(1.0, c_n), float(s_us) / maxf(1.0, s_n), h, launched]


func _run() -> void:
	await process_frame
	AnimData.load_all()
	var names: Array = ["fast (default)", "before (--no-tick-fast)"]
	var res: Array = [[], []]
	var hashes: Array = [0, 0]
	for r in range(rounds):
		for i in range(2):
			var o: Array = _one(i == 0)
			res[i].append(o)
			hashes[i] = o[2]
	for i in range(2):
		var mc: float = 1.0e9
		var ms: float = 1.0e9
		var sc: float = 0.0
		var ss: float = 0.0
		for o in res[i]:
			mc = minf(mc, o[0])
			ms = minf(ms, o[1])
			sc += o[0]
			ss += o[1]
		print("%-24s consume min %.1f us (mean %.1f) a call, solve min %.1f us (mean %.1f) a call, %d rounds, hash %d, launched samples %d" % [names[i], mc, sc / rounds, ms, ss / rounds, rounds, hashes[i], res[i][0][3]])
	print("TICKBENCH poses %s" % ("IDENTICAL" if hashes[0] == hashes[1] else "DIFFER"))
	RenderAnim.tick_fast = true
	quit(0 if hashes[0] == hashes[1] else 1)
