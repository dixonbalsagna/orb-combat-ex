extends SceneTree
# What a place-try costs, by how far it gets (the height test 3, the gap test 6, the score 14 units): each try timed on its own (a budget of one unit a call).
#   godot --headless --path . --script res://sim/world/tools/try_prof.gd [-- --seed=13 --b]
func _init() -> void:
	var seed: int = 13
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seed="):
			seed = int(a.substr(7))
	WorldClimate.useGen(2)
	if "--b" in OS.get_cmdline_user_args():
		WorldLand.setB(true)
	WorldPlanet.forget()
	var P := WorldPlanet._newPlanet(seed, 2)
	WorldClimate.gridOf(P)
	var st: Dictionary = WorldPlanet._placeBegin(P)
	var sum: Dictionary = {}
	var cnt: Dictionary = {}
	var worst: Dictionary = {}
	var fin: bool = false
	var n: int = 0
	while not fin:
		st.spent = 0
		var t0: int = Time.get_ticks_usec()
		fin = WorldPlanet._placeStep(P, st, 1)
		var us: float = float(Time.get_ticks_usec() - t0)
		var k: int = int(st.spent)
		sum[k] = sum.get(k, 0.0) + us
		cnt[k] = cnt.get(k, 0) + 1
		worst[k] = maxf(worst.get(k, 0.0), us)
		n += 1
	var keys: Array = sum.keys()
	keys.sort()
	for k in keys:
		print("units ", k, ": ", cnt[k], " calls, mean ", snappedf(sum[k] / float(cnt[k]), 0.1), " us, worst ", worst[k], " us")
	print(n, " calls")
	quit()
