// Schema key for Animation's zip pass under the rival (docs/animation; Animation's zip build): data/anim/zip.json `pass` gains an optional third key,
// `under` (an entry name: the same shape and the same zip-entry cross-check as `over` and `round`). `over` and `round` stay required inside `pass`.
// It also adds an optional top-level closed `pass_depth` {z (number, 0 to 60), ticks (integer, 1 to 8)} (both required inside it): how far toward the
// camera the zipper's drawn root comes during a pass, render-only; and, from the tree's data/anim/zip.json as it stands (Animation's zip view keys,
// docs/animation/zip.md sections 10 and 15; the shape may still move):
//   ends     optional, closed: done, stopped, outrun, countered, caught, shot, down (each optional), each {blend (integer, 0 to 12; required),
//            overcommit (boolean)}: how the body leaves a zip
//   arrival  optional, closed: {settle (number, 0 to 1; required)}: the zipper stands in his arrival, the travel pose settled toward the tell
//   dropped  optional, closed: {land_w (number, 0 to 1), tech (a record of the sim's word on drop_end to a pose or sequence id)}; both required
//            inside it. Rule zip-dropped: every tech value is a pose or a sequence of data/anim (poses.json and the wave files)
// NOT run by CI, the validator or the sim. Run once from the repo root, in the commit that lands Animation's zip build (after apply-anim-zip2.cjs,
// applied, and Encounter's zip commit):
//     node docs/tools/pending/apply-anim-zip-under.cjs
// It does NOT edit data/. The earlier case that named `under` as an unknown key of `pass` (anim-zip-pass-unknown-key) is changed to name another.
// Every new case sets its own whole `pass`. Re-runnable (a second run changes nothing).
const fs = require('fs');
const closed = { additionalProperties: false, patternProperties: { '^_': true } };
const rj = (f) => JSON.parse(fs.readFileSync(f, 'utf8'));
const wj = (f, o) => fs.writeFileSync(f, JSON.stringify(o, null, 2) + '\n');

// =============================== schema ===============================
{
  const f = 'tools/schemas/anim-zip.schema.json';
  const s = rj(f);
  const pass = s.properties.pass;
  if (!pass.properties.under) {
    pass.properties.under = { description: 'The entry a zip under the rival plays (optional).', type: 'string', pattern: '^[a-z][a-z0-9_]*$' };
    wj(f, s);
  }
  if (!s.properties.ends) {
    const row = Object.assign({ type: 'object', required: ['blend'], properties: { blend: { type: 'integer', minimum: 0, maximum: 12, description: 'Ticks the last zip pose is blended away over (0 leaves it to the next layer).' }, overcommit: { type: 'boolean', description: 'Carry the zipper past, off balance, as a whiff does.' } } }, closed);
    const ENDS = ['done', 'stopped', 'outrun', 'countered', 'caught', 'shot', 'down'];
    const views = {
      ends: Object.assign({ type: 'object', properties: Object.fromEntries(ENDS.map((k) => [k, row])), description: 'Optional. How the body leaves a zip, by the word zip_end carries (docs/animation/zip.md section 15).' }, closed),
      arrival: Object.assign({ type: 'object', required: ['settle'], properties: { settle: { type: 'number', minimum: 0, maximum: 1, description: 'How far the travel pose settles toward the tell pose while the zipper stands in reach.' } }, description: 'Optional. The zipper\'s arrival in reach.' }, closed),
      dropped: Object.assign({ type: 'object', required: ['land_w', 'tech'], properties: { land_w: { type: 'number', minimum: 0, maximum: 1, description: 'The weight of the soft catch when a shot-down zipper reaches the ground.' }, tech: { type: 'object', propertyNames: { pattern: '^(_.*|[a-z][a-z0-9_]*)$' }, additionalProperties: { type: 'string', pattern: '^[a-z][a-z0-9_]*([.][a-z0-9_]+)*$' }, patternProperties: { '^_': true }, description: 'The sim\'s word on drop_end to the pose or sequence it plays (a word with none plays as end).' } }, description: 'Optional. A zipper shot down on his way out (SimFighter.drop).' }, closed),
    };
    const props = {};
    for (const [k, v] of Object.entries(s.properties)) {
      props[k] = v;
      if (k === 'pass_depth') Object.assign(props, views);
    }
    if (!props.ends) Object.assign(props, views);
    s.properties = props;
    wj(f, s);
  }
  if (!s.properties.pass_depth) {
    const props = {};
    for (const [k, v] of Object.entries(s.properties)) {
      props[k] = v;
      if (k === 'pass') {
        props.pass_depth = Object.assign({
          type: 'object',
          required: ['z', 'ticks'],
          properties: {
            z: { type: 'number', minimum: 0, maximum: 60, description: 'How far toward the camera the zipper\'s drawn root comes during a pass (render-only).' },
            ticks: { type: 'integer', minimum: 1, maximum: 8, description: 'The ticks the root takes to come forward (and to go back).' },
          },
          description: 'Optional. How the zipper is drawn in front of the rival on a close pass.',
        }, closed);
      }
    }
    s.properties = props;
    wj(f, s);
  }
}

// =============================== xref ===============================
{
  const f = 'tools/lib/xref-fight.js';
  let t = fs.readFileSync(f, 'utf8');
  if (!t.includes("needEntry(zip.pass.under, '/pass/under')")) {
    const a = "needEntry(zip.pass.round, '/pass/round'); }";
    if (!t.includes(a)) throw new Error('zip pass anchor');
    t = t.replace(a, () => "needEntry(zip.pass.round, '/pass/round'); needEntry(zip.pass.under, '/pass/under'); }");
    fs.writeFileSync(f, t);
  }
  t = fs.readFileSync(f, 'utf8');
  if (!t.includes("'zip-dropped'")) {
    const a = "needEntry(zip.pass.under, '/pass/under'); }";
    if (!t.includes(a)) throw new Error('zip dropped anchor');
    t = t.replace(a, () => [
      a,
      "    if (isObj(zip.dropped) && isObj(zip.dropped.tech)) {",
      "      const known = new Set();",
      "      const mainP = get('data/anim/poses.json');",
      "      if (isObj(mainP) && isObj(mainP.poses)) Object.keys(mainP.poses).forEach((k) => known.add(k));",
      "      for (const rel of docsFor(/^data\\/anim\\/waves\\/[^/]+\\.poses\\.json$/)) { const d = get(rel); if (isObj(d) && isObj(d.poses)) Object.keys(d.poses).forEach((k) => known.add(k)); }",
      "      for (const rel of docsFor(/^data\\/anim\\/waves\\/[^/]+\\.sequences\\.json$/)) { const d = get(rel); if (isObj(d) && isObj(d.sequences)) Object.keys(d.sequences).forEach((k) => known.add(k)); }",
      "      if (known.size) for (const [w, id] of Object.entries(zip.dropped.tech)) if (!w.startsWith('_') && typeof id === 'string' && !known.has(id)) err(ZP, `/dropped/tech/${esc(w)}`, 'zip-dropped', `\"${id}\" is neither a pose nor a sequence of data/anim`);",
      "    }",
    ].join('\n'));
    fs.writeFileSync(f, t);
  }
}

// =============================== cases ===============================
{
  const cf = 'tools/fixtures/cases.json';
  const c = rj(cf);
  const Z = 'data/anim/zip.json';
  const zx = (n, mut, expect) => ({ id: 'anim-zip-' + n, schema: 'anim-zip.schema.json', mutate: [{ file: Z, ...mut }], expect });
  const add = [
    // the earlier case now names a key that is still unknown
    zx('pass-unknown-key', { set: { '/pass': { over: 'dash', round: 'arc_dive', beneath: 'skid' } } }, { rule: 'additionalProperties', pointer: '/pass/beneath' }),
    zx('pass-under-ok', { set: { '/pass': { over: 'dash', round: 'arc_dive', under: 'skid' } } }, null),
    zx('pass-without-under-ok', { set: { '/pass': { over: 'dash', round: 'arc_dive' } } }, null),
    zx('pass-under-shape', { set: { '/pass': { over: 'dash', round: 'arc_dive', under: 'Skid' } } }, { rule: 'pattern', pointer: '/pass/under' }),
    zx('pass-under-type', { set: { '/pass': { over: 'dash', round: 'arc_dive', under: 5 } } }, { rule: 'type', pointer: '/pass/under' }),
    zx('pass-under-unknown', { set: { '/pass': { over: 'dash', round: 'arc_dive', under: 'nowhere' } } }, { rule: 'xref:zip-entry', pointer: '/pass/under' }),
    zx('pass-under-alone-is-not-enough', { set: { '/pass': { under: 'skid' } } }, { rule: 'required', pointer: '/pass' }),
    zx('pass-over-still-required', { set: { '/pass': { round: 'arc_dive', under: 'skid' } } }, { rule: 'required', pointer: '/pass' }),
    zx('pass-round-still-required', { set: { '/pass': { over: 'dash', under: 'skid' } } }, { rule: 'required', pointer: '/pass' }),
    zx('pass-depth-ok', { set: { '/pass_depth': { z: 24, ticks: 3 } } }, null),
    zx('pass-depth-fraction-ok', { set: { '/pass_depth': { z: 24.5, ticks: 3 } } }, null),
    zx('pass-depth-edges-ok', { set: { '/pass_depth': { z: 0, ticks: 1 } } }, null),
    zx('pass-depth-far-edges-ok', { set: { '/pass_depth': { z: 60, ticks: 8 } } }, null),
    zx('pass-depth-note-ok', { set: { '/pass_depth': { z: 24, ticks: 3, _why: 'comment' } } }, null),
    zx('pass-depth-type', { set: { '/pass_depth': 24 } }, { rule: 'type', pointer: '/pass_depth' }),
    zx('pass-depth-z-required', { set: { '/pass_depth': { ticks: 3 } } }, { rule: 'required', pointer: '/pass_depth' }),
    zx('pass-depth-ticks-required', { set: { '/pass_depth': { z: 24 } } }, { rule: 'required', pointer: '/pass_depth' }),
    zx('pass-depth-unknown-key', { set: { '/pass_depth': { z: 24, ticks: 3, y: 1 } } }, { rule: 'additionalProperties', pointer: '/pass_depth/y' }),
    zx('pass-depth-z-negative', { set: { '/pass_depth': { z: -1, ticks: 3 } } }, { rule: 'minimum', pointer: '/pass_depth/z' }),
    zx('pass-depth-z-above-sixty', { set: { '/pass_depth': { z: 60.5, ticks: 3 } } }, { rule: 'maximum', pointer: '/pass_depth/z' }),
    zx('pass-depth-z-type', { set: { '/pass_depth': { z: 'near', ticks: 3 } } }, { rule: 'type', pointer: '/pass_depth/z' }),
    zx('pass-depth-ticks-zero', { set: { '/pass_depth': { z: 24, ticks: 0 } } }, { rule: 'minimum', pointer: '/pass_depth/ticks' }),
    zx('pass-depth-ticks-nine', { set: { '/pass_depth': { z: 24, ticks: 9 } } }, { rule: 'maximum', pointer: '/pass_depth/ticks' }),
    zx('pass-depth-ticks-integer', { set: { '/pass_depth': { z: 24, ticks: 3.5 } } }, { rule: 'type', pointer: '/pass_depth/ticks' }),
    zx('ends-ok', { set: { '/ends': { done: { blend: 4 }, stopped: { blend: 4 }, outrun: { blend: 6, overcommit: true }, countered: { blend: 2 }, caught: { blend: 2 }, shot: { blend: 2 }, down: { blend: 0 } } } }, null),
    zx('ends-empty-ok', { set: { '/ends': {} } }, null),
    zx('ends-one-row-ok', { set: { '/ends': { done: { blend: 3 } } } }, null),
    zx('ends-type', { set: { '/ends': 4 } }, { rule: 'type', pointer: '/ends' }),
    zx('ends-unknown-word', { set: { '/ends': { done: { blend: 4 }, lost: { blend: 4 } } } }, { rule: 'additionalProperties', pointer: '/ends/lost' }),
    zx('ends-note-ok', { set: { '/ends': { done: { blend: 4 }, _why: 'a note' } } }, null),
    zx('ends-row-blend-required', { set: { '/ends': { done: { overcommit: true } } } }, { rule: 'required', pointer: '/ends/done' }),
    zx('ends-row-unknown-key', { set: { '/ends': { done: { blend: 4, mood: 1 } } } }, { rule: 'additionalProperties', pointer: '/ends/done/mood' }),
    zx('ends-blend-negative', { set: { '/ends': { done: { blend: -1 } } } }, { rule: 'minimum', pointer: '/ends/done/blend' }),
    zx('ends-blend-above-twelve', { set: { '/ends': { done: { blend: 13 } } } }, { rule: 'maximum', pointer: '/ends/done/blend' }),
    zx('ends-blend-integer', { set: { '/ends': { done: { blend: 4.5 } } } }, { rule: 'type', pointer: '/ends/done/blend' }),
    zx('ends-blend-edges-ok', { set: { '/ends': { done: { blend: 0 }, stopped: { blend: 12 } } } }, null),
    zx('ends-overcommit-type', { set: { '/ends': { outrun: { blend: 6, overcommit: 'yes' } } } }, { rule: 'type', pointer: '/ends/outrun/overcommit' }),
    zx('arrival-ok', { set: { '/arrival': { settle: 0.4 } } }, null),
    zx('arrival-edges-ok', { set: { '/arrival': { settle: 0 } } }, null),
    zx('arrival-one-ok', { set: { '/arrival': { settle: 1 } } }, null),
    zx('arrival-settle-required', { set: { '/arrival': {} } }, { rule: 'required', pointer: '/arrival' }),
    zx('arrival-settle-negative', { set: { '/arrival': { settle: -0.1 } } }, { rule: 'minimum', pointer: '/arrival/settle' }),
    zx('arrival-settle-above-one', { set: { '/arrival': { settle: 1.1 } } }, { rule: 'maximum', pointer: '/arrival/settle' }),
    zx('arrival-settle-type', { set: { '/arrival': { settle: 'half' } } }, { rule: 'type', pointer: '/arrival/settle' }),
    zx('arrival-unknown-key', { set: { '/arrival': { settle: 0.4, mood: 1 } } }, { rule: 'additionalProperties', pointer: '/arrival/mood' }),
    zx('dropped-ok', { set: { '/dropped': { land_w: 0.35, tech: { recover: 'gc.tech_flip', tech: 'gc.tech_flip' } } } }, null),
    zx('dropped-empty-tech-ok', { set: { '/dropped': { land_w: 0.35, tech: {} } } }, null),
    zx('dropped-land-w-required', { set: { '/dropped': { tech: {} } } }, { rule: 'required', pointer: '/dropped' }),
    zx('dropped-tech-required', { set: { '/dropped': { land_w: 0.35 } } }, { rule: 'required', pointer: '/dropped' }),
    zx('dropped-unknown-key', { set: { '/dropped': { land_w: 0.35, tech: {}, mood: 1 } } }, { rule: 'additionalProperties', pointer: '/dropped/mood' }),
    zx('dropped-land-w-above-one', { set: { '/dropped': { land_w: 1.5, tech: {} } } }, { rule: 'maximum', pointer: '/dropped/land_w' }),
    zx('dropped-land-w-negative', { set: { '/dropped': { land_w: -0.1, tech: {} } } }, { rule: 'minimum', pointer: '/dropped/land_w' }),
    zx('dropped-land-w-type', { set: { '/dropped': { land_w: 'soft', tech: {} } } }, { rule: 'type', pointer: '/dropped/land_w' }),
    zx('dropped-tech-word-shape', { set: { '/dropped': { land_w: 0.35, tech: { 'Drop End': 'gc.tech_flip' } } } }, { rule: 'propertyNames', pointer: '/dropped/tech/Drop End' }),
    zx('dropped-tech-id-shape', { set: { '/dropped': { land_w: 0.35, tech: { tech: 'GC Tech Flip' } } } }, { rule: 'pattern', pointer: '/dropped/tech/tech' }),
    zx('dropped-tech-id-type', { set: { '/dropped': { land_w: 0.35, tech: { tech: 5 } } } }, { rule: 'type', pointer: '/dropped/tech/tech' }),
    zx('dropped-tech-names-no-pose', { set: { '/dropped': { land_w: 0.35, tech: { tech: 'gc.nowhere' } } } }, { rule: 'xref:zip-dropped', pointer: '/dropped/tech/tech' }),
    zx('pass-under-with-a-note-ok', { set: { '/pass': { over: 'dash', round: 'arc_dive', under: 'skid', _why: 'comment' } } }, null),
  ];
  let n = 0;
  for (const k of add) {
    const i = c.cases.findIndex((y) => y.id === k.id);
    if (i < 0) { c.cases.push(k); n++; } else if (JSON.stringify(c.cases[i]) !== JSON.stringify(k)) { c.cases[i] = k; n++; }
  }
  wj(cf, c);
  console.log(`zip pass under applied (${n} new or changed cases)`);
}
