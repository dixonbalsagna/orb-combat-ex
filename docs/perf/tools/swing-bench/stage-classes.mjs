// Classes the ticks over a limit of stage_bench2.gd runs (see stage-report.mjs) and prints a markdown table of the ticks and the totals per class.
//   node stage-classes.mjs <dir of json> [limit us = 16000]
// A tick's cause comes from the process that had the minimum time at that tick (its stage times and DirSwing.pm marks). Classes:
//   surf    the first surface lookup of a rematch: WorldContact._buildSurf (Bs_total, or Bi_look/the fighter stage with a rematch's 50 to 90 ms)
//   launch  a launch tick: DirMelee.launchBeat -> DirLaunch.chooseLaunch (predictFlight, building aims, biome candidates, DirSwing.scored)
//   water+n WorldWater.step's flow window on a tick that built new lattice nodes
//   water   WorldWater.step's flow window with no new lattice node (the window's columns read through SimField.col)
//   other   anything else, named by its biggest stage
import { readdirSync, readFileSync } from 'node:fs';
const dir = process.argv[2];
const limit = Number(process.argv[3] || 16000);
const cases = new Map();
for (const f of readdirSync(dir).filter((x) => x.endsWith('.json'))) {
  const m = /^(p(\d+)s(\d+)(on|off))\.r(\d+)\.json$/.exec(f);
  if (!m) continue;
  if (!cases.has(m[1])) cases.set(m[1], { planet: +m[2], seed: +m[3], swing: m[4], runs: [] });
  cases.get(m[1]).runs.push(JSON.parse(readFileSync(`${dir}/${f}`, 'utf8')));
}
const rows = [];
for (const [name, c] of [...cases].sort()) {
  for (let rep = 0; rep < c.runs[0].reps.length; rep++) {
    const n = c.runs[0].ticks;
    for (let t = 0; t < n; t++) {
      let best = null;
      for (const r of c.runs) if (!best || r.reps[rep].us[t] < best.reps[rep].us[t]) best = r;
      const us = best.reps[rep].us[t];
      if (us <= limit) continue;
      const d = best.reps[rep].det[String(t)] || { stg: {}, pm: {} };
      const nodes = best.reps[rep].nodes[t];
      const stg = Object.entries(d.stg).sort((a, b) => b[1] - a[1]);
      const top = stg[0] ? stg[0][0] : '?';
      let cls = 'other', why = top;
      const pm = d.pm || {};
      if ((pm.Bi_look || 0) > 20000 || (top === 'fighter' && rep === 1 && us > 40000)) { cls = 'surf'; why = 'WorldContact._buildSurf'; }
      else if (top === 'dirUpdate' && pm.m_choose) {
        cls = 'launch';
        const parts = [['predictFlight', pm.predict || 0], ['building aims (L2_brunt)', pm.L2_brunt || 0], ['biome candidates (L4_biome)', pm.L4_biome || 0], ['DirSwing.scored', pm.s_scored || 0]].sort((a, b) => b[1] - a[1]);
        why = `${parts[0][0]} ${(parts[0][1] / 1000).toFixed(1)}, ${parts[1][0]} ${(parts[1][1] / 1000).toFixed(1)}`;
      } else if (top === 'water') { cls = nodes > 0 ? 'water+n' : 'water'; why = `WorldWater.step${nodes > 0 ? ', ' + nodes + ' new lattice nodes' : ''}`; }
      rows.push({ case: `${c.planet}/${c.seed}/${c.swing}`, match: rep === 0 ? 'first' : 'rematch', tick: t, ms: us / 1000, cls, why, nodes, stg: top, tags: (d.tags || []).slice(0, 2).join(' ') });
    }
  }
}
const sum = {};
for (const r of rows) { const k = `${r.match} ${r.cls}`; sum[k] = sum[k] || { n: 0, over: 0, max: 0 }; sum[k].n++; sum[k].over += r.ms - limit / 1000; sum[k].max = Math.max(sum[k].max, r.ms); }
console.log('| match | class | ticks over | ms over the limit, summed | worst ms |\n|---|---|---|---|---|');
for (const [k, v] of Object.entries(sum).sort()) console.log(`| ${k.split(' ')[0]} | ${k.split(' ')[1]} | ${v.n} | ${v.over.toFixed(0)} | ${v.max.toFixed(0)} |`);
if (process.argv.includes('--rows')) { console.log(''); for (const r of rows) console.log(`| ${r.case} | ${r.match} | ${r.tick} | ${r.ms.toFixed(1)} | ${r.cls} | ${r.why} |`); }
