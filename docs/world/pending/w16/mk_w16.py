"""Window 16 (World, 2026-10-26): Game Design rulings-2026-10-26 items 1, 2 and 5 (the campaign route) and Legal's RL-186 with GD's lifts (Wreck Toss).   python mk_w16.py <root>   (root: main plus the rivers and surfacing diffs)
 - data/biomes/campaign.json, sim/world/campaign.gd: the flight band in columns (322 to 806 each way; on a Close ring it ends at the far side, 600), a side story widens to any named place on the ring and then turns the ring
 - tools/schemas/biomes-campaign.schema.json (Tools', granted)"""
import sys, json, collections
from mk_wbc_lib import rw, rep
R = sys.argv[1].rstrip('/') + '/'
OD = collections.OrderedDict


def campaign_json(s):
    s = rep(s, '''  "flight": {
    "speed": 1032.0,
    "minS": 10.0,
    "maxS": 25.0,
    "climaxMaxS": 45.0
  },''', '''  "flight": {
    "speed": 1032.0,
    "minCols": 322,
    "maxCols": 806,
    "climaxCols": 1451
  },''')
    s = rep(s, '''    "sepS": 5.0,
    "jitter"''', '''    "sepCols": 161,
    "jitter"''')
    s = rep(s, '''  "side": {
    "sepS": 3.0,''', '''  "side": {
    "sepCols": 97,''')
    s = rep(s, '''flight: how fast the pair fly between places (units a second: the melee dash, 430 x 2.4, the traversal multiplier left out: with it a lap of the planet is 15 s and 10 to 25 s would be a lap or more), the least and most seconds of flight from the last stage to the near edge of a column's place, and the most for the climax (its home may be farther: the flight is the build-up).''', '''flight: a column's places lie minCols to maxCols columns from the pair, each way (Game Design rulings 2026-10-26 item 1: the band is stated in columns, 322 to 806, the 10 to 25 s of the melee dash, 430 x 2.4 = 1,032 units a second; the speed here only turns columns into the seconds a site reports; on a Close ring the band ends at the far side, 600), and climaxCols is the most for the climax before its flight counts as the build-up.''')
    s = rep(s, '''sepS the least seconds of flight between two of a column's places,''', '''sepCols the least columns between two of a column's places,''')
    s = rep(s, '''side: a side story's place is a standing city or town on the current ring within the usual flight, at least sepS seconds from the column's places; ringCols its own Close ring's length (Game Design size close).''', '''side: a side story's place is a named city or town on the current ring (rulings 2026-10-26 item 2): in the flight band if there is one, else any on the ring, else the ring turns at the episode's end to bring one along it (a campaign turn); never an unnamed site, and if all fail the draw is spent; at least sepCols columns from the column's places; ringCols its own Close ring's length (Game Design size close).''')
    s = rep(s, '''minGain how much better a ring must be than none turned for it to win.''', '''minGain how much better a ring must be than none turned for it to win. Game Design's target (rulings 2026-10-26 item 5): 40 to 60% of columns 1 to 4 turn, minGain raised first, then bonus lowered; campaign_check measures it.''')
    return rep(s, '"minGain": 0.2', '"minGain": 0.45')   # measured by campaign_turns.gd: about 45% of columns 1 to 4 turn (GD: 40 to 60%)


def campaign_gd(s):
    s = rep(s, '''static var K_MIN_S: float = 10.0
static var K_MAX_S: float = 25.0
static var K_CLIMAX_S: float = 45.0
''', '''static var K_MIN_C: int = 322
static var K_MAX_C: int = 806
static var K_CLIMAX_C: int = 1451
''')
    s = rep(s, '''static var K_SEP_S: float = 5.0
''', '''static var K_SEP_C: int = 161
''')
    s = rep(s, '''static var K_SIDE_SEP: float = 3.0
''', '''static var K_SIDE_SEP_C: int = 97
''')
    s = rep(s, '''	if float(fl.speed) <= 0.0 or float(fl.minS) <= 0.0 or float(fl.maxS) <= float(fl.minS) or float(fl.climaxMaxS) < float(fl.maxS):
		_errors.append("campaign.json: flight.speed and minS above 0, maxS above minS, climaxMaxS at least maxS")''', '''	if float(fl.speed) <= 0.0 or int(fl.minCols) < 1 or int(fl.maxCols) <= int(fl.minCols) or int(fl.climaxCols) < int(fl.maxCols):
		_errors.append("campaign.json: flight.speed and minCols above 0, maxCols above minCols, climaxCols at least maxCols")''')
    s = rep(s, '''	K_MIN_S = float(fl.minS)
	K_MAX_S = float(fl.maxS)
	K_CLIMAX_S = float(fl.climaxMaxS)''', '''	K_MIN_C = int(fl.minCols)
	K_MAX_C = int(fl.maxCols)
	K_CLIMAX_C = int(fl.climaxCols)''')
    s = rep(s, '''	K_SEP_S = float(j.sites.sepS)''', '''	K_SEP_C = int(j.sites.sepCols)''')
    s = rep(s, '''	K_SIDE_SEP = float(j.side.sepS)''', '''	K_SIDE_SEP_C = int(j.side.sepCols)''')
    s = rep(s, '''static func _candidates(P: WorldPlanet.Planet, spec: Dictionary, pc: int, minS: float, maxS: float, wear: Dictionary) -> Array:''', '''static func _candidates(P: WorldPlanet.Planet, spec: Dictionary, pc: int, minC: int, maxC: int, wear: Dictionary) -> Array:''')
    s = rep(s, '''	var lo: int = int(ceil(minS * K_SPEED / COL))
	var hi: int = mini(int(floor(maxS * K_SPEED / COL)), cols / 2)''', '''	var lo: int = minC
	var hi: int = mini(maxC, cols / 2)   # on a Close ring the band ends at the far side''')
    s = rep(s, '''		var fs: float = float(entry) * COL / K_SPEED
		if fs < minS or fs > maxS:
			continue''', '''		var fs: float = float(entry) * COL / K_SPEED
		if entry < lo or entry > hi:
			continue''')
    s = rep(s, '''	var sepCols: int = int(ceil(K_SEP_S * K_SPEED / SimConst.COL))
	var pool: Array = []''', '''	var sepCols: int = K_SEP_C
	var pool: Array = []''')
    s = rep(s, '''## minS and maxS (the flight band, seconds; the data's by default).''', '''## minCols and maxCols (the band, columns each way; the data's by default).''')
    s = rep(s, '''	var minS: float = 0.0
	var maxS: float = 0.0
''', '''	var minC: int = 0
	var maxC: int = 0
''')
    s = rep(s, '''		minS = float(opts.get("minS", WorldCampaign.K_MIN_S))
		maxS = float(opts.get("maxS", WorldCampaign.K_MAX_S))''', '''		minC = int(opts.get("minCols", WorldCampaign.K_MIN_C))
		maxC = int(opts.get("maxCols", WorldCampaign.K_MAX_C))''')
    s = rep(s, '''WorldCampaign._candidates(P, ts, mid, minS, maxS, wear)''', '''WorldCampaign._candidates(P, ts, mid, minC, maxC, wear)''')
    s = rep(s, '''	notes.append("the climax: the ring through the pair and place %d, %.1f s of flight%s" % [home, fs, " (the build-up: past the band)" if fs > K_CLIMAX_S else ""])''', '''	notes.append("the climax: the ring through the pair and place %d, %d columns%s" % [home, entry, " (the build-up: past the band)" if entry > K_CLIMAX_C else ""])''')
    s = rep(s, '''"far": fs > K_CLIMAX_S}''', '''"far": entry > K_CLIMAX_C}''')
    a = s.index("## A side story's place (campaign 1.4)")
    b = s.index("# ===================================================================== the planet's wounds")
    side = '''## A side story's place (campaign 1.4; Game Design rulings 2026-10-26 item 2): a named city or town of the planet's places on the ring. First one in the flight band of the pair at column pc; if the ring has
## none there, any named place on the ring (at travel speed even the far side is a short trip); if it has none at all, the ring turns (a campaign turn, outside the fight's four) by the smallest of the data's
## bearings, either way, that brings one along it. Never an unnamed site: the templates read the place's name. If every step fails nothing is offered and the arc's draw is spent (`ok` false, `spent` true).
## At least `side.sepCols` columns from each of the column's places (opts.sites: their arcs, in columns). opts: used (place ids), wear. `arcSeed` and `n` key the draw (the arc's, and the episode's number).
## Returns {ok, how ("band", "widened" or "turned"), site, place, arena (a Close ring round the place, the filler episode's ground), turn (null, or {deg, from}), ring (the arena the place lies on: the
## current ring, or the turned one: the pair's point is its touch-down), pc} or {ok: false, spent: true, why}. The caller asks only on a yes of the run's own draw (H(arc, "side", n)).
static func side(planetSeed: int, arcSeed: int, n: int, arena: Dictionary, pc: int, opts: Dictionary = {}) -> Dictionary:
	var P: WorldPlanet.Planet = WorldPlanet.make(planetSeed)
	var spec: Dictionary = specOf(arena)
	var cols: int = int(spec.cols)
	var wear: Dictionary = opts.get("wear", {})
	var used: Array = opts.get("used", [])
	var avoid: Array = opts.get("sites", [])
	var base: Dictionary = rebased(P, spec, pc)
	var mid: int = cols / 2
	var best = _sidePick(P, base, mid, K_MIN_C, K_MAX_C, arcSeed, n, used, avoid, wear)
	var how: String = "band"
	var turn = null
	var ringSpec: Dictionary = base
	if best == null:
		best = _sidePick(P, base, mid, 1, cols / 2, arcSeed, n, used, avoid, wear)
		how = "widened"
	if best == null:
		for dg in K_BEAR:
			for sg in [1.0, -1.0]:
				if best != null:
					break
				var ts: Dictionary = turnedSpec(P, base, mid, float(dg) * sg)
				var pk = _sidePick(P, ts, mid, 1, cols / 2, arcSeed, n, used, avoid, wear)
				if pk != null:
					best = pk
					how = "turned"
					turn = {"deg": float(dg) * sg, "from": WorldRingPick.arenaOf(base)}
					ringSpec = ts
	if best == null:
		return {"ok": false, "spent": true, "why": "no named city or town on this ring, or on it turned either way"}
	var phi: float = SimRng.keyed(arcSeed, "camp/sidering%d" % n, int(best.place)) * 2.0 * SimMathx.PI
	var rs: Dictionary = WorldRingPick.roundSpec(WorldRingPick.placePoint(P, int(best.place)), K_SIDE_COLS, phi)
	return {"ok": true, "how": how, "site": _publish([best])[0], "place": int(best.place), "arena": WorldRingPick.arenaOf(rs), "turn": turn, "ring": WorldRingPick.arenaOf(ringSpec), "pc": mid}


## The best standing named place of a ring for a side story among those `minC` to `maxC` columns from the pair, clear of the column's own places, or null.
static func _sidePick(P: WorldPlanet.Planet, spec: Dictionary, pc: int, minC: int, maxC: int, arcSeed: int, n: int, used: Array, avoid: Array, wear: Dictionary):
	var cols: int = int(spec.cols)
	var best = null
	var bs: float = -1.0e9
	for c in _candidates(P, spec, pc, minC, maxC, wear):
		if not c.settled or c.fallen or used.has(c.place):
			continue
		var clash: bool = false
		for a in avoid:
			if absi(arcCols(int(a), int(c.arc), cols)) < K_SIDE_SEP_C:
				clash = true
		if clash:
			continue
		var s: float = 1.0 + (SimRng.keyed(arcSeed, "camp/side%d" % n, int(c.key)) - 0.5) * 2.0 * K_JIT + (0.2 if c.kind == "city" else 0.0)
		if s > bs:
			bs = s
			best = c
	return best


'''
    return s[:a] + side + s[b:]


def schema(p):
    j = json.load(open(p, encoding='utf-8'), object_pairs_hook=OD)

    def integer(lo, hi, desc):
        return OD([("type", "integer"), ("minimum", lo), ("maximum", hi), ("description", desc)])
    fl = j['properties']['flight']
    props = OD()
    props['speed'] = fl['properties']['speed']
    props['minCols'] = integer(1, 5000, "The least columns from the pair to a column's place (its near edge), each way.")
    props['maxCols'] = integer(1, 5000, "The most (above minCols: WorldCampaign's load; on a Close ring the band ends at the far side).")
    props['climaxCols'] = integer(1, 20000, "The most for the climax before its flight counts as the build-up.")
    fl['properties'] = props
    fl['required'] = list(props.keys())
    for blk, desc in (('sites', "The least columns between two of a column's places."), ('side', "The least columns between a side story's place and a column's.")):
        old = j['properties'][blk]['properties']
        new = OD()
        for k, v in old.items():
            new['sepCols' if k == 'sepS' else k] = integer(0, 5000, desc) if k == 'sepS' else v
        j['properties'][blk]['properties'] = new
        j['properties'][blk]['required'] = [('sepCols' if k == 'sepS' else k) for k in j['properties'][blk]['required']]
    open(p, 'w', encoding='utf-8', newline='').write(json.dumps(j, indent=2) + '\n')


rw(R, 'data/biomes/campaign.json', campaign_json)
rw(R, 'sim/world/campaign.gd', campaign_gd)
schema(R + 'tools/schemas/biomes-campaign.schema.json')
print('w16 campaign applied')
