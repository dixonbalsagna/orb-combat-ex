// Self-test of tools/flash/head-export.mjs (the HEAD export check-clip.mjs --head uses): a throwaway repository, a revision unpacked into a new folder, the failures that must say why, and
// no tar file left behind. No Godot, no network. CI runs it.
//   node tools/flash/head-export-selftest.mjs
import { execFileSync } from 'node:child_process';
import { existsSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { exportRevision } from './head-export.mjs';

let ran = 0, failed = 0;
const check = (name, ok, extra) => { ran++; if (!ok) { failed++; console.log(`  FAIL ${name}${extra ? ': ' + extra : ''}`); } };
const tmp = mkdtempSync(join(tmpdir(), 'head-export-'));
// git archive writes the working-tree line endings (core.autocrlf), so compare text with them normalised
const text = (p) => readFileSync(p, 'utf8').split(String.fromCharCode(13)).join('');
const git = (cwd, ...a) => execFileSync('git', ['-c', 'user.name=t', '-c', 'user.email=t@example.invalid', '-c', 'commit.gpgsign=false', ...a], { cwd, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] });

try {
  const repo = join(tmp, 'repo');
  mkdirSync(join(repo, 'sub dir'), { recursive: true });
  git(repo, 'init', '-q');
  writeFileSync(join(repo, 'a.txt'), 'first\n');
  writeFileSync(join(repo, 'sub dir', 'b.txt'), 'with a space in the folder\n');
  git(repo, 'add', '-A');
  git(repo, 'commit', '-q', '-m', 'one');
  writeFileSync(join(repo, 'a.txt'), 'second, committed\n');
  git(repo, 'commit', '-q', '-am', 'two');
  writeFileSync(join(repo, 'a.txt'), 'third, NOT committed\n');
  writeFileSync(join(repo, 'untracked.txt'), 'x');

  const dest = join(tmp, 'out', 'head-1');
  const r = exportRevision(repo, dest);
  check('HEAD is unpacked into a new folder', r.ok === true, JSON.stringify(r));
  check('it is the committed tree: the committed text, not the working copy\'s, and no untracked file', text(join(dest, 'a.txt')) === 'second, committed\n' && !existsSync(join(dest, 'untracked.txt')));
  check('a folder with a space in its name comes through', text(join(dest, 'sub dir', 'b.txt')) === 'with a space in the folder\n');
  check('no .git in the copy', !existsSync(join(dest, '.git')));
  check('the tar file is removed', readdirSync(join(tmp, 'out')).every((f) => !f.endsWith('.tar')), readdirSync(join(tmp, 'out')).join(','));
  const older = exportRevision(repo, join(tmp, 'out', 'prev'), 'HEAD~1');
  check('another revision can be asked for', older.ok && text(join(tmp, 'out', 'prev', 'a.txt')) === 'first\n');

  const notRepo = join(tmp, 'plain'); mkdirSync(notRepo);
  const bad = exportRevision(notRepo, join(tmp, 'out', 'bad'));
  check('a folder that is not a git repository fails and says so, with the hint', bad.ok === false && /git archive HEAD failed/.test(bad.message) && /not a git repository/i.test(bad.message) && /git checkout/.test(bad.message), bad.message);
  const noRev = exportRevision(repo, join(tmp, 'out', 'norev'), 'no-such-rev');
  check('a revision that does not exist fails and names it', noRev.ok === false && /no-such-rev/.test(noRev.message), noRev.message);
  const noDir = exportRevision(join(tmp, 'missing'), join(tmp, 'out', 'nodir'));
  check('a repository folder that does not exist fails and says so', noDir.ok === false && /does not exist/.test(noDir.message), noDir.message);
  check('a failed export leaves no tar file behind', readdirSync(join(tmp, 'out')).every((f) => !f.endsWith('.tar')));
} finally {
  rmSync(tmp, { recursive: true, force: true });
}
console.log(failed ? `head export self-test FAILED: ${failed} of ${ran}` : `head export self-test ok: ${ran} checks`);
process.exit(failed ? 1 : 0);
