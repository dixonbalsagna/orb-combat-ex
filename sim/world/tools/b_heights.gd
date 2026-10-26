extends SceneTree
# Window 13: the heights of dry land on B plates (percentiles), for the climate's thresholds.
#   godot --headless --path . --script res://sim/world/tools/b_heights.gd -- [--b] --seeds=7,11,42
func _init() -> void:
	var useB: bool = false
	var seeds: Array = [7, 11, 42]
	for a in OS.get_cmdline_user_args():
		if a == "--b":
			useB = true
		if a.begins_with("--seeds="):
			seeds = Array(a.substr(8).split(",")).map(func(v): return int(v))
	WorldClimate.useGen(2)
	if useB:
		WorldLand.setB(true)
	for sd in seeds:
		var P := WorldPlanet.make(sd)
		var hs: Array = []
		var n: int = 0
		for k in range(40000):
			var q: Array = WorldPlateB._randUnit(sd, 7777, k)
			if absf(q[1]) > 0.72:
				continue
			n += 1
			WorldPlanet.surfAt(P, q[0], q[1], q[2])
			if P.outH > 0.0 and P.outB != WorldPlanet.BIO_ICE_SHEET:
				hs.append(P.outH)
		hs.sort()
		var out: String = "seed %d (%s): %d land points of %d; heights at the percentiles 50 75 85 90 93 95 97 99: " % [sd, "B" if useB else "window 3", hs.size(), n]
		for pc in [50, 75, 85, 90, 93, 95, 97, 99]:
			out += "%.0f " % hs[mini(hs.size() - 1, hs.size() * pc / 100)]
		print(out)
	quit()
