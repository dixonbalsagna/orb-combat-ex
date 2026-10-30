extends SceneTree
# The floor of a lake or the sea (Game Design rulings 2026-10-30 rows 1, 4, 5, 7; data/biomes/water.json floor; docs/world/lake-floor.md; WorldWater.floorAt, WorldFill.floorOn).
#   godot --headless --path . --script res://sim/world/tools/floor_check.gd
var fails: int = 0


func ok(c: bool, w: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", w])
	if not c:
		fails += 1


func gen2_match(sd: int, touch: int) -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {}, {"planet": sd, "touch": touch, "arena": {"cols": 2400}, "planetGen": 2, "intro": false})
	return S


func hand_made() -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {}, {"intro": false})
	return S


## Every x in steps of dx across the ring: the largest excess of one sample's change of floor over what the ground's and the depth's changes allow (a floor f = g + h(d) has |df| <= |dg| + 2|dd|: more is a step), the largest jump
## across a column boundary, and the bounds the floor must keep.
func scan(S: SimState, dx: float) -> Dictionary:
	var excess: float = -1.0e9
	var edge: float = 0.0
	var pf: float = NAN
	var pg: float = 0.0
	var pd: float = 0.0
	var below: int = 0   # floor under the ground
	var firstBreak: String = ""
	var above: int = 0   # floor over the surface
	var wetSamples: int = 0
	var bed: int = 0     # d <= wade.below / 2 and the floor is not the ground
	var sheet: int = 0   # d >= wade.below and the floor is not the surface
	var half: float = WorldFill.wadeBelow() * 0.5
	var x: float = 0.0
	while x < SimConst.W:
		var g: float = WorldTerrain.groundY(S, x)
		var d: float = WorldWater.floorDepth(S, x)
		var f: float = WorldWater.floorAt(S, x)
		if f < g - 1.0e-9:
			below += 1
		if f > g + d + 1.0e-3:
			above += 1
			if firstBreak == "":
				firstBreak = "above at x=%.1f g=%.3f d=%.3f f=%.3f" % [x, g, d, f]
		if d > 0.0:
			wetSamples += 1
			if d <= half and absf(f - g) > 1.0e-9:
				bed += 1
				if firstBreak == "":
					firstBreak = "bed at x=%.1f g=%.3f d=%.3f f=%.3f" % [x, g, d, f]
			if d >= WorldFill.wadeBelow() and absf(f - (g + d)) > 1.0e-3:
				sheet += 1
				if firstBreak == "":
					firstBreak = "sheet at x=%.1f g=%.3f d=%.3f f=%.3f" % [x, g, d, f]
		if not is_nan(pf):
			excess = maxf(excess, absf(f - pf) - absf(g - pg) - 2.0 * absf(d - pd))
		pf = f
		pg = g
		pd = d
		x += dx
	for i in range(1, SimConst.NC):
		var xb: float = float(i) * SimConst.COL
		if S.water[i] >= 1.0 or S.water[i - 1] >= 1.0:
			edge = maxf(edge, absf(WorldWater.floorAt(S, xb + 1.0e-4) - WorldWater.floorAt(S, xb - 1.0e-4)))
	return {"excess": excess, "edge": edge, "below": below, "above": above, "wet": wetSamples, "bed": bed, "sheet": sheet, "first": firstBreak}


func _init() -> void:
	ok(WorldFill.dataErrors().is_empty(), "water.json is clean (%s)" % str(WorldFill.dataErrors()))
	ok(not WorldFill.floorOn() and WorldFill.wadeBelow() == 75.0, "the floor ships off, and wade.below is 75")
	# --- the curve (row 1)
	WorldFill.setFloor(true)
	var pts := {0.0: 0.0, 20.0: 20.0, 37.5: 37.5, 50.0: 25.0, 62.5: 12.5, 75.0: 0.0, 100.0: 0.0, 900.0: 0.0}
	var curveOk: bool = true
	for d in pts:
		if absf(WorldWater.feet(float(d)) - float(pts[d])) > 1.0e-9:
			curveOk = false
	ok(curveOk, "feet(d): the bed in water up to 37.5 deep, 25 at 50, nothing at 75 and below (the sheet), no step anywhere")
	var step: float = 0.0
	var d2: float = 0.0
	while d2 < 120.0:
		step = maxf(step, absf(WorldWater.feet(d2 + 0.01) - WorldWater.feet(d2)))
		d2 += 0.01
	ok(step < 0.0101, "the curve has no step: the largest change over 0.01 units of depth is %.4f" % step)
	# floor = surface - feet is the ground + d - feet(d): the waist at most in 37.5, then rising
	ok(absf(WorldWater.feet(46.0) - 29.0) < 1.0e-9, "tundra's 46-deep column: %.1f of him under the sheet (the ruling says 29)" % WorldWater.feet(46.0))

	# --- the floor's load check (row 10): both halves of the surfacing rule, and the message names both
	var on_: Dictionary = {"floor": {"enabled": true}, "surface": {"enabled": true, "ticks": 30}}
	var surfOff: Dictionary = {"floor": {"enabled": true}, "surface": {"enabled": false, "ticks": 30}}
	var offAll: Dictionary = {"floor": {"enabled": false}, "surface": {"enabled": false, "ticks": 30}}
	var named: bool = true
	for pr in [WorldFill.floorProblem(surfOff, true), WorldFill.floorProblem(on_, false), WorldFill.floorProblem(surfOff, false)]:
		named = named and String(pr).find("surface.enabled") >= 0 and String(pr).find("interrupts.json") >= 0 and String(pr).find("water.enabled") >= 0
	ok(WorldFill.floorProblem(on_, true) == "" and WorldFill.floorProblem(offAll, false) == "" and named, "the floor loads only with surface.enabled and interrupts water.enabled, and its error names both (off, anything goes)")
	ok(WorldFill.floorProblem(surfOff, true) != "" and WorldFill.floorProblem(on_, false) != "", "either half missing is an error")
	ok(WorldWater.riseMax(10) == 7.5 and WorldWater.riseMax(0) == 75.0, "the most a body under his floor rises in a tick is wade.below over riseTicks: %.1f at 10 ticks" % WorldWater.riseMax(10))

	# --- the hand-made world (the sea, a beach): the same floor, no special case (row 7)
	var H: SimState = hand_made()
	WorldFill.setFloor(false)
	var offSame: bool = true
	var x: float = 0.0
	while x < SimConst.W:
		if WorldWater.floorAt(H, x) != WorldTerrain.groundY(H, x):
			offSame = false
			break
		x += 7.0
	ok(offSame, "the floor off: floorAt is exactly the ground, everywhere on the hand-made world")
	WorldFill.setFloor(true)
	var on: Dictionary = scan(H, 1.0)
	ok(int(on.wet) > 100, "the hand-made world has %d wet samples to read" % int(on.wet))
	ok(float(on.excess) <= 2.0e-3 and float(on.edge) < 0.01, "the floor is continuous across the sea's edge and the shallows: no step (excess %.9f), %.4f across a column boundary" % [float(on.excess), float(on.edge)])
	ok(int(on.below) == 0 and int(on.above) == 0, "never under the ground, never over the surface (%d, %d)" % [int(on.below), int(on.above)])
	ok(int(on.bed) == 0 and int(on.sheet) == 0, "on the bed to 37.5 deep and on the sheet from 75 (%d off the bed, %d off the sheet)" % [int(on.bed), int(on.sheet)])
	var deep: float = -1.0
	for i in range(0, SimConst.NC, 5):
		if H.base[i] < -400.0:
			deep = (float(i) + 0.5) * SimConst.COL
			break
	ok(deep >= 0.0 and WorldWater.floorAt(H, deep) == 0.0, "mid-sea the floor is the sea level, 0 (the sheet)")
	# the rules measured from the ground stay measured from it: only the floor moves
	ok(WorldTerrain.groundY(H, deep) < -400.0, "groundY is still the sea bed there (%.0f): a power-up's crater reads it" % WorldTerrain.groundY(H, deep))
	WorldFill.setFloor(false)

	# --- a gen 2 ring with lakes (rows 1, 4, 5)
	var withLake: int = 0
	var deepLake: int = 0
	var worstExcess: float = -1.0e9
	var worstEdge: float = 0.0
	var bad: int = 0
	var seen: String = ""
	for sd in [7, 3, 11, 21, 25, 42]:
		for touch in [0, 1, 2]:
			var S: SimState = gen2_match(sd, touch)
			var lakes: Array = S.planetRing.get("lakes", [])
			if lakes.is_empty():
				continue
			withLake += 1
			var mx: float = 0.0
			for i in range(SimConst.NC):
				mx = maxf(mx, S.water[i] if S.base[i] >= WorldWater.SHORE_WET else 0.0)
			if mx >= 75.0:
				deepLake += 1
			WorldFill.setFloor(true)
			var r: Dictionary = scan(S, 2.0)
			WorldFill.setFloor(false)
			worstExcess = maxf(worstExcess, float(r.excess))
			worstEdge = maxf(worstEdge, float(r.edge))
			bad += int(r.below) + int(r.above) + int(r.bed) + int(r.sheet)
			if String(r.first) != "":
				print("   first break on ring %d/%d: %s" % [sd, touch, String(r.first)])
			seen += "%d/%d:%d " % [sd, touch, int(r.wet)]
	ok(withLake >= 3, "%d of the 18 rings hold a lake to read (%d deeper than wade.below)" % [withLake, deepLake])
	ok(bad == 0, "lakes and rivers: never under the ground or over the surface, on the bed to 37.5 and on the sheet from 75 (%d breaks; wet samples %s)" % [bad, seen])
	ok(worstExcess <= 2.0e-3 and worstEdge < 0.01, "and the floor is continuous through them: no step (excess %.9f), %.4f across a column boundary" % [worstExcess, worstEdge])

	# --- the line for a lake (row 4): wade.below, with water v2 off
	var L: SimState = null
	var lc: int = -1
	for sd in [7, 3, 11, 21, 25, 42]:
		for touch in [0, 1, 2]:
			var S2: SimState = gen2_match(sd, touch)
			var lakes2: Array = S2.planetRing.get("lakes", [])
			if lakes2.is_empty():
				continue
			for lk in lakes2:
				var mid: int = (int(lk[0]) + int(lk[3]) / 2) % SimConst.NC
				if S2.water[mid] >= 30.0 and WorldGround.live():
					L = S2
					lc = mid
					break
			if L != null:
				break
		if L != null:
			break
	ok(L != null, "a lake column to test on")
	if L != null:
		var xl: float = (float(lc) + 0.5) * SimConst.COL
		var keep: float = L.water[lc]
		for d in [30.0, 60.0, 80.0, 99.0, 120.0]:
			L.water[lc] = d
			WorldFill.setFloor(false)
			var seaOff: bool = WorldTerrain.seaAt(L, xl)
			var topOff: bool = WorldWater.seaTop(L, xl) != WorldWater.NO_SEA
			var wadeOff: bool = WorldFill.wading(L, xl)
			WorldFill.setFloor(true)
			var seaOn: bool = WorldTerrain.seaAt(L, xl)
			var topOn: bool = WorldWater.seaTop(L, xl) != WorldWater.NO_SEA
			var wadeOn: bool = WorldFill.wading(L, xl)
			WorldFill.setFloor(false)
			ok(seaOff == (d >= 100.0) and topOff == (d >= 100.0) and not wadeOff, "d=%d, floor off: sea %s (from 100, as before), waded %s (water v2 is off)" % [int(d), str(seaOff), str(wadeOff)])
			ok(seaOn == (d >= 75.0) and topOn == (d >= 75.0) and wadeOn == (d < 75.0), "d=%d, floor on: sea %s, waded %s (wade.below 75 for a lake, with water v2 off)" % [int(d), str(seaOn), str(wadeOn)])
		L.water[lc] = keep

		# --- a crater a fight dug in a lake's bed (Encounter's measurement: a straight-down launch at 2600 digs about 300; he popped 327 to 388 a tick later): the floor measures from the undug bed
		WorldFill.setFloor(true)
		var f0: float = WorldWater.floorAt(L, xl)
		var d0: float = WorldWater.floorDepth(L, xl)
		for k in range(-3, 4):
			L.deform[lc + k] -= 300.0
		WorldLakes.refill(L, lc, 3)   # the lake stands level over the hole, as the water module keeps it
		var f1: float = WorldWater.floorAt(L, xl)
		var d1: float = WorldWater.floorDepth(L, xl)
		var g1: float = WorldTerrain.groundY(L, xl)
		for k in range(-3, 4):
			L.deform[lc + k] += 300.0
		WorldLakes.refill(L, lc, 3)
		WorldFill.setFloor(false)
		ok(absf(f1 - f0) < 0.01 and absf(d1 - d0) < 0.01 and f1 >= g1, "a 300-deep crater in the lake's bed leaves his floor where it was: %.2f before, %.2f after (depth %.2f and %.2f), and the ground there is %.1f" % [f0, f1, d0, d1, g1])

		# --- a fill the fight dug is not the ring's water (row 5)
		var dry: int = -1
		for i in range(SimConst.NC):
			if L.base[i] > 500.0 and L.water[i] < 1.0 and L.water[(i + 1) % SimConst.NC] < 1.0 and L.water[(i + SimConst.NC - 1) % SimConst.NC] < 1.0 and not WorldLakes.inLake(L.planetRing.get("lakes", []), i, SimConst.NC):
				dry = i
				break
		if dry >= 0:
			var xd: float = (float(dry) + 0.5) * SimConst.COL
			L.water[dry] = 40.0   # a hole dug on high ground and filled
			WorldFill.setFloor(true)
			var fd: float = WorldWater.floorAt(L, xd)
			var gd: float = WorldTerrain.groundY(L, xd)
			WorldFill.setFloor(false)
			ok(fd == gd, "a 40-deep fill in a hole on high ground never lifts or holds him: the floor is the ground (%.1f, %.1f)" % [fd, gd])
			L.water[dry] = 0.0

	# --- a world with no water: the floor on changes nothing
	var G: SimState = gen2_match(7, 0)
	var dryOnly: bool = true
	WorldFill.setFloor(true)
	for i in range(0, SimConst.NC, 3):
		if G.water[i] < 1.0 and G.water[(i + 1) % SimConst.NC] < 1.0 and WorldWater.floorAt(G, (float(i) + 0.5) * SimConst.COL) != WorldTerrain.groundY(G, (float(i) + 0.5) * SimConst.COL):
			dryOnly = false
	WorldFill.setFloor(false)
	ok(dryOnly, "dry ground: the floor is the ground with the switch on")

	print("FLOOR: %d check(s) failed" % fails)
	quit(1 if fails > 0 else 0)
