"""A looping GIF for a phone message from a capture folder (tNNNNN.jpg or .png, one per captured tick).
usage: python bd_gif.py <dir> <first tick> <last tick> <out.gif> [step ticks, 5 = 12 fps] [colours] [max KB] [tolerance]
480 px wide, one shared palette (no dither, so nothing crawls). Each frame after the first draws only the pixels that
changed by more than the tolerance from what is on screen (the rest transparent), so the file is small. If it is still
over max KB the tolerance rises, then the colours drop."""
import sys, os
from PIL import Image, ImageChops, ImageFilter

d, a, b, out = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), sys.argv[4]
step = int(sys.argv[5]) if len(sys.argv) > 5 else 5
cols = int(sys.argv[6]) if len(sys.argv) > 6 else 127
maxkb = int(sys.argv[7]) if len(sys.argv) > 7 else 580
tol = int(sys.argv[8]) if len(sys.argv) > 8 else 10
top = float(sys.argv[9]) if len(sys.argv) > 9 else -1.0   # a widescreen crop: its top as a share of the height (-1: none)
CROP_H = 216
ims = []
for n in range(a, b + 1, step):
    for ext in ('png', 'jpg'):
        f = os.path.join(d, 't%05d.%s' % (n, ext))
        if os.path.exists(f):
            im = Image.open(f).convert('RGB')
            im = im.resize((480, int(im.height * 480 / im.width)), Image.LANCZOS)
            if top >= 0.0:
                y0 = int(round(top * im.height))
                im = im.crop((0, y0, 480, y0 + CROP_H))
            ims.append(im)
            break
if len(ims) < 2:
    sys.exit('no frames in %s from %d to %d' % (d, a, b))
ms = int(round(1000.0 * step / 60.0))


def build(cols, tol):
    strip = Image.new('RGB', (480, ims[0].height * len(ims)))
    for i, im in enumerate(ims):
        strip.paste(im, (0, i * im.height))
    # most colours from the whole clip; a share kept for the saturated ones (a costume's red is a few pixels of a big frame)
    nsat = cols // 4
    base = strip.quantize(colors=cols - nsat, method=Image.MEDIANCUT)
    sat = strip.convert('HSV').split()[1].point(lambda v: 255 if v > 110 else 0)
    small = strip.resize((strip.width // 2, strip.height // 2), Image.NEAREST)
    sm = sat.resize(small.size, Image.NEAREST).getdata()
    px = [c for c, m in zip(small.getdata(), sm) if m]
    vivid = Image.new('RGB', (len(px), 1))
    vivid.putdata(px)
    vp = vivid.quantize(colors=nsat, method=Image.Quantize.MAXCOVERAGE)   # spread over the colours, not weighted by area
    pl = base.getpalette()[:3 * (cols - nsat)] + vp.getpalette()[:3 * nsat]
    pal = Image.new('P', (1, 1))
    pal.putpalette(pl + [0, 0, 0] * (256 - cols))
    T = cols   # the transparent index, past the palette's colours
    q = [im.quantize(palette=pal, dither=Image.Dither.NONE) for im in ims]
    rgb = [x.convert('RGB') for x in q]
    frames = [q[0]]
    shown = rgb[0]
    for i in range(1, len(q)):
        dr, dg, db = ImageChops.difference(rgb[i], shown).split()
        diff = ImageChops.lighter(ImageChops.lighter(dr, dg), db)   # the largest channel's change: a hue shift counts
        changed = diff.point(lambda v: 255 if v > tol else 0)
        # specks left alone (a lone changed pixel breaks the encoder's runs); a big change is never left: it is over 3 x tol
        big = diff.point(lambda v: 255 if v > 3 * tol else 0)
        changed = ImageChops.lighter(changed.filter(ImageFilter.MinFilter(3)).filter(ImageFilter.MaxFilter(3)), big)
        shown = Image.composite(rgb[i], shown, changed)
        idx = Image.frombytes('L', q[i].size, q[i].tobytes())
        keep = Image.new('L', q[i].size, T)
        f = Image.composite(idx, keep, changed)
        p = Image.frombytes('P', f.size, f.tobytes())
        p.putpalette(q[i].getpalette())
        p.info['transparency'] = T
        frames.append(p)
    # the loop's seam: the first frame is drawn whole (no transparency on it)
    frames[0].save(out, save_all=True, append_images=frames[1:], duration=ms, loop=0, disposal=1, transparency=T, optimize=False)
    return os.path.getsize(out) / 1024.0


while True:
    kb = build(cols, tol)
    print('%s: %d frames, %.1f s, %d colours, tolerance %d, %.0f KB' % (out, len(ims), len(ims) * ms / 1000.0, cols, tol, kb))
    if kb <= maxkb:
        break
    if tol < 24:
        tol += 6
    elif cols > 31:
        cols = cols // 2
    else:
        break
