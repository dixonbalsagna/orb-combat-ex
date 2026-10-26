# GRANT (World's sim/world/planet.gd, for Simulation's planet_load.py beside this): two small things a host's load
# step needs.
#   - WorldPlanet.isMade(seed): whether make(seed) would find the planet made (World's memo), so a match's start can
#     refuse a gen 2 planet that is not, and a host knows when to load. WorldPlanet.ringRead(seed, ring): whether a
#     ring's slice is read already, so a load does not read it again.
#   - PlanetJob: the flow field (rivers on, about 140 ms native, 1.4 s on Performance's phone tier) is a slice of its
#     own. Today a frame's slice that ends the climate grid also runs the wind's carry and then the flow field; now the
#     flow field waits for the next slice when the one that ended the grid has fewer units left than the flow field
#     costs. A whole budget (a finishNow's) still goes on in the same call. The planet is the same (the flow is a pure
#     function of the grid), and make(seed) does not use the job.
# Usage: python grant_world.py <repo root>
import os, sys
os.chdir(sys.argv[1])
p = 'sim/world/planet.gd'
s = open(p, encoding='utf-8').read()
pairs = [
("\tvar _grid = null\n\tvar _st: Dictionary = {}\n",
 "\tvar _grid = null\n\tvar _flowDue: bool = false\n\tvar _st: Dictionary = {}\n"),
("\t\t\tP.grid = _grid\n"
 "\t\t\t_grid = null\n"
 "\t\t\tif WorldRivers.enabled():   # the drainage of the grid (about 100 ms: FLOW_COST units), its own step of the job\n"
 "\t\t\t\tWorldRivers.flowOf(P)\n"
 "\t\t\t\tleft -= WorldRivers.FLOW_COST\n"
 "\t\t\t\tif left <= 0:\n"
 "\t\t\t\t\treturn false\n",
 "\t\t\tP.grid = _grid\n"
 "\t\t\t_grid = null\n"
 "\t\t\t_flowDue = WorldRivers.enabled()\n"
 "\t\t\tif _flowDue and left < WorldRivers.FLOW_COST:   # a frame's slice that ended the grid (and its carry) leaves the flow field to the next; a whole budget (finishNow) goes on\n"
 "\t\t\t\treturn false\n"
 "\t\tif _flowDue:   # the drainage of the grid (about 100 ms: FLOW_COST units), a slice of its own\n"
 "\t\t\t_flowDue = false\n"
 "\t\t\tWorldRivers.flowOf(P)\n"
 "\t\t\tleft -= WorldRivers.FLOW_COST\n"
 "\t\t\tif left <= 0:\n"
 "\t\t\t\treturn false\n"),
("static func makeJob(seed: int) -> PlanetJob:\n",
 "## Whether make(seed) would find the planet made (by the generation planets are made by now): a host's load step asks\n"
 "## before a match's start (SimPlanetLoad).\n"
 "static func isMade(seed: int) -> bool:\n"
 "\treturn _planets.has(seed * 4 + WorldClimate.genNow())\n"
 "\n\n"
 "static func makeJob(seed: int) -> PlanetJob:\n"),
("## A ring's slice read in steps is put where sliceRing finds it.\n",
 "## Whether sliceRing would find this ring's slice read already (a host's load step asks before it reads one in steps).\n"
 "static func ringRead(seed: int, ring: Dictionary) -> bool:\n"
 "\treturn _slices.has(_ringKey(seed, ring, PackedByteArray()))\n"
 "\n\n"
 "## A ring's slice read in steps is put where sliceRing finds it.\n"),
]
for a, b in pairs:
    assert s.count(a) == 1, (a[:80], s.count(a))
    s = s.replace(a, b)
open(p, 'w', encoding='utf-8', newline='\n').write(s)
print("World: WorldPlanet.isMade and ringRead, and PlanetJob's flow field a slice of its own")
