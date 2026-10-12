extends SceneTree
## The brawl's reads are pure (Encounter): calling every read that other layers use, on both fighters, leaves the
## gameplay hash and the count of each fighter's director integers as they were. It is run on a fresh match, a fresh
## match with an intro, a match with a player in slot 0, after one tick, on the first tick of a brawl and on the tick
## after that brawl ends. Exit code 1 on a failure.
## godot --headless --path . --script res://sim/director/tools/reads_check.gd

var fails := 0
var checks := 0


func _reads(S: SimState) -> void:
	var ex = S.dirS.ex
	for f in S.fighters:
		DirBrawl.launcherRest(S, f)
		DirBrawl.launcherReady(S, f)
		DirBrawl.launcherOpen(S, f)
		DirBrawl.winding(S, f)
		DirBrawl.giving(S, f)
		DirBrawl.inBrawl(S, f)
		DirBrawl.busy(S, f)
		DirBrawl.beatAt(S, f)
		DirBrawl.open(S, f)
		if DirBrawl.isBrawl(ex):
			DirBrawl.stick(ex, f)
	DirBrawl.centre(S, ex)
	DirBrawl.doubling(ex)


func _check(S: SimState, what: String) -> void:
	var h0: String = JSON.stringify(SimHash.stateHash(S))
	var n0: Array = [S.fighters[0].act.dirI.size(), S.fighters[1].act.dirI.size()]
	_reads(S)
	var h1: String = JSON.stringify(SimHash.stateHash(S))
	var n1: Array = [S.fighters[0].act.dirI.size(), S.fighters[1].act.dirI.size()]
	checks += 1
	if h0 != h1 or n0 != n1:
		fails += 1
		print("FAIL  ", what, ": the hash ", "changed" if h0 != h1 else "held", "; the integers' counts ", n0, " then ", n1)
	else:
		print("ok    ", what, " (counts ", n0, ")")


func _init() -> void:
	for setup in [{"name": "two AIs", "ai": {"p1": true, "p2": true}, "s": {}}, {"name": "two AIs, an intro", "ai": {"p1": true, "p2": true}, "s": {"intro": true}},
			{"name": "a player in slot 0", "ai": {"p1": false, "p2": true}, "s": {"v2": [true, false]}}, {"name": "a player in slot 0, an intro", "ai": {"p1": false, "p2": true}, "s": {"v2": [true, false], "intro": true}}]:
		var S := SimCore.createSim()
		SimCore.newMatch(S, 7, setup.ai, setup.s)
		_check(S, String(setup.name) + ": a fresh match")
		SimCore.step(S, null if bool(setup.ai.p1) else [SimIntent.new(), null])
		S.out.fx.clear()
		S.out.feed.clear()
		_check(S, String(setup.name) + ": after one tick")
		var seen := false
		var after := false
		while S.tick < 20000 and S.game.ko == null and not after:
			SimCore.step(S, null if bool(setup.ai.p1) else [SimIntent.new(), null])
			S.out.fx.clear()
			S.out.feed.clear()
			var inB: bool = DirBrawl.isBrawl(S.dirS.ex)
			if inB and not seen:
				seen = true
				_check(S, String(setup.name) + ": the first tick of a brawl (tick " + str(S.tick) + ")")
			elif seen and not inB:
				after = true
				_check(S, String(setup.name) + ": the tick after it ends (tick " + str(S.tick) + ")")
		if not seen:
			print("note  ", setup.name, ": no brawl in 20000 ticks")
	print("reads_check: ", checks - fails, " of ", checks, " passed")
	quit(1 if fails > 0 else 0)
