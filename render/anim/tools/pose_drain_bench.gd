extends SceneTree
## The missing-pose lookup (docs/animation/cloud-reports/2026-10-28-pose-drain.md): a seeded AI-vs-AI match through the main scene with the incremental bake on, timing every frame.
## Prints the worst single frame (and its tick), the bake's queue runs, on-demand bakes and early wave loads. Native and headless, so the times are this machine's, not a phone's.
## `godot --headless --path . -s res://render/anim/tools/pose_drain_bench.gd -- --lazy-bake [--seeds=12345,4] [--ticks=900] [--intro]`
var seeds: Array = [12345, 4]
var max_ticks: int = 900
var intro: bool = false
var probes: Array = []   # --probe=a,b: pose ids asked for (pose_exists) inside the first frame after the match starts, while the queue is still full, as a layer asking for a pose would


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seeds="):
			seeds = Array(a.substr(8).split(",")).map(func(s): return int(s))
		elif a.begins_with("--ticks="):
			max_ticks = int(a.substr(8))
		elif a == "--intro":
			intro = true
		elif a.begins_with("--probe="):
			probes = Array(a.substr(8).split(","))
	_run.call_deferred()


func _run() -> void:
	for seed in seeds:
		var vpn := SubViewport.new()
		vpn.size = Vector2i(1280, 720)
		root.add_child(vpn)
		var main: Node = load("res://render/main.tscn").instantiate()
		main.manual = true
		vpn.add_child(main)
		await process_frame
		var d0: int = AnimData.bake_drains
		var o0: int = AnimData.bake_demand
		var e0: int = AnimData.bake_early
		var f0: int = Time.get_ticks_usec()
		main.manual = not intro
		main.start_match(seed, {"p1": true, "p2": true})
		main.manual = true
		var start_ms: float = float(Time.get_ticks_usec() - f0) / 1000.0
		var host: SimHost = main.host
		var worst: int = 0
		var worst_tick: int = 0
		var times: Array = []
		while host.ticks < max_ticks and not (host.S.game.ko != null and host.S.game.koT > 3.0):
			var t0: int = Time.get_ticks_usec()
			main.frame(1.0 / 60.0)
			if times.is_empty() and not probes.is_empty():
				var pr: Array = []
				for pid in probes:
					var p0: int = Time.get_ticks_usec()
					var ok: bool = AnimData.pose_exists(String(pid))
					pr.append("%s %s %.2f ms" % [pid, "found" if ok else "absent", float(Time.get_ticks_usec() - p0) / 1000.0])
				print("PROBE first frame (queue %d pieces, %d poses): %s" % [AnimData._work.size(), AnimData._pend.size(), "; ".join(PackedStringArray(pr))])
			var dt: int = Time.get_ticks_usec() - t0
			times.append(dt)
			if dt > worst:
				worst = dt
				worst_tick = host.ticks
		times.sort()
		var e1: int = AnimData.bake_early
		print("DRAINBENCH seed=%d lazy=%s ticks=%d start_ms=%.1f worst_frame_ms=%.2f at_tick=%d p99_ms=%.2f median_ms=%.2f queue_runs=%d on_demand_poses=%d early_waves=%d idle=%s" % [seed, str(AnimData.lazy), host.ticks, start_ms, float(worst) / 1000.0, worst_tick, float(times[int(times.size() * 0.99)]) / 1000.0, float(times[times.size() / 2]) / 1000.0, AnimData.bake_drains - d0, AnimData.bake_demand - o0, e1 - e0, str(AnimData.bake_idle())])
		vpn.queue_free()
		await process_frame
	quit()
