#!/usr/bin/env node
// Reads a load-probe.mjs run and prints the phase table (wall, CPU seconds of the renderer and GPU processes, GL blocking time, longest freeze, machine load) for each load.
//   node docs/perf/tools/load-report.mjs run.json [--top 12]
import { readFileSync } from 'node:fs';

const f = process.argv[2];
if (!f) { console.error('usage: node docs/perf/tools/load-report.mjs run.json'); process.exit(2); }
const topN = process.argv.includes('--top') ? Number(process.argv[process.argv.indexOf('--top') + 1]) : 12;
const R = JSON.parse(readFileSync(f, 'utf8'));
const S = R.sample;
const sec = (ms) => (ms / 1000).toFixed(1);

/** cumulative CPU seconds of one process type (the busiest process of that type, by its last reading) at absolute time `abs` (linear between samples) */
function cpuAt(type, abs, ids) {
  const col = (i) => S.pi[i].filter((p) => p[0] === type && ids.has(p[1])).reduce((a, p) => a + p[2], 0);
  const n = S.t.length;
  if (abs <= S.t[0]) return col(0);
  if (abs >= S.t[n - 1]) return col(n - 1);
  let i = 1; while (S.t[i] < abs) i++;
  const a = col(i - 1), b = col(i), w = (abs - S.t[i - 1]) / (S.t[i] - S.t[i - 1]);
  return a + (b - a) * w;
}
function busiest(type, k0, k1) {
  const m = new Map();
  for (let i = k0; i < Math.min(k1, S.pi.length); i++) for (const p of S.pi[i]) if (p[0] === type) m.set(p[1], Math.max(m.get(p[1]) || 0, p[2]));
  return new Set([...m.entries()].sort((a, b) => b[1] - a[1]).slice(0, 1).map((e) => e[0]));
}
function loadMean(a0, a1) {
  const v = []; for (let i = 0; i < S.t.length; i++) if (S.t[i] >= a0 && S.t[i] <= a1) v.push(S.load[i]);
  return v.length ? Math.round(v.reduce((x, y) => x + y, 0) / v.length) : null;
}

for (const L of R.loads) {
  const P = L.p;
  console.log(`\n=== load ${L.n} (${L.n === 1 ? 'COLD: fresh profile' : 'WARM: same browser, second visit'}) ${R.query ? '?' + R.query : ''} — ${R.size}, GPU ${L.gpu} ===`);
  if (!P) { console.log('no page data'); continue; }
  const origin = P.origin;   // epoch ms of the page's t=0
  const ab = (t) => origin + t;
  const rids = busiest('renderer', L.k0, L.k1), gids = busiest('GPU', L.k0, L.k1);
  const stageT = {}; for (const [s, t] of P.stages) if (!(s in stageT)) stageT[s] = t;
  const bp = Object.fromEntries(P.bp);
  const res = (L.resources || []).filter((r) => /index\.(js|wasm|pck)$|index\.html$/.test(r[0]));
  console.log('stages (page clock, s):', P.stages.map(([s, t]) => `${s} ${sec(t)}`).join(' | '));
  console.log('wasm compile:', bp.wasm_instantiateStreaming_begin != null ? `${sec(bp.wasm_instantiateStreaming_begin)} -> ${sec(bp.wasm_instantiateStreaming_end)}` : bp.wasm_instantiate_begin != null ? `${sec(bp.wasm_instantiate_begin)} -> ${sec(bp.wasm_instantiate_end)}` : '(not seen)');
  console.log('downloads (start -> end, s; bytes):', res.map((r) => `${r[0]} ${sec(r[1])}->${sec(r[2])} ${r[3] || r[4]}`).join(' | '));
  const wasmEnd = bp.wasm_instantiateStreaming_end ?? bp.wasm_instantiate_end ?? 0;
  const dlEnd = Math.max(0, ...res.map((r) => r[2]));
  const end = P.stages.length ? (stageT.card ?? stageT.intro ?? stageT.playing ?? P.stages[P.stages.length - 1][1]) : null;
  const phases = [
    ['download (localhost; wasm+pck+js)', 0, dlEnd],
    ['wasm compile', bp.wasm_instantiateStreaming_begin ?? bp.wasm_instantiate_begin ?? dlEnd, wasmEnd],
    ['engine init (wasm up -> line up = first_frame)', wasmEnd, stageT.first_frame],
    ['scripts (graphs loaded a frame each)', stageT.first_frame, stageT.loading ?? stageT.compiling],
    ['loading (match + panes built in steps)', stageT.loading, stageT.compiling],
    ['compiling (shader warm-up)', stageT.compiling, end],
  ];
  console.log('\nphase                                           wall s   renderer CPU s   GPU CPU s   GL compile-wait s   GL draw s   GL upload s   longest freeze s   machine busy %');
  for (const [name, t0, t1] of phases) {
    if (t0 == null || t1 == null || t1 < t0) { console.log(`${name.padEnd(48)}(not seen)`); continue; }
    const rc = cpuAt('renderer', ab(t1), rids) - cpuAt('renderer', ab(t0), rids), gc = cpuAt('GPU', ab(t1), gids) - cpuAt('GPU', ab(t0), gids);
    let gl = { compile: 0, draw: 0, upload: 0 };
    const stg = name.startsWith('scripts') ? ['scripts', 'first_frame'] : name.startsWith('loading') ? ['loading'] : name.startsWith('compiling') ? ['compiling'] : name.startsWith('engine') ? ['page'] : [];
    for (const s of stg) { const g = P.glStage[s] || {}; for (const k of Object.keys(gl)) gl[k] += (g[k] ? g[k].ms : 0); }
    const fr = Math.max(0, ...P.gaps.filter((g) => g[0] >= t0 - 1 && g[0] < t1).map((g) => g[1]), ...P.long.filter((g) => g[0] >= t0 - 1 && g[0] < t1).map((g) => g[1]));
    console.log(`${name.padEnd(48)}${sec(t1 - t0).padStart(6)}   ${rc.toFixed(1).padStart(14)}   ${gc.toFixed(1).padStart(9)}   ${(gl.compile / 1000).toFixed(1).padStart(17)}   ${(gl.draw / 1000).toFixed(1).padStart(9)}   ${(gl.upload / 1000).toFixed(1).padStart(11)}   ${sec(fr).padStart(16)}   ${String(loadMean(ab(t0), ab(t1))).padStart(14)}`);
  }
  if (end != null) console.log(`\nTIME TO PLAYABLE (first card / boot done): ${sec(end)} s from the page start.  Frames drawn: ${P.frames}.`);
  const top = (P.long || []).slice().sort((a, b) => b[1] - a[1]).slice(0, 8);
  console.log('longest tasks (start s, ms):', top.map((x) => `${sec(x[0])}s ${x[1]}ms`).join(' | '));
  console.log('freezes over 100 ms (start s, ms, stage):', P.gaps.slice().sort((a, b) => b[1] - a[1]).slice(0, 12).map((g) => `${sec(g[0])}s ${g[1]}ms ${g[2]}`).join(' | '));
  console.log('GL method totals (ms):', Object.entries(P.gl).map(([k, v]) => [k, v.ms, v.n, v.max]).sort((a, b) => b[1] - a[1]).slice(0, 8).map((x) => `${x[0]} ${x[1].toFixed(0)}ms/${x[2]} calls (max ${x[3].toFixed(0)})`).join(' | '));
  const progs = Object.entries(P.dump || {}).map(([id, v]) => ({ id, ...v, total: (v.link_ms || 0) + (v.draw_stall_ms || 0) })).sort((a, b) => b.total - a.total).slice(0, topN);
  console.log(`programs: ${Object.keys(P.dump || {}).length}; summed link wait ${(Object.values(P.dump || {}).reduce((a, v) => a + (v.link_ms || 0), 0) / 1000).toFixed(1)} s, summed draw stalls ${(Object.values(P.dump || {}).reduce((a, v) => a + (v.draw_stall_ms || 0), 0) / 1000).toFixed(1)} s. Slowest:`);
  for (const p of progs) console.log(`  #${String(p.id).padEnd(3)} link ${((p.link_ms || 0)).toFixed(0).padStart(5)} ms  draw-stall ${((p.draw_stall_ms || 0)).toFixed(0).padStart(5)} ms  vs/fs ${p.vlen}/${p.flen}  at ${sec(p.t || 0)}s  ${p.tag || ''}`);
  console.log('single GL calls over 25 ms:', (P.big || []).length, (P.big || []).slice().sort((a, b) => b[2] - a[2]).slice(0, 10).map((x) => `${sec(x[0])}s ${x[1]} ${x[2]}ms #${x[3]} ${x[4]}`).join(' | '));
}
const sl = S.load.slice(); sl.sort((a, b) => a - b);
console.log(`\nmachine busy over the whole run: median ${sl[Math.floor(sl.length / 2)]}%, p90 ${sl[Math.floor(sl.length * 0.9)]}%`);
