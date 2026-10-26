extends SceneTree
# A touch-down's ring read (WorldPlanet.sliceFor), piece by piece: the touch point, the candidate circles, each circle's evaluation, the read of the ring.
#   godot --headless --path . --script res://sim/world/tools/touch_prof.gd [-- --seed=13 --cols=2400 --gen=2]
func _init() -> void:
	var seed: int = 13
	var cols: int = 2400
	var gen: int = 2
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seed="):
			seed = int(a.substr(7))
		if a.begins_with("--cols="):
			cols = int(a.substr(7))
		if a.begins_with("--gen="):
			gen = int(a.substr(6))
	WorldClimate.useGen(gen)
	SimConst.setArena(cols)
	var P := WorldPlanet.make(seed)
	for touch in [1, 2, 3, 5]:
		var t0: int = Time.get_ticks_usec()
		var T: Array = WorldPlanet.touchPoint(P, touch)
		var t1: int = Time.get_ticks_usec()
		var cand: Array = WorldPlanet.candidates(P, T, touch, PackedByteArray())
		var t2: int = Time.get_ticks_usec()
		var evals: Array = []
		var picked = null
		var c: Dictionary = P.c
		for circ in cand:
			var te: int = Time.get_ticks_usec()
			var e: Dictionary = WorldPlanet.evalCircle(P, circ, PackedByteArray(), int(c.minCities), int(c.minTowns))
			evals.append(float(Time.get_ticks_usec() - te) / 1000.0)
			if WorldPlanet.meets(c, e, false):
				picked = circ
				break
		var t3: int = Time.get_ticks_usec()
		var s: String = ""
		for q in evals:
			s += " %.1f" % q
		print("touch %d: point %.2f ms, %d candidates %.2f ms, evaluations (ms):%s, in all %.1f ms; samples a circle %s" % [touch, float(t1 - t0) / 1000.0, cand.size(), float(t2 - t1) / 1000.0, s, float(t3 - t2) / 1000.0, str(c.samples)])
		if picked != null:
			var t4: int = Time.get_ticks_usec()
			var sl: WorldPlanet.Slice = WorldPlanet.readSlice(P, WorldPlanet.ringThrough(picked, SimConst.NC, 1), WorldPlanet.touchPoint(P, touch), PackedByteArray())
			print("   the ring read: %.1f ms (%d columns)" % [float(Time.get_ticks_usec() - t4) / 1000.0, SimConst.NC])
	quit()
