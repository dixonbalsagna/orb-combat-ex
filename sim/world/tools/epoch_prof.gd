extends SceneTree
# The calm turn's warm ticks at the real rate (Performance's k = 32; docs/perf/gen2-bench-2026-10-26.md): each tick of WorldEpoch.tick after a turn is decided, timed, with the ring's read (RingJob.step) and the swap's
# preparation (_prep) told apart: the worst tick is what the frame feels. Gen 1 and gen 2 side by side.
#   godot --headless --path . --script res://sim/world/tools/epoch_prof.gd [-- --k=32 --seed=7 --total]
func run(gen: int, k: int, seed: int) -> void:
	WorldClimate.useGen(gen)
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {}, {"planet": seed, "touch": 3, "arena": {"cols": 2400, "turn": true}, "planetGen": gen, "intro": false})
	for t in range(30):
		SimCore.step(S)
	S.T = 100.0
	var px: float = 0.5 * (S.fighters[0].x + S.fighters[1].x)
	var c: Array = WorldEpoch.ask(S, "prof", px, 1, 0)
	WorldEpoch.choose(S, c.size() - 1, k, 2.5)
	var times: Array = []
	var g: int = 0
	while S.epoch.next != null and g < 1200:
		var t0: int = Time.get_ticks_usec()
		WorldEpoch.tick(S, g > 60)
		times.append(float(Time.get_ticks_usec() - t0))
		g += 1
	var sum: float = 0.0
	var mx: float = 0.0
	for t in times:
		sum += t
		mx = maxf(mx, t)
	var first: float = times[0]
	var rings: int = 2
	print("gen %d, k %d: %d ticks to the swap; first tick %.2f ms, mean %.2f ms, worst %.2f ms; the whole warm %.0f ms for %d columns of rings (%.0f us a column all in)" % [gen, k, times.size(), first / 1000.0, sum / float(times.size()) / 1000.0, mx / 1000.0, sum / 1000.0, rings * SimConst.NC, sum / float(rings * SimConst.NC)])
	var worst3: String = ""
	var sorted: Array = times.duplicate()
	sorted.sort()
	sorted.reverse()
	for q in range(5):
		worst3 += " %.1f" % (sorted[q] / 1000.0)
	print("    the five worst ticks (ms):%s" % worst3)


func _init() -> void:
	WorldRingPick.cfg().turn["warmTotal"] = 1 if "--total" in OS.get_cmdline_user_args() else 0   # --total: k shared among the rings (the turn data's warmTotal)
	var k: int = 32
	var seed: int = 7
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--k="):
			k = int(a.substr(4))
		if a.begins_with("--seed="):
			seed = int(a.substr(7))
	run(1, k, seed)
	run(2, k, seed)
	quit()
