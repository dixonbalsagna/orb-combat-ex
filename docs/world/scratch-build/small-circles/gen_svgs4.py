"""The canon planet's map, and the research outposts to scale.  python gen_svgs4.py <small.json> <canon_out dir> <outposts.json> <outdir>"""
import json, math, sys, os, random

small = json.load(open(sys.argv[1]))
canon = json.load(open(os.path.join(sys.argv[2], 'canon_work.json')))
outs = json.load(open(sys.argv[3]))
OUT = sys.argv[4]
os.makedirs(OUT, exist_ok=True)
COL = ['#6f9fc8', '#c3cf8a', '#5f9a68', '#e4c98a', '#9a9187', '#f3f7fb', '#cfe4f0']
BIO = ['ocean', 'plains', 'forest', 'desert', 'mountains', 'ice sheet', 'sea ice']
INK = '#1d2230'
SOFT = '#5a6070'
BG = '#fbfaf6'
CITY = '#2a2f45'
TOWN = '#c0502d'
FONT = 'font-family="Segoe UI, system-ui, Arial, sans-serif"'


def text(x, y, s, size=13, w='400', fill=INK, anchor='start', extra=''):
    return '<text x="%.1f" y="%.1f" font-size="%s" font-weight="%s" fill="%s" text-anchor="%s" %s %s>%s</text>' % (x, y, size, w, fill, anchor, '' if 'font-family' in extra else FONT, extra, s)


def lonlat(v):
    return math.degrees(math.atan2(v[2], v[0])), math.degrees(math.asin(max(-1, min(1, v[1]))))


def fig_map():
    W, H = 1000, 700
    mx, my, cw = 20, 100, 8.0
    o = ['<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" width="%d" height="%d">' % (W, H, W, H), '<rect width="%d" height="%d" fill="%s"/>' % (W, H, BG)]
    o.append(text(24, 34, 'L1. Everhold: a canon planet (proposal)', 20, '700'))
    o.append(text(24, 56, 'Planet seed 7 (pictures A2 to F) as a flat map: longitude across, latitude down (the poles are stretched).', 12.5, '400', SOFT))
    o.append(text(24, 74, "Names from Narrative's grammar with Legal's blocklist applied. They are proposals for Legal to screen and Orb to change.", 12.5, '400', SOFT))
    grid = small['grid']
    for j in range(60):
        for i in range(120):
            b = grid[j][i]
            o.append('<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="%s" stroke="%s" stroke-width="0.4"/>' % (mx + i * cw, my + (59 - j) * cw, cw + 0.3, cw + 0.3, COL[b], COL[b]))
    names = canon['names']
    boxes = []

    def free(x, y, w, h):
        for bx, by, bw, bh in boxes:
            if x < bx + bw and x + w > bx and y < by + bh and y + h > by:
                return False
        return True

    def place_label(px, py, s, size, w, fill, extra='', sub=None):
        tw = len(s) * size * 0.56
        th = size * (2.1 if sub else 1.15)
        for dx, dy in ((7, -4), (7, size + 3), (-7 - tw, -4), (-7 - tw, size + 3), (-tw / 2, -size - 6), (-tw / 2, size + 8), (7, -size - 8), (7, size * 2 + 6)):
            x, y = px + dx, py + dy
            if mx <= x and x + tw <= mx + 960 and my <= y - size and y + th <= my + 480 and free(x, y - size, tw, th):
                boxes.append((x, y - size, tw, th))
                o.append(text(x, y, s, size, w, fill, 'start', 'paint-order="stroke" stroke="#ffffff" stroke-opacity="0.75" stroke-width="2.4" ' + extra))
                if sub:
                    o.append(text(x, y + size * 0.95, sub, size - 1.5, '400', '#444b5c', 'start', 'font-style="italic" paint-order="stroke" stroke="#ffffff" stroke-opacity="0.7" stroke-width="2"'))
                return
        # no free spot: put it anyway to the right
        o.append(text(px + 7, py - 4, s, size, w, fill, 'start', extra))

    # the regions first (big, spaced, faint)
    for r in canon['regions']:
        x = mx + (r['lon'] + 180) / 3 * cw
        y = my + (90 - r['lat']) / 3 * cw
        label = r['name'].upper()
        boxes.append((x - len(label) * 3.6, y - 8, len(label) * 7.2, 12))
        o.append(text(x, y, label, 11, '700', '#3a4252', 'middle', 'letter-spacing="2" fill-opacity="0.55" paint-order="stroke" stroke="#ffffff" stroke-opacity="0.5" stroke-width="2"'))
    places = small['places']
    land = {l['place']: l['name'] for l in canon['landmarks']}
    # cities and towns
    for i, p in enumerate(places):
        lo, la = lonlat(p['v'])
        x = mx + (lo + 180) / 3 * cw
        y = my + (90 - la) / 3 * cw
        if p['kind'] == 0:
            o.append('<rect x="%.1f" y="%.1f" width="8" height="8" fill="%s" stroke="#fff" stroke-width="1"/>' % (x - 4, y - 4, CITY))
        else:
            o.append('<circle cx="%.1f" cy="%.1f" r="3" fill="%s" stroke="#fff" stroke-width="0.8"/>' % (x, y, TOWN))
    for i, p in enumerate(places):
        lo, la = lonlat(p['v'])
        x = mx + (lo + 180) / 3 * cw
        y = my + (90 - la) / 3 * cw
        nm = names[str(i)]
        if p['kind'] == 0:
            place_label(x, y, nm, 11.5, '700', CITY, '', land.get(i))
    for i, p in enumerate(places):
        if p['kind'] == 1:
            lo, la = lonlat(p['v'])
            x = mx + (lo + 180) / 3 * cw
            y = my + (90 - la) / 3 * cw
            place_label(x, y, names[str(i)], 9.5, '400', '#6b2a14')
    for o_ in canon['outposts']:
        lo, la = lonlat(o_['v'])
        x = mx + (lo + 180) / 3 * cw
        y = my + (90 - la) / 3 * cw
        o.append('<path d="M %.1f %.1f l 5 5 l -5 5 l -5 -5 z" fill="#d6336c" stroke="#fff" stroke-width="1"/>' % (x, y - 5))
        place_label(x, y, o_['name'], 10, '700', '#a61e4d')
    o.append('<rect x="%d" y="%d" width="960" height="480" fill="none" stroke="%s"/>' % (mx, my, INK))
    # legend
    y = my + 500
    cx = 20
    for i, b in enumerate(BIO):
        o.append('<rect x="%d" y="%d" width="14" height="14" fill="%s" stroke="%s" stroke-width="0.8"/>' % (cx, y, COL[i], '#9aa6b2' if i >= 5 else COL[i]))
        o.append(text(cx + 19, y + 12, b, 12))
        cx += 25 + 7 * len(b)
    o.append('<rect x="%d" y="%d" width="10" height="10" fill="%s"/>' % (cx + 4, y + 2, CITY)); o.append(text(cx + 19, y + 12, 'city (and its landmark)', 12)); cx += 150
    o.append('<circle cx="%d" cy="%d" r="4.5" fill="%s"/>' % (cx + 5, y + 7, TOWN)); o.append(text(cx + 16, y + 12, 'town', 12)); cx += 60
    o.append('<path d="M %d %d l 5 5 l -5 5 l -5 -5 z" fill="#d6336c"/>' % (cx + 5, y + 2)); o.append(text(cx + 16, y + 12, 'research outpost', 12))
    o.append(text(20, y + 38, 'Bellgate is the hub (the city nearest the others); Kilnstead the town nearest it, Farwatch the farthest, Netmend the one on the coast:', 12, '400', SOFT))
    o.append(text(20, y + 54, "the old planet's names, kept where the geography matches. The other 10 cities and 30 towns come from the grammar and each place's seed.", 12, '400', SOFT))
    o.append('</svg>')
    open(os.path.join(OUT, 'l1-canon-planet-map.svg'), 'w', encoding='utf-8').write('\n'.join(o))


def station(o, x, y, w, sc, kind, rg):
    """a station to scale, in the city's own scale (a house is 4 to 6 fighter heights): huts 300 tall, a lab block 520, tanks 400, a mast 800"""
    parts = []
    cx = x

    def rect(dx, wd, ht, fill):
        parts.append('<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="%s" stroke="#ffffff" stroke-width="0.6"/>' % (cx + dx * sc, y - ht * sc, wd * sc, ht * sc, fill))
    rect(-700, 360, 300, '#c0502d')      # huts
    rect(-300, 300, 260, '#c0502d')
    rect(-100, 700, 520, '#8b94a3')      # the lab block
    rect(700, 300, 280, '#c0502d')
    rect(1050, 150, 400, '#6d7282')      # tanks
    rect(1250, 150, 400, '#6d7282')
    parts.append('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="#444b5c" stroke-width="2"/>' % (cx - 900 * sc, y, cx - 900 * sc, y - 800 * sc))   # a mast
    parts.append('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="#444b5c" stroke-width="1"/>' % (cx - 1000 * sc, y - 640 * sc, cx - 800 * sc, y - 640 * sc))
    o.extend(parts)


def fig_outposts():
    W, H = 1000, 1130
    o = ['<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" width="%d" height="%d">' % (W, H, W, H), '<rect width="%d" height="%d" fill="%s"/>' % (W, H, BG)]
    o.append(text(24, 34, 'L2. Three research outposts, to scale', 20, '700'))
    o.append(text(24, 56, 'One screen is 3,000 units across, fighters 75 tall. A station is 6 to 9 buildings at the city scale (huts 300 tall, a lab 520, tanks 400, a mast 800).', 12.5, '400', SOFT))
    SKY = '#eaf1f7'
    WATER = '#6f9fc8'
    cw, ch = 940, 300
    sc = cw / 3000.0
    random.seed(5)
    specs = [('shelf', 'The shelf station: on the flat ice shelf (36 units above the sea): the sea is within 2,500 units on one side and the dome rises on the other', 'Glasswatch'),
             ('inland', 'The high station: on the ice sheet 1,450 units up, rock showing through nearby, nothing else for thousands of units', 'Rimewatch'),
             ('floe', 'The floe station: at the north pole, on the middle of a big floe (18 units above the water): open water more than 1,500 units away', 'Thawwatch')]
    names = {o_['kind']: o_['name'] for o_ in canon['outposts']}
    y0 = 90
    for kind, ttl, _ in specs:
        win = outs[kind]['win']
        mn = min(h for h, b in win)
        mx = max(h for h, b in win)
        o.append(text(20, y0 + 14, '%s: %s' % (names[kind], ttl), 12.5, '700'))
        by = y0 + 22
        o.append('<rect x="20" y="%d" width="%d" height="%d" fill="%s" stroke="#c9ccd6"/>' % (by, cw, ch, SKY))
        if kind == 'inland':
            yref = by + ch - 10 + (mn * sc)
        else:
            yref = by + ch - 20 - max(0.0, -mn) * sc
        def Y(hh): return yref - hh * sc
        if mn < 0:
            o.append('<rect x="20" y="%.1f" width="%d" height="%.1f" fill="%s"/>' % (Y(0), cw, by + ch - Y(0), WATER))
        pts = []
        for i, (hh, b) in enumerate(win):
            xi = 20 + i * cw / len(win)
            if hh >= 0:
                col = '#e1eaf3' if b in (5,) else ('#cfe4f0' if b == 6 else '#9a9187')
                bot = by + ch if mn >= 0 else Y(0) + 1
                top = Y(hh)
                o.append('<rect x="%.2f" y="%.1f" width="%.2f" height="%.1f" fill="%s" stroke="%s" stroke-width="0.3"/>' % (xi, top, cw / len(win) + 0.4, max(1.0, bot - top), col, '#aebdcb' if b in (5, 6) else col))
        # station at the centre
        gx = 20 + cw / 2
        gh = win[500][0]
        station(o, gx, Y(max(0, gh)), cw, sc, kind, random)
        # two fighters 750 apart, on the ground
        for dx in (-750, 750):
            ix = int(500 + dx / 3.0)
            hh = max(0, win[ix][0])
            o.append('<rect x="%.1f" y="%.1f" width="5" height="%.1f" rx="2" fill="#d6336c"/>' % (gx + dx * sc - 2.5, Y(hh) - 75 * sc, 75 * sc))
        y0 += 22 + ch + 36
    o.append(text(20, y0 - 20, "What a polar outpost is for: something to break, and a few people to evacuate, in an arena that is otherwise empty ice.", 12, '400', SOFT))
    o.append(text(20, y0 - 4, "Tens of people each (a few hundredths of a city's weight), so the collateral shares barely move.", 12, '400', SOFT))
    o.append('</svg>')
    open(os.path.join(OUT, 'l2-research-outposts.svg'), 'w', encoding='utf-8').write('\n'.join(o))


fig_map()
fig_outposts()
print('ok')
