extends SceneTree
# Window 12: SimRun.beginGround's planet made in steps (WorldPlanet.makeJob): a cold gen 2 planet is made over the reads, a frame at a time, and the ground it picks is the one a warm call picks.
#   godot --headless --path . --script res://sim/world/tools/host_check.gd
var fails: int = 0


func ok(c: bool, w: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", w])
	if not c:
		fails += 1


func _init() -> void:
	WorldClimate.useGen(2)
	var run: String = "00000000000000a7"
	WorldPlanet.forget()
	var g: SimRun.GroundJob = SimRun.beginGround(run, 1, "RIVAL")
	ok(g.pj != null and not g.pj.done and g.rule == "" and g.job == null and g.first == null, "cold: the planet is pending and the ground has not started")
	var n: int = 0
	var worst: int = 0
	var t0: int = Time.get_ticks_usec()
	while not g.done and n < 200000:
		var t1: int = Time.get_ticks_usec()
		g.step(1)
		worst = maxi(worst, Time.get_ticks_usec() - t1)
		n += 1
	var total: int = Time.get_ticks_usec() - t0
	ok(g.done and g.pj == null and g.rule != "", "stepped to the end: %d reads in %.0f ms, the longest one %.1f ms" % [n, float(total) / 1000.0, float(worst) / 1000.0])
	var cold: String = JSON.stringify(g.result)
	var w: SimRun.GroundJob = SimRun.beginGround(run, 1, "RIVAL")
	ok(w.pj == null and w.rule != "", "warm: the planet is whole and the ground starts in beginGround, as it always did")
	w.finishNow()
	ok(JSON.stringify(w.result) == cold, "the same ground, cold and warm")
	WorldPlanet.forget()
	var c2: SimRun.GroundJob = SimRun.beginGround(run, 1, "RIVAL")
	c2.finishNow()
	ok(JSON.stringify(c2.result) == cold, "finishNow on a cold job: the same ground")
	print("HOST: %d check(s) failed" % fails)
	quit()
