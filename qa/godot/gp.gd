extends SceneTree
## QA's copy of Encounter's grapple probe (docs/director/pending/grapple-g3/probes/gp.gd), with the wall cap and the validity fields (probe, requested, n, wallCapped, budgetStopped). The grapple is turned on in memory.
## Modes: ai (AI against AI), alone (Game Design's grab-and-follow, the replacement of the A-only row of 2026-10-19: a catch every 30 ticks while free in a brawl, one A for each pulse within 3 ticks, and B on the bury),
## tapA (a masher of A), mash, idle, pulse. Rows: the clinch's length (median 30 to 55, at most 60, time-outs under 30%), grab-and-follow wins 25 to 50%, catch tells a minute 1 to 3, throws a match, open-then-launch.
## -- <matches> <seed0> [--mode=ai|tapA|alone|mash|idle|pulse] [--level=medium] [--cap=54000] [--wall=300] [--budget=3600]
## Probe: the grapple, slice G1, with grapple.enabled turned on in memory. --mode=ai: the AI on both sides (level medium).
## Otherwise slot 0 is a scripted player against the AI at --level:
##   guardgrab / guardonly (rulings-2026-10-22 1d): both guard whenever the AI winds up and he is not in a clinch; guardgrab also catches in reach, pummels within 3 ticks, throws down and presses B on the bury; guardonly does nothing else.
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
	var wall: float = 300.0
	var budget: float = 3600.0
	for s in args:
		if s.begins_with("--mode="):
			mode = s.substr(7)
		if s.begins_with("--level="):
			DirAI.level = s.substr(8)
		if s.begins_with("--cap="):
			cap = int(s.substr(6))
		if s.begins_with("--wall="):
			wall = float(s.substr(7))
		if s.begins_with("--budget="):
			budget = float(s.substr(9))
	DirInterrupt.data()["grapple"]["enabled"] = true
	var g: Dictionary = DirInterrupt.data().grapple
	var react: int = int(DirAI.skill().get("reactTicks", 14))
	var win: int = int(g.clinch.window)
	var r := {"mode": mode, "level": DirAI.level, "matches": n, "ticks": 0, "kos": 0, "wins0": 0, "catch": {}, "clinches": 0, "ends": {},
		"lens": [], "throws": 0, "throwsByKind": {}, "openThrows": 0, "openThenLaunch": 0, "refused": {}, "steps0": 0, "steps1": 0,
		"clinches0": 0, "throwDmg": 0.0, "throwN": 0, "hpEnd": [], "hard": {"strayStep": 0, "regrab": 0, "aiTechSoon": 0}, "reactTicks": react}
	r["probe"] = "gp"
	r["brinkMatches"] = 0
	r["maxAge"] = 0
	r["maxLive"] = 0
	r["dmgTo1"] = 0.0
	r["requested"] = n
	r["n"] = 0
	r["wallCapped"] = 0
	r["budgetStopped"] = false
	var t_start: int = Time.get_ticks_msec()
	for m in range(n):
		if float(Time.get_ticks_msec() - t_start) / 1000.0 > budget:
			r.budgetStopped = true
			break
		var t_match: int = Time.get_ticks_msec()
		var capped := false
		var live_age := 0   # the live ticks of the clinch running now (hit-stop ticks advance S.tick and not the clinch)
		var brink1 := false   # the AI (slot 1) reached the brink in this match
		var S := SimCore.createSim()
		var human: bool = mode != "ai"
		SimCore.newMatch(S, seed0 + m, {"p1": not human, "p2": true}, {"v2": [true, false]})
		var me = S.fighters[0]
		var lastX := -1000
		var lastA := -1000
		var bAt := -1
		var b_pending := false   # B is thrown on every tick until a LIVE tick has run (a hit-stop can swallow a one-tick press), then its level is held 2 live ticks (rulings-2026-10-23 9d)
		var b_hold := 0
		var wind_until := -1   # guardgrab and guardonly: the tick the AI's wind-up lands, plus 4; he guards until then (never in a clinch)
		var tie := [-1, -1]      # the tie-up's S.tick, by the catcher's slot; -1 none
		var tellAt := [-1, -1]   # the tell's press tick, by the catcher's slot
		var thrownAt := [-100000, -100000]
		var opens := []          # [thrower slot, the throw's tick, done]
		var hpWas := [float(S.fighters[0].hp), float(S.fighters[1].hp)]
		while S.tick < cap and S.game.ko == null:
			if float(Time.get_ticks_msec() - t_match) / 1000.0 > wall:
				capped = true
				break
			var it := SimIntent.new()
			if human:
				var gn: Dictionary = DirGrapple.now(S, me)
				var guarding: bool = (mode == "guardgrab" or mode == "guardonly") and DirBrawl.inBrawl(S, me) and DirBrawl._windOn(S.fighters[1]) and (gn.is_empty() or String(gn.mode) != "clinch")   # the AI winds up and he is not in a clinch
				if mode == "tapA":
					if S.tick - lastA >= 8:
						it.context = true
						lastA = S.tick
				elif b_pending or S.tick == bAt:
					it.sig = true
					it.sigHeld = true
					b_pending = true
					bAt = -1
				elif b_hold > 0:
					it.sigHeld = true
				elif guarding:
					it.guard = true   # exclusive: while he guards he presses nothing else, as Encounter's probe has it
				elif mode == "guardonly":
					pass   # the control: the same guard, no grab, no blow
				elif mode == "alone" or mode == "guardgrab":
					if not gn.is_empty() and String(gn.mode) == "clinch":
						var ta: int = S.tick - int(gn.t0)
						var kp: int = int(round(float(ta) / float(int(g.clinch.pulse))))
						var off: int = ((int(gn.t0) * 5 + kp * 3) % 7) - 3   # a human's spread, by the pulse
						if kp >= 1 and ta == kp * int(g.clinch.pulse) + off:
							it.context = true
							if mode == "guardgrab" or mode == "alone":
								it.my = -1.0   # the stick down at the claim: his throw is down, the bury opens the sure launcher (rulings-2026-10-23 9d)
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
			var stepped: bool = SimCore.step(S, [it, null] if human else null)
			var gn2: Dictionary = DirGrapple.now(S, me)   # the oldest clinch seen, read each tick from the grapple itself (S.tick less its start), not from the end cue
			if not gn2.is_empty() and String(gn2.mode) == "clinch":
				r.maxAge = maxi(int(r.maxAge), S.tick - int(gn2.t0))
				if stepped:
					live_age += 1
					r.maxLive = maxi(int(r.maxLive), live_age)
			else:
				live_age = 0
			if stepped:
				if b_pending:
					b_pending = false
					b_hold = 2
				elif b_hold > 0:
					b_hold -= 1
			for e in S.out.fx:
				if String(e.type) == "brink_enter" and int(e.actor) == 1:
					brink1 = true
				if String(e.type) == "damage" and int(e.attacker) == 0 and int(e.victim) == 1 and float(e.amount) > 0.0:
					r.dmgTo1 += float(e.amount)
				if String(e.type) != "cue":
					if String(e.type) == "launch_plan" and String(e.chosen) != "KNOCK BACK" and String(e.chosen) != "":
						for q in opens:
							if not q[2] and int(q[0]) == int(e.actor) and S.tick - int(q[1]) <= 40:
								q[2] = true
								r.openThenLaunch += 1
					continue
				var ck: String = String(e.kind)
				if ck == "windup" and String(e.text) == "start" and int(e.actor) == 1:
					wind_until = int(e.n) + 4
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
						r.throwN += 1
						r.throwDmg += float(hpWas[int(e.target)]) - float(S.fighters[int(e.target)].hp)
						r.throwsByKind[tx] = int(r.throwsByKind.get(tx, 0)) + 1
						thrownAt[int(e.target)] = S.tick
						if tx != "throw_across":
							r.openThrows += 1
							opens.append([a, S.tick, false])
							if a == 0 and human and mode != "tapA":
								bAt = S.tick + 2
					tie = [-1, -1]
			hpWas = [float(S.fighters[0].hp), float(S.fighters[1].hp)]
			S.out.fx.clear()
			S.out.feed.clear()
		if brink1:
			r.brinkMatches += 1
		r.hpEnd.append([snappedf(float(S.fighters[0].hp), 1.0), snappedf(float(S.fighters[1].hp), 1.0)])
		SimCore.dispose(S)
		if capped:
			r.wallCapped += 1
		else:
			r.n += 1
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
	r["throwDmgMean"] = snappedf(r.throwDmg / maxf(1.0, float(r.throwN)), 0.1)
	r["tellsAMinute"] = snappedf(float(r.catch.get("tell", 0)) / maxf(0.1, float(r.ticks) / 3600.0), 0.01)
	r["throwsAMatch"] = snappedf(float(r.throws) / maxf(1.0, float(n)), 0.01)
	r["openThenLaunchShare"] = snappedf(float(r.openThenLaunch) / maxf(1.0, float(r.openThrows)), 0.001)
	print(JSON.stringify(r))
	quit()
