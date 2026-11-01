// Self-test for the two-fighter ratchet: a synthetic tree, so the count, the exclusions, the verdict and the one-way baseline are shown to work (and to fail) before the real one is trusted.
//   node tools/ratchet-two-fighter-selftest.mjs
import { mkdtempSync, mkdirSync, writeFileSync, rmSync, readFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { count, judge } from './ratchet-two-fighter.mjs';

const here = dirname(fileURLToPath(import.meta.url));
let bad = 0;
const check = (name, ok) => { console.log(`${ok ? 'ok  ' : 'FAIL'} ${name}`); if (!ok) bad++; };
const put = (root, rel, text) => { const p = join(root, rel); mkdirSync(dirname(p), { recursive: true }); writeFileSync(p, text); };
const root = mkdtempSync(join(tmpdir(), 'ratchet-'));
try {
  put(root, 'sim/core/a.gd', 'var a = S.fighters[0]\nvar b = S.fighters[1]\nvar c = S.dirS.ex.x\nvar d = SimRoster.opp(S, 0)\n');
  put(root, 'render/camera/b.gd', 'x = host.S.fighters[0].x + host.S.fighters[0].y\n');
  put(root, 'sim/core/tools/a_probe.gd', 'S.fighters[0]\nS.fighters[1]\n');            // tools: not counted
  put(root, 'sim/director/test/t.gd', 'S.fighters[0]\n');                              // test: not counted
  put(root, 'sim/director/x_check.gd', 'S.fighters[0]\n');                             // a check: not counted
  put(root, 'sim/director/y_test.gd', 'S.fighters[1]\n');
  put(root, 'docs/z.gd', 'S.fighters[0]\n');                                           // outside the roots
  put(root, 'sim/core/c.gd', 'for f in S.fighters:\n\tf.x += 1\nvar n = fighters[10]\n');   // the honest form: not counted
  const now = count(root);
  check('the four spellings are counted in shipped files', now.total === 6 && now.files['sim/core/a.gd'] === 4 && now.files['render/camera/b.gd'] === 2 && now.bySpelling['fighters[0]'] === 3);
  check('tests, tools, probes, checks and files outside the roots are not counted', Object.keys(now.files).length === 2);
  check('the honest form (a loop over the list, fighters[10]) is not counted', !('sim/core/c.gd' in now.files));
  const base = { total: 6, files: { 'sim/core/a.gd': 4, 'render/camera/b.gd': 2 } };
  check('the same count passes', judge(now, base).ok);
  put(root, 'sim/core/a.gd', 'var a = S.fighters[0]\nvar b = S.fighters[1]\nvar c = S.dirS.ex.x\nvar d = SimRoster.opp(S, 0)\nvar e = S.fighters[0]\n');
  const grew = judge(count(root), base);
  check('one more fails and names the file', !grew.ok && grew.grew.length === 1 && grew.grew[0][0] === 'sim/core/a.gd' && grew.grew[0][2] === 5);
  put(root, 'sim/core/a.gd', 'var a = S.fighters[0]\nvar b = S.fighters[1]\n');   // an honest fix: two removed
  const fixed = judge(count(root), base);
  check('an honest fix (fewer) passes and says what shrank', fixed.ok && fixed.shrank.length === 1 && fixed.total === 4);
  put(root, 'sim/core/new.gd', 'var a = S.fighters[0]\n');   // a moved reference: the total still falls, so it is free
  check('moving a reference to a new file is free while the total does not rise', judge(count(root), base).ok);

  // the command line: check, write, refuse to raise
  const bp = join(root, 'baseline.json');
  const run = (...a) => spawnSync(process.execPath, [join(here, 'ratchet-two-fighter.mjs'), '--root', root, '--baseline', bp, ...a], { encoding: 'utf8' });
  let r = run('--write');
  check('--write makes a baseline', r.status === 0 && JSON.parse(readFileSync(bp, 'utf8')).total === count(root).total);
  r = run();
  check('a check against it passes', r.status === 0 && /ratchet ok/.test(r.stdout));
  put(root, 'sim/core/new.gd', 'var a = S.fighters[0]\nvar b = S.fighters[1]\n');
  r = run();
  check('a rise exits 1 and says which file grew', r.status === 1 && /FAILED/.test(r.stdout) && /new\.gd/.test(r.stdout));
  r = run('--write');
  check('--write refuses to raise the baseline', r.status === 1 && /refusing to RAISE/.test(r.stderr));
  put(root, 'sim/core/new.gd', '');
  r = run('--write');
  check('--write lowers it after a fix', r.status === 0 && JSON.parse(readFileSync(bp, 'utf8')).total === count(root).total);
  r = spawnSync(process.execPath, [join(here, 'ratchet-two-fighter.mjs'), '--stray'], { encoding: 'utf8' });
  check('an unknown option exits 2', r.status === 2);
} finally { rmSync(root, { recursive: true, force: true }); }
console.log(bad ? `ratchet self-test FAILED: ${bad}` : 'ratchet self-test ok');
process.exit(bad ? 1 : 0);
