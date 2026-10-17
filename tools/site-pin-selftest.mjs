// Self-test of the pinned deploy (tools/site-pin.mjs): on a throwaway git repository, a LATER game commit leaves the pinned /play/ byte-identical, the recorded pass is stale against the
// later commit (which is why the pin exists) and holds against the pinned one, and the pin follows the record. The exporter is a stub that writes a Web build from the commit's own
// files, so no Godot is needed. CI runs it.
//   node tools/site-pin-selftest.mjs
import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { mkdirSync, mkdtempSync, readdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { hashesAt, problemsWith, INTERIM_WAIVES } from './flash/release-pass.mjs';
import { pinOf, exportPinned } from './site-pin.mjs';

let ran = 0, failed = 0;
const check = (name, ok, extra) => { ran++; if (!ok) { failed++; console.log(`  FAIL ${name}${extra ? ': ' + extra : ''}`); } };

const dir = mkdtempSync(join(tmpdir(), 'site-pin-'));
const git = (...a) => execFileSync('git', ['-c', 'user.name=t', '-c', 'user.email=t@t', '-c', 'commit.gpgsign=false', ...a], { cwd: dir, encoding: 'utf8' }).trim();
const put = (p, text) => { mkdirSync(dirname(join(dir, p)), { recursive: true }); writeFileSync(join(dir, p), text); };
const commit = (msg) => { git('add', '-A'); git('commit', '-q', '-m', msg); return git('rev-parse', 'HEAD'); };
// a tree's hash: every file's path and bytes, sorted
function treeHash(root) {
  const out = [];
  const walk = (d) => { for (const e of readdirSync(d, { withFileTypes: true })) { const p = join(d, e.name); if (e.isDirectory()) walk(p); else out.push(p); } };
  walk(root);
  const h = createHash('sha256');
  for (const p of out.sort()) h.update(p.slice(root.length) + '\0').update(readFileSync(p)).update('\0');
  return h.digest('hex');
}
// the stub exporter: a Godot command line that writes a deterministic "Web build" from the files of the tree it is pointed at
const stub = join(dir, '..', `stub-godot-${process.pid}.mjs`);
writeFileSync(stub, `
import { readFileSync, readdirSync, writeFileSync, mkdirSync, existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
const a = process.argv.slice(2);
const path = a[a.indexOf('--path') + 1];
const ex = a.indexOf('--export-release');
if (ex < 0) process.exit(0);   // --import: nothing
const out = a[ex + 2];
const walk = (d) => readdirSync(d, { withFileTypes: true }).flatMap((e) => e.name === '.git' ? [] : e.isDirectory() ? walk(join(d, e.name)) : [join(d, e.name)]);
const files = walk(path).sort();
let pck = '';
for (const f of files) pck += f.slice(path.length) + '\\n' + readFileSync(f, 'utf8') + '\\n';
mkdirSync(dirname(out), { recursive: true });
writeFileSync(join(dirname(out), 'index.pck'), pck);
writeFileSync(out, '<!doctype html><title>Orb Combat EX</title><!-- build ' + (existsSync(join(path, 'build_info.json')) ? readFileSync(join(path, 'build_info.json'), 'utf8').trim() : 'none') + ' -->\\n');
`);

try {
  git('init', '-q');
  put('project.godot', 'config/name="x"');
  put('render/a.gd', 'a v1');
  put('sim/b.gd', 'b');
  put('data/fighters/roster.json', '["A","B"]');
  put('tools/flash/sources.json', '{"scenarios":[],"pairings":[]}');
  put('tools/flash/wcag.js', 'w');
  put('tools/flash/verdict.js', 'v');
  put('render/tools/flash_capture.gd', 'h');
  const A = commit('the measured commit');
  // the record of a pass for A, with an interim (the clips are not the point: the hashes are)
  const ids = ['collapse-normal'];
  const record = { hookFixed: true, extraSeeds: { seeds: Array.from({ length: 22 }, (_, i) => 1008 + i), clips: 44, maxPrimary: 2.5, rows: Array.from({ length: 22 }, (_, i) => ['normal', 'reduced'].map((m) => ({ id: 'ai-' + (1008 + i) + '-' + m, primary: 2.5, red: 0, reduceFlashing: m === 'reduced' }))).flat() }, ...hashesAt(dir, A), commit: A, hud: { perSecond: 2, limit: 3 }, seedPick: { seeds: [1] }, rows: ids.map((id) => ({ id, verdict: 'PASS', red: 0, reduceFlashing: /-reduced$/.test(id), flashCalm: /-reduced$/.test(id), probe: { 60: id }, guard: { framesPerSecond: 5 }, shortestDipGapTicks: null })), interim: { legal: 'RL-136', from: '2026-10-15', expires: '2026-10-22', waives: INTERIM_WAIVES } };
  const recFile = join(dir, '..', `record-${process.pid}.json`);
  writeFileSync(recFile, JSON.stringify(record));
  const online = { offline: false, approved: '2026-10-15', interim: { legal: 'RL-136', expires: '2026-10-22' } };

  // the pin follows the record
  const p0 = pinOf(online, recFile);
  check('an online site is pinned to the recorded commit', p0.pin === A && p0.problems.length === 0, JSON.stringify(p0));
  check('an offline site has no pin', pinOf({ offline: true, approved: null, interim: null }, recFile).pin === '');
  check('a "pin" in site.json that is not the recorded commit is refused', pinOf({ ...online, pin: 'f'.repeat(40) }, recFile).problems.length === 1);
  check('a "pin" equal to the recorded commit is accepted', pinOf({ ...online, pin: A }, recFile).pin === A);
  check('an online site with no recorded pass is refused', pinOf(online, join(dir, 'nope.json')).problems.length === 1);
  check('a record with no full commit is refused', (() => { const f = join(dir, '..', `rec-nocommit-${process.pid}.json`); writeFileSync(f, JSON.stringify({ ...record, commit: 'abc1234' })); const r = pinOf(online, f); rmSync(f); return r.problems.length >= 1 && r.pin === ''; })());

  // export the pinned commit, then move main on with a game commit and export the pin again
  const web1 = join(dir, '..', `web1-${process.pid}`), tree1 = join(dir, '..', `tree1-${process.pid}`);
  exportPinned(A, web1, { repo: dir, tree: tree1, godotNode: stub });
  const hash1 = treeHash(web1);
  check('the pinned export has an index.html, a pack and the pinned commit\'s own build_info', /build \{"commit":"[0-9a-f]{7}"/.test(readFileSync(join(web1, 'index.html'), 'utf8')) && readFileSync(join(web1, 'index.pck'), 'utf8').includes('a v1'));
  put('render/a.gd', 'a v2: a later game commit');
  put('sim/b.gd', 'b changed too');
  const B = commit('a later game commit: main keeps moving');
  check('the later commit is a different commit', B !== A);
  check('the recorded pass is STALE against the later commit (why a branch-tip build cannot stay green)', problemsWith(record, hashesAt(dir, B), ids, { today: '2026-10-16' }).some((p) => /contentHash differs/.test(p)));
  check('the recorded pass HOLDS against the pinned commit', problemsWith(record, hashesAt(dir, A), ids, { today: '2026-10-16' }).length === 0);
  check('the pin is still the recorded commit after the later commit', pinOf(online, recFile).pin === A);
  const web2 = join(dir, '..', `web2-${process.pid}`), tree2 = join(dir, '..', `tree2-${process.pid}`);
  exportPinned(pinOf(online, recFile).pin, web2, { repo: dir, tree: tree2, godotNode: stub });
  check('/play/ after the later game commit is BYTE-IDENTICAL to the pinned export', treeHash(web2) === hash1);
  const webHead = join(dir, '..', `webhead-${process.pid}`), treeHead = join(dir, '..', `treehead-${process.pid}`);
  exportPinned(B, webHead, { repo: dir, tree: treeHead, godotNode: stub });
  check('a build of the branch tip WOULD differ (the test can tell)', treeHash(webHead) !== hash1);
  // a record pointed at the new run changes the published game, and nothing else does
  const record2 = { ...record, ...hashesAt(dir, B), commit: B };
  const rec2 = join(dir, '..', `record2-${process.pid}.json`);
  writeFileSync(rec2, JSON.stringify(record2));
  check('recording a new run and pointing at it moves the pin to the new commit', pinOf(online, rec2).pin === B);
  for (const d of [web1, tree1, web2, tree2, webHead, treeHead, recFile, rec2, stub]) rmSync(d, { recursive: true, force: true });
} finally {
  rmSync(dir, { recursive: true, force: true });
}
console.log(failed ? `site pin self-test FAILED: ${failed} of ${ran} checks` : `site pin self-test ok: ${ran} checks`);
process.exit(failed ? 1 : 0);
