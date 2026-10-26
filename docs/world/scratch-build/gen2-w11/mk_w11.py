"""Window 11 (World, 2026-10-23): the owners' sea-rule lines for lakes at altitude (the EP's item 1; Game Design 23b rows 13 to 15: lakes follow the sea's rules).   python mk_w11.py <root>   (root: windows 2 to 10)
The sea's rules measure depth from absolute zero (y < 0, y < 30, y < SURFACE_Y). WorldWater.seaTop(S, x) is the surface they should measure from: 0 over the sea, a gen 2 lake deep enough to hide in: its own surface,
and -1e18 where there is neither. Where seaTop is 0 (any world without a lake) every line below is the same arithmetic as before, so gen 1 is bit for bit.
 - sim/world/water.gd (World's): seaTop
 - sim/core/fighter.gd (Simulation's), 1 line: flightSpeed's damping in the sea
 - sim/director/launch.gd (Encounter's), 3 lines: predictFlight's water entry and its landing flag, doLaunch's wet flag
 - sim/director/beam.gd (Encounter's), 1 line: the beam's splash
 - sim/director/ai.gd (Encounter's), 7 lines: the hold-at-the-surface height and the dash for the surface"""
import sys
from mk_wbc_lib import rw, rep
R = sys.argv[1].rstrip('/') + '/'


def water(s):
    return rep(s, '''## Start of a match:''', '''const NO_SEA: float = -1.0e18   # seaTop where there is no sea-like water: nothing is below it


## The surface the sea's rules measure from at x: the sea level over the sea, a gen 2 lake deep enough to hide in: its own surface (Game Design 23b row 13: lakes follow the sea's rules), and NO_SEA where there
## is neither. On any world without a lake it is 0 over the sea and NO_SEA elsewhere, which is `y < 0 and seaAt` as the rules were written.
static func seaTop(S: SimState, x: float) -> float:
	var i: int = int(floor(SimWrap.wrap(x) / SimConst.COL)) % SimConst.NC
	if S.base[i] < RESERVOIR_BASE:
		return SEA_LEVEL
	if S.water[i] >= HIDE_MIN_DEPTH and WorldGround.live():
		return S.base[i] + WorldTerrain.lowD(S)[i] + S.water[i]
	return NO_SEA


## Start of a match:''')


def fighter(s):
    return rep(s, '''	if f.y < 0.0 and WorldTerrain.seaAt(S, f.x):
		sp *= 0.55''', '''	if f.y < WorldWater.seaTop(S, f.x):   # in the sea or a deep lake: below its surface
		sp *= 0.55''')


def launch(s):
    s = rep(s, '''		if y < 0.0 and WorldTerrain.seaAt(S, x):
			vx *= kWx''', '''		if y < WorldWater.seaTop(S, x):
			vx *= kWx''')
    s = rep(s, '''"water": y < 0.0 and WorldTerrain.seaAt(S, x), "t": t, "land": x}''', '''"water": y < WorldWater.seaTop(S, x), "t": t, "land": x}''')
    s = rep(s, '''	tgt.wet = tgt.y < 0.0 and WorldTerrain.seaAt(S, tgt.x)''', '''	tgt.wet = tgt.y < WorldWater.seaTop(S, tgt.x)''')
    return s


def beam(s):
    return rep(s, '''	if y < 30.0 and WorldTerrain.seaAt(S, x):''', '''	if y < WorldWater.seaTop(S, x) + 30.0:''')


def ai(s):
    s = rep(s, '''	var sea: bool = WorldTerrain.seaAt(S, f.x)
	if lure != 0.0:''', '''	var sea: bool = WorldTerrain.seaAt(S, f.x)
	var top: float = WorldWater.seaTop(S, f.x) if sea else 0.0   # the water's surface: 0 over the sea, a lake's own
	if lure != 0.0:''')
    s = rep(s, '''		i.my = 1.0 if sea and f.y < SURFACE_Y else 0.0''', '''		i.my = 1.0 if sea and f.y < top + SURFACE_Y else 0.0''')
    s = rep(s, '''		i.my = -1.0 if not sea else (1.0 if f.y < SURFACE_Y else 0.0)''', '''		i.my = -1.0 if not sea else (1.0 if f.y < top + SURFACE_Y else 0.0)''')
    s = rep(s, '''		var cy: float = SimMathx.jmax(o.y, SURFACE_Y) if sea else o.y''', '''		var cy: float = SimMathx.jmax(o.y, top + SURFACE_Y) if sea else o.y''')
    s = rep(s, '''		var ty: float = SimMathx.jmax(o.y, SURFACE_Y) if sea else o.y''', '''		var ty: float = SimMathx.jmax(o.y, top + SURFACE_Y) if sea else o.y''')
    s = rep(s, '''	if sea and f.y < 0.0 and i.my > 0.0:''', '''	if sea and f.y < top and i.my > 0.0:''')
    return s


rw(R, 'sim/world/water.gd', water)
rw(R, 'sim/core/fighter.gd', fighter)
rw(R, 'sim/director/launch.gd', launch)
rw(R, 'sim/director/beam.gd', beam)
rw(R, 'sim/director/ai.gd', ai)
print('w11 applied')
