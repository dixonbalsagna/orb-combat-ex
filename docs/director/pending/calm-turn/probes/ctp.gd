extends SceneTree
## Probe (5a): the calm-moment turn in live AI matches, planet 7, touch 3, the Whole ring, World's turn on by the setup
## and the director's calmTurn on in memory, on World's e41118069cea (the sim warms: no host). Each match runs to its KO
## or --ticks. Reads: asks by moment (form, landed) and the k they passed; turns (World's arena_turn events) by moment,
## with the bearing, the ticks from the ask, the most the ground moved under a fighter (his distance from the pivot times
## the sine of the angle used: at most World's moveMax), whether it took the fallback (scaled), whether World had the
## ring read the tick before (cold must be 0: World never reads on the swap tick), World's waited and refused counts,
## and the director's conditions at the swap (each must be none);
## pausing form steps seen and how many asked; why the hold is off while a pick waits (DirCalm.why), every tick and in
## the 45 ticks after a journey ends; turns per match.
## -- <matches> <seed0> [--ticks=14400] [--cols=4800] [--off]   (--off: calmTurn as the data has it: no ask may come)


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var n: int = int(args[0]) if args.size() > 0 else 4
	var seed0: int = int(args[1]) if args.size() > 1 else 1
	var ticks := 14400
	var cols := 4800
	for s in args:
		if s.begins_with("--cols="):
			cols = int(s.substr(7))
		if s.begins_with("--ticks="):
			ticks = int(s.substr(8))
	if not args.has("--off"):
		DirInterrupt.data()["calmTurn"]["enabled"] = true
	var gm: float = float(WorldEpoch.data().get("moveMax", 300.0))
	var r := {"matches": n, "on": bool(DirInterrupt.data().calmTurn.enabled), "asks": {}, "turns": 0, "turnsBy": {}, "bad": 0, "cold": 0, "scaled": 0, "overGround": 0,
		"pendingAtEnd": 0, "perMatch": [], "turnList": [], "minutes": 0.0, "epoch": 0, "pauses": {}, "whyAll": {}, "whyLanded": {}, "rates": {}}
	for m in range(n):
		var S := SimCore.createSim()
		SimCore.newMatch(S, seed0 + m, {}, {"planet": 7, "touch": 3, "arena": {"cols": cols, "turn": true}})
		if S.epoch != null:
			r.epoch += 1
		var askedAt := -1
		var landT := -1000
		var rate := 16
		var warm := false
		var pick = null
		var here := 0
		for t in range(ticks):
			warm = S.epoch != null and S.epoch.next != null and not WorldEpoch.warmAngles(S).is_empty()
			SimCore.step(S)
			for e in S.out.fx:
				var ty: String = String(e.type)
				if ty == "journey_end":
					landT = S.tick
				if ty == "transform":
					var v: String = String(e.version)
					r.pauses[v] = int(r.pauses.get(v, 0)) + 1
				if ty == "cue" and String(e.kind) == "calm_turn":
					var w0: String = String(e.text)
					r.asks[w0] = int(r.asks.get(w0, 0)) + 1
					rate = maxi(1, int(e.k))
					r.rates[str(rate)] = int(r.rates.get(str(rate), 0)) + 1
					askedAt = S.tick
					pick = S.epoch.next.duplicate() if S.epoch.next != null else null
				elif ty == "arena_turn":
					r.turns += 1
					here += 1
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
					var why: String = ("at form" if DirCalm._afterForm(S) else "at landing") + " from " + (String(pick.get("why", "?")) if pick != null else "?")
					r.turnsBy[why] = int(r.turnsBy.get(why, 0)) + 1
					var mv := 0.0
					if pick != null:
						var pv: float = float(int(pick.pc)) * SimConst.COL
						for f in S.fighters:
							mv = maxf(mv, absf(SimWrap.sdx(f.x, pv)) * sin(deg_to_rad(absf(float(e.amount)))))   # at the angle used (World's scale)
						if absf(float(e.amount)) < absf(float(pick.bearing)) - 0.001:
							r.scaled += 1   # read on the swap tick
					if mv > gm + 0.5:
						r.overGround += 1
						badHere.append("ground")
					if not warm:
						r.cold += 1
					if badHere.size() > 0:
						r.bad += 1
					r.turnList.append({"m": m, "why": why, "tick": S.tick, "afterAsk": (S.tick - askedAt) if askedAt >= 0 else -1, "bearing": snappedf(float(e.amount), 0.1), "moved": int(mv), "warm": warm, "states": [S.fighters[0].state, S.fighters[1].state], "bad": badHere})
					askedAt = -1
					pick = null
			if S.epoch != null and S.epoch.next != null:
				var w: String = DirCalm.why(S)
				r.whyAll[w] = int(r.whyAll.get(w, 0)) + 1
				if S.tick - landT <= 45:
					r.whyLanded[w] = int(r.whyLanded.get(w, 0)) + 1
			S.out.fx.clear()
			S.out.feed.clear()
			if S.game.ko != null:
				break
		if S.epoch != null and S.epoch.next != null:
			r.pendingAtEnd += 1
		if S.epoch != null:
			r["waited"] = int(r.get("waited", 0)) + int(S.epoch.get("waited", 0))
			r["refused"] = int(r.get("refused", 0)) + int(S.epoch.get("refused", 0))
			r["worldCold"] = int(r.get("worldCold", 0)) + int(S.epoch.get("cold", 0))
		r.perMatch.append(here)
		r.minutes += S.T / 60.0
	r["minutes"] = snappedf(r.minutes, 0.1)
	print(JSON.stringify(r))
	quit()
