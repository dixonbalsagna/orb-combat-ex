"""Window 12, the makeJob host for Simulation's SimRun.beginGround (a draft for its owner): the planet is made in steps while the previous stage's beats play, not in one call.   python mk_host_run.py <root>
Warm (the planet is already made, which is every stage after the first and every gen 1 run) nothing changes: the job is done at once and the ground starts in beginGround as before."""
import sys
from mk_wbc_lib import rw, rep
R = sys.argv[1].rstrip('/') + '/'


def run(s):
    s = rep(s, '''static var framesPerRead: Dictionary''', '''## Planet units (a climate cell, about 20 microseconds; a place's try-set is 1000) spent on the planet's own make for each read a host asks of the ground, when the planet is not made yet (WorldPlanet.makeJob):
## about 5 ms a read, so a gen 2 planet (about a second) is made over the first beats of the stage before it, a frame at a time, and the pick starts when it is whole.
const PLANET_UNITS_PER_READ: int = 250
static var framesPerRead: Dictionary''')
    s = rep(s, '''	g.planet = planetSeed(run)
	g.P = WorldPlanet.make(g.planet)
	g.standing = opts.get("standing", PackedByteArray())
	g.damaged = opts.get("damaged", [])
	g.used = opts.get("used", [])
	var hm: Dictionary = opts.get("homes", homes(g.P))
	g.rule = ruleOf(chapter)
	g.size = sizeFor(opponent, chapter, String(opts.get("kind", "")))
	var stream: int = H(run, "ground", chapter, g.choice)
	if g.rule == "first":
		g.home = int(hm.get(String(opts.get("player", "PROTAGONIST")), -1))
		if g.home >= 0:   # stepped like the others: one read, 13 when the ring is turned toward land
			g.first = WorldRingPick.beginFirstRing(g.P, g.home, stream, {"standing": g.standing, "damaged": g.damaged})
	elif g.rule == "boss":
		g.home = int(hm.get(opponent, -1))
		var b = WorldRingPick.bossRing(g.P, g.home, g.standing) if g.home >= 0 else null
		if b != null:
			g.spec = b
			g.spec["place"] = g.home
	if g.spec.is_empty() and g.first == null:
		g.rule = "boss_claim" if g.rule == "boss" else "claim"
		g.home = int(hm.get(opponent, -1))
		g.job = WorldRingPick.beginPick(g.P, claim(opponent), g.size, stream, {"home": g.home, "standing": g.standing, "damaged": g.damaged, "used": g.used})
	return g
''', '''	g.planet = planetSeed(run)
	g.opts = opts
	g.pj = WorldPlanet.makeJob(g.planet)
	if g.pj.done:   # made already: the ground starts here, as it always did
		g.start()
	return g
''')
    s = rep(s, '''	var P: WorldPlanet.Planet
''', '''	var P: WorldPlanet.Planet
	var opts: Dictionary = {}
	var pj: WorldPlanet.PlanetJob = null       # the planet being made in steps, until it is whole (null once the ground has started)
''')
    s = rep(s, '''	## Reads up to n more candidates; true when the ground is picked.
	func step(n: int) -> bool:
		if done or n <= 0:
			return done
''', '''	## The ground's start, once the planet is whole (beginGround when it already is, else the first step after the planet's job finishes).
	func start() -> void:
		pj = null
		P = WorldPlanet.make(planet)
		standing = opts.get("standing", PackedByteArray())
		damaged = opts.get("damaged", [])
		used = opts.get("used", [])
		var hm: Dictionary = opts.get("homes", SimRun.homes(P))
		rule = SimRun.ruleOf(chapter)
		size = SimRun.sizeFor(opponent, chapter, String(opts.get("kind", "")))
		var stream: int = SimRun.H(run, "ground", chapter, choice)
		if rule == "first":
			home = int(hm.get(String(opts.get("player", "PROTAGONIST")), -1))
			if home >= 0:   # stepped like the others: one read, 13 when the ring is turned toward land
				first = WorldRingPick.beginFirstRing(P, home, stream, {"standing": standing, "damaged": damaged})
		elif rule == "boss":
			home = int(hm.get(opponent, -1))
			var b = WorldRingPick.bossRing(P, home, standing) if home >= 0 else null
			if b != null:
				spec = b
				spec["place"] = home
		if spec.is_empty() and first == null:
			rule = "boss_claim" if rule == "boss" else "claim"
			home = int(hm.get(opponent, -1))
			job = WorldRingPick.beginPick(P, SimRun.claim(opponent), size, stream, {"home": home, "standing": standing, "damaged": damaged, "used": used})

	## Reads up to n more candidates; true when the ground is picked. While the planet is still being made the reads go to it (PLANET_UNITS_PER_READ each) and nothing is picked until it is whole (the same call then goes on to the pick, so finishNow still finishes).
	func step(n: int) -> bool:
		if done or n <= 0:
			return done
		if pj != null:
			if not pj.step(n * SimRun.PLANET_UNITS_PER_READ):
				return false
			start()
''')
    return s


def parity(s):
    return rep(s, '''	var gc: SimRun.GroundJob = SimRun.beginGround(coast, 1, "RIVAL")
	var fc: int = 1''', '''	WorldPlanet.make(SimRun.planetSeed(coast))   # made already, as in a run's later stages: a cold planet is made over the first reads (host_check), which are not candidates
	var gc: SimRun.GroundJob = SimRun.beginGround(coast, 1, "RIVAL")
	var fc: int = 1''')


rw(R, 'sim/core/run.gd', run)
rw(R, 'sim/core/tools/parity.gd', parity)
print('host run draft built')
