// Schema for UI's display names: ui/data/fighter_names.json (the name a player sees for each roster id; UI's draft is
// docs/ui/ui-fighter-names.schema.json). NOT run by CI, the validator or the sim. Run once from the repo root, in the commit where UI lands
// the file:
//     node docs/tools/pending/apply-ui-fighter-names.cjs
// It does NOT edit ui/. It adds tools/schemas/ui-fighter-names.schema.json (closed except keys starting with an underscore; `names` has at
// least one row; a key is a lower-case roster id; a value is a non-empty string of at most 24 characters, as UI's draft says: the draft has no
// case rule), the map entry and the cases (each sets the whole file, so none depends on the real one). No new xref rule.
// Re-runnable (a second run changes nothing).
const fs = require('fs');
const rj = (f) => JSON.parse(fs.readFileSync(f, 'utf8'));
const wj = (f, o) => fs.writeFileSync(f, JSON.stringify(o, null, 2) + '\n');
const clone = (o) => JSON.parse(JSON.stringify(o));

// =============================== schema ===============================
{
  const f = 'tools/schemas/ui-fighter-names.schema.json';
  if (!fs.existsSync(f)) {
    wj(f, {
      $schema: 'https://json-schema.org/draft/2020-12/schema',
      $id: 'meridian/ui-fighter-names',
      title: 'ui fighter display names (schema 1)',
      description: 'ui/data/fighter_names.json: the name a player sees for each roster id (lower case, as the sim spells it). A fighter with no row shows its own name. `names` maps a roster id (lower case letters, digits and underscores, starting with a letter) to its display name (a non-empty string of at most 24 characters). Version field: schema. Policy: closed except keys starting with an underscore.',
      type: 'object',
      required: ['schema', 'names'],
      properties: {
        schema: { const: 1 },
        note: { type: 'string' },
        names: {
          type: 'object',
          minProperties: 1,
          propertyNames: { pattern: '^(_.*|[a-z][a-z0-9_]*)$' },
          additionalProperties: { type: 'string', minLength: 1, maxLength: 24 },
          patternProperties: { '^_': true },
        },
      },
      additionalProperties: false,
      patternProperties: { '^_': true },
    });
  }
}

// =============================== map ===============================
{
  const f = 'tools/schemas/map.json';
  const m = rj(f);
  if (!m.rules.some((r) => r.match === 'ui/data/fighter_names.json')) {
    const i = m.rules.findIndex((r) => r.match === 'ui/data/stances.json');
    const j = i >= 0 ? i : m.rules.findIndex((r) => r.match === 'ui/data/faces.json');
    m.rules.splice(j >= 0 ? j + 1 : m.rules.length, 0, { match: 'ui/data/fighter_names.json', schema: 'ui-fighter-names.schema.json' });
    wj(f, m);
  }
}

// =============================== cases ===============================
{
  const cf = 'tools/fixtures/cases.json';
  const c = rj(cf);
  const F = 'ui/data/fighter_names.json';
  const BASE = { schema: 1, names: { alpha: 'FIRST', beta: 'SECOND' } };
  const x = (n, tweak, expect) => {
    const d = clone(BASE);
    tweak(d);
    const set = {};
    const del = [];
    for (const k of Object.keys(d)) set['/' + k] = d[k];
    for (const k of Object.keys(BASE)) if (!(k in d)) del.push('/' + k);
    return { id: 'ui-fighter-names-' + n, schema: 'ui-fighter-names.schema.json', mutate: [{ file: F, set, ...(del.length ? { del } : {}) }], expect };
  };
  const add = [
    x('live-valid', () => {}, null),
    x('key-required-names', (d) => { delete d.names; }, { rule: 'required', pointer: '' }),
    x('key-required-schema', (d) => { delete d.schema; }, { rule: 'required', pointer: '' }),
    x('schema-version', (d) => { d.schema = 2; }, { rule: 'const', pointer: '/schema' }),
    x('unknown-key', (d) => { d.extra = 1; }, { rule: 'additionalProperties', pointer: '/extra' }),
    x('underscore-key-ok', (d) => { d._why = 'comment'; }, null),
    x('note-ok', (d) => { d.note = 'a note'; }, null),
    x('note-type', (d) => { d.note = 5; }, { rule: 'type', pointer: '/note' }),
    x('names-type', (d) => { d.names = ['FIRST']; }, { rule: 'type', pointer: '/names' }),
    x('names-empty', (d) => { d.names = {}; }, { rule: 'minProperties', pointer: '/names' }),
    x('names-one-row-ok', (d) => { d.names = { alpha: 'FIRST' }; }, null),
    x('names-underscore-row-ok', (d) => { d.names._why = 'a note'; }, null),
    x('id-upper-case', (d) => { d.names.Alpha = 'FIRST'; }, { rule: 'propertyNames', pointer: '/names/Alpha' }),
    x('id-starts-with-a-digit', (d) => { d.names['1st'] = 'FIRST'; }, { rule: 'propertyNames', pointer: '/names/1st' }),
    x('id-with-a-dash', (d) => { d.names['al-pha'] = 'FIRST'; }, { rule: 'propertyNames', pointer: '/names/al-pha' }),
    x('id-with-digits-and-underscore-ok', (d) => { d.names.fighter_2 = 'THIRD'; }, null),
    x('name-empty', (d) => { d.names.alpha = ''; }, { rule: 'minLength', pointer: '/names/alpha' }),
    x('name-too-long', (d) => { d.names.alpha = 'A'.repeat(25); }, { rule: 'maxLength', pointer: '/names/alpha' }),
    x('name-longest-ok', (d) => { d.names.alpha = 'A'.repeat(24); }, null),
    x('name-type', (d) => { d.names.alpha = 7; }, { rule: 'type', pointer: '/names/alpha' }),
    x('name-null', (d) => { d.names.alpha = null; }, { rule: 'type', pointer: '/names/alpha' }),
    x('name-mixed-case-ok', (d) => { d.names.alpha = 'First One'; }, null),
  ];
  let n = 0;
  for (const k of add) if (!c.cases.some((y) => y.id === k.id)) { c.cases.push(k); n++; }
  wj(cf, c);
  console.log(`ui-fighter-names schema applied (${n} new cases)`);
}
