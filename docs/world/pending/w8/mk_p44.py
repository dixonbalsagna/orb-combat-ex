"""World, 2026-10-30: density_check also holds the replay-header helpers.   python mk_p44.py <root>"""
import sys
from mk_wbc_lib import rw, rep
R = sys.argv[1].rstrip('/') + '/'


def check(s):
    return rep(s, '''	D["enabled"] = on0
	print("DENSITY: %d check(s) failed" % fails)''', '''	D["enabled"] = on0
	# --- the replay header's helpers (Simulation folds them in): the module's switch and a cached hash, the generation a setup names, and the planet's hash keyed on it
	ok(WorldDensity.enabled() == on0 and WorldDensity.dataHash() != "" and WorldDensity.dataHash() == WorldDensity.dataHash(), "WorldDensity.enabled() reads the switch and dataHash() is made once (%s)" % WorldDensity.dataHash())
	var keep: int = WorldClimate.curGen
	WorldClimate.useGen(1)
	var gA: int = WorldClimate.genFor({"planetGen": 2})
	WorldClimate.useGen(2)
	var gB: int = WorldClimate.genFor({})
	var gC: int = WorldClimate.genFor({"planetGen": 1})
	WorldClimate.useGen(0)
	var dataGen: int = int(WorldClimate.data().get("gen", 1))
	ok(gA == 2 and gC == 1 and gB == dataGen and WorldClimate.genFor({"planetGen": 0}) == dataGen, "genFor(setup) is the setup's planetGen, else climate.json's gen, whatever generation a tool has in force (%d, %d, %d)" % [gA, gB, gC])
	WorldClimate.useGen(1)
	var p1: String = WorldPlanet.dataHash()
	var p2: String = WorldPlanet.dataHash(2)
	WorldClimate.useGen(2)
	var p2n: String = WorldPlanet.dataHash()
	var p1g: String = WorldPlanet.dataHash(1)
	WorldClimate.useGen(keep)
	ok(p1 != p2 and p2n == p2 and p1g == p1 and WorldPlanet.dataHash(2) == p2, "WorldPlanet.dataHash(gen) follows the generation given, and 0 the one in force (gen 1 %s, gen 2 %s)" % [p1.substr(0, 10), p2.substr(0, 16)])
	print("DENSITY: %d check(s) failed" % fails)''')


rw(R, 'sim/world/tools/density_check.gd', check)
print('p44 applied')
