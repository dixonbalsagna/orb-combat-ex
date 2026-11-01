// The Driver and mines page (docs/ep/prototypes/driver-mines-v1.html), run in node with no browser: its sim and drawing, a scanline fill and a GIF encoder (after research/energy-proto/gif.mjs).
//   node research/rule-of-cool/driver-clips.mjs --check             plays every clip, prints what happened
//   node research/rule-of-cool/driver-clips.mjs --bots              seeded bots against the stand-in rival: the mines' and Driver's first reads
//   node research/rule-of-cool/driver-clips.mjs <out dir> [D1,M3]   the clips as GIFs, with inputs at the frame's edge
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { join } from 'node:path';
import { Img } from '../planet-gen/lib/img.mjs';

const src = readFileSync('docs/ep/prototypes/driver-mines-v1.html', 'utf8'), a = src.indexOf('// ==== SIM (no DOM) ===='), b = src.indexOf('// ==== PAGE (DOM) ====');
if (a < 0 || b < 0) throw new Error('markers');
const E = new Function(src.slice(a, b) + '\nreturn E;')();
const W = E.W, H = E.H, BAR = 66, FW = W, FH = H + BAR, hex = (s) => [parseInt(s.slice(1, 3), 16), parseInt(s.slice(3, 5), 16), parseInt(s.slice(5, 7), 16)];

function makeR(img, oy) {
  const cache = new Map(), rgb = (c) => { let v = cache.get(c); if (!v) { v = hex(c); cache.set(c, v); } return v; };
  return {
    clear(c) { img.fill(0, oy, W, H, rgb(c)); },
    text(x, y, s, c) { img.text(Math.round(x), Math.round(y) + oy, String(s).toUpperCase(), 1, rgb(c)); },
    poly(p, c) {
      const n = p.length / 2; if (n < 3) return; let y0 = Infinity, y1 = -Infinity;
      for (let i = 1; i < p.length; i += 2) { if (p[i] < y0) y0 = p[i]; if (p[i] > y1) y1 = p[i]; } if (!(y1 >= y0)) return;
      const col = rgb(c), ya = Math.max(0, Math.ceil(y0 - 0.5)), yb = Math.min(H - 1, Math.floor(y1 - 0.5)), xs = [];
      for (let y = ya; y <= yb; y++) { const sy = y + 0.5; xs.length = 0; for (let i = 0, j = n - 1; i < n; j = i++) { const xi = p[2 * i], yi = p[2 * i + 1], xj = p[2 * j], yj = p[2 * j + 1]; if ((yi > sy) !== (yj > sy)) xs.push(xi + (sy - yi) / (yj - yi) * (xj - xi)); } xs.sort((u, v) => u - v);
        for (let k = 0; k + 1 < xs.length; k += 2) { const xa = Math.max(0, Math.ceil(xs[k] - 0.5)), xb = Math.min(W - 1, Math.floor(xs[k + 1] - 0.5)); for (let x = xa; x <= xb; x++) { const o = ((y + oy) * FW + x) * 3; img.d[o] = col[0]; img.d[o + 1] = col[1]; img.d[o + 2] = col[2]; } } }
    },
  };
}
function lzw(indices, minCode) { const clear = 1 << minCode, eoi = clear + 1, out = []; let size = minCode + 1, next = eoi + 1, dict = new Map(), cur = 0, nbits = 0; const emit = (code) => { cur |= code << nbits; nbits += size; while (nbits >= 8) { out.push(cur & 255); cur >>>= 8; nbits -= 8; } }; emit(clear); let w = indices[0]; for (let i = 1; i < indices.length; i++) { const k = indices[i], key = w * 4096 + k, v = dict.get(key); if (v !== undefined) { w = v; continue; } emit(w); if (next < 4096) { dict.set(key, next++); if (next > (1 << size) && size < 12) size++; } else { emit(clear); dict = new Map(); size = minCode + 1; next = eoi + 1; } w = k; } emit(w); emit(eoi); if (nbits > 0) out.push(cur & 255); return out; }
function encodeGif(frames, delay) {
  const pal = new Map(), plist = [], idx = frames.map((f) => { const ix = new Uint8Array(FW * FH); for (let i = 0; i < FW * FH; i++) { const key = (f.d[i * 3] << 16) | (f.d[i * 3 + 1] << 8) | f.d[i * 3 + 2]; let v = pal.get(key); if (v === undefined) { v = plist.length; if (v > 255) throw new Error('more than 256 colours'); pal.set(key, v); plist.push(key); } ix[i] = v; } return ix; });
  const bytes = [], push = (...v) => { for (const x of v) bytes.push(x); }, u16 = (v) => push(v & 255, v >> 8); push(...Buffer.from('GIF89a')); u16(FW); u16(FH); push(0xf7, 0, 0); for (let i = 0; i < 256; i++) { const c = plist[i] || 0; push(c >> 16, (c >> 8) & 255, c & 255); } push(0x21, 0xff, 11, ...Buffer.from('NETSCAPE2.0'), 3, 1, 0, 0, 0);
  let prev = null; idx.forEach((ix) => { let x0 = 0, y0 = 0, x1 = FW - 1, y1 = FH - 1; if (prev) { x0 = FW; y0 = FH; x1 = -1; y1 = -1; for (let y = 0; y < FH; y++) for (let x = 0; x < FW; x++) { const i = y * FW + x; if (ix[i] !== prev[i]) { if (x < x0) x0 = x; if (x > x1) x1 = x; if (y < y0) y0 = y; if (y > y1) y1 = y; } } if (x1 < 0) { x0 = y0 = 0; x1 = y1 = 0; } } push(0x21, 0xf9, 4, 0x04); u16(delay); push(0, 0); push(0x2c); u16(x0); u16(y0); u16(x1 - x0 + 1); u16(y1 - y0 + 1); push(0); const sub = new Uint8Array((x1 - x0 + 1) * (y1 - y0 + 1)); for (let y = y0, o = 0; y <= y1; y++) for (let x = x0; x <= x1; x++) sub[o++] = ix[y * FW + x]; const data = lzw(sub, 8); push(8); for (let i = 0; i < data.length; i += 255) { const c = data.slice(i, i + 255); push(c.length, ...c); } push(0); prev = ix; }); push(0x3b); return Buffer.from(bytes);
}
function wrapText(s, n) { const out = []; let l = ''; for (const wd of s.split(' ')) { if ((l + ' ' + wd).trim().length > n) { out.push(l.trim()); l = wd; } else l += ' ' + wd; } if (l.trim()) out.push(l.trim()); return out; }

function play(ci) { const c = E.CLIPS[ci], len = E.clipLen(c), run = E.newRun(ci, 'demo'), log = []; for (let t = 0; t < len - 1; t++) { E.stepRun(run); } const w = run.w; return { c, stats: w.stats, L: w.L, R: w.R, mines: w.mines.length, feed: w.feed }; }

const arg = process.argv[2];
if (arg === '--check') {
  E.CLIPS.forEach((c, i) => { const r = play(i), s = r.stats; console.log(c.n, c.name, '| fired', s.fired.join('/'), 'landed', s.land.join('/'), 'read', s.read.join('/'), '| mines laid', s.laid, 'off', s.off, 'answered', s.answered, 'sent into', s.sentInto, '| rival hp', Math.round(r.R.hp), 'ki', Math.round(r.L.ki), '| hold', E.OPT.hold); });
} else if (arg === '--bots') {
  // A mine-using arm and a Driver arm against the page's stand-in rival, 3 minutes each, seeded. A bot, not a person: it says whether the rules give mines and shots work to do on the big ring, not whether they're fun
  const hash = (n) => { const x = Math.sin(n * 91.7 + 13.3) * 43758.5453; return x - Math.floor(x); };
  function bout(seed, read, tier, armMines, armDriver) {
    E.OPT.read = read; E.OPT.tier = tier; E.OPT.hold = 'driver'; const w = E.newWorld(null, 0); w.seed = seed; w.L.x = 1000 + hash(seed) * 90000; w.R.x = w.L.x + 2000; let plan = null, nextT = 60;
    const ticks = 180 * 60; for (let t = 0; t < ticks; t++) { const L = w.L, R = w.R, d = E.sdx(L.x, R.x), dist = Math.abs(d), o = { mx: 0, my: 0 }, mode = w.aiMode; if (mode === 'chase') { o.mx = d > 0 ? -1 : 1; o.LT = true; } else { o.mx = 0; } o.my = (1100 - L.y) / 700;
      if (t >= nextT && !plan) { const r = hash(seed * 7 + t); if (armMines && mode === 'chase' && dist > 4500) plan = { k: 'lay', b: hash(seed + t) < 0.6 ? 'Y' : 'X', n: 2, t: 0 }; else if (armDriver) plan = { k: 'drv', n: [40, 64, 92][Math.floor(hash(seed * 3 + t) * 3)], t: 0 }; nextT = t + 70 + Math.floor(hash(seed * 11 + t) * 160); }
      if (plan) { plan.t++; if (plan.k === 'lay') { o.LB = true; o.RB = true; if (plan.t > 2 && plan.t < 3 + plan.n) o[plan.b] = true; if (plan.t >= 4 + plan.n) plan = null; } else { o.RB = true; if (plan.t > 2 && plan.t < 3 + plan.n) o.B = true; if (plan.t >= 4 + plan.n) plan = null; } }
      L.inp = o; E.aiStep(w); E.stepWorld(w); }
    const s = w.stats; return s;
  }
  function row(label, read, tier, m, dr) { const T = { laid: 0, off: 0, answered: 0, fizzled: 0, cold: 0, expired: 0, sentInto: 0, fired: [0, 0, 0, 0], land: [0, 0, 0, 0], read: [0, 0, 0, 0], hits: 0 }, N = 20; for (let s = 1; s <= N; s++) { const r = bout(s, read, tier, m, dr); for (const k of ['laid', 'off', 'answered', 'fizzled', 'cold', 'expired', 'sentInto']) T[k] += r[k]; for (let i = 0; i < 4; i++) { T.fired[i] += r.fired[i]; T.land[i] += r.land[i]; T.read[i] += r.read[i]; } T.hits += r.hitsOnYou; } const pct = (x, y) => (y ? Math.round(100 * x / y) : 0) + '%'; console.log(label, '| mines a bout', (T.laid / N).toFixed(0), ', off', pct(T.off, T.laid), ', answered', pct(T.answered, T.laid), ', fizzled', pct(T.fizzled + T.cold + T.expired, T.laid), '(cold', pct(T.cold, T.laid) + ')', '| real work a bout', (T.off / N).toFixed(1), '| Driver landed L1', pct(T.land[1], T.fired[1]), 'L2', pct(T.land[2], T.fired[2]), 'L3', pct(T.land[3], T.fired[3]), 'of', T.fired[3] / N | 0, 'a bout; read L3', pct(T.read[3], T.fired[3])); }
  for (const [fz, cb] of [['plain', 120], ['lead', 120], ['plain', 600], ['lead', 600]]) { E.OPT.fuse = fz; E.OPT.coldBh = cb; for (const [t, r] of [[1, 0.35], [4, 0.35], [4, 0.75]]) row(`fuse ${fz}, cold ${cb}, tier ${t}, reads ${r}`, r, t, true, false); }
  E.OPT.fuse = 'lead';
  for (const r of [0, 0.35, 0.75]) row(`tier 4, reads ${r}, Driver arm`, r, 4, false, true);
} else {
  const out = arg || 'research/rule-of-cool/clips', only = process.argv[3] ? process.argv[3].split(',') : null; mkdirSync(out, { recursive: true }); const BG = [31, 31, 28], INK = [240, 239, 233], DIM = [176, 174, 165];
  E.CLIPS.forEach((c, ci) => { if (only && !only.includes(c.n)) return; const run = E.newRun(ci, 'demo'), len = E.clipLen(c), frames = []; for (let t = 0; t < len - 1; t++) { E.stepRun(run); if (t % 2) continue; const img = new Img(FW, FH); img.fill(0, 0, FW, BAR, BG); img.text(10, 6, `${c.n} ${c.name}`.toUpperCase(), 2, INK); const k = E.stepOf(c, run.t); wrapText(`${k + 1}. ${c.steps[k][1]}`.toUpperCase(), 118).slice(0, 3).forEach((l, i) => img.text(10, 28 + i * 12, l, 1, DIM)); E.draw(run, makeR(img, BAR)); frames.push(img); } const file = join(out, `${c.n}-${c.name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/-$/, '')}.gif`), g = encodeGif(frames, 3); writeFileSync(file, g); console.log(file, Math.round(g.length / 1024), 'KB', frames.length, 'frames'); });
}
