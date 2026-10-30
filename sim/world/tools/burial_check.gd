extends SceneTree
# A burial needs water under half of wade.below at his column (Game Design rulings 2026-10-30 row 11): WorldWater.burialOK, the embed's condition in WorldContact. MARSH SWALLOW's always-embed holds only where a burial can start.
# Read here: on gen 2 rings, whether any wetland column (where a MARSH SWALLOW lands) holds the ring's own water as deep as that, so that the rule would take its embed away.
#   godot --headless --path . --script res://sim/world/tools/burial_check.gd
var fails: int = 0


func ok(c: bool, w: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", w])
	if not c:
		fails += 1


func gen2_match(sd: int, touch: int) -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {}, {"planet": sd, "touch": touch, "arena": {"cols": 2400}, "planetGen": 2, "intro": false})
	return S


func _init() -> void:
	var half: float = WorldFill.wadeBelow() * 0.5
	WorldFill.setFloor(false)
	var H := SimCore.createSim()
	SimCore.newMatch(H, 1, {}, {"intro": false})
	ok(WorldWater.burialOK(H, 100.0) and WorldWater.burialOK(H, 40000.0), "the floor off: a burial can start everywhere (the sea's too)")
	var rings: int = 0
	var marsh: int = 0
	var wet: int = 0
	var deepest: float = 0.0
	var deepAt: String = ""
	var shallow: int = 0   # wetland columns with the ring's own water at all
	var band: int = 0      # 37.5 to 75 deep: waded, not sea, so MARSH SWALLOW is offered there if the ground looks like mud
	var bandMud: int = 0
	var sea75: int = 0     # 75 deep or more: sea to every rule with the floor on, where MARSH SWALLOW is not offered
	var bandAt: String = ""
	for sd in [3, 7, 11, 13, 17, 19, 21, 23, 25, 29, 31, 42, 47, 101]:
		for touch in [0, 1, 2, 3]:
			var S: SimState = gen2_match(sd, touch)
			if WorldBiomes.fineCols.size() != SimConst.NC:
				continue
			rings += 1
			WorldFill.setFloor(true)
			for i in range(SimConst.NC):
				if int(WorldBiomes.fineCols[i]) != WorldClimate.F_WETLAND:
					continue
				marsh += 1
				var x: float = (float(i) + 0.5) * SimConst.COL
				var d: float = WorldWater.floorDepth(S, x)
				if d > 0.0:
					shallow += 1
				if d > deepest:
					deepest = d
					deepAt = "planet %d touch %d column %d" % [sd, touch, i]
				if not WorldWater.burialOK(S, x):
					wet += 1
					if d >= WorldFill.wadeBelow():
						sea75 += 1
					else:
						band += 1
						if WorldContact.lookAt(S, x) == "mud":
							bandMud += 1
							bandAt = "planet %d touch %d column %d, %.1f deep" % [sd, touch, i, d]
			WorldFill.setFloor(false)
	ok(rings >= 40 and marsh > 500, "%d gen 2 rings read, %d wetland columns" % [rings, marsh])
	print("  (%d wetland columns hold the ring's own water at all; the deepest is %.1f (%s); %d are %.1f deep or more)" % [shallow, deepest, deepAt, wet, half])
	print("  MARSH SWALLOW is offered over mud, not over sea (launch.gd): of the %d columns the rule stops, %d are 75 deep or more (sea with the floor on: never offered there), %d are 37.5 to 75 deep and %d of those look like mud (%s)" % [wet, sea75, band, bandMud, bandAt])
	ok(wet == sea75 + band, "every wetland column the rule stops holds the ring's own water %.1f deep or more (%d)" % [half, wet])
	# the rule itself, on a lake column
	var L: SimState = null
	var lc: int = -1
	for sd in [7, 3, 11, 21, 25, 42]:
		for touch in [0, 1, 2]:
			var S2: SimState = gen2_match(sd, touch)
			for lk in S2.planetRing.get("lakes", []):
				var mid: int = (int(lk[0]) + int(lk[3]) / 2) % SimConst.NC
				if S2.water[mid] >= 30.0 and L == null:
					L = S2
					lc = mid
	ok(L != null, "a lake column to test on")
	if L != null:
		var xl: float = (float(lc) + 0.5) * SimConst.COL
		var keep: float = L.water[lc]
		WorldFill.setFloor(true)
		var seen: Array = []
		var ks: Array = [L.water[lc - 1], L.water[lc], L.water[lc + 1]]
		for d in [10.0, 30.0, 37.0, 38.0, 60.0, 120.0]:
			for k in range(-1, 2):
				L.water[lc + k] = d
			seen.append(WorldWater.burialOK(L, xl))
		for k in range(-1, 2):
			L.water[lc + k] = ks[k + 1]
		WorldFill.setFloor(false)
		ok(seen == [true, true, true, false, false, false], "a lake column: a burial can start to 37 deep and not from 38 (%s)" % str(seen))
	print("BURIAL: %d check(s) failed" % fails)
	quit(1 if fails > 0 else 0)
