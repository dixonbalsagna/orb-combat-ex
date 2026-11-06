extends SceneTree
## The VFX script cost of a real match, per frame, headless: the hub's consume (`h_vfx`) plus every pane's layer update (`r_vfxlayer`), at three settings (docs/vfx/perf-level.md; Performance's order of 2026-10-31):
##   high   VFX quality high
##   low    VFX quality low (`Q_LOW`): what the Performance level has today
##   perf   quality low and the hub's `perf_level` on: the smaller pool, the batched overflow, the far-side skip, the job cap
## It plays the real game scene (render/main.tscn in a SubViewport) for each seed with the forms readied and a tier raised, as hash_check does, one frame to the tick, and prints mean, p50, p95, p99 and max of the
## frame's VFX script time in ms, and the pool's peak. Headless means the dummy renderer: the numbers are the SCRIPT side only (what Performance's 2.2 table calls h_vfx and r_vfxlayer); the GPU is not here.
## One process, so another session's load adds noise: read the ratios against `high`, and run it in a quiet window or at below-normal priority (the numbers marked `load` are the machine's, not the game's).
##   godot --headless --path . --script res://render/vfx/tools/perf_bench.gd -- [--seeds=12345,4,7] [--ticks=2400] [--modes=high,low,perf]

const FORM_TICKS: Array = [300, 1500]
var seeds: Array = [12345, 4, 7]
var max_ticks: int = 2400
var modes: Array = ["high", "low", "perf"]
var main: Node


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seeds="):
			seeds = Array(a.substr(8).split(",")).map(func(s): return int(s))
		elif a.begins_with("--ticks="):
			max_ticks = int(a.substr(8))
		elif a.begins_with("--modes="):
			modes = Array(a.substr(8).split(","))
	var vpn := SubViewport.new()
	vpn.size = Vector2i(1280, 720)
	vpn.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vpn)
	main = load("res://render/main.tscn").instantiate()
	main.manual = true
	vpn.add_child(main)
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var hub = main.host.vfx
	hub.auto_quality = false
	hub.cracks_enabled = true
	hub.destruction_enabled = true
	hub.embers_enabled = true
	var results: Dictionary = {}
	for mode in modes:
		var all := PackedFloat64Array()
		var peak: int = 0
		var spawned: int = 0
		var dropped: int = 0
		var spilled: int = 0
		var skipped: int = 0
		var held: int = 0
		for seed in seeds:
			main.start_match(seed, {"p1": true, "p2": true})
			hub = main.host.vfx
			hub.auto_quality = false
			hub.quality = VfxLook.Q_HIGH if mode == "high" else VfxLook.Q_LOW
			hub.perf_level = mode == "perf" if "perf_level" in hub else false
			var host: SimHost = main.host
			var forms_cb := func(n: int):
				if FORM_TICKS.has(n):
					for f in host.S.fighters:
						f.act.formReady = true
				if n == 900:
					host.S.fighters[0].tier = 3.0
				if n == 1200:
					host.S.fighters[1].stage[1] = 2
			host.ticked.connect(forms_cb)
			var c0: int = hub.stat_consume_usec
			var l0: Array = []
			for pw in main.panes:
				l0.append(pw.vfx_layer.stat_update_usec)
			while host.ticks < max_ticks:
				var c_before: int = hub.stat_consume_usec
				var l_before: int = 0
				for pw in main.panes:
					l_before += pw.vfx_layer.stat_update_usec
				main.frame(1.0 / 60.0)
				var c_after: int = hub.stat_consume_usec
				var l_after: int = 0
				for pw in main.panes:
					l_after += pw.vfx_layer.stat_update_usec
				if host.ticks > 120:
					all.append(float(c_after - c_before + l_after - l_before) / 1000.0)
				peak = maxi(peak, hub.debris.bits.size())
			host.ticked.disconnect(forms_cb)
			spawned += hub.debris.spawned
			dropped += hub.debris.dropped
			if "spilled" in hub.debris:
				spilled += hub.debris.spilled
				skipped += hub.debris.skipped_far
				held += hub.debris.jobs_held
		results[mode] = all
		print("%-5s %d frames  VFX script ms: mean %.3f  p50 %.3f  p95 %.3f  p99 %.3f  max %.3f | pool peak %d, spawned %d, dropped %d, batched %d, far-skipped %d, jobs held %d" % [mode, all.size(), _mean(all), _pct(all, 0.5), _pct(all, 0.95), _pct(all, 0.99), _max(all), peak, spawned, dropped, spilled, skipped, held])
	if results.has("low") and results.has("perf"):
		print("perf against low: mean %+.3f ms, p95 %+.3f ms, p99 %+.3f ms" % [_mean(results["perf"]) - _mean(results["low"]), _pct(results["perf"], 0.95) - _pct(results["low"], 0.95), _pct(results["perf"], 0.99) - _pct(results["low"], 0.99)])
	quit()


func _mean(v: PackedFloat64Array) -> float:
	if v.is_empty():
		return 0.0
	var s: float = 0.0
	for x in v:
		s += x
	return s / float(v.size())


func _max(v: PackedFloat64Array) -> float:
	var m: float = 0.0
	for x in v:
		m = maxf(m, x)
	return m


func _pct(v: PackedFloat64Array, p: float) -> float:
	if v.is_empty():
		return 0.0
	var a: Array = Array(v)
	a.sort()
	return float(a[clampi(int(floor(p * float(a.size() - 1))), 0, a.size() - 1)])
