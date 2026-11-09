extends SceneTree
## You only go round after him if you're still pressing toward him (interrupts.json carryRound, off; docs/director/pending/carry-round/;
## Game Design, beams-third-play.md, the dodge exchange):
##   godot --headless --path . --script res://sim/director/tools/carry_round_check.gd
## A player presses a light up close at a rival in the evasive stance: the planned dodge set piece, its read branch (the rival steps round to
## the far side, then the attacker's follow rush). Played to its end three ways:
## - on, the left stick held toward him: he follows round (the sides swap), as before
## - on, the stick let go: he stays on his own side, the set piece ends at the follow, and he's free
## - off, the stick let go (the negative control): he's carried round anyway
## Ends on the verdict line.

var failed: int = 0


func _init() -> void:
	var c: Dictionary = DirInterrupt.data()
	var was = c.get("carryRound", {}).duplicate()
	if not c.has("carryRound"):
		c["carryRound"] = {}
	c.carryRound["enabled"] = true
	var toward: Dictionary = _play(true)
	var letGo: Dictionary = _play(false)
	c.carryRound["enabled"] = false
	var off: Dictionary = _play(false)
	c["carryRound"] = was
	for r in [toward, letGo, off]:
		print("      %s: found %s (seed %d, %s), sides swapped %s, set piece ticks %d, free at the end %s, stayed cue %s" % [r.name, str(r.found), r.seed, r.branch, str(r.swapped), r.ticks, str(r.free), str(r.cue)])
	_expect(toward.found and toward.swapped and not toward.cue, "on, the stick toward him: he follows round, the sides swap")
	_expect(letGo.found and not letGo.swapped and letGo.free and letGo.cue and letGo.ticks < toward.ticks, "on, the stick let go: he stays on his side, the set piece ends at the follow (%d ticks against %d), and he's free" % [letGo.ticks, toward.ticks])
	_expect(off.found and off.swapped and not off.cue, "negative control, off: let go, he's carried round anyway")
	print("CARRY ROUND: %d check(s) failed" % failed)
	quit(1 if failed > 0 else 0)


func _expect(ok: bool, what: String) -> void:
	print(("ok    " if ok else "FAIL  ") + what)
	if not ok:
		failed += 1


## The first seed whose planned exchange is the dodge's read branch, played to its end with the stick toward him (hold) or let go.
func _play(hold: bool) -> Dictionary:
	var out := {"name": ("stick toward" if hold else "let go") + ("" if bool(DirInterrupt.data().carryRound.get("enabled", false)) else ", off"), "found": false, "seed": -1, "branch": "", "swapped": false, "ticks": 0, "free": false, "cue": false}
	for seed in range(1, 40):
		var S := SimCore.createSim()
		SimCore.newMatch(S, seed, {"p1": false, "p2": false}, {"intro": false})
		var A = S.fighters[0]
		var D = S.fighters[1]
		for f in S.fighters:
			f.ai = null
			f.hp = 100000.0
			f.ki = 100.0
		for _k in range(3):
			SimCore.step(S, [SimIntent.new(), SimIntent.new()])
		D.x = SimWrap.wrap(A.x + 120.0)
		D.y = A.y
		var side0: float = SimMathx.jsign(SimWrap.sdx(D.x, A.x))
		var started: bool = false
		var t0: int = -1
		for t in range(240):
			D.act.dodgeTick = S.tick   # the evasive stance, held
			var i := SimIntent.new()
			i.light = t == 0
			var ex = S.dirS.ex
			if hold and ex != null:
				i.mx = SimMathx.jsign(SimWrap.sdx(A.x, D.x))
			var di := SimIntent.new()
			di.stance = 2.0   # (a slot that is not v2 takes its stance from the intent)
			SimCore.step(S, [i, di])
			for e in S.out.fx:
				if String(e.type) == "cue" and String(e.kind) == "carry_round":
					out.cue = true
			S.out.fx.clear()
			S.out.feed.clear()
			ex = S.dirS.ex
			if not started and ex != null:
				if seed <= 3:
					print("      (seed %d: the first exchange %s/%s, his stance %.0f)" % [seed, ex.tpl, ex.branch, D.stance])
				if ex.tpl != "dodge" or ex.branch != "read":
					break
				started = true
				t0 = t
				out.branch = ex.tpl + "/" + ex.branch
			if started and ex == null:
				out.ticks = t - t0
				break
		if started:
			out.found = true
			out.seed = seed
			out.swapped = SimMathx.jsign(SimWrap.sdx(D.x, A.x)) != side0
			out.free = A.state == "free"
			SimCore.dispose(S)
			return out
		out.cue = false
		SimCore.dispose(S)
	return out
