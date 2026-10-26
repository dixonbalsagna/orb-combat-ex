# PARKED BUILD (Simulation): the planet's load step (docs/architecture/planet-load.md), on the EP's brief after
# Performance's gen 2 bench (docs/perf/gen2-bench-2026-10-26.md: a cold gen 2 planet takes 1.7 s here, 9.5 s on an old
# laptop and 16 s on a phone). A host loads a planet in steps before a match, a bounded slice a frame, and reads its
# progress for a loading screen; no match's start makes a gen 2 planet cold.
#   adds sim/core/planet_load.gd (SimPlanetLoad: begin/beginFor, Job.step/progress/phase/finishNow, ready, mayStart,
#     strict, refused) and its .uid;
#   edits sim/core/sim.gd (newMatch: with SimPlanetLoad.strict on, a setup whose gen 2 planet is not made is refused and
#     the state left as it was), sim/core/run.gd (the run's GroundJob loads its planet with SimPlanetLoad: the same
#     steps, its progress) and sim/core/tools/parity.gd ("the planet's load").
# strict is off unless a host sets it, and nothing here runs in a match: the golden does not move. Needs World's two
# lines (grant_world.py: WorldPlanet.isMade, PlanetJob's flow field a slice of its own). Usage: python planet_load.py <root>
import os, shutil, sys
HERE = os.path.dirname(os.path.abspath(__file__))
os.chdir(sys.argv[1])
for f in ['sim/core/planet_load.gd', 'sim/core/planet_load.gd.uid']:
    assert not os.path.exists(f), f + ' is already there'
    shutil.copyfile(os.path.join(HERE, 'files', f + '.txt'), f)

def edit(p, pairs):
    s = open(p, encoding='utf-8').read()
    for a, b in pairs:
        assert s.count(a) == 1, (p, a[:90], s.count(a))
        s = s.replace(a, b)
    open(p, 'w', encoding='utf-8', newline='\n').write(s)

edit('sim/core/sim.gd', [
("static func newMatch(S: SimState, seed: int, ai: Dictionary = {}, setup: Dictionary = {}) -> void:\n"
 "\tS.game.seed = float(seed & 0xFFFFFFFF)\n",
 "static func newMatch(S: SimState, seed: int, ai: Dictionary = {}, setup: Dictionary = {}) -> void:\n"
 "\tif SimPlanetLoad.strict and not SimPlanetLoad.mayStart(setup):   # the game's host loads a gen 2 planet first (SimPlanetLoad): never made cold in a match's start\n"
 "\t\tSimPlanetLoad.refused += 1\n"
 "\t\tif not FighterData.quiet:\n"
 "\t\t\tpush_error(\"SimCore.newMatch: planet %d (gen %d) is not made: load it first (SimPlanetLoad)\" % [int(setup.planet), SimPlanetLoad.genOf(setup)])\n"
 "\t\treturn\n"
 "\tS.game.seed = float(seed & 0xFFFFFFFF)\n"),
])

edit('sim/core/run.gd', [
("\tg.pj = WorldPlanet.makeJob(g.planet)\n",
 "\tg.pj = SimPlanetLoad.begin(g.planet)\n"),
("\tvar pj: WorldPlanet.PlanetJob = null       # the planet being made in steps, until it is whole (null once the ground has started)\n",
 "\tvar pj: SimPlanetLoad.Job = null          # the planet being loaded in steps (SimPlanetLoad), until it is ready (null once the ground has started)\n"),
("\t## The ground's start, once the planet is whole",
 "\t## How far the planet's load is, 0 to 1, for a loading screen (1 once the ground has started: the reads are quick).\n"
 "\tfunc progress() -> float:\n"
 "\t\treturn 1.0 if pj == null else pj.progress()\n"
 "\n"
 "\t## The ground's start, once the planet is whole"),
])

CHECK = open(os.path.join(HERE, 'files', 'parity_planet_load.gd.txt'), encoding='utf-8').read()
edit('sim/core/tools/parity.gd', [
("\tcheck(\"the campaign's arc and episode\", _campaign())\n",
 "\tcheck(\"the campaign's arc and episode\", _campaign())\n"
 "\tcheck(\"the planet's load\", _planetLoad())\n"),
("func _ringHolds(ev: Dictionary, id: int) -> bool:\n", CHECK + "\n\nfunc _ringHolds(ev: Dictionary, id: int) -> bool:\n"),
])
print("the planet's load: SimPlanetLoad, newMatch's strict refusal, the run's ground on it, parity's check")
