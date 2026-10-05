// Schema for Simulation's dynamic intros: data/fight/intro.json becomes fight.intro/2 (docs/architecture/pending/dynamic-intros.md section 11; the
// file is docs/architecture/pending/dynamic-intros/src/intro.json). The shape is REPLACED, not extended. NOT run by CI, the validator or the sim.
// Run once from the repo root, in the commit where Simulation lands the file (after World's stages script, which also edits cases.json):
//     node docs/tools/pending/apply-intro2.cjs
// It does NOT edit data/. It replaces tools/schemas/fight-intro.schema.json (fight.intro/2), replaces the validator fixture
// tools/fixtures/virtual/data/fight/intro.json (from the live file if it is fight.intro/2, else from Simulation's parked file), drops the
// fight.intro/1 cases, replaces the v1 rules in tools/lib/xref-fight.js (intro-order on `ticks`, and intro-staredown, which measured the
// anim opening against a staredown that is no longer a number in the data) by intro-order, intro-pool, intro-part, intro-classic and intro-id,
// and adds the cases. Re-runnable (a second run changes nothing).
const fs = require('fs');
const rj = (f) => JSON.parse(fs.readFileSync(f, 'utf8'));
const wj = (f, o) => fs.writeFileSync(f, JSON.stringify(o, null, 2) + '\n');
const closed = { additionalProperties: false, patternProperties: { '^_': true } };
const obj = (props, opts = {}) => Object.assign({ type: 'object', required: opts.required === undefined ? Object.keys(props) : opts.required, properties: props }, opts.description ? { description: opts.description } : {}, closed);
const clone = (o) => JSON.parse(JSON.stringify(o));
const int0 = (d) => ({ type: 'integer', minimum: 0, description: d });
const WHO = ['first', 'second', 'left', 'right'];

const SRC = 'docs/architecture/pending/dynamic-intros/src/intro.json';
const LIVE = 'data/fight/intro.json';
const liveIsV2 = fs.existsSync(LIVE) && rj(LIVE).schema === 'fight.intro/2';
const source = liveIsV2 ? LIVE : SRC;
if (!fs.existsSync(source)) { console.error(`apply-intro2: ${source} is not there.`); process.exit(1); }

// =============================== schema ===============================
{
  const f = 'tools/schemas/fight-intro.schema.json';
  const old = rj(f);
  if (old.properties && old.properties.schema && old.properties.schema.const === 'fight.intro/1') {
    const beat = Object.assign({
      type: 'object',
      required: ['t', 'kind'],
      properties: {
        t: { type: 'integer', description: 'Ticks from the part\'s start.' },
        kind: { enum: ['fall', 'land', 'wait', 'line', 'staredown', 'gesture'] },
        intent: { type: 'string', pattern: '^[a-z][a-z0-9_]*$', description: 'What the line or the gesture says or means.' },
        who: { enum: WHO, description: 'Overrides the slot\'s role for this beat.' },
      },
      allOf: [{ if: { properties: { kind: { enum: ['line', 'gesture'] } }, required: ['kind'] }, then: { required: ['intent'] } }],
    }, closed);
    const part = Object.assign({
      type: 'object',
      required: ['type', 'ticks', 'beats'],
      properties: {
        type: { enum: ['entrance', 'reaction', 'look'] },
        mode: { type: 'string', pattern: '^[a-z][a-z0-9_]*$', description: 'The arrival mode an entrance reports.' },
        ticks: int0('How far the part moves the template on.'),
        beats: { type: 'array', items: beat },
      },
      allOf: [{ if: { properties: { type: { const: 'entrance' } }, required: ['type'] }, then: { required: ['mode'] } }],
      description: 'A short list of beats, with ticks from the part\'s start.',
    }, closed);
    const slot = obj({
      slot: { type: 'string', pattern: '^[a-z][a-z0-9_]*$', description: 'A label.' },
      who: { enum: [...WHO, 'both'] },
      pool: { type: 'array', minItems: 1, uniqueItems: true, items: { type: 'string', pattern: '^[a-z][a-z0-9_]*$' }, description: 'The parts that may fill the slot.' },
      after: int0('Ticks after the slot before it ends.'),
      gap: { type: 'boolean', description: 'Add the drawn gap.' },
      with: { type: 'boolean', description: 'Run alongside, without moving the template on.' },
      draw: { type: 'boolean', description: 'false: the part is not left to chance.' },
    }, { required: ['slot', 'who', 'pool'] });
    const template = obj({
      id: { type: 'string', pattern: '^[a-z][a-z0-9_]*$' },
      weight: { type: 'number', minimum: 0, description: 'The draw\'s weight.' },
      tone: { enum: ['light', 'neutral', 'grave'] },
      clock: int0('The intro\'s length in ticks. The look takes what is left.'),
      gap: obj({ min: int0('The shortest gap.'), max: int0('The longest gap.'), default: int0('The default gap.') }, { description: 'Ticks from the first landing to the second fall.' }),
      notTwice: { type: 'boolean', description: 'Never right after itself.' },
      classic: { type: 'boolean', description: 'The one a plain `true` plays.' },
      slots: { type: 'array', minItems: 1, items: slot },
    }, { required: ['id', 'weight', 'tone', 'clock', 'gap', 'slots'] });
    wj(f, {
      $schema: 'https://json-schema.org/draft/2020-12/schema',
      $id: 'meridian/fight-intro',
      title: 'fight.intro/2 (docs/architecture/pending/dynamic-intros.md)',
      description: 'data/fight/intro.json: the intro phase, as templates and parts (sim/core/intro.gd plays it; sim/director/intro.gd picks it). Ticks are sim ticks (60 a second). A template is a scenario: an ordered list of slots, each filled by one part from its pool; a part is a short list of beats with ticks from its start. Roles: first and second by arrival; left and right by start spot; both. skipFrom: a press on a human slot skips from this tick; fallHeight and craterEnergy shape the entrances; clockBend: the most the host\'s facts may shorten (min, 0 or less) or lengthen (max, 0 or more) a template, in ticks; gesturePoints: where a facts gesture plays (ticks after land_first, land_second, wait and look_start; look_end counted back from the clock). Version field: schema. Policy: closed except keys starting with an underscore. Cross-references (every pool id is a part; every entrance has one fall and one land; exactly one template is classic; ids are unique; a gap runs min to default to max; skipFrom is before every clock) are checked by tools/lib/xref-fight.js (intro-*). The loader checks that a template fits its clock.',
      type: 'object',
      required: ['schema', 'skipFrom', 'fallHeight', 'craterEnergy', 'clockBend', 'gesturePoints', 'parts', 'templates'],
      properties: {
        schema: { const: 'fight.intro/2' },
        skipFrom: int0('A press on a human slot skips from this tick.'),
        fallHeight: { type: 'number', exclusiveMinimum: 0, description: 'The height a fighter falls from.' },
        craterEnergy: { type: 'number', minimum: 0, description: 'The crater energy of an entrance.' },
        clockBend: obj({ min: { type: 'integer', maximum: 0, description: 'The most a template may be shortened (0 or less).' }, max: { type: 'integer', minimum: 0, description: 'The most a template may be lengthened (0 or more).' } }),
        gesturePoints: obj({
          land_first: int0('Ticks after the first landing.'),
          land_second: int0('Ticks after the second landing.'),
          wait: int0('Ticks into the wait.'),
          look_start: { type: 'integer', minimum: 0, description: 'Ticks into the look.' },
          look_end: { type: 'integer', maximum: 0, description: 'Counted back from the clock (0 or less).' },
        }),
        parts: { type: 'object', minProperties: 1, propertyNames: { pattern: '^(_.*|[a-z][a-z0-9_]*)$' }, additionalProperties: part, patternProperties: { '^_': true } },
        templates: { type: 'array', minItems: 1, items: template },
      },
      additionalProperties: false,
      patternProperties: { '^_': true },
    });
  }
}

// =============================== fixture ===============================
{
  const f = 'tools/fixtures/virtual/data/fight/intro.json';
  const o = rj(f);
  if (o.schema !== 'fight.intro/2') {
    const src = rj(source);
    const out = { _about: 'Validator fixture, not game data: Simulation\'s dynamic intros.' };
    for (const k of Object.keys(src)) if (k !== '_about') out[k] = src[k];
    wj(f, out);
  }
}

// =============================== xref ===============================
{
  const f = 'tools/lib/xref-fight.js';
  let t = fs.readFileSync(f, 'utf8');
  if (!t.includes("'intro-pool'")) {
    const start = t.indexOf('  // ---- fight intro: the timeline runs in order; the animation\'s opening fits its staredown ----');
    const end = t.indexOf('  // ---- anim last stand: ready keys are shapes, sequences exist ----');
    if (start < 0 || end < 0 || end < start) throw new Error('intro v1 block not found');
    const block = [
      "  // ---- fight intro: the templates' slots name parts, entrances have one fall and one land, one template is classic ----",
      "  const fint = get('data/fight/intro.json');",
      "  if (isObj(fint) && Array.isArray(fint.templates)) {",
      "    const IT2 = 'data/fight/intro.json';",
      "    const parts = isObj(fint.parts) ? fint.parts : {};",
      "    for (const [pid, p] of Object.entries(parts)) {",
      "      if (pid.startsWith('_') || !isObj(p) || p.type !== 'entrance' || !Array.isArray(p.beats)) continue;",
      "      const falls = p.beats.filter((b) => isObj(b) && b.kind === 'fall').length;",
      "      const lands = p.beats.filter((b) => isObj(b) && b.kind === 'land').length;",
      "      if (falls !== 1 || lands !== 1) err(IT2, `/parts/${esc(pid)}/beats`, 'intro-part', `entrance \"${pid}\" has ${falls} fall and ${lands} land beats; it needs exactly one of each`);",
      "    }",
      "    const ids = new Map();",
      "    let classics = 0;",
      "    let minClock = Infinity;",
      "    fint.templates.forEach((tp, i) => {",
      "      if (!isObj(tp)) return;",
      "      const at = `/templates/${i}`;",
      "      if (typeof tp.id === 'string') { if (ids.has(tp.id)) err(IT2, `${at}/id`, 'intro-id', `template id \"${tp.id}\" is already used at /templates/${ids.get(tp.id)}`); else ids.set(tp.id, i); }",
      "      if (tp.classic === true) classics++;",
      "      if (typeof tp.clock === 'number') minClock = Math.min(minClock, tp.clock);",
      "      if (isObj(tp.gap) && typeof tp.gap.min === 'number' && typeof tp.gap.max === 'number' && typeof tp.gap.default === 'number') {",
      "        if (tp.gap.min > tp.gap.default) err(IT2, `${at}/gap/min`, 'intro-order', `gap min ${tp.gap.min} is above the default ${tp.gap.default}`);",
      "        if (tp.gap.default > tp.gap.max) err(IT2, `${at}/gap/default`, 'intro-order', `gap default ${tp.gap.default} is above max ${tp.gap.max}`);",
      "      }",
      "      if (Array.isArray(tp.slots)) tp.slots.forEach((s, j) => { if (isObj(s) && Array.isArray(s.pool)) s.pool.forEach((pid, k) => { if (typeof pid === 'string' && !(pid in parts)) err(IT2, `${at}/slots/${j}/pool/${k}`, 'intro-pool', `slot \"${s.slot}\" names part \"${pid}\", which is not in parts (${Object.keys(parts).filter((x) => !x.startsWith('_')).join(', ')})`); }); });",
      "    });",
      "    if (classics !== 1) err(IT2, '/templates', 'intro-classic', `${classics} templates are classic; exactly one must be (the one a plain \"intro\": true plays)`);",
      "    if (typeof fint.skipFrom === 'number' && minClock !== Infinity && fint.skipFrom >= minClock) err(IT2, '/skipFrom', 'intro-order', `skipFrom ${fint.skipFrom} is not before the shortest clock (${minClock})`);",
      "  }",
      "",
    ].join('\n');
    t = t.slice(0, start) + block + t.slice(end);
    fs.writeFileSync(f, t);
  }
}

// =============================== cases ===============================
{
  const cf = 'tools/fixtures/cases.json';
  const c = rj(cf);
  // the fight.intro/1 cases go, and the two anim-intro cases that measured against the v1 staredown
  const drop = new Set(['anim-intro-tense-lead-longer-than-staredown-warns', 'anim-intro-beat-ends-after-staredown-warns']);
  const before = c.cases.length;
  c.cases = c.cases.filter((k) => (k.schema !== 'fight-intro.schema.json' || k.id.startsWith('fight-intro-')) && !drop.has(k.id));
  const dropped = before - c.cases.length;
  const F = 'data/fight/intro.json';
  const fx = rj('tools/fixtures/virtual/data/fight/intro.json');
  const tplIds = fx.templates.map((x) => x.id);
  const partIds = Object.keys(fx.parts).filter((k) => !k.startsWith('_'));
  const entrance = partIds.find((k) => fx.parts[k].type === 'entrance');
  const T0 = '/templates/0/';
  const x = (n, mut, expect) => ({ id: 'fight-intro-' + n, schema: 'fight-intro.schema.json', mutate: [{ file: F, ...mut }], expect });
  const ent = { type: 'entrance', mode: 'drop', ticks: 36, beats: [{ t: 0, kind: 'fall' }, { t: 36, kind: 'land' }] };
  const slot = { slot: 'entrance', who: 'first', pool: [entrance] };
  const tpl = (over) => Object.assign({ id: 'extra', weight: 1, tone: 'neutral', clock: 300, gap: { min: 30, default: 48, max: 70 }, slots: [clone(slot)] }, over);
  const add = [
    x('live-valid', { set: { '/skipFrom': 30 } }, null),
    x('schema-version', { set: { '/schema': 'fight.intro/1' } }, { rule: 'const', pointer: '/schema' }),
    x('unknown-key', { set: { '/extra': 1 } }, { rule: 'additionalProperties', pointer: '/extra' }),
    x('underscore-key-ok', { set: { '/_why': 'comment' } }, null),
    x('ticks-retired', { set: { '/ticks': { fallA: 0 } } }, { rule: 'additionalProperties', pointer: '/ticks' }),
    ...['skipFrom', 'fallHeight', 'craterEnergy', 'clockBend', 'gesturePoints', 'parts', 'templates'].map((k) => x('key-required-' + k, { del: ['/' + k] }, { rule: 'required', pointer: '' })),
    x('skip-from-negative', { set: { '/skipFrom': -1 } }, { rule: 'minimum', pointer: '/skipFrom' }),
    x('skip-from-integer', { set: { '/skipFrom': 30.5 } }, { rule: 'type', pointer: '/skipFrom' }),
    x('skip-from-zero-ok', { set: { '/skipFrom': 0 } }, null),
    x('skip-from-not-before-the-shortest-clock', { set: { '/skipFrom': 9999 } }, { rule: 'xref:intro-order', pointer: '/skipFrom' }),
    x('fall-height-zero', { set: { '/fallHeight': 0 } }, { rule: 'exclusiveMinimum', pointer: '/fallHeight' }),
    x('fall-height-type', { set: { '/fallHeight': 'high' } }, { rule: 'type', pointer: '/fallHeight' }),
    x('crater-energy-negative', { set: { '/craterEnergy': -1 } }, { rule: 'minimum', pointer: '/craterEnergy' }),
    x('crater-energy-zero-ok', { set: { '/craterEnergy': 0 } }, null),
    // clockBend and gesturePoints
    x('clock-bend-key-required', { set: { '/clockBend': { min: -60 } } }, { rule: 'required', pointer: '/clockBend' }),
    x('clock-bend-min-positive', { set: { '/clockBend': { min: 10, max: 60 } } }, { rule: 'maximum', pointer: '/clockBend/min' }),
    x('clock-bend-max-negative', { set: { '/clockBend': { min: -60, max: -10 } } }, { rule: 'minimum', pointer: '/clockBend/max' }),
    x('clock-bend-integer', { set: { '/clockBend': { min: -60.5, max: 60 } } }, { rule: 'type', pointer: '/clockBend/min' }),
    x('clock-bend-zero-ok', { set: { '/clockBend': { min: 0, max: 0 } } }, null),
    x('clock-bend-unknown-key', { set: { '/clockBend': { min: -60, max: 60, mid: 0 } } }, { rule: 'additionalProperties', pointer: '/clockBend/mid' }),
    x('gesture-points-key-required', { set: { '/gesturePoints': { land_first: 12, land_second: 12, wait: 20, look_start: 24 } } }, { rule: 'required', pointer: '/gesturePoints' }),
    x('gesture-points-unknown-name', { set: { '/gesturePoints': { land_first: 12, land_second: 12, wait: 20, look_start: 24, look_end: -48, fall: 3 } } }, { rule: 'additionalProperties', pointer: '/gesturePoints/fall' }),
    x('gesture-points-look-start-negative', { set: { '/gesturePoints': { land_first: 12, land_second: 12, wait: 20, look_start: -1, look_end: -48 } } }, { rule: 'minimum', pointer: '/gesturePoints/look_start' }),
    x('gesture-points-look-end-positive', { set: { '/gesturePoints': { land_first: 12, land_second: 12, wait: 20, look_start: 24, look_end: 5 } } }, { rule: 'maximum', pointer: '/gesturePoints/look_end' }),
    x('gesture-points-wait-negative', { set: { '/gesturePoints': { land_first: 12, land_second: 12, wait: -1, look_start: 24, look_end: -48 } } }, { rule: 'minimum', pointer: '/gesturePoints/wait' }),
    x('gesture-points-integer', { set: { '/gesturePoints': { land_first: 12.5, land_second: 12, wait: 20, look_start: 24, look_end: -48 } } }, { rule: 'type', pointer: '/gesturePoints/land_first' }),
    // parts
    x('parts-empty', { set: { '/parts': {} } }, { rule: 'minProperties', pointer: '/parts' }),
    x('part-id-shape', { set: { '/parts/Big Drop': clone(ent) } }, { rule: 'propertyNames', pointer: '/parts/Big Drop' }),
    x('part-ok', { set: { '/parts/extra_drop': clone(ent) } }, null),
    x('part-note-ok', { set: { '/parts/_why': 'comment' } }, null),
    x('part-type-enum', { set: { '/parts/extra_drop': Object.assign(clone(ent), { type: 'dance' }) } }, { rule: 'enum', pointer: '/parts/extra_drop/type' }),
    x('part-key-required', { set: { '/parts/extra_drop': { type: 'look', beats: [] } } }, { rule: 'required', pointer: '/parts/extra_drop' }),
    x('part-unknown-key', { set: { '/parts/extra_drop': Object.assign(clone(ent), { loud: true }) } }, { rule: 'additionalProperties', pointer: '/parts/extra_drop/loud' }),
    x('entrance-needs-mode', { set: { '/parts/extra_drop': { type: 'entrance', ticks: 36, beats: clone(ent.beats) } } }, { rule: 'required', pointer: '/parts/extra_drop' }),
    x('reaction-needs-no-mode-ok', { set: { '/parts/extra_wait': { type: 'reaction', ticks: 0, beats: [{ t: 14, kind: 'wait' }] } } }, null),
    x('part-ticks-negative', { set: { '/parts/extra_drop': Object.assign(clone(ent), { ticks: -1 }) } }, { rule: 'minimum', pointer: '/parts/extra_drop/ticks' }),
    x('part-ticks-integer', { set: { '/parts/extra_drop': Object.assign(clone(ent), { ticks: 36.5 }) } }, { rule: 'type', pointer: '/parts/extra_drop/ticks' }),
    x('part-mode-shape', { set: { '/parts/extra_drop': Object.assign(clone(ent), { mode: 'Big Drop' }) } }, { rule: 'pattern', pointer: '/parts/extra_drop/mode' }),
    x('beat-key-required', { set: { '/parts/extra_drop': Object.assign(clone(ent), { beats: [{ kind: 'fall' }, { t: 36, kind: 'land' }] }) } }, { rule: 'required', pointer: '/parts/extra_drop/beats/0' }),
    x('beat-t-integer', { set: { '/parts/extra_drop': Object.assign(clone(ent), { beats: [{ t: 0.5, kind: 'fall' }, { t: 36, kind: 'land' }] }) } }, { rule: 'type', pointer: '/parts/extra_drop/beats/0/t' }),
    x('beat-kind-enum', { set: { '/parts/extra_drop': Object.assign(clone(ent), { beats: [{ t: 0, kind: 'jump' }, { t: 36, kind: 'land' }] }) } }, { rule: 'enum', pointer: '/parts/extra_drop/beats/0/kind' }),
    x('beat-who-enum', { set: { '/parts/extra_drop': Object.assign(clone(ent), { beats: [{ t: 0, kind: 'fall', who: 'both' }, { t: 36, kind: 'land' }] }) } }, { rule: 'enum', pointer: '/parts/extra_drop/beats/0/who' }),
    x('beat-who-left-ok', { set: { '/parts/extra_drop': Object.assign(clone(ent), { beats: [{ t: 0, kind: 'fall', who: 'left' }, { t: 36, kind: 'land' }] }) } }, null),
    x('beat-unknown-key', { set: { '/parts/extra_drop': Object.assign(clone(ent), { beats: [{ t: 0, kind: 'fall', loud: 1 }, { t: 36, kind: 'land' }] }) } }, { rule: 'additionalProperties', pointer: '/parts/extra_drop/beats/0/loud' }),
    x('line-needs-intent', { set: { '/parts/extra_line': { type: 'reaction', ticks: 0, beats: [{ t: 10, kind: 'line' }] } } }, { rule: 'required', pointer: '/parts/extra_line/beats/0' }),
    x('line-with-intent-ok', { set: { '/parts/extra_line': { type: 'reaction', ticks: 0, beats: [{ t: 10, kind: 'line', intent: 'remark', who: 'first' }] } } }, null),
    x('gesture-needs-intent', { set: { '/parts/extra_line': { type: 'reaction', ticks: 0, beats: [{ t: 10, kind: 'gesture' }] } } }, { rule: 'required', pointer: '/parts/extra_line/beats/0' }),
    x('gesture-with-intent-ok', { set: { '/parts/extra_line': { type: 'reaction', ticks: 0, beats: [{ t: 10, kind: 'gesture', intent: 'acknowledge' }] } } }, null),
    x('intent-shape', { set: { '/parts/extra_line': { type: 'reaction', ticks: 0, beats: [{ t: 10, kind: 'line', intent: 'Wait Remark' }] } } }, { rule: 'pattern', pointer: '/parts/extra_line/beats/0/intent' }),
    x('wait-needs-no-intent-ok', { set: { '/parts/extra_line': { type: 'reaction', ticks: 0, beats: [{ t: 10, kind: 'wait' }] } } }, null),
    x('entrance-without-a-fall', { set: { '/parts/extra_drop': Object.assign(clone(ent), { beats: [{ t: 36, kind: 'land' }] }) } }, { rule: 'xref:intro-part', pointer: '/parts/extra_drop/beats' }),
    x('entrance-without-a-land', { set: { '/parts/extra_drop': Object.assign(clone(ent), { beats: [{ t: 0, kind: 'fall' }] }) } }, { rule: 'xref:intro-part', pointer: '/parts/extra_drop/beats' }),
    x('entrance-with-two-falls', { set: { '/parts/extra_drop': Object.assign(clone(ent), { beats: [{ t: 0, kind: 'fall' }, { t: 5, kind: 'fall' }, { t: 36, kind: 'land' }] }) } }, { rule: 'xref:intro-part', pointer: '/parts/extra_drop/beats' }),
    // templates
    x('templates-empty', { set: { '/templates': [] } }, { rule: 'minItems', pointer: '/templates' }),
    x('template-key-required', { del: [T0 + 'clock'] }, { rule: 'required', pointer: '/templates/0' }),
    x('template-unknown-key', { set: { [T0 + 'colour']: 'red' } }, { rule: 'additionalProperties', pointer: T0 + 'colour' }),
    x('template-note-ok', { set: { [T0 + '_why']: 'comment' } }, null),
    x('template-id-shape', { set: { [T0 + 'id']: 'Double Drop' } }, { rule: 'pattern', pointer: T0 + 'id' }),
    x('template-id-twice', { set: { '/templates/1/id': tplIds[0] } }, { rule: 'xref:intro-id', pointer: '/templates/1/id' }),
    x('template-weight-negative', { set: { [T0 + 'weight']: -1 } }, { rule: 'minimum', pointer: T0 + 'weight' }),
    x('template-weight-zero-ok', { set: { '/templates/1/weight': 0 } }, null),
    x('template-tone-enum', { set: { [T0 + 'tone']: 'angry' } }, { rule: 'enum', pointer: T0 + 'tone' }),
    x('template-clock-negative', { set: { [T0 + 'clock']: -1 } }, { rule: 'minimum', pointer: T0 + 'clock' }),
    x('template-clock-integer', { set: { [T0 + 'clock']: 300.5 } }, { rule: 'type', pointer: T0 + 'clock' }),
    x('template-gap-key-required', { set: { [T0 + 'gap']: { min: 30, max: 70 } } }, { rule: 'required', pointer: T0 + 'gap' }),
    x('template-gap-min-above-default', { set: { [T0 + 'gap']: { min: 60, default: 48, max: 70 } } }, { rule: 'xref:intro-order', pointer: T0 + 'gap/min' }),
    x('template-gap-default-above-max', { set: { [T0 + 'gap']: { min: 30, default: 80, max: 70 } } }, { rule: 'xref:intro-order', pointer: T0 + 'gap/default' }),
    x('template-gap-equal-ok', { set: { [T0 + 'gap']: { min: 48, default: 48, max: 48 } } }, null),
    x('template-gap-negative', { set: { [T0 + 'gap']: { min: -1, default: 48, max: 70 } } }, { rule: 'minimum', pointer: T0 + 'gap/min' }),
    x('template-not-twice-type', { set: { [T0 + 'notTwice']: 'yes' } }, { rule: 'type', pointer: T0 + 'notTwice' }),
    x('template-classic-type', { set: { [T0 + 'classic']: 1 } }, { rule: 'type', pointer: T0 + 'classic' }),
    x('no-classic-template', { set: { [T0 + 'classic']: false } }, { rule: 'xref:intro-classic', pointer: '/templates' }),
    x('two-classic-templates', { set: { '/templates/1/classic': true } }, { rule: 'xref:intro-classic', pointer: '/templates' }),
    x('template-ok', { set: { '/templates/-': tpl({ id: 'extra_one' }) } }, null),
    // slots
    x('slots-empty', { set: { [T0 + 'slots']: [] } }, { rule: 'minItems', pointer: T0 + 'slots' }),
    x('slot-key-required', { set: { [T0 + 'slots/0']: { slot: 'entrance', who: 'first' } } }, { rule: 'required', pointer: T0 + 'slots/0' }),
    x('slot-unknown-key', { set: { [T0 + 'slots/0/loud']: true } }, { rule: 'additionalProperties', pointer: T0 + 'slots/0/loud' }),
    x('slot-label-shape', { set: { [T0 + 'slots/0/slot']: 'The Entrance' } }, { rule: 'pattern', pointer: T0 + 'slots/0/slot' }),
    x('slot-who-enum', { set: { [T0 + 'slots/0/who']: 'nobody' } }, { rule: 'enum', pointer: T0 + 'slots/0/who' }),
    x('slot-who-both-ok', { set: { [T0 + 'slots/0/who']: 'both' } }, null),
    x('slot-pool-empty', { set: { [T0 + 'slots/0/pool']: [] } }, { rule: 'minItems', pointer: T0 + 'slots/0/pool' }),
    x('slot-pool-duplicate', { set: { [T0 + 'slots/0/pool']: [entrance, entrance] } }, { rule: 'uniqueItems', pointer: T0 + 'slots/0/pool/1' }),
    x('slot-pool-unknown-part', { set: { [T0 + 'slots/0/pool']: ['nowhere'] } }, { rule: 'xref:intro-pool', pointer: T0 + 'slots/0/pool/0' }),
    x('slot-after-negative', { set: { [T0 + 'slots/0/after']: -1 } }, { rule: 'minimum', pointer: T0 + 'slots/0/after' }),
    x('slot-after-integer', { set: { [T0 + 'slots/0/after']: 80.5 } }, { rule: 'type', pointer: T0 + 'slots/0/after' }),
    x('slot-gap-type', { set: { [T0 + 'slots/0/gap']: 'yes' } }, { rule: 'type', pointer: T0 + 'slots/0/gap' }),
    x('slot-with-type', { set: { [T0 + 'slots/0/with']: 1 } }, { rule: 'type', pointer: T0 + 'slots/0/with' }),
    x('slot-draw-type', { set: { [T0 + 'slots/0/draw']: 'no' } }, { rule: 'type', pointer: T0 + 'slots/0/draw' }),
    x('slot-draw-false-ok', { set: { [T0 + 'slots/0/draw']: false } }, null),
  ];
  let n = 0;
  for (const k of add) if (!c.cases.some((y) => y.id === k.id)) { c.cases.push(k); n++; }
  wj(cf, c);
  console.log(`fight.intro/2 applied (${n} new cases, ${dropped} old cases dropped)`);
}

// =============================== docs ===============================
{
  const f = 'docs/tools/README.md';
  let t = fs.readFileSync(f, 'utf8');
  if (!t.includes('intro-pool')) {
    const old = t.split('\n').find((l) => l.includes('`intro-order`') && l.includes('`intro-staredown`'));
    const row = '| `intro-order`, `intro-pool`, `intro-part`, `intro-classic`, `intro-id`, `wounds-last-stand` | data/fight/intro.json (fight.intro/2): a template\'s gap runs min to default to max, skipFrom is before the shortest clock, every slot\'s pool names parts, every entrance has exactly one fall and one land, exactly one template is classic, template ids are unique (the v1 timeline check and the `intro-staredown` check of data/anim/intro.json are retired: the staredown is no longer a number in the data); a fighter\'s lastStand.windowS is a whole number of ticks |';
    if (!old) throw new Error('intro README row not found');
    t = t.replace(old, () => row);
    fs.writeFileSync(f, t);
  }
}
