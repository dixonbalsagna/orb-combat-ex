// The homework GIFs for the right-stick prototype, made in node with no browser: the page's sim and drawing
// (docs/ep/prototypes/right-stick-v1.html, between its "STICK SIM" and "PAGE" markers) run here against a small scanline
// rasteriser with the bitmap font. Each clip plays once, takes in order, and every other tick becomes a GIF frame (30 a
// second) under a caption bar with the clip's number, name and current step. One still per step, and a sheet per clip.
// The rasteriser and the GIF encoder are copied from research/energy-proto/gif.mjs, with text added for the stick panel.
//   node research/right-stick-proto/gif.mjs [out dir, default homework/49-right-stick] [only: e.g. R1,R4]
//   node research/right-stick-proto/gif.mjs --check     (plays every clip, prints what the recognizer said, writes nothing)
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { join } from 'node:path';
import { Img } from '../planet-gen/lib/img.mjs';

const HTML = 'docs/ep/prototypes/right-stick-v1.html';
const src = readFileSync(HTML, 'utf8');
const a = src.indexOf('// ==== STICK SIM (no DOM) ===='), b = src.indexOf('// ==== PAGE (DOM) ====');
if (a < 0 || b < 0) throw new Error('markers not found in ' + HTML);
const S = new Function(src.slice(a, b) + '\nreturn S;')();

const W = S.W, H = S.H, BAR = 92, FW = W, FH = H + BAR;
const hex = (s) => [parseInt(s.slice(1, 3), 16), parseInt(s.slice(3, 5), 16), parseInt(s.slice(5, 7), 16)];

// ---- a scanline polygon fill (even-odd, pixel centres) into an Img, below the caption bar; text in the bitmap font ----
function makeR(img, oy) {
  const cache = new Map(), rgb = (c) => { let v = cache.get(c); if (!v) { v = hex(c); cache.set(c, v); } return v; };
  return {
    clear(c) { img.fill(0, oy, W, H, rgb(c)); },
    text(x, y, str, size, c) { img.text(Math.round(x), Math.round(y) + oy, str, Math.max(1, Math.round(size / 7)), rgb(c)); },
    poly(p, c) {
      const n = p.length / 2; if (n < 3) return;
      let y0 = Infinity, y1 = -Infinity;
      for (let i = 1; i < p.length; i += 2) { if (p[i] < y0) y0 = p[i]; if (p[i] > y1) y1 = p[i]; }
      if (!(y1 >= y0)) return;
      const col = rgb(c), ya = Math.max(0, Math.ceil(y0 - 0.5)), yb = Math.min(H - 1, Math.floor(y1 - 0.5)), xs = [];
      for (let y = ya; y <= yb; y++) {
        const syy = y + 0.5; xs.length = 0;
        for (let i = 0, j = n - 1; i < n; j = i++) {
          const xi = p[2 * i], yi = p[2 * i + 1], xj = p[2 * j], yj = p[2 * j + 1];
          if ((yi > syy) !== (yj > syy)) xs.push(xi + (syy - yi) / (yj - yi) * (xj - xi));
        }
        xs.sort((u, v) => u - v);
        for (let k = 0; k + 1 < xs.length; k += 2) {
          const xa = Math.max(0, Math.ceil(xs[k] - 0.5)), xb = Math.min(W - 1, Math.floor(xs[k + 1] - 0.5));
          for (let x = xa; x <= xb; x++) { const o = ((y + oy) * FW + x) * 3; img.d[o] = col[0]; img.d[o + 1] = col[1]; img.d[o + 2] = col[2]; }
        }
      }
    },
  };
}

// ---- the caption bar ----
const BARC = [31, 31, 28], INK = [240, 239, 233], DIM = [176, 174, 165];
function wrap(s, n) { const out = []; let line = ''; for (const wd of s.split(' ')) { if ((line + ' ' + wd).trim().length > n) { out.push(line.trim()); line = wd; } else line += ' ' + wd; } if (line.trim()) out.push(line.trim()); return out; }
function caption(img, title, k, text) {
  img.fill(0, 0, FW, BAR, BARC);
  img.text(10, 7, title, 2, INK);
  wrap(`${k + 1}. ${text}`, 80).slice(0, 3).forEach((l, i) => img.text(10, 30 + i * 19, l, 2, DIM));
}

// ---- a GIF encoder: one global palette, each frame as the rectangle that changed, LZW ----
function lzw(indices, minCode) {
  const clear = 1 << minCode, eoi = clear + 1, out = [];
  let size = minCode + 1, next = eoi + 1, dict = new Map(), cur = 0, nbits = 0;
  const emit = (code) => { cur |= code << nbits; nbits += size; while (nbits >= 8) { out.push(cur & 255); cur >>>= 8; nbits -= 8; } };
  emit(clear);
  let w = indices[0];
  for (let i = 1; i < indices.length; i++) {
    const k = indices[i], key = w * 4096 + k, v = dict.get(key);
    if (v !== undefined) { w = v; continue; }
    emit(w);
    if (next < 4096) { dict.set(key, next++); if (next > (1 << size) && size < 12) size++; }
    else { emit(clear); dict = new Map(); size = minCode + 1; next = eoi + 1; }
    w = k;
  }
  emit(w); emit(eoi);
  if (nbits > 0) out.push(cur & 255);
  return out;
}
function encodeGif(frames, delays) {
  const pal = new Map(), plist = [];
  const idxFrames = frames.map((f) => {
    const ix = new Uint8Array(FW * FH);
    for (let i = 0; i < FW * FH; i++) {
      const key = (f.d[i * 3] << 16) | (f.d[i * 3 + 1] << 8) | f.d[i * 3 + 2];
      let v = pal.get(key); if (v === undefined) { v = plist.length; if (v > 255) throw new Error('more than 256 colours'); pal.set(key, v); plist.push(key); }
      ix[i] = v;
    }
    return ix;
  });
  const bytes = [], push = (...a) => { for (const v of a) bytes.push(v); }, u16 = (v) => push(v & 255, v >> 8);
  push(...Buffer.from('GIF89a')); u16(FW); u16(FH); push(0xf7, 0, 0);
  for (let i = 0; i < 256; i++) { const c = plist[i] || 0; push(c >> 16, (c >> 8) & 255, c & 255); }
  push(0x21, 0xff, 11, ...Buffer.from('NETSCAPE2.0'), 3, 1, 0, 0, 0);
  let prev = null;
  idxFrames.forEach((ix, n) => {
    let x0 = 0, y0 = 0, x1 = FW - 1, y1 = FH - 1;
    if (prev) {
      x0 = FW; y0 = FH; x1 = -1; y1 = -1;
      for (let y = 0; y < FH; y++) for (let x = 0; x < FW; x++) { const i = y * FW + x; if (ix[i] !== prev[i]) { if (x < x0) x0 = x; if (x > x1) x1 = x; if (y < y0) y0 = y; if (y > y1) y1 = y; } }
      if (x1 < 0) { x0 = y0 = 0; x1 = y1 = 0; }
    }
    push(0x21, 0xf9, 4, 0x04); u16(delays[n]); push(0, 0);
    push(0x2c); u16(x0); u16(y0); u16(x1 - x0 + 1); u16(y1 - y0 + 1); push(0);
    const sub = new Uint8Array((x1 - x0 + 1) * (y1 - y0 + 1));
    for (let y = y0, o = 0; y <= y1; y++) for (let x = x0; x <= x1; x++) sub[o++] = ix[y * FW + x];
    const data = lzw(sub, 8);
    push(8);
    for (let i = 0; i < data.length; i += 255) { const c = data.slice(i, i + 255); push(c.length, ...c); }
    push(0);
    prev = ix;
  });
  push(0x3b);
  return Buffer.from(bytes);
}

// ---- the clips, with one line each for Orb ----
const STEM = { R1: 'R1-lunge-and-steps', R2: 'R2-dash-orbit-cross-up', R3: 'R3-wall-run-and-skim', R4: 'R4-aim-latch', R5: 'R5-beam-sweep', R6: 'R6-patterns-later' };
const CAP = {
  R1: 'Flight, with nothing held: a flick toward him from range is the lunge (10 ki); in reach it is a step in; a flick away steps back and slips a shot; flicks up and down hop and drop.',
  R2: 'Holds continue their flicks: a hold away or toward is the dash; in reach, a hold up or down is the orbit, and held through it is the cross-up onto his other side.',
  R3: 'A hold into the cliff face runs him up it; near the ground or the water, a hold down skims along the surface while the left stick steers.',
  R4: 'With RB held the stick aims: flicks latch the line 45 degrees above or below him, or behind; a toward flick clears it; X, Y and B fire along it; a hold sweeps it.',
  R5: 'While his beam is out, a hold sweeps it after the rival at his own rate and it stays where the stick lets go; the left stick sweeps it too, so the thumb can pulse.',
  R6: 'Patterns are step 2: a zig-zag or a circle drawn now is just its flicks and holds, and the panel only names what it will become.',
};

function play(ci, onTick) {
  const run = S.newRun(ci, 'demo'), clip = S.CLIPS[ci], len = S.clipLen(clip), said = [];
  let last = null;
  for (let t = 0; t < len; t++) {
    S.stepRun(run);
    const top = run.w.rd.log[0];
    if (top && top !== last) { said.push(`${run.t} ${top.text}`); last = top; }
    if (onTick) onTick(run);
  }
  return { run, said };
}

const args = process.argv.slice(2);
if (args.includes('--check')) {
  S.CLIPS.forEach((c, ci) => { const { run, said } = play(ci); const P = run.w.P; console.log(`${c.n} ${c.name}:\n   ${said.join(' | ')}\n   end: P ${P.x.toFixed(0)},${P.y.toFixed(0)} ki ${P.ki.toFixed(0)}  V ${run.w.V.x.toFixed(0)},${run.w.V.y.toFixed(0)}`); });
  process.exit(0);
}
// --frames R1 30,60,90 out.png: those global ticks of one clip as a sheet, at half size, for a close look
const fa = args.indexOf('--frames');
if (fa >= 0) {
  const ci = S.CLIPS.findIndex((c) => c.n === args[fa + 1]), want = args[fa + 2].split(',').map(Number), got = [];
  play(ci, (run) => { if (want.includes(run.t)) { const img = new Img(FW, FH, null); S.draw(run, makeR(img, BAR)); img.text(10, 7, 'T ' + run.t, 2, INK); got.push(img.shrink(2)); } });
  const cw = got[0].w, ch = got[0].h, sheet = new Img(cw * 2 + 6, Math.ceil(got.length / 2) * (ch + 6), [24, 26, 34]);
  got.forEach((im, k) => sheet.blit(im, (k % 2) * (cw + 6), Math.floor(k / 2) * (ch + 6)));
  sheet.save(args[fa + 3]); console.log('saved', args[fa + 3]); process.exit(0);
}
const OUT = args[0] && !args[0].startsWith('-') ? args[0] : 'homework/49-right-stick';
const only = args[1] ? args[1].split(',') : null;
mkdirSync(join(OUT, 'stills'), { recursive: true });
S.CLIPS.forEach((clip, ci) => {
  if (only && !only.includes(clip.n)) return;
  const stem = STEM[clip.n], title = `${clip.n}. ${clip.name}`, len = S.clipLen(clip);
  const mids = clip.steps.map((s, k) => s[2] != null ? s[2] : Math.round((s[0] + (k + 1 < clip.steps.length ? clip.steps[k + 1][0] : len)) / 2));
  const frames = [], delays = [], stills = [];
  let i = 0;
  play(ci, (run) => {
    const t = run.t, still = mids.indexOf(t);
    if (t % 2 && still < 0) return;
    const img = new Img(FW, FH, null), R = makeR(img, BAR);
    S.draw(run, R);
    const k = S.stepOf(clip, t);
    caption(img, title, k, clip.steps[k][1]);
    if (still >= 0) { img.save(join(OUT, 'stills', `${stem}-${still + 1}.png`)); stills[still] = img; }
    if (t % 2) return;
    frames.push(img); delays.push([3, 3, 4][i++ % 3]);
  });
  const gif = encodeGif(frames, delays);
  writeFileSync(join(OUT, stem + '.gif'), gif);
  const half = stills.map((im) => im.shrink(2)), cw = half[0].w, ch = half[0].h, rows = Math.ceil(half.length / 2);
  const sheet = new Img(cw * 2 + 6, rows * (ch + 6), [24, 26, 34]);
  half.forEach((im, k) => sheet.blit(im, (k % 2) * (cw + 6), Math.floor(k / 2) * (ch + 6)));
  sheet.save(join(OUT, 'stills', `${stem}-sheet.png`));
  console.log(`${stem}.gif: ${frames.length} frames, ${(gif.length / 1024).toFixed(0)} KB`);
});
if (!only) {
  const L = ['# 49. The right stick, step 1 (6 min to watch, one question)', '',
    "Game Design's recommended pitch for the right stick is C, the family stick: whatever shoulder you already hold picks what the stick does, and a quick flick and a steady hold do different things. These clips are its step 1, as Game Design fixed it (`docs/design/right-stick-pitches.md` section 11) and as Controls reads it (`docs/controls/right-stick.md` section 11).",
    '', '- **Nothing held: Flight.** Flicks are the lunge, the steps, the hop and the drop. Holds are the dash, the orbit and its cross-up, the wall run and the skim.',
    '- **RB held: the aim.** Flicks latch an aim line above, below or behind him, or clear it; X, Y and B fire along it; a hold sweeps it, or sweeps a beam that is out.',
    '- **Patterns** (zig-zags, circles) come in step 2. Here the panel only names them.',
    '', 'The panel on the right of each clip is the stick itself: its trace, the dead zone (the grey middle), the dashed ring a flick must cross, the shoulder family it locked, and what the game read, newest first. Bodies are flat stand-ins.',
    '', '**Try it yourself:** open `docs/ep/prototypes/right-stick-v1.html` in your browser and pick Play. A gamepad works as it is (right stick, RB, LB, X, Y, B). On the keyboard: the arrow keys are the right stick (tap to flick, hold to hold), W A S D the left stick, E holds RB, Q holds LB, J K L are X Y B.', '',
    '**The clips** (`stills/` has one picture per step):', ''];
  S.CLIPS.forEach((c) => L.push(`- ${c.n}. \`${STEM[c.n]}.gif\`: ${CAP[c.n]}`));
  L.push('', '**The steps in each clip:**', '');
  S.CLIPS.forEach((c) => { L.push(`- **${c.n}. ${c.name}**`); c.steps.forEach((s, k) => L.push(`  ${k + 1}. ${s[1]}`)); });
  L.push('', '**One question:** is this the right first step for the right stick?', '- (a) Yes, build step 1 as it is.', '- (b) Yes, with changes (say which clip and step).', '- (c) Not this pitch: tell us what you want the stick to do instead.', '', 'Your notes:', '');
  writeFileSync(join(OUT, 'README.md'), L.join('\n'));
  console.log('README.md written');
}
