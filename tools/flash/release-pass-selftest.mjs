// Self-test of tools/flash/release-pass.mjs: what makes a recorded pass stale and what does not, on a throwaway git repository, and the rules a record must meet.
//   node tools/flash/release-pass-selftest.mjs
import { execFileSync } from 'node:child_process';
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { contentHash, hashesAt, problemsWith, DIP_GAP_TICKS } from './release-pass.mjs';

let ran = 0, failed = 0;
const check = (name, ok, extra) => { ran++; if (!ok) { failed++; console.log(`  FAIL ${name}${extra ? ': ' + extra : ''}`); } };

const dir = mkdtempSync(join(tmpdir(), 'release-pass-'));
const git = (...a) => execFileSync('git', ['-c', 'user.name=t', '-c', 'user.email=t@t', '-c', 'commit.gpgsign=false', ...a], { cwd: dir, encoding: 'utf8' }).trim();
const put = (p, text) => { mkdirSync(dirname(join(dir, p)), { recursive: true }); writeFileSync(join(dir, p), text); };
const commit = (msg) => { git('add', '-A'); git('commit', '-q', '-m', msg); return git('rev-parse', 'HEAD'); };
try {
  git('init', '-q');
  put('project.godot', 'config/name="x"');
  put('render/a.gd', 'a');
  put('sim/b.gd', 'b');
  put('data/fighters/roster.json', '["A","B"]');
  put('docs/x.md', 'x');
  put('tools/flash/sources.json', '{"scenarios":[],"pairings":[]}');
  put('tools/flash/wcag.js', 'w');
  put('tools/flash/verdict.js', 'v');
  put('render/tools/flash_capture.gd', 'h');
  put('README.md', 'r');
  const c1 = commit('one');
  const h1 = hashesAt(dir, c1);
  put('docs/x.md', 'x changed'); put('README.md', 'r changed'); put('qa/q.js', 'q'); put('.github/w.yml', 'w');
  const c2 = commit('docs, qa, .github and the readme only');
  check('a commit that changes only docs, qa, .github and the readme leaves the content hash alone', hashesAt(dir, c2).contentHash === h1.contentHash);
  put('tools/other.mjs', 'o'); put('research/r.txt', 'r'); put('prototype/p.html', 'p');
  const c2b = commit('tools, research and prototype only');
  check('nor does a change to tools (outside the analyser files), research or the prototype', hashesAt(dir, c2b).contentHash === h1.contentHash);
  put('render/a.gd', 'a changed');
  const c3 = commit('render');
  check('a change to render/ changes it', hashesAt(dir, c3).contentHash !== h1.contentHash);
  put('render/a.gd', 'a'); put('data/new.json', '{}');
  const c4 = commit('back, with new data');
  check('a new file under data/ changes it', hashesAt(dir, c4).contentHash !== h1.contentHash);
  check('the content hash lists the player\'s entries and none of docs, tools, qa', contentHash(dir, c1).entries.every((e) => !/^(docs|tools|qa|research|prototype|README\.md|\.github)\b/.test(e)) && contentHash(dir, c1).entries.length === 4, JSON.stringify(contentHash(dir, c1).entries));
  put('tools/flash/wcag.js', 'w changed');
  const c5 = commit('the analyser');
  check('a change to wcag.js changes the analyser hash and not the content hash', hashesAt(dir, c5).analyserHash !== h1.analyserHash && hashesAt(dir, c5).contentHash === hashesAt(dir, c4).contentHash);
  put('tools/flash/sources.json', '{"scenarios":[1],"pairings":[]}');
  const c6 = commit('the set');
  check('a change to sources.json changes the required-set hash', hashesAt(dir, c6).requiredSetHash !== h1.requiredSetHash);
  put('render/tools/flash_capture.gd', 'h changed');
  const c7 = commit('the staging');
  check('a change to the capture staging changes the hook hash', hashesAt(dir, c7).hookHash !== h1.hookHash);
} finally {
  rmSync(dir, { recursive: true, force: true });
}

// the rules a record must meet
const now = { contentHash: 'c', requiredSetHash: 's', analyserHash: 'a', hookHash: 'h' };
const ids = ['collapse-normal', 'collapse-reduced'];
const row = (id, extra = {}) => ({ id, verdict: 'PASS', shortestDipGapTicks: null, ...extra });
const good = { ...now, rows: ids.map((i) => row(i)) };
check('a record matching the hashes with every required clip PASS holds', problemsWith(good, now, ids).length === 0);
check('no record at all does not hold', problemsWith(null, now, ids).length === 1);
for (const k of Object.keys(now)) check(`a different ${k} does not hold`, problemsWith({ ...good, [k]: 'x' }, now, ids).some((p) => p.startsWith(k)));
check('a missing row does not hold', problemsWith({ ...good, rows: [row('collapse-normal')] }, now, ids).some((p) => /no row for required clip collapse-reduced/.test(p)));
check('an extra row does not hold', problemsWith({ ...good, rows: [...good.rows, row('mash-normal')] }, now, ids).some((p) => /not in the required set/.test(p)));
check('a row that is OVER GATE or FAIL does not hold', problemsWith({ ...good, rows: [row('collapse-normal'), row('collapse-reduced', { verdict: 'OVER GATE' })] }, now, ids).some((p) => /OVER GATE, not PASS/.test(p)) && problemsWith({ ...good, rows: [row('collapse-normal', { verdict: 'FAIL' }), row('collapse-reduced')] }, now, ids).length === 1);
check(`two whole-screen dips closer than ${DIP_GAP_TICKS} ticks do not hold`, problemsWith({ ...good, rows: [row('collapse-normal', { shortestDipGapTicks: DIP_GAP_TICKS - 1 }), row('collapse-reduced')] }, now, ids).some((p) => /dips/.test(p)));
check(`two dips ${DIP_GAP_TICKS} ticks apart hold`, problemsWith({ ...good, rows: [row('collapse-normal', { shortestDipGapTicks: DIP_GAP_TICKS }), row('collapse-reduced')] }, now, ids).length === 0);

console.log(failed ? `release-pass self-test FAILED: ${failed} of ${ran}` : `release-pass self-test ok: ${ran} checks`);
process.exit(failed ? 1 : 0);
