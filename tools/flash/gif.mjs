// A small GIF decoder with no dependencies (GIF87a and GIF89a: global and local palettes, interlacing, transparency, the three disposal methods, frame delays, the loop count), so a
// GIF can go through the flash analyser as frames. Returns the frames composed on the logical screen the way a browser shows them.
//
//   decodeGif(buffer) -> { width, height, loop, frames: [{ rgba: Uint8Array (width*height*4), delayMs }] }
//   timeline(frames, fps = 60, loopSeamTicks = 0) -> [frame index per tick]: each GIF frame held for its delay in ticks of 1/fps s (a browser shows a delay under 20 ms as 100 ms, so does
//                                                   this), then, when loopSeamTicks > 0, the start of the clip again, so the seam where it loops is analysed too
import { createRequire } from 'node:module';

const BROWSER_MIN_DELAY_MS = 20;      // browsers treat a delay of 0 or 10 ms as 100 ms
const BROWSER_DEFAULT_DELAY_MS = 100;

export function decodeGif(buf) {
  if (buf.length < 13 || (buf.toString('latin1', 0, 6) !== 'GIF87a' && buf.toString('latin1', 0, 6) !== 'GIF89a')) throw new Error('not a GIF');
  let p = 6;
  const width = buf.readUInt16LE(p), height = buf.readUInt16LE(p + 2);
  const flags = buf[p + 4], bgIndex = buf[p + 5];
  p += 7;
  let gct = null;
  if (flags & 0x80) { const n = 2 << (flags & 7); gct = buf.subarray(p, p + n * 3); p += n * 3; }
  const screen = new Uint8Array(width * height * 4);           // what is on screen now (transparent black at first)
  const frames = [];
  let loop = 1;
  let gce = { disposal: 0, delayMs: BROWSER_DEFAULT_DELAY_MS, transparent: -1 };
  const skipBlocks = () => { while (p < buf.length && buf[p] !== 0) p += buf[p] + 1; p++; };
  while (p < buf.length) {
    const b = buf[p++];
    if (b === 0x3b) break;                                     // trailer
    if (b === 0x21) {                                          // extension
      const label = buf[p++];
      if (label === 0xf9) {                                    // graphic control: size 4, packed, delay (1/100 s), transparent index, terminator
        const packed = buf[p + 1];
        let ms = buf.readUInt16LE(p + 2) * 10;
        if (ms < BROWSER_MIN_DELAY_MS) ms = BROWSER_DEFAULT_DELAY_MS;
        gce = { disposal: (packed >> 2) & 7, delayMs: ms, transparent: packed & 1 ? buf[p + 4] : -1 };
        p += 1 + buf[p];
        p++;
      } else if (label === 0xff && buf.toString('latin1', p + 1, p + 12) === 'NETSCAPE2.0') {
        const sub = p + 1 + buf[p];
        if (buf[sub] >= 3 && buf[sub + 1] === 1) loop = buf.readUInt16LE(sub + 2);
        skipBlocks();
      } else skipBlocks();
      continue;
    }
    if (b !== 0x2c) throw new Error(`unexpected GIF block 0x${b.toString(16)} at ${p - 1}`);
    const ix = buf.readUInt16LE(p), iy = buf.readUInt16LE(p + 2), iw = buf.readUInt16LE(p + 4), ih = buf.readUInt16LE(p + 6);
    const lf = buf[p + 8];
    p += 9;
    let palette = gct;
    if (lf & 0x80) { const n = 2 << (lf & 7); palette = buf.subarray(p, p + n * 3); p += n * 3; }
    if (!palette) throw new Error('GIF frame without a palette');
    const minCode = buf[p++];
    const chunks = [];
    while (p < buf.length && buf[p] !== 0) { chunks.push(buf.subarray(p + 1, p + 1 + buf[p])); p += buf[p] + 1; }
    p++;
    const indices = lzwDecode(Buffer.concat(chunks), minCode, iw * ih);
    const saved = gce.disposal === 3 ? screen.slice() : null;
    const rows = lf & 0x40 ? interlaceRows(ih) : null;
    for (let y = 0; y < ih; y++) {
      const sy = (rows ? rows[y] : y) + iy;
      if (sy >= height) continue;
      for (let x = 0; x < iw; x++) {
        const sx = x + ix;
        if (sx >= width) continue;
        const k = indices[y * iw + x];
        if (k === gce.transparent) continue;
        const o = (sy * width + sx) * 4;
        screen[o] = palette[k * 3]; screen[o + 1] = palette[k * 3 + 1]; screen[o + 2] = palette[k * 3 + 2]; screen[o + 3] = 255;
      }
    }
    frames.push({ rgba: screen.slice(), delayMs: gce.delayMs });
    if (gce.disposal === 2) {                                  // restore to the background: transparent, which a page shows as its own colour (the analyser takes black)
      for (let y = 0; y < ih; y++) for (let x = 0; x < iw; x++) { const sy = y + iy, sx = x + ix; if (sy < height && sx < width) { const o = (sy * width + sx) * 4; screen[o] = screen[o + 1] = screen[o + 2] = screen[o + 3] = 0; } }
    } else if (gce.disposal === 3 && saved) screen.set(saved);
    gce = { disposal: 0, delayMs: BROWSER_DEFAULT_DELAY_MS, transparent: -1 };
  }
  void bgIndex;
  // a frame's transparent pixels are black for analysis
  for (const f of frames) for (let i = 0; i < f.rgba.length; i += 4) if (f.rgba[i + 3] === 0) { f.rgba[i] = f.rgba[i + 1] = f.rgba[i + 2] = 0; f.rgba[i + 3] = 255; }
  return { width, height, loop, frames };
}

function interlaceRows(h) {
  const rows = [];
  for (const [start, step] of [[0, 8], [4, 8], [2, 4], [1, 2]]) for (let y = start; y < h; y += step) rows.push(y);
  return rows;
}

/** GIF's variable-width LZW. */
function lzwDecode(data, minCode, total) {
  const clear = 1 << minCode, end = clear + 1;
  const out = new Uint8Array(total);
  let n = 0, bits = 0, acc = 0, pos = 0, size = minCode + 1, next = end + 1, prev = -1;
  const prefix = new Int32Array(4096), suffix = new Uint8Array(4096), stack = new Uint8Array(4097);
  for (let i = 0; i < clear; i++) suffix[i] = i;
  while (n < total) {
    while (bits < size) { if (pos >= data.length) return out; acc |= data[pos++] << bits; bits += 8; }
    const code = acc & ((1 << size) - 1);
    acc >>>= size; bits -= size;
    if (code === clear) { size = minCode + 1; next = end + 1; prev = -1; continue; }
    if (code === end) break;
    let cur = code, sp = 0;
    if (prev === -1) { out[n++] = suffix[code]; prev = code; continue; }
    if (code >= next) { stack[sp++] = firstOf(prev, prefix, suffix, clear); cur = prev; }
    while (cur >= clear) { stack[sp++] = suffix[cur]; cur = prefix[cur]; }
    stack[sp++] = suffix[cur];
    const first = stack[sp - 1];
    while (sp > 0 && n < total) out[n++] = stack[--sp];
    if (next < 4096) { prefix[next] = prev; suffix[next] = first; next++; if (next === 1 << size && size < 12) size++; }
    prev = code;
  }
  return out;
}
function firstOf(code, prefix, suffix, clear) { let c = code; while (c >= clear) c = prefix[c]; return suffix[c]; }

/** The frame index shown on each tick of 1/fps s (a frame held for its delay), then, with loopSeamTicks > 0, the first that many ticks of the clip again (the loop's seam). */
export function timeline(frames, fps = 60, loopSeamTicks = 0) {
  const out = [];
  let t = 0;
  frames.forEach((f, i) => {
    const end = t + f.delayMs;
    const to = Math.round((end * fps) / 1000);
    const from = Math.round((t * fps) / 1000);
    for (let k = from; k < Math.max(to, from + 1); k++) out.push(i);
    t = end;
  });
  if (loopSeamTicks > 0) { const n = out.length; for (let k = 0; k < Math.min(loopSeamTicks, n); k++) out.push(out[k]); }
  return out;
}

/** RGBA of a frame as a PNG (for a poster). */
export function framePng(gif, index, shrink = 1) {
  const require = createRequire(import.meta.url);
  const W = require('./wcag.js');
  const f = gif.frames[index];
  if (shrink <= 1) return W.encodePng(gif.width, gif.height, f.rgba);
  const w = Math.floor(gif.width / shrink), h = Math.floor(gif.height / shrink);
  const o = new Uint8Array(w * h * 4);
  const n = shrink * shrink;
  for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) {
    let r = 0, g = 0, b = 0;
    for (let j = 0; j < shrink; j++) for (let i = 0; i < shrink; i++) { const q = ((y * shrink + j) * gif.width + (x * shrink + i)) * 4; r += f.rgba[q]; g += f.rgba[q + 1]; b += f.rgba[q + 2]; }
    const d = (y * w + x) * 4;
    o[d] = Math.round(r / n); o[d + 1] = Math.round(g / n); o[d + 2] = Math.round(b / n); o[d + 3] = 255;
  }
  return W.encodePng(w, h, o);
}
