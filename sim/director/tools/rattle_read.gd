extends SceneTree
## Rattles: launched bodies with many contacts in one flight, computer against computer. Contacts per flight, and the worst flights.
##   godot --headless --path . --script res://sim/director/tools/rattle_read.gd -- [fights]
func _init() -> void:
	SimInputData.load_and_apply()
	var u: PackedStringArray = OS.get_cmdline_user_args()
	var n: int = int(u[0]) if u.size() > 0 else 8
	var hist: Dictionary = {}
	var top: Array = []
	var marks: Dictionary = {"craters": 0, "flights": 0}
	for sd in range(1, n + 1):
		_one(sd, hist, top, marks)
	print("ground contacts per flight: ", str(hist), "; flights ", marks.flights, ", craters ", marks.craters)
	top.sort_custom(func(a, b): return a[0] > b[0])
	for r in top.slice(0, 5):
		print("WORST %d, seed %d tick %d: %s" % [r[0], r[1], r[2], str(r[3]).substr(0, 220)])
	quit(0)
func _one(sd: int, hist: Dictionary, top: Array, marks: Dictionary) -> void:
	var S := SimCore.createSim()
	SimCore.newMatch(S, sd, {"p1": true, "p2": true}, {"planet": 7, "planetGen": 3, "touch": 3, "intro": false, "aiLevel": "medium"})
	var since: Array = [-1, -1]
	var seq: Array = [[], []]
	var c0: int = S.craters.size()
	for t in range(14400):
		SimCore.step(S, [SimIntent.new(), SimIntent.new()])
		for e in S.out.fx:
			var ty: String = String(e.type)
			if ty in ["bounce", "land", "slam", "wall"]:
				var k: int = int(e.actor) if "actor" in e else -1
				if k >= 0 and k < 2 and String(e.surface if "surface" in e else "") != "water":
					seq[k].append("%s:%s@%d" % [ty, str(e.kind) if "kind" in e else "", t])
		S.out.fx.clear()
		S.out.feed.clear()
		for k in [0, 1]:
			var f = S.fighters[k]
			if f.state == "launched" and since[k] < 0:
				since[k] = t
				seq[k] = []
			elif f.state != "launched" and since[k] >= 0:
				var c: int = seq[k].size()
				hist[c] = int(hist.get(c, 0)) + 1
				marks.flights += 1
				if c >= 4:
					top.append([c, sd, since[k], seq[k]])
				since[k] = -1
		if S.game.ko != null:
			break
	marks.craters += S.craters.size() - c0
	SimCore.dispose(S)
