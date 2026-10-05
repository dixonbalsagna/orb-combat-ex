// Schema keys for Animation's wave 2 (the gestures). NOT run by CI, the validator or the sim. Run once from the repo root, in the commit that lands
// the data:
//     node docs/tools/pending/apply-anim-gestures.cjs
// It does NOT edit data/. All the keys are optional. It adds to data/anim/pair_live.json:
//   roles.<fighter>.gestures  {intent: {seq, w, mask, hold}} with the intent one of acknowledge, appraise, dismiss, defer, brace, ease, claim, check,
//                             soften or harden; seq is a sequence or pose id, w (0 to 1) and mask (group names) are optional
//   gesture_groups            group name (head, torso, arms or legs) to a unique list of bone names
// Cross-checks: a gesture's seq is a sequence or a pose of the wave files (pairlive-gesture); every bone of gesture_mask is a bone of
// profiles.json bone_lag (pairlive-bone); every mask entry of a gesture is a key of gesture_groups (pairlive-gesture). Every case sets its own values. Re-runnable (a second run changes nothing).
const fs = require('fs');
const rj = (f) => JSON.parse(fs.readFileSync(f, 'utf8'));
const wj = (f, o) => fs.writeFileSync(f, JSON.stringify(o, null, 2) + '\n');
const GROUPS = ['head', 'torso', 'arms', 'legs'];
const HOLD = { type: 'number', exclusiveMinimum: 0, description: 'Seconds a pose is held (for a pose id).' };
const INTENTS = ['acknowledge', 'appraise', 'dismiss', 'defer', 'brace', 'ease', 'claim', 'check', 'soften', 'harden'];

// =============================== schema ===============================
{
  const f = 'tools/schemas/anim-pairlive.schema.json';
  const s = rj(f);
  const rp = s.properties.roles.additionalProperties.properties;
  if (!rp.gestures) {
    rp.gestures = {
      type: 'object',
      propertyNames: { pattern: '^(_.*|[a-z]+)$' },
      description: 'Optional. The body gestures a fighter plays for each intent (acknowledge, appraise, dismiss, defer, brace, ease, claim, check, soften, harden).',
      properties: Object.fromEntries(INTENTS.map((i) => [i, {
        type: 'object',
        required: ['seq'],
        properties: {
          seq: { type: 'string', pattern: '^[a-z][a-z0-9_]*([.][a-z0-9_~]+)*$', description: 'A sequence or a pose id of the wave files.' },
          w: { type: 'number', minimum: 0, maximum: 1, description: 'How much of the gesture the body takes (optional).' },
          mask: { type: 'array', minItems: 1, uniqueItems: true, items: { enum: GROUPS }, description: 'The groups of gesture_groups the gesture moves (optional).' },
          hold: HOLD,
        },
        additionalProperties: false,
        patternProperties: { '^_': true },
      }])),
      additionalProperties: false,
      patternProperties: { '^_': true },
    };
    s.properties.gesture_groups = {
      type: 'object',
      propertyNames: { pattern: '^(_.*|head|torso|arms|legs)$' },
      description: 'Optional. The bone groups a gesture may move (head, torso, arms, legs); the rest of the body keeps playing the fight.',
      additionalProperties: { type: 'array', minItems: 1, uniqueItems: true, items: { type: 'string', pattern: '^[a-z][a-z0-9_]*$' } },
      patternProperties: { '^_': true },
    };
    wj(f, s);
  }
}

// ---- schema upgrade: a first version of this script (without `hold`) may have run already ----
{
  const f = 'tools/schemas/anim-pairlive.schema.json';
  const s = rj(f);
  const g = s.properties.roles.additionalProperties.properties.gestures;
  if (g) {
    const intent = g.properties[INTENTS[0]];
    if (intent && !intent.properties.hold) {
      for (const i of INTENTS) g.properties[i].properties.hold = HOLD;
      wj(f, s);
    }
  }
}

// =============================== xref ===============================
{
  const f = 'tools/lib/xref-fight.js';
  let t = fs.readFileSync(f, 'utf8');
  if (!t.includes("'pairlive-gesture'")) {
    const a = "    const shotsPl = get('data/fight/shots.json');";
    if (!t.includes(a)) throw new Error('pairlive anchor');
    t = t.replace(a, () => [
      "    for (const [fid, r] of Object.entries(isObj(plv.roles) ? plv.roles : {})) {",
      "      if (fid.startsWith('_') || !isObj(r) || !isObj(r.gestures)) continue;",
      "      for (const [intent, g] of Object.entries(r.gestures)) if (!intent.startsWith('_') && isObj(g)) needEither(g.seq, `/roles/${esc(fid)}/gestures/${esc(intent)}/seq`);",
      "    }",
      "    const profPl = get('data/anim/profiles.json');",
      "    const bonesPl = isObj(profPl) && isObj(profPl.bone_lag) ? Object.keys(profPl.bone_lag) : [];",
      "    const groupsPl = isObj(plv.gesture_groups) ? plv.gesture_groups : {};",
      "    if (bonesPl.length) for (const [gk, list] of Object.entries(groupsPl)) if (!gk.startsWith('_') && Array.isArray(list)) list.forEach((b, i) => { if (typeof b === 'string' && !bonesPl.includes(b)) err(PL, `/gesture_groups/${esc(gk)}/${i}`, 'pairlive-bone', `gesture group \"${gk}\" has bone \"${b}\", which is not in profiles.json bone_lag`); });",
      "    for (const [fid, r] of Object.entries(isObj(plv.roles) ? plv.roles : {})) {",
      "      if (fid.startsWith('_') || !isObj(r) || !isObj(r.gestures)) continue;",
      "      for (const [intent, g] of Object.entries(r.gestures)) if (!intent.startsWith('_') && isObj(g) && Array.isArray(g.mask)) g.mask.forEach((m, i) => { if (typeof m === 'string' && !(m in groupsPl)) err(PL, `/roles/${esc(fid)}/gestures/${esc(intent)}/mask/${i}`, 'pairlive-gesture', `mask group \"${m}\" is not a key of gesture_groups`); });",
      "    }",
      a,
    ].join('\n'));
    // a gesture's seq is reported as pairlive-gesture rather than pairlive-ref
    t = t.replace("needEither(g.seq, `/roles/${esc(fid)}/gestures/${esc(intent)}/seq`);", () => "{ const v = g.seq; if ((poseSet.size || seqSet.size) && typeof v === 'string' && !poseSet.has(v) && !seqSet.has(v)) err(PL, `/roles/${esc(fid)}/gestures/${esc(intent)}/seq`, 'pairlive-gesture', `gesture \"${v}\" is neither a pose nor a sequence of the wave files`); }");
    fs.writeFileSync(f, t);
  }
}

// =============================== cases ===============================
{
  const cf = 'tools/fixtures/cases.json';
  const c = rj(cf);
  const P = 'data/anim/pair_live.json';
  const x = (n, mut, expect) => ({ id: 'anim-pairlive-' + n, schema: 'anim-pairlive.schema.json', mutate: [{ file: P, ...mut }], expect });
  const GP = '/roles/protagonist/gestures';
  // cases that replace gesture_groups clear every fighter's gestures first, so none depends on the real file's masks
  const CLR = { [GP]: {}, '/roles/antihero/gestures': {} };
  const ok = { acknowledge: { seq: 'pg.taunt_close' }, brace: { seq: 'brace', w: 0.5 } };
  const add = [
    x('gestures-ok', { set: { [GP]: ok } }, null),
    x('gestures-every-intent-ok', { set: { [GP]: Object.fromEntries(['acknowledge', 'appraise', 'dismiss', 'defer', 'brace', 'ease', 'claim', 'check', 'soften', 'harden'].map((i) => [i, { seq: 'brace' }])) } }, null),
    x('gestures-type', { set: { [GP]: 'bow' } }, { rule: 'type', pointer: GP }),
    x('gestures-empty-ok', { set: { [GP]: {} } }, null),
    x('gestures-note-ok', { set: { [GP]: { _why: 'comment', acknowledge: { seq: 'brace' } } } }, null),
    x('gesture-intent-unknown', { set: { [GP]: { wave: { seq: 'brace' } } } }, { rule: 'additionalProperties', pointer: GP + '/wave' }),
    x('gesture-intent-shape', { set: { [GP]: { 'Acknowledge Him': { seq: 'brace' } } } }, { rule: 'propertyNames', pointer: GP + '/Acknowledge Him' }),
    x('gesture-key-required', { set: { [GP]: { brace: { w: 0.5 } } } }, { rule: 'required', pointer: GP + '/brace' }),
    x('gesture-unknown-key', { set: { [GP]: { brace: { seq: 'brace', speed: 2 } } } }, { rule: 'additionalProperties', pointer: GP + '/brace/speed' }),
    x('gesture-note-key-ok', { set: { [GP]: { brace: { seq: 'brace', _why: 'comment' } } } }, null),
    x('gesture-seq-shape', { set: { [GP]: { brace: { seq: 'Brace Pose' } } } }, { rule: 'pattern', pointer: GP + '/brace/seq' }),
    x('gesture-seq-type', { set: { [GP]: { brace: { seq: 3 } } } }, { rule: 'type', pointer: GP + '/brace/seq' }),
    x('gesture-seq-unknown', { set: { [GP]: { brace: { seq: 'pg.nowhere' } } } }, { rule: 'xref:pairlive-gesture', pointer: GP + '/brace/seq' }),
    x('gesture-pose-ok', { set: { [GP]: { claim: { seq: 'brace' } } } }, null),
    x('gesture-weight-range', { set: { [GP]: { brace: { seq: 'brace', w: 1.5 } } } }, { rule: 'maximum', pointer: GP + '/brace/w' }),
    x('gesture-weight-negative', { set: { [GP]: { brace: { seq: 'brace', w: -0.1 } } } }, { rule: 'minimum', pointer: GP + '/brace/w' }),
    x('gesture-weight-type', { set: { [GP]: { brace: { seq: 'brace', w: 'half' } } } }, { rule: 'type', pointer: GP + '/brace/w' }),
    x('gesture-hold-ok', { set: { [GP]: { brace: { seq: 'brace', hold: 0.6 } } } }, null),
    x('gesture-hold-zero', { set: { [GP]: { brace: { seq: 'brace', hold: 0 } } } }, { rule: 'exclusiveMinimum', pointer: GP + '/brace/hold' }),
    x('gesture-hold-negative', { set: { [GP]: { brace: { seq: 'brace', hold: -1 } } } }, { rule: 'exclusiveMinimum', pointer: GP + '/brace/hold' }),
    x('gesture-hold-type', { set: { [GP]: { brace: { seq: 'brace', hold: 'long' } } } }, { rule: 'type', pointer: GP + '/brace/hold' }),
    x('gesture-hold-with-w-and-mask-ok', { set: { [GP]: { brace: { seq: 'brace', hold: 1.5, w: 0.5 } } } }, null),
    x('gesture-weight-edges-ok', { set: { [GP]: { brace: { seq: 'brace', w: 0 }, ease: { seq: 'brace', w: 1 } } } }, null),
    x('gestures-for-the-other-fighter-ok', { set: { '/roles/antihero/gestures': ok } }, null),
    x('gesture-mask-ok', { set: { ...CLR, [GP]: { brace: { seq: 'brace', mask: ['head', 'arms'] } }, '/gesture_groups': { head: ['head', 'neck'], arms: ['upper_arm_l', 'upper_arm_r'] } } }, null),
    x('gesture-mask-type', { set: { [GP]: { brace: { seq: 'brace', mask: 'head' } } } }, { rule: 'type', pointer: GP + '/brace/mask' }),
    x('gesture-mask-empty', { set: { [GP]: { brace: { seq: 'brace', mask: [] } } } }, { rule: 'minItems', pointer: GP + '/brace/mask' }),
    x('gesture-mask-duplicate', { set: { [GP]: { brace: { seq: 'brace', mask: ['head', 'head'] } }, '/gesture_groups': { head: ['head'] } } }, { rule: 'uniqueItems', pointer: GP + '/brace/mask/1' }),
    x('gesture-mask-group-enum', { set: { [GP]: { brace: { seq: 'brace', mask: ['tail'] } } } }, { rule: 'enum', pointer: GP + '/brace/mask/0' }),
    x('gesture-mask-group-not-defined', { set: { [GP]: { brace: { seq: 'brace', mask: ['legs'] } }, '/gesture_groups': { head: ['head'] } } }, { rule: 'xref:pairlive-gesture', pointer: GP + '/brace/mask/0' }),
    x('gesture-groups-ok', { set: { ...CLR, '/gesture_groups': { head: ['head', 'neck'], torso: ['spine_1', 'spine_2'], arms: ['upper_arm_l'], legs: ['thigh_l'] } } }, null),
    x('gesture-groups-type', { set: { '/gesture_groups': ['head'] } }, { rule: 'type', pointer: '/gesture_groups' }),
    x('gesture-groups-name-enum', { set: { '/gesture_groups': { tail: ['head'] } } }, { rule: 'propertyNames', pointer: '/gesture_groups/tail' }),
    x('gesture-groups-note-ok', { set: { ...CLR, '/gesture_groups': { _why: 'comment', head: ['head'] } } }, null),
    x('gesture-groups-empty-ok', { set: { ...CLR, '/gesture_groups': {} } }, null),
    x('gesture-groups-list-empty', { set: { '/gesture_groups': { head: [] } } }, { rule: 'minItems', pointer: '/gesture_groups/head' }),
    x('gesture-groups-bone-duplicate', { set: { '/gesture_groups': { head: ['head', 'head'] } } }, { rule: 'uniqueItems', pointer: '/gesture_groups/head/1' }),
    x('gesture-groups-bone-shape', { set: { '/gesture_groups': { head: ['Head'] } } }, { rule: 'pattern', pointer: '/gesture_groups/head/0' }),
    x('gesture-groups-bone-unknown', { set: { '/gesture_groups': { head: ['head', 'tail_9'] } } }, { rule: 'xref:pairlive-bone', pointer: '/gesture_groups/head/1' }),
  ];
  let n = 0;
  for (const k of add) { const i = c.cases.findIndex((y) => y.id === k.id); if (i < 0) { c.cases.push(k); n++; } else if (JSON.stringify(c.cases[i]) !== JSON.stringify(k)) { c.cases[i] = k; n++; } } // a re-run over an earlier version updates its cases
  wj(cf, c);
  console.log(`anim gestures schema applied (${n} new cases)`);
}

// =============================== docs ===============================
{
  const f = 'docs/tools/README.md';
  let t = fs.readFileSync(f, 'utf8');
  if (!t.includes('pairlive-gesture')) {
    const a = '`pairlive-fighter`, `pairlive-wave`, `pairlive-ref`, `pairlive-gated`, `pairlive-kind` |';
    if (!t.includes(a)) throw new Error('pairlive README anchor');
    t = t.replace(a, () => '`pairlive-fighter`, `pairlive-wave`, `pairlive-ref`, `pairlive-gated`, `pairlive-kind`, `pairlive-gesture`, `pairlive-bone` |');
    const line = t.split('\n').find((l) => l.includes('`pairlive-gesture`'));
    t = t.replace(line, () => line.replace(/ \|$/, () => '; the optional gestures\' seq is a pose or a sequence of the wave files and every gesture_groups bone is a bone of bone_lag, and a gesture\'s mask names groups of gesture_groups |'));
    fs.writeFileSync(f, t);
  }
}
