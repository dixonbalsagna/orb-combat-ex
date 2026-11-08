extends SceneTree
## The 2v2 last event by team (docs/design/two-v-two.md, "The last event in a 2v2", 2026-11-07; DirEnding._lastTeam).
##   godot --headless --path . --script res://sim/director/tools/ending_team_check.gd
## - by team, not fight by fight: four standing, team 1 with the less wear in all though fight 2's team-2 fighter has the less of that fight:
##   team 1's fighter finishes team 2's in both fights, and team 2 falls
## - more standing first: with one of team 2 out, team 1 wins whatever the wear
## - one decision for the stage: every body carries it (E_DONE 3 + the team), and each losing fighter's finisher starts once (5 + the team)
## - nobody's played (four players, no input since the cap) and the teams level: a no-contest in both fights
## - two fights with hits across off: each fight by its own pair, as a 1v1
## - a losing fighter alone in his fight (his fight won by him) waits for Simulation's rejoin, and the opponent it brings finishes him
## Ends on the verdict line.

var failed: int = 0


func _init() -> void:
	DirEnding.setForce(1)
	_byTeam()
	_moreStanding()
	_noContest()
	_acrossOff()
	_rejoin()
	DirEnding.setForce(-1)
	print("ENDING TEAM: %d check(s) failed" % failed)
	quit(1 if failed > 0 else 0)


func _expect(ok: bool, what: String) -> void:
	print(("ok    " if ok else "FAIL  ") + what)
	if not ok:
		failed += 1


## A 2v2 of players with no input (or computer fighters), both fights past the cap and a tick short of the last event. wear: each body's core wear
## (p1, p2, p3, p4), on top of the brink the cap gives.
func _stage(cross: bool, ai: bool, wear: Array) -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 9, {"p1": ai, "p2": ai, "p3": ai, "p4": ai}, {"intro": false, "fights": 2, "cross": cross})
	for _k in range(3):
		SimCore.step(S, null if ai else [null, null, null, null])   # (the match's first tick sets the wounds: the wear is put on after it)
	var last: float = SimCross.lastAt() if cross else float(DirEnding.cfg().lastAt)
	S.T = last - 0.05
	S.stage.fights[1].T = last - 0.05 if not cross else SimCross.timeCap() + 5.0
	S.game.timeCap = true
	S.stage.fights[1].game.timeCap = true
	var all: Array = SimStage.bodies(S)
	for k in range(4):
		all[k].wear[SimWounds.HEAD] += int(wear[k]) * 10000   # (wear is counted in tens of thousands: the brink is hundreds of thousands)
		all[k].hp = 100000.0
	return S


func _body(S: SimState, keys: String):
	for f in SimStage.bodies(S):
		if String(f.keys) == keys:
			return f
	return null


## Steps n ticks (or to a KO in both fights, unless untilOver); returns each body's E_DONE (p1 to p4), and the keys of the bodies out at the end.
func _run(S: SimState, n: int, untilOver: bool = false) -> Array:
	for _k in range(n):
		SimCore.step(S, [null, null, null, null])
		for i in [0, 1]:
			SimStage.enter(S, i)
			S.out.fx.clear()
			S.out.feed.clear()
		SimStage.enter(S, 0)
		var both: bool = S.game.ko != null and S.stage.fights[1].game.ko != null
		if S.stage.over >= 0 or (both and not untilOver):
			break
	var done: Array = []
	for keys in ["p1", "p2", "p3", "p4"]:
		done.append(DirEnding._g(_body(S, keys), DirEnding.E_DONE))
	var out: Array = []
	for f in SimStage.bodies(S):
		if f.out:
			out.append(String(f.keys))
	for i in [0, 1]:
		var g = S.game if S.stage.cur == i else S.stage.fights[i].game
		if g.ko != null and not out.has(String(g.ko.keys)):
			out.append(String(g.ko.keys))   # (with hits across off a KO doesn't mark him out)
	out.sort()
	return [done, out]


func _byTeam() -> void:
	# team 1 (p1, p3) wears 2 + 10 = 12 in all, team 2 (p2, p4) 8 + 8 = 16; in fight 2, p4 (8) has less than p3 (10)
	var S := _stage(true, false, [2, 8, 10, 8])   # (players with no input: no blow moves the wear before the event)
	var r: Array = _run(S, 900)
	print("      by team: the marks %s, out %s, the match over for team %d" % [str(r[0]), str(r[1]), S.stage.over + 1])
	_expect(r[0] == [3, 5, 3, 5], "one decision for the stage: every body carries team 1's (3), and both of team 2's finishers started (5)")
	_expect(r[1] == ["p2", "p4"] and S.stage.over == 1, "by team: team 1's fighters finish team 2's in both fights, p4 too though he had the less wear of his fight")
	SimCore.dispose(S)


func _moreStanding() -> void:
	# team 2 has the less wear (p2 0, p4 0 against p1 30, p3 30), but p2 is out: team 1 stands two to one
	var S := _stage(true, false, [30, 0, 30, 0])
	_body(S, "p2").out = true
	var r: Array = _run(S, 900)
	print("      more standing: marks %s, out %s" % [str(r[0]), str(r[1])])
	_expect(r[1].has("p4") and not r[1].has("p1") and not r[1].has("p3"), "more standing first: two to one, team 1 wins though team 2 has the less wear")
	SimCore.dispose(S)


func _noContest() -> void:
	var S := _stage(true, false, [5, 5, 5, 5])
	var need: int = int((SimCross.lastAt() - SimCross.timeCap()) * DirData.TICKS_PER_SEC)
	for f in SimStage.bodies(S):
		DirEnding._s(f, DirEnding.E_IDLE, need + 5)
	var cues: int = 0
	for _k in range(6):
		SimCore.step(S, [null, null, null, null])
		for i in [0, 1]:
			SimStage.enter(S, i)
			for e in S.out.fx:
				if String(e.type) == "cue" and String(e.kind) == "no_contest":
					cues += 1
			S.out.fx.clear()
			S.out.feed.clear()
		SimStage.enter(S, 0)
	var done: Array = []
	for f in SimStage.bodies(S):
		done.append(DirEnding._g(f, DirEnding.E_DONE))
	print("      nobody's played: marks %s, no_contest cues %d" % [str(done), cues])
	_expect(done == [2, 2, 2, 2] and cues == 1, "nobody's played and the teams level: a no-contest in both fights, said once")
	SimCore.dispose(S)


func _acrossOff() -> void:
	# the same wear as by team, with hits across off: fight 2's own less-worn (p4) finishes p3
	var S := _stage(false, false, [2, 8, 10, 8])
	var r: Array = _run(S, 900)
	print("      hits across off: marks %s, out %s" % [str(r[0]), str(r[1])])
	_expect(r[1].has("p3") and not r[1].has("p4"), "with hits across off each fight goes by its own pair, as a 1v1: p4 finishes p3")
	SimCore.dispose(S)


## One fight won each side before the event: p1 falls in fight 1 and p4 in fight 2, so p2 and p3 stand alone in their fights. The
## decision is made with p2 alone (team 1 has the less wear: p3 5 against p2 20), so he has nobody to finish him there and waits. The rejoin
## puts p3 in p1's place, and there p3 finishes him: team 2 is out.
func _rejoin() -> void:
	var S := _stage(true, false, [0, 20, 5, 0])
	var p1 = _body(S, "p1")
	var p4 = _body(S, "p4")
	p1.out = true
	S.game.ko = p1
	S.game.koT = 0.0
	p4.out = true
	S.stage.fights[1].game.ko = p4
	S.stage.fights[1].game.koT = 0.0
	DirEnding._lastTeam(S, [S.fighters[0], S.fighters[1]])   # fight 1 decides, with p2 alone in it
	var waits: bool = DirEnding._g(_body(S, "p2"), DirEnding.E_DONE) == 3 and DirEnding._g(_body(S, "p3"), DirEnding.E_DONE) == 3
	var r: Array = _run(S, 900, true)
	print("      rejoin: rejoined %d, marks %s, out %s, the match over for team %d" % [S.stage.rejoined, str(r[0]), str(r[1]), S.stage.over + 1])
	_expect(waits, "alone in his fight, the losing fighter's finisher waits (both marked 3)")
	_expect(S.stage.rejoined == 1 and r[1] == ["p1", "p2", "p4"] and S.stage.over == 1, "the rejoin brings p3 to him, and p3 finishes him: team 2 is out")
	SimCore.dispose(S)
