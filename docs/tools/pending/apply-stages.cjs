// Schema for World's staged destruction, slice 1: data/biomes/stages.json (biomes.stages/1; docs/world/staged-destruction.md). NOT run by CI,
// the validator or the sim. Run once from the repo root, in the commit where World lands the file:
//     node docs/tools/pending/apply-stages.cjs
// It does NOT edit data/. It adds tools/schemas/biomes-stages.schema.json (closed; underscore keys are notes), the map entry, a validator
// fixture (tools/fixtures/virtual/data/biomes/stages.json, from the live file if present, else the brief's numbers; a fixture wins over the
// live file in the self-test), the rule stages-order (hpAt strictly decreasing) and the cases. Re-runnable (a second run changes nothing).
const fs = require('fs');
const rj = (f) => JSON.parse(fs.readFileSync(f, 'utf8'));
const wj = (f, o) => fs.writeFileSync(f, JSON.stringify(o, null, 2) + '\n');

// =============================== schema ===============================
{
  const f = 'tools/schemas/biomes-stages.schema.json';
  if (!fs.existsSync(f)) {
    wj(f, {
      $schema: 'https://json-schema.org/draft/2020-12/schema',
      $id: 'meridian/biomes-stages',
      title: 'biomes.stages/1',
      description: 'data/biomes/stages.json: the stages of a building\'s destruction (docs/world/staged-destruction.md; WorldStructures.stage). hpAt: the health shares (of its full health) at which a building enters its next stage, three numbers falling from the first. cutFloorsStage: the stage from which cut floors show. Version field: schema. Policy: closed except keys starting with an underscore. The order of hpAt (strictly decreasing) is checked by tools/lib/xref-fight.js (stages-order).',
      type: 'object',
      required: ['schema', 'hpAt', 'cutFloorsStage', 'leaveFrac'],
      properties: {
        schema: { const: 'biomes.stages/1' },
        hpAt: {
          type: 'array',
          minItems: 3,
          maxItems: 3,
          items: { type: 'number', exclusiveMinimum: 0, exclusiveMaximum: 1 },
          description: 'The health shares at which a building enters stages 1, 2 and 3, strictly decreasing.',
        },
        cutFloorsStage: { type: 'integer', minimum: 1, maximum: 3, description: 'The stage from which cut floors show.' },
        leaveFrac: { type: 'number', minimum: 0, maximum: 0.9, description: 'One blast (damageArea, not a beam or a brunt) cannot take a standing building below this share of its hit points, so a second blast finishes it. 0 is off.' },
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
  if (!m.rules.some((r) => r.match === 'data/biomes/stages.json')) {
    const i = m.rules.findIndex((r) => r.match === 'data/biomes/blast.json');
    m.rules.splice(i >= 0 ? i + 1 : m.rules.length, 0, { match: 'data/biomes/stages.json', schema: 'biomes-stages.schema.json' });
    wj(f, m);
  }
}

// =============================== fixture ===============================
{
  const f = 'tools/fixtures/virtual/data/biomes/stages.json';
  if (!fs.existsSync(f)) {
    const live = fs.existsSync('data/biomes/stages.json') ? rj('data/biomes/stages.json') : null;
    wj(f, {
      schema: 'biomes.stages/1',
      _about: 'Validator fixture, not game data.',
      hpAt: live && Array.isArray(live.hpAt) ? live.hpAt : [0.9, 0.65, 0.35],
      cutFloorsStage: live && Number.isInteger(live.cutFloorsStage) ? live.cutFloorsStage : 2,
      leaveFrac: live && typeof live.leaveFrac === 'number' ? live.leaveFrac : 0.1,
    });
  }
}

// =============================== xref ===============================
{
  const f = 'tools/lib/xref-fight.js';
  let t = fs.readFileSync(f, 'utf8');
  if (!t.includes("'stages-order'")) {
    const marker = '  // ---- fighter ladder: the beam tables never decrease with the tier ----';
    if (!t.includes(marker)) throw new Error('xref marker');
    t = t.replace(marker, () => [
      "  // ---- biomes stages: the health thresholds strictly fall ----",
      "  const stg = get('data/biomes/stages.json');",
      "  if (isObj(stg) && Array.isArray(stg.hpAt)) for (let i = 1; i < stg.hpAt.length; i++) {",
      "    if (typeof stg.hpAt[i] === 'number' && typeof stg.hpAt[i - 1] === 'number' && stg.hpAt[i] >= stg.hpAt[i - 1]) err('data/biomes/stages.json', `/hpAt/${i}`, 'stages-order', `hpAt[${i}] ${stg.hpAt[i]} is not below hpAt[${i - 1}] ${stg.hpAt[i - 1]}; the thresholds must strictly fall`);",
      "  }",
      "",
      marker,
    ].join('\n'));
    fs.writeFileSync(f, t);
  }
}

// =============================== cases ===============================
{
  const cf = 'tools/fixtures/cases.json';
  const c = rj(cf);
  const S = 'data/biomes/stages.json';
  const x = (n, mut, expect) => ({ id: 'biomes-stages-' + n, schema: 'biomes-stages.schema.json', mutate: [{ file: S, ...mut }], expect });
  const add = [
    x('live-valid', { set: { '/cutFloorsStage': 2 } }, null),
    x('key-required', { del: ['/hpAt'] }, { rule: 'required', pointer: '' }),
    x('cut-floors-required', { del: ['/cutFloorsStage'] }, { rule: 'required', pointer: '' }),
    x('schema-version', { set: { '/schema': 'biomes.stages/2' } }, { rule: 'const', pointer: '/schema' }),
    x('unknown-key', { set: { '/extra': 1 } }, { rule: 'additionalProperties', pointer: '/extra' }),
    x('underscore-key-ok', { set: { '/_why': 'comment' } }, null),
    x('hp-at-type', { set: { '/hpAt': 0.5 } }, { rule: 'type', pointer: '/hpAt' }),
    x('hp-at-too-short', { set: { '/hpAt': [0.9, 0.5] } }, { rule: 'minItems', pointer: '/hpAt' }),
    x('hp-at-too-long', { set: { '/hpAt': [0.9, 0.65, 0.35, 0.1] } }, { rule: 'maxItems', pointer: '/hpAt' }),
    x('hp-at-item-type', { set: { '/hpAt': [0.9, 'half', 0.35] } }, { rule: 'type', pointer: '/hpAt/1' }),
    x('hp-at-zero', { set: { '/hpAt': [0.9, 0.65, 0] } }, { rule: 'exclusiveMinimum', pointer: '/hpAt/2' }),
    x('hp-at-one', { set: { '/hpAt': [1, 0.65, 0.35] } }, { rule: 'exclusiveMaximum', pointer: '/hpAt/0' }),
    x('hp-at-negative', { set: { '/hpAt': [0.9, 0.65, -0.1] } }, { rule: 'exclusiveMinimum', pointer: '/hpAt/2' }),
    x('hp-at-rising', { set: { '/hpAt': [0.5, 0.65, 0.35] } }, { rule: 'xref:stages-order', pointer: '/hpAt/1' }),
    x('hp-at-equal', { set: { '/hpAt': [0.9, 0.65, 0.65] } }, { rule: 'xref:stages-order', pointer: '/hpAt/2' }),
    x('hp-at-last-above', { set: { '/hpAt': [0.9, 0.35, 0.65] } }, { rule: 'xref:stages-order', pointer: '/hpAt/2' }),
    x('hp-at-close-ok', { set: { '/hpAt': [0.99, 0.5, 0.01] } }, null),
    x('cut-floors-low', { set: { '/cutFloorsStage': 0 } }, { rule: 'minimum', pointer: '/cutFloorsStage' }),
    x('cut-floors-high', { set: { '/cutFloorsStage': 4 } }, { rule: 'maximum', pointer: '/cutFloorsStage' }),
    x('cut-floors-integer', { set: { '/cutFloorsStage': 1.5 } }, { rule: 'type', pointer: '/cutFloorsStage' }),
    x('cut-floors-edges-ok', { set: { '/cutFloorsStage': 1 } }, null),
    x('cut-floors-last-ok', { set: { '/cutFloorsStage': 3 } }, null),
    x('leave-frac-required', { del: ['/leaveFrac'] }, { rule: 'required', pointer: '' }),
    x('leave-frac-negative', { set: { '/leaveFrac': -0.1 } }, { rule: 'minimum', pointer: '/leaveFrac' }),
    x('leave-frac-above-limit', { set: { '/leaveFrac': 0.95 } }, { rule: 'maximum', pointer: '/leaveFrac' }),
    x('leave-frac-one', { set: { '/leaveFrac': 1 } }, { rule: 'maximum', pointer: '/leaveFrac' }),
    x('leave-frac-type', { set: { '/leaveFrac': 'some' } }, { rule: 'type', pointer: '/leaveFrac' }),
    x('leave-frac-off-ok', { set: { '/leaveFrac': 0 } }, null),
    x('leave-frac-limit-ok', { set: { '/leaveFrac': 0.9 } }, null),
    x('leave-frac-first-value-ok', { set: { '/leaveFrac': 0.1 } }, null),
  ];
  let n = 0;
  for (const k of add) if (!c.cases.some((y) => y.id === k.id)) { c.cases.push(k); n++; }
  wj(cf, c);
  console.log(`stages schema applied (${n} new cases)`);
}

// =============================== docs ===============================
{
  const f = 'docs/tools/README.md';
  let t = fs.readFileSync(f, 'utf8');
  if (!t.includes('stages-order')) {
    const line = t.split('\n').find((l) => l.includes('`contact-order`')) || t.split('\n').find((l) => l.includes('`blast-kind`'));
    if (!line) throw new Error('stages README anchor');
    t = t.replace(line, () => line + '\n| `stages-order` | data/biomes/stages.json: hpAt strictly decreases |');
    fs.writeFileSync(f, t);
  }
}
