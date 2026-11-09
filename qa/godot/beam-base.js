// The beam baseline (EP brief 2026-11-08, for Orb's beam overhaul): every beam fired in a set of records, with its range at the fire, the height difference, whether it was answered and the time from fire to outcome.
//   node qa/godot/beam-base.js label=records.json [label=records.json ...] > table.md
// Records come from qa/godot/records.gd (rec.beamGeo: see _qa_tick there) on a whole-ring planet with the energy model on and travel 1.5. A beam row: a (shooter slot), ai (the shooter is the computer), rng (true distance at the fire),
// dy (target minus shooter), wide (fired wide of him), win (ticks hand to arrival), out (outcome kind or STRUGGLE or ""), ot/t (outcome tick and fire tick), td/ta (tiers).
// ANSWERED = the target's answer decided it: DODGE, DEFLECT, GUARD, CLASH, STRUGGLE (a late answer started a struggle). HIT = no answer took it. ESCAPE (the escape gamble) is listed apart. WIDE beams were fired wide of him and
// have no outcome. A beam with no outcome and not wide was cut off (the match ended, or the exchange was lost) and is listed as "none".
const fs = require('fs');
const q = (a, p) => { if (!a.length) return NaN; const b = [...a].sort((x, y) => x - y); const i = (b.length - 1) * p, lo = Math.floor(i), hi = Math.ceil(i); return b[lo] + (b[hi] - b[lo]) * (i - lo); };
const f0 = (v, d = 0) => (Number.isFinite(v) ? v.toFixed(d) : 'n/a');
const pct = (n, d) => (d ? (100 * n / d).toFixed(1) + '%' : 'n/a');
const cols = process.argv.slice(2).map(s => { const k = s.indexOf('='); const d = JSON.parse(fs.readFileSync(s.slice(k + 1), 'utf8')); return { name: s.slice(0, k), recs: Array.isArray(d) ? d : d.records }; });
const out = [];
const ANS = new Set(['DODGE', 'DEFLECT', 'GUARD', 'CLASH', 'STRUGGLE']);
const bucket = r => (r < 500 ? '0 to 500' : r < 2000 ? '500 to 2,000' : r < 5000 ? '2,000 to 5,000' : '5,000 and over');
const BUCKETS = ['0 to 500', '500 to 2,000', '2,000 to 5,000', '5,000 and over'];
for (const c of cols) {
  const B = []; for (const r of c.recs) for (const b of (r.beamGeo || [])) B.push(b);
  const n = c.recs.length;
  out.push(`### ${c.name}: ${n} matches, ${B.length} beams fired (${(B.length / Math.max(1, n)).toFixed(2)} a match)`, '');
  const split = [['all shooters', B], ['the computer shooting', B.filter(b => b.ai)], ['a scripted human shooting', B.filter(b => !b.ai)]];
  out.push('| Shooter | Beams | Range at the fire: median (p10 to p90) | Over 2,000 | Over 5,000 | Height difference, absolute: median (p90) | Over 1,000 | Fired wide | Hit | Answered | Escape | None | Fire to outcome, ticks: median (p10 to p90, max), hits |');
  out.push('| :--- | ---: | :--- | ---: | ---: | :--- | ---: | ---: | ---: | ---: | ---: | ---: | :--- |');
  for (const [label, S] of split) {
    if (!S.length) { out.push(`| ${label} | 0 | | | | | | | | | | | |`); continue; }
    const aimed = S.filter(b => !b.wide), res = aimed.filter(b => b.out !== '');
    const hits = res.filter(b => b.out === 'HIT'), ans = res.filter(b => ANS.has(b.out)), esc = res.filter(b => b.out === 'ESCAPE');
    const ft = hits.filter(b => b.ot >= 0).map(b => b.ot - b.t);
    out.push(`| ${label} | ${S.length} | ${f0(q(S.map(b => b.rng), 0.5))} (${f0(q(S.map(b => b.rng), 0.1))} to ${f0(q(S.map(b => b.rng), 0.9))}) | ${pct(S.filter(b => b.rng > 2000).length, S.length)} | ${pct(S.filter(b => b.rng > 5000).length, S.length)} | ${f0(q(S.map(b => Math.abs(b.dy)), 0.5))} (${f0(q(S.map(b => Math.abs(b.dy)), 0.9))}) | ${pct(S.filter(b => Math.abs(b.dy) > 1000).length, S.length)} | ${pct(S.filter(b => b.wide).length, S.length)} | ${pct(hits.length, aimed.length)} | ${pct(ans.length, aimed.length)} | ${pct(esc.length, aimed.length)} | ${pct(aimed.length - res.length, aimed.length)} | ${ft.length ? `${f0(q(ft, 0.5))} (${f0(q(ft, 0.1))} to ${f0(q(ft, 0.9))}, ${f0(Math.max(...ft))})` : 'n/a'} |`);
  }
  out.push('', 'Shares of the beams fired at him (not wide) in each row. Answered = dodge, deflect, guard, clash, struggle; none = no outcome seen.', '');
  out.push('By range at the fire (all shooters, beams fired at him):', '', '| Range | Beams | Hit | Answered | Escape | None | Median ticks fire to outcome, hits | Median window ticks (hand to arrival) |', '| :--- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |');
  for (const bk of BUCKETS) {
    const S = B.filter(b => !b.wide && bucket(b.rng) === bk);
    if (!S.length) { out.push(`| ${bk} | 0 | | | | | | |`); continue; }
    const res = S.filter(b => b.out !== ''), hits = res.filter(b => b.out === 'HIT');
    out.push(`| ${bk} | ${S.length} | ${pct(hits.length, S.length)} | ${pct(res.filter(b => ANS.has(b.out)).length, S.length)} | ${pct(res.filter(b => b.out === 'ESCAPE').length, S.length)} | ${pct(S.length - res.length, S.length)} | ${f0(q(hits.filter(b => b.ot >= 0).map(b => b.ot - b.t), 0.5))} | ${f0(q(S.filter(b => b.win >= 0).map(b => b.win), 0.5))} |`);
  }
  const kinds = {}; for (const b of B.filter(b => !b.wide)) kinds[b.out || 'none'] = (kinds[b.out || 'none'] || 0) + 1;
  out.push('', 'Outcome counts (beams fired at him): ' + Object.entries(kinds).sort((a, b) => b[1] - a[1]).map(([k, v]) => `${k} ${v}`).join(', '));
  const hv = B.filter(b => !b.wide && b.out === 'HIT');
  out.push(`Hits from over 5,000 units: ${hv.filter(b => b.rng > 5000).length} of ${hv.length}; hits with a height difference over 1,000: ${hv.filter(b => Math.abs(b.dy) > 1000).length}; hits on a target in the air or hit-stopped state: ${hv.filter(b => /launched|dropped|down/.test(b.dstate)).length}.`, '');
}
console.log(out.join('\n'));
