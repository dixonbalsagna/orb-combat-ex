"""Water v2 (World, 2026-10-23, Orb's brief via the EP): windows (a) sources and the water table, (b) the fill cue, (c) skim and wade, and the three payoffs of Game Design's 23b row 16, all behind data/biomes/water.json
`enabled` (off: the water module is as it was).   python mk_w10.py <root>   (root: windows 2 to 9)
 - fill.gd (new), water.json (new), fill_check.gd (new)
 - water.gd: touched opens a fill window; step runs fill and wave windows; the flow windows' merge skips them
 - crater.gd: a slam throws the wave (before the fill reacts to the hole)
 - contact.gd: a body in shallow water is waded (no drag, no sink; it still skims); the data hash carries the switch when on
 - hash.gd (Simulation's, one entry): the three events' fields"""
import sys
from mk_wbc_lib import rw, rep
R = sys.argv[1].rstrip('/') + '/'


def water(s):
    s = rep(s, '''	if not S.planetRing.is_empty():
		WorldLakes.refill(S, c0, cols)   # a gen 2 ring's lakes stand flat when their bed is dug
''', '''	if not S.planetRing.is_empty():
		WorldLakes.refill(S, c0, cols)   # a gen 2 ring's lakes stand flat when their bed is dug
	if WorldFill.on():
		WorldFill.open(S, c0, cols)   # water v2: a hole dug where water would come fills (its own windows)
''')
    s = rep(s, '''	for w in S.waterWin:
		var dc: int = absi(colDelta(c0, w[0]))''', '''	for w in S.waterWin:
		if w.size() > 4:
			continue   # a fill or wave window (WorldFill) is not a flow window
		var dc: int = absi(colDelta(c0, w[0]))''')
    s = rep(s, '''		var w: Array = S.waterWin[wi]
		var lo: int = w[0] - w[1]''', '''		var w: Array = S.waterWin[wi]
		if w.size() > 4:
			if WorldFill.stepWindow(S, w):
				S.waterWin.remove_at(wi)
			else:
				wi += 1
			continue
		var lo: int = w[0] - w[1]''')
    return s


def crater(s):
    return rep(s, '''	WorldTerrain.lowRefresh(S, c0, cols)
	WorldWater.touched(S, c0, cols, minG)
	return rec''', '''	WorldTerrain.lowRefresh(S, c0, cols)
	if kind == "impact":
		WorldFill.slam(S, xw, E)   # a slam into water already standing throws the wave (before the fill reacts to this hole)
	WorldWater.touched(S, c0, cols, minG)
	return rec''')


def contact(s):
    s = rep(s, '''	if inW:
		b.vy += grav   # water holds him up''', '''	if inW and not WorldFill.wading(S, b.x):   # shallow water is waded: no drag, no sink (water v2; he still skimmed above)
		b.vy += grav   # water holds him up''')
    s = rep(s, '''	if skateOn():
		h.text("skate")''', '''	if WorldFill.on():
		h.text("biomes.water")
		FighterData._canon(h, WorldFill.parsed())   # water v2's switch, on: a replay must know
	if skateOn():
		h.text("skate")''') if 'h.text("skate")' in s else rep(s, '''	if skateOn():
		h.text("biomes.skate")''', '''	if WorldFill.on():
		h.text("biomes.water")
		FighterData._canon(h, WorldFill.parsed())   # water v2's switch, on: a replay must know
	if skateOn():
		h.text("biomes.skate")''')
    return s


def hash_(s):
    return rep(s, '''	"arena_turn": ["n", "x", "amount", "k"],''', '''	"arena_turn": ["n", "x", "amount", "k"], "water_fill": ["x", "y", "n", "r", "spd", "k", "amount", "dur", "cause"], "water_wave": ["x", "y", "n", "r", "spd", "amount", "dur"], "water_douse": ["x", "w", "n"],''')


rw(R, 'sim/world/water.gd', water)
rw(R, 'sim/world/crater.gd', crater)
rw(R, 'sim/world/contact.gd', contact)
rw(R, 'sim/core/hash.gd', hash_)
print('w10 applied')
