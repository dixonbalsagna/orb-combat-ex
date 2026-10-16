"""Planet v2 (polar ice) diagrams from the prototype's own output.  python gen_svgs2.py <planet2.json> <outdir>
Reuses the helpers of gen_svgs.py (the code above its figure A)."""
import json, math, sys, os

src = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'gen_svgs.py'), encoding='utf-8').read()
src = src[:src.index('# ================================================================== (a) the planet stored')]
ns = {'__name__': 'gen2', '__file__': __file__}
exec(compile(src, 'gen_svgs_helpers', 'exec'), ns)
globals().update(ns)

BIO = ['ocean', 'plains', 'forest', 'desert', 'mountains', 'ice sheet', 'sea ice']
COL = ['#6f9fc8', '#c3cf8a', '#5f9a68', '#e4c98a', '#9a9187', '#f3f7fb', '#cfe4f0']
ns['COL'] = COL
ICE_EDGE = '#8fb2cc'
WATER = '#6f9fc8'
SKY = '#eaf1f7'
WINS = json.load(open(sys.argv[3])) if len(sys.argv) > 3 else None
N = d['polar']['n']
S_ = d['polar']['s']


def legend2(x, y):
    o = []
    cx = x
    for i, b in enumerate(BIO):
        o.append('<rect x="%d" y="%d" width="14" height="14" fill="%s" stroke="%s" stroke-width="0.8"/>' % (cx, y, COL[i], '#9aa6b2' if i >= 5 else COL[i]))
        o.append(text(cx + 19, y + 12, b, 12))
        cx += 25 + 7 * len(b)
    o.append('<rect x="%d" y="%d" width="10" height="10" fill="%s"/>' % (cx + 4, y + 2, CITY)); o.append(text(cx + 19, y + 12, 'city', 12)); cx += 58
    o.append('<circle cx="%d" cy="%d" r="4.5" fill="%s"/>' % (cx + 5, y + 7, TOWN)); o.append(text(cx + 16, y + 12, 'town', 12))
    return o


def disc(cx, cy, rad, rings, south, places):
    """A pole seen from above: 60 rings of 0.75 degrees (45 degrees across), 240 sectors; runs of one biome drawn as one shape."""
    o = ['<circle cx="%.1f" cy="%.1f" r="%.1f" fill="%s" stroke="%s" stroke-width="1.5"/>' % (cx, cy, rad, WATER, INK)]
    nr = len(rings)
    na = len(rings[0])
    for ri in range(nr):
        r0 = rad * ri / nr
        r1 = rad * (ri + 1) / nr + 0.4
        row = rings[ri]
        a = 0
        while a < na:
            b = a
            while b + 1 < na and row[b + 1] == row[a]:
                b += 1
            bio = row[a]
            if bio != 0:
                # split a long run into pieces of at most 20 sectors (30 degrees): an arc cannot close on itself
                pa = a
                while pa <= b:
                    pb = min(b, pa + 19)
                    t0 = 2 * math.pi * pa / na
                    t1 = 2 * math.pi * (pb + 1) / na
                    if south:
                        t0, t1 = -t1, -t0
                    def pt(r, t): return (cx + r * math.cos(t), cy + r * math.sin(t))
                    p0i, p0o, p1o, p1i = pt(r0, t0), pt(r1, t0), pt(r1, t1), pt(r0, t1)
                    path = 'M %.1f %.1f L %.1f %.1f A %.1f %.1f 0 0 1 %.1f %.1f L %.1f %.1f' % (p0i[0], p0i[1], p0o[0], p0o[1], r1, r1, p1o[0], p1o[1], p1i[0], p1i[1])
                    if r0 > 0.5:
                        path += ' A %.1f %.1f 0 0 0 %.1f %.1f Z' % (r0, r0, p0i[0], p0i[1])
                    else:
                        path += ' Z'
                    o.append('<path d="%s" fill="%s" stroke="%s" stroke-width="0.35"/>' % (path, COL[bio], COL[bio]))
                    pa = pb + 1
            a = b + 1
    # graticule at 30 and 15 degrees from the pole
    for deg in (15, 30):
        o.append('<circle cx="%.1f" cy="%.1f" r="%.1f" fill="none" stroke="%s" stroke-width="0.8" stroke-dasharray="3 3" stroke-opacity="0.7"/>' % (cx, cy, rad * deg / 45.0, INK))
    o.append(text(cx, cy - rad - 8, '', 1))
    # places inside 45 degrees
    for pl in places:
        v = pl['v']
        if abs(v[1]) < math.cos(math.radians(45)):
            continue
        if (v[1] < 0) != south:
            continue
        colat = math.degrees(math.acos(min(1.0, abs(v[1]))))
        az = math.atan2(v[2], v[0])
        if south:
            az = -az
        r = rad * colat / 45.0
        x, y = cx + r * math.cos(az), cy + r * math.sin(az)
        if pl['kind'] == 'city':
            o.append('<rect x="%.1f" y="%.1f" width="7" height="7" fill="%s" stroke="#fff"/>' % (x - 3.5, y - 3.5, CITY))
        else:
            o.append('<circle cx="%.1f" cy="%.1f" r="3" fill="%s" stroke="#fff" stroke-width="0.8"/>' % (x, y, TOWN))
    return o


def wrap_text(o, x, y, s, size=12.5, width=46, fill=SOFT, lh=16):
    line = ''
    for wd in s.split(' '):
        if len(line) + len(wd) > width and line:
            o.append(text(x, y, line, size, '400', fill)); y += lh; line = ''
        line += wd + ' '
    o.append(text(x, y, line, size, '400', fill))
    return y + lh


# ================================================================== A2
def fig_a2():
    W, H = 1000, 800
    o = head(W, H, 'A2. The planet stored, with polar ice', 'Picture A again, with an ice cap on each pole: a continent under an ice sheet in the south, broken sea ice in the north. Seed %d.' % d['seed'])
    g = Globe(235, 330, 200, (0.62, 0.30, 0.72))
    o.append(globe_svg(g, d['grid'], d['places'], [], []))
    # north and south poles as little marks on the globe, if visible
    for lab, y in (('N', 1.0), ('S', -1.0)):
        q = g.proj((0, y, 0))
        if q[2] > 0:
            o.append(text(q[0], q[1] - 6, lab, 12, '700', INK, 'middle'))
    o += legend2(30, 566)
    # polar discs
    o += disc(590, 180, 100, N, False, d['places'])
    o += disc(590, 410, 100, S_, True, d['places'])
    o.append(text(590, 76, 'looking down on each pole, 45 degrees across', 12, '400', SOFT, 'middle'))
    o.append(text(720, 118, 'North: sea, no land', 15, '700'))
    y = wrap_text(o, 720, 140, 'A pack of sea ice, broken into floes. Near the pole the floes are big and close together. Toward the edge they shrink, part, and thin to scattered bergs in open water.', width=44)
    o.append(text(720, 350, 'South: a continent under ice', 15, '700'))
    y = wrap_text(o, 720, 372, 'A dome of ice sheet over land, with bare rock breaking through it. A flat ice shelf around the coast, then an ocean ring with the odd berg.', width=44)
    o.append(text(30, 604, 'Dashed rings are 15 and 30 degrees from the pole. The south disc is mirrored as if seen from outside the planet.', 12, '400', SOFT))
    o.append(text(30, 648, 'How the ice is made (nothing stored)', 14, '700'))
    rows = ['It is part of the same function as the rest of the planet: the latitude (the y of the point), the sea (open water is below zero) and our noise.',
            'Sea ice (north): the pack is thick near the pole and thins to nothing at about 28 degrees of it. Floes are cells of a cellular noise; the chance a cell is ice, and how much of it, falls with the pack\'s thickness.',
            'Ice sheet (south): a land mask about 24 degrees across, noisy at its edge; the ice dome rises inward; where it is high and a second noise is high, rock shows through.',
            'Nothing here is a table: the same seed gives the same ice. Cities and towns are kept out of the caps.']
    yy = 668
    for r_ in rows:
        yy = wrap_text(o, 30, yy, r_, 12.5, 150, INK if r_ is rows[0] else SOFT, 16)
    o.append('</svg>')
    open(os.path.join(OUT, 'a2-planet-ice.svg'), 'w', encoding='utf-8').write('\n'.join(o))


# ================================================================== F: a slice through both poles
def window_panel(o, x0, y0, w, h, win, title, fighters=True):
    """A screen's worth, to scale: 3,000 units across (1,000 columns of 3), 0.153 px a unit; the sea level drawn; fighters 75 units tall."""
    pts = win['p']
    sc = w / 3000.0
    hs = [p[0] for p in pts]
    mn, mx = min(hs), max(hs)
    o.append('<rect x="%d" y="%d" width="%d" height="%d" fill="%s" stroke="#c9ccd6"/>' % (x0, y0, w, h, SKY))
    o.append(text(x0 + 8, y0 + 16, title, 12.5, '700', INK, 'start', 'paint-order="stroke" stroke="%s" stroke-width="4"' % SKY))
    if mn < 0 or mx < 400:
        yref = y0 + h - 14 - max(0.0, -mn) * sc          # sea level
        base = 0.0
    else:
        yref = y0 + h - 14 + (mn * sc)                    # all land: heights relative to the lowest column
        base = 0.0
    def Y(hh): return yref - hh * sc
    cols = len(pts)
    cw = w / cols
    # water under sea level
    if mn < 0:
        o.append('<rect x="%d" y="%.1f" width="%d" height="%.1f" fill="%s"/>' % (x0, Y(0), w, y0 + h - Y(0), WATER))
    for i, (hh, b) in enumerate(pts):
        xi = x0 + i * cw
        if hh >= 0 and b in (5, 6, 4, 1, 2, 3):
            top = Y(hh)
            bot = y0 + h if mn >= 0 else Y(0) + 1
            col = COL[b] if b != 4 else '#8d8579'
            o.append('<rect x="%.2f" y="%.1f" width="%.2f" height="%.1f" fill="%s"/>' % (xi, top, cw + 0.4, max(1.0, bot - top), col))
    # the outline of the surface
    path = ['M']
    for i, (hh, b) in enumerate(pts):
        yv = Y(hh) if hh >= 0 else Y(0)
        path.append('%.1f,%.1f' % (x0 + i * cw, yv))
    o.append('<polyline points="%s" fill="none" stroke="%s" stroke-width="1"/>' % (' '.join(path[1:]), ICE_EDGE if mx < 400 else '#9aa6b2'))
    if fighters:
        # two fighters 750 units apart at the centre, standing on the highest ground under them
        for dx in (-375, 375):
            ix = int(500 + dx / 3.0)
            for dd in range(0, 400):          # the nearest dry column
                for jx in (ix + dd, ix - dd):
                    if 0 <= jx < len(pts) and pts[jx][0] >= 0:
                        ix = jx
                        break
                else:
                    continue
                break
            hh = max(0, pts[ix][0])
            dx = (ix - 500) * 3.0
            o.append('<rect x="%.1f" y="%.1f" width="5" height="%.1f" rx="2" fill="#d6336c"/>' % (x0 + w / 2 + dx * sc - 2.5, Y(hh) - 75 * sc, 75 * sc))
    o.append(text(x0 + w - 8, y0 + h - 4, '3,000 units; fighters 75 tall', 10.5, '400', SOFT, 'end'))


def fig_f():
    ex = [e for e in d['slices'] if e.get('name') == 'meridian']
    if not ex:
        return
    sl = ex[0]
    W, H = 1000, 1180
    o = head(W, H, 'F. An arena through both poles', 'The circle through a land touch-down and both poles: a stretch of sea ice, a stretch of ice sheet, and what lies between. From the prototype (seed %d).' % d['seed'])
    x0, w = 40, 920
    y0 = 120
    o.append(text(x0, y0 - 24, 'Whole arena (153,600 units; heights exaggerated); T in the middle', 13, '700'))
    st, sx, base = strip(x0, y0, w, 100, sl, 0.5, hmax=6000.0)
    o += st
    for hld in sl['held']:
        cx = sx(hld['s']); ww = w * hld['half'] * 2 / L
        o.append('<rect x="%.1f" y="%.1f" width="%.1f" height="14" fill="%s"/>' % (cx - ww / 2, base + 6, max(ww, 3), CITY if hld['kind'] == 'city' else TOWN))
    # the poles on the strip
    for lab, key in (('north pole', 'zoomN_a'), ('south pole', 'zoomS_a')):
        a = sl[key] % (2 * math.pi)
        s = a / (2 * math.pi) * L
        xx = sx(s)
        o.append('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="#1d2230" stroke-width="1.5" stroke-dasharray="4 3"/>' % (xx, y0 - 8, xx, base + 24))
        o.append(text(xx, y0 - 12, lab, 12, '700', INK, 'middle'))
    o += legend2(40, base + 38)
    # the two zooms
    def zoom(y, key, label, vmax, sea_clip):
        zz = sl[key]
        n = len(zz)
        zh = 92
        o.append(text(x0, y - 10, label, 13, '700'))
        o.append('<rect x="%d" y="%d" width="%d" height="%d" fill="%s" stroke="#c9ccd6"/>' % (x0, y, w, zh, SKY))
        sea_y = y + zh - 28
        o.append('<rect x="%d" y="%d" width="%d" height="%d" fill="%s"/>' % (x0, sea_y, w, y + zh - sea_y, WATER))
        for i, (hh, b) in enumerate(zz):
            xi = x0 + w * i / n
            if hh >= 0:
                top = sea_y - min(hh, vmax) / vmax * (zh - 34)
                col = COL[b] if b != 4 else '#8d8579'
                o.append('<rect x="%.2f" y="%.1f" width="%.2f" height="%.1f" fill="%s" stroke="%s" stroke-width="0.4"/>' % (xi, top, w / n + 0.5, (y + zh) - top if hh > 100 and b in (5, 4) else sea_y - top + 2, col, col))
        for v_ in (-24000, -12000, 0, 12000, 24000):
            xx = x0 + w * (v_ + 24000) / 48000
            o.append('<line x1="%.1f" y1="%d" x2="%.1f" y2="%d" stroke="%s"/>' % (xx, y + zh, xx, y + zh + 5, INK))
            o.append(text(xx, y + zh + 17, ('%+dk' % (v_ // 1000)) if v_ else 'pole', 11, '400', SOFT, 'middle'))
    zoom(300, 'zoomN', 'The north pole, 24,000 units each way: the pack thick at the pole, thinning and parting toward its edge (heights exaggerated 30 times)', 100.0, True)
    zoom(450, 'zoomS', 'The south pole, 24,000 units each way: the ice sheet rises gently toward the pole (about true scale), the shelf, then open water', 2800.0, False)
    # to scale
    o.append(text(x0, 590, 'What a fighter sees: one screen (3,000 units), to scale', 14, '700'))
    wins = []
    for key, tag in (('zoomN_win', 'N'), ('zoomS_win', 'S')):
        for wv in sl.get(key, []):
            wins.append((tag, wv))
    pick = []
    titles = {}
    if WINS:
        for key, off, ttl in (('N', 3000, 'North, 3,000 from the pole: big floes, thick'),
                              ('B', None, 'North, near the edge of the pack: an iceberg in open water'),
                              ('S', 3000, 'South, 3,000 from the pole: the dome of the ice sheet'),
                              ('S', 12500, 'South, 12,500 from the pole: the shelf and its cliff')):
            for wv in WINS[key]:
                if off is None or wv['off'] == off:
                    pick.append((key, wv)); titles[(key, wv['off'])] = ttl
    else:
        for tag, off in (('N', 3000.0), ('N', 12500.0), ('S', 3000.0), ('S', 10500.0)):
            for t, wv in wins:
                if t == tag and abs(wv['off'] - off) < 1:
                    pick.append((t, wv)); titles[(t, wv['off'])] = '%s %d' % (t, off)
    cw, ch = 455, 170
    for i, (t, wv) in enumerate(pick):
        cx = x0 + (i % 2) * (cw + 10)
        cy = 604 + (i // 2) * (ch + 10)
        window_panel(o, cx, cy, cw, ch, wv, titles[(t, wv['off'])])
    yy = 604 + 2 * (ch + 10) + 18
    o.append(text(x0, yy, 'What it plays like', 14, '700'))
    lines = ['Sea ice: flat white platforms a few units above the water (10 to 40), hundreds to a few thousand units across, with dark water between. Bergs stand 45 to 215 units: taller than a fighter. No buildings, no people: no collateral at all.',
             'Ice sheet: a long white slope that rises 1,500 to 2,500 units toward the pole, rock showing through the high ground; at the coast a flat shelf 36 units high that ends in a cliff. Also nothing built.',
             'New rules this would ask for (not built): ice is thin, so a crater through a floe should open the water under it (today water only exists where the original ground is below the sea); fighters can dive into the leads (the ocean cover rule already exists).']
    for l in lines:
        yy = wrap_text(o, x0, yy + 20, l, 12.5, 150, SOFT, 16)
    o.append('</svg>')
    open(os.path.join(OUT, 'f-polar-arena.svg'), 'w', encoding='utf-8').write('\n'.join(o))


# ================================================================== D2: what the polar slices hold
def fig_d2():
    W, H = 1000, 760
    o = head(W, H, 'D2. What a slice holds, now that ice is a biome', 'Three arenas from the same planet to the same scale (153,600 units): an ordinary one, one through both poles, one that clips a cap.')
    x0, w = 40, 920
    names = {'temperate': 'An ordinary slice (no ice)', 'meridian': 'Through both poles', 'clip': 'Clipping a polar cap'}
    y = 120
    for sl in d['slices']:
        nm = sl.get('name', '')
        o.append(text(x0, y - 8, '%s: %d cities, %d towns, %d biomes, %d%% land, %d%% ice (%d%% sheet, %d%% sea ice)' % (names.get(nm, nm), sl['cities'], sl['towns'], sl['biomes'], round(100 * sl['land']), round(100 * sl['ice']), round(100 * sl['sheet']), round(100 * sl['seaice'])), 13, '700'))
        prof = sl['profile']
        n = len(prof)
        for k in range(n):
            s = ((k / n) + 0.5) % 1.0 * L
            o.append('<rect x="%.1f" y="%d" width="%.1f" height="34" fill="%s" stroke="none"/>' % (x0 + w * s / L, y, w * (L / n + 40) / L, COL[prof[k][1]]))
        for hld in sl['held']:
            s = ((hld['s'] / L) + 0.5) % 1.0 * L
            ww = w * hld['half'] * 2 / L
            for sh in (-w, 0, w):
                xb = x0 + w * s / L - ww / 2 + sh
                if xb + ww < x0 or xb > x0 + w:
                    continue
                xa = max(xb, x0); xe = min(xb + ww, x0 + w)
                o.append('<rect x="%.1f" y="%d" width="%.1f" height="%d" fill="%s" fill-opacity="0.9"/>' % (xa, y + 40, max(xe - xa, 3), 22 if hld['kind'] == 'city' else 14, CITY if hld['kind'] == 'city' else TOWN))
        o.append('<rect x="%d" y="%d" width="%d" height="34" fill="none" stroke="#c9ccd6"/>' % (x0, y, w))
        y += 110
    o += legend2(40, y - 20)
    y += 20
    st = d['stats']
    o.append(text(40, y, 'What ice does to the picker', 15, '700'))
    rows = [
        ('How often a random circle carries ice (at least 8% of its length)', '%d%%' % round(100 * st['ice_circles'] / st['circles'])),
        ('A circle through both poles meets the minimum (2 cities, 3 towns, 3 biomes, half land)', '%d%%' % round(100 * st['mer_ok'] / st['mer_n'])),
        ('The same circle meets a relaxed minimum (1 city, 2 towns, 3 biomes, 40% land)', '%d%%' % round(100 * st['mer_relaxed'] / st['mer_n'])),
        ('Touch-downs where the picker finds a slice meeting the minimum (the earlier planet: 92%)', '%d%%' % round(100 * st['ok'] / st['N'])),
        ('Accepted arenas that carry at least 8% ice', '%d%%' % round(100 * st['ice_pick'] / max(1, st['ok']))),
    ]
    yy = y + 24
    for a_, b_ in rows:
        o.append(text(60, yy, a_, 12.5, '400', INK))
        o.append(text(940, yy, b_, 13, '700', INK, 'end'))
        yy += 22
    yy += 8
    for l in ['Rules that change: ice sheet and sea ice count as biomes (so a polar slice easily has its three); sea ice is not land (half of the length must still be land, ice sheet included); cities and towns stay out of the caps, so a slice through a cap has less room for them.',
              'The picker itself does not change: it still tries the circles through the touch-down and a city and keeps the first that meets the minimum. Ice only changes which circles pass.']:
        yy = wrap_text(o, 40, yy, l, 12.5, 150, SOFT, 16) + 4
    o.append('</svg>')
    open(os.path.join(OUT, 'd2-arena-holds-ice.svg'), 'w', encoding='utf-8').write('\n'.join(o))


fig_a2(); fig_f(); fig_d2()
print('ok')
