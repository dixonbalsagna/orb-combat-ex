// VFX's aura fixtures (Legal fx06 condition 3: the closed schema rejects a 2.5 Hz rate and an alpha of 0.6; the burst's gap and hold have bounds), from docs/vfx/pending/aura3d/fixtures.json, into
// tools/fixtures/cases.json, inserted before the last case like Tools' other additions. They need the aura3d park's data and schemas, so this refuses until data/vfx/aura3d.json is in the tree
// (run it in the commit that lands that park):
//     node docs/tools/pending/apply-aura-fixtures.cjs
// Re-runnable: a case with the same id is replaced, never doubled. Not run by CI or the validator.
const fs = require('fs');
const F = 'tools/fixtures/cases.json';
if (!fs.existsSync('data/vfx/aura3d.json')) { console.error('data/vfx/aura3d.json is not in the tree yet: run this in the commit that lands the aura3d park'); process.exit(1); }
const CASES = [
  {"id":"vfx-aura3d-live-valid","schema":"vfx-aura3d.schema.json","mutate":[{"file":"data/vfx/aura3d.json","set":{"/version":1}}],"expect":null},
  {"id":"vfx-aura3d-pulse-hz-2.5-rejected","schema":"vfx-aura3d.schema.json","mutate":[{"file":"data/vfx/aura3d.json","set":{"/themes/protagonist/pulse_hz":2.5}}],"expect":{"rule":"maximum","pointer":"/themes/protagonist/pulse_hz"}},
  {"id":"vfx-aura3d-cell-rate-2.5-rejected","schema":"vfx-aura3d.schema.json","mutate":[{"file":"data/vfx/aura3d.json","set":{"/themes/rival/cell_rate":2.5}}],"expect":{"rule":"maximum","pointer":"/themes/rival/cell_rate"}},
  {"id":"vfx-aura3d-alpha-max-0.6-rejected","schema":"vfx-aura3d.schema.json","mutate":[{"file":"data/vfx/aura3d.json","set":{"/common/alpha_max":0.6}}],"expect":{"rule":"maximum","pointer":"/common/alpha_max"}},
  {"id":"vfx-aura-burst-gap-too-short-rejected","schema":"vfx-aura.schema.json","mutate":[{"file":"data/vfx/aura.json","set":{"/standing/burst_gap":20}}],"expect":{"rule":"minimum","pointer":"/standing/burst_gap"}},
  {"id":"vfx-aura-burst-hold-too-long-rejected","schema":"vfx-aura.schema.json","mutate":[{"file":"data/vfx/aura.json","set":{"/standing/burst_hold":400}}],"expect":{"rule":"maximum","pointer":"/standing/burst_hold"}}
];
const c = JSON.parse(fs.readFileSync(F, 'utf8'));
let n = 0;
for (const k of CASES) {
  const i = c.cases.findIndex((y) => y.id === k.id);
  if (i >= 0) { if (JSON.stringify(c.cases[i]) !== JSON.stringify(k)) { c.cases[i] = k; n++; } } else { c.cases.splice(Math.max(0, c.cases.length - 1), 0, k); n++; }
}
if (n) fs.writeFileSync(F, JSON.stringify(c, null, 2) + String.fromCharCode(10));
console.log('cases: ' + n + ' new or changed');
