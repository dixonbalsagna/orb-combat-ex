# GIF 7 (a mockup, in development): planet 7 today against B (the plate terrain), two orthographic globes turning slowly, drawn from World's flat maps (docs/world/img/overhaul-b/map-today-vs-b.png). A hard side by side, no fade.
import sys, math
sys.path.insert(0, 't')
from PIL import Image, ImageDraw, ImageFont
from mkgif import encode
SRC = r'C:/Users/<user>/Documents/Claude Proj/Breakers-Like/docs/world/img/overhaul-b/map-today-vs-b.png'
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
    N = 40
    frames = [frame(math.radians(-70 + 70 * i / N)) for i in range(N)]
    kb, nc, nf, dl = encode(frames, 83, 'gifs/7-planet-today-vs-plates.gif', 560)
    print('GIF7', round(kb), 'KB', nc, 'colors', nf, 'frames', dl, 'ms', round(nf * dl / 1000, 1), 's')
