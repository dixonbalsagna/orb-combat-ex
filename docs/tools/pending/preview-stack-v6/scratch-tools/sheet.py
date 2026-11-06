import sys
from PIL import Image, ImageDraw
d, t0, t1, step, cols, out = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), int(sys.argv[4]), int(sys.argv[5]), sys.argv[6]
ticks = list(range(t0, t1 + 1, step))
w, h = 320, 180
rows = (len(ticks) + cols - 1) // cols
sh = Image.new('RGB', (cols * w, rows * h), (0, 0, 0))
dr = ImageDraw.Draw(sh)
for i, t in enumerate(ticks):
    try:
        im = Image.open('%s/stills/still-%06d.jpg' % (d, t)).convert('RGB').resize((w, h))
    except Exception:
        continue
    x, y = (i % cols) * w, (i // cols) * h
    sh.paste(im, (x, y)); dr.text((x + 4, y + 4), str(t), fill=(255, 255, 0))
sh.save(out)
