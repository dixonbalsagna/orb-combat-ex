extends SceneTree
func _init() -> void:
	var a: Array = OS.get_cmdline_user_args()
	var seed: int = int(a[0])
	var arm: String = a[1]
	var t0: float = float(a[2])
	var S := SimCore.createSim()
	SimCore.newMatch(S, seed)
	SimGolden.applyArm(arm, S.fighters)
	var steps: int = 0
	var last_sec: int = 0
	var tl: Array = []
	while S.game.ko == null and steps < 54000:
		WorldCollateral.DBG_ON = S.T >= t0
		SimCore.step(S, null)
		var top: int = int(maxf(S.fighters[0].tier, S.fighters[1].tier))
		if int(S.T) > last_sec:
			last_sec = int(S.T)
			tl.append([last_sec, S.world.casualties / S.world.pop0, top])
		S.out.fx.clear()
		S.out.feed.clear()
		steps += 1
	var BUD := [0.0, 0.02, 0.04, 0.08, 0.15]
	for i in range(tl.size()):
		var j: int = -1
		for k in range(tl.size()):
			if tl[k][0] >= tl[i][0] - 60:
				j = k
				break
		var back: float = tl[j][1] if (j >= 0 and tl[i][0] >= 60) else 0.0
		var over: float = tl[i][1] - back - BUD[tl[i][2]]
		if over > 0.000000001 or (tl[i][0] % 10 == 0 and tl[i][0] >= t0 - 30 and tl[i][0] <= t0 + 80):
			print("TL sec %d cum %.4f back(%d) %.4f top %d window %.4f budget %.2f over %.4f" % [tl[i][0], tl[i][1], tl[j][0], back, tl[i][2], tl[i][1] - back, BUD[tl[i][2]], over])
	print("END T %.1f pop0 %.0f cas %.1f" % [S.T, S.world.pop0, S.world.casualties])
	quit(0)
