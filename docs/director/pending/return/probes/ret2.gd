extends SceneTree
## Probe: the AI's return after the player launches it (Orb, 2026-10-15: "they rushed back at me at full speed and got
## some cheap hits"). Slot 0 is a scripted player: X every 8 ticks on the match clock, one B tap whenever a
## launcher_open names him, until he launches the AI (slot 1). Then the defender script takes over until the AI's first
## blow back lands (with no --def the scripted player goes on as before): idle (presses nothing), striker (X every 8 ticks) or guarder (holds guard, with a fresh guard press
## when it starts and the tick after any windup cue of the AI's), each starting --react live ticks after the AI comes
## within the mid band (12.5 bh), or after the approach's start cue with --from=cue (return, charge_, lunge_ or
## taunt_start). It counts: unanswered (that blow lands clean and the player landed nothing on the AI after it came
## within the mid band), guarded, perfect, met (a return_met cue), playerFirst, the ticks in the mid and close bands
## before the blow, the blow's kind and the approach that brought it.
## -- <matches> <seed0> [--level=medium] [--def=idle|striker|guarder] [--react=15] [--from=cue]


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var n: int = int(args[0]) if args.size() > 0 else 20
	var seed0: int = int(args[1]) if args.size() > 1 else 1
	var idle := false
	var def := "idle"
	var react := 15
	var fromCue := false
	for s in args:
		if s.begins_with("--level="):
			DirAI.level = s.substr(8)
		if s.begins_with("--def="):
			def = s.substr(6)
			idle = true
		if s == "--from=cue":
			fromCue = true
		if s.begins_with("--react="):
			react = int(s.substr(8))
	var BH := 75.0
	var r := {"matches": n, "launches": 0, "returns": 0, "noReturn": 0, "firstBlow": {}, "unanswered": 0, "playerFirst": 0,
		"approach": {}, "perfect": 0, "guarded": 0, "clean": 0, "met": 0, "metTrade": 0, "midTicks": [], "closeTicks": [], "arriveToHit": [], "wins": 0}
	for m in range(n):
		var S := SimCore.createSim()
		SimCore.newMatch(S, seed0 + m, {"p1": false, "p2": true}, {"v2": [true, false]})
		var me = S.fighters[0]
		var him = S.fighters[1]
		var last := -1000
		var openUntil := -1
		var routeB := -1000
		var bUp := -1
		var watch := false     # the AI was launched by him: follow it back
		var t0 := 0
		var inMid := -1        # the live tick it came within 12.5 bh on its way back
		var inClose := -1
		var answered := false
		var appr := "none"
		var arrive := -1
		var sawWind := -1000
		var seen := -1
		var pb := false
		while S.tick < 60000 and S.game.ko == null:
			var it := SimIntent.new()
			var quiet: bool = idle and watch
			var from: int = seen if fromCue else inMid
			if quiet and from >= 0 and DirBrawl._now(S) - from >= react:
				if def == "striker" and S.tick - last >= 8:
					it.light = true
					last = S.tick
				elif def == "guarder":
					it.guard = true
					if DirBrawl._now(S) - from == react or sawWind == S.tick - 1:
						it.guardPress = true
			if not quiet:
				if openUntil >= S.tick and S.tick - routeB > 40:
					it.sig = true
					it.sigHeld = true
					routeB = S.tick
					bUp = S.tick + 4
				elif S.tick < bUp:
					it.sigHeld = true
				elif S.tick - last >= 8:
					it.light = true
					last = S.tick
			var stepped: bool = SimCore.step(S, [it, null])
			if not stepped:
				if last == S.tick - 1:
					last = -1000
				if routeB == S.tick - 1:
					routeB = -1000
			var now: int = DirBrawl._now(S)
			if watch:
				var d: float = DirBands.dist(me, him) / BH
				if inMid < 0 and d <= 12.5 and him.state != "launched":
					inMid = now
				if inClose < 0 and d <= 3.0 and him.state != "launched":
					inClose = now
				if now - t0 > 1800:
					r.noReturn += 1
					watch = false
			if watch and pb:
				r.returns += 1
				r.perfect += 1
				watch = false
				pb = false
			for e in S.out.fx:
				if e.type == "launch" and int(e.actor) == 1 and int(e.target) == 0:
					r.launches += 1
					watch = true
					t0 = now
					inMid = -1
					inClose = -1
					answered = false
					pb = false
					seen = -1
					appr = "none"
					arrive = -1
				elif watch and e.type == "cue" and int(e.actor) == 0 and String(e.kind) == "return_met":
					r.met += 1
				elif watch and e.type == "cue" and int(e.actor) == 0 and String(e.kind) == "perfect_block":
					pb = true
				elif watch and e.type == "cue" and int(e.actor) == 1:
					var ck: String = String(e.kind)
					if seen < 0 and (ck == "return" or ck.begins_with("charge_") or ck.begins_with("lunge_") or ck == "taunt_start"):
						seen = DirBrawl._now(S)
					if ck == "windup":
						sawWind = S.tick
					if ck.begins_with("lunge_") or ck.begins_with("charge_") or ck.begins_with("far_") or ck == "rush" or ck == "approach":
						appr = ck + ":" + String(e.text)
					elif ck == "brawl_start" and arrive < 0:
						arrive = now
				elif watch and e.type == "damage" and e.amount > 0.0:
					if int(e.attacker) == 0 and int(e.victim) == 1 and inMid >= 0:
						answered = true
					elif int(e.attacker) == 1 and int(e.victim) == 0 and him.state != "launched" and inMid >= 0:
						r.returns += 1
						var k: String = String(e.kind)
						r.firstBlow[k] = int(r.firstBlow.get(k, 0)) + 1
						r.approach[appr] = int(r.approach.get(appr, 0)) + 1
						r.midTicks.append(now - inMid)
						r.closeTicks.append(now - inClose if inClose >= 0 else -1)
						r.arriveToHit.append(now - arrive if arrive >= 0 else -1)
						if answered:
							r.playerFirst += 1
						elif k == "guard":
							r.guarded += 1
						else:
							r.unanswered += 1
						watch = false
				elif e.type == "cue" and String(e.kind) == "launcher_open" and int(e.actor) == 0:
					openUntil = int(e.n)
			S.out.fx.clear()
			S.out.feed.clear()
		if S.game.ko != null and S.game.ko == him:
			r.wins += 1
	for key in ["midTicks", "closeTicks", "arriveToHit"]:
		var a: Array = r[key]
		a.sort()
		r[key] = {"n": a.size(), "p10": a[int(a.size() * 0.1)] if a.size() > 0 else -1, "median": a[a.size() / 2] if a.size() > 0 else -1, "p90": a[int(a.size() * 0.9)] if a.size() > 0 else -1}
	print(JSON.stringify(r))
	quit()
