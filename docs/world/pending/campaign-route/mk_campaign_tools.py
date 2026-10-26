"""The campaign route's Tools files (granted on Orb's word): the schema for data/biomes/campaign.json, its rule in tools/schemas/map.json, three invalid cases.   python mk_campaign_tools.py <root>"""
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


def arr(item, n, desc):
    return OD([("type", "array"), ("minItems", n), ("maxItems", n), ("items", item), ("description", desc)])


col = obj(OD([
    ("min", integer(1, 4, "The fewest places the column offers.")),
    ("max", integer(1, 4, "The most (at least min: WorldCampaign's load).")),
    ("pThree", num(0.0, 1.0, "The chance of each extra place past min (a seeded draw).")),
    ("settled", integer(0, 4, "How many must be a city or town on the ring.")),
    ("pull", num(0.0, 5.0, "The pull toward settled places in the score.")),
    ("pinned", OD([("type", "boolean"), ("description", "The column's place is the one the caller pins (the climax: the boss's home).")])),
]), "One column of the episode.")
props = OD([
    ("schema", OD([("const", "biomes.campaign/1")])),
    ("_about", OD([("type", "string")])),
    ("enabled", OD([("type", "boolean"), ("description", "The campaign's route on or off; off, nothing in WorldCampaign runs and the golden is as it was.")])),
    ("flight", obj(OD([
        ("speed", num(0.0, 100000.0, "Units a second the pair fly between places.", True)),
        ("minS", num(0.0, 1000.0, "The least seconds of flight to a place's near edge.", True)),
        ("maxS", num(0.0, 1000.0, "The most (above minS: WorldCampaign's load).", True)),
        ("climaxMaxS", num(0.0, 1000.0, "The most for the climax before it counts as the build-up.", True)),
    ]), "The flight band.")),
    ("columns", arr(col, 5, "The five columns, cold open to climax.")),
    ("sites", obj(OD([
        ("openStride", integer(1, 400, "Columns between open-ground samples.")),
        ("sepS", num(0.0, 1000.0, "The least seconds of flight between two of a column's places.")),
        ("jitter", num(0.0, 5.0, "How far a seeded draw may move a place's score.")),
        ("novelty", num(0.0, 5.0, "What a new kind of ground adds.")),
        ("fallen", num(0.0, 5.0, "What a fallen place loses.")),
        ("openMin", num(0.0, 1.0, "The least land share around an open site.")),
    ]), "Choosing places.")),
    ("turn", obj(OD([
        ("bearings", OD([("type", "array"), ("minItems", 0), ("maxItems", 12), ("items", num(0.0, 90.0, "A bearing in degrees, tried both ways.")), ("description", "The turns a column may make.")])),
        ("bonus", num(0.0, 5.0, "What a turn adds to a ring's score.")),
        ("minGain", num(0.0, 5.0, "How much a turn must gain over no turn.")),
    ]), "The ring turn between columns.")),
    ("side", obj(OD([
        ("sepS", num(0.0, 1000.0, "The least seconds of flight between a side story's place and a column's.")),
        ("ringCols", integer(100, 4800, "The columns of the Close ring round a side story's place.")),
    ]), "The side story's place.")),
    ("wear", obj(OD([
        ("band", arr(num(0.0, 1.0, "The share of a place's buildings lost that lifts it to the band."), 3, "Bands 1 to 3.")),
        ("fallen", arr(num(0.0, 1.0, "The share of a worn place's buildings already fallen."), 4, "For bands 0 to 3.")),
        ("hpKeep", arr(num(0.0, 1.0, "The share of hp the other buildings keep.", False), 4, "For bands 0 to 3.")),
    ]), "A place's wounds, as place state only (Legal mc02).")),
])
schema = OD([
    ("$schema", "https://json-schema.org/draft/2020-12/schema"),
    ("$id", "meridian/biomes-campaign"),
    ("title", "biomes.campaign/1"),
    ("description", "data/biomes/campaign.json: the campaign's route on the ring (docs/design/campaign.md; WorldCampaign). Version field: schema. Policy: every key required, objects closed except keys starting with an underscore. Order checks (min within max, maxS above minS, five columns) are WorldCampaign's own load and campaign_check."),
    ("type", "object"),
    ("required", list(props.keys())),
    ("additionalProperties", False),
    ("properties", props)])
open(R + 'tools/schemas/biomes-campaign.schema.json', 'w', encoding='utf-8', newline='').write(json.dumps(schema, indent=2) + '\n')


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
      "match": "data/biomes/campaign.json",
      "schema": "biomes-campaign.schema.json"
    },
''')


def case(i, mut, rule, ptr):
    return '''    {
      "id": "%s",
      "schema": "biomes-campaign.schema.json",
      "mutate": [
        {
          "file": "data/biomes/campaign.json",
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
    new = case("campaign-enabled-not-boolean", '"on"', "type", "/enabled") \
        + case("campaign-flight-speed-zero", "0", "exclusiveMinimum", "/flight/speed") \
        + case("campaign-side-ring-too-short", "50", "minimum", "/side/ringCols")
    return rep(s, '''    {
      "id": "rings-turn-bearing-over-10",''', new + '''    {
      "id": "rings-turn-bearing-over-10",''')


rw(R, 'tools/schemas/map.json', maprule)
rw(R, 'tools/fixtures/cases.json', cases)
print('campaign tools applied')
