extends SceneTree
# (with the rise: a body under his floor rises at most wade.below / riseTicks a tick, rulings 2026-10-30 row 9)
# The floor of a lake or the sea as a fighter meets it (docs/world/lake-floor.md; the grant lines in sim/core/fighter.gd): a free fighter holds the stick toward a lake, and down, and swims in; with the floor off he sinks to the bed.
#   godot --headless --path . --script res://sim/world/tools/floor_walk_probe.gd
var fails: int = 0


func ok(c: bool, w: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", w])
	if not c:
		fails += 1


func gen2_match(sd: int, touch: int) -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {"p1": false, "p2": false}, {"planet": sd, "touch": touch, "arena": {"cols": 2400}, "planetGen": 2, "intro": false})
	return S


## The ring and the lake: the widest lake of a ring that holds one at least 100 deep.
func find() -> Array:
	for sd in [7, 3, 11, 21, 25, 42]:
		for touch in [0, 1, 2]:
			var S: SimState = gen2_match(sd, touch)
			for lk in S.planetRing.get("lakes", []):
				var mx: float = 0.0
				for k in range(int(lk[3])):
					mx = maxf(mx, S.water[(int(lk[0]) + k) % SimConst.NC])
				if mx >= 100.0 and int(lk[3]) >= 14 and float(lk[2]) > 5.0:
					return [sd, touch, int(lk[0]), int(lk[3])]
	return []


## Walk: from 24 columns left of the lake's first column, stick right and down, ticks ticks. Returns the track of [x, y, floor, ground, depth].
func water(on: bool, riseTicks: int = 10) -> void:
	WorldFill.setSurface(on)
	WorldFill.setFloor(on)
	DirInterrupt.data()["water"]["enabled"] = on   # the floor needs both halves of the surfacing rule (row 10)
	DirInterrupt.data()["water"]["riseTicks"] = riseTicks


func walk(sd: int, touch: int, c0: int, cols: int, floorOn: bool, ticks: int) -> Array:
	var S: SimState = gen2_match(sd, touch)
	water(floorOn)
	var f = S.fighters[0]
	f.x = (float(c0 - 24) + 0.5) * SimConst.COL
	f.y = WorldTerrain.groundY(S, f.x) + 10.0
	f.state = "free"
	f.vx = 0.0
	f.vy = 0.0
	f.z = 0.0
	f.input.mx = 1.0
	f.input.my = -1.0
	var out: Array = []
	for t in range(ticks):
		SimFighter.stepFighter(S, f, SimConst.DT)
		S.tick += 1
		out.append([f.x, f.y, WorldWater.floorAt(S, f.x, f.z), WorldTerrain.groundY(S, f.x, f.z), WorldWater.floorDepth(S, f.x, f.z), WorldWater.seaTop(S, f.x)])
	water(false)
	return out


## A column of one of the ring's lakes 60 to 70 deep (a lift of 45 to 65 from the bed to the floor), or -1.
func shoulder(S: SimState) -> int:
	for lk in S.planetRing.get("lakes", []):
		for k in range(int(lk[3])):
			var c: int = (int(lk[0]) + k) % SimConst.NC
			if S.water[c] >= 60.0 and S.water[c] <= 70.0 and S.water[(c + 1) % SimConst.NC] >= 60.0 and S.water[(c + SimConst.NC - 1) % SimConst.NC] >= 60.0:
				return c
	return -1


## A real get-up and a real drop's end on the bed of water 60 to 70 deep, with the surfacing's riseTicks as given: the largest change of height in one tick, the number of ticks he rose over, and where he ends against his floor.
func rise(riseTicks: int) -> Dictionary:
	var best: Dictionary = {}
	for sd in [7, 3, 11, 21, 25, 42]:
		for touch in [0, 1, 2]:
			var S: SimState = gen2_match(sd, touch)
			var c: int = shoulder(S)
			if c < 0:
				continue
			water(true, riseTicks)
			var x: float = (float(c) + 0.5) * SimConst.COL
			var out: Dictionary = {"lift": WorldWater.floorAt(S, x) - WorldTerrain.groundY(S, x)}
			for how in ["getup", "drop"]:
				var f = S.fighters[0]
				f.x = x
				f.z = 0.0
				f.vx = 0.0
				f.vy = 0.0
				f.input.mx = 0.0
				f.input.my = 0.0
				f.y = WorldTerrain.groundY(S, x)
				if how == "getup":
					f.state = "down"
					f.stateT = 0.0
					f.embedT = 0
				else:
					f.state = "free"
					SimFighter.drop(S, f, 20)
				var maxDy: float = 0.0
				var ticksRising: int = 0
				var prev: float = f.y
				for t in range(120):
					SimFighter.stepFighter(S, f, SimConst.DT)
					S.tick += 1
					maxDy = maxf(maxDy, f.y - prev)
					if f.y - prev > 0.01:
						ticksRising += 1
					prev = f.y
				out[how] = {"maxDy": maxDy, "ticks": ticksRising, "gap": WorldWater.floorAt(S, x) - f.y, "state": f.state}
			water(false)
			return out
	return best


func _init() -> void:
	var pick: Array = find()
	ok(not pick.is_empty(), "a ring with a lake at least 100 deep and 14 columns wide: %s" % str(pick))
	if pick.is_empty():
		quit(1)
		return
	var sd: int = pick[0]
	var touch: int = pick[1]
	var c0: int = pick[2]
	var cols: int = pick[3]
	var ticks: int = int((float(cols + 48) * SimConst.COL) / (430.0 / 60.0 * 0.8)) + 120
	var on: Array = walk(sd, touch, c0, cols, true, ticks)
	var off: Array = walk(sd, touch, c0, cols, false, ticks)
	var below: int = 0
	var off_floor: int = 0
	var maxDy: float = 0.0
	var inWater: int = 0
	var lag: int = 0
	var onSheet: int = 0
	var sunk: int = 0
	var slow: int = 0
	for k in range(on.size()):
		var r: Array = on[k]
		if float(r[1]) < float(r[2]) - 1.0e-6:
			below += 1
		if float(r[4]) > 0.0:
			inWater += 1
			var fall: float = float(r[2]) - float((on[k - 1] as Array)[2]) if k > 0 else 0.0
			if absf(float(r[1]) - float(r[2])) > 1.0e-6:
				if fall < -0.05:
					lag += 1   # the floor is falling away faster than his own descent: he follows it down, as he follows any slope
				else:
					off_floor += 1
		if float(r[5]) > -1.0e17 and float(r[1]) == float(r[5]):
			onSheet += 1
		if k > 0:
			maxDy = maxf(maxDy, absf(float(r[1]) - float((on[k - 1] as Array)[1])))
	for r2 in off:
		if float((r2 as Array)[4]) > 0.0 and float((r2 as Array)[1]) < float((r2 as Array)[5]) - 1.0 and float((r2 as Array)[5]) > -1.0e17:
			sunk += 1
	ok(inWater > 40, "%d ticks in the lake's water to read" % inWater)
	ok(below == 0, "never under the floor (%d ticks)" % below)
	ok(off_floor <= 3, "stick down in the water: on the floor every tick the floor does not fall away under him (%d ticks off it; %d ticks he is following a falling floor down)" % [off_floor, lag])
	ok(onSheet > 10, "and on the sheet where the lake is deep: %d ticks at exactly the surface rules ask about (seaTop), so never 'below' it" % onSheet)
	ok(maxDy <= WorldWater.riseMax(10) + 1.0e-6, "an ordinary walk stays on the floor: the largest change of height in one tick is %.2f, under the rise limit %.1f (a fighter's own speed is %.2f a tick)" % [maxDy, WorldWater.riseMax(10), 430.0 / 60.0])
	ok(sunk > 10, "control, floor off: he sinks under the surface of the deep water (%d ticks under it)" % sunk)
	# --- row 9: a body below his floor rises over ticks, with the stick kept; the control (riseTicks 1: the whole depth in a tick) is the lift the review measured
	var real: Dictionary = rise(10)
	var ctl: Dictionary = rise(1)
	ok(not real.is_empty() and not ctl.is_empty() and float(real.lift) >= 45.0, "a lake with a 60 to 70 deep shoulder: the floor is %.1f above the bed there" % float(real.get("lift", 0.0)))
	for how in ["getup", "drop"]:
		var r: Dictionary = real.get(how, {})
		var c: Dictionary = ctl.get(how, {})
		ok(not r.is_empty() and float(r.maxDy) <= WorldWater.riseMax(10) + 1.0e-6 and int(r.ticks) >= 5 and absf(float(r.gap)) < 1.0e-6, "real %s: he rises at most %.2f a tick (limit %.1f) over %d ticks and ends on his floor (gap %.6f)" % [how, float(r.get("maxDy", -1.0)), WorldWater.riseMax(10), int(r.get("ticks", 0)), float(r.get("gap", 1.0))])
		ok(not c.is_empty() and float(c.maxDy) >= 16.0, "control %s, riseTicks 1 (no limit): he is lifted %.1f in one tick, the bug Simulation measured" % [how, float(c.get("maxDy", 0.0))])
	var lastOff: Array = off[off.size() - 1]
	ok(true, "(floor off, end of the walk: x %.0f y %.1f ground %.1f)" % [float(lastOff[0]), float(lastOff[1]), float(lastOff[3])])
	print("FLOORWALK: %d check(s) failed" % fails)
	quit(1 if fails > 0 else 0)
