extends SceneTree
## Probe (5b): the director's hits by weight, AI v AI, hit-stop by weight on (the setup's "hitstop"), on Simulation's
## hitstop2 (the data's table is Game Design's rulings-2026-10-22 5b: mash or burst light 2, tapped light 3, medium 5,
## heavy 8, launch or close 12, full launch 14, decisive 20, KO 24; 18% of a rolling 10 s, the x0.75 second step).
## Each frozen tick is put down to what froze it: a pausing set piece (S.pause.total moves), a hit-stop (a stop was in
## force), or the intro. Reads: those shares of all ticks; Game Design's budget as blocks of 600 live ticks (10 s of
## fight) whose hit-stop ticks pass 108 (18%); the longest hit-stop run; each damage event's stop by its ticks and form.
## -- <matches> <seed0> [--off] [--ticks=10800]   (--off: hit-stop by weight off, the stops as the director passes them)


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var n: int = int(args[0]) if args.size() > 0 else 5
	var seed0: int = int(args[1]) if args.size() > 1 else 1
	var ticks := 10800
	for s in args:
		if s.begins_with("--ticks="):
			ticks = int(s.substr(8))
	var on: bool = not args.has("--off")
	var by := {}
	var all := 0
	var live := 0
	var hs := 0
	var pz := 0
	var other := 0
	var blocks := 0
	var over := 0
	var longest := 0
	var worst := 0
	for m in range(n):
		var S := SimCore.createSim()
		SimCore.newMatch(S, seed0 + m, {}, {"hitstop": on})
		var bl := 0
		var bh := 0
		var run := 0
		for t in range(ticks):
			var t0: float = S.T
			var p0: int = int(S.pause.total)
			var stop0: float = S.dirS.stop
			SimCore.step(S)
			all += 1
			if S.T != t0:
				live += 1
				bl += 1
				run = 0
			elif int(S.pause.total) != p0:
				pz += 1
				run = 0
			elif stop0 > 0.0:
				hs += 1
				bh += 1
				run += 1
				longest = maxi(longest, run)
			else:
				other += 1
			if bl >= 600:
				blocks += 1
				worst = maxi(worst, bh)
				if bh > 108:
					over += 1
				bl = 0
				bh = 0
			for e in S.out.fx:
				if String(e.type) == "damage" and float(e.attacker) >= 0.0:
					var st: int = int(e.get("stop")) if e.get("stop") != null else 0
					var w: String = str(st) + ":" + (String(e.mode) if String(e.mode) != "" else "planned")
					if not by.has(w):
						by[w] = [0, 0.0]
					by[w][0] += 1
			S.out.fx.clear()
			S.out.feed.clear()
			if S.game.ko != null:
				break
	var d: float = maxf(1.0, float(all))
	var r := {"hitstop": on, "matches": n, "ticks": all, "hitstopShare": snappedf(float(hs) / d, 0.001), "pauseShare": snappedf(float(pz) / d, 0.001),
		"otherShare": snappedf(float(other) / d, 0.001), "hitstopOfLive": snappedf(float(hs) / maxf(1.0, float(live + hs)), 0.001),
		"blocks10s": blocks, "blocksOver18": over, "worstBlockTicks": worst, "longestHitstop": longest, "byWeight": {}}
	for w in by:
		r.byWeight[w] = by[w][0]
	print(JSON.stringify(r))
	quit()
