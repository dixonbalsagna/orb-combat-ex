"""Window 14 (World, 2026-10-26): rivers behind data/biomes/rivers.json (off).   python mk_r1.py <root>   (root: HEAD plus the window 13, wreck-toss and campaign-route diffs; sim/world/rivers.gd and data/biomes/rivers.json already in it)
 - sim/world/planet.gd: Planet.flow, the flow field a step of the planet job, and the planet's data hash carries rivers.json only while on
 - sim/world/planet_world.gd: a gen 2 ring's rivers are planned after its lakes, cut into the ground and planted as lakes
 - sim/world/epoch.gd: the calm turn plans the new ring's rivers the same way (only where the ring is wholly new)"""
import sys
from mk_wbc_lib import rw, rep
R = sys.argv[1].rstrip('/') + '/'


def planet(s):
    s = rep(s, '''	var grid = null                          # gen 2: the climate grid (WorldClimate.Grid), made when first asked
''', '''	var grid = null                          # gen 2: the climate grid (WorldClimate.Grid), made when first asked
	var flow = null                          # gen 2 with rivers.json on: the drainage of that grid (WorldRivers.Flow), made when first asked
''')
    s = rep(s, '''			P.grid = _grid
			_grid = null
''', '''			P.grid = _grid
			_grid = null
			if WorldRivers.enabled():   # the drainage of the grid (about 100 ms: FLOW_COST units), its own step of the job
				WorldRivers.flowOf(P)
				left -= WorldRivers.FLOW_COST
				if left <= 0:
					return false
''')
    return rep(s, '''		return _cHash + "/g2/" + WorldClimate.dataHash() + "/" + WorldLand.dataHash() + "/" + WorldSites.dataHash()''', '''		return _cHash + "/g2/" + WorldClimate.dataHash() + "/" + WorldLand.dataHash() + "/" + WorldSites.dataHash() + ("/r" + WorldRivers.dataHash() if WorldRivers.enabled() else "")''')


def planet_world(s):
    return rep(s, '''		lakes = WorldLakes.plan(S.base, chords, sl.fine, cols)   # window 5: the valleys of the ring that hold water; trees do not grow in them
		S.trees = WorldLakes.dryTrees(S.trees, lakes, NC)''', '''		lakes = WorldLakes.plan(S.base, chords, sl.fine, cols)   # window 5: the valleys of the ring that hold water; trees do not grow in them
		if WorldRivers.enabled():   # window 14: where the ring crosses a river it is cut into the ground and planted as a narrow shallow lake
			var rsp: Dictionary = specOf(sl.circ)
			if not rsp.is_empty():
				var rv: Array = WorldRivers.plan(P, rsp, S.base, chords, sl.fine, cols, lakes)
				WorldRivers.carve(S.base, rv)
				lakes = lakes + rv
		S.trees = WorldLakes.dryTrees(S.trees, lakes, NC)''')


def epoch(s):
    return rep(s, '''			ep["lakes"] = WorldLakes.onlyNew(WorldLakes.plan(ep.base, ep.chordsAll, ep.fcols, ep.cols), pl.wt)
			ep["trees"] = WorldLakes.dryTrees(ep.trees, ep.lakes, NC)''', '''			ep["lakes"] = WorldLakes.onlyNew(WorldLakes.plan(ep.base, ep.chordsAll, ep.fcols, ep.cols), pl.wt)
			if WorldRivers.enabled():   # window 14: the new ring's rivers, only where the ring is wholly new, cut into its prepared ground
				var rsp: Dictionary = WorldPlanetWorld.specOf(sl.circ)
				if not rsp.is_empty():
					var rv: Array = WorldLakes.onlyNew(WorldRivers.plan(WorldPlanet.make(int(E.seed)), rsp, ep.base, ep.chordsAll, ep.fcols, ep.cols, ep.lakes), pl.wt)
					WorldRivers.carve(ep.base, rv)
					ep["lakes"] = ep.lakes + rv
			ep["trees"] = WorldLakes.dryTrees(ep.trees, ep.lakes, NC)''')


rw(R, 'sim/world/planet.gd', planet)
rw(R, 'sim/world/planet_world.gd', planet_world)
rw(R, 'sim/world/epoch.gd', epoch)
print('rivers hooks applied')
