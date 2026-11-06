# Orb's GIFs (private, never committed): frames -> a looping GIF under a size limit, one global palette (no dither: no flicker between frames). Usage as a module: encode(frames, delay_ms, out, maxkb)
import os, sys, io
from PIL import Image

def encode(frames, delay_ms, out, maxkb=560, colors_try=(64, 48, 40, 32, 24, 20, 16), allow_drop=False):
    frames = [f.convert('RGB') for f in frames]
    best = None
    for keep_every in ((1, 2) if allow_drop else (1,)):
        fr = frames[::keep_every]
        dl = delay_ms * keep_every
        for n in colors_try:
            # one palette for the whole clip: a montage of a spread of frames, quantised once
            sample = fr[::max(1, len(fr) // 8)]
            w, h = sample[0].size
            mont = Image.new('RGB', (w, h * len(sample)))
            for i, s in enumerate(sample):
                mont.paste(s, (0, i * h))
            pal = mont.quantize(colors=n, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
            q = [f.quantize(palette=pal, dither=Image.Dither.NONE) for f in fr]
            buf = io.BytesIO()
            q[0].save(buf, format='GIF', save_all=True, append_images=q[1:], duration=dl, loop=0, optimize=False, disposal=1)
            kb = len(buf.getvalue()) / 1024
            if best is None or kb < best[0]:
                best = (kb, n, keep_every, dl, buf.getvalue())
            if kb <= maxkb:
                with open(out, 'wb') as fh:
                    fh.write(buf.getvalue())
                return kb, n, len(fr), dl
    kb, n, ke, dl, data = best
    with open(out, 'wb') as fh:
        fh.write(data)
    return kb, n, len(frames[::ke]), dl

def crop_still(path, box, width=480):
    im = Image.open(path).convert('RGB').crop(box)
    if im.size[0] != width:
        im = im.resize((width, round(im.size[1] * width / im.size[0])), Image.LANCZOS)
    return im
