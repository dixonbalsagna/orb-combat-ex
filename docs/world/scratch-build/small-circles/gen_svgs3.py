"""Small-circle arenas: the pictures.  python gen_svgs3.py <small.json> <outdir>   (reuses the helpers of gen_svgs.py and gen_svgs2.py)"""
import json, math, sys, os

src = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'gen_svgs.py'), encoding='utf-8').read()
src = src[:src.index('# ================================================================== (a) the planet stored')]
ns = {'__name__': 'gen3', '__file__': __file__}
exec(compile(src, 'helpers', 'exec'), ns)
globals().update(ns)
for _p in d['places']:
    _p['kind'] = 'city' if _p['kind'] == 0 else 'town'
BIO = ['ocean', 'plains', 'forest', 'desert', 'mountains', 'ice sheet', 'sea ice']
COL = ['#6f9fc8', '#c3cf8a', '#5f9a68', '#e4c98a', '#9a9187', '#f3f7fb', '#cfe4f0']
ns['COL'] = COL
SKY = '#eaf1f7'
Rp = d['R']
L0 = 153600.0


def legend3(x, y, extra=True):
    o = []
    cx = x
    for i, b in enumerate(BIO):
        o.append('<rect x="%d" y="%d" width="14" height="14" fill="%s" stroke="%s" stroke-width="0.8"/>' % (cx, y, COL[i], '#9aa6b2' if i >= 5 else COL[i]))
        o.append(text(cx + 19, y + 12, b, 12))
        cx += 25 + 7 * len(b)
    o.append('<rect x="%d" y="%d" width="10" height="10" fill="%s"/>' % (cx + 4, y + 2, CITY)); o.append(text(cx + 19, y + 12, 'city', 12)); cx += 58
    o.append('<circle cx="%d" cy="%d" r="4.5" fill="%s"/>' % (cx + 5, y + 7, TOWN)); o.append(text(cx + 16, y + 12, 'town', 12))
    return o


def frame(c, bearing):
    ref = (0, 1, 0) if abs(c[1]) < 0.9 else (1, 0, 0)
    u0 = norm(cross(ref, c))
    v0 = cross(c, u0)
    co, si = math.cos(bearing), math.sin(bearing)
    u = tuple(u0[i] * co + v0[i] * si for i in range(3))
    v = cross(c, u)
    return u, v


def loop_pts(c, L, bearing, n=180):
    th = math.asin(min(1.0, L / (2 * math.pi * Rp)))
    u, v = frame(c, bearing)
    pts = []
    for k in range(n + 1):
        a = 2 * math.pi * k / n
        p = tuple(math.cos(th) * c[i] + math.sin(th) * (math.cos(a) * u[i] + math.sin(a) * v[i]) for i in range(3))
        pts.append(p)
    return pts


def draw_poly(g, pts, col, w, dash=''):
    out = []
    run = []
    for p in pts:
        q = g.proj(p)
        if q[2] >= 0:
            run.append(q)
        else:
            if len(run) > 1:
                out.append('<polyline points="%s" fill="none" stroke="%s" stroke-width="%s" %s/>' % (' '.join('%.1f,%.1f' % (a[0], a[1]) for a in run), col, w, dash))
            run = []
    if len(run) > 1:
        out.append('<polyline points="%s" fill="none" stroke="%s" stroke-width="%s" %s/>' % (' '.join('%.1f,%.1f' % (a[0], a[1]) for a in run), col, w, dash))
    return out


def wrap_text(o, x, y, s, size=12.5, width=46, fill=SOFT, lh=16):
    line = ''
    for wd in s.split(' '):
        if len(line) + len(wd) > width and line:
            o.append(text(x, y, line, size, '400', fill)); y += lh; line = ''
        line += wd + ' '
    o.append(text(x, y, line, size, '400', fill))
    return y + lh


ex = {e['name']: e for e in d['examples']}
E76 = ex['best loop, 76800']
E38 = ex['best loop, 38400']
S38 = ex['round the south pole, 38,400']
N38 = ex['round the north pole, 38,400']


def fig_k1():
    W, H = 1000, 700
    o = head(W, H, 'K1. A smaller arena: a loop round a point', 'A great circle is the biggest loop on a planet. A loop of a smaller circle goes round a centre point instead. Planet 7, to the same scale as picture A2.')
    c = E76['c']
    g = Globe(250, 340, 205, norm((c[0] + 0.6 * E38['c'][0], c[1] + 0.6 * E38['c'][1] + 0.1, c[2] + 0.6 * E38['c'][2])))
    o.append(globe_svg(g, d['grid'], d['places'], [], []))
    # a great circle for comparison: the circle through the two centres
    n = norm(cross(c, E38['c']))
    gc = []
    uu = norm(cross(n, (0.3, 0.9, 0.2)))
    vv = cross(n, uu)
    for k in range(181):
        a = 2 * math.pi * k / 180
        gc.append(tuple(math.cos(a) * uu[i] + math.sin(a) * vv[i] for i in range(3)))
    o += draw_poly(g, gc, '#6b7280', 1.6, 'stroke-dasharray="6 4"')
    o += draw_poly(g, loop_pts(E76['c'], 76800.0, E76['bearing']), '#d6336c', 3.2)
    o += draw_poly(g, loop_pts(E38['c'], 38400.0, E38['bearing']), '#2f6fed', 3.2)
    for e, col in ((E76, '#d6336c'), (E38, '#2f6fed')):
        q = g.proj(tuple(e['c']))
        if q[2] > 0:
            o.append('<circle cx="%.1f" cy="%.1f" r="4" fill="%s"/>' % (q[0], q[1], col))
    o += legend3(30, 585)
    x = 520
    o.append(text(x, 100, 'Three loops on the same planet', 16, '700'))
    rows = [('#6b7280', 'dashed', 'The great circle: 153,600 units round (today). It goes through the middle of the planet.'),
            ('#d6336c', 'pink', 'A loop of 76,800 units: half as long. It circles a centre 12,800 units away from every point of it.'),
            ('#2f6fed', 'blue', 'A loop of 38,400 units: a quarter as long. Its centre is 6,177 units from the line, and the loop is 6,111 units in radius.')]
    y = 130
    for col, nm, s in rows:
        o.append('<rect x="%d" y="%d" width="22" height="6" fill="%s"/>' % (x, y - 8, col))
        y = wrap_text(o, x + 32, y, s, 12.5, 48, INK, 16) + 8
    o.append(text(x, y + 14, 'What the two loops hold (planet 7)', 15, '700'))
    y += 38
    for nm, e, col in (('76,800', E76, '#d6336c'), ('38,400', E38, '#2f6fed')):
        o.append(text(x, y, '%s: %d cit%s, %d towns, %d biomes, %d%% land, %d%% of its length settled' % (nm, e['cities'], 'y' if e['cities'] == 1 else 'ies', e['towns'], e['biomes'], round(100 * e['land']), round(100 * e['settled'])), 12.5, '700', col))
        y += 20
    y += 6
    y = wrap_text(o, x, y, 'These are the best loop found of each size, from loops round every city and town and some random points. A loop meets the minimum far less often than a great circle does (next picture), so the picker tries more of them.', 12.5, 52, SOFT, 16)
    y += 10
    o.append(text(x, y, 'A loop can go round anything', 15, '700'))
    y = wrap_text(o, x, y + 22, 'A city, a mountain range, a lake, or a pole (K2): a ring of ice sheet round the south pole, a ring of sea ice round the north.', 12.5, 52, SOFT, 16)
    o.append('</svg>')
    open(os.path.join(OUT, 'k1-small-circles-planet.svg'), 'w', encoding='utf-8').write('\n'.join(o))


def strip_k(o, x0, y0, w, e, L, label, shift_extra=0.0):
    """One loop unrolled to w pixels, T in the middle (the loop has no seam: any point can be the middle)."""
    prof = e['profile']
    n = len(prof)
    h = 70
    o.append(text(x0, y0 - 12, label, 13, '700'))
    for k in range(n):
        xk = x0 + w * (((k / n) + 0.5) % 1.0)
        hh = prof[k][0]
        top = y0 + h - max(2.0, min(max(hh, 0.0), 6000.0) / 6000.0 * (h - 10)) - 6
        if hh < 0:
            top = y0 + h - 8
        o.append('<rect x="%.2f" y="%.1f" width="%.2f" height="%.1f" fill="%s" stroke="%s" stroke-width="0.3"/>' % (xk, top, w / n + 0.5, y0 + h - top, COL[prof[k][1]], COL[prof[k][1]]))
    o.append('<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s"/>' % (x0, y0 + h, x0 + w, y0 + h, INK))
    for hld in e['held']:
        s = hld['s']
        for sh in (-L, 0, L):
            cx = x0 + w * (((s / L) + 0.5) % 1.0) + sh * w / L
            ww = w * hld['half'] * 2 / L
            xa = max(x0, cx - ww / 2); xe = min(x0 + w, cx + ww / 2)
            if xe > xa:
                o.append('<rect x="%.1f" y="%d" width="%.1f" height="%d" fill="%s" fill-opacity="0.9"/>' % (xa, y0 + h + 6, max(xe - xa, 3), 18 if hld['kind'] == 0 else 12, CITY if hld['kind'] == 0 else TOWN))


def fig_k2():
    W, H = 1000, 800
    o = head(W, H, 'K2. A smaller arena, unrolled', 'The loops of K1 as strips, to the same scale as each other and as the great circle (the bar at the top). A loop has no seam either: it wraps exactly as the great circle does.')
    x0 = 40
    w = 920
    # the great circle bar, to scale
    o.append(text(x0, 96, 'The great circle today: 153,600 units', 13, '700'))
    o.append('<rect x="%d" y="104" width="%d" height="10" fill="#c9ccd6"/>' % (x0, w))
    wp = w * 76800 / L0
    o.append(text(x0, 134, 'A loop of 76,800: half', 12, '700', '#d6336c'))
    o.append('<rect x="%d" y="140" width="%.1f" height="10" fill="#d6336c"/>' % (x0, wp))
    wq = w * 38400 / L0
    o.append(text(x0 + wp + 30, 134, 'A loop of 38,400: a quarter', 12, '700', '#2f6fed'))
    o.append('<rect x="%.1f" y="140" width="%.1f" height="10" fill="#2f6fed"/>' % (x0 + wp + 30, wq))
    # strips at their own widths
    y = 200
    for e, col in ((E76, '#d6336c'), (E38, '#2f6fed')):
        L = e['L']
        ww = w * L / L0
        strip_k(o, x0, y, ww, e, L, 'Best loop of %d: %d cit%s, %d towns, %d biomes, %d%% land (%d%% settled)' % (L, e['cities'], 'y' if e['cities'] == 1 else 'ies', e['towns'], e['biomes'], round(100 * e['land']), round(100 * e['settled'])))
        o.append('<rect x="%d" y="%d" width="%.1f" height="3" fill="%s"/>' % (x0, y - 3, ww, col))
        y += 140
    o.append(text(x0, y - 4, 'Round a pole, 38,400 units each (the loop is 14.5 degrees from the pole)', 13, '700'))
    y += 12
    for e, nm in ((S38, 'South: all ice sheet'), (N38, 'North: sea ice and open water')):
        ww = w * e['L'] / L0
        strip_k(o, x0, y + 16, ww, e, e['L'], '%s (%d%% ice)' % (nm, round(100 * e['ice'])))
        y += 130
    o += legend3(40, y + 4)
    o.append(text(40, y + 36, 'Each strip is the whole loop with the touch-down in the middle. The boxes under it are the places the line passes, as in picture B.', 12, '400', SOFT))
    o.append('</svg>')
    open(os.path.join(OUT, 'k2-small-arena-strip.svg'), 'w', encoding='utf-8').write('\n'.join(o))


def fig_k3():
    W, H = 1000, 940
    o = head(W, H, 'K3. What it is like inside a smaller arena', 'To scale: the loop of 38,400 units seen from above, then a screen with two fighters. Looking toward the middle, the far side of the loop is across the way.')
    # plan view
    cx, cy, rr = 250, 290, 170
    r = E38['r']
    sc = rr / r     # px per unit
    o.append('<circle cx="%d" cy="%d" r="%d" fill="#f3f1e8" stroke="%s" stroke-width="1"/>' % (cx, cy, rr + 40 * 0, INK))
    # the fight band: 29 fighter heights deep toward the centre side (the band depth 2,400 units inward) and the loop line
    o.append('<circle cx="%d" cy="%d" r="%.1f" fill="none" stroke="#d6336c" stroke-width="3"/>' % (cx, cy, rr))
    o.append('<circle cx="%d" cy="%d" r="%.1f" fill="none" stroke="#d6336c" stroke-opacity="0.35" stroke-width="%.1f"/>' % (cx, cy, rr - 2400 * sc / 2, 2400 * sc))
    o.append('<circle cx="%d" cy="%d" r="6" fill="%s"/>' % (cx, cy, CITY))
    o.append(text(cx, cy + 22, 'the centre', 12, '700', CITY, 'middle'))
    o.append(text(cx, cy + 38, '6,177 units from the line', 11, '400', SOFT, 'middle'))
    # the fight spot at the bottom of the loop, and the camera wedge looking inward (up)
    fx, fy = cx, cy + rr
    o.append('<polygon points="%.1f,%.1f %.1f,%.1f %.1f,%.1f" fill="#2f6fed" fill-opacity="0.18" stroke="#2f6fed" stroke-width="1"/>' % (fx - 1500 * sc, fy, fx + 1500 * sc, fy, cx + 0, cy - rr))
    o.append('<circle cx="%.1f" cy="%.1f" r="4" fill="#d6336c"/><circle cx="%.1f" cy="%.1f" r="4" fill="#d6336c"/>' % (fx - 4, fy, fx + 4, fy))
    o.append(text(fx + 14, fy + 4, 'the fight', 12, '700', '#d6336c'))
    o.append(text(cx, cy - rr - 10, 'the far side of the loop: 12,222 units across the way', 12, '700', INK, 'middle'))
    o.append(text(60, 82, 'From above, the loop of 38,400 units (radius 6,111)', 13, '700'))
    o.append(text(60, cy + rr + 40, 'Pink: the line the fighters move along. Pale pink: the band they fight in (2,400 units deep).', 11.5, '400', SOFT))
    o.append(text(60, cy + rr + 56, 'Blue: what the camera sees, looking in toward the middle.', 11.5, '400', SOFT))
    # a screen: side view to scale: 3,000 units across, fighters, then the centre skyline and the far side
    x1, y1, w1, h1 = 520, 110, 440, 250
    o.append(text(x1, y1 - 14, 'What the camera sees (one screen, 3,000 units across, fighters 75 tall)', 13, '700'))
    o.append('<rect x="%d" y="%d" width="%d" height="%d" fill="%s" stroke="#c9ccd6"/>' % (x1, y1, w1, h1, SKY))
    # far side of the loop: a long low band of hills and small buildings, faint
    random_rows = []
    import random
    rg = random.Random(3)
    gy = y1 + h1 - 40
    # far side (faint): small silhouettes
    x = x1
    while x < x1 + w1:
        hgt = 6 + rg.random() * 16
        ww = 4 + rg.random() * 6
        o.append('<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="#b7c0cc"/>' % (x, gy - 44 - hgt, ww, hgt))
        x += ww + 1
    # the centre: a skyline in the middle distance
    x = x1 + 90
    while x < x1 + w1 - 90:
        t = abs((x - (x1 + w1 / 2)) / (w1 / 2 - 90))
        hgt = (1 - t) ** 1.2 * 120 + rg.random() * 10
        ww = 8 + rg.random() * 12
        o.append('<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="#8b94a3" stroke="#fff" stroke-width="0.5"/>' % (x, gy - 28 - hgt, ww, hgt))
        x += ww + 1.5
    # ground and the fight
    o.append('<rect x="%d" y="%d" width="%d" height="40" fill="#c3cf8a"/>' % (x1, gy, w1))
    for dx in (-60, 60):
        o.append('<rect x="%.1f" y="%.1f" width="7" height="12" rx="3" fill="#d6336c"/>' % (x1 + w1 / 2 + dx - 3.5, gy - 12))
    o.append(text(x1 + 8, y1 + 18, 'the far side of the loop', 11, '400', '#7b8696'))
    o.append(text(x1 + 8, y1 + 34, 'the centre (here a city\'s towers) always straight behind', 11, '400', '#5a6070'))
    o.append(text(x1 + w1 - 8, y1 + h1 - 6, 'not to scale in depth; fighters to scale across', 10.5, '400', SOFT, 'end'))
    # facts
    y = 410
    o.append(text(520, y, 'What it does', 15, '700'))
    y += 24
    facts = ['The camera looks toward the middle, so the centre of the loop is always behind the fight, and the far side of the loop is a skyline across the way. The arena "circles round a point" because that point never leaves the background.',
             'The wrap and the seam: a loop wraps exactly as the great circle does (shortest arc round, no seam to mark). The only change is its length: the sim\'s 153,600-unit world becomes 76,800 or 38,400 (section 3 of the note).',
             'The lap: flat out, 15 s round the great circle, 7.5 s round a loop of 76,800, 3.8 s round one of 38,400. A fight a screen wide covers 2% of the great circle and 8% of the smallest loop.']
    for f in facts:
        y = wrap_text(o, 520, y, f, 12.5, 48, SOFT, 16) + 6
    # size comparison, to scale with the fighters
    y0 = 700
    o.append(text(60, y0 + 20, 'The three arenas against a screen and two fighters 750 units apart', 13, '700'))
    for i, (Ls, nm) in enumerate(((153600.0, 'great circle 153,600'), (76800.0, 'loop 76,800'), (38400.0, 'loop 38,400'))):
        yy = y0 + 46 + i * 52
        ww = 880 * Ls / L0
        o.append('<rect x="60" y="%d" width="%.1f" height="16" fill="#e1e4ea" stroke="%s"/>' % (yy, ww, INK))
        sw = 880 * 3000 / L0
        o.append('<rect x="%.1f" y="%d" width="%.1f" height="16" fill="#2f6fed" fill-opacity="0.5"/>' % (60 + ww / 2 - sw / 2, yy, sw))
        o.append('<circle cx="%.1f" cy="%d" r="2.2" fill="#d6336c"/><circle cx="%.1f" cy="%d" r="2.2" fill="#d6336c"/>' % (60 + ww / 2 - 375 * 880 / L0, yy + 8, 60 + ww / 2 + 375 * 880 / L0, yy + 8))
        o.append(text(60, yy + 32, '%s: the screen is %d%% of the loop' % (nm, round(100 * 3000 / Ls)), 11.5, '400', SOFT))
    o.append('</svg>')
    open(os.path.join(OUT, 'k3-small-arena-inside.svg'), 'w', encoding='utf-8').write('\n'.join(o))


fig_k1(); fig_k2(); fig_k3()
print('ok')
