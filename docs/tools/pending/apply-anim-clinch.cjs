// The closed schema for Animation's data/anim/clinch.json (anim.clinch/1: the clinch's grip layer, docs/animation/clinch-sizing.md slice C2; parked in docs/animation/pending/grip-layer.patch):
// tools/schemas/anim-clinch.schema.json, its map.json rule, the cross-references and the cases. Run once from the repo root, in the commit that lands the file (a schema with no document fails the
// data job's coverage check, so it refuses until data/anim/clinch.json and the wave cl1 are in the tree):
//     node docs/tools/pending/apply-anim-clinch.cjs
// Policy: closed except keys starting with an underscore. poses: the twelve kinds of a hold's read (reach, seat, ahead, behind, pummel_l, pummel_r, brace, pin, carry, strain, whiff, apart), each a
// pose or sequence id; held_poses: the pose the held body takes for a kind (a kind of poses); ramp_ticks 1 to 60; gap_budget 0 to 20 (how many ticks of gap the layer closes); hand_back 0 to 1;
// depth_offset 0 to 30 units. Cross-references: anim-clinch-pose (every pose named exists in poses.json or a wave), anim-clinch-held (every held_poses key is a kind of poses).
// Re-runnable. Not run by CI or the validator.
const fs = require('fs');
const rj = (f) => JSON.parse(fs.readFileSync(f, 'utf8'));
const wj = (f, o) => fs.writeFileSync(f, JSON.stringify(o, null, 2) + '\n');
const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);
const F = 'data/anim/clinch.json', SF = 'tools/schemas/anim-clinch.schema.json';
if (!fs.existsSync(F)) { console.error(`${F} is not in the tree yet: run this in the commit that lands it`); process.exit(1); }
const data = rj(F);
const KINDS = ['reach', 'seat', 'ahead', 'behind', 'pummel_l', 'pummel_r', 'brace', 'pin', 'carry', 'strain', 'whiff', 'apart'];
const POSE = '^[a-z][a-z0-9_]*([.][a-z0-9_]+)*$';
const closed = { additionalProperties: false, patternProperties: { '^_': true } };
const pose = (d) => ({ type: 'string', pattern: POSE, description: d });

{
  const s = {
    $schema: 'https://json-schema.org/draft/2020-12/schema', $id: 'meridian/anim-clinch', title: 'anim.clinch/1',
    description: "data/anim/clinch.json: the clinch's grip layer (docs/animation/clinch-sizing.md, slice C2; AnimFighter._grip_layer): the sim's hold arrives as a read (partner, kind, role, grade, side) and the layer mixes these poses in. Render only, outside the sim's data hash. Version field: schema. Policy: closed except keys starting with an underscore. Cross-references in tools/lib/xref-fight.js (anim-clinch-pose: every pose named exists; anim-clinch-held: every held_poses key is a kind of poses).",
    type: 'object', required: ['schema', 'poses', 'held_poses', 'ramp_ticks', 'gap_budget', 'hand_back', 'depth_offset'],
    properties: {
      schema: { const: 'anim.clinch/1' },
      poses: { type: 'object', required: KINDS, properties: Object.fromEntries(KINDS.map((k) => [k, pose(`The pose of a hold's read "${k}" (a real pose: rule anim-clinch-pose).`)])), ...closed, description: 'The pose of each kind of a hold.' },
      held_poses: { type: 'object', propertyNames: { pattern: '^(_.*|[a-z][a-z0-9_]*)$' }, additionalProperties: pose('The pose the held body takes for this kind.'), patternProperties: { '^_': true }, description: 'The pose the held (pinned) body takes, by kind (each key a kind of poses: rule anim-clinch-held).' },
      ramp_ticks: { type: 'integer', minimum: 1, maximum: 60, description: 'Ticks the layer takes to mix a pose in.' },
      gap_budget: { type: 'number', minimum: 0, maximum: 20, description: 'How much of the gap between the pair the layer may close, in body units.' },
      hand_back: { type: 'number', minimum: 0, maximum: 1, description: 'How far the hand comes back toward the guard when the hold ends, 0 to 1.' },
      depth_offset: { type: 'number', minimum: 0, maximum: 30, description: 'How far the holder stands off in depth, in units.' },
    },
    ...closed,
  };
  if (fs.existsSync(SF) && same(rj(SF), s)) console.log('schema: already'); else { wj(SF, s); console.log('schema: written'); }
}
{
  const mf = 'tools/schemas/map.json';
  const m = rj(mf);
  if (m.rules.some((r) => r.match === F)) console.log('map: already');
  else { const i = m.rules.findIndex((r) => r.match === 'data/anim/guard_pass.json'); m.rules.splice(i < 0 ? m.rules.length : i + 1, 0, { match: F, schema: 'anim-clinch.schema.json' }); wj(mf, m); console.log('map: rule added'); }
}
{
  const f = 'tools/lib/xref-fight.js';
  let t = fs.readFileSync(f, 'utf8');
  const crlf = t.includes('\r\n');
  if (crlf) t = t.split('\r\n').join('\n');
  if (t.includes('anim-clinch-pose')) console.log('xref: already');
  else {
    const a = '    const thr = get(\'data/anim/throws.json\');';
    if (!t.includes(a)) throw new Error('xref anchor (the parked anim data block is not in the tree)');
    const block = [
      "    const cli = get('data/anim/clinch.json');",
      "    if (isObj(cli)) {",
      "      const CL = 'data/anim/clinch.json';",
      "      const ok = (id) => !posesP.size || posesP.has(id) || seqsP.has(id);",
      "      if (isObj(cli.poses)) for (const [k, id] of Object.entries(cli.poses)) if (!k.startsWith('_') && typeof id === 'string' && !ok(id)) err(CL, `/poses/${esc(k)}`, 'anim-clinch-pose', `pose \"${id}\" is neither a pose nor a sequence of any wave`);",
      "      if (isObj(cli.held_poses)) for (const [k, id] of Object.entries(cli.held_poses)) {",
      "        if (k.startsWith('_')) continue;",
      "        if (!isObj(cli.poses) || !(k in cli.poses)) err(CL, `/held_poses/${esc(k)}`, 'anim-clinch-held', `held_poses names the kind \"${k}\", which is not a kind of poses`);",
      "        if (typeof id === 'string' && !ok(id)) err(CL, `/held_poses/${esc(k)}`, 'anim-clinch-pose', `pose \"${id}\" is neither a pose nor a sequence of any wave`);",
      "      }",
      "    }",
      "",
    ].join('\n');
    t = t.replace(a, () => block + a);
    fs.writeFileSync(f, crlf ? t.split('\n').join('\r\n') : t);
    console.log('xref: clinch rules added');
  }
}
{
  const cf = 'tools/fixtures/cases.json';
  const c = rj(cf);
  const out = [];
  const cs = (id, mutate, expect) => out.push({ id: 'anim-clinch-' + id, schema: 'anim-clinch.schema.json', mutate: [{ file: F, ...mutate }], expect });
  cs('valid', { set: { '/schema': 'anim.clinch/1' } }, null);
  for (const k of ['schema', 'poses', 'held_poses', 'ramp_ticks', 'gap_budget', 'hand_back', 'depth_offset']) cs('key-required-' + k.replace(/_/g, '-'), { del: ['/' + k] }, { rule: 'required', pointer: '' });
  cs('unknown-key', { set: { '/extra': 1 } }, { rule: 'additionalProperties', pointer: '/extra' });
  cs('underscore-key-ok', { set: { '/_why': 'a note' } }, null);
  cs('schema-version', { set: { '/schema': 'anim.clinch/2' } }, { rule: 'const', pointer: '/schema' });
  cs('kind-missing', { del: ['/poses/pin'] }, { rule: 'required', pointer: '/poses' });
  cs('kind-unknown', { set: { '/poses/choke': 'cl.hold.pin' } }, { rule: 'additionalProperties', pointer: '/poses/choke' });
  cs('pose-shape', { set: { '/poses/seat': 'Seat It' } }, { rule: 'pattern', pointer: '/poses/seat' });
  cs('pose-missing', { set: { '/poses/seat': 'cl.hold.no_such_pose' } }, { rule: 'xref:anim-clinch-pose', pointer: '/poses/seat' });
  cs('held-kind-unknown', { set: { '/held_poses/choke': 'cl.hold.pin_brace' } }, { rule: 'xref:anim-clinch-held', pointer: '/held_poses/choke' });
  cs('held-pose-missing', { set: { '/held_poses/pin': 'cl.hold.no_such_pose' } }, { rule: 'xref:anim-clinch-pose', pointer: '/held_poses/pin' });
  cs('ramp-zero', { set: { '/ramp_ticks': 0 } }, { rule: 'minimum', pointer: '/ramp_ticks' });
  cs('ramp-fraction', { set: { '/ramp_ticks': 2.5 } }, { rule: 'type', pointer: '/ramp_ticks' });
  cs('gap-negative', { set: { '/gap_budget': -1 } }, { rule: 'minimum', pointer: '/gap_budget' });
  cs('hand-back-over-one', { set: { '/hand_back': 1.5 } }, { rule: 'maximum', pointer: '/hand_back' });
  cs('depth-offset-negative', { set: { '/depth_offset': -2 } }, { rule: 'minimum', pointer: '/depth_offset' });
  void data;
  let n = 0;
  for (const k of out) {
    const i = c.cases.findIndex((y) => y.id === k.id);
    if (i >= 0) { if (!same(c.cases[i], k)) { c.cases[i] = k; n++; } } else { c.cases.splice(Math.max(0, c.cases.length - 1), 0, k); n++; }
  }
  if (n) wj(cf, c);
  console.log(`cases: ${n} new or changed`);
}
