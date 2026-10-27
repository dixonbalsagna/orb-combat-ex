# GRANT (World's sim/world/terrain.gd, for Simulation's match_start.py beside this): genWorld in pieces, for a match's
# start in steps (SimCore.beginMatch; docs/architecture/match-start.md). WorldTerrain.genBegin makes a GenJob,
# genStep runs one piece (the ground HEIGHT_SLICE columns a piece, then the smoothing and the platforms, a settlement a
# piece, the lanes, then the people, the trees and the arrays) and genWorld is them run to the end: the same work in
# the same order, every line as it was, so the world is the same however it is stepped and the golden does not move.
# Usage: python grant_world.py <repo root>
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
os.chdir(sys.argv[1])
p = 'sim/world/terrain.gd'
s = open(p, encoding='utf-8').read()
a = 'static func genWorld(S: SimState) -> void:\n\tvar r := SimRng.new(4242)\n'
b = '\tWorldWater.init(S)\n\tWorldCollateral.init(S)\n'
assert s.count(a) == 1 and s.count(b) == 1 and s.index(a) < s.index(b), 'genWorld as on main'
i = s.index(a)
j = s.index(b) + len(b)
s = s[:i] + open(os.path.join(HERE, 'files', 'genworld_new.gd.txt'), encoding='utf-8').read() + s[j:]
open(p, 'w', encoding='utf-8', newline='\n').write(s)
print("World: genWorld in pieces (genBegin, genStep, GenJob)")
