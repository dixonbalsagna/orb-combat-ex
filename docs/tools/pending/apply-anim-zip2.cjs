// Schema keys for Animation's wave 1 (the zip's entries and the push style). NOT run by CI, the validator or the sim. Run once from the repo
// root, in the commit that lands the data:
//     node docs/tools/pending/apply-anim-zip2.cjs
// It does NOT edit data/. All the keys are optional. It adds:
//   data/anim/zip.json          readings.<r>.entry_in and entry_out (optional entry names) and the optional top-level `pass` {over, round} (entry names)
//   data/anim/press_styles.json styles.push (an optional fourth style row of the shape of tech, speed and heavy) and the optional top-level
//                               `guard` {pose, bones[], weight 0 to 1} (all three required inside it)
// Cross-checks: an entry name is the `name` of a row of an entrymap in data/anim/waves (zip-entry); the guard's pose is a pose and its bones are
// bones without a side whose `_l` and `_r` are both in profiles.json bone_lag (the render adds the guard arm's side) (pressstyles-pose, pressstyles-bone). Every case sets its own values. Re-runnable (a second run changes nothing).
// `read` still names tech, speed and heavy only: tell me if the push style may be read too.
const fs = require('fs');
const rj = (f) => JSON.parse(fs.readFileSync(f, 'utf8'));
const wj = (f, o) => fs.writeFileSync(f, JSON.stringify(o, null, 2) + '\n');
const closed = { additionalProperties: false, patternProperties: { '^_': true } };
const obj = (props, opts = {}) => Object.assign({ type: 'object', required: opts.required === undefined ? Object.keys(props) : opts.required, properties: props }, opts.description ? { description: opts.description } : {}, closed);
const entryName = { type: 'string', pattern: '^[a-z][a-z0-9_]*$' };
const clone = (o) => JSON.parse(JSON.stringify(o));

// =============================== zip schema ===============================
{
  const f = 'tools/schemas/anim-zip.schema.json';
  const s = rj(f);
  const rp = s.properties.readings.additionalProperties.properties;
  if (!rp.entry_in) {
    rp.entry_in = Object.assign({ description: 'The entry (a `name` of an entrymap row) the zip\'s way in plays.' }, entryName);
    rp.entry_out = Object.assign({ description: 'The entry the zip\'s way out plays.' }, entryName);
    s.properties.pass = obj({
      over: Object.assign({ description: 'The entry a zip over the rival plays.' }, entryName),
      round: Object.assign({ description: 'The entry a zip round the rival plays.' }, entryName),
    }, { description: 'The entries a zip past the rival plays.' });
    wj(f, s);
  }
}

// =============================== press styles schema ===============================
{
  const f = 'tools/schemas/anim-press-styles.schema.json';
  const s = rj(f);
  if (!s.properties.guard) {
    const st = s.properties.styles;
    if (!st.properties.push) st.properties.push = clone(st.properties.tech);
    const props = {};
    for (const k of Object.keys(s.properties)) {
      props[k] = s.properties[k];
      if (k === 'squash_pose') props.guard = obj({
        pose: { type: 'string', pattern: '^[a-z][a-z0-9_]*([.][a-z0-9_]+)*$', description: 'The pose whose bones the guard takes.' },
        bones: { type: 'array', minItems: 1, uniqueItems: true, items: { type: 'string', pattern: '^[a-z][a-z0-9_]*$' }, description: 'The bones the guard takes from its pose.' },
        weight: { type: 'number', minimum: 0, maximum: 1, description: 'How much of the pose the guard takes.' },
      }, { description: 'Optional. The guard a styled blow keeps up while it plays.' });
    }
    s.properties = props;
    wj(f, s);
  }
}

// =============================== xref ===============================
{
  const f = 'tools/lib/xref-fight.js';
  let t = fs.readFileSync(f, 'utf8');
  if (!t.includes("'zip-entry'")) {
    // the zip's entry names
    const a = "    const def = blocks.find(([k]) => k === 'default');";
    if (!t.includes(a)) throw new Error('zip anchor');
    t = t.replace(a, () => [
      "    const entryNames = new Set();",
      "    for (const rel of docsFor(/^data\\/anim\\/waves\\/[^/]+\\.entrymap\\.json$/)) { const d = get(rel); if (isObj(d) && Array.isArray(d.entries)) for (const r of d.entries) if (isObj(r) && typeof r.name === 'string') entryNames.add(r.name); }",
      "    const needEntry = (n, at) => { if (entryNames.size && typeof n === 'string' && !entryNames.has(n)) err(ZP, at, 'zip-entry', `\"${n}\" is the name of no entrymap row (${[...entryNames].join(', ')})`); };",
      "    if (isObj(zip.readings)) for (const [rk, r] of Object.entries(zip.readings)) if (!rk.startsWith('_') && isObj(r)) { needEntry(r.entry_in, `/readings/${esc(rk)}/entry_in`); needEntry(r.entry_out, `/readings/${esc(rk)}/entry_out`); }",
      "    if (isObj(zip.pass)) { needEntry(zip.pass.over, '/pass/over'); needEntry(zip.pass.round, '/pass/round'); }",
      a,
    ].join('\n'));
    // the guard's pose and bones
    const b = "    for (const [sid, st] of Object.entries(isObj(pst.styles) ? pst.styles : {})) {";
    if (!t.includes(b)) throw new Error('press styles guard anchor');
    t = t.replace(b, () => [
      "    if (isObj(pst.guard)) {",
      "      needPosePs(pst.guard.pose, '/guard/pose');",
      "      const profG = get('data/anim/profiles.json');",
      "      const bonesG = isObj(profG) && isObj(profG.bone_lag) ? Object.keys(profG.bone_lag) : [];",
      "      if (bonesG.length && Array.isArray(pst.guard.bones)) pst.guard.bones.forEach((bn, i) => { if (typeof bn === 'string' && !(bonesG.includes(bn + '_l') && bonesG.includes(bn + '_r'))) err(PS, `/guard/bones/${i}`, 'pressstyles-bone', `guard bone \"${bn}\" has no _l and _r pair in profiles.json bone_lag (a guard bone is written without its side)`); });",
      "    }",
      b,
    ].join('\n'));
    fs.writeFileSync(f, t);
  }
}

// ---- xref upgrade: a first version of this script checked a guard bone as written, not as a side-less pair ----
{
  const f = 'tools/lib/xref-fight.js';
  let t = fs.readFileSync(f, 'utf8');
  const old = "if (typeof bn === 'string' && !bonesG.includes(bn)) err(PS, `/guard/bones/${i}`, 'pressstyles-bone', `bone \"${bn}\" is not in profiles.json bone_lag`);";
  if (t.includes(old)) {
    t = t.replace(old, () => "if (typeof bn === 'string' && !(bonesG.includes(bn + '_l') && bonesG.includes(bn + '_r'))) err(PS, `/guard/bones/${i}`, 'pressstyles-bone', `guard bone \"${bn}\" has no _l and _r pair in profiles.json bone_lag (a guard bone is written without its side)`);");
    fs.writeFileSync(f, t);
  }
}

// =============================== cases ===============================
{
  const cf = 'tools/fixtures/cases.json';
  const c = rj(cf);
  const Z = 'data/anim/zip.json';
  const P = 'data/anim/press_styles.json';
  const pst = rj(P);
  const tech = clone(pst.styles.tech);
  const zx = (n, mut, expect) => ({ id: 'anim-zip-' + n, schema: 'anim-zip.schema.json', mutate: [{ file: Z, ...mut }], expect });
  const px = (n, mut, expect) => ({ id: 'anim-pressstyles-' + n, schema: 'anim-press-styles.schema.json', mutate: [{ file: P, ...mut }], expect });
  const R = '/readings/speed/';
  const G = '/guard/';
  const guard = { pose: 'brace', bones: ['upper_arm', 'forearm'], weight: 0.5 };
  const add = [
    // ---- zip: entries and pass ----
    zx('entry-in-ok', { set: { [R + 'entry_in']: 'dash' } }, null),
    zx('entry-out-ok', { set: { [R + 'entry_out']: 'hop_back' } }, null),
    zx('entry-in-type', { set: { [R + 'entry_in']: 3 } }, { rule: 'type', pointer: R + 'entry_in' }),
    zx('entry-in-shape', { set: { [R + 'entry_in']: 'Dash' } }, { rule: 'pattern', pointer: R + 'entry_in' }),
    zx('entry-out-shape', { set: { [R + 'entry_out']: 'hop back' } }, { rule: 'pattern', pointer: R + 'entry_out' }),
    zx('entry-in-unknown', { set: { [R + 'entry_in']: 'nowhere' } }, { rule: 'xref:zip-entry', pointer: R + 'entry_in' }),
    zx('entry-out-unknown', { set: { [R + 'entry_out']: 'nowhere' } }, { rule: 'xref:zip-entry', pointer: R + 'entry_out' }),
    zx('entry-in-every-reading-ok', { set: { '/readings/heavy/entry_in': 'rising', '/readings/hold/entry_in': 'skid' } }, null),
    zx('pass-ok', { set: { '/pass': { over: 'dash', round: 'arc_dive' } } }, null),
    zx('pass-key-required', { set: { '/pass': { over: 'dash' } } }, { rule: 'required', pointer: '/pass' }),
    zx('pass-unknown-key', { set: { '/pass': { over: 'dash', round: 'arc_dive', under: 'skid' } } }, { rule: 'additionalProperties', pointer: '/pass/under' }),
    zx('pass-note-ok', { set: { '/pass': { over: 'dash', round: 'arc_dive', _why: 'comment' } } }, null),
    zx('pass-over-shape', { set: { '/pass': { over: 'Dash', round: 'arc_dive' } } }, { rule: 'pattern', pointer: '/pass/over' }),
    zx('pass-over-unknown', { set: { '/pass': { over: 'nowhere', round: 'arc_dive' } } }, { rule: 'xref:zip-entry', pointer: '/pass/over' }),
    zx('pass-round-unknown', { set: { '/pass': { over: 'dash', round: 'nowhere' } } }, { rule: 'xref:zip-entry', pointer: '/pass/round' }),
    zx('pass-type', { set: { '/pass': 'over' } }, { rule: 'type', pointer: '/pass' }),
    // ---- press styles: push and guard ----
    px('push-ok', { set: { '/styles/push': clone(tech) } }, null),
    px('push-key-required', { set: { '/styles/push': (() => { const o = clone(tech); delete o.ghosts; return o; })() } }, { rule: 'required', pointer: '/styles/push' }),
    px('push-unknown-key', { set: { '/styles/push': Object.assign(clone(tech), { sparkle: 1 }) } }, { rule: 'additionalProperties', pointer: '/styles/push/sparkle' }),
    px('push-ghosts-negative', { set: { '/styles/push': Object.assign(clone(tech), { ghosts: -1 }) } }, { rule: 'minimum', pointer: '/styles/push/ghosts' }),
    px('push-squash-range', { set: { '/styles/push': Object.assign(clone(tech), { squash: 2 }) } }, { rule: 'maximum', pointer: '/styles/push/squash' }),
    px('style-unknown-still-rejected', { set: { '/styles/slide': clone(tech) } }, { rule: 'additionalProperties', pointer: '/styles/slide' }),
    px('guard-ok', { set: { '/guard': clone(guard) } }, null),
    px('guard-key-required', { set: { '/guard': { pose: 'brace', bones: ['pelvis'] } } }, { rule: 'required', pointer: '/guard' }),
    px('guard-unknown-key', { set: { '/guard': Object.assign(clone(guard), { extra: 1 }) } }, { rule: 'additionalProperties', pointer: G + 'extra' }),
    px('guard-note-ok', { set: { '/guard': Object.assign(clone(guard), { _why: 'comment' }) } }, null),
    px('guard-pose-shape', { set: { '/guard': Object.assign(clone(guard), { pose: 'Brace' }) } }, { rule: 'pattern', pointer: G + 'pose' }),
    px('guard-pose-unknown', { set: { '/guard': Object.assign(clone(guard), { pose: 'nowhere' }) } }, { rule: 'xref:pressstyles-pose', pointer: G + 'pose' }),
    px('guard-bones-empty', { set: { '/guard': Object.assign(clone(guard), { bones: [] }) } }, { rule: 'minItems', pointer: G + 'bones' }),
    px('guard-bones-duplicate', { set: { '/guard': Object.assign(clone(guard), { bones: ['pelvis', 'pelvis'] }) } }, { rule: 'uniqueItems', pointer: G + 'bones/1' }),
    px('guard-bone-unknown', { set: { '/guard': Object.assign(clone(guard), { bones: ['upper_arm', 'tail_9'] }) } }, { rule: 'xref:pressstyles-bone', pointer: G + 'bones/1' }),
    px('guard-bone-with-a-side', { set: { '/guard': Object.assign(clone(guard), { bones: ['upper_arm_l'] }) } }, { rule: 'xref:pressstyles-bone', pointer: G + 'bones/0' }),
    px('guard-bone-without-a-pair', { set: { '/guard': Object.assign(clone(guard), { bones: ['pelvis'] }) } }, { rule: 'xref:pressstyles-bone', pointer: G + 'bones/0' }),
    px('guard-arm-bones-ok', { set: { '/guard': Object.assign(clone(guard), { bones: ['clavicle', 'upper_arm', 'forearm', 'hand'] }) } }, null),
    px('guard-weight-range', { set: { '/guard': Object.assign(clone(guard), { weight: 1.5 }) } }, { rule: 'maximum', pointer: G + 'weight' }),
    px('guard-weight-negative', { set: { '/guard': Object.assign(clone(guard), { weight: -0.1 }) } }, { rule: 'minimum', pointer: G + 'weight' }),
    px('guard-weight-edges-ok', { set: { '/guard': Object.assign(clone(guard), { weight: 1 }) } }, null),
    px('guard-weight-zero-ok', { set: { '/guard': Object.assign(clone(guard), { weight: 0 }) } }, null),
  ];
  // Animation's waves protag9 and rival6 now exist: the earlier fighters cases that used protag9 as a wave with no poses file use a name that never will
  for (let i = 0; i < c.cases.length; i++) {
    const k = c.cases[i];
    if (!k.id.startsWith('anim-fighters-') || !JSON.stringify(k).includes('protag9')) continue;
    c.cases[i] = JSON.parse(JSON.stringify(k).split('protag9').join('nowave9'));
  }
  let n = 0;
  for (const k of add) { const i = c.cases.findIndex((y) => y.id === k.id); if (i < 0) { c.cases.push(k); n++; } else if (JSON.stringify(c.cases[i]) !== JSON.stringify(k)) { c.cases[i] = k; n++; } } // a re-run over an earlier version updates its cases
  wj(cf, c);
  console.log(`anim zip2 schema applied (${n} new cases)`);
}

// =============================== docs ===============================
{
  const f = 'docs/tools/README.md';
  let t = fs.readFileSync(f, 'utf8');
  if (!t.includes('zip-entry')) {
    const a = '`zip-fighter`, `zip-pose`, `zip-name`, `zip-phase` |';
    if (!t.includes(a)) throw new Error('zip README anchor');
    t = t.replace(a, () => '`zip-fighter`, `zip-pose`, `zip-name`, `zip-phase`, `zip-entry` |');
    const line = t.split('\n').find((l) => l.includes('`zip-entry`'));
    t = t.replace(line, () => line.replace(/ \|$/, () => '; the optional entry_in, entry_out and pass.over and round are the name of an entrymap row. data/anim/press_styles.json: the optional guard\'s pose is a pose and its bones are bones of bone_lag |'));
    fs.writeFileSync(f, t);
  }
}
