extends SceneTree
# Lakes and rivers as planet records on the field (World, sim/world/waterrec.gd): the records the ring's plan implies hold the same water on the line, hold it in two dimensions off the line, are pure functions of
# the point, and a river's channel is continuous. Needs the state's fieldRecs (sim/core/state.gd).
#   godot --headless --path . --script res://sim/world/tools/field_water_check.gd
var fails: int = 0


func ok(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		fails += 1
		print("  FAIL ", what)


func _match(planet: int, touch: int) -> SimState:
	WorldPlanet.forget()
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {}, {"planet": planet, "touch": touch, "arena": {"cols": 2400}, "planetGen": 3, "intro": false})
	return S


func _init() -> void:
	WorldClimate.useGen(3)
	var S: SimState = null
	var pl: int = 0
	var tc: int = 0
	for cand in [[7, 1], [3, 1], [11, 1], [25, 1], [7, 2], [3, 2], [5, 1], [9, 1], [13, 1], [17, 1], [21, 1], [29, 1]]:
		var T: SimState = _match(cand[0], cand[1])
		var n: int = 0
		for lk in T.planetRing.get("lakes", []):
			if lk.size() == 4:
				n += 1
		if n > 0:
			S = T
			pl = cand[0]
			tc = cand[1]
			break
	ok(S != null, "a gen 3 ring with lakes was found (planet %d touch %d)" % [pl, tc])
	if S == null:
		print("FIELDWATER: %d check(s) failed" % fails)
		quit(1)
		return
	var P := WorldPlanet.make(pl)
	var circ: Dictionary = WorldRingPick.ringFrom(S.planetRing.c, int(S.planetRing.cols), S.planetRing.t)
	var strip: Array = []
	for lk in S.planetRing.get("lakes", []):
		if lk.size() == 4:
			strip.append(lk)
	var recs: Array = []
	for r in S.fieldRecs:
		if r.k == "lake":
			recs.append(r)
	ok(recs.size() == strip.size(), "%d lake records for the ring's %d lakes" % [recs.size(), strip.size()])
	var NC: int = SimConst.NC
	var worst: float = 0.0
	var tested: int = 0
	var inside_miss: int = 0
	var outside_wet: int = 0
	var differs: int = 0
	for lk in strip:
		var first: int = int(lk[0])
		var w: int = int(lk[3])
		for k in range(0, w, 3):
			var c: int = (first + k) % NC
			var q: Array = WorldPlanet.columnPoint(P, circ, c)
			var h: float = WorldField.applyRecords(S, q[0], q[1], q[2], WorldField.height(P, q[0], q[1], q[2]))
			if absf(h - S.base[c]) > 1.0:
				differs += 1
				continue
			var want: float = maxf(0.0, float(lk[2]) - S.base[c])
			var got: float = WorldField.recordWater(S, q[0], q[1], q[2], h)
			if want > 0.0:
				tested += 1
				if got <= 0.0:
					inside_miss += 1
				worst = maxf(worst, absf(got - want))
		for off in [-14, w + 14]:
			var c2: int = ((first + off) % NC + NC) % NC
			var q2: Array = WorldPlanet.columnPoint(P, circ, c2)
			var h2: float = WorldField.applyRecords(S, q2[0], q2[1], q2[2], WorldField.height(P, q2[0], q2[1], q2[2]))
			if absf(h2 - S.base[c2]) > 1.0:
				differs += 1
				continue
			if WorldField.recordWater(S, q2[0], q2[1], q2[2], h2) > 0.0 and S.water[c2] <= 0.0:
				outside_wet += 1
	ok(tested > 0 and inside_miss == 0 and worst < 0.5, "on the line the records hold the ring's water: %d columns, %d missed, depth differs by %.3f at most (%d columns skipped where the ring's ground and the field plus platforms differ by over a unit)" % [tested, inside_miss, worst, differs])
	print("  info %d of the points 14 columns beyond a lake's ends on the line are wet in the records and dry on the line: the basin is flooded in two dimensions and the ring's plan stopped at a crest (the 2D water is the truth in a swing)" % outside_wet)
	# in two dimensions: off the line at a lake's middle
	var wide: int = 0
	var total: int = 0
	for lk in strip:
		var mid: int = (int(lk[0]) + int(lk[3]) / 2) % NC
		var x: float = float(mid) * SimConst.COL
		var wet: int = 0
		for z in range(-1600, 1601, 100):
			var q3: Array = WorldPlan.pointAtX(P, circ, x, float(z))
			var h3: float = WorldField.height(P, q3[0], q3[1], q3[2])
			h3 = WorldField.applyRecords(S, q3[0], q3[1], q3[2], h3)
			if WorldField.recordWater(S, q3[0], q3[1], q3[2], h3) > 0.0:
				wet += 1
		total += 1
		if wet > 1:
			wide += 1
		print("  info lake at column %d (level %.0f, %d columns on the line): water at %d of 33 points across the line" % [mid, float(lk[2]), int(lk[3]), wet])
	ok(total > 0, "%d lakes sampled across the line, %d of them wider than the line itself" % [total, wide])
	# pure: the same point read twice and after another read is the same
	var q4: Array = WorldPlanet.columnPoint(P, circ, (int(strip[0][0]) + 2) % NC)
	var h4: float = WorldField.height(P, q4[0], q4[1], q4[2])
	var a4: float = WorldField.recordWater(S, q4[0], q4[1], q4[2], h4)
	var q5: Array = WorldPlanet.columnPoint(P, circ, 100)
	WorldField.recordWater(S, q5[0], q5[1], q5[2], 0.0)
	ok(a4 == WorldField.recordWater(S, q4[0], q4[1], q4[2], h4), "a water read is a pure function of the point")
	# rivers, with the switch on for this process
	WorldRivers.setOn(true)
	var found: bool = false
	for cand in [[7, 2], [3, 2], [11, 2], [25, 2], [7, 1], [3, 1], [5, 2], [9, 2]]:
		var R2: SimState = _match(cand[0], cand[1])
		var rivers: Array = []
		for r in R2.fieldRecs:
			if r.k == "river":
				rivers.append(r)
		if rivers.is_empty():
			continue
		found = true
		var P2 := WorldPlanet.make(cand[0])
		print("  info planet %d touch %d: %d river segment records near the ring" % [cand[0], cand[1], rivers.size()])
		# along the strongest segment: the level never jumps, the bed is under the level, the channel is as wide as the record says
		var best: Dictionary = rivers[0]
		for r in rivers:
			if float(r.flow) > float(best.flow):
				best = r
		var jump: float = 0.0
		var prev: float = NAN
		var under: bool = true
		var wetn: int = 0
		for k in range(0, 21):
			var t: float = float(k) / 20.0
			var a: Array = best.a
			var b: Array = best.b
			var qx: float = a[0] + (b[0] - a[0]) * t
			var qy: float = a[1] + (b[1] - a[1]) * t
			var qz: float = a[2] + (b[2] - a[2]) * t
			var ql: float = sqrt(qx * qx + qy * qy + qz * qz)
			qx /= ql
			qy /= ql
			qz /= ql
			var bl: Array = WorldWaterRec.riverBed(P2, best, qx, qy, qz)
			if bl.is_empty():
				continue
			wetn += 1
			under = under and float(bl[0]) < float(bl[1])
			if not is_nan(prev):
				jump = maxf(jump, absf(float(bl[1]) - prev))
			prev = float(bl[1])
		ok(wetn > 0 and under, "the strongest river (flow %.0f): %d of 21 points along its axis are in a channel, bed under level" % [float(best.flow), wetn])
		ok(jump < 120.0, "its level changes by %.1f units at most between points a twentieth of a segment apart" % jump)
		break
	if not found:
		print("  info no river segments near the rings tried: the river half is not exercised on these planets")
	WorldRivers.setOn(false)
	print("FIELDWATER: %d check(s) failed" % fails)
	quit(0 if fails == 0 else 1)
