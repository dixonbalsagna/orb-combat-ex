extends SceneTree
# A gen 3 planet's load in steps (World, sim/world/field.gd, sim/core/planet_load.gd): the bake is a phase of the host's load, the match starts only when it is whole, and the stepped load is the planet the whole one makes.
#   godot --headless --path . --script res://sim/world/tools/field_load_check.gd -- [--planet=4246]
var fails: int = 0


func ok(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		fails += 1
		print("  FAIL ", what)


func _init() -> void:
	var planet: int = 4246
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--planet="):
			planet = int(a.substr(9))
	WorldFieldCache.dirOverride = "user://field-cache-load-check/"   # a folder of its own, emptied first: the first load below is cold, the last reads the cache
	WorldFieldCache.enabledOverride = 1
	DirAccess.make_dir_recursive_absolute(WorldFieldCache.dir())
	for fn in DirAccess.get_files_at(WorldFieldCache.dir()):
		if fn.ends_with(".wfc"):
			DirAccess.remove_absolute(WorldFieldCache.dir() + fn)
	WorldPlanet.forget()
	var setup := {"intro": false, "planet": planet, "planetGen": 3, "arena": {"cols": 2400}}
	ok(not SimPlanetLoad.mayStart(setup), "a cold gen 3 planet may not start a match")
	var was_strict: bool = SimPlanetLoad.strict
	SimPlanetLoad.strict = true
	var refused0: int = SimPlanetLoad.refused
	var S0 := SimCore.createSim()
	SimCore.newMatch(S0, 1, {}, setup)
	ok(SimPlanetLoad.refused == refused0 + 1, "strict: the sim refuses to make the planet cold")
	var job: SimPlanetLoad.Job = SimPlanetLoad.beginFor(setup)
	ok(job != null and job.gen == 3, "a load of a gen 3 setup is a gen 3 load")
	var steps: int = 0
	var last: float = -1.0
	var mono: bool = true
	var phases: Dictionary = {}
	var worst_us: int = 0
	var units: int = 250
	while not job.step(units):
		steps += 1
		var p: float = job.progress()
		if p < last - 1.0e-9:
			mono = false
		last = p
		phases[job.phase] = int(phases.get(job.phase, 0)) + 1
		if steps > 20000:
			break
	ok(job.done and steps < 20000, "the stepped load finishes (%d steps of %d units; phases %s)" % [steps, units, str(phases)])
	ok(mono, "progress never goes back")
	ok(WorldField.bakeReady(planet), "the bake is whole when the load is done")
	ok(SimPlanetLoad.mayStart(setup), "the load made the planet ready for a match")
	var S1 := SimCore.createSim()
	SimCore.newMatch(S1, 1, {}, setup)
	ok(SimPlanetLoad.refused == refused0 + 1 and S1.planetGen == 3 and S1.base.size() == SimConst.NC, "strict: the match starts on the loaded gen 3 planet")
	var h1: String = str(SimHash.stateHash(S1).gameplay)
	# the whole load is the same planet: forget everything, load in one call, start the same match
	var hash1: String = WorldField.of(WorldPlanet.make(planet)).bakeHash
	WorldPlanet.forget()
	WorldClimate.useGen(3)
	var job2: SimPlanetLoad.Job = SimPlanetLoad.beginFor(setup)
	job2.finishNow()
	ok(job2.done, "a whole-budget load finishes in one call")
	var S2 := SimCore.createSim()
	SimCore.newMatch(S2, 1, {}, setup)
	var h2: String = str(SimHash.stateHash(S2).gameplay)
	WorldClimate.useGen(3)
	ok(WorldField.of(WorldPlanet.make(planet)).bakeHash == hash1, "the bake's hash is the same (%s)" % hash1)
	ok(h1 == h2, "the stepped load and the whole load start the same state (%s)" % h1)
	# a third load, on a warm cache: the bake is read back, the planet and the start are the same
	WorldPlanet.forget()
	WorldClimate.useGen(3)
	var job3: SimPlanetLoad.Job = SimPlanetLoad.beginFor(setup)
	var steps3: int = 0
	while not job3.step(250):
		steps3 += 1
	var F3: WorldField.Field = WorldField.of(WorldPlanet.make(planet))
	ok(F3.fromCache and F3.bakeHash == hash1, "a warm load reads the bake from the cache and has the same bake hash (%d steps)" % steps3)
	ok(F3.reads == 0 and F3.subReads == 0, "and reads no node of the planet's function at all: the planet, the bake and the ring's nodes all came from the cache (%d nodes and %d sub-nodes pooled)" % [F3.extra.size(), F3.extraSub.size()])
	var S3 := SimCore.createSim()
	SimCore.newMatch(S3, 1, {}, setup)
	ok(str(SimHash.stateHash(S3).gameplay) == h1, "and starts the same state as the cold load did")
	for fn in DirAccess.get_files_at(WorldFieldCache.dir()):
		if fn.ends_with(".wfc"):
			DirAccess.remove_absolute(WorldFieldCache.dir() + fn)
	DirAccess.remove_absolute(WorldFieldCache.dir())
	WorldFieldCache.dirOverride = ""
	WorldFieldCache.enabledOverride = -1
	SimPlanetLoad.strict = was_strict
	print("FIELDLOAD: %d check(s) failed" % fails)
	quit(0 if fails == 0 else 1)
