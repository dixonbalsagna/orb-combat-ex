"""The shifting arena, illustrated (World, 2026-10-19; Orb, homework 31): a globe, the plane that cuts it through the fighters, the ring of ground where the plane meets
the surface, and the plane turning and drifting slowly over a fight so the ring sweeps across new ground. One animated SVG (SMIL, no script).
python gen_shift.py <planet_grid.json> <out.svg> [seconds_into_loop]     (the last argument freezes the picture at that time, for checking)"""
import json, math, sys

grid = json.load(open(sys.argv[1]))
OUT = sys.argv[2]
FREEZE = float(sys.argv[3]) if len(sys.argv) > 3 else None
STEP = grid['step']
NLON = int(round(360 / STEP)); NLAT = int(round(180 / STEP))
RG = grid['grid']
PL = grid['places']
RAD = grid['R']

COL = ['#6f9fc8', '#c3cf8a', '#5f9a68', '#e4c98a', '#9a9187', '#e1ebf4', '#c4dcea']
NAME = ['ocean', 'plains', 'forest', 'desert', 'mountains', 'ice sheet', 'sea ice']
CITY = '#2a2f45'
TOWN = '#c0502d'
RED = '#d12f2f'
INK = '#222a38'
MUTE = '#5d6878'


def dot(a, b): return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]
def cross(a, b): return [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]
def unit(a):
    n = math.sqrt(dot(a, a)); return [a[0] / n, a[1] / n, a[2] / n]
def comb(a, x, b, y): return [a[0] * x + b[0] * y, a[1] * x + b[1] * y, a[2] * x + b[2] * y]
def fromll(lon, lat): return [math.cos(lat) * math.cos(lon), math.sin(lat), math.cos(lat) * math.sin(lon)]


def biome_at(p):
    lat = math.asin(max(-1, min(1, p[1])))
    lon = math.atan2(p[2], p[0])
    j = min(NLAT - 1, max(0, int((lat * 180 / math.pi + 90) / STEP)))
    i = min(NLON - 1, max(0, int((lon * 180 / math.pi + 180) / STEP)))
    return RG[j][i]


# ---- the view: the direction that shows the most kinds of ground
best = None
for lo in range(-180, 180, 15):
    for la in range(-30, 61, 15):
        e = fromll(lo * math.pi / 180, la * math.pi / 180)
        seen = {}
        for j in range(0, NLAT, 2):
            for i in range(0, NLON, 2):
                p = fromll((-180 + (i + 0.5) * STEP) * math.pi / 180, (-90 + (j + 0.5) * STEP) * math.pi / 180)
                if dot(p, e) > 0.3:
                    seen[RG[j][i]] = seen.get(RG[j][i], 0) + 1
        tot = sum(seen.values())
        h = -sum(v / tot * math.log(v / tot) for v in seen.values())
        # prefer a view with a city in the middle third
        cit = sum(1 for pl in PL if pl[0] == 0 and dot(unit([pl[1], pl[2], pl[3]]), e) > 0.8)
        s = h + 0.35 * min(cit, 2)
        if best is None or s > best[0]:
            best = (s, lo, la, e)
_, VLON, VLAT, EZ = best
EY = unit([-EZ[0] * EZ[1], 1 - EZ[1] * EZ[1], -EZ[2] * EZ[1]])
EX = cross(EY, EZ)

# ---- the globe, drawn once
CX, CY, RR = 300.0, 335.0, 245.0
def proj(p): return (CX + RR * dot(p, EX), CY - RR * dot(p, EY), dot(p, EZ))
def pt(p): return '%.1f %.1f' % proj(p)[:2]

paths = {b: [] for b in range(7)}
st2 = STEP
for j in range(0, NLAT):
    for i in range(0, NLON):
        b = RG[j][i]
        lon0 = (-180 + i * STEP) * math.pi / 180; lon1 = lon0 + st2 * math.pi / 180
        lat0 = (-90 + j * STEP) * math.pi / 180; lat1 = lat0 + st2 * math.pi / 180
        cs = [fromll(lon0, lat0), fromll(lon1, lat0), fromll(lon1, lat1), fromll(lon0, lat1)]
        if any(dot(c, EZ) < 0.02 for c in cs):
            continue
        paths[b].append('M' + ' L'.join(pt(c) for c in cs) + 'Z')

# ---- the motion: the fighters' point M and the ring's tangent T over the loop
LOOP = 40.0
F = 120   # frames in a loop (a forward sweep and the way back)
# M0: a point near the middle of the view, the ring's start heading east-west on screen
M0 = unit(comb(EZ, 0.93, EX, -0.18)); M0 = unit(comb(M0, 1, EY, -0.12))
T0 = unit(comb(EX, 1, M0, -dot(EX, M0)))
# the drift's direction and size: the pair's point slides far enough over the ground to change what they stand on, and stays in view
def rot0(v, axis, a):
    c, s_ = math.cos(a), math.sin(a)
    k = cross(axis, v); d = dot(axis, v)
    return [v[0] * c + k[0] * s_ + axis[0] * d * (1 - c), v[1] * c + k[1] * s_ + axis[1] * d * (1 - c), v[2] * c + k[2] * s_ + axis[2] * d * (1 - c)]
_perp = unit(cross(M0, T0))
_bestd = None
for psi in range(0, 360, 15):
    ax = unit(rot0(_perp, M0, psi * math.pi / 180))
    for dd in (28, 34, 40):
        pts = [rot0(M0, ax, dd * math.pi / 180 * f) for f in (0.0, 0.5, 1.0)]
        if min(dot(q, EZ) for q in pts) < 0.45:
            continue
        sc = len(set(biome_at(q) for q in pts)) * 100 - dd
        if _bestd is None or sc > _bestd[0]:
            _bestd = (sc, ax, dd)
DRIFT_AXIS = _bestd[1]
DRIFT = _bestd[2] * math.pi / 180
TURN = 82 * math.pi / 180


def rot(v, axis, a):
    c, s = math.cos(a), math.sin(a)
    k = cross(axis, v)
    d = dot(axis, v)
    return [v[0] * c + k[0] * s + axis[0] * d * (1 - c), v[1] * c + k[1] * s + axis[1] * d * (1 - c), v[2] * c + k[2] * s + axis[2] * d * (1 - c)]


def smooth(x): return x * x * (3 - 2 * x)
def state(u):
    """u in 0..1: the sweep. Returns M, T."""
    d = smooth(u)
    M = unit(rot(M0, DRIFT_AXIS, DRIFT * d))
    T = unit(rot(T0, DRIFT_AXIS, DRIFT * d))                 # carried along
    T = unit(comb(T, 1, M, -dot(T, M)))
    T = unit(rot(T, M, TURN * smooth(u * u * 0.4 + u * 0.6)))   # then turned about M
    return M, T


def phase(f): return 0.5 - 0.5 * math.cos(2 * math.pi * f / F)   # 0 -> 1 -> 0 over the loop


NARC = 36
def ring_paths(M, T):
    a = math.atan2(dot(T, EZ), dot(M, EZ))
    front = []; back = []
    for k in range(NARC + 1):
        th = a - math.pi / 2 + math.pi * k / NARC
        front.append(comb(M, math.cos(th), T, math.sin(th)))
        th2 = a + math.pi / 2 + math.pi * k / NARC
        back.append(comb(M, math.cos(th2), T, math.sin(th2)))
    f = 'M' + ' L'.join(pt(p) for p in front)
    b = 'M' + ' L'.join(pt(p) for p in back)
    return f, b


def sheet(M, T):
    s = 1.08
    cs = [comb(M, s, T, s), comb(M, -s, T, s), comb(M, -s, T, -s), comb(M, s, T, -s)]
    return 'M' + ' L'.join(pt(p) for p in cs) + 'Z'


def fighters(M, T):
    out = []
    for th in (-0.075, 0.075):
        p = comb(M, math.cos(th), T, math.sin(th))
        x, y, z = proj(p)
        out.append((x, y))
    return out


# ---- the unrolled ring: 96 cells, centred on the fighters
NC_ = 96
def cells(M, T):
    ground = []; sett = []
    for i in range(NC_):
        th = -math.pi + (i + 0.5) * 2 * math.pi / NC_
        p = comb(M, math.cos(th), T, math.sin(th))
        ground.append(COL[biome_at(p)])
        s = ''
        for pl in PL:
            q = unit([pl[1], pl[2], pl[3]])
            ang = math.acos(max(-1, min(1, dot(p, q))))
            if ang < pl[4] / RAD * 0.7:
                s = CITY if pl[0] == 0 else TOWN
                if pl[0] == 0:
                    break
        sett.append(s or 'none')
    return ground, sett


def describe(M, T):
    """What the fighters stand on: the runs of ground within 30 degrees either side, west to east."""
    runs = []
    for k in range(-30, 31, 3):
        th = k * math.pi / 180
        p = comb(M, math.cos(th), T, math.sin(th))
        b = NAME[biome_at(p)]
        s = ''
        for pl in PL:
            q = unit([pl[1], pl[2], pl[3]])
            if math.acos(max(-1, min(1, dot(p, q)))) < pl[4] / RAD * 0.7:
                s = ' (city)' if pl[0] == 0 else ' (town)'
                break
        lab = b + s
        if not runs or runs[-1] != lab:
            runs.append(lab)
    here = None
    p = M
    here = NAME[biome_at(p)]
    return here, runs


# ---- the three moments
MOMENTS = [('A', 0.0), ('B', 0.5), ('C', 1.0)]
mdesc = []
for lab, u in MOMENTS:
    M, T = state(u)
    mdesc.append((lab, u, cells(M, T), describe(M, T)))


def fmt(vs): return ';'.join(vs)
T_ = 'begin="%.2fs"' % (-FREEZE) if FREEZE is not None else 'begin="0s"'
def anim(attr, values, discrete=False):
    return '<animate attributeName="%s" dur="%.0fs" repeatCount="indefinite" %s %s values="%s"/>' % (attr, LOOP, 'calcMode="discrete"' if discrete else 'calcMode="linear"', T_, fmt(values))


frames = [state(phase(f)) for f in range(F + 1)]
fr_front = []; fr_back = []; fr_sheet = []; fr_f1x = []; fr_f1y = []; fr_f2x = []; fr_f2y = []; fr_g = [[] for _ in range(NC_)]; fr_s = [[] for _ in range(NC_)]
for (M, T) in frames:
    a, b = ring_paths(M, T)
    fr_front.append(a); fr_back.append(b); fr_sheet.append(sheet(M, T))
    (x1, y1), (x2, y2) = fighters(M, T)
    fr_f1x.append('%.1f' % x1); fr_f1y.append('%.1f' % y1); fr_f2x.append('%.1f' % x2); fr_f2y.append('%.1f' % y2)
    g, s = cells(M, T)
    for i in range(NC_):
        fr_g[i].append(g[i]); fr_s[i].append(s[i])

W, H = 1100, 1010
o = []
o.append('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" width="%d" height="%d" font-family="Segoe UI, Helvetica, Arial, sans-serif">' % (W, H, W, H))
o.append('<title>A shifting arena: the ring of ground under the fight</title>')
o.append('<rect width="%d" height="%d" fill="#f4f6f9"/>' % (W, H))
o.append('<text x="30" y="40" font-size="24" font-weight="700" fill="%s">The arena can move: the ring of ground under the fight</text>' % INK)
o.append('<text x="30" y="64" font-size="14" fill="%s">The planet is Everhold (seed 7), the canon planet. Red is the arena: where a flat plane through the fighters cuts the surface. Press nothing: it plays by itself, 40 s a loop.</text>' % MUTE)
# the globe
o.append('<defs><radialGradient id="sh" cx="0.38" cy="0.32" r="0.8"><stop offset="0" stop-color="#fff" stop-opacity="0.18"/><stop offset="0.6" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#0b1f3a" stop-opacity="0.38"/></radialGradient><clipPath id="gc"><circle cx="%.0f" cy="%.0f" r="%.0f"/></clipPath><clipPath id="sc"><rect x="10" y="84" width="600" height="528"/></clipPath></defs>' % (CX, CY, RR))
o.append('<circle cx="%.0f" cy="%.0f" r="%.0f" fill="%s"/>' % (CX, CY, RR, COL[0]))
for b in range(7):
    if paths[b] and b != 0:
        o.append('<path d="%s" fill="%s" stroke="%s" stroke-width="0.6" stroke-linejoin="round"/>' % (' '.join(paths[b]), COL[b], COL[b]))
# places
for pl in PL:
    q = unit([pl[1], pl[2], pl[3]])
    x, y, z = proj(q)
    if z > 0.12:
        if pl[0] == 0:
            o.append('<rect x="%.1f" y="%.1f" width="7" height="7" fill="%s" stroke="#fff" stroke-width="1"/>' % (x - 3.5, y - 3.5, CITY))
        else:
            o.append('<circle cx="%.1f" cy="%.1f" r="3" fill="%s" stroke="#fff" stroke-width="0.8"/>' % (x, y, TOWN))
o.append('<circle cx="%.0f" cy="%.0f" r="%.0f" fill="url(#sh)"/>' % (CX, CY, RR))
o.append('<circle cx="%.0f" cy="%.0f" r="%.0f" fill="none" stroke="#51627a" stroke-width="1.5"/>' % (CX, CY, RR))
# the far half of the ring (behind the planet), the plane, the near half, the fighters
o.append('<path d="%s" fill="none" stroke="%s" stroke-width="2" stroke-dasharray="5 6" opacity="0.55" clip-path="url(#gc)">%s</path>' % (fr_back[0], RED, anim('d', fr_back)))
o.append('<path d="%s" fill="%s" fill-opacity="0.09" stroke="%s" stroke-opacity="0.35" stroke-width="1.2" clip-path="url(#sc)">%s</path>' % (fr_sheet[0], RED, RED, anim('d', fr_sheet)))
o.append('<path d="%s" fill="none" stroke="#fff" stroke-width="7" stroke-linecap="round" opacity="0.65">%s</path>' % (fr_front[0], anim('d', fr_front)))
o.append('<path d="%s" fill="none" stroke="%s" stroke-width="4" stroke-linecap="round">%s</path>' % (fr_front[0], RED, anim('d', fr_front)))
for k, (xs, ys) in enumerate(((fr_f1x, fr_f1y), (fr_f2x, fr_f2y))):
    o.append('<circle cx="%s" cy="%s" r="6.5" fill="#fff" stroke="%s" stroke-width="2.5">%s%s</circle>' % (xs[0], ys[0], INK, anim('cx', xs), anim('cy', ys)))
o.append('<text x="%.0f" y="%.0f" font-size="13" fill="%s" text-anchor="middle">the planet, seen from space</text>' % (CX, CY + RR + 18, MUTE))
# the right column: how to read it, legend, clock
RX = 640
o.append('<text x="%d" y="112" font-size="17" font-weight="700" fill="%s">How to read it</text>' % (RX, INK))
for i, t in enumerate(['The faint red sheet is the plane. It passes through',
                       'the two fighters (the white dots).',
                       'The red line is the ring, where the plane meets the',
                       'ground: the only ground they can fly over and land on.',
                       'The dashed part is the far side of the planet.',
                       'Over the fight the plane turns and drifts, so the ring',
                       'slides across new ground.']):
    o.append('<text x="%d" y="%d" font-size="13.5" fill="%s">%s</text>' % (RX, 136 + i * 19, INK, t))
lx = RX; ly = 284
for i, b in enumerate([0, 1, 2, 3, 4, 5, 6]):
    xx = lx + (i % 4) * 110; yy = ly + (i // 4) * 24
    o.append('<rect x="%d" y="%d" width="14" height="14" fill="%s" stroke="#7a8794" stroke-width="0.6"/><text x="%d" y="%d" font-size="12.5" fill="%s">%s</text>' % (xx, yy, COL[b], xx + 19, yy + 12, INK, NAME[b]))
o.append('<rect x="%d" y="%d" width="10" height="10" fill="%s"/><text x="%d" y="%d" font-size="12.5" fill="%s">city</text>' % (lx + 330, ly + 24 + 2, CITY, lx + 346, ly + 24 + 12, INK))
o.append('<circle cx="%d" cy="%d" r="5" fill="%s"/><text x="%d" y="%d" font-size="12.5" fill="%s">town</text>' % (lx + 392, ly + 24 + 7, TOWN, lx + 402, ly + 24 + 12, INK))
# the clock
CLX, CLY, CLW = RX, 385, 420
o.append('<text x="%d" y="%d" font-size="13" fill="%s">The fight, start to end (the picture plays it forward and back)</text>' % (RX, CLY - 10, MUTE))
o.append('<rect x="%d" y="%d" width="%d" height="8" rx="4" fill="#d6dce5"/>' % (CLX, CLY, CLW))
for lab, u in MOMENTS:
    xx = CLX + CLW * u
    o.append('<circle cx="%.0f" cy="%d" r="11" fill="#fff" stroke="%s" stroke-width="1.5"/><text x="%.0f" y="%d" font-size="13" font-weight="700" text-anchor="middle" fill="%s">%s</text>' % (xx, CLY + 4, MUTE, xx, CLY + 9, INK, lab))
ph = [CLX + CLW * phase(f) for f in range(F + 1)]
o.append('<circle cx="%.0f" cy="%d" r="6" fill="%s" stroke="#fff" stroke-width="1.5">%s</circle>' % (ph[0], CLY + 4, RED, anim('cx', ['%.1f' % v for v in ph])))
# the three moments, what they stand on
my = 440
for lab, u, (g, s), (here, runs) in mdesc:
    o.append('<text x="%d" y="%d" font-size="14" font-weight="700" fill="%s">Moment %s</text>' % (RX, my, INK, lab))
    o.append('<text x="%d" y="%d" font-size="13" fill="%s">They stand on %s.</text>' % (RX + 86, my, INK, here))
    seq = ', '.join(runs[:5])
    o.append('<text x="%d" y="%d" font-size="12" fill="%s">Ring, west to east: %s</text>' % (RX, my + 18, MUTE, seq if len(seq) < 52 else seq[:49] + '...'))
    my += 46
# the live strip: the whole ring unrolled
SX, SW = 30, 1040
cw = SW / NC_
sy = 665
o.append('<text x="%d" y="%d" font-size="14" font-weight="700" fill="%s">The whole ring, unrolled: every point the fighters could touch down on (they are at the middle line)</text>' % (SX, sy - 38, INK))
o.append('<text x="%d" y="%d" font-size="12.5" fill="%s">Live: this strip is the red line above, and it changes as the plane turns. Bars on top mark cities and towns.</text>' % (SX, sy - 20, MUTE))
for i in range(NC_):
    o.append('<rect x="%.2f" y="%d" width="%.2f" height="34" fill="%s" stroke="#ffffff" stroke-opacity="0.35" stroke-width="0.4">%s</rect>' % (SX + i * cw, sy + 8, cw + 0.3, fr_g[i][0], anim('fill', fr_g[i], True)))
    sv = fr_s[i]
    o.append('<rect x="%.2f" y="%d" width="%.2f" height="7" fill="%s" fill-opacity="%s">%s%s</rect>' % (SX + i * cw, sy, cw + 0.3, CITY if sv[0] == CITY else TOWN, '1' if sv[0] != 'none' else '0',
                                                                                                    anim('fill', [v if v != 'none' else TOWN for v in sv], True),
                                                                                                    anim('fill-opacity', ['0' if v == 'none' else '1' for v in sv], True)))
mx = SX + SW / 2
o.append('<line x1="%.0f" y1="%d" x2="%.0f" y2="%d" stroke="%s" stroke-width="2.5"/>' % (mx, sy - 4, mx, sy + 46, RED))
# the three frozen strips
fy = 745
for lab, u, (g, s), (here, runs) in mdesc:
    o.append('<text x="%d" y="%d" font-size="13" font-weight="700" fill="%s">%s</text>' % (SX - 2, fy + 15, INK, lab))
    for i in range(NC_):
        o.append('<rect x="%.2f" y="%d" width="%.2f" height="20" fill="%s"/>' % (SX + 14 + i * (SW - 14) / NC_, fy, (SW - 14) / NC_ + 0.3, g[i]))
        if s[i] != 'none':
            o.append('<rect x="%.2f" y="%d" width="%.2f" height="5" fill="%s"/>' % (SX + 14 + i * (SW - 14) / NC_, fy - 6, (SW - 14) / NC_ + 0.3, s[i]))
    o.append('<line x1="%.0f" y1="%d" x2="%.0f" y2="%d" stroke="%s" stroke-width="2"/>' % (SX + 14 + (SW - 14) / 2, fy - 8, SX + 14 + (SW - 14) / 2, fy + 24, RED))
    fy += 50
# the caption: three lines
o.append('<rect x="20" y="%d" width="%d" height="78" rx="8" fill="#fff" stroke="#c9d1dc"/>' % (H - 96, W - 40))
cap = ['The arena is a ring: the line where a flat plane through the fighters cuts the planet. They fly along it and land on it.',
       'If the plane turns and drifts during the fight, the ring slides over new ground: what they land on, and what lies ahead and behind, changes.',
       'A, B and C are the same fight at three moments; the strips show the whole ring each time, and what the fighters would see change.']
for i, t in enumerate(cap):
    o.append('<text x="38" y="%d" font-size="14.5" fill="%s">%s</text>' % (H - 70 + i * 24, INK, t))
o.append('</svg>')
open(OUT, 'w', encoding='utf-8').write('\n'.join(o))
print('wrote', OUT, 'view', VLON, VLAT, 'size KB', round(len('\n'.join(o)) / 1024))
for lab, u, c, (here, runs) in mdesc:
    print(lab, here, runs)
