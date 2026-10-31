// The comparison: every architecture over the same seeded fights, the numbers for research.md. Counts are deterministic; the
// JS times are this machine's (other sessions load it), so the paper leans on counts times World's measured cost per read.
//   node research/ring-any-angle/bench.mjs [--seeds=3] [--ticks=7200]
import { readFileSync, writeFileSync } from 'node:fs';
import { performance } from 'node:perf_hooks';
import { surf } from '../planet-gen/gen/base.mjs';
import { sin, cos, atan2f, R } from '../planet-gen/lib/det.mjs';

const arg = (k, d) => { const a = process.argv.find((x) => x.startsWith('--' + k + '=')); return a ? +a.split('=')[1] : d; };
const code = readFileSync(new URL('./sim.js', import.meta.url), 'utf8');
export const RAA = new Function('surf', 'sin', 'cos', 'atan2f', 'R', code + '\nreturn RAA;')(surf, sin, cos, atan2f, R);
const KEYS = Object.keys(RAA.ARCHS), SEEDS = arg('seeds', 3), TICKS = arg('ticks', 7200);
// World's and Performance's measured cost of one gen 2 column read (calm-turn-read.md): native; the laptop tier x4; x6
const US = { native: 55, x4: 800, x6: 1350 }, BUDGET_MS = 15;
const out = { scen: {} };

function play(key, script, rollbackEvery) {
  RAA.clearMemo();
  const run = RAA.mkRun(key); const t0 = performance.now(); let rb = 0, rbBad = 0, rbEv = 0, snapMs = 0;
  for (let i = 0; i < script.length; i++) {
    if (rollbackEvery && i % rollbackEvery === 5 && i + 20 < script.length) {
      // a rollback of 20 ticks (NetSession's maxAhead): keep, run, hash, restore, run again, the same hash
      const s0 = performance.now(), keep = run.arch.snap(), keepT = run.t, keepN = run.nextId, keepM = run.marks.length, keepAsks = run.asks.length; snapMs += performance.now() - s0;
      for (let k = 0; k < 20; k++) run.tick(script[i + k]);
      const h1 = run.arch.hash(), ev0 = run.evals;
      run.arch.rest(keep); run.t = keepT; run.nextId = keepN; run.marks.length = keepM; run.asks.length = keepAsks;
      for (let k = 0; k < 20; k++) run.tick(script[i + k]);
      rb++; if (run.arch.hash() !== h1) rbBad++; rbEv += run.evals - ev0;
      i += 19; continue;
    }
    run.tick(script[i]);
  }
  return { run, ms: performance.now() - t0, rb, rbBad, rbEv };
}
function hashTwice(key, script) { const a = play(key, script), b = play(key, script); return a.run.arch.hash() === b.run.arch.hash() && a.run.evals === b.run.evals; }
const avg = (a) => a.reduce((x, y) => x + y, 0) / a.length;

for (const scen of ['calm', 'any', 'hard']) {
  out.scen[scen] = {};
  for (const key of KEYS) {
    const S = [];
    for (let seed = 1; seed <= SEEDS; seed++) {
      const script = RAA.genFight(seed, scen, TICKS), p = play(key, script), m = RAA.marksReport(p.run), s = RAA.summarize(p.run, p.ms);
      S.push({ ...s, ...m });
    }
    const f = (k) => avg(S.map((x) => x[k] ?? 0));
    const o = { farFillP50: f('farFillP50'), farFillN: f('farFillN'), farErrRms: f('farErrRms'), reseen: f('reseen'), reseenMax: Math.max(...S.map((x) => x.reseenMax)), evalsMean: f('evalsMean'), evalsP99: f('evalsP99'), evalsMax: Math.max(...S.map((x) => x.evalsMax)), forced: f('forced'), lookups: f('lookups') / TICKS, popTicks: f('popTicks'), popCols: f('popCols'), popMax: Math.max(...S.map((x) => x.popMax)), asks: f('asks'), refused: f('refused'), realised: f('realised'), latP50: f('latP50'), latP90: f('latP90'), marks: f('marks'), right: f('right'), moved: f('moved'), gone: f('gone'), revisit: f('revisit'), seamGap: Math.min(...S.map((x) => x.seamGap)), jsMs: f('jsMs'), bytes: S[0].bytes };
    o.tickMsNative = o.evalsMean * US.native / 1000; o.peakMsNative = o.evalsMax * US.native / 1000; o.p99MsX6 = o.evalsP99 * US.x6 / 1000; o.p99MsX4 = o.evalsP99 * US.x4 / 1000;
    out.scen[scen][key] = o;
  }
}
// rollback and determinism on the any-time fight
out.rollback = {};
for (const key of KEYS) {
  const script = RAA.genFight(1, 'any', 3600), r = play(key, script, 40), same = hashTwice(key, script);
  out.rollback[key] = { rollbacks: r.rb, mismatches: r.rbBad, reReadEvals: r.rbEv, sameTwice: same, snapshot: r.run.arch.bytes().snapshot };
}
// a lap: straight, does it close? with a turn half way, where does it arrive, and is there any wall?
out.lap = {};
for (const key of KEYS) for (const steer of [false, true]) {
  const script = RAA.genLap(steer); RAA.clearMemo(); const run = RAA.mkRun(key); let start = null, end = null, c0 = 0;
  script.forEach((w, i) => { run.tick(w); const c = Math.round(w.m); if (i === 0) { start = run.arch.axis(c).p; c0 = c; } if (!end && c >= c0 + RAA.NC) end = run.arch.axis(c).p; });
  out.lap[key + (steer ? ' steered' : ' straight')] = { missU: RAA.arcU(start, end) - (Math.round(script.find((w) => Math.round(w.m) >= c0 + RAA.NC).m) - c0 - RAA.NC) * RAA.COL, evals: run.evals, evPeak: run.evPeak, forced: run.forced, popTicks: run.viewPopTicks, marks: RAA.marksReport(run), asksRealised: run.asks.length };
}
// flying to a place: the choreographer aims the line at a point a quarter of the way round
out.home = {};
for (const key of KEYS) {
  RAA.clearMemo(); const run0 = RAA.mkRun(key); const q = RAA.along(run0.p0, RAA.norm(RAA.cross(run0.p0, [0.3, 0.8, -0.2])), 1100).p;
  const script = RAA.genHome(q); RAA.clearMemo(); const run = RAA.mkRun(key); let best = 1e12, at = -1;
  script.forEach((w, i) => { run.tick(w); const d = RAA.arcU(run.arch.axis(Math.round(w.m)).p, q); if (d < best) { best = d; at = i; } });
  out.home[key] = { missU: best, atTick: at, evals: run.evals, popTicks: run.viewPopTicks, forced: run.forced };
}
out.cross = {};
for (const key of KEYS) {
  RAA.clearMemo(); const r0 = RAA.mkRun(key); const q = { q: null }; const scr0 = RAA.genCross(q); r0.tick(scr0[0]); r0.tick(scr0[1]); q.q = r0.marks[0].p;
  const script = RAA.genCross(q); RAA.clearMemo(); const run = RAA.mkRun(key); let best = 1e12, shown = 0, at = -1, ang = 0, after = false;
  script.forEach((w, i) => { run.tick(w); const c = Math.round(w.m), ax = run.arch.axis(c), d = RAA.arcU(ax.p, q.q); if (i > 400 && d < best) { best = d; at = i; const s = run.arch.s, ci = RAA.mod(c); shown = s.def[ci]; const n0 = RAA.cross(q.q, script[0].t0 || [0, 1, 0]); ang = 0; } });
  out.cross[key] = { closestU: best, atTick: at, depthThereU: shown, popTicks: run.viewPopTicks, evals: run.evals };
}
// a launch with the bearing asked on its first tick: how far does it fly before the line has turned, and how far off the old line is it?
out.launch = {};
for (const key of KEYS) for (const ang of [45, 90, 180]) {
  RAA.clearMemo(); const run = RAA.mkRun(key), script = RAA.genLaunch(ang); let p0 = null, n0 = null, half = null, full = null, off6 = null;
  script.forEach((w, i) => { run.tick(w); const ax = run.arch.axis(Math.round(w.m)); if (i === 60) { p0 = ax.p; n0 = RAA.norm(RAA.cross(ax.p, ax.t)); } if (i > 60) { const n = RAA.norm(RAA.cross(ax.p, ax.t)), c = RAA.dot(n, n0), ang2 = Math.acos(Math.max(-1, Math.min(1, c))) * 180 / Math.PI, fl = (i - 60) * 3.125 * RAA.COL; if (half == null && ang2 >= ang * 0.5) half = fl; if (full == null && ang2 >= ang * 0.95) full = fl; if (off6 == null && fl >= 12000) off6 = Math.abs(RAA.dot(ax.p, n0)) * 24446; } });
  out.launch[key + ' ' + ang] = { flownAtHalfU: half, flownAtFullU: full, offLineAt12kU: off6, forced: run.forced, popTicks: run.viewPopTicks };
}
// the coarse field against the real ground, by node spacing: how much relief a 2D grid keeps
{ const p0 = RAA.norm([0.4, 0.1, 0.9]), t0 = RAA.norm(RAA.cross(p0, [0, 1, 0])); out.fieldErr = {};
  const h = (p) => surf(7, p[0], p[1], p[2])[0];
  for (const G of [32, 64, 128, 256, 512, 1024]) { let sq = 0, n = 0, mx = 0; const st = G / 32;
    for (let k = 0; k < 4800; k += 7) { const f0 = RAA.along(p0, t0, Math.floor(k / st) * st), f1 = RAA.along(p0, t0, Math.floor(k / st) * st + st), f = RAA.along(p0, t0, k), u = (k % st) / st, e = h(f.p) - (h(f0.p) * (1 - u) + h(f1.p) * u); sq += e * e; n++; if (Math.abs(e) > mx) mx = Math.abs(e); }
    out.fieldErr[G] = { rmsU: Math.sqrt(sq / n), maxU: mx }; } }
// the noise's measured JS cost, for the x16 line
{ const t0 = performance.now(); let s = 0; for (let i = 0; i < 20000; i++) { const a = i * 0.0003; s += surf(7, cos(a) * 0.8, 0.6, sin(a) * 0.8)[0]; } out.surfUsJs = (performance.now() - t0) * 1000 / 20000; out.surfSum = s; }
out.US = US; out.BUDGET_MS = BUDGET_MS; out.TICKS = TICKS; out.SEEDS = SEEDS;
writeFileSync(new URL('./results.json', import.meta.url), JSON.stringify(out, null, 1));
const fx = (v, d = 1) => (v == null || Number.isNaN(v) ? '-' : (+v).toFixed(d));
for (const scen in out.scen) { console.log('\n== ' + scen + ' (' + SEEDS + ' seeds, ' + TICKS + ' ticks)'); for (const k of KEYS) { const o = out.scen[scen][k]; console.log(k.padEnd(8), 'reads/tick', fx(o.evalsMean, 2).padStart(6), 'p99', fx(o.evalsP99, 0).padStart(4), 'max', String(o.evalsMax).padStart(5), '| forced', fx(o.forced, 0).padStart(6), '| asks', fx(o.asks, 0).padStart(4), 'refused', fx(o.refused, 0).padStart(4), 'lat50/90', fx(o.latP50, 0), fx(o.latP90, 0), '| pop ticks', fx(o.popTicks, 0).padStart(5), 'cols', fx(o.popCols, 0).padStart(6), 'max', fx(o.popMax, 0).padStart(5), 'reseen', fx(o.reseen, 0).padStart(5), '| marks', fx(o.marks, 0), 'right', fx(o.right, 0), 'moved', fx(o.moved, 0), 'gone', fx(o.gone, 0), 'revisit', fx(o.revisit, 0), '| seam', o.seamGap > 1e8 ? '-' : o.seamGap, o.farErrRms ? '| far fill p50 ' + fx(o.farFillP50, 0) + ' err rms ' + fx(o.farErrRms, 1) : '', '| ' + fx(o.jsMs / TICKS, 3) + ' ms/tick js'); } }
console.log('\nrollback', JSON.stringify(out.rollback)); console.log('lap', JSON.stringify(out.lap, (k, v) => (typeof v === 'number' ? +v.toFixed(1) : v))); console.log('launch', JSON.stringify(out.launch, (k, v) => (typeof v === 'number' ? +v.toFixed(0) : v))); console.log('cross', JSON.stringify(out.cross, (k, v) => (typeof v === 'number' ? +v.toFixed(1) : v))); console.log('home', JSON.stringify(out.home, (k, v) => (typeof v === 'number' ? +v.toFixed(1) : v))); console.log('fieldErr', JSON.stringify(out.fieldErr, (k, v) => (typeof v === 'number' ? +v.toFixed(1) : v))); console.log('surf us js', out.surfUsJs);
