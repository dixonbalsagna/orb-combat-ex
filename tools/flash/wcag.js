// The frame analyser for WCAG 2.2 success criterion 2.3.1 (three flashes or below threshold), as Legal states it in docs/legal/photosensitivity-note.md and its RL-116 addendum
// (W3C's Understanding page for 2.3.1). Dependency-free (Node built-ins only: zlib for PNG). It reads a sequence of frames (one per tick, so 60 a second) and reports, for the
// general flash and the red flash, the most flashes in any one second. It is NOT a recognised analyser (Harding / PEAT): docs/tools/flash-check.md says what it can and cannot claim.
//
// The reading of the standard (every number is a parameter, so a different reading is one option):
//   luminance   WCAG relative luminance of each pixel: the 8-bit sRGB values are gamma-decoded (c/255 <= 0.04045 ? c/12.92 : ((c+0.055)/1.055)^2.4), then
//               L = 0.2126 R + 0.7152 G + 0.0722 B (0 to 1)
//   general     a pair of opposing changes in relative luminance of 0.10 or more (of a maximum of 1.0) where the darker state is below 0.80, per pixel
//   red         a pair of opposing transitions where one state is a saturated red (R/(R+G+B) >= 0.8) and the two states differ by more than 0.2 in CIE 1976 u'v' chromaticity,
//               per pixel. "Saturated red" is taken on the stored (sRGB) values or on the linear ones, whichever is red (the more conservative of two readings of the text)
//   area        a change counts only if, in one 341 x 256 window at 1024 x 768 (the standard's estimate of a 10-degree field; scaled to the frame: a third of its width and of
//               its height), at least a quarter of the window's pixels change together, the window slid to every position (an integral image over the changed-pixel mask).
//               At 1024 x 768 that is 25% of 87,296 = 21,824 pixels. A fade that takes several frames is one change: the pixels that turn the same way on consecutive frames are
//               pooled before the window is tried
//   count       flashes = opposing changes / 2 in any window of one second (fps frames); more than 3 fails the standard. OUR gate is 2.5 (RL-119): `pass` means the worst
//               second is 2.5 or below, `passStandard` that it is 3 or below
// A CHANGE HAS A BOUNDED MEMORY (so the result cannot depend on where a clip starts): a pixel's up change happens on the frame it first stands `lumDelta` above its lowest value
// of the last `memory` frames (one second by default), a down change on the frame it first stands that far below its highest value of those frames. Nothing older than that
// window is remembered, so the changes counted on a frame depend only on the frames from `memory` before it, and the first `memory` frames of a clip count no change (the warm-up).
// A swing that takes longer than the memory is not a change; a fade shorter than it is one change.
'use strict';
const zlib = require('zlib');

const DEFAULTS = {
  fps: 60,
  memory: null,          // frames a pixel remembers (null: one second, `fps`): the warm-up before any change is counted
  lumDelta: 0.10,        // general flash: the change, of a maximum of 1.0
  darkBelow: 0.80,       // general flash: the darker state must be below this relative luminance
  redShare: 0.80,        // red flash: R/(R+G+B) at or above this is a saturated red
  redSpace: 'either',    // 'stored', 'linear' or 'either': which values the saturated-red share is taken on
  redUv: 0.20,           // red flash: the two states must differ by more than this in CIE 1976 u'v'
  windowW: 341 / 1024,   // the area window, as a fraction of the frame's width ...
  windowH: 256 / 768,    // ... and of its height (341 x 256 at 1024 x 768)
  areaShare: 0.25,       // the share of the window's pixels that must change together
  levels: [0.85, 1, 1.15],   // the area threshold times each of these is tried too, to say how much of a count is the threshold's edge (the middle one is the reading)
  poolMin: 0.002,        // a frame joins a same-direction run when at least this share of the frame turned that way on it
  maxFlashes: 3,         // the standard's limit: more than this in any second fails the standard
  gate: 2.5,             // OUR gate (Legal, RL-119): the check is a proxy with unmeasured error, so the worst second must be this or below
  dipArea: 0.40,         // a dip: a down change over this share of the whole frame ...
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

/** WCAG relative luminance of an 8-bit sRGB pixel (gamma-decoded), 0..1. */
function relLum(r, g, b) { return 0.2126 * LIN[r] + 0.7152 * LIN[g] + 0.0722 * LIN[b]; }

const WHITE_UV = [0.19784, 0.46834];   // D65: the chromaticity given to a pixel with no light at all

/** CIE 1976 u', v' of an 8-bit sRGB pixel. */
function uv(r, g, b) {
  const R = LIN[r], G = LIN[g], B = LIN[b];
  const X = 0.4124 * R + 0.3576 * G + 0.1805 * B, Y = 0.2126 * R + 0.7152 * G + 0.0722 * B, Z = 0.0193 * R + 0.1192 * G + 0.9505 * B;
  const d = X + 15 * Y + 3 * Z;
  return d < 1e-12 ? WHITE_UV : [4 * X / d, 9 * Y / d];
}

/** Whether a pixel is a saturated red: R/(R+G+B) >= share, on the stored values, the linear ones, or either. */
function isSatRed(r, g, b, share, space) {
  if (space !== 'linear') { const s = r + g + b; if (s > 0 && r / s >= share) return true; if (space === 'stored') return false; }
  const R = LIN[r], G = LIN[g], B = LIN[b], s = R + G + B;
  return s > 0 && R / s >= share;
}

/**
 * Per-pixel change detector with a bounded memory. push(values) takes one value per pixel and returns { up, down }: how many pixels began a change on this frame, and fills
 * this.upMask / this.downMask (1 for those pixels). A pixel is "up" on a frame when it stands `delta` or more above its lowest value of the last `H` frames (and that lowest
 * value is below `dark`), "down" when it stands `delta` or more below its highest value of those frames (and is itself below `dark`); a change begins on the frame the state turns on.
 * Nothing older than H frames matters, so the changes of a frame depend only on the H + 1 frames up to it; the first H frames report none (the warm-up).
 */
class WindowDetector {
  constructor(n, delta, dark, H) {
    this.n = n; this.delta = delta; this.dark = dark; this.H = H; this.k = 0;
    this.buf = new Float32Array(n * H).fill(NaN);
    this.min = new Float32Array(n); this.max = new Float32Array(n);
    this.minAge = new Int32Array(n); this.maxAge = new Int32Array(n);
    this.upOn = new Uint8Array(n); this.downOn = new Uint8Array(n);
    this.upMask = new Uint8Array(n); this.downMask = new Uint8Array(n);
  }
  push(v) {
    const { n, delta, dark, H, buf, min, max, minAge, maxAge, upOn, downOn, upMask, downMask } = this;
    const slot = this.k % H, base = slot * n;
    const first = this.k === 0, report = this.k >= H;
    upMask.fill(0); downMask.fill(0);
    let up = 0, down = 0;
    for (let i = 0; i < n; i++) {
      const x = v[i];
      buf[base + i] = x;
      if (first) { min[i] = x; max[i] = x; minAge[i] = 0; maxAge[i] = 0; }
      else {
        if (x <= min[i]) { min[i] = x; minAge[i] = 0; }
        else if (++minAge[i] >= H) { let m = x, a = 0; for (let s = 0; s < H; s++) { const b = buf[s * n + i]; if (b < m) { m = b; a = (slot - s + H) % H; } } min[i] = m; minAge[i] = a; }
        if (x >= max[i]) { max[i] = x; maxAge[i] = 0; }
        else if (++maxAge[i] >= H) { let m = x, a = 0; for (let s = 0; s < H; s++) { const b = buf[s * n + i]; if (b > m) { m = b; a = (slot - s + H) % H; } } max[i] = m; maxAge[i] = a; }
      }
      const u = x - min[i] >= delta && min[i] < dark ? 1 : 0;
      const d = max[i] - x >= delta && x < dark ? 1 : 0;
      if (report) {
        if (u && !upOn[i]) { up++; upMask[i] = 1; }
        if (d && !downOn[i]) { down++; downMask[i] = 1; }
      }
      upOn[i] = u; downOn[i] = d;
    }
    this.k++;
    return { up, down };
  }
}

/**
 * The red counterpart: a pixel goes "into red" on the frame it is a saturated red and the last frame of the last H that was not one differs from it by more than `uvDelta` in
 * CIE 1976 u'v', and "out of red" on the frame it is not and the last saturated red of those frames differs that much; a transition begins on the frame the state turns on. The same
 * bounded memory, the same warm-up, the same interface as WindowDetector (the masks are the pixels that went into red and out of it on this frame).
 */
class WindowRedDetector {
  constructor(n, o, H) {
    this.n = n; this.o = o; this.H = H; this.k = 0;
    this.satAge = new Int32Array(n).fill(1 << 20); this.satRgb = new Int32Array(n);
    this.nonAge = new Int32Array(n).fill(1 << 20); this.nonRgb = new Int32Array(n);
    this.upOn = new Uint8Array(n); this.downOn = new Uint8Array(n);
    this.upMask = new Uint8Array(n); this.downMask = new Uint8Array(n);
  }
  push(d) {
    const { n, o, H, satAge, satRgb, nonAge, nonRgb, upOn, downOn, upMask, downMask } = this;
    const report = this.k >= H;
    upMask.fill(0); downMask.fill(0);
    let up = 0, down = 0;
    for (let i = 0, p = 0; i < n; i++, p += 4) {
      const r = d[p], g = d[p + 1], b = d[p + 2];
      const sat = isSatRed(r, g, b, o.redShare, o.redSpace);
      satAge[i]++; nonAge[i]++;
      let u = 0, dn = 0;
      if (sat) {
        if (nonAge[i] < H) { const q = nonRgb[i]; const a = uv(r, g, b), e = uv(q >> 16, (q >> 8) & 255, q & 255); if (Math.hypot(a[0] - e[0], a[1] - e[1]) > o.redUv) u = 1; }
        satAge[i] = 0; satRgb[i] = (r << 16) | (g << 8) | b;
      } else {
        if (satAge[i] < H) { const q = satRgb[i]; const a = uv(r, g, b), e = uv(q >> 16, (q >> 8) & 255, q & 255); if (Math.hypot(a[0] - e[0], a[1] - e[1]) > o.redUv) dn = 1; }
        nonAge[i] = 0; nonRgb[i] = (r << 16) | (g << 8) | b;
      }
      if (report) {
        if (u && !upOn[i]) { up++; upMask[i] = 1; }
        if (dn && !downOn[i]) { down++; downMask[i] = 1; }
      }
      upOn[i] = u; downOn[i] = dn;
    }
    this.k++;
    return { up, down };
  }
}

/** The most pixels of a 0/1 mask inside any ww x wh window of a w x h frame (an integral image: one pass to build, one to slide). */
function maxWindow(mask, w, h, ww, wh, sat) {
  const W1 = w + 1;
  for (let y = 0; y < h; y++) {
    let row = 0;
    for (let x = 0; x < w; x++) { row += mask[y * w + x]; sat[(y + 1) * W1 + x + 1] = sat[y * W1 + x + 1] + row; }
  }
  let best = 0;
  for (let y = wh; y <= h; y++) for (let x = ww; x <= w; x++) {
    const s = sat[y * W1 + x] - sat[(y - wh) * W1 + x] - sat[y * W1 + x - ww] + sat[(y - wh) * W1 + x - ww];
    if (s > best) best = s;
  }
  return best;
}

/**
 * Counts the flashes in a list of signed events [{ f: frame, s: +1 | -1 }] (only those over the area test): same-sign neighbours merge into one change, then the most
 * opposing changes in any window of `fps` frames is halved.
 */
function worstWindow(events, fps) {
  const ch = [];
  for (const e of events) { if (ch.length && ch[ch.length - 1].s === e.s) continue; ch.push({ f: e.f, s: e.s, ev: e }); }
  let worst = 0, at = -1, from = 0, to = -1;
  for (let i = 0, j = 0; i < ch.length; i++) {
    if (j < i) j = i;
    while (j + 1 < ch.length && ch[j + 1].f < ch[i].f + fps) j++;
    const n = j - i + 1;
    if (n / 2 > worst) { worst = n / 2; at = ch[i].f; from = i; to = j; }
  }
  return { flashes: worst, atFrame: at, changes: ch.length, inWorst: at < 0 ? [] : ch.slice(from, to + 1).map((c) => c.ev) };
}

/**
 * Pools one detector's masks: a direction's pixels are pooled over consecutive frames that turned that way (a fade is one change; a run ends when the other direction dominates
 * a frame, so a fast alternation is many changes), and a pooled change counts, for each level of the area threshold, from the first frame some window holds that many pixels.
 * Returns the events of every level (events[li]) and, for each, the largest window its run reached.
 */
class Pool {
  constructor(n, w, h, ww, wh, thr, poolMin, levels) {
    this.n = n; this.w = w; this.h = h; this.ww = ww; this.wh = wh; this.thr = thr; this.poolMin = poolMin; this.levels = levels;
    this.acc = { up: new Uint8Array(n), down: new Uint8Array(n) };
    this.run = { up: null, down: null };
    this.sat = new Int32Array((w + 1) * (h + 1));
    this.events = levels.map(() => []); this.best = 0; this.bestAt = -1; this.bestDirPx = 0; this.series = new Map();
  }
  push(k, det, counts) {
    const dom = counts.up >= counts.down ? 'up' : 'down';
    for (const dir of ['up', 'down']) {
      const cnt = dir === dom ? counts[dir] : 0, mask = dir === 'up' ? det.upMask : det.downMask, acc = this.acc[dir];
      if (cnt >= this.poolMin * this.n) {
        if (!this.run[dir]) { acc.fill(0); this.run[dir] = { size: 0, max: 0, fired: this.levels.map(() => null) }; }
        const run = this.run[dir];
        for (let i = 0; i < this.n; i++) if (mask[i]) { if (!acc[i]) run.size++; acc[i] = 1; }
        if (run.size > this.bestDirPx) this.bestDirPx = run.size;
        if (run.size >= Math.ceil(this.levels[0] * this.thr / 8)) {
          const wmax = maxWindow(acc, this.w, this.h, this.ww, this.wh, this.sat);
          if (wmax > run.max) run.max = wmax;
          if (wmax > this.best) { this.best = wmax; this.bestAt = k; }
          this.series.set(k, Math.max(this.series.get(k) || 0, wmax));
          this.levels.forEach((lv, li) => {
            if (run.fired[li] === null && wmax >= lv * this.thr) { const ev = { f: k, s: dir === 'up' ? 1 : -1, size: run.size, window: wmax, run }; run.fired[li] = ev; this.events[li].push(ev); }
          });
        }
      } else this.run[dir] = null;
    }
  }
}

/**
 * Analyses frames: an array of { w, h, data } (RGBA) or a function (i) => frame with opts.count. Returns { frames, general, red, dips, pass, ... }. `pass` means the worst second
 * is within our gate, `passStandard` within the standard's 3; neither is a clearance. general.levels says what the worst second reads when the area threshold is 15% lower and
 * 15% higher, and general.marginal how many of the changes in the worst second are within 15% above the threshold (the margin the gate is meant to cover).
 */
function analyse(frames, opts = {}) {
  const o = Object.assign({}, DEFAULTS, opts);
  const get = typeof frames === 'function' ? frames : (i) => frames[i];
  const count = typeof frames === 'function' ? o.count : frames.length;
  const H = Math.max(2, Math.round(o.memory || o.fps));
  if (!count || count <= H + 1) throw new Error(`need more than ${H + 1} frames (the first ${H} are the warm-up and count no change)`);
  const f0 = get(0);
  const n = f0.w * f0.h;
  const ww = Math.max(1, Math.round(f0.w * o.windowW)), wh = Math.max(1, Math.round(f0.h * o.windowH));
  const thr = Math.ceil(o.areaShare * ww * wh);
  const dg = new WindowDetector(n, o.lumDelta, o.darkBelow, H);
  const dr = new WindowRedDetector(n, o, H);
  const pg = new Pool(n, f0.w, f0.h, ww, wh, thr, o.poolMin, o.levels), pr = new Pool(n, f0.w, f0.h, ww, wh, thr, o.poolMin, o.levels);
  const lum = new Float32Array(n);
  const means = new Float64Array(count);
  for (let k = 0; k < count; k++) {
    const fr = get(k);
    if (fr.w !== f0.w || fr.h !== f0.h) throw new Error(`frame ${k} is ${fr.w}x${fr.h}, the first is ${f0.w}x${f0.h}`);
    const d = fr.data;
    let sum = 0;
    for (let i = 0, p = 0; i < n; i++, p += 4) { const l = relLum(d[p], d[p + 1], d[p + 2]); lum[i] = l; sum += l; }
    means[k] = sum / n;
    pg.push(k, dg, dg.push(lum));
    pr.push(k, dr, dr.push(d));
  }
  const mid = o.levels.indexOf(1) >= 0 ? o.levels.indexOf(1) : Math.floor(o.levels.length / 2);
  const per = (pool) => pool.events.map((evs) => worstWindow(evs, o.fps));
  const gl = per(pg), rl = per(pr);
  const g = gl[mid], r = rl[mid];
  const evView = (e) => ({ tick: e.f + 1, sign: e.s, windowPx: e.window, runMaxPx: e.run.max, runMaxOfThreshold: e.run.max / thr, marginal: e.run.max < o.levels[o.levels.length - 1] * thr, pooledPx: e.size });
  // dips: a general down change over `dipArea` of the whole frame; depth = the frame's mean luminance before it and its lowest within 8 frames after
  const dips = pg.events[mid].filter((e) => e.s === -1 && e.size >= o.dipArea * n).map((e) => {
    let min = means[e.f];
    for (let j = e.f; j < Math.min(count, e.f + 8); j++) min = Math.min(min, means[j]);
    const before = means[Math.max(0, e.f - 1)];
    return { frame: e.f, tick: e.f + 1, areaOfFrame: e.size / n, meanBefore: before, meanMin: min, drop: before - min };
  });
  const gaps = dips.slice(1).map((d, i) => d.frame - dips[i].frame);
  const section = (pool, lv, w) => ({
    events: pool.events[mid].map(evView), flashes: w.flashes, atFrame: w.atFrame, atTick: w.atFrame + 1, qualifyingChanges: w.changes,
    levels: Object.fromEntries(o.levels.map((x, li) => [String(x), lv[li].flashes])), flashesIfThresholdLower: lv[0].flashes, flashesIfThresholdHigher: lv[lv.length - 1].flashes,
    worstSecond: w.inWorst.map(evView), marginal: w.inWorst.filter((e) => e.run.max < o.levels[o.levels.length - 1] * thr).length,
    largestWindowPx: pool.best, largestWindowOfThreshold: pool.best / thr, largestChangePx: pool.bestDirPx, largestChangeOfFrame: pool.bestDirPx / n, largestAtFrame: pool.bestAt,
    windowByTick: Object.fromEntries([...pool.series].map(([f, v]) => [f + 1, v])),
  });
  const gs = section(pg, gl, g), rs = section(pr, rl, r);
  return {
    frames: count, width: f0.w, height: f0.h, fps: o.fps, memoryFrames: H, warmupFrames: H, windowPx: [ww, wh], thresholdPx: thr, thresholdOfWindow: o.areaShare,
    general: gs, red: rs,
    dips: { list: dips, shortestGapFrames: gaps.length ? Math.min(...gaps) : null },
    pass: g.flashes <= o.gate && r.flashes <= o.gate,
    passStandard: g.flashes <= o.maxFlashes && r.flashes <= o.maxFlashes,
    params: o,
  };
}

module.exports = { DEFAULTS, decodePng, encodePng, relLum, uv, isSatRed, WindowDetector, WindowRedDetector, maxWindow, worstWindow, analyse };
