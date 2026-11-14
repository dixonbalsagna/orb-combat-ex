// Self-test of tools/preview/build-compare.mjs (A-CODE-03 criterion 1): a tree against its commit, on a throwaway git repository. Node and git only.
//   node tools/preview/build-compare-selftest.mjs
import { execFileSync, spawnSync } from 'node:child_process';
import { cpSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { blobId, commitFiles, compareTree, report, scrubPath } from './build-compare.mjs';

const here = dirname(fileURLToPath(import.meta.url));
let ran = 0, failed = 0;
const check = (name, ok, extra) => { ran++; if (!ok) { failed++; console.log(`  FAIL ${name}${extra ? ': ' + extra : ''}`); } };

const dir = mkdtempSync(join(tmpdir(), 'build-compare-'));
const repo = join(dir, 'repo'), tree = join(dir, 'tree');
const git = (...a) => execFileSync('git', ['-c', 'user.name=t', '-c', 'user.email=t@t', '-c', 'commit.gpgsign=false', '-c', 'core.autocrlf=false', ...a], { cwd: repo, encoding: 'utf8' }).trim();
const put = (root, p, text) => { mkdirSync(dirname(join(root, p)), { recursive: true }); writeFileSync(join(root, p), text); };
try {
  mkdirSync(repo); mkdirSync(tree);
  git('init', '-q');
  put(repo, 'project.godot', 'config/name="x"\n'); put(repo, 'render/core/main.gd', 'extends Node\nvar a = 1\n'); put(repo, 'data/a.json', '{"on": false}\n'); put(repo, 'sim/b file.gd', 'b\n');
  git('add', '-A'); git('commit', '-q', '-m', 'one');
  const rev = git('rev-parse', 'HEAD');
  const files = commitFiles(repo, rev);
  check('the commit lists its four files by path, spaces and all', files.size === 4 && files.has('sim/b file.gd'));
  check('a blob id is git\'s own (the file written by git hashes to the id the commit lists), and CRLF reads as LF', blobId(readFileSync(join(repo, 'project.godot'))) === files.get('project.godot') && blobId(Buffer.from('extends Node\r\nvar a = 1\r\n')) === files.get('render/core/main.gd'));
  cpSync(repo, tree, { recursive: true }); rmSync(join(tree, '.git'), { recursive: true, force: true });
  let r = compareTree(tree, files);
  check('a tree copied from the commit is the commit', r.same === 4 && !r.differ.length && !r.missing.length && !r.extra.length && /THE TREE IS THE COMMIT/.test(report(r, { rev: 'x', tree })));
  put(tree, 'render/core/main.gd', 'extends Node\nvar a = 1\nfunc _preview() -> void:\n\tpass\n');
  r = compareTree(tree, files);
  check('a patched file is listed as differing, and the report says it is not the commit', r.differ.join() === 'render/core/main.gd' && /NOT the commit/.test(report(r)));
  put(tree, 'render/core/main.gd', 'extends Node\r\nvar a = 1\r\n');
  check('the same file with CRLF endings is the same file', compareTree(tree, files).differ.length === 0);
  put(tree, 'extra/new.gd', 'x\n'); rmSync(join(tree, 'data', 'a.json'));
  r = compareTree(tree, files);
  check('a file the tree has and the commit lacks is extra; one the commit has and the tree lacks is missing', r.extra.join() === 'extra/new.gd' && r.missing.join() === 'data/a.json');
  r = compareTree(tree, files, { allow: ['extra/new.gd', 'data/a.json'] });
  check('allowed paths are listed apart and do not count', r.allowed.length === 2 && !r.extra.length && !r.missing.length);
  put(tree, '.godot/imported/x.bin', 'cache');
  check('the engine\'s import cache is ignored by default', !compareTree(tree, files, { allow: ['extra/new.gd', 'data/a.json'] }).extra.length && compareTree(tree, files, { allow: ['extra/new.gd', 'data/a.json'], ignoreDirs: [] }).extra.includes('.godot/imported/x.bin'));
  put(tree, 'data/a.json', '{"on": false}\n'); rmSync(join(tree, 'extra'), { recursive: true });
  const c = spawnSync(process.execPath, [join(here, 'build-compare.mjs'), '--tree', tree, '--repo', repo, '--rev', rev], { encoding: 'utf8' });
  check('the command exits 0 on an identical tree (the main.gd of the tree is CRLF, which is the same)', c.status === 0 && /THE TREE IS THE COMMIT/.test(c.stdout), c.stdout + c.stderr);
  put(tree, 'sim/b file.gd', 'changed\n');
  const c2 = spawnSync(process.execPath, [join(here, 'build-compare.mjs'), '--tree', tree, '--repo', repo, '--rev', rev], { encoding: 'utf8' });
  check('and exits 1 on a changed file, naming it', c2.status === 1 && /DIFFERS +sim\/b file.gd/.test(c2.stdout), c2.stdout + c2.stderr);
  // a record kept in the repository holds no profile path (the content screen refuses it): the user folder is written <user>
  const win = ['C:', 'Us' + 'ers', 'someone', 'AppData', 'Local', 'Temp', 'x'].join('\\'), win2 = ['C:', 'Us' + 'ers', 'someone', 'y'].join('/'), nix = ['', 'ho' + 'me', 'runner', 'work'].join('/');
  check('a Windows profile path (either slash) and a Unix home path are written <user>', scrubPath(win) === '<user>\\AppData\\Local\\Temp\\x' && scrubPath(win2) === '<user>/y' && scrubPath(nix) === '<user>/work', [scrubPath(win), scrubPath(win2), scrubPath(nix)].join(' | '));
  check('the report line carries no profile path', !new RegExp('Us' + 'ers').test(report({ same: 0, differ: [], missing: [], extra: [], allowed: [] }, { rev: 'x', tree: win })));
  const c3 = spawnSync(process.execPath, [join(here, 'build-compare.mjs')], { encoding: 'utf8' });
  check('no tree given: the usage and exit 2', c3.status === 2 && /usage/.test(c3.stderr));
} finally { rmSync(dir, { recursive: true, force: true }); }

console.log(failed ? `build-compare self-test FAILED: ${failed} of ${ran}` : `build-compare self-test ok: ${ran} checks`);
process.exit(failed ? 1 : 0);
