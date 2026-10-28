#!/usr/bin/env node
// Two or more arms of records side by side, each row with a 95% bootstrap interval over matches (docs/qa/cloud-reports/2026-10-28-gen2-baseline.md).
//   node qa/godot/compare-arms.js <label>=<records.json> [<label>=<records.json> ...] [--boot=2000] [--md=<file>] [--by-ring]
// The rows are the whole-match rows of the gen 1 reads (bands.js computes the same point values; this adds the intervals): match length
// median, p10 and p90; rallies a match and full launches (L16); links a rally (median) and turns; collateral (civilians and structures lost).
// --by-ring adds, for records that carry `ring` (QA_PLANET runs), the length and collateral split by planet and by sea share.
// The bootstrap is seeded, so a table is the same every time it is made from the same records.
const fs = require('fs');
const { median, q } = require('./bands');

const args = process.argv.slice(2), opt = (k, d) => { const a = args.find(x => x.startsWith('--' + k + '=')); return a ? a.slice(k.length + 3) : d; };
const sum = a => a.reduce((x, y) => x + y, 0), mean = a => (a.length ? sum(a) / a.length : NaN);

// A rally's links (bands.js rally.links: the last hands' links plus the turns, or every link without the turns' sends plus the turns).
const links = e => e[1] + (e[5] == null ? e[0] : e[5]);
const ends = D => D.flatMap(r => (r.rally && r.rally.ends) || []);
const fullLaunches = D => { const rallyOn = D.some(r => r.rally && r.rally.has && r.pow && r.pow.fullOpen); return mean(D.map(r => (!(r.pow && r.pow.has) ? 0 : rallyOn ? r.pow.fullOpen[0] + r.pow.fullOpen[1] : r.pow.full[0] + r.pow.full[1]))); };
const structShare = r => { const v = Object.values(r.rows || {}); const n = sum(v.map(x => x.n)); return n ? sum(v.map(x => x.lost)) / n : NaN; };

const ROWS = [
  ['Match length, median (s; 360 to 480)', D => median(D.map(r => r.koAt)), 1],
  ['Match length, p10 (s; at least 300)', D => q(D.map(r => r.koAt), 0.1), 1],
  ['Match length, p90 (s; at most 600)', D => q(D.map(r => r.koAt), 0.9), 1],
  ['Rallies a match (3 to 10)', D => ends(D).length / D.length, 2],
  ['Full launches a match, L16 (6 to 12)', fullLaunches, 2],
  ['Links a rally, median (2 to 4)', D => median(ends(D).map(links)), 1],
  ['Links a rally, mean', D => mean(ends(D).map(links)), 2],
  ['Rallies that turn (%; 15 to 40)', D => { const e = ends(D); return (100 * e.filter(x => x[1] >= 1).length) / e.length; }, 1],
  ['Civilians lost at the KO, mean (%; 12 to 30)', D => mean(D.map(r => r.civPct)), 1],
  ['Structures lost at the KO, mean share (%)', D => 100 * mean(D.map(structShare).filter(Number.isFinite)), 1],
  ['Structures on the ring, mean', D => mean(D.map(r => r.nStructs)), 1],
  ['Population at the start, mean', D => mean(D.map(r => r.pop0)), 0]
];

// mulberry32: a seeded generator for the resamples
function rng(seed) { let a = seed >>> 0; return () => { a = (a + 0x6d2b79f5) >>> 0; let t = a; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }; }
function boot(D, f, B, seed = 1) {
  const r = rng(seed), vals = [];
  for (let b = 0; b < B; b++) { const S = new Array(D.length); for (let i = 0; i < D.length; i++) S[i] = D[Math.floor(r() * D.length)]; const v = f(S); if (Number.isFinite(v)) vals.push(v); }
  vals.sort((x, y) => x - y);
  return [vals[Math.floor(0.025 * vals.length)], vals[Math.min(vals.length - 1, Math.floor(0.975 * vals.length))]];
}

function table(arms, B) {
  const L = ['| Row | ' + arms.map(a => `${a.label} (${a.D.length})`).join(' | ') + ' |', '| :--- |' + arms.map(() => ' :--- |').join('')];
  for (const [what, f, dp] of ROWS) {
    const cells = arms.map(a => { const v = f(a.D); if (!Number.isFinite(v)) return 'n/a'; const [lo, hi] = boot(a.D, f, B); return `${v.toFixed(dp)} (${lo.toFixed(dp)} to ${hi.toFixed(dp)})`; });
    L.push(`| ${what} | ${cells.join(' | ')} |`);
  }
  return L.join('\n');
}

// The length and collateral by planet and by the ring's sea share, for records that carry `ring`.
function byRing(a) {
  const R = a.D.filter(r => r.ring);
  if (!R.length) return '';
  const groups = (key, name) => {
    const g = {};
    for (const r of R) (g[key(r)] = g[key(r)] || []).push(r);
    const L = [`| ${name} | Matches | Median (s) | p10 (s) | Civilians lost (%) | Structures on the ring | Structures lost (%) | Sea share | Rallies a match |`, '| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |'];
    for (const k of Object.keys(g).sort((x, y) => (isNaN(x) ? x.localeCompare(y) : x - y))) {
      const D = g[k];
      L.push(`| ${k} | ${D.length} | ${median(D.map(r => r.koAt)).toFixed(1)} | ${q(D.map(r => r.koAt), 0.1).toFixed(1)} | ${mean(D.map(r => r.civPct)).toFixed(1)} | ${mean(D.map(r => r.nStructs)).toFixed(1)} | ${(100 * mean(D.map(structShare).filter(Number.isFinite))).toFixed(1)} | ${mean(D.map(r => r.ring.sea)).toFixed(2)} | ${(ends(D).length / D.length).toFixed(2)} |`);
    }
    return L.join('\n');
  };
  const seaBand = r => (r.ring.sea < 0.2 ? 'a. sea under 20%' : r.ring.sea < 0.4 ? 'b. sea 20 to 40%' : r.ring.sea < 0.6 ? 'c. sea 40 to 60%' : 'd. sea 60% or more');
  return `### ${a.label}: by planet\n\n${groups(r => String(r.ring.planet), 'Planet')}\n\n### ${a.label}: by touch\n\n${groups(r => String(r.ring.touch), 'Touch')}\n\n### ${a.label}: by the ring's sea share\n\n${groups(seaBand, 'Sea share')}\n`;
}

if (require.main === module) {
  const arms = args.filter(x => !x.startsWith('--')).map(x => { const i = x.indexOf('='); return { label: x.slice(0, i), D: JSON.parse(fs.readFileSync(x.slice(i + 1), 'utf8')) }; });
  if (!arms.length) { console.error('usage: node qa/godot/compare-arms.js <label>=<records.json> ... [--boot=2000] [--md=<file>] [--by-ring]'); process.exit(2); }
  let out = table(arms, parseInt(opt('boot', '2000'), 10)) + '\n';
  if (args.includes('--by-ring')) for (const a of arms) out += '\n' + byRing(a);
  if (opt('md', '')) fs.writeFileSync(opt('md'), out);
  console.log(out);
}
module.exports = { table, byRing, ROWS };
