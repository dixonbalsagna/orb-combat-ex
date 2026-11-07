#!/usr/bin/env node
// Reads a two-fights kit's result file (Performance and Platform, 2026-11-07, co-op 2v2 A7): one fight and two fights side by side, in the sim (native) and on the page (the browser's frames).
//   node docs/perf/oldpc/kit/read-two-fights.mjs <oldpc-result-<build>-2v2-....json> [<a second result file to set beside it>]
// Information only: the old PC is a reading, never a gap (ADR 0013). A result is only worth reading when the PC was quiet: the page's own warnings (software drawing, hidden tab) are printed.
import { readFileSync } from 'node:fs';

const files = process.argv.slice(2);
if (!files.length) { console.error('usage: read-two-fights.mjs <result.json> [<result.json>]'); process.exit(2); }
const f1 = (v) => (v === undefined || v === null ? '-' : String(Math.round(v * 10) / 10));
for (const file of files) {
  const d = JSON.parse(readFileSync(file, 'utf8'));
  console.log(`\n${file}\n  ${d.cpu} | ${d.ram} | ${d.os}\n  graphics: ${d.graphics}`);
  if (!d.sim_pair) { console.log('  no sim_pair: this is not a two-fights kit result'); continue; }
  console.log('  SIM (native, planet 7 seed 77, 3,600 ticks; a tick steps BOTH fights):');
  console.log('    fights  match      mean us   p99 us   max us');
  for (const k of Object.keys(d.sim_pair).sort()) {
    for (const m of d.sim_pair[k].cases[0].matches) console.log(`    ${k.replace('fights', '')}       ${m.rep === 0 ? 'first   ' : 'rematch '}  ${String(m.mean_us).padStart(8)} ${String(m.p99_us).padStart(8)} ${String(m.max_us).padStart(8)}`);
  }
  const mean = (k) => { const ms = d.sim_pair[k] && d.sim_pair[k].cases[0].matches; return ms ? ms.reduce((a, m) => a + m.mean_us, 0) / ms.length : null; };
  if (mean('fights1') && mean('fights2')) console.log(`    two fights cost ${(mean('fights2') / mean('fights1')).toFixed(2)} times one fight (mean tick), job ${d.sim && d.sim.job_ms} ms`);
  const runs = d.browser && d.browser.runs;
  if (runs) {
    console.log('  PAGE (frames in the browser, the match the player sees is fight one):');
    console.log('    run    fights  fps    p50   p95   p99   max   over34  sim ticks/s (mean, slowest second)');
    for (const r of runs) {
      const fr = r.frames, tr = r.tickRate;
      console.log(`    ${r.game.padEnd(6)} ${String(r.probe && r.probe.fights !== undefined ? r.probe.fights : 1).padEnd(6)} ${f1(fr.fps).padStart(5)} ${f1(fr.p50).padStart(5)} ${f1(fr.p95).padStart(5)} ${f1(fr.p99).padStart(5)} ${f1(fr.max).padStart(5)} ${String(fr.over34).padStart(6)}   ${tr ? tr.meanPerS + ', ' + tr.minPerS : 'n/a'}`);
    }
  }
  if (d.browser && d.browser.verdict) for (const v of d.browser.verdict) console.log('  ' + v);
  if (d.browser && d.browser.hiddenDuringMeasure) console.log('  WARN: the tab was hidden during a measurement');
}
