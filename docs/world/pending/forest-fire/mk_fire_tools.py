"""Window 18's Tools files (granted on Orb's word) and the data hash line.   python mk_fire_tools.py <root>
 - tools/schemas/biomes-fire.schema.json, its rule in tools/schemas/map.json, three invalid cases in tools/fixtures/cases.json
 - sim/world/contact.gd: the replay's data hash carries fire.json while the fires are on"""
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
    ("schema", OD([("const", "biomes.fire/1")])),
    ("_about", OD([("type", "string")])),
    ("enabled", OD([("type", "boolean"), ("description", "Fires in the forests on or off; off, nothing in WorldFire runs and the trees are as they were.")])),
    ("ignite", obj(OD([("bandLo", num(0.0, 10.0, "Trees from this share of a blast's radius out may catch (inside 0.7 they are felled).")), ("bandHi", num(0.0, 10.0, "Up to this share (above bandLo: WorldFire's load).")), ("chance", num(0.0, 1.0, "The chance, times the ground's flammability."))]), "Where a blast lights trees.")),
    ("burn", obj(OD([
        ("ticks", integer(2, 100000, "Ticks a tree burns before it is dead and charred.")),
        ("spreadRadius", num(0.0, 100000.0, "A burning tree may light a tree within this many units.", True)),
        ("spread", num(0.0, 1000.0, "The chance a second at point-blank, falling with distance, times the flammability.")),
        ("every", integer(1, 1000, "Spread is tried every this many ticks.")),
        ("maxBurning", integer(1, 100000, "At most this many trees burn at once.")),
        ("quenchDepth", num(0.0, 10000.0, "Water deeper than this at a tree's column puts it out.")),
    ]), "A burning tree.")),
    ("flammable", OD([("type", "object"), ("additionalProperties", num(0.0, 1.0, "How readily the biome burns.")), ("description", "By biome name (the fine name on a gen 2 planet); a biome not listed does not burn. Names are checked by WorldFire's load.")])),
])
schema = OD([
    ("$schema", "https://json-schema.org/draft/2020-12/schema"),
    ("$id", "meridian/biomes-fire"),
    ("title", "biomes.fire/1"),
    ("description", "data/biomes/fire.json: fires in the forests (docs/world/forest-fire.md; WorldFire). Version field: schema. Policy: every key required, objects closed except keys starting with an underscore. Order checks and biome names are WorldFire's own load and fire_check."),
    ("type", "object"),
    ("required", list(props.keys())),
    ("additionalProperties", False),
    ("properties", props)])
open(R + 'tools/schemas/biomes-fire.schema.json', 'w', encoding='utf-8', newline='').write(json.dumps(schema, indent=2) + '\n')


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
      "match": "data/biomes/fire.json",
      "schema": "biomes-fire.schema.json"
    },
''')


def case(i, mut, rule, ptr):
    return '''    {
      "id": "%s",
      "schema": "biomes-fire.schema.json",
      "mutate": [
        {
          "file": "data/biomes/fire.json",
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
    new = case("fire-enabled-not-boolean", '"on"', "type", "/enabled") \
        + case("fire-burn-ticks-one", "1", "minimum", "/burn/ticks") \
        + case("fire-chance-over-one", "2", "maximum", "/ignite/chance")
    return rep(s, '''    {
      "id": "rings-turn-bearing-over-10",''', new + '''    {
      "id": "rings-turn-bearing-over-10",''')


def contact(s):
    return rep(s, '''	if skateOn():
		h.text("biomes.skate")''', '''	if WorldFire.on():
		h.text("biomes.fire")
		FighterData._canon(h, WorldFire.data())   # the fires in the forests, on: a replay must know
	if skateOn():
		h.text("biomes.skate")''')


rw(R, 'tools/schemas/map.json', maprule)
rw(R, 'tools/fixtures/cases.json', cases)
rw(R, 'sim/world/contact.gd', contact)
print('fire tools applied')
