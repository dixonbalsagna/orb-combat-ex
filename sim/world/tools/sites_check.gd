extends SceneTree
# Planet generation 2, window 4: placement by climate and coast, and the ragged biome borders (WorldSites, data/biomes/sites.json).
#   godot --headless --path . --script res://sim/world/tools/sites_check.gd
var fails: int = 0


func ok(c: bool, w: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", w])
	if not c:
		fails += 1


func fineAt(P: WorldPlanet.Planet, i: int) -> int:
	WorldPlanet.surfAt(P, P.px[i], P.py[i], P.pz[i])
	return P.outF if P.outF >= 0 else P.outB


func changes(a: PackedByteArray) -> int:
	var c: int = 0
	for i in range(a.size()):
		if a[i] != a[(i + 1) % a.size()]:
			c += 1
	return c


func _init() -> void:
	ok(WorldSites.dataErrors().is_empty() and int(WorldClimate.data().gen) == 1, "sites.json is clean (%s) and the data's generation is still 1" % str(WorldSites.dataErrors()))
	var seeds: Array = [7, 3, 11, 25, 42, 101]
	var bad: Array = []
	var total: int = 0
	var cities: int = 0
	var citiesHarbour2: int = 0
	var citiesHarbour1: int = 0
	var cities1: int = 0
	var avoid2: int = 0
	var avoid1: int = 0
	var places1: int = 0
	var minCities: int = 99
	var minPlaces: int = 99
	var names: Array = []
	for g in WorldClimate.data().fine:
		names.append(String(g.name))
	var avoidSet: Array = [WorldClimate.F_DESERT, WorldClimate.F_JUNGLE, WorldClimate.F_TUNDRA, WorldClimate.F_WETLAND, WorldClimate.F_HIGHLAND]
	var t2: int = 0
	var t1: int = 0
	for sd in seeds:
		WorldPlanet.forget()
		WorldClimate.useGen(1)
		var t0: int = Time.get_ticks_usec()
		var P1 := WorldPlanet.make(sd)
		t1 += Time.get_ticks_usec() - t0
		WorldClimate.useGen(2)
		t0 = Time.get_ticks_usec()
		var P2 := WorldPlanet.make(sd)
		t2 += Time.get_ticks_usec() - t0
		var nc: int = 0
		for i in range(P2.n):
			total += 1
			var f: int = fineAt(P2, i)
			if f in [WorldClimate.F_OCEAN, WorldClimate.F_ICE_SHEET, WorldClimate.F_SEA_ICE, WorldClimate.F_VOLCANIC, WorldClimate.F_MOUNTAINS] or P2.outH < 0.0:
				bad.append("%d/%d %s" % [sd, i, names[f]])
			if f in avoidSet:
				avoid2 += 1
			if int(P2.kind[i]) == WorldPlanet.KIND_CITY:
				nc += 1
				cities += 1
				var n2: int = WorldSites.seaDirs(P2, P2.px[i], P2.py[i], P2.pz[i], WorldSites.K_REACH[0])
				if n2 >= WorldSites.K_LOW and n2 <= WorldSites.K_HIGH:
					citiesHarbour2 += 1
		minCities = mini(minCities, nc)
		minPlaces = mini(minPlaces, P2.n)
		WorldClimate.useGen(1)
		for i in range(P1.n):
			places1 += 1
			if int(P1.kind[i]) == WorldPlanet.KIND_CITY:
				cities1 += 1
				var n1: int = WorldSites.seaDirs(P1, P1.px[i], P1.py[i], P1.pz[i], WorldSites.K_REACH[0])
				if n1 >= WorldSites.K_LOW and n1 <= WorldSites.K_HIGH:
					citiesHarbour1 += 1
	WorldClimate.useGen(2)
	ok(bad.is_empty() and minCities >= 2 and minPlaces >= 20, "%d places on 6 planets: none in the sea, on ice, on volcanic ground or on a range %s; at least %d cities and %d places a planet" % [total, str(bad.slice(0, 4)), minCities, minPlaces])
	var hs2: float = float(citiesHarbour2) / float(maxi(cities, 1))
	var hs1: float = float(citiesHarbour1) / float(maxi(cities1, 1))
	ok(hs2 > hs1 + 0.15 and hs2 > 0.5, "%.0f%% of gen 2's cities (%d) have a harbour (some sea within %d units, not an islet) against %.0f%% in gen 1 (%d)" % [hs2 * 100.0, cities, int(WorldSites.K_REACH[0]), hs1 * 100.0, cities1])
	ok(float(avoid2) / float(maxi(total, 1)) < 0.2, "%.0f%% of gen 2's places stand on desert, jungle, tundra, wetland or highland (the biomes the weights mark down)" % (100.0 * float(avoid2) / float(maxi(total, 1))))
	print("  (planet set-up, 6 planets: %.0f ms in gen 1, %.0f ms in gen 2 a planet, the climate grid and the sites' scoring included)" % [float(t1) / 6000.0, float(t2) / 6000.0])

	# --- the borders
	WorldClimate.useGen(2)
	var P := WorldPlanet.make(7)
	SimConst.setArena(SimConst.PLANET_NC)
	var found: int = 0
	var blendOk: bool = true
	var aliasOk: bool = true
	var chB: int = 0
	var chU: int = 0
	var shareDrift: float = 0.0
	var pureOk: bool = true
	var msBlend: float = 0.0
	var nring: int = 0
	for sd in [7, 3, 11, 25]:
		var Pp := WorldPlanet.make(sd)
		for tk in [0, 1, 2]:
			var r: Dictionary = WorldPlanet.pick(Pp, tk)
			if not r.ok:
				continue
			found += 1
			var ring: Dictionary = WorldPlanet.ringThrough(r.circle, SimConst.NC, 1)
			var Su: WorldPlanet.Slice = WorldPlanet.readBegin(Pp, ring, r.T)
			WorldPlanet.readColumns(Pp, Su, 0, SimConst.NC)   # the read before the borders are blended
			var Sb: WorldPlanet.Slice = WorldPlanet.readBegin(Pp, ring, r.T)
			WorldPlanet.readColumns(Pp, Sb, 0, SimConst.NC)
			var t0: int = Time.get_ticks_usec()
			WorldSites.blend(Pp, Sb)
			msBlend += float(Time.get_ticks_usec() - t0) / 1000.0
			nring += 1
			var again: WorldPlanet.Slice = WorldPlanet.readBegin(Pp, ring, r.T)
			WorldPlanet.readColumns(Pp, again, 0, SimConst.NC)
			WorldSites.blend(Pp, again)
			if again.fine != Sb.fine or again.biomes != Sb.biomes:
				pureOk = false
			for i in range(SimConst.NC):
				if int(Sb.biomes[i]) != WorldClimate.aliasOf(int(Sb.fine[i])):
					aliasOk = false
			chU += changes(Su.fine)
			chB += changes(Sb.fine)
			var cu := PackedInt32Array()
			cu.resize(15)
			var cb := PackedInt32Array()
			cb.resize(15)
			for i in range(SimConst.NC):
				cu[Su.fine[i]] += 1
				cb[Sb.fine[i]] += 1
			for k in range(15):
				shareDrift = maxf(shareDrift, absf(float(cb[k] - cu[k])) / float(SimConst.NC))
			var viaSlice: WorldPlanet.Slice = WorldPlanet.readSlice(Pp, ring, r.T)   # readSlice blends as part of the read
			if viaSlice.fine != Sb.fine or viaSlice.biomes != Sb.biomes:
				blendOk = false
	ok(found >= 8 and blendOk, "the blend is part of every read: readSlice's fine biomes are the blended ones (%d rings of 4 planets)" % found)
	ok(pureOk and aliasOk, "the blend is a pure function of the ring and the stored biomes follow the fine ones by alias")
	ok(chB > chU * 1.2, "borders are ragged: %d biome changes along %d rings against %d unblended (%.2fx)" % [chB, found, chU, float(chB) / float(maxi(chU, 1))])
	ok(shareDrift < 0.06, "the blend moves no biome's share of a ring by more than %.1f%% (the largest move)" % (shareDrift * 100.0))
	print("  (the blend: %.2f ms a ring of 4,800 columns)" % (msBlend / float(maxi(nring, 1))))
	# --- a pick still finds rings
	var picked: int = 0
	var tried: int = 0
	for sd in [7, 3, 11, 25]:
		var Pq := WorldPlanet.make(sd)
		for tk in [0, 1, 2, 3]:
			tried += 1
			if WorldPlanet.pick(Pq, tk).ok:
				picked += 1
	ok(picked * 4 >= tried * 3, "the ring picker finds a ring on %d of %d tries in gen 2" % [picked, tried])
	WorldClimate.useGen(0)
	print("SITES: %d check(s) failed" % fails)
	quit()
