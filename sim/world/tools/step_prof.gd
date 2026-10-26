extends SceneTree
# A ring read k columns a call from a planet just made, as the calm turn does: the first calls (the planet's own cold work, the climate grid) and the rest, per call and per column.
#   godot --headless --path . --script res://sim/world/tools/step_prof.gd [-- --k=32 --gen=2]
func _init() -> void:
	var k: int = 32
	var gen: int = 2
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--k="):
			k = int(a.substr(4))
		if a.begins_with("--gen="):
			gen = int(a.substr(6))
	WorldClimate.useGen(gen)
	SimConst.setArena(2400)
	for round in range(2):
		var t0: int = Time.get_ticks_usec()
		var P := WorldPlanet.make(7)
		print("round ", round, ": make ", float(Time.get_ticks_usec() - t0) / 1000.0, " ms")
		var T: Array = WorldPlanet.unitFromDraws(0.37, 0.62)
		var spec: Dictionary = WorldRingPick.roundSpec(T, 2400, 0.9)
		var ring: Dictionary = WorldRingPick.ringFrom(spec.c, 2400, spec.t)
		var job := WorldPlanet.RingJob.new(P, ring)
		var times: Array = []
		while not job.done:
			var t1: int = Time.get_ticks_usec()
			job.step(k)
			times.append(float(Time.get_ticks_usec() - t1))
		var firsts: String = ""
		for q in range(4):
			firsts += " %.2f" % (times[q] / 1000.0)
		var rest: float = 0.0
		var worst: float = 0.0
		for q in range(4, times.size()):
			rest += times[q]
			worst = maxf(worst, times[q])
		print("  ", times.size(), " calls of ", k, " columns; the first four calls (ms):", firsts, "; the rest: mean ", rest / float(times.size() - 4) / 1000.0, " ms a call (", rest / float(times.size() - 4) / float(k), " us a column), worst ", worst / 1000.0, " ms")
	quit()
