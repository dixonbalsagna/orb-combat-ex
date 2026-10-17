"""Writes data/biomes/planet.json and tools/schemas/biomes-planet.schema.json for WorldPlanet.  python mk_planet_data.py <root>"""
import json, sys, collections

R = sys.argv[1].rstrip('/') + '/'

G = collections.OrderedDict()


def grp(title, items):
    G[title] = items


grp('terrain: the ordinary ground (the continents, the relief, the detail), and the biome thresholds', [
    ('contScale', 30000.0, 'the continents: noise scale in units'), ('contOct', 4, 'the continents: octaves'),
    ('reliefScale', 9000.0, 'the ranges on high land: noise scale'), ('reliefOct', 3, 'the relief: octaves'),
    ('seaShift', 0.15, 'height = (e + seaShift) x hMul: more shift, less ocean'), ('hMul', 1300.0, 'the height of the continents'),
    ('rangeFrom', 0.12, 'above this e the ground rises into ranges'), ('rangeMul', 16000.0, 'range height per unit of e above rangeFrom'),
    ('reliefBase', 0.35, 'ranges are (reliefBase + relief noise) tall'),
    ('detailScale', 1500.0, 'the fine relief: noise scale'), ('detailOct', 3, 'the fine relief: octaves'), ('detailAmp', 300.0, 'the fine relief on ordinary land, units'),
    ('detailSheet', 0.25, 'the share of the fine relief an ice sheet takes'),
    ('mountainAbove', 3200.0, 'ground above this is the mountains biome'),
    ('wetScale', 20000.0, 'wetness noise scale'), ('wetOct', 3, 'wetness octaves'), ('tempScale', 12000.0, 'warmth noise scale'), ('tempOct', 2, 'warmth octaves'),
    ('tempLat', 0.8, 'warmth falls by this per unit of latitude y'), ('tempNoise', 0.5, 'the warmth noise amplitude'),
    ('desertWet', 0.42, 'desert where wetness is below this ...'), ('desertTemp', 0.45, '... and warmth is above this'), ('forestWet', 0.55, 'forest where wetness is above this'),
])
grp('seeds: offsets added to the planet seed for each noise', [
    ('sRelief', 5000, 'relief'), ('sWet', 9000, 'wetness'), ('sTemp', 13000, 'warmth'), ('sDetail', 777, 'fine relief'), ('sPackEdge', 31, 'the north pack edge'),
    ('sSouthMask', 37, 'the south land mask'), ('sSouthRelief', 41, 'the south dome relief'), ('sRock', 43, 'rock through the ice'), ('sShelf', 47, 'the shelf'),
    ('sSea', 61, 'the polar sea floor'), ('sFloe', 71, 'floes'), ('sBerg', 83, 'icebergs'),
])
grp('ice: the poles (docs/world/planet-ice.md)', [
    ('polarY', 0.72, 'the caps begin at this latitude y (ordinary ground blends to sea there)'), ('blend', 0.10, 'the blend width in y'),
    ('seaNorth', -380.0, 'the north sea floor'), ('seaSouth', -330.0, 'the south sea floor'),
    ('seaNoiseScale', 7000.0, 'sea floor noise scale'), ('seaNoiseOct', 2, 'sea floor noise octaves'), ('seaNoiseAmp', 60.0, 'sea floor noise amplitude'),
    ('packEdgeY', 0.88, 'the pack is 0 thick at this y'), ('packWidth', 0.10, 'y over which the pack thickens to 1'),
    ('packNoiseScale', 14000.0, 'pack edge noise scale'), ('packNoiseOct', 3, 'pack edge noise octaves'), ('packNoiseAmp', 0.5, 'pack edge noise amplitude'),
    ('packMin', -0.05, 'floes only where the thickness is above this'),
    ('floeCell', 2200.0, 'floe cell size, units'), ('floePow', 0.8, 'the chance a cell is ice is thickness^floePow x floeCap'), ('floeCap', 1.05, 'floe chance scale'),
    ('floeR0', 0.28, 'floe radius (in cells) at 0 thickness'), ('floeR1', 0.42, 'floe radius gain at thickness 1'),
    ('floeH0', 10.0, 'floe height base, units'), ('floeH1', 28.0, 'floe height by the cell random'), ('floeThin0', 0.4, 'floe height scale at the edge'), ('floeThin1', 0.6, 'floe height scale gain with thickness'),
    ('bergCell', 1100.0, 'iceberg cell size'), ('bergRate', 0.12, 'the chance a cell holds a berg at the band centre (north)'),
    ('bergBandLo', -0.3, 'bergs only above this thickness'), ('bergBandHi', 0.5, 'and below this'), ('bergBandMid', 0.1, 'the band centre'), ('bergBandSlope', 1.6, 'the chance falls this fast off the centre'),
    ('bergRadius', 0.26, 'berg radius in cells'), ('bergH0', 45.0, 'berg height base'), ('bergH1', 170.0, 'berg height gain by the cell random'),
    ('southMaskY', 0.91, 'the south land mask is 0 at this y'), ('southWidth', 0.07, 'y per unit of the mask'),
    ('southMaskScale', 9000.0, 'mask noise scale'), ('southMaskOct', 3, 'mask noise octaves'), ('southMaskAmp', 1.4, 'mask noise amplitude (in mask units)'),
    ('domeBase', 180.0, 'the ice dome at the coast'), ('domeMul', 1500.0, 'dome height per unit of the mask'), ('domeMax', 1.4, 'the dome stops rising at this mask value'),
    ('domeReliefScale', 6000.0, 'dome relief noise scale'), ('domeReliefOct', 3, 'dome relief octaves'), ('domeReliefAmp', 900.0, 'dome relief amplitude'),
    ('rockHeight', 1500.0, 'rock shows through the ice above this'), ('rockScale', 2500.0, 'rock noise scale'), ('rockOct', 3, 'rock noise octaves'), ('rockNoise', 0.62, 'rock where the noise is above this'),
    ('shelfFrom', -0.55, 'the shelf runs from the mask 0 down to this'), ('shelfH', 36.0, 'the shelf height'),
    ('shelfNoiseScale', 2500.0, 'shelf noise scale'), ('shelfNoiseOct', 2, 'shelf noise octaves'), ('shelfNoiseAmp', 14.0, 'shelf noise amplitude'),
    ('southBergFrom', -1.3, 'bergs round the south shelf down to this mask value'), ('southBergRate', 0.07, 'the chance a cell holds a berg there'),
])
grp('places: cities and towns on the ordinary ground', [
    ('cities', 12, 'cities requested'), ('cityRadius', 6500.0, 'a city\'s radius, units'), ('cityTries', 80, 'candidates a city'),
    ('towns', 44, 'towns requested (about 3 in 4 find room)'), ('townRadius', 2437.5, 'a town\'s radius'), ('townTries', 40, 'candidates a town'),
    ('placeHMin', 60.0, 'a place stands on ground at least this high'), ('placeHMax', 1800.0, 'and at most this high'), ('placeYMax', 0.80, 'and not beyond this latitude y'),
    ('placeGap', 400.0, 'the least clear gap between two places, units'), ('scoreGap', 0.001, 'score per unit of clear gap'),
    ('scoreH0', 300.0, 'the preferred height'), ('scoreHW', 0.002, 'score lost per unit away from it'),
    ('placeSeedMul', 31, 'the stream is SimRng(seed x this + 1); the second pass + 2'), ('replaceTries', 800, 'candidates when a place that fell in a cap is placed again'),
])
grp('picker: the slice and Orb\'s minimum', [
    ('minCities', 2, 'a slice holds at least this many standing cities'), ('minTowns', 3, 'and towns'), ('minBiomes', 3, 'and biomes of biomeShare each'),
    ('biomeShare', 0.08, 'a biome counts when it covers this share of the length'), ('minLand', 0.5, 'and at least this share is land (ocean and sea ice are not)'),
    ('cityReach', 0.6, 'a city is on the slice when the line passes within this share of its radius'), ('townReach', 0.7, 'a town, this share'),
    ('samples', 96, 'points along the circle the minimum reads'), ('randomBearings', 4, 'random-bearing circles tried beside those through a city'),
    ('nMinCity', 0.15, 'a circle through the touch-down and a city needs the cross of the two at least this long'), ('nMinRandom', 0.3, 'a random-bearing circle, this long'),
    ('relaxCities', 1, 'the relaxed minimum (late in a run): standing cities'), ('relaxTowns', 4, 'towns'), ('relaxBiomes', 3, 'biomes'), ('relaxLand', 0.4, 'land share'),
    ('touchLand', 1, '1: the touch-down is redrawn until it is on land'), ('touchTries', 16, 'redraws'),
])
grp('wear: the run\'s damage per place, in whole numbers (docs/world/planet-module.md)', [
    ('craterCap', 400, 'craters kept per place; past it the two oldest merge'), ('foldDepthMax', 4096, 'a merged crater\'s depth cap, 1/16 units'),
    ('damagedPermille', 50, 'a place is damaged at this share (per thousand) of its buildings or people lost'),
    ('fallenPermille', 400, 'fallen when under this share (per thousand) of its buildings stand, or of its people are present'),
    ('slicePeople', 1800, 'the people of a full slice (today\'s arena)'), ('bandUnits', 2300.0, 'a mark within this lateral distance of the line is on the slice'),
])
grp('offers: three slices to choose from', [
    ('offerCount', 3, 'offers a chapter'), ('offerTries', 48, 'touch-downs tried for them'), ('offerMinSep', 20000.0, 'least distance between two offers\' touch-downs, units'),
])

doc = collections.OrderedDict()
doc['schema'] = 'biomes.planet/1'
doc['_about'] = ('The stored procedural planet (docs/world/planet-slice.md, planet-ice.md, planet-module.md; WorldPlanet). Every number of the planet function, the places, the slice picker, the wear list and the offers; '
                 'the function is a pure function of the planet seed and these numbers, in float64 scalars. "story" holds story planets by id (a fixed seed and a hand-placed list), empty for now.')
props = collections.OrderedDict()
for title, items in G.items():
    for k, v, why in items:
        doc[k] = v
        props[k] = {'type': 'integer' if isinstance(v, int) else 'number', 'description': why}
doc['story'] = {}
open(R + 'data/biomes/planet.json', 'w', encoding='utf-8', newline='').write(json.dumps(doc, indent=2, ensure_ascii=False) + '\n')

sch = collections.OrderedDict()
sch['$schema'] = 'https://json-schema.org/draft/2020-12/schema'
sch['$id'] = 'meridian/biomes-planet'
sch['title'] = 'biomes.planet/1'
sch['description'] = ('data/biomes/planet.json: the stored procedural planet (docs/world/planet-module.md; WorldPlanet). Terrain and biome thresholds, noise seeds, the polar ice, the places, the slice picker and its minimum, the wear list and the offers. '
                      'Every key is required (a number cannot vanish unseen). "story": story planets by id (empty for now). Version field: schema. Policy: closed except keys starting with an underscore.')
sch['type'] = 'object'
sch['required'] = ['schema'] + list(props.keys()) + ['story']
sch['properties'] = collections.OrderedDict()
sch['properties']['schema'] = {'const': 'biomes.planet/1'}
sch['properties']['_about'] = {'type': 'string'}
for k, v in props.items():
    sch['properties'][k] = v
sch['properties']['story'] = {'type': 'object', 'description': 'story planets by id: {seed, places}; empty for now'}
sch['additionalProperties'] = False
sch['patternProperties'] = {'^_': True}
open(R + 'tools/schemas/biomes-planet.schema.json', 'w', encoding='utf-8', newline='').write(json.dumps(sch, indent=2, ensure_ascii=False) + '\n')
print(len(props), 'keys')
