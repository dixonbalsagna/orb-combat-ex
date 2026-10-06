// Schema keys for Simulation's retune: power for damage taken and dealt. NOT run by CI, the validator or the sim. Run once from the repo root, in the
// commit that lands the slice's data:
//     node docs/tools/pending/apply-ladder-rates.cjs
// It does NOT edit data/. data/fighters/<FIGHTER>/ladder.json gains two required keys (a `_perDamage` note is allowed beside them by the file's
// underscore rule):
//   takenPerDamage  number, 0 or more: power for each point of damage a hit does to this fighter (0.0075 in the slice)
//   dealtPerDamage  number, 0 or more: power for each point of damage this fighter's hit does (0.0045)
// The two fixtures' ladder.json get the keys and every case sets its own values. Re-runnable (a second run changes nothing).
const fs = require('fs');
const rj = (f) => JSON.parse(fs.readFileSync(f, 'utf8'));
const wj = (f, o) => fs.writeFileSync(f, JSON.stringify(o, null, 2) + '\n');

// =============================== schema ===============================
{
  const f = 'tools/schemas/fighter-ladder.schema.json';
  const s = rj(f);
  let changed = false;
  if (!s.properties.takenPerDamage) {
    s.properties.takenPerDamage = { type: 'number', minimum: 0, description: 'Power for each point of damage a hit does to this fighter.' };
    changed = true;
  }
  if (!s.properties.dealtPerDamage) {
    s.properties.dealtPerDamage = { type: 'number', minimum: 0, description: 'Power for each point of damage this fighter\'s hit does.' };
    changed = true;
  }
  for (const k of ['takenPerDamage', 'dealtPerDamage']) if (!s.required.includes(k)) { s.required.push(k); changed = true; }
  if (changed) wj(f, s);
}

// =============================== fixtures ===============================
{
  for (const id of ['FIXTURE_HERO', 'FIXTURE_VILLAIN']) {
    const f = `tools/fixtures/virtual/data/fighters/${id}/ladder.json`;
    if (!fs.existsSync(f)) continue;
    const o = rj(f);
    let changed = false;
    if (o.takenPerDamage === undefined) { o.takenPerDamage = 0.0075; changed = true; }
    if (o.dealtPerDamage === undefined) { o.dealtPerDamage = 0.0045; changed = true; }
    if (changed) wj(f, o);
  }
}

// =============================== cases ===============================
{
  const cf = 'tools/fixtures/cases.json';
  const c = rj(cf);
  const L = 'data/fighters/FIXTURE_HERO/ladder.json';
  const x = (n, mut, expect) => ({ id: 'ladder-rates-' + n, schema: 'fighter-ladder.schema.json', mutate: [Object.assign({ file: L }, mut)], expect });
  const add = [
    x('valid', { set: { '/takenPerDamage': 0.0075, '/dealtPerDamage': 0.0045 } }, null),
    x('taken-required', { del: ['/takenPerDamage'] }, { rule: 'required', pointer: '' }),
    x('dealt-required', { del: ['/dealtPerDamage'] }, { rule: 'required', pointer: '' }),
    x('taken-negative', { set: { '/takenPerDamage': -0.001 } }, { rule: 'minimum', pointer: '/takenPerDamage' }),
    x('dealt-negative', { set: { '/dealtPerDamage': -0.001 } }, { rule: 'minimum', pointer: '/dealtPerDamage' }),
    x('taken-type', { set: { '/takenPerDamage': 'some' } }, { rule: 'type', pointer: '/takenPerDamage' }),
    x('dealt-type', { set: { '/dealtPerDamage': '0.0045' } }, { rule: 'type', pointer: '/dealtPerDamage' }),
    x('taken-zero-ok', { set: { '/takenPerDamage': 0, '/dealtPerDamage': 0.0045 } }, null),
    x('dealt-zero-ok', { set: { '/takenPerDamage': 0.0075, '/dealtPerDamage': 0 } }, null),
    x('large-values-ok', { set: { '/takenPerDamage': 5, '/dealtPerDamage': 3 } }, null),
    x('note-ok', { set: { '/takenPerDamage': 0.0075, '/dealtPerDamage': 0.0045, '/_perDamage': 'a note' } }, null),
    x('unknown-key', { set: { '/takenPerDamage': 0.0075, '/dealtPerDamage': 0.0045, '/blockedPerDamage': 0.001 } }, { rule: 'additionalProperties', pointer: '/blockedPerDamage' }),
  ];
  let n = 0;
  for (const k of add) {
    const i = c.cases.findIndex((y) => y.id === k.id);
    if (i < 0) { c.cases.push(k); n++; } else if (JSON.stringify(c.cases[i]) !== JSON.stringify(k)) { c.cases[i] = k; n++; }
  }
  wj(cf, c);
  console.log(`ladder rates applied (${n} new cases)`);
}
