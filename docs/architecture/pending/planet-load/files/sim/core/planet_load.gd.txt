class_name SimPlanetLoad
extends RefCounted
## A planet made before a match, in steps (docs/architecture/planet-load.md). Performance's gen 2 bench: a cold gen 2
## planet takes 1.7 s on this PC, 9.5 s on an old laptop and 16 s on a phone, so it is never made inside a match's
## start. The host begins a load, spends a bounded slice a frame on it (SimRun.planetUnitsPerRead units, the data's:
## about 5 ms here, a unit is about 20 microseconds of World's) and reads progress() and phase for its loading screen;
## then SimCore.newMatch finds the planet made and the match's ring read. The steps:
##   plates   gen 2's plates (and Research's B plates when on), a step of their own: the first ground read makes them;
##   climate  World's PlanetJob: the climate grid, a slice of cells a step, then the wind's carry;
##   rivers   the flow field when rivers are on (World's job makes it as a step of its own);
##   places   the cities and towns, a try-set a step;
##   ring     a match's ring read (beginFor only): World's RingJob, a slice of columns a step, memoised where the match
##            finds it (an arena with no ring of its own, a touch-down's, is read in one piece).
## The planet and the ring are the same however they are stepped (make(seed) is World's job run to the end). Behind
## gen 2: a gen 1 planet is quick, and newMatch still makes it as it always did.
## strict: the game's host sets it. SimCore.newMatch then refuses a setup whose gen 2 planet is not made (it is left as
## it was, and `refused` counts it); tools leave it off and make their planets as before.

const COLUMN_UNITS: int = 4   # a ring column's read, in World's units (gen 2 about 60 to 80 microseconds on this PC)

static var strict: bool = false
static var refused: int = 0


## The generation a match's setup makes its planet by: its planetGen, else the data's (WorldPlanetWorld.gen).
static func genOf(setup: Dictionary) -> int:
	var g: int = int(setup.get("planetGen", 0))
	return g if g > 0 else int(WorldClimate.data().get("gen", 1))


## Whether a planet is ready for a match's start: made (World's memo) and, with rivers on, its flow field made.
static func ready(seed: int, gen: int) -> bool:
	var was: int = WorldClimate.curGen
	WorldClimate.useGen(gen)
	var ok: bool = WorldPlanet.isMade(seed)
	if ok and gen >= 2 and WorldRivers.enabled():
		ok = WorldPlanet.make(seed).flow != null
	WorldClimate.useGen(was)
	return ok


## Whether SimCore.newMatch may start this setup without making a planet cold: no planet, a gen 1 one, or a gen 2 one
## already made.
static func mayStart(setup: Dictionary) -> bool:
	if not setup.has("planet"):
		return true
	var g: int = genOf(setup)
	return g < 2 or ready(int(setup.planet), g)


## A load of planet `seed` by generation `gen` (0: the generation planets are made by now, a tool's or the data's).
static func begin(seed: int, gen: int = 0) -> Job:
	return Job.new(seed, gen if gen > 0 else WorldClimate.genNow(), {})


## The load of a match's setup: its planet by its generation, then its ring. Null when it has no planet.
static func beginFor(setup: Dictionary) -> Job:
	return Job.new(int(setup.planet), genOf(setup), setup) if setup.has("planet") else null


class Job extends RefCounted:
	var seed: int = 0
	var gen: int = 1
	var P: WorldPlanet.Planet = null
	var pj: WorldPlanet.PlanetJob = null
	var phase: String = "plates"   # plates, climate, rivers, places, ring, done
	var spent: int = 0             # units spent
	var total: int = 1             # the units in all: the grid's cells, the flow field's, a try-set's a place, the ring's columns
	var frames: int = 0
	var done: bool = false
	var _cells: int = 0
	var _flow: int = 0
	var _places: int = 0
	var _setup: Dictionary = {}
	var _cols: int = 0             # the match's arena, in columns (0: no ring to read)
	var _ring: Dictionary = {}     # its ring, when the arena names one
	var _rj = null                 # World's RingJob over it
	var _ringDone: bool = true

	func _init(sd: int, g: int, setup: Dictionary) -> void:
		seed = sd
		gen = g
		var was: int = WorldClimate.curGen
		WorldClimate.useGen(g)
		pj = WorldPlanet.makeJob(sd)
		P = pj.P
		if g >= 2:
			var gd: Dictionary = WorldClimate.data().grid
			_cells = int(gd.w) * int(gd.h)
			_flow = WorldRivers.FLOW_COST if WorldRivers.enabled() else 0
		_places = (int(P.c.cities) + int(P.c.towns) + 1) * WorldPlanet.PlanetJob.PLACE_COST
		if setup.has("planet"):
			_setup = setup
			_cols = SimCore._arenaCols(setup)
			var arena = setup.get("arena", {})
			_ring = WorldRingPick.ringOfArena(arena) if arena is Dictionary else {}
			var nc: int = SimConst.NC
			SimConst.setArena(_cols)   # the ring's memo is keyed by the arena's columns, as the match reads it
			_ringDone = not _ring.is_empty() and WorldPlanet.ringRead(sd, _ring)
			SimConst.setArena(nc)
		total = maxi(1, _cells + _flow + _places + (_cols * COLUMN_UNITS if _cols > 0 else 0))
		if g < 2 or pj.done:   # gen 1 has no grid or plates; a planet made already may want only its flow field or ring
			phase = "places"
		_settle()
		WorldClimate.useGen(was)

	## One frame's slice: up to `units` of World's units (the plates' step, the carry, the flow field and a try-set are
	## one piece each). True when the planet is ready for a match (and, from beginFor, its ring read). A budget of the
	## whole load or more (finishNow's) goes through every step in the one call.
	func step(units: int) -> bool:
		if done:
			return true
		frames += 1
		var u: int = maxi(1, units)
		var whole: bool = u >= total
		var was: int = WorldClimate.curGen
		WorldClimate.useGen(gen)
		while true:
			if phase == "plates":   # made by the first ground read in one piece: a step of their own
				WorldLand.platesOf(P)
				if WorldLand.plateB():
					WorldPlateB.stateOf(P)
				phase = "climate"
			elif not pj.done:
				var placing: bool = phase == "places"
				pj.step(u)
				spent += maxi(u, WorldPlanet.PlanetJob.PLACE_COST) if placing else u   # a step makes one try-set at least
			elif _flow > 0 and P.flow == null:   # a planet made whole elsewhere, without its flow field
				WorldRivers.flowOf(P)
			elif not _ringDone:
				_readRing(u)
			_settle()
			if done or not whole:
				break
		WorldClimate.useGen(was)
		return done

	func finishNow() -> void:
		step(1 << 40)

	## How far the load is, 0 to 1, for a loading screen (by World's units: about even in time).
	func progress() -> float:
		return 1.0 if done else clampf(float(spent) / float(total), 0.0, 0.99)

	## The match's ring, read as newMatch reads it (its arena's columns and generation) and memoised where it finds it.
	func _readRing(u: int) -> void:
		var nc: int = SimConst.NC
		SimConst.setArena(_cols)
		if _ring.is_empty():   # a touch-down's ring: World has no stepped read for it, so one piece
			var arena = _setup.get("arena", {})
			WorldPlanet.sliceFor(seed, int(_setup.get("touch", 0)), PackedByteArray(), false, int(arena.get("side", 1)) if arena is Dictionary else 1)
			_ringDone = true
		else:
			if _rj == null:
				_rj = WorldPlanet.RingJob.new(P, _ring)
			if _rj.step(maxi(1, u / COLUMN_UNITS)):
				WorldPlanet.memoRing(seed, _ring, _rj.slice)
				_ringDone = true
			spent += u
		SimConst.setArena(nc)

	func _settle() -> void:
		var planetDone: bool = pj.done and (_flow == 0 or P.flow != null)
		done = planetDone and _ringDone
		if done:
			phase = "done"
			spent = total
		elif phase == "plates":
			return
		elif P.grid == null and gen >= 2:
			phase = "climate"
		elif _flow > 0 and P.flow == null:
			phase = "rivers"
			spent = maxi(spent, _cells)
		elif not pj.done:
			phase = "places"
			spent = maxi(spent, _cells + _flow)
		else:
			phase = "ring"
			spent = maxi(spent, _cells + _flow + _places)
