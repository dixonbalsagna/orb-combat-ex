"""Window 16, additions from Combat's check (World, 2026-10-26).   python mk_w16d.py <root>
 (1) the wreck's mass is wreckMass (cubic body heights) in data, the query's return and the doc, never compared with the car classes' mass (bike 1, sedan 3, van 4, bus 8)
 (2) data/biomes/props.json throwTier follows the throwables ruling (rule-of-cool.md: tier 1 lifts a van, tier 2 a bus): bike 1, sedan 1, van 1, bus 2; props_check reads the ruling, not Art's old throw_tier"""
import sys, json, collections
from mk_wbc_lib import rw, rep
R = sys.argv[1].rstrip('/') + '/'
OD = collections.OrderedDict


def wrecks_json(s):
    s = rep(s, '"minMass"', '"minWreckMass"')
    s = rep(s, '"massRef"', '"wreckMassRef"')
    s = rep(s, "fill: a wreck's mass is this share of its building's volume, in cubic body heights", "fill: a wreck's wreckMass is this share of its building's volume, in cubic body heights (wreckMass is the wreck's own unit, not the car classes' mass: bike 1, sedan 3, van 4, bus 8 are Art's classes)")
    s = rep(s, "minMass: a smaller wreck", "minWreckMass: a lighter wreck")
    s = rep(s, "the heaviest wreck each tier (1 to 4) lifts, in the same unit", "the heaviest wreckMass each tier (1 to 4) lifts")
    return s


def wrecks_gd(s):
    s = rep(s, '"fill", "minMass", "tierLift", "burst"', '"fill", "minWreckMass", "tierLift", "burst"')
    s = rep(s, "float(b.massRef) <= 0.0", "float(b.wreckMassRef) <= 0.0")
    s = rep(s, "wrecks.json: reachBh, fill and massRef above 0", "wrecks.json: reachBh, fill and wreckMassRef above 0")
    s = rep(s, "K_MIN = float(j.minMass)", "K_MIN = float(j.minWreckMass)")
    s = rep(s, "K_B_REF = float(b.massRef)", "K_B_REF = float(b.wreckMassRef)")
    s = rep(s, '''## The mass of a fallen building's wreck: its box in cubic body heights, times the data's fill.''', '''## The wreckMass of a fallen building's wreck: its box in cubic body heights, times the data's fill. The wreck's own unit: not the car classes' mass (bike 1, sedan 3, van 4, bus 8), which are Art's.''')
    s = rep(s, '''		out.append({"id": bi, "mass": m, "dist": d, "ok": why == "", "why": why})''', '''		out.append({"id": bi, "wreckMass": m, "dist": d, "ok": why == "", "why": why})''')
    s = rep(s, '''			return {"id": c.id, "mass": c.mass, "x": b.x''', '''			return {"id": c.id, "wreckMass": c.wreckMass, "x": b.x''')
    return s


def wrecks_check(s):
    return s.replace('pk.mass', 'pk.wreckMass').replace('pk.get("mass", 0.0)', 'pk.get("wreckMass", 0.0)').replace('c.mass', 'c.wreckMass')


def props_json(s):
    s = rep(s, '"throwTier": 2,', '"throwTier": 1,')
    s = rep(s, '"throwTier": 3,', '"throwTier": 1,')
    return rep(s, '"throwTier": 4,', '"throwTier": 2,')


def props_check(s):
    return rep(s, '''		if int(cl[k].length) != int(v.length) or int(cl[k].height) != int(v.height) or int(cl[k].mass) != int(v.mass_class) or int(cl[k].throwTier) != int(v.throw_tier):
			same = false
	ok(same, "each box, mass class and first tier is Art's (data/art/vehicles.json)")''', '''		if int(cl[k].length) != int(v.length) or int(cl[k].height) != int(v.height) or int(cl[k].mass) != int(v.mass_class):
			same = false
	ok(same, "each box and mass class is Art's (data/art/vehicles.json)")
	# the first tier that lifts a car is the throwables ruling's (docs/design/rule-of-cool.md: tier 1 lifts a van, tier 2 a bus), not Art's throw_tier (1, 2, 3, 4, still in vehicles.json)
	var tiers: Array = []
	for k in cl:
		tiers.append(int(cl[k].throwTier))
	ok(tiers == [1, 1, 1, 2], "each class's first throw tier is the throwables ruling's: bike, sedan and van 1, bus 2 (%s)" % str(tiers))''')


rw(R, 'data/biomes/wrecks.json', wrecks_json)
rw(R, 'sim/world/wrecks.gd', wrecks_gd)
rw(R, 'sim/world/tools/wrecks_check.gd', wrecks_check)
rw(R, 'data/biomes/props.json', props_json)
rw(R, 'sim/world/tools/props_check.gd', props_check)
p = R + 'tools/schemas/biomes-wrecks.schema.json'
j = json.load(open(p, encoding='utf-8'), object_pairs_hook=OD)


def renamed(od, a, b):
    return OD((b if k == a else k, v) for k, v in od.items())


j['properties'] = renamed(j['properties'], 'minMass', 'minWreckMass')
j['required'] = ['minWreckMass' if k == 'minMass' else k for k in j['required']]
bu = j['properties']['burst']
bu['properties'] = renamed(bu['properties'], 'massRef', 'wreckMassRef')
bu['required'] = ['wreckMassRef' if k == 'massRef' else k for k in bu['required']]
open(p, 'w', encoding='utf-8', newline='').write(json.dumps(j, indent=2) + '\n')
print('w16 additions applied')
