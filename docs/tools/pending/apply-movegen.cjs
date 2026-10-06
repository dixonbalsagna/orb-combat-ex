// Schemas and cross-checks for Combat's generated movesets, generator version 5 (docs/combat/pending/movegen/README.md sections 4 and 5;
// docs/combat/moveset-generator.md).
// NOT run by CI, the validator or the sim. Run once from the repo root, in the commit where Combat lands the files
//     data/combat/parts.json, identity.json, cells.json, data/combat/movesets/<fighter>.json and data/combat/movesets/lock.json
// (the drafts in docs/combat/pending/movegen/ with `_target` dropped; lock.json goes in movesets/):
//     node docs/tools/pending/apply-movegen.cjs
// It does NOT copy the data and stops with a message if the files are not there. It adds the combat-parts, combat-identity, combat-cells,
// combat-moveset and combat-moveset-lock schemas (closed; underscore keys are notes), the five map entries (the lock before the movesets),
// tools/lib/xref-movegen.js (copied from docs/tools/pending/xref-movegen.js and called from xref.js) with the rules parts-grammar,
// parts-shot, parts-travel, parts-legal, identity-ref, cells-quota, cells-asks, moveset-cell, moveset-shape, moveset-derived, moveset-keys,
// moveset-travel, moveset-table, moveset-special and lock-ref, and the cases. Re-runnable (a second run changes nothing). A first version of
// this script (for generator version 2) is replaced by this one: run it on a tree where that one has not run.
// The generator's own `--check` (the committed movesets are what the inputs give; the hash in generator.inputs; Legal's rows that name pose
// flags; that every row of docs/legal/movegen-banned.json is in parts.json) is not a validator rule: see docs/tools/movegen-ci.md.
const fs = require('fs');
const rj = (f) => JSON.parse(fs.readFileSync(f, 'utf8'));
const wj = (f, o) => fs.writeFileSync(f, JSON.stringify(o, null, 2) + '\n');
const closed = { additionalProperties: false, patternProperties: { '^_': true } };
const obj = (props, opts = {}) => Object.assign({ type: 'object', required: opts.required === undefined ? Object.keys(props) : opts.required, properties: props }, opts.description ? { description: opts.description } : {}, closed);
const clone = (o) => JSON.parse(JSON.stringify(o));

const LOCK = 'data/combat/movesets/lock.json';
const NEEDED = ['data/combat/parts.json', 'data/combat/identity.json', 'data/combat/cells.json', LOCK];
for (const f of NEEDED) if (!fs.existsSync(f)) { console.error(`apply-movegen: ${f} is not there. Run this in the commit that lands the movegen data files.`); process.exit(1); }
const movesetFiles = fs.existsSync('data/combat/movesets') ? fs.readdirSync('data/combat/movesets').filter((n) => n.endsWith('.json') && n !== 'lock.json') : [];
if (!movesetFiles.length) { console.error('apply-movegen: data/combat/movesets/ has no moveset files. Run this in the commit that lands them.'); process.exit(1); }

const LIMBS = ['hand', 'foot', 'elbow', 'knee', 'shoulder', 'head'];
const PATHS = ['line', 'arc_in', 'arc_out', 'rise', 'drop', 'spin'];
const SENDS = ['across', 'up', 'down', 'turned'];
const STEPS = ['in', 'hold', 'around', 'out'];
const WEIGHTS = ['light', 'medium', 'heavy'];
const GROUND = ['ok', 'plant', 'only', 'no'];
const LEVELS = ['posed', 'hand_state', 're_aim', 're_aim_edge', 'hand_state_re_aim', 'hand_state_re_aim_edge', 'stand_in', 'new'];
const STATUS = ['posed', 'derived', 'waiting'];
const CLASSES = ['open', 'fast', 'mid', 'slow'];
const REVIEW = ['new', 'accepted', 'change', 'rejected', 'locked', 'stand-in'];
const KINDS = ['strikes', 'context', 'frame', 'travel', 'table', 'special', 'string'];
const CELLID = '^[a-z][a-z0-9_]*\\.[xyab](\\.[a-z0-9_]+)?$';
const name = { type: 'string', pattern: '^[a-z][a-z0-9_]*$' };
const label = { type: 'string', minLength: 1 };
const strikeId = { type: 'string', pattern: '^strike\\.[a-z0-9_]+$' };
const condId = { type: 'string', pattern: '^[A-Z][0-9]+$' };
const moveId = { type: 'string', pattern: '^mv\\.[a-z][a-z0-9_]*\\.[a-z][a-z0-9_]*\\.[xyab](\\.[a-z0-9_]+)?\\.[0-9]{2}$' };
const keySet = { type: 'string', pattern: '^[a-z0-9_.~]+$' };
const wave = { type: 'string', pattern: '^[a-z]+[0-9]+$' };
const why = { type: 'string', minLength: 1 };
const strArr = (d) => ({ type: 'array', minItems: 1, uniqueItems: true, items: { type: 'string', minLength: 1 }, description: d });
const nameArr = (d) => ({ type: 'array', minItems: 1, uniqueItems: true, items: name, description: d });
const labelArr = (d) => ({ type: 'array', minItems: 1, uniqueItems: true, items: label, description: d });
const nullable = (s) => ({ anyOf: [s, { type: 'null' }] });
const tableOf = (inner, d, min = 1) => Object.assign({ type: 'object', propertyNames: { pattern: '^(_.*|[a-z][a-z0-9_]*)$' }, additionalProperties: inner, patternProperties: { '^_': true }, description: d }, min ? { minProperties: min } : {});
const labelTable = (inner, d) => ({ type: 'object', propertyNames: { pattern: '^(_.*|[a-z][^\n]*)$' }, additionalProperties: inner, patternProperties: { '^_': true }, description: d });
const tipTable = (inner, d) => ({ type: 'object', propertyNames: { pattern: '^(_.*|[a-z]+\\.[a-z0-9_]+)$' }, additionalProperties: inner, patternProperties: { '^_': true }, description: d });
const numTable = (d) => tableOf({ type: 'number', minimum: 0 }, d);

// a filter: part values that must all hold; `any` is a list of filters of which one must
const listOf = (d) => ({ type: 'array', minItems: 1, uniqueItems: true, items: { type: 'string', minLength: 1 }, description: d });
const filter = {
  type: 'object',
  properties: {
    limb: listOf('Allowed limbs.'),
    tip: listOf('Allowed tips.'),
    path: listOf('Allowed paths.'),
    target: listOf('Allowed targets.'),
    weight: listOf('Allowed weights.'),
    form: listOf('Allowed forms (any of a move\'s forms).'),
    flags: listOf('Pose flags (any a move is known to have).'),
    event: listOf('Run-time events.'),
    arms: { type: 'array', minItems: 1, uniqueItems: true, items: { type: 'integer', minimum: 0 }, description: 'Allowed numbers of arms.' },
    kind: listOf('A travel move\'s kind.'),
    direction: listOf('A travel move\'s direction.'),
    exit: listOf('A travel move\'s way out.'),
    release: listOf('A shot\'s release.'),
    body: listOf('A shot\'s body.'),
    delivery: listOf('A shot\'s delivery.'),
    any: { type: 'array', minItems: 1, items: { $ref: '#/$defs/filter' }, description: 'A list of filters of which one must hold.' },
  },
  description: 'Part values that must all hold; or `any`: a list of filters of which one must.',
  additionalProperties: false,
  patternProperties: { '^_': true },
};
// a hand filter: any part of a hand (parts.json shot.hands) a row names, as a list of allowed values
const handFilter = { type: 'object', propertyNames: { pattern: '^(_.*|[a-z][a-z0-9_]*)$' }, additionalProperties: { type: 'array', minItems: 1, uniqueItems: true, items: { type: ['string', 'integer'] } }, patternProperties: { '^_': true }, description: 'Hand parts (shape, light, hands, height) to the allowed values.' };
const withDefs = (s, extra = {}) => Object.assign(s, { $defs: Object.assign({ filter }, extra) });
const filterRef = { $ref: '#/$defs/filter' };
const needs = { type: 'array', items: obj({ who: why, what: { type: 'string' } }), description: 'What other teams must supply for the cell to be played in full.' };
const asks = { type: 'array', uniqueItems: true, items: condId, description: 'The ids of Legal\'s conditions (parts.json strike.conditions) that apply.' };

// =============================== parts ===============================
const legalRow = Object.assign({
  type: 'object',
  required: ['id', 'kind', 'rule', 'why'],
  properties: {
    id: { type: 'string', pattern: '^[a-z][0-9]+$' },
    kind: { enum: ['drawn', 'numbers', 'travel', 'move', 'hand', 'holdPoints', 'string', 'slots', 'burst', 'shape'] },
    uses: nameArr('Rule ids a row widens or is made of.'),
    ignores: nameArr('What the rule ignores.'),
    class: name,
    maxRun: { type: 'integer', minimum: 1 },
    match: filterRef,
    grab: name,
    allowed: nameArr('The hold points a kind of grab may use.'),
    string: obj({ same: nameArr('The parts that must differ run to run.'), max: { type: 'integer', minimum: 1 } }, { description: 'A move row\'s string rule.' }),
    owner: why,
    check: why,
    if: filterRef,
    then: filterRef,
    hand: obj({ need: handFilter }),
    need: handFilter,
    never: { anyOf: [handFilter, { type: 'array', minItems: 1, uniqueItems: true, items: { type: 'string', minLength: 1 } }] },
    rule: why,
    why,
  },
  allOf: [
    { if: { properties: { kind: { enum: ['travel', 'move'] } } }, then: { required: ['if', 'then'] } },
    { if: { properties: { kind: { const: 'hand' } } }, then: { required: ['never'] } },
    { if: { properties: { kind: { const: 'holdPoints' } } }, then: { required: ['never'] } },
    { if: { properties: { kind: { const: 'numbers' } } }, then: { required: ['owner', 'check'] } },
    { if: { properties: { kind: { const: 'drawn' } } }, then: { required: ['owner'] } },
    { if: { properties: { kind: { enum: ['string', 'burst'] } } }, then: { required: ['uses'] } },
    { if: { properties: { kind: { const: 'slots' } } }, then: { required: ['class', 'maxRun'] } },
    { if: { properties: { kind: { const: 'shape' } } }, then: { required: ['match'] } },
  ],
}, closed);
const shotRule = Object.assign({ type: 'object', required: ['if', 'then'], properties: { if: filterRef, then: filterRef, why } }, closed);
const seqRow = Object.assign({
      type: 'object',
      required: ['id', 'kind', 'rule'],
      properties: {
        id: name,
        kind: { enum: ['run', 'after', 'steps', 'audio', 'once'] },
        same: { type: 'array', minItems: 1, uniqueItems: true, items: { type: 'string', pattern: '^[a-z]+$' }, description: 'run: the parts that must be shared.' },
        max: { type: 'integer', minimum: 1, description: 'run: at most this many in a row.' },
        tighter: { type: 'array', items: obj({ when: filterRef, max: { type: 'integer', minimum: 1 } }), description: 'run: a smaller max where a filter holds.' },
        after: filterRef,
        never: { type: 'array', minItems: 1, items: filterRef, description: 'after: what may never follow.' },
        state: name,
        drawn: { type: 'array', minItems: 1, uniqueItems: true, items: { enum: STEPS } },
        rule: why,
        why,
      },
    }, closed);
const strikeBlock = obj({
  tips: tableOf(tableOf({ type: 'array', minItems: 1, uniqueItems: true, items: { enum: PATHS } }, 'tip to the paths it can travel'), 'limb to tip to the paths that tip can travel'),
  targets: tableOf(tableOf({ type: 'array', minItems: 1, uniqueItems: true, items: name }, 'path to targets'), 'limb to path to the places it can land'),
  lightNever: { type: 'array', items: filterRef, description: 'A shape matching one of these is never light.' },
  sends: tableOf({ enum: SENDS }, 'path to the direction it sends the rival'),
  links: tableOf({ type: 'array', minItems: 1, uniqueItems: true, items: { enum: PATHS } }, 'path to the paths that flow out of it, in order'),
  step: tableOf({ type: 'array', minItems: 1, items: { enum: STEPS } }, 'path to its steps'),
  beat: tableOf({ type: 'integer', minimum: 20, maximum: 28 }, 'path to its beat point, in ticks after contact'),
  forms: {
    type: 'array',
    minItems: 1,
    description: 'The forms a move can take, by rule, in order; `unless` names an earlier form that rules it out.',
    items: Object.assign({
      type: 'object',
      required: ['form'],
      properties: { form: name, when: filterRef, any: { type: 'array', minItems: 1, items: filterRef }, unless: name, reads: { enum: ['quick', 'charged'], description: 'The form applies only to a move whose wind-up rule reads this (parts.json strike.windup).' } },
      anyOf: [{ required: ['when'] }, { required: ['any'] }],
    }, closed),
  },
  weights: nameArr('The weights a strike has (light, medium, heavy).'),
  animWeight: tableOf({ enum: WEIGHTS }, 'The weight Animation read a posed strike at, to the weight it has now (a heavy of the old rows is a medium).'),
  legalTips: why,
  windup: obj({
    medium: { type: 'array', minItems: 1, items: obj({ id: name, when: filterRef, reads: { enum: ['quick', 'charged'] }, change: why, why }, { required: ['id', 'when', 'reads'] }), description: 'What a medium needs on Y\'s 12-tick wind-up: the first rule that matches is its rule.' },
    all: why,
  }, { required: ['medium'], description: 'Wind-up rules for the mediums.' }),
  heavy: obj({
    tips: tableOf(tableOf({ type: 'array', minItems: 1, uniqueItems: true, items: { enum: PATHS } }, 'tip to paths'), 'limb to tip to the paths a heavy may take'),
    never: { type: 'array', items: obj({ shape: filterRef, why }), description: 'Shapes the heavy tier never has.' },
    drive: tableOf(obj({
      id: name,
      word: why,
      flags: { type: 'array', uniqueItems: true, items: name },
      bears: nameArr('Legal rows the drive bears on.'),
      what: why,
      tell: why,
      end: why,
      legal: why,
      seen: { type: 'boolean', description: 'Whether the drive has been seen drawn.' },
    }, { required: ['id', 'word', 'bears', 'what', 'tell', 'end', 'seen'] }), 'a path to the whole-body drive a heavy takes on it'),
    words: { type: 'object', propertyNames: { pattern: '^(_.*|[a-z]+\\.[a-z0-9_]+)$' }, additionalProperties: why, patternProperties: { '^_': true }, description: 'limb.tip to the words that name it.' },
    standIn: why,
  }, { required: ['tips', 'never', 'drive'], description: 'The heavy tier (docs/combat/pending/movegen/three-strengths.md section 3).' }),
  burst: obj({
    classes: tableOf(obj({ gap: why, when: filterRef, why }), 'a class of gap (open, fast, mid, slow) to the shapes that may fill it'),
    noStutter: { type: 'array', minItems: 1, items: seqRow, description: 'The rules that keep a short gap from reading as a stutter.' },
  }, { description: 'The held X: eight lights that slow on a curve.' }),
  swap: { type: 'array', minItems: 1, uniqueItems: true, items: name, description: 'Hand tips one key set can show by a hand-state swap.' },
  tagTips: tableOf({ type: 'array', minItems: 1, uniqueItems: true, items: name }, 'a Legal tag to the hand tips a swap may show'),
  reaim: obj({ source: why, levels: obj({ ok: name, edge: name }) }, { description: 'Where the contact solve\'s reach comes from (Animation\'s tips.json) and the level name for a re-aim and for one at the edge.' }),
  legalTags: { type: 'array', items: obj({ tag: name, when: filterRef, why }), description: 'Conditions a shape carries onto its key set, from Legal\'s rulings.' },
  banned: {
    type: 'array',
    description: 'Legal\'s shape rows: never generated, for every fighter. A row matches when every field it names matches (`match`, or the older `shape`).',
    items: Object.assign({ type: 'object', required: ['why'], properties: { id: name, match: filterRef, shape: filterRef, why, appliesTo: why }, anyOf: [{ required: ['match'] }, { required: ['shape'] }] }, closed),
  },
  bannedSequences: {
    type: 'array',
    description: 'Legal\'s sequence rules, in a form a program can check: run, after, steps or audio.',
    items: seqRow,
  },
  flags: Object.assign({
    type: 'object',
    description: 'How a move gets the pose flags Legal\'s rows name.',
    properties: {
      fromTip: { type: 'string' },
      clearedBy: tableOf({ type: 'array', minItems: 1, uniqueItems: true, items: name }, 'a Legal tag to the flags it rules out'),
      byVocabulary: { type: 'array', uniqueItems: true, items: name },
      fromAnimation: { type: 'array', uniqueItems: true, items: name },
      fromVfx: { type: 'array', uniqueItems: true, items: name },
    },
  }, closed),
  conditions: {
    type: 'array',
    description: 'Legal\'s conditions, for Animation: which rows bite on which shapes (`when`) or in which stance (`stance`).',
    items: Object.assign({
      type: 'object',
      required: ['id', 'ask', 'rows'],
      properties: { id: condId, when: filterRef, stance: name, from: why, ask: why, rows: { type: 'array', minItems: 1, uniqueItems: true, items: name } },
      anyOf: [{ required: ['when'] }, { required: ['stance'] }],
    }, closed),
  },
}, { required: ['tips', 'targets', 'lightNever', 'sends', 'links', 'step', 'beat', 'forms', 'swap', 'tagTips', 'reaim', 'banned', 'weights', 'windup', 'heavy', 'burst'] });
const travelMoveRow = obj({ direction: name, entries: nameArr('Entry names (entrymap rows) it may open with.'), exit: nullable(name) });
const partsSchema = withDefs({
  $schema: 'https://json-schema.org/draft/2020-12/schema',
  $id: 'meridian/combat-parts',
  title: 'combat.parts/1',
  description: 'data/combat/parts.json: the grammar the moveset generator assembles moves from (docs/combat/moveset-generator.md). strike: the strike grammar (tips and the paths each can travel, the targets each limb reaches on each path, the shapes never light, what a path sends, links, steps and beats, the forms, the hand swap, the Legal tags, the re-aim, Legal\'s banned shapes and sequences, the flags, the conditions). travel: the kinds of travel (zip, step, charge, pursuit) with their moves, and the paths each arrival may blow on. shot: energy releases, bodies, rules, forms and the hand table. readings: a stance to a reading to its forms. legal: Legal\'s motion, energy, grab, held and stacking rows. grab: the hold points. Version field: schema. Policy: closed except keys starting with an underscore. Cross-references (every tip path has targets; every path has a send, links, a step and a beat; shot rules name releases and bodies of shot; every travel direction has arrive paths and every entry is an entrymap row; no hold point is one of g01\'s; rule ids are unique) are checked by tools/lib/xref-movegen.js (parts-*).',
  type: 'object',
  required: ['schema', 'strike', 'travel', 'shot', 'readings', 'legal', 'grab'],
  properties: {
    schema: { const: 'combat.parts/1' },
    strike: strikeBlock,
    travel: obj({
      kinds: tableOf(obj({ band: name, what: why, moves: { type: 'array', minItems: 1, items: travelMoveRow } }), 'a kind of travel to its band, its note and the moves (a direction, the entries it may open with and the exit) it comes in'),
      arrive: tableOf({ type: 'array', minItems: 1, uniqueItems: true, items: { enum: PATHS } }, 'a direction to the paths of the blow that arrives that way'),
    }),
    shot: obj({
      release: nameArr('The ways a shot is released.'),
      body: nameArr('The bodies a shot is released from.'),
      rules: { type: 'array', items: shotRule, description: 'If a move matches `if`, it must match `then`.' },
      forms: { type: 'array', minItems: 1, items: obj({ form: name, when: filterRef }) },
      hands: tableOf(obj({ shape: name, light: name, hands: { type: 'integer', minimum: 1 }, height: name }), 'a hand to its shape, where the light sits, how many hands and the height'),
    }),
    readings: tableOf(tableOf({ anyOf: [nameArr('forms'), tableOf(label, 'a press (tap, mash, hold, beat) to the form it asks for')] }, 'a reading (or a button) to its forms (or its presses)'), 'a stance to its readings'),
    legal: Object.assign({
      type: 'object',
      required: ['applies', 'motion', 'energy', 'grabs', 'held', 'stacking'],
      properties: {
        applies: { type: 'object', additionalProperties: why, patternProperties: { '^_': true }, description: 'Which cells each of Legal\'s groups judges (notes).' },
        motion: { type: 'array', items: legalRow },
        energy: { type: 'array', items: legalRow },
        grabs: { type: 'array', items: legalRow },
        held: { type: 'array', items: legalRow },
        stacking: { type: 'array', items: legalRow },
        heldScope: { type: 'object', description: 'Legal\'s scope for the held-pose lint, copied from docs/legal/movegen-banned.json as it stands (not rows; an open object).' },
      },
    }, { additionalProperties: { type: 'array', items: legalRow }, patternProperties: { '^_': true } }),
    grab: obj({ holdPoints: nameArr('The places a grab may hold.'), kinds: tableOf(nameArr('hold points'), 'a kind of grab (tackle, clinch) to the points it may hold') }, { required: ['holdPoints'] }),
  },
  additionalProperties: false,
  patternProperties: { '^_': true },
});

// =============================== identity ===============================
const special = obj({ id: { type: 'string', pattern: '^special\\.[a-z0-9_]+$' }, what: why, status: why, parts: tableOf(strArr('values'), 'a part of the special to the values it can take'), rules: { type: 'array', items: Object.assign({ type: 'object', required: ['if', 'then'], properties: { if: handFilter, then: handFilter, why } }, closed) } }, { required: ['id', 'what', 'status', 'parts'] });
const identitySchema = withDefs({
  $schema: 'https://json-schema.org/draft/2020-12/schema',
  $id: 'meridian/combat-identity',
  title: 'combat.identity/1',
  description: 'data/combat/identity.json: how each fighter bends the grammar of parts.json (docs/combat/moveset-generator.md section 2): the waves his posed strikes come from, the entry waves, the weights of limbs, paths, tips (a tip written limb.tip) and entries, the weights that replace them for some shapes, the shapes he never has, his own reading of a shared strike, how strongly a posed shape is preferred, how he shows a tip, his energy hands, releases and posed sets, and his specials. rejected: shapes a review turned down. Version field: schema. Policy: closed except keys starting with an underscore. Cross-references (every wave has a manifest; every entry wave an entry map; every tip is a tip of parts.json; every entry weight an entrymap row; energy hands and releases are those of parts.json shot; the fighters are keys of recipes.json pools) are checked by tools/lib/xref-movegen.js (identity-ref).',
  type: 'object',
  required: ['schema', 'fighters', 'rejected'],
  properties: {
    schema: { const: 'combat.identity/1' },
    fighters: {
      type: 'object',
      minProperties: 1,
      propertyNames: { pattern: '^(_.*|[a-z][a-z0-9_]*)$' },
      additionalProperties: obj({
        waves: { type: 'array', minItems: 1, uniqueItems: true, items: wave, description: 'Animation\'s manifests that hold his posed strikes, in the order their rows replace each other.' },
        entryWaves: { type: 'array', minItems: 1, uniqueItems: true, items: wave, description: 'Animation\'s entry maps his travel moves come from.' },
        weights: obj({ limb: numTable('limb to weight'), path: numTable('path to weight'), tip: tipTable({ type: 'number', minimum: 0 }, 'limb.tip to weight'), entry: numTable('entry name to weight') }, { required: ['limb', 'path', 'tip'] }),
        weightsBy: { type: 'array', items: obj({ when: filterRef, tip: tipTable({ type: 'number', minimum: 0 }, 'limb.tip to the weight that replaces the plain one'), target: numTable('target to the weight that replaces the plain one'), path: numTable('path to the weight that replaces the plain one'), limb: numTable('limb to the weight that replaces the plain one') }, { required: ['when'] }), description: 'Weights that replace the plain ones for shapes the filter matches.' },
        never: { type: 'array', items: obj({ id: name, shape: filterRef, why }, { required: ['shape', 'why'] }), description: 'Shapes he never has.' },
        tipOf: { type: 'object', propertyNames: { pattern: '^(_.*|strike\\.[a-z0-9_]+)$' }, additionalProperties: name, patternProperties: { '^_': true }, description: 'Strike id to a tip: his own reading of a shared strike.' },
        tipFlags: tipTable({ type: 'array', minItems: 1, uniqueItems: true, items: name }, 'How he shows a tip, as pose flags (limb.tip to flags), for Legal\'s rows.'),
        reuse: obj({
          posed: { type: 'number', minimum: 1 },
          hand_state: { type: 'number', minimum: 1 },
          re_aim: { type: 'number', minimum: 1 },
          re_aim_edge: { type: 'number', minimum: 1 },
          hand_state_re_aim: { type: 'number', minimum: 1 },
          hand_state_re_aim_edge: { type: 'number', minimum: 1 },
          stand_in: { type: 'number', minimum: 1 },
        }, { required: ['posed', 'hand_state', 're_aim', 'hand_state_re_aim'], description: 'How strongly a shape that is posed, or one swap or re-aim from it, is preferred (1 or more).' }),
        energy: obj({
          hands: numTable('an energy hand of parts.json shot.hands to its weight'),
          posedHands: tableOf(why, 'an energy hand to the pose that holds it'),
          release: numTable('a release of parts.json shot.release to its weight'),
          split: { type: 'boolean', description: 'Whether he can split a shot.' },
          posed: { type: 'array', items: obj({ when: filterRef, set: why }), description: 'Shots that have a posed key set: the set of the first row whose filter matches.' },
        }, { required: ['hands', 'release'] }),
        specials: obj({ x: special, y: special, a: special }, { required: [] }),
        manner: obj({ heavy: why, burst: why }, { required: [], description: 'How he throws, in words, for Animation and Legal. Not read by the generator.' }),
        pinned: { type: 'object', propertyNames: { pattern: '^(_.*|' + CELLID.slice(1, -1) + ')$' }, additionalProperties: { type: 'array', items: { type: 'array', minItems: 5, maxItems: 5, prefixItems: [{ enum: LIMBS }, name, { enum: PATHS }, name, { enum: WEIGHTS }] }, description: 'Shapes a cell must hold: [limb, tip, path, target, weight].' }, patternProperties: { '^_': true }, description: 'A cell to the shapes pinned in it for this fighter.' },
        burst: obj({ close: obj({ path: { type: 'array', minItems: 1, uniqueItems: true, items: { enum: PATHS } } }, { description: 'What his burst\'s eighth blow is, when the rules allow.' }) }, { description: 'How his held X closes.' }),
      }, { required: ['waves', 'weights', 'weightsBy', 'never', 'tipOf', 'reuse'] }),
      patternProperties: { '^_': true },
    },
    rejected: {
      type: 'array',
      items: obj({
        fighter: name,
        shape: obj({ limb: { enum: LIMBS }, tip: name, path: { enum: PATHS }, target: name, weight: { enum: WEIGHTS } }),
        why,
      }),
      description: 'Shapes a review turned down, by fighter: never proposed again.',
    },
  },
  additionalProperties: false,
  patternProperties: { '^_': true },
});

// =============================== cells ===============================
const slot = obj({
  slot: label,
  ticks: { type: 'integer', minimum: 1 },
  count: { type: 'integer', minimum: 1 },
  from: { type: 'string', minLength: 1 },
  to: { type: 'string', minLength: 1 },
  order: label,
  by: label,
}, { required: ['slot'] });
const standIn = obj({
  kind: { const: 'strikes' },
  temporary: { type: 'boolean' },
  only: name,
  asks,
  without: { type: 'object', propertyNames: { pattern: '^(_.*|[a-z][a-z0-9_]*)$' }, additionalProperties: { type: 'array', minItems: 1, items: strikeId }, patternProperties: { '^_': true }, description: 'A fighter to the posed strikes left out of his stand-ins.' },
  what: why,
  filter: filterRef,
  count: { type: 'integer', minimum: 1 },
}, { required: ['kind', 'temporary', 'only', 'what', 'filter', 'count'], description: 'Stand-ins for B until the tier is posed: temporary, never locked.' });
const quota = Object.assign({
  type: 'object',
  required: ['name', 'min'],
  properties: {
    name: label,
    min: { type: 'integer', minimum: 0 },
    filter: filterRef,
    any: { type: 'array', minItems: 1, items: filterRef },
    form: name,
    sends: { enum: SENDS },
  },
}, closed);
const cellsSchema = withDefs({
  $schema: 'https://json-schema.org/draft/2020-12/schema',
  $id: 'meridian/combat-cells',
  title: 'combat.cells/1',
  description: 'data/combat/cells.json: what each face button holds in each stance (Game Design\'s matrix, docs/design/melee-press-feel.md sections 10 and 13): X quick, Y strong, A the stance\'s context action, B its signature. A strikes cell is a filter, a count and quotas (and may be a guard layer, a push, any weight, or read in forms); a travel cell names its blows cell, its kinds and readings; a table cell names a block of parts.json and its deliveries; a special cell is a fighter\'s special; a context cell lists actions pressed and held; a frame cell lists slots and readings. Any cell may list what others must supply (needs) and Legal\'s conditions (asks). seed: the generator\'s seed. spread: how each pick marks down the shapes that share a part of it. Version field: schema. Policy: closed except keys starting with an underscore. Cross-references (a quota has exactly one of filter, any, form or sends; names are unique; a quota fits in its cell; its form and sends exist in parts.json; a travel cell\'s blows is a cell and its kinds are travel kinds; a table cell\'s block is a block of parts.json; asks are conditions of parts.json) are checked by tools/lib/xref-movegen.js (cells-quota, cells-asks).',
  type: 'object',
  required: ['schema', 'seed', 'spread', 'stances'],
  properties: {
    schema: { const: 'combat.cells/1' },
    seed: { type: 'integer' },
    spread: obj({
      path: { type: 'number', exclusiveMinimum: 0, maximum: 1 },
      target: { type: 'number', exclusiveMinimum: 0, maximum: 1 },
      tip: { type: 'number', exclusiveMinimum: 0, maximum: 1 },
      shape: { type: 'number', exclusiveMinimum: 0, maximum: 1 },
    }),
    stances: {
      type: 'object',
      minProperties: 1,
      propertyNames: { pattern: '^(_.*|[a-z][a-z0-9_]*)$' },
      additionalProperties: Object.assign({
        type: 'object',
        required: ['held'],
        properties: {
          held: { type: 'integer', minimum: 0, description: 'The stance mask.' },
          x: { $ref: '#/$defs/cell' },
          y: { $ref: '#/$defs/cell' },
          a: { $ref: '#/$defs/cell' },
          b: { $ref: '#/$defs/cell' },
        },
      }, closed),
      patternProperties: { '^_': true },
    },
  },
  additionalProperties: false,
  patternProperties: { '^_': true },
}, {
  standIn,
  cell: Object.assign({
    type: 'object',
    required: ['kind', 'what'],
    properties: {
      kind: { enum: KINDS },
      what: why,
      spread: tableOf({ type: 'number', exclusiveMinimum: 0, maximum: 1 }, 'a part (look, path, target, tip, shape) to how hard a pick marks down what shares it, in this cell'),
      weights: nameArr('Weights this cell may hold (a defensive blow may be a light or a medium).'),
      notLevels: nameArr('Key levels this cell does not take (a stand-in is not one of the tier).'),
      presses: tableOf({ $ref: '#/$defs/cell' }, 'a press (hold) to the sub-cell it plays'),
      standIn: { $ref: '#/$defs/standIn' },
      from: { type: 'string', pattern: CELLID, description: 'A string cell: the cell its blows come from.' },
      leans: { type: 'array', minItems: 1, items: Object.assign({ type: 'object', required: ['name'], properties: { name: name, filter: filterRef, any: { type: 'array', minItems: 1, items: filterRef } } }, closed), description: 'A string cell: a lean of the stick to the filter its string draws on.' },
      needs,
      asks,
      filter: filterRef,
      count: { type: 'integer', minimum: 1 },
      quotas: { type: 'array', items: quota },
      layer: name,
      as: name,
      anyWeight: { type: 'boolean' },
      notFlags: { type: 'array', minItems: 1, uniqueItems: true, items: name },
      readings: { anyOf: [nameArr('The forms a cell is read in.'), labelTable(why, 'a reading to a sentence')] },
      blows: { type: 'string', pattern: CELLID, description: 'The cell whose blows this travel cell strikes with.' },
      kinds: nameArr('The kinds of travel (parts.json travel.kinds) this cell holds.'),
      block: name,
      delivery: nameArr('The deliveries (shot kinds) this cell holds.'),
      slot: { enum: ['x', 'y', 'a'] },
      pressed: labelArr('The actions of a press.'),
      held: labelArr('The actions of a hold.'),
      actions: labelArr('The actions of a context cell.'),
      slots: { type: 'array', minItems: 1 },
      legal: why,
    },
    allOf: [
      { if: { properties: { kind: { const: 'strikes' } } }, then: { required: ['filter', 'count', 'quotas'] } },
      { if: { properties: { kind: { const: 'travel' } } }, then: { required: ['blows', 'kinds', 'count', 'readings', 'quotas'] } },
      { if: { properties: { kind: { const: 'table' } } }, then: { required: ['block', 'delivery', 'count', 'quotas'] } },
      { if: { properties: { kind: { const: 'special' } } }, then: { required: ['slot', 'count', 'readings'] } },
      { if: { properties: { kind: { const: 'context' } } }, then: { required: ['pressed', 'held'] } },
      { if: { properties: { kind: { const: 'frame' } } }, then: { required: ['slots'], properties: { slots: { items: slot } } } },
      { if: { properties: { kind: { const: 'string' } } }, then: { required: ['from', 'slots', 'leans'], properties: { slots: { items: { enum: CLASSES } } } } },
    ],
  }, closed),
});

// =============================== moveset ===============================
const keys = obj({
  level: { enum: LEVELS },
  from: strikeId,
  set: keySet,
  wave,
  layer: name,
  hand: name,
  aim: why,
}, { required: ['level'] });
const strikeMove = obj({
  id: moveId,
  limb: { enum: LIMBS },
  tip: name,
  path: { enum: PATHS },
  target: name,
  weight: { enum: WEIGHTS },
  arms: { type: 'integer', minimum: 0, description: 'The number of arms the move uses.' },
  forms: nameArr('forms'),
  step: { type: 'array', minItems: 1, items: { enum: STEPS } },
  sends: { enum: SENDS },
  links: { type: 'array', minItems: 1, uniqueItems: true, items: { enum: PATHS } },
  beat: { type: 'integer', minimum: 20, maximum: 28 },
  keys,
  ground: { enum: GROUND },
  status: { enum: STATUS },
  flags: { type: 'array', uniqueItems: true, items: name, description: 'The pose flags known present on the move.' },
  legal: { type: 'array', uniqueItems: true, items: name },
  asks,
  review: { enum: REVIEW },
  as: name,
  wind: name,
  drive: name,
  name: why,
}, { required: ['id', 'limb', 'tip', 'path', 'target', 'weight', 'arms', 'forms', 'step', 'sends', 'links', 'beat', 'keys', 'ground', 'status', 'flags', 'legal', 'asks', 'review'] });
const stringMove = obj({ id: moveId, lean: name, blows: { type: 'array', minItems: 1, items: moveId }, slots: { type: 'array', minItems: 1, items: { enum: CLASSES } }, status: { enum: STATUS }, asks, review: { enum: REVIEW } });
const entryRef = obj({ id: { type: 'string', pattern: '^entry\\.[a-z0-9_]+$' }, set: keySet });
const travelMove = obj({
  id: moveId,
  kind: name,
  band: name,
  direction: name,
  entry: entryRef,
  exit: nullable(entryRef),
  blow: obj({ move: moveId, limb: { enum: LIMBS }, tip: name, path: { enum: PATHS }, target: name, weight: { enum: WEIGHTS }, set: keySet }),
  forms: nameArr('forms'),
  status: { enum: STATUS },
  flags: { type: 'array', uniqueItems: true, items: name },
  legal: { type: 'array', uniqueItems: true, items: name },
  asks,
  review: { enum: REVIEW },
});
const tableMove = obj({
  id: moveId,
  hand: name,
  release: name,
  body: name,
  delivery: name,
  forms: nameArr('forms'),
  keys: obj({ set: nullable(keySet), hand: nullable(why) }),
  status: { enum: STATUS },
  asks,
  review: { enum: REVIEW },
});
const specialMove = obj({ id: moveId, look: tableOf(label, 'a part of the special to its value'), forms: nameArr('forms'), status: { enum: STATUS }, asks, review: { enum: REVIEW } });
const refusedTravel = obj({ move: obj({ kind: name, direction: name, exit: nullable(name) }), rows: nameArr('Legal rows that refused it.') });
const refusedTable = obj({ move: obj({ delivery: name, release: name }), rows: nameArr('Legal rows that refused it.'), candidates: { type: 'integer', minimum: 0 } });
const movesetSchema = withDefs({
  $schema: 'https://json-schema.org/draft/2020-12/schema',
  $id: 'meridian/combat-moveset',
  title: 'combat.moveset/1',
  description: 'data/combat/movesets/<fighter>.json: a fighter\'s generated moves (GENERATED by the moveset generator; never edited by hand). fighter: the fighter id. generator: its version, the seed and a hash of its inputs. cells: cell id (stance.button) to a strikes cell (the candidates counted, the ones Legal refused, the quota counts, the moves), a travel cell (moves of a kind, a direction, an entry, an exit and the blow they strike with), a table cell (energy moves: a hand, a release, a body and a delivery), a special cell, a context cell (pressed and held actions) or a frame cell (slots and readings). A strike move is a shape of the grammar with what the grammar derives from it, the key set it plays (keys), its status and its review; `locked` means its id keeps its shape for good (lock.json). Version field: schema. Policy: closed except keys starting with an underscore. Cross-references (every move is a valid shape that matches no never or banned row, no cell holds a shape twice, sends, links, step, beat and forms are what parts.json derives, status follows keys.level, keys.set and keys.from are a manifest row of the fighter, each cell has its count and quotas, a travel move is one of parts.json travel.kinds and its blow a move of the blows cell, a table move breaks no rule of its block, a special\'s look is made of the special\'s parts) are checked by tools/lib/xref-movegen.js (moveset-*). That the files are what the inputs give is the generator\'s own --check.',
  type: 'object',
  required: ['schema', 'fighter', 'generator', 'cells'],
  properties: {
    schema: { const: 'combat.moveset/1' },
    fighter: name,
    generator: obj({ version: { type: 'integer', minimum: 1 }, seed: { type: 'integer' }, inputs: { type: 'string', pattern: '^[0-9a-f]{8,64}$' } }),
    cells: {
      type: 'object',
      minProperties: 1,
      propertyNames: { pattern: '^(_.*|' + CELLID.slice(1, -1) + ')$' },
      additionalProperties: { $ref: '#/$defs/cell' },
      patternProperties: { '^_': true },
    },
  },
  additionalProperties: false,
  patternProperties: { '^_': true },
}, {
  cell: Object.assign({
    type: 'object',
    required: ['kind'],
    properties: {
      kind: { enum: KINDS },
      valid: { type: 'integer', minimum: 0, description: 'How many shapes were candidates.' },
      refused: { type: 'array', description: 'Candidates Legal\'s rows refused.' },
      from: { type: 'string', pattern: CELLID },
      temporary: { type: 'boolean', description: 'A stand-in cell: never locked; it goes as the tier\'s own poses arrive.' },
      quotas: labelTable({ type: 'integer', minimum: 0 }, 'quota name to how many moves meet it'),
      moves: { type: 'array', minItems: 1 },
      special: { type: 'string', pattern: '^special\\.[a-z0-9_]+$' },
      what: why,
      state: why,
      pressed: labelArr('The actions of a press.'),
      held: labelArr('The actions of a hold.'),
      slots: { type: 'array', minItems: 1, items: slot },
      readings: labelTable(why, 'a reading to a sentence'),
      asks,
    },
    allOf: [
      { if: { properties: { kind: { const: 'strikes' } } }, then: { required: ['valid', 'refused', 'quotas', 'moves'], properties: { moves: { items: strikeMove } } } },
      { if: { properties: { kind: { const: 'string' } } }, then: { required: ['from', 'valid', 'quotas', 'moves'], properties: { moves: { items: stringMove } } } },
      { if: { properties: { kind: { const: 'travel' } } }, then: { required: ['valid', 'refused', 'quotas', 'moves'], properties: { moves: { items: travelMove }, refused: { items: refusedTravel } } } },
      { if: { properties: { kind: { const: 'table' } } }, then: { required: ['valid', 'refused', 'quotas', 'moves'], properties: { moves: { items: tableMove }, refused: { items: refusedTable } } } },
      { if: { properties: { kind: { const: 'special' } } }, then: { required: ['special', 'what', 'state', 'valid', 'quotas', 'moves'], properties: { moves: { items: specialMove } } } },
      { if: { properties: { kind: { const: 'context' } } }, then: { required: ['pressed', 'held'] } },
      { if: { properties: { kind: { const: 'frame' } } }, then: { required: ['slots'] } },
    ],
  }, closed),
});

// =============================== lock ===============================
const lockRow = { type: 'array', minItems: 3, maxItems: 3, prefixItems: [moveId, { type: 'array', minItems: 5, maxItems: 5, prefixItems: [{ enum: LIMBS }, name, { enum: PATHS }, name, { enum: WEIGHTS }] }, nullable(keySet)], description: '[move id, [limb, tip, path, target, weight], key set id or null]' };
const lockSchema = {
  $schema: 'https://json-schema.org/draft/2020-12/schema',
  $id: 'meridian/combat-moveset-lock',
  title: 'combat.moveset.lock/1',
  description: 'data/combat/movesets/lock.json: the strike moves that are locked: an id keeps its shape for good, so a regeneration cannot change what a locked id means (GENERATED by the moveset generator). fighters: a fighter to a cell id (stance.button) to a list of rows [move id, [limb, tip, path, target, weight], key set id or null]. Version field: schema. Policy: closed except keys starting with an underscore. Cross-references (every id is a move of that fighter\'s cell with the same shape, and the key set of a posed move or null for any other level; every strike move is in the lock) are checked by tools/lib/xref-movegen.js (lock-ref).',
  type: 'object',
  required: ['schema', 'fighters'],
  properties: {
    schema: { const: 'combat.moveset.lock/1' },
    fighters: tableOf({ type: 'object', propertyNames: { pattern: '^(_.*|' + CELLID.slice(1, -1) + ')$' }, additionalProperties: { type: 'array', items: lockRow }, patternProperties: { '^_': true } }, 'a fighter to its locked cells'),
  },
  additionalProperties: false,
  patternProperties: { '^_': true },
};
// a schema that an older run of this script (generator version 2) wrote is replaced, not kept
for (const [file, s] of [['combat-parts', partsSchema], ['combat-identity', identitySchema], ['combat-cells', cellsSchema], ['combat-moveset', movesetSchema], ['combat-moveset-lock', lockSchema]]) {
  const f = `tools/schemas/${file}.schema.json`;
  const old = fs.existsSync(f) ? rj(f) : null;
  const upToDate = old && (file !== 'combat-parts' || (old.properties && old.properties.legal));
  if (!upToDate) wj(f, s);
}

// =============================== map ===============================
{
  const f = 'tools/schemas/map.json';
  const m = rj(f);
  let changed = false;
  const at = () => { const i = m.rules.findIndex((r) => r.match === 'data/combat/recipes.json'); return i >= 0 ? i + 1 : m.rules.length; };
  // the lock comes before `movesets/*.json`: the first match wins
  for (const [match, schema] of [['data/combat/parts.json', 'combat-parts.schema.json'], ['data/combat/identity.json', 'combat-identity.schema.json'], ['data/combat/cells.json', 'combat-cells.schema.json'], ['data/combat/movesets/lock.json', 'combat-moveset-lock.schema.json'], ['data/combat/movesets/*.json', 'combat-moveset.schema.json']]) {
    if (m.rules.some((r) => r.match === match)) continue;
    m.rules.splice(at(), 0, { match, schema });
    changed = true;
  }
  const iLock = m.rules.findIndex((r) => r.match === 'data/combat/movesets/lock.json');
  const iSets = m.rules.findIndex((r) => r.match === 'data/combat/movesets/*.json');
  if (iLock > iSets) { const [r] = m.rules.splice(iLock, 1); m.rules.splice(iSets, 0, r); changed = true; }
  if (changed) wj(f, m);
}

// =============================== xref ===============================
{
  const dst = 'tools/lib/xref-movegen.js';
  const src = 'docs/tools/pending/xref-movegen.js';
  if (!fs.existsSync(dst) || fs.readFileSync(dst, 'utf8') !== fs.readFileSync(src, 'utf8')) fs.copyFileSync(src, dst);
  const f = 'tools/lib/xref.js';
  let t = fs.readFileSync(f, 'utf8');
  if (!t.includes('xref-movegen')) {
    const req = "const { xrefInput } = require('./xref-input');";
    if (!t.includes(req)) throw new Error('xref.js require anchor');
    t = t.replace(req, () => req + "\nconst { xrefMovegen } = require('./xref-movegen');");
    const call = '  xrefFight({ get, err, esc, isObj, plainKeys, docsFor: (re) => [...docs.keys()].filter((k) => re.test(k)).sort() });';
    if (!t.includes(call)) throw new Error('xref.js call anchor');
    t = t.replace(call, () => call + "\n  xrefMovegen({ get, err, esc, isObj, docsFor: (re) => [...docs.keys()].filter((k) => re.test(k)).sort() });");
    fs.writeFileSync(f, t);
  }
}

// =============================== cases ===============================
{
  const cf = 'tools/fixtures/cases.json';
  const c = rj(cf);
  const P = 'data/combat/parts.json';
  const I = 'data/combat/identity.json';
  const C = 'data/combat/cells.json';
  const L = LOCK;
  const M = 'data/combat/movesets/' + movesetFiles[0];
  const rival = rj(M);
  const fid = rival.fighter;
  const ident = rj(I).fighters[fid];
  // every case sets the values it depends on, so a change of the data does not break it
  const SHAPE = { limb: 'hand', tip: 'blade', path: 'line', target: 'head', weight: 'light' };
  const pa = (n, mut, expect) => ({ id: 'combat-parts-' + n, schema: 'combat-parts.schema.json', mutate: [{ file: P, ...mut }], expect });
  const id = (n, mut, expect) => ({ id: 'combat-identity-' + n, schema: 'combat-identity.schema.json', mutate: [{ file: I, ...mut }], expect });
  const ce = (n, mut, expect) => ({ id: 'combat-cells-' + n, schema: 'combat-cells.schema.json', mutate: [{ file: C, ...mut }], expect });
  const ms = (n, mut, expect) => ({ id: 'combat-moveset-' + n, schema: 'combat-moveset.schema.json', mutate: [{ file: M, ...mut }], expect });
  const lk = (n, mut, expect) => ({ id: 'combat-moveset-lock-' + n, schema: 'combat-moveset-lock.schema.json', mutate: [{ file: L, ...mut }], expect });
  const F = '/fighters/' + fid + '/';
  const ST = '/strike/';
  const TR = '/travel/';
  const SH = '/shot/';
  const LG = '/legal/';
  const live = rj(M);
  const X = '/cells/martial.x/';
  const TRIAL = '/stances/trial';
  const TC = '/cells/trial.x';
  const TL = '/fighters/' + fid + '/trial.x';
  const P0 = TC + '/moves/0';
  const tplMove = { medium: live.cells['martial.y'].moves[0], heavy: live.cells['martial.b'].moves[0], string: live.cells['martial.x.hold'].moves[0], standin: live.cells['martial.b.standin'].moves[0], strikes: live.cells['martial.x'].moves[0], travel: live.cells['manoeuvre.x'].moves[0], table: live.cells['energy.x'].moves[0], special: live.cells['charging.x'].moves[0] };
  const lockRow = (m) => [m.id, [m.limb, m.tip, m.path, m.target, m.weight], m.keys && m.keys.level === 'posed' && typeof m.keys.set === 'string' ? m.keys.set : null];
  // a condition and a banned row of the case's own (a shape that matches nothing)
  const ownCond = () => [{ file: P, set: { '/strike/banned/-': { id: 'b98', match: { limb: ['hand'], tip: ['none_such'] }, why: 'a' }, '/strike/conditions/-': { id: 'Z9', stance: 'any', rows: ['b98'], ask: 'a' } } }];
  // a trial cell: a stance `trial` in cells.json, a cell `trial.x` in the moveset (copies of a live move of the kind, so what the grammar derives stays true) and, for strikes, its rows in the lock
  const trialMut = (kind, f = {}) => {
    const base = clone(tplMove[kind] || {});
    let moves = [clone(base)];
    if (moves[0].id) moves[0].id = kind === 'string' ? `mv.${fid}.trial.x.hold.01` : kind === 'standin' ? `mv.${fid}.trial.b.standin.01` : `mv.${fid}.trial.x.01`;
    if (f.moves) moves = f.moves(moves);
    if (f.move) f.move(moves[0]);
    let def;
    let cell;
    if (kind === 'strikes' || kind === 'medium' || kind === 'heavy') {
      def = { kind: 'strikes', what: 'a', filter: { weight: [base.weight] }, count: moves.length, readings: base.forms, quotas: [] };
      cell = { kind: 'strikes', valid: 1, refused: [], quotas: {}, moves };
    } else if (kind === 'string') {
      def = { kind: 'string', what: 'a', from: 'martial.x', slots: clone(base.slots), leans: [{ name: base.lean, filter: { weight: ['light'] } }] };
      cell = { kind: 'string', from: 'martial.x', valid: 1, quotas: {}, moves };
    } else if (kind === 'standin') {
      def = { kind: 'strikes', temporary: true, only: 'stand_in', what: 'a', filter: { weight: [tplMove.heavy.weight] }, count: 2 };
      cell = { kind: 'strikes', valid: 1, refused: [], quotas: {}, temporary: true, moves };
    } else if (kind === 'travel') {
      def = { kind, what: 'a', blows: 'martial.x', kinds: [base.kind], count: moves.length, readings: base.forms, quotas: [] };
      cell = { kind, valid: 1, refused: [], quotas: {}, moves };
    } else if (kind === 'table') {
      def = { kind, what: 'a', block: 'shot', delivery: [base.delivery], count: moves.length, quotas: [] };
      cell = { kind, valid: 1, refused: [], quotas: {}, moves };
    } else if (kind === 'special') {
      def = { kind, what: 'a', slot: 'x', count: moves.length, readings: base.forms };
      cell = Object.assign(clone(live.cells['charging.x']), { moves });
    } else if (kind === 'context') {
      def = { kind, what: 'a', pressed: ['p'], held: ['h'] };
      cell = { kind, pressed: ['p'], held: ['h'] };
    } else {
      def = { kind, what: 'a', slots: [{ slot: 'tell', ticks: 30 }] };
      cell = { kind, slots: [{ slot: 'tell', ticks: 30 }] };
    }
    if (f.def) f.def(def);
    if (f.cell) f.cell(cell);
    const muts = kind === 'string'
      ? [{ file: M, set: { [TC + '.hold']: cell } }, { file: C, set: { [TRIAL]: { held: 0, x: { kind: 'strikes', what: 'a', filter: { weight: ['light'] }, count: 1, quotas: [], presses: { hold: def } } } } }]
      : kind === 'standin'
        ? [{ file: M, set: { '/cells/trial.b.standin': cell } }, { file: C, set: { [TRIAL]: { held: 0, b: { kind: 'strikes', what: 'a', filter: { weight: [tplMove.heavy.weight] }, count: 1, quotas: [], standIn: def } } } }]
        : [{ file: M, set: { [TC]: cell } }, { file: C, set: { [TRIAL]: { held: 0, x: def } } }];
    if (kind === 'strikes' || kind === 'medium' || kind === 'heavy') {
      const rows = moves.map(lockRow);
      if (f.lock) f.lock(rows);
      muts.push({ file: L, set: { [TL]: rows } });
    }
    if (f.extra) muts.push(...f.extra(moves[0], base));
    return muts;
  };
  const mt = (n, kind, f, expect) => ({ id: 'combat-moveset-' + n, schema: 'combat-moveset.schema.json', mutate: trialMut(kind, f), expect });
  const sk = (n, tweak, expect) => mt(n, 'strikes', { move: tweak }, expect);
  const handRow = { shape: 'open', light: 'hand_edge', hands: 1, height: 'shoulder' };
  // the three strengths' cells: a strikes cell of a trial stance that holds a press (a string) or the stand-ins, each case with its own values
  const TP = '/stances/trial/x/';
  const TB = '/stances/trial/b/';
  const standFrom = tplMove.standin.keys.from;
  const SC = (extra) => Object.assign({ kind: 'strikes', what: 'a', filter: { weight: ['light'] }, count: 3, quotas: [] }, extra);
  const HOLD = (extra) => Object.assign({ kind: 'string', what: 'a', from: 'martial.x', slots: ['open', 'fast', 'mid', 'slow'], leans: [{ name: 'toward', filter: { limb: ['elbow'] } }, { name: 'down', any: [{ path: ['drop'] }, { target: ['legs'] }] }], asks: [], needs: [{ who: 'Animation', what: 'a' }] }, extra);
  const SI = (extra) => Object.assign({ kind: 'strikes', temporary: true, only: 'stand_in', what: 'a', filter: { weight: ['heavy'] }, count: 2, asks: [], without: { [fid]: [standFrom] } }, extra);
  const cc = (n, tweak, expect) => { const h = HOLD({}); tweak(h); return { id: 'combat-cells-' + n, schema: 'combat-cells.schema.json', mutate: [{ file: C, set: { '/stances/trial': { held: 0, x: SC({ presses: { hold: h } }) } } }], expect }; };
  const si = (n, tweak, expect) => { const s = SI({}); tweak(s); return { id: 'combat-cells-' + n, schema: 'combat-cells.schema.json', mutate: [{ file: C, set: { '/stances/trial': { held: 0, b: SC({ standIn: s }) } } }], expect }; };
  const cl = (n, extra, expect) => ({ id: 'combat-cells-' + n, schema: 'combat-cells.schema.json', mutate: [{ file: C, set: { '/stances/trial': { held: 0, x: SC(extra) } } }], expect });
  const add = [
    // ---- parts ----
    pa('live-valid', { set: { '/schema': 'combat.parts/1' } }, null),
    pa('key-required', { del: ['/legal'] }, { rule: 'required', pointer: '' }),
    pa('schema-version', { set: { '/schema': 'combat.parts/2' } }, { rule: 'const', pointer: '/schema' }),
    pa('unknown-key', { set: { '/extra': 1 } }, { rule: 'additionalProperties', pointer: '/extra' }),
    pa('underscore-key-ok', { set: { '/_why': 'comment' } }, null),
    pa('strikes-block-is-gone', { set: { '/strikes': {} } }, { rule: 'additionalProperties', pointer: '/strikes' }),
    pa('strike-key-required', { del: [ST + 'beat'] }, { rule: 'required', pointer: '/strike' }),
    pa('strike-unknown-key', { set: { [ST + 'wobble']: 1 } }, { rule: 'additionalProperties', pointer: ST + 'wobble' }),
    pa('tip-path-enum', { set: { [ST + 'tips/hand/fist']: ['zigzag'] } }, { rule: 'enum', pointer: ST + 'tips/hand/fist/0' }),
    pa('tip-paths-empty', { set: { [ST + 'tips/hand/fist']: [] } }, { rule: 'minItems', pointer: ST + 'tips/hand/fist' }),
    pa('tip-path-without-targets', { set: { [ST + 'tips/elbow/plate']: ['arc_out'] } }, { rule: 'xref:parts-grammar', pointer: ST + 'tips/elbow/plate/0' }),
    pa('path-without-send', { del: [ST + 'sends/spin'] }, { rule: 'xref:parts-grammar', pointer: ST + 'sends' }),
    pa('path-without-links', { del: [ST + 'links/spin'] }, { rule: 'xref:parts-grammar', pointer: ST + 'links' }),
    pa('path-without-step', { del: [ST + 'step/spin'] }, { rule: 'xref:parts-grammar', pointer: ST + 'step' }),
    pa('path-without-beat', { del: [ST + 'beat/spin'] }, { rule: 'xref:parts-grammar', pointer: ST + 'beat' }),
    pa('send-enum', { set: { [ST + 'sends/line']: 'sideways' } }, { rule: 'enum', pointer: ST + 'sends/line' }),
    pa('beat-range', { set: { [ST + 'beat/line']: 30 } }, { rule: 'maximum', pointer: ST + 'beat/line' }),
    pa('beat-low', { set: { [ST + 'beat/line']: 19 } }, { rule: 'minimum', pointer: ST + 'beat/line' }),
    pa('step-enum', { set: { [ST + 'step/line']: ['in', 'leap'] } }, { rule: 'enum', pointer: ST + 'step/line/1' }),
    pa('links-unknown-path', { set: { [ST + 'links/line']: ['line', 'zigzag'] } }, { rule: 'enum', pointer: ST + 'links/line/1' }),
    pa('light-never-filter-unknown-key', { set: { [ST + 'lightNever']: [{ colour: ['red'] }] } }, { rule: 'additionalProperties', pointer: ST + 'lightNever/0/colour' }),
    pa('light-never-filter-empty-list', { set: { [ST + 'lightNever']: [{ path: [] }] } }, { rule: 'minItems', pointer: ST + 'lightNever/0/path' }),
    pa('light-never-any-ok', { set: { [ST + 'lightNever']: [{ any: [{ path: ['spin'] }, { limb: ['head'] }] }] } }, null),
    pa('forms-key-required', { set: { [ST + 'forms']: [{ when: { weight: ['light'] } }] } }, { rule: 'required', pointer: ST + 'forms/0' }),
    pa('forms-needs-a-rule', { set: { [ST + 'forms']: [{ form: 'light' }] } }, { rule: 'anyOf', pointer: ST + 'forms/0' }),
    pa('forms-duplicate', { set: { [ST + 'forms']: [{ form: 'light', when: { weight: ['light'] } }, { form: 'light', when: { weight: ['light'] } }] } }, { rule: 'xref:parts-grammar', pointer: ST + 'forms/1/form' }),
    pa('forms-unless-later', { set: { [ST + 'forms']: [{ form: 'light', when: { weight: ['light'] }, unless: 'break' }, { form: 'break', when: { weight: ['heavy'] } }] } }, { rule: 'xref:parts-grammar', pointer: ST + 'forms/0/unless' }),
    pa('swap-not-a-hand-tip', { set: { [ST + 'swap']: ['fist', 'ball'] } }, { rule: 'xref:parts-grammar', pointer: ST + 'swap/1' }),
    pa('tag-tip-not-a-hand-tip', { set: { [ST + 'tagTips']: { hands_open_or_claw: ['palm', 'ball'] } } }, { rule: 'xref:parts-grammar', pointer: ST + 'tagTips/hands_open_or_claw/1' }),
    pa('reaim-key-required', { set: { [ST + 'reaim']: { source: 'data/anim/tips.json' } } }, { rule: 'required', pointer: ST + 'reaim' }),
    pa('reaim-levels-shape', { set: { [ST + 'reaim/levels/ok']: 'Re Aim' } }, { rule: 'pattern', pointer: ST + 'reaim/levels/ok' }),
    pa('condition-key-required', { set: { [ST + 'conditions']: [{ id: 'L1', when: { limb: ['hand'] }, rows: ['b01'] }] } }, { rule: 'required', pointer: ST + 'conditions/0' }),
    pa('condition-id-shape', { set: { [ST + 'conditions']: [{ id: 'cond1', when: { limb: ['hand'] }, rows: ['b01'], ask: 'a' }] } }, { rule: 'pattern', pointer: ST + 'conditions/0/id' }),
    pa('condition-needs-when-or-stance', { set: { [ST + 'conditions']: [{ id: 'L1', rows: ['b01'], ask: 'a' }] } }, { rule: 'anyOf', pointer: ST + 'conditions/0' }),
    pa('condition-stance-ok', { set: { [ST + 'banned/-']: { id: 'b98', match: { limb: ['hand'], tip: ['none_such'] }, why: 'a' }, [ST + 'conditions/-']: { id: 'T1', stance: 'any', rows: ['b98'], ask: 'a' } } }, null),
    pa('condition-names-no-rule', { set: { [ST + 'conditions']: [{ id: 'L1', when: { limb: ['hand'] }, rows: ['b99'], ask: 'a' }] } }, { rule: 'xref:parts-grammar', pointer: ST + 'conditions/0/rows/0' }),
    pa('condition-id-twice', { set: { [ST + 'conditions']: [{ id: 'L1', when: { limb: ['hand'] }, rows: ['b01'], ask: 'a' }, { id: 'L1', when: { limb: ['foot'] }, rows: ['b01'], ask: 'b' }] } }, { rule: 'xref:parts-grammar', pointer: ST + 'conditions/1/id' }),
    pa('rule-id-twice', { set: { [ST + 'banned']: [{ id: 'b01', match: { limb: ['head'] }, why: 'a' }, { id: 'b01', match: { limb: ['knee'] }, why: 'b' }] } }, { rule: 'xref:parts-grammar', pointer: ST + 'banned/1/id' }),
    pa('banned-sequence-kind-enum', { set: { [ST + 'bannedSequences']: [{ id: 's01', kind: 'dance', rule: 'a', why: 'b' }] } }, { rule: 'enum', pointer: ST + 'bannedSequences/0/kind' }),
    pa('banned-sequence-key-required', { set: { [ST + 'bannedSequences']: [{ id: 's01', kind: 'run', why: 'a' }] } }, { rule: 'required', pointer: ST + 'bannedSequences/0' }),
    pa('banned-sequence-max-zero', { set: { [ST + 'bannedSequences']: [{ id: 's01', kind: 'run', max: 0, rule: 'a', why: 'b' }] } }, { rule: 'minimum', pointer: ST + 'bannedSequences/0/max' }),
    pa('banned-flag-unknown-warns', { set: { [ST + 'flags']: { fromAnimation: ['claw'] }, [ST + 'banned']: [{ id: 'b01', match: { flags: ['claw', 'levitate'] }, why: 'a' }] } }, { rule: 'xref:parts-grammar', pointer: ST + 'banned/0/match/flags/1' }),
    pa('banned-ok', { set: { [ST + 'banned/-']: { id: 'b98', match: { limb: ['hand'], tip: ['none_such'] }, why: 'a' } } }, null),
    pa('banned-key-required', { set: { [ST + 'banned']: [{ match: { limb: ['head'] } }] } }, { rule: 'required', pointer: ST + 'banned/0' }),
    pa('banned-needs-a-match', { set: { [ST + 'banned']: [{ id: 'b01', why: 'a' }] } }, { rule: 'anyOf', pointer: ST + 'banned/0' }),
    pa('target-not-a-socket', { set: { [ST + 'targets/hand/line']: ['head', 'moon'] } }, { rule: 'xref:parts-grammar', pointer: ST + 'targets/hand/line/1' }),
    pa('travel-key-required', { del: [TR + 'arrive'] }, { rule: 'required', pointer: '/travel' }),
    pa('travel-kind-key-required', { set: { [TR + 'kinds/zip']: { band: 'mid', moves: [{ direction: 'back', entries: ['dash'], exit: null }] } } }, { rule: 'required', pointer: TR + 'kinds/zip' }),
    pa('travel-moves-empty', { set: { [TR + 'kinds/zip/moves']: [] } }, { rule: 'minItems', pointer: TR + 'kinds/zip/moves' }),
    pa('travel-move-key-required', { set: { [TR + 'kinds/zip/moves']: [{ direction: 'back', entries: ['dash'] }] } }, { rule: 'required', pointer: TR + 'kinds/zip/moves/0' }),
    pa('travel-move-exit-null-ok', { set: { [TR + 'kinds/zip/moves/-']: { direction: 'back', entries: ['dash'], exit: null } } }, null),
    pa('travel-move-entries-empty', { set: { [TR + 'kinds/zip/moves']: [{ direction: 'back', entries: [], exit: null }] } }, { rule: 'minItems', pointer: TR + 'kinds/zip/moves/0/entries' }),
    pa('travel-direction-without-arrive', { set: { [TR + 'kinds/zip/moves']: [{ direction: 'sideways', entries: ['dash'], exit: null }] } }, { rule: 'xref:parts-travel', pointer: TR + 'kinds/zip/moves/0/direction' }),
    pa('travel-entry-unknown', { set: { [TR + 'kinds/zip/moves']: [{ direction: 'back', entries: ['teleport'], exit: null }] } }, { rule: 'xref:parts-travel', pointer: TR + 'kinds/zip/moves/0/entries/0' }),
    pa('travel-exit-unknown', { set: { [TR + 'kinds/zip/moves']: [{ direction: 'back', entries: ['dash'], exit: 'teleport' }] } }, { rule: 'xref:parts-travel', pointer: TR + 'kinds/zip/moves/0/exit' }),
    pa('travel-arrive-path-enum', { set: { [TR + 'arrive/back']: ['zigzag'] } }, { rule: 'enum', pointer: TR + 'arrive/back/0' }),
    pa('shot-key-required', { del: [SH + 'hands'] }, { rule: 'required', pointer: '/shot' }),
    pa('shot-release-empty', { set: { [SH + 'release']: [] } }, { rule: 'minItems', pointer: SH + 'release' }),
    pa('shot-rule-key-required', { set: { [SH + 'rules']: [{ if: { release: ['drop'] }, why: 'a' }] } }, { rule: 'required', pointer: SH + 'rules/0' }),
    pa('shot-rule-unknown-release', { set: { [SH + 'release']: ['thrust', 'drop'], [SH + 'rules']: [{ if: { release: ['teleport'] }, then: { body: ['planted'] } }] } }, { rule: 'xref:parts-shot', pointer: SH + 'rules/0/if/release/0' }),
    pa('shot-rule-unknown-body', { set: { [SH + 'body']: ['planted'], [SH + 'rules']: [{ if: { release: ['drop'] }, then: { body: ['hovering'] } }] } }, { rule: 'xref:parts-shot', pointer: SH + 'rules/0/then/body/0' }),
    pa('shot-forms-key-required', { set: { [SH + 'forms']: [{ form: 'speed' }] } }, { rule: 'required', pointer: SH + 'forms/0' }),
    pa('shot-hand-key-required', { set: { [SH + 'hands/open_palm']: { shape: 'open', light: 'hand_edge', hands: 1 } } }, { rule: 'required', pointer: SH + 'hands/open_palm' }),
    pa('shot-hand-ok', { set: { [SH + 'hands/open_palm']: handRow } }, null),
    pa('shot-hand-count-zero', { set: { [SH + 'hands/open_palm']: Object.assign({}, handRow, { hands: 0 }) } }, { rule: 'minimum', pointer: SH + 'hands/open_palm/hands' }),
    pa('shot-hand-name-shape', { set: { [SH + 'hands/Open Palm']: handRow } }, { rule: 'propertyNames', pointer: SH + 'hands/Open Palm' }),
    pa('readings-form-shape', { set: { '/readings/martial/speed': ['Quick'] } }, { rule: 'anyOf', pointer: '/readings/martial/speed' }),
    pa('readings-stance-unknown-warns', { set: { '/readings/nowhere': { speed: ['light'] } } }, { rule: 'xref:parts-grammar', pointer: '/readings/nowhere' }),
    pa('legal-key-required', { del: [LG + 'stacking'] }, { rule: 'required', pointer: '/legal' }),
    pa('legal-held-scope-open-object-ok', { set: { [LG + 'heldScope']: { _about: 'a', anything: { goes: ['here'] } } } }, null),
    pa('legal-held-scope-type', { set: { [LG + 'heldScope']: [] } }, { rule: 'type', pointer: LG + 'heldScope' }),
    pa('legal-unknown-group-is-not-rows', { set: { [LG + 'extra']: 'a note' } }, { rule: 'type', pointer: LG + 'extra' }),
    pa('legal-row-kind-enum', { set: { [LG + 'motion']: [{ id: 'm01', kind: 'dance', rule: 'a', why: 'b' }] } }, { rule: 'enum', pointer: LG + 'motion/0/kind' }),
    pa('legal-row-key-required', { set: { [LG + 'motion']: [{ id: 'm01', kind: 'drawn', owner: 'Animation', rule: 'a' }] } }, { rule: 'required', pointer: LG + 'motion/0' }),
    pa('legal-row-id-shape', { set: { [LG + 'motion']: [{ id: 'motion1', kind: 'drawn', owner: 'Animation', rule: 'a', why: 'b' }] } }, { rule: 'pattern', pointer: LG + 'motion/0/id' }),
    pa('legal-row-unknown-key', { set: { [LG + 'motion']: [{ id: 'm01', kind: 'drawn', owner: 'Animation', rule: 'a', why: 'b', mood: 1 }] } }, { rule: 'additionalProperties', pointer: LG + 'motion/0/mood' }),
    pa('legal-travel-row-needs-if-then', { set: { [LG + 'motion']: [{ id: 'm01', kind: 'travel', rule: 'a', why: 'b' }] } }, { rule: 'required', pointer: LG + 'motion/0' }),
    pa('legal-travel-row-ok', { set: { [LG + 'motion/-']: { id: 'm98', kind: 'travel', if: { kind: ['zip'], direction: ['far_side'] }, then: { exit: ['pivot', 'arc_dive', 'fade'] }, rule: 'a', why: 'b' } } }, null),
    pa('legal-numbers-row-needs-check', { set: { [LG + 'motion']: [{ id: 'm01', kind: 'numbers', owner: 'Simulation', rule: 'a', why: 'b' }] } }, { rule: 'required', pointer: LG + 'motion/0' }),
    pa('legal-drawn-row-needs-owner', { set: { [LG + 'motion']: [{ id: 'm01', kind: 'drawn', rule: 'a', why: 'b' }] } }, { rule: 'required', pointer: LG + 'motion/0' }),
    pa('legal-hand-row-needs-never', { set: { [LG + 'energy']: [{ id: 'e01', kind: 'hand', rule: 'a', why: 'b' }] } }, { rule: 'required', pointer: LG + 'energy/0' }),
    pa('legal-hand-row-need-ok', { set: { [SH + 'hands/test_hand']: handRow, [LG + 'energy/-']: { id: 'e98', kind: 'hand', need: { hands: [1] }, never: { light: ['ball'] }, rule: 'a', why: 'b' } } }, null),
    pa('legal-hand-need-unknown-property', { set: { [SH + 'hands']: { open_palm: handRow }, [LG + 'energy']: [{ id: 'e01', kind: 'hand', need: { mood: [1] }, never: { light: ['ball'] }, rule: 'a', why: 'b' }] } }, { rule: 'xref:parts-shot', pointer: LG + 'energy/0/need/mood' }),
    pa('legal-move-row-hand-need-ok', { set: { [SH + 'hands/test_hand']: handRow, [LG + 'energy/-']: { id: 'e97', kind: 'move', if: { delivery: ['volley'] }, then: { release: ['thrust', 'flick', 'sweep', 'drop', 'lob'] }, hand: { need: { hands: [1] } }, rule: 'a', why: 'b' } } }, null),
    pa('legal-move-row-hand-need-unknown-property', { set: { [SH + 'hands']: { open_palm: handRow }, [LG + 'energy']: [{ id: 'e05', kind: 'move', if: { delivery: ['volley'] }, then: { release: ['thrust'] }, hand: { need: { mood: [1] } }, rule: 'a', why: 'b' }] } }, { rule: 'xref:parts-shot', pointer: LG + 'energy/0/hand/need/mood' }),
    pa('legal-move-row-hand-unknown-key', { set: { [LG + 'energy']: [{ id: 'e05', kind: 'move', if: { delivery: ['volley'] }, then: { release: ['sweep'] }, hand: { mood: 1 }, rule: 'a', why: 'b' }] } }, { rule: 'additionalProperties', pointer: LG + 'energy/0/hand/mood' }),
    pa('legal-hold-points-row-needs-never', { set: { [LG + 'grabs']: [{ id: 'g01', kind: 'holdPoints', rule: 'a', why: 'b' }] } }, { rule: 'required', pointer: LG + 'grabs/0' }),
    pa('legal-rule-id-twice', { set: { [LG + 'motion']: [{ id: 'm01', kind: 'drawn', owner: 'A', rule: 'a', why: 'b' }, { id: 'm01', kind: 'drawn', owner: 'A', rule: 'a', why: 'b' }] } }, { rule: 'xref:parts-grammar', pointer: LG + 'motion/1/id' }),
    pa('legal-id-clashes-with-a-banned-row', { set: { [ST + 'banned']: [{ id: 'b01', match: { limb: ['head'] }, why: 'a' }], [LG + 'motion']: [{ id: 'b01', kind: 'drawn', owner: 'A', rule: 'a', why: 'b' }] } }, { rule: 'xref:parts-grammar', pointer: LG + 'motion/0/id' }),
    pa('grab-hold-points-empty', { set: { '/grab/holdPoints': [] } }, { rule: 'minItems', pointer: '/grab/holdPoints' }),
    pa('grab-hold-point-is-never', { set: { '/grab/holdPoints': ['collar', 'throat'], [LG + 'grabs']: [{ id: 'g01', kind: 'holdPoints', never: ['throat', 'hair'], rule: 'a', why: 'b' }, { id: 'g02', kind: 'drawn', owner: 'A', rule: 'a', why: 'b' }, { id: 'g03', kind: 'drawn', owner: 'A', rule: 'a', why: 'b' }] } }, { rule: 'xref:parts-legal', pointer: '/grab/holdPoints/1' }),
    pa('grab-hold-points-clear-of-never-ok', { set: { '/grab/holdPoints': ['collar', 'waist'], [LG + 'grabs']: [{ id: 'g01', kind: 'holdPoints', never: ['throat', 'hair'], rule: 'a', why: 'b' }, { id: 'g02', kind: 'drawn', owner: 'A', rule: 'a', why: 'b' }, { id: 'g03', kind: 'drawn', owner: 'A', rule: 'a', why: 'b' }] } }, null),
    // ---- parts: the three strengths ----
    pa('weights-required', { del: [ST + 'weights'] }, { rule: 'required', pointer: '/strike' }),
    pa('weights-item-shape', { set: { [ST + 'weights']: ['Light'] } }, { rule: 'pattern', pointer: ST + 'weights/0' }),
    pa('weights-empty', { set: { [ST + 'weights']: [] } }, { rule: 'minItems', pointer: ST + 'weights' }),
    pa('anim-weight-enum', { set: { [ST + 'animWeight']: { light: 'average' } } }, { rule: 'enum', pointer: ST + 'animWeight/light' }),
    pa('windup-required', { del: [ST + 'windup'] }, { rule: 'required', pointer: '/strike' }),
    pa('windup-medium-required', { set: { [ST + 'windup']: {} } }, { rule: 'required', pointer: ST + 'windup' }),
    pa('windup-rule-key-required', { set: { [ST + 'windup/medium']: [{ id: 'w1', when: { path: ['line'] } }] } }, { rule: 'required', pointer: ST + 'windup/medium/0' }),
    pa('windup-rule-reads-enum', { set: { [ST + 'windup/medium']: [{ id: 'w1', when: { path: ['line'] }, reads: 'slow' }] } }, { rule: 'enum', pointer: ST + 'windup/medium/0/reads' }),
    pa('windup-rule-unknown-key', { set: { [ST + 'windup/medium']: [{ id: 'w1', when: { path: ['line'] }, reads: 'quick', mood: 1 }] } }, { rule: 'additionalProperties', pointer: ST + 'windup/medium/0/mood' }),
    pa('windup-rule-id-twice', { set: { [ST + 'windup/medium']: [{ id: 'w1', when: { path: ['line'] }, reads: 'quick' }, { id: 'w1', when: { path: ['rise'] }, reads: 'quick' }] } }, { rule: 'xref:parts-windup', pointer: ST + 'windup/medium/1/id' }),
    pa('windup-rule-last-ok', { set: { [ST + 'windup/medium/-']: { id: 'w99', when: { limb: ['head'] }, reads: 'quick', change: 'a note', why: 'a note' } } }, null),
    pa('heavy-required', { del: [ST + 'heavy'] }, { rule: 'required', pointer: '/strike' }),
    pa('heavy-key-required', { set: { [ST + 'heavy']: { tips: {}, never: [] } } }, { rule: 'required', pointer: ST + 'heavy' }),
    pa('heavy-tip-path-enum', { set: { [ST + 'heavy/tips/hand/fist']: ['zigzag'] } }, { rule: 'enum', pointer: ST + 'heavy/tips/hand/fist/0' }),
    pa('heavy-tip-not-in-the-grammar', { set: { [ST + 'heavy/tips/hand/claw']: ['line'] } }, { rule: 'xref:parts-heavy', pointer: ST + 'heavy/tips/hand/claw' }),
    pa('heavy-never-key-required', { set: { [ST + 'heavy/never']: [{ shape: { limb: ['foot'] } }] } }, { rule: 'required', pointer: ST + 'heavy/never/0' }),
    pa('heavy-never-ok', { set: { [ST + 'heavy/never/-']: { shape: { limb: ['head'] }, why: 'a ruling' } } }, null),
    pa('heavy-drive-key-required', { set: { [ST + 'heavy/drive/line']: { id: 'a_drive', word: 'a', flags: [], bears: [], what: 'a', tell: 'a', end: 'a' } } }, { rule: 'required', pointer: ST + 'heavy/drive/line' }),
    pa('heavy-drive-unknown-key', { set: { [ST + 'heavy/drive/line']: { id: 'a_drive', word: 'a', flags: [], bears: [], what: 'a', tell: 'a', end: 'a', seen: false, mood: 1 } } }, { rule: 'additionalProperties', pointer: ST + 'heavy/drive/line/mood' }),
    pa('heavy-drive-bears-no-rule', { set: { [ST + 'heavy/drive/line']: { id: 'a_drive', word: 'a', flags: [], bears: ['b99'], what: 'a', tell: 'a', end: 'a', seen: false } } }, { rule: 'xref:parts-heavy', pointer: ST + 'heavy/drive/line/bears/0' }),
    pa('heavy-drive-id-twice', { set: { [ST + 'heavy/drive/line']: { id: 'twice', word: 'a', flags: [], bears: [], what: 'a', tell: 'a', end: 'a', seen: false }, [ST + 'heavy/drive/rise']: { id: 'twice', word: 'a', flags: [], bears: [], what: 'a', tell: 'a', end: 'a', seen: false } } }, { rule: 'xref:parts-heavy', pointer: ST + 'heavy/drive/rise/id' }),
    pa('heavy-drive-seen-type', { set: { [ST + 'heavy/drive/line']: { id: 'a_drive', word: 'a', flags: [], bears: [], what: 'a', tell: 'a', end: 'a', seen: 'yes' } } }, { rule: 'type', pointer: ST + 'heavy/drive/line/seen' }),
    pa('heavy-words-key-shape', { set: { [ST + 'heavy/words']: { fist: 'a fist' } } }, { rule: 'propertyNames', pointer: ST + 'heavy/words/fist' }),
    pa('heavy-words-tip-unknown', { set: { [ST + 'heavy/words/hand.claw']: 'a claw' } }, { rule: 'xref:parts-heavy', pointer: ST + 'heavy/words/hand.claw' }),
    pa('burst-required', { del: [ST + 'burst'] }, { rule: 'required', pointer: '/strike' }),
    pa('burst-class-key-required', { set: { [ST + 'burst/classes/fast']: { gap: '5 ticks or fewer', when: {} } } }, { rule: 'required', pointer: ST + 'burst/classes/fast' }),
    pa('burst-no-stutter-key-required', { set: { [ST + 'burst/noStutter']: [{ id: 'u1', kind: 'run' }] } }, { rule: 'required', pointer: ST + 'burst/noStutter/0' }),
    pa('burst-no-stutter-once-ok', { set: { [ST + 'burst/noStutter/-']: { id: 'u98', kind: 'once', rule: 'no piece twice in one burst' } } }, null),
    pa('forms-reads-enum', { set: { [ST + 'forms/-']: { form: 'quick', when: { weight: ['medium'] }, reads: 'slow' } } }, { rule: 'enum', pointer: ST + 'forms/' + rj(P).strike.forms.length + '/reads' }),
    pa('forms-same-name-for-another-weight-ok', { set: { [ST + 'forms/-']: { form: 'quick', when: { weight: ['heavy'], limb: ['tail'] } } } }, null),
    pa('banned-applies-to-ok', { set: { [ST + 'banned/-']: { id: 'b97', match: { limb: ['hand'], tip: ['none_such'] }, why: 'a', appliesTo: 'open or clawed hands' } } }, null),
    pa('condition-from-ok', { set: { [ST + 'banned/-']: { id: 'b96', match: { limb: ['hand'], tip: ['none_such'] }, why: 'a' }, [ST + 'conditions/-']: { id: 'T3', stance: 'any', rows: ['b96'], from: 'Legal\'s screen', ask: 'a' } } }, null),
    pa('readings-presses-ok', { set: { '/readings/martial/z': { tap: 'light', mash: 'flurry', hold: 'the burst', beat: 'skill' } } }, null),
    pa('readings-presses-type', { set: { '/readings/martial/x': 5 } }, { rule: 'anyOf', pointer: '/readings/martial/x' }),
    pa('legal-new-group-ok', { set: { [LG + 'extra_rows']: [{ id: 'x01', kind: 'drawn', owner: 'A', rule: 'a', why: 'b' }] } }, null),
    pa('legal-string-row-needs-uses', { set: { [LG + 'extra_rows']: [{ id: 'x01', kind: 'string', rule: 'a', why: 'b' }] } }, { rule: 'required', pointer: LG + 'extra_rows/0' }),
    pa('legal-string-row-ok', { set: { [LG + 'extra_rows']: [{ id: 'x01', kind: 'string', uses: ['s01'], ignores: ['button'], rule: 'a', why: 'b' }] } }, null),
    pa('legal-slots-row-needs-class', { set: { [LG + 'extra_rows']: [{ id: 'x01', kind: 'slots', rule: 'a', why: 'b' }] } }, { rule: 'required', pointer: LG + 'extra_rows/0' }),
    pa('legal-slots-row-ok', { set: { [LG + 'extra_rows']: [{ id: 'x01', kind: 'slots', class: 'fast', maxRun: 3, rule: 'a', why: 'b' }] } }, null),
    pa('legal-slots-max-run-zero', { set: { [LG + 'extra_rows']: [{ id: 'x01', kind: 'slots', class: 'fast', maxRun: 0, rule: 'a', why: 'b' }] } }, { rule: 'minimum', pointer: LG + 'extra_rows/0/maxRun' }),
    pa('legal-burst-row-needs-uses', { set: { [LG + 'extra_rows']: [{ id: 'x01', kind: 'burst', rule: 'a', why: 'b' }] } }, { rule: 'required', pointer: LG + 'extra_rows/0' }),
    pa('legal-shape-row-needs-match', { set: { [LG + 'extra_rows']: [{ id: 'x01', kind: 'shape', rule: 'a', why: 'b' }] } }, { rule: 'required', pointer: LG + 'extra_rows/0' }),
    pa('legal-shape-row-ok', { set: { [LG + 'extra_rows']: [{ id: 'x01', kind: 'shape', match: { weight: ['medium'], flags: ['hip_chamber'] }, rule: 'a', why: 'b' }] } }, null),
    pa('legal-hold-points-row-grab-ok', { set: { [LG + 'extra_rows']: [{ id: 'x01', kind: 'holdPoints', grab: 'tackle', allowed: ['waist'], never: ['throat'], rule: 'a', why: 'b' }] } }, null),
    pa('legal-move-row-string-ok', { set: { [LG + 'extra_rows']: [{ id: 'x01', kind: 'move', if: { delivery: ['volley'] }, then: { release: ['thrust', 'flick', 'sweep', 'drop', 'lob'] }, string: { same: ['hand'], max: 1 }, rule: 'a', why: 'b' }] } }, null),
    pa('grab-kinds-ok', { set: { '/grab/kinds/test_kind': ['collar'] } }, null),
    pa('grab-kinds-point-shape', { set: { '/grab/kinds/test_kind': ['Collar'] } }, { rule: 'pattern', pointer: '/grab/kinds/test_kind/0' }),
    // ---- identity ----
    id('live-valid', { set: { '/schema': 'combat.identity/1' } }, null),
    id('key-required', { del: ['/rejected'] }, { rule: 'required', pointer: '' }),
    id('unknown-key', { set: { '/extra': 1 } }, { rule: 'additionalProperties', pointer: '/extra' }),
    id('underscore-key-ok', { set: { '/_why': 'comment' } }, null),
    id('fighter-key-required', { del: [F + 'reuse'] }, { rule: 'required', pointer: F.slice(0, -1) }),
    id('fighter-unknown-key', { set: { [F + 'mood']: 1 } }, { rule: 'additionalProperties', pointer: F + 'mood' }),
    id('fighter-not-in-recipes', { set: { '/fighters/nobody': clone(ident) } }, { rule: 'xref:identity-ref', pointer: '/fighters/nobody' }),
    id('waves-shape', { set: { [F + 'waves']: ['Wave 1'] } }, { rule: 'pattern', pointer: F + 'waves/0' }),
    id('waves-empty', { set: { [F + 'waves']: [] } }, { rule: 'minItems', pointer: F + 'waves' }),
    id('wave-without-manifest', { set: { [F + 'waves']: ['wave9'] } }, { rule: 'xref:identity-ref', pointer: F + 'waves/0' }),
    id('entry-waves-empty', { set: { [F + 'entryWaves']: [] } }, { rule: 'minItems', pointer: F + 'entryWaves' }),
    id('entry-waves-shape', { set: { [F + 'entryWaves']: ['Wave 2'] } }, { rule: 'pattern', pointer: F + 'entryWaves/0' }),
    id('entry-wave-without-entry-map', { set: { [F + 'entryWaves']: ['wave9'] } }, { rule: 'xref:identity-ref', pointer: F + 'entryWaves/0' }),
    id('weight-negative', { set: { [F + 'weights/limb/hand']: -1 } }, { rule: 'minimum', pointer: F + 'weights/limb/hand' }),
    id('weight-type', { set: { [F + 'weights/path/line']: 'high' } }, { rule: 'type', pointer: F + 'weights/path/line' }),
    id('weight-key-required', { del: [F + 'weights/tip'] }, { rule: 'required', pointer: F + 'weights' }),
    id('weight-tip-unknown', { set: { [F + 'weights/tip/hand.claw']: 1 } }, { rule: 'xref:identity-ref', pointer: F + 'weights/tip/hand.claw' }),
    id('weight-tip-without-limb', { set: { [F + 'weights/tip/fist']: 1 } }, { rule: 'xref:identity-ref', pointer: F + 'weights/tip/fist' }),
    id('weight-entry-negative', { set: { [F + 'weights/entry']: { dash: -1 } } }, { rule: 'minimum', pointer: F + 'weights/entry/dash' }),
    id('weight-entry-unknown', { set: { [F + 'weights/entry']: { teleport: 1 } } }, { rule: 'xref:identity-ref', pointer: F + 'weights/entry/teleport' }),
    id('weights-by-key-required', { set: { [F + 'weightsBy']: [{ tip: { 'hand.fist': 1 } }] } }, { rule: 'required', pointer: F + 'weightsBy/0' }),
    id('weights-by-tip-unknown', { set: { [F + 'weightsBy']: [{ when: { weight: ['light'] }, tip: { 'hand.claw': 2 } }] } }, { rule: 'xref:identity-ref', pointer: F + 'weightsBy/0/tip/hand.claw' }),
    id('never-key-required', { set: { [F + 'never']: [{ shape: { limb: ['head'] } }] } }, { rule: 'required', pointer: F + 'never/0' }),
    id('never-ok', { set: { [F + 'never']: [{ shape: { limb: ['head'] }, why: 'a ruling' }] } }, null),
    id('tip-flags-tip-unknown', { set: { [F + 'tipFlags']: { 'hand.claw': ['claw'] } } }, { rule: 'xref:identity-ref', pointer: F + 'tipFlags/hand.claw' }),
    id('tip-flags-empty', { set: { [F + 'tipFlags']: { 'hand.palm': [] } } }, { rule: 'minItems', pointer: F + 'tipFlags/hand.palm' }),
    id('reuse-below-one', { set: { [F + 'reuse/posed']: 0.5 } }, { rule: 'minimum', pointer: F + 'reuse/posed' }),
    id('reuse-key-required', { del: [F + 'reuse/re_aim'] }, { rule: 'required', pointer: F + 'reuse' }),
    id('reuse-edge-levels-ok', { set: { [F + 'reuse/re_aim_edge']: 2, [F + 'reuse/hand_state_re_aim_edge']: 2 } }, null),
    id('reuse-edge-below-one', { set: { [F + 'reuse/re_aim_edge']: 0.5 } }, { rule: 'minimum', pointer: F + 'reuse/re_aim_edge' }),
    id('energy-key-required', { set: { [F + 'energy']: { hands: { blade_hand: 1 } } } }, { rule: 'required', pointer: F + 'energy' }),
    id('energy-unknown-key', { set: { [F + 'energy/mood']: 1 } }, { rule: 'additionalProperties', pointer: F + 'energy/mood' }),
    id('energy-hand-weight-negative', { set: { [F + 'energy']: { hands: { open_palm: -1 }, release: { thrust: 1 } } } }, { rule: 'minimum', pointer: F + 'energy/hands/open_palm' }),
    id('energy-hand-not-in-shot', { set: { [F + 'energy']: { hands: { claw_fist: 1 }, release: { thrust: 1 } } } }, { rule: 'xref:identity-ref', pointer: F + 'energy/hands/claw_fist' }),
    id('energy-release-not-in-shot', { set: { [F + 'energy']: { hands: { open_palm: 1 }, release: { hurl: 1 } } } }, { rule: 'xref:identity-ref', pointer: F + 'energy/release/hurl' }),
    id('energy-split-type', { set: { [F + 'energy']: { hands: { open_palm: 1 }, release: { thrust: 1 }, split: 'yes' } } }, { rule: 'type', pointer: F + 'energy/split' }),
    id('energy-posed-hand-not-a-pose', { set: { [F + 'energy']: { hands: { open_palm: 1 }, release: { thrust: 1 }, posedHands: { open_palm: 'no.such.pose' } } } }, { rule: 'xref:identity-ref', pointer: F + 'energy/posedHands/open_palm' }),
    id('energy-posed-key-required', { set: { [F + 'energy']: { hands: { open_palm: 1 }, release: { thrust: 1 }, posed: [{ when: { delivery: ['volley'] } }] } } }, { rule: 'required', pointer: F + 'energy/posed/0' }),
    id('energy-posed-set-unknown', { set: { [F + 'energy']: { hands: { open_palm: 1 }, release: { thrust: 1 }, posed: [{ when: { delivery: ['volley'] }, set: 'no.such.set' }] } } }, { rule: 'xref:identity-ref', pointer: F + 'energy/posed/0/set' }),
    id('special-key-required', { set: { [F + 'specials']: { x: { id: 'special.cut', what: 'a cut' } } } }, { rule: 'required', pointer: F + 'specials/x' }),
    id('special-id-shape', { set: { [F + 'specials']: { x: { id: 'cut', what: 'a cut', status: 'designed', parts: { level: ['up'] } } } } }, { rule: 'pattern', pointer: F + 'specials/x/id' }),
    id('special-button-unknown', { set: { [F + 'specials']: { z: { id: 'special.cut', what: 'a cut', status: 'designed', parts: { level: ['up'] } } } } }, { rule: 'additionalProperties', pointer: F + 'specials/z' }),
    id('special-parts-empty-list', { set: { [F + 'specials']: { x: { id: 'special.cut', what: 'a cut', status: 'designed', parts: { level: [] } } } } }, { rule: 'minItems', pointer: F + 'specials/x/parts/level' }),
    id('special-ok', { set: { [F + 'specials/x/status']: 'designed, not posed' } }, null),
    id('weights-by-target-ok', { set: { [F + 'weightsBy/-']: { when: { weight: ['light'] }, target: { head: 1.5 }, path: { line: 2 }, limb: { hand: 1.2 }, _why: 'a note' } } }, null),
    id('weights-by-path-unknown', { set: { [F + 'weightsBy/-']: { when: { weight: ['light'] }, path: { zigzag: 2 } } } }, { rule: 'xref:identity-ref', pointer: F + 'weightsBy/' + ident.weightsBy.length + '/path/zigzag' }),
    id('weights-by-limb-unknown', { set: { [F + 'weightsBy/-']: { when: { weight: ['light'] }, limb: { tail: 2 } } } }, { rule: 'xref:identity-ref', pointer: F + 'weightsBy/' + ident.weightsBy.length + '/limb/tail' }),
    id('weights-by-target-negative', { set: { [F + 'weightsBy/-']: { when: { weight: ['light'] }, target: { head: -1 } } } }, { rule: 'minimum', pointer: F + 'weightsBy/' + ident.weightsBy.length + '/target/head' }),
    id('pinned-ok', { set: { [F + 'pinned']: { 'martial.b': [['hand', 'blade', 'line', 'head', 'light']] } } }, null),
    id('pinned-cell-unknown', { set: { [F + 'pinned']: { 'martial.q': [['hand', 'blade', 'line', 'head', 'light']] } } }, { rule: 'xref:identity-ref', pointer: F + 'pinned/martial.q' }),
    id('pinned-cell-id-shape', { set: { [F + 'pinned']: { martial: [['hand', 'blade', 'line', 'head', 'light']] } } }, { rule: 'propertyNames', pointer: F + 'pinned/martial' }),
    id('pinned-shape-invalid', { set: { [F + 'pinned']: { 'martial.b': [['hand', 'claw', 'line', 'head', 'light']] } } }, { rule: 'xref:identity-ref', pointer: F + 'pinned/martial.b/0' }),
    id('pinned-row-short', { set: { [F + 'pinned']: { 'martial.b': [['hand', 'blade', 'line', 'head']] } } }, { rule: 'minItems', pointer: F + 'pinned/martial.b/0' }),
    id('pinned-weight-enum', { set: { [F + 'pinned']: { 'martial.b': [['hand', 'blade', 'line', 'head', 'average']] } } }, { rule: 'enum', pointer: F + 'pinned/martial.b/0/4' }),
    id('burst-close-ok', { set: { [F + 'burst']: { close: { path: ['line'] }, _close: 'a note' } } }, null),
    id('burst-close-path-enum', { set: { [F + 'burst']: { close: { path: ['zigzag'] } } } }, { rule: 'enum', pointer: F + 'burst/close/path/0' }),
    id('burst-close-path-empty', { set: { [F + 'burst']: { close: { path: [] } } } }, { rule: 'minItems', pointer: F + 'burst/close/path' }),
    id('burst-unknown-key', { set: { [F + 'burst']: { close: { path: ['line'] }, mood: 1 } } }, { rule: 'additionalProperties', pointer: F + 'burst/mood' }),
    id('manner-ok', { set: { [F + 'manner']: { heavy: 'a show-off', burst: 'a show of speed', _about: 'a note' } } }, null),
    id('manner-unknown-key', { set: { [F + 'manner']: { heavy: 'a', mood: 'b' } } }, { rule: 'additionalProperties', pointer: F + 'manner/mood' }),
    id('manner-type', { set: { [F + 'manner/heavy']: 5 } }, { rule: 'type', pointer: F + 'manner/heavy' }),
    id('reuse-stand-in-ok', { set: { [F + 'reuse/stand_in']: 1 } }, null),
    id('reuse-stand-in-below-one', { set: { [F + 'reuse/stand_in']: 0.5 } }, { rule: 'minimum', pointer: F + 'reuse/stand_in' }),
    id('never-id-ok', { set: { [F + 'never/-']: { id: 'pointed', shape: { limb: ['head'], tip: ['none_such'] }, why: 'a ruling' } } }, null),
    id('rejected-key-required', { set: { '/rejected': [{ fighter: fid, why: 'a review' }] } }, { rule: 'required', pointer: '/rejected/0' }),
    id('rejected-fighter-unknown', { set: { '/rejected': [{ fighter: 'nobody', shape: SHAPE, why: 'a review' }] } }, { rule: 'xref:identity-ref', pointer: '/rejected/0/fighter' }),
    id('rejected-ok', { set: { '/rejected': [{ fighter: fid, shape: SHAPE, why: 'a review' }] } }, null),
    // ---- cells ----
    ce('live-valid', { set: { '/schema': 'combat.cells/1' } }, null),
    ce('key-required', { del: ['/stances'] }, { rule: 'required', pointer: '' }),
    ce('seed-type', { set: { '/seed': 'lucky' } }, { rule: 'type', pointer: '/seed' }),
    ce('unknown-key', { set: { '/extra': 1 } }, { rule: 'additionalProperties', pointer: '/extra' }),
    ce('spread-zero', { set: { '/spread/path': 0 } }, { rule: 'exclusiveMinimum', pointer: '/spread/path' }),
    ce('spread-above-one', { set: { '/spread/tip': 1.5 } }, { rule: 'maximum', pointer: '/spread/tip' }),
    ce('spread-key-required', { del: ['/spread/shape'] }, { rule: 'required', pointer: '/spread' }),
    ce('stance-held-required', { del: ['/stances/martial/held'] }, { rule: 'required', pointer: '/stances/martial' }),
    ce('stance-unknown-key', { set: { '/stances/martial/z': {} } }, { rule: 'additionalProperties', pointer: '/stances/martial/z' }),
    ce('cell-kind-enum', { set: { '/stances/martial/x/kind': 'dance' } }, { rule: 'enum', pointer: '/stances/martial/x/kind' }),
    ce('strikes-cell-count-required', { set: { '/stances/martial/x': { kind: 'strikes', what: 'a', filter: { weight: ['light'] }, quotas: [] } } }, { rule: 'required', pointer: '/stances/martial/x' }),
    ce('strikes-cell-count-zero', { set: { '/stances/martial/x': { kind: 'strikes', what: 'a', filter: { weight: ['light'] }, count: 0, quotas: [] } } }, { rule: 'minimum', pointer: '/stances/martial/x/count' }),
    ce('strikes-cell-quotas-required', { set: { '/stances/martial/x': { kind: 'strikes', what: 'a', filter: { weight: ['light'] }, count: 3 } } }, { rule: 'required', pointer: '/stances/martial/x' }),
    ce('strikes-cell-layer-and-flags-ok', { set: { '/stances/trial': { held: 0, x: { kind: 'strikes', what: 'a', filter: { weight: ['light'] }, count: 3, layer: 'guard', as: 'push', anyWeight: true, notFlags: ['leap'], readings: ['speed', 'tech'], quotas: [] } } } }, null),
    ce('strikes-cell-not-flags-empty', { set: { '/stances/martial/x': { kind: 'strikes', what: 'a', filter: { weight: ['light'] }, count: 3, notFlags: [], quotas: [] } } }, { rule: 'minItems', pointer: '/stances/martial/x/notFlags' }),
    ce('strikes-cell-any-weight-type', { set: { '/stances/martial/x': { kind: 'strikes', what: 'a', filter: { weight: ['light'] }, count: 3, anyWeight: 'yes', quotas: [] } } }, { rule: 'type', pointer: '/stances/martial/x/anyWeight' }),
    ce('strikes-cell-filter-with-any-ok', { set: { '/stances/trial': { held: 0, x: { kind: 'strikes', what: 'a', filter: { any: [{ limb: ['hand'] }, { limb: ['foot'] }] }, count: 3, quotas: [] } } } }, null),
    ce('strikes-cell-unknown-key', { set: { '/stances/martial/x': { kind: 'strikes', what: 'a', filter: { weight: ['light'] }, count: 3, quotas: [], mood: 1 } } }, { rule: 'additionalProperties', pointer: '/stances/martial/x/mood' }),
    ce('context-cell-held-required', { set: { '/stances/martial/a': { kind: 'context', what: 'a', pressed: ['throw'] } } }, { rule: 'required', pointer: '/stances/martial/a' }),
    ce('context-cell-held-is-a-list', { set: { '/stances/martial/a': { kind: 'context', what: 'a', pressed: ['throw'], held: 'grab' } } }, { rule: 'type', pointer: '/stances/martial/a/held' }),
    { id: 'combat-cells-context-cell-ok', schema: 'combat-cells.schema.json', mutate: [{ file: C, set: { '/stances/trial': { held: 0, a: { kind: 'context', what: 'a', pressed: ['throw'], held: ['grab'], asks: ['Z9'], needs: [{ who: 'Simulation', what: 'a lockout' }] } } } }, ...ownCond()], expect: null },
    ce('cell-asks-shape', { set: { '/stances/martial/a': { kind: 'context', what: 'a', pressed: ['throw'], held: ['grab'], asks: ['g1'] } } }, { rule: 'pattern', pointer: '/stances/martial/a/asks/0' }),
    ce('cell-asks-unknown-condition', { set: { '/stances/martial/a': { kind: 'context', what: 'a', pressed: ['throw'], held: ['grab'], asks: ['Q99'] } } }, { rule: 'xref:cells-asks', pointer: '/stances/martial/a/asks/0' }),
    ce('cell-needs-key-required', { set: { '/stances/martial/a': { kind: 'context', what: 'a', pressed: ['throw'], held: ['grab'], needs: [{ who: 'Simulation' }] } } }, { rule: 'required', pointer: '/stances/martial/a/needs/0' }),
    ce('frame-cell-slots-required', { set: { '/stances/martial/b': { kind: 'frame', what: 'a' } } }, { rule: 'required', pointer: '/stances/martial/b' }),
    { id: 'combat-cells-frame-cell-readings-and-asks-ok', schema: 'combat-cells.schema.json', mutate: [{ file: C, set: { '/stances/trial': { held: 0, b: { kind: 'frame', what: 'a', slots: [{ slot: 'tell', ticks: 30 }], readings: { speed: 'the quick form' }, legal: 'a person screens it', asks: ['Z9'] } } } }, ...ownCond()], expect: null },
    ce('frame-cell-asks-unknown-condition', { set: { '/stances/martial/b': { kind: 'frame', what: 'a', slots: [{ slot: 'tell', ticks: 30 }], asks: ['Q99'] } } }, { rule: 'xref:cells-asks', pointer: '/stances/martial/b/asks/0' }),
    ce('frame-slot-key-required', { set: { '/stances/martial/b': { kind: 'frame', what: 'a', slots: [{ ticks: 30 }] } } }, { rule: 'required', pointer: '/stances/martial/b/slots/0' }),
    ce('frame-slot-unknown-key', { set: { '/stances/martial/b': { kind: 'frame', what: 'a', slots: [{ slot: 'tell', mood: 1 }] } } }, { rule: 'additionalProperties', pointer: '/stances/martial/b/slots/0/mood' }),
    ce('travel-cell-key-required', { set: { '/stances/manoeuvre/x': { kind: 'travel', what: 'a', blows: 'martial.x', kinds: ['zip'], count: 3, quotas: [] } } }, { rule: 'required', pointer: '/stances/manoeuvre/x' }),
    ce('travel-cell-ok', { set: { '/stances/trial': { held: 0, x: { kind: 'travel', what: 'a', blows: 'martial.x', kinds: ['zip'], count: 1, readings: ['speed'], quotas: [{ name: 'zip', min: 1, filter: { kind: ['zip'] } }] } } } }, null),
    ce('travel-cell-blows-shape', { set: { '/stances/manoeuvre/x': { kind: 'travel', what: 'a', blows: 'martial', kinds: ['zip'], count: 1, readings: ['speed'], quotas: [] } } }, { rule: 'pattern', pointer: '/stances/manoeuvre/x/blows' }),
    ce('travel-cell-blows-unknown-cell', { set: { '/stances/manoeuvre/x': { kind: 'travel', what: 'a', blows: 'boxing.x', kinds: ['zip'], count: 1, readings: ['speed'], quotas: [] } } }, { rule: 'xref:cells-quota', pointer: '/stances/manoeuvre/x/blows' }),
    ce('travel-cell-kind-unknown', { set: { '/stances/manoeuvre/x': { kind: 'travel', what: 'a', blows: 'martial.x', kinds: ['teleport'], count: 1, readings: ['speed'], quotas: [] } } }, { rule: 'xref:cells-quota', pointer: '/stances/manoeuvre/x/kinds/0' }),
    ce('table-cell-key-required', { set: { '/stances/energy/x': { kind: 'table', what: 'a', delivery: ['bolt'], count: 3, quotas: [] } } }, { rule: 'required', pointer: '/stances/energy/x' }),
    ce('table-cell-ok', { set: { '/stances/trial': { held: 0, x: { kind: 'table', what: 'a', block: 'shot', delivery: ['bolt', 'volley'], count: 3, quotas: [{ name: 'heavy', min: 1, form: 'heavy' }] } } } }, null),
    ce('table-cell-block-unknown', { set: { '/stances/energy/x': { kind: 'table', what: 'a', block: 'nowhere', delivery: ['bolt'], count: 3, quotas: [] } } }, { rule: 'xref:cells-quota', pointer: '/stances/energy/x/block' }),
    ce('special-cell-key-required', { set: { '/stances/charging/x': { kind: 'special', what: 'a', slot: 'x', count: 3 } } }, { rule: 'required', pointer: '/stances/charging/x' }),
    ce('special-cell-slot-enum', { set: { '/stances/charging/x': { kind: 'special', what: 'a', slot: 'q', count: 3, readings: ['speed'] } } }, { rule: 'enum', pointer: '/stances/charging/x/slot' }),
    ce('special-cell-ok', { set: { '/stances/trial': { held: 0, x: { kind: 'special', what: 'a', slot: 'x', count: 3, readings: ['speed', 'tech'] } } } }, null),
    ce('quota-key-required', { set: { '/stances/martial/x': { kind: 'strikes', what: 'a', filter: { weight: ['light'] }, count: 3, quotas: [{ name: 'toward', filter: { weight: ['light'] } }] } } }, { rule: 'required', pointer: '/stances/martial/x/quotas/0' }),
    ce('quota-min-negative', { set: { '/stances/martial/x': { kind: 'strikes', what: 'a', filter: { weight: ['light'] }, count: 3, quotas: [{ name: 'toward', min: -1, filter: { weight: ['light'] } }] } } }, { rule: 'minimum', pointer: '/stances/martial/x/quotas/0/min' }),
    ce('quota-sends-enum', { set: { '/stances/martial/x': { kind: 'strikes', what: 'a', filter: { weight: ['light'] }, count: 3, quotas: [{ name: 'up', min: 1, sends: 'sideways' }] } } }, { rule: 'enum', pointer: '/stances/martial/x/quotas/0/sends' }),
    ce('quota-name-with-a-space-ok', { set: { '/stances/trial': { held: 0, x: { kind: 'strikes', what: 'a', filter: { weight: ['light'] }, count: 3, quotas: [{ name: 'zip away', min: 1, filter: { weight: ['light'] } }] } } } }, null),
    ce('quota-with-two-rules', { set: { '/stances/martial/x': { kind: 'strikes', what: 'a', filter: { weight: ['light'] }, count: 3, quotas: [{ name: 'a', min: 1, filter: { weight: ['light'] }, form: 'light' }] } } }, { rule: 'xref:cells-quota', pointer: '/stances/martial/x/quotas/0' }),
    ce('quota-with-no-rule', { set: { '/stances/martial/x': { kind: 'strikes', what: 'a', filter: { weight: ['light'] }, count: 3, quotas: [{ name: 'a', min: 1 }] } } }, { rule: 'xref:cells-quota', pointer: '/stances/martial/x/quotas/0' }),
    ce('quota-name-twice', { set: { '/stances/martial/x': { kind: 'strikes', what: 'a', filter: { weight: ['light'] }, count: 3, quotas: [{ name: 'a', min: 1, filter: { weight: ['light'] } }, { name: 'a', min: 1, filter: { weight: ['heavy'] } }] } } }, { rule: 'xref:cells-quota', pointer: '/stances/martial/x/quotas/1/name' }),
    ce('quota-larger-than-cell', { set: { '/stances/martial/x': { kind: 'strikes', what: 'a', filter: { weight: ['light'] }, count: 3, quotas: [{ name: 'a', min: 99, filter: { weight: ['light'] } }] } } }, { rule: 'xref:cells-quota', pointer: '/stances/martial/x/quotas/0/min' }),
    ce('quota-form-unknown', { set: { '/stances/martial/x': { kind: 'strikes', what: 'a', filter: { weight: ['light'] }, count: 3, quotas: [{ name: 'a', min: 1, form: 'dance' }] } } }, { rule: 'xref:cells-quota', pointer: '/stances/martial/x/quotas/0/form' }),
    // ---- cells: the three strengths ----
    { id: 'combat-cells-presses-hold-ok', schema: 'combat-cells.schema.json', mutate: [{ file: C, set: { '/stances/trial': { held: 0, x: SC({ presses: { hold: HOLD({}) } }) } } }], expect: null },
    cc('presses-hold-key-required', (h) => { delete h.from; }, { rule: 'required', pointer: TP + 'presses/hold' }),
    cc('presses-hold-slots-required', (h) => { delete h.slots; }, { rule: 'required', pointer: TP + 'presses/hold' }),
    cc('presses-hold-leans-required', (h) => { delete h.leans; }, { rule: 'required', pointer: TP + 'presses/hold' }),
    cc('presses-hold-slot-class-enum', (h) => { h.slots[1] = 'quick'; }, { rule: 'enum', pointer: TP + 'presses/hold/slots/1' }),
    cc('presses-hold-from-shape', (h) => { h.from = 'martial'; }, { rule: 'pattern', pointer: TP + 'presses/hold/from' }),
    cc('presses-hold-from-is-no-strikes-cell', (h) => { h.from = 'manoeuvre.a'; }, { rule: 'xref:cells-quota', pointer: TP + 'presses/hold/from' }),
    cc('presses-hold-from-is-no-cell', (h) => { h.from = 'martial.q'; }, { rule: 'xref:cells-quota', pointer: TP + 'presses/hold/from' }),
    cc('presses-hold-lean-twice', (h) => { h.leans.push(clone(h.leans[0])); }, { rule: 'xref:cells-quota', pointer: TP + 'presses/hold/leans/2/name' }),
    cc('presses-hold-lean-key-required', (h) => { delete h.leans[0].name; }, { rule: 'required', pointer: TP + 'presses/hold/leans/0' }),
    cc('presses-hold-lean-unknown-key', (h) => { h.leans[0].mood = 1; }, { rule: 'additionalProperties', pointer: TP + 'presses/hold/leans/0/mood' }),
    cc('presses-hold-asks-unknown-condition', (h) => { h.asks = ['Q99']; }, { rule: 'xref:cells-asks', pointer: TP + 'presses/hold/asks/0' }),
    { id: 'combat-cells-stand-in-ok', schema: 'combat-cells.schema.json', mutate: [{ file: C, set: { '/stances/trial': { held: 0, b: SC({ standIn: SI({}) }) } } }], expect: null },
    si('stand-in-key-required', (s) => { delete s.only; }, { rule: 'required', pointer: TB + 'standIn' }),
    si('stand-in-unknown-key', (s) => { s.mood = 1; }, { rule: 'additionalProperties', pointer: TB + 'standIn/mood' }),
    si('stand-in-temporary-type', (s) => { s.temporary = 'yes'; }, { rule: 'type', pointer: TB + 'standIn/temporary' }),
    si('stand-in-count-zero', (s) => { s.count = 0; }, { rule: 'minimum', pointer: TB + 'standIn/count' }),
    si('stand-in-kind-const', (s) => { s.kind = 'string'; }, { rule: 'const', pointer: TB + 'standIn/kind' }),
    si('stand-in-without-fighter-unknown', (s) => { s.without = { nobody: [standFrom] }; }, { rule: 'xref:cells-quota', pointer: TB + 'standIn/without/nobody' }),
    si('stand-in-without-strike-unknown', (s) => { s.without = { [fid]: ['strike.nowhere'] }; }, { rule: 'xref:cells-quota', pointer: TB + 'standIn/without/' + fid + '/0' }),
    si('stand-in-without-strike-shape', (s) => { s.without = { [fid]: ['jab'] }; }, { rule: 'pattern', pointer: TB + 'standIn/without/' + fid + '/0' }),
    si('stand-in-without-empty', (s) => { s.without = { [fid]: [] }; }, { rule: 'minItems', pointer: TB + 'standIn/without/' + fid }),
    si('stand-in-asks-unknown-condition', (s) => { s.asks = ['Q99']; }, { rule: 'xref:cells-asks', pointer: TB + 'standIn/asks/0' }),
    cl('spread-look-ok', { spread: { look: 0.15 } }, null),
    cl('spread-look-above-one', { spread: { look: 1.5 } }, { rule: 'maximum', pointer: TP + 'spread/look' }),
    cl('spread-look-zero', { spread: { look: 0 } }, { rule: 'exclusiveMinimum', pointer: TP + 'spread/look' }),
    cl('not-levels-ok', { notLevels: ['stand_in'] }, null),
    cl('not-levels-empty', { notLevels: [] }, { rule: 'minItems', pointer: TP + 'notLevels' }),
    cl('weights-ok', { weights: ['light', 'medium'] }, null),
    cl('weights-type', { weights: 'light' }, { rule: 'type', pointer: TP + 'weights' }),
    { id: 'combat-cells-frame-slot-to-ok', schema: 'combat-cells.schema.json', mutate: [{ file: C, set: { '/stances/trial': { held: 0, b: { kind: 'frame', what: 'a', slots: [{ slot: 'tell', to: 'the first flash' }, { slot: 'his art', from: 'a string the player drives' }], readings: { 'held on, in acts 3 and 4': 'his ultimate' } } } } }], expect: null },
    { id: 'combat-cells-frame-reading-key-shape', schema: 'combat-cells.schema.json', mutate: [{ file: C, set: { '/stances/trial': { held: 0, b: { kind: 'frame', what: 'a', slots: [{ slot: 'tell' }], readings: { 'Held': 'x' } } } } }], expect: { rule: 'anyOf', pointer: '/stances/trial/b/readings' } },
    // ---- moveset ----
    // The cells that need a moveset to agree with cells.json, parts.json and the lock are tried in a cell of their own: a stance `trial` in
    // cells.json, a cell `trial.x` in the moveset and (for a strikes cell) its rows in the lock, all set by the case. The moves are copies of a
    // live move of the kind, so what the grammar derives stays true while the data is regenerated; the case sets everything else.
    ms('live-valid', { set: { '/schema': 'combat.moveset/1' } }, null),
    ms('key-required', { del: ['/generator'] }, { rule: 'required', pointer: '' }),
    ms('schema-version', { set: { '/schema': 'combat.moveset/2' } }, { rule: 'const', pointer: '/schema' }),
    ms('unknown-key', { set: { '/extra': 1 } }, { rule: 'additionalProperties', pointer: '/extra' }),
    ms('underscore-key-ok', { set: { '/_why': 'comment' } }, null),
    ms('fighter-not-in-identity', { set: { '/fighter': 'nobody' } }, { rule: 'xref:moveset-cell', pointer: '/fighter' }),
    ms('generator-key-required', { del: ['/generator/seed'] }, { rule: 'required', pointer: '/generator' }),
    ms('generator-inputs-shape', { set: { '/generator/inputs': 'not a hash' } }, { rule: 'pattern', pointer: '/generator/inputs' }),
    ms('generator-seed-differs-from-cells', { set: { '/generator/seed': 1 } }, { rule: 'xref:moveset-cell', pointer: '/generator/seed' }),
    ms('cell-id-shape', { set: { '/cells/martial': { kind: 'frame', slots: [{ slot: 'tell' }] } } }, { rule: 'propertyNames', pointer: '/cells/martial' }),
    ms('cell-not-in-cells', { set: { '/cells/boxing.x': { kind: 'frame', slots: [{ slot: 'tell' }] } } }, { rule: 'xref:moveset-cell', pointer: '/cells/boxing.x' }),
    ms('cell-kind-enum', { set: { '/cells/martial.x/kind': 'dance' } }, { rule: 'enum', pointer: '/cells/martial.x/kind' }),
    ms('cell-kind-differs', { set: { '/cells/martial.b': { kind: 'context', pressed: ['throw'], held: ['grab'] } } }, { rule: 'xref:moveset-cell', pointer: '/cells/martial.b/kind' }),
    ms('context-cell-key-required', { set: { '/cells/martial.a': { kind: 'context', pressed: ['throw'] } } }, { rule: 'required', pointer: '/cells/martial.a' }),
    ms('context-cell-asks-unknown-condition', { set: { '/cells/martial.a': { kind: 'context', pressed: ['throw'], held: ['grab'], asks: ['Q99'] } } }, { rule: 'xref:moveset-keys', pointer: '/cells/martial.a/asks/0' }),
    ms('frame-cell-key-required', { set: { '/cells/martial.b': { kind: 'frame' } } }, { rule: 'required', pointer: '/cells/martial.b' }),
    mt('context-cell-ok', 'context', {}, null),
    mt('frame-cell-readings-ok', 'frame', { cell: (c) => { c.readings = { speed: 'the quick form' }; } }, null),
    // strikes cell
    mt('strikes-cell-ok', 'strikes', {}, null),
    mt('strikes-cell-key-required', 'strikes', { cell: (c) => { delete c.valid; } }, { rule: 'required', pointer: TC }),
    mt('strikes-cell-refused-required', 'strikes', { cell: (c) => { delete c.refused; } }, { rule: 'required', pointer: TC }),
    mt('strikes-cell-quota-negative', 'strikes', { cell: (c) => { c.quotas = { toward: -1 }; } }, { rule: 'minimum', pointer: TC + '/quotas/toward' }),
    mt('strikes-cell-moves-empty', 'strikes', { cell: (c) => { c.moves = []; } }, { rule: 'minItems', pointer: TC + '/moves' }),
    mt('strikes-cell-refused-type', 'strikes', { cell: (c) => { c.refused = 'many'; } }, { rule: 'type', pointer: TC + '/refused' }),
    mt('cell-short-of-its-count', 'strikes', { def: (d) => { d.count = 3; } }, { rule: 'xref:moveset-cell', pointer: TC + '/moves' }),
    mt('cell-quota-miscounted', 'strikes', { def: (d) => { d.quotas = [{ name: 'a', min: 0, filter: { weight: [d.filter.weight[0]] } }]; }, cell: (c) => { c.quotas = { a: 99 }; } }, { rule: 'xref:moveset-cell', pointer: TC + '/quotas/a' }),
    mt('cell-quota-recount-ok', 'strikes', { def: (d) => { d.quotas = [{ name: 'a', min: 1, filter: { weight: [d.filter.weight[0]] } }]; }, cell: (c) => { c.quotas = { a: 1 }; } }, null),
    // strike moves
    sk('move-key-required', (m) => { delete m.review; }, { rule: 'required', pointer: P0 }),
    sk('move-unknown-key', (m) => { m.mood = 1; }, { rule: 'additionalProperties', pointer: P0 + '/mood' }),
    sk('move-id-shape', (m) => { m.id = 'move 1'; }, { rule: 'pattern', pointer: P0 + '/id' }),
    sk('move-id-out-of-order', (m) => { m.id = `mv.${fid}.trial.x.07`; }, { rule: 'xref:moveset-cell', pointer: P0 + '/id' }),
    sk('move-limb-enum', (m) => { m.limb = 'tail'; }, { rule: 'enum', pointer: P0 + '/limb' }),
    sk('move-weight-enum', (m) => { m.weight = 'average'; }, { rule: 'enum', pointer: P0 + '/weight' }),
    sk('move-beat-range', (m) => { m.beat = 30; }, { rule: 'maximum', pointer: P0 + '/beat' }),
    sk('move-status-enum', (m) => { m.status = 'done'; }, { rule: 'enum', pointer: P0 + '/status' }),
    sk('move-review-enum', (m) => { m.review = 'maybe'; }, { rule: 'enum', pointer: P0 + '/review' }),
    sk('move-review-locked-ok', (m) => { m.review = 'locked'; }, null),
    sk('move-ground-enum', (m) => { m.ground = 'sometimes'; }, { rule: 'enum', pointer: P0 + '/ground' }),
    sk('move-forms-duplicate', (m) => { m.forms = ['light', 'light']; }, { rule: 'uniqueItems', pointer: P0 + '/forms/1' }),
    sk('move-legal-duplicate', (m) => { m.legal = ['no_leap', 'no_leap']; }, { rule: 'uniqueItems', pointer: P0 + '/legal/1' }),
    sk('move-keys-level-enum', (m) => { m.keys = { level: 'remix' }; }, { rule: 'enum', pointer: P0 + '/keys/level' }),
    sk('move-keys-level-required', (m) => { m.keys = { from: 'strike.jab' }; }, { rule: 'required', pointer: P0 + '/keys' }),
    sk('move-keys-edge-levels-ok', (m) => { m.keys.level = 'hand_state_re_aim_edge'; m.keys.aim = 'edge'; m.status = 'derived'; }, null),
    sk('move-keys-re-aim-edge-ok', (m) => { m.keys.level = 're_aim_edge'; m.status = 'derived'; }, null),
    sk('move-keys-from-shape', (m) => { m.keys.from = 'jab'; }, { rule: 'pattern', pointer: P0 + '/keys/from' }),
    sk('move-keys-wave-shape', (m) => { m.keys.wave = 'Wave 1'; }, { rule: 'pattern', pointer: P0 + '/keys/wave' }),
    sk('move-keys-layer-ok', (m) => { m.keys.layer = 'guard'; }, null),
    sk('move-keys-unknown-key', (m) => { m.keys.mood = 1; }, { rule: 'additionalProperties', pointer: P0 + '/keys/mood' }),
    sk('move-as-ok', (m) => { m.as = 'push'; }, null),
    sk('move-shape-invalid', (m) => { m.tip = 'claw'; }, { rule: 'xref:moveset-shape', pointer: P0 }),
    mt('move-shape-twice', 'strikes', { moves: (ms2) => [ms2[0], Object.assign(clone(ms2[0]), { id: `mv.${fid}.trial.x.02` })] }, { rule: 'xref:moveset-shape', pointer: TC + '/moves/1' }),
    sk('move-sends-not-derived', (m) => { m.sends = m.sends === 'down' ? 'up' : 'down'; }, { rule: 'xref:moveset-derived', pointer: P0 + '/sends' }),
    sk('move-beat-not-derived', (m) => { m.beat = m.beat === 27 ? 26 : 27; }, { rule: 'xref:moveset-derived', pointer: P0 + '/beat' }),
    sk('move-step-not-derived', (m) => { m.step = ['out', 'out', 'out']; }, { rule: 'xref:moveset-derived', pointer: P0 + '/step' }),
    sk('move-links-not-derived', (m) => { m.links = m.links.length === 1 ? ['line', 'rise'] : [m.links[0]]; }, { rule: 'xref:moveset-derived', pointer: P0 + '/links' }),
    sk('move-forms-not-derived', (m) => { m.forms = ['nonsense']; }, { rule: 'xref:moveset-derived', pointer: P0 + '/forms' }),
    sk('move-arms-not-derived', (m) => { m.arms = m.arms === 0 ? 2 : 0; }, { rule: 'xref:moveset-derived', pointer: P0 + '/arms' }),
    sk('move-status-differs-from-level', (m) => { m.keys = { level: 'new' }; m.status = 'posed'; }, { rule: 'xref:moveset-keys', pointer: P0 + '/status' }),
    sk('move-new-with-a-key-set', (m) => { m.keys = { level: 'new', set: m.keys.set }; m.status = 'waiting'; }, { rule: 'xref:moveset-keys', pointer: P0 + '/keys' }),
    sk('move-posed-without-a-key-set', (m) => { m.keys = { level: 'posed' }; m.status = 'posed'; }, { rule: 'xref:moveset-keys', pointer: P0 + '/keys' }),
    sk('move-key-set-in-no-manifest', (m) => { m.keys.set = 'w9.nowhere'; }, { rule: 'xref:moveset-keys', pointer: P0 + '/keys/set' }),
    sk('move-arms-negative', (m) => { m.arms = -1; }, { rule: 'minimum', pointer: P0 + '/arms' }),
    sk('move-flags-duplicate', (m) => { m.flags = ['leap', 'leap']; }, { rule: 'uniqueItems', pointer: P0 + '/flags/1' }),
    sk('move-asks-shape', (m) => { m.asks = ['legal-1']; }, { rule: 'pattern', pointer: P0 + '/asks/0' }),
    sk('move-asks-unknown-condition', (m) => { m.asks = ['Q99']; }, { rule: 'xref:moveset-keys', pointer: P0 + '/asks/0' }),
    mt('move-asks-ok', 'strikes', { move: (m) => { m.asks = ['Z9']; }, extra: ownCond }, null),
    // travel
    mt('travel-cell-ok', 'travel', {}, null),
    mt('travel-cell-key-required', 'travel', { cell: (c) => { delete c.refused; } }, { rule: 'required', pointer: TC }),
    mt('travel-cell-quota-name-with-a-space-ok', 'travel', { cell: (c) => { c.quotas = { 'zip away': 1 }; } }, null),
    mt('travel-move-key-required', 'travel', { move: (m) => { delete m.band; } }, { rule: 'required', pointer: P0 }),
    mt('travel-move-unknown-key', 'travel', { move: (m) => { m.mood = 1; } }, { rule: 'additionalProperties', pointer: P0 + '/mood' }),
    mt('travel-move-entry-id-shape', 'travel', { move: (m) => { m.entry.id = 'dash'; } }, { rule: 'pattern', pointer: P0 + '/entry/id' }),
    mt('travel-move-no-way-out-ok', 'travel', { move: (m) => { m.exit = null; }, extra: (m) => [{ file: P, set: { [`/travel/kinds/${m.kind}/moves/-`]: { direction: m.direction, entries: [m.entry.id.replace(/^entry\./, '')], exit: null } } }] }, null),
    mt('travel-move-kind-not-in-cell', 'travel', { move: (m) => { m.kind = 'teleport'; } }, { rule: 'xref:moveset-travel', pointer: P0 + '/kind' }),
    mt('travel-move-band-differs-from-kind', 'travel', { move: (m) => { m.band = m.band === 'beyond' ? 'close' : 'beyond'; } }, { rule: 'xref:moveset-travel', pointer: P0 + '/band' }),
    mt('travel-move-not-in-parts', 'travel', { extra: (m) => [{ file: P, set: { ['/travel/kinds/' + m.kind + '/moves']: [{ direction: 'nowhere', entries: ['dash'], exit: null }] } }] }, { rule: 'xref:moveset-travel', pointer: P0 }),
    mt('travel-move-entry-set-not-in-entry-maps', 'travel', { move: (m) => { m.entry.set = 'w9.nowhere'; } }, { rule: 'xref:moveset-travel', pointer: P0 + '/entry/set' }),
    mt('travel-move-blow-set-shape', 'travel', { move: (m) => { m.blow.set = 'W1 Jab'; } }, { rule: 'pattern', pointer: P0 + '/blow/set' }),
    mt('travel-move-blow-is-no-move', 'travel', { move: (m) => { m.blow.move = `mv.${fid}.martial.x.99`; } }, { rule: 'xref:moveset-travel', pointer: P0 + '/blow/move' }),
    mt('travel-move-far-side-exit-breaks-the-legal-row', 'travel', { move: (m) => { m.direction = 'far_side'; m.exit = { id: 'entry.fade', set: m.entry.set }; }, extra: (m) => [{ file: P, set: { '/legal/motion/-': { id: 'm98', kind: 'travel', if: { kind: [m.kind], direction: ['far_side'] }, then: { exit: ['pivot'] }, rule: 'a', why: 'b' }, ['/travel/kinds/' + m.kind + '/moves/-']: { direction: 'far_side', entries: [m.entry.id.replace(/^entry\./, '')], exit: m.exit.id.replace(/^entry\./, '') } } }] }, { rule: 'xref:moveset-travel', pointer: P0 }),
    mt('travel-refused-key-required', 'travel', { cell: (c) => { c.refused = [{ move: { kind: 'zip', direction: 'far_side', exit: 'fade' } }]; } }, { rule: 'required', pointer: TC + '/refused/0' }),
    mt('travel-refused-ok', 'travel', { cell: (c) => { c.refused = [{ move: { kind: 'zip', direction: 'far_side', exit: 'fade' }, rows: ['m04'] }]; } }, null),
    mt('travel-refused-move-unknown-key', 'travel', { cell: (c) => { c.refused = [{ move: { kind: 'zip', direction: 'far_side', exit: 'fade', mood: 1 }, rows: ['m04'] }]; } }, { rule: 'additionalProperties', pointer: TC + '/refused/0/move/mood' }),
    // table
    mt('table-cell-ok', 'table', {}, null),
    mt('table-cell-key-required', 'table', { cell: (c) => { delete c.refused; } }, { rule: 'required', pointer: TC }),
    mt('table-move-key-required', 'table', { move: (m) => { delete m.body; } }, { rule: 'required', pointer: P0 }),
    mt('table-move-unknown-key', 'table', { move: (m) => { m.mood = 1; } }, { rule: 'additionalProperties', pointer: P0 + '/mood' }),
    mt('table-move-keys-unknown-key', 'table', { move: (m) => { m.keys.mood = 1; } }, { rule: 'additionalProperties', pointer: P0 + '/keys/mood' }),
    mt('table-move-keys-set-null-ok', 'table', { move: (m) => { m.keys.set = null; } }, null),
    mt('table-move-hand-not-in-shot', 'table', { move: (m) => { m.hand = 'claw_fist'; } }, { rule: 'xref:moveset-table', pointer: P0 + '/hand' }),
    mt('table-move-release-not-in-shot', 'table', { move: (m) => { m.release = 'hurl'; } }, { rule: 'xref:moveset-table', pointer: P0 + '/release' }),
    mt('table-move-body-not-in-shot', 'table', { move: (m) => { m.body = 'hovering'; } }, { rule: 'xref:moveset-table', pointer: P0 + '/body' }),
    mt('table-move-forms-not-derived', 'table', { move: (m) => { m.forms = ['nonsense']; } }, { rule: 'xref:moveset-derived', pointer: P0 + '/forms' }),
    mt('table-refused-key-required', 'table', { cell: (c) => { c.refused = [{ move: { delivery: 'volley', release: 'thrust' }, rows: ['e05'] }]; } }, { rule: 'required', pointer: TC + '/refused/0' }),
    mt('table-refused-ok', 'table', { cell: (c) => { c.refused = [{ move: { delivery: 'volley', release: 'thrust' }, rows: ['e05'], candidates: 2 }]; } }, null),
    // special
    mt('special-cell-ok', 'special', {}, null),
    mt('special-cell-key-required', 'special', { cell: (c) => { delete c.state; } }, { rule: 'required', pointer: TC }),
    mt('special-move-key-required', 'special', { move: (m) => { delete m.review; } }, { rule: 'required', pointer: P0 }),
    mt('special-move-look-shape', 'special', { move: (m) => { m.look = { Level: 'up' }; } }, { rule: 'propertyNames', pointer: P0 + '/look/Level' }),
    mt('special-move-look-part-unknown', 'special', { move: (m) => { m.look = { colour: 'red' }; } }, { rule: 'xref:moveset-special', pointer: P0 + '/look/colour' }),
    mt('special-cell-id-shape', 'special', { cell: (c) => { c.special = 'cut'; } }, { rule: 'pattern', pointer: TC + '/special' }),
    // the three strengths: a medium, a heavy, a string (the burst) and the stand-ins
    mt('medium-ok', 'medium', {}, null),
    mt('medium-wind-not-derived', 'medium', { move: (m) => { m.wind = m.wind === 'w5' ? 'w6' : 'w5'; } }, { rule: 'xref:moveset-derived', pointer: P0 + '/wind' }),
    mt('medium-wind-shape', 'medium', { move: (m) => { m.wind = 'W 8'; } }, { rule: 'pattern', pointer: P0 + '/wind' }),
    mt('medium-weight-in-a-light-cell', 'medium', { def: (d) => { d.filter.weight = ['light']; } }, { rule: 'xref:moveset-cell', pointer: P0 }),
    mt('heavy-ok', 'heavy', {}, null),
    mt('heavy-drive-not-derived', 'heavy', { move: (m) => { m.drive = 'a_wrong_drive'; } }, { rule: 'xref:moveset-derived', pointer: P0 + '/drive' }),
    mt('heavy-drive-shape', 'heavy', { move: (m) => { m.drive = 'Full Turn'; } }, { rule: 'pattern', pointer: P0 + '/drive' }),
    mt('heavy-name-empty', 'heavy', { move: (m) => { m.name = ''; } }, { rule: 'minLength', pointer: P0 + '/name' }),
    mt('heavy-tip-cannot-travel-as-a-heavy', 'heavy', { move: (m) => { m.tip = 'ball'; m.limb = 'hand'; } }, { rule: 'xref:moveset-shape', pointer: P0 }),
    mt('heavy-new-with-a-key-set', 'heavy', { move: (m) => { m.keys = { level: 'new', set: 'w1.jab' }; } }, { rule: 'xref:moveset-keys', pointer: P0 + '/keys' }),
    mt('string-ok', 'string', {}, null),
    mt('string-key-required', 'string', { cell: (c) => { delete c.from; } }, { rule: 'required', pointer: '/cells/trial.x.hold' }),
    mt('string-moves-key-required', 'string', { move: (m) => { delete m.lean; } }, { rule: 'required', pointer: '/cells/trial.x.hold/moves/0' }),
    mt('string-move-unknown-key', 'string', { move: (m) => { m.mood = 1; } }, { rule: 'additionalProperties', pointer: '/cells/trial.x.hold/moves/0/mood' }),
    mt('string-from-is-no-cell', 'string', { cell: (c) => { c.from = 'martial.q'; } }, { rule: 'xref:moveset-cell', pointer: '/cells/trial.x.hold/from' }),
    mt('string-blow-is-no-move', 'string', { move: (m) => { m.blows[1] = `mv.${fid}.martial.x.99`; } }, { rule: 'xref:moveset-cell', pointer: '/cells/trial.x.hold/moves/0/blows/1' }),
    mt('string-blow-id-shape', 'string', { move: (m) => { m.blows[0] = 'blow one'; } }, { rule: 'pattern', pointer: '/cells/trial.x.hold/moves/0/blows/0' }),
    mt('string-blow-twice', 'string', { move: (m) => { m.blows[1] = m.blows[0]; } }, { rule: 'xref:moveset-cell', pointer: '/cells/trial.x.hold/moves/0/blows' }),
    mt('string-blows-fewer-than-slots', 'string', { move: (m) => { m.blows.pop(); } }, { rule: 'xref:moveset-cell', pointer: '/cells/trial.x.hold/moves/0/blows' }),
    mt('string-slots-differ-from-cells', 'string', { move: (m) => { m.slots = m.slots.slice().reverse(); } }, { rule: 'xref:moveset-cell', pointer: '/cells/trial.x.hold/moves/0/slots' }),
    mt('string-slot-class-enum', 'string', { move: (m) => { m.slots[1] = 'quick'; } }, { rule: 'enum', pointer: '/cells/trial.x.hold/moves/0/slots/1' }),
    mt('string-lean-unknown', 'string', { move: (m) => { m.lean = 'sideways'; } }, { rule: 'xref:moveset-cell', pointer: '/cells/trial.x.hold/moves/0/lean' }),
    mt('stand-in-ok', 'standin', {}, null),
    mt('stand-in-review-enum', 'standin', { move: (m) => { m.review = 'standin'; } }, { rule: 'enum', pointer: '/cells/trial.b.standin/moves/0/review' }),
    mt('stand-in-level-enum', 'standin', { move: (m) => { m.keys.level = 'stand-in'; } }, { rule: 'enum', pointer: '/cells/trial.b.standin/moves/0/keys/level' }),
    mt('stand-in-more-than-the-cell-allows', 'standin', { def: (d) => { d.count = 1; }, moves: (ms) => [ms[0], Object.assign(clone(ms[0]), { id: `mv.${fid}.trial.b.standin.02` })] }, { rule: 'xref:moveset-cell', pointer: '/cells/trial.b.standin/moves' }),
    mt('stand-in-not-marked-temporary', 'standin', { cell: (c) => { c.temporary = false; } }, { rule: 'xref:moveset-cell', pointer: '/cells/trial.b.standin/temporary' }),
    mt('stand-in-temporary-type', 'standin', { cell: (c) => { c.temporary = 'yes'; } }, { rule: 'type', pointer: '/cells/trial.b.standin/temporary' }),
    mt('stand-in-built-on-a-strike-the-cell-leaves-out', 'standin', { def: (d) => { d.without = { [fid]: [tplMove.standin.keys.from] }; } }, { rule: 'xref:moveset-cell', pointer: '/cells/trial.b.standin/moves/0/keys/from' }),
    // ---- lock ----
    lk('live-valid', { set: { '/schema': 'combat.moveset.lock/1' } }, null),
    lk('key-required', { del: ['/fighters'] }, { rule: 'required', pointer: '' }),
    lk('schema-version', { set: { '/schema': 'combat.moveset.lock/2' } }, { rule: 'const', pointer: '/schema' }),
    lk('unknown-key', { set: { '/extra': 1 } }, { rule: 'additionalProperties', pointer: '/extra' }),
    lk('underscore-key-ok', { set: { '/_why': 'comment' } }, null),
    lk('cell-id-shape', { set: { ['/fighters/' + fid]: { martial: [] } } }, { rule: 'propertyNames', pointer: '/fighters/' + fid + '/martial' }),
    lk('row-too-short', { set: { ['/fighters/' + fid]: { 'martial.x': [[`mv.${fid}.martial.x.01`, ['hand', 'blade', 'line', 'head', 'light']]] } } }, { rule: 'minItems', pointer: '/fighters/' + fid + '/martial.x/0' }),
    lk('row-id-shape', { set: { ['/fighters/' + fid]: { 'martial.x': [['move 1', ['hand', 'blade', 'line', 'head', 'light'], null]] } } }, { rule: 'pattern', pointer: '/fighters/' + fid + '/martial.x/0/0' }),
    lk('row-shape-limb-enum', { set: { ['/fighters/' + fid]: { 'martial.x': [[`mv.${fid}.martial.x.01`, ['tail', 'blade', 'line', 'head', 'light'], null]] } } }, { rule: 'enum', pointer: '/fighters/' + fid + '/martial.x/0/1/0' }),
    lk('row-shape-short', { set: { ['/fighters/' + fid]: { 'martial.x': [[`mv.${fid}.martial.x.01`, ['hand', 'blade', 'line', 'head'], null]] } } }, { rule: 'minItems', pointer: '/fighters/' + fid + '/martial.x/0/1' }),
    { id: 'combat-moveset-lock-row-key-set-null-ok', schema: 'combat-moveset-lock.schema.json', mutate: trialMut('strikes', { move: (m) => { m.keys = { level: 'new' }; m.status = 'waiting'; } }), expect: null },
    lk('fighter-without-a-moveset', { set: { '/fighters/nobody': { 'martial.x': [] } } }, { rule: 'xref:lock-ref', pointer: '/fighters/nobody' }),
    lk('locked-move-is-no-move', { set: { ['/fighters/' + fid]: { 'martial.x': [[`mv.${fid}.martial.x.99`, ['hand', 'blade', 'line', 'head', 'light'], null]] } } }, { rule: 'xref:lock-ref', pointer: '/fighters/' + fid + '/martial.x/0' }),
    lk('third-part-cell-id-ok', { set: { ['/fighters/' + fid + '/martial.b.standin']: [] } }, null),
    lk('third-part-cell-id-shape', { set: { ['/fighters/' + fid + '/martial.b.Stand In']: [] } }, { rule: 'propertyNames', pointer: '/fighters/' + fid + '/martial.b.Stand In' }),
    lk('weight-enum', { set: { ['/fighters/' + fid]: { 'martial.y': [[`mv.${fid}.martial.y.01`, ['hand', 'palm', 'rise', 'jaw', 'average'], null]] } } }, { rule: 'enum', pointer: '/fighters/' + fid + '/martial.y/0/1/4' }),
    lk('locked-cell-is-no-strike-cell', { set: { ['/fighters/' + fid]: { 'boxing.x': [] } } }, { rule: 'xref:lock-ref', pointer: '/fighters/' + fid + '/boxing.x' }),
  ];
  let n = 0;
  for (const k of add) {
    const i = c.cases.findIndex((y) => y.id === k.id);
    if (i < 0) { c.cases.push(k); n++; } else if (JSON.stringify(c.cases[i]) !== JSON.stringify(k)) { c.cases[i] = k; n++; }
  }
  // cases of a first version of this script (generator version 2) that no longer apply
  const gone = c.cases.filter((y) => /^combat-(parts|identity|cells|moveset)-/.test(y.id) && !add.some((k) => k.id === y.id));
  if (gone.length) c.cases = c.cases.filter((y) => !gone.includes(y));
  wj(cf, c);
  console.log(`movegen schemas applied (${n} new or changed cases, ${gone.length} dropped)`);
}

// =============================== docs ===============================
{
  const f = 'docs/tools/README.md';
  let t = fs.readFileSync(f, 'utf8');
  const lines = t.split('\n');
  const rows = [
    '| `parts-grammar`, `parts-shot`, `parts-travel`, `parts-legal` | data/combat/parts.json: every path a tip travels has targets, a send, links, a step and a beat; forms, conditions and rule ids are consistent (a condition names rows of Legal\'s groups); shot rules name releases and bodies of shot, and a hand property a Legal row needs is one the hands have; every travel direction has arrive paths and every entry and exit is an entrymap row; no hold point is one of g01\'s never |',
    '| `identity-ref` | data/combat/identity.json: the fighters are keys of recipes.json pools; every wave has a manifest and every entry wave an entry map; every tip key is a tip of parts.json; entry weights are entrymap rows; energy hands and releases are those of parts.json shot and posed hands and sets are poses or sequences |',
    '| `cells-quota`, `cells-asks` | data/combat/cells.json: a quota has exactly one of filter, any, form or sends; names are unique in a cell; a quota fits in its cell; its form and sends exist in parts.json; a travel cell\'s blows is a cell and its kinds are travel kinds; a table cell\'s block is a block of parts.json; asks are conditions of parts.json |',
    '| `moveset-cell`, `moveset-shape`, `moveset-derived`, `moveset-keys`, `moveset-travel`, `moveset-table`, `moveset-special` | data/combat/movesets/<fighter>.json: the fighter and seed match identity.json and cells.json; each cell is in cells.json with its count, quotas (recounted) and kind; move ids run in order; a strike move is a valid shape that matches no never or banned row and no cell repeats one; sends, links, step, beat, arms and forms are what parts.json derives; status follows keys.level; keys.set and keys.from are a manifest row of the fighter; a travel move is one of parts.json travel.kinds with its band and arrive path, entries of the fighter\'s entry maps and a blow that is a move of the blows cell; a table move breaks no rule of its block; a special\'s look is made of the special\'s parts |',
    '| `lock-ref` | data/combat/movesets/lock.json: every locked id is a move of its fighter\'s cell with the same shape and key set, and every strike move is in the lock |',
  ];
  const anchorIdx = lines.findIndex((l) => l.startsWith('| `parts-grammar`'));
  if (anchorIdx >= 0 && !t.includes('`lock-ref`')) {
    // replace the rows of the first version of this script
    let end = anchorIdx;
    while (end < lines.length && /^\| `(parts-grammar|identity-ref|cells-quota|moveset-cell)/.test(lines[end])) end++;
    lines.splice(anchorIdx, end - anchorIdx, ...rows);
    fs.writeFileSync(f, lines.join('\n'));
  } else if (anchorIdx < 0) {
    const i = lines.findIndex((l) => l.includes('`recipes-brawl`') || l.includes('`recipes-heavies`'));
    if (i < 0) throw new Error('movegen README anchor');
    lines.splice(i + 1, 0, ...rows);
    fs.writeFileSync(f, lines.join('\n'));
  }
}
