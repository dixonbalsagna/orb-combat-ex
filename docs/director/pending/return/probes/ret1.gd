extends SceneTree
## Scratch probe: the AI's return after the player launches it (Orb, 2026-10-15: "they rushed back at me at full speed
## and got some cheap hits"). Slot 0 is a scripted player: X every 8 ticks on the match clock, one B tap whenever a
## launcher_open names him; slot 1 the AI. After each launch of the AI by the player it follows the AI back: the ticks
## the AI spends inside the mid band (12.5 bh) and inside the close band (3 bh) before its first blow lands on him, the
## approach that brought it (the band's start cue, if any), the blow's kind, and whether the player landed anything on it
## after it came within the mid band. "Unanswered": that first blow lands clean (not on a guard) and he landed nothing.
## -- <matches> <seed0> [--level=medium] [--idle=1: after a launch the player presses nothing until he is hit]


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var n: int = int(args[0]) if args.size() > 0 else 20
	var seed0: int = int(args[1]) if args.size() > 1 else 1
	var idle := false
	for s in args:
		if s.begins_with("--level="):
			DirAI.level = s.substr(8)
		if s == "--idle=1":
			idle = true
	var BH := 75.0
	var r := {"matches": n, "launches": 0, "returns": 0, "noReturn": 0, "firstBlow": {}, "unanswered": 0, "playerFirst": 0,
		"approach": {}, "midTicks": [], "closeTicks": [], "arriveToHit": [], "wins": 0}
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
		while S.tick < 60000 and S.game.ko == null:
			var it := SimIntent.new()
			var quiet: bool = idle and watch
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
			for e in S.out.fx:
				if e.type == "launch" and int(e.actor) == 1 and int(e.target) == 0:
					r.launches += 1
					watch = true
					t0 = now
					inMid = -1
					inClose = -1
					answered = false
					appr = "none"
					arrive = -1
				elif watch and e.type == "cue" and int(e.actor) == 1:
					var ck: String = String(e.kind)
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
						elif k != "guard":
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
