extends SceneTree
# the hybrid: front row and all rows lost at the KO, civilians lost, structures a minute by tier (all rows and front row), C1 at tier 1 and 2; seeds a[0] to a[1]
func _init() -> void:
	var a: Array = OS.get_cmdline_user_args()
	var BUD := [0.0, 0.02, 0.04, 0.08, 0.15]
	var n: int = 0
	var sh1: float = 0.0
	var sha: float = 0.0
	var civ: float = 0.0
	var bad: Array = []
	var minutes := [0.0, 0.0, 0.0, 0.0, 0.0]
	var strA := [0.0, 0.0, 0.0, 0.0, 0.0]
	var strF := [0.0, 0.0, 0.0, 0.0, 0.0]
	var len_sum: float = 0.0
	for sd in range(int(a[0]), int(a[1])):
		var S := SimCore.createSim()
		SimCore.newMatch(S, sd)
		SimGolden.applyArm("default", S.fighters)
		var nb: int = S.buildings.size()
		var n1: int = 0
		for b in S.buildings:
			if b.row == 1.0:
				n1 += 1
		var steps: int = 0
		var last_sec: int = 0
		var tl: Array = []
		var alive_prev: int = nb
		var f_prev: int = n1
		while S.game.ko == null and steps < 54000:
			SimCore.step(S, null)
			var top: int = clampi(int(maxf(S.fighters[0].tier, S.fighters[1].tier)), 1, 4)
			minutes[top] += 1.0 / 3600.0
			if int(S.T) > last_sec:
				last_sec = int(S.T)
				tl.append([last_sec, snappedf(S.world.casualties / S.world.pop0, 0.0001), top])
				# structures lost this second, all rows and the front row, to the tier
				var al: int = 0
				var fr: int = 0
				for b in S.buildings:
					if b.alive:
						al += 1
						if b.row == 1.0:
							fr += 1
				strA[top] += float(alive_prev - al) / float(nb)
				strF[top] += float(f_prev - fr) / float(n1)
				alive_prev = al
				f_prev = fr
			S.out.fx.clear()
			S.out.feed.clear()
			steps += 1
		var lost1: int = 0
		var lost: int = 0
		for b in S.buildings:
			if not b.alive:
				lost += 1
				if b.row == 1.0:
					lost1 += 1
		sh1 += float(lost1) / float(n1)
		sha += float(lost) / float(nb)
		civ += S.world.casualties / S.world.pop0
		len_sum += S.T
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
		n += 1
		SimCore.dispose(S)
	var s: String = "HY matches %d  front row %.1f%%  all rows %.1f%%  civilians %.1f%%  length %.0f s  C1 fails %d %s |" % [n, sh1 / n * 100.0, sha / n * 100.0, civ / n * 100.0, len_sum / n, bad.size(), str(bad)]
	for t in range(1, 5):
		if minutes[t] > 0.0:
			s += "  t%d all %.2f front %.2f %%/min;" % [t, strA[t] / minutes[t] * 100.0, strF[t] / minutes[t] * 100.0]
	print(s)
	quit(0)
