"""Window 16, the Wreck Toss half (World, 2026-10-26): GD's lifts and Legal's RL-186.   python mk_w16b.py <root>
 - data/biomes/wrecks.json: tierLift [2, 6, 16, 57]
 - sim/world/wrecks.gd: livingNear counts any living civilian within 3 bh of the wreck's edge, in a building or in the open (the people a district flight has put on the street count while it runs)
 - sim/world/tools/wrecks_check.gd: a civilian in the street, a flight in progress, fighters and partners not counted"""
import sys
from mk_wbc_lib import rw, rep
R = sys.argv[1].rstrip('/') + '/'


def wrecks_json(s):
    s = rep(s, '''    0.8,
    2.0,
    5.0,
    14.0''', '''    2.0,
    6.0,
    16.0,
    57.0''')
    s = rep(s, '''tierLift: the heaviest wreck each tier (1 to 4) lifts, in the same unit: Game Design and Combat's numbers to confirm; Encounter may pass its own.''', '''tierLift: the heaviest wreck each tier (1 to 4) lifts, in the same unit (Game Design's, rulings 2026-10-26: 2, 6, 16, 57); Encounter may pass its own.''')
    return rep(s, '''nearBh: no living civilian stands in a building within this many body heights of the wreck's edge (people are people in standing buildings; fighters are not counted unless fighters is true).''', '''nearBh: no living civilian is within this many body heights of the wreck's edge, indoors or in the open (Legal RL-186: the people in the standing buildings, whose figures stand on their street side, and the people a district flight has put on the street while it runs; fighters, partners and henchmen are combatants and are not counted unless fighters is true).''')


def wrecks_gd(s):
    a = s.index("## The living civilians near building b's wreck")
    b = s.index("## The distance from the point (x, y, z) to the wreck's box")
    new = '''## The living civilians near building b's wreck (Legal RL-186: any living civilian within `nearBh` of the wreck's edge, in a building or in the open): the people in the standing buildings whose edge is within it (the
## sim holds people as counts per building and Rendering draws them on the building's street side, within its x extent, so the street in front of a building is the building's), and the people a district flight is
## putting on the street (WorldCollateral: after a heavy event, while the budget is spent, the buildings within EVAC_R of it empty at EVAC_RATE for EVAC_ACTIVE_S): while it runs, those who are still to leave
## within reach of the wreck count. With the data's `fighters` set, a fighter within that distance counts as one more (the default: no, they are combatants).
static func livingNear(S: SimState, b) -> float:
	if not _loaded:
		_load()
	var r: float = K_NEAR * BH
	var s: float = 0.0
	for bi in WorldStructures.near(S, b.x, r + b.w * 0.5):
		var o = S.buildings[bi]
		if o == b or not o.alive or o.popAlive <= 0.0:
			continue
		var gap: float = absf(SimWrap.sdx(b.x, o.x)) - (b.w + o.w) * 0.5
		if gap < r:
			s += o.popAlive
	s += _fleeingNear(S, b, r)
	if K_FIGHTERS:
		for f in S.fighters:
			if absf(SimWrap.sdx(b.x, f.x)) - b.w * 0.5 < r:
				s += 1.0
	return s


## The people in a district flight that is running, if the wreck is within reach of where they would be: the flight's buildings are those within EVAC_R of the latest heavy event, and its people are on the
## street from the moment they leave a building (WorldCollateral.flight) until they are sheltered or gone, which the sim does not follow person by person, so while the flight runs those who may still leave count.
static func _fleeingNear(S: SimState, b, r: float) -> float:
	var w = S.world
	if w.heavyX < 0.0 or S.T - w.heavyT > WorldCollateral.EVAC_ACTIVE_S or not WorldCollateral.isOver(S):
		return 0.0
	if absf(SimWrap.sdx(b.x, w.heavyX)) - b.w * 0.5 > WorldCollateral.EVAC_R + r:
		return 0.0
	var n: float = 0.0
	for bi in WorldStructures.near(S, w.heavyX, WorldCollateral.EVAC_R):
		var o = S.buildings[bi]
		if not o.alive or o.popAlive <= 0.0:
			continue
		if absf(SimWrap.sdx(w.heavyX, o.x)) - o.w * 0.5 > WorldCollateral.EVAC_R:
			continue
		n += minf(o.popAlive, maxf(0.0, WorldCollateral.FLIGHT_MAX * o.pop - o.fled))
	return n


'''
    s = s[:a] + new + s[b:]
    s = rep(s, '''## half: when the hurled wreck lands, the scrap damages structures by the brunt ladder's tier factor, and the wreck is spent.''', '''## half: when the hurled wreck lands, the scrap damages structures by the brunt ladder's tier factor, and the wreck is spent.''') if False else s
    return s


def wrecks_check(s):
    s = rep(s, '''	# an occupied wreck is never offered (made by hand: the game has none)''', '''	# Legal RL-186: a civilian in the open counts as much as one indoors. A district flight that is running puts the people of the buildings near a heavy event on the street: while it runs, a wreck within reach of it is not offered
	for s in saved:
		s[0].popAlive = 0.0   # (nobody indoors beside the wreck for what follows)
	var wkeep: Array = []
	for o in S.buildings:
		if o != b and o.alive and absf(SimWrap.sdx(b.x + 1500.0, o.x)) < WorldCollateral.EVAC_R and o.popAlive > 0.0 and absf(SimWrap.sdx(b.x, o.x)) - (b.w + o.w) * 0.5 >= WorldWrecks.K_NEAR * WorldWrecks.BH + 1.0:
			wkeep.append(o)
	S.world.heavyX = b.x + 1500.0
	S.world.heavyT = S.T
	S.world.cbSum = 1.0e9   # the collateral window is spent: the district flight runs
	var fleeing: Array = WorldWrecks.within(S, f.x, f.y, f.z, top)
	ok(not wkeep.is_empty() and WorldWrecks.pick(S, f.x, f.y, f.z, top).is_empty() and fleeing[0].why == "living", "RL-186: while a district flight runs (people of %d building(s) still to leave, on the street) the wreck is not offered, though no building beside it holds anyone" % wkeep.size())
	S.T += WorldCollateral.EVAC_ACTIVE_S + 1.0
	ok(not WorldWrecks.pick(S, f.x, f.y, f.z, top).is_empty(), "when the flight is over, it is offered again")
	# fighters, a partner and henchmen are combatants: not counted, whoever stands at the wreck
	S.fighters[1].x = b.x
	S.fighters[1].y = f.y
	ok(not WorldWrecks.pick(S, f.x, f.y, f.z, top).is_empty(), "a fighter standing at the wreck does not refuse it (RL-186: combatants are not counted)")
	# an occupied wreck is never offered (made by hand: the game has none)''')
    s = rep(s, '''	for s in saved:
		s[0].popAlive = s[1]
		if s[1] > 0.0:
			gotLiving = true''', '''	for s in saved:
		s[0].popAlive = s[1]
		if s[1] > 0.0:
			gotLiving = true''') if False else s
    return s


rw(R, 'data/biomes/wrecks.json', wrecks_json)
rw(R, 'sim/world/wrecks.gd', wrecks_gd)
rw(R, 'sim/world/tools/wrecks_check.gd', wrecks_check)
print('w16 wrecks applied')
