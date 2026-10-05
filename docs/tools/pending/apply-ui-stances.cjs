// Schema for UI's stances file: ui/data/stances.json (the five stances, their badge words and the four face buttons of each;
// docs/ui/hud-spec.md section 36; UI's draft is docs/ui/ui-stances.schema.json). NOT run by CI, the validator or the sim. Run once from the
// repo root, in the commit where UI lands the file:
//     node docs/tools/pending/apply-ui-stances.cjs
// It does NOT edit ui/. It adds tools/schemas/ui-stances.schema.json (closed; underscore keys are notes; exactly the five stances; each
// stance's mask is the intent's stanceMask bit, so the masks are unique by construction: martial 0, defensive 1, energy 2, charging 4,
// manoeuvre 8), the map entry and the cases (each sets the whole order and stances, so none depends on the real file). No new xref rule.
// Re-runnable (a second run changes nothing).
const fs = require('fs');
const rj = (f) => JSON.parse(fs.readFileSync(f, 'utf8'));
const wj = (f, o) => fs.writeFileSync(f, JSON.stringify(o, null, 2) + '\n');
const clone = (o) => JSON.parse(JSON.stringify(o));
const closed = { additionalProperties: false, patternProperties: { '^_': true } };
const IDS = ['martial', 'defensive', 'energy', 'charging', 'manoeuvre'];
const MASKS = { martial: 0, defensive: 1, energy: 2, charging: 4, manoeuvre: 8 };
const text = (extra = {}) => Object.assign({ type: 'string', minLength: 1 }, extra);

// =============================== schema ===============================
{
  const f = 'tools/schemas/ui-stances.schema.json';
  if (!fs.existsSync(f)) {
    const stance = (id) => ({
      allOf: [{ $ref: '#/$defs/stance' }, { type: 'object', properties: { mask: { const: MASKS[id], description: `The intent's stanceMask bit for ${id}.` } } }],
    });
    wj(f, {
      $schema: 'https://json-schema.org/draft/2020-12/schema',
      $id: 'meridian/ui-stances',
      title: 'ui stances (schema 1)',
      description: 'ui/data/stances.json: the five stances and what the four face buttons do in each (docs/ui/hud-spec.md section 36). `order` lists the five ids (each once); `stances` has exactly those ids. Each stance has its mask (the intent\'s stanceMask bit: martial 0, defensive 1, energy 2, charging 4, manoeuvre 8, so the masks are unique), the badge word (`name`, at most 12 characters), the full name (`title`), how it is entered (`enter`) and the four cells x, y, a and b (a short name each). Version field: schema. Policy: closed except keys starting with an underscore.',
      type: 'object',
      required: ['schema', 'order', 'stances'],
      properties: {
        schema: { const: 1 },
        note: { type: 'string' },
        order: { type: 'array', minItems: 5, maxItems: 5, uniqueItems: true, items: { enum: IDS }, description: 'The five stance ids, each once, in the order the HUD lists them.' },
        stances: Object.assign({ type: 'object', required: IDS, properties: Object.fromEntries(IDS.map((id) => [id, stance(id)])) }, closed),
      },
      additionalProperties: false,
      patternProperties: { '^_': true },
      $defs: {
        stance: Object.assign({
          type: 'object',
          required: ['mask', 'name', 'title', 'enter', 'cells'],
          properties: {
            mask: { enum: [0, 1, 2, 4, 8] },
            name: text({ maxLength: 12 }),
            title: text(),
            enter: text(),
            cells: Object.assign({ type: 'object', required: ['x', 'y', 'a', 'b'], properties: { x: text(), y: text(), a: text(), b: text() } }, closed),
          },
        }, closed),
      },
    });
  }
}

// =============================== map ===============================
{
  const f = 'tools/schemas/map.json';
  const m = rj(f);
  if (!m.rules.some((r) => r.match === 'ui/data/stances.json')) {
    const i = m.rules.findIndex((r) => r.match === 'ui/data/faces.json');
    m.rules.splice(i >= 0 ? i + 1 : m.rules.length, 0, { match: 'ui/data/stances.json', schema: 'ui-stances.schema.json' });
    wj(f, m);
  }
}

// =============================== cases ===============================
{
  const cf = 'tools/fixtures/cases.json';
  const c = rj(cf);
  const F = 'ui/data/stances.json';
  const cell = (id) => ({ x: `${id} x`, y: `${id} y`, a: `${id} a`, b: `${id} b` });
  const BASE = {
    schema: 1,
    order: IDS.slice(),
    stances: Object.fromEntries(IDS.map((id) => [id, { mask: MASKS[id], name: id.toUpperCase().slice(0, 12), title: id, enter: 'Hold ' + id, cells: cell(id) }])),
  };
  // every case sets the whole order and stances (and the keys it changes), so none depends on the real file
  const x = (n, tweak, expect) => {
    const d = clone(BASE);
    tweak(d);
    const set = {};
    const del = [];
    for (const k of Object.keys(d)) set['/' + k] = d[k];
    for (const k of Object.keys(BASE)) if (!(k in d)) del.push('/' + k);
    return { id: 'ui-stances-' + n, schema: 'ui-stances.schema.json', mutate: [{ file: F, set, ...(del.length ? { del } : {}) }], expect };
  };
  const S = '/stances/';
  const add = [
    x('live-valid', () => {}, null),
    x('key-required-order', (d) => { delete d.order; }, { rule: 'required', pointer: '' }),
    x('key-required-stances', (d) => { delete d.stances; }, { rule: 'required', pointer: '' }),
    x('key-required-schema', (d) => { delete d.schema; }, { rule: 'required', pointer: '' }),
    x('schema-version', (d) => { d.schema = 2; }, { rule: 'const', pointer: '/schema' }),
    x('unknown-key', (d) => { d.extra = 1; }, { rule: 'additionalProperties', pointer: '/extra' }),
    x('underscore-key-ok', (d) => { d._why = 'comment'; }, null),
    x('note-ok', (d) => { d.note = 'a note'; }, null),
    x('note-type', (d) => { d.note = 5; }, { rule: 'type', pointer: '/note' }),
    x('order-too-short', (d) => { d.order = IDS.slice(0, 4); }, { rule: 'minItems', pointer: '/order' }),
    x('order-too-long', (d) => { d.order = IDS.concat('martial'); }, { rule: 'maxItems', pointer: '/order' }),
    x('order-duplicate', (d) => { d.order = ['martial', 'martial', 'energy', 'charging', 'manoeuvre']; }, { rule: 'uniqueItems', pointer: '/order/1' }),
    x('order-unknown-id', (d) => { d.order = ['martial', 'defensive', 'energy', 'charging', 'brawler']; }, { rule: 'enum', pointer: '/order/4' }),
    x('order-another-order-ok', (d) => { d.order = ['manoeuvre', 'charging', 'energy', 'defensive', 'martial']; }, null),
    x('stance-missing', (d) => { delete d.stances.charging; }, { rule: 'required', pointer: '/stances' }),
    x('stance-unknown-id', (d) => { d.stances.brawler = clone(d.stances.martial); }, { rule: 'additionalProperties', pointer: S + 'brawler' }),
    x('stance-key-required-mask', (d) => { delete d.stances.energy.mask; }, { rule: 'required', pointer: S + 'energy' }),
    x('stance-key-required-name', (d) => { delete d.stances.energy.name; }, { rule: 'required', pointer: S + 'energy' }),
    x('stance-key-required-title', (d) => { delete d.stances.energy.title; }, { rule: 'required', pointer: S + 'energy' }),
    x('stance-key-required-enter', (d) => { delete d.stances.energy.enter; }, { rule: 'required', pointer: S + 'energy' }),
    x('stance-key-required-cells', (d) => { delete d.stances.energy.cells; }, { rule: 'required', pointer: S + 'energy' }),
    x('stance-unknown-key', (d) => { d.stances.energy.mood = 1; }, { rule: 'additionalProperties', pointer: S + 'energy/mood' }),
    x('stance-underscore-key-ok', (d) => { d.stances.energy._why = 'comment'; }, null),
    x('mask-not-a-bit', (d) => { d.stances.energy.mask = 3; }, { rule: 'enum', pointer: S + 'energy/mask' }),
    x('mask-type', (d) => { d.stances.energy.mask = '2'; }, { rule: 'enum', pointer: S + 'energy/mask' }),
    x('mask-differs-from-the-stances-bit', (d) => { d.stances.energy.mask = 4; }, { rule: 'const', pointer: S + 'energy/mask' }),
    x('mask-twice', (d) => { d.stances.defensive.mask = 2; }, { rule: 'const', pointer: S + 'defensive/mask' }),
    x('mask-martial-is-zero', (d) => { d.stances.martial.mask = 1; }, { rule: 'const', pointer: S + 'martial/mask' }),
    x('name-empty', (d) => { d.stances.energy.name = ''; }, { rule: 'minLength', pointer: S + 'energy/name' }),
    x('name-too-long', (d) => { d.stances.energy.name = 'ABCDEFGHIJKLM'; }, { rule: 'maxLength', pointer: S + 'energy/name' }),
    x('name-longest-ok', (d) => { d.stances.energy.name = 'ABCDEFGHIJKL'; }, null),
    x('name-type', (d) => { d.stances.energy.name = 7; }, { rule: 'type', pointer: S + 'energy/name' }),
    x('title-empty', (d) => { d.stances.energy.title = ''; }, { rule: 'minLength', pointer: S + 'energy/title' }),
    x('enter-empty', (d) => { d.stances.energy.enter = ''; }, { rule: 'minLength', pointer: S + 'energy/enter' }),
    x('cells-key-required', (d) => { delete d.stances.energy.cells.b; }, { rule: 'required', pointer: S + 'energy/cells' }),
    x('cells-unknown-key', (d) => { d.stances.energy.cells.z = 'a'; }, { rule: 'additionalProperties', pointer: S + 'energy/cells/z' }),
    x('cell-empty', (d) => { d.stances.energy.cells.a = ''; }, { rule: 'minLength', pointer: S + 'energy/cells/a' }),
    x('cell-type', (d) => { d.stances.energy.cells.x = ['Bolts']; }, { rule: 'type', pointer: S + 'energy/cells/x' }),
  ];
  let n = 0;
  for (const k of add) if (!c.cases.some((y) => y.id === k.id)) { c.cases.push(k); n++; }
  wj(cf, c);
  console.log(`ui-stances schema applied (${n} new cases)`);
}
