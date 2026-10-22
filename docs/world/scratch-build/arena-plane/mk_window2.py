"""Planet window 2, a DRAFT (World, scratch, parked): a match on a slice of the stored planet.   python mk_window2.py <root>
Root: an export of main's HEAD with the collateral window applied (the draft sets Building.place and Building.plan).
Lines in files that are not World's: sim/core/sim.gd (newMatch: the planet branch and the start)."""
import sys, shutil, os
from mk_wbc_lib import rw, rep

R = sys.argv[1].rstrip('/') + '/'
here = os.path.dirname(os.path.abspath(__file__))
shutil.copy(os.path.join(here, 'planet_world.gd'), R + 'sim/world/planet_world.gd')
for f, d in (('planet_world.gd.uid', 'sim/world/'), ('planet_world_check.gd', 'sim/world/tools/'), ('planet_world_check.gd.uid', 'sim/world/tools/')):
    if os.path.exists(os.path.join(here, f)):
        shutil.copy(os.path.join(here, f), R + d + f)


def biomes(s):
    s = rep(s, '''static func biomeAt(x: float) -> String:
	x = SimWrap.wrap(x)
''', '''## A match on a planet's slice (WorldPlanetWorld.gen): the biome of each column, as an index into WorldPlanetWorld.BIOME_NAME; empty for the hand-made world.
static var planetCols := PackedByteArray()


static func biomeAt(x: float) -> String:
	x = SimWrap.wrap(x)
	if planetCols.size() > 0:
		return WorldPlanetWorld.BIOME_NAME[planetCols[mini(int(x / SimConst.COL), planetCols.size() - 1)]]
''')
    return s


def sim(s):
    s = rep(s, '''	WorldTerrain.genWorld(S)
	S.contactOn''', '''	WorldBiomes.planetCols = PackedByteArray()
	if not (setup.has("planet") and WorldPlanetWorld.gen(S, setup)):   # a setup with a planet reads its world from the slice; without one, today's world
		WorldTerrain.genWorld(S)
	S.contactOn''')
    s = rep(s, '''	var x0: float = start_x
	var x1: float = start_x + SimConst.START_GAP''', '''	if setup.has("planet"):
		start_x = float(WorldPlanet.TOUCH_COL) * SimConst.COL - SimConst.START_GAP * 0.5   # astride the touch-down
	var x0: float = start_x
	var x1: float = start_x + SimConst.START_GAP''')
    return s


rw(R, 'sim/world/biomes.gd', biomes)
rw(R, 'sim/core/sim.gd', sim)
print('window 2 draft applied')
