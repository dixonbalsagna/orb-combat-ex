// How much room each clip has, and where its counted changes come from (docs/tools/flash-check.md, "Margins and sources"). Reads the clips folder of a run-pixels.mjs run (clip.json,
// analysis.json and, for the worst second, the frames --keep-ranges keeps) and prints one table: the three readings of the combined rule, and for every counted change inside the worst
// second its size as a share of the area threshold (21,824 px at 1024 by 768: 100% is the least that counts, so a pass that sits at 101% has no room and one at 250% is a real flash), and
// a reading of its source from the frames:
//   HUD     most of the changed pixels are inside the HUD's panels (the bars along the top, the strip along the bottom)
//   camera  a whole-picture shift between the two frames explains most of the change (the picture moved: a pan, a zoom, a jump)
//   world   no shift explains it: the world's own brightness changed (a beam's white, a stage change, terrain shading, a horizon drifting, a flash)
// The source is a heuristic, not a verdict: read the frames of any clip that matters (`--frames` prints the pixels behind each change).
//
//   node tools/flash/margins.mjs <clips folder> [--clips ai-4-normal,collapse-reduced] [--json out.json] [--md out.md] [--no-frames]
import { readFileSync, writeFileSync, existsSync, readdirSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createRequire } from 'node:module';

const here = dirname(fileURLToPath(import.meta.url));
const W = createRequire(import.meta.url)('./wcag.js');
const argv = process.argv.slice(2);
const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
const DIR = argv.find((a) => !a.startsWith('--') && (argv[argv.indexOf(a) - 1] || '').startsWith('--') === false);
if (!DIR || !existsSync(DIR)) { console.error('usage: node tools/flash/margins.mjs <clips folder> [--clips a,b] [--json out.json] [--md out.md] [--no-frames]'); process.exit(2); }
const ONLY = opt('--clips') ? opt('--clips').split(',') : null;
const THRESHOLD = 21824;                                  // 25% of a 341 by 256 window at 1024 by 768 (WCAG 2.3.1's 10 degrees of the visual field)
const HUD = [[40, 30, 250, 125], [370, 30, 660, 82], [775, 30, 990, 125], [285, 712, 735, 738]];   // x0, y0, x1, y1 at 1024 by 768
const MAXSHIFT = 48;

function lumFrame(dir, tick) {
  const f = join(dir, `frame-${String(tick).padStart(6, '0')}.png`);
  if (!existsSync(f)) return null;
  const im = W.decodePng(readFileSync(f));
  const L = new Float32Array(im.w * im.h);
  const lin = (c) => { c /= 255; return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4); };
  for (let i = 0; i < L.length; i++) L[i] = 0.2126 * lin(im.data[i * 4]) + 0.7152 * lin(im.data[i * 4 + 1]) + 0.0722 * lin(im.data[i * 4 + 2]);
  return { L, w: im.w, h: im.h };
}
function profile(fr, axis) {
  const n = axis === 'x' ? fr.w : fr.h, m = axis === 'x' ? fr.h : fr.w;
  const p = new Float64Array(n);
  for (let a = 0; a < n; a++) { let s = 0; for (let b = 0; b < m; b++) s += axis === 'x' ? fr.L[b * fr.w + a] : fr.L[a * fr.w + b]; p[a] = s / m; }
  return p;
}
function bestShift(p, q) {
  const n = p.length;
  let best = { s: 0, e: Infinity }, zero = 0;
  for (let s = -MAXSHIFT; s <= MAXSHIFT; s++) {
    let e = 0, c = 0;
    for (let i = Math.max(0, s); i < Math.min(n, n + s); i++) { e += Math.abs(p[i - s] - q[i]); c++; }
    e /= Math.max(c, 1);
    if (s === 0) zero = e;
    if (e < best.e) best = { s, e };
  }
  return { shift: best.s, err: best.e, zero };
}
function source(dir, tick) {
  const a = lumFrame(dir, tick - 1), b = lumFrame(dir, tick);
  if (!a || !b) return null;
  let changed = 0, inHud = 0, sumA = 0, sumB = 0, up = 0;
  for (let y = 0; y < a.h; y++) for (let x = 0; x < a.w; x++) {
    const i = y * a.w + x;
    sumA += a.L[i]; sumB += b.L[i];
    if (Math.abs(b.L[i] - a.L[i]) >= 0.1) {
      changed++;
      if (b.L[i] > a.L[i]) up++;
      for (const r of HUD) if (x >= r[0] && x < r[2] && y >= r[1] && y < r[3]) { inHud++; break; }
    }
  }
  const sx = bestShift(profile(a, 'x'), profile(b, 'x')), sy = bestShift(profile(a, 'y'), profile(b, 'y'));
  const explained = (r) => (r.zero > 1e-6 ? 1 - r.err / r.zero : 0);
  const moved = Math.max(explained(sx), explained(sy));
  // the picture's content changing both ways at once (as much brighter as darker) is the picture moving or being replaced; one way is the world's own brightness (a beam's white, a stage change, a flash)
  const upShare = changed ? up / changed : 0.5;
  const balance = Math.min(upShare, 1 - upShare) / Math.max(upShare, 1 - upShare, 1e-9);
  let kind = 'world';
  if (changed > 0 && inHud / changed > 0.5) kind = 'HUD';
  else if (moved > 0.5 && (Math.abs(sx.shift) + Math.abs(sy.shift)) >= 1) kind = 'camera';
  else if (balance >= 0.45 && changed >= 20000) kind = 'camera';
  return { kind, changedPx: changed, hudShare: changed ? inHud / changed : 0, shiftX: sx.shift, shiftY: sy.shift, explained: +moved.toFixed(2), upShare: +upShare.toFixed(2), meanStep: +(sumB / a.L.length - sumA / a.L.length).toFixed(3) };
}

const ids = readdirSync(DIR).filter((d) => existsSync(join(DIR, d, 'analysis.json')) && (!ONLY || ONLY.includes(d))).sort();
const rows = [];
for (const id of ids) {
  const dir = join(DIR, id);
  const r = JSON.parse(readFileSync(join(dir, 'analysis.json'), 'utf8'))[0].result;
  const c = r.combined || {};
  const at = r.general.atTick;
  const evs = (r.general.events || []).filter((e) => e.tick >= at && e.tick < at + 60);
  const changes = evs.map((e) => {
    const s = argv.includes('--no-frames') ? null : source(dir, e.tick);
    return { tick: e.tick, dir: e.sign > 0 ? 'up' : 'down', windowPx: e.windowPx, pct: Math.round((e.windowPx / THRESHOLD) * 100), runMaxPct: Math.round((e.runMaxPx || e.windowPx) / THRESHOLD * 100), marginal: !!e.marginal, source: s ? s.kind : '?', detail: s || null };
  });
  const sources = {};
  for (const ch of changes) sources[ch.source] = (sources[ch.source] || 0) + 1;
  const lowest = changes.length ? Math.min(...changes.map((x) => x.pct)) : null;
  rows.push({
    id, verdict: c.verdict || '?', primary: c.primary, lower: c.lower, higher: c.higher, stricter: c.stricter, worstAt: at, red: r.red ? r.red.flashes : 0,
    counted: changes.length, lowestPct: lowest, atRisk: changes.filter((x) => x.pct <= 115).length, sources, changes,
  });
}
const out = [];
out.push('| clip | verdict | primary | area-15% | 2 s memory | worst second at | counted changes (% of threshold) | lowest | within 15% of it | sources |');
out.push('|---|---|---|---|---|---|---|---|---|---|');
for (const r of rows) {
  const list = r.changes.map((x) => `${x.pct}${x.dir === 'up' ? '+' : '-'}`).join(' ');
  out.push(`| ${r.id} | ${r.verdict} | ${r.primary} | ${r.lower} | ${r.stricter} | ${r.worstAt} | ${list} | ${r.lowestPct === null ? '' : r.lowestPct + '%'} | ${r.atRisk} | ${Object.entries(r.sources).map(([k, v]) => `${k} ${v}`).join(', ')} |`);
}
console.log(out.join('\n'));
if (opt('--json')) writeFileSync(opt('--json'), JSON.stringify(rows, null, 2) + '\n');
if (opt('--md')) writeFileSync(opt('--md'), out.join('\n') + '\n');
void here;
