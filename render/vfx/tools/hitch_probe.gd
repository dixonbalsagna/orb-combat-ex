extends SceneTree
## A headless frame-time probe for first-use hitches (docs/vfx/warm-up.md; Performance's audit section 3.6). It plays an AI match natively, one tick a frame, and lists the frames that took
## longest with the split the host keeps (the sim tick, the effects and camera, and the rest: the views' GDScript and the audio). It sees the CPU side only: a shader the graphics driver compiles on
## its first draw (the cause the audit suspects) does not exist in the headless renderer, so a hitch of that kind shows here as nothing, and the web build is where it is tested.
## Like the game it warms the audio bank first (main.gd skips that in headless: without it every first sound shows as a 10 to 60 ms hitch that the game does not have).
##   godot --headless --path . --script res://render/vfx/tools/hitch_probe.gd -- [--seed=4] [--ticks=1500] [--top=12] [--min-ms=6] [--audio-warm=0|1]
## Run it at below-normal priority, on a quiet machine: a hitch must be the same ticks in two runs to count.

var m: Node


func _initialize() -> void:
	_run.call_deferred()


func _arg(key: String, d: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--%s=" % key):
			return a.substr(key.length() + 3)
	return d


func _run() -> void:
	var seed_v: int = int(_arg("seed", "4"))
	var ticks: int = int(_arg("ticks", "1500"))
	var top: int = int(_arg("top", "12"))
	var min_ms: float = float(_arg("min-ms", "6"))
	var packed = load("res://render/main.tscn")
	m = packed.instantiate()
	root.add_child(m)
	await process_frame
	m.set_process(false)
	m.set_physics_process(false)
	if _arg("audio-warm", "1") != "0":
		m.host.audio_cues.bank.warm()
	var rows: Array = []
	var first_beam: int = -1
	var first_beam_ms: float = 0.0
	var all_ms := PackedFloat64Array()
	for t in range(1, ticks + 1):
		var t0: int = Time.get_ticks_usec()
		m.host.acc = SimConst.DT * 0.9999
		m.frame(SimConst.DT)
		var ms: float = (Time.get_ticks_usec() - t0) / 1000.0
		var sim: float = m.host.tick_usec / 1000.0
		var fx: float = m.host.fx_usec / 1000.0
		all_ms.append(ms)
		if first_beam < 0 and not m.host.S.beams.is_empty():
			first_beam = t
			first_beam_ms = ms
		if t > 3 and ms >= min_ms:
			rows.append([ms, t, sim, fx, ms - sim - fx])
	rows.sort_custom(func(a, b): return a[0] > b[0])
	var sorted_ms := all_ms.duplicate()
	sorted_ms.sort()
	print("hitch probe: seed %d, %d ticks, median %.2f ms, p99 %.2f ms, max %.2f ms" % [seed_v, ticks, sorted_ms[sorted_ms.size() / 2], sorted_ms[int(sorted_ms.size() * 0.99)], sorted_ms[sorted_ms.size() - 1]])
	print("first beam at tick %d: frame took %.2f ms" % [first_beam, first_beam_ms])
	for i in range(mini(top, rows.size())):
		var r: Array = rows[i]
		print("  tick %5d  %6.2f ms   sim %.2f  fx+camera %.2f  views, audio and the rest %.2f" % [r[1], r[0], r[2], r[3], r[4]])
	print("hitch probe done")
	quit(0)
