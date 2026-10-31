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


## A real slam on the hand-made world: a special launch straight down (3200) over x, the pair put on the floor there and the rival 400 off, followed 240 ticks of the full step. The most embedT he has, and where he ends.
func slam(x: float, on: bool) -> Dictionary:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {"p1": false, "p2": false}, {"intro": false, "v2": [true, true]})
	WorldFill.setSurface(on)
	WorldFill.setFloor(on)
	DirInterrupt.data()["water"]["enabled"] = on
	DirInterrupt.data()["water"]["riseTicks"] = 10
	var A = S.fighters[0]
	var D = S.fighters[1]
	for f in S.fighters:
		f.ai = null
		f.rush = null
		f.vx = 0.0
		f.vy = 0.0
		f.z = 0.0
		f.zT = 0.0
		f.state = "free"
		f.stunTicks = 0
	D.x = SimWrap.wrap(x)
	D.y = WorldWater.floorAt(S, D.x) + 200.0
	A.x = SimWrap.wrap(x + 400.0)
	A.y = WorldWater.floorAt(S, A.x)
	D.state = "locked"
	S.dirS.ex = DirExchange.newEx(A, D, "probe")
	DirLaunch.doLaunch(S, A, D, {"name": "SLAM DOWN", "ux": 0.0, "uy": -1.0}, 3200.0, true)
	S.dirS.ex = null
	var emb: int = 0
	var low: float = 1.0e9
	for t in range(240):
		SimCore.step(S)
		emb = maxi(emb, int(D.embedT))
		low = minf(low, D.y)
	var r: Dictionary = {"emb": emb, "low": low, "end": D.y, "floor": WorldWater.floorAt(S, x), "state": String(D.state)}
	WorldFill.setSurface(false)
	WorldFill.setFloor(false)
	SimCore.dispose(S)
	return r


## The hand-made world's column whose water is nearest to depth (the sea's own, 5 either side), with the sea's open water on both sides if asked; NAN if none.
func column(S: SimState, depth: float, openSea: bool) -> float:
	var best: float = NAN
	var off: float = 5.0
	for c in range(SimConst.NC):
		var x: float = (float(c) + 0.5) * SimConst.COL
		var e: float = absf(WorldWater.floorDepth(S, x) - depth)
		if e >= off:
			continue
		if openSea != (S.base[c] < WorldWater.RESERVOIR_BASE):
			continue
		off = e
		best = x
	return best


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
	# --- the sea (rows 7 and 11): a burial needs the bed, so the beach to 37.5 deep and not the sea beyond
	var H2 := SimCore.createSim()
	SimCore.newMatch(H2, 1, {}, {"intro": false})
	WorldFill.setFloor(true)
	var openAll: bool = true
	var openN: int = 0
	var beachOk: int = 0
	var beachNo: int = 0
	var beachBad: int = 0
	for i in range(SimConst.NC):
		var xs: float = (float(i) + 0.5) * SimConst.COL
		var ds: float = WorldWater.floorDepth(H2, xs)
		if H2.base[i] < WorldWater.RESERVOIR_BASE:
			openN += 1
			if WorldWater.burialOK(H2, xs):
				openAll = false
		elif ds > 0.0:
			if WorldWater.burialOK(H2, xs) == (ds < half):
				beachOk += 1 if ds < half else 0
				beachNo += 0 if ds < half else 1
			else:
				beachBad += 1
	WorldFill.setFloor(false)
	ok(openN > 100 and openAll, "the floor on: a burial can start in none of the hand-made world's %d open-sea columns" % openN)
	ok(beachOk > 5 and beachNo > 5 and beachBad == 0, "and on its shores exactly where the water is under %.1f deep: %d columns where it can, %d where it can't, %d wrong" % [half, beachOk, beachNo, beachBad])
	var xe: float = column(H2, 20.0, false)
	var xm: float = column(H2, 50.0, false)
	var xd: float = column(H2, 90.0, false)
	var xo: float = column(H2, 600.0, true)
	ok(not is_nan(xe) and not is_nan(xm) and not is_nan(xd) and not is_nan(xo), "shore columns about 20, 50 and 90 deep and an open-sea column to slam into (%s)" % str([xe, xm, xd, xo]))
	if not (is_nan(xe) or is_nan(xm) or is_nan(xd) or is_nan(xo)):
		for p in [["20 deep", xe, true], ["50 deep", xm, false], ["90 deep", xd, false], ["open sea", xo, false]]:
			var offr: Dictionary = slam(float(p[1]), false)
			var onr: Dictionary = slam(float(p[1]), true)
			print("   %s: floor off embed %d, lowest %.1f, ends %.1f; floor on embed %d, lowest %.1f, ends %.1f (floor %.1f), %s" % [String(p[0]), int(offr.emb), float(offr.low), float(offr.end), int(onr.emb), float(onr.low), float(onr.end), float(onr.floor), String(onr.state)])
			ok(int(offr.emb) > 0, "%s: the control, floor off: a special launch straight down embeds him (%d)" % [String(p[0]), int(offr.emb)])
			ok((int(onr.emb) > 0) == bool(p[2]), "%s: with the floor on a burial %s" % [String(p[0]), "starts" if bool(p[2]) else "does not start (no embed, no follow-up)"])
		var deepOn: Dictionary = slam(xo, true)
		ok(absf(float(deepOn.end) - float(deepOn.floor)) < 1.0e-3 and String(deepOn.state) != "down", "slammed into the open sea he comes up to the sheet, standing (ends %.3f on the floor %.3f, %s)" % [float(deepOn.end), float(deepOn.floor), String(deepOn.state)])
	print("BURIAL: %d check(s) failed" % fails)
	quit(1 if fails > 0 else 0)
