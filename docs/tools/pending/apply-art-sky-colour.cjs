// Schemas for Art's two new data files: data/art/sky.json (the dynamic sky: four bands, the keys, the blend paths, the start, the drift, the rate limits, the mood numbers) and
// data/art/colour-vision.json (the protan, deutan and tritan presets with the two auras each, the cue set, the hue families and the rule for future fighters). NOT run by CI, the
// validator or the sim. Run once from the repo root, in the commit that lands Art's two files (they are in the tree, uncommitted):
//     node docs/tools/pending/apply-art-sky-colour.cjs
// It adds tools/schemas/art-sky.schema.json and art-colour-vision.schema.json, their map.json rules, the cross-references in tools/lib/xref-fight.js and the cases. It does NOT edit data/.
// Policy: both schemas are closed at the top and in every object whose keys are Art's own names; the prose and measurement objects Art's generators write (`measured`, `how`, the notes)
// are open or strings. Cross-references (rules in the README table):
//   sky-key-id, sky-key-phase  key ids are unique; phases start at or above 0, strictly increase and stay below 1
//   sky-start-key              start.key is a key's id
//   sky-anchor-order           the band anchors rise: horizon < lower < upper < top
//   sky-transitions            the transitions are the cycle of the keys: key i to key i+1, the last to the first, each once
//   sky-time                   time.cycle_minutes is 1 / cycles_per_minute (within 1%)
//   sky-rate-limit             every mean is at most its band, and every band is positive and below the flash threshold (0.10 of relative luminance in a second, WCAG 2.3.1: the
//                              file states it in rate_limit.fastest_allowed); the total band is at least the place_and_time and mood bands; the band weights sum to 1
//   sky-lane-colours           readability.lane_colours P and A are the default auras of data/art/colour-vision.json (protagonist and rival)
//   colour-vision-fighters     the fighters of `default` and of each of protan, deutan and tritan are the same set, and (on the live data, not the self-test's fixture roster) they are the roster's fighters, lower-cased
//   colour-vision-body         a preset keeps each fighter's body colour (col): a preset remaps only the aura
// The flash threshold is a constant of the standard (0.10), not a key of the file, so the schema fixes it. Re-runnable (a second run changes nothing).
const fs = require('fs');
const rj = (f) => JSON.parse(fs.readFileSync(f, 'utf8'));
const wj = (f, o) => fs.writeFileSync(f, JSON.stringify(o, null, 2) + '\n');
const clone = (o) => JSON.parse(JSON.stringify(o));
const closed = { additionalProperties: false, patternProperties: { '^_': true } };
const obj = (props, opts = {}) => Object.assign({ type: 'object', required: opts.required || Object.keys(props), properties: props }, opts.description ? { description: opts.description } : {}, closed);
const open = (props, description) => ({ type: 'object', required: Object.keys(props), properties: props, additionalProperties: true, description });
const str = (d) => ({ type: 'string', minLength: 1, description: d });
const hex = (d) => ({ type: 'string', pattern: '^#[0-9a-fA-F]{6}$', description: d });
const num = (d, min, max) => Object.assign({ type: 'number', description: d }, min !== undefined ? { minimum: min } : {}, max !== undefined ? { maximum: max } : {});
const pos = (d) => ({ type: 'number', exclusiveMinimum: 0, description: d });
const BANDS = ['horizon', 'lower', 'upper', 'top'];
const FLASH = 0.1;   // WCAG 2.3.1: a general flash needs an opposing pair of 0.10 of relative luminance inside a second

// =============================== schemas ===============================
const SKY = {
  $schema: 'https://json-schema.org/draft/2020-12/schema', $id: 'meridian/art-sky', title: 'art sky (version 1)',
  description: 'data/art/sky.json: the dynamic sky (docs/art/dynamic-sky.md): four bands from the horizon up, five keys round one lap, the blend paths between them, where the match starts, how the sky follows place, time and mood, and the rate limits that keep it below a flash. Version field: version. Policy: closed except keys starting with an underscore; the measured objects Art\'s generator writes are open. Cross-references in tools/lib/xref-fight.js (sky-key-id, sky-key-phase, sky-start-key, sky-anchor-order, sky-transitions, sky-time, sky-rate-limit, sky-lane-colours). The rate limits are positive and below 0.10 of relative luminance a second, the threshold of a general flash (WCAG 2.3.1), which the schema fixes.',
  type: 'object', ...closed,
  required: ['version', 'note', 'bands', 'anchors_half_screens', 'start', 'keys', 'blend', 'place', 'time', 'rate_limit', 'mood', 'readability'],
  properties: {
    version: { const: 1 }, note: str('Where the file comes from.'),
    bands: { const: BANDS, description: 'The four bands, horizon to top.' },
    anchors_half_screens: obj(Object.fromEntries(BANDS.map((b) => [b, num('Where the band sits, in half screens above the horizon (rising: sky-anchor-order).', 0)])), { description: 'Band anchors.' }),
    start: obj({ key: str('The key the match starts at (a key id: sky-start-key).'), phase: num('The phase it starts at.', 0, 1) }, { description: 'The start.' }),
    keys: { type: 'array', minItems: 2, description: 'The keys round one lap, in phase order (sky-key-id, sky-key-phase).', items: obj({
      id: { type: 'string', pattern: '^[a-z][a-z0-9_]*$', description: 'The key\'s id.' }, phase: { type: 'number', minimum: 0, exclusiveMaximum: 1, description: 'Where in the lap the key is.' },
      hold: { type: 'number', minimum: 0, exclusiveMaximum: 1, description: 'The share of a lap the key holds its colours.' }, stars: num('How many stars show, 0 to 1.', 0, 1),
      bands: obj(Object.fromEntries(BANDS.map((b) => [b, hex(`The ${b} band\'s colour.`)])), { description: 'The four band colours.' }), note: str('Why the key looks as it does.'),
    }) },
    blend: obj({
      space: { const: 'oklab', description: 'The colour space blends run in.' }, ease: { enum: ['smoothstep', 'linear'], description: 'The easing.' }, hold: str('How a hold works.'), path: str('How a path is chosen.'),
      transitions: { type: 'array', minItems: 2, description: 'One per key, round the lap (sky-transitions).', items: obj(Object.assign({ from: str('A key id.'), to: str('The next key id.') }, Object.fromEntries(BANDS.map((b) => [b, { enum: ['lab', 'lch+', 'lch-'], description: `The ${b} band\'s blend path.` }])))) },
    }, { description: 'How colours blend between keys.' }),
    place: obj({ cycles_per_lap: pos('Cycles of the sky in one lap of the planet.'), phase_of: str('The formula.'), per_pane: { type: 'boolean', description: 'Whether each split pane has its own phase.' }, note: str('Note.') }, { description: 'The sky follows place.' }),
    time: obj({ cycles_per_minute: pos('The drift with time, cycles a minute.'), cycle_minutes: pos('Minutes for one cycle (1 / cycles_per_minute: sky-time).'), note: str('Note.') }, { description: 'The sky follows time.' }),
    rate_limit: obj({
      unit: str('The unit.'),
      total: obj({ mean: { type: 'number', exclusiveMinimum: 0, exclusiveMaximum: FLASH, description: 'The weighted mean, relative luminance a second, all drivers together.' }, band: { type: 'number', exclusiveMinimum: 0, exclusiveMaximum: FLASH, description: 'The fastest any band moves.' } }, { description: 'All drivers together.' }),
      place_and_time: obj({ mean: { type: 'number', exclusiveMinimum: 0, exclusiveMaximum: FLASH, description: 'Mean.' }, band: { type: 'number', exclusiveMinimum: 0, exclusiveMaximum: FLASH, description: 'Band.' } }, { description: 'Place and time together.' }),
      mood: obj({ mean: { type: 'number', exclusiveMinimum: 0, exclusiveMaximum: FLASH, description: 'Mean.' }, band: { type: 'number', exclusiveMinimum: 0, exclusiveMaximum: FLASH, description: 'Band.' } }, { description: 'Mood.' }),
      how: str('How the limit is kept.'),
      weights: obj(Object.fromEntries(BANDS.map((b) => [b, pos(`The ${b} band\'s weight in the mean (the four sum to 1: sky-rate-limit).`)])), { description: 'Band weights.' }),
      measured: open({}, 'What the stress test measured (Art\'s generator writes it).'), fastest_allowed: str('The rule in words, with the flash threshold.'),
    }, { description: 'The rate limits.' }),
    mood: obj({
      inputs: obj({ frenzy: str('Input.'), ruin: str('Input.'), glow: str('Input.') }, { description: 'The mood inputs.' }),
      min_seconds_0_to_1: obj({ frenzy: pos('The least seconds the input takes from 0 to 1.'), ruin: pos('Seconds.'), glow: pos('Seconds.') }, { description: 'How fast an input may rise.' }),
      colours: obj({ ember: hex('Ember.'), smoke: hex('Smoke.'), ash: hex('Ash.'), deep: hex('Deep.') }, { description: 'The mood colours.' }),
      frenzy: str('What frenzy does.'), ruin: str('What ruin does.'), glow: str('What glow does.'), order: str('The order they apply in.'),
      never: { type: 'array', minItems: 1, items: str('A thing the sky never does.'), description: 'What the sky never does.' },
    }, { description: 'The mood.' }),
    readability: obj({ lane_colours: obj({ P: hex('The Protagonist\'s lane colour (the default aura: sky-lane-colours).'), A: hex('The Anti-hero\'s lane colour.') }, { description: 'The lane colours.' }), rule: str('The readability rule.'), measured: open({}, 'What was measured.') }, { description: 'Readability against the sky.' }),
  },
};
const HEX2 = obj({ col: hex('The body colour.'), aura: hex('The aura (lane) colour.') });
const MATRIX = { type: 'array', minItems: 3, maxItems: 3, items: { type: 'array', minItems: 3, maxItems: 3, items: { type: 'number' } } };
const RANGE = (d) => ({ type: 'array', minItems: 2, maxItems: 2, items: { type: 'number', minimum: 0 }, description: d });
const FIGHTER_KEY = '^(_.*|[a-z][a-z0-9_]*)$';
const fighterMap = (inner, d) => ({ type: 'object', minProperties: 1, propertyNames: { pattern: FIGHTER_KEY }, additionalProperties: inner, patternProperties: { '^_': true }, description: d });
const CV = {
  $schema: 'https://json-schema.org/draft/2020-12/schema', $id: 'meridian/art-colour-vision', title: 'art colour vision (version 1)',
  description: 'data/art/colour-vision.json: the colour-vision presets (docs/art/colour-vision.md): per fighter the default body and aura colours and, for protan, deutan and tritan vision, the aura that keeps the fighters apart and apart from the sky and the cue marks; the cue set, the hue families and the rule for future fighters. A preset remaps only the aura. Version field: version. Policy: closed except keys starting with an underscore; the measured objects are open. Cross-references in tools/lib/xref-fight.js (colour-vision-fighters: every roster fighter, lower-cased, has a default and a preset in each of the three, and no preset names anyone else; colour-vision-body: a preset keeps the body colour).',
  type: 'object', ...closed, required: ['version', 'note', 'simulation', 'default', 'presets', 'cue_set', 'hue_families', 'rule_for_future_fighters'],
  properties: {
    version: { const: 1 }, note: str('Where the file comes from.'),
    simulation: obj({ model: str('The colour-vision model.'), matrices: obj({ protan: MATRIX, deutan: MATRIX, tritan: MATRIX }, { description: 'The 3 x 3 matrices, applied in linear RGB.' }) }, { description: 'How the presets were simulated.' }),
    default: fighterMap(HEX2, 'The default colours per fighter (a fighter\'s lower-cased roster id).'),
    presets: obj(Object.fromEntries(['protan', 'deutan', 'tritan'].map((p) => [p, {
      type: 'object', required: ['chosen_by', 'measured_dE00_under_this_vision'], propertyNames: { pattern: '^(_.*|[a-z][A-Za-z0-9_]*)$' },
      properties: { chosen_by: str('How the pair was chosen.'), measured_dE00_under_this_vision: open({ between_the_two: num('CIEDE2000 between the two fighters under this vision.', 0) }, 'What was measured.') },
      additionalProperties: HEX2, patternProperties: { '^_': true }, description: `The ${p} preset: each fighter's colours, and how they were chosen.`,
    }])), { description: 'The three presets.' }),
    cue_set: obj({ wound_and_guard_marks: { type: 'object', minProperties: 1, additionalProperties: hex('A mark colour.'), patternProperties: { '^_': true }, description: 'The wound and guard marks.' }, hud_chips_for_ui_to_check: { type: 'object', minProperties: 1, additionalProperties: hex('A chip colour.'), patternProperties: { '^_': true }, description: 'HUD chips UI checks.' }, source: str('Where the colours come from.') }, { description: 'The cue colours the auras are kept apart from.' }),
    hue_families: fighterMap(obj({ h: RANGE('Hue range, degrees.'), l: RANGE('Lightness range.'), s: RANGE('Saturation range.') }), 'Each fighter\'s hue family.'),
    rule_for_future_fighters: { type: 'array', minItems: 1, items: str('A rule.'), description: 'The rule for a fighter who joins the roster.' },
  },
};
{
  for (const [f, s] of [['tools/schemas/art-sky.schema.json', SKY], ['tools/schemas/art-colour-vision.schema.json', CV]]) if (!fs.existsSync(f)) wj(f, s);
  const mf = 'tools/schemas/map.json';
  const m = rj(mf);
  const i = m.rules.findIndex((r) => r.match === 'data/art/auras.json');
  if (i < 0) throw new Error('map.json has no auras rule to put the sky rules after');
  let ch = false;
  for (const [match, schema] of [['data/art/sky.json', 'art-sky.schema.json'], ['data/art/colour-vision.json', 'art-colour-vision.schema.json']]) {
    if (!m.rules.some((r) => r.match === match)) { m.rules.splice(i + 1, 0, { match, schema }); ch = true; }
  }
  if (ch) wj(mf, m);
}

// =============================== xref ===============================
{
  // the rules live in docs/tools/pending/xref-art.js, copied to tools/lib/xref-art.js and called at the start of xrefFight
  fs.copyFileSync('docs/tools/pending/xref-art.js', 'tools/lib/xref-art.js');
  const f = 'tools/lib/xref-fight.js';
  let t = fs.readFileSync(f, 'utf8');
  if (!t.includes("require('./xref-art')")) {
    const a = 'function xrefFight({ get, err, esc, isObj, plainKeys, docsFor }) {\n';
    if (!t.includes(a)) throw new Error('art xref anchor');
    t = t.replace(a, () => a + "  require('./xref-art').xrefArt({ get, err, esc, isObj });\n");
    fs.writeFileSync(f, t);
  }
}

// =============================== cases ===============================
{
  const cf = 'tools/fixtures/cases.json';
  const c = rj(cf);
  const SK = 'data/art/sky.json', CVF = 'data/art/colour-vision.json';
  const sky = rj(SK), cv = rj(CVF);
  const k0 = sky.keys[0], k1 = sky.keys[1];
  const lastId = sky.keys[sky.keys.length - 1].id;
  const fid = Object.keys(cv.default).filter((k) => !k.startsWith('_'));
  const f0 = fid[0];
  const sk = (id, mutate, expect) => ({ id: 'art-sky-' + id, schema: 'art-sky.schema.json', mutate: [{ file: SK, ...mutate }], expect });
  const cvc = (id, mutate, expect) => ({ id: 'art-colour-vision-' + id, schema: 'art-colour-vision.schema.json', mutate: [{ file: CVF, ...mutate }], expect });
  const add = [];
  // ---- the sky
  add.push(sk('valid', { set: { '/version': 1 } }, null));
  for (const k of SKY.required) add.push(sk('key-required-' + k.replace(/_/g, '-'), { del: ['/' + k] }, { rule: 'required', pointer: '' }));
  add.push(
    sk('unknown-key', { set: { '/extra': 1 } }, { rule: 'additionalProperties', pointer: '/extra' }),
    sk('note-ok', { set: { '/_why': 'a note' } }, null),
    sk('version', { set: { '/version': 2 } }, { rule: 'const', pointer: '/version' }),
    sk('bands-order', { set: { '/bands': ['top', 'upper', 'lower', 'horizon'] } }, { rule: 'const', pointer: '/bands' }),
    sk('anchor-negative', { set: { '/anchors_half_screens/lower': -0.1 } }, { rule: 'minimum', pointer: '/anchors_half_screens/lower' }),
    sk('anchor-order', { set: { '/anchors_half_screens/lower': 0.7, '/anchors_half_screens/upper': 0.55 } }, { rule: 'xref:sky-anchor-order', pointer: '/anchors_half_screens/upper' }),
    sk('anchor-type', { set: { '/anchors_half_screens/top': 'high' } }, { rule: 'type', pointer: '/anchors_half_screens/top' }),
    sk('start-key-unknown', { set: { '/start/key': 'twilight' } }, { rule: 'xref:sky-start-key', pointer: '/start/key' }),
    sk('start-key-ok', { set: { '/start/key': k1.id } }, null),
    sk('start-phase-above-one', { set: { '/start/phase': 1.2 } }, { rule: 'maximum', pointer: '/start/phase' }),
    sk('start-phase-negative', { set: { '/start/phase': -0.1 } }, { rule: 'minimum', pointer: '/start/phase' }),
    sk('keys-type', { set: { '/keys': 'five' } }, { rule: 'type', pointer: '/keys' }),
    sk('keys-one', { set: { '/keys': [k0] } }, { rule: 'minItems', pointer: '/keys' }),
    sk('key-id-shape', { set: { '/keys/0/id': 'Noon Day' } }, { rule: 'pattern', pointer: '/keys/0/id' }),
    sk('key-id-twice', { set: { '/keys/1/id': k0.id } }, { rule: 'xref:sky-key-id', pointer: '/keys/1/id' }),
    sk('key-phase-equal', { set: { '/keys/1/phase': k0.phase } }, { rule: 'xref:sky-key-phase', pointer: '/keys/1/phase' }),
    sk('key-phase-falls', { set: { '/keys/1/phase': k0.phase - 0.001 } }, { rule: 'xref:sky-key-phase', pointer: '/keys/1/phase' }),
    sk('key-phase-one', { set: { '/keys/0/phase': 1 } }, { rule: 'exclusiveMaximum', pointer: '/keys/0/phase' }),
    sk('key-phase-negative', { set: { '/keys/0/phase': -0.1 } }, { rule: 'minimum', pointer: '/keys/0/phase' }),
    sk('key-hold-negative', { set: { '/keys/0/hold': -0.01 } }, { rule: 'minimum', pointer: '/keys/0/hold' }),
    sk('key-hold-zero-ok', { set: { '/keys/0/hold': 0 } }, null),
    sk('key-stars-above-one', { set: { '/keys/0/stars': 1.5 } }, { rule: 'maximum', pointer: '/keys/0/stars' }),
    sk('key-stars-negative', { set: { '/keys/0/stars': -0.5 } }, { rule: 'minimum', pointer: '/keys/0/stars' }),
    sk('key-unknown-key', { set: { '/keys/0/mood': 1 } }, { rule: 'additionalProperties', pointer: '/keys/0/mood' }),
    sk('key-note-required', { del: ['/keys/0/note'] }, { rule: 'required', pointer: '/keys/0' }),
    ...BANDS.map((b) => sk('key-band-not-hex-' + b, { set: { ['/keys/0/bands/' + b]: 'blue' } }, { rule: 'pattern', pointer: '/keys/0/bands/' + b })),
    ...BANDS.map((b) => sk('key-band-missing-' + b, { del: ['/keys/0/bands/' + b] }, { rule: 'required', pointer: '/keys/0/bands' })),
    sk('key-band-short-hex', { set: { '/keys/0/bands/top': '#14307' } }, { rule: 'pattern', pointer: '/keys/0/bands/top' }),
    sk('key-band-upper-case-ok', { set: { '/keys/0/bands/top': '#14307A' } }, null),
    sk('blend-space', { set: { '/blend/space': 'rgb' } }, { rule: 'const', pointer: '/blend/space' }),
    sk('blend-ease', { set: { '/blend/ease': 'bounce' } }, { rule: 'enum', pointer: '/blend/ease' }),
    sk('transition-path', { set: { '/blend/transitions/0/lower': 'rgb' } }, { rule: 'enum', pointer: '/blend/transitions/0/lower' }),
    sk('transition-path-ok', { set: { '/blend/transitions/0/lower': 'lch+' } }, null),
    sk('transition-missing-band', { del: ['/blend/transitions/0/top'] }, { rule: 'required', pointer: '/blend/transitions/0' }),
    sk('transition-wrong-next', { set: { '/blend/transitions/0/to': lastId } }, { rule: 'xref:sky-transitions', pointer: '/blend/transitions/0/to' }),
    sk('transition-from-twice', { set: { '/blend/transitions/1/from': sky.blend.transitions[0].from } }, { rule: 'xref:sky-transitions', pointer: '/blend/transitions/1/from' }),
    sk('transitions-one-short', { set: { '/blend/transitions': sky.blend.transitions.slice(1) } }, { rule: 'xref:sky-transitions', pointer: '/blend/transitions' }),
    sk('time-cycle-mismatch', { set: { '/time/cycle_minutes': 40, '/time/cycles_per_minute': 0.0125 } }, { rule: 'xref:sky-time', pointer: '/time/cycle_minutes' }),
    sk('time-cycle-agrees-ok', { set: { '/time/cycle_minutes': 100, '/time/cycles_per_minute': 0.01 } }, null),
    sk('time-zero', { set: { '/time/cycles_per_minute': 0 } }, { rule: 'exclusiveMinimum', pointer: '/time/cycles_per_minute' }),
    sk('place-per-pane-type', { set: { '/place/per_pane': 'yes' } }, { rule: 'type', pointer: '/place/per_pane' }),
    sk('place-cycles-zero', { set: { '/place/cycles_per_lap': 0 } }, { rule: 'exclusiveMinimum', pointer: '/place/cycles_per_lap' }),
  );
  for (const g of ['total', 'place_and_time', 'mood']) for (const kk of ['mean', 'band']) {
    const P = `/rate_limit/${g}/${kk}`;
    add.push(
      sk(`rate-${g.replace(/_/g, '-')}-${kk}-zero`, { set: { [P]: 0 } }, { rule: 'exclusiveMinimum', pointer: P }),
      sk(`rate-${g.replace(/_/g, '-')}-${kk}-negative`, { set: { [P]: -0.01 } }, { rule: 'exclusiveMinimum', pointer: P }),
      sk(`rate-${g.replace(/_/g, '-')}-${kk}-at-the-flash-threshold`, { set: { [P]: 0.1 } }, { rule: 'exclusiveMaximum', pointer: P }),
      sk(`rate-${g.replace(/_/g, '-')}-${kk}-type`, { set: { [P]: 'slow' } }, { rule: 'type', pointer: P }),
    );
  }
  add.push(
    sk('rate-mean-above-band', { set: { '/rate_limit/total/mean': 0.06, '/rate_limit/total/band': 0.05 } }, { rule: 'xref:sky-rate-limit', pointer: '/rate_limit/total/mean' }),
    sk('rate-part-band-above-total', { set: { '/rate_limit/mood/band': 0.09, '/rate_limit/mood/mean': 0.004, '/rate_limit/total/band': 0.05 } }, { rule: 'xref:sky-rate-limit', pointer: '/rate_limit/mood/band' }),
    sk('rate-weights-sum', { set: { '/rate_limit/weights/horizon': 0.3 } }, { rule: 'xref:sky-rate-limit', pointer: '/rate_limit/weights' }),
    sk('rate-weight-zero', { set: { '/rate_limit/weights/top': 0 } }, { rule: 'exclusiveMinimum', pointer: '/rate_limit/weights/top' }),
    sk('rate-measured-open-ok', { set: { '/rate_limit/measured/extra_number': 1 } }, null),
    sk('mood-seconds-zero', { set: { '/mood/min_seconds_0_to_1/frenzy': 0 } }, { rule: 'exclusiveMinimum', pointer: '/mood/min_seconds_0_to_1/frenzy' }),
    sk('mood-colour-not-hex', { set: { '/mood/colours/ember': 'orange' } }, { rule: 'pattern', pointer: '/mood/colours/ember' }),
    sk('mood-never-empty', { set: { '/mood/never': [] } }, { rule: 'minItems', pointer: '/mood/never' }),
    sk('readability-lane-not-hex', { set: { '/readability/lane_colours/P': 'blue' } }, { rule: 'pattern', pointer: '/readability/lane_colours/P' }),
    sk('readability-lane-not-the-default-aura', { set: { '/readability/lane_colours/P': '#8fd6fe' } }, { rule: 'xref:sky-lane-colours', pointer: '/readability/lane_colours/P' }),
    sk('readability-lane-case-ok', { set: { '/readability/lane_colours/P': cv.default.protagonist.aura.toUpperCase() } }, null),
  );
  // ---- the colour-vision presets
  add.push(cvc('valid', { set: { '/version': 1 } }, null));
  for (const k of CV.required) add.push(cvc('key-required-' + k.replace(/_/g, '-'), { del: ['/' + k] }, { rule: 'required', pointer: '' }));
  add.push(
    cvc('unknown-key', { set: { '/extra': 1 } }, { rule: 'additionalProperties', pointer: '/extra' }),
    cvc('note-ok', { set: { '/_why': 'a note' } }, null),
    cvc('version', { set: { '/version': 2 } }, { rule: 'const', pointer: '/version' }),
    cvc('matrix-row-short', { set: { '/simulation/matrices/protan/0': [0.1, 0.2] } }, { rule: 'minItems', pointer: '/simulation/matrices/protan/0' }),
    cvc('matrix-rows', { set: { '/simulation/matrices/deutan': [[1, 0, 0], [0, 1, 0]] } }, { rule: 'minItems', pointer: '/simulation/matrices/deutan' }),
    cvc('matrix-cell-type', { set: { '/simulation/matrices/tritan/1/1': 'x' } }, { rule: 'type', pointer: '/simulation/matrices/tritan/1/1' }),
    cvc('matrix-missing-vision', { del: ['/simulation/matrices/tritan'] }, { rule: 'required', pointer: '/simulation/matrices' }),
    cvc('default-col-not-hex', { set: { [`/default/${f0}/col`]: 'blue' } }, { rule: 'pattern', pointer: `/default/${f0}/col` }),
    cvc('default-aura-not-hex', { set: { [`/default/${f0}/aura`]: '#12345' } }, { rule: 'pattern', pointer: `/default/${f0}/aura` }),
    cvc('default-aura-missing', { del: [`/default/${f0}/aura`] }, { rule: 'required', pointer: `/default/${f0}` }),
    cvc('default-unknown-key', { set: { [`/default/${f0}/glow`]: '#ffffff' } }, { rule: 'additionalProperties', pointer: `/default/${f0}/glow` }),
    cvc('default-fighter-key-shape', { set: { '/default/Bad Name': { col: '#112233', aura: '#445566' } } }, { rule: 'propertyNames', pointer: '/default/Bad Name' }),
    cvc('default-fighter-without-presets', { set: { '/default/nobody': { col: '#112233', aura: '#445566' } } }, { rule: 'xref:colour-vision-fighters', pointer: '/presets/protan' }),
    cvc('default-fighter-missing-but-in-the-presets', { del: [`/default/${f0}`] }, { rule: 'xref:colour-vision-fighters', pointer: `/presets/protan/${f0}` }),
  );
  for (const p of ['protan', 'deutan', 'tritan']) {
    add.push(
      cvc(`${p}-required`, { del: [`/presets/${p}`] }, { rule: 'required', pointer: '/presets' }),
      cvc(`${p}-fighter-missing`, { del: [`/presets/${p}/${f0}`] }, { rule: 'xref:colour-vision-fighters', pointer: `/presets/${p}` }),
      cvc(`${p}-aura-not-hex`, { set: { [`/presets/${p}/${f0}/aura`]: 'teal' } }, { rule: 'pattern', pointer: `/presets/${p}/${f0}/aura` }),
      cvc(`${p}-aura-changes-ok`, { set: { [`/presets/${p}/${f0}/aura`]: '#123456' } }, null),
      cvc(`${p}-body-changed`, { set: { [`/presets/${p}/${f0}/col`]: '#123456' } }, { rule: 'xref:colour-vision-body', pointer: `/presets/${p}/${f0}/col` }),
      cvc(`${p}-body-case-ok`, { set: { [`/presets/${p}/${f0}/col`]: cv.presets[p][f0].col.toUpperCase() } }, null),
      cvc(`${p}-fighter-without-default`, { set: { [`/presets/${p}/nobody`]: { col: '#112233', aura: '#445566' } } }, { rule: 'xref:colour-vision-fighters', pointer: `/presets/${p}/nobody` }),
      cvc(`${p}-chosen-by-required`, { del: [`/presets/${p}/chosen_by`] }, { rule: 'required', pointer: `/presets/${p}` }),
      cvc(`${p}-measured-required`, { del: [`/presets/${p}/measured_dE00_under_this_vision`] }, { rule: 'required', pointer: `/presets/${p}` }),
      cvc(`${p}-between-negative`, { set: { [`/presets/${p}/measured_dE00_under_this_vision/between_the_two`]: -1 } }, { rule: 'minimum', pointer: `/presets/${p}/measured_dE00_under_this_vision/between_the_two` }),
    );
  }
  const cueName = Object.keys(cv.cue_set.wound_and_guard_marks)[0];
  add.push(
    cvc('cue-not-hex', { set: { [`/cue_set/wound_and_guard_marks/${cueName}`]: 'cyan' } }, { rule: 'pattern', pointer: `/cue_set/wound_and_guard_marks/${cueName}` }),
    cvc('cue-set-empty', { set: { '/cue_set/wound_and_guard_marks': {} } }, { rule: 'minProperties', pointer: '/cue_set/wound_and_guard_marks' }),
    cvc('hue-range-short', { set: { [`/hue_families/${f0}/h`]: [150] } }, { rule: 'minItems', pointer: `/hue_families/${f0}/h` }),
    cvc('hue-range-negative', { set: { [`/hue_families/${f0}/l`]: [-1, 88] } }, { rule: 'minimum', pointer: `/hue_families/${f0}/l/0` }),
    cvc('hue-range-missing-s', { del: [`/hue_families/${f0}/s`] }, { rule: 'required', pointer: `/hue_families/${f0}` }),
    cvc('rule-empty', { set: { '/rule_for_future_fighters': [] } }, { rule: 'minItems', pointer: '/rule_for_future_fighters' }),
    cvc('rule-item-type', { set: { '/rule_for_future_fighters': [5] } }, { rule: 'type', pointer: '/rule_for_future_fighters/0' }),
  );
  let n = 0;
  for (const k of add) {
    const i = c.cases.findIndex((y) => y.id === k.id);
    if (i < 0) { c.cases.push(k); n++; } else if (JSON.stringify(c.cases[i]) !== JSON.stringify(k)) { c.cases[i] = k; n++; }
  }
  wj(cf, c);
  console.log(`art sky and colour-vision schemas applied (${n} new cases)`);
}

// =============================== docs ===============================
{
  const f = 'docs/tools/README.md';
  const t = fs.readFileSync(f, 'utf8');
  const lines = t.split('\n');
  const i = ['`ai-digin-fighter`', '`pressstyles-strength`', '`reach-keyset`', '`brawl-order`'].map((k) => lines.findIndex((l) => l.includes(k))).find((x) => x >= 0);
  if (i === undefined) throw new Error('art README anchor');
  const rows = [
    ['`sky-key-id`', '| `sky-key-id`, `sky-key-phase` | data/art/sky.json: key ids are unique; key phases start at or above 0, strictly increase and stay below 1 |'],
    ['`sky-start-key`', '| `sky-start-key`, `sky-anchor-order` | data/art/sky.json: start.key is a key id; the band anchors rise from the horizon to the top |'],
    ['`sky-transitions`', '| `sky-transitions` | data/art/sky.json: the transitions are the cycle of the keys (key i to key i+1, the last to the first, each once) |'],
    ['`sky-time`', '| `sky-time`, `sky-rate-limit` | data/art/sky.json: cycle_minutes is 1 / cycles_per_minute; every rate-limit mean is at most its band, every band is positive and below the flash threshold 0.10 (fixed in the schema), the total band is at least the others, the band weights sum to 1 |'],
    ['`sky-lane-colours`', '| `sky-lane-colours` | data/art/sky.json readability.lane_colours are the default auras of data/art/colour-vision.json |'],
    ['`colour-vision-fighters`', "| `colour-vision-fighters`, `colour-vision-body` | data/art/colour-vision.json: every roster fighter (lower-cased) has a default and a preset in protan, deutan and tritan, no preset or default names anyone else, and a preset keeps each fighter's body colour |"],
  ].filter(([key]) => !t.includes(key)).map(([, row]) => row);
  if (rows.length) { lines.splice(i + 1, 0, ...rows); fs.writeFileSync(f, lines.join('\n')); }
}
