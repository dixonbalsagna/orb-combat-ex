extends SceneTree
## Probe (scratch): a match on each named planet size, timed. godot --headless --path . --script res://sim/world/tools/size_probe.gd -- small big [planet=7] [touch=1] [ticks=300]
func _init() -> void:
	var names: Array = []
	var planet: int = 7
	var touch: int = 1
	var ticks: int = 300
	for a in OS.get_cmdline_user_args():
		if a.begins_with("planet="):
			planet = int(a.substr(7))
		elif a.begins_with("touch="):
			touch = int(a.substr(6))
		elif a.begins_with("ticks="):
			ticks = int(a.substr(6))
		else:
			names.append(a)
	WorldPlanetSize.heldOverride = true   # a probe plays any size the data has, offered or not (tiny, small and huge are held)
	for nm in names:
		WorldClimate.useGen(3)
		var t0: int = Time.get_ticks_usec()
		var S := SimCore.createSim()
		SimCore.newMatch(S, 5, {"p1": false, "p2": false}, {"intro": false, "planet": planet, "touch": touch, "planetGen": 3, "planetSize": nm})
		var tm: float = float(Time.get_ticks_usec() - t0) / 1.0e6
		var t1: int = Time.get_ticks_usec()
		for t in range(ticks):
			SimCore.step(S)
		var t2: int = Time.get_ticks_usec()
		var f0 = S.fighters[0]
		var f1 = S.fighters[1]
		print(WorldPlanetSize.dataErrors()); print("%s: planetNC %d arena %d NC %d R %.0f; start %.2f s, %d ticks %.2f s (%.2f ms/tick); fighters x %.0f %.0f y %.0f %.0f; buildings %d trees %d; frame %s" % [nm, S.planetNC, S.arenaCols, SimConst.NC, SimField.R, (t1 - t0) / 1.0e6, ticks, (t2 - t1) / 1.0e6, (t2 - t1) / 1000.0 / float(ticks), f0.x, f1.x, f0.y, f1.y, S.structures.size() if "structures" in S else -1, S.trees.size(), str(S.frame != null)])
		SimCore.dispose(S)
	quit(0)
