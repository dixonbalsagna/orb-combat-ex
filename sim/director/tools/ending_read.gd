extends SceneTree
## Real fights to their end, with the ending on: when, by what, and when both reach tier 4.
##   godot --headless --path . --script res://sim/director/tools/ending_read.gd -- ai|idle [seeds] [first]

func _init() -> void:
	var u: PackedStringArray = OS.get_cmdline_user_args()
	var mode: String = u[0] if u.size() > 0 else "ai"
	var n: int = int(u[1]) if u.size() > 1 else 16
	var first: int = int(u[2]) if u.size() > 2 else 21
	DirEnding.setForce(1)
	for sd in range(first, first + n):
		_one(sd, mode)
	DirEnding.setForce(-1)
	quit(0)


func _one(sd: int, mode: String) -> void:
	var S := SimCore.createSim()
	SimCore.newMatch(S, sd, {"p1": mode == "ai", "p2": true}, {"planet": 7, "touch": 2, "planetGen": 3, "intro": false})
	var brink: Array = [-1, -1]
	var t4: int = -1
	var ko: int = -1
	var by: String = ""
	var t: int = 0
	while t < 50000:
		SimCore.step(S, [SimIntent.new(), SimIntent.new()])
		t += 1
		S.out.fx.clear()
		S.out.feed.clear()
		for i in [0, 1]:
			if brink[i] < 0 and S.fighters[i].brink:
				brink[i] = t
		if t4 < 0 and S.fighters[0].tier >= 4.0 and S.fighters[1].tier >= 4.0:
			t4 = t
		if S.game.ko != null:
			ko = t
			by = "cap" if S.game.timeCap else "fight"
			break
		if DirEnding.noContest(S):
			by = "no contest"
			break
	print("seed %d: first brink %.1f min, tier 4 both %s, ends %.1f min by %s" % [sd, float(mini(brink[0] if brink[0] >= 0 else 999999, brink[1] if brink[1] >= 0 else 999999)) / 3600.0, ("%.1f min" % (float(t4) / 3600.0)) if t4 >= 0 else "never", float(ko if ko >= 0 else t) / 3600.0, by if by != "" else "NOTHING"])
	SimCore.dispose(S)
