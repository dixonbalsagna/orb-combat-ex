"""Window 16, campaign_check (World, 2026-10-26): the band in columns, the side story's three steps, the turn frequency row.   python mk_w16c.py <root>"""
import sys
from mk_wbc_lib import rw, rep
R = sys.argv[1].rstrip('/') + '/'


def check(s):
    s = rep(s, '''	var sepCols: int = int(ceil(WorldCampaign.K_SEP_S * speed / COL))''', '''	var sepCols: int = WorldCampaign.K_SEP_C''')
    s = rep(s, '''					if s.flightS < WorldCampaign.K_MIN_S - 1.0e-9 or s.flightS > WorldCampaign.K_MAX_S + 1.0e-9:''', '''					if s.entry < WorldCampaign.K_MIN_C or s.entry > mini(WorldCampaign.K_MAX_C, cols / 2):''')
    s = rep(s, '''		ok(bandOk, "gen %d: every place of columns 1 to 4 is within %.0f to %.0f s of flight of the pair" % [gen, WorldCampaign.K_MIN_S, WorldCampaign.K_MAX_S])
		ok(sepOk, "gen %d: the places of a column are at least %.0f s of flight apart" % [gen, WorldCampaign.K_SEP_S])''', '''		ok(bandOk, "gen %d: every place of columns 1 to 4 is %d to %d columns from the pair (on a Close ring the band ends at the far side)" % [gen, WorldCampaign.K_MIN_C, WorldCampaign.K_MAX_C])
		ok(sepOk, "gen %d: the places of a column are at least %d columns apart" % [gen, WorldCampaign.K_SEP_C])''')
    a = s.index("	# a side story: on some rings")
    b = s.index("	# the planet's wounds: place state only")
    new = '''	# a side story (Game Design rulings 2026-10-26 item 2): a named place in the flight band; else any named place on the ring; else the ring turns to bring one along it; never an unnamed site; if all fail the draw is spent
	var how: Dictionary = {"band": 0, "widened": 0, "turned": 0, "none": 0}
	var sideOk: bool = true
	var tried: int = 0
	var townReach: float = float(P7.c.townReach)
	for nth in range(8):
		for phi in [0.7, 2.0, 3.3, 4.6]:
			var ar: Dictionary = ringThrough(P7, nth, 2400, phi)
			var sd1: Dictionary = WorldCampaign.side(7, 77, 3, ar, 1200, {})
			tried += 1
			if not sd1.ok:
				how.none += 1
				if not (sd1.get("spent", false) and not sd1.has("place")):
					sideOk = false
				continue
			how[sd1.how] += 1
			var ringS: Dictionary = WorldRingPick.ringOfArena(sd1.arena)
			var pp: Array = WorldRingPick.placePoint(P7, int(sd1.place))
			if not (sd1.place >= 0 and vclose(ringS.c, pp, 1.0e-9) and int(sd1.arena.cols) == WorldCampaign.K_SIDE_COLS and sd1.site.settled and not sd1.site.fallen):
				sideOk = false
			var onRing: Dictionary = WorldRingPick.ringOfArena(sd1.ring)
			var reach: float = townReach * P7.rad[int(sd1.place)] if P7.kind[int(sd1.place)] != WorldPlanet.KIND_CITY else float(P7.c.cityReach) * P7.rad[int(sd1.place)]
			if sd1.how != "turned" and absf(WorldPlanet.lateral(P7, WorldRingPick.ringOfArena(ar), pp[0], pp[1], pp[2])) >= reach:
				sideOk = false   # a place on the ring as it is lies on it
			if sd1.how == "band" and (int(sd1.site.entry) < WorldCampaign.K_MIN_C or int(sd1.site.entry) > mini(WorldCampaign.K_MAX_C, 1200)):
				sideOk = false
			if sd1.how == "turned":
				var degOk: bool = sd1.turn != null and WorldCampaign.K_BEAR.has(absf(float(sd1.turn.deg)))
				if not degOk or absf(WorldPlanet.lateral(P7, onRing, pp[0], pp[1], pp[2])) >= reach:
					sideOk = false   # the turned ring holds the place, at one of the data's bearings
			elif sd1.turn != null:
				sideOk = false
	ok(sideOk and how.band + how.widened + how.turned + how.none == tried and how.band >= 1, "a side story's place is always a named city or town with a Close ring round it: of %d rings of planet 7, %d had one in the band, %d widened to any on the ring, %d turned the ring, %d had none (the draw is spent)" % [tried, how.band, how.widened, how.turned, how.none])
	var sdAvoid: Dictionary = {}
	for phi in [0.7, 2.0, 3.3, 4.6]:
		for nth in range(8):
			var ar2: Dictionary = ringThrough(P7, nth, 2400, phi)
			var s0: Dictionary = WorldCampaign.side(7, 77, 3, ar2, 1200, {})
			if s0.ok:
				var s1: Dictionary = WorldCampaign.side(7, 77, 3, ar2, 1200, {"sites": [int(s0.site.arc)]})
				sdAvoid = {"a": s0, "b": s1}
				break
		if not sdAvoid.is_empty():
			break
	var avoidOk: bool = sdAvoid.is_empty() or (not sdAvoid.b.ok) or int(sdAvoid.b.place) != int(sdAvoid.a.place)
	ok(avoidOk, "a side story's place keeps clear of a column's own places")
	# how often the ring turns (rulings 2026-10-26 item 5: 40 to 60% of columns 1 to 4): 6 planets, 2 rings each, the four columns walked on as an episode would
	var turnedN: int = 0
	var colsN: int = 0
	for gen in [1, 2]:
		WorldClimate.useGen(gen)
		for sd in [7, 3, 11, 25, 5, 9]:
			var Pt := WorldPlanet.make(sd)
			for nth in range(2):
				var here: Dictionary = ringThrough(Pt, nth)
				var pcw: int = 1200
				for colw in range(1, 5):
					var rj: Dictionary = WorldCampaign.column(sd, 100 + sd + nth, colw, here, pcw, {})
					colsN += 1
					if rj.turn != null:
						turnedN += 1
					here = rj.start
					pcw = int(rj.pc)
	var share: float = float(turnedN) / float(colsN)
	ok(share >= 0.40 and share <= 0.60, "the ring turns in %.0f%% of %d columns (both generations, 6 planets, 2 rings, columns 1 to 4): Game Design's target is 40 to 60%% (minGain %.2f, bonus %.2f)" % [100.0 * share, colsN, WorldCampaign.K_TURN_GAIN, WorldCampaign.K_TURN_BONUS])
	WorldClimate.useGen(1)
'''
    s = s[:a] + new + s[b:]
    return s


rw(R, 'sim/world/tools/campaign_check.gd', check)
print('w16 campaign_check applied')
