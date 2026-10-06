// The frame analyser for WCAG 2.2 criterion 2.3.1 (three flashes or below threshold), as Legal states it in docs/legal/photosensitivity-note.md.
// Dependency-free (Node built-ins only: zlib for PNG). It reads a sequence of frames (one per tick, so 60 a second) and reports, for the general flash and
// the red flash, the most flashes in any one second. It is NOT a recognised analyser (Harding / PEAT): docs/tools/flash-check.md says what it can and cannot claim.
//
// The reading of the standard (every number is a parameter, so a different reading is one flag):
//   general flash   a pair of opposing changes in relative luminance of 0.10 or more (of a maximum of 1.0) where the darker state is below 0.80
//   red flash       a pair of opposing transitions involving a saturated red (R/(R+G+B) >= 0.8, R G B in 0..1 as stored) with a change of (R-G-B)*320 of more than 20
//   area            a change counts only if the pixels making it, anywhere in the frame (contiguous or not: the safe over-count), cover at least 341*256 px at 1024*768
//                   (0.111 of the frame, scaled to the frame's size)
//   count           flashes = opposing changes / 2 in any window of one second (fps frames); more than 3 fails
// A change is a swing of one pixel's value of at least the threshold, taken from its last extreme, so a slow ramp is one change and a flicker below the threshold is none.
'use strict';
const zlib = require('zlib');

const DEFAULTS = {
  fps: 60,
  lumDelta: 0.10,        // general flash: the change, of a maximum of 1.0
  darkBelow: 0.80,       // general flash: the darker state must be below this relative luminance
  redDelta: 20,          // red flash: the change of (R-G-B)*320
  redShare: 0.80,        // red flash: R/(R+G+B) at or above this is a saturated red
  areaFrac: (341 * 256) / (1024 * 768),
  maxFlashes: 3,         // more than this in any second fails
};

// ------------------------------------------------------------------ PNG
function paeth(a, b, c) {
  const p = a + b - c;
  const pa = Math.abs(p - a), pb = Math.abs(p - b), pc = Math.abs(p - c);
  return pa <= pb && pa <= pc ? a : pb <= pc ? b : c;
}

/** Decodes an 8-bit, non-interlaced PNG of colour type 0, 2, 3, 4 or 6 to { w, h, data } (RGBA, 4 bytes a pixel). */
function decodePng(buf) {
  if (buf.length < 8 || buf.readUInt32BE(0) !== 0x89504e47) throw new Error('not a PNG');
  let off = 8, w = 0, h = 0, depth = 0, ctype = 0, inter = 0;
  const idat = [];
  let plte = null, trns = null;
  while (off + 8 <= buf.length) {
    const len = buf.readUInt32BE(off), type = buf.toString('latin1', off + 4, off + 8);
    const body = buf.subarray(off + 8, off + 8 + len);
    if (type === 'IHDR') { w = body.readUInt32BE(0); h = body.readUInt32BE(4); depth = body[8]; ctype = body[9]; inter = body[12]; }
    else if (type === 'PLTE') plte = body;
    else if (type === 'tRNS') trns = body;
    else if (type === 'IDAT') idat.push(body);
    else if (type === 'IEND') break;
    off += 12 + len;
  }
  if (depth !== 8 || inter !== 0) throw new Error(`unsupported PNG (bit depth ${depth}, interlace ${inter}); 8-bit non-interlaced only`);
  const ch = { 0: 1, 2: 3, 3: 1, 4: 2, 6: 4 }[ctype];
  if (!ch) throw new Error(`unsupported PNG colour type ${ctype}`);
  const raw = zlib.inflateSync(Buffer.concat(idat));
  const stride = w * ch;
  const px = Buffer.alloc(h * stride);
  for (let y = 0; y < h; y++) {
    const ft = raw[y * (stride + 1)];
    const src = y * (stride + 1) + 1, dst = y * stride;
    for (let x = 0; x < stride; x++) {
      const a = x >= ch ? px[dst + x - ch] : 0;
      const b = y > 0 ? px[dst - stride + x] : 0;
      const c = x >= ch && y > 0 ? px[dst - stride + x - ch] : 0;
      const v = raw[src + x];
      px[dst + x] = (ft === 0 ? v : ft === 1 ? v + a : ft === 2 ? v + b : ft === 3 ? v + ((a + b) >> 1) : ft === 4 ? v + paeth(a, b, c) : (() => { throw new Error(`bad PNG filter ${ft}`); })()) & 255;
    }
  }
  const data = new Uint8Array(w * h * 4);
  for (let i = 0; i < w * h; i++) {
    let r, g, b, a = 255;
    if (ctype === 6) { r = px[i * 4]; g = px[i * 4 + 1]; b = px[i * 4 + 2]; a = px[i * 4 + 3]; }
    else if (ctype === 2) { r = px[i * 3]; g = px[i * 3 + 1]; b = px[i * 3 + 2]; }
    else if (ctype === 0) { r = g = b = px[i]; }
    else if (ctype === 4) { r = g = b = px[i * 2]; a = px[i * 2 + 1]; }
    else { const k = px[i]; r = plte[k * 3]; g = plte[k * 3 + 1]; b = plte[k * 3 + 2]; if (trns && k < trns.length) a = trns[k]; }
    data[i * 4] = r; data[i * 4 + 1] = g; data[i * 4 + 2] = b; data[i * 4 + 3] = a;
  }
  return { w, h, data };
}

/** Encodes RGBA to a PNG (used by the self-test to make frames; also handy for a tool that wants to save one). */
function encodePng(w, h, rgba) {
  const stride = w * 4;
  const raw = Buffer.alloc(h * (stride + 1));
  for (let y = 0; y < h; y++) { raw[y * (stride + 1)] = 0; Buffer.from(rgba.buffer, rgba.byteOffset + y * stride, stride).copy(raw, y * (stride + 1) + 1); }
  const crcTable = [];
  for (let n = 0; n < 256; n++) { let c = n; for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1; crcTable[n] = c >>> 0; }
  const crc = (b) => { let c = 0xffffffff; for (const x of b) c = crcTable[(c ^ x) & 255] ^ (c >>> 8); return (c ^ 0xffffffff) >>> 0; };
  const chunk = (t, body) => { const o = Buffer.alloc(12 + body.length); o.writeUInt32BE(body.length, 0); o.write(t, 4, 'latin1'); body.copy(o, 8); o.writeUInt32BE(crc(o.subarray(4, 8 + body.length)), 8 + body.length); return o; };
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(w, 0); ihdr.writeUInt32BE(h, 4); ihdr[8] = 8; ihdr[9] = 6;
  return Buffer.concat([Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]), chunk('IHDR', ihdr), chunk('IDAT', zlib.deflateSync(raw)), chunk('IEND', Buffer.alloc(0))]);
}

// ------------------------------------------------------------------ the measures
const LIN = new Float64Array(256);
for (let i = 0; i < 256; i++) { const c = i / 255; LIN[i] = c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4); }

/** WCAG relative luminance of an 8-bit sRGB pixel, 0..1. */
function relLum(r, g, b) { return 0.2126 * LIN[r] + 0.7152 * LIN[g] + 0.0722 * LIN[b]; }

/** The red measure of a pixel: (R-G-B)*320 on stored values 0..1 when R/(R+G+B) >= share, else 0. */
function redMeasure(r, g, b, share) {
  const s = r + g + b;
  if (s === 0 || r / s < share) return 0;
  return ((r - g - b) / 255) * 320;
}

/**
 * One detector over a sequence of per-pixel values. Feed frames in order with push(values); each push returns { up, down }: how many pixels turned a change in that
 * direction on this frame (a swing of at least `delta` from the pixel's last extreme). `dark` (general flash) refuses a swing whose darker state is at or above that value.
 */
class Detector {
  constructor(n, delta, dark) {
    this.n = n; this.delta = delta; this.dark = dark;
    this.ext = new Float32Array(n); this.dir = new Int8Array(n); this.first = true;
  }
  push(v) {
    const { n, delta, dark, ext, dir } = this;
    if (this.first) { ext.set(v); this.first = false; return { up: 0, down: 0 }; }
    let up = 0, down = 0;
    for (let i = 0; i < n; i++) {
      const x = v[i], e = ext[i], d = dir[i];
      if (d === 0) {
        if (x - e >= delta) { if (e < dark) up++; dir[i] = 1; ext[i] = x; }
        else if (e - x >= delta) { if (x < dark) down++; dir[i] = -1; ext[i] = x; }
      } else if (d === 1) {
        if (x > e) ext[i] = x;
        else if (e - x >= delta) { if (x < dark) down++; dir[i] = -1; ext[i] = x; }
      } else if (x < e) ext[i] = x;
      else if (x - e >= delta) { if (e < dark) up++; dir[i] = 1; ext[i] = x; }
    }
    return { up, down };
  }
}

/**
 * Counts the flashes in a list of signed events [{ f: frame, s: +1 | -1, area }] (only those over the area threshold): same-sign neighbours merge into one
 * change, then the most opposing changes in any window of `fps` frames is halved.
 */
function worstWindow(events, fps) {
  const ch = [];
  for (const e of events) { if (ch.length && ch[ch.length - 1].s === e.s) continue; ch.push({ f: e.f, s: e.s }); }
  let worst = 0, at = -1;
  for (let i = 0, j = 0; i < ch.length; i++) {
    if (j < i) j = i;
    while (j + 1 < ch.length && ch[j + 1].f < ch[i].f + fps) j++;
    const n = j - i + 1;
    if (n / 2 > worst) { worst = n / 2; at = ch[i].f; }
  }
  return { flashes: worst, atFrame: at, changes: ch.length };
}

/**
 * Analyses frames: an array of { w, h, data } (RGBA) or a function (i) => frame with `count`. Returns
 * { frames, general: { flashes, atFrame, events }, red: {...}, areaPx, pass, ... }. Never says "safe": `pass` only means "this reading found no failure in these frames".
 */
function analyse(frames, opts = {}) {
  const o = Object.assign({}, DEFAULTS, opts);
  const get = typeof frames === 'function' ? frames : (i) => frames[i];
  const count = typeof frames === 'function' ? o.count : frames.length;
  if (!count || count < 2) throw new Error('need at least two frames');
  const f0 = get(0);
  const n = f0.w * f0.h;
  const areaPx = Math.round(o.areaFrac * n);
  const dg = new Detector(n, o.lumDelta, o.darkBelow);
  const dr = new Detector(n, o.redDelta, Infinity);
  const lum = new Float32Array(n), red = new Float32Array(n);
  const gEv = [], rEv = [];
  const peak = { general: 0, red: 0 };
  for (let k = 0; k < count; k++) {
    const fr = get(k);
    if (fr.w !== f0.w || fr.h !== f0.h) throw new Error(`frame ${k} is ${fr.w}x${fr.h}, the first is ${f0.w}x${f0.h}`);
    const d = fr.data;
    for (let i = 0, p = 0; i < n; i++, p += 4) { lum[i] = relLum(d[p], d[p + 1], d[p + 2]); red[i] = redMeasure(d[p], d[p + 1], d[p + 2], o.redShare); }
    const a = dg.push(lum), b = dr.push(red);
    peak.general = Math.max(peak.general, a.up, a.down);
    peak.red = Math.max(peak.red, b.up, b.down);
    if (a.up >= areaPx || a.down >= areaPx) gEv.push({ f: k, s: a.up >= a.down ? 1 : -1, area: Math.max(a.up, a.down) });
    if (b.up >= areaPx || b.down >= areaPx) rEv.push({ f: k, s: b.up >= b.down ? 1 : -1, area: Math.max(b.up, b.down) });
  }
  const g = worstWindow(gEv, o.fps), r = worstWindow(rEv, o.fps);
  return {
    frames: count, width: f0.w, height: f0.h, fps: o.fps, areaPx, areaOfFrame: o.areaFrac,
    general: { flashes: g.flashes, atFrame: g.atFrame, qualifyingChanges: g.changes, largestChangePx: peak.general, largestChangeOfFrame: peak.general / n },
    red: { flashes: r.flashes, atFrame: r.atFrame, qualifyingChanges: r.changes, largestChangePx: peak.red, largestChangeOfFrame: peak.red / n },
    pass: g.flashes <= o.maxFlashes && r.flashes <= o.maxFlashes,
    params: o,
  };
}

module.exports = { DEFAULTS, decodePng, encodePng, relLum, redMeasure, Detector, worstWindow, analyse };
