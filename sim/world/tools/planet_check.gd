extends SceneTree
# WorldPlanet's checks (window 1): the data, our own inverse trig, determinism and the caches, picture A's planet, the ice, the picker, the slice, the wear list.
#   godot --headless --path . --script res://sim/world/tools/planet_check.gd [-- --write]     (--write regenerates sim/world/tools/planet_vectors.json)
const VECTORS := "res://sim/world/tools/planet_vectors.json"
const A2 := "res://docs/world/scratch-build/planet-slice/planet2.json"
var fails: int = 0


func ok(c: bool, w: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", w])
	if not c:
		fails += 1


func hexd(x: float) -> String:
	var b := PackedByteArray()
	b.resize(8)
	b.encode_double(0, x)
	return b.hex_encode()


func pointOf(r: SimRng) -> Array:
	return WorldPlanet.unitFromDraws(r.next(), r.next())


func _init() -> void:
	var write: bool = OS.get_cmdline_user_args().has("--write")
	# ---- 1. the data
	ok(WorldPlanet.dataErrors().is_empty(), "planet.json loads clean (%s)" % str(WorldPlanet.dataErrors()))
	var c: Dictionary = WorldPlanet.cfg()
	# ---- 2. our own inverse trig, against the engine's (the engine's only here, in the test)
	var worst: float = 0.0
	var r0 := SimRng.new(1)
	for i in range(4000):
		var x: float = r0.range_(-1.0, 1.0)
		worst = maxf(worst, absf(WorldPlanet.asinf(x) - asin(x)))
		worst = maxf(worst, absf(WorldPlanet.acosf(x) - acos(x)))
		var y: float = r0.range_(-5.0, 5.0)
		worst = maxf(worst, absf(WorldPlanet.atan2f(y, x) - atan2(y, x)))
	ok(worst < 1.0e-9, "atan2f, asinf and acosf agree with the engine's to %s over 12,000 values (a column is 1.3e-3 rad)" % str(worst))
	ok(WorldPlanet.atan2f(0.0, 0.0) == 0.0 and absf(WorldPlanet.atan2f(1.0, 0.0) - PI / 2.0) < 1.0e-12 and absf(WorldPlanet.atan2f(0.0, -1.0) - PI) < 1.0e-12, "atan2f on the axes")
	# ---- 3. no engine vectors, no engine trig in the module
	var src: String = FileAccess.get_file_as_string("res://sim/world/planet.gd")
	var banned := ["Vector2", "Vector3", "Transform", "randf", "randi", "Time.", "lerpf(", "clampf(", "smoothstep(", "snappedf(", "fposmod("]
	var hits: Array = []
	for line in src.split("\n"):
		var code: String = line.split("#")[0]
		for b in banned:
			if code.contains(b):
				hits.append(b)
		for fn in [" sin(", " cos(", "(sin(", "(cos(", " asin(", " acos(", "(asin(", "(acos(", " atan2(", "(atan2(", " atan(", " pow(", " exp(", " log("]:
			if code.contains(fn) and not code.contains("SimDetMath" + fn.strip_edges()):
				hits.append(fn)
	ok(hits.is_empty(), "planet.gd uses no engine vector types and no engine trig, pow or exp (%s)" % str(hits))
	# ---- 4. determinism and the caches
	WorldPlanet.forget()
	var P: WorldPlanet.Planet = WorldPlanet.make(7)
	var places0: String = ""
	for i in range(P.n):
		places0 += "%s/%s/%s/%d;" % [hexd(P.px[i]), hexd(P.py[i]), hexd(P.pz[i]), P.kind[i]]
	WorldPlanet.forget()
	var P2: WorldPlanet.Planet = WorldPlanet.make(7)
	var places1: String = ""
	for i in range(P2.n):
		places1 += "%s/%s/%s/%d;" % [hexd(P2.px[i]), hexd(P2.py[i]), hexd(P2.pz[i]), P2.kind[i]]
	ok(places0 == places1 and P.n > 30, "the planet of seed 7 is the same twice (%d places)" % P.n)
	var rp := SimRng.new(5)
	var pts: Array = []
	for i in range(160):
		pts.append(pointOf(rp))
	for i in range(40):   # points in the caps
		var z: float = (0.75 + 0.25 * rp.next()) * (1.0 if i % 2 == 0 else -1.0)
		var a: float = rp.range_(0.0, 2.0 * PI)
		var q: float = sqrt(1.0 - z * z)
		pts.append([q * SimDetMath.cos(a), z, q * SimDetMath.sin(a)])
	WorldPlanet.forget()
	var Pa: WorldPlanet.Planet = WorldPlanet.make(7)
	var fresh: Array = []
	for p in pts:
		fresh.append(hexd(WorldPlanet.surf(Pa, p[0], p[1], p[2])[0]) + "/" + str(Pa.outB))
	# warm the caches on other points, read again in another order
	var Pb: WorldPlanet.Planet = WorldPlanet.make(7)
	for k in range(600):
		var pp: Array = pointOf(rp)
		WorldPlanet.surf(Pb, pp[0], pp[1], pp[2])
	var same: bool = true
	for i in range(pts.size() - 1, -1, -1):
		var p2: Array = pts[i]
		var s2: String = hexd(WorldPlanet.surf(Pb, p2[0], p2[1], p2[2])[0]) + "/" + str(Pb.outB)
		if s2 != fresh[i]:
			same = false
	ok(same, "a point reads the same bits whether the cell caches are cold or warm, in either order (200 points)")
	# ---- 5. picture A's planet (the planet Orb saw): the module reproduces its places
	if FileAccess.file_exists(A2):
		var d = JSON.parse_string(FileAccess.get_file_as_string(A2))
		var same_n: int = 0
		for pl in d["places"]:
			for i in range(P.n):
				if absf(P.px[i] - pl["v"][0]) < 1.0e-5 and absf(P.py[i] - pl["v"][1]) < 1.0e-5 and absf(P.pz[i] - pl["v"][2]) < 1.0e-5:
					same_n += 1
		ok(same_n == d["places"].size() and P.n == d["places"].size(), "planet 7 has the places of picture A2 (%d of %d; the module has %d)" % [same_n, d["places"].size(), P.n])
	else:
		print("  skip  planet2.json is not in this tree: A2's places not compared")
	# ---- 6. the ice
	var seen := [0, 0, 0, 0, 0, 0, 0]
	var floeSum_hi: float = 0.0
	var floeN_hi: int = 0
	var floeSum_lo: float = 0.0
	var floeN_lo: int = 0
	var bergOk: bool = true
	var bergs: int = 0
	var shelf: int = 0
	var shelfOk: bool = true
	var outside_ice: int = 0
	var rr := SimRng.new(9)
	for i in range(5000):
		var q: Array = pointOf(rr)
		if i >= 1000:
			var zb: float = 0.74 + 0.24 * rr.next()
			var ab: float = rr.range_(0.0, 2.0 * PI)
			var qb2: float = sqrt(1.0 - zb * zb)
			q = [qb2 * SimDetMath.cos(ab), zb, qb2 * SimDetMath.sin(ab)]
		WorldPlanet.surfAt(P, q[0], q[1], q[2])
		seen[P.outB] += 1
		var b: int = P.outB
		if (b == WorldPlanet.BIO_SEA_ICE or b == WorldPlanet.BIO_ICE_SHEET) and absf(q[1]) < c.polarY:
			outside_ice += 1
		if b == WorldPlanet.BIO_SEA_ICE:
			if P.outH > 40.0:
				bergs += 1
				if P.outH < c.bergH0 - 0.001 or P.outH > c.bergH0 + c.bergH1 + 0.001:
					bergOk = false
			elif q[1] > c.packEdgeY + 0.04:
				floeSum_hi += P.outH
				floeN_hi += 1
			elif q[1] > 0.0 and q[1] < c.packEdgeY:
				floeSum_lo += P.outH
				floeN_lo += 1
	for i in range(2000):   # the south cap
		var z2: float = -(c.polarY + (1.0 - c.polarY) * rr.next())
		var a2: float = rr.range_(0.0, 2.0 * PI)
		var q2: float = sqrt(1.0 - z2 * z2)
		WorldPlanet.surfAt(P, q2 * SimDetMath.cos(a2), z2, q2 * SimDetMath.sin(a2))
		seen[P.outB] += 1
		if P.outB == WorldPlanet.BIO_ICE_SHEET and absf(P.outH - c.shelfH) <= c.shelfNoiseAmp * 0.5 + 0.001:
			shelf += 1
		if P.outB == WorldPlanet.BIO_ICE_SHEET and P.outH < c.shelfH - c.shelfNoiseAmp * 0.5 - 0.001:
			shelfOk = false
	ok(seen[WorldPlanet.BIO_ICE_SHEET] > 0 and seen[WorldPlanet.BIO_SEA_ICE] > 0 and seen[WorldPlanet.BIO_MOUNTAINS] > 0, "both ice biomes occur (sheet %d, sea ice %d of 5,000 points)" % [seen[5], seen[6]])
	ok(outside_ice == 0, "no ice outside the caps (latitude y beyond %.2f): %d" % [c.polarY, outside_ice])
	ok(floeN_hi > 5 and (floeN_lo == 0 or floeSum_hi / float(floeN_hi) > floeSum_lo / maxf(1.0, float(floeN_lo))), "floes are thicker toward the pole (%.1f units near it, %.1f toward the edge)" % [floeSum_hi / maxf(1.0, float(floeN_hi)), floeSum_lo / maxf(1.0, float(floeN_lo))])
	ok(bergOk, "bergs stand %d to %d units (%d seen)" % [int(c.bergH0), int(c.bergH0 + c.bergH1), bergs])
	ok(shelf > 50 and shelfOk, "the shelf is flat at %d units, within its noise, and no ice sheet dips below it (%d points seen)" % [int(c.shelfH), shelf])
	# no land in the north cap: every ground sample there is below zero or ice
	var landN: int = 0
	for i in range(500):
		var z3: float = c.packEdgeY - 0.02 + (1.0 - c.packEdgeY + 0.02) * rr.next()
		var a3: float = rr.range_(0.0, 2.0 * PI)
		var q3: float = sqrt(1.0 - z3 * z3)
		WorldPlanet.surfAt(P, q3 * SimDetMath.cos(a3), z3, q3 * SimDetMath.sin(a3))
		if P.outB in [1, 2, 3, 4]:
			landN += 1
	ok(landN == 0, "no land inside the north pack's edge (%d of 500)" % landN)
	# ---- 7. the picker
	var strictOk: int = 0
	var tried: int = 0
	var n: int = 150
	var firstSame: bool = true
	var times: Array = []
	for t in range(n):
		var r1: Dictionary = WorldPlanet.pick(P, t)
		if r1.ok:
			strictOk += 1
			tried += r1.tried
			if t < 10:
				var r2: Dictionary = WorldPlanet.pick(P, t)
				if r2.index != r1.index or hexd(r2.T[0]) != hexd(r1.T[0]):
					firstSame = false
	ok(float(strictOk) / float(n) >= 0.85, "the picker finds a slice meeting the minimum for %d%% of %d touch-downs (%.1f candidates tried)" % [round(100.0 * strictOk / n), n, float(tried) / maxf(1.0, float(strictOk))])
	ok(firstSame, "the same touch-down picks the same circle and the same point twice")
	var relOk: int = 0
	var strictMiss: int = 0
	for t in range(80):
		if not WorldPlanet.pick(P, t).ok:
			strictMiss += 1
			if WorldPlanet.pick(P, t, PackedByteArray(), true).ok:
				relOk += 1
	ok(strictMiss == 0 or relOk >= 1, "where the strict minimum finds nothing the relaxed one sometimes does (%d of %d of 80 touch-downs; the rest are moved to another touch-down)" % [relOk, strictMiss])
	var rm := WorldPlanet.pick(P, 3)
	ok(rm.ok and rm.eval.cities >= int(c.minCities) and rm.eval.towns >= int(c.minTowns) and rm.eval.biomes >= int(c.minBiomes) and rm.eval.land >= c.minLand, "an accepted slice holds the minimum (%d cities, %d towns, %d biomes, %.0f%% land)" % [rm.eval.cities, rm.eval.towns, rm.eval.biomes, 100.0 * rm.eval.land])
	# ---- 8. the slice
	var pr: Dictionary = WorldPlanet.pick(P, 3)
	var S: WorldPlanet.Slice = WorldPlanet.readSlice(P, pr.circle, pr.T)
	ok(S.heights.size() == SimConst.NC and S.biomes.size() == SimConst.NC, "a slice is %d columns of height and biome" % S.heights.size())
	var mid: Array = WorldPlanet.columnPoint(P, pr.circle, WorldPlanet.TOUCH_COL)
	ok(absf(mid[0] - pr.T[0]) < 1.0e-9 and absf(mid[1] - pr.T[1]) < 1.0e-9 and absf(mid[2] - pr.T[2]) < 1.0e-9, "the middle column is the touch-down")
	var nHeldCities: int = 0
	for h in S.held:
		if h.kind == WorldPlanet.KIND_CITY:
			nHeldCities += 1
	ok(nHeldCities == pr.eval.cities, "the places the slice holds are the ones the picker counted (%d cities)" % nHeldCities)
	var colsOk: bool = true
	for h in S.held:
		var cp: Array = WorldPlanet.columnPoint(P, pr.circle, h.col)
		var dx: float = cp[0] - P.px[h.id]
		var dy: float = cp[1] - P.py[h.id]
		var dz: float = cp[2] - P.pz[h.id]
		var chord: float = P.R * sqrt(dx * dx + dy * dy + dz * dz)
		if absf(chord - absf(h.d)) > SimConst.COL:   # the nearest column is within a column of the place's foot
			colsOk = false
	ok(colsOk, "a held place's column is the nearest to its centre (within a column)")
	var h1: int = WorldPlanet.sliceHash(S)
	WorldPlanet.forget()
	var P3: WorldPlanet.Planet = WorldPlanet.make(7)
	var pr3: Dictionary = WorldPlanet.pick(P3, 3)
	var S3: WorldPlanet.Slice = WorldPlanet.readSlice(P3, pr3.circle, pr3.T)
	ok(WorldPlanet.sliceHash(S3) == h1, "the slice hash is the same from a cold planet (%08x)" % h1)
	var m1 := WorldPlanet.sliceFor(7, 3)
	var m2 := WorldPlanet.sliceFor(7, 3)
	ok(m1 == m2 and WorldPlanet.sliceHash(m1) == h1, "the memoised slice is the one the read gives")
	var heightsFinite: bool = true
	var kinds := [0, 0, 0, 0, 0, 0, 0]
	for i in range(S.heights.size()):
		if is_nan(S.heights[i]) or absf(S.heights[i]) > 20000.0:
			heightsFinite = false
		kinds[S.biomes[i]] += 1
	ok(heightsFinite, "every height is finite and under 20,000 units")
	# the same point reached along two circles (float64: the proof's 7.5e-12)
	var worstX: float = 0.0
	var rx := SimRng.new(77)
	for t in range(100):
		var nA: Array = WorldPlanet.unitFromDraws(rx.next(), rx.next())
		var nB: Array = WorldPlanet.unitFromDraws(rx.next(), rx.next())
		var X: Array = WorldPlanet._unit(WorldPlanet._cross(nA, nB))
		var cA: Dictionary = WorldPlanet.circleOf(WorldPlanet._unit(WorldPlanet._cross(nA, WorldPlanet.unitFromDraws(rx.next(), rx.next()))), nA)
		var cB: Dictionary = WorldPlanet.circleOf(WorldPlanet._unit(WorldPlanet._cross(nB, WorldPlanet.unitFromDraws(rx.next(), rx.next()))), nB)
		var qa: Array = [0.0, 0.0, 0.0]
		var qb: Array = [0.0, 0.0, 0.0]
		for pair in [[cA, qa], [cB, qb]]:
			var cc: Dictionary = pair[0]
			var ang: float = WorldPlanet.atan2f(X[0] * cc.v[0] + X[1] * cc.v[1] + X[2] * cc.v[2], X[0] * cc.u[0] + X[1] * cc.u[1] + X[2] * cc.u[2])
			var co: float = SimDetMath.cos(ang)
			var si: float = SimDetMath.sin(ang)
			pair[1][0] = cc.u[0] * co + cc.v[0] * si
			pair[1][1] = cc.u[1] * co + cc.v[1] * si
			pair[1][2] = cc.u[2] * co + cc.v[2] * si
		worstX = maxf(worstX, absf(WorldPlanet.surf(P, qa[0], qa[1], qa[2])[0] - WorldPlanet.surf(P, qb[0], qb[1], qb[2])[0]))
	ok(worstX < 1.0e-6, "one point reached along two circles agrees to %s units over 100 crossings" % str(worstX))
	# ---- 9. the wear list
	var wear: Dictionary = WorldPlanet.wearNew()
	var hp: Dictionary = {}
	for h in S.held:
		if h.kind == WorldPlanet.KIND_CITY:
			hp = h
			break
	var id: int = hp.id
	var frameBad: int = 0
	for k in range(60):
		var e0: int = int(rx.range_(-5000.0, 5000.0))
		var n0: int = int(rx.range_(-5000.0, 5000.0))
		var q4: Array = WorldPlanet.fromFrame(P, id, e0, n0)
		var back: Array = WorldPlanet.toFrame(P, id, q4[0], q4[1], q4[2])
		if absi(back[0] - e0) > 1 or absi(back[1] - n0) > 1:
			frameBad += 1
	ok(frameBad == 0, "a place's frame round-trips whole units to within one unit (60 points)")
	# a crater laid at a column of the slice's line comes back at that column
	var colTest: int = hp.col + 5
	var qc: Array = WorldPlanet.columnPoint(P, pr.circle, colTest)
	WorldPlanet.wearCrater(P, wear, qc[0], qc[1], qc[2], 160 * 16, 40 * 16, 1)
	var marks: Array = WorldPlanet.wearMarks(P, wear, S)
	ok(marks.size() == 1 and absi(marks[0].col - colTest) <= 1 and absi(marks[0].lateral) <= 2, "a crater laid on the line is read back at its column and on the line (col %d for %d, lateral %d)" % [marks[0].col if marks.size() > 0 else -1, colTest, marks[0].lateral if marks.size() > 0 else 0])
	var before: float = S.heights[colTest]
	var far: float = S.heights[(colTest + 400) % SimConst.NC]
	WorldPlanet.applyBowls(S, marks)
	ok(S.heights[colTest] < before - 30.0 and S.heights[(colTest + 400) % SimConst.NC] == far, "the bowl lowers its columns (%.1f units) and no others" % (before - S.heights[colTest]))
	# a negative depth is a raised mound (cooled magma)
	var wm: Dictionary = WorldPlanet.wearNew()
	var qm: Array = WorldPlanet.columnPoint(P, pr.circle, (colTest + 200) % SimConst.NC)
	WorldPlanet.wearCrater(P, wm, qm[0], qm[1], qm[2], 120 * 16, -30 * 16, 3)
	var Sm: WorldPlanet.Slice = WorldPlanet.readSlice(P, pr.circle, pr.T)
	var hm0: float = Sm.heights[(colTest + 200) % SimConst.NC]
	WorldPlanet.applyBowls(Sm, WorldPlanet.wearMarks(P, wm, Sm))
	ok(Sm.heights[(colTest + 200) % SimConst.NC] > hm0 + 20.0, "a negative depth raises the ground (a cooled-magma mound: +%.1f units)" % (Sm.heights[(colTest + 200) % SimConst.NC] - hm0))
	# an open-country crater is a point
	WorldPlanet.wearCrater(P, wear, 0.0, 1.0, 0.0, 16 * 16, 16 * 16, 2)
	ok(wear.open.size() == 1, "a crater outside every place is kept as a point of the sphere")
	WorldPlanet.wearBuilding(wear, id, 3, 2)
	WorldPlanet.wearBuilding(wear, id, 3, 1)
	ok(wear.pl[str(id)].bl == [[3, 2]], "a building keeps its highest stage")
	WorldPlanet.wearPeople(wear, id, 300, 100)
	WorldPlanet.wearPeople(wear, id, 900, 900)
	ok(wear.pl[str(id)].lost == 1000 and wear.pl[str(id)].gone == 0, "people lost and gone never pass a thousand together")
	var js: String = JSON.stringify(wear)
	var wb: Dictionary = WorldPlanet.wearFromJson(JSON.parse_string(js))
	var allInt: bool = true
	for k in wb.pl:
		for cr in wb.pl[k].cr:
			for v in cr:
				if v != int(v):
					allInt = false
	ok(allInt and JSON.stringify(wb) == js, "the wear list is whole numbers and round-trips through JSON byte for byte")
	# folding
	var w2: Dictionary = WorldPlanet.wearNew()
	for k in range(int(c.craterCap) + 30):
		WorldPlanet.wearCrater(P, w2, qc[0], qc[1], qc[2], 16 * 16, 8 * 16, 1)
	ok(w2.pl[str(id)].cr.size() == int(c.craterCap), "past the cap the oldest craters merge (%d kept)" % w2.pl[str(id)].cr.size())
	# status and the mask
	var w3: Dictionary = WorldPlanet.wearNew()
	ok(WorldPlanet.placeStatus(w3, id, 40) == 0, "a place with no wear is fresh")
	WorldPlanet.wearBuilding(w3, id, 0, 3)
	WorldPlanet.wearBuilding(w3, id, 1, 3)
	ok(WorldPlanet.placeStatus(w3, id, 40) == 1, "2 of 40 buildings down (5%) is damaged")
	for k in range(2, 26):
		WorldPlanet.wearBuilding(w3, id, k, 4)
	ok(WorldPlanet.placeStatus(w3, id, 40) == 2, "26 of 40 down (under 40% standing) is fallen")
	var w4: Dictionary = WorldPlanet.wearNew()
	WorldPlanet.wearPeople(w4, id, 700, 0)
	ok(WorldPlanet.placeStatus(w4, id, 40) == 2, "70% of the people lost is fallen")
	var mask := WorldPlanet.standingMask(P, w3, [])
	ok(mask.size() == P.n and mask[id] == 0 and mask[(id + 1) % P.n] == 1, "the mask marks the fallen place and no other")
	# people of a slice
	var pe0: Array = WorldPlanet.slicePeople(P, S, WorldPlanet.wearNew())
	var sum0: int = 0
	for v in pe0:
		sum0 += v
	ok(sum0 == int(c.slicePeople), "a full slice's people sum to %d (%s)" % [sum0, str(pe0)])
	var pe1: Array = WorldPlanet.slicePeople(P, S, w4)
	var sum1: int = 0
	for v in pe1:
		sum1 += v
	ok(sum1 < sum0, "a slice through a ruin has fewer people (%d)" % sum1)
	# a fallen city is not offered or held by the picker
	var rf: Dictionary = WorldPlanet.pick(P, 3, mask)
	var heldFallen: bool = false
	if rf.ok:
		var Sf := WorldPlanet.readSlice(P, rf.circle, rf.T, mask)
		for h in Sf.held:
			if h.id == id and h.standing:
				heldFallen = true
	ok(not heldFallen, "with a city fallen, no slice counts it as standing")
	# ---- 10. offers
	var off: Array = WorldPlanet.offers(P, 5, PackedByteArray())
	var off2: Array = WorldPlanet.offers(P, 5, PackedByteArray())
	ok(off.size() == int(c.offerCount) and off[0].touch == off2[0].touch and off[2].touch == off2[2].touch, "three offers, the same twice (touch-downs %d, %d, %d)" % [off[0].touch, off[1].touch, off[2].touch])
	var distinct: bool = true
	for i in range(off.size()):
		for j in range(i + 1, off.size()):
			if str(off[i].cities) == str(off[j].cities):
				distinct = false
	ok(distinct, "the offers hold different cities")
	# ---- 11. the vectors
	var vec: Dictionary = {}
	for sd in [7, 11]:
		var Pv: WorldPlanet.Planet = WorldPlanet.make(sd)
		var rv := SimRng.new(100 + sd)
		var rows: Array = []
		for i in range(64):
			var q5: Array
			if i < 48:
				q5 = pointOf(rv)
			else:
				var z4: float = (0.74 + 0.26 * rv.next()) * (1.0 if i % 2 == 0 else -1.0)
				var a4: float = rv.range_(0.0, 2.0 * PI)
				var qq: float = sqrt(1.0 - z4 * z4)
				q5 = [qq * SimDetMath.cos(a4), z4, qq * SimDetMath.sin(a4)]
			var sv: Array = WorldPlanet.surf(Pv, q5[0], q5[1], q5[2])
			rows.append(hexd(q5[0]) + hexd(q5[1]) + hexd(q5[2]) + "|" + hexd(sv[0]) + "|" + str(sv[1]))
		var picks: Array = []
		for t in range(8):
			var pk: Dictionary = WorldPlanet.pick(Pv, t)
			picks.append([t, pk.index, pk.tried, hexd(pk.T[0]) if pk.ok else ""])
		var ph: int = 0x811c9dc5
		for i in range(Pv.n):
			for x in [Pv.px[i], Pv.py[i], Pv.pz[i]]:
				for byte in PackedByteArray([0, 0, 0, 0, 0, 0, 0, 0]):
					pass
				var bb := PackedByteArray()
				bb.resize(8)
				bb.encode_double(0, x)
				for byte2 in bb:
					ph = SimRng.imul((ph ^ byte2) & 0xFFFFFFFF, 0x01000193)
		vec[str(sd)] = {"points": rows, "picks": picks, "places": Pv.n, "placesHash": "%08x" % (ph & 0xFFFFFFFF)}
	if write:
		var f := FileAccess.open(VECTORS, FileAccess.WRITE)
		f.store_string(JSON.stringify(vec, "  "))
		f.close()
		print("  wrote %s" % VECTORS)
	elif FileAccess.file_exists(VECTORS):
		var ref = JSON.parse_string(FileAccess.get_file_as_string(VECTORS))
		ok(JSON.stringify(ref) == JSON.stringify(JSON.parse_string(JSON.stringify(vec))), "the vectors file matches: 64 points on each of two planets (height bits, biome), 8 picks, the places' hash")
	else:
		ok(false, "planet_vectors.json is missing (run with -- --write)")
	print("PLANET: %d check(s) failed" % fails)
	quit()
