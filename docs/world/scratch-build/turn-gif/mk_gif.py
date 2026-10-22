import sys, glob, os
from PIL import Image

src, out, w, colors, ms = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4]), int(sys.argv[5])
a = int(sys.argv[6]) if len(sys.argv) > 6 else 0
b = int(sys.argv[7]) if len(sys.argv) > 7 else 10**9
files = sorted(glob.glob(os.path.join(src, 't*.jpg')))
files = [f for f in files if a <= int(os.path.basename(f)[1:6]) <= b]
frames = []
for f in files:
    im = Image.open(f).convert('RGB')
    h = round(im.height * w / im.width)
    im = im.resize((w, h), Image.LANCZOS)
    frames.append(im)
# one palette for the whole clip (from a sample of its frames), so the colours do not shimmer between frames
sheet = Image.new('RGB', (w, frames[0].height * min(8, len(frames))))
step = max(1, len(frames) // 8)
for i, k in enumerate(range(0, len(frames), step)):
    if i >= 8:
        break
    sheet.paste(frames[k], (0, i * frames[0].height))
pal = sheet.quantize(colors=colors, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
q = [f.quantize(palette=pal, dither=Image.Dither.NONE) for f in frames]
q[0].save(out, save_all=True, append_images=q[1:], duration=ms, loop=0, optimize=True, disposal=1)
print(len(q), 'frames', os.path.getsize(out), 'bytes')
