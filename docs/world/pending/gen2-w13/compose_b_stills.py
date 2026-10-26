"""Window 12 stills: for each seed a row: height (B off), height (B on), fine biomes (B off), fine biomes (B on).   python compose_b_stills.py <maps dir with planet-<s>-gen2-*.png and planet-<s>-gen2b-*.png> <out png>"""
import sys
from PIL import Image, ImageDraw
src, out = sys.argv[1].rstrip('/').rstrip(chr(92)), sys.argv[2]
seeds = [7, 11, 42]
cols = [('gen2', 'height', 'WINDOW 3 GROUND: HEIGHT'), ('gen2b', 'height', 'B PLATES: HEIGHT'), ('gen2', 'fine', 'WINDOW 3 GROUND: BIOMES'), ('gen2b', 'fine', 'B PLATES: BIOMES')]
tiles = []
for s in seeds:
    row = []
    for g, k, _ in cols:
        row.append(Image.open('%s/planet-%d-%s-%s.png' % (src, s, g, k)).convert('RGB'))
    tiles.append(row)
w, h = tiles[0][0].size
pad, cap = 4, 22
W = 4 * w + 5 * pad
H = 3 * (h + cap) + 4 * pad
im = Image.new('RGB', (W, H), (14, 16, 22))
d = ImageDraw.Draw(im)
for r, s in enumerate(seeds):
    for c in range(4):
        x = pad + c * (w + pad)
        y = pad + r * (h + cap + pad)
        d.text((x + 4, y + 5), 'SEED %d  %s' % (s, cols[c][2]), fill=(220, 224, 232))
        im.paste(tiles[r][c], (x, y + cap))
im.save(out)
print(im.size)
