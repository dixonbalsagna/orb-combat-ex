extends SceneTree
# the damage state of buildings at the KO: counts by a damage-fraction stage, per match, all rows and the front row; floors cut
func _init() -> void:
	var a: Array = OS.get_cmdline_user_args()
	var cnt := [0, 0, 0, 0, 0]
	var cntF := [0, 0, 0, 0, 0]
	var cutT: int = 0
	var n: int = 0
	var tot: int = 0
	var totF: int = 0
	for sd in range(int(a[0]), int(a[1])):
		var S := SimCore.createSim()
		SimCore.newMatch(S, sd)
		SimGolden.applyArm("default", S.fighters)
		var steps: int = 0
		while S.game.ko == null and steps < 54000:
			SimCore.step(S, null)
			S.out.fx.clear()
			S.out.feed.clear()
			steps += 1
		for b in S.buildings:
			var st: int = 4
			if b.alive:
				var d: float = 1.0 - b.hp / b.maxhp
				var cut: bool = b.floors >= WorldBrunt.FLOORS_MIN and b.fmask != (1 << b.floors) - 1
				if cut:
					cutT += 1
				if d < 0.10 and not cut:
					st = 0
				elif d < 0.35 and not cut:
					st = 1
				elif d < 0.65:
					st = 2
				else:
					st = 3
				if cut and d < 0.65:
					st = 2
			cnt[st] += 1
			tot += 1
			if b.row == 1.0:
				cntF[st] += 1
				totF += 1
		n += 1
		SimCore.dispose(S)
	var s: String = "STG matches %d  all rows by stage (intact, light, part, shell, gone):" % n
	for i in range(5):
		s += " %.1f%%" % (100.0 * cnt[i] / tot)
	s += " | front row:"
	for i in range(5):
		s += " %.1f%%" % (100.0 * cntF[i] / totF)
	s += " | buildings with cut floors per match %.1f" % (float(cutT) / n)
	print(s)
	quit(0)
