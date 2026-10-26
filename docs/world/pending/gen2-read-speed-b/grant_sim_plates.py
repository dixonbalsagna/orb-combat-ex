# GRANT (Simulation's sim/core/planet_load.gd, for World's second window 20 add-on beside this): Research's B plates
# (46 ms in one call, 49 to 55 on Performance's PC) are made a slice at a time (WorldPlateB.step(P, units)) in the
# load's "plates" step; it stays in the phase until they are made.
# Usage: python grant_sim_plates.py <repo root>
import os, sys
os.chdir(sys.argv[1])
p = 'sim/core/planet_load.gd'
s = open(p, encoding='utf-8').read()
a = ("\t\t\tif phase == \"plates\":   # made by the first ground read in one piece: a step of their own\n"
     "\t\t\t\tWorldLand.platesOf(P)\n"
     "\t\t\t\tif WorldLand.plateB():\n"
     "\t\t\t\t\tWorldPlateB.stateOf(P)\n"
     "\t\t\t\tphase = \"climate\"\n")
b = ("\t\t\tif phase == \"plates\":   # gen 2's plates are small (made here in one piece); Research's B plates (46 ms) are made a slice at a time: the phase stays until they are\n"
     "\t\t\t\tWorldLand.platesOf(P)\n"
     "\t\t\t\tif not WorldLand.plateB() or WorldPlateB.step(P, u):\n"
     "\t\t\t\t\tphase = \"climate\"\n"
     "\t\t\t\telse:\n"
     "\t\t\t\t\tspent += u\n")
assert s.count(a) == 1
s = s.replace(a, b)
open(p, 'w', encoding='utf-8', newline='\n').write(s)
print("Simulation: the load's plates step makes Research's B plates a slice at a time")
