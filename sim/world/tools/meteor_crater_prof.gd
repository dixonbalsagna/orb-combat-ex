extends SceneTree
# Timing of the meteor's dig (World; docs/world/meteor-crater.md): profile, no verdict. For Performance: the dig call itself, the 120 ticks before and after it (mean, p99, max), and what it touched.
#   godot --headless --path . --script res://sim/world/tools/meteor_crater_prof.gd -- [--planet=7] [--touch=1] [--rmax=6100] [--n=3]
# rmax overrides craters.json meteor.rMax for the run (to price a smaller bowl); n digs are made one after another a fighter-width apart in x, as a match with 3 meteors does, timed one by one.
func _stats(a: Array) -> String:
	if a.is_empty():
		return "-"
	var b: Array = a.duplicate()
	b.sort()
	var s: float = 0.0
	for v in b:
		s += v
	return "mean %d us, p50 %d, p99 %d, max %d (%d ticks)" % [s / b.size(), b[b.size() / 2], b[int(b.size() * 0.99)], b[b.size() - 1], b.size()]


func _ticks(S: SimState, n: int) -> Array:
	var out: Array = []
	for i in range(n):
		var a: int = Time.get_ticks_usec()
		SimCore.step(S)
		out.append(Time.get_ticks_usec() - a)
	return out


func _init() -> void:
	var planet: int = 7
	var touch: int = 1
	var rmax: float = -1.0
	var count: int = 3
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--planet="):
			planet = int(a.substr(9))
		elif a.begins_with("--touch="):
			touch = int(a.substr(8))
		elif a.begins_with("--rmax="):
			rmax = float(a.substr(7))
		elif a.begins_with("--n="):
			count = int(a.substr(4))
	if rmax > 0.0:
		WorldCraters.data()["meteor"] = {"eMult": 9.0, "rMax": rmax}
	WorldClimate.useGen(3)
	WorldPlanet.forget()
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {}, {"intro": false, "planet": planet, "touch": touch, "planetGen": 3})
	_ticks(S, 60)
	var E: float = WorldCrater.impactEnergy(8570.0, 4.0)
	print("planet %d touch %d, E %.1f, rMax %.0f, %d trees, %d buildings" % [planet, touch, E, WorldCraters.meteorRMax(), S.trees.size(), S.buildings.size()])
	for k in range(count):
		var before: Array = _ticks(S, 120)
		var x: float = S.fighters[0].x + float(k) * 900.0
		var ev0: int = S.out.fx.size()
		var tr0: int = 0
		for t in S.trees:
			if t.alive:
				tr0 += 1
		var cr0: int = S.craters.size()
		var t0: int = Time.get_ticks_usec()
		var rec = WorldCrater.dig(S, x, E, S.fighters[0], "impact", 0.0, 1.0, false, NAN, PackedFloat64Array(), true)
		var td: int = Time.get_ticks_usec() - t0
		var tr1: int = 0
		for t in S.trees:
			if t.alive:
				tr1 += 1
		print("dig %d: %d us, r %.0f depth %.0f rim %.0f, %d craters on the list, %d trees felled, %d fx events, store %s" % [k + 1, td, rec.r if rec != null else -1.0, rec.depth if rec != null else -1.0, rec.rim if rec != null else -1.0, S.craters.size() - cr0, tr0 - tr1, S.out.fx.size() - ev0, str(S.store.size()) if "store" in S else "-"])
		print("  120 ticks before: ", _stats(before))
		print("  120 ticks after:  ", _stats(_ticks(S, 120)))
		print("  next 240 ticks:   ", _stats(_ticks(S, 240)))
	quit(0)
