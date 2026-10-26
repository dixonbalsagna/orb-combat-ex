"""Window 12 (World, 2026-10-23): Research's B plates (round 2) as the gen 2 ground behind land.json's b.enabled (off).   python mk_w12.py <root> <w12 dir with plateb.gd, plates-b.json>   (root: windows 2 to 11)
 - sim/world/plateb.gd (new, World's), data/biomes/plates-b.json (new)
 - sim/world/land.gd: the switch (plateB, setB), the data hash carries plates-b only while on
 - sim/world/planet.gd: Planet.platesB, and ground() hands a gen 2 planet to WorldPlateB when the switch is on
 - data/biomes/land.json: b.enabled (false)
 - Tools' (granted): tools/schemas/biomes-land.schema.json (b), biomes-plates-b.schema.json, map.json, three invalid cases"""
import sys, json, shutil, collections
from mk_wbc_lib import rw, rep
OD = collections.OrderedDict
R = sys.argv[1].rstrip('/') + '/'
W = sys.argv[2].rstrip('/') + '/'

shutil.copyfile(W + 'plateb.gd', R + 'sim/world/plateb.gd')
shutil.copyfile(W + 'plates-b.json', R + 'data/biomes/plates-b.json')


def land_json(s):
    s = rep(s, '''  "keep": 0.55
}''', '''  "keep": 0.55,
  "b": {
    "enabled": false
  }
}''')
    return rep(s, '''the old blobs are weaker).",''', '''the old blobs are weaker). b: window 12's switch, off: when true a gen 2 planet's ground is Research's B plates (data/biomes/plates-b.json, sim/world/plateb.gd) in place of the plates, ranges, rifts, shoreline, plateaus and canyons above.",''')


def land_gd(s):
    s = rep(s, '''static var K_KEEP: float = 1.0
''', '''static var K_KEEP: float = 1.0
static var K_B_ON: bool = false   # window 12: the ground is Research's B plates (WorldPlateB) in place of the landforms below
''')
    s = rep(s, '''	for k in ["plates", "ranges", "rifts", "coast", "plateaus", "canyons", "polar", "keep"]:''', '''	for k in ["plates", "ranges", "rifts", "coast", "plateaus", "canyons", "polar", "keep", "b"]:''')
    s = rep(s, '''		if float(j.keep) < 0.0 or float(j.keep) > 1.0:
			_errors.append("land.json: keep is in [0, 1]")''', '''		if float(j.keep) < 0.0 or float(j.keep) > 1.0:
			_errors.append("land.json: keep is in [0, 1]")
		if bool(j.b.enabled) and not WorldPlateB.dataErrors().is_empty():
			_errors.append("land.json: b is on but plates-b.json is not clean: " + str(WorldPlateB.dataErrors()))''')
    s = rep(s, '''	K_KEEP = float(j.keep)
''', '''	K_KEEP = float(j.keep)
	K_B_ON = bool(j.b.enabled)
''')
    s = rep(s, '''static func dataHash() -> String:
	if not _loaded:
		_load()
	return _hash
''', '''static func dataHash() -> String:
	if not _loaded:
		_load()
	return _hash + ("/b" + WorldPlateB.dataHash() if K_B_ON else "")   # plates-b.json counts only while the switch is on
''')
    return rep(s, '''static func _load() -> void:''', '''## Whether a gen 2 planet's ground is Research's B plates (land.json b.enabled).
static func plateB() -> bool:
	if not _loaded:
		_load()
	return K_B_ON


## For tools and checks: the switch for this process (the file is not touched). On only if plates-b.json is clean.
static func setB(on: bool) -> void:
	if not _loaded:
		_load()
	K_B_ON = on and WorldPlateB.dataErrors().is_empty()


static func _load() -> void:''')


def planet_gd(s):
    s = rep(s, '''	var plates = null                        # gen 2: the plates (WorldLand.Plates), made when first asked
''', '''	var plates = null                        # gen 2: the plates (WorldLand.Plates), made when first asked
	var platesB = null                       # gen 2 with land.json's b on: the B plates (WorldPlateB.State), made when first asked
''')
    return rep(s, '''static func ground(P: Planet, px: float, py: float, pz: float) -> float:
	var c: Dictionary = P.c''', '''static func ground(P: Planet, px: float, py: float, pz: float) -> float:
	if P.gen >= 2 and WorldLand.plateB():
		return WorldPlateB.ground(P, px, py, pz)   # Research's B plates in place of everything below (window 12)
	var c: Dictionary = P.c''')


rw(R, 'data/biomes/land.json', land_json)
rw(R, 'sim/world/land.gd', land_gd)
rw(R, 'sim/world/planet.gd', planet_gd)

# ---- Tools' files (granted on Orb's word)
props = json.load(open(R + 'data/biomes/plates-b.json', encoding='utf-8'), object_pairs_hook=OD)['params']
INTS = [k for k, v in props.items() if isinstance(v, int) and not isinstance(v, bool) and (k in ('plates', 'areaPts', 'sepTries', 'cells', 'warpOct', 'crustOct', 'crustOctM', 'alongOct', 'interiorOct', 'oldOct', 'reliefOct', 'peakOct', 'detailOct', 'hotspots', 'chain', 'hotActive') or (k[0] == 's' and k[1].isupper()))]
POS = ('quadW', 'capW', 'junctionW', 'domW', 'vRef', 'bw', 'blendW', 'typeW', 'islSp', 'riftSeg', 'shelfW', 'oldW', 'junctionEase', 'knee', 'upCap', 'warpScale', 'crustScale', 'coastScale', 'alongScale', 'interiorScale', 'oldScale', 'reliefScale', 'peakScale', 'detailScale', 'detailRamp')
pp = OD()
for k in props:
    if k in INTS:
        d = OD([("type", "integer")])
        if k == 'plates':
            d["minimum"] = 3
        elif k == 'areaPts':
            d["minimum"] = 100
        elif k == 'cells':
            d["minimum"] = 3
        elif k[0] != 's' or not k[1].isupper():
            d["minimum"] = 1 if k in ('hotspots', 'chain') else 0
        else:
            d["minimum"] = 0
    else:
        d = OD([("type", "number")])
        if k in POS:
            d["exclusiveMinimum"] = 0
        if k == 'landShare':
            d["exclusiveMinimum"] = 0
            d["exclusiveMaximum"] = 1
    pp[k] = d
schema = OD([
    ("$schema", "https://json-schema.org/draft/2020-12/schema"),
    ("$id", "meridian/biomes-plates-b"),
    ("title", "biomes.plates-b/1"),
    ("description", "data/biomes/plates-b.json: planet generation 2's B plates (Research's PB, research/planet-gen/gen/plates.mjs; WorldPlateB, window 12). Version field: schema. Policy: every key required, objects closed except keys starting with an underscore. Order checks (cells at least plates) are WorldPlateB's own load and b_check."),
    ("type", "object"),
    ("required", ["schema", "_about", "params"]),
    ("additionalProperties", False),
    ("properties", OD([("schema", OD([("const", "biomes.plates-b/1")])), ("_about", OD([("type", "string")])),
                       ("params", OD([("type", "object"), ("required", list(pp.keys())), ("additionalProperties", False), ("description", "Research's PB, one number each."), ("properties", pp)]))]))])
open(R + 'tools/schemas/biomes-plates-b.schema.json', 'w', encoding='utf-8', newline='').write(json.dumps(schema, indent=2) + '\n')


def land_schema(s):
    s = rep(s, '''    "keep"
  ],''', '''    "keep",
    "b"
  ],''')
    return rep(s, '''    "keep": {''', '''    "b": {
      "type": "object",
      "required": [
        "enabled"
      ],
      "additionalProperties": false,
      "description": "Window 12's switch: true makes a gen 2 planet's ground Research's B plates (data/biomes/plates-b.json), false the plates and landforms above.",
      "properties": {
        "enabled": {
          "type": "boolean"
        }
      }
    },
    "keep": {''')


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
      "match": "data/biomes/plates-b.json",
      "schema": "biomes-plates-b.schema.json"
    },
''')


def case(i, f, mut, rule, ptr):
    return '''    {
      "id": "%s",
      "schema": "biomes-plates-b.schema.json",
      "mutate": [
        {
          "file": "data/biomes/plates-b.json",
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
    new = case("platesb-plates-two", "/params/plates", "2", "minimum", "/params/plates") \
        + case("platesb-vref-zero", "/params/vRef", "0", "exclusiveMinimum", "/params/vRef") \
        + case("platesb-landshare-one", "/params/landShare", "1", "exclusiveMaximum", "/params/landShare")
    return rep(s, '''    {
      "id": "rings-turn-bearing-over-10",''', new + '''    {
      "id": "rings-turn-bearing-over-10",''')


rw(R, 'tools/schemas/biomes-land.schema.json', land_schema)
rw(R, 'tools/schemas/map.json', maprule)
rw(R, 'tools/fixtures/cases.json', cases)
print('w12 applied')
