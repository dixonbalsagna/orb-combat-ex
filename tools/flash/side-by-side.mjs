// Two captured clips side by side, for showing a regression: stills at chosen ticks (PNG, full size) and a GIF (half size, ordered dither), no dependencies.
//   node tools/flash/side-by-side.mjs --left <frames dir> --right <frames dir> --out <dir> [--from 1] [--to N] [--step 3] [--stills 5] [--labels d3f1ca0,5c46fec] [--name regression] [--delay 5] [--stills-at 120,300,...]
// The frames are tools/flash/capture-web.mjs's (frame-000001.png ...); the tick is the frame number. Left and right are drawn with a thin colour bar on top (left blue, right orange), the label
// (a hex string, drawn in a 3x5 font) in the corner of each, and the tick at the right end of each panel. The GIF takes every <step>th frame from <from> to <to> at <delay> hundredths of a second.
import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { createRequire } from 'node:module';
import { readMatch, differences, matchText } from './clip-id.mjs';
const { decodePng, encodePng } = createRequire(import.meta.url)('./wcag.js');

const argv = process.argv.slice(2);
const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 ? argv[i + 1] : d; };
const L = opt('--left'), R = opt('--right'), OUT = opt('--out');
if (!L || !R || !OUT) { console.error('usage: node tools/flash/side-by-side.mjs --left <dir> --right <dir> --out <dir> [--from 1] [--to N] [--step 3] [--stills 5] [--stills-at t,t] [--labels a,b] [--name n] [--delay 5] [--allow-different]'); process.exit(2); }
const from = Number(opt('--from', 1)), to = Number(opt('--to', 3600)), step = Number(opt('--step', 3)), delay = Number(opt('--delay', 5));
const labels = (opt('--labels', 'left,right')).split(',');
const name = opt('--name', 'side-by-side');
// Two clips of different matches are not a regression: the pair is refused unless the two sides carry the same scenario, seed, pairing and variant (the clip.json capture-web.mjs wrote), or --allow-different
// says the difference is the point. A side with no record (a clip from before it, or a folder of frames from elsewhere) is shown with a warning, because there is nothing to compare.
const sides = [['left', L], ['right', R]].map(([which, dir]) => ({ which, ...readMatch(dir) }));
for (const s of sides) console.log(s.match ? `${s.which}: ${matchText(s.match)}${s.match.derived ? ' (derived from an older clip.json: the pairing was not recorded)' : ''}` : `${s.which}: no match record (${s.why})`);
if (sides.every((s) => s.match)) {
  const diff = differences(sides[0].match, sides[1].match);
  if (diff.length && !argv.includes('--allow-different')) { console.error(`side-by-side: REFUSED: the two clips are not the same match (${diff.join('; ')}). Capture both with the same --seed and --slots, or pass --allow-different if the difference is the point.`); process.exit(1); }
  if (diff.length) console.error(`side-by-side: WARNING: the two clips are not the same match (${diff.join('; ')}); --allow-different was given`);
} else console.error('side-by-side: WARNING: a side has no match record, so the two cannot be checked to be the same match; capture with tools/flash/capture-web.mjs to get one');
mkdirSync(OUT, { recursive: true });
writeFileSync(join(OUT, `${name}-clips.json`), JSON.stringify({ left: sides[0].match, right: sides[1].match, leftDir: L, rightDir: R, sameMatch: sides.every((s) => s.match) ? differences(sides[0].match, sides[1].match).length === 0 : null }, null, 2) + String.fromCharCode(10));   // the match of each side, beside the stills and the GIF
const fp = (d, t) => join(d, `frame-${String(t).padStart(6, '0')}.png`);

// ---- a 3x5 font for 0-9, a-f and a few marks
const FONT = {
  0: '111101101101111', 1: '010110010010111', 2: '111001111100111', 3: '111001111001111', 4: '101101111001001', 5: '111100111001111', 6: '111100111101111', 7: '111001001001001',
  8: '111101111101111', 9: '111101111001111', a: '010101111101101', b: '110101110101110', c: '011100100100011', d: '110101101101110', e: '111100110100111', f: '111100110100100',
  ' ': '000000000000000', '-': '000000111000000', '#': '101111101111101',
};
function text(img, str, x0, y0, scale, rgb) {
  let x = x0;
  for (const ch of str) {
    const g = FONT[ch] || FONT[' '];
    for (let i = 0; i < 15; i++) if (g[i] === '1') for (let dy = 0; dy < scale; dy++) for (let dx = 0; dx < scale; dx++) {
      const px = x + (i % 3) * scale + dx, py = y0 + Math.floor(i / 3) * scale + dy;
      if (px < img.w && py < img.h) { const o = (py * img.w + px) * 4; img.data[o] = rgb[0]; img.data[o + 1] = rgb[1]; img.data[o + 2] = rgb[2]; img.data[o + 3] = 255; }
    }
    x += 4 * scale;
  }
}
function rect(img, x0, y0, w, h, rgb) { for (let y = y0; y < y0 + h && y < img.h; y++) for (let x = x0; x < x0 + w && x < img.w; x++) { const o = (y * img.w + x) * 4; img.data[o] = rgb[0]; img.data[o + 1] = rgb[1]; img.data[o + 2] = rgb[2]; img.data[o + 3] = 255; } }

/** One composed frame { w, h, data }: the two panels, the bars, the labels, the tick. */
function compose(t) {
  const a = decodePng(readFileSync(fp(L, t))), b = decodePng(readFileSync(fp(R, t)));
  const gap = 6, h = Math.max(a.h, b.h) + 14, w = a.w + b.w + gap;
  const img = { w, h, data: new Uint8Array(w * h * 4) };
  for (let i = 0; i < img.data.length; i += 4) { img.data[i] = 16; img.data[i + 1] = 16; img.data[i + 2] = 16; img.data[i + 3] = 255; }
  const blit = (p, ox) => { for (let y = 0; y < p.h; y++) img.data.set(p.data.subarray(y * p.w * 4, (y + 1) * p.w * 4), ((y + 14) * w + ox) * 4); };
  blit(a, 0); blit(b, a.w + gap);
  rect(img, 0, 0, a.w, 4, [70, 130, 255]); rect(img, a.w + gap, 0, b.w, 4, [255, 150, 40]);
  text(img, labels[0], 4, 6, 2, [140, 180, 255]); text(img, labels[1], a.w + gap + 4, 6, 2, [255, 190, 110]);
  const tw = String(t).length * 8;
  text(img, String(t), a.w - tw - 4, 6, 2, [230, 230, 230]); text(img, String(t), a.w + gap + b.w - tw - 4, 6, 2, [230, 230, 230]);
  return img;
}
const half = (img) => {
  const w = img.w >> 1, h = img.h >> 1, data = new Uint8Array(w * h * 4);
  for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) for (let c = 0; c < 4; c++) {
    const o = ((2 * y) * img.w + 2 * x) * 4 + c;
    data[(y * w + x) * 4 + c] = (img.data[o] + img.data[o + 4] + img.data[o + img.w * 4] + img.data[o + img.w * 4 + 4]) >> 2;
  }
  return { w, h, data };
};

// ---- a GIF encoder: 6x7x6 colour cube plus 4 greys (252 + 4), ordered dither, LZW
const BAYER = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5];
function palette() { const p = []; for (let r = 0; r < 6; r++) for (let g = 0; g < 7; g++) for (let b = 0; b < 6; b++) p.push([Math.round(r * 255 / 5), Math.round(g * 255 / 6), Math.round(b * 255 / 5)]); while (p.length < 256) p.push([0, 0, 0]); return p; }
const PAL = palette();
function index(img) {
  const out = new Uint8Array(img.w * img.h);
  for (let y = 0; y < img.h; y++) for (let x = 0; x < img.w; x++) {
    const o = (y * img.w + x) * 4, th = (BAYER[(y & 3) * 4 + (x & 3)] / 16 - 0.5);
    const q = (v, n) => Math.max(0, Math.min(n - 1, Math.round((v / 255 + th / (n - 1)) * (n - 1))));
    out[y * img.w + x] = q(img.data[o], 6) * 42 + q(img.data[o + 1], 7) * 6 + q(img.data[o + 2], 6);
  }
  return out;
}
function lzw(idx, minCode) {
  const clear = 1 << minCode, eoi = clear + 1;
  let codeSize = minCode + 1, next = eoi + 1, dict = new Map();
  const out = []; let cur = 0, bits = 0;
  const emit = (c) => { cur |= c << bits; bits += codeSize; while (bits >= 8) { out.push(cur & 255); cur >>>= 8; bits -= 8; } };
  emit(clear);
  let prefix = idx[0];
  for (let i = 1; i < idx.length; i++) {
    const k = idx[i], key = prefix * 256 + k;
    const hit = dict.get(key);
    if (hit !== undefined) { prefix = hit; continue; }
    emit(prefix);
    if (next < 4096) { dict.set(key, next++); if (next - 1 === (1 << codeSize) && codeSize < 12) codeSize++; }
    else { emit(clear); dict = new Map(); next = eoi + 1; codeSize = minCode + 1; }
    prefix = k;
  }
  emit(prefix); emit(eoi);
  if (bits > 0) out.push(cur & 255);
  return Buffer.from(out);
}
function gif(frames, delayCs) {
  const w = frames[0].w, h = frames[0].h;
  const parts = [Buffer.from('GIF89a'), Buffer.from([w & 255, w >> 8, h & 255, h >> 8, 0xf7, 0, 0])];
  parts.push(Buffer.from(PAL.flat()));
  parts.push(Buffer.from([0x21, 0xff, 0x0b, ...Buffer.from('NETSCAPE2.0'), 3, 1, 0, 0, 0]));
  for (const f of frames) {
    parts.push(Buffer.from([0x21, 0xf9, 4, 0, delayCs & 255, delayCs >> 8, 0, 0]));
    parts.push(Buffer.from([0x2c, 0, 0, 0, 0, w & 255, w >> 8, h & 255, h >> 8, 0, 8]));
    const data = lzw(index(f), 8);
    for (let i = 0; i < data.length; i += 255) { const n = Math.min(255, data.length - i); parts.push(Buffer.from([n]), data.subarray(i, i + n)); }
    parts.push(Buffer.from([0]));
  }
  parts.push(Buffer.from([0x3b]));
  return Buffer.concat(parts);
}

// ---- stills
const have = (t) => existsSync(fp(L, t)) && existsSync(fp(R, t));
const at = opt('--stills-at') ? opt('--stills-at').split(',').map(Number) : Array.from({ length: Number(opt('--stills', 5)) }, (_, i) => Math.round(from + (to - from) * (i + 0.5) / Number(opt('--stills', 5))));
for (const t of at) {
  if (!have(t)) { console.log(`still ${t}: a frame is missing`); continue; }
  const img = compose(t);
  writeFileSync(join(OUT, `${name}-t${String(t).padStart(5, '0')}.png`), encodePng(img.w, img.h, img.data));
  console.log(`still: ${name}-t${String(t).padStart(5, '0')}.png`);
}
// ---- the GIF
const frames = [];
for (let t = from; t <= to; t += step) if (have(t)) frames.push(half(compose(t)));
if (frames.length) {
  const g = gif(frames, delay);
  writeFileSync(join(OUT, `${name}.gif`), g);
  console.log(`gif: ${name}.gif, ${frames.length} frames of ${frames[0].w}x${frames[0].h}, ${Math.round(g.length / 1024)} KB`);
}
