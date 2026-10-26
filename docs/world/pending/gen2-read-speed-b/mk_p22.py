"""Window 20, second add-on (World, 2026-10-26): Research's B plates made in steps.   python mk_p22.py <root>   (root: main + gen2-read-speed + its grant_sim_load.py)
 - sim/world/plateb.gd: WorldPlateB._make is _makeBegin (the cells and plates), _makeArea (the 2,000 area points, 39 of its 46 ms: a few at a time) and _makeEnd (the rest; the land share's order statistic by a native
   sort of the values, not a comparator sort of pairs: the same value whatever the order of ties); stateOf is the three run to the end; WorldPlateB.step(P, units) makes P's plates a slice at a time
 - sim/world/planet.gd: Planet.platesBJob, the stepped make's state"""
import sys
from mk_wbc_lib import rw, rep
R = sys.argv[1].rstrip('/') + '/'


def plateb(s):
    a = s.index("static func _make(seed: int, R: float) -> State:")
    b = s.index("\treturn S\n", a) + len("\treturn S\n")
    orig = s[a:b]
    hm = "\tfor k in range(Pm.areaPts):\n\t\tvar p: Array = _randUnit(seed, Pm.sArea, k)\n"
    i1 = orig.index(hm)
    head = orig[len("static func _make(seed: int, R: float) -> State:\n"):i1]
    i2 = orig.index("\tvar rank: Array = []\n")
    body = orig[i1 + len(hm):i2]
    tail = orig[i2:]
    old = '''	var cvs: Array = []
	for k in range(Pm.areaPts):
		cvs.append([cn[k] + pbias[under[k]], k])
	cvs.sort_custom(_cmpDesc)
	var lift: float = -float(cvs[int(floor(Pm.landShare * float(Pm.areaPts)))][0])
'''
    new = '''	var cvs := PackedFloat64Array()   # the land share's order statistic is the same value whatever the order of ties: a native sort of the values, not a comparator sort of pairs (5 ms)
	for k in range(Pm.areaPts):
		cvs.append(cn[k] + pbias[under[k]])
	cvs.sort()
	var lift: float = -float(cvs[Pm.areaPts - 1 - int(floor(Pm.landShare * float(Pm.areaPts)))])
'''
    assert tail.count(old) == 1
    tail = tail.replace(old, new)
    code = '''static func _make(seed: int, R: float) -> State:
	var ctx: Dictionary = _makeBegin(seed, R)
	_makeArea(ctx, 1 << 40)
	return _makeEnd(ctx)


## The plates' cells and drifts (under a millisecond): the state the area sample and the end go on from.
static func _makeBegin(seed: int, R: float) -> Dictionary:
''' + head + '''	return {"seed": seed, "R": R, "c": c, "plate": plate, "pw": pw, "area": area, "under": under, "cn": cn, "k": 0}


## Up to n more of the area sample's points (a point is about 20 us: 39 of the make's 46 ms are its 2,000); true when all are read.
static func _makeArea(ctx: Dictionary, n: int) -> bool:
	var Pm: Prm = K
	var seed: int = ctx.seed
	var R: float = ctx.R
	var nc: int = Pm.cells
	var c: Array = ctx.c
	var plate: Array = ctx.plate
	var area: Array = ctx.area
	var under: Array = ctx.under
	var cn: Array = ctx.cn
	var last: int = mini(Pm.areaPts, int(ctx.k) + n)
	for k in range(int(ctx.k), last):
		var p: Array = _randUnit(seed, Pm.sArea, k)
''' + body + '''	ctx.k = last
	return last >= Pm.areaPts


## The rest of the make (about a millisecond): the plates' types, the land share, the hotspots, the pair table, the state.
static func _makeEnd(ctx: Dictionary) -> State:
	var Pm: Prm = K
	var seed: int = ctx.seed
	var nc: int = Pm.cells
	var c: Array = ctx.c
	var plate: Array = ctx.plate
	var pw: Array = ctx.pw
	var area: Array = ctx.area
	var under: Array = ctx.under
	var cn: Array = ctx.cn
''' + tail + '''

## Makes P's B plates a slice at a time (a host's load, SimPlanetLoad): `units` of about 20 us (an area point is one; the start and the end are 30 and 50). True when P.platesB is made.
static func step(P: WorldPlanet.Planet, units: int) -> bool:
	if P.platesB != null:
		return true
	if not _loaded:
		_load()
	var left: int = units
	var ctx = P.platesBJob
	if ctx == null:
		ctx = _makeBegin(P.seed, P.R)
		P.platesBJob = ctx
		left -= 30
	if not _makeArea(ctx, maxi(1, left)):
		return false
	P.platesB = _makeEnd(ctx)
	P.platesBJob = null
	return true
'''
    return s[:a] + code + s[b:]


def planet(s):
    s = rep(s, '''const TRY_U_SCORE: int = 8
''', '''const TRY_U_SCORE: int = 8
## With the B plates on a try is dearer (measured 119, 200 and 649 us a try: 6, 10 and 32 units).
const TRY_B_H: int = 6
const TRY_B_GAP: int = 4
const TRY_B_SCORE: int = 22
''')
    s = rep(s, '''	var spent: int = 0
	var best = ts.best
''', '''	var spent: int = 0
	var uH: int = TRY_U_H
	var uG: int = TRY_U_GAP
	var uS: int = TRY_U_SCORE
	if P.gen >= 2 and WorldLand.plateB():
		uH = TRY_B_H
		uG = TRY_B_GAP
		uS = TRY_B_SCORE
	var best = ts.best
''')
    s = rep(s, "\t\tspent += TRY_U_H\n", "\t\tspent += uH\n")
    s = rep(s, "\t\tspent += TRY_U_GAP\n", "\t\tspent += uG\n")
    s = rep(s, "\t\t\tspent += TRY_U_SCORE\n", "\t\t\tspent += uS\n")
    s = rep(s, '''		var left: int = budget
		if _grid != null:
			var before: int = _grid.spent
''', '''		var left: int = budget
		if P.gen >= 2 and WorldLand.plateB() and P.platesB == null:   # Research's B plates (46 ms), a slice at a time: the first ground read would make them in one piece
			if not WorldPlateB.step(P, left) or budget < (1 << 30):
				return false
		if _grid != null:
			var before: int = _grid.spent
''')
    return rep(s, '''	var platesB = null                       # gen 2 with land.json's b on: the B plates (WorldPlateB.State), made when first asked
''', '''	var platesB = null                       # gen 2 with land.json's b on: the B plates (WorldPlateB.State), made when first asked
	var platesBJob = null                    # their make in steps (WorldPlateB.step): the state it has reached
''')


def climate(s):
    s = rep(s, "\t\t\tvar last: int = mini(total, cell + n)\n", "\t\t\tvar cu: int = 3 if WorldLand.plateB() else 1   # a cell on the B plates' ground costs about 65 us, on the stored continents' about 20\n\t\t\tvar last: int = mini(total, cell + maxi(1, n / cu))\n")
    s = rep(s, "\t\t\tleft -= last - cell\n\t\t\tspent += last - cell\n\t\t\tcell = last\n", "\t\t\tleft -= (last - cell) * cu\n\t\t\tspent += (last - cell) * cu\n\t\t\tcell = last\n")
    return s


rw(R, 'sim/world/climate.gd', climate)
rw(R, 'sim/world/plateb.gd', plateb)
rw(R, 'sim/world/planet.gd', planet)
print('p22 applied')
