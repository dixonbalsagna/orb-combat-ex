// Schema keys for Simulation's default intro facts: data/fight/intro.json `defaultFacts` (docs/architecture/dynamic-intros.md section 13; the facts a
// composed intro takes when the setup's record sends none). NOT run by CI, the validator or the sim. Run once from the repo root, in the commit that
// lands Simulation's slice:
//     node docs/tools/pending/apply-intro-default.cjs
// It does NOT edit data/. tools/schemas/fight-intro.schema.json gains a top-level optional closed record `defaultFacts` (a `_defaultFacts` note is
// allowed beside it by the file's underscore rule), with only these keys, all optional:
//   look      a part id (rule intro-default: it names a part of type look)
//   gestures  at most 8 records, each with all of at (land_first, land_second, wait, look_start or look_end), who (first, second, left, right or
//             both) and intent (a non-empty string)
//   intents   a record keyed by a voice slot's intent (arrive_remark, wait_remark, late_reply, staredown_pair; any lower-case name is allowed, as
//             the slots may grow); each value is {who?, stance?, angle?, event?, p?} (p 0 to 1) or {lines: [the same record]}
//   tones     an array of strings
//   weights   a record of template id to a number 0 or more (rule intro-default: every id is a template)
//   gap       a number -1 to 1
//   clock     an integer
//   plot      a string
// `take` is a key of the match setup, not of the data file: it has no schema here. The fixture (tools/fixtures/virtual/data/fight/intro.json)
// gets Simulation's value, and every case sets its own whole block (and the own part or template a cross-check needs). Re-runnable.
const fs = require('fs');
const rj = (f) => JSON.parse(fs.readFileSync(f, 'utf8'));
const wj = (f, o) => fs.writeFileSync(f, JSON.stringify(o, null, 2) + '\n');
const closed = { additionalProperties: false, patternProperties: { '^_': true } };
const obj = (props, opts = {}) => Object.assign({ type: 'object', required: opts.required === undefined ? Object.keys(props) : opts.required, properties: props }, opts.description ? { description: opts.description } : {}, closed);
const clone = (o) => JSON.parse(JSON.stringify(o));
const str = (d) => ({ type: 'string', minLength: 1, description: d });
const name = { type: 'string', pattern: '^[a-z][a-z0-9_]*$' };

const FACTS_VALUE = {
  look: 'hold',
  gestures: [{ at: 'look_start', who: 'both', intent: 'appraise' }],
  intents: { arrive_remark: { angle: 'you', p: 0.8 }, wait_remark: { angle: 'you', p: 0.8 }, late_reply: { angle: 'you', p: 0.8 }, staredown_pair: { angle: 'you', p: 0.8 } },
};

// =============================== schema ===============================
{
  const f = 'tools/schemas/fight-intro.schema.json';
  const s = rj(f);
  if (!s.properties.defaultFacts) {
    const entry = obj({
      who: Object.assign({}, name, { description: 'A role (first, second, left, right, or a plot role): the speaker this entry is for.' }),
      stance: str('A stance the line is about.'),
      angle: str('The angle of the line (for example you).'),
      event: str('An event the line is about.'),
      p: { type: 'number', minimum: 0, maximum: 1, description: 'The chance the line plays.' },
    }, { required: [] });
    s.properties.defaultFacts = obj({
      look: Object.assign({}, name, { description: 'The part the look is, where the slot\'s pool has it (rule intro-default: a part of type look).' }),
      gestures: {
        type: 'array',
        maxItems: 8,
        items: obj({
          at: { enum: ['land_first', 'land_second', 'wait', 'look_start', 'look_end'] },
          who: { enum: ['first', 'second', 'left', 'right', 'both'] },
          intent: str('The gesture\'s intent.'),
        }),
        description: 'The gestures played at the points of gesturePoints.',
      },
      intents: {
        type: 'object',
        propertyNames: { pattern: '^(_.*|[a-z][a-z0-9_]*)$' },
        additionalProperties: {
          anyOf: [
            entry,
            obj({ lines: { type: 'array', minItems: 1, items: entry, description: 'One row a speaker: the row whose who is the speaker\'s role.' } }),
          ],
        },
        patternProperties: { '^_': true },
        description: 'A voice slot\'s intent to the tags of its line, or to a list of rows a speaker.',
      },
      tones: { type: 'array', items: { type: 'string', minLength: 1 }, description: 'The tones a composed intro may take.' },
      weights: { type: 'object', propertyNames: { pattern: '^(_.*|[a-z][a-z0-9_]*)$' }, additionalProperties: { type: 'number', minimum: 0 }, patternProperties: { '^_': true }, description: 'A template id to its weight (rule intro-default: every id is a template).' },
      gap: { type: 'number', minimum: -1, maximum: 1, description: 'Where in the template\'s gap range the gap falls.' },
      clock: { type: 'integer', description: 'A bend of the clock, in ticks.' },
      plot: { type: 'string', description: 'A plot id.' },
    }, { required: [], description: 'The facts a composed intro takes when the setup\'s record sends none (a first meeting). A record\'s own facts keys, all optional.' });
    if (!/intro-default/.test(s.description)) s.description = s.description.replace('are checked by tools/lib/xref-fight.js (intro-*).', () => 'are checked by tools/lib/xref-fight.js (intro-*); defaultFacts.look names a part of type look and every defaultFacts.weights id is a template (intro-default).');
    wj(f, s);
  }
}

// =============================== fixture ===============================
{
  const f = 'tools/fixtures/virtual/data/fight/intro.json';
  const o = rj(f);
  if (o.defaultFacts === undefined) {
    const out = {};
    for (const k of Object.keys(o)) { out[k] = o[k]; if (k === '_gesturePoints') { out.defaultFacts = clone(FACTS_VALUE); out._defaultFacts = 'Validator fixture, not game data: the default facts.'; } }
    if (out.defaultFacts === undefined) out.defaultFacts = clone(FACTS_VALUE);
    wj(f, out);
  }
}

// =============================== xref ===============================
{
  const f = 'tools/lib/xref-fight.js';
  let t = fs.readFileSync(f, 'utf8');
  if (!t.includes("'intro-default'")) {
    const marker = '  // ---- anim last stand: ready keys are shapes, sequences exist ----';
    if (!t.includes(marker)) throw new Error('intro-default xref marker');
    t = t.replace(marker, () => [
      "  // ---- fight intro: the default facts name a look part and templates that exist ----",
      "  if (isObj(fint) && isObj(fint.defaultFacts)) {",
      "    const IT3 = 'data/fight/intro.json';",
      "    const df = fint.defaultFacts;",
      "    const partsD = isObj(fint.parts) ? fint.parts : {};",
      "    if (typeof df.look === 'string' && (!isObj(partsD[df.look]) || partsD[df.look].type !== 'look')) err(IT3, '/defaultFacts/look', 'intro-default', `look \"${df.look}\" is not a part of type look`);",
      "    const tids = new Set(Array.isArray(fint.templates) ? fint.templates.filter(isObj).map((tp) => tp.id) : []);",
      "    if (isObj(df.weights) && tids.size) for (const k of Object.keys(df.weights)) if (!k.startsWith('_') && !tids.has(k)) err(IT3, `/defaultFacts/weights/${esc(k)}`, 'intro-default', `weight for \"${k}\", which is not a template id`);",
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
  const F = 'data/fight/intro.json';
  const D = '/defaultFacts';
  const OWN_LOOK = { type: 'look', ticks: 0, beats: [{ t: 0, kind: 'staredown' }] };
  const OWN_OTHER = { type: 'reaction', ticks: 10, beats: [{ t: 0, kind: 'wait' }] };
  const OWN_TEMPLATE = { id: 'df_template', weight: 1, tone: 'neutral', clock: 300, gap: { min: 30, max: 70, default: 48 }, slots: [{ slot: 'look', who: 'both', pool: ['df_look'] }] };
  const BASE = { look: 'df_look', gestures: [{ at: 'look_start', who: 'both', intent: 'appraise' }], intents: { arrive_remark: { angle: 'you', p: 0.8 }, staredown_pair: { lines: [{ who: 'left', angle: 'you' }, { who: 'right', angle: 'now', p: 0.5 }] } }, tones: ['neutral'], weights: { df_template: 2 }, gap: 0, clock: 0, plot: 'first_meeting' };
  const x = (n, tweak, expect) => {
    const d = clone(BASE);
    tweak(d);
    return { id: 'fight-intro-default-' + n, schema: 'fight-intro.schema.json', mutate: [{ file: F, set: { '/parts/df_look': OWN_LOOK, '/parts/df_other': OWN_OTHER, '/templates/-': OWN_TEMPLATE, [D]: d } }], expect };
  };
  const G = D + '/gestures/';
  const I = D + '/intents/';
  const add = [
    x('valid', () => {}, null),
    x('empty-ok', (d) => { for (const k of Object.keys(d)) delete d[k]; }, null),
    x('unknown-key', (d) => { d.take = 1; }, { rule: 'additionalProperties', pointer: D + '/take' }),
    x('underscore-key-ok', (d) => { d._why = 'a note'; }, null),
    x('look-type', (d) => { d.look = 5; }, { rule: 'type', pointer: D + '/look' }),
    x('look-shape', (d) => { d.look = 'Hold Long'; }, { rule: 'pattern', pointer: D + '/look' }),
    x('look-unknown-part', (d) => { d.look = 'nowhere'; }, { rule: 'xref:intro-default', pointer: D + '/look' }),
    x('look-part-of-another-type', (d) => { d.look = 'df_other'; }, { rule: 'xref:intro-default', pointer: D + '/look' }),
    x('gestures-type', (d) => { d.gestures = 'appraise'; }, { rule: 'type', pointer: D + '/gestures' }),
    x('gestures-eight-ok', (d) => { d.gestures = Array.from({ length: 8 }, () => ({ at: 'wait', who: 'first', intent: 'brace' })); }, null),
    x('gestures-nine', (d) => { d.gestures = Array.from({ length: 9 }, () => ({ at: 'wait', who: 'first', intent: 'brace' })); }, { rule: 'maxItems', pointer: G.slice(0, -1) }),
    x('gesture-key-required-at', (d) => { d.gestures = [{ who: 'both', intent: 'appraise' }]; }, { rule: 'required', pointer: G + '0' }),
    x('gesture-key-required-who', (d) => { d.gestures = [{ at: 'wait', intent: 'appraise' }]; }, { rule: 'required', pointer: G + '0' }),
    x('gesture-key-required-intent', (d) => { d.gestures = [{ at: 'wait', who: 'both' }]; }, { rule: 'required', pointer: G + '0' }),
    x('gesture-at-enum', (d) => { d.gestures = [{ at: 'later', who: 'both', intent: 'appraise' }]; }, { rule: 'enum', pointer: G + '0/at' }),
    x('gesture-who-enum', (d) => { d.gestures = [{ at: 'wait', who: 'last_loser', intent: 'appraise' }]; }, { rule: 'enum', pointer: G + '0/who' }),
    x('gesture-intent-empty', (d) => { d.gestures = [{ at: 'wait', who: 'both', intent: '' }]; }, { rule: 'minLength', pointer: G + '0/intent' }),
    x('gesture-unknown-key', (d) => { d.gestures = [{ at: 'wait', who: 'both', intent: 'appraise', w: 1 }]; }, { rule: 'additionalProperties', pointer: G + '0/w' }),
    x('gesture-every-point-and-role-ok', (d) => { d.gestures = ['land_first', 'land_second', 'wait', 'look_start', 'look_end'].map((at, i) => ({ at, who: ['first', 'second', 'left', 'right', 'both'][i], intent: 'check' })); }, null),
    x('intents-type', (d) => { d.intents = []; }, { rule: 'type', pointer: D + '/intents' }),
    x('intent-slot-name-shape', (d) => { d.intents['Arrive Remark'] = { p: 1 }; }, { rule: 'propertyNames', pointer: I + 'Arrive Remark' }),
    x('intent-unknown-key', (d) => { d.intents.arrive_remark.mood = 1; }, { rule: 'anyOf', pointer: I + 'arrive_remark' }),
    x('intent-p-above-one', (d) => { d.intents.arrive_remark.p = 1.5; }, { rule: 'anyOf', pointer: I + 'arrive_remark' }),
    x('intent-p-negative', (d) => { d.intents.arrive_remark.p = -0.1; }, { rule: 'anyOf', pointer: I + 'arrive_remark' }),
    x('intent-p-type', (d) => { d.intents.arrive_remark.p = 'often'; }, { rule: 'anyOf', pointer: I + 'arrive_remark' }),
    x('intent-p-edges-ok', (d) => { d.intents.arrive_remark.p = 0; d.intents.wait_remark = { p: 1 }; }, null),
    x('intent-empty-record-ok', (d) => { d.intents.late_reply = {}; }, null),
    x('intent-every-tag-ok', (d) => { d.intents.wait_remark = { who: 'first', stance: 'martial', angle: 'you', event: 'a_fall', p: 0.5 }; }, null),
    x('intent-tag-empty', (d) => { d.intents.arrive_remark.angle = ''; }, { rule: 'anyOf', pointer: I + 'arrive_remark' }),
    x('intent-lines-empty', (d) => { d.intents.staredown_pair = { lines: [] }; }, { rule: 'anyOf', pointer: I + 'staredown_pair' }),
    x('intent-lines-row-unknown-key', (d) => { d.intents.staredown_pair = { lines: [{ who: 'left', mood: 1 }] }; }, { rule: 'anyOf', pointer: I + 'staredown_pair' }),
    x('intent-lines-with-a-tag-beside', (d) => { d.intents.staredown_pair = { lines: [{ who: 'left' }], angle: 'you' }; }, { rule: 'anyOf', pointer: I + 'staredown_pair' }),
    x('tones-type', (d) => { d.tones = 'grave'; }, { rule: 'type', pointer: D + '/tones' }),
    x('tones-item-type', (d) => { d.tones = [5]; }, { rule: 'type', pointer: D + '/tones/0' }),
    x('tones-empty-ok', (d) => { d.tones = []; }, null),
    x('weights-type', (d) => { d.weights = [1]; }, { rule: 'type', pointer: D + '/weights' }),
    x('weight-negative', (d) => { d.weights.df_template = -1; }, { rule: 'minimum', pointer: D + '/weights/df_template' }),
    x('weight-type', (d) => { d.weights.df_template = 'heavy'; }, { rule: 'type', pointer: D + '/weights/df_template' }),
    x('weight-zero-ok', (d) => { d.weights.df_template = 0; }, null),
    x('weight-id-shape', (d) => { d.weights['Df Template'] = 1; }, { rule: 'propertyNames', pointer: D + '/weights/Df Template' }),
    x('weight-id-not-a-template', (d) => { d.weights = { nowhere: 1 }; }, { rule: 'xref:intro-default', pointer: D + '/weights/nowhere' }),
    x('gap-below-minus-one', (d) => { d.gap = -1.1; }, { rule: 'minimum', pointer: D + '/gap' }),
    x('gap-above-one', (d) => { d.gap = 1.1; }, { rule: 'maximum', pointer: D + '/gap' }),
    x('gap-type', (d) => { d.gap = 'wide'; }, { rule: 'type', pointer: D + '/gap' }),
    x('gap-edges-ok', (d) => { d.gap = -1; }, null),
    x('gap-one-ok', (d) => { d.gap = 1; }, null),
    x('clock-type', (d) => { d.clock = 'long'; }, { rule: 'type', pointer: D + '/clock' }),
    x('clock-integer', (d) => { d.clock = 30.5; }, { rule: 'type', pointer: D + '/clock' }),
    x('clock-negative-ok', (d) => { d.clock = -30; }, null),
    x('plot-type', (d) => { d.plot = 5; }, { rule: 'type', pointer: D + '/plot' }),
    { id: 'fight-intro-default-note-beside-ok', schema: 'fight-intro.schema.json', mutate: [{ file: F, set: { '/_defaultFacts': 'a note' } }], expect: null },
    { id: 'fight-intro-default-absent-ok', schema: 'fight-intro.schema.json', mutate: [{ file: F, del: [D] }], expect: null },
  ];
  let n = 0;
  for (const k of add) {
    const i = c.cases.findIndex((y) => y.id === k.id);
    if (i < 0) { c.cases.push(k); n++; } else if (JSON.stringify(c.cases[i]) !== JSON.stringify(k)) { c.cases[i] = k; n++; }
  }
  wj(cf, c);
  console.log(`intro default facts applied (${n} new cases)`);
}

// =============================== docs ===============================
{
  const f = 'docs/tools/README.md';
  let t = fs.readFileSync(f, 'utf8');
  if (!t.includes('`intro-default`')) {
    const lines = t.split('\n');
    const i = lines.findIndex((l) => l.includes('`intro-classic`'));
    if (i < 0) throw new Error('intro-default README anchor');
    lines.splice(i + 1, 0, '| `intro-default` | data/fight/intro.json: defaultFacts.look names a part of type look, and every defaultFacts.weights id is a template id |');
    fs.writeFileSync(f, lines.join('\n'));
  }
}
