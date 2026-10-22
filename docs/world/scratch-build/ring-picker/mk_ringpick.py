"""Shifting arena, window 4: the ring picker (World, scratch, parked; docs/world/shifting-arena-design.md section 5).
python mk_ringpick.py <root> <ringpick.gd>     (root: HEAD with windows 0 and 1 applied)
 - sim/world/ringpick.gd (WorldRingPick), data/biomes/rings.json and its schema
 - WorldPlanet.sliceRing: a slice of an explicit ring (axis, touch-down), memoised outside the state
 - setup.arena may name its ring: {"cols", "c": [hex x3], "t": [hex x3]}; planet_world reads it
 - Tools' lines: a rule in map.json and three invalid cases (the same commit as the schema)"""
import sys, shutil, json, collections
from mk_wbc_lib import rw, rep
OD = collections.OrderedDict
R = sys.argv[1].rstrip('/') + '/'
shutil.copyfile(sys.argv[2], R + 'sim/world/ringpick.gd')

d = OD([("schema", "biomes.rings/1"),
        ("_about", "The ring picker's numbers (docs/world/shifting-arena-design.md window 4; WorldRingPick). sizes: the columns of Game Design's three sizes (Close 38,400 units, Half 76,800, Whole 153,600). minimum: what a ring must hold by size (standing cities and towns, kinds of ground of at least biomeShare of the ring, and the share that is land). candidates: how many rings are tried for a claim at a size. stride: columns between the coarse read's samples. ref: the share of the ring (or the count) at which a claim's suit counts in full. mustAt: the least value of a must-cross feature. avoidWeight: how much of an avoided feature's value comes off the score. homeBonus: added when the ring holds the claim's home place. coastRef: coast crossings (water to land and back) that count as a full coast. The claims themselves are Narrative's (docs/narrative/opponent_grounds.json) and are passed in; features the planet function cannot see are proxies (WorldRingPick.featureValue)."),
        ("sizes", OD([("close", 1200), ("half", 2400), ("whole", 4800)])),
        ("minimum", OD([("close", OD([("cities", 1), ("towns", 0), ("biomes", 2), ("land", 0.4)])), ("half", OD([("cities", 1), ("towns", 2), ("biomes", 2), ("land", 0.5)])), ("whole", OD([("cities", 2), ("towns", 3), ("biomes", 3), ("land", 0.5)]))])),
        ("candidates", OD([("close", 48), ("half", 48), ("whole", 32)])),
        ("stride", 8), ("biomeShare", 0.05), ("ref", 0.25), ("mustAt", 0.2), ("avoidWeight", 0.5), ("homeBonus", 0.25), ("coastRef", 2)])
open(R + 'data/biomes/rings.json', 'w', encoding='utf-8', newline='').write(json.dumps(d, indent=2) + '\n')


def num(lo, hi, desc): return OD([("type", "number"), ("minimum", lo), ("maximum", hi), ("description", desc)])
def integer(lo, hi, desc): return OD([("type", "integer"), ("minimum", lo), ("maximum", hi), ("description", desc)])
def sizes3(item, desc): return OD([("type", "object"), ("required", ["close", "half", "whole"]), ("additionalProperties", False), ("properties", OD([(k, item) for k in ["close", "half", "whole"]])), ("description", desc)])


minimum = OD([("type", "object"), ("required", ["cities", "towns", "biomes", "land"]), ("additionalProperties", False), ("properties", OD([
    ("cities", integer(0, 20, "Standing cities the ring holds.")), ("towns", integer(0, 30, "Standing towns the ring holds.")),
    ("biomes", integer(0, 7, "Kinds of ground of at least biomeShare of the ring.")), ("land", num(0, 1, "The share of the ring that is not water."))]))])
sch = OD([("$schema", "https://json-schema.org/draft/2020-12/schema"), ("$id", "meridian/biomes-rings"), ("title", "biomes.rings/1"),
          ("description", "data/biomes/rings.json: the ring picker's numbers (docs/world/shifting-arena-design.md window 4; WorldRingPick): the three sizes in columns, the minimum a ring holds by size, how many candidates are tried, and the scoring weights. Every key required. Version field: schema. Policy: closed except keys starting with an underscore."),
          ("type", "object"), ("required", ["schema", "sizes", "minimum", "candidates", "stride", "biomeShare", "ref", "mustAt", "avoidWeight", "homeBonus", "coastRef"]),
          ("properties", OD([("schema", OD([("const", "biomes.rings/1")])), ("_about", OD([("type", "string")])),
                             ("sizes", sizes3(OD([("type", "integer"), ("minimum", 600), ("maximum", 4800), ("multipleOf", 8), ("description", "The ring's columns (a column is 32 units of arc), a multiple of 8: the ground's largest stride.")]), "Game Design's three sizes in columns: close 1,200, half 2,400, whole 4,800.")),
                             ("minimum", sizes3(minimum, "What a ring of each size must hold.")),
                             ("candidates", sizes3(integer(1, 400, "Rings tried."), "How many candidate rings are tried for a claim at each size.")),
                             ("stride", integer(1, 64, "Columns between the coarse read's samples.")),
                             ("biomeShare", num(0, 1, "The share of a ring a kind of ground needs to count as seen.")),
                             ("ref", num(0.01, 1, "The share (or count) at which a suit counts in full.")),
                             ("mustAt", num(0, 1, "The least value a must-cross feature may have.")),
                             ("avoidWeight", num(0, 2, "How much of an avoided feature's value comes off the score.")),
                             ("homeBonus", num(0, 2, "Added to the score when the ring holds the claim's home place.")),
                             ("coastRef", num(0.5, 20, "Coast crossings that count as a full coast."))])),
          ("additionalProperties", False)])
open(R + 'tools/schemas/biomes-rings.schema.json', 'w', encoding='utf-8', newline='').write(json.dumps(sch, indent=2) + '\n')


def planet(s):
    return rep(s, '''## A hash of what the read produced''', '''## The slice of an explicit ring (WorldRingPick: an axis, the columns, a touch-down), memoised outside the state like sliceFor's. The ring is the arena's, so its columns are SimConst.NC.
static func sliceRing(seed: int, ring: Dictionary, standing: PackedByteArray = PackedByteArray()) -> Slice:
	var key: String = "ring/%d/%s/%s/%s/%d" % [seed, str(ring.c), str(ring.u), str(standing.hex_encode()), SimConst.NC]
	if _slices.has(key):
		return _slices[key]
	var P: Planet = make(seed)
	var S: Slice = readSlice(P, ring, ring.u, standing)
	if _slices.size() > 4:
		_slices.clear()
	_slices[key] = S
	return S


## A hash of what the read produced''')


def planet_world(s):
    return rep(s, '''	var sl: WorldPlanet.Slice = WorldPlanet.sliceFor(seed, touch, PackedByteArray(), false, int(arena.get("side", 1)) if arena is Dictionary else 1)''', '''	var ring: Dictionary = WorldRingPick.ringOfArena(arena) if arena is Dictionary else {}
	var sl: WorldPlanet.Slice = WorldPlanet.sliceRing(seed, ring) if not ring.is_empty() else WorldPlanet.sliceFor(seed, touch, PackedByteArray(), false, int(arena.get("side", 1)) if arena is Dictionary else 1)''')


def mapjson(s):
    a = '''    {
      "match": "data/biomes/collateral.json",
      "schema": "biomes-collateral.schema.json"
    },
'''
    return rep(s, a, a + '''    {
      "match": "data/biomes/rings.json",
      "schema": "biomes-rings.schema.json"
    },
''')


CASES = '''    {
      "id": "rings-schema-version",
      "schema": "biomes-rings.schema.json",
      "mutate": [
        {
          "file": "data/biomes/rings.json",
          "set": {
            "/schema": "biomes.rings/2"
          }
        }
      ],
      "expect": {
        "rule": "const",
        "pointer": "/schema"
      }
    },
    {
      "id": "rings-size-too-small",
      "schema": "biomes-rings.schema.json",
      "mutate": [
        {
          "file": "data/biomes/rings.json",
          "set": {
            "/sizes/close": 100
          }
        }
      ],
      "expect": {
        "rule": "minimum",
        "pointer": "/sizes/close"
      }
    },
    {
      "id": "rings-size-not-multiple-of-8",
      "schema": "biomes-rings.schema.json",
      "mutate": [
        {
          "file": "data/biomes/rings.json",
          "set": {
            "/sizes/half": 2404
          }
        }
      ],
      "expect": {
        "rule": "multipleOf",
        "pointer": "/sizes/half"
      }
    },
    {
      "id": "rings-minimum-land-over-one",
      "schema": "biomes-rings.schema.json",
      "mutate": [
        {
          "file": "data/biomes/rings.json",
          "set": {
            "/minimum/half/land": 1.5
          }
        }
      ],
      "expect": {
        "rule": "maximum",
        "pointer": "/minimum/half/land"
      }
    },
'''


def cases(s):
    i = s.rindex('"id": "collateral-')
    j = s.index('\n    {\n      "id": "', i)
    return s[:j + 1] + CASES + s[j + 1:]


rw(R, 'sim/world/planet.gd', planet)
rw(R, 'sim/world/planet_world.gd', planet_world)
rw(R, 'tools/schemas/map.json', mapjson)
rw(R, 'tools/fixtures/cases.json', cases)
print('ring picker applied')
