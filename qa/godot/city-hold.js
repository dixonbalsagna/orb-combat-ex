// The cityHold city read (EP 2026-11-20; Encounter's cityHold fix for Orb's "ping-pong" bug, World's wall-hold row, Encounter's wall-hold-air): seeded AI-v-AI city matches with cityHold off against on.
//   node qa/godot/city-hold.js off=records.json on=records.json > table.md
// Records come from qa/godot/records.gd (rec.cityHits: one row a body that struck a building; see _qa_tick). Per arm:
//   buildings fallen (rec.structs); building hits by outcome; THROWN BACK: the body's vx flipped against its way, at 10% of its speed or more, within 40 ticks of the hit (the ricochet; an estimate from the body's velocity one tick before the hit);
//   FROZEN: the longest fight freeze (a held clock: hit-stop ticks, or S.pause.left above 0) within 40 ticks of the hit, in ticks; HOME: ticks until the body's depth was within a tenth of the depth it was hit at (300 at most), and the share of hits where he was still in the air when he got home;
//   match length (median, p10, p90, bootstrap 95%); bystanders: the highest casualty share a match reached (rec.casTimeline rows are [second, share, tier]) and civPct and evacuations (rec.fxCounts.evacuate). Rates carry Wilson 95% intervals, means and medians a bootstrap.
const fs = require('fs');
const z = 1.96;
const wil = (k, n) => { if (!n) return [NaN, NaN]; const p = k / n, d = 1 + z * z / n, c = p + z * z / (2 * n), r = z * Math.sqrt(p * (1 - p) / n + z * z / (4 * n * n)); return [100 * (c - r) / d, 100 * (c + r) / d]; };
const q = (a, p) => { if (!a.length) return NaN; const b = [...a].sort((x, y) => x - y); const i = (b.length - 1) * p, lo = Math.floor(i), hi = Math.ceil(i); return b[lo] + (b[hi] - b[lo]) * (i - lo); };
let seed = 4242; const rnd = () => { seed = (seed * 1664525 + 1013904223) >>> 0; return seed / 4294967296; };
const boot = (a, f, n = 2000) => { if (a.length < 2) return [NaN, NaN]; const v = []; for (let i = 0; i < n; i++) { const s = []; for (let j = 0; j < a.length; j++) s.push(a[Math.floor(rnd() * a.length)]); v.push(f(s)); } return [q(v, 0.025), q(v, 0.975)]; };
const mean = a => a.reduce((x, y) => x + y, 0) / Math.max(1, a.length);
const ci = (a, f, d = 1) => { const [lo, hi] = boot(a, f); return `${f(a).toFixed(d)} (${lo.toFixed(d)} to ${hi.toFixed(d)})`; };
const cols = process.argv.slice(2).map(s => { const k = s.indexOf('='); const d = JSON.parse(fs.readFileSync(s.slice(k + 1), 'utf8')); return { name: s.slice(0, k), recs: Array.isArray(d) ? d : d.records }; });
const rows = [];
const row = (label, f) => rows.push([label, ...cols.map(c => { try { return f(c.recs); } catch (e) { return 'n/a'; } })]);
const hits = R => R.flatMap(r => r.cityHits || []);
const pct = (k, n) => `${(100 * k / Math.max(1, n)).toFixed(1)}% (${wil(k, n).map(x => x.toFixed(1)).join(' to ')}), ${k} of ${n}`;
row('matches', R => String(R.length));
row('match length median, s (95% interval)', R => ci(R.map(r => (r.koAt >= 0 ? r.koAt : 900)), a => q(a, 0.5), 0));
row('match length p10 / p90, s', R => { const a = R.map(r => (r.koAt >= 0 ? r.koAt : 900)); return `${q(a, 0.1).toFixed(0)} / ${q(a, 0.9).toFixed(0)}`; });
row('buildings fallen a match, mean (95% interval)', R => ci(R.map(r => r.structs || 0), mean, 1));
row('building hits a match, mean (95% interval)', R => ci(R.map(r => (r.cityHits || []).length), mean, 1));
row('building hits by outcome', R => { const o = {}; for (const h of hits(R)) o[h.out] = (o[h.out] || 0) + 1; return Object.entries(o).sort((a, b) => b[1] - a[1]).map(([k, v]) => `${k} ${v}`).join(', '); });
row('hits where the body was THROWN BACK (vx flipped)', R => { const H = hits(R).filter(h => Math.abs(h.pvx) > 1); return pct(H.filter(h => h.bounced).length, H.length); });
row('... throw-backs a match, mean (95% interval)', R => ci(R.map(r => (r.cityHits || []).filter(h => h.bounced).length), mean, 2));
row('hits followed by a fight freeze of 10 ticks or more', R => { const H = hits(R); return pct(H.filter(h => h.pauseMax >= 10).length, H.length); });
row('... longest freeze after a hit, ticks (p50 / p90 / max)', R => { const a = hits(R).map(h => h.pauseMax); return `${q(a, 0.5).toFixed(0)} / ${q(a, 0.9).toFixed(0)} / ${Math.max(0, ...a)}`; });
row('depth home in the air (still launched when home)', R => { const H = hits(R).filter(h => h.homeTicks >= 0 && Math.abs(h.z) > 100); return pct(H.filter(h => h.homeAir).length, H.length); });
row('... ticks until the depth was home (p50 / p90; hits at 100 or more off the line)', R => { const a = hits(R).filter(h => Math.abs(h.z) > 100).map(h => (h.homeTicks >= 0 ? h.homeTicks : 300)); return `${q(a, 0.5).toFixed(0)} / ${q(a, 0.9).toFixed(0)} (${a.length} hits)`; });
row('people lost: the highest casualty share any second of a match reached (rec.casTimeline, share of all the people); matches where it was above 0', R => { const m = R.map(r => Math.max(0, ...(r.casTimeline || []).map(x => x[1]))); return `${Math.max(0, ...m)}; ${m.filter(x => x > 0).length} of ${R.length}`; });
row('civilians lost, mean % of the people in the places reached or the old figure', R => mean(R.map(r => (Number.isFinite(r.reachedPct) ? r.reachedPct : r.civPct) || 0)).toFixed(2) + '%');
row('evacuation events a match (bystanders scattering), mean', R => mean(R.map(r => ((r.fxCounts || {}).evacuate || 0))).toFixed(1));
const L = ['| Measure | ' + cols.map(c => c.name).join(' | ') + ' |', '| :--- |' + cols.map(() => ' :--- |').join('')];
for (const r of rows) L.push('| ' + r.join(' | ') + ' |');
console.log(L.join('\n'));
