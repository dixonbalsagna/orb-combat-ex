# SCRATCH: which pixels flip by 0.1 relative luminance (darker side under 0.8) between ticks t-1 and t, and between
# which tones.   python flipmap.py <clipdir> <out.png> t...
import sys
from PIL import Image
lin = [((i / 255) / 12.92 if i / 255 <= 0.04045 else (((i / 255) + 0.055) / 1.055) ** 2.4) for i in range(256)]
def lum(p):
    im = Image.open(p).convert('RGB')
    return im, [0.2126 * lin[r] + 0.7152 * lin[g] + 0.0722 * lin[b] for r, g, b in im.getdata()]
d, outp = sys.argv[1], sys.argv[2]
rows = []
for t in map(int, sys.argv[3:]):
    i0, l0 = lum(f"{d}/frame-{t-1:06d}.png")
    i1, l1 = lum(f"{d}/frame-{t:06d}.png")
    w, h = i1.size
    m = Image.new('RGB', (w, h))
    px = [(int(r * 0.35), int(g * 0.35), int(b * 0.35)) for r, g, b in i1.getdata()]
    up = dn = upr = dnr = 0
    pairs = {}
    for k in range(w * h):
        a, b = l0[k], l1[k]
        if min(a, b) >= 0.8 or abs(b - a) < 0.1:
            continue
        if b > a:
            up += 1; upr += (k % w) >= w // 2; px[k] = (255, 255, 255)
        else:
            dn += 1; dnr += (k % w) >= w // 2; px[k] = (255, 0, 255)
        if k % 7 == 0:
            q = (round(a, 2), round(b, 2)); pairs[q] = pairs.get(q, 0) + 1
    m.putdata(px)
    print(t, 'up', up, 'down', dn, '| right half up', upr, 'down', dnr)
    print('   commonest (before, after):', sorted(pairs.items(), key=lambda kv: -kv[1])[:10])
    row = Image.new('RGB', (w * 2, h)); row.paste(i1, (0, 0)); row.paste(m, (w, 0)); rows.append(row)
sheet = Image.new('RGB', (rows[0].width, rows[0].height * len(rows)))
for i, r in enumerate(rows):
    sheet.paste(r, (0, i * r.height))
sheet.resize((sheet.width // 2, sheet.height // 2)).save(outp)
