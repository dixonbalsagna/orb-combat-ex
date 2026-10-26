extends SceneTree
# The rings a calm turn really reads (the match's decided turn), read k columns a call as WorldEpoch._warm does: per call and per column, the first calls told apart.
#   godot --headless --path . --script res://sim/world/tools/warm_ring_prof.gd [-- --k=32 --seed=7 --gen=2]
func _init() -> void:
	var k: int = 32
	var seed: int = 7
	var gen: int = 2
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--k="):
			k = int(a.substr(4))
		if a.begins_with("--seed="):
			seed = int(a.substr(7))
		if a.begins_with("--gen="):
			gen = int(a.substr(6))
	WorldClimate.useGen(gen)
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {}, {"planet": seed, "touch": 3, "arena": {"cols": 2400, "turn": true}, "planetGen": gen, "intro": false})
	for t in range(30):
		SimCore.step(S)
	S.T = 100.0
	var px: float = 0.5 * (S.fighters[0].x + S.fighters[1].x)
	var c: Array = WorldEpoch.ask(S, "prof", px, 1, 0)
	WorldEpoch.choose(S, c.size() - 1, k, 2.5)
	var E = S.epoch
	for w in E.warm:
		var P := WorldPlanet.make(int(E.seed))
		var ring: Dictionary = WorldRingPick.ringFrom(w.spec.c, int(w.spec.cols), w.spec.t)
		var job := WorldPlanet.RingJob.new(P, ring)
		var times: Array = []
		while not job.done:
			var t1: int = Time.get_ticks_usec()
			job.step(k)
			times.append(float(Time.get_ticks_usec() - t1))
		var firsts: String = ""
		for q in range(3):
			firsts += " %.2f" % (times[q] / 1000.0)
		var sum: float = 0.0
		var worst: float = 0.0
		for t in times:
			sum += t
			worst = maxf(worst, t)
		var hs: String = ""
		var nland: int = 0
		for i in range(SimConst.NC):
			if job.slice.heights[i] > 0.0:
				nland += 1
		print("ring (", w.spec.cols, " columns, ", nland, " above sea): ", times.size(), " calls; first three (ms):", firsts, "; all ", sum / 1000.0, " ms = ", sum / float(SimConst.NC), " us a column; worst call ", worst / 1000.0, " ms")
	quit()
