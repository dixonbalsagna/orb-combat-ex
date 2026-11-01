extends SceneTree
## The ladder (docs/design/spec-wounds.md 1b-end). Rows are set up with the clock moved on, not by playing for 11 minutes;
## ending_read.gd plays real fights. Ends on the verdict line.
##   godot --headless --path . --script res://sim/director/tools/ending_check.gd

var failed: int = 0


func _init() -> void:
	DirEnding.setForce(0)
	_off()
	DirEnding.setForce(1)
	_idle()
	_cap()
	_last()
	_level()
	_levelPlayed()
	DirEnding.setForce(-1)
	print("ENDING: %d check(s) failed" % failed)
	quit(1 if failed > 0 else 0)


func _expect(ok: bool, what: String) -> void:
	print(("ok    " if ok else "FAIL  ") + what)
	if not ok:
		failed += 1


func _fresh(seed: int = 11, ai: bool = false) -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, seed, {"p1": false, "p2": ai}, {"intro": false})
	S.out.fx.clear()
	S.out.feed.clear()
	return S


func _run(S: SimState, n: int, a: SimIntent = null, b: SimIntent = null) -> void:
	for _k in range(n):
		SimCore.step(S, [a if a != null else SimIntent.new(), b if b != null else SimIntent.new()])
		S.out.fx.clear()
		S.out.feed.clear()
		if S.game.ko != null:
			return


func _moving() -> SimIntent:
	var i := SimIntent.new()
	i.mx = 1.0
	return i


func _off() -> void:
	var S := _fresh()
	var n: int = S.fighters[0].act.dirI.size()
	_run(S, 700)
	_expect(DirEnding._g(S.fighters[0], DirEnding.E_IDLE) == 0 and DirEnding.wearMul(S.fighters[0]) == 1.0, "off: nothing counted (%d slots)" % n)
	SimCore.dispose(S)


func _idle() -> void:
	var sec: int = int(float(DirEnding.cfg().idleSec) * DirData.TICKS_PER_SEC)
	var S := _fresh()
	var P = S.fighters[0]
	_run(S, sec - 2, null, _moving())
	_expect(DirEnding.wearMul(P) == 1.0, "under the time: wear as ever")
	_run(S, 3, null, _moving())
	_expect(DirEnding.wearMul(P) == float(DirEnding.cfg().idleWearMul), "no input for the time: wear x%.0f" % DirEnding.wearMul(P))
	_run(S, 1, _moving(), _moving())
	_expect(DirEnding.wearMul(P) == 1.0, "any input ends it at once")
	SimCore.dispose(S)
	# on the brink, with a rival who's playing: he's opened
	var S2 := _fresh()
	var P2 = S2.fighters[0]
	P2.wear[SimWounds.CORE] = int(P2.wd.stageAt[2])
	SimWounds.updateStages(S2, P2)
	_run(S2, sec + 2, null, _moving())
	_expect(P2.brink and P2.brinkOpen, "idle on the brink, the rival playing: he's open")
	SimCore.dispose(S2)
	# both idle: nothing's opened
	var S3 := _fresh()
	var P3 = S3.fighters[0]
	P3.wear[SimWounds.CORE] = int(P3.wd.stageAt[2])
	SimWounds.updateStages(S3, P3)
	_run(S3, sec + 60)
	_expect(not P3.brinkOpen, "both idle: nobody's opened")
	SimCore.dispose(S3)
	# an AI is never idle
	var S4 := _fresh(11, true)
	_run(S4, sec + 60)
	_expect(not DirEnding.idle(S4.fighters[1]), "an AI's never idle")
	SimCore.dispose(S4)


func _cap() -> void:
	var S := _fresh()
	var cap: float = DirData.timeCapAt()
	_expect(cap == 660.0, "the cap is at 11:00 (%.0f)" % cap)
	S.T = cap - 0.5
	_run(S, 60, _moving(), _moving())
	_expect(S.game.timeCap, "the cap fires")
	_expect(S.fighters[0].brink and S.fighters[1].brink, "both on the brink, with nobody near it before")
	var f = S.fighters[0]
	f.rallyCool = 0.0
	_expect(not SimWounds.rally(S, f, "second_wind"), "Rallies are off")
	SimCore.dispose(S)


func _last() -> void:
	var S := _fresh()
	var P = S.fighters[0]
	P.wear[SimWounds.HEAD] = int(P.wd.stageAt[1])   # the first has the more wear: the second wins
	S.T = float(DirEnding.cfg().lastAt) - 0.5
	S.game.timeCap = true
	var ko: bool = false
	for _k in range(1200):
		SimCore.step(S, [_moving(), _moving()])
		S.out.fx.clear()
		S.out.feed.clear()
		if S.game.ko != null:
			ko = true
			break
	_expect(ko, "lastAt: a finisher, and a KO")
	_expect(ko and S.game.ko == P, "the fighter with the more wear falls")
	SimCore.dispose(S)


func _levelPlayed() -> void:
	var S := _fresh()
	S.T = float(DirEnding.cfg().lastAt) - 0.5
	S.game.timeCap = true
	var ko: bool = false
	for _k in range(1200):
		SimCore.step(S, [_moving(), SimIntent.new()])
		S.out.fx.clear()
		S.out.feed.clear()
		if S.game.ko != null:
			ko = true
			break
	_expect(ko and not DirEnding.noContest(S), "level wear with someone playing: a finisher, no draw")
	SimCore.dispose(S)


func _level() -> void:
	var S := _fresh()
	S.T = float(DirEnding.cfg().lastAt) - 0.5
	S.game.timeCap = true
	for f in S.fighters:
		DirEnding._s(f, DirEnding.E_IDLE, 3700)
	var cue: int = 0
	for _k in range(90):
		SimCore.step(S, [SimIntent.new(), SimIntent.new()])
		for e in S.out.fx:
			if e.type == "cue" and e.kind == "no_contest":
				cue += 1
		S.out.fx.clear()
		S.out.feed.clear()
	_expect(cue == 1, "nobody touched anything: one no-contest cue (%d)" % cue)
	_expect(DirEnding.noContest(S) and S.game.ko == null, "a no-contest, with no KO")
	SimCore.dispose(S)
