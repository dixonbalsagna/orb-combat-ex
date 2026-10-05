// Schemas and cross-checks for Combat's generated movesets (docs/combat/pending/movegen/README.md section 4; docs/combat/moveset-generator.md).
// NOT run by CI, the validator or the sim. Run once from the repo root, in the commit where Combat lands the files
//     data/combat/parts.json, identity.json, cells.json and data/combat/movesets/<fighter>.json
// (the drafts in docs/combat/pending/movegen/ with `_target` dropped):
//     node docs/tools/pending/apply-movegen.cjs
// It does NOT copy the data and stops with a message if the files are not there. It adds combat-parts, combat-identity, combat-cells and
// combat-moveset schemas (closed; underscore keys are notes), the four map entries, tools/lib/xref-movegen.js (copied from
// docs/tools/pending/xref-movegen.js and called from xref.js) with the rules parts-grammar, parts-strike, identity-ref, cells-quota,
// moveset-cell, moveset-shape, moveset-derived and moveset-keys, and the cases. Re-runnable (a second run changes nothing).
// The generator's own `--check` (the committed movesets are what the inputs give; the hash in generator.inputs) is not a validator rule:
// see docs/tools/movegen-ci.md.
const fs = require('fs');
const rj = (f) => JSON.parse(fs.readFileSync(f, 'utf8'));
const wj = (f, o) => fs.writeFileSync(f, JSON.stringify(o, null, 2) + '\n');
const closed = { additionalProperties: false, patternProperties: { '^_': true } };
const obj = (props, opts = {}) => Object.assign({ type: 'object', required: opts.required === undefined ? Object.keys(props) : opts.required, properties: props }, opts.description ? { description: opts.description } : {}, closed);

const NEEDED = ['data/combat/parts.json', 'data/combat/identity.json', 'data/combat/cells.json'];
for (const f of NEEDED) if (!fs.existsSync(f)) { console.error(`apply-movegen: ${f} is not there. Run this in the commit that lands the movegen data files.`); process.exit(1); }
const movesetFiles = fs.existsSync('data/combat/movesets') ? fs.readdirSync('data/combat/movesets').filter((n) => n.endsWith('.json')) : [];
if (!movesetFiles.length) { console.error('apply-movegen: data/combat/movesets/ has no files. Run this in the commit that lands them.'); process.exit(1); }

const LIMBS = ['hand', 'foot', 'elbow', 'knee', 'shoulder', 'head'];
const PATHS = ['line', 'arc_in', 'arc_out', 'rise', 'drop', 'spin'];
const SENDS = ['across', 'up', 'down', 'turned'];
const STEPS = ['in', 'hold', 'around', 'out'];
const WEIGHTS = ['light', 'heavy'];
const GROUND = ['ok', 'plant', 'only', 'no'];
const LEVELS = ['posed', 'hand_state', 're_aim', 'hand_state_re_aim', 'new'];
const name = { type: 'string', pattern: '^[a-z][a-z0-9_]*$' };
const strikeId = { type: 'string', pattern: '^strike\\.[a-z0-9_]+$' };
const strArr = (d) => ({ type: 'array', minItems: 1, uniqueItems: true, items: { type: 'string', minLength: 1 }, description: d });
const why = { type: 'string', minLength: 1 };

// a filter: part values that must all hold; `any` is a list of filters of which one must
const filter = {
  type: 'object',
  properties: {
    limb: strArr('Allowed limbs.'),
    tip: strArr('Allowed tips.'),
    path: strArr('Allowed paths.'),
    target: strArr('Allowed targets.'),
    weight: strArr('Allowed weights.'),
    form: strArr('Allowed forms (any of a move\'s forms).'),
    flags: strArr('Pose flags (any a move is known to have).'),
    event: strArr('Run-time events.'),
    arms: { type: 'array', minItems: 1, uniqueItems: true, items: { type: 'integer', minimum: 0 }, description: 'Allowed numbers of arms.' },
    any: { type: 'array', minItems: 1, items: { $ref: '#/$defs/filter' }, description: 'A list of filters of which one must hold.' },
  },
  description: 'Part values that must all hold; or `any`: a list of filters of which one must.',
  additionalProperties: false,
  patternProperties: { '^_': true },
};
const withDefs = (s) => Object.assign(s, { $defs: { filter } });
const filterRef = { $ref: '#/$defs/filter' };
const clone = (o) => JSON.parse(JSON.stringify(o));

// =============================== parts ===============================
const tableOf = (inner, d) => ({ type: 'object', minProperties: 1, propertyNames: { pattern: '^(_.*|[a-z][a-z0-9_]*)$' }, additionalProperties: inner, patternProperties: { '^_': true }, description: d });
const byPath = (inner, d) => tableOf(inner, d);
const partsSchema = withDefs({
  $schema: 'https://json-schema.org/draft/2020-12/schema',
  $id: 'meridian/combat-parts',
  title: 'combat.parts/1',
  description: 'data/combat/parts.json: the strike grammar the moveset generator assembles moves from (docs/combat/moveset-generator.md section 1): a move is a limb, a tip, a path, a target and a weight, and everything else is derived by the rules here. strike: the grammar (tips and the paths each can travel, the targets each limb reaches on each path, the shapes never light, what a path sends, links, steps and beats, the forms, the hand swap, the Legal tags, the re-aim, the banned shapes). strikes: every posed strike as a shape of the grammar. Version field: schema. Policy: closed except keys starting with an underscore. Cross-references (every tip path has targets; every path has a send, links, a step and a beat; every strike is a valid shape and agrees with its manifest rows) are checked by tools/lib/xref-movegen.js (parts-*).',
  type: 'object',
  required: ['schema', 'strike', 'strikes'],
  properties: {
    schema: { const: 'combat.parts/1' },
    strike: obj({
      tips: tableOf(tableOf({ type: 'array', minItems: 1, uniqueItems: true, items: { enum: PATHS } }, 'tip to the paths it can travel'), 'limb to tip to the paths that tip can travel'),
      targets: tableOf(byPath({ type: 'array', minItems: 1, uniqueItems: true, items: name }, 'path to targets'), 'limb to path to the places it can land'),
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
          properties: { form: name, when: filterRef, any: { type: 'array', minItems: 1, items: filterRef }, unless: name },
          anyOf: [{ required: ['when'] }, { required: ['any'] }],
        }, closed),
      },
      swap: { type: 'array', minItems: 1, uniqueItems: true, items: name, description: 'Hand tips one key set can show by a hand-state swap.' },
      tagTips: tableOf({ type: 'array', minItems: 1, uniqueItems: true, items: name }, 'a Legal tag to the hand tips a swap may show'),
      reaim: obj({ limbs: { type: 'array', minItems: 1, uniqueItems: true, items: { enum: LIMBS } }, neighbours: tableOf({ type: 'array', items: name }, 'target to the targets a re-aim can reach') }, { description: 'Sockets the contact solve can reach from a posed key set\'s own.' }),
      legalTags: { type: 'array', items: obj({ tag: name, when: filterRef, why }), description: 'Conditions a shape carries onto its key set, from Legal\'s rulings.' },
      banned: {
        type: 'array',
        description: 'Legal\'s shape rows: never generated, for every fighter. A row matches when every field it names matches (`match`, or the older `shape`).',
        items: Object.assign({ type: 'object', required: ['why'], properties: { id: name, match: filterRef, shape: filterRef, why }, anyOf: [{ required: ['match'] }, { required: ['shape'] }] }, closed),
      },
      bannedSequences: {
        type: 'array',
        description: 'Legal\'s sequence rules, in a form a program can check: run, after, steps or audio.',
        items: Object.assign({
          type: 'object',
          required: ['id', 'kind', 'rule', 'why'],
          properties: {
            id: name,
            kind: { enum: ['run', 'after', 'steps', 'audio'] },
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
        }, closed),
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
      conditions: { type: 'array', description: 'Legal\'s conditions, for Animation: which rows bite on which shapes.', items: obj({ id: { type: 'string', pattern: '^L[0-9]+$' }, when: filterRef, rows: { type: 'array', minItems: 1, uniqueItems: true, items: name }, ask: why }) },
    }, { required: ['tips', 'targets', 'lightNever', 'sends', 'links', 'step', 'beat', 'forms', 'swap', 'tagTips', 'reaim', 'banned'] }),
    strikes: {
      type: 'object',
      propertyNames: { pattern: '^(_.*|strike\\.[a-z0-9_]+)$' },
      description: 'Strike id to its shape.',
      additionalProperties: obj({
        limb: { enum: LIMBS },
        tip: name,
        path: { enum: PATHS },
        target: name,
        weight: { enum: WEIGHTS },
        uses: Object.assign({ type: 'object', properties: { arms: { type: 'integer', minimum: 0 }, legs: { type: 'integer', minimum: 0 }, head: { type: 'integer', minimum: 0 } } }, closed),
        ground: { enum: GROUND },
      }),
      patternProperties: { '^_': true },
    },
  },
  additionalProperties: false,
  patternProperties: { '^_': true },
});

// =============================== identity ===============================
const numTable = (d) => tableOf({ type: 'number', minimum: 0 }, d);
const tipTable = (inner, d) => ({ type: 'object', propertyNames: { pattern: '^(_.*|[a-z]+\\.[a-z0-9_]+)$' }, additionalProperties: inner, patternProperties: { '^_': true }, description: d });
const identitySchema = withDefs({
  $schema: 'https://json-schema.org/draft/2020-12/schema',
  $id: 'meridian/combat-identity',
  title: 'combat.identity/1',
  description: 'data/combat/identity.json: how each fighter bends the grammar of parts.json (docs/combat/moveset-generator.md section 2): the waves his posed strikes come from, the weights of limbs, paths and tips (a tip written limb.tip), the weights that replace them for some shapes, the shapes he never has, his own reading of a shared strike, and how strongly a posed shape is preferred. rejected: shapes a review turned down. Version field: schema. Policy: closed except keys starting with an underscore. Cross-references (every wave has a manifest; every tip is a tip of parts.json; the fighters are keys of recipes.json pools) are checked by tools/lib/xref-movegen.js (identity-ref).',
  type: 'object',
  required: ['schema', 'fighters', 'rejected'],
  properties: {
    schema: { const: 'combat.identity/1' },
    fighters: {
      type: 'object',
      minProperties: 1,
      propertyNames: { pattern: '^(_.*|[a-z][a-z0-9_]*)$' },
      additionalProperties: obj({
        waves: { type: 'array', minItems: 1, uniqueItems: true, items: { type: 'string', pattern: '^[a-z]+[0-9]+$' }, description: 'Animation\'s manifests that hold his posed strikes, in the order their rows replace each other.' },
        weights: obj({ limb: numTable('limb to weight'), path: numTable('path to weight'), tip: tipTable({ type: 'number', minimum: 0 }, 'limb.tip to weight') }),
        weightsBy: { type: 'array', items: obj({ when: filterRef, tip: tipTable({ type: 'number', minimum: 0 }, 'limb.tip to the weight that replaces the plain one') }), description: 'Weights that replace the plain ones for shapes the filter matches.' },
        never: { type: 'array', items: obj({ shape: filterRef, why }), description: 'Shapes he never has.' },
        tipOf: { type: 'object', propertyNames: { pattern: '^(_.*|strike\\.[a-z0-9_]+)$' }, additionalProperties: name, patternProperties: { '^_': true }, description: 'Strike id to a tip: his own reading of a shared strike.' },
        tipFlags: tipTable({ type: 'array', minItems: 1, uniqueItems: true, items: name }, 'How he shows a tip, as pose flags (limb.tip to flags), for Legal\'s rows.'),
        reuse: obj({
          posed: { type: 'number', minimum: 1 },
          hand_state: { type: 'number', minimum: 1 },
          re_aim: { type: 'number', minimum: 1 },
          hand_state_re_aim: { type: 'number', minimum: 1 },
        }, { description: 'How strongly a shape that is posed, or one swap or re-aim from it, is preferred (1 or more).' }),
      }),
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

// a fighter's tipFlags is optional (it came after the first version of the file)
identitySchema.properties.fighters.additionalProperties.required = ['waves', 'weights', 'weightsBy', 'never', 'tipOf', 'reuse'];

// =============================== cells ===============================
const slot = obj({
  slot: name,
  ticks: { type: 'integer', minimum: 1 },
  count: { type: 'integer', minimum: 1 },
  from: { type: 'string', minLength: 1 },
  order: name,
  by: name,
}, { required: ['slot'] });
const quota = Object.assign({
  type: 'object',
  required: ['name', 'min'],
  properties: {
    name,
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
  description: 'data/combat/cells.json: what each face button holds in each stance (Game Design\'s matrix, docs/design/melee-press-feel.md sections 10 and 13): X quick, Y strong, A the stance\'s context action, B its signature. A strikes cell is a filter, a count and quotas; a context cell lists actions; a frame cell lists slots. seed: the generator\'s seed. spread: how each pick marks down the shapes that share a part of it. Version field: schema. Policy: closed except keys starting with an underscore. Cross-references (a quota has exactly one of filter, any, form or sends; names are unique; a quota fits in its cell; its form and sends exist in parts.json) are checked by tools/lib/xref-movegen.js (cells-quota).',
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
});
cellsSchema.$defs.cell = Object.assign({
  type: 'object',
  required: ['kind', 'what'],
  properties: {
    kind: { enum: ['strikes', 'context', 'frame'] },
    what: why,
    filter: filterRef,
    count: { type: 'integer', minimum: 1 },
    quotas: { type: 'array', items: quota },
    actions: { type: 'array', minItems: 1, uniqueItems: true, items: name },
    held: name,
    slots: { type: 'array', minItems: 1, items: slot },
  },
  allOf: [
    { if: { properties: { kind: { const: 'strikes' } } }, then: { required: ['filter', 'count', 'quotas'] } },
    { if: { properties: { kind: { const: 'context' } } }, then: { required: ['actions', 'held'] } },
    { if: { properties: { kind: { const: 'frame' } } }, then: { required: ['slots'] } },
  ],
}, closed);

// =============================== moveset ===============================
const move = obj({
  id: { type: 'string', pattern: '^mv\\.[a-z][a-z0-9_]*\\.[a-z][a-z0-9_]*\\.[a-z]\\.[0-9]{2}$' },
  limb: { enum: LIMBS },
  tip: name,
  path: { enum: PATHS },
  target: name,
  weight: { enum: WEIGHTS },
  forms: { type: 'array', minItems: 1, uniqueItems: true, items: name },
  step: { type: 'array', minItems: 1, items: { enum: STEPS } },
  sends: { enum: SENDS },
  links: { type: 'array', minItems: 1, uniqueItems: true, items: { enum: PATHS } },
  beat: { type: 'integer', minimum: 20, maximum: 28 },
  keys: obj({
    level: { enum: LEVELS },
    from: strikeId,
    set: { type: 'string', pattern: '^[a-z0-9_.~]+$' },
    hand: name,
    aim: name,
  }, { required: ['level'] }),
  ground: { enum: GROUND },
  status: { enum: ['posed', 'derived', 'waiting'] },
  legal: { type: 'array', uniqueItems: true, items: name },
  review: { enum: ['new', 'accepted', 'change', 'rejected'] },
});
// the generator's second version adds arms, flags and asks to a move (all optional here, so the first version's files still pass)
move.properties.arms = { type: 'integer', minimum: 0, description: 'The number of arms the move uses (a generated shape uses one).' };
move.properties.flags = { type: 'array', uniqueItems: true, items: name, description: 'The pose flags known present on the move.' };
move.properties.asks = { type: 'array', uniqueItems: true, items: { type: 'string', pattern: '^L[0-9]+$' }, description: 'The ids of Legal\'s conditions (parts.json strike.conditions) that apply to it.' };
const movesetSchema = {
  $schema: 'https://json-schema.org/draft/2020-12/schema',
  $id: 'meridian/combat-moveset',
  title: 'combat.moveset/1',
  description: 'data/combat/movesets/<fighter>.json: a fighter\'s generated moves (GENERATED by the moveset generator; never edited by hand). fighter: the fighter id. generator: its version, the seed and a hash of its inputs. cells: cell id (stance.button) to a strikes cell (the candidates counted, the quota counts, the moves), a context cell or a frame cell. A move is a shape of the grammar with what the grammar derives from it, the key set it plays (keys), its status and its review. Version field: schema. Policy: closed except keys starting with an underscore. Cross-references (every move is a valid shape that matches no never or banned row, no cell holds a shape twice, sends, links, step, beat and forms are what parts.json derives, status follows keys.level, keys.set and keys.from are a manifest row of the fighter, each cell has its count and quotas) are checked by tools/lib/xref-movegen.js (moveset-*). That the files are what the inputs give is the generator\'s own --check.',
  type: 'object',
  required: ['schema', 'fighter', 'generator', 'cells'],
  properties: {
    schema: { const: 'combat.moveset/1' },
    fighter: name,
    generator: obj({ version: { type: 'integer', minimum: 1 }, seed: { type: 'integer' }, inputs: { type: 'string', pattern: '^[0-9a-f]{8,64}$' } }),
    cells: {
      type: 'object',
      minProperties: 1,
      propertyNames: { pattern: '^(_.*|[a-z][a-z0-9_]*\\.[xyab])$' },
      additionalProperties: Object.assign({
        type: 'object',
        required: ['kind'],
        properties: {
          kind: { enum: ['strikes', 'context', 'frame'] },
          valid: { type: 'integer', minimum: 0, description: 'How many shapes were candidates.' },
          refused: { type: 'array', description: 'Candidates Legal\'s rows refused.' },
          quotas: tableOf({ type: 'integer', minimum: 0 }, 'quota name to how many moves meet it'),
          moves: { type: 'array', minItems: 1, items: move },
          actions: { type: 'array', minItems: 1, uniqueItems: true, items: name },
          held: name,
          slots: { type: 'array', minItems: 1, items: slot },
        },
        allOf: [
          { if: { properties: { kind: { const: 'strikes' } } }, then: { required: ['valid', 'quotas', 'moves'] } },
          { if: { properties: { kind: { const: 'context' } } }, then: { required: ['actions', 'held'] } },
          { if: { properties: { kind: { const: 'frame' } } }, then: { required: ['slots'] } },
        ],
      }, closed),
      patternProperties: { '^_': true },
    },
  },
  additionalProperties: false,
  patternProperties: { '^_': true },
};

for (const [file, s] of [['combat-parts', partsSchema], ['combat-identity', identitySchema], ['combat-cells', cellsSchema], ['combat-moveset', movesetSchema]]) {
  const f = `tools/schemas/${file}.schema.json`;
  if (!fs.existsSync(f)) wj(f, s);
}

// =============================== map ===============================
{
  const f = 'tools/schemas/map.json';
  const m = rj(f);
  let changed = false;
  for (const [match, schema] of [['data/combat/parts.json', 'combat-parts.schema.json'], ['data/combat/identity.json', 'combat-identity.schema.json'], ['data/combat/cells.json', 'combat-cells.schema.json'], ['data/combat/movesets/*.json', 'combat-moveset.schema.json']]) {
    if (m.rules.some((r) => r.match === match)) continue;
    const i = m.rules.findIndex((r) => r.match === 'data/combat/recipes.json');
    m.rules.splice(i >= 0 ? i + 1 : m.rules.length, 0, { match, schema });
    changed = true;
  }
  if (changed) wj(f, m);
}

// =============================== xref ===============================
{
  const dst = 'tools/lib/xref-movegen.js';
  const src = 'docs/tools/pending/xref-movegen.js';
  if (!fs.existsSync(dst)) fs.copyFileSync(src, dst);
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
  const live = {
    parts: rj(P),
    ident: rj(I),
    cells: rj(C),
    rival: rj('data/combat/movesets/' + movesetFiles[0]),
  };
  const M = 'data/combat/movesets/' + movesetFiles[0];
  const fid = live.rival.fighter;
  const X = '/cells/martial.x/';
  const mv = X + 'moves/';
  const strikeIds = Object.keys(live.parts.strikes).filter((k) => !k.startsWith('_'));
  const sid = strikeIds[0];
  const pa = (n, mut, expect) => ({ id: 'combat-parts-' + n, schema: 'combat-parts.schema.json', mutate: [{ file: P, ...mut }], expect });
  const id = (n, mut, expect) => ({ id: 'combat-identity-' + n, schema: 'combat-identity.schema.json', mutate: [{ file: I, ...mut }], expect });
  const ce = (n, mut, expect) => ({ id: 'combat-cells-' + n, schema: 'combat-cells.schema.json', mutate: [{ file: C, ...mut }], expect });
  const ms = (n, mut, expect) => ({ id: 'combat-moveset-' + n, schema: 'combat-moveset.schema.json', mutate: [{ file: M, ...mut }], expect });
  const F = '/fighters/' + fid + '/';
  const ST = '/strike/';
  const add = [
    // ---- parts ----
    pa('live-valid', { set: { '/schema': 'combat.parts/1' } }, null),
    pa('key-required', { del: ['/strikes'] }, { rule: 'required', pointer: '' }),
    pa('schema-version', { set: { '/schema': 'combat.parts/2' } }, { rule: 'const', pointer: '/schema' }),
    pa('unknown-key', { set: { '/extra': 1 } }, { rule: 'additionalProperties', pointer: '/extra' }),
    pa('underscore-key-ok', { set: { '/_why': 'comment' } }, null),
    pa('strike-key-required', { del: [ST + 'beat'] }, { rule: 'required', pointer: '/strike' }),
    pa('strike-unknown-key', { set: { [ST + 'wobble']: 1 } }, { rule: 'additionalProperties', pointer: ST + 'wobble' }),
    pa('tip-path-enum', { set: { [ST + 'tips/hand/fist']: ['zigzag'] } }, { rule: 'enum', pointer: ST + 'tips/hand/fist/0' }),
    pa('tip-paths-empty', { set: { [ST + 'tips/hand/fist']: [] } }, { rule: 'minItems', pointer: ST + 'tips/hand/fist' }),
    pa('tip-path-without-targets', { set: { [ST + 'tips/elbow/point']: ['arc_in', 'rise', 'drop', 'spin', 'arc_out'] } }, { rule: 'xref:parts-grammar', pointer: ST + 'tips/elbow/point/4' }),
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
    pa('forms-key-required', { set: { [ST + 'forms/0']: { when: { weight: ['light'] } } } }, { rule: 'required', pointer: ST + 'forms/0' }),
    pa('forms-needs-a-rule', { set: { [ST + 'forms/0']: { form: 'light' } } }, { rule: 'anyOf', pointer: ST + 'forms/0' }),
    pa('forms-duplicate', { set: { [ST + 'forms/1/form']: 'light' } }, { rule: 'xref:parts-grammar', pointer: ST + 'forms/1/form' }),
    pa('forms-unless-later', { set: { [ST + 'forms/1/unless']: 'break' } }, { rule: 'xref:parts-grammar', pointer: ST + 'forms/1/unless' }),
    pa('swap-not-a-hand-tip', { set: { [ST + 'swap']: ['fist', 'ball'] } }, { rule: 'xref:parts-grammar', pointer: ST + 'swap/1' }),
    pa('tag-tip-not-a-hand-tip', { set: { [ST + 'tagTips/hands_open_or_claw']: ['palm', 'ball'] } }, { rule: 'xref:parts-grammar', pointer: ST + 'tagTips/hands_open_or_claw/1' }),
    pa('reaim-limb-enum', { set: { [ST + 'reaim/limbs']: ['tail'] } }, { rule: 'enum', pointer: ST + 'reaim/limbs/0' }),
    pa('condition-key-required', { set: { [ST + 'conditions/0']: { id: 'L1', when: { limb: ['hand'] }, rows: ['b03'] } } }, { rule: 'required', pointer: ST + 'conditions/0' }),
    pa('condition-id-shape', { set: { [ST + 'conditions/0/id']: 'cond1' } }, { rule: 'pattern', pointer: ST + 'conditions/0/id' }),
    pa('condition-names-no-rule', { set: { [ST + 'conditions/0/rows']: ['b99'] } }, { rule: 'xref:parts-grammar', pointer: ST + 'conditions/0/rows/0' }),
    pa('rule-id-twice', { set: { [ST + 'banned/1/id']: 'b01' } }, { rule: 'xref:parts-grammar', pointer: ST + 'banned/1/id' }),
    pa('banned-sequence-kind-enum', { set: { [ST + 'bannedSequences/0/kind']: 'dance' } }, { rule: 'enum', pointer: ST + 'bannedSequences/0/kind' }),
    pa('banned-sequence-key-required', { del: [ST + 'bannedSequences/0/why'] }, { rule: 'required', pointer: ST + 'bannedSequences/0' }),
    pa('banned-sequence-max-zero', { set: { [ST + 'bannedSequences/0/max']: 0 } }, { rule: 'minimum', pointer: ST + 'bannedSequences/0/max' }),
    pa('banned-flag-unknown-warns', { set: { [ST + 'banned/0/match/flags']: ['wrists_together', 'levitate'] } }, { rule: 'xref:parts-grammar', pointer: ST + 'banned/0/match/flags/1' }),
    pa('banned-ok', { set: { [ST + 'banned/-']: { id: 'b99', match: { limb: ['head'], path: ['spin'] }, why: 'a review' } } }, null),
    pa('banned-key-required', { set: { [ST + 'banned']: [{ shape: { limb: ['head'] } }] } }, { rule: 'required', pointer: ST + 'banned/0' }),
    pa('target-not-a-socket', { set: { [ST + 'targets/hand/line']: ['head', 'moon'] } }, { rule: 'xref:parts-grammar', pointer: ST + 'targets/hand/line/1' }),
    pa('strikes-id-shape', { set: { '/strikes/Jab': { limb: 'hand', tip: 'blade', path: 'line', target: 'head', weight: 'light', uses: { arms: 1 }, ground: 'ok' } } }, { rule: 'propertyNames', pointer: '/strikes/Jab' }),
    pa('strike-row-key-required', { del: [`/strikes/${sid}/ground`] }, { rule: 'required', pointer: `/strikes/${sid}` }),
    pa('strike-row-limb-enum', { set: { [`/strikes/${sid}/limb`]: 'tail' } }, { rule: 'enum', pointer: `/strikes/${sid}/limb` }),
    pa('strike-row-ground-enum', { set: { [`/strikes/${sid}/ground`]: 'sometimes' } }, { rule: 'enum', pointer: `/strikes/${sid}/ground` }),
    pa('strike-row-uses-unknown-key', { set: { [`/strikes/${sid}/uses/tail`]: 1 } }, { rule: 'additionalProperties', pointer: `/strikes/${sid}/uses/tail` }),
    pa('strike-row-tip-cannot-travel', { set: { [`/strikes/${sid}/tip`]: 'ball' } }, { rule: 'xref:parts-strike', pointer: `/strikes/${sid}` }),
    pa('strike-row-target-unreachable', { set: { [`/strikes/${sid}/target`]: 'shins' } }, { rule: 'xref:parts-strike', pointer: `/strikes/${sid}` }),
    pa('strike-row-limb-differs-from-manifest', { set: { [`/strikes/${sid}/limb`]: 'foot', [`/strikes/${sid}/tip`]: 'ball', [`/strikes/${sid}/path`]: 'line', [`/strikes/${sid}/target`]: 'chest' } }, { rule: 'xref:parts-strike', pointer: `/strikes/${sid}/limb` }),
    pa('strike-row-without-manifest', { set: { '/strikes/strike.nowhere': { limb: 'hand', tip: 'blade', path: 'line', target: 'head', weight: 'light', uses: { arms: 1 }, ground: 'ok' } } }, { rule: 'xref:parts-strike', pointer: '/strikes/strike.nowhere' }),
    // ---- identity ----
    id('live-valid', { set: { '/schema': 'combat.identity/1' } }, null),
    id('key-required', { del: ['/rejected'] }, { rule: 'required', pointer: '' }),
    id('unknown-key', { set: { '/extra': 1 } }, { rule: 'additionalProperties', pointer: '/extra' }),
    id('underscore-key-ok', { set: { '/_why': 'comment' } }, null),
    id('fighter-key-required', { del: [F + 'reuse'] }, { rule: 'required', pointer: F.slice(0, -1) }),
    id('fighter-unknown-key', { set: { [F + 'mood']: 1 } }, { rule: 'additionalProperties', pointer: F + 'mood' }),
    id('fighter-not-in-recipes', { set: { '/fighters/nobody': clone(live.ident.fighters[fid]) } }, { rule: 'xref:identity-ref', pointer: '/fighters/nobody' }),
    id('waves-shape', { set: { [F + 'waves']: ['Wave 1'] } }, { rule: 'pattern', pointer: F + 'waves/0' }),
    id('waves-empty', { set: { [F + 'waves']: [] } }, { rule: 'minItems', pointer: F + 'waves' }),
    id('wave-without-manifest', { set: { [F + 'waves']: ['wave9'] } }, { rule: 'xref:identity-ref', pointer: F + 'waves/0' }),
    id('weight-negative', { set: { [F + 'weights/limb/hand']: -1 } }, { rule: 'minimum', pointer: F + 'weights/limb/hand' }),
    id('weight-type', { set: { [F + 'weights/path/line']: 'high' } }, { rule: 'type', pointer: F + 'weights/path/line' }),
    id('weight-key-required', { del: [F + 'weights/tip'] }, { rule: 'required', pointer: F + 'weights' }),
    id('weight-tip-unknown', { set: { [F + 'weights/tip/hand.claw']: 1 } }, { rule: 'xref:identity-ref', pointer: F + 'weights/tip/hand.claw' }),
    id('weight-tip-without-limb', { set: { [F + 'weights/tip/fist']: 1 } }, { rule: 'xref:identity-ref', pointer: F + 'weights/tip/fist' }),
    id('weights-by-key-required', { set: { [F + 'weightsBy']: [{ when: { weight: ['light'] } }] } }, { rule: 'required', pointer: F + 'weightsBy/0' }),
    id('weights-by-tip-unknown', { set: { [F + 'weightsBy']: [{ when: { weight: ['light'] }, tip: { 'hand.claw': 2 } }] } }, { rule: 'xref:identity-ref', pointer: F + 'weightsBy/0/tip/hand.claw' }),
    id('never-key-required', { set: { [F + 'never']: [{ shape: { limb: ['head'] } }] } }, { rule: 'required', pointer: F + 'never/0' }),
    id('never-ok', { set: { [F + 'never']: [{ shape: { limb: ['head'] }, why: 'a ruling' }] } }, null),
    id('tip-of-unknown-strike', { set: { [F + 'tipOf']: { 'strike.nowhere': 'fist' } } }, { rule: 'xref:identity-ref', pointer: F + 'tipOf/strike.nowhere' }),
    id('tip-of-wrong-limb', { set: { [F + 'tipOf']: { [sid]: 'ball' } } }, { rule: 'xref:identity-ref', pointer: F + `tipOf/${sid}` }),
    id('reuse-below-one', { set: { [F + 'reuse/posed']: 0.5 } }, { rule: 'minimum', pointer: F + 'reuse/posed' }),
    id('reuse-key-required', { del: [F + 'reuse/re_aim'] }, { rule: 'required', pointer: F + 'reuse' }),
    id('rejected-key-required', { set: { '/rejected': [{ fighter: fid, why: 'a review' }] } }, { rule: 'required', pointer: '/rejected/0' }),
    id('rejected-fighter-unknown', { set: { '/rejected': [{ fighter: 'nobody', shape: { limb: 'hand', tip: 'fist', path: 'line', target: 'head', weight: 'light' }, why: 'a review' }] } }, { rule: 'xref:identity-ref', pointer: '/rejected/0/fighter' }),
    id('rejected-ok', { set: { '/rejected': [{ fighter: fid, shape: { limb: 'hand', tip: 'fist', path: 'line', target: 'head', weight: 'light' }, why: 'a review' }] } }, null),
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
    ce('strikes-cell-count-required', { del: ['/stances/martial/x/count'] }, { rule: 'required', pointer: '/stances/martial/x' }),
    ce('strikes-cell-count-zero', { set: { '/stances/martial/x/count': 0 } }, { rule: 'minimum', pointer: '/stances/martial/x/count' }),
    ce('strikes-cell-quotas-required', { del: ['/stances/martial/x/quotas'] }, { rule: 'required', pointer: '/stances/martial/x' }),
    ce('context-cell-actions-required', { del: ['/stances/martial/a/actions'] }, { rule: 'required', pointer: '/stances/martial/a' }),
    ce('frame-cell-slots-required', { del: ['/stances/martial/b/slots'] }, { rule: 'required', pointer: '/stances/martial/b' }),
    ce('frame-slot-key-required', { set: { '/stances/martial/b/slots/0': { ticks: 30 } } }, { rule: 'required', pointer: '/stances/martial/b/slots/0' }),
    ce('frame-slot-unknown-key', { set: { '/stances/martial/b/slots/0/mood': 1 } }, { rule: 'additionalProperties', pointer: '/stances/martial/b/slots/0/mood' }),
    ce('quota-key-required', { del: ['/stances/martial/x/quotas/0/min'] }, { rule: 'required', pointer: '/stances/martial/x/quotas/0' }),
    ce('quota-min-negative', { set: { '/stances/martial/x/quotas/0/min': -1 } }, { rule: 'minimum', pointer: '/stances/martial/x/quotas/0/min' }),
    ce('quota-sends-enum', { set: { '/stances/martial/y/quotas/0/sends': 'sideways' } }, { rule: 'enum', pointer: '/stances/martial/y/quotas/0/sends' }),
    ce('quota-with-two-rules', { set: { '/stances/martial/x/quotas/0/form': 'flurry' } }, { rule: 'xref:cells-quota', pointer: '/stances/martial/x/quotas/0' }),
    ce('quota-with-no-rule', { del: ['/stances/martial/x/quotas/0/filter'] }, { rule: 'xref:cells-quota', pointer: '/stances/martial/x/quotas/0' }),
    ce('quota-name-twice', { set: { '/stances/martial/x/quotas/1/name': live.cells.stances.martial.x.quotas[0].name } }, { rule: 'xref:cells-quota', pointer: '/stances/martial/x/quotas/1/name' }),
    ce('quota-larger-than-cell', { set: { '/stances/martial/x/quotas/0/min': 99 } }, { rule: 'xref:cells-quota', pointer: '/stances/martial/x/quotas/0/min' }),
    ce('quota-form-unknown', { set: { '/stances/martial/x/quotas/5/form': 'dance' } }, { rule: 'xref:cells-quota', pointer: '/stances/martial/x/quotas/5/form' }),
    // ---- moveset ----
    ms('live-valid', { set: { '/schema': 'combat.moveset/1' } }, null),
    ms('key-required', { del: ['/generator'] }, { rule: 'required', pointer: '' }),
    ms('schema-version', { set: { '/schema': 'combat.moveset/2' } }, { rule: 'const', pointer: '/schema' }),
    ms('unknown-key', { set: { '/extra': 1 } }, { rule: 'additionalProperties', pointer: '/extra' }),
    ms('underscore-key-ok', { set: { '/_why': 'comment' } }, null),
    ms('fighter-not-in-identity', { set: { '/fighter': 'nobody' } }, { rule: 'xref:moveset-cell', pointer: '/fighter' }),
    ms('generator-key-required', { del: ['/generator/seed'] }, { rule: 'required', pointer: '/generator' }),
    ms('generator-inputs-shape', { set: { '/generator/inputs': 'not a hash' } }, { rule: 'pattern', pointer: '/generator/inputs' }),
    ms('generator-seed-differs-from-cells', { set: { '/generator/seed': live.cells.seed + 1 } }, { rule: 'xref:moveset-cell', pointer: '/generator/seed' }),
    ms('cell-id-shape', { set: { '/cells/martial': { kind: 'frame', slots: [{ slot: 'tell' }] } } }, { rule: 'propertyNames', pointer: '/cells/martial' }),
    ms('cell-not-in-cells', { set: { '/cells/boxing.x': { kind: 'frame', slots: [{ slot: 'tell' }] } } }, { rule: 'xref:moveset-cell', pointer: '/cells/boxing.x' }),
    ms('cell-kind-differs', { set: { '/cells/martial.b/kind': 'context', '/cells/martial.b/actions': ['a'], '/cells/martial.b/held': 'channel' } }, { rule: 'xref:moveset-cell', pointer: '/cells/martial.b/kind' }),
    ms('strikes-cell-key-required', { del: [X + 'valid'] }, { rule: 'required', pointer: '/cells/martial.x' }),
    ms('strikes-cell-quota-negative', { set: { [X + 'quotas/toward']: -1 } }, { rule: 'minimum', pointer: X + 'quotas/toward' }),
    ms('strikes-cell-moves-empty', { set: { [X + 'moves']: [] } }, { rule: 'minItems', pointer: X + 'moves' }),
    ms('cell-short-of-its-count', { del: [mv + '29'] }, { rule: 'xref:moveset-cell', pointer: X.slice(0, -1) + '/moves' }),
    ms('move-key-required', { del: [mv + '0/review'] }, { rule: 'required', pointer: mv + '0' }),
    ms('move-unknown-key', { set: { [mv + '0/mood']: 1 } }, { rule: 'additionalProperties', pointer: mv + '0/mood' }),
    ms('move-id-shape', { set: { [mv + '0/id']: 'move 1' } }, { rule: 'pattern', pointer: mv + '0/id' }),
    ms('move-id-out-of-order', { set: { [mv + '0/id']: `mv.${fid}.martial.x.07` } }, { rule: 'xref:moveset-cell', pointer: mv + '0/id' }),
    ms('move-limb-enum', { set: { [mv + '0/limb']: 'tail' } }, { rule: 'enum', pointer: mv + '0/limb' }),
    ms('move-weight-enum', { set: { [mv + '0/weight']: 'medium' } }, { rule: 'enum', pointer: mv + '0/weight' }),
    ms('move-beat-range', { set: { [mv + '0/beat']: 30 } }, { rule: 'maximum', pointer: mv + '0/beat' }),
    ms('move-status-enum', { set: { [mv + '0/status']: 'done' } }, { rule: 'enum', pointer: mv + '0/status' }),
    ms('move-review-enum', { set: { [mv + '0/review']: 'maybe' } }, { rule: 'enum', pointer: mv + '0/review' }),
    ms('move-ground-enum', { set: { [mv + '0/ground']: 'sometimes' } }, { rule: 'enum', pointer: mv + '0/ground' }),
    ms('move-forms-duplicate', { set: { [mv + '0/forms']: ['light', 'light'] } }, { rule: 'uniqueItems', pointer: mv + '0/forms/1' }),
    ms('move-legal-duplicate', { set: { [mv + '0/legal']: ['no_leap', 'no_leap'] } }, { rule: 'uniqueItems', pointer: mv + '0/legal/1' }),
    ms('move-keys-level-enum', { set: { [mv + '0/keys/level']: 'remix' } }, { rule: 'enum', pointer: mv + '0/keys/level' }),
    ms('move-keys-level-required', { del: [mv + '0/keys/level'] }, { rule: 'required', pointer: mv + '0/keys' }),
    ms('move-keys-from-shape', { set: { [mv + '0/keys/from']: 'jab' } }, { rule: 'pattern', pointer: mv + '0/keys/from' }),
    ms('move-keys-unknown-key', { set: { [mv + '0/keys/mood']: 1 } }, { rule: 'additionalProperties', pointer: mv + '0/keys/mood' }),
    ms('move-shape-invalid', { set: { [mv + '0/tip']: 'claw' } }, { rule: 'xref:moveset-shape', pointer: mv + '0' }),
    ms('move-shape-twice', { set: { [mv + '1/limb']: live.rival.cells['martial.x'].moves[0].limb, [mv + '1/tip']: live.rival.cells['martial.x'].moves[0].tip, [mv + '1/path']: live.rival.cells['martial.x'].moves[0].path, [mv + '1/target']: live.rival.cells['martial.x'].moves[0].target } }, { rule: 'xref:moveset-shape', pointer: mv + '1' }),
    ms('move-sends-not-derived', { set: { [mv + '0/sends']: 'up' === live.rival.cells['martial.x'].moves[0].sends ? 'down' : 'up' } }, { rule: 'xref:moveset-derived', pointer: mv + '0/sends' }),
    ms('move-beat-not-derived', { set: { [mv + '0/beat']: live.rival.cells['martial.x'].moves[0].beat === 22 ? 24 : 22 } }, { rule: 'xref:moveset-derived', pointer: mv + '0/beat' }),
    ms('move-step-not-derived', { set: { [mv + '0/step']: ['out'] } }, { rule: 'xref:moveset-derived', pointer: mv + '0/step' }),
    ms('move-links-not-derived', { set: { [mv + '0/links']: ['spin'] } }, { rule: 'xref:moveset-derived', pointer: mv + '0/links' }),
    ms('move-forms-not-derived', { set: { [mv + '0/forms']: ['light', 'ender'] } }, { rule: 'xref:moveset-derived', pointer: mv + '0/forms' }),
    ms('move-status-differs-from-level', { set: { [mv + '0/status']: live.rival.cells['martial.x'].moves[0].status === 'waiting' ? 'posed' : 'waiting' } }, { rule: 'xref:moveset-keys', pointer: mv + '0/status' }),
    ms('move-new-with-a-key-set', { set: { [mv + '0/keys/level']: 'new' } }, { rule: 'xref:moveset-keys', pointer: mv + '0/keys' }),
    ms('move-key-set-in-no-manifest', { set: { [mv + '0/keys/set']: 'w9.nowhere' } }, { rule: 'xref:moveset-keys', pointer: mv + '0/keys/set' }),
    ms('move-key-set-is-another-strike', { set: { [mv + '0/keys/from']: strikeIds.find((s) => s !== live.rival.cells['martial.x'].moves[0].keys.from) } }, { rule: 'xref:moveset-keys', pointer: mv + '0/keys/from' }),
    ms('move-arms-negative', { set: { [mv + '0/arms']: -1 } }, { rule: 'minimum', pointer: mv + '0/arms' }),
    ms('move-flags-duplicate', { set: { [mv + '0/flags']: ['claw', 'claw'] } }, { rule: 'uniqueItems', pointer: mv + '0/flags/1' }),
    ms('move-asks-shape', { set: { [mv + '0/asks']: ['legal-1'] } }, { rule: 'pattern', pointer: mv + '0/asks/0' }),
    ms('move-asks-unknown-condition', { set: { [mv + '0/asks']: ['L99'] } }, { rule: 'xref:moveset-keys', pointer: mv + '0/asks/0' }),
    ms('cell-refused-type', { set: { [X + 'refused']: 'many' } }, { rule: 'type', pointer: X + 'refused' }),
    ms('cell-quota-miscounted', { set: { [X + 'quotas/toward']: 99 } }, { rule: 'xref:moveset-cell', pointer: X + 'quotas/toward' }),
    ms('context-cell-key-required', { del: ['/cells/martial.a/actions'] }, { rule: 'required', pointer: '/cells/martial.a' }),
    ms('frame-cell-key-required', { del: ['/cells/martial.b/slots'] }, { rule: 'required', pointer: '/cells/martial.b' }),
  ];
  let n = 0;
  for (const k of add) if (!c.cases.some((y) => y.id === k.id)) { c.cases.push(k); n++; }
  wj(cf, c);
  console.log(`movegen schemas applied (${n} new cases)`);
}

// =============================== docs ===============================
{
  const f = 'docs/tools/README.md';
  let t = fs.readFileSync(f, 'utf8');
  if (!t.includes('moveset-derived')) {
    const line = t.split('\n').find((l) => l.includes('`recipes-brawl`')) || t.split('\n').find((l) => l.includes('`recipes-heavies`'));
    if (!line) throw new Error('movegen README anchor');
    t = t.replace(line, () => line + '\n| `parts-grammar`, `parts-strike` | data/combat/parts.json: every path a tip travels has targets; every path has a send, links, a step and a beat; every strike is a valid shape (its tip takes its path, its path reaches its target, a light matches no lightNever row) and agrees with its manifest rows (limb and target; the grammar\'s `arm` is a near arm) |\n| `identity-ref` | data/combat/identity.json: the fighters are keys of recipes.json pools; every wave has a manifest; every tip key is a tip of parts.json; `tipOf` names a strike and a tip of its limb |\n| `cells-quota` | data/combat/cells.json: a quota has exactly one of filter, any, form or sends; names are unique in a cell; a quota fits in its cell; its form and sends exist in parts.json |\n| `moveset-cell`, `moveset-shape`, `moveset-derived`, `moveset-keys` | data/combat/movesets/<fighter>.json: the fighter and seed match identity.json and cells.json; each cell is in cells.json with its count, filter and quotas (recounted); move ids run in order; every move is a valid shape, matches no never or banned row, and no cell repeats a shape; sends, links, step, beat and forms are what parts.json derives; status follows keys.level; keys.set and keys.from are a manifest row of the fighter |');
    fs.writeFileSync(f, t);
  }
}
