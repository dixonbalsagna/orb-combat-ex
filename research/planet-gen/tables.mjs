// The numbers behind the pictures, as Markdown: each biome's share of land per seed and approach, and the fight read
// (what the 4,800-column ring crosses).  node research/planet-gen/tables.mjs > docs/research/planet-gen-tables.md
import { readFileSync } from 'node:fs';
const ROOT = process.argv[2] || 'research/planet-gen';
const ORDER = [['base', 'Today (WorldPlanet)'], ['A', 'A: climate table'], ['B', 'B: plates and climate'], ['C', 'C: erosion on B'], ['Cb', 'C on A: erosion on today\'s ground']];
const SEEDS = ['7', '11', '23', '42', '101', '2026'];
const out = [];
const p = (s) => out.push(s);
p('# Planet generation: the tables');
p('');
p('Research & Prototyping, 2026-10-23. Written by `research/planet-gen/tables.mjs` from `research/planet-gen/stats/*.json`; the study is `planet-gen.md`. Shares are of the planet\'s land, area-weighted from a 1,024 x 512 equirect sample. A dash is under 0.1%.');
p('');
p('## 1. Each biome\'s share of land, per seed');
for (const [k, title] of ORDER) {
  const j = JSON.parse(readFileSync(`${ROOT}/stats/${k}.json`, 'utf8'));
  const names = new Set();
  for (const s of SEEDS) for (const [n] of j.seeds[s].map.landBiomes) names.add(n);
  const rows = [...names].map((n) => [n, SEEDS.map((s) => { const e = j.seeds[s].map.landBiomes.find((b) => b[0] === n); return e ? e[1] : 0; })]);
  rows.sort((a, b) => b[1].reduce((x, y) => x + y, 0) - a[1].reduce((x, y) => x + y, 0));
  p('');
  p(`### ${title}`);
  p('');
  p('| Biome | ' + SEEDS.map((s) => `Seed ${s}`).join(' | ') + ' |');
  p('| :--- | ' + SEEDS.map(() => '---:').join(' | ') + ' |');
  p('| **Land, % of the planet** | ' + SEEDS.map((s) => `**${j.seeds[s].map.landPct}**`).join(' | ') + ' |');
  for (const [n, v] of rows) p(`| ${n} | ` + v.map((x) => (x >= 0.1 ? x.toFixed(1) : '-')).join(' | ') + ' |');
  p('| Lakes, % of the planet | ' + SEEDS.map((s) => (j.seeds[s].map.water.Lake ? j.seeds[s].map.water.Lake : '-')).join(' | ') + ' |');
}
p('');
p('## 2. The fight read: what the 4,800-column ring crosses');
p('');
p('Each seed\'s ring is the first of 16 seeded great circles that holds half land and three biomes of 8% or more on 96 samples (WorldPlanet\'s minimum without the places); "no" means none did and the one with the most land is shown. Biomes: of the ring\'s land, those of 1% or more. Changes: columns where the biome differs from the one before. Longest: the longest single-biome stretch.');
for (const [k, title] of ORDER) {
  const j = JSON.parse(readFileSync(`${ROOT}/stats/${k}.json`, 'utf8'));
  p('');
  p(`### ${title}`);
  p('');
  p('| Seed | Ring | Met | Land % | Biomes | Changes | Coasts | Longest (units) | Mountain % | Rivers | Lakes | Heights | The ring\'s land, by share |');
  p('| ---: | ---: | :--- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | :--- | :--- |');
  for (const s of SEEDS) {
    const r = j.seeds[s].ring;
    p(`| ${s} | ${r.candidate} | ${r.metMinimum ? 'yes' : 'no'} | ${r.landPct} | ${r.distinct} | ${r.changes} | ${r.coasts} | ${r.longestUnits.toLocaleString('en-GB')} | ${r.mountainPct} | ${r.rivers} | ${r.lakes} | ${r.hMin.toLocaleString('en-GB')} to ${r.hMax.toLocaleString('en-GB')} | ${r.biomes.map(([n, v]) => `${n} ${v}`).join(', ')} |`);
  }
}
p('');
p('## 3. Cost per seed (JS, this PC)');
p('');
p('Ring: the 4,800 columns read cold (the climate memo emptied), best of 5. Today: WorldPlanet\'s function on the same ring in the same run. Set-up: the per-planet work before the first read (approach C\'s grid).');
p('');
p('| Approach | ' + SEEDS.map((s) => `Seed ${s}`).join(' | ') + ' | Median |');
p('| :--- | ' + SEEDS.map(() => '---:').join(' | ') + ' | ---: |');
for (const [k, title] of ORDER) {
  const j = JSON.parse(readFileSync(`${ROOT}/stats/${k}.json`, 'utf8'));
  const v = SEEDS.map((s) => j.seeds[s].cost.perColumnVsToday), m = [...v].sort((a, b) => a - b);
  p(`| ${title}: ring, times today | ` + v.join(' | ') + ` | ${((m[2] + m[3]) / 2).toFixed(1)} |`);
  if (k === 'C' || k === 'Cb') {
    const w = SEEDS.map((s) => Math.round(j.seeds[s].cost.initMs)), n = [...w].sort((a, b) => a - b);
    p(`| ${title}: set-up, ms | ` + w.join(' | ') + ` | ${Math.round((n[2] + n[3]) / 2)} |`);
  }
}
console.log(out.join('\n'));
