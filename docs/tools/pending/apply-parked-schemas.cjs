// The schemas of the data files that Animation's and Simulation's parks bring (data/anim/brake.json, chain.json, guard_pass.json, throws.json; data/fight/forms.json and
// data/fighters/<id>/forms.json). Each is written by docs/tools/pending/infer-schema.cjs from the file itself, so run this in the commit that lands the files (a schema with no document
// fails the data job's coverage check, which is why these are not in the tree already):
//     node docs/tools/pending/apply-parked-schemas.cjs            every one whose file is in the tree
//     node docs/tools/pending/apply-parked-schemas.cjs brake      one of: brake, chain, guard-pass, throws, forms
// Proved on a scratch export of main with Animation's whole stack (many-bodies to study-poses, 18 patches) and Simulation's forms park: validate 0 errors, with the five files each mapped.
// Re-runnable: a second run changes nothing. Not run by CI or the validator.
const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');
const INFER = path.join(__dirname, 'infer-schema.cjs');
const JOBS = {
  brake: [['data/anim/brake.json', 'anim-brake', 'schema', ['--policy', 'the mid-air skid\'s poses and numbers (docs/animation/ragdoll-physics-paper.md)']]],
  chain: [['data/anim/chain.json', 'anim-chain', 'schema', ['--policy', 'the chain inside a tower: ceiling, lodge and rebound poses and rules']]],
  'guard-pass': [['data/anim/guard_pass.json', 'anim-guard-pass', 'schema', ['--maps', 'contacts', '--policy', 'the contact-key pass: how far each contact key\'s free hand was and is from the guard (docs/animation/guard-pass.md)']]],
  throws: [['data/anim/throws.json', 'anim-throws', 'schema', ['--maps', 'sends,grip', '--policy', 'the grapple\'s throws by the send and where each throw\'s hands take hold']]],
  forms: [
    ['data/fight/forms.json', 'fight-forms', 'schema', ['--policy', 'the forms\' switch and what every fighter shares (docs/architecture/forms-core.md)']],
    ['data/fighters/PROTAGONIST/forms.json', 'fighters-forms', 'schema', ['--match', 'data/fighters/*/forms.json', '--case-file', 'data/fighters/FIXTURE_HERO/forms.json', '--policy', 'a fighter\'s own steps, gains, coil, patience and release (docs/design/hero-forms.md)']],
  ],
};
const want = process.argv[2] ? [process.argv[2]] : Object.keys(JOBS);
let ran = 0;
for (const k of want) {
  if (!JOBS[k]) { console.error(`no such job "${k}" (${Object.keys(JOBS).join(', ')})`); process.exit(2); }
  for (const [file, name, vkey, extra] of JOBS[k]) {
    if (!fs.existsSync(file)) { console.log(`${name}: ${file} is not in the tree: skipped`); continue; }
    // a fighter's forms file is tested through a virtual fixture fighter's copy (the validator's fighters are fixtures), made here
    // (and so are data/fight, data/input and data/director: the self-test reads those from tools/fixtures/virtual, not the live folders)
    if (file.startsWith('data/fighters/') || file.startsWith('data/fight/')) {
      const v = file.startsWith('data/fight/') ? 'tools/fixtures/virtual/' + file : 'tools/fixtures/virtual/data/fighters/FIXTURE_HERO/forms.json';
      fs.mkdirSync(path.dirname(v), { recursive: true });
      fs.copyFileSync(file, v);
    }
    const r = spawnSync(process.execPath, [INFER, file, name, vkey, ...extra], { stdio: 'inherit' });
    if (r.status !== 0) process.exit(r.status || 1);
    ran++;
  }
}
console.log(`parked schemas: ${ran} file(s) done`);
