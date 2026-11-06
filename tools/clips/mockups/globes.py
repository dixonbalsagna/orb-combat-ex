"""Mockup clip: planet 7 today against B (the plate terrain), two orthographic globes turning slowly, drawn from World's flat maps (docs/world/img/overhaul-b/map-today-vs-b.png).
A mockup, not the game's globe: the colours are the map's, the shading is simple. A hard side by side, no fade.   python globes.py --out <frames folder> [--frames 40] [--turn 70]
"""
import argparse, math, os, sys
from PIL import Image, ImageDraw, ImageFont
HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, '..', '..', '..', 'docs', 'world', 'img', 'overhaul-b', 'map-today-vs-b.png')
im = Image.open(SRC).convert('RGB')
maps = [im.crop((0, 0, 720, 360)), im.crop((732, 0, 1452, 360))]
# the red touch-down crosses are not terrain: replace each red pixel by a neighbour that is not red
def clean(m):
    px = m.load(); W, H = m.size
    for y in range(H):
        for x in range(W):
            r, g, b = px[x, y]
            if r > 170 and g < 110 and b < 110:
                for d in (4, 8, 12):
                    for dx, dy in ((d, 0), (-d, 0), (0, d), (0, -d)):
                        xx, yy = x + dx, y + dy
                        if 0 <= xx < W and 0 <= yy < H:
                            c = px[xx, yy]
                            if not (c[0] > 170 and c[1] < 110 and c[2] < 110):
                                px[x, y] = c; break
                    else:
                        continue
                    break
    return m
maps = [clean(m) for m in maps]
pix = [m.load() for m in maps]
W, H = 720, 360
CW, CH, R = 480, 250, 104
centres = [(120, 112), (360, 112)]
LIGHT = (-0.55, 0.45, 0.70); n = math.sqrt(sum(c * c for c in LIGHT)); LIGHT = tuple(c / n for c in LIGHT)
TILT = math.radians(14)
sl, cl = math.sin(TILT), math.cos(TILT)
try:
    font = ImageFont.load_default(size=13); small = ImageFont.load_default(size=11)
except TypeError:
    font = small = ImageFont.load_default()

def frame(lon0):
    img = Image.new('RGB', (CW, CH), (6, 8, 20))
    out = img.load()
    for gi, (cx, cy) in enumerate(centres):
        p = pix[gi]
        for py in range(cy - R, cy + R + 1):
            y = (cy - py) / R
            for px in range(cx - R, cx + R + 1):
                x = (px - cx) / R
                d2 = x * x + y * y
                if d2 > 1.0: continue
                z = math.sqrt(1.0 - d2)
                lat = math.asin(max(-1.0, min(1.0, z * sl + y * cl)))
                lon = lon0 + math.atan2(x, z * cl - y * sl)
                u = int(((lon / (2 * math.pi)) + 0.5) % 1.0 * W) % W
                v = min(H - 1, max(0, int((0.5 - lat / math.pi) * H)))
                r, g, b = p[u, v]
                nx, ny, nz = x, y, z
                lam = max(0.0, nx * LIGHT[0] + ny * LIGHT[1] + nz * LIGHT[2])
                sh = 0.30 + 0.70 * lam
                rim = (1.0 - z) ** 3 * 0.35
                out[px, py] = (min(255, int(r * sh + 40 * rim)), min(255, int(g * sh + 70 * rim)), min(255, int(b * sh + 120 * rim)))
    dr = ImageDraw.Draw(img)
    dr.text((centres[0][0], 232), 'today', fill=(200, 210, 225), font=font, anchor='mm')
    dr.text((centres[1][0], 232), 'plate terrain (in development)', fill=(200, 210, 225), font=font, anchor='mm')
    return img


if __name__ == '__main__':
    ap = argparse.ArgumentParser(); ap.add_argument('--out', required=True); ap.add_argument('--frames', type=int, default=40); ap.add_argument('--turn', type=float, default=70.0)
    o = ap.parse_args(); os.makedirs(o.out, exist_ok=True)
    for i in range(o.frames):
        frame(math.radians(-o.turn + o.turn * i / o.frames)).save(os.path.join(o.out, 'f-%05d.png' % (i + 1)))
    print('frames', o.frames)
