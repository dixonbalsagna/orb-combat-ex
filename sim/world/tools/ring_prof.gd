extends SceneTree
# Where a gen 2 ring column's microseconds go (window 20): each stage of readColumns timed over a Half ring's columns in order (the noise's corner cache sees the same sequence a ring read gives it).
#   godot --headless --path . --script res://sim/world/tools/ring_prof.gd [-- --gen=2 --seed=7]
var P: WorldPlanet.Planet


func timed(label: String, f: Callable, n: int) -> float:
	var best: float = 1.0e18
	for rep in range(3):
		var t0: int = Time.get_ticks_usec()
		f.call()
		best = minf(best, float(Time.get_ticks_usec() - t0))
	print("  %-34s %7.1f us/col" % [label, best / float(n)])
	return best / float(n)


func _init() -> void:
	var gen: int = 2
	var seed: int = 7
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--gen="):
			gen = int(a.substr(6))
		if a.begins_with("--seed="):
			seed = int(a.substr(7))
	WorldClimate.useGen(gen)
	P = WorldPlanet.make(seed)
	var cols: int = 2400
	SimConst.setArena(cols)
	var T: Array = WorldPlanet.unitFromDraws(0.37 + 0.05 * float(seed % 7), 0.62)
	var spec: Dictionary = WorldRingPick.roundSpec(T, cols, 0.9)
	var ring: Dictionary = WorldRingPick.ringFrom(spec.c, cols, spec.t)
	if "--warm" in OS.get_cmdline_user_args():   # the first ring a real calm turn reads (a match's decided turn), not the bench's round ring
		var S := SimCore.createSim()
		SimCore.newMatch(S, 1, {}, {"planet": seed, "touch": 3, "arena": {"cols": 2400, "turn": true}, "planetGen": gen, "intro": false})
		for t in range(30):
			SimCore.step(S)
		S.T = 100.0
		var px: float = 0.5 * (S.fighters[0].x + S.fighters[1].x)
		var c: Array = WorldEpoch.ask(S, "prof", px, 1, 0)
		WorldEpoch.choose(S, c.size() - 1, 32, 2.5)
		var w = S.epoch.warm[0]
		ring = WorldRingPick.ringFrom(w.spec.c, int(w.spec.cols), w.spec.t)
		P = WorldPlanet.make(int(S.epoch.seed))
	var n: int = cols
	var qs := PackedFloat64Array()
	qs.resize(n * 3)
	var stf: float = ring.st
	var tc: int = WorldPlanet.touchCol()
	var t0: int = Time.get_ticks_usec()
	for i in range(n):
		var ang: float = float(i - tc) * SimConst.COL / (P.R * stf)
		var co: float = SimDetMath.cos(ang)
		var si: float = SimDetMath.sin(ang)
		qs[3 * i] = ring.c[0] * ring.ct + stf * (ring.u[0] * co + ring.v[0] * si)
		qs[3 * i + 1] = ring.c[1] * ring.ct + stf * (ring.u[1] * co + ring.v[1] * si)
		qs[3 * i + 2] = ring.c[2] * ring.ct + stf * (ring.u[2] * co + ring.v[2] * si)
	print("gen %d planet %d, a ring of %d columns" % [gen, seed, n])
	print("  %-34s %7.1f us/col" % ["trig and the point (one pass)", float(Time.get_ticks_usec() - t0) / float(n)])
	var fb := func() -> void:
		for i in range(n):
			WorldPlanet._fbm(P.R, qs[3 * i], qs[3 * i + 1], qs[3 * i + 2], 6000.0, 2, 77)
	timed("one fbm, 2 octaves (reference)", fb, n)
	var sw: float = timed("surfAt (ground + biome)", func() -> void:
		for i in range(n):
			WorldPlanet.surfAt(P, qs[3 * i], qs[3 * i + 1], qs[3 * i + 2]), n)
	timed("ground (continents, relief, landforms)", func() -> void:
		for i in range(n):
			WorldPlanet.ground(P, qs[3 * i], qs[3 * i + 1], qs[3 * i + 2]), n)
	var cgen: Dictionary = P.c
	timed("continent fbm only", func() -> void:
		for i in range(n):
			WorldPlanet._fbm(P.R, qs[3 * i], qs[3 * i + 1], qs[3 * i + 2], cgen.contScale, int(cgen.contOct), P.seed), n)
	if gen >= 2:
		timed("WorldLand.shape (landforms)", func() -> void:
			for i in range(n):
				WorldLand.shape(P, qs[3 * i], qs[3 * i + 1], qs[3 * i + 2], 800.0), n)
		timed("WorldLand._terms (plate pairs)", func() -> void:
			for i in range(n):
				WorldLand._terms(P, qs[3 * i], qs[3 * i + 1], qs[3 * i + 2]), n)
		timed("polarWob", func() -> void:
			for i in range(n):
				WorldLand.polarWob(P, qs[3 * i], qs[3 * i + 1], qs[3 * i + 2]), n)
		timed("climateAt (temperature, moisture)", func() -> void:
			for i in range(n):
				WorldClimate.climateAt(P, qs[3 * i], qs[3 * i + 1], qs[3 * i + 2], 400.0), n)
		timed("plain (the fine biome of ordinary land)", func() -> void:
			for i in range(n):
				WorldClimate.plain(P, qs[3 * i], qs[3 * i + 1], qs[3 * i + 2], 400.0), n)
	timed("detail fbm", func() -> void:
		for i in range(n):
			WorldPlanet._fbm(P.R, qs[3 * i], qs[3 * i + 1], qs[3 * i + 2], cgen.detailScale, int(cgen.detailOct), P.seed + int(cgen.sDetail)), n)
	var S: WorldPlanet.Slice = WorldPlanet.readBegin(P, ring, ring.u)
	timed("readColumns (the whole step)", func() -> void:
		WorldPlanet.readColumns(P, S, 0, n), n)
	var th: int = Time.get_ticks_usec()
	WorldPlanet.readHeld(P, S)
	print("  readHeld once (sites, blend): %.1f ms (%.1f us/col)" % [float(Time.get_ticks_usec() - th) / 1000.0, float(Time.get_ticks_usec() - th) / float(n)])
	quit()
