extends SceneTree
## Probe: recoil flips, AI v AI with the switch on in memory (QA's row: flips a minute, both fighters, 2 to 6).
## Each match runs to its KO or --ticks. Reads, per minute of match time and in all: knock-backs by kind, flips by
## the knock-back's kind and by fighter, flourishes, counter-rushes and the blows they bring, World's recoil
## journey ends; the live ticks from a knock-back to its flip; one sample flip with what followed it.
## -- <matches> <seed0> [--ticks=10800] [--off]
##   --off: the switch stays as the data has it (the probe of a copy with it off: nothing may count).


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var n: int = int(args[0]) if args.size() > 0 else 5
	var seed0: int = int(args[1]) if args.size() > 1 else 1
	var ticks := 10800
	var off := false
	for s in args:
		if s.begins_with("--ticks="):
			ticks = int(s.substr(8))
		elif s == "--off":
			off = true
	if not off:
		DirInterrupt.data()["recoilFlip"]["enabled"] = true
	var r := {"on": DirRecoil.on(), "matches": n, "minutes": 0.0, "knocks": {}, "flips": {}, "flipsBy": [0, 0], "flourish": 0,
		"counters": 0, "journeyRecoil": 0, "flipAfter": {}, "kos": 0, "sample": []}
	for m in range(n):
		var S := SimCore.createSim()
		SimCore.newMatch(S, seed0 + m, {}, {})
		var knockAt := [-1, -1]
		var knockKind := ["", ""]
		var watch := -1   # the sample: ticks left to log after a flip
		for t in range(ticks):
			SimCore.step(S)
			for e in S.out.fx:
				var ty: String = String(e.type)
				if ty == "knockback":
					var v: int = int(e.victim)
					r.knocks[String(e.kind)] = int(r.knocks.get(String(e.kind), 0)) + 1
					if v >= 0 and v < 2:
						knockAt[v] = S.tick
						knockKind[v] = String(e.kind)
				elif ty == "cue" and String(e.kind) == "recoil":
					var a: int = int(e.actor)
					if String(e.text) == "flip":
						r.flipsBy[a] += 1
						var kk: String = knockKind[a] if a >= 0 and a < 2 else "?"
						r.flips[kk] = int(r.flips.get(kk, 0)) + 1
						var after: String = str(S.tick - int(knockAt[a]))
						r.flipAfter[after] = int(r.flipAfter.get(after, 0)) + 1
						if r.sample.size() == 0:
							watch = 60
							r.sample.append("t%d flip %s by %d after %s, from x=%d to x=%d, lands t%d, ground %d" % [S.tick, String(e.source), a, kk, int(e.x), int(e.amount), int(e.n), int(e.k)])
					else:
						r.flourish += 1
				elif ty == "cue" and String(e.kind) == "counter_rush":
					r.counters += 1
					if watch > 0:
						r.sample.append("t%d counter-rush by %d" % [S.tick, int(e.actor)])
				elif ty == "cue" and String(e.kind) == "blow" and String(e.source) == "lunge" and watch > 0:
					r.sample.append("t%d lunge blow %s by %d, lands t%d" % [S.tick, String(e.text), int(e.actor), int(e.n)])
				elif ty == "journey_end" and String(e.kind) == "recoil":
					r.journeyRecoil += 1
			if watch > 0:
				watch -= 1
				if watch % 6 == 0:
					var f = S.fighters[0]
					var g = S.fighters[1]
					r.sample.append("t%d  0: %s x=%d y=%d rush=%s   1: %s x=%d y=%d rush=%s" % [S.tick, f.state, int(f.x), int(f.y), str(f.rush != null), g.state, int(g.x), int(g.y), str(g.rush != null)])
			S.out.fx.clear()
			S.out.feed.clear()
			if S.game.ko != null:
				r.kos += 1
				break
		r.minutes += S.T / 60.0
	r["flipsPerMin"] = snappedf(float(r.flipsBy[0] + r.flipsBy[1]) / maxf(0.01, r.minutes), 0.01)
	r["minutes"] = snappedf(r.minutes, 0.01)
	print(JSON.stringify(r))
	quit()
