extends SceneTree
## Probe: the calm-moment turn in live AI matches, planet 7, touch 3, the Whole ring, World's turn on by the setup and the
## director's calmTurn on in memory. Each match runs to its KO or --ticks. Reads: asks (calm_turn cues), turns (World's
## arena_turn events) with their bearing and the ticks from the ask; at each turn, the fighters' states and speeds, an
## exchange or approach on, an attack waiting (each must be none); asks still pending at the end; the fight time of each.
## While a pick waits: why the hold is off (DirCalm.why), every tick, and in the 30 ticks after a journey ends; the warm
## rates asked.
## -- <matches> <seed0> [--ticks=14400] [--off]   (--off: calmTurn as the data has it: no ask may come)


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var n: int = int(args[0]) if args.size() > 0 else 4
	var seed0: int = int(args[1]) if args.size() > 1 else 1
	var ticks := 14400
	for s in args:
		if s.begins_with("--ticks="):
			ticks = int(s.substr(8))
	if not args.has("--off"):
		DirInterrupt.data()["calmTurn"]["enabled"] = true
	var r := {"matches": n, "on": bool(DirInterrupt.data().calmTurn.enabled), "asks": 0, "turns": 0, "bad": 0, "pendingAtEnd": 0, "turnList": [], "minutes": 0.0, "epoch": 0, "whyAll": {}, "whyLanded": {}, "rates": {}}
	for m in range(n):
		var S := SimCore.createSim()
		SimCore.newMatch(S, seed0 + m, {}, {"planet": 7, "touch": 3, "arena": {"cols": 4800, "turn": true}})
		if S.epoch != null:
			r.epoch += 1
		var askedAt := -1
		var landT := -1000
		for t in range(ticks):
			SimCore.step(S)
			for e in S.out.fx:
				var ty: String = String(e.type)
				if ty == "journey_end":
					landT = S.tick
				if ty == "cue" and String(e.kind) == "calm_turn":
					r.asks += 1
					r.rates[str(int(e.k))] = int(r.rates.get(str(int(e.k)), 0)) + 1
					askedAt = S.tick
				elif ty == "arena_turn":
					r.turns += 1
					var badHere := []
					if S.dirS.ex != null:
						badHere.append("exchange")
					if DirBands.who(S) >= 0:
						badHere.append("approach")
					for f in S.fighters:
						if not SimAct.peek(f).is_empty():
							badHere.append("queued")
						if f.state == "launched" or f.rush != null:
							badHere.append("moving:" + f.state)
					if badHere.size() > 0:
						r.bad += 1
					r.turnList.append({"m": m, "tick": S.tick, "afterAsk": (S.tick - askedAt) if askedAt >= 0 else -1, "bearing": snappedf(float(e.amount), 0.1), "states": [S.fighters[0].state, S.fighters[1].state], "speeds": [int(SimDetMath.hypot(S.fighters[0].vx, S.fighters[0].vy)), int(SimDetMath.hypot(S.fighters[1].vx, S.fighters[1].vy))], "bad": badHere})
					askedAt = -1
			if S.epoch != null and S.epoch.next != null:
				var w: String = DirCalm.why(S)
				r.whyAll[w] = int(r.whyAll.get(w, 0)) + 1
				if S.tick - landT <= 30:
					r.whyLanded[w] = int(r.whyLanded.get(w, 0)) + 1
			S.out.fx.clear()
			S.out.feed.clear()
			if S.game.ko != null:
				break
		if S.epoch != null and S.epoch.next != null:
			r.pendingAtEnd += 1
		r.minutes += S.T / 60.0
	r["minutes"] = snappedf(r.minutes, 0.1)
	print(JSON.stringify(r))
	quit()
