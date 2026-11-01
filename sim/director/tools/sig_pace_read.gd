extends SceneTree
## The AI's beams against a scripted pad, with vsHuman on: when the first comes, how many in 90 s, time in a brawl, signatures' share of the
## damage, and how many ended in a struggle. The pad flies at him, presses X every 15 ticks and, if answers, answers in the charge when it can pay.
##   godot --headless --path . --script res://sim/director/tools/sig_pace_read.gd -- [fights] [answers 0|1] [sigPick]
## Ends on the verdict line.

var failed: int = 0


func _init() -> void:
	var u: PackedStringArray = OS.get_cmdline_user_args()
	var n: int = int(u[0]) if u.size() > 0 else 12
	var answers: bool = u.size() < 2 or int(u[1]) == 1
	DirAI.skill()["vsHuman"]["enabled"] = true
	if u.size() > 2:
		DirAI.skill()["vsHuman"]["sigPick"] = float(u[2])
	var firsts: Array = []
	var per: Array = []
	var clashes: int = 0
	var beams: int = 0
	var brawl: int = 0
	var ticks: int = 0
	var sigDmg: float = 0.0
	var dmg: float = 0.0
	var could: int = 0
	var worst: float = 0.0
	for sd in range(1, n + 1):
		var r: Array = _one(sd, answers)
		firsts.append(r[0])
		per.append(r[1])
		beams += int(r[1])
		clashes += int(r[2])
		brawl += int(r[3])
		ticks += int(r[4])
		sigDmg += float(r[5])
		dmg += float(r[6])
		could += int(r[7])
		worst = maxf(worst, float(r[0]))
	print("first beam at (s): %s" % str(firsts))
	print("beams in 90 s: %s" % str(per))
	print("time in a brawl %.0f%%; signatures %.0f%% of the human's damage taken; struggles %d of %d; the human could pay on %d of %d" % [100.0 * float(brawl) / float(maxi(1, ticks)), 100.0 * sigDmg / maxf(1.0, dmg), clashes, beams, could, beams])
	_expect(worst > 0.0 and worst <= 60.5 and not firsts.has(-1.0), "the first beam by 60 s in every match (worst %.1f)" % worst)
	print("SIG PACE: %d check(s) failed" % failed)
	quit(1 if failed > 0 else 0)


func _expect(ok: bool, what: String) -> void:
	print(("ok    " if ok else "FAIL  ") + what)
	if not ok:
		failed += 1


func _one(sd: int, answers: bool) -> Array:
	var S := SimCore.createSim()
	SimCore.newMatch(S, sd, {"p1": false, "p2": true}, {"planet": 7, "touch": 2, "planetGen": 3, "intro": false})
	var H = S.fighters[0]
	var A = S.fighters[1]
	H.act.v2 = true
	var first: float = -1.0
	var beams: int = 0
	var clashes: int = 0
	var brawl: int = 0
	var sigDmg: float = 0.0
	var dmg: float = 0.0
	var could: int = 0
	var inClash: bool = false
	var t: int = 0
	while t < 5400 and S.game.ko == null:
		var i := SimIntent.new()
		var gap: float = SimWrap.sdx(H.x, A.x)
		i.mx = signf(gap)
		i.my = signf(A.y - H.y) * 0.5
		if t % 15 == 0 and S.dirS.stop <= 0.0:
			i.light = true
		var ex = S.dirS.ex
		if answers and ex != null and ex.kind == "sig" and ex.D == H and ex.branch == "" and H.ki >= 45.0 and S.T >= H.sigReadyT and t % 10 == 0 and S.dirS.stop <= 0.0:
			i.light = false
			i.sig = true
			i.stanceMask = 4
		var hp: float = H.hp
		SimCore.step(S, [i, SimIntent.new()])
		t += 1
		if S.dirS.ex != null and DirBrawl.isBrawl(S.dirS.ex):
			brawl += 1
		var hurt: float = maxf(0.0, hp - H.hp)
		dmg += hurt
		if S.dirS.ex != null and S.dirS.ex.kind == "sig":
			sigDmg += hurt
		for e in S.out.fx:
			if e.type == "cue" and e.kind == "beam_charge" and e.actor == 1.0 and String(e.text) == "start":
				beams += 1
				if first < 0.0:
					first = S.T
				if H.ki >= 45.0:
					could += 1
		S.out.fx.clear()
		S.out.feed.clear()
		if S.game.clash != null and not inClash:
			clashes += 1
		inClash = S.game.clash != null
	SimCore.dispose(S)
	return [snappedf(first, 0.1), beams, clashes, brawl, t, sigDmg, dmg, could]
