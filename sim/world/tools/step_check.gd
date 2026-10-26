extends SceneTree
# The planet's load in steps (window 20 add-on, docs/world/gen2-readiness.md): the climate grid and its carry, the flow field, the places' tries and a touch-down's ring read a slice at a time are the
# whole ones, bit for bit; no call is a whole piece; the memos evict the oldest.
#   godot --headless --path . --script res://sim/world/tools/step_check.gd
var fails: int = 0


func ok(c: bool, w: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", w])
	if not c:
		fails += 1


func samePlanet(A: WorldPlanet.Planet, B: WorldPlanet.Planet) -> bool:
	if A.n != B.n or A.kind != B.kind or A.px != B.px or A.py != B.py or A.pz != B.pz or A.rad != B.rad or A.people != B.people:
		return false
	if A.gen >= 2:
		if A.grid.adv != B.grid.adv or A.grid.ht != B.grid.ht:
			return false
		if (A.flow == null) != (B.flow == null):
			return false
		if A.flow != null and (A.flow.recv != B.flow.recv or A.flow.flow != B.flow.flow or A.flow.order != B.flow.order):
			return false
	return true


## Runs a job at a budget a call; returns [calls, longest call ms, longest call while ...] and leaves the planet memoised.
func run(seed: int, budget: int) -> Array:
	WorldPlanet.forget()
	var job: WorldPlanet.PlanetJob = WorldPlanet.makeJob(seed)
	var calls: int = 0
	var worst: float = 0.0
	while not job.done and calls < 1000000:
		var t0: int = Time.get_ticks_usec()
		job.step(budget)
		worst = maxf(worst, float(Time.get_ticks_usec() - t0) / 1000.0)
		calls += 1
	return [calls, worst, job.P]


func _init() -> void:
	WorldClimate.useGen(2)
	for rivers in [false, true]:
		WorldRivers.setOn(rivers)
		WorldPlanet.forget()
		var ref: WorldPlanet.Planet = WorldPlanet.make(13)
		if rivers:
			WorldRivers.flowOf(ref)
		var line: String = ""
		var allSame: bool = true
		var worst250: float = 0.0
		for budget in [250, 37, 1 << 40]:
			var r: Array = run(13, budget)
			var P: WorldPlanet.Planet = r[2]
			if rivers and P.flow == null:
				allSame = false
			if not samePlanet(ref, P):
				allSame = false
			line += " %s (%d calls, longest %.1f ms)" % ["whole" if budget > 100000 else str(budget), r[0], r[1]]
			if budget == 250:
				worst250 = r[1]
		ok(allSame, "a gen 2 planet%s made by the job at a budget of 250, 37 and the whole is the one make gives, bit for bit:%s" % [" with rivers" if rivers else "", line])
		ok(worst250 < 25.0, "at the read's budget (250 units, about 5 ms) no call of the job is long: the longest %.1f ms (the grid's carry, the flow field and a try-set were 17 to 140 ms in one call)" % worst250)
	WorldRivers.setOn(false)
	WorldClimate.useGen(1)
	var ref1: WorldPlanet.Planet = WorldPlanet.make(13)
	var r1: Array = run(13, 40)
	ok(samePlanet(ref1, r1[2]), "a gen 1 planet made by the job at a budget of 40 is make's (%d calls)" % r1[0])
	# a touch-down's ring in steps
	WorldClimate.useGen(2)
	SimConst.setArena(2400)
	for touch in [1, 2, 3]:
		WorldPlanet.forget()
		WorldPlanet.make(13)
		var whole: WorldPlanet.Slice = WorldPlanet.sliceFor(13, touch)
		WorldPlanet.forget()
		WorldPlanet.make(13)
		var job := WorldPlanet.SliceJob.new(13, touch)
		var calls: int = 0
		var worst: float = 0.0
		while not job.done and calls < 100000:
			var t0: int = Time.get_ticks_usec()
			job.step(250)
			worst = maxf(worst, float(Time.get_ticks_usec() - t0) / 1000.0)
			calls += 1
		var same: bool = (whole == null and job.slice == null) or (whole != null and job.slice != null and whole.heights == job.slice.heights and whole.biomes == job.slice.biomes and whole.fine == job.slice.fine and str(whole.held) == str(job.slice.held) and WorldPlanet.sliceHash(whole) == WorldPlanet.sliceHash(job.slice))
		var memo: bool = whole == null or WorldPlanet.sliceFor(13, touch) == job.slice
		ok(same and memo, "touch %d: the ring read in steps of 250 units (%d calls, the longest %.1f ms) is sliceFor's slice, bit for bit, and sliceFor then returns it from the memo" % [touch, calls, worst])
	WorldClimate.useGen(1)
	# the host's load (Simulation's SimPlanetLoad) over World's stepped job and SliceJob: a touch-down's match after the load is the cold one
	var setup: Dictionary = {"planet": 13, "touch": 2, "arena": {"cols": 2400}, "planetGen": 2, "intro": false}
	WorldPlanet.forget()
	WorldClimate.useGen(2)
	var cold := SimCore.createSim()
	SimCore.newMatch(cold, 1, {}, setup)
	for t in range(20):
		SimCore.step(cold)
	var hCold: String = str(SimHash.stateHash(cold).gameplay)
	WorldPlanet.forget()
	var ld: SimPlanetLoad.Job = SimPlanetLoad.beginFor(setup)
	var frames: int = 0
	var worstLoad: float = 0.0
	while not ld.done and frames < 100000:
		var t0: int = Time.get_ticks_usec()
		ld.step(SimRun.planetUnitsPerRead)
		worstLoad = maxf(worstLoad, float(Time.get_ticks_usec() - t0) / 1000.0)
		frames += 1
	var t1: int = Time.get_ticks_usec()
	var warm := SimCore.createSim()
	SimCore.newMatch(warm, 1, {}, setup)
	var startMs: float = float(Time.get_ticks_usec() - t1) / 1000.0
	for t in range(20):
		SimCore.step(warm)
	ok(ld.done and str(SimHash.stateHash(warm).gameplay) == hCold, "a touch-down's match started after the host's load (%d frames at the read's budget, the longest %.1f ms) is the cold one, bit for bit; its start then takes %.0f ms" % [frames, worstLoad, startMs])
	WorldClimate.useGen(1)
	# Research's B plates in steps (window 20, second add-on): the plates made a slice at a time are the whole make's, and a planet job with B on goes in steps
	WorldClimate.useGen(2)
	WorldLand.setB(true)
	WorldPlanet.forget()
	var Pw := WorldPlanet._newPlanet(13, 2)
	var Sw: WorldPlateB.State = WorldPlateB.stateOf(Pw)
	var Ps := WorldPlanet._newPlanet(13, 2)
	var bCalls: int = 0
	var bWorst: float = 0.0
	while bCalls < 100000:
		var tb: int = Time.get_ticks_usec()
		var bdone: bool = WorldPlateB.step(Ps, 250)
		bWorst = maxf(bWorst, float(Time.get_ticks_usec() - tb) / 1000.0)
		bCalls += 1
		if bdone:
			break
	var Ss: WorldPlateB.State = Ps.platesB
	ok(Ss != null and Ss.cf == Sw.cf and Ss.bf == Sw.bf and Ss.plate == Sw.plate and Ss.lift == Sw.lift and Ss.hot == Sw.hot and Ss.hotB == Sw.hotB and Ss.pe == Sw.pe, "the B plates made at 250 units a call (%d calls, the longest %.1f ms; it was one call of 46 ms) are the whole make's, bit for bit" % [bCalls, bWorst])
	WorldPlanet.forget()
	var refB: WorldPlanet.Planet = WorldPlanet.make(13)
	var rb: Array = run(13, 250)
	ok(samePlanet(refB, rb[2]) and rb[1] < 25.0, "a gen 2 planet with the B plates on made by the job at 250 units is the one make gives, bit for bit (%d calls, the longest %.1f ms)" % [rb[0], rb[1]])
	WorldLand.setB(false)
	WorldClimate.useGen(1)
	# the memos evict the oldest
	WorldPlanet.forget()
	for sd in range(1, 9):
		WorldPlanet.make(sd)
	var have: Array = []
	for sd in range(1, 9):
		have.append(WorldPlanet.isMade(sd))
	ok(not have[0] and have.slice(1).all(func(x): return x) and WorldPlanet._planets.size() == 7, "an eighth planet evicts the oldest only: seed 1 is gone, seeds 2 to 8 stay (%d kept)" % WorldPlanet._planets.size())
	WorldPlanet.forget()
	print("STEP: %d check(s) failed" % fails)
	quit()
