extends SceneTree
## QA's read of the return from a launch (Game Design's eleventh round, Orb's playtest: "they rushed back at me at full speed and got some cheap hits").
## The method is Encounter's probe (docs/director/pending/return/probes/ret2.gd), kept here as QA's own so that it runs on any build and carries the wall cap and the validity fields.
## Slot 0 is a scripted player: X every 8 ticks on the match clock, one B tap whenever a launcher_open names him, until he launches the AI (slot 1). Then the defender script takes over until the AI's
## first blow back lands: idle (presses nothing), striker (X every 8 ticks) or guarder (holds guard, with a fresh guard press when it starts and the tick after any windup cue of the AI's), each
## starting --react live ticks after the approach's start cue (return, charge_, lunge_ or taunt_start) with --from=cue, or after the AI comes within the mid band (12.5 bh) with --from=mid.
## "Unanswered": the AI's first blow back lands clean (not guarded) and the player landed nothing on it after it came within the mid band.
## -- <matches> <seed0> [--level=medium] [--def=idle|striker|guarder] [--react=15] [--from=cue|mid] [--wall=300] [--budget=3600]


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var n: int = int(args[0]) if args.size() > 0 else 20
	var seed0: int = int(args[1]) if args.size() > 1 else 1
	var def := "striker"
	var react := 15
	var from_cue := true
	var wall: float = 300.0
	var budget: float = 3600.0
	for s in args:
		if s.begins_with("--level="):
			DirAI.level = s.substr(8)
		elif s.begins_with("--def="):
			def = s.substr(6)
		elif s.begins_with("--react="):
			react = int(s.substr(8))
		elif s == "--from=mid":
			from_cue = false
		elif s.begins_with("--wall="):
			wall = float(s.substr(7))
		elif s.begins_with("--budget="):
			budget = float(s.substr(9))
	var BH := 75.0
	var r := {"probe": "ret", "def": def, "level": DirAI.level, "requested": n, "n": 0, "wallCapped": 0, "budgetStopped": false, "launches": 0, "returns": 0, "noReturn": 0, "firstBlow": {},
		"unanswered": 0, "playerFirst": 0, "guarded": 0, "perfect": 0, "met": 0, "approach": {}, "midTicks": [], "ranged": 0}
	var t_start: int = Time.get_ticks_msec()
	for m in range(n):
		if float(Time.get_ticks_msec() - t_start) / 1000.0 > budget:
			r.budgetStopped = true
			break
		var t_match: int = Time.get_ticks_msec()
		var S := SimCore.createSim()
		SimCore.newMatch(S, seed0 + m, {"p1": false, "p2": true}, {"v2": [true, false]})
		var me = S.fighters[0]
		var him = S.fighters[1]
		var last := -1000
		var open_until := -1
		var route_b := -1000
		var b_up := -1
		var watch := false      # the AI was launched by him: follow it back
		var t0 := 0
		var in_mid := -1        # the live tick it came within 12.5 bh on its way back
		var answered := false
		var appr := "none"
		var saw_wind := -1000
		var seen := -1          # the live tick of the approach's start cue
		var pb := false
		var capped := false
		while S.tick < 60000 and S.game.ko == null:
			if float(Time.get_ticks_msec() - t_match) / 1000.0 > wall:
				capped = true
				break
			var it := SimIntent.new()
			var quiet: bool = watch
			var from: int = seen if from_cue else in_mid
			if quiet and from >= 0 and DirBrawl._now(S) - from >= react:
				if def == "striker" and S.tick - last >= 8:
					it.light = true
					last = S.tick
				elif def == "guarder":
					it.guard = true
					if DirBrawl._now(S) - from == react or saw_wind == S.tick - 1:
						it.guardPress = true
			if not quiet:
				if open_until >= S.tick and S.tick - route_b > 40:
					it.sig = true
					it.sigHeld = true
					route_b = S.tick
					b_up = S.tick + 4
				elif S.tick < b_up:
					it.sigHeld = true
				elif S.tick - last >= 8:
					it.light = true
					last = S.tick
			var stepped: bool = SimCore.step(S, [it, null])
			if not stepped:
				if last == S.tick - 1:
					last = -1000
				if route_b == S.tick - 1:
					route_b = -1000
			var now: int = DirBrawl._now(S)
			if watch:
				var d: float = DirBands.dist(me, him) / BH
				if in_mid < 0 and d <= 12.5 and him.state != "launched":
					in_mid = now
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
					in_mid = -1
					answered = false
					pb = false
					seen = -1
					appr = "none"
				elif watch and e.type == "cue" and int(e.actor) == 0 and String(e.kind) == "return_met":
					r.met += 1
				elif watch and e.type == "cue" and int(e.actor) == 0 and String(e.kind) == "perfect_block":
					pb = true
				elif watch and e.type == "cue" and int(e.actor) == 1:
					var ck: String = String(e.kind)
					if seen < 0 and (ck == "return" or ck.begins_with("charge_") or ck.begins_with("lunge_") or ck == "taunt_start"):
						seen = DirBrawl._now(S)
					if ck == "windup":
						saw_wind = S.tick
					if ck.begins_with("lunge_") or ck.begins_with("charge_") or ck.begins_with("far_") or ck == "rush" or ck == "approach":
						appr = ck + ":" + String(e.text)
				elif watch and e.type == "damage" and e.amount > 0.0:
					if int(e.attacker) == 0 and int(e.victim) == 1 and in_mid >= 0:
						answered = true
					elif int(e.attacker) == 1 and int(e.victim) == 0 and him.state != "launched" and in_mid >= 0:
						r.returns += 1
						var k: String = String(e.kind)
						r.firstBlow[k] = int(r.firstBlow.get(k, 0)) + 1
						r.approach[appr] = int(r.approach.get(appr, 0)) + 1
						r.midTicks.append(now - in_mid)
						if k == "blast" or k == "beam" or k == "bolt" or k == "signature":
							r.ranged += 1
						if answered:
							r.playerFirst += 1
						elif k == "guard":
							r.guarded += 1
						else:
							r.unanswered += 1
						watch = false
				elif e.type == "cue" and String(e.kind) == "launcher_open" and int(e.actor) == 0:
					open_until = int(e.n)
			S.out.fx.clear()
			S.out.feed.clear()
		SimCore.dispose(S)
		if capped:
			r.wallCapped += 1
		else:
			r.n += 1
	var a: Array = r.midTicks
	a.sort()
	r["midTicks"] = {"n": a.size(), "p10": a[int(a.size() * 0.1)] if a.size() > 0 else -1, "median": a[a.size() / 2] if a.size() > 0 else -1, "p90": a[int(a.size() * 0.9)] if a.size() > 0 else -1}
	print(JSON.stringify(r))
	quit()
