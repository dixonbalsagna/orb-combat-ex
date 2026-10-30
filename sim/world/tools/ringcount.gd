extends SceneTree
# World W7 probe: structures on a gen 2 ring (QA's planets and touches), per ring and per place kind, and the densest window.
#   godot --headless --path . --script res://sim/world/tools/ringcount.gd -- [--cols=2400] [--gen=2]
func _init() -> void:
	var cols: int = 2400
	var gen: int = 2
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--cols="):
			cols = int(a.substr(7))
		if a.begins_with("--gen="):
			gen = int(a.substr(6))
	var tot: int = 0
	var n: int = 0
	var mn: int = 99999
	var mx: int = 0
	var dens2: int = 0
	var dens3: int = 0
	for sd in [3, 7, 11, 13, 17, 19, 23, 25, 29, 31]:
		for touch in [0, 1, 2, 3]:
			var S := SimCore.createSim()
			SimCore.newMatch(S, 1, {}, {"planet": sd, "touch": touch, "arena": {"cols": cols}, "planetGen": gen, "intro": false})
			var xs: Array = []
			var byPlace: Dictionary = {}
			for b in S.buildings:
				xs.append(float(b.x))
				byPlace[b.place] = int(byPlace.get(b.place, 0)) + 1
			xs.sort()
			var best2: int = 0
			var best3: int = 0
			var NCU: float = float(SimConst.NC) * SimConst.COL
			for i in range(xs.size()):
				var c2: int = 0
				var c3: int = 0
				for j in range(xs.size()):
					var d: float = absf(SimWrap.sdx(xs[i], xs[j]))
					if d <= 1000.0:
						c2 += 1
					if d <= 1500.0:
						c3 += 1
				best2 = maxi(best2, c2)
				best3 = maxi(best3, c3)
			var tr: int = 0
			for t in S.trees:
				tr += 1
			print("planet %2d touch %d: %3d structures in %d places %s  densest 2000u %d  3000u %d  (%d trees, %d civ)" % [sd, touch, S.buildings.size(), byPlace.size(), str(byPlace.values()), best2, best3, tr, S.civilians.size() if "civilians" in S else -1])
			tot += S.buildings.size()
			n += 1
			mn = mini(mn, S.buildings.size())
			mx = maxi(mx, S.buildings.size())
			dens2 = maxi(dens2, best2)
			dens3 = maxi(dens3, best3)
	print("RINGCOUNT cols %d gen %d: %d rings, mean %.1f, min %d, max %d, densest 2000u %d, 3000u %d" % [cols, gen, n, float(tot) / float(n), mn, mx, dens2, dens3])
	quit()
