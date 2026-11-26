extends SceneTree
# The relief cap of the small planet sizes (World, GW1c; sim/world/size.gd reliefCap, reliefClamp, reliefKey, sim/world/planet.gd surfAt and the gen 2 fast path, sim/world/field.gd _read; data/biomes/sizes.json maxReliefShare,
# reliefKnee, reliefRef; docs/world/pending/relief-cap-gw1c). The relief is the same height at every size, so on tiny the tallest point was 1.03 of the planet's radius and small's 0.52. The keys ship OFF; this check
# turns them on in memory (0.3 and 0.6, 11,000) so it tests the code whether or not the data row has landed. Proves, on planet 7: no point the field holds and no column of a gen 2 or gen 3 ring on tiny or small is over the
# cap; the cap acts (without it they are); medium, big and huge are bit for bit; the squeeze is monotone, its own under the knee, never over the cap; the biomes are read from the height without the cap; the tops keep
# their taper; and the planet's data key (the saved planets, the replay's key) follows the cap's numbers and is exactly what it was where there is no cap.
#   godot --headless --path . --script res://sim/world/tools/relief_cap_check.gd -- [--negative-control]
var fails: int = 0
var negative: bool = false
var atCap: int = 0   # columns of the last ring match held at the cap itself (the clamp, not the squeeze: a plateau)


func ok(c: bool, w: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", w])
	if not c:
		fails += 1


func _points(n: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var out: Array = []
	for i in range(n):
		var x: float = rng.randfn()
		var y: float = rng.randfn()
		var z: float = rng.randfn()
		var l: float = sqrt(x * x + y * y + z * z)
		out.append([x / l, y / l, z / l])
	return out


func _setKeys(on: bool, knee: float = 0.7) -> void:
	var sz: Dictionary = WorldPlanetSize.data().sizes
	for nm in ["tiny", "small"]:
		if on:
			sz[nm]["maxReliefShare"] = 0.3
			sz[nm]["reliefKnee"] = knee
		else:
			sz[nm].erase("maxReliefShare")
			sz[nm].erase("reliefKnee")
	WorldPlanetSize.data()["reliefRef"] = 11000
	WorldPlanetSize.data()["reliefTop"] = 6739
	WorldPlanetSize.reloadRelief()


## The tallest column of a ring match at a size and a generation, over a few touch points (the ring crosses land of every height somewhere).
func _ringMax(nm: String, gen: int) -> float:
	var hi: float = -1.0e30
	atCap = 0
	var cap: float = WorldPlanetSize.reliefCapUnits()
	for touch in [1, 3, 5, 7, 9]:
		WorldClimate.useGen(gen)
		var S := SimCore.createSim()
		SimCore.newMatch(S, 4, {"p1": false, "p2": false}, {"intro": false, "planet": 7, "touch": touch, "planetGen": gen, "planetSize": nm})
		for i in range(S.base.size()):
			hi = maxf(hi, float(S.base[i]))
			if cap > 0.0 and float(S.base[i]) >= cap - 0.001:
				atCap += 1
		SimCore.dispose(S)
	WorldClimate.useGen(3)
	return hi


func _init() -> void:
	negative = OS.get_cmdline_user_args().has("--negative-control")
	WorldPlanetSize.heldOverride = true   # the check names tiny and small, which are held as shipped (the way in is the tests')
	ok(WorldPlanetSize.dataErrors().is_empty(), "sizes.json is clean as shipped (%s)" % str(WorldPlanetSize.dataErrors()))
	var shipped: bool = WorldPlanetSize.data().sizes.tiny.has("maxReliefShare")
	print("      the cap keys in the shipped data: %s (this check turns them on in memory)" % ("on" if shipped else "off"))
	_setKeys(true)
	WorldClimate.useGen(3)
	var pts: Array = _points(20000)
	var sizes: Dictionary = {"tiny": 1280, "small": 2560, "medium": 4800, "big": 9600, "huge": 19200}
	for nm in ["tiny", "small", "medium", "big", "huge"]:
		SimConst.setPlanet(int(sizes[nm]))
		WorldPlanetSize.setReliefOff(negative)
		WorldField.forget()
		WorldPlanet.forget()
		var P := WorldPlanet.make(7)
		var R: float = float(P.R)
		var cap: float = WorldPlanetSize.reliefCapUnits()
		var hi: float = -1.0e30
		var fhi: float = -1.0e30
		var capped: Array = []
		var bio: Array = []
		for p in pts:
			var sb: Array = WorldPlanet.surf(P, p[0], p[1], p[2])
			capped.append(float(sb[0]))
			bio.append(int(sb[1]))
			hi = maxf(hi, float(sb[0]))
		for i in range(0, pts.size(), 4):
			fhi = maxf(fhi, WorldField.height(P, pts[i][0], pts[i][1], pts[i][2]))
		WorldPlanetSize.setReliefOff(true)
		var hiOff: float = -1.0e30
		var same: bool = true
		var bioSame: bool = true
		for i in range(pts.size()):
			var p2: Array = pts[i]
			var sb2: Array = WorldPlanet.surf(P, p2[0], p2[1], p2[2])
			hiOff = maxf(hiOff, float(sb2[0]))
			if float(sb2[0]) != float(capped[i]):
				same = false
			if int(sb2[1]) != int(bio[i]):
				bioSame = false
		WorldPlanetSize.setReliefOff(false)
		if nm == "tiny" or nm == "small":
			ok(hi <= 0.3 * R + 0.01 and fhi <= 0.3 * R + 0.01, "%s: no point of 20,000 is over 0.3 of the radius, in the surface (tallest %.0f) or in the field with its detail (%.0f); the cap %.0f, R %.0f" % [nm, hi, fhi, 0.3 * R, R])
			ok(hiOff > 0.3 * R + 100.0, "%s: and the cap acts: without it the tallest is %.0f (%.2f R)" % [nm, hiOff, hiOff / R])
			# Art's ruling (docs/art/relief-cap-ruling.md, follow-up of 2026-11-22): the altitude lines are those of medium scaled by the planet's TALLEST CAPPED PEAK over 6,739 (the squeeze only approaches the cap, so a scale by the cap sat above every top)
			var peak: float = WorldPlanetSize.tallestCapped(P)
			var ls: float = WorldPlanetSize.linesScaleFor(P)
			ok(peak > 0.0 and peak <= cap and absf(ls * 6739.0 - peak) < 1.0e-6 and hi <= peak * 1.05 and hi >= peak * 0.95, "%s: the lines scale by the planet's tallest capped peak (%.0f, under the cap %.0f; the 20,000 sampled points reach %.0f) over 6,739: %.4f" % [nm, peak, cap, hi, ls])
			var mtn: float = float(P.c.mountainAbove)
			var hl: float = float(WorldClimate.data().highland.h)
			ok(hl * ls < mtn * ls and mtn * ls < peak and absf(mtn * ls / peak - mtn / 6739.0) < 1.0e-9 and absf(hl * ls / peak - hl / 6739.0) < 1.0e-9, "%s: the mountain line (%.0f) and the highland line (%.0f) are the same share of the peak as on medium of its tallest relief (%.3f and %.3f), and under it" % [nm, mtn * ls, hl * ls, mtn * ls / peak, hl * ls / peak])
			var mtop: int = 0
			var tops: Array = []
			for i in range(pts.size()):
				tops.append([float(capped[i]), i])
			tops.sort_custom(func(a, b): return a[0] < b[0])
			for k in range(100):
				var ti: int = int(tops[tops.size() - 1 - k][1])
				if int(bio[ti]) == WorldPlanet.BIO_MOUNTAINS:
					mtop += 1
			ok(mtop >= 90, "%s: the tallest ground reaches the mountain line: %d of the 100 tallest points are mountain biome" % [nm, mtop])
			# the temperature falls with the capped height at the scaled rate: a fall over the planet's tallest capped peak is the fall over medium's tallest relief, so the highest peak reaches the snow line where medium's does (Rendering's snow line is 0.997 of it)
			var q0: Array = pts[0]
			WorldClimate.climateAt(P, q0[0], q0[1], q0[2], 0.0)
			var T0: float = float(WorldClimate._cT)
			WorldClimate.climateAt(P, q0[0], q0[1], q0[2], peak)
			var dT: float = T0 - float(WorldClimate._cT)
			SimConst.setPlanet(SimConst.PLANET_NC_MEDIUM)
			var Pmed := WorldPlanet.make(7)
			WorldClimate.climateAt(Pmed, q0[0], q0[1], q0[2], 0.0)
			var Tm0: float = float(WorldClimate._cT)
			WorldClimate.climateAt(Pmed, q0[0], q0[1], q0[2], 6739.0)
			var dTm: float = Tm0 - float(WorldClimate._cT)
			SimConst.setPlanet(int(sizes[nm]))
			ok(absf(dT - dTm) < 1.0e-9 and dT > 0.0, "%s: the tallest capped peak is as cold as medium's tallest relief (a fall of %.4f against %.4f): the snow and the tree line reach the top" % [nm, dT, dTm])
			var order: Array = capped.duplicate()
			order.sort()
			var top: Array = order.slice(order.size() - 100)
			var distinct: Dictionary = {}
			for v in top:
				distinct[snappedf(float(v), 0.5)] = true
			ok(distinct.size() >= 50 and float(top[99]) - float(top[0]) >= 20.0, "%s: the 100 tallest points keep their taper (%d distinct heights to half a unit, %.0f from the lowest to the highest of them)" % [nm, distinct.size(), float(top[99]) - float(top[0])])
			# the columns of a ring match (gen 2's fast path and gen 3's field), the numbers the sim stands a fighter on
			var b0: bool = WorldLand.plateB()
			for kase in [[2, true], [2, false], [3, true]]:   # gen 2 with Research's B plates, gen 2 without them (the fast path of readColumns, which sets the height itself), gen 3 (the field)
				var gen: int = int(kase[0])
				WorldLand.setB(bool(kase[1]))
				WorldField.forget()
				WorldPlanet.forget()
				WorldPlanetSize.setReliefOff(negative)
				var colHi: float = _ringMax(nm, gen)
				var plateau: int = atCap
				WorldPlanetSize.setReliefOff(true)
				WorldField.forget()
				WorldPlanet.forget()
				var colOff: float = _ringMax(nm, gen)
				WorldPlanetSize.setReliefOff(false)
				ok(colHi <= 0.3 * R + 0.01 and colOff > colHi and plateau == 0, "%s: no column of a gen %d ring match%s is over the cap or held flat at it (tallest %.0f, %d at the cap; without the cap %.0f, so the row sees the difference)" % [nm, gen, "" if gen == 3 else (" with B plates" if bool(kase[1]) else " on the fast path (no B plates)"), colHi, plateau, colOff])
			WorldLand.setB(b0)
		else:
			ok(same and cap == 0.0, "%s: no cap, and the heights are bit for bit what they are without the code (all 20,000 equal)" % nm)
	# the controls of the biome rows: the old lines (the cap on, the lines of medium unscaled) put no mountain biome on the tallest ground of a small planet, and Art's first scale (by the cap over 6,739) leaves the highest peak warmer than medium's tallest relief (no snow at the top)
	var oldTop: Array = []
	var byCap: Array = []
	var sub: Array = pts.slice(0, 4000)
	for nm in ["tiny", "small"]:
		SimConst.setPlanet(int(sizes[nm]))
		WorldPlanetSize.setReliefOff(false)
		WorldPlanetSize.setLinesOff(true)
		var Po := WorldPlanet.make(7)
		var tp: Array = []
		for i in range(sub.size()):
			var sbo: Array = WorldPlanet.surf(Po, sub[i][0], sub[i][1], sub[i][2])
			tp.append([float(sbo[0]), int(sbo[1])])
		tp.sort_custom(func(a, b): return a[0] < b[0])
		var cm: int = 0
		for k in range(100):
			if int(tp[tp.size() - 1 - k][1]) == WorldPlanet.BIO_MOUNTAINS:
				cm += 1
		oldTop.append(cm)
		WorldPlanetSize.setLinesOff(false)
		WorldPlanetSize.setLinesByCap(true)
		var pk: float = WorldPlanetSize.tallestCapped(Po)
		var qc: Array = pts[0]
		WorldClimate.climateAt(Po, qc[0], qc[1], qc[2], 0.0)
		var Tc0: float = float(WorldClimate._cT)
		WorldClimate.climateAt(Po, qc[0], qc[1], qc[2], pk)
		byCap.append(Tc0 - float(WorldClimate._cT))
		WorldPlanetSize.setLinesByCap(false)
	SimConst.setPlanet(SimConst.PLANET_NC_MEDIUM)
	var Pm2 := WorldPlanet.make(7)
	WorldClimate.climateAt(Pm2, pts[0][0], pts[0][1], pts[0][2], 0.0)
	var Tz: float = float(WorldClimate._cT)
	WorldClimate.climateAt(Pm2, pts[0][0], pts[0][1], pts[0][2], 6739.0)
	var dTmed: float = Tz - float(WorldClimate._cT)
	ok(negative or int(oldTop[0]) < 10, "control (old lines): with the lines of medium unscaled, %d of the 100 tallest points of tiny are mountain biome (its tallest ground is under the unscaled line), so the mountain row can fail" % [oldTop[0]])
	ok(negative or (float(byCap[0]) < dTmed - 0.05 and float(byCap[1]) < dTmed - 0.05), "control (the first scale, by the cap): the highest peak is only %.3f colder than the sea level on tiny and %.3f on small, against %.3f for medium's tallest relief: no snow at the top, so the temperature row can fail" % [byCap[0], byCap[1], dTmed])
	# the squeeze itself, at tiny and small: monotone, its own under the knee, never over the cap
	for nm in ["tiny", "small"]:
		SimConst.setPlanet(int(sizes[nm]))
		WorldPlanetSize.setReliefOff(negative)
		var cap2: float = WorldPlanetSize.reliefCapUnits()
		var prev: float = -1.0e30
		var mono: bool = true
		var under: bool = true
		var over: bool = true
		var h: float = -500.0
		while h <= 12000.0:
			var v: float = WorldPlanetSize.reliefCap(h)
			if v < prev - 1.0e-9:
				mono = false
			prev = v
			if h <= 0.5 * (cap2 if cap2 > 0.0 else 1.0e9) and v != h:
				under = false
			if cap2 > 0.0 and v > cap2 + 1.0e-9:
				over = false
			h += 7.0
		ok(mono and under and over, "%s: the squeeze is monotone, its own under the knee, never over the cap (%.0f)" % [nm, cap2])
	# the data key: the planet data hash carries the cap's numbers (a saved planet, the replay's key), and is what it was where there is no cap
	SimConst.setPlanet(1280)
	WorldPlanetSize.setReliefOff(true)
	var hOff: String = WorldPlanet.dataHash(3)
	WorldPlanetSize.setReliefOff(negative)
	var hOn: String = WorldPlanet.dataHash(3)
	_setKeys(true, 0.6)
	WorldPlanetSize.setReliefOff(negative)
	var hKnee: String = WorldPlanet.dataHash(3)
	_setKeys(true)
	SimConst.setPlanet(SimConst.PLANET_NC_MEDIUM)
	WorldPlanetSize.setReliefOff(true)
	var mOff: String = WorldPlanet.dataHash(3)
	WorldPlanetSize.setReliefOff(negative)
	var mOn: String = WorldPlanet.dataHash(3)
	ok(hOn != hOff and hKnee != hOn and hKnee != hOff, "tiny: the planet data key follows the cap (off, knee 0.7 and knee 0.6 are three keys), so a saved planet is a miss when the numbers change")
	ok(mOn == mOff, "medium: the key is exactly what it was with the cap keys on in the data")
	_setKeys(shipped)
	SimConst.setPlanet(SimConst.PLANET_NC_MEDIUM)
	WorldPlanetSize.setReliefOff(false)
	WorldField.forget()
	WorldPlanet.forget()
	print("RELIEFCAP: %d check(s) failed%s" % [fails, " (negative control)" if negative else ""])
	quit(0 if fails == 0 else 1)
