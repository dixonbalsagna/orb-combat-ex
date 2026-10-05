extends SceneTree
## The scripted masher (docs/design/control-rules.md section 6, QA bands): a human slot pressing light every `gap` ticks and
## nothing else (and, with --forms=1, the transform input when a form is ready), against the AI at one level. It plays seeded matches on the live sim through the real input path (a v2 human
## slot) and prints one JSON line: how many the masher won, lost, timed out, and the median match length.
##   godot --headless --path . --script res://qa/godot/masher.gd -- <matches> <baseSeed> --level=easy|medium|hard [--gap=8] [--clock=tick|live] [--capsec=900]
## The masher takes slot 0 in odd seeds and slot 1 in even ones, so the spawn side and the slot cancel. Read-only with respect to sim/.

func _init() -> void:
	var pos: Array = []
	var level: String = ""
	var gap: int = 8
	var capsec: float = 900.0
	var clock: String = "tick"   # tick: the taps count S.tick (a player's real tap rate, as the brawl counts it; Game Design's ruling 4); live: live ticks, as before
	var wall: float = 300.0       # real seconds one match may take before it is ended as a timeout
	var budget: float = 3600.0    # real seconds the whole run may take before it stops starting matches
	var forms: bool = false       # --forms=1: also send `transform` whenever a form is ready (the masher who has learned the one prompt the game shows)
	var fixed_slot: int = -1       # -1 alternates by seed; 0 or 1 pins the masher to that slot
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--level="):
			level = a.substr(8)
		elif a.begins_with("--gap="):
			gap = int(a.substr(6))
		elif a.begins_with("--forms="):
			forms = int(a.substr(8)) != 0
		elif a.begins_with("--slot="):
			fixed_slot = int(a.substr(7))
		elif a.begins_with("--clock="):
			clock = a.substr(8)
		elif a.begins_with("--wall="):
			wall = float(a.substr(7))
		elif a.begins_with("--budget="):
			budget = float(a.substr(9))
		elif a.begins_with("--capsec="):
			capsec = float(a.substr(9))
		else:
			pos.append(a)
	var n: int = int(pos[0]) if pos.size() > 0 else 20
	var base: int = int(pos[1]) if pos.size() > 1 else 1
	if not (level in ["easy", "medium", "hard", ""]):
		print("usage: godot --headless --path . --script res://qa/godot/masher.gd -- <matches> <baseSeed> --level=easy|medium|hard [--gap=8] [--capsec=900]")
		quit(2)
		return
	SimInputData.load_and_apply()
	var dai = load("res://sim/director/ai.gd")   # loaded as a resource: a typed class reference would not parse on a sim before step 3 (no level)
	dai.set("level", level)
	var wins: int = 0
	var losses: int = 0
	var timeouts: int = 0
	var lens: Array = []
	var by_masher: int = 0      # launches the masher caused (the AI was the victim)
	var on_masher: int = 0      # launches the AI caused (the masher was the victim)
	var caught_ai: int = 0      # the AI was launched and the follow-up reached it before it landed (an air catch)
	var caught_masher: int = 0
	var t_proc: int = Time.get_ticks_msec()
	var n_done: int = 0
	var wall_capped: int = 0
	var budget_stopped: bool = false
	for i in range(n):
		if float(Time.get_ticks_msec() - t_proc) > budget * 1000.0:
			budget_stopped = true
			break
		n_done += 1
		var wall0: int = Time.get_ticks_msec()
		var seed: int = base + i
		var slot: int = fixed_slot if fixed_slot >= 0 else (0 if seed % 2 == 1 else 1)
		var S: SimState = SimCore.createSim()
		SimCore.newMatch(S, seed, {"p1": slot != 0, "p2": slot != 1}, {"v2": [slot == 0, slot == 1]})
		var ticks: int = 0
		var live: int = 0
		var pending: bool = false
		var wait: int = 0         # the frozen steps the pending press has waited (the intent's `waited`: a press is graded at its own tick, not when the freeze lifts)
		while S.T < capsec and not (S.game.ko != null and S.game.koT > 3.0) and ticks < 400000:
			var it := SimIntent.new()
			ticks += 1
			if (ticks & 255) == 0 and Time.get_ticks_msec() - wall0 > int(wall * 1000.0):
				wall_capped += 1
				break
			it.light = pending
			if pending:
				it.waited = mini(15, wait)
			if forms and S.fighters[slot].act.formReady:
				it.transform = true
			var ins: Array = [null, null]
			ins[slot] = it
			# step() returns false in hit-stop or a pause: the press was not consumed, so it is held for the next call (a real player keeps the button down)
			var prev0: String = S.fighters[0].state
			var prev1: String = S.fighters[1].state
			var stepped: bool = SimCore.step(S, ins)
			for ev in S.out.fx:
				if ev.type == "launch":
					if int(ev.actor) == slot:
						on_masher += 1
					else:
						by_masher += 1
			S.out.fx.clear()
			S.out.feed.clear()
			for fi in range(2):
				var pv: String = prev0 if fi == 0 else prev1
				if pv == "launched" and S.fighters[fi].state == "locked":
					if fi == slot:
						caught_masher += 1
					else:
						caught_ai += 1
			if pending and not stepped:
				wait += 1
			if stepped:
				live += 1
				if pending:
					pending = false
					wait = 0
				if clock != "tick" and live % gap == 0:
					pending = true
			if clock == "tick" and not pending and S.tick % gap == 0:
				pending = true
		lens.append(S.T)
		if S.game.ko == null:
			timeouts += 1
		elif S.game.ko == S.fighters[slot]:
			losses += 1
		else:
			wins += 1
		SimCore.dispose(S)
	lens.sort()
	print(JSON.stringify({"masher": true, "level": level if level != "" else "data", "gap": gap, "clock": clock, "forms": forms, "n": n_done, "requested": n, "wallCapped": wall_capped, "budgetStopped": budget_stopped, "wins": wins, "losses": losses, "timeouts": timeouts, "medianSec": (snappedf(lens[lens.size() >> 1], 0.1) if lens.size() > 0 else -1.0), "launchesByMasher": snappedf(float(by_masher) / maxi(1, n_done), 0.01), "launchesOnMasher": snappedf(float(on_masher) / maxi(1, n_done), 0.01), "airCatchesOfAI": snappedf(float(caught_ai) / maxi(1, n_done), 0.01), "airCatchesOfMasher": snappedf(float(caught_masher) / maxi(1, n_done), 0.01)}))
	quit(0)
