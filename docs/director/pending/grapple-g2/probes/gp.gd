extends SceneTree
## Probe: the grapple, slice G1, with grapple.enabled turned on in memory. --mode=ai: the AI on both sides (level medium).
## Otherwise slot 0 is a scripted player against the AI at --level:
##   tapA: A every 8 ticks and nothing else (a masher of A);
##   alone: A only, as it is meant (Game Design's re-defined row): a catch every 30 ticks while free in a brawl, and in a
##   clinch one A for each pulse, at a human's spread (-3 to 3 ticks off, by the pulse);
##   mash, idle, pulse: X every 8 ticks, and A every 30 ticks while free in a brawl (a catch); in a clinch, A every 3
##   ticks (mash), nothing (idle), or A on each pulse (pulse, the control), and after a throw of his down or up, B.
## Counts, by the cues: catches (tell, stopped, miss, the quick throw), clinches, how each ends, clinch lengths (the
## tie-up to the end), throws a match, throws down or up followed by the thrower's launch within 40 ticks, refusals,
## grip steps won by slot 0, and the hard rows: a step or sharp pummel more than the window off its pulse, a tell on a
## fighter thrown less than noRegrab ago, and the AI's tech sooner than its reaction time after the tell began.
## -- <matches> <seed0> [--mode=ai|tapA|alone|mash|idle|pulse] [--level=medium] [--cap=54000]


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var n: int = int(args[0]) if args.size() > 0 else 3
	var seed0: int = int(args[1]) if args.size() > 1 else 1
	var mode := "ai"
	var cap := 54000
	for s in args:
		if s.begins_with("--mode="):
			mode = s.substr(7)
		if s.begins_with("--level="):
			DirAI.level = s.substr(8)
		if s.begins_with("--cap="):
			cap = int(s.substr(6))
	DirInterrupt.data()["grapple"]["enabled"] = true
	var g: Dictionary = DirInterrupt.data().grapple
	var react: int = int(DirAI.skill().get("reactTicks", 14))
	var win: int = int(g.clinch.window)
	var r := {"mode": mode, "level": DirAI.level, "matches": n, "ticks": 0, "kos": 0, "wins0": 0, "catch": {}, "clinches": 0, "ends": {},
		"lens": [], "throws": 0, "throwsByKind": {}, "openThrows": 0, "openThenLaunch": 0, "refused": {}, "steps0": 0, "steps1": 0,
		"clinches0": 0, "hard": {"strayStep": 0, "regrab": 0, "aiTechSoon": 0}, "reactTicks": react}
	for m in range(n):
		var S := SimCore.createSim()
		var human: bool = mode != "ai"
		SimCore.newMatch(S, seed0 + m, {"p1": not human, "p2": true}, {"v2": [true, false]})
		var me = S.fighters[0]
		var lastX := -1000
		var lastA := -1000
		var bAt := -1
		var tie := [-1, -1]      # the tie-up's S.tick, by the catcher's slot; -1 none
		var tellAt := [-1, -1]   # the tell's press tick, by the catcher's slot
		var thrownAt := [-100000, -100000]
		var opens := []          # [thrower slot, the throw's tick, done]
		while S.tick < cap and S.game.ko == null:
			var it := SimIntent.new()
			if human:
				var gn: Dictionary = DirGrapple.now(S, me)
				if mode == "tapA":
					if S.tick - lastA >= 8:
						it.context = true
						lastA = S.tick
				elif S.tick == bAt:
					it.sig = true
					it.sigHeld = true
					bAt = -1
				elif mode == "alone":
					if not gn.is_empty() and String(gn.mode) == "clinch":
						var ta: int = S.tick - int(gn.t0)
						var kp: int = int(round(float(ta) / float(int(g.clinch.pulse))))
						var off: int = ((int(gn.t0) * 5 + kp * 3) % 7) - 3   # a human's spread, by the pulse
						if kp >= 1 and ta == kp * int(g.clinch.pulse) + off:
							it.context = true
					elif gn.is_empty() and DirBrawl.inBrawl(S, me) and not DirBrawl.busy(S, me) and S.tick - lastA >= 30:
						it.context = true
						lastA = S.tick
				elif not gn.is_empty() and String(gn.mode) == "clinch":
					var t: int = S.tick - int(gn.t0)
					if mode == "mash" and S.tick - lastA >= 3:
						it.context = true
						lastA = S.tick
					elif mode == "pulse" and t > 0 and t % int(g.clinch.pulse) == 0:
						it.context = true
				elif gn.is_empty():
					if DirBrawl.inBrawl(S, me) and not DirBrawl.busy(S, me) and S.tick - lastA >= 30:
						it.context = true
						lastA = S.tick
					elif S.tick - lastX >= 8:
						it.light = true
						lastX = S.tick
			SimCore.step(S, [it, null] if human else null)
			for e in S.out.fx:
				if String(e.type) != "cue":
					if String(e.type) == "launch_plan" and String(e.chosen) != "KNOCK BACK" and String(e.chosen) != "":
						for q in opens:
							if not q[2] and int(q[0]) == int(e.actor) and S.tick - int(q[1]) <= 40:
								q[2] = true
								r.openThenLaunch += 1
					continue
				var ck: String = String(e.kind)
				if not ck.begins_with("grapple_"):
					continue
				var a: int = int(e.actor)
				var tx: String = String(e.text)
				if ck == "grapple_catch":
					r.catch[tx] = int(r.catch.get(tx, 0)) + 1
					if tx == "tell":
						tellAt[a] = int(e.n) - int(g.catch.tell)
						if S.tick - int(thrownAt[int(e.target)]) < int(g.noRegrab):
							r.hard.regrab += 1
				elif ck == "grapple_clinch":
					r.clinches += 1
					tie[a] = S.tick
					if a == 0 or int(e.target) == 0:
						r.clinches0 += 1
				elif ck == "grapple_pummel" and (tx == "step" or tx == "sharp"):
					if int(e.amount) > win:
						r.hard.strayStep += 1
					if a == 0:
						r.steps0 += 1
					else:
						r.steps1 += 1
				elif ck == "grapple_refused":
					r.refused[tx] = int(r.refused.get(tx, 0)) + 1
				elif ck == "grapple_end":
					r.ends[tx] = int(r.ends.get(tx, 0)) + 1
					var cs: int = a if tie[a] >= 0 else int(e.target)
					if cs >= 0 and cs < 2 and tie[cs] >= 0:
						r.lens.append(S.tick - int(tie[cs]))
					if tx == "tech":
						# the caught is the one who isn't the catcher; its tech tick is now
						var caught: int = 1 - cs
						if S.fighters[caught].ai != null and tellAt[cs] >= 0 and S.tick - int(tellAt[cs]) < react:
							r.hard.aiTechSoon += 1
					if tx.begins_with("throw") or tx.begins_with("thrown") or tx == "reversal":
						r.throws += 1
						r.throwsByKind[tx] = int(r.throwsByKind.get(tx, 0)) + 1
						thrownAt[int(e.target)] = S.tick
						if tx != "throw_across":
							r.openThrows += 1
							opens.append([a, S.tick, false])
							if a == 0 and human and mode != "tapA":
								bAt = S.tick + 2
					tie = [-1, -1]
			S.out.fx.clear()
			S.out.feed.clear()
		r.ticks += S.tick
		if S.game.ko != null:
			r.kos += 1
			if S.game.ko == S.fighters[1]:
				r.wins0 += 1
	var ls: Array = r.lens.duplicate()
	ls.sort()
	r["lenMedian"] = ls[ls.size() / 2] if ls.size() > 0 else -1
	r["lenMax"] = ls[ls.size() - 1] if ls.size() > 0 else -1
	r.erase("lens")
	r["minutes"] = snappedf(float(r.ticks) / 3600.0, 0.1)
	r["tellsAMinute"] = snappedf(float(r.catch.get("tell", 0)) / maxf(0.1, float(r.ticks) / 3600.0), 0.01)
	r["throwsAMatch"] = snappedf(float(r.throws) / maxf(1.0, float(n)), 0.01)
	r["openThenLaunchShare"] = snappedf(float(r.openThenLaunch) / maxf(1.0, float(r.openThrows)), 0.001)
	print(JSON.stringify(r))
	quit()
