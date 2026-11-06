// Self-test of tools/pin-child.mjs (Legal RL-209 (b)): the words-only child of a pin, on a throwaway git repo. Node built-ins and git only.
import { execFileSync, spawnSync } from 'node:child_process';
import { mkdtempSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildChild, proveWordsOnly, patchOf, childCommitId, recipe, getAt, pathOf } from './pin-child.mjs';

const here = dirname(fileURLToPath(import.meta.url));
let failed = 0;
const check = (name, ok, detail) => { console.log(`${ok ? 'ok  ' : 'FAIL'} ${name}${ok || !detail ? '' : '\n     ' + detail}`); if (!ok) failed++; };

const root = mkdtempSync(join(tmpdir(), 'pin-child-test-'));
const git = (...a) => execFileSync('git', ['-c', 'core.autocrlf=false', '-c', 'user.name=t', '-c', 'user.email=t@t.invalid', '-c', 'commit.gpgsign=false', ...a], { cwd: root, encoding: 'utf8' }).trim();
try {
  git('init', '-q');
  const put = (f, text) => { const p = join(root, ...f.split('/')); mkdirSync(dirname(p), { recursive: true }); writeFileSync(p, text); };
  // the pin: a notice with the old words, a settings file with an item to locate, an options file with a British word in a label and in an id
  const pinTerms = '{\n  "prompt": { "menu_notice": "We are fixing them.", "other": "same" }\n}\n';
  const pinSettings = '{\n  "sections": [ { "items": [ "a", { "action": "photo_notice", "help": "an analyser" } ] } ]\n}\n';
  const pinOptions = '{\n  "options": { "colour_vision": { "label": "Colour-blind mode" } }\n}\n';
  put('ui/data/terms.json', pinTerms); put('ui/data/settings.json', pinSettings); put('ui/data/options.json', pinOptions); put('ui/data/untouched.json', '{ "k": "a licence" }\n');
  git('add', '-A'); git('commit', '-q', '-m', 'pin');
  const PIN = git('rev-parse', 'HEAD');
  // main: the cleared words, a moved settings item, a new key and a feature string that is NOT a word
  put('ui/data/terms.json', '{\n  "prompt": { "menu_notice": "Please do not play.", "other": "same", "load_x": "Raising" }\n}\n');
  put('ui/data/settings.json', '{\n  "sections": [ { "items": [ "z", "a", { "action": "photo_notice", "help": "an analyzer" } ] } ]\n}\n');
  put('ui/data/options.json', '{\n  "options": { "colour_vision": { "label": "Color-blind mode" } }\n}\n');
  put('ui/data/untouched.json', '{ "k": "a license" }\n');
  git('add', '-A'); git('commit', '-q', '-m', 'main');
  const FROM = git('rev-parse', 'HEAD');
  const readPin = (f) => git('show', `${PIN}:${f}`) + '\n';
  const readFrom = (f) => git('show', `${FROM}:${f}`) + '\n';
  const config = { pin: PIN, from: FROM, commit: { name: 'Meridian Tools', email: 'tools@meridian.invalid', date: '2026-10-30T20:00:00Z', message: 'child' }, words: [
    { file: 'ui/data/terms.json', pointer: '/prompt/menu_notice', row: 'RL-192' },
    { file: 'ui/data/settings.json', locate: { key: 'action', equals: 'photo_notice' }, field: 'help', row: 'RL-192' },
    { file: 'ui/data/options.json', pointer: '/options/colour_vision/label', row: 'RL-193' },
  ] };

  const built = buildChild(readPin, readFrom, config);
  check('the listed strings are replaced in the pin\'s own text, the formatting untouched', built.texts['ui/data/terms.json'] === '{\n  "prompt": { "menu_notice": "Please do not play.", "other": "same" }\n}\n' && built.changes.length === 3);
  check('an item is found by a key and its value even when it moved (the settings help), and only that string changes', built.texts['ui/data/settings.json'] === '{\n  "sections": [ { "items": [ "a", { "action": "photo_notice", "help": "an analyzer" } ] } ]\n}\n');
  check('a new key or a moved item in the source is not copied (load_x, the extra settings item)', !/load_x/.test(built.texts['ui/data/terms.json']) && !/"z"/.test(built.texts['ui/data/settings.json']));
  check('a file that is not listed is never in the child', !('ui/data/untouched.json' in built.texts));
  check('the proof holds: the child equals the pin with only the listed strings changed', proveWordsOnly(readPin, config, built.texts, readFrom).length === 0);
  const tampered = { ...built.texts, 'ui/data/terms.json': built.texts['ui/data/terms.json'].replace('"same"', '"other"') };
  check('the proof catches any other difference', proveWordsOnly(readPin, config, tampered, readFrom).some((m) => /more than the listed strings/.test(m)));
  const tried = (cfg) => { try { buildChild(readPin, readFrom, cfg); return ''; } catch (e) { return e.message; } };
  check('a string that is the same in both is refused (nothing to change)', /the same in both/.test(tried({ ...config, words: [{ file: 'ui/data/terms.json', pointer: '/prompt/other', row: 'x' }] })));
  check('a pointer that is not a string in the pin is refused', /not a string in the pin/.test(tried({ ...config, words: [{ file: 'ui/data/terms.json', pointer: '/prompt', row: 'x' }] })));
  check('a pointer missing in the source is refused', /not a string in/.test(tried({ ...config, words: [{ file: 'ui/data/terms.json', pointer: '/prompt/menu_notice_gone', row: 'x' }] })));
  check('a string that occurs twice in the pin\'s text is refused (a replacement must be unambiguous)', (() => {
    const two = { ...config, pin: PIN };
    const rp = (f) => (f === 'ui/data/terms.json' ? '{ "prompt": { "menu_notice": "We are fixing them.", "dup": "We are fixing them." } }\n' : readPin(f));
    const rf = (f) => (f === 'ui/data/terms.json' ? '{ "prompt": { "menu_notice": "Please.", "dup": "We are fixing them." } }\n' : readFrom(f));
    try { buildChild(rp, rf, { ...two, words: [{ file: 'ui/data/terms.json', pointer: '/prompt/menu_notice', row: 'x' }] }); return false; } catch (e) { return /2 times/.test(e.message); }
  })());
  check('locate needs exactly one match', (() => { try { pathOf({ a: [{ k: 'v' }, { k: 'v' }] }, { file: 'f', locate: { key: 'k', equals: 'v' }, field: 'h' }); return false; } catch (e) { return /2 items/.test(e.message); } })());
  check('getAt reads a pointer path and returns undefined past the end', getAt({ a: [{ b: 1 }] }, ['a', 0, 'b']) === 1 && getAt({ a: 1 }, ['a', 'b']) === undefined);

  // the patch applies to the pin and gives the child's files
  const patch = patchOf(readPin, built.texts);
  const pf = join(root, 'child.patch');
  writeFileSync(pf, patch);
  git('checkout', '-q', PIN);
  const ap = spawnSync('git', ['-c', 'core.autocrlf=false', 'apply', '--check', pf], { cwd: root, encoding: 'utf8' });
  check('the patch applies to the pin\'s tree and has no CRs or a/a/ paths', ap.status === 0 && !/\r/.test(patch) && /^diff --git a\/ui\/data\/terms\.json b\/ui\/data\/terms\.json$/m.test(patch), ap.stderr);
  git('checkout', '-q', FROM);

  // the commit id: deterministic, nothing written to the repo, the same as the recipe's commit made for real
  const objectsBefore = git('count-objects', '-v');
  const id1 = childCommitId(root, config, built.texts), id2 = childCommitId(root, config, built.texts);
  check('the child commit id is computed without writing to the repo, and is the same twice', /^[0-9a-f]{40}$/.test(id1) && id1 === id2 && git('count-objects', '-v') === objectsBefore, `${id1} ${id2}`);
  const files = join(root, 'files');
  for (const [f, text] of Object.entries(built.texts)) { const p = join(files, ...f.split('/')); mkdirSync(dirname(p), { recursive: true }); writeFileSync(p, text); }
  const made = spawnSync('bash', ['-c', recipe(config, files.replace(/\\/g, '/'))], { cwd: root, encoding: 'utf8' });
  check('the recipe makes that same commit for real (same id), parent the pin, three files changed', made.status === 0 && made.stdout.trim().split('\n').pop() === id1 && git('rev-parse', `${id1}^`) === PIN && git('diff', '--name-only', PIN, id1).split('\n').length === 3, made.stdout + made.stderr);
  check('the child commit\'s own files are the child\'s text, byte for byte', git('show', `${id1}:ui/data/terms.json`) + '\n' === built.texts['ui/data/terms.json'] && git('show', `${id1}:ui/data/untouched.json`) + '\n' === readPin('ui/data/untouched.json'));
} finally { rmSync(root, { recursive: true, force: true }); }

console.log(failed ? `pin-child self-test FAILED (${failed})` : 'pin-child self-test passed');
process.exit(failed ? 1 : 0);
