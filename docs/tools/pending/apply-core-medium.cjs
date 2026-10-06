// Schema keys for Simulation's weight slice (a third strength, "medium", in the core): data/fighters/*/wounds.json gains `family.medium` (four numbers, 0 or more, in the
// file's order head, core, arms, legs; required like the family's other rows) and `penalties.armsBrokenMediumMul` (a number above 0, required, the same rule as
// armsBrokenLightMul beside it); data/fight/mood.json gains `impulses.brawlMedium` (an integer, 0 or more, required). NOT run by CI, the validator or the sim. Run once from the
// repo root, in the commit that lands Simulation's data (8, 8, 7, 9 and 1.0 in both fighters' wounds.json, 40 in mood.json):
//     node docs/tools/pending/apply-core-medium.cjs
// It does NOT edit data/. It does edit the fixture fighters and the fixture mood (tools/fixtures/virtual/), which validate under the schemas and need the new keys. The three
// form words the director may put on a hit (brawl_light, brawl_medium, brawl_heavy) are not data. Every case sets its own values. Re-runnable (a second run changes nothing).
//
// One thing to know: the request said armsBrokenMediumMul is "0 or more" and "the same rule as armsBrokenLightMul". Those differ: armsBrokenLightMul is exclusiveMinimum 0
// (a multiplier of 0 would delete a broken arm's damage). This script takes "the same rule" (above 0). If 0 is meant to be allowed, change the one `exclusiveMinimum` below
// to `minimum` and the two cases named `-zero`.
const fs = require('fs');
const rj = (f) => JSON.parse(fs.readFileSync(f, 'utf8'));
const wj = (f, o) => fs.writeFileSync(f, JSON.stringify(o, null, 2) + '\n');
const clone = (o) => JSON.parse(JSON.stringify(o));
/** o with `key: value` placed straight after `after` (the key order of the data files), or unchanged when it is already there. */
const insertAfter = (o, after, key, value) => {
  if (key in o) return o;
  const out = {};
  for (const [k, v] of Object.entries(o)) { out[k] = v; if (k === after) out[key] = value; }
  if (!(key in out)) throw new Error(`no "${after}" to put "${key}" after`);
  return out;
};

// =============================== schemas ===============================
{
  const f = 'tools/schemas/fighter-wounds.schema.json';
  const s = rj(f);
  let changed = false;
  const fam = s.properties.family;
  if (!fam.required.includes('medium')) { fam.required.splice(fam.required.indexOf('light') + 1, 0, 'medium'); changed = true; }
  const pen = s.properties.penalties;
  if (!pen.properties.armsBrokenMediumMul) {
    pen.properties = insertAfter(pen.properties, 'armsBrokenLightMul', 'armsBrokenMediumMul', Object.assign(clone(pen.properties.armsBrokenLightMul), { description: 'A broken arm\'s multiplier on a medium blow (armsBrokenLightMul is the light one). Above 0.' }));
    changed = true;
  }
  if (!pen.required.includes('armsBrokenMediumMul')) { pen.required.splice(pen.required.indexOf('armsBrokenLightMul') + 1, 0, 'armsBrokenMediumMul'); changed = true; }
  if (changed) wj(f, s);
}
{
  const f = 'tools/schemas/fight-mood.schema.json';
  const s = rj(f);
  const imp = s.properties.impulses;
  let changed = false;
  if (!imp.properties.brawlMedium) {
    imp.properties = insertAfter(imp.properties, 'brawlLight', 'brawlMedium', Object.assign(clone(imp.properties.brawlHeavy), { description: 'The mood a landed medium blow of a brawl feeds (brawlLight is the light one, brawlHeavy the heavy one).' }));
    changed = true;
  }
  if (!imp.required.includes('brawlMedium')) { imp.required.splice(imp.required.indexOf('brawlLight') + 1, 0, 'brawlMedium'); changed = true; }
  if (changed) wj(f, s);
}

// =============================== fixtures ===============================
for (const fid of ['FIXTURE_HERO', 'FIXTURE_VILLAIN']) {
  const f = `tools/fixtures/virtual/data/fighters/${fid}/wounds.json`;
  const d = rj(f);
  const before = JSON.stringify(d);
  d.family = insertAfter(d.family, 'light', 'medium', [8, 8, 7, 9]);
  d.penalties = insertAfter(d.penalties, 'armsBrokenLightMul', 'armsBrokenMediumMul', 1.0);
  if (JSON.stringify(d) !== before) wj(f, d);
}
{
  const f = 'tools/fixtures/virtual/data/fight/mood.json';
  const d = rj(f);
  const before = JSON.stringify(d);
  d.impulses = insertAfter(d.impulses, 'brawlLight', 'brawlMedium', 40);
  if (JSON.stringify(d) !== before) wj(f, d);
}

// =============================== cases ===============================
{
  const cf = 'tools/fixtures/cases.json';
  const c = rj(cf);
  const W = 'data/fighters/FIXTURE_HERO/wounds.json', M = 'data/fight/mood.json';
  const w = (id, mutate, expect) => ({ id: 'wounds-medium-' + id, schema: 'fighter-wounds.schema.json', mutate: [{ file: W, ...mutate }], expect });
  const m = (id, mutate, expect) => ({ id: 'mood-impulse-brawlMedium-' + id, schema: 'fight-mood.schema.json', mutate: [{ file: M, ...mutate }], expect });
  const add = [
    // family.medium
    w('family-valid', { set: { '/family/medium': [8, 8, 7, 9] } }, null),
    w('family-zeros-ok', { set: { '/family/medium': [0, 0, 0, 0] } }, null),
    w('family-required', { del: ['/family/medium'] }, { rule: 'required', pointer: '/family' }),
    w('family-length', { set: { '/family/medium': [1, 2, 3] } }, { rule: 'minItems', pointer: '/family/medium' }),
    w('family-five-weights', { set: { '/family/medium': [1, 2, 3, 4, 5] } }, { rule: 'maxItems', pointer: '/family/medium' }),
    w('family-negative', { set: { '/family/medium': [8, -1, 7, 9] } }, { rule: 'minimum', pointer: '/family/medium/1' }),
    w('family-item-type', { set: { '/family/medium': [8, 8, 'seven', 9] } }, { rule: 'type', pointer: '/family/medium/2' }),
    w('family-type', { set: { '/family/medium': 8 } }, { rule: 'type', pointer: '/family/medium' }),
    // penalties.armsBrokenMediumMul
    w('mul-valid', { set: { '/penalties/armsBrokenMediumMul': 1.0 } }, null),
    w('mul-below-one-ok', { set: { '/penalties/armsBrokenMediumMul': 0.5 } }, null),
    w('mul-above-one-ok', { set: { '/penalties/armsBrokenMediumMul': 1.3 } }, null),
    w('mul-required', { del: ['/penalties/armsBrokenMediumMul'] }, { rule: 'required', pointer: '/penalties' }),
    w('mul-zero', { set: { '/penalties/armsBrokenMediumMul': 0 } }, { rule: 'exclusiveMinimum', pointer: '/penalties/armsBrokenMediumMul' }),
    w('mul-negative', { set: { '/penalties/armsBrokenMediumMul': -0.5 } }, { rule: 'exclusiveMinimum', pointer: '/penalties/armsBrokenMediumMul' }),
    w('mul-type', { set: { '/penalties/armsBrokenMediumMul': '1.0' } }, { rule: 'type', pointer: '/penalties/armsBrokenMediumMul' }),
    // impulses.brawlMedium
    m('valid', { set: { '/impulses/brawlMedium': 40 } }, null),
    m('zero-ok', { set: { '/impulses/brawlMedium': 0 } }, null),
    m('required', { del: ['/impulses/brawlMedium'] }, { rule: 'required', pointer: '/impulses' }),
    m('negative', { set: { '/impulses/brawlMedium': -1 } }, { rule: 'minimum', pointer: '/impulses/brawlMedium' }),
    m('integer', { set: { '/impulses/brawlMedium': 1.5 } }, { rule: 'type', pointer: '/impulses/brawlMedium' }),
    m('type', { set: { '/impulses/brawlMedium': 'forty' } }, { rule: 'type', pointer: '/impulses/brawlMedium' }),
  ];
  let n = 0;
  for (const k of add) {
    const i = c.cases.findIndex((y) => y.id === k.id);
    if (i < 0) { c.cases.push(k); n++; } else if (JSON.stringify(c.cases[i]) !== JSON.stringify(k)) { c.cases[i] = k; n++; }
  }
  wj(cf, c);
  console.log(`core medium keys applied (${n} new cases)`);
}
