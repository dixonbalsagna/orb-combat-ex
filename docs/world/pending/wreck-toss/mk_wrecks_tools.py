"""The wreck query's Tools files (granted on Orb's word): the schema for data/biomes/wrecks.json, its rule in tools/schemas/map.json, three invalid cases.   python mk_wrecks_tools.py <root>"""
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


def obj(props, desc):
    return OD([("type", "object"), ("required", list(props.keys())), ("additionalProperties", False), ("description", desc), ("properties", props)])


props = OD([
    ("schema", OD([("const", "biomes.wrecks/1")])),
    ("_about", OD([("type", "string")])),
    ("reachBh", num(0.0, 20.0, "How near the fighter must be, in body heights, to the wreck's box.", True)),
    ("nearBh", num(0.0, 50.0, "No living civilian in a building within this many body heights of the wreck's edge.")),
    ("fighters", OD([("type", "boolean"), ("description", "A fighter near the wreck counts as living too.")])),
    ("fill", num(0.0, 10.0, "A wreck's mass is this share of its building's volume (cubic body heights).", True)),
    ("minMass", num(0.0, 1000.0, "A smaller wreck is not worth lifting.")),
    ("tierLift", OD([("type", "array"), ("minItems", 4), ("maxItems", 8), ("items", num(0.0, 100000.0, "The heaviest wreck this tier lifts.", True)), ("description", "Per tier from 1; never falls as the tier rises (WorldWrecks' load).")])),
    ("burst", obj(OD([
        ("speed", num(0.0, 100000.0, "The scrap's speed in the brunt ladder's terms.", True)),
        ("massRef", num(0.0, 100000.0, "The mass at which the damage and radius are as written.", True)),
        ("scaleMin", num(0.0, 100.0, "Lowest damage scale (square root of mass over massRef).")),
        ("scaleMax", num(0.0, 100.0, "Highest damage scale.")),
        ("radiusBh", num(0.0, 50.0, "The burst's radius in body heights at massRef.", True)),
        ("radiusMinBh", num(0.0, 50.0, "Smallest radius.")),
        ("radiusMaxBh", num(0.0, 50.0, "Largest radius.")),
    ]), "The scrap's damage to structures.")),
])
schema = OD([
    ("$schema", "https://json-schema.org/draft/2020-12/schema"),
    ("$id", "meridian/biomes-wrecks"),
    ("title", "biomes.wrecks/1"),
    ("description", "data/biomes/wrecks.json: the liftable wreck (Game Design 23d section 8 item 20; WorldWrecks). Version field: schema. Policy: every key required, objects closed except keys starting with an underscore. Order checks (tierLift never falls, scaleMin within scaleMax) are WorldWrecks' own load and wrecks_check."),
    ("type", "object"),
    ("required", list(props.keys())),
    ("additionalProperties", False),
    ("properties", props)])
open(R + 'tools/schemas/biomes-wrecks.schema.json', 'w', encoding='utf-8', newline='').write(json.dumps(schema, indent=2) + '\n')


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
      "match": "data/biomes/wrecks.json",
      "schema": "biomes-wrecks.schema.json"
    },
''')


def case(i, mut, rule, ptr):
    return '''    {
      "id": "%s",
      "schema": "biomes-wrecks.schema.json",
      "mutate": [
        {
          "file": "data/biomes/wrecks.json",
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
    new = case("wrecks-reach-zero", "0", "exclusiveMinimum", "/reachBh") \
        + case("wrecks-fighters-not-boolean", '"yes"', "type", "/fighters") \
        + case("wrecks-burst-speed-zero", "0", "exclusiveMinimum", "/burst/speed")
    return rep(s, '''    {
      "id": "rings-turn-bearing-over-10",''', new + '''    {
      "id": "rings-turn-bearing-over-10",''')


rw(R, 'tools/schemas/map.json', maprule)
rw(R, 'tools/fixtures/cases.json', cases)
print('wrecks tools applied')
