"""The rivers' Tools files (granted on Orb's word): the schema for data/biomes/rivers.json, its rule in tools/schemas/map.json, three invalid cases.   python mk_rivers_tools.py <root>"""
import sys, json, collections
from mk_wbc_lib import rw, rep
OD = collections.OrderedDict
R = sys.argv[1].rstrip('/') + '/'


def num(lo, hi, desc, excl=False):
    d = OD([("type", "number")])
    d["exclusiveMinimum" if excl else "minimum"] = lo
    d["maximum"] = hi
    d["description"] = desc
    return d


def integer(lo, hi, desc):
    return OD([("type", "integer"), ("minimum", lo), ("maximum", hi), ("description", desc)])


def obj(props, desc):
    return OD([("type", "object"), ("required", list(props.keys())), ("additionalProperties", False), ("description", desc), ("properties", props)])


props = OD([
    ("schema", OD([("const", "biomes.rivers/1")])),
    ("_about", OD([("type", "string")])),
    ("enabled", OD([("type", "boolean"), ("description", "Rivers on or off; off, nothing in WorldRivers runs and a planet is as it was.")])),
    ("rain", obj(OD([("dry", num(0.0, 1.0, "Moisture under which a land cell sheds no runoff.")), ("gain", num(0.0, 100.0, "Runoff per unit of moisture over dry.", True)), ("frozenT", num(0.0, 2.0, "Under this temperature a cell sheds none (a frozen river is not a channel)."))]), "Runoff.")),
    ("flow", obj(OD([("river", num(0.0, 100000.0, "A cell whose flow passes this is a river cell.", True)), ("ref", num(0.0, 100000.0, "The flow a river of the base width carries.", True))]), "The flow field.")),
    ("span", obj(OD([
        ("minCols", integer(1, 200, "The narrowest channel, in columns.")),
        ("maxCols", integer(1, 400, "The widest (at least minCols: WorldRivers' load).")),
        ("width0", num(0.0, 400.0, "Columns wide at no flow.")),
        ("width1", num(0.0, 400.0, "Columns added with the square root of flow over ref.")),
        ("depth0", num(0.0, 1000.0, "Depth at no flow, in units.")),
        ("depth1", num(0.0, 1000.0, "Depth added with the square root of flow over ref.")),
        ("maxDepth", num(0.0, 1000.0, "The deepest a river is: under the depth that hides a fighter (WorldRivers' load).", True)),
        ("freeboard", num(0.0, 1000.0, "How far the surface lies under the lower bank.")),
        ("reach", integer(0, 200, "Columns either side the crossing is snapped to the lowest ground within.")),
        ("bank", integer(0, 100, "Columns outside the channel the banks are read at.")),
        ("margin", integer(0, 200, "Columns kept clear of a settlement.")),
        ("floor", num(-1000.0, 1000.0, "No river on ground under this height (the sea's edge).")),
    ]), "A river's channel.")),
    ("spacing", obj(OD([("gapUnits", num(0.0, 1000000.0, "Of the crossings at most one is kept in any this many units (Game Design 23b row 13: 3,000).")), ("maxPerRing", integer(1, 200, "At most this many a ring."))]), "How many rivers a ring keeps.")),
    ("refuse", OD([("type", "array"), ("items", OD([("type", "string")])), ("description", "Fine biomes a river does not cross (their names are checked by WorldRivers' load).")])),
])
schema = OD([
    ("$schema", "https://json-schema.org/draft/2020-12/schema"),
    ("$id", "meridian/biomes-rivers"),
    ("title", "biomes.rivers/1"),
    ("description", "data/biomes/rivers.json: planet generation 2's rivers (docs/world/rivers.md; WorldRivers). Version field: schema. Policy: every key required, objects closed except keys starting with an underscore. Order checks are WorldRivers' own load and rivers_check."),
    ("type", "object"),
    ("required", list(props.keys())),
    ("additionalProperties", False),
    ("properties", props)])
open(R + 'tools/schemas/biomes-rivers.schema.json', 'w', encoding='utf-8', newline='').write(json.dumps(schema, indent=2) + '\n')


def maprule(s):
    return rep(s, '''    {
      "match": "data/biomes/water.json",
      "schema": "biomes-water.schema.json"
    },
''', '''    {
      "match": "data/biomes/water.json",
      "schema": "biomes-water.schema.json"
    },
    {
      "match": "data/biomes/rivers.json",
      "schema": "biomes-rivers.schema.json"
    },
''')


def case(i, mut, rule, ptr):
    return '''    {
      "id": "%s",
      "schema": "biomes-rivers.schema.json",
      "mutate": [
        {
          "file": "data/biomes/rivers.json",
          "set": {
            "%s": %s
          }
        }
      ],
      "expect": {
        "rule": "%s",
        "pointer": "%s"
      }
    },
''' % (i, ptr, mut, rule, ptr)


def cases(s):
    new = case("rivers-enabled-not-boolean", '"on"', "type", "/enabled") \
        + case("rivers-flow-river-zero", "0", "exclusiveMinimum", "/flow/river") \
        + case("rivers-spacing-per-ring-zero", "0", "minimum", "/spacing/maxPerRing")
    return rep(s, '''    {
      "id": "rings-turn-bearing-over-10",''', new + '''    {
      "id": "rings-turn-bearing-over-10",''')


rw(R, 'tools/schemas/map.json', maprule)
rw(R, 'tools/fixtures/cases.json', cases)
print('rivers tools applied')
