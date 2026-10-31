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
	SimPlanetLoad.strict = was_strict
	print("field_load_check: %d check(s) failed" % fails)
	quit(0 if fails == 0 else 1)
