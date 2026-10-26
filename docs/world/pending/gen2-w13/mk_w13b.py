"""Window 13 (b) (World, 2026-10-25): the climate on B plates.   python mk_w13b.py <root>   (root: main plus windows 9 to 12 and 13 (a))
B's ground is taller than window 3's (ranges to 8,000 units, the 93rd percentile of land at about 3,200 against window 3's 3,500 but its tail twice as long), so the stored mountain line (3,200) and the highland line (2,300) turned 15% of the
non-ice land into rock where Research's own climate (alpine only where it is also cold) gives about 6%. With land.json's b on, climate.json's `b` block moves the two lines: mountains above `mountainAbove` and highland above `highlandH`.
 - data/biomes/climate.json: b {mountainAbove, highlandH}; tools/schemas/biomes-climate.schema.json: the same (Tools', granted)
 - sim/world/planet.gd: a gen 2 planet made with B on takes b.mountainAbove over the stored one
 - sim/world/climate.gd: plain() reads b.highlandH for the highland line with B on"""
import sys, json
from mk_wbc_lib import rw, rep
R = sys.argv[1].rstrip('/') + '/'


def climate_json(s):
    return rep(s, '''  "highland": {
    "h": 2300.0
  },''', '''  "highland": {
    "h": 2300.0
  },
  "b": {
    "mountainAbove": 4200.0,
    "highlandH": 3000.0
  },''')


def schema(s):
    s = rep(s, '''    "highland",
    "volcanic",''', '''    "highland",
    "b",
    "volcanic",''') if '"highland",\n    "volcanic",' in s else s
    return s


def planet_gd(s):
    return rep(s, '''		for k in WorldClimate.data().planet:
			P.c[k] = WorldClimate.data().planet[k]
''', '''		for k in WorldClimate.data().planet:
			P.c[k] = WorldClimate.data().planet[k]
		if WorldLand.plateB():   # Research's B plates make taller ground: the mountain line moves up (climate.json b, window 13)
			P.c["mountainAbove"] = float(WorldClimate.data().b.mountainAbove)
''')


def climate_gd(s):
    return rep(s, '''	elif h >= float(d.highland.h):''', '''	elif h >= (float(d.b.highlandH) if onB else float(d.highland.h)):''')


rw(R, 'data/biomes/climate.json', climate_json)
rw(R, 'sim/world/planet.gd', planet_gd)
rw(R, 'sim/world/climate.gd', climate_gd)
p = R + 'tools/schemas/biomes-climate.schema.json'
j = json.load(open(p, encoding='utf-8'))
j['required'].insert(j['required'].index('highland') + 1, 'b')
props = {}
for k, v in j['properties'].items():
    props[k] = v
    if k == 'highland':
        props['b'] = {"type": "object", "required": ["mountainAbove", "highlandH"], "additionalProperties": False, "description": "With land.json's b on (Research's B plates, window 13): the lines B's taller ground moves.",
                      "properties": {"mountainAbove": {"type": "number", "minimum": 1000, "maximum": 12000, "description": "Land above this is mountains (the stored planet's is 3,200)."},
                                     "highlandH": {"type": "number", "minimum": 100, "maximum": 12000, "description": "Land from this height is rocky highland."}}}
j['properties'] = props
open(p, 'w', encoding='utf-8', newline='').write(json.dumps(j, indent=2) + '\n')
print('w13 (b) applied')
