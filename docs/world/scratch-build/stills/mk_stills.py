"""World's stills of the re-laid city: plan, elevation and staged destruction on one downtown block, from lanesview.json (L1 with D1 scratch).
python mk_stills.py <lanesview.json> <outdir>"""
import json, sys, os, html
src, outdir = sys.argv[1], sys.argv[2]
os.makedirs(outdir, exist_ok=True)
D = json.load(open(src, encoding='utf-8'))
B = D['buildings']
L = D['lanes']
nl, ns, nd, na = int(L[1]), int(L[2]), int(L[3]), int(L[4])
oL, oS, oD = int(L[10]), int(L[11]), int(L[12])
lanes = [L[oL + 4 * i:oL + 4 * i + 4] for i in range(nl)]
strips = [L[oS + 4 * i:oS + 4 * i + 4] for i in range(ns)]
dists = [L[oD + 6 * i:oD + 6 * i + 6] for i in range(nd)]
oA = oD + 6 * nd
aves = [L[oA + 3 * i:oA + 3 * i + 3] for i in range(na)]
LOOKS = D['settle'].get('looks', [])
ZF, ZB = L[8], L[9]
BH = 75.0
GROUND = D['ground']  # every 64 units


def ground(x):
    i = int((x % D['W']) / 64.0)
    return GROUND[i % len(GROUND)]


def esc(t):
    return html.escape(str(t))


STRIP_FILL = {0: '#cfcac0', 1: '#b9b3a6', 2: '#8c8a86'}
LOOK_NAME = lambda k: LOOKS[int(k)] if 0 <= int(k) < len(LOOKS) else '?'


def height_col(h, kind):
    bh = h / BH
    if kind == 'house':
        return '#c9a27a' if bh < 5 else '#b8896a'
    if bh < 20:
        return '#8fa7c2'
    if bh < 45:
        return '#6f8fb3'
    if bh < 90:
        return '#4f729c'
    return '#37557d'


# ------------------------------------------------------------------ plan
def plan(x0, x1, scale, fname, title, label_dist=True, z_lo=None, z_hi=None):
    zmin = z_lo if z_lo is not None else lanes[-1][1] - 100
    zmax = z_hi if z_hi is not None else lanes[0][0] + 100
    W = (x1 - x0) * scale
    H = (zmax - zmin) * scale
    pad_t, pad_b = 70, 40
    o = ['<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d" font-family="Segoe UI, Arial, sans-serif">' % (W + 40, H + pad_t + pad_b, W + 40, H + pad_t + pad_b)]
    o.append('<rect width="100%" height="100%" fill="#f4f1ea"/>')
    o.append('<text x="20" y="28" font-size="18" font-weight="600" fill="#222">%s</text>' % esc(title))
    o.append('<text x="20" y="48" font-size="12" fill="#555">Plan view from above; the camera is at the bottom. x runs left to right (%d to %d units), depth z runs from the camera (bottom) to the back (top). One fighter is 75 units.</text>' % (x0, x1))

    def X(x):
        return 20 + (x - x0) * scale

    def Y(z):
        return pad_t + (z - zmin) * scale
    # lanes
    for (zt, zb, kind, row) in lanes:
        col = {0: '#e2ded4', 1: '#ece7da', 2: '#e9efe1', 3: '#e1e6dc'}.get(int(kind), '#eee')
        o.append('<rect x="20" y="%.1f" width="%.1f" height="%.1f" fill="%s"/>' % (Y(zb), W, (zt - zb) * scale, col))
    for (lane, zt, zb, kind) in strips:
        o.append('<rect x="20" y="%.1f" width="%.1f" height="%.1f" fill="%s"/>' % (Y(zb), W, (zt - zb) * scale, STRIP_FILL.get(int(kind), '#ccc')))
    # fighters' band
    o.append('<rect x="20" y="%.1f" width="%.1f" height="%.1f" fill="none" stroke="#c0392b" stroke-width="1.4" stroke-dasharray="8 5"/>' % (Y(ZB), W, (ZF - ZB) * scale))
    o.append('<text x="26" y="%.1f" font-size="11" fill="#c0392b">the fighters\' band (%.0f bh deep)</text>' % (Y(ZB) + 13, (ZF - ZB) / BH))
    # avenues (gaps in the blocks, drawn as street)
    for (a0, a1, di) in aves:
        if a1 < x0 or a0 > x1:
            continue
        for (zt, zb, kind, row) in lanes:
            if int(kind) == 1:
                o.append('<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="#8c8a86" opacity="0.85"/>' % (X(max(a0, x0)), Y(zb), (min(a1, x1) - max(a0, x0)) * scale, (zt - zb) * scale))
    # buildings, back to front
    for b in sorted(B, key=lambda b: b['z']):
        if b['x'] + b['w'] / 2 < x0 or b['x'] - b['w'] / 2 > x1:
            continue
        col = height_col(b['h'], b['kind'])
        st = '#111' if b['landmark'] == 0 else '#c0392b'
        sw = 0.6 if b['landmark'] == 0 else 1.8
        o.append('<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="%s" stroke="%s" stroke-width="%.1f" opacity="0.92"/>' % (X(b['x'] - b['w'] / 2), Y(b['z'] - b['d'] / 2), max(b['w'] * scale, 0.8), max(b['d'] * scale, 0.8), col, st, sw))
    # districts
    for (a0, a1, look, mask, traf, st) in dists:
        if a1 < x0 or a0 > x1:
            continue
        xa, xb = max(a0, x0), min(a1, x1)
        o.append('<line x1="%.1f" y1="%d" x2="%.1f" y2="%.1f" stroke="#555" stroke-width="0.8" stroke-dasharray="3 4"/>' % (X(xa), pad_t - 6, X(xa), pad_t + H))
        if label_dist and (xb - xa) * scale > 40:
            o.append('<text x="%.1f" y="%d" font-size="11" fill="#333" font-weight="600">%s</text>' % (X(xa) + 3, pad_t - 10, esc(LOOK_NAME(look))))
    # scale bar and a fighter marker
    bar = 1000
    o.append('<g transform="translate(%.1f,%.1f)"><rect width="%.1f" height="5" fill="#222"/><text x="0" y="16" font-size="11" fill="#222">1,000 units (13 fighter heights)</text></g>' % (20, pad_t + H + 14, bar * scale))
    o.append('<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="#c0392b"/><text x="%.1f" y="%.1f" font-size="11" fill="#c0392b">a fighter</text>' % (X(x0 + bar * 1.6), pad_t + H + 10, max(BH * scale, 2), max(BH * scale, 2), X(x0 + bar * 1.6) + 10, pad_t + H + 20))
    # legend
    lx = 20 + bar * scale + 380 if W > 1200 else 20 + W - 420
    for i, (c, t) in enumerate([('#c9a27a', 'house'), ('#8fa7c2', 'low tower'), ('#6f8fb3', 'mid-rise'), ('#37557d', 'downtown')]):
        o.append('<rect x="%.1f" y="%d" width="10" height="10" fill="%s"/><text x="%.1f" y="%d" font-size="11" fill="#333">%s</text>' % (lx + i * 90, pad_t + H + 10, c, lx + i * 90 + 14, pad_t + H + 19, t))
    o.append('</svg>')
    open(os.path.join(outdir, fname), 'w', encoding='utf-8').write('\n'.join(o))


# ------------------------------------------------------------------ elevation
ROWSHADE = {3: 0.55, 2: 0.35, 1: 0.12, 0: 0.0}


def mix(hexc, amt, to=(232, 236, 241)):
    r, g, b = int(hexc[1:3], 16), int(hexc[3:5], 16), int(hexc[5:7], 16)
    return '#%02x%02x%02x' % (int(r + (to[0] - r) * amt), int(g + (to[1] - g) * amt), int(b + (to[2] - b) * amt))


def draw_building(o, b, X, Y, state=None, row_shade=True):
    """state: None or {'hp','alive','fmask','stage','curH'}"""
    x0 = b['x'] - b['w'] / 2
    w = b['w']
    base = b['base']
    full = b['h']
    stage = 0
    cur = full
    fm = (1 << b['floors']) - 1
    if state is not None:
        stage = state['stage']
        cur = state['curH']
        fm = int(state['fmask'])
        if not state['alive']:
            stage = 4
    col = height_col(full, b['kind'])
    if row_shade:
        col = mix(col, ROWSHADE.get(b['row'], 0.0))
    if stage == 4:
        # rubble: a low mound across the footprint
        hh = max(40.0, full * 0.05)
        o.append('<polygon points="%.1f,%.1f %.1f,%.1f %.1f,%.1f %.1f,%.1f" fill="#9a958c" stroke="#555" stroke-width="0.5"/>' % (X(x0), Y(base), X(x0 + w * 0.15), Y(base + hh * 0.6), X(x0 + w * 0.5), Y(base + hh), X(x0 + w * 0.85), Y(base + hh * 0.5)) )
        o.append('<polygon points="%.1f,%.1f %.1f,%.1f %.1f,%.1f" fill="#9a958c" stroke="#555" stroke-width="0.5"/>' % (X(x0 + w), Y(base), X(x0 + w * 0.85), Y(base + hh * 0.5), X(x0), Y(base)))
        return
    nfl = max(int(b['floors']), 1)
    fh = full / nfl
    if stage == 3:
        # a shell: the frame only, floors as lines, the inside dark
        o.append('<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="#2a2e35" stroke="%s" stroke-width="1.2"/>' % (X(x0), Y(base + cur), w * (X(1) - X(0)), cur * (Y(0) - Y(1)), col))
        k = 1
        while k * fh < cur:
            o.append('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="%s" stroke-width="0.8"/>' % (X(x0), Y(base + k * fh), X(x0 + w), Y(base + k * fh), col))
            k += 1
        # corner columns
        for cx in (x0, x0 + w):
            o.append('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="%s" stroke-width="1.6"/>' % (X(cx), Y(base), X(cx), Y(base + cur), col))
        return
    # standing: the whole body at curH (a damaged building is lower), with its cut floors as gaps
    top = cur
    o.append('<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="%s" stroke="#1d1d1d" stroke-width="0.7"/>' % (X(x0), Y(base + top), w * (X(1) - X(0)), top * (Y(0) - Y(1)), col))
    if b['kind'] == 'tower' and nfl >= 5:
        # the window grid by floor
        for k in range(nfl):
            if (k + 1) * fh > top + 1:
                break
            standing = (fm >> k) & 1
            if not standing:
                o.append('<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="#1d2025"/>' % (X(x0), Y(base + (k + 1) * fh), w * (X(1) - X(0)), fh * (Y(0) - Y(1))))
            else:
                wc = '#f2e6b8' if stage == 0 else ('#2b3441' if stage >= 1 else '#f2e6b8')
                o.append('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="%s" stroke-width="%.1f" opacity="0.9"/>' % (X(x0 + w * 0.12), Y(base + (k + 0.5) * fh), X(x0 + w * 0.88), Y(base + (k + 0.5) * fh), wc, max(fh * (Y(0) - Y(1)) * 0.45, 0.6)))
    elif b['kind'] == 'house':
        wc = '#f2e6b8' if stage == 0 else '#2b3441'
        o.append('<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="%s" opacity="0.9"/>' % (X(x0 + w * 0.25), Y(base + top * 0.6), w * 0.5 * (X(1) - X(0)), top * 0.25 * (Y(0) - Y(1)), wc))
    if stage == 2:
        # a part gone: the upper corner sheared (a notch), drawn as a background-colour wedge
        o.append('<polygon points="%.1f,%.1f %.1f,%.1f %.1f,%.1f" fill="#e8ecf1"/>' % (X(x0 + w * 0.55), Y(base + top), X(x0 + w), Y(base + top), X(x0 + w), Y(base + top * 0.8)))


def elevation(x0, x1, ymax, scale, fname, title, state_by_i=None, only_ids=None, note=None, panel=False):
    W = (x1 - x0) * scale
    H = ymax * scale
    pad_t = 54 if not panel else 40
    pad_b = 36
    o = []
    o.append('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d" font-family="Segoe UI, Arial, sans-serif">' % (W + 40, H + pad_t + pad_b, W + 40, H + pad_t + pad_b))
    o.append('<rect width="100%" height="100%" fill="#e8ecf1"/>')

    def X(x):
        return 20 + (x - x0) * scale

    def Y(y):
        return pad_t + (ymax - y) * scale
    # ground
    pts = ['%.1f,%.1f' % (X(x0), Y(0))]
    xx = x0
    gmin = ground(x0)
    while xx <= x1:
        pts.append('%.1f,%.1f' % (X(xx), Y(ground(xx) - gmin)))
        xx += 64.0
    pts.append('%.1f,%.1f %.1f,%.1f' % (X(x1), Y(0) + 30, X(x0), Y(0) + 30))
    o.append('<polygon points="%s" fill="#bdb7a8"/>' % ' '.join(pts))
    for b in sorted(B, key=lambda b: b['z']):
        if b['x'] + b['w'] / 2 < x0 or b['x'] - b['w'] / 2 > x1:
            continue
        if only_ids is not None and b['i'] not in only_ids:
            continue
        bb = dict(b)
        bb['base'] = b['base'] - gmin
        st = state_by_i.get(b['i']) if state_by_i else None
        draw_building(o, bb, X, Y, st)
    # fighters at three depths for scale
    for (fx, lab) in ((x0 + (x1 - x0) * 0.12, 'a fighter (75 units)'), (x0 + (x1 - x0) * 0.5, ''), (x0 + (x1 - x0) * 0.86, '')):
        o.append('<g><rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="#c0392b" opacity="0.9"/>' % (X(fx), Y(BH * 1.0 + 0.0), max(35 * scale, 2), BH * scale))
        if lab:
            o.append('<text x="%.1f" y="%.1f" font-size="11" fill="#c0392b">%s</text>' % (X(fx) + 8, Y(BH) - 3, lab))
        o.append('</g>')
    # a ruler in fighter heights
    for k in (10, 25, 50, 100, 150):
        yy = k * BH
        if yy <= ymax:
            o.append('<line x1="20" y1="%.1f" x2="%.1f" y2="%.1f" stroke="#c0392b" stroke-width="0.7" stroke-dasharray="2 5"/><text x="24" y="%.1f" font-size="10" fill="#c0392b">%d fighter heights</text>' % (Y(yy), 20 + W, Y(yy), Y(yy) - 2, k))
    # the header on top of everything
    o.append('<rect x="0" y="0" width="100%%" height="%d" fill="#e8ecf1"/>' % (pad_t - 6))
    o.append('<text x="20" y="26" font-size="17" font-weight="600" fill="#222">%s</text>' % esc(title))
    if note:
        o.append('<text x="20" y="44" font-size="12" fill="#555">%s</text>' % esc(note))
    o.append('</svg>')
    open(os.path.join(outdir, fname), 'w', encoding='utf-8').write('\n'.join(o))


# the plans
plan(37900, 61300, 0.058, 'bellgate-plan-overview.svg', 'Bellgate: the re-laid city seen from above (L1 with D1, scratch)')
down = [d for d in dists if LOOK_NAME(d[2]) == 'downtown']
dx0, dx1 = down[0][0], down[0][1]
cx = (dx0 + dx1) / 2.0
plan(cx - 2600, cx + 2600, 0.24, 'bellgate-plan-downtown.svg', 'Bellgate downtown: lanes, streets, blocks and what stands in them (plan)', z_lo=-3300, z_hi=1000)
elevation(cx - 4800, cx + 4800, 11600, 0.1, 'bellgate-elevation-downtown.svg', 'Bellgate downtown seen from the camera: four rows of buildings in depth', note='Back to front: row 3 (far scenery), row 2 (the back block), row 1 (the front block), row 0 (the foreground). The red dashes are fighter heights: the street canyon is 60 and more of them deep.')

# the staged-destruction sequence on one block
seq = D['sequence']
ids = set(D['seqIds'])
sc = D['seqCentre']
sx0, sx1 = sc - 1700, sc + 1700
n = len(seq)
for k, s in enumerate(seq):
    st = {e['i']: e for e in s['state']}
    stages = [e['stage'] for e in s['state']]
    cnt = {i: stages.count(i) for i in range(5)}
    note = 'stage 0 intact: %d, 1 windows out: %d, 2 a part gone: %d, 3 a shell: %d, 4 rubble: %d' % (cnt[0], cnt[1], cnt[2], cnt[3], cnt[4])
    elevation(sx0, sx1, 4400, 0.2, 'bellgate-stages-%d.svg' % k, 'One downtown block, step %d: %s' % (k, s['label']), state_by_i=st, only_ids=ids, note=note, panel=True)
print('stills written', os.listdir(outdir))


# ------------------------------------------------------------------ the stage strip: one house, one mid-rise, one tower at every stage
def strip(fname):
    pick = {}
    for b in B:
        if b['row'] == 1 and b['kind'] == 'house' and 'house' not in pick and b['h'] > 300:
            pick['house'] = b
        if b['row'] == 1 and b['kind'] == 'tower' and 9 <= b['floors'] <= 14 and 'mid' not in pick:
            pick['mid'] = b
        if b['row'] == 1 and b['kind'] == 'tower' and 26 <= b['floors'] <= 34 and 'tall' not in pick:
            pick['tall'] = b
    rows = [('house', 'a house (%d floors)'), ('mid', 'a mid-rise (%d floors)'), ('tall', 'a downtown tower (%d floors)')]
    names = ['0  intact', '1  windows out', '2  a part gone', '3  a shell', '4  rubble']
    colw, rowh = 190, 360
    W = 70 + colw * 5
    H = 70 + rowh * len(rows)
    o = ['<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d" font-family="Segoe UI, Arial, sans-serif">' % (W, H, W, H)]
    o.append('<rect width="100%" height="100%" fill="#e8ecf1"/>')
    o.append('<text x="20" y="26" font-size="17" font-weight="600" fill="#222">The five stages of a building (hit points 90 / 65 / 35 percent and a cut floor; World, WorldStructures.stage)</text>')
    o.append('<text x="20" y="46" font-size="12" fill="#555">Each row is drawn at its own scale. Stage 1: windows out. Stage 2: a part gone (floors cut, a sheared corner). Stage 3: a shell (the frame, the inside dark). Stage 4: rubble, the building is lost.</text>')
    for ri, (key, lab) in enumerate(rows):
        b = dict(pick[key])
        fl = max(int(b['floors']), 1)
        full = b['h']
        sc = min((rowh - 80) / full, (colw * 0.8) / max(b['w'], 1.0))
        y0 = 70 + ri * rowh + (rowh - 40)
        o.append('<text x="20" y="%d" font-size="12" fill="#333">%s</text>' % (y0 - (rowh - 70), esc(lab % fl)))
        for si in range(5):
            xc = 70 + si * colw + colw / 2
            if ri == 0:
                o.append('<text x="%.1f" y="62" font-size="12" font-weight="600" fill="#222" text-anchor="middle">%s</text>' % (xc, names[si]))
            full_mask = (1 << fl) - 1
            hp = [1.0, 0.8, 0.55, 0.2, 0.0][si]
            fm = full_mask
            if si == 2 and fl >= 5:
                k0 = int(fl * 0.45)
                fm = full_mask & ~(3 << k0)
            cur = full * (0.3 + 0.7 * hp)
            if fl >= 5 and fm != full_mask:
                top = max(k for k in range(fl) if (fm >> k) & 1) + 1
                cur = top * (full / fl)
            st = {'hp': hp, 'alive': si < 4, 'fmask': fm, 'stage': si, 'curH': cur}
            bb = dict(b)
            bb['base'] = 0.0
            bb['x'] = 0.0
            bb['w'] = min(b['w'], full * 0.5) if key != 'house' else b['w']
            ww = bb['w'] * sc
            xs = 1.0

            def X(x, xc=xc, sc=sc):
                return xc + x * sc

            def Y(y, y0=y0, sc=sc):
                return y0 - y * sc
            draw_building(o, bb, X, Y, st, row_shade=False)
        o.append('<line x1="20" y1="%d" x2="%d" y2="%d" stroke="#8c8a86" stroke-width="1"/>' % (y0, W - 20, y0))
    o.append('</svg>')
    open(os.path.join(outdir, fname), 'w', encoding='utf-8').write('\n'.join(o))


strip('bellgate-stage-strip.svg')
