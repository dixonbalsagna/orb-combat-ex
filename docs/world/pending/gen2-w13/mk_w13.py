"""Window 13 (World, 2026-10-23): B's volcanic score is the fine biome `volcanic` when land.json's b.enabled is on.   python mk_w13.py <root>   (root: main plus windows 9 to 12)
 - sim/world/plateb.gd: State remembers the point of its last ground read; volcAt(P, x, y, z) is that read's volcanic score (reading the ground there if the last read was elsewhere)
 - sim/world/climate.gd: plain() takes B's volcanic score in place of the noise's, as Research's approach B does (a land point whose score is over plates-b's `volcanic`, not too cold, not a beach, is a volcanic field), also on ground that would be mountains"""
import sys
from mk_wbc_lib import rw, rep
R = sys.argv[1].rstrip('/') + '/'


def plateb(s):
    s = rep(s, '''	var volc: float = 0.0               # the volcanic score of the last ground read (0 to 1), a side output
''', '''	var volc: float = 0.0               # the volcanic score of the last ground read (0 to 1), a side output
	var lx: float = 2.0                 # the point of that read (a unit vector's parts are within 1, so 2 is "none yet")
	var ly: float = 2.0
	var lz: float = 2.0
''')
    s = rep(s, '''	S.volc = 1.0 if volc > 1.0 else volc
	return h
''', '''	S.volc = 1.0 if volc > 1.0 else volc
	S.lx = px
	S.ly = py
	S.lz = pz
	return h
''')
    return rep(s, '''## The ground at a point of the unit sphere:''', '''## The volcanic score (0 to 1) at a point: that of the last ground read when it was at this point (surfAt reads the ground and then the biome at the same point), else of a read made here.
static func volcAt(P: WorldPlanet.Planet, px: float, py: float, pz: float) -> float:
	var S: State = P.platesB if P.platesB != null else stateOf(P)
	if S.lx != px or S.ly != py or S.lz != pz:
		ground(P, px, py, pz)
	return S.volc


## The ground at a point of the unit sphere:''')


def climate(s):
    s = rep(s, '''	if h > P.c.mountainAbove:
		P.outF = F_MOUNTAINS
		return WorldPlanet.BIO_MOUNTAINS
	var d: Dictionary = data()
	var cm: Array = climateAt(P, px, py, pz, h)
	var T: float = cm[0]
	var M: float = cm[1]
	var vc: Dictionary = d.volcanic
	var fine: int
	if h >= float(vc.hMin) and WorldPlanet._fbm(P.R, px, py, pz, vc.scale, int(vc.oct), P.seed + int(vc.seed)) > float(vc.above):
		fine = F_VOLCANIC
	elif h >= float(d.highland.h):''', '''	var onB: bool = WorldLand.plateB()   # Research's B plates: their volcanic score makes the volcanic fields, in place of the noise (window 13)
	var bv: bool = onB and WorldPlateB.volcAt(P, px, py, pz) > WorldPlateB.K.volcanic
	if h > P.c.mountainAbove and not bv:
		P.outF = F_MOUNTAINS
		return WorldPlanet.BIO_MOUNTAINS
	var d: Dictionary = data()
	var cm: Array = climateAt(P, px, py, pz, h)
	var T: float = cm[0]
	var M: float = cm[1]
	var vc: Dictionary = d.volcanic
	var fine: int
	if bv and T >= float(d.tempEdges[0]) and h >= float(d.coast.beachH):   # not too cold for it, and not a beach (Research's notCold)
		fine = F_VOLCANIC
	elif h > P.c.mountainAbove:
		fine = F_MOUNTAINS
	elif not onB and h >= float(vc.hMin) and WorldPlanet._fbm(P.R, px, py, pz, vc.scale, int(vc.oct), P.seed + int(vc.seed)) > float(vc.above):
		fine = F_VOLCANIC
	elif h >= float(d.highland.h):''')
    return s


rw(R, 'sim/world/plateb.gd', plateb)
rw(R, 'sim/world/climate.gd', climate)
print('w13 (a) applied')
