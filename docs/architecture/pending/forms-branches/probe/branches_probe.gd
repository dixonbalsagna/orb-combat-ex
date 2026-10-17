extends SceneTree
# Scratch (Simulation): Witness and Trial in AI matches with {"forms": true} (the Protagonist in slot 0 against the
# rival; the AI takes a ready step at the first break). Each match: the branch picked at each branch step, crosses, the
# fills when the pick came, and each match the same twice. Game Design's row: each branch taken at some step in at least
# 25% of matches. Usage: godot --headless --path <export> --script res://zbranch/branches_probe.gd -- <matches> <ticks>


func _one(seed: int, ticks: int) -> Dictionary:
	var S := SimCore.createSim()
	SimCore.newMatch(S, seed, {}, {"forms": true})
	var p = S.fighters[0]
	var picks: Array = []
	var maxW: float = 0.0
	var maxT: float = 0.0
	for t in range(ticks):
		var w0: float = p.form.witness
		var t0: float = p.form.trial
		SimCore.step(S)
		maxW = maxf(maxW, w0)
		maxT = maxf(maxT, t0)
		for e in S.out.fx:
			if e.type == "form_step" and int(e.actor) == 0 and e.text != "" and (picks.is_empty() or int(picks[picks.size() - 1][0]) != int(e.k)):
				if int(e.k) == 2 or int(e.k) == 4 or (picks.is_empty() and int(e.k) >= 2) or (picks.size() == 1 and int(e.k) >= 4):
					picks.append([int(e.k), String(e.text), String(e.source), snappedf(w0, 0.1), snappedf(t0, 0.1)])
		S.out.fx.clear()
		S.out.feed.clear()
		if S.game.ko != null and S.game.koT > 2.5:
			break
	var out := {"hash": SimHash.stateHash(S).gameplay, "picks": picks, "step": p.form.step, "end": S.tick, "maxW": snappedf(maxW, 0.1), "maxT": snappedf(maxT, 0.1)}
	SimCore.dispose(S)
	return out


func _init() -> void:
	var a: Array = OS.get_cmdline_user_args()
	var n: int = int(a[0]) if a.size() > 0 else 12
	var ticks: int = int(a[1]) if a.size() > 1 else 14400
	var same: int = 0
	var withW: int = 0
	var withT: int = 0
	var picked: int = 0
	var crosses: int = 0
	for k in range(n):
		var x: Dictionary = _one(500 + k, ticks)
		var y: Dictionary = _one(500 + k, ticks)
		same += 1 if x.hash == y.hash else 0
		var hasW: bool = false
		var hasT: bool = false
		for pk in x.picks:
			hasW = hasW or pk[1] == "witness"
			hasT = hasT or pk[1] == "trial"
			crosses += 1 if pk[2] == "cross" else 0
		withW += 1 if hasW else 0
		withT += 1 if hasT else 0
		picked += 1 if not x.picks.is_empty() else 0
		print("seed %d: %d ticks, step %d; picks [step, branch, cross, Witness, Trial] %s; the fills' highest %s and %s; twice: %s" % [500 + k, x.end, x.step, str(x.picks), str(x.maxW), str(x.maxT), "same" if x.hash == y.hash else "DIFFERENT"])
	print("%d matches: %d with a pick; Witness taken in %d, Trial in %d; %d crosses; %d of %d the same twice" % [n, picked, withW, withT, crosses, same, n])
	quit()
