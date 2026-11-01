// Aggregates frame-bench runs made in rotating pairs: files <prefix><variant>-r<round>.json (variant A, B0, B1, B2). Prints each variant's median of the runs' p10, p50, mean, p95, and the paired differences B minus A per round.
//   node bench-pairs.mjs <dir> <prefix>      (prefix: '', 'hi-', 'w-' or 'whi-')
import { readdirSync, readFileSync } from 'node:fs';
const dir = process.argv[2], prefix = process.argv[3] || '';
const re = new RegExp('^' + prefix + '(A|B\\d)-r(\\d)\\.json$');
const by = {};
for (const f of readdirSync(dir)) {
  const m = re.exec(f); if (!m) continue;
  const j = JSON.parse(readFileSync(`${dir}/${f}`, 'utf8'));
  (by[m[1]] = by[m[1]] || []).push({ r: +m[2], ...j.frame_ms, vp: j.viewport, load: j.loadBefore && j.loadBefore.all });
}
const med = (a) => { const s = [...a].sort((x, y) => x - y); return s[Math.floor(s.length / 2)]; };
for (const k of Object.keys(by).sort()) { const v = by[k]; console.log(k, 'runs', v.length, v[0].vp, '| p10', med(v.map((x) => x.p10)).toFixed(2), '| p50', med(v.map((x) => x.p50)).toFixed(2), 'range', Math.min(...v.map((x) => x.p50)), Math.max(...v.map((x) => x.p50)), '| mean', med(v.map((x) => x.mean)).toFixed(2), '| p95', med(v.map((x) => x.p95)).toFixed(1)); }
for (const k of Object.keys(by).filter((x) => x !== 'A').sort()) {
  const d = [], e = [], m = [];
  for (const a of by.A || []) { const b = by[k].find((x) => x.r === a.r); if (b) { d.push(+(b.p50 - a.p50).toFixed(2)); e.push(+(b.p10 - a.p10).toFixed(2)); m.push(+(b.mean - a.mean).toFixed(2)); } }
  console.log(k, 'paired B-A per round: p50', d.join(' '), '-> median', med(d), '| p10 median', med(e), '| mean median', med(m));
}
