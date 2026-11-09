// The close-fight control table (EP brief 2026-11-08, for Encounter): the share of each minute a fighter cannot act on a press, by state, in AI-v-AI.
//   node qa/godot/control-table.js label=records.json [label=records.json ...] > table.md
// Records come from qa/godot/records.gd (rec.ctl, rec.ctlMin: see _qa_tick there), one tick at a time, for both fighters. Categories, first that holds:
//   launched (launched or dropped), down, stunned (stunTicks above 0), exchange (in a planned exchange that is not a brawl: a signature, a beam, a finisher, a set piece), queued (a press waiting in the queue),
//   brawl (in the brawl, where the magnet holds the pair at contact and every press is a blow), free.
// CAN'T ACT on a press = launched + down + stunned + exchange + queued. The brawl and free are able to act. Shares are of all fighter-ticks (both fighters, every match tick before the KO's end). A minute is a minute of match time.
const fs = require('fs');
const f1 = v => (Number.isFinite(v) ? (100 * v).toFixed(1) + '%' : 'n/a');
const cols = process.argv.slice(2).map(s => { const k = s.indexOf('='); const d = JSON.parse(fs.readFileSync(s.slice(k + 1), 'utf8')); return { name: s.slice(0, k), recs: Array.isArray(d) ? d : d.records }; });
const CATS = ['launched', 'down', 'stunned', 'exchange', 'queued', 'brawl', 'free'];
const CANT = ['launched', 'down', 'stunned', 'exchange', 'queued'];
const out = [];
const boot = (vals, n = 1000) => { let s = 12345; const rnd = () => { s = (s * 1664525 + 1013904223) >>> 0; return s / 4294967296; }; const v = []; for (let i = 0; i < n; i++) { let a = 0, b = 0; for (let j = 0; j < vals.length; j++) { const p = vals[Math.floor(rnd() * vals.length)]; a += p[0]; b += p[1]; } v.push(a / Math.max(1, b)); } v.sort((x, y) => x - y); return [v[Math.floor(n * 0.025)], v[Math.floor(n * 0.975)]]; };
for (const c of cols) {
  const R = c.recs.filter(r => r.ctl);
  const tot = [0, 0], cat = {}; for (const k of CATS) cat[k] = [0, 0];
  const per = [];
  for (const r of R) {
    let t = 0, cant = 0;
    for (const k of CATS) { const a = r.ctl[k] || [0, 0]; cat[k][0] += a[0]; cat[k][1] += a[1]; t += a[0] + a[1]; if (CANT.includes(k)) cant += a[0] + a[1]; }
    per.push([cant, t]);
  }
  const all = CATS.reduce((s, k) => s + cat[k][0] + cat[k][1], 0);
  const cantAll = CANT.reduce((s, k) => s + cat[k][0] + cat[k][1], 0);
  const [lo, hi] = boot(per);
  out.push(`### ${c.name}: ${R.length} matches, ${(all / 2 / 3600).toFixed(1)} fighter-minutes each`, '', `**Can't act on a press: ${f1(cantAll / all)} of fighter time (95% interval ${f1(lo)} to ${f1(hi)} over matches).**`, '');
  out.push('| State | Both fighters | Slot 0 | Slot 1 | Counts as can\'t act |', '| :--- | ---: | ---: | ---: | :--- |');
  for (const k of CATS) { const s0 = cat[k][0] / (all / 2), s1 = cat[k][1] / (all / 2); out.push(`| ${k} | ${f1((cat[k][0] + cat[k][1]) / all)} | ${f1(s0)} | ${f1(s1)} | ${CANT.includes(k) ? 'yes' : 'no'} |`); }
  const mins = {}; for (const r of R) for (const [m, v] of Object.entries(r.ctlMin || {})) { const a = mins[m] || (mins[m] = { n: 0, cant: 0, matches: 0 }); a.n += v.n * 2; a.cant += v.cant0 + v.cant1; a.matches++; }
  out.push('', 'By minute of match time (share of that minute either fighter spent unable to act on a press; later minutes have fewer matches):', '', '| Minute | Matches in it | Can\'t act |', '| ---: | ---: | ---: |');
  for (const m of Object.keys(mins).map(Number).sort((a, b) => a - b)) out.push(`| ${m + 1} | ${mins[m].matches} | ${f1(mins[m].cant / mins[m].n)} |`);
  out.push('');
}
console.log(out.join('\n'));
