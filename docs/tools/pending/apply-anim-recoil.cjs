// The closed schema for Animation's data/anim/recoil.json (anim.recoil/1: the recoil exits and ricochets, docs/combat/choreography-feel.md sections 1 and 2; parked in docs/animation/pending/recoil-flips.patch):
// tools/schemas/anim-recoil.schema.json, its map.json rule, the cross-references and the cases. Run once from the repo root, in the commit that lands the file (a schema with no document fails the
// data job's coverage check, so it refuses until data/anim/recoil.json is in the tree):
//     node docs/tools/pending/apply-anim-recoil.cjs
// Policy: closed except keys starting with an underscore. pivot_y 0 to 100 (the height of the turning point above the feet); kinds: the six exits (skip, handspring, tuck, backflip, ricochet_wall,
// ricochet_ground), each { seq, turns (whole, 0 to 3), arc (0 to 60: DirRecoil's own bow is 60), plant (optional, 0 to 1, a ricochet's) }; fighters: a roster id's own sequence for a kind.
// Cross-references: anim-recoil-seq (every sequence named exists in a wave's sequences), anim-recoil-fighter (each kind a fighter names is a kind of kinds; a fighters key must look like a roster id, upper-case, but the roster is not read: the self-test's roster is a fixture).
// Re-runnable. Not run by CI or the validator.
const fs = require('fs');
const rj = (f) => JSON.parse(fs.readFileSync(f, 'utf8'));
const wj = (f, o) => fs.writeFileSync(f, JSON.stringify(o, null, 2) + '\n');
const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);
const F = 'data/anim/recoil.json', SF = 'tools/schemas/anim-recoil.schema.json';
if (!fs.existsSync(F)) { console.error(`${F} is not in the tree yet: run this in the commit that lands it`); process.exit(1); }
const KINDS = ['skip', 'handspring', 'tuck', 'backflip', 'ricochet_wall', 'ricochet_ground'];
const SEQ = '^[a-z][a-z0-9_]*([.][a-z0-9_]+)*$';
const closed = { additionalProperties: false, patternProperties: { '^_': true } };
const seq = (d) => ({ type: 'string', pattern: SEQ, description: d });

{
  const kind = {
    type: 'object', required: ['seq', 'turns', 'arc'],
    properties: {
      seq: seq('The sequence the exit plays (a sequence of a wave: rule anim-recoil-seq).'),
      turns: { type: 'integer', minimum: 0, maximum: 3, description: 'Whole turns backward over the exit (a flip is 1; a skip or a ricochet 0).' },
      arc: { type: 'number', minimum: 0, maximum: 60, description: 'The height the body\'s middle rises on top of the sim\'s path, in units (DirRecoil\'s own bow is 60).' },
      plant: { type: 'number', minimum: 0, maximum: 1, description: 'A ricochet: how far through the exit the feet meet the surface, 0 to 1.' },
    },
    ...closed,
  };
  const s = {
    $schema: 'https://json-schema.org/draft/2020-12/schema', $id: 'meridian/anim-recoil', title: 'anim.recoil/1',
    description: "data/anim/recoil.json: the recoil exits and ricochets (docs/combat/choreography-feel.md sections 1 and 2; AnimFighter.on_recoil and _recoil_layer): the kind's sequence, the turns, the arc, and a roster id's own sequence for a kind. Render only, outside the sim's data hash. Version field: schema. Policy: closed except keys starting with an underscore. Cross-references in tools/lib/xref-fight.js (anim-recoil-seq: every sequence named exists; anim-recoil-fighter: each kind a fighter names is a kind of kinds).",
    type: 'object', required: ['schema', 'pivot_y', 'kinds', 'fighters'],
    properties: {
      schema: { const: 'anim.recoil/1' },
      pivot_y: { type: 'number', minimum: 0, maximum: 100, description: 'The height of the turning point above the feet, in units.' },
      kinds: { type: 'object', required: KINDS, properties: Object.fromEntries(KINDS.map((k) => [k, kind])), ...closed, description: 'The six exits.' },
      fighters: { type: 'object', propertyNames: { pattern: '^(_.*|[A-Z][A-Z0-9_]*)$' }, additionalProperties: { type: 'object', propertyNames: { pattern: '^[a-z_]+$' }, additionalProperties: seq("A roster id's own sequence for this kind."), description: 'Kind to sequence.' }, patternProperties: { '^_': true }, description: 'A roster id to its own sequences, by kind.' },
    },
    ...closed,
  };
  if (fs.existsSync(SF) && same(rj(SF), s)) console.log('schema: already'); else { wj(SF, s); console.log('schema: written'); }
}
{
  const mf = 'tools/schemas/map.json';
  const m = rj(mf);
  if (m.rules.some((r) => r.match === F)) console.log('map: already');
  else { const i = m.rules.findIndex((r) => r.match === 'data/anim/guard_pass.json'); m.rules.splice(i < 0 ? m.rules.length : i + 1, 0, { match: F, schema: 'anim-recoil.schema.json' }); wj(mf, m); console.log('map: rule added'); }
}
{
  const f = 'tools/lib/xref-fight.js';
  let t = fs.readFileSync(f, 'utf8');
  const crlf = t.includes('\r\n');
  if (crlf) t = t.split('\r\n').join('\n');
  if (t.includes('anim-recoil-seq')) console.log('xref: already');
  else {
    const a = '    const thr = get(\'data/anim/throws.json\');';
    if (!t.includes(a)) throw new Error('xref anchor (the parked anim data block is not in the tree)');
    const block = [
      "    const rcl = get('data/anim/recoil.json');",
      "    if (isObj(rcl)) {",
      "      const RC = 'data/anim/recoil.json';",
      "      const okSeq = (id) => !seqsP.size || seqsP.has(id);",
      "      if (isObj(rcl.kinds)) for (const [k, v] of Object.entries(rcl.kinds)) if (!k.startsWith('_') && isObj(v) && typeof v.seq === 'string' && !okSeq(v.seq)) err(RC, `/kinds/${esc(k)}/seq`, 'anim-recoil-seq', `sequence \"${v.seq}\" is not a sequence of any wave`);",
      "      if (isObj(rcl.fighters)) for (const [who, ks] of Object.entries(rcl.fighters)) {",
      "        if (who.startsWith('_') || !isObj(ks)) continue;",
      "        for (const [k, id] of Object.entries(ks)) {",
      "          if (k.startsWith('_')) continue;",
      "          if (!isObj(rcl.kinds) || !(k in rcl.kinds)) err(RC, `/fighters/${esc(who)}/${esc(k)}`, 'anim-recoil-fighter', `${who} names the kind \"${k}\", which is not a kind of kinds`);",
      "          if (typeof id === 'string' && !okSeq(id)) err(RC, `/fighters/${esc(who)}/${esc(k)}`, 'anim-recoil-seq', `sequence \"${id}\" is not a sequence of any wave`);",
      "        }",
      "      }",
      "    }",
      "",
    ].join('\n');
    t = t.replace(a, () => block + a);
    fs.writeFileSync(f, crlf ? t.split('\n').join('\r\n') : t);
    console.log('xref: recoil rules added');
  }
}
{
  const cf = 'tools/fixtures/cases.json';
  const c = rj(cf);
  const out = [];
  const cs = (id, mutate, expect) => out.push({ id: 'anim-recoil-' + id, schema: 'anim-recoil.schema.json', mutate: [{ file: F, ...mutate }], expect });
  cs('valid', { set: { '/schema': 'anim.recoil/1' } }, null);
  for (const k of ['schema', 'pivot_y', 'kinds', 'fighters']) cs('key-required-' + k.replace(/_/g, '-'), { del: ['/' + k] }, { rule: 'required', pointer: '' });
  cs('unknown-key', { set: { '/extra': 1 } }, { rule: 'additionalProperties', pointer: '/extra' });
  cs('underscore-key-ok', { set: { '/_why': 'a note' } }, null);
  cs('schema-version', { set: { '/schema': 'anim.recoil/2' } }, { rule: 'const', pointer: '/schema' });
  cs('pivot-over-100', { set: { '/pivot_y': 150 } }, { rule: 'maximum', pointer: '/pivot_y' });
  cs('kind-missing', { del: ['/kinds/tuck'] }, { rule: 'required', pointer: '/kinds' });
  cs('kind-unknown', { set: { '/kinds/cartwheel': { seq: 'rc.skip', turns: 0, arc: 3 } } }, { rule: 'additionalProperties', pointer: '/kinds/cartwheel' });
  cs('kind-key-missing', { del: ['/kinds/skip/arc'] }, { rule: 'required', pointer: '/kinds/skip' });
  cs('turns-fraction', { set: { '/kinds/tuck/turns': 1.5 } }, { rule: 'type', pointer: '/kinds/tuck/turns' });
  cs('turns-over-three', { set: { '/kinds/tuck/turns': 5 } }, { rule: 'maximum', pointer: '/kinds/tuck/turns' });
  cs('arc-negative', { set: { '/kinds/skip/arc': -1 } }, { rule: 'minimum', pointer: '/kinds/skip/arc' });
  cs('plant-over-one', { set: { '/kinds/ricochet_wall/plant': 1.5 } }, { rule: 'maximum', pointer: '/kinds/ricochet_wall/plant' });
  cs('seq-shape', { set: { '/kinds/skip/seq': 'Skip It' } }, { rule: 'pattern', pointer: '/kinds/skip/seq' });
  cs('seq-missing', { set: { '/kinds/skip/seq': 'rc.no_such_sequence' } }, { rule: 'xref:anim-recoil-seq', pointer: '/kinds/skip/seq' });
  cs('fighter-seq-missing', { set: { '/fighters/RIVAL/backflip': 'rc.no_such_sequence' } }, { rule: 'xref:anim-recoil-seq', pointer: '/fighters/RIVAL/backflip' });
  cs('fighter-key-not-an-id', { set: { '/fighters/ghost': { backflip: 'rc.backflip_tuck' } } }, { rule: 'propertyNames', pointer: '/fighters/ghost' });
  cs('fighter-kind-unknown', { set: { '/fighters/RIVAL/cartwheel': 'rc.backflip_tuck' } }, { rule: 'xref:anim-recoil-fighter', pointer: '/fighters/RIVAL/cartwheel' });
  let n = 0;
  for (const k of out) {
    const i = c.cases.findIndex((y) => y.id === k.id);
    if (i >= 0) { if (!same(c.cases[i], k)) { c.cases[i] = k; n++; } } else { c.cases.splice(Math.max(0, c.cases.length - 1), 0, k); n++; }
  }
  if (n) wj(cf, c);
  console.log(`cases: ${n} new or changed`);
}
