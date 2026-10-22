extends SceneTree
## Probe: DirLocation's planet shares (_planet) on the hand-made world, on planet 7 (the Whole), and on its Half (2,400
## columns). Each: the shares by biome, their sum, and an AI match of 1,800 ticks played on it (its biome times).
func _init() -> void:
	var out := []
	for setup in [{}, {"planet": 7, "touch": 3}, {"planet": 7, "touch": 3, "arena": {"cols": 2400}}]:
		var S := SimCore.createSim()
		SimCore.newMatch(S, 1, {}, setup)
		for t in range(1800):
			SimCore.step(S)
			S.out.fx.clear()
			S.out.feed.clear()
		var sh := {}
		var sum := 0.0
		for i in range(DirLocation.BIOMES.size()):
			sh[DirLocation.BIOMES[i]] = snappedf(DirLocation._planet[i], 0.001)
			sum += DirLocation._planet[i]
		var bt := {}
		for i in range(S.dirS.biomeT.size()):
			if S.dirS.biomeT[i] > 0.0:
				bt[DirLocation.BIOMES[i]] = snappedf(S.dirS.biomeT[i], 0.1)
		out.append({"setup": setup, "cols": WorldBiomes.planetCols.size(), "W": SimConst.W, "shares": sh, "sum": snappedf(sum, 0.001), "fightTime": bt})
	for o in out:
		print(JSON.stringify(o))
	quit()
