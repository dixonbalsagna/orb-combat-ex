"""Water v2's Tools files (granted on Orb's word): the schema for data/biomes/water.json, its rule in tools/schemas/map.json, three invalid cases.   python mk_w10_tools.py <root>"""
import sys, json, collections
from mk_wbc_lib import rw, rep
OD = collections.OrderedDict
R = sys.argv[1].rstrip('/') + '/'


def num(lo, hi, desc, excl=False):
    d = OD([("type", "number")])
    if excl:
        d["exclusiveMinimum"] = lo
    else:
        d["minimum"] = lo
    d["maximum"] = hi
    d["description"] = desc
    return d


def integer(lo, hi, desc):
    return OD([("type", "integer"), ("minimum", lo), ("maximum", hi), ("description", desc)])


def obj(props, desc):
    return OD([("type", "object"), ("required", list(props.keys())), ("additionalProperties", False), ("description", desc), ("properties", props)])


props = OD([
    ("schema", OD([("const", "biomes.water/1")])),
    ("_about", OD([("type", "string")])),
    ("enabled", OD([("type", "boolean"), ("description", "Water v2 on or off; off, the water module is as it was.")])),
    ("table", OD([("type", "object"), ("description", "Wet biomes (climate.json's fine names) and how far below the original ground their water stands.")
                  , ("additionalProperties", obj(OD([("depth", num(0.0, 500.0, "Units below the original ground.")), ("near", OD([("type", "boolean"), ("description", "true: the table is there only with open water in reach.")]))]), "One biome's table."))])),
    ("near", obj(OD([("reach", integer(1, 400, "Columns within which open water feeds a hole.")), ("maxRise", num(0.0, 500.0, "Ground at most this far above the water's level is fed.")), ("front", num(0.1, 100.0, "Columns a step the front runs from the source."), )]), "Open water as a source.")),
    ("fill", obj(OD([("rate", num(0.0, 200.0, "Depth added a step toward the target.", True)), ("minDug", num(0.0, 500.0, "Ground dug at least this far below its original height opens a fill.")), ("halfMax", integer(4, 480, "Columns either side of a window's centre, at most.")), ("pad", integer(0, 100, "Columns added round the touched span.")), ("maxWindows", integer(1, 16, "Fills open at once.")), ("ageMax", integer(1, 5000, "Steps after which a window closes.")), ("settle", integer(1, 50, "Quiet steps after which a window closes."))]), "How a fill runs.")),
    ("wade", obj(OD([("below", num(0.0, 1000.0, "Water shallower than this is waded: no drag, no sink."))]), "Shallow water.")),
    ("wave", obj(OD([("minE", num(0.0, 1000.0, "Impact energy a slam needs.")), ("minDepth", num(0.0, 1000.0, "Water this deep must stand where it lands.")), ("radius", num(1.0, 20000.0, "Ring radius in units.")), ("band", num(0.0, 1000.0, "A body within this of the surface is pushed.")), ("push", num(0.0, 1000.0, "Units outward in all.")), ("steps", integer(1, 100, "Over this many steps."))]), "The crater wave.")),
    ("douse", obj(OD([("scorchMin", num(0.0, 1.0, "A column scorched at least this is a fire line a fill puts out."))]), "Water douses fire.")),
])
schema = OD([
    ("$schema", "https://json-schema.org/draft/2020-12/schema"),
    ("$id", "meridian/biomes-water"),
    ("title", "biomes.water/1"),
    ("description", "data/biomes/water.json: water v2 (docs/world/water-v2.md; WorldFill). Version field: schema. Policy: every key required, objects closed except keys starting with an underscore. Table names are checked against climate.json's fine biomes by WorldFill's load and fill_check."),
    ("type", "object"),
    ("required", list(props.keys())),
    ("additionalProperties", False),
    ("properties", props)])
open(R + 'tools/schemas/biomes-water.schema.json', 'w', encoding='utf-8', newline='').write(json.dumps(schema, indent=2) + '\n')


def maprule(s):
    return rep(s, '''    {
      "match": "data/biomes/skate.json",
      "schema": "biomes-skate.schema.json"
    },
''', '''    {
      "match": "data/biomes/skate.json",
      "schema": "biomes-skate.schema.json"
    },
    {
      "match": "data/biomes/water.json",
      "schema": "biomes-water.schema.json"
    },
''')


def case(i, f, mut, rule, ptr):
    return '''    {
      "id": "%s",
      "schema": "biomes-water.schema.json",
      "mutate": [
        {
          "file": "data/biomes/water.json",
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
''' % (i, f, mut, rule, ptr)


def cases(s):
    new = case("water-enabled-not-boolean", "/enabled", '"on"', "type", "/enabled") \
        + case("water-fill-rate-zero", "/fill/rate", "0", "exclusiveMinimum", "/fill/rate") \
        + case("water-wave-steps-zero", "/wave/steps", "0", "minimum", "/wave/steps")
    return rep(s, '''    {
      "id": "rings-turn-bearing-over-10",''', new + '''    {
      "id": "rings-turn-bearing-over-10",''')


rw(R, 'tools/schemas/map.json', maprule)
rw(R, 'tools/fixtures/cases.json', cases)
print('w10 tools applied')
