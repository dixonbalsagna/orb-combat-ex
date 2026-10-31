// SCRATCH: a contact sheet: node sw_sheet.mjs <wcag.js> <out.png> <cols> <scale> <files...>
import { readFileSync, writeFileSync } from 'node:fs';
import { createRequire } from 'node:module';
const [wc, out, cols, sc, ...files] = process.argv.slice(2);
const { decodePng, encodePng } = createRequire(import.meta.url)(wc);
const C = +cols, S = +sc;
const ims = files.map((f) => decodePng(readFileSync(f)));
const w = Math.floor(ims[0].w / S), h = Math.floor(ims[0].h / S);
const rows = Math.ceil(ims.length / C), W = C * w + (C - 1) * 4, H = rows * h + (rows - 1) * 4;
const d = Buffer.alloc(W * H * 4, 255);
ims.forEach((p, k) => {
  const ox = (k % C) * (w + 4), oy = Math.floor(k / C) * (h + 4);
  for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) {
    const si = (y * S * p.w + x * S) * 4, di = ((oy + y) * W + ox + x) * 4;
    for (let c = 0; c < 4; c++) d[di + c] = p.data[si + c];
  }
});
writeFileSync(out, encodePng(W, H, d));
