extends SceneTree
## Probe: the AI's holds of a ready step (hero-forms.md section 4b), forms on ({"forms": true}), AI against AI at
## --level. For slot 0 (the Protagonist, with steps): each release's hold (form_release dur, seconds), its coil and
## steps, and whether his rival's tier was above his as it was taken. The holds on purpose: ticks where a ready step
## could be taken now (SimForms.canTake) and DirAI._formHold keeps the AI from pressing, and the longest run of them.
## -- <matches> <seed0> [--level=medium] [--ticks=7200]


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var n: int = int(args[0]) if args.size() > 0 else 4
	var seed0: int = int(args[1]) if args.size() > 1 else 1
	var ticks := 7200
	for s in args:
		if s.begins_with("--level="):
			DirAI.level = s.substr(8)
		if s.begins_with("--ticks="):
			ticks = int(s.substr(8))
	var r := {"level": DirAI.level, "matches": n, "releases": 0, "holds": [], "coils": [], "steps": 0, "above": 0, "heldOver1s": 0, "fh": DirAI.lv().get("forms", {}), "purposeTicks": 0, "purposeRuns": 0, "purposeMaxS": 0.0, "purposeAbove": 0, "purposeCoilUnder": 0, "readyAtBreakTicks": 0}
	for m in range(n):
		var S := SimCore.createSim()
		SimCore.newMatch(S, seed0 + m, {}, {"forms": true})
		var run := 0
		for t in range(ticks):
			SimCore.step(S)
			var me = S.fighters[0]
			var op = SimRoster.opp(S, me)
			var can: bool = me.act.formReady and SimForms.canTake(S, me)
			if can:
				r.readyAtBreakTicks += 1
			if can and DirAI._formHold(S, me, op):
				r.purposeTicks += 1
				if run == 0:
					r.purposeRuns += 1
				run += 1
				r.purposeMaxS = maxf(r.purposeMaxS, float(run) / 60.0)
				if op.tier > me.tier:
					r.purposeAbove += 1
				if me.form != null and me.form.coil < 60.0:
					r.purposeCoilUnder += 1
			else:
				run = 0
			for e in S.out.fx:
				if String(e.type) == "form_release" and int(e.actor) == 0:
					r.releases += 1
					r.holds.append(snappedf(float(e.dur), 0.01))
					r.coils.append(snappedf(float(e.amount), 0.1))
					r.steps += int(e.n)
					if SimRoster.opp(S, S.fighters[0]).tier > S.fighters[0].tier:
						r.above += 1
					if float(e.dur) >= 1.0:
						r.heldOver1s += 1
			S.out.fx.clear()
			S.out.feed.clear()
	var hs: Array = r.holds.duplicate()
	hs.sort()
	r["holdMax"] = hs[hs.size() - 1] if hs.size() > 0 else -1
	r["holdMedian"] = hs[hs.size() / 2] if hs.size() > 0 else -1
	print(JSON.stringify(r))
	quit()
