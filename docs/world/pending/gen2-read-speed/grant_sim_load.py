# GRANT (Simulation's sim/core/planet_load.gd, for World's window 20 add-on beside this): the load spends its slice on
# World's now-stepped job and reads a touch-down's ring with World's SliceJob.
#   - a PlanetJob step goes on where it left off (a try, a row of the carry, a few cells of the flow field), so a
#     step spends the slice: `spent += u` (it was one try-set at least, PLACE_COST units);
#   - a touch-down's ring (no ring named by the arena) is read with WorldPlanet.SliceJob (the pick a circle a step,
#     the columns a slice, the held places; memoised where sliceFor finds it) instead of one sliceFor call.
# Usage: python grant_sim_load.py <repo root>
import os, sys
os.chdir(sys.argv[1])
p = 'sim/core/planet_load.gd'
s = open(p, encoding='utf-8').read()
pairs = [
("\tvar _rj = null                 # World's RingJob over it\n",
 "\tvar _rj = null                 # World's RingJob over it\n\tvar _sj = null                 # World's SliceJob over a touch-down's ring\n"),
("\t\t\t\tvar placing: bool = phase == \"places\"\n\t\t\t\tpj.step(u)\n\t\t\t\tspent += maxi(u, WorldPlanet.PlanetJob.PLACE_COST) if placing else u   # a step makes one try-set at least\n",
 "\t\t\t\tpj.step(u)\n\t\t\t\tspent += u   # World's job goes on where it left off (a try, a row of the carry, a few cells of the flow field): a step spends the slice\n"),
("\t\tif _ring.is_empty():   # a touch-down's ring: World has no stepped read for it, so one piece\n\t\t\tvar arena = _setup.get(\"arena\", {})\n\t\t\tWorldPlanet.sliceFor(seed, int(_setup.get(\"touch\", 0)), PackedByteArray(), false, int(arena.get(\"side\", 1)) if arena is Dictionary else 1)\n\t\t\t_ringDone = true\n",
 "\t\tif _ring.is_empty():   # a touch-down's ring: World's SliceJob (the pick a circle a step, the columns a slice, the held places), memoised where sliceFor finds it\n\t\t\tif _sj == null:\n\t\t\t\tvar arena = _setup.get(\"arena\", {})\n\t\t\t\t_sj = WorldPlanet.SliceJob.new(seed, int(_setup.get(\"touch\", 0)), PackedByteArray(), false, int(arena.get(\"side\", 1)) if arena is Dictionary else 1)\n\t\t\tif _sj.step(u):\n\t\t\t\t_ringDone = true\n\t\t\tspent += u\n"),
("##   ring     a match's ring read (beginFor only): World's RingJob, a slice of columns a step, memoised where the match\n##            finds it (an arena with no ring of its own, a touch-down's, is read in one piece).\n",
 "##   ring     a match's ring read (beginFor only): World's RingJob (an arena that names its ring) or SliceJob (a\n##            touch-down's), a slice of columns a step, memoised where the match finds it.\n"),
]
for a, b in pairs:
    assert s.count(a) == 1, (a[:70], s.count(a))
    s = s.replace(a, b)
open(p, 'w', encoding='utf-8', newline='\n').write(s)
print("Simulation: the load spends its slice on World's stepped job and reads a touch-down's ring with SliceJob")
