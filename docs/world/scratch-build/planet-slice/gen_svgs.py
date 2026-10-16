"""Planet-slice diagrams from the prototype generator's own output (planet_12.json).  python gen_svgs.py <json> <outdir>"""
import json, math, sys, os

d = json.load(open(sys.argv[1]))
OUT = sys.argv[2]
os.makedirs(OUT, exist_ok=True)
R = d['R']
L = d['L']
BIO = ['ocean', 'plains', 'forest', 'desert', 'mountains']
COL = ['#6f9fc8', '#c3cf8a', '#5f9a68', '#e4c98a', '#9a9187']
INK = '#1d2230'
SOFT = '#5a6070'
BG = '#fbfaf6'
CITY = '#2a2f45'
TOWN = '#c0502d'
FONT = 'font-family="Segoe UI, system-ui, Arial, sans-serif"'


def vec(a): return tuple(a)
def dot(a, b): return a[0]*b[0] + a[1]*b[1] + a[2]*b[2]
def cross(a, b): return (a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0])
def add(a, b): return (a[0]+b[0], a[1]+b[1], a[2]+b[2])
def mul(a, k): return (a[0]*k, a[1]*k, a[2]*k)
def norm(a):
    n = math.sqrt(dot(a, a)); return (a[0]/n, a[1]/n, a[2]/n)


def basis(c):
    ex = norm(cross((0, 1, 0), c))
    ey = cross(c, ex)
    return ex, ey, c


class Globe:
    def __init__(self, cx, cy, rad, centre):
        self.cx, self.cy, self.rad = cx, cy, rad
        self.ex, self.ey, self.ez = basis(norm(centre))

    def proj(self, p):
        return (self.cx + self.rad * dot(p, self.ex), self.cy - self.rad * dot(p, self.ey), dot(p, self.ez))

    def cap(self, centre, ang, n=28):
        """a small circle of angular radius ang around centre, as projected points"""
        c = norm(centre)
        a = norm(cross(c, (0.3, 0.9, 0.2)))
        b = cross(c, a)
        pts = []
        for i in range(n):
            t = 2*math.pi*i/n
            p = add(mul(c, math.cos(ang)), add(mul(a, math.sin(ang)*math.cos(t)), mul(b, math.sin(ang)*math.sin(t))))
            pts.append(self.proj(p))
        return pts


def globe_svg(g, grid, places, circles, pins, labels=False):
    o = []
    o.append('<circle cx="%.1f" cy="%.1f" r="%.1f" fill="#dfe8f1" stroke="%s" stroke-width="1.5"/>' % (g.cx, g.cy, g.rad, INK))
    nlat, nlon = len(grid), len(grid[0])
    stp = 180.0 / nlat
    for j in range(nlat):
        la = math.radians(-90 + stp * (j + 0.5))
        for i in range(nlon):
            lo = math.radians(-180 + stp * (i + 0.5))
            ps = []
            ok = True
            h2 = stp / 2
            for dla, dlo in ((-h2, -h2), (-h2, h2), (h2, h2), (h2, -h2)):
                a = la + math.radians(dla); b = lo + math.radians(dlo)
                p = (math.cos(a)*math.cos(b), math.sin(a), math.cos(a)*math.sin(b))
                q = g.proj(p)
                if q[2] < 0.0: ok = False
                ps.append(q)
            if not ok: continue
            o.append('<polygon points="%s" fill="%s" stroke="%s" stroke-width="0.6"/>' % (' '.join('%.1f,%.1f' % (q[0], q[1]) for q in ps), COL[grid[j][i]], COL[grid[j][i]]))
    # settlement footprints
    for pl in places:
        c = tuple(pl['v'])
        if g.proj(c)[2] < 0.05: continue
        pts = g.cap(c, pl['r']/R)
        if all(p[2] > -0.05 for p in pts):
            o.append('<polygon points="%s" fill="%s" fill-opacity="%s" stroke="%s" stroke-width="1"/>' % (' '.join('%.1f,%.1f' % (p[0], p[1]) for p in pts), CITY if pl['kind'] == 'city' else TOWN, '0.28' if pl['kind'] == 'city' else '0.35', CITY if pl['kind'] == 'city' else TOWN))
        q = g.proj(c)
        if pl['kind'] == 'city':
            o.append('<rect x="%.1f" y="%.1f" width="8" height="8" fill="%s" stroke="#fff" stroke-width="1"/>' % (q[0]-4, q[1]-4, CITY))
        else:
            o.append('<circle cx="%.1f" cy="%.1f" r="3.2" fill="%s" stroke="#fff" stroke-width="0.8"/>' % (q[0], q[1], TOWN))
    for cir in circles:
        n = cir['n']; col = cir.get('col', INK)
        u = norm(cross(n, (0.3, 0.9, 0.2)))
        v = cross(n, u)
        front, back = [], []
        for k in range(121):
            t = 2*math.pi*k/120
            p = add(mul(u, math.cos(t)), mul(v, math.sin(t)))
            q = g.proj(p)
            (front if q[2] >= 0 else back).append((q, k))
        def runs(pts):
            out, cur = [], []
            last = None
            for q, k in pts:
                if last is not None and k != last + 1:
                    out.append(cur); cur = []
                cur.append(q); last = k
            if cur: out.append(cur)
            return out
        for r_ in runs(front):
            if len(r_) > 1:
                o.append('<polyline points="%s" fill="none" stroke="%s" stroke-width="%s" stroke-opacity="%s" %s/>' % (' '.join('%.1f,%.1f' % (q[0], q[1]) for q in r_), col, cir.get('w', 2), cir.get('op', 1), cir.get('dash', '')))
    for pin in pins:
        q = g.proj(tuple(pin['v']))
        if q[2] > 0:
            o.append('<circle cx="%.1f" cy="%.1f" r="6" fill="#fff" stroke="%s" stroke-width="3"/>' % (q[0], q[1], pin.get('col', '#d6336c')))
    return '\n'.join(o)


def text(x, y, s, size=13, w='400', fill=INK, anchor='start', extra=''):
    return '<text x="%.1f" y="%.1f" font-size="%d" font-weight="%s" fill="%s" text-anchor="%s" %s %s>%s</text>' % (x, y, size, w, fill, anchor, '' if 'font-family' in extra else FONT, extra, s)


def head(w, h, title, sub):
    return ['<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" width="%d" height="%d">' % (w, h, w, h),
            '<rect width="%d" height="%d" fill="%s"/>' % (w, h, BG),
            text(24, 34, title, 20, '700'), text(24, 56, sub, 13, '400', SOFT)]


def legend(x, y):
    o = []
    cx = x
    for i, b in enumerate(BIO):
        o.append('<rect x="%d" y="%d" width="14" height="14" fill="%s"/>' % (cx, y, COL[i]))
        o.append(text(cx+19, y+12, b, 12))
        cx += 25 + 8*len(b)
    o.append('<rect x="%d" y="%d" width="10" height="10" fill="%s"/>' % (cx+4, y+2, CITY)); o.append(text(cx+19, y+12, 'city', 12)); cx += 62
    o.append('<circle cx="%d" cy="%d" r="4.5" fill="%s"/>' % (cx+5, y+7, TOWN)); o.append(text(cx+16, y+12, 'town', 12))
    return o


def strip(x0, y0, w, h, sl, shift, touch=True, hmax=3600.0):
    """The unrolled slice: heights as a ground profile with biome colours, settlement chords on the axis. Touch-down at the middle."""
    o = []
    prof = sl['profile']
    n = len(prof)
    sx = lambda s: x0 + w * (((s / L) + shift) % 1.0)
    base = y0 + h
    # biome band under the profile
    bw = w / n
    for k in range(n):
        xk = x0 + w * (((k / n) + shift) % 1.0)
        hh = prof[k][0]
        top = base - max(2.0, (min(max(hh, 0.0), hmax) / hmax) * (h - 18)) - 6
        if hh < 0: top = base - 8
        o.append('<rect x="%.2f" y="%.1f" width="%.2f" height="%.1f" fill="%s"/>' % (xk, top, bw+0.6, base-top, COL[prof[k][1]]))
    # axis
    o.append('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="%s" stroke-width="1"/>' % (x0, base, x0+w, base, INK))
    return o, sx, base


def city_chord(o, sx, base, h_item, x0, w, sl):
    pass


# ================================================================== (a) the planet stored
def fig_a():
    W, H = 1000, 700
    o = head(W, H, 'A. The whole planet, stored', 'What a seed makes: a sphere of biomes, 12 cities and about 30 towns, each with a place, a size and a seed. Drawn from the prototype generator (seed %d).' % d['seed'])
    sl = d['slices'][0]
    g = Globe(270, 330, 215, (0.62, 0.35, 0.70))
    o.append(globe_svg(g, d['grid'], d['places'], [], []))
    o += legend(40, 575)
    o.append(text(40, 606, 'Shaded discs are the reach of each settlement.', 12, '400', SOFT))
    o.append(text(40, 624, 'Planet radius %d units: a great circle is 153,600 units, the length of today' % round(R) + chr(39) + 's arena.', 12, '400', SOFT))
    x = 560
    o.append(text(x, 100, 'What is stored', 16, '700'))
    rows = [
        ('The seed', '8 bytes. The planet is a pure function of it.', '#1d2230'),
        ('The places', '12 cities + about 31 towns + their landmarks: a place, a size, a kind and a seed each. About 48 bytes a record: ~2 KB.', CITY),
        ('A coarse map, if wanted', '6 faces x 128 x 128 cells of 300 units, 4 bytes each: 384 KB. For a map screen and a fast read; it can be thrown away and rebuilt from the seed.', '#5a6070'),
        ('Wear, if Orb wants it', 'Craters and levelled buildings as a short list per place (a few KB), so a flattened city stays flat next fight.', TOWN),
    ]
    y = 124
    for t, s, c in rows:
        o.append('<rect x="%d" y="%d" width="6" height="64" fill="%s"/>' % (x, y, c))
        o.append(text(x+16, y+18, t, 14, '700'))
        words = s.split(' ')
        line, ly = '', y + 38
        for wd in words:
            if len(line) + len(wd) > 56:
                o.append(text(x+16, ly, line, 12.5, '400', SOFT)); ly += 16; line = ''
            line += wd + ' '
        o.append(text(x+16, ly, line, 12.5, '400', SOFT))
        y += 82
    o.append(text(x, 470, 'What is NOT stored', 16, '700'))
    o.append(text(x, 494, 'The ground itself. At the sim\'s 32-unit columns the whole sphere would be', 12.5, '400', SOFT))
    o.append(text(x, 510, '7.3 million cells, about 14.6 MB at two bytes. The slice reads only its own', 12.5, '400', SOFT))
    o.append(text(x, 526, '4,800 columns (19 KB) from the seed when a fight starts.', 12.5, '400', SOFT))
    # size bars (log-ish feel with plain widths)
    o.append(text(x, 566, 'Sizes', 13, '700'))
    bars = [('seed + places', 2.0, '#2a2f45'), ('coarse map', 384.0, '#5a6070'), ('every column', 14950.0, '#c9ccd6')]
    by = 580
    for nme, kb, c in bars:
        wd = max(3.0, 300.0 * kb / 14950.0)
        o.append('<rect x="%d" y="%d" width="%.1f" height="12" fill="%s"/>' % (x, by, wd, c))
        o.append(text(x + wd + 8, by + 11, '%s  %s' % (nme, ('%.0f KB' % kb) if kb < 1000 else '14.6 MB'), 11.5, '400', INK))
        by += 17
    o.append('</svg>')
    open(os.path.join(OUT, 'a-planet-stored.svg'), 'w', encoding='utf-8').write('\n'.join(o))


# ================================================================== (b) how a fight picks its slice
def fig_b():
    W, H = 1000, 830
    sl = d['slices'][0]
    o = head(W, H, 'B. How a fight picks its slice', 'A touch-down point and a great circle through it; the circle is kept when it meets Orb\'s minimum. Then the circle is read as the arena.')
    T = tuple(sl['touch']); n = tuple(sl['n'])
    v = cross(n, T)
    g = Globe(220, 215, 150, norm(add(T, mul(v, 0.45))))
    # candidate circles: through T and each city (a few), grey; the chosen one in colour
    cands = []
    for pl in d['places']:
        if pl['kind'] == 'city':
            nn = cross(T, tuple(pl['v']))
            if math.sqrt(dot(nn, nn)) > 0.15:
                cands.append({'n': norm(nn), 'col': '#9aa0ae', 'w': 1.2, 'op': 0.8})
    cands.append({'n': n, 'col': '#d6336c', 'w': 3})
    o.append(globe_svg(g, d['grid'], d['places'], cands, [{'v': T}]))
    o.append(text(410, 90, '1  Touch-down point T', 14, '700'))
    o.append(text(410, 108, 'Random on the planet (or named by a story level).', 12.5, '400', SOFT))
    o.append(text(410, 134, '2  Candidate circles', 14, '700'))
    o.append(text(410, 152, 'The great circle through T and each city (grey), plus a few of random bearing.', 12.5, '400', SOFT))
    o.append(text(410, 178, '3  Test, in a seeded order, the first that passes wins (pink)', 14, '700'))
    for i, s in enumerate(['at least 2 cities and 3 towns within reach of the line', 'at least 3 biomes of 8% each, at least half of it land', 'none passes (about 8% of touch-downs with 12 cities): move T, or relax to one city + five towns']):
        o.append(text(426, 198 + 18*i, '- ' + s, 12.5, '400', SOFT))
    o.append(text(410, 268, '4  Read the circle as the arena', 14, '700'))
    o.append(text(426, 288, 'column i sits at p(i) = cos(i x 32 / R) u  +  sin(i x 32 / R) v', 12.5, '400', INK, extra='font-family="Consolas, monospace"'))
    o.append(text(426, 306, 'u = T, v = (n x T): only sin, cos and sqrt, our own and exact. No inverse trig.', 12.5, '400', SOFT))
    o.append(text(426, 324, 'height(p), biome(p) come from the planet\'s function; places come from the list.', 12.5, '400', SOFT))
    # the unrolled arena
    x0, w = 40, 920
    y0 = 440
    o.append(text(x0, y0 - 14, 'The arena: 153,600 units, 4,800 columns, wrapping (T is the middle; the ends meet).', 13, '700'))
    st, sx, base = strip(x0, y0, w, 150, sl, 0.5, hmax=6000.0)
    o += st
    # settlements as chords, drawn on the axis
    for hld in sl['held']:
        cx = sx(hld['s'])
        ww = w * hld['half'] * 2 / L
        hh = 54 if hld['kind'] == 'city' else 26
        col = CITY if hld['kind'] == 'city' else TOWN
        o.append('<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="%s" fill-opacity="0.85"/>' % (cx - ww/2, base - hh - 40, max(ww, 4), hh, col))
        o.append(text(cx, base - hh - 46, ('city' if hld['kind'] == 'city' else 'town'), 11, '700', col, 'middle'))
        off = abs(hld['d'])
        o.append(text(cx, base + 16, 'off %.1fk' % (off / 1000.0), 10.5, '400', SOFT, 'middle'))
    tx = sx(0.0)
    o.append('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="#d6336c" stroke-width="2"/>' % (tx, y0 - 8, tx, base + 4))
    o.append(text(tx, y0 - 14 + 0, '', 1))
    o.append(text(tx + 6, y0 + 8, 'T', 14, '700', '#d6336c'))
    o += legend(40, 644)
    o.append(text(40, 682, 'Settlement boxes are the width of the line\'s chord through the settlement; the label under each says how far off its centre the line passes.', 12, '400', SOFT))
    o.append(text(40, 700, 'A line through a city\'s middle shows its downtown; a line near the edge shows only its outskirts (figure E).', 12, '400', SOFT))
    o.append(text(40, 736, 'Held by this arena:', 13, '700'))
    o.append(text(40, 756, '%d cities, %d towns, %d biomes, %d%% land, %d%% of the length is settled. Found on candidate %d.' % (sl['cities'], sl['towns'], sl['biomes'], round(100*sl['land']), round(100*sl['settled']), sl['tried']), 13, '400', INK))
    o.append(text(40, 776, 'Same seed, same touch-down, same circle: nothing about the choice depends on the machine.', 12, '400', SOFT))
    o.append('</svg>')
    open(os.path.join(OUT, 'b-slice-pick.svg'), 'w', encoding='utf-8').write('\n'.join(o))


# ================================================================== (c) the touch-down
def fig_c():
    W, H = 1000, 700
    sl = d['slices'][0]
    o = head(W, H, 'C. The touch-down', 'Where the fighters land, and what is round them. The camera sees about 1,800 to 4,200 units across; the arena is 153,600.')
    x0, w = 40, 920
    y0 = 140
    o.append(text(x0, y0 - 24, 'Whole arena, T in the middle (heights exaggerated about 20 times)', 13, '700'))
    st, sx, base = strip(x0, y0, w, 110, sl, 0.5)
    o += st
    for hld in sl['held']:
        cx = sx(hld['s']); ww = w * hld['half'] * 2 / L
        o.append('<rect x="%.1f" y="%.1f" width="%.1f" height="14" fill="%s"/>' % (cx - ww/2, base + 6, max(ww, 3), CITY if hld['kind'] == 'city' else TOWN))
    tx = sx(0.0)
    o.append('<line x1="%.1f" y1="%d" x2="%.1f" y2="%.1f" stroke="#d6336c" stroke-width="2"/>' % (tx, y0 - 8, tx, base + 24))
    # zoom lens
    z0 = 12000.0
    zx0 = tx - w * z0 / L; zx1 = tx + w * z0 / L
    o.append('<rect x="%.1f" y="%d" width="%.1f" height="%.1f" fill="none" stroke="#d6336c" stroke-width="1.5" stroke-dasharray="4 3"/>' % (zx0, y0 - 4, zx1 - zx0, base - y0 + 30))
    o.append('<line x1="%.1f" y1="%.1f" x2="%d" y2="%d" stroke="#d6336c" stroke-width="1" stroke-dasharray="4 3"/>' % (zx0, base + 26, x0, 300))
    o.append('<line x1="%.1f" y1="%.1f" x2="%d" y2="%d" stroke="#d6336c" stroke-width="1" stroke-dasharray="4 3"/>' % (zx1, base + 26, x0 + w, 300))
    # zoom panel: +-12,000 units
    zy0, zh = 300, 150
    zw = w
    prof = sl['profile']
    n = len(prof)
    zbase = zy0 + zh
    o.append('<rect x="%d" y="%d" width="%d" height="%d" fill="#ffffff" stroke="%s" stroke-width="1"/>' % (x0, zy0, zw, zh, '#c9ccd6'))
    per = L / n
    for k in range(n):
        s = k * per
        ss = s if s <= L / 2 else s - L
        if abs(ss) <= z0:
            xk = x0 + zw * (ss + z0) / (2 * z0)
            hh = prof[k][0]
            top = zbase - max(3.0, (min(max(hh, 0.0), 3600.0) / 3600.0) * (zh - 30)) - 6
            if hh < 0: top = zbase - 8
            o.append('<rect x="%.2f" y="%.1f" width="%.2f" height="%.1f" fill="%s"/>' % (xk, top, zw * per / (2 * z0) + 0.6, zbase - top, COL[prof[k][1]]))
    for hld in sl['held']:
        s = hld['s'] if hld['s'] <= L/2 else hld['s'] - L
        if abs(s) < z0 + hld['half']:
            cx = x0 + zw * (s + z0) / (2 * z0); ww = zw * hld['half'] * 2 / (2 * z0)
            o.append('<rect x="%.1f" y="%.1f" width="%.1f" height="26" fill="%s" fill-opacity="0.85"/>' % (max(x0, cx - ww/2), zbase - 70, min(ww, x0 + zw - max(x0, cx - ww/2)), CITY if hld['kind'] == 'city' else TOWN))
    # fighters: two figures 750 apart, camera window 3,000
    fx = x0 + zw / 2
    pxu = zw / (2 * z0)
    for dx in (-375, 375):
        o.append('<circle cx="%.1f" cy="%.1f" r="5" fill="#d6336c"/>' % (fx + dx * pxu, zbase - 22))
    o.append('<rect x="%.1f" y="%d" width="%.1f" height="%d" fill="none" stroke="%s" stroke-width="1.2"/>' % (fx - 1500 * pxu, zy0 + 10, 3000 * pxu, zh - 14, INK))
    o.append(text(fx, zy0 - 6, 'zoom: T plus and minus 12,000 units. Fighters 750 apart; a screen about 3,000 wide', 12, '400', SOFT, 'middle'))
    for v_ in (-12000, -6000, 0, 6000, 12000):
        xx = x0 + zw * (v_ + z0) / (2 * z0)
        o.append('<line x1="%.1f" y1="%d" x2="%.1f" y2="%d" stroke="%s"/>' % (xx, zbase, xx, zbase + 5, INK))
        o.append(text(xx, zbase + 18, ('%+d' % v_) if v_ else 'T', 11, '400', SOFT, 'middle'))
    # three ways to choose T
    cards = [
        ('Pure random', 'Any point on land, seeded. Some fights land in open country and the lure carries them to a city. Honest to "a random spot".'),
        ('Within sight of something', 'Random, but T must be inside 6,000 units of a town, city or landmark. Fights start with a skyline in view. A knob, not a rule.'),
        ('Level-chosen (story mode)', 'The level names a place and an offset. The arena is the circle through it, so the same city can be a different fight each chapter.'),
    ]
    cw = 296
    for i, (t, s) in enumerate(cards):
        cx = 40 + i * (cw + 16)
        o.append('<rect x="%d" y="490" width="%d" height="122" rx="6" fill="#fff" stroke="#c9ccd6"/>' % (cx, cw))
        o.append(text(cx + 12, 514, t, 14, '700'))
        line, ly = '', 536
        for wd in s.split(' '):
            if len(line) + len(wd) > 42:
                o.append(text(cx + 12, ly, line, 12.5, '400', SOFT)); ly += 17; line = ''
            line += wd + ' '
        o.append(text(cx + 12, ly, line, 12.5, '400', SOFT))
    o += legend(40, 636)
    o.append(text(40, 670, 'The sim never sees the sphere: it gets 4,800 columns and a list of buildings, exactly the shape it has today.', 12.5, '400', INK))
    o.append('</svg>')
    open(os.path.join(OUT, 'c-touchdown.svg'), 'w', encoding='utf-8').write('\n'.join(o))


# ================================================================== (d) what one arena holds
def fig_d():
    W, H = 1000, 730
    sl = d['slices'][0]
    o = head(W, H, 'D. What one arena holds', 'Orb\'s minimum (two cities, several towns, a few biomes) against today\'s hand-made arena, both drawn to scale at 153,600 units.')
    x0, w = 40, 920
    def band(y, label, segs, sets, extra=None):
        o.append(text(x0, y - 8, label, 13, '700'))
        for a, b, c in segs:
            o.append('<rect x="%.1f" y="%d" width="%.1f" height="34" fill="%s"/>' % (x0 + w*a/L, y, w*(b-a)/L, COL[c]))
        for a, b, kind in sets:
            o.append('<rect x="%.1f" y="%d" width="%.1f" height="%d" fill="%s" fill-opacity="0.9"/>' % (x0 + w*a/L, y + 40, max(w*(b-a)/L, 3), 22 if kind == 'city' else 14, CITY if kind == 'city' else TOWN))
    # today: biome spans x16 and settlements
    P = 16.0
    seg = [(0, 1200, 0), (1200, 1800, 1), (1800, 2350, 1), (2350, 3850, 1), (3850, 4500, 1), (4500, 5500, 2), (5500, 6500, 3), (6500, 7600, 4), (7600, 8000, 1), (8000, 8300, 1), (8300, 9600, 0)]
    segs = [(a*P, b*P, c) for a, b, c in seg]
    sets = [(1260*P, 1760*P, 'town'), (2370*P, 3830*P, 'city'), (3880*P, 4480*P, 'town'), (7640*P, 7960*P, 'town')]
    band(120, 'Today: one city, three villages, five biomes (hand-made, the same every fight)', segs, sets)
    # proposed: the slice's profile for biomes, settlements from held (touch in the middle)
    prof = sl['profile']; n = len(prof)
    segs2 = []
    for k in range(n):
        s = ((k / n) + 0.5) % 1.0 * L
        segs2.append((s, s + L / n + 40, prof[k][1]))
    sets2 = []
    for hld in sl['held']:
        s = ((hld['s'] / L) + 0.5) % 1.0 * L
        sets2.append((s - hld['half'], s + hld['half'], hld['kind']))
    band(220, 'Proposed: a slice of the generated planet (%d cities, %d towns, %d biomes, %d%% land)' % (sl['cities'], sl['towns'], sl['biomes'], round(100*sl['land'])), segs2, sets2)
    # axis ticks
    for kk in range(0, 7):
        xx = x0 + w * kk / 6
        o.append('<line x1="%.1f" y1="285" x2="%.1f" y2="291" stroke="%s"/>' % (xx, xx, INK))
        o.append(text(xx, 306, '%dk' % (kk * 25.6), 11, '400', SOFT, 'middle'))
    o += legend(40, 326)
    # the length question
    o.append(text(40, 372, 'How long should the arena be?', 15, '700'))
    hdr = ['Arena (planet radius)', 'Columns', 'Planet places', 'One arena holds', 'Reading cost']
    xs = [40, 240, 320, 500, 740]
    for t, x in zip(hdr, xs):
        o.append(text(x, 398, t, 12, '700', SOFT))
    rows = [
        ('76,800 units (12,200)', '2,400', '3 cities, 8 towns', 'about 1.4 cities, 1.7 towns: cannot meet two cities unless cities shrink to half', 'half the columns'),
        ('153,600 units (24,400)', '4,800', '12 cities, 31 towns', 'about 2.9 cities, 3.5 towns, 4 biomes: meets the minimum (92% of touch-downs, the rest moved)', 'today: 4,800 columns, 19 KB'),
        ('307,200 units (48,900)', '9,600', '48 cities, 124 towns', 'about 5.8 cities, 7 towns: room to spare', 'double the columns, 4x the places'),
    ]
    y = 420
    for r_ in rows:
        o.append('<rect x="30" y="%d" width="940" height="56" rx="4" fill="%s" stroke="#d9dbe3"/>' % (y - 16, '#f1f4ea' if '24,400' in r_[0] else '#ffffff'))
        for t, x in zip(r_, xs):
            wmax = {40: 22, 240: 7, 320: 18, 500: 46, 740: 28}[x]
            line, ly = '', y
            for wd in t.split(' '):
                if len(line) + len(wd) > wmax and line:
                    o.append(text(x, ly, line, 12, '400', INK)); ly += 15; line = ''
                line += wd + ' '
            o.append(text(x, ly, line, 12, '400', INK))
        y += 66
    o.append(text(40, 636, 'What does not change with the arena: the sim still steps the same few hundred things. Today\'s 118 buildings sit on 46,000 settled units (2.6 per 1,000);', 12, '400', SOFT))
    o.append(text(40, 652, 'a slice that is 34% settled has about 52,000 settled units, so about 134 buildings: the same order. Crowds, windows and lanes are drawn only near the camera.', 12, '400', SOFT))
    o.append(text(40, 676, 'The cost that grows is the planet: places and the optional cache (4x the area for 2x the length). An old laptop and the web build pay once, at touch-down.', 12, '400', INK))
    o.append(text(40, 698, 'A fight uses a few thousand units around T. The rest of the circle is where the lure, a launch or a loser\'s flight takes them.', 12, '400', SOFT))
    o.append('</svg>')
    open(os.path.join(OUT, 'd-arena-holds.svg'), 'w', encoding='utf-8').write('\n'.join(o))


# ================================================================== (e) two fights, one city
def fig_e():
    W, H = 1000, 720
    o = head(W, H, 'E. Two fights, one city', 'A city is a plan, not a line. A slice through its middle shows towers; a slice near its edge shows houses, and the towers on the far skyline.')
    # the plan: concentric districts, radius 6,500
    cx, cy, rad = 250, 240, 170
    rings = [(1.0, '#e8e5da', 'outskirts'), (0.72, '#d7d3c4', 'suburb'), (0.45, '#bdb9a8', 'mid-rise'), (0.2, '#8d8a7c', 'downtown')]
    for k, c, nme in rings:
        o.append('<circle cx="%d" cy="%d" r="%.1f" fill="%s" stroke="#fff" stroke-width="1.5"/>' % (cx, cy, rad*k, c))
    # an industrial wedge
    a0, a1 = math.radians(200), math.radians(250)
    pts = [(cx, cy)]
    for i in range(13):
        a = a0 + (a1 - a0) * i / 12
        pts.append((cx + rad*0.72*math.cos(a), cy + rad*0.72*math.sin(a)))
    o.append('<polygon points="%s" fill="#a79a86"/>' % ' '.join('%.1f,%.1f' % p for p in pts))
    o.append(text(cx + 70, cy + 128, 'harbour', 11, '700', '#2c5f8a'))
    o.append(text(cx - 118, cy - 70, 'industrial', 11, '700', '#6b5f4d'))
    o.append('<path d="M %d %d A %d %d 0 0 1 %d %d L %d %d Z" fill="#6f9fc8" fill-opacity="0.8"/>' % (cx + rad*0.72*math.cos(math.radians(30)), cy + rad*0.72*math.sin(math.radians(30)), rad*0.72, rad*0.72, cx + rad*0.72*math.cos(math.radians(70)), cy + rad*0.72*math.sin(math.radians(70)), cx, cy))
    # landmark: bell tower at (+0.18r, -0.1r)
    bt = (cx + 0.18*rad*math.cos(math.radians(-40)), cy + 0.18*rad*math.sin(math.radians(-40)))
    cr = (cx - 0.55*rad, cy + 0.1*rad)
    o.append('<path d="M %.1f %.1f l 6 12 l -12 0 Z" fill="#d6336c"/>' % (bt[0], bt[1] - 8))
    o.append(text(bt[0] + 10, bt[1] + 2, 'bell tower', 11, '700', '#d6336c'))
    o.append('<rect x="%.1f" y="%.1f" width="9" height="9" fill="#5b3a8a"/>' % (cr[0] - 4, cr[1] - 4))
    o.append(text(cr[0] + 9, cr[1] - 6, 'hall', 11, '700', '#5b3a8a'))
    # two slices
    sa = (cx - rad*1.1, cy + 0.12*rad, cx + rad*1.1, cy + 0.12*rad)   # near the middle, east-west
    ang = math.radians(-35)
    off = 0.62 * rad
    bx = cx + off * math.cos(ang + math.pi/2); by = cy + off * math.sin(ang + math.pi/2)
    sb = (bx - rad*1.1*math.cos(ang), by - rad*1.1*math.sin(ang), bx + rad*1.1*math.cos(ang), by + rad*1.1*math.sin(ang))
    o.append('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="#2f6fed" stroke-width="3"/>' % sa)
    o.append('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="#e8590c" stroke-width="3"/>' % sb)
    o.append(text(sa[0] - 4, sa[1] - 10, 'fight 1', 13, '700', '#2f6fed', 'start'))
    o.append(text(sb[2] + 6, sb[3] - 6, 'fight 2', 13, '700', '#e8590c', 'start'))
    # legend rings
    ly = 462
    for i, (k, c, nme) in enumerate(reversed(rings)):
        o.append('<rect x="%d" y="%d" width="12" height="12" fill="%s" stroke="#999"/>' % (60 + i*120, ly, c))
        o.append(text(60 + i*120 + 18, ly + 11, nme, 12))
    o.append(text(60, 494, 'City radius 6,500 units. Rings are the districts of the city', 12, '400', SOFT))
    o.append(text(60, 510, '(today' + chr(39) + 's Bellgate has the same ones).', 12, '400', SOFT))
    # skylines
    def skyline(y0, title, colr, dist, towers_tall):
        o.append(text(520, y0 - 128, title, 14, '700', colr))
        o.append('<line x1="520" y1="%d" x2="960" y2="%d" stroke="%s" stroke-width="1.5"/>' % (y0, y0, INK))
        random_state = 11 if colr == '#2f6fed' else 29
        x = 520
        import random
        rg = random.Random(random_state)
        while x < 958:
            t = (x - 520) / 440.0                                   # position along the line
            # distance from the city centre along this slice
            rho = abs(t - 0.5) * 2.2 * 1.0 + dist
            h = max(8, (1.0 - min(rho, 1.0)) ** 1.4 * towers_tall + rg.random() * 10)
            ww = 6 + rg.random() * 9
            o.append('<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="%s" stroke="#fff" stroke-width="0.6"/>' % (x, y0 - h, ww, h, '#6d7282' if h > 40 else '#9aa0ae'))
            x += ww + 1.5
    skyline(260, 'Fight 1: through the middle (downtown 0.1 r from the line)', '#2f6fed', 0.1, 120)
    skyline(440, 'Fight 2: near the edge (0.6 r from the line)', '#e8590c', 0.6, 120)
    # the bell tower in each
    o.append('<path d="M 735 140 l 7 20 l -14 0 Z" fill="#d6336c"/><rect x="731" y="160" width="8" height="100" fill="#d6336c"/>')
    o.append(text(752, 152, 'bell tower, in the fight', 11, '700', '#d6336c'))
    o.append('<path d="M 800 367 l 4 12 l -8 0 Z" fill="#d6336c" fill-opacity="0.45"/><rect x="798" y="379" width="4" height="61" fill="#d6336c" fill-opacity="0.45"/>')
    o.append(text(660, 366, 'the same tower, faint, behind the street', 11, '700', '#d6336c'))
    o.append(text(520, 478, 'Both fights hold the same buildings with the same names and the same seed; only the line through them changes. A damaged city', 12, '400', SOFT))
    o.append(text(520, 494, 'could keep its damage between fights if Orb wants that (question 3 in the note).', 12, '400', SOFT))
    # rule box
    o.append('<rect x="30" y="520" width="940" height="150" rx="6" fill="#fff" stroke="#c9ccd6"/>')
    o.append(text(48, 548, 'How a city becomes a strip', 14, '700'))
    steps = ['1  A city is stored as a centre, a radius, a seed and its districts as rings (and a few wedges: harbour, industrial).',
             '2  The line passes at an offset d from the centre. At distance s along it the point is rho = sqrt(s^2 + d^2) from the centre.',
             '3  The district at rho picks the building kinds and heights (data we already have), the seed picks the exact buildings, so both fights agree.',
             '4  Landmarks are fixed points of the plan. A landmark within the band is in the fight; a landmark further off is the backdrop skyline (World\'s data, Rendering\'s picture).',
             '5  The same city seen from the opposite side is mirrored: nothing else is needed.']
    for i, s in enumerate(steps):
        o.append(text(48, 574 + 20*i, s, 12.5, '400', INK if i < 4 else SOFT))
    o.append('</svg>')
    open(os.path.join(OUT, 'e-shared-city.svg'), 'w', encoding='utf-8').write('\n'.join(o))


fig_a(); fig_b(); fig_c(); fig_d(); fig_e()
print('ok')
