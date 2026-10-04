extends SceneTree
# C1 (QA's rolling 60 s budget at tier 1 and 2) and the per-tier casualty and structure rates, over a seed range of one arm
func _init() -> void:
	var a: Array = OS.get_cmdline_user_args()
	var arm: String = a[0]
	var BUD := [0.0, 0.02, 0.04, 0.08, 0.15]
	var bad: Array = []
	var minutes := [0.0, 0.0, 0.0, 0.0, 0.0]
	var cas := [0.0, 0.0, 0.0, 0.0, 0.0]
	var strs := [0.0, 0.0, 0.0, 0.0, 0.0]
	var seeds: Array = []
	for i in range(1, a.size()):
		seeds.append(int(a[i]))
	if seeds.size() == 2 and seeds[0] < 0:
		seeds = range(-seeds[0], seeds[1])
	var nb: int = 1
	for sd in seeds:
		var S := SimCore.createSim()
		SimCore.newMatch(S, sd)
		SimGolden.applyArm(arm, S.fighters)
		nb = S.buildings.size()
		var steps: int = 0
		var last_sec: int = 0
		var tl: Array = []
		var pc: float = 0.0
		var ps: float = 0.0
		while S.game.ko == null and steps < 54000:
			SimCore.step(S, null)
			var top: int = clampi(int(maxf(S.fighters[0].tier, S.fighters[1].tier)), 1, 4)
			var dc: float = S.world.casualties - pc
			var ds: float = S.world.structuresLost - ps
			pc = S.world.casualties
			ps = S.world.structuresLost
			cas[top] += dc / S.world.pop0
			strs[top] += ds
			minutes[top] += 1.0 / 3600.0
			if int(S.T) > last_sec:
				last_sec = int(S.T)
				tl.append([last_sec, snappedf(S.world.casualties / S.world.pop0, 0.0001), top])
			S.out.fx.clear()
			S.out.feed.clear()
			steps += 1
		for i in range(tl.size()):
			var j: int = -1
			for k in range(tl.size()):
				if tl[k][0] >= tl[i][0] - 60:
					j = k
					break
			var back: float = tl[j][1] if (j >= 0 and tl[i][0] >= 60) else 0.0
			if tl[i][1] - back - BUD[tl[i][2]] > 0.000000001 and tl[i][2] <= 2:
				bad.append(sd)
				break
		SimCore.dispose(S)
	var s: String = "C1 arm %s matches %d  C1 failures %d %s |" % [arm, seeds.size(), bad.size(), str(bad)]
	for t in range(1, 5):
		if minutes[t] > 0.0:
			s += "  tier %d: %.0f min, casualties %.2f%%/min, structures %.2f%%/min;" % [t, minutes[t], cas[t] / minutes[t] * 100.0, strs[t] / float(nb) / minutes[t] * 100.0]
	print(s)
	quit(0)
