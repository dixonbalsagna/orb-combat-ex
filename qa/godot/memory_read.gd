extends SceneTree
## A memory reading at 5 and 30 minutes of computer-against-computer play (sprint A1, A-PERF-07, for Performance): plays seeded AI v AI matches one after another on the sim alone (no window) and prints the process's static memory, the object count and the
## orphan nodes at each mark of cumulative sim time, so a leak shows as a climb. Matches are disposed between runs, as the game does.
##   bash tools/godot-run.sh --path <tree copy with qa/godot/qa_planet.gd> --script res://qa/godot/memory_read.gd -- [--marks=5,30] [--level=easy|medium|hard] [--base=1]
## Lines: MEM <json> at every mark and a first line at tick 0; a last line MEMDONE. Static memory is the engine's own count (OS.get_static_memory_usage), in MiB; headless has no video memory, so this is the process's CPU-side memory only. Read-only with respect to sim/.
const QaPlanet = preload("res://qa/godot/qa_planet.gd")


func _init() -> void:
	var marks: Array = [5, 30]
	var level: String = "medium"
	var base: int = 1
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--marks="):
			marks = Array(a.substr(8).split(",", false)).map(func(x): return int(x))
		elif a.begins_with("--level="):
			level = a.substr(8)
		elif a.begins_with("--base="):
			base = int(a.substr(7))
	SimInputData.load_and_apply()
	var dai = load("res://sim/director/ai.gd")
	dai.set("level", level)
	_print("start", 0, 0)
	var total: int = 0
	var seed_: int = base
	var mi: int = 0
	var matches: int = 0
	while mi < marks.size():
		var su: Dictionary = QaPlanet.setup(seed_)
		su["intro"] = false
		var S := SimCore.createSim()
		SimCore.newMatch(S, seed_, {"p1": true, "p2": true}, su)
		if QaPlanet.fellBack(S, seed_):
			quit(3)
			return
		var koSeen: int = -1
		for t in range(60 * 900):
			SimCore.step(S, [null, null])
			S.out.fx.clear()
			S.out.feed.clear()
			total += 1
			if S.game.ko != null and koSeen < 0:
				koSeen = t
			if koSeen >= 0 and S.game.koT > 3.0:
				break
			if mi < marks.size() and total >= int(marks[mi]) * 3600:
				_print("mark", int(marks[mi]), matches)
				mi += 1
				if mi >= marks.size():
					break
		SimCore.dispose(S)
		matches += 1
		seed_ += 1
	_print("done", total / 3600, matches)
	print("MEMDONE matches %d ticks %d" % [matches, total])
	quit()


func _print(kind: String, minutes: int, matches: int) -> void:
	var o := {"kind": kind, "simMinutes": minutes, "matches": matches, "staticMiB": snappedf(float(OS.get_static_memory_usage()) / 1048576.0, 0.1), "peakMiB": snappedf(float(OS.get_static_memory_peak_usage()) / 1048576.0, 0.1),
		"objects": int(Performance.get_monitor(Performance.OBJECT_COUNT)), "orphans": int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)), "resources": int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT))}
	print("MEM " + JSON.stringify(o))
