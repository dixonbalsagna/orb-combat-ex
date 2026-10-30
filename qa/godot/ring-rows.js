#!/usr/bin/env node
// The ring rows of a gen 2 read with 95% bootstrap intervals over matches (docs/qa/cloud-reports/2026-10-30-gen2-reread.md): structures on the ring,
// structures levelled a minute at tiers 1 to 4, journeys over 4,000 units, bounces a bounced journey, and each launch kind's share of the planner's launches.
//   node qa/godot/ring-rows.js <label>=<records.json> [<label>=<records.json> ...] [--boot=2000] [--kind=PROP SMASH]
// The rows are bands.js's own formulas (5c.long, 5c.bounces, 15.str.t1 to t4); the bootstrap is seeded, so a table is the same every time.
const fs = require('fs');

const args = process.argv.slice(2), opt = (k, d) => { const a = args.find(x => x.startsWith('--' + k + '=')); return a ? a.slice(k.length + 3) : d; };
const B = parseInt(opt('boot', '2000'), 10), KIND = opt('kind', 'PROP SMASH');
const sum = a => a.reduce((x, y) => x + y, 0);
const rng = s => () => { s |= 0; s = (s + 0x6D2B79F5) | 0; let t = Math.imul(s ^ (s >>> 15), 1 | s); t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t; return ((t ^ (t >>> 14)) >>> 0) / 4294967296; };

function perTier(D, tier) {
  let lost = 0, secs = 0, n = 0;
  for (const r of D) {
    const t = r.strTimeline; n += r.nStructs;
    for (let k = 1; k < t.length; k++) if (t[k][2] === tier) { secs += t[k][0] - t[k - 1][0]; lost += t[k][1] - t[k - 1][1]; }
  }
  return secs ? (lost / (n / D.length)) / (secs / 60) * 100 : NaN;
}
const J = (D, f) => sum(D.map(r => r.journeys[f]));
const launches = D => sum(D.map(r => sum(Object.values(r.launches))));
const base = k => k.replace(/ \(earned.*$/, '');   // a launch is keyed by its kind and, when earned, how ("UPPERCUT (earned: the turn)")
const kindN = (r, kind) => sum(Object.entries(r.launches).filter(([k]) => base(k) === kind).map(([, n]) => n));
const ROWS = [
  ['Structures on the ring, mean', D => sum(D.map(r => r.nStructs)) / D.length, 1],
  ['Structures levelled a minute, tier 1 (at most 2%)', D => perTier(D, 1), 2],
  ['Structures levelled a minute, tier 2 (at most 4%)', D => perTier(D, 2), 2],
  ['Structures levelled a minute, tier 3 (2 to 10%)', D => perTier(D, 3), 2],
  ['Structures levelled a minute, tier 4 (6 to 20%)', D => perTier(D, 4), 2],
  ['Journeys over 4,000 units (at most 20%)', D => 100 * J(D, 'long') / J(D, 'jn'), 1],
  ['Bounces a bounced journey (1.2 to 2.0)', D => J(D, 'jbounces') / J(D, 'jbounced'), 2],
  [`${KIND}: share of the planner's launches (%)`, D => 100 * sum(D.map(r => kindN(r, KIND))) / launches(D), 2],
  [`${KIND}: matches with at least one (%)`, D => 100 * D.filter(r => kindN(r, KIND) > 0).length / D.length, 1],
];

const arms = args.filter(a => !a.startsWith('--')).map(a => { const i = a.indexOf('='); return [a.slice(0, i), JSON.parse(fs.readFileSync(a.slice(i + 1), 'utf8'))]; });
const fmt = (x, d) => (Number.isFinite(x) ? x.toFixed(d) : 'n/a');
console.log('| Row | ' + arms.map(a => `${a[0]} (${a[1].length})`).join(' | ') + ' |');
console.log('| :--- | ' + arms.map(() => ':---').join(' | ') + ' |');
for (const [name, f, d] of ROWS) {
  const cells = arms.map(([, D]) => {
    const v = f(D), r = rng(20261030), bs = [];
    for (let b = 0; b < B; b++) { const S = []; for (let i = 0; i < D.length; i++) S.push(D[Math.floor(r() * D.length)]); const x = f(S); if (Number.isFinite(x)) bs.push(x); }
    bs.sort((x, y) => x - y);
    return bs.length ? `${fmt(v, d)} (${fmt(bs[Math.floor(0.025 * bs.length)], d)} to ${fmt(bs[Math.floor(0.975 * bs.length)], d)})` : fmt(v, d);
  });
  console.log(`| ${name} | ${cells.join(' | ')} |`);
}
// the kinds the planner picked, over all matches of each arm
for (const [label, D] of arms) {
  const t = {}; for (const r of D) for (const [k, n] of Object.entries(r.launches)) t[base(k)] = (t[base(k)] || 0) + n;
  const tot = sum(Object.values(t));
  console.log(`\n${label}: planner launches ${tot} (${(tot / D.length).toFixed(1)} a match): ` + Object.entries(t).sort((a, b) => b[1] - a[1]).map(([k, n]) => `${k} ${(100 * n / tot).toFixed(1)}%`).join(', '));
}
