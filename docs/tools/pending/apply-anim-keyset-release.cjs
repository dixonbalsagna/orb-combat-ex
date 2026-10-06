// Two more optional key set keys, for Legal's nudges on the heavy tier (the solve lets go of the limb sooner after a heavy lands):
// tools/schemas/anim-wave-keysets.schema.json gains `hold_t` (integer, 0 to 12: ticks the contact key is held) and `ci_end` (integer, 0 to 30:
// ticks after the contact by which the solve releases the limb to the follow key). NOT run by CI, the validator or the sim. Run once from the repo
// root, in the commit that lands Animation's data (data/anim/waves/rival7.keysets.json carries them; the new parked waves protag11 and rival8, the
// energy blows in reach, validate under the existing wave schemas and need nothing more):
//     node docs/tools/pending/apply-anim-keyset-release.cjs
// It does NOT edit data/. Every case sets its own values. Re-runnable (a second run changes nothing).
const fs = require('fs');
const rj = (f) => JSON.parse(fs.readFileSync(f, 'utf8'));
const wj = (f, o) => fs.writeFileSync(f, JSON.stringify(o, null, 2) + '\n');

// =============================== schema ===============================
{
  const f = 'tools/schemas/anim-wave-keysets.schema.json';
  const s = rj(f);
  const row = s.properties.keysets.additionalProperties;
  if (!row.properties.hold_t) {
    const props = {};
    for (const [k, v] of Object.entries(row.properties)) {
      props[k] = v;
      if (k === 'drive') {
        props.hold_t = { type: 'integer', minimum: 0, maximum: 12, description: 'Ticks the contact key is held (a heavy lands, then lets go sooner: Legal\'s nudge).' };
        props.ci_end = { type: 'integer', minimum: 0, maximum: 30, description: 'Ticks after the contact by which the solve releases the limb to the follow key.' };
      }
    }
    if (!props.hold_t) throw new Error('the keysets schema has no `drive` property to put the new keys after: run apply-anim-superheavy.cjs first');
    row.properties = props;
    wj(f, s);
  }
}

// =============================== cases ===============================
{
  const cf = 'tools/fixtures/cases.json';
  const c = rj(cf);
  const K = 'data/anim/waves/protag10.keysets.json';
  const kid = Object.keys(rj(K).keysets)[0];
  const KP = '/keysets/' + kid + '/';
  const ks = (n, set, expect) => ({ id: 'anim-wave-keysets-release-' + n, schema: 'anim-wave-keysets.schema.json', mutate: [{ file: K, set }], expect });
  const add = [
    ks('both-ok', { [KP + 'hold_t']: 1, [KP + 'ci_end']: 6 }, null),
    ks('hold-t-zero-ok', { [KP + 'hold_t']: 0 }, null),
    ks('hold-t-twelve-ok', { [KP + 'hold_t']: 12 }, null),
    ks('hold-t-negative', { [KP + 'hold_t']: -1 }, { rule: 'minimum', pointer: KP + 'hold_t' }),
    ks('hold-t-above-twelve', { [KP + 'hold_t']: 13 }, { rule: 'maximum', pointer: KP + 'hold_t' }),
    ks('hold-t-integer', { [KP + 'hold_t']: 1.5 }, { rule: 'type', pointer: KP + 'hold_t' }),
    ks('hold-t-type', { [KP + 'hold_t']: 'short' }, { rule: 'type', pointer: KP + 'hold_t' }),
    ks('ci-end-zero-ok', { [KP + 'ci_end']: 0 }, null),
    ks('ci-end-thirty-ok', { [KP + 'ci_end']: 30 }, null),
    ks('ci-end-negative', { [KP + 'ci_end']: -1 }, { rule: 'minimum', pointer: KP + 'ci_end' }),
    ks('ci-end-above-thirty', { [KP + 'ci_end']: 31 }, { rule: 'maximum', pointer: KP + 'ci_end' }),
    ks('ci-end-integer', { [KP + 'ci_end']: 6.5 }, { rule: 'type', pointer: KP + 'ci_end' }),
    ks('ci-end-type', { [KP + 'ci_end']: 'soon' }, { rule: 'type', pointer: KP + 'ci_end' }),
    ks('with-the-superheavy-keys-ok', { [KP + 'tell_at']: 0.5, [KP + 'squash_w']: 0, [KP + 'drive']: 'fall', [KP + 'hold_t']: 1, [KP + 'ci_end']: 6 }, null),
    ks('unknown-key-still-refused', { [KP + 'hold_ticks']: 1 }, { rule: 'additionalProperties', pointer: KP + 'hold_ticks' }),
  ];
  let n = 0;
  for (const k of add) {
    const i = c.cases.findIndex((y) => y.id === k.id);
    if (i < 0) { c.cases.push(k); n++; } else if (JSON.stringify(c.cases[i]) !== JSON.stringify(k)) { c.cases[i] = k; n++; }
  }
  wj(cf, c);
  console.log(`key set release keys applied (${n} new cases)`);
}
