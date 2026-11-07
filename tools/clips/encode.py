"""The clip kit's encoder (tools/clips): a folder of frames (JPEG or PNG, in file name order) -> one looping GIF under a size limit, a PNG sequence, or a folder of prepared frames for the WebM step.

    python encode.py --in <frames folder> --out <file or folder> --format gif|png|frames [--crop x0,y0,x1,y1] [--width 480] [--fps 12] [--maxkb 560] [--blur 0] [--tol 0] [--strip strip.json] [--drop]

One palette for the whole clip (a montage of a spread of frames, quantised once, no dither), so the colours do not flicker from frame to frame; the palette is cut down (64, 48, 40, 32, 24, 20, 16 colours) until the file fits.
Only Pillow (PIL) is needed; nothing else is installed or downloaded. Prints one JSON line: the file, its size, the colours, the frames, the seconds.
"""
import argparse, io, json, os, sys
from PIL import Image, ImageChops, ImageFilter


STRIP_H = 34
BG = (16, 19, 26)
OFF = (58, 66, 82)
TXT = (214, 220, 232)
FACE = {'X': (74, 140, 255), 'Y': (245, 197, 66), 'B': (229, 72, 77), 'A': (63, 184, 106)}
LIT = (207, 214, 228)
ORDER = ['LS', 'LT', 'LB', 'X', 'Y', 'B', 'A', 'RB', 'RT', 'RS']


def _font(size):
    from PIL import ImageFont
    for name in ('arialbd.ttf', 'arial.ttf', 'DejaVuSans-Bold.ttf', 'DejaVuSans.ttf'):
        try:
            return ImageFont.truetype(name, size)
        except Exception:
            pass
    return ImageFont.load_default()


def draw_strip(width, st):
    """The button strip: one band under the picture (never over it) with the pad's controls, lit while pressed, and a word under a lit one: tap, hold or mash. st is the frame's state from make.mjs: {LS: [x, y], X: 'tap'|'hold'|'mash'|null, ..., RS: {dir, level, g}}."""
    from PIL import ImageDraw
    im = Image.new('RGB', (width, STRIP_H), BG)
    d = ImageDraw.Draw(im)
    big, small = _font(11), _font(8)
    cell = width / len(ORDER)
    for i, k in enumerate(ORDER):
        cx = int(cell * i + cell / 2)
        cy = 13
        if k == 'LS' or k == 'RS':
            r = 10
            d.ellipse((cx - r, cy - r, cx + r, cy + r), outline=OFF if True else TXT, fill=(28, 33, 44))
            if k == 'LS':
                x, y = (st.get('LS') or [0, 0])
                px, py = cx + int(max(-1, min(1, x)) * (r - 4)), cy + int(max(-1, min(1, y)) * (r - 4))
                lit = abs(x) > 0.15 or abs(y) > 0.15
                d.ellipse((px - 3, py - 3, px + 3, py + 3), fill=LIT if lit else OFF)
                g = None
            else:
                rs = st.get('RS') or {}
                g = rs.get('g')
                dr = int(rs.get('dir') or 0)
                if g or dr:
                    col = FACE['Y'] if g else OFF
                    if dr == 1:
                        d.polygon([(cx, cy - 7), (cx - 5, cy + 1), (cx + 5, cy + 1)], fill=col)
                    elif dr == 2:
                        d.polygon([(cx, cy + 7), (cx - 5, cy - 1), (cx + 5, cy - 1)], fill=col)
                    elif dr == 3:
                        d.polygon([(cx - 7, cy), (cx + 1, cy - 5), (cx + 1, cy + 5)], fill=col)
                    elif dr == 4:
                        d.polygon([(cx + 7, cy), (cx - 1, cy - 5), (cx - 1, cy + 5)], fill=col)
                    else:
                        d.ellipse((cx - 3, cy - 3, cx + 3, cy + 3), fill=col)
                lvl = int(rs.get('level') or 0)
                for j in range(min(lvl, 3)):
                    d.rectangle((cx - 10 + j * 8, cy + 11, cx - 6 + j * 8, cy + 12), fill=FACE['Y'])
        else:
            g = st.get(k)
            col = (FACE[k] if k in FACE else LIT) if g else OFF
            if k in FACE:
                d.ellipse((cx - 9, cy - 9, cx + 9, cy + 9), fill=col if g else (28, 33, 44), outline=col)
            else:
                d.rounded_rectangle((cx - 15, cy - 7, cx + 15, cy + 7), radius=4, fill=col if g else (28, 33, 44), outline=col)
            tw = d.textlength(k, font=big)
            d.text((cx - tw / 2, cy - 7), k, font=big, fill=(10, 12, 18) if g else (120, 130, 150))
        if g:
            w = d.textlength(g, font=small)
            d.text((cx - w / 2, 24), g, font=small, fill=TXT)
    return im


def prep(frames, crop, width, blur, strips=None):
    out = []
    for n, f in enumerate(frames):
        im = f.convert('RGB')
        if crop:
            im = im.crop(crop)
        if width and im.size[0] != width:
            im = im.resize((width, max(1, round(im.size[1] * width / im.size[0]))), Image.LANCZOS)
        if blur:
            im = im.filter(ImageFilter.GaussianBlur(blur))
        if strips is not None and n < len(strips):
            bar = draw_strip(im.size[0], strips[n])
            both = Image.new('RGB', (im.size[0], im.size[1] + STRIP_H))
            both.paste(im, (0, 0))
            both.paste(bar, (0, im.size[1]))
            im = both
        out.append(im)
    return out


def encode_gif(frames, delay_ms, out, maxkb, colors_try=(64, 48, 40, 32, 24, 20, 16), tol=0, allow_drop=False):
    """One palette for the clip; every frame after the first draws only the pixels that changed by more than `tol` from what is on screen (the rest transparent), so a still background costs nothing.
    If the file does not fit, the tolerance rises (+6 at a time, to tol + 18) before the palette is cut down further."""
    best = None
    for keep in ((1, 2) if allow_drop else (1,)):
        fr = frames[::keep]
        dl = delay_ms * keep
        for extra in (0, 6, 12, 18):
            for n in colors_try:
                sample = fr[::max(1, len(fr) // 8)]
                w, h = sample[0].size
                mont = Image.new('RGB', (w, h * len(sample)))
                for i, s_ in enumerate(sample):
                    mont.paste(s_, (0, i * h))
                pal = mont.quantize(colors=n, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
                q = [f.quantize(palette=pal, dither=Image.Dither.NONE) for f in fr]
                T = 255   # the transparent index: the palette has at most 64 colours, so 255 is free
                shown = q[0].convert('RGB')
                outq = [q[0]]
                for qi in q[1:]:
                    rgb = qi.convert('RGB')
                    changed = ImageChops.difference(rgb, shown).convert('L').point(lambda v, t=tol + extra: 255 if v > t else 0)
                    keepmask = changed.point(lambda v: 255 - v)   # 255 where the pixel stays as it is on screen
                    frame = qi.copy()
                    frame.paste(T, mask=keepmask)
                    frame.info['transparency'] = T
                    outq.append(frame)
                    shown = Image.composite(rgb, shown, changed)
                outq[0].info['transparency'] = T
                buf = io.BytesIO()
                outq[0].save(buf, format='GIF', save_all=True, append_images=outq[1:], duration=dl, loop=0, optimize=False, disposal=1, transparency=T)
                kb = len(buf.getvalue()) / 1024
                if best is None or kb < best[0]:
                    best = (kb, n, len(fr), dl, buf.getvalue(), tol + extra)
                if kb <= maxkb:
                    break
            else:
                continue
            break
        else:
            continue
        break
    kb, n, nf, dl, data, tl = best
    with open(out, 'wb') as fh:
        fh.write(data)
    return kb, n, nf, dl, tl


def main():
    a = argparse.ArgumentParser()
    a.add_argument('--in', dest='src', required=True)
    a.add_argument('--out', required=True)
    a.add_argument('--format', default='gif')
    a.add_argument('--crop', default='')
    a.add_argument('--width', type=int, default=480)
    a.add_argument('--fps', type=float, default=12)
    a.add_argument('--maxkb', type=float, default=560)
    a.add_argument('--blur', type=float, default=0)
    a.add_argument('--tol', type=int, default=0, help='temporal tolerance: pixels that changed by no more than this keep the colour on screen')
    a.add_argument('--strip', default='', help='a json file of one button-strip state per frame (tools/clips/make.mjs): the strip is added under the picture')
    a.add_argument('--drop', action='store_true', help='allow dropping every second frame when the file will not fit')
    o = a.parse_args()
    names = sorted(n for n in os.listdir(o.src) if n.lower().endswith(('.jpg', '.jpeg', '.png')))
    if not names:
        print(json.dumps({'error': 'no frames in ' + o.src})); sys.exit(1)
    crop = tuple(int(x) for x in o.crop.split(',')) if o.crop else None
    strips = None
    if o.strip:
        strips = json.load(open(o.strip))['frames']
        if len(strips) != len(names):
            print(json.dumps({'error': 'the strip has %d states for %d frames' % (len(strips), len(names))})); sys.exit(1)
    frames = prep([Image.open(os.path.join(o.src, n)) for n in names], crop, o.width, o.blur, strips)
    if o.format == 'gif':
        kb, n, nf, dl, tl = encode_gif(frames, round(1000 / o.fps), o.out, o.maxkb, tol=o.tol, allow_drop=o.drop)
        print(json.dumps({'file': o.out, 'kb': round(kb), 'colors': n, 'frames': nf, 'seconds': round(nf * dl / 1000, 1), 'size': list(frames[0].size), 'tol': tl}))
    elif o.format in ('png', 'frames'):
        os.makedirs(o.out, exist_ok=True)
        ext, fmt, kw = ('png', 'PNG', {}) if o.format == 'png' else ('jpg', 'JPEG', {'quality': 90})
        for i, f in enumerate(frames):
            f.save(os.path.join(o.out, 'f-%05d.%s' % (i + 1, ext)), fmt, **kw)
        print(json.dumps({'file': o.out, 'frames': len(frames), 'seconds': round(len(frames) / o.fps, 1), 'size': list(frames[0].size)}))
    else:
        print(json.dumps({'error': 'unknown format ' + o.format})); sys.exit(1)


if __name__ == '__main__':
    main()
