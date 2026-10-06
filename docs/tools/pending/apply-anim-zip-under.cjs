// Schema key for Animation's zip pass under the rival (docs/animation; Animation's zip build): data/anim/zip.json `pass` gains an optional third key,
// `under` (an entry name: the same shape and the same zip-entry cross-check as `over` and `round`). `over` and `round` stay required inside `pass`.
// NOT run by CI, the validator or the sim. Run once from the repo root, in the commit that lands Animation's zip build (after apply-anim-zip2.cjs,
// applied, and Encounter's zip commit):
//     node docs/tools/pending/apply-anim-zip-under.cjs
// It does NOT edit data/. The earlier case that named `under` as an unknown key of `pass` (anim-zip-pass-unknown-key) is changed to name another.
// Every new case sets its own whole `pass`. Re-runnable (a second run changes nothing).
const fs = require('fs');
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
