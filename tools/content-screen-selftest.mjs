// Self-test of tools/content-screen.mjs (CD-27): each thing the screen hunts is planted in a scratch folder and must be found, each thing it must leave alone must pass, a personal name or a
// secret must never be printed in full, and the repository itself must pass. No git, no Godot, no browser, no network. CI runs it.
//   node tools/content-screen-selftest.mjs
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { loadRules, screen } from './content-screen.mjs';

const BS = String.fromCharCode(92);   // a backslash, built so no escaping layer can change it
let ran = 0, failed = 0;
const check = (name, ok, extra) => { ran++; if (!ok) { failed++; console.log(`  FAIL ${name}${extra ? ': ' + extra : ''}`); } };
const rules = loadRules();
const tmp = mkdtempSync(join(tmpdir(), 'content-screen-'));
const put = (f, text) => { const p = join(tmp, ...f.split('/')); mkdirSync(dirname(p), { recursive: true }); writeFileSync(p, text); };
const rulesHit = (r, id, file) => r.hits.filter((h) => h.rule === id && (!file || h.file === file));
const win = (name) => `C:${BS}Users${BS}${name}${BS}Documents${BS}x`;

try {
  // a clean tree
  put('README.md', 'A free fighting game. The hosted build is offline for now.\n');
  put('docs/notes.md', `Placeholders are fine: ${win('<user>')}, ${win('Public')}, /home/runner/work/x, /home/user/x, ${BS}${BS}Users${BS}${BS}<user>${BS}${BS}a.\n`);
  put('data/fighters/A/fighter.json', '{ "hair": "#22c7a9" }\n');
  put('data/fighters/B/fighter.json', '{ "hair": "#181818" }\n');
  put('sim/x.gd', 'var a = 1\n');
  let r = screen(tmp, rules);
  check('a clean tree has no hit', r.hits.length === 0, JSON.stringify(r.hits));

  // profile paths, in every slash form, and never printed in full
  put('docs/a.md', `see ${win('realperson')}\n`);
  put('docs/b.json', `{"p": "C:${BS}${BS}Users${BS}${BS}realperson${BS}${BS}x"}\n`);
  const NM = 'real' + 'person';   // built from two pieces so this file does not hold a name the screen would flag
  put('docs/c.sh', `cd /c/Users/${NM}/x; cp /Us${'ers'}/${NM}/y /ho${'me'}/${NM}/z\n`);
  put('docs/d.md', `${BS}Users${BS}${NM}${BS}foo and Users%5C${NM}%5Cbar\n`);
  r = screen(tmp, rules);
  const pp = rulesHit(r, 'profile-path');
  check('a user-profile path is found in the Windows, escaped, macOS, Linux and percent-encoded forms', ['docs/a.md', 'docs/b.json', 'docs/c.sh', 'docs/d.md'].every((f) => pp.some((h) => h.file === f)), JSON.stringify(pp.map((h) => h.file)));
  check('every profile hit is a fail', pp.length >= 4 && pp.every((h) => h.severity === 'fail'));
  check('the screen never prints the whole name', JSON.stringify(r.hits).indexOf('realperson') < 0, JSON.stringify(pp.slice(0, 2)));
  check('the placeholders (<user>, Public, runner, user, the escaped <user>) are not profile hits', !pp.some((h) => h.file === 'docs/notes.md'));
  rmSync(join(tmp, 'docs', 'a.md')); rmSync(join(tmp, 'docs', 'b.json')); rmSync(join(tmp, 'docs', 'c.sh')); rmSync(join(tmp, 'docs', 'd.md'));

  // secrets
  put('docs/s1.txt', `token ${'gh' + 'p_'}${'A'.repeat(36)}\n`);
  put('docs/s2.txt', `${'AK' + 'IA'}${'B'.repeat(16)}\n`);
  put('docs/s3.txt', `${'-----BEGIN '}${'RSA PRIVATE'} KEY-----\n`);
  put('docs/s4.json', `{ "api_key": "${'Q'.repeat(32)}" }\n`);
  r = screen(tmp, rules);
  const sec = r.hits.filter((h) => h.rule.startsWith('secret:'));
  check('a GitHub token, an AWS key, a private-key header and an assigned secret are found', ['docs/s1.txt', 'docs/s2.txt', 'docs/s3.txt', 'docs/s4.json'].every((f) => sec.some((h) => h.file === f)), JSON.stringify(sec.map((h) => h.rule + ' ' + h.file)));
  check('a secret is masked in the output', !JSON.stringify(r.hits).includes('A'.repeat(10)) && !JSON.stringify(r.hits).includes('Q'.repeat(10)));
  for (const f of ['s1.txt', 's2.txt', 's3.txt', 's4.json']) rmSync(join(tmp, 'docs', f));

  // console SDK
  put('tools/x.mjs', `const p = 'C:${BS}${BS}Program Files${BS}${BS}Nintendo${BS}${BS}SDK';\n`);
  put('docs/sdk.md', 'the NINTENDO_SDK_ROOT variable\n');
  r = screen(tmp, rules);
  check('a console SDK path or variable is found', rulesHit(r, 'console-sdk', 'tools/x.mjs').length === 1 && rulesHit(r, 'console-sdk', 'docs/sdk.md').length === 1, JSON.stringify(rulesHit(r, 'console-sdk')));
  rmSync(join(tmp, 'tools', 'x.mjs')); rmSync(join(tmp, 'docs', 'sdk.md'));

  // franchise words: in what ships, found; in the notes, not
  put('data/combat/x.json', '{ "name": "Kamehameha wave" }\n');
  put('ui/data/terms.json', '{ "t": "a Super Saiyan glow" }\n');
  put('docs/narrative/screen.md', 'Stage 0: no Saiyan, no Dragon Ball.\n');
  put('docs/legal/never-use-words.md', 'Saiyan, scouter\n');
  r = screen(tmp, rules);
  const fw = rulesHit(r, 'franchise-word');
  check('a franchise word in shipped data or UI text is found', fw.some((h) => h.file === 'data/combat/x.json') && fw.some((h) => h.file === 'ui/data/terms.json'), JSON.stringify(fw));
  check('the same words in the screening notes and Legal\'s lists are out of scope', !fw.some((h) => h.file.startsWith('docs/')));
  rmSync(join(tmp, 'data', 'combat', 'x.json')); rmSync(join(tmp, 'ui', 'data', 'terms.json'));

  // RL-014: gold hair
  put('data/fighters/C/fighter.json', '{ "hair": "#f2d338" }\n');
  put('data/fighters/D/fighter.json', '{ "hair": "#6f6f6f" }\n');
  r = screen(tmp, rules);
  const gh = rulesHit(r, 'rl014-gold-hair');
  check('a gold hair colour in a shipped fighter file is found; teal, grey and near-black are not', gh.length === 1 && gh[0].file === 'data/fighters/C/fighter.json', JSON.stringify(gh));
  rmSync(join(tmp, 'data', 'fighters', 'C', 'fighter.json'));

  // public words
  put('README.md', 'The flashing scenes: We are fixing them. The engine is (official).\n');
  put('CLAUDE.md', 'A free and open source game.\n');
  r = screen(tmp, rules);
  const pw = r.hits.filter((h) => h.rule.startsWith('public-words:'));
  check('"We are fixing them" and "(official)" in README.md are fails', pw.some((h) => h.rule === 'public-words:we-are-fixing-them' && h.severity === 'fail' && h.file === 'README.md') && pw.some((h) => h.rule === 'public-words:official-engine' && h.severity === 'fail'));
  check('"open source" in CLAUDE.md is a warning, not a fail', pw.some((h) => h.rule === 'public-words:open-source-claim' && h.severity === 'warn' && h.file === 'CLAUDE.md'));
  check('only fails make the screen fail', r.hits.some((h) => h.severity === 'fail') && r.hits.some((h) => h.severity === 'warn'));

  // binary and large files are skipped, and a hit-free tree passes again
  rmSync(join(tmp, 'README.md')); rmSync(join(tmp, 'CLAUDE.md'));
  writeFileSync(join(tmp, 'blob.bin'), Buffer.concat([Buffer.from([0, 1, 2]), Buffer.from(win('realperson'))]));
  put('art/pic.png', win('realperson'));
  r = screen(tmp, rules);
  check('a binary file and a skipped extension are not read', r.hits.length === 0, JSON.stringify(r.hits));
} finally {
  rmSync(tmp, { recursive: true, force: true });
}

// the repository itself must pass (a CI check that fails on the first real hit)
const repo = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const real = screen(repo, rules);
check('the repository has no failing hit', real.hits.filter((h) => h.severity === 'fail').length === 0, JSON.stringify(real.hits.filter((h) => h.severity === 'fail').slice(0, 5)));
console.log(failed ? `content screen self-test FAILED: ${failed} of ${ran} checks` : `content screen self-test ok: ${ran} checks`);
process.exit(failed ? 1 : 0);
