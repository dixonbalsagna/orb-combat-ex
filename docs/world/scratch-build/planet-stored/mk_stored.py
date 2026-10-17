"""Stored places for a canon planet (World, scratch, parked): Everhold's places list in planet.json's `story` section, `make` reading it, and a check that stored equals generated.
python mk_stored.py <root> <everhold_places.json>     (root: an export of main's HEAD with planet window 1)"""
import sys, json, collections
from mk_wbc_lib import rw, rep

R = sys.argv[1].rstrip('/') + '/'
placesFile = sys.argv[2]


def planet(s):
    s = rep(s, '''	_placeAll(P)
	if _planets.size() > 6:
		_planets.clear()
	_planets[key] = P
	return P
''', '''	var st: Dictionary = storyFor(seed)
	if st.is_empty():
		_placeAll(P)
	else:
		_loadStored(P, st)   # a story planet's places are data: no placement to do
	_register(P)
	return P


static func _register(P: Planet) -> void:
	if _planets.size() > 6:
		_planets.clear()
	_planets[P.seed] = P


## The same planet as `make` would build, but always by the generator, never from the story data (the check that the stored list equals the generated one reads it).
static func makeGenerated(seed: int) -> Planet:
	var P := Planet.new()
	P.seed = seed
	P.c = cfg()
	P.L = float(SimConst.NC) * SimConst.COL
	P.R = P.L / (2.0 * PI)
	_placeAll(P)
	return P


## The story planet (planet.json "story") whose seed this is, or {}. A story planet stores its places: cities then towns, each a kind (0 city, 1 town), a unit vector as three
## float64 bit patterns (16 hex digits, high word first: exact, and read with SimMathx.f64) and a radius.
static func storyFor(seed: int) -> Dictionary:
	var st = cfg().get("story", {})
	if not (st is Dictionary):
		return {}
	for id in st:
		var e = st[id]
		if e is Dictionary and e.has("seed") and int(e.seed) == seed and e.has("places") and (e.places is Array) and e.places.size() > 0:
			return e
	return {}


static func _loadStored(P: Planet, st: Dictionary) -> void:
	for pl in st.places:
		_addPlace(P, int(pl.kind), [SimMathx.f64(str(pl.x)), SimMathx.f64(str(pl.y)), SimMathx.f64(str(pl.z))], float(pl.r))
	_finishPeople(P)
''')
    # _addPlace and _finishPeople (the generator's pieces) are needed by the loader: they are added here when window 1 does not have them
    if "static func _addPlace(" not in s:
        s = rep(s, '''## The places of a planet: first as picture A placed them''', '''static func _addPlace(P: Planet, kind: int, p: Array, radius: float) -> void:
	P.kind.append(kind)
	P.px.append(p[0])
	P.py.append(p[1])
	P.pz.append(p[2])
	P.rad.append(radius)
	P.n += 1


## A place's weight is its area (radius squared), so a city holds about seven towns' people (as Bellgate and the villages do).
static func _finishPeople(P: Planet) -> void:
	P.people.resize(P.n)
	for i in range(P.n):
		P.people[i] = int(P.rad[i] * P.rad[i] / 1000000.0 * 100.0)


## The places of a planet: first as picture A placed them''')
        # use them in _tryPlace and _placeAll
        s = rep(s, '''	if best != null:
		P.kind.append(kind)
		P.px.append(best[0])
		P.py.append(best[1])
		P.pz.append(best[2])
		P.rad.append(radius)
		P.n += 1
		return true
	return false''', '''	if best != null:
		_addPlace(P, kind, best, radius)
		return true
	return false''')
        s = rep(s, '''	# people: a place's weight is its area (radius squared), so a city holds about seven towns' people (as Bellgate and the villages do)
	P.people.resize(P.n)
	for i in range(P.n):
		P.people[i] = int(P.rad[i] * P.rad[i] / 1000000.0 * 100.0)
''', '''	_finishPeople(P)
''')
    # the data errors: the story entries
    s = rep(s, '''	_cHash = str(text.hash())''', '''	var st = j.get("story", {})
	if st is Dictionary:
		for id in st:
			var e = st[id]
			if not (e is Dictionary) or not e.has("seed") or not e.has("places") or not (e.places is Array):
				_cErrors.append("planet.json: story %s needs a seed and a places list" % id)
				continue
			for i in range(e.places.size()):
				var pl = e.places[i]
				var okp: bool = pl is Dictionary and pl.has("kind") and pl.has("r") and (int(pl.kind) == 0 or int(pl.kind) == 1)
				for k in ["x", "y", "z"]:
					okp = okp and pl.has(k) and str(pl[k]).length() == 16 and str(pl[k]).is_valid_hex_number()
				if not okp:
					_cErrors.append("planet.json: story %s place %d is not {kind, x, y, z (16 hex digits each), r}" % [id, i])
	_cHash = str(text.hash())''')
    return s


def data():
    places = json.load(open(placesFile))
    p = R + 'data/biomes/planet.json'
    d = json.load(open(p, encoding='utf-8'), object_pairs_hook=collections.OrderedDict)
    d['story'] = collections.OrderedDict([('everhold', collections.OrderedDict([
        ('seed', places['seed']), ('name', 'Everhold'),
        ('_about', 'The canon planet (docs/world/canon-planet.md): planet seed 7 with its places stored, so a load does not place them (0.5 to 0.7 s). Each place: kind 0 city or 1 town, x y z the unit vector as float64 bits (16 hex digits, high word first), r its radius. WorldPlanet.makeGenerated is the check that this list equals what the generator makes.'),
        ('places', places['places'])]))])
    open(p, 'w', encoding='utf-8', newline='').write(json.dumps(d, indent=2, ensure_ascii=False) + '\n')
    p = R + 'tools/schemas/biomes-planet.schema.json'
    j = json.load(open(p, encoding='utf-8'), object_pairs_hook=collections.OrderedDict)
    hexp = {'type': 'string', 'pattern': '^[0-9a-f]{16}$', 'description': 'a float64 as 16 hex digits, high word first'}
    j['properties']['story'] = collections.OrderedDict([
        ('type', 'object'), ('description', 'story planets by id: a fixed seed, its name and its places list (so a load does not place them)'),
        ('additionalProperties', collections.OrderedDict([('type', 'object'), ('required', ['seed', 'places']), ('properties', collections.OrderedDict([
            ('seed', {'type': 'integer', 'minimum': 0}), ('name', {'type': 'string'}), ('_about', {'type': 'string'}),
            ('places', {'type': 'array', 'minItems': 1, 'items': collections.OrderedDict([('type', 'object'), ('required', ['kind', 'x', 'y', 'z', 'r']), ('additionalProperties', False), ('properties', collections.OrderedDict([
                ('kind', {'enum': [0, 1]}), ('x', hexp), ('y', hexp), ('z', hexp), ('r', {'type': 'number', 'exclusiveMinimum': 0})]))])})])), ('additionalProperties', False)]))])
    open(p, 'w', encoding='utf-8', newline='').write(json.dumps(j, indent=2, ensure_ascii=False) + '\n')


data()
rw(R, 'sim/world/planet.gd', planet)
print('stored places applied')
