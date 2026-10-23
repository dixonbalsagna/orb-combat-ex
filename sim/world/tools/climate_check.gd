extends SceneTree
# Planet generation 2, climate (docs/world/planet-gen2.md; WorldClimate; data/biomes/climate.json):  godot --headless --path . --script res://sim/world/tools/climate_check.gd
var fails: int = 0


func ok(c: bool, w: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", w])
	if not c:
		fails += 1


func ring(P: WorldPlanet.Planet, cols: int, a: float, b: float) -> Dictionary:
	SimConst.setArena(cols)
	var T: Array = WorldPlanet.unitFromDraws(a, b)
	var spec: Dictionary = WorldRingPick.roundSpec(T, cols, 0.9) if cols < 4800 else WorldRingPick.throughSpec(T, cols, 0.9)
	return WorldRingPick.ringFrom(spec.c, cols, spec.t)


func slicehash(seed: int, cols: int) -> Array:
	var P := WorldPlanet.make(seed)
	var r: Dictionary = ring(P, cols, 0.37 + 0.05 * float(seed % 7), 0.62)
	var sl: WorldPlanet.Slice = WorldPlanet.readSlice(P, r, r.u)
	return [WorldPlanet.sliceHash(sl), sl]


func _init() -> void:
	ok(WorldClimate.dataErrors().is_empty() and int(WorldClimate.data().gen) == 1, "climate.json is clean and the default generation is 1 (%s)" % str(WorldClimate.dataErrors()))
	WorldClimate.useGen(0)
	# --- generation 1 is what it was, to the bit: the slice hashes the stored planet gave before gen 2 existed
	var gold := {"7/1200": 2833587438, "7/2400": 713084292, "7/4800": 1796267095, "3/1200": 2973050903, "3/2400": 648931602, "3/4800": 111264617, "11/1200": 2603306661, "11/2400": 633813060, "11/4800": 2849232720, "25/1200": 1383108576, "25/2400": 2288383709, "25/4800": 1311726002}
	var same1: bool = true
	for k in gold:
		var sp: PackedStringArray = k.split("/")
		var h: Array = slicehash(int(sp[0]), int(sp[1]))
		if h[0] != gold[k] or h[1].fine.size() != 0:
			same1 = false
	ok(same1, "generation 1 reads the stored planet bit for bit: 12 slices (4 planets x 3 sizes) hash to what they did before gen 2, and carry no fine biomes")
	# --- generation 2 is a pure function of the seed and the data
	WorldClimate.useGen(2)
	var a1: Array = slicehash(7, 2400)
	WorldPlanet.forget()
	var a2: Array = slicehash(7, 2400)
	var b1: Array = slicehash(3, 2400)
	ok(a1[0] == a2[0] and a1[0] != b1[0] and a1[1].fine.size() == 2400 and a1[0] != 713084292, "a gen 2 slice is the same twice (a new planet object, a new grid), differs between seeds and from gen 1's, and carries a fine biome a column")
	var consistent: bool = true
	var nfine := {}
	for sd in [7, 3, 11, 25]:
		var h2: Array = slicehash(sd, 4800)
		var sl: WorldPlanet.Slice = h2[1]
		for i in range(4800):
			nfine[int(sl.fine[i])] = true
			if int(sl.fine[i]) >= WorldClimate.data().fine.size() or WorldClimate.aliasOf(int(sl.fine[i])) != int(sl.biomes[i]):
				consistent = false
	ok(consistent and nfine.size() >= 8, "every column's stored biome is its fine biome's alias, and 4 Whole rings show %d of the %d fine biomes" % [nfine.size(), WorldClimate.data().fine.size()])
	# --- the climate: temperature falls with latitude and height; a range casts a rain shadow; the coast is wetter than the interior
	var P7 := WorldPlanet.make(7)
	var tEq: Array = WorldClimate.climateAt(P7, 1.0, 0.0, 0.0, 100.0)
	var yy: float = 0.7
	var cc: float = sqrt(1.0 - yy * yy)
	var tMid: Array = WorldClimate.climateAt(P7, cc, yy, 0.0, 100.0)
	var tHigh: Array = WorldClimate.climateAt(P7, 1.0, 0.0, 0.0, 2500.0)
	ok(tEq[0] > tMid[0] + 0.15 and tEq[0] > tHigh[0] + 0.3, "temperature falls with latitude (equator %.2f, 44 degrees %.2f) and with height (%.2f at 2,500 units)" % [tEq[0], tMid[0], tHigh[0]])
	var lee: float = 0.0
	var wind: float = 0.0
	var nRidge: int = 0
	var coast: float = 0.0
	var inland: float = 0.0
	var nCoast: int = 0
	var nInland: int = 0
	for sd in [7, 3, 11, 25]:
		var G: WorldClimate.Grid = WorldClimate.gridOf(WorldPlanet.make(sd))
		for r in range(G.h):
			var y: float = -1.0 + (float(r) + 0.5) * 2.0 / float(G.h)
			if WorldClimate.westerly(y) > 0.8 and absf(y) < 0.8:
				for k in range(G.w):
					var h0: float = G.ht[r * G.w + (k - 1 + G.w) % G.w]
					var h1: float = G.ht[r * G.w + k]
					if h1 > 0.0 and h1 - maxf(h0, 0.0) > 700.0:   # a climb of the wind from the west
						var up: int = r * G.w + (k - 4 + G.w) % G.w
						var dn: int = r * G.w + (k + 4) % G.w
						if G.ht[up] > 0.0 and G.ht[dn] > 0.0:
							wind += G.adv[up]
							lee += G.adv[dn]
							nRidge += 1
			for k in range(G.w):
				var i: int = r * G.w + k
				if G.ht[i] > 0.0 and absf(y) < 0.7:
					var d: int = 99
					for q in range(1, 16):
						if G.ht[r * G.w + (k + q) % G.w] < 0.0 or G.ht[r * G.w + (k - q + G.w) % G.w] < 0.0:
							d = q
							break
					if d <= 2:
						coast += G.adv[i]
						nCoast += 1
					elif d >= 14:
						inland += G.adv[i]
						nInland += 1
	var ws: float = wind / float(maxi(nRidge, 1))
	var ls: float = lee / float(maxi(nRidge, 1))
	ok(nRidge >= 15 and ls < ws - 0.03, "a range casts a rain shadow: over %d climbs of the westerlies the carried moisture 4 cells downwind (%.2f) is below the windward side's (%.2f)" % [nRidge, ls, ws])
	var cs: float = coast / float(maxi(nCoast, 1))
	var ins: float = inland / float(maxi(nInland, 1))
	ok(nCoast >= 100 and nInland >= 30 and cs > ins + 0.1, "the coast is wetter than the interior: moisture within 2 cells of the sea %.2f (%d cells), 14 or more cells inland %.2f (%d cells)" % [cs, nCoast, ins, nInland])
	# --- what a surfAt costs against generation 1's (the same points)
	var pts: Array = []
	var rng := SimRng.new(5)
	for t in range(6000):
		pts.append(WorldPlanet.unitFromDraws(rng.next(), rng.next()))
	WorldClimate.useGen(1)
	var P1 := WorldPlanet.make(7)
	var t0: int = Time.get_ticks_usec()
	for q in pts:
		WorldPlanet.surfAt(P1, q[0], q[1], q[2])
	var us1: float = float(Time.get_ticks_usec() - t0) / 6000.0
	WorldClimate.useGen(2)
	var P2 := WorldPlanet.make(7)
	WorldClimate.gridOf(P2)
	t0 = Time.get_ticks_usec()
	for q in pts:
		WorldPlanet.surfAt(P2, q[0], q[1], q[2])
	var us2: float = float(Time.get_ticks_usec() - t0) / 6000.0
	ok(us2 < us1 * 2.5, "surfAt on random points costs %.1f us in gen 2 against %.1f in gen 1 (%.2f times; the climate grid is made once a planet)" % [us2, us1, us2 / maxf(us1, 0.001)])
	# heights are the stored planet's in window 1, so the places are too
	WorldClimate.useGen(1)
	var Pa := WorldPlanet.make(7)
	var na: int = Pa.n
	var xa: float = Pa.px[3]
	WorldClimate.useGen(2)
	var Pb := WorldPlanet.make(7)
	ok(Pb.n == na and Pb.px[3] == xa and Pb.gen == 2 and Pa.gen == 1, "the same seed makes the same places in either generation (window 1 changes the biomes, not the land), and a planet knows its generation")
	WorldClimate.useGen(0)
	print("CLIMATE: %d check(s) failed" % fails)
	quit()
