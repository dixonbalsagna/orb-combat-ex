// The civilians-removed split (Game Design 2026-11-06, docs/world/ring-any-angle/game-design.md addendum, item 3): big swings a match with the people on against the people removed, by pair, and which cause carries the gap.
//   node qa/godot/civless-pair.js label=on.json,off.json [label=on.json,off.json ...]
// A big swing is the swing rows' own: a swing_start that is not a nudge, not a jolt and more than 15 degrees. The difference is the mean over matches of (people on) minus (people removed) on the same seeds; the interval is a paired bootstrap over seeds (2,000 resamples).
// The row stands within 1 (swing.civless in swing-rows.js).
const fs = require('fs');
const sum = a => a.reduce((x, y) => x + y, 0), mean = a => (a.length ? sum(a) / a.length : NaN);
const BIG = 15;
const starts = r => (r.swings || []).filter(e => e.type === 'swing_start' && e.kind !== 'nudge');
const isJolt = e => /jolt|small/i.test(e.kind || '') || Math.abs(e.amount) <= BIG;
const big = r => starts(r).filter(e => !isJolt(e));
const cause = e => e.src || e.kind || '?';
let seed = 777;
const rnd = () => { seed = (seed * 1664525 + 1013904223) >>> 0; return seed / 4294967296; };
const q = (a, p) => { const b = [...a].sort((x, y) => x - y); const i = (b.length - 1) * p, lo = Math.floor(i), hi = Math.ceil(i); return b[lo] + (b[hi] - b[lo]) * (i - lo); };
const out = ['| Pair | Matches | Big swings on | Big swings removed | Difference (95% interval, paired) | Within 1 |', '| :--- | ---: | ---: | ---: | :--- | :--- |'];
const causes = [];
for (const arg of process.argv.slice(2)) {
  const [label, files] = arg.split('=');
  const [fa, fb] = files.split(',');
  const load = f => { const d = JSON.parse(fs.readFileSync(f, 'utf8')); return Array.isArray(d) ? d : d.records; };
  const A = load(fa), B = load(fb);
  const bySeed = new Map(B.map(r => [r.seed, r]));
  const pairs = A.filter(r => bySeed.has(r.seed)).map(r => [big(r).length, big(bySeed.get(r.seed)).length]);
  const diffs = pairs.map(([a, b]) => a - b), d = mean(diffs);
  const bs = [];
  for (let i = 0; i < 2000; i++) { let s = 0; for (let j = 0; j < diffs.length; j++) s += diffs[Math.floor(rnd() * diffs.length)]; bs.push(s / diffs.length); }
  const lo = q(bs, 0.025), hi = q(bs, 0.975);
  out.push(`| ${label} | ${pairs.length} | ${mean(pairs.map(p => p[0])).toFixed(2)} | ${mean(pairs.map(p => p[1])).toFixed(2)} | ${d >= 0 ? '+' : ''}${d.toFixed(2)} (${lo.toFixed(2)} to ${hi.toFixed(2)}) | ${Math.abs(d) <= 1 ? 'yes' : 'NO'}${lo > 1 || hi < -1 ? ' (interval wholly outside)' : ''} |`);
  const ca = {}, cb = {};
  for (const r of A) for (const e of big(r)) ca[cause(e)] = (ca[cause(e)] || 0) + 1;
  for (const r of B) for (const e of big(r)) cb[cause(e)] = (cb[cause(e)] || 0) + 1;
  const keys = [...new Set([...Object.keys(ca), ...Object.keys(cb)])].sort();
  causes.push(`${label}: by cause a match, on / removed: ` + keys.map(k => `${k} ${((ca[k] || 0) / A.length).toFixed(2)} / ${((cb[k] || 0) / B.length).toFixed(2)}`).join(', '));
}
console.log(out.join('\n') + '\n\n' + causes.join('\n'));
