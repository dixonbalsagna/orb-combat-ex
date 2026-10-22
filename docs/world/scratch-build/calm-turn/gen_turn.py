"""A turn of the arena, illustrated from a real one (World, 2026-10-22): the globe with the ring before and after a calm-moment turn, the zone that stays, and the ring unrolled before and after.
python gen_turn.py <planet_grid.json> <turn.json> <out.svg> [seconds_into_loop]     (the last argument freezes the picture at that time, for checking)"""
import json, math, sys

grid = json.load(open(sys.argv[1]))
T = json.load(open(sys.argv[2]))
OUT = sys.argv[3]
FREEZE = float(sys.argv[4]) if len(sys.argv) > 4 else None
STEP = grid['step']
NLON = int(round(360 / STEP)); NLAT = int(round(180 / STEP))
RG = grid['grid']
PL = grid['places']
RAD = grid['R']
COLS = T['cols']
COLW = 32.0
PLANET_COLS = 4800
MID = COLS // 2
RP = RAD   # the planet's radius in units

COL = ['#6f9fc8', '#c3cf8a', '#5f9a68', '#e4c98a', '#9a9187', '#e1ebf4', '#c4dcea', '#b9a089', '#8c8fa0']
NAME = ['ocean', 'plains', 'forest', 'desert', 'mountains', 'ice sheet', 'sea ice']
INK = '#222a38'
MUTE = '#5d6878'
RED = '#d12f2f'
ZONE = '#1f6fe0'


def dot(a, b): return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]
def cross(a, b): return [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]
def unit(a):
    n = math.sqrt(dot(a, a)); return [a[0] / n, a[1] / n, a[2] / n]
def comb(a, x, b, y): return [a[0] * x + b[0] * y, a[1] * x + b[1] * y, a[2] * x + b[2] * y]
def fromll(lon, lat): return [math.cos(lat) * math.cos(lon), math.sin(lat), math.cos(lat) * math.sin(lon)]
def rot(v, axis, a):
    c, s = math.cos(a), math.sin(a)
    k = cross(axis, v); d = dot(axis, v)
    return [v[0] * c + k[0] * s + axis[0] * d * (1 - c), v[1] * c + k[1] * s + axis[1] * d * (1 - c), v[2] * c + k[2] * s + axis[2] * d * (1 - c)]


def ring_from(c, cols, t):
    st = min(1.0, cols / PLANET_COLS)
    ct = math.sqrt(1 - st * st) if st < 1 else 0.0
    d = dot(c, t)
    e1 = unit([t[0] - c[0] * d, t[1] - c[1] * d, t[2] - c[2] * d])
    e2 = unit(cross(c, e1))
    return {'u': e1, 'v': e2, 'c': c, 'st': st, 'ct': ct}


def ring_point(r, a):
    co, si = math.cos(a), math.sin(a)
    return [r['c'][i] * r['ct'] + r['st'] * (r['u'][i] * co + r['v'][i] * si) for i in range(3)]


def turned(spec, pc, deg):
    cols = spec['cols']
    r = ring_from(spec['c'], cols, spec['t'])
    st, ct = r['st'], r['ct']
    step = COLW / (RP * st)
    a = (pc - cols // 2) * step
    M = ring_point(r, a)
    co, si = math.cos(a), math.sin(a)
    Tg = unit([-r['u'][i] * si + r['v'][i] * co for i in range(3)])
    T2 = rot(Tg, M, deg * math.pi / 180)
    ng = unit(cross(M, T2))
    c2 = unit([M[i] * ct + ng[i] * st for i in range(3)])
    rm = ring_from(c2, cols, M)
    t2 = ring_point(rm, -a)
    return {'c': c2, 't': t2, 'cols': cols}


def biome_at(p):
    lat = math.asin(max(-1, min(1, p[1])))
    lon = math.atan2(p[2], p[0])
    j = min(NLAT - 1, max(0, int((lat * 180 / math.pi + 90) / STEP)))
    i = min(NLON - 1, max(0, int((lon * 180 / math.pi + 180) / STEP)))
    return RG[j][i]


specA = {'c': T['before']['ring']['c'], 't': T['before']['ring']['t'], 'cols': COLS}
pc = T['pivotCol']
deg = T['bearing']
specB = {'c': T['after']['ring']['c'], 't': T['after']['ring']['t'], 'cols': COLS}
ringA = ring_from(specA['c'], COLS, specA['t'])
stA = ringA['st']
M = ring_point(ringA, (pc - MID) * COLW / (RP * stA))

# the view: the pivot a little off the middle of the disc
EZ = unit(comb(M, 1.0, [0.0, 1.0, 0.0], 0.28))
EY = unit([-EZ[0] * EZ[1], 1 - EZ[1] * EZ[1], -EZ[2] * EZ[1]])
EX = cross(EY, EZ)
CX, CY, RR = 300.0, 345.0, 245.0
def proj(p): return (CX + RR * dot(p, EX), CY - RR * dot(p, EY), dot(p, EZ))
def pt(p): return '%.1f %.1f' % proj(p)[:2]

paths = {b: [] for b in range(7)}
for j in range(NLAT):
    for i in range(NLON):
        b = RG[j][i]
        lon0 = (-180 + i * STEP) * math.pi / 180; lon1 = lon0 + STEP * math.pi / 180
        lat0 = (-90 + j * STEP) * math.pi / 180; lat1 = lat0 + STEP * math.pi / 180
        cs = [fromll(lon0, lat0), fromll(lon1, lat0), fromll(lon1, lat1), fromll(lon0, lat1)]
        if any(dot(c, EZ) < 0.02 for c in cs):
            continue
        paths[b].append('M' + ' L'.join(pt(c) for c in cs) + 'Z')

LOOP = 16.0
F = 96


def phase(f):
    """0 for the first quarter (before), the turn over the second, 1 held, then back."""
    u = f / F
    if u < 0.2: return 0.0
    if u < 0.45:
        x = (u - 0.2) / 0.25; return x * x * (3 - 2 * x)
    if u < 0.75: return 1.0
    if u < 0.95:
        x = (u - 0.75) / 0.2; return 1 - x * x * (3 - 2 * x)
    return 0.0


NARC = 36
def ring_paths(r):
    EZv = EZ
    # visible half: z of p(a) = a0 cos(a) + b0 sin(a)
    z0 = dot(r['c'], EZv) * r['ct'] + r['st'] * dot(r['u'], EZv)
    zc = r['st'] * dot(r['u'], EZv)
    zs = r['st'] * dot(r['v'], EZv)
    A = math.hypot(zc, zs)
    phi = math.atan2(zs, zc)
    front = []; back = []
    for k in range(NARC + 1):
        a = phi - math.pi / 2 + math.pi * k / NARC
        front.append(ring_point(r, a))
        a2 = phi + math.pi / 2 + math.pi * k / NARC
        back.append(ring_point(r, a2))
    return 'M' + ' L'.join(pt(p) for p in front), 'M' + ' L'.join(pt(p) for p in back)


def zone_path(r):
    """The carried zone: the arc within Z units of the pivot, on the ring, as the front-facing line."""
    Z = T['Z']
    a0 = (pc - MID) * COLW / (RP * r['st'])
    half = Z / (RP * r['st'])
    pts = [ring_point(r, a0 - half + 2 * half * k / 24) for k in range(25)]
    return 'M' + ' L'.join(pt(p) for p in pts)


def fmt(vs): return ';'.join(vs)
T_ = 'begin="%.2fs"' % (-FREEZE) if FREEZE is not None else 'begin="0s"'
def anim(attr, values, discrete=False):
    return '<animate attributeName="%s" dur="%.0fs" repeatCount="indefinite" %s %s values="%s"/>' % (attr, LOOP, 'calcMode="discrete"' if discrete else 'calcMode="linear"', T_, fmt(values))


frames = []
for f in range(F + 1):
    ph = phase(f)
    sp = turned(specA, pc, deg * ph) if ph > 0 else specA
    r = ring_from(sp['c'], COLS, sp['t'])
    frames.append((ring_paths(r), zone_path(r), r))
fr_front = [fr[0][0] for fr in frames]
fr_back = [fr[0][1] for fr in frames]
fr_zone = [fr[1] for fr in frames]
swapped = ['1' if phase(f) >= 0.999 else '0' for f in range(F + 1)]   # after the turn is complete
shown_after = ['1' if (f / F) >= 0.45 and (f / F) < 0.95 else '0' for f in range(F + 1)]

W, H = 1100, 930
o = []
o.append('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" width="%d" height="%d" font-family="Segoe UI, Helvetica, Arial, sans-serif">' % (W, H, W, H))
o.append('<title>A turn of the arena</title>')
o.append('<rect width="%d" height="%d" fill="#f4f6f9"/>' % (W, H))
o.append('<text x="30" y="40" font-size="24" font-weight="700" fill="%s">A turn of the arena, from a real fight</text>' % INK)
o.append('<text x="30" y="64" font-size="14" fill="%s">Everhold, a Whole ring, the fighters at the pivot. The ring turns %.0f degrees about them; the blue stretch stays as it was. %.0f s a loop.</text>' % (MUTE, abs(deg), LOOP))
o.append('<defs><radialGradient id="sh" cx="0.38" cy="0.32" r="0.8"><stop offset="0" stop-color="#fff" stop-opacity="0.18"/><stop offset="0.6" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#0b1f3a" stop-opacity="0.38"/></radialGradient><clipPath id="gc"><circle cx="%.0f" cy="%.0f" r="%.0f"/></clipPath></defs>' % (CX, CY, RR))
o.append('<circle cx="%.0f" cy="%.0f" r="%.0f" fill="%s"/>' % (CX, CY, RR, COL[0]))
for b in range(7):
    if paths[b] and b != 0:
        o.append('<path d="%s" fill="%s" stroke="%s" stroke-width="0.6" stroke-linejoin="round"/>' % (' '.join(paths[b]), COL[b], COL[b]))
for pl in PL:
    q = unit([pl[1], pl[2], pl[3]])
    x, y, z = proj(q)
    if z > 0.12:
        if pl[0] == 0:
            o.append('<rect x="%.1f" y="%.1f" width="7" height="7" fill="#2a2f45" stroke="#fff" stroke-width="1"/>' % (x - 3.5, y - 3.5))
        else:
            o.append('<circle cx="%.1f" cy="%.1f" r="3" fill="#c0502d" stroke="#fff" stroke-width="0.8"/>' % (x, y))
o.append('<circle cx="%.0f" cy="%.0f" r="%.0f" fill="url(#sh)"/>' % (CX, CY, RR))
o.append('<circle cx="%.0f" cy="%.0f" r="%.0f" fill="none" stroke="#51627a" stroke-width="1.5"/>' % (CX, CY, RR))
# the old ring, held faintly
fA, bA = ring_paths(ringA)
o.append('<path d="%s" fill="none" stroke="#fff" stroke-width="5" opacity="0.5" clip-path="url(#gc)"/>' % fA)
o.append('<path d="%s" fill="none" stroke="#3a4558" stroke-width="2" stroke-dasharray="6 5" clip-path="url(#gc)"/>' % fA)
o.append('<path d="%s" fill="none" stroke="%s" stroke-width="2" stroke-dasharray="5 6" opacity="0.5" clip-path="url(#gc)">%s</path>' % (fr_back[0], RED, anim('d', fr_back)))
o.append('<path d="%s" fill="none" stroke="#fff" stroke-width="7" stroke-linecap="round" opacity="0.65">%s</path>' % (fr_front[0], anim('d', fr_front)))
o.append('<path d="%s" fill="none" stroke="%s" stroke-width="4" stroke-linecap="round">%s</path>' % (fr_front[0], RED, anim('d', fr_front)))
o.append('<path d="%s" fill="none" stroke="%s" stroke-width="9" stroke-linecap="round" opacity="0.45">%s</path>' % (fr_zone[0], ZONE, anim('d', fr_zone)))
mx, my, _ = proj(M)
for dx in (-7, 7):
    o.append('<circle cx="%.1f" cy="%.1f" r="6.5" fill="#fff" stroke="%s" stroke-width="2.5"/>' % (mx + dx, my, INK))
o.append('<text x="%.0f" y="%.0f" font-size="13" fill="%s" text-anchor="middle">the planet, seen from space: grey dashed the ring before, red the ring now</text>' % (CX, CY + RR + 22, MUTE))
# the right column
RX = 640
o.append('<text x="%d" y="112" font-size="17" font-weight="700" fill="%s">What a turn does</text>' % (RX, INK))
for i, t in enumerate(['The pair and the ground and buildings round them stay:',
                       'the blue stretch is {:,.0f} units each way, the same'.format(T['Z']),
                       'columns, craters, fallen towers and people.',
                       'Beyond it the ground is the new ring\'s, and the',
                       'places the new ring passes are laid fresh.',
                       'It happens on a calm moment, under a hard cut,',
                       'never in a brawl, at most %.0f degrees, 4 a fight.' % 10]):
    o.append('<text x="%d" y="%d" font-size="13.5" fill="%s">%s</text>' % (RX, 138 + i * 19, INK, t))
lx = RX; ly = 292
for i, b in enumerate([0, 1, 2, 3, 4, 5, 6, 7, 8]):
    nm = NAME[b] if b < 7 else ('town ground' if b == 7 else 'city ground')
    xx = lx + (i % 4) * 110; yy = ly + (i // 4) * 24
    o.append('<rect x="%d" y="%d" width="14" height="14" fill="%s" stroke="#7a8794" stroke-width="0.6"/><text x="%d" y="%d" font-size="12.5" fill="%s">%s</text>' % (xx, yy, COL[b], xx + 19, yy + 12, INK, nm))
o.append('<text x="%d" y="%d" font-size="12.5" fill="%s">Buildings: dark standing, orange hurt, red outline fallen; red ring a crater.</text>' % (RX, ly + 82, MUTE))
# the strips
SX, SW = 30, 1040
n = len(T['before']['cells'])
cw = SW / n
step = T['step']
def shifted(cells):
    k = (pc // step) - n // 2
    return [cells[(i + k) % n] for i in range(n)]
before = shifted(T['before']['cells'])
after = shifted(T['after']['cells'])
def strip(y, cells, title, blds, craterAt):
    o.append('<text x="%d" y="%d" font-size="14" font-weight="700" fill="%s">%s</text>' % (SX, y - 8, INK, title))
    for i in range(n):
        o.append('<rect x="%.2f" y="%d" width="%.2f" height="26" fill="%s"/>' % (SX + i * cw, y, cw + 0.3, COL[cells[i]]))
    # buildings, positioned by their column relative to the pivot
    for b in blds:
        col = b[0] / COLW
        rel = (col - pc + COLS / 2) % COLS - COLS / 2   # columns from the pivot, wrapped
        xx = SX + SW / 2 + rel / COLS * SW
        if xx < SX or xx > SX + SW:
            continue
        hh = max(3.0, min(16.0, b[2] / 60.0))
        wd = max(1.2, b[1] / COLW / COLS * SW)
        col_ = '#2a2f45' if b[3] == 1 and b[4] > 0.95 else ('#e08a2e' if b[3] == 1 else '#ffffff')
        stroke = '' if b[3] == 1 else ' stroke="%s" stroke-width="1"' % RED
        o.append('<rect x="%.2f" y="%.1f" width="%.2f" height="%.1f" fill="%s"%s/>' % (xx - wd / 2, y + 26 - hh, wd, hh, col_, stroke))
    if craterAt is not None:
        rel = (craterAt / COLW - pc + COLS / 2) % COLS - COLS / 2
        xx = SX + SW / 2 + rel / COLS * SW
        o.append('<circle cx="%.1f" cy="%d" r="4" fill="none" stroke="%s" stroke-width="2"/>' % (xx, y + 40, RED))
    # the pivot and the zone
    o.append('<line x1="%.0f" y1="%d" x2="%.0f" y2="%d" stroke="%s" stroke-width="2.5"/>' % (SX + SW / 2, y - 4, SX + SW / 2, y + 32, INK))
    zw = T['Z'] / COLW / COLS * SW
    o.append('<rect x="%.1f" y="%d" width="%.1f" height="30" fill="none" stroke="%s" stroke-width="2.5" stroke-dasharray="7 4"/>' % (SX + SW / 2 - zw, y - 2, 2 * zw, ZONE))
cr = T['crater'][0] if T['crater'][0] >= 0 else None
strip(650, before, 'Before: the whole ring, unrolled, the pair at the middle line', T['before']['blds'], cr)
strip(755, after, 'After the turn: inside the blue box nothing has changed; outside it is new ground and new places', T['after']['blds'], cr)
o.append('<text x="%d" y="%d" font-size="12.5" fill="%s">The strips are the sim\'s own (a real match on Everhold, a Whole ring turned %.0f degrees at 100 s); %d buildings before, %d after.</text>' % (SX, 824, MUTE, abs(deg), len(T['before']['blds']), len(T['after']['blds'])))
o.append('<rect x="20" y="%d" width="%d" height="78" rx="8" fill="#fff" stroke="#c9d1dc"/>' % (H - 96, W - 40))
cap = ['At a calm moment the arena turns a few degrees about the two fighters: the ground and buildings round them stay, the far side is new.',
       'A turn is a hard cut under the camera, never in a brawl: at most 10 degrees, 4 a fight, 60 seconds apart, so the drift stays small.',
       'This one is a real turn from the game\'s own code: the blue box is what carries over, and the fallen towers and the crater are still there.']
for i, t in enumerate(cap):
    o.append('<text x="38" y="%d" font-size="14.5" fill="%s">%s</text>' % (H - 70 + i * 24, INK, t))
o.append('</svg>')
open(OUT, 'w', encoding='utf-8').write('\n'.join(o))
print('wrote', OUT, 'KB', round(len('\n'.join(o)) / 1024))
