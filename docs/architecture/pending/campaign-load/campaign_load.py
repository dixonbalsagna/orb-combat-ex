# PARKED BUILD (Simulation): the campaign's host loads the arc's planet before its first column (docs/architecture/
# planet-load.md section 3; Game Design's rulings-2026-10-26 item 27: the load starts as soon as the planet's seed is
# known, while the pair are picked).
#   sim/core/campaign.gd: SimCampaign.beginLoad(arcId); beginColumn, with SimPlanetLoad.strict on, refuses a gen 2
#     planet that is not made;
#   sim/core/tools/campaign_recipes.gd: the test's episode loads the arc's planet a slice a step, and each stage's ring,
#     as a host does;
#   sim/core/tools/parity.gd: "the planet's load" adds the campaign's refusal of a cold gen 2 planet, and its column
#     once the arc's planet is loaded.
# Nothing here runs in a match and strict is off unless a host sets it: the golden does not move. No other director's
# files, and not sim/core/planet_load.gd (World's gen2-read-speed grant edits it). Usage: python campaign_load.py <root>
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
os.chdir(sys.argv[1])
assert 'class_name SimPlanetLoad' in open('sim/core/planet_load.gd', encoding='utf-8').read(), 'planet-load (0c62c856) first'
assert 'static func beginLoad' not in open('sim/core/campaign.gd', encoding='utf-8').read(), 'applied already'


def edit(p, pairs):
    s = open(p, encoding='utf-8').read()
    for a, b in pairs:
        assert s.count(a) == 1, (p, a[:90], s.count(a))
        s = s.replace(a, b)
    open(p, 'w', encoding='utf-8', newline='\n').write(s)


edit('sim/core/campaign.gd', [
("## The current column's job (World's WorldCampaign.beginColumn): the host steps it a ring's read a frame during the\n"
 "## beats before the column (500 ms at once on a gen 2 planet), and hands the result to columnDone.\n"
 "static func beginColumn(state: Dictionary, P: WorldPlanet.Planet) -> WorldCampaign.ColumnJob:\n"
 "\tvar a: Dictionary = state.arc\n",
 "## The arc's planet, loaded before its first episode (SimPlanetLoad, planet-load.md): the host steps it a slice a frame\n"
 "## from the moment the arc is known (while the pair are picked: Game Design's rulings-2026-10-26 item 27), then\n"
 "## WorldPlanet.make finds it made for newEpisode and the columns. Every episode of the arc, and its side stories, fly it.\n"
 "static func beginLoad(arcId: String) -> SimPlanetLoad.Job:\n"
 "\treturn SimPlanetLoad.begin(arcPlanet(arcId))\n"
 "\n\n"
 "## The current column's job (World's WorldCampaign.beginColumn): the host steps it a ring's read a frame during the\n"
 "## beats before the column (500 ms at once on a gen 2 planet), and hands the result to columnDone. With\n"
 "## SimPlanetLoad.strict on (the game's host), a gen 2 planet not made is refused (null): the host loads it first.\n"
 "static func beginColumn(state: Dictionary, P: WorldPlanet.Planet) -> WorldCampaign.ColumnJob:\n"
 "\tvar seed: int = int(state.planet.seed)\n"
 "\tif SimPlanetLoad.strict and WorldClimate.genNow() >= 2 and not SimPlanetLoad.ready(seed, WorldClimate.genNow()):   # never made cold in a column's job\n"
 "\t\tSimPlanetLoad.refused += 1\n"
 "\t\t_err(\"campaign: planet %d is not made: load it first (SimCampaign.beginLoad)\" % seed)\n"
 "\t\treturn null\n"
 "\tvar a: Dictionary = state.arc\n"),
])

edit('sim/core/tools/campaign_recipes.gd', [
("\tvar P: WorldPlanet.Planet = WorldPlanet.make(SimCampaign.arcPlanet(arcId))\n",
 "\tvar ld: SimPlanetLoad.Job = SimCampaign.beginLoad(arcId)   # the arc's planet first, a slice a step, as the host loads it while the pair are picked\n"
 "\twhile not ld.step(SimRun.planetUnitsPerRead):\n"
 "\t\tpass\n"
 "\tvar P: WorldPlanet.Planet = WorldPlanet.make(SimCampaign.arcPlanet(arcId))\n"),
("\t\tvar S := SimCore.createSim()\n\t\tSimCore.newMatch(S, SimRun.stageSeed(String(s.run), c + 1, 0), {}, su)\n",
 "\t\tvar rl: SimPlanetLoad.Job = SimPlanetLoad.beginFor(su)   # the stage's ring, read over the flight to the site as the host reads it\n"
 "\t\twhile not rl.step(SimRun.planetUnitsPerRead):\n"
 "\t\t\tpass\n"
 "\t\tvar S := SimCore.createSim()\n\t\tSimCore.newMatch(S, SimRun.stageSeed(String(s.run), c + 1, 0), {}, su)\n"),
])

CHECK = open(os.path.join(HERE, 'files', 'parity_campaign_load.gd.txt'), encoding='utf-8').read()
edit('sim/core/tools/parity.gd', [
("\tSimCore.dispose(S4)\n\tWorldPlanet.forget()\n\tWorldClimate.useGen(0)\n\tFighterData.quiet = quiet\n",
 "\tSimCore.dispose(S4)\n\tWorldPlanet.forget()\n\tWorldClimate.useGen(0)\n" + CHECK + "\tFighterData.quiet = quiet\n"),
("## - a ring an arena names, read in slices of columns, gives the same match as one read in one piece, and a second load\n##   of it has nothing to do.\n",
 "## - a ring an arena names, read in slices of columns, gives the same match as one read in one piece, and a second load\n##   of it has nothing to do;\n"
 "## - the campaign's column job refuses a gen 2 planet not made (strict), and takes it once the arc's planet is loaded.\n"),
])
print("the campaign's arc-planet load (beginLoad), its column's refusal of a cold gen 2 planet, the episode's loads, parity's case")
