// The homework GIFs for the rally prototype, made in node with no browser: the page's sim and drawing
// (docs/ep/prototypes/rally-v1.html, between its "RALLY SIM" and "PAGE" markers) run here against a small scanline
// rasteriser with the bitmap font. Each clip plays once, takes in order, and every other tick becomes a GIF frame (30 a
// second) under a caption bar with the clip's number, name and current step. One still per step, and a sheet per clip.
// The rasteriser, the GIF encoder and the README merge are copied from research/right-stick-proto/gif.mjs.
//   node research/rally-proto/gif.mjs [out dir] [only: e.g. D1,D4]
//   node research/rally-proto/gif.mjs --check     (plays every clip, prints the director's feed, writes nothing)
//   node research/rally-proto/gif.mjs --frames D4 30,60 out.png
import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { Img } from '../planet-gen/lib/img.mjs';

const HTML = 'docs/ep/prototypes/rally-v1.html';
const src = readFileSync(HTML, 'utf8');
const a = src.indexOf('// ==== RALLY SIM (no DOM) ===='), b = src.indexOf('// ==== PAGE (DOM) ====');
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
  wrap(`${k + 1}. ${text}`, 64).slice(0, 3).forEach((l, i) => img.text(10, 30 + i * 19, l, 2, DIM));
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

// The README's generated part sits between these markers. Anything outside them (the EP's text and questions) is kept as it
// is; a README without them gets the part inserted before its first question, and a missing README is written whole.
const BEGIN = '<!-- research: clips begin (written by research/rally-proto/gif.mjs; edit outside the markers) -->', END = '<!-- research: clips end -->';
function mergeReadme(path, title, block, question) {
  const part = [BEGIN, ...block, END].join('\n');
  if (!existsSync(path)) { writeFileSync(path, [title, '', part, '', ...question].join('\n')); return 'written'; }
  let s = readFileSync(path, 'utf8'); const a = s.indexOf(BEGIN.slice(0, 30)), b = s.indexOf(END);
  if (a >= 0 && b > a) s = s.slice(0, a) + part + s.slice(b + END.length);
  else { const q = s.search(/^\*\*(One|Two|Three) questions?/m); s = q >= 0 ? s.slice(0, q) + part + '\n\n' + s.slice(q) : s.trimEnd() + '\n\n' + part + '\n'; }
  writeFileSync(path, s); return 'merged';
}

const STEM = { D1: 'D1-the-daze', D2: 'D2-the-sell', D3: 'D3-the-send', D4: 'D4-a-rally-of-links', D5: 'D5-the-turn-and-repetition' };
const CAP = {
  D1: "The daze is earned: a fully charged heavy breaks his guard and he is dazed for 40 ticks, swaying with his guard down; his own presses shorten it. A flurry only staggers.",
  D2: "The sell: in the daze each landed blow takes the launch's hit-stop, a camera push and a reaction a size larger; the damage stays each blow's own.",
  D3: "B ends the sell with the send at full power and the decisive hit-stop: the kick, the glide, and the rally is open.",
  D4: "A rally of five different links over the city and out to sea: the chase strike, the bank off a building, the spike that glances off hard ground, the overtake head-on, a lob where he lands.",
  D5: "The turn: he techs a fresh-kind link, counter-rushes and takes the rally over. Then repetition: the same link again widens his window, and a third of one kind techs itself.",
};

function play(ci, onTick) {
  const run = S.newRun(ci, 'demo'), clip = S.CLIPS[ci], len = S.clipLen(clip), said = [];
  let last = null;
  for (let t = 0; t < len; t++) {
    S.stepRun(run);
    const top = run.w.feed[0];
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
const OUT = args[0] && !args[0].startsWith('-') ? args[0] : 'homework/combat-and-controls/SOON - rally (stun, sell, bounce)';
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
  const L = ["**The prototype: Game Design's rulings 23d** (`docs/design/rulings-2026-10-23d.md`), the balance you asked for: \"moments where a fighter gets stunned, then sells some big powerful hits from the attacker, who then continues to bounce him around with elaborate flight attacks.\"",
    '', "- **The daze** is earned (a broken guard, a perfect block's reversal, a wall slam, a clean full heavy, a punished whiff, a lost struggle), lasts 40 ticks, and his own presses shorten it. A flurry only staggers, so mashing never dazes.",
    "- **The sell:** in the daze, each landed blow takes the launch's hit-stop, a camera push and a reaction a size larger. B ends it with the send.",
    "- **The rally:** every press of the attacker's while the body flies is a link: the chase strike, the overtake, the bank, the spike, a lob, or the world itself (a skip across the sea, a glance off a face). Nothing caps it.",
    "- **Repetition is the guard:** a fresh kind of link gives the one being bounced a 4-tick tech, the same kind again 8 ticks, and a third of one kind techs itself. A teched link gives him the counter-rush, and if it lands on the chaser in the air, the rally is his.",
    '', "Flight distances are drawn at half the game's, so both fighters stay in the frame. Bodies are flat stand-ins. The words at the top right are the director's feed, at the screen's edge, never over the fighters.",
    '', "**Try it yourself:** open `docs/ep/prototypes/rally-v1.html` in your browser and pick Play. Keyboard: W A S D fly (and nudge a send, or hold back for the overtake), J K L are X Y B (hold L to charge a heavy), Space guards (and techs a link as it arrives), Shift is LT (with J or K in a rally, the chase; a tap at a wall, the bank), E is RB (with K, a lob where he lands), Q is RT (the burst). A gamepad works as it is.", '',
    '**The clips** (`stills/` has one picture per step):', ''];
  S.CLIPS.forEach((c) => L.push(`- ${c.n}. \`${STEM[c.n]}.gif\`: ${CAP[c.n]}`));
  L.push('', '**The steps in each clip:**', '');
  S.CLIPS.forEach((c) => { L.push(`- **${c.n}. ${c.name}**`); c.steps.forEach((s, k) => L.push(`  ${k + 1}. ${s[1]}`)); });
  console.log('README.md ' + mergeReadme(join(OUT, 'README.md'), '# SOON - the rally: the stun, the sell and the bounce (6 min to watch)', L, ['**One question (optional; Game Design says none is needed):** is this the balance you meant? (a) yes; (b) yes, with changes (say which clip and step); (c) not quite: say what is off.', '', 'Your answer:', '']));
}
