"""Mockup clip: a slow pan across a wide picture (default: the bottom row of Art's megastructure sheet, art/concepts/megastructures/megastructures.png, the card text left out).
   python pan.py --out <frames folder> [--src <png>] [--box x,y,w,h start window] [--to x] [--frames 40]   Eased in and out; the window moves along x only."""
import argparse, os
from PIL import Image
HERE = os.path.dirname(os.path.abspath(__file__))
ap = argparse.ArgumentParser()
ap.add_argument('--out', required=True)
ap.add_argument('--src', default=os.path.join(HERE, '..', '..', '..', 'art', 'concepts', 'megastructures', 'megastructures.png'))
ap.add_argument('--box', default='30,1008,1000,562')
ap.add_argument('--to', type=int, default=880)
ap.add_argument('--frames', type=int, default=40)
o = ap.parse_args()
im = Image.open(o.src).convert('RGB')
x0, y0, w, h = (int(v) for v in o.box.split(','))
os.makedirs(o.out, exist_ok=True)
for i in range(o.frames):
    t = i / max(1, o.frames - 1)
    t = t * t * (3 - 2 * t)
    x = round(x0 + (o.to - x0) * t)
    im.crop((x, y0, x + w, y0 + h)).resize((480, round(480 * h / w)), Image.LANCZOS).save(os.path.join(o.out, 'f-%05d.png' % (i + 1)))
print('frames', o.frames)
