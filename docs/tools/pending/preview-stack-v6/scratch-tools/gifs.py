import sys
sys.path.insert(0, 't')
from mkgif import encode, crop_still
S = {
  '1-charged-strike':  ('fp/g-hold',  114, (300, 190, 900, 528)),
  '2-chase':           ('fp/g-chase', 414, (0, 0, 960, 540)),
  '3-beam-and-shove':  ('fp/g-beam',   72, (0, 0, 960, 540)),
  '4-beam-struggle':   ('fp/g-clash', 291, (180, 160, 780, 498)),
  '5-top-power-towers':('fp/g-towers',  None, (0, 0, 960, 540)),
  '6-building-gives-way': ('fp/g-city', 498, (180, 200, 780, 538)),
}
def build(name, t0=None, box=None, n=36):
    d, ts, bx = S[name]
    t0 = ts if t0 is None else t0
    box = bx if box is None else box
    frames = [crop_still('%s/stills/still-%06d.jpg' % (d, t), box) for t in range(t0, t0 + 3 * n, 3)]
    kb, nc, nf, dl = encode(frames, 83, 'gifs/%s.gif' % name, 560)
    print(name, round(kb), 'KB', nc, 'colors', nf, 'frames', round(nf * dl / 1000, 1), 's', 'ticks', t0, '-', t0 + 3 * n)
if __name__ == '__main__':
    for nm in sys.argv[1:]:
        build(nm)
