extends SceneTree
# Planet generation 2, window 7: what the EP's review found, as checks. A gen 2 match must not change a gen 1 match in the same process (the ring-slice memo's key, the statics a step restores), and a lake
# stands flat, is carried by a turn and is water to land in.
#   godot --headless --path . --script res://sim/world/tools/gen2_state_check.gd
var fails: int = 0


func ok(c: bool, w: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", w])
	if not c:
		fails += 1


func hx(v: float) -> String:
	var bb := PackedByteArray()
	bb.resize(8)
	bb.encode_double(0, v)
	return "%08x%08x" % [bb.decode_u32(4), bb.decode_u32(0)]


func mk(setup: Dictionary) -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {}, setup)
	return S


func hash_of(S: SimState) -> String:
	return str(SimHash.stateHash(S).gameplay)


func run_alone(setup: Dictionary, ticks: int) -> String:
	var S: SimState = mk(setup)
	for t in range(ticks):
		SimCore.step(S)
	return hash_of(S)


func _init() -> void:
	# --- 1: the ring memo's key carries the generation. A gen 1 match on an explicit ring, a gen 2 match on the same ring, the gen 1 match again.
	var probe: SimState = mk({"planet": 7, "touch": 0, "arena": {"cols": 2400}, "intro": false})
	var ring: Dictionary = {"cols": 2400, "c": [hx(probe.planetRing.c[0]), hx(probe.planetRing.c[1]), hx(probe.planetRing.c[2])], "t": [hx(probe.planetRing.t[0]), hx(probe.planetRing.t[1]), hx(probe.planetRing.t[2])]}
	WorldPlanet.forget()
	var g1: Dictionary = {"planet": 7, "arena": ring, "intro": false}
	var g2: Dictionary = {"planet": 7, "arena": ring, "planetGen": 2, "intro": false}
	var a0: String = run_alone(g1, 120)
	var b0: String = run_alone(g2, 120)
	var a1: String = run_alone(g1, 120)
	var b1: String = run_alone(g2, 120)
	ok(a0 == a1 and b0 == b1 and a0 != b0, "a gen 1 and a gen 2 match on the same explicit ring are told apart by the memo: gen 1 %s both times, gen 2 %s both times" % [a0.substr(0, 8), b0.substr(0, 8)])
	var S1: SimState = mk(g1)
	ok(WorldBiomes.fineCols.size() == 0 and S1.trees.size() == 0 and S1.fineCols.size() == 0 and S1.planetGen == 0, "a gen 1 match built after a gen 2 one has no fine columns, no trees, and the data's generation in its own state")

	# --- 2: two sims alive, stepped in turns, are each what they are alone
	var A: SimState = mk(g1)
	var B: SimState = mk(g2)
	for t in range(120):
		SimCore.step(A)
		SimCore.step(B)
	ok(hash_of(A) == a0 and hash_of(B) == b0, "two sims alive (gen 1 built first, gen 2 after), stepped in turns for 120 ticks, are each the match they are alone")
	var B2: SimState = mk(g2)
	var A2: SimState = mk(g1)
	for t in range(120):
		SimCore.step(B2)
		SimCore.step(A2)
	ok(hash_of(A2) == a0 and hash_of(B2) == b0, "the same with the gen 2 built first and the other order of stepping")
	var T1: SimState = mk({"planet": 7, "touch": 1, "arena": {"cols": 2400, "turn": true}, "planetGen": 2, "intro": false})
	var T0: SimState = mk({"planet": 7, "touch": 1, "arena": {"cols": 2400, "turn": true}, "intro": false})
	ok(T1.planetGen == 2 and T0.planetGen == 0 and T1.fineCols.size() == SimConst.NC and T0.fineCols.size() == 0, "each match keeps its own generation and fine columns in its state (gen %d and %d)" % [T1.planetGen, T0.planetGen])
	WorldClimate.useGen(0)

	# --- 3: lakes
	var L: SimState = null
	for touch in [1, 0, 2]:
		var Sx: SimState = mk({"planet": 7, "touch": touch, "arena": {"cols": 2400}, "planetGen": 2, "intro": false})
		if Sx.planetRing.get("lakes", []).size() > 0:
			L = Sx
			break
	ok(L != null, "a gen 2 ring with lakes is found; the match keeps them in S.planetRing")
	if L != null:
		var lakes: Array = L.planetRing.lakes
		var lk: Array = lakes[0]
		var best: Array = lk
		for q in lakes:
			if int(q[3]) > int(best[3]):
				best = q
		lk = best
		var NC: int = SimConst.NC
		var level: float = float(lk[2])
		var mid: int = (int(lk[0]) + int(lk[3]) / 2) % NC
		# a dug bed: the surface stays at the level, the depth grows by the dig
		var depth0: float = L.water[mid]
		L.deform[mid] = -80.0
		WorldWater.touched(L, mid, 3, L.base[mid] - 80.0)
		var flat: bool = true
		for k in range(int(lk[3])):
			var c: int = (int(lk[0]) + k) % NC
			if L.water[c] > 0.0 and absf(L.base[c] + WorldTerrain.lowD(L)[c] + L.water[c] - level) > 0.05:
				flat = false
		ok(flat and L.water[mid] > depth0 + 70.0, "a lake bed dug 80 deep keeps the lake's surface level (%.0f deep at the dig, was %.0f) and a berm does not raise it" % [L.water[mid], depth0])
		L.deform[mid] = 40.0
		WorldWater.touched(L, mid, 3, L.base[mid])
		ok(absf(L.base[mid] + WorldTerrain.lowD(L)[mid] + L.water[mid] - level) < 0.05 or L.water[mid] == 0.0, "a berm over the bed leaves the water at the level or dry")
		L.deform[mid] = 0.0
		WorldWater.touched(L, mid, 3, L.base[mid])
		# a body landing in a deep lake slams, as in the sea
		var deepc: int = -1
		for k in range(int(lk[3])):
			var c2: int = (int(lk[0]) + k) % NC
			if L.water[c2] >= WorldWater.HIDE_MIN_DEPTH + 20.0:
				deepc = c2
				break
		if deepc >= 0:
			var xb: float = (float(deepc) + 0.5) * SimConst.COL
			var jr: Dictionary = WorldContact.journey(L, WorldContact.launchBody(xb, L.base[deepc] + 6.0, 0.0, -3000.0, 1.0, 2.0, true))
			var first: String = String(jr.contacts[0].kind) if jr.contacts.size() > 0 else "-"
			ok(first == "slam", "a body landing on the bed of a deep lake (%.0f deep) slams, as in the sea (first contact: %s)" % [L.water[deepc], first])

	if L != null:
		# a deep lake is sea to seaAt (and so to every rule that asks), a shallow one and the dry bank are not; a lake gives no lock-on loss: line of sight is over the ground, water does not change it
		var deepSea: bool = false
		var shallowNot: bool = true
		for q in L.planetRing.lakes:
			for k in range(int(q[3])):
				var c6: int = (int(q[0]) + k) % SimConst.NC
				var xs6: float = (float(c6) + 0.5) * SimConst.COL
				if L.water[c6] >= WorldWater.HIDE_MIN_DEPTH:
					deepSea = true
					if not WorldTerrain.seaAt(L, xs6):
						deepSea = false
				elif WorldTerrain.seaAt(L, xs6):
					shallowNot = false
		ok(deepSea and shallowNot, "in a gen 2 match a lake column deep enough to hide in is sea to WorldTerrain.seaAt, a shallower one is not")
		var Sg: SimState = mk({"planet": 7, "touch": 1, "arena": {"cols": 2400}, "intro": false})
		var anySea: bool = false
		for i6 in range(SimConst.NC):
			if WorldTerrain.seaAt(Sg, (float(i6) + 0.5) * SimConst.COL) and Sg.base[i6] >= WorldWater.RESERVOIR_BASE:
				anySea = true
		ok(not anySea, "a gen 1 match has no sea but the reservoir's")
		# a fighter standing in a deep lake does not break the hunter's lock: line of sight ignores water
		var dcol: int = -1
		for q7 in L.planetRing.lakes:
			for k in range(int(q7[3])):
				var c7: int = (int(q7[0]) + k) % SimConst.NC
				if dcol < 0 and L.water[c7] >= WorldWater.HIDE_MIN_DEPTH:
					dcol = c7
		if dcol >= 0:
			var xt: float = (float(dcol) + 0.5) * SimConst.COL
			var tgt = L.fighters[1]
			var hun = L.fighters[0]
			tgt.x = xt
			tgt.y = WorldWater.surfaceAt(L, xt) - 80.0
			hun.x = xt - 600.0
			hun.y = WorldTerrain.groundY(L, hun.x) + 200.0
			tgt.canHide = false
			ok(SimHiding.lineOfSight(L, hun, tgt) or WorldTerrain.groundY(L, xt - 300.0) > hun.y + 40.0, "a fighter low in a deep lake is not out of sight because of the water (line of sight reads the ground only)")

	# --- the turn keeps the lakes of the kept core
	var T: SimState = mk({"planet": 7, "touch": 1, "arena": {"cols": 2400, "turn": true}, "planetGen": 2, "intro": false})
	var before: Array = T.planetRing.lakes.duplicate(true)
	var waterBefore: PackedFloat32Array = T.water.duplicate()
	for t in range(30):
		SimCore.step(T)
	T.T = 100.0
	var mid2: float = 0.5 * (T.fighters[0].x + T.fighters[1].x)
	if not WorldEpoch.ask(T, "t", mid2, 1, 0).is_empty():
		WorldEpoch.choose(T, 3)
		T.epoch.next.k = 100000
		var warm: int = 0
		while WorldEpoch.warmAngles(T).size() < T.epoch.warm.size() and warm < 100:
			WorldEpoch.tick(T, false)
			warm += 1
		WorldEpoch.tick(T, true)
	ok(int(T.epoch.n) == 1, "the gen 2 turn landed (epoch %d)" % int(T.epoch.n))
	var NC2: int = SimConst.NC
	var keptOk: bool = true
	var nKept: int = 0
	var carried: Array = T.planetRing.lakes
	for lk2 in before:
		var inCore: bool = true
		for k in range(int(lk2[3])):
			var c3: int = (int(lk2[0]) + k) % NC2
			var dx: float = absf(SimWrap.sdx(mid2, (float(c3) + 0.5) * SimConst.COL))
			if dx > 2500.0:
				inCore = false
		if inCore:
			nKept += 1
			var still: bool = false
			for q2 in carried:
				if int(q2[0]) == int(lk2[0]) and int(q2[3]) == int(lk2[3]) and absf(float(q2[2]) - float(lk2[2])) < 1.0e-6:
					still = true
			for k in range(int(lk2[3])):
				var c4: int = (int(lk2[0]) + k) % NC2
				if absf(T.water[c4] - waterBefore[c4]) > 1.0e-4:
					still = false
			if not still:
				keptOk = false
	ok(keptOk, "a lake in the kept core of a turn (%d of %d here) stands as it was: the same columns, level and water; the new ring's lakes are only on ground the new ring takes (%d lakes now)" % [nKept, before.size(), carried.size()])
	var intact: bool = true
	for lk3 in carried:
		for k in range(int(lk3[3])):
			var c5: int = (int(lk3[0]) + k) % NC2
			if T.water[c5] <= 0.0 and T.base[c5] < float(lk3[2]) - 1.0:
				intact = false
	ok(intact, "every carried or planted lake is wet over all of its columns after the swap")

	# --- the turn's preparation is spread: the largest step of the assembly, ticks to ready
	var T2: SimState = mk({"planet": 7, "touch": 1, "arena": {"cols": 2400, "turn": true}, "planetGen": 2, "intro": false})
	for t in range(30):
		SimCore.step(T2)
	T2.T = 100.0
	var mid3: float = 0.5 * (T2.fighters[0].x + T2.fighters[1].x)
	if not WorldEpoch.ask(T2, "t", mid3, 1, 0).is_empty():
		WorldEpoch.choose(T2, 3)
		T2.epoch.next.k = 100000
		var worst: int = 0
		var ticks: int = 0
		while WorldEpoch.warmAngles(T2).size() < T2.epoch.warm.size() and ticks < 200:
			var t0: int = Time.get_ticks_usec()
			WorldEpoch.tick(T2, false)
			worst = maxi(worst, Time.get_ticks_usec() - t0)
			ticks += 1
		print("  (a gen 2 turn's preparation: %d warm ticks, the dearest %.1f ms)" % [ticks, float(worst) / 1000.0])
	# --- a planet made in steps is the planet make makes (gen 1 by construction, gen 2 with its grid), and nothing is memoised before it is whole
	for g in [1, 2]:
		WorldClimate.useGen(g)
		WorldPlanet.forget()
		var Pm: WorldPlanet.Planet = WorldPlanet.make(11)
		WorldPlanet.forget()
		var job: WorldPlanet.PlanetJob = WorldPlanet.makeJob(11)
		var steps: int = 0
		var memoEarly: bool = false
		while not job.step(4000):
			steps += 1
			if WorldPlanet._planets.has(11 * 4 + g):
				memoEarly = true
		var same: bool = job.P.n == Pm.n and job.P.px == Pm.px and job.P.py == Pm.py and job.P.pz == Pm.pz and job.P.kind == Pm.kind and job.P.people == Pm.people
		if g == 2:
			same = same and job.P.grid != null and job.P.grid.adv == Pm.grid.adv
		ok(same and not memoEarly and WorldPlanet.make(11) == job.P, "gen %d: makeJob in %d steps of 4,000 units makes the planet make makes (%d places), memoised only when whole, and make then returns it" % [g, steps + 1, Pm.n])
	WorldClimate.useGen(0)
	print("STATE: %d check(s) failed" % fails)
	quit()
