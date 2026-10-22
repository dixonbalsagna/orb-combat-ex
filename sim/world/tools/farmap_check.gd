extends SceneTree
# WorldPlanet.farField and WorldFarMap (render-only far reads): godot --headless --path . --script res://sim/world/tools/farmap_check.gd
var fails: int = 0


func ok(c: bool, w: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", w])
	if not c:
		fails += 1


func ring_of(P: WorldPlanet.Planet, cols: int, a: float, b: float) -> Dictionary:
	SimConst.setArena(cols)
	var T: Array = WorldPlanet.unitFromDraws(a, b)
	var spec: Dictionary = WorldRingPick.roundSpec(T, cols, 0.9) if cols < 4800 else WorldRingPick.throughSpec(T, cols, 0.9)
	return WorldRingPick.ringFrom(spec.c, cols, spec.t)


func _init() -> void:
	# the noise's hash written out is the hash: _fm against SimRng.imul's own composition
	var rng := SimRng.new(99)
	var fmOk: bool = true
	for t in range(60000):
		var v: int = int(rng.next() * 4294967296.0) ^ (int(rng.next() * 1048576.0) << 32)
		var x: int = v & 0xFFFFFFFF
		x ^= x >> 16
		x = SimRng.imul(x, 0x85ebca6b)
		x ^= x >> 13
		x = SimRng.imul(x, 0xc2b2ae35)
		x ^= x >> 16
		if WorldPlanet._fm(v) != (x & 0xFFFFFFFF):
			fmOk = false
	ok(fmOk, "_fm (SimRng.imul written out) is the hash it was: 60,000 random inputs, bit for bit")
	var depths := PackedFloat64Array([-40000.0, -9000.0, -2000.0, 0.0, 700.0, 3000.0, 15000.0, 40000.0])
	var allSame: bool = true
	var allCoarseBiome: float = 0.0
	var coarseN: int = 0
	var worst: float = 0.0
	var mapsDone: Array = []
	var mapMean: Array = []
	var mapBiome: Array = []
	var mapBig: Array = []
	for pl in [7, 3, 25]:
		var P := WorldPlanet.make(pl)
		for cols in [4800, 2400, 1200]:
			var ring: Dictionary = ring_of(P, cols, 0.37 + 0.05 * float(pl % 7), 0.62)
			var c0: int = 137
			var nc: int = 120
			var stride: int = maxi(1, cols / 120)
			var ex: Dictionary = WorldPlanet.farField(P, ring, c0, nc, stride, depths)
			for di in range(depths.size()):
				for ci in range(nc):
					var r: Array = WorldPlanet.farColumn(P, ring, c0 + ci * stride, depths[di])
					if r[0] != ex.h[di * nc + ci] or r[1] != ex.b[di * nc + ci]:
						allSame = false
			# the coarse read changes the height and the odd biome, nothing else (no NaN, same shape)
			var co: Dictionary = WorldPlanet.farField(P, ring, c0, nc, stride, depths, 1500.0)
			if co.h.size() != ex.h.size() or WorldPlanet._octOff != 0:
				allSame = false
			for di in range(depths.size()):
				for ci in range(nc):
					var i: int = di * nc + ci
					if absf(depths[di]) <= 1500.0 and (co.h[i] != ex.h[i] or co.b[i] != ex.b[i]):
						allSame = false   # inside the limit the coarse read is the exact one
					if absf(depths[di]) > 1500.0:
						worst = maxf(worst, absf(co.h[i] - ex.h[i]))
						coarseN += 1
						if co.b[i] != ex.b[i]:
							allCoarseBiome += 1.0
			if cols == 2400 or pl != 7:
				var fm := WorldFarMap.new(P)
				var steps: int = 0
				while not fm.step(7000):
					steps += 1
				var mf: Dictionary = fm.field(ring, c0, nc, stride, depths)
				var sm: float = 0.0
				var bd: int = 0
				var big: int = 0
				for i in range(ex.h.size()):
					var d: float = absf(mf.h[i] - ex.h[i])
					sm += d
					if d > 100.0:
						big += 1
					if mf.b[i] != ex.b[i]:
						bd += 1
				mapMean.append(sm / float(ex.h.size()))
				mapBiome.append(float(bd) / float(ex.h.size()))
				mapBig.append(float(big) / float(ex.h.size()))
				mapsDone.append("%d/%d" % [pl, cols])
	ok(allSame, "farField is farColumn bit for bit (heights and biomes) on 3 planets x 3 ring sizes x 8 depths including z = 0; the coarse read inside its limit is the exact read, and it leaves no octave dropped behind (%d)" % WorldPlanet._octOff)
	ok(coarseN > 0 and allCoarseBiome / float(coarseN) < 0.25 and worst < 2500.0, "the coarse read past its limit is a rougher height (at most %.0f units off) with %.1f%% of its biomes moved" % [worst, 100.0 * allCoarseBiome / float(maxi(coarseN, 1))])
	var mm: float = 0.0
	var bb: float = 0.0
	var gg: float = 0.0
	for k in range(mapMean.size()):
		mm = maxf(mm, mapMean[k])
		bb = maxf(bb, mapBiome[k])
		gg = maxf(gg, mapBig[k])
	ok(mm < 30.0 and bb < 0.04 and gg < 0.04, "the map's far field against the exact read over %d rings (%s): worst mean |dh| %.1f units, worst share of heights over 100 units off %.1f%%, worst share of biomes different %.1f%%" % [mapsDone.size(), ", ".join(PackedStringArray(mapsDone)), mm, 100.0 * gg, 100.0 * bb])
	# the octahedral map: decode and encode are inverses (both hemispheres), and the same map twice is the same map
	var P2 := WorldPlanet.make(7)
	var fm1 := WorldFarMap.new(P2, 64)
	var inv: bool = true
	for t in range(2000):
		var u: float = rng.next()
		var v: float = rng.next()
		var d: Array = WorldFarMap.decode(u, v)
		var uv: Vector2 = fm1._uv(d[0], d[1], d[2])
		if absf((uv.x + 0.5) / 64.0 - u) > 1e-6 or absf((uv.y + 0.5) / 64.0 - v) > 1e-6:
			inv = false
	ok(inv, "the octahedral decode and encode are inverses (2,000 points over both hemispheres)")
	fm1.step(100000)
	var fm2 := WorldFarMap.new(P2, 64)
	fm2.step(100000)
	ok(fm1.done and fm1.hs == fm2.hs and fm1.bs == fm2.bs, "the same planet and size give the same map")
	var cont: float = 0.0
	for t in range(3000):   # a point and one a texel's tenth away read the same to within a smooth slope (no seam, no pole)
		var d: Array = WorldFarMap.decode(rng.next(), rng.next())
		var e: Array = [d[0] + 0.001, d[1] - 0.001, d[2] + 0.0005]
		var l: float = sqrt(e[0] * e[0] + e[1] * e[1] + e[2] * e[2])
		cont = maxf(cont, absf(fm1.height(d[0], d[1], d[2]) - fm1.height(e[0] / l, e[1] / l, e[2] / l)))
	ok(cont < 700.0, "the lookup is continuous over the whole sphere, fold and edge included: the largest step over 3,000 pairs 0.0016 radians apart is %.0f units" % cont)
	print("FARMAP: %d check(s) failed" % fails)
	quit()
