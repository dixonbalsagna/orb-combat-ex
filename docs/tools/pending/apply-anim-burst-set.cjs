// Schema keys for Animation's burst set (the pose a burst's first blow sets from): data/anim/press_styles.json gains an optional `set` object on a
// style row (today only `burst` has it). NOT run by CI, the validator or the sim. Run once from the repo root, in the commit that lands Animation's
// data (the style's `set`, and the parked wave burst1 with the poses bu.set_p.set and bu.set_r.set):
//     node docs/tools/pending/apply-anim-burst-set.cjs
// It does NOT edit data/. The `set` object (closed; all seven keys required inside it, as the data has them):
//   pose     an object, fighter key to pose id (at least one fighter)
//   from, to_before, in, out   integers, 0 to 30 (ticks)
//   w        number, 0 to 1
//   min_gap  integer, 0 to 60 (ticks)
// Rule pressstyles-set: every key of `set.pose` is a fighter of data/anim/fighters.json (as the squash poses' fighters are) and every pose id is a
// pose of poses.json or of a wave. The waves protag11, rival8 and burst1 validate under the existing wave schemas and need nothing more.
// Every case sets its own values (a pose and a fighter it reads from the data of the day). Re-runnable (a second run changes nothing).
const fs = require('fs');
const rj = (f) => JSON.parse(fs.readFileSync(f, 'utf8'));
const wj = (f, o) => fs.writeFileSync(f, JSON.stringify(o, null, 2) + '\n');
const clone = (o) => JSON.parse(JSON.stringify(o));
const closed = { additionalProperties: false, patternProperties: { '^_': true } };
const ticks = (max, d) => ({ type: 'integer', minimum: 0, maximum: max, description: d });

// =============================== schema ===============================
{
  const f = 'tools/schemas/anim-press-styles.schema.json';
  const s = rj(f);
  const rows = s.properties.styles.properties;
  const SET = Object.assign({
    type: 'object',
    required: ['pose', 'from', 'to_before', 'in', 'out', 'w', 'min_gap'],
    description: 'Optional. The pose a style\'s first blow sets from (the burst\'s set): a fighter\'s pose, and how it is blended in and out.',
    properties: {
      pose: { type: 'object', minProperties: 1, propertyNames: { pattern: '^(_.*|[A-Za-z][A-Za-z0-9_]*)$' }, additionalProperties: { type: 'string', pattern: '^[a-z][a-z0-9_]*([.][a-z0-9_]+)*$' }, patternProperties: { '^_': true }, description: 'A fighter key to the pose he sets from (rule pressstyles-set: a fighter of fighters.json and a real pose).' },
      from: ticks(30, 'Ticks before the blow at which the set begins.'),
      to_before: ticks(30, 'Ticks before the blow by which the set has been reached.'),
      in: ticks(30, 'Ticks the set takes to blend in.'),
      out: ticks(30, 'Ticks the set takes to blend out.'),
      w: { type: 'number', minimum: 0, maximum: 1, description: 'How much of the pose is taken.' },
      min_gap: ticks(60, 'The shortest gap, in ticks, between blows at which the set is used.'),
    },
  }, closed);
  let changed = false;
  for (const [k, row] of Object.entries(rows)) {
    if (row && row.properties && !row.properties.set) { row.properties.set = clone(SET); changed = true; }
  }
  if (!/pressstyles-set/.test(s.description)) { s.description = s.description.replace(/\. Cross-references \(/, () => '. Cross-references (a style\'s set.pose names fighters of fighters.json and real poses (pressstyles-set); '); changed = true; }
  if (changed) wj(f, s);
}

// =============================== xref ===============================
{
  const f = 'tools/lib/xref-fight.js';
  let t = fs.readFileSync(f, 'utf8');
  if (!t.includes("'pressstyles-set'")) {
    const a = "    for (const [sid, st] of Object.entries(isObj(pst.styles) ? pst.styles : {})) {\n      if (sid.startsWith('_') || !isObj(st)) continue;\n      if (st.carry === true";
    if (!t.includes(a)) throw new Error('burst set xref anchor');
    t = t.replace(a, () => [
      "    for (const [sid, st] of Object.entries(isObj(pst.styles) ? pst.styles : {})) {",
      "      if (sid.startsWith('_') || !isObj(st) || !isObj(st.set) || !isObj(st.set.pose)) continue;",
      "      const fgsSet = get('data/anim/fighters.json');",
      "      const fidsSet = isObj(fgsSet) && isObj(fgsSet.fighters) ? Object.keys(fgsSet.fighters).filter((k) => !k.startsWith('_')) : [];",
      "      for (const [fk, pid] of Object.entries(st.set.pose)) {",
      "        if (fk.startsWith('_')) continue;",
      "        if (fidsSet.length && !fidsSet.includes(fk)) err(PS, `/styles/${esc(sid)}/set/pose/${esc(fk)}`, 'pressstyles-set', `\"${fk}\" is not a fighter of fighters.json (${fidsSet.join(', ')})`);",
      "        if (typeof pid === 'string' && allPosesPs.size && !allPosesPs.has(pid)) err(PS, `/styles/${esc(sid)}/set/pose/${esc(fk)}`, 'pressstyles-set', `pose \"${pid}\" is not in poses.json nor a wave's poses`);",
      "      }",
      "    }",
      a,
    ].join('\n'));
    fs.writeFileSync(f, t);
  }
}

// =============================== cases ===============================
{
  const cf = 'tools/fixtures/cases.json';
  const c = rj(cf);
  const P = 'data/anim/press_styles.json';
  const fighter = Object.keys(rj('data/anim/fighters.json').fighters)[0];
  const pose = Object.keys(rj('data/anim/poses.json').poses)[0];
  const BASE = { pose: { [fighter]: pose }, from: 3, to_before: 2, in: 2, out: 2, w: 0.9, min_gap: 14 };
  const x = (n, tweak, expect, style) => { const o = clone(BASE); tweak(o); return { id: 'anim-press-styles-set-' + n, schema: 'anim-press-styles.schema.json', mutate: [{ file: P, set: { ['/styles/' + (style || 'burst') + '/set']: o } }], expect }; };
  const S = '/styles/burst/set/';
  const add = [
    x('valid', () => {}, null),
    x('on-another-style-ok', () => {}, null, 'tech'),
    x('key-required-pose', (o) => { delete o.pose; }, { rule: 'required', pointer: '/styles/burst/set' }),
    x('key-required-from', (o) => { delete o.from; }, { rule: 'required', pointer: '/styles/burst/set' }),
    x('key-required-to-before', (o) => { delete o.to_before; }, { rule: 'required', pointer: '/styles/burst/set' }),
    x('key-required-in', (o) => { delete o.in; }, { rule: 'required', pointer: '/styles/burst/set' }),
    x('key-required-out', (o) => { delete o.out; }, { rule: 'required', pointer: '/styles/burst/set' }),
    x('key-required-w', (o) => { delete o.w; }, { rule: 'required', pointer: '/styles/burst/set' }),
    x('key-required-min-gap', (o) => { delete o.min_gap; }, { rule: 'required', pointer: '/styles/burst/set' }),
    x('unknown-key', (o) => { o.extra = 1; }, { rule: 'additionalProperties', pointer: S + 'extra' }),
    x('note-ok', (o) => { o._why = 'a note'; }, null),
    x('pose-type', (o) => { o.pose = 'bu.set'; }, { rule: 'type', pointer: S + 'pose' }),
    x('pose-empty', (o) => { o.pose = {}; }, { rule: 'minProperties', pointer: S + 'pose' }),
    x('pose-id-shape', (o) => { o.pose[fighter] = 'Bu Set'; }, { rule: 'pattern', pointer: S + 'pose/' + fighter }),
    x('pose-id-type', (o) => { o.pose[fighter] = 5; }, { rule: 'type', pointer: S + 'pose/' + fighter }),
    x('pose-fighter-unknown', (o) => { o.pose.nobody = pose; }, { rule: 'xref:pressstyles-set', pointer: S + 'pose/nobody' }),
    x('pose-fighter-key-shape', (o) => { o.pose['No Body'] = pose; }, { rule: 'propertyNames', pointer: S + 'pose/No Body' }),
    x('pose-unknown', (o) => { o.pose[fighter] = 'bu.nowhere'; }, { rule: 'xref:pressstyles-set', pointer: S + 'pose/' + fighter }),
    ...['from', 'to_before', 'in', 'out'].flatMap((k) => [
      x(k.replace(/_/g, '-') + '-negative', (o) => { o[k] = -1; }, { rule: 'minimum', pointer: S + k }),
      x(k.replace(/_/g, '-') + '-above-thirty', (o) => { o[k] = 31; }, { rule: 'maximum', pointer: S + k }),
      x(k.replace(/_/g, '-') + '-integer', (o) => { o[k] = 2.5; }, { rule: 'type', pointer: S + k }),
      x(k.replace(/_/g, '-') + '-edges-ok', (o) => { o[k] = 0; }, null),
      x(k.replace(/_/g, '-') + '-thirty-ok', (o) => { o[k] = 30; }, null),
    ]),
    x('w-negative', (o) => { o.w = -0.1; }, { rule: 'minimum', pointer: S + 'w' }),
    x('w-above-one', (o) => { o.w = 1.1; }, { rule: 'maximum', pointer: S + 'w' }),
    x('w-type', (o) => { o.w = 'half'; }, { rule: 'type', pointer: S + 'w' }),
    x('w-edges-ok', (o) => { o.w = 0; }, null),
    x('w-one-ok', (o) => { o.w = 1; }, null),
    x('min-gap-negative', (o) => { o.min_gap = -1; }, { rule: 'minimum', pointer: S + 'min_gap' }),
    x('min-gap-above-sixty', (o) => { o.min_gap = 61; }, { rule: 'maximum', pointer: S + 'min_gap' }),
    x('min-gap-integer', (o) => { o.min_gap = 14.5; }, { rule: 'type', pointer: S + 'min_gap' }),
    x('min-gap-zero-ok', (o) => { o.min_gap = 0; }, null),
  ];
  let n = 0;
  for (const k of add) {
    const i = c.cases.findIndex((y) => y.id === k.id);
    if (i < 0) { c.cases.push(k); n++; } else if (JSON.stringify(c.cases[i]) !== JSON.stringify(k)) { c.cases[i] = k; n++; }
  }
  wj(cf, c);
  console.log(`press styles burst set applied (${n} new cases)`);
}

// =============================== docs ===============================
{
  const f = 'docs/tools/README.md';
  let t = fs.readFileSync(f, 'utf8');
  if (!t.includes('`pressstyles-set`')) {
    const lines = t.split('\n');
    const i = lines.findIndex((l) => l.includes('`pressstyles-riposte`'));
    if (i < 0) throw new Error('burst set README anchor');
    lines.splice(i + 1, 0, '| `pressstyles-set` | data/anim/press_styles.json: every key of a style\'s `set.pose` is a fighter of fighters.json and every pose id is a pose of poses.json or of a wave |');
    fs.writeFileSync(f, lines.join('\n'));
  }
}
