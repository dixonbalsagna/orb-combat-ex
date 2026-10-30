#!/usr/bin/env node
// Which launch candidate is over-represented in the shortest matches (docs/qa/cloud-reports/2026-10-30-lake-floor.md; GD 10-30 row 4: "the autopsy of the shortest 20 names the candidate first").
//   node qa/godot/short-launches.js <records.json> [N=20] [--label=<name>]
// The N shortest matches against the rest: launches a match and a minute by kind (an "(earned: ...)" suffix folds into its kind), each kind's count a minute in the short set over the rest
// (a ratio over 1 means more of it in the short matches), the planets and touches the short matches were played on, and the damage a second and the ticks to tier 3 and 4.
const fs = require('fs');
const args = process.argv.slice(2), N = parseInt(args.find(a => /^\d+$/.test(a)) || '20', 10), label = (args.find(a => a.startsWith('--label=')) || '--label=').slice(8);
const recs = JSON.parse(fs.readFileSync(args.find(a => !a.startsWith('--') && !/^\d+$/.test(a)), 'utf8'));
const sum = a => a.reduce((x, y) => x + y, 0), mean = a => (a.length ? sum(a) / a.length : NaN);
const base = k => k.replace(/ \(earned.*$/, '');
const s = recs.slice().sort((a, b) => a.koAt - b.koAt), short = s.slice(0, N), rest = s.slice(N);
const mins = G => sum(G.map(r => r.koAt)) / 60;
const kinds = G => { const t = {}; for (const r of G) for (const [k, n] of Object.entries(r.launches)) t[base(k)] = (t[base(k)] || 0) + n; return t; };
const ks = kinds(short), kr = kinds(rest);
console.log(`${label} ${recs.length} matches; the ${N} shortest run ${short[0].koAt.toFixed(0)} to ${short[N - 1].koAt.toFixed(0)} s (median ${short[N >> 1].koAt.toFixed(0)}); the rest ${rest[0].koAt.toFixed(0)} to ${rest[rest.length - 1].koAt.toFixed(0)} s`);
const per = (G, k, t) => (t[k] || 0) / mins(G);
const rows = [...new Set([...Object.keys(ks), ...Object.keys(kr)])].map(k => ({ k, a: per(short, k, ks), b: per(rest, k, kr), ns: ks[k] || 0, nr: kr[k] || 0 })).sort((x, y) => (y.a - y.b) - (x.a - x.b));
console.log('| Launch kind | short: count (a minute) | rest: count (a minute) | ratio |\n| :--- | :--- | :--- | :--- |');
for (const r of rows) console.log(`| ${r.k} | ${r.ns} (${r.a.toFixed(2)}) | ${r.nr} (${r.b.toFixed(2)}) | ${r.b > 0 ? (r.a / r.b).toFixed(2) : 'n/a'} |`);
const lm = G => sum(G.map(r => sum(Object.values(r.launches)))) / mins(G);
console.log(`\nLaunches a minute: short ${lm(short).toFixed(2)}, rest ${lm(rest).toFixed(2)}`);
const dps = G => sum(G.map(r => sum(r.dmgVictim))) / sum(G.map(r => r.koAt));
console.log(`Damage a second (both fighters): short ${dps(short).toFixed(1)}, rest ${dps(rest).toFixed(1)}`);
const tierAt = (G, t) => { const v = G.map(r => (r.tierT || [])[t]).filter(x => Number.isFinite(x) && x >= 0); return `${v.length} of ${G.length}, mean ${mean(v).toFixed(0)} s`; };
console.log(`Tier 3 reached: short ${tierAt(short, 3)}; rest ${tierAt(rest, 3)}`);
const where = G => { const c = {}; for (const r of G) { const k = r.ring ? `p${r.ring.planet}/t${r.ring.touch}` : '?'; c[k] = (c[k] || 0) + 1; } return Object.entries(c).sort((a, b) => b[1] - a[1]).map(([k, n]) => `${k} x${n}`).join(', '); };
console.log(`Planet/touch of the short ${N}: ${where(short)}`);
console.log(`Seeds of the short ${N}: ${short.map(r => r.seed).join(' ')}`);
const w = G => { const c = [0, 0]; for (const r of G) if (r.winner >= 0) c[r.winner]++; return c.join(' to '); };
console.log(`Winners (slot 1 to slot 2): short ${w(short)}, rest ${w(rest)}`);
