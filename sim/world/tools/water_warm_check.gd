extends SceneTree
# A new flow window reads its span in chunks (World, sim/world/water.gd flowWarm, data/biomes/water.json flowWarm.cols; docs/world/water-window-warm.md): off (cols 0) a window starts at age 0 and reads all its span in its first step,
# as it always did; on, it starts at minus the steps its span needs, no water moves in it until that is read, and then it flows as a window does; the same setup gives the same state twice. Prints the worst tick of each (informational).
#   godot --headless --path . --script res://sim/world/tools/water_warm_check.gd -- [--cols=48]
var fails: int = 0
var COLS: int = 48


func ok(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		fails += 1
		print("  FAIL ", what)


func _match(planet: int, touch: int) -> SimState:
	WorldClimate.useGen(3)
	WorldPlanet.forget()
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {}, {"intro": false, "planet": planet, "touch": touch, "planetGen": 3})
	for i in range(30):
		SimCore.step(S)
	return S


## A column of dry land within 60 columns of the sea (a coast): the centre of a dig that opens a flow window.
func _coast(S: SimState) -> int:
	var NC: int = SimConst.NC
	for i in range(0, NC):
		if WorldTerrain.baseAt(S, i) < WorldWater.RESERVOIR_BASE:
			continue
		var sea: bool = false
		for k in range(1, 60):
			if WorldTerrain.baseAt(S, posmod(i + k, NC)) < WorldWater.RESERVOIR_BASE:
				sea = true
				break
		if sea and WorldTerrain.baseAt(S, i) < 400.0:
			return i
	return -1


func _dig(S: SimState, c: int) -> void:
	var x: float = (float(c) + 0.5) * SimConst.COL
	WorldCrater.dig(S, x, 27.0, S.fighters[0], "impact", 0.0, 1.0, false, NAN, PackedFloat64Array(), true)   # a meteor-size bowl, a window of a few hundred columns


func _flow_wins(S: SimState) -> Array:
	var out: Array = []
	for w in S.waterWin:
		if w.size() <= 4:
			out.append(w)
	return out


func _run(planet: int, touch: int, cols: int) -> Dictionary:
	WorldFill.data()["flowWarm"] = {"cols": cols}
	var S := _match(planet, touch)
	var c: int = _coast(S)
	if c < 0:
		return {"coast": false}
	_dig(S, c)
	var wins: Array = _flow_wins(S)
	var all_steps: int = 0
	for w0 in wins:
		all_steps += -int(w0[3])
	var out := {"coast": true, "wins": wins.size(), "age0": int(wins[0][3]) if wins.size() > 0 else 0, "span": 2 * int(wins[0][1]) + 1 if wins.size() > 0 else 0, "all_steps": all_steps}
	var worst: float = 0.0
	var moved_early: bool = false
	var water0: float = 0.0
	for v in S.water:
		water0 += v
	var neg_ticks: int = 0
	var t_flow: int = -1
	var first120: Array = []
	for t in range(1200):
		var a: int = Time.get_ticks_usec()
		SimCore.step(S)
		var ms: float = float(Time.get_ticks_usec() - a) / 1000.0
		worst = maxf(worst, ms)
		if t < 120:
			first120.append([ms, t])
		var neg: bool = false
		for w in _flow_wins(S):
			if int(w[3]) < 0:
				neg = true
		for w2 in _flow_wins(S):
			if int(w2[3]) >= 1 and t_flow < 0:
				t_flow = t   # the first tick a window has taken a flow step
		if neg:
			neg_ticks += 1
		if t == 30:
			out["ticks_at_30"] = neg_ticks
	var water1: float = 0.0
	for v in S.water:
		water1 += v
	out["worst_ms"] = worst
	out["neg_ticks"] = neg_ticks
	out["t_flow"] = t_flow
	first120.sort_custom(func(p, q): return p[0] > q[0])
	out["top"] = "%.1f ms at tick %d, %.1f at %d, %.1f at %d" % [first120[0][0], first120[0][1], first120[1][0], first120[1][1], first120[2][0], first120[2][1]]
	out["water0"] = water0
	out["water1"] = water1
	out["hash"] = str(SimHash.stateHash(S).gameplay)
	return out


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--cols="):
			COLS = int(a.substr(7))
	var d: Dictionary = WorldFill.data()
	ok(int(d.get("flowWarm", {}).get("cols", -1)) == 0, "off in the data as shipped (flowWarm.cols 0)")
	var picks: Array = [[7, 1], [12, 1], [7, 2], [3, 1], [13, 1], [17, 1]]
	var done: bool = false
	for p in picks:
		var off: Dictionary = _run(p[0], p[1], 0)
		if not off.coast or int(off.wins) == 0:
			continue
		var on: Dictionary = _run(p[0], p[1], COLS)
		var on2: Dictionary = _run(p[0], p[1], COLS)
		ok(int(on.wins) >= 1 and int(off.age0) == 0, "planet %d touch %d: off, the dig's window (span %d) starts at age 0" % [p[0], p[1], int(off.span)])
		var steps: int = (int(on.span) + COLS - 1) / COLS
		ok(int(on.age0) == -steps and steps >= 2, "on (%d a step): the window starts at minus %d steps to read %d columns (%d)" % [COLS, steps, int(on.span), int(on.age0)])
		ok(int(on.neg_ticks) > 0 and int(off.neg_ticks) == 0 and int(off.t_flow) >= 0 and absi(int(on.t_flow) - int(off.t_flow) - 2 * int(on.all_steps)) <= 2, "the first flow step comes %d ticks later (the %d window(s) need %d steps of 2); the off run never warms (%d)" % [int(on.t_flow) - int(off.t_flow), int(on.wins), int(on.all_steps), int(off.neg_ticks)])
		ok(on.hash == on2.hash, "the same setup gives the same state twice")
		ok(absf(float(on.water1) - float(off.water1)) <= 0.01 * maxf(1.0, absf(float(off.water1))), "after 1,200 ticks the water is the same (%.0f against %.0f)" % [float(on.water1), float(off.water1)])
		print("  info worst tick over 1,200 after the dig: off %.1f ms, on %.1f ms (a shared PC, indicative)" % [float(off.worst_ms), float(on.worst_ms)])
		print("  info the three worst ticks of the first 120 after the dig: off: %s; on: %s" % [off.top, on.top])
		done = true
		break
	ok(done, "a coast with a window was found to test on")
	WorldFill.data()["flowWarm"] = {"cols": 0}
	print("WATERWARM: %d check(s) failed" % fails)
	quit(0 if fails == 0 else 1)
