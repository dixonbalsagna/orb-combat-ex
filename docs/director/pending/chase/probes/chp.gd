extends SceneTree
## Probe (5d): the AI's chase of a launch it threw, AI v AI, chase on in memory, at a level. Reads: its sends (launch
## events by an AI), chases started (chase cue "start"), those on a sky send, chases a match (QA's row: 1 to 4), the
## chaser's top speed in a chase, the gap to the sent body when he lands (his first tick not launched), and how each
## chase ended; with --off, no chase may start.
## -- <matches> <seed0> [--level=medium] [--off] [--ticks=10800]


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var n: int = int(args[0]) if args.size() > 0 else 5
	var seed0: int = int(args[1]) if args.size() > 1 else 1
	var ticks := 10800
	for s in args:
		if s.begins_with("--ticks="):
			ticks = int(s.substr(8))
		elif s.begins_with("--level="):
			DirAI.level = s.substr(8)
	if not args.has("--off"):
		DirAI.skill()["chase"]["enabled"] = true
	var r := {"level": DirAI.level if DirAI.level != "" else "default", "on": DirChase.on(), "matches": n, "sends": 0, "chases": 0, "sky": 0, "perMatch": [], "topSpeed": [], "gapAtLanding": [], "ended": {}, "minutes": 0.0}
	for m in range(n):
		var S := SimCore.createSim()
		SimCore.newMatch(S, seed0 + m, {}, {})
		var here := 0
		var chasing := [-1, -1]   # the sent fighter's slot each chaser is after, or -1
		var top := [0.0, 0.0]
		var wasLaunched := [false, false]
		for t in range(ticks):
			SimCore.step(S)
			for e in S.out.fx:
				var ty: String = String(e.type)
				if ty == "launch":
					r.sends += 1
				elif ty == "cue" and String(e.kind) == "chase":
					var a: int = int(e.actor)
					if String(e.text) == "start":
						r.chases += 1
						here += 1
						chasing[a] = int(e.target)
						top[a] = 0.0
						if DirChase._sky(S, S.fighters[int(e.target)]):
							r.sky += 1
					else:
						var why: String = "landed" if S.fighters[int(e.target)].state != "launched" else S.fighters[a].state
						r.ended[why] = int(r.ended.get(why, 0)) + 1
						r.topSpeed.append(int(top[a]))
						chasing[a] = -1
			for a in range(2):
				if chasing[a] >= 0:
					top[a] = maxf(top[a], SimDetMath.hypot(S.fighters[a].vx, S.fighters[a].vy))
			for k in range(2):
				var f = S.fighters[k]
				if wasLaunched[k] and f.state != "launched" and chasing[1 - k] == k:
					r.gapAtLanding.append(int(DirBands.dist(S.fighters[1 - k], f)))
				wasLaunched[k] = f.state == "launched"
			S.out.fx.clear()
			S.out.feed.clear()
			if S.game.ko != null:
				break
		r.perMatch.append(here)
		r.minutes += S.T / 60.0
	r["minutes"] = snappedf(r.minutes, 0.1)
	r.topSpeed.sort()
	r.gapAtLanding.sort()
	print(JSON.stringify(r))
	quit()
