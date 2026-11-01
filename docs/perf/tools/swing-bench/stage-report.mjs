// Reads the JSON that stage_bench2.gd wrote (several independent processes per case, two matches in each) and prints, per case, the ticks whose minimum over the processes is over a limit, by match (first in the process / rematch).
//   node stage-report.mjs <dir of json> [limit us = 16000] [--all]
// The minimum over independent processes stands in for CPU time on a busy machine: a spike that one process saw and another did not is the machine's (preemption), and one that every process saw is the code's.
import { readdirSync, readFileSync } from 'node:fs';
const dir = process.argv[2];
const limit = Number(process.argv[3] && !process.argv[3].startsWith('--') ? process.argv[3] : 16000);
const files = readdirSync(dir).filter((f) => f.endsWith('.json'));
const cases = new Map();
for (const f of files) {
  const m = /^(p\d+s\d+(?:on|off))\.r(\d+)\.json$/.exec(f);
  if (!m) continue;
  if (!cases.has(m[1])) cases.set(m[1], []);
  cases.get(m[1]).push(JSON.parse(readFileSync(`${dir}/${f}`, 'utf8')));
}
const q = (a, p) => { const s = [...a].sort((x, y) => x - y); return s[Math.min(s.length - 1, Math.floor(p * s.length))]; };
const out = [];
for (const [name, runs] of [...cases].sort()) {
  const r0 = runs[0];
  for (let rep = 0; rep < r0.reps.length; rep++) {
    const n = r0.ticks;
    const mins = new Array(n).fill(Infinity);
    for (const r of runs) for (let t = 0; t < n; t++) mins[t] = Math.min(mins[t], r.reps[rep].us[t]);
    const ends = new Set(runs.map((r) => r.reps[rep].end));
    const over = [];
    for (let t = 0; t < n; t++) if (mins[t] > limit) over.push(t);
    const mean = mins.reduce((a, b) => a + b, 0) / n;
    out.push(`${name} ${rep === 0 ? 'FIRST' : 'REMATCH'} | ${runs.length} runs | ends ${ends.size === 1 ? 'same' : 'DIFFER'} | mean ${mean.toFixed(0)} p50 ${q(mins, 0.5)} p95 ${q(mins, 0.95)} p99 ${q(mins, 0.99)} max ${Math.max(...mins)} | ticks over ${limit}: ${over.length}`);
    // ticks over the limit in any single run but not in the minimum: the machine's
    let spiky = 0;
    for (const r of runs) for (let t = 0; t < n; t++) if (r.reps[rep].us[t] > limit && mins[t] <= limit) spiky++;
    out.push(`   run-only spikes over the limit that the minimum removes: ${spiky}`);
    for (const t of over) {
      let best = null;
      for (const r of runs) if (!best || r.reps[rep].us[t] < best.reps[rep].us[t]) best = r;
      const d = best.reps[rep].det[String(t)] || {};
      const top = (o, k = 4) => Object.entries(o || {}).sort((a, b) => b[1] - a[1]).slice(0, k).map(([a, b]) => `${a} ${b}`).join(', ');
      out.push(`   tick ${t}: ${mins[t]} us (runs: ${runs.map((r) => r.reps[rep].us[t]).join('/')}) | stages ${top(d.stg, 3)} | pm ${top(d.pm, 4)} | new nodes ${best.reps[rep].nodes[t]} | swing ${d.swing} | ${(d.tags || []).slice(0, 4).join(',')}`);
    }
  }
}
console.log(out.join('\n'));
