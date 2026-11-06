# Cut a GIF from a reel folder's stills (every 3 ticks): python gifcut.py <reel folder> <first tick> <frames> <out.gif> [--box x0,y0,x1,y1] [--blur r] [--fps 12] [--maxkb 560] [--step 3]
import sys
sys.path.insert(0, 't')
from mkgif import encode, crop_still
from PIL import ImageFilter
a = sys.argv[1:]
d, t0, n, out = a[0], int(a[1]), int(a[2]), a[3]
opt = lambda k, dflt: a[a.index(k) + 1] if k in a else dflt
box = tuple(int(x) for x in opt('--box', '0,0,960,540').split(','))
step = int(opt('--step', 3)); blur = float(opt('--blur', 0)); fps = float(opt('--fps', 12)); maxkb = float(opt('--maxkb', 560))
frames = [crop_still('%s/stills/still-%06d.jpg' % (d, t), box) for t in range(t0, t0 + step * n, step)]
if blur: frames = [f.filter(ImageFilter.GaussianBlur(blur)) for f in frames]
kb, nc, nf, dl = encode(frames, round(1000 / fps), out, maxkb)
print(out, round(kb), 'KB', nc, 'colors', nf, 'frames', round(nf * dl / 1000, 1), 's', frames[0].size)
