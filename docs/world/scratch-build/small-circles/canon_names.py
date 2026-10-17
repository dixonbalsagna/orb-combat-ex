"""A canon planet: names for planet 7's places, regions, landmarks and outposts, by Narrative's grammar (docs/narrative/place-names.md) and Legal's blocklist.
python canon_names.py <small.json> <outposts.json> <out dir>"""
import json, math, sys, os

small = json.load(open(sys.argv[1]))
outs = json.load(open(sys.argv[2]))
OUT = sys.argv[3]
os.makedirs(OUT, exist_ok=True)
banks = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'place_names_banks.json')))['banks']
STEM = banks['biome_stems']
CITY_STEMS = banks['city_stems']
SUF = banks['suffixes']
BLOCK = set(x.lower() for x in ['stonehaven', 'brassfield', 'longford', 'bellfield', 'kilnwick', 'mereby', 'oakfield', 'elmfield', 'hazelwick', 'ashford',
                                 'bellhaven', 'larkfield', 'longfield', 'stonebridge', 'stonegate', 'sunrise', 'wakefield', 'whitefield', 'whiteford', 'whitehaven', 'whiterock'])
BIOME_NAME = ['ocean', 'plains', 'forest', 'desert', 'mountains', 'ice', 'ice']


def fnv(s):
    h = 0x811c9dc5
    for ch in s.encode():
        h = ((h ^ ch) * 0x01000193) & 0xFFFFFFFF
    return h


used = set(['Longwater', 'Furrowlea', 'Deepholt', 'Sunwaste', 'Anvilfell'])   # the old fixed planet's region names, reserved for the regions they fit


def ok(name, join_a, join_b):
    n = name.lower().replace(' ', '')
    if len(name.replace(' ', '')) > (13 if ' ' in name else 12):
        return False
    if join_a and join_b and join_a[-1] == join_b[0]:
        return False
    if join_b == 'by' and join_a[-1] in 'yb':
        return False
    if n in BLOCK or name in used:
        return False
    return True


def make(seedtext, kind, biome):
    for salt in range(60):
        h = fnv('%s:%s:%d' % (seedtext, kind, salt))
        if kind == 'city':
            bank = CITY_STEMS if (h >> 20) & 1 else STEM[biome]
            stem = bank[h % len(bank)]
            suf = SUF['city'][(h >> 12) % len(SUF['city'])]
            name = (stem + suf).capitalize()
            if ok(name, stem, suf):
                used.add(name)
                return name
        elif kind == 'town':
            stem = STEM[biome][h % 12]
            suf = SUF['town'][(h >> 12) % len(SUF['town'])]
            name = (stem + suf).capitalize()
            if ok(name, stem, suf):
                used.add(name)
                return name
        elif kind == 'landmark':
            bank = CITY_STEMS if (h >> 20) & 1 else STEM[biome]
            stem = bank[h % len(bank)]
            noun = SUF['landmark'][(h >> 12) % len(SUF['landmark'])]
            name = stem.capitalize() + ' ' + noun
            if name not in used and (stem + noun).lower() not in BLOCK:
                used.add(name)
                return name
    return None


def lonlat(v):
    return math.degrees(math.atan2(v[2], v[0])), math.degrees(math.asin(max(-1, min(1, v[1]))))


def ang(a, b):
    return math.acos(max(-1, min(1, a[0] * b[0] + a[1] * b[1] + a[2] * b[2])))


places = small['places']
pb = small['placeBiome']
cities = [i for i, p in enumerate(places) if p['kind'] == 0]
towns = [i for i, p in enumerate(places) if p['kind'] == 1]
# the hub: the city nearest all the others (the capital's role)
def meand(i):
    return sum(ang(places[i]['v'], places[j]['v']) for j in cities if j != i) / (len(cities) - 1)
hub = min(cities, key=meand)
names = {}
names[hub] = 'Bellgate'
used.add('Bellgate')
# the old fixed planet's other names, where the geography matches
def nearest_to(i, group, far=False):
    pick = (max if far else min)([j for j in group if j not in names], key=lambda j: ang(places[i]['v'], places[j]['v']))
    return pick
kil = nearest_to(hub, towns)
names[kil] = 'Kilnstead'; used.add('Kilnstead')
far = nearest_to(hub, towns, far=True)
names[far] = 'Farwatch'; used.add('Farwatch')
# a coastal harbour town: the town on the plains or forest nearest the ocean cells of the grid
grid = small['grid']
def near_ocean(i):
    lo, la = lonlat(places[i]['v'])
    gi = int((lo + 180) / 3) % 120
    gj = min(59, int((la + 90) / 3))
    best = 99
    for dj in range(-6, 7):
        for di in range(-6, 7):
            jj = gj + dj
            if 0 <= jj < 60 and grid[jj][(gi + di) % 120] == 0:
                best = min(best, math.hypot(dj, di))
    return best
cand = sorted([j for j in towns if j not in names], key=near_ocean)
names[cand[0]] = 'Netmend'; used.add('Netmend')
for i, p in enumerate(places):
    if i in names:
        continue
    biome = BIOME_NAME[pb[i][0]] if pb[i][0] > 0 else 'plains'
    kind = 'city' if p['kind'] == 0 else 'town'
    names[i] = make('7:place:%d' % i, kind, biome)
# regions: flood fill of the 3 degree grid, longitude wraps
NJ, NI = 60, 120
seen = [[False] * NI for _ in range(NJ)]
comps = []
for j in range(NJ):
    for i in range(NI):
        if seen[j][i]:
            continue
        b = grid[j][i]
        cls = 0 if b == 0 else (5 if b in (5, 6) else b)
        if b == 6:
            cls = 5
        stack = [(j, i)]
        seen[j][i] = True
        cells = []
        while stack:
            cj, ci = stack.pop()
            cells.append((cj, ci))
            for dj, di in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nj, ni = cj + dj, (ci + di) % NI
                if 0 <= nj < NJ and not seen[nj][ni]:
                    bb = grid[nj][ni]
                    c2 = 0 if bb == 0 else (5 if bb in (5, 6) else bb)
                    if c2 == cls:
                        seen[nj][ni] = True
                        stack.append((nj, ni))
        comps.append((cls, cells))


def centroid(cells):
    # spherical mean of the cell centres
    x = y = z = 0.0
    for cj, ci in cells:
        la = math.radians(-88.5 + 3 * cj)
        lo = math.radians(-178.5 + 3 * ci)
        w = math.cos(la)
        x += math.cos(la) * math.cos(lo) * w
        y += math.sin(la) * w
        z += math.cos(la) * math.sin(lo) * w
    n = math.sqrt(x * x + y * y + z * z)
    return (x / n, y / n, z / n)


SUFR = {0: 'water', 1: 'lea', 2: 'holt', 3: 'waste', 4: 'fell', 5: 'waste'}
regions = []
want = {0: 3, 1: 2, 2: 2, 3: 2, 4: 3, 5: 2}
bycls = {}
for cls, cells in comps:
    bycls.setdefault(cls, []).append(cells)
OLD = {0: 'Longwater', 1: 'Furrowlea', 2: 'Deepholt', 3: 'Sunwaste', 4: 'Anvilfell', 5: None}
for cls in want:
    lst = sorted(bycls.get(cls, []), key=len, reverse=True)[:want[cls]]
    for k, cells in enumerate(lst):
        if len(cells) < 12:
            continue
        cen = centroid(cells)
        lo, la = lonlat(cen)
        if k == 0 and OLD[cls]:
            nm = OLD[cls]
        else:
            biome = BIOME_NAME[cls if cls != 5 else 5]
            nm = None
            suffix = SUFR[cls] if not (cls == 5 and la > 0) else 'water'
            for salt in range(60):
                h = fnv('7:region:%d:%d:%d' % (cls, k, salt))
                stem = STEM[biome][h % 12]
                cand_ = (stem + suffix).capitalize()
                if cand_ not in used and cand_.lower() not in BLOCK and stem[-1] != suffix[0]:
                    nm = cand_
                    used.add(nm)
                    break
        regions.append({'name': nm, 'biome': cls, 'cells': len(cells), 'lon': lo, 'lat': la, 'v': cen})
# the polar names
for r in regions:
    if r['biome'] == 5:
        r['label'] = 'ice sheet' if r['lat'] < 0 else 'sea ice'
# landmarks: one a city
landmarks = []
for i in cities:
    biome = BIOME_NAME[pb[i][0]] if pb[i][0] > 0 else 'plains'
    if i == hub:
        nm = 'Bell Tower'
        used.add(nm)
    else:
        nm = make('7:landmark:%d' % i, 'landmark', biome)
    landmarks.append({'place': i, 'name': nm})
# outposts: a name a station, 'watch' for a frontier
ICE = STEM['ice']
outposts = []
for kind, label in (('shelf', 'the shelf station'), ('inland', 'the high station'), ('floe', 'the floe station')):
    o = outs[kind]
    nm = None
    for salt in range(60):
        h = fnv('7:outpost:%s:%d' % (kind, salt))
        cand_ = (ICE[h % 12] + 'watch').capitalize()
        if cand_ not in used:
            nm = cand_
            used.add(nm)
            break
    outposts.append({'kind': kind, 'label': label, 'name': nm, 'v': o['v'], 'h': o['h']})
canon = {'schema': 'world.canon_planet/1', 'planet': 'Everhold', 'seed': 7,
         '_about': 'PROPOSAL (World, 2026-10-16): a canon planet for the story. Planet seed 7 (picture A2); names by Narrative\'s place-name grammar (docs/narrative/place-names.md) with Legal\'s blocklist (10 starting entries and the 11 real towns of RL-149); the old fixed planet\'s names kept where the geography matches. Names are proposals: Legal screens them, Orb picks.',
         'places': [{'id': i, 'kind': 'city' if p['kind'] == 0 else 'town', 'name': names[i], 'seed': fnv('7:place:%d' % i), 'biome': BIOME_NAME[pb[i][0]], 'lon': round(lonlat(p['v'])[0], 2), 'lat': round(lonlat(p['v'])[1], 2), 'radius': p['r']} for i, p in enumerate(places)],
         'landmarks': [{'place': l['place'], 'in': names[l['place']], 'name': l['name']} for l in landmarks],
         'regions': [{'name': r['name'], 'biome': BIOME_NAME[r['biome']], 'lon': round(r['lon'], 1), 'lat': round(r['lat'], 1), 'cells': r['cells']} for r in regions],
         'outposts': [{'name': o['name'], 'kind': o['kind'], 'lat': round(lonlat(o['v'])[1], 2), 'lon': round(lonlat(o['v'])[0], 2)} for o in outposts]}
json.dump(canon, open(os.path.join(OUT, 'everhold.json'), 'w', encoding='utf-8'), indent=1, ensure_ascii=False)
json.dump({'names': {str(k): v for k, v in names.items()}, 'regions': [{k: v for k, v in r.items()} for r in regions], 'landmarks': landmarks, 'outposts': outposts, 'hub': hub}, open(os.path.join(OUT, 'canon_work.json'), 'w'), indent=1)
print('hub', hub, names[hub], '| cities:', ', '.join(names[i] for i in cities))
print('towns:', ', '.join(names[i] for i in towns))
print('regions:', ', '.join('%s(%s)' % (r['name'], BIOME_NAME[r['biome']]) for r in regions))
print('landmarks:', ', '.join(l['name'] for l in landmarks))
print('outposts:', ', '.join(o['name'] for o in outposts))
print('unique:', len(used))
