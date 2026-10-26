// The homework GIFs for the energy prototype, made in node with no browser: the page's sim and drawing
// (docs/ep/prototypes/energy-v1.html, between its "ENERGY SIM" and "PAGE" markers) run here against a small scanline
// rasteriser. Each of section 13's clips (C1 to C10) plays once, takes in order, and every other tick becomes a GIF frame
// (30 a second) under a caption bar with the clip's number, name and current step. One still per step, mid-step.
//   node research/energy-proto/gif.mjs [out dir, default homework/48-energy] [only: comma-separated clip numbers, e.g. C1,C6]
//   node research/energy-proto/gif.mjs --check     (plays every clip to the end, prints what happened, writes nothing)
import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { Img } from '../planet-gen/lib/img.mjs';

const HTML = 'docs/ep/prototypes/energy-v1.html';
const src = readFileSync(HTML, 'utf8');
const a = src.indexOf('// ==== ENERGY SIM (no DOM) ===='), b = src.indexOf('// ==== PAGE (DOM) ====');
if (a < 0 || b < 0) throw new Error('markers not found in ' + HTML);
const E = new Function(src.slice(a, b) + '\nreturn E;')();

const W = E.W, H = E.H, BAR = 92, FW = W, FH = H + BAR;
const hex = (s) => [parseInt(s.slice(1, 3), 16), parseInt(s.slice(3, 5), 16), parseInt(s.slice(5, 7), 16)];

// ---- a scanline polygon fill (even-odd, pixel centres) into an Img, below the caption bar ----
function makeR(img, oy) {
  const cache = new Map(), rgb = (c) => { let v = cache.get(c); if (!v) { v = hex(c); cache.set(c, v); } return v; };
  return {
    clear(c) { img.fill(0, oy, W, H, rgb(c)); },
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
  wrap(`${k + 1}. ${text}`, 57).slice(0, 3).forEach((l, i) => img.text(10, 30 + i * 19, l, 2, DIM));
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

// ---- the ten clips and 7b, with one line each for Orb ----

// The README's generated part sits between these markers. Anything outside them (the EP's text and questions) is kept as it
// is; a README without them gets the part inserted before its first question, and a missing README is written whole.
const BEGIN = '<!-- research: clips begin (written by research/energy-proto/gif.mjs; edit outside the markers) -->', END = '<!-- research: clips end -->';
function mergeReadme(path, title, block, question) {
  const part = [BEGIN, ...block, END].join('\n');
  if (!existsSync(path)) { writeFileSync(path, [title, '', part, '', ...question].join('\n')); return 'written'; }
  let s = readFileSync(path, 'utf8'); const a = s.indexOf(BEGIN.slice(0, 30)), b = s.indexOf(END);
  if (a >= 0 && b > a) s = s.slice(0, a) + part + s.slice(b + END.length);
  else { const q = s.search(/^\*\*(One|Two|Three) questions?/m); s = q >= 0 ? s.slice(0, q) + part + '\n\n' + s.slice(q) : s.trimEnd() + '\n\n' + part + '\n'; }
  writeFileSync(path, s); return 'merged';
}

const STEM = { C1: 'C1-rapid-fire', C2: 'C2-the-lob', C3: 'C3-blast-or-beam', C4: 'C4-pulses', C5: 'C5-loaded', C6: 'C6-beam-struggle', C7: 'C7-two-grabs', C7b: 'C7b-four-grabs', C8: 'C8-mines-and-traps', C9: 'C9-close-and-far', C10: 'C10-one-beam-three-places' };
const CAP = {
  C1: "Rapid fire (X): one bolt a tap, one a press when mashed, a stream when held (a steady light at the palm); bolts cancel in pairs.",
  C2: "The lob (Y): the Rival's block on a low arc, a barrage when mashed, two charge steps (his level 2 cracks into three blocks), the stick leads the landing, a bolt can burst it in the air.",
  C3: "Blast or beam (B): tap for the heavy blast, hold for a beam in three steps; let go early and it is still the blast; a dodge drops the charge for nothing.",
  C4: "Pulses: each B press while the Demon Cyborg's beam is out is a hammer on his chest plate, sending a swell down it and making it last longer; holding B pulses on a steady beat; the rival can still dodge out.",
  C5: "Loaded: the Empress holds a level-3 beam at her hand's lit edge while she flies, and lets it go as the rival lunges; held too long, the charge steps down as her ki runs short, and it never fires by itself.",
  C6: "A struggle between two beams (a wall and a sheaf of lances), decided by presses on the beat: surges push, a stray press voids the next; the loser buckles, then is overwhelmed, or lets go with A on the beat.",
  C7: "Two energy grabs: the Protagonist's net, which the rival tears at, then the yank into his blow; the Rival's ring, which snaps shut, then the bind and a bolt.",
  C7b: "The four energy grabs side by side: net and yank, ring and bind, banners and slam, hook and throw.",
  C8: "Guard and energy: the Empress lays spark mines, a blast mine and her Velvet Rope with her guard up; one is dodged in its flare, one shot from range, the rope fires and swings shut, and a send sets off her own mine.",
  C9: "The mixed string, close and far: punches, a point-blank bolt and blast, bolts after him as he slides, a lob where he lands, a zip strike back in.",
  C10: "One level-3 beam in three places: it parts the sea, which rushes back; down a village lane the hero's beam narrows and the villain's (the Demon Cyborg's here) widens; in a forest the trees catch and lake water later fills the trench.",
};

function play(ci, onTick) {
  const run = E.newRun(ci, 'demo'), clip = E.CLIPS[ci], len = E.clipLen(clip), log = [], seen = new Set();
  for (let t = 0; t < len; t++) {
    E.stepRun(run);
    const w = run.w;
    for (const s of ['L', 'R']) {
      const f = w[s];
      const tag = f.caught ? 'caught' : f.send ? 'send-' + f.send.k : f.dodge ? 'dodge' : f.beam && !f.beam.end ? 'beam' + f.beam.lv : f.bchg ? 'gather' + f.bchg.lv : f.ychg ? 'lob' + f.ychg.lv : f.knock ? 'knock' : f.reel ? 'reel' : '';
      const key = run.take + s + tag;
      if (tag && !seen.has(key)) { seen.add(key); log.push(`${run.t} ${s} ${tag}`); }
    }
    if (w.struggle && !seen.has(run.take + 'struggle')) { seen.add(run.take + 'struggle'); log.push(`${run.t} struggle`); }
    for (const m of w.mines) { const key = 'm' + m.kind + m.x + m.st; if (!seen.has(key)) { seen.add(key); log.push(`${run.t} ${m.kind}@${Math.round(m.x)} ${m.st}`); } }
    if (onTick) onTick(run);
  }
  return { run, log };
}

const args = process.argv.slice(2);
if (args.includes('--check')) {
  E.CLIPS.forEach((c, ci) => { const { run, log } = play(ci); console.log(`${c.n} ${c.name}: ${log.join(', ')}\n   end: L ${run.w.L.x.toFixed(0)},${run.w.L.y.toFixed(0)} ki ${run.w.L.ki.toFixed(0)}  R ${run.w.R.x.toFixed(0)},${run.w.R.y.toFixed(0)} ki ${run.w.R.ki.toFixed(0)}`); });
  process.exit(0);
}
const OUT = args[0] && !args[0].startsWith('-') ? args[0] : 'homework/48-energy';
const only = args[1] ? args[1].split(',') : null;
mkdirSync(join(OUT, 'stills'), { recursive: true });
E.CLIPS.forEach((clip, ci) => {
  if (only && !only.includes(clip.n)) return;
  const stem = STEM[clip.n], title = `${clip.n}. ${clip.name}`, len = E.clipLen(clip);
  const mids = clip.steps.map((s, k) => s[2] != null ? s[2] : Math.round((s[0] + (k + 1 < clip.steps.length ? clip.steps[k + 1][0] : len)) / 2));
  const frames = [], delays = [], stills = [];
  let i = 0;
  play(ci, (run) => {
    const t = run.t;
    const still = mids.indexOf(t);
    if (t % 2 && still < 0) return;
    const img = new Img(FW, FH, null), R = makeR(img, BAR);
    E.draw(run, R);
    const k = E.stepOf(clip, t);
    caption(img, title, k, clip.steps[k][1]);
    if (still >= 0) { img.save(join(OUT, 'stills', `${stem}-${still + 1}.png`)); stills[still] = img; }
    if (t % 2) return;
    frames.push(img); delays.push([3, 3, 4][i++ % 3]);
  });
  const gif = encodeGif(frames, delays);
  writeFileSync(join(OUT, stem + '.gif'), gif);
  // a sheet of the step stills at half size, two across
  const half = stills.map((im) => im.shrink(2)), cw = half[0].w, ch = half[0].h, rows = Math.ceil(half.length / 2);
  const sheet = new Img(cw * 2 + 6, rows * (ch + 6), [24, 26, 34]);
  half.forEach((im, k) => sheet.blit(im, (k % 2) * (cw + 6), Math.floor(k / 2) * (ch + 6)));
  sheet.save(join(OUT, 'stills', `${stem}-sheet.png`));
  console.log(`${stem}.gif: ${frames.length} frames, ${(gif.length / 1024).toFixed(0)} KB`);
});
if (!only) {
  const L = [
    'Your energy overhaul, built as Game Design wrote it (`docs/design/energy-overhaul.md`) and drawn as the ten clips in its section 13, plus 7b, the four grabs side by side. Each clip is one feature; the bar on top names the clip and the step.',
    '', "The four fighters use Combat's energy kits (Protagonist, Rival, Empress and Demon Cyborg; names provisional), in Art's colour lanes, and are drawn to Legal's look rules: no balls of energy in a hand, one firing hand, straight beams. Bodies are flat stand-ins, two at a time. Knock-backs are drawn shorter than they will be, to fit the picture. C9 and C10 use simple stand-ins for punches, the zip, the sea, houses, trees, fire and water.",
    '', "**Two changes from section 13's text.** In C5 the held charge steps down when her ki runs short and never fires by itself (Game Design's ruling 5). In C7 each fighter shows the payoff Combat gave them: the Protagonist's net ends in the yank, the Rival's ring in the bind.",
    '', "**Not in it yet:** damage and armour, a mine drifting out while its button is held, and sound in the GIFs. The Empress is shown with her full kit from revision 9 (her beam and Velvet Rope); in her base form her guards are her energy.",
    '', '**Try it yourself:** open `docs/ep/prototypes/energy-v1.html` in your browser. Pick a clip to watch it step by step, or press any play key: J light, K medium, L heavy, I grab, Space guard (with a face key it lays a mine), Shift dodge, W A S D to fly and aim.', '',
    '**The clips** (`stills/` has one picture per step):', ''];
  E.CLIPS.forEach((c) => L.push(`- ${c.n}. \`${STEM[c.n]}.gif\`: ${CAP[c.n]}`));
  L.push('', '**The steps in each clip:**', '');
  E.CLIPS.forEach((c) => { L.push(`- **${c.n}. ${c.name}**`); c.steps.forEach((s, k) => L.push(`  ${k + 1}. ${s[1]}`)); });
  console.log('README.md ' + mergeReadme(join(OUT, 'README.md'), '# 48. Energy attacks, step by step', L, ['**One question:** is this the energy system you had in mind? (a) yes, (b) yes with changes, (c) not quite.', '', 'Your notes:', '']));
}
