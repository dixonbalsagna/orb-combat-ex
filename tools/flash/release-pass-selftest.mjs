// Self-test of tools/flash/release-pass.mjs: what makes a recorded pass stale and what does not, on a throwaway git repository, and the rules a record must meet.
//   node tools/flash/release-pass-selftest.mjs
import { execFileSync } from 'node:child_process';
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { contentHash, hashesAt, problemsWith, DIP_GAP_TICKS, verdictOf, effective } from './release-pass.mjs';
import { setFor } from './which-set.mjs';
import { pickSeeds, worstSeedsOf, parseScan } from './pick-seeds.mjs';

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
const GUARD = { cpuPercent: 25, timeoutS: 3600, tag: 'cap-tools-flash-abc123', framesPerSecond: 4, loadBefore: 20, loadAfter: 35 };
const row = (id, extra = {}) => ({ id, verdict: 'PASS', shortestDipGapTicks: null, guard: GUARD, ...extra });
const RECORD_LINES = { hud: { perSecond: 1.5, limit: 3, source: 'hud_check' }, seedPick: { rule: 'pick-seeds.mjs', seeds: [12345, 4] } };
const good = { ...now, ...RECORD_LINES, rows: ids.map((i) => row(i)) };
check('a record matching the hashes with every required clip PASS holds', problemsWith(good, now, ids).length === 0);
check('no record at all does not hold', problemsWith(null, now, ids).length === 1);
for (const k of Object.keys(now)) check(`a different ${k} does not hold`, problemsWith({ ...good, [k]: 'x' }, now, ids).some((p) => p.startsWith(k)));
check('a missing row does not hold', problemsWith({ ...good, rows: [row('collapse-normal')] }, now, ids).some((p) => /no row for required clip collapse-reduced/.test(p)));
check('an extra row does not hold', problemsWith({ ...good, rows: [...good.rows, row('mash-normal')] }, now, ids).some((p) => /not in the required set/.test(p)));
check('a row that is OVER GATE or FAIL does not hold', problemsWith({ ...good, rows: [row('collapse-normal'), row('collapse-reduced', { verdict: 'OVER GATE' })] }, now, ids).some((p) => /OVER GATE, not PASS/.test(p)) && problemsWith({ ...good, rows: [row('collapse-normal', { verdict: 'FAIL' }), row('collapse-reduced')] }, now, ids).length === 1);
check(`two whole-screen dips closer than ${DIP_GAP_TICKS} ticks do not hold`, problemsWith({ ...good, rows: [row('collapse-normal', { shortestDipGapTicks: DIP_GAP_TICKS - 1 }), row('collapse-reduced')] }, now, ids).some((p) => /dips/.test(p)));
check(`two dips ${DIP_GAP_TICKS} ticks apart hold`, problemsWith({ ...good, rows: [row('collapse-normal', { shortestDipGapTicks: DIP_GAP_TICKS }), row('collapse-reduced')] }, now, ids).length === 0);

// the margin rules (Legal's addendum 6, RL-128)
const rowM = (id, extra = {}) => row(id, { primary: 2, areaLower: 2, stricter: 2, marginal: '0/4', ...extra });
const rec = (rows, extra = {}) => ({ ...now, ...RECORD_LINES, rows, ...extra });
const pM = (rows) => problemsWith(rec(rows), now, ids);
check('readings that agree and no change near the threshold hold', pM([rowM('collapse-normal'), rowM('collapse-reduced')]).length === 0);
check('readings more than 1.0 apart are sensitive: no re-capture, no pass', pM([rowM('collapse-normal', { primary: 2, areaLower: 3.5, stricter: 2 }), rowM('collapse-reduced')]).some((p) => /sensitive.*no re-capture/.test(p)));
check('readings exactly 1.0 apart are not sensitive', pM([rowM('collapse-normal', { primary: 2, areaLower: 3, stricter: 2 }), rowM('collapse-reduced')]).length === 0);
check('the memory reading counts in the spread', pM([rowM('collapse-normal', { primary: 1, areaLower: 1.5, stricter: 3 }), rowM('collapse-reduced')]).some((p) => /sensitive/.test(p)));
check('a sensitive row with a passing, steady re-capture at another seed holds', pM([rowM('collapse-normal', { primary: 2, areaLower: 3.5, stricter: 2, recapture: { verdict: 'PASS', how: 'seed 7', primary: 2, areaLower: 2.5, stricter: 2, marginal: '0/4' } }), rowM('collapse-reduced')]).length === 0);
check('a re-capture that is not PASS does not count', pM([rowM('collapse-normal', { primary: 2, areaLower: 3.5, stricter: 2, recapture: { verdict: 'FAIL', how: 'seed 7', primary: 4, areaLower: 4, stricter: 4 } }), rowM('collapse-reduced')]).some((p) => /re-capture .* is FAIL/.test(p)));
check('a re-capture that is itself sensitive does not count', pM([rowM('collapse-normal', { primary: 2, areaLower: 3.5, stricter: 2, recapture: { verdict: 'PASS', how: 'skip 600', primary: 1, areaLower: 3, stricter: 1.5 } }), rowM('collapse-reduced')]).some((p) => /still sensitive/.test(p)));
check('a change within 15% above the threshold in a second that totals 2.5 does not hold', pM([rowM('collapse-normal', { primary: 2.5, areaLower: 2.5, stricter: 2.5, marginal: '1/5' }), rowM('collapse-reduced')]).some((p) => /within 15% above the area threshold/.test(p)));
check('the same change in a second that totals 2.0 holds', pM([rowM('collapse-normal', { primary: 2, marginal: '1/4' }), rowM('collapse-reduced')]).length === 0);
check('the numeric marginalCount is read as well as the older string', pM([rowM('collapse-normal', { primary: 2.5, areaLower: 2.5, stricter: 2.5, marginal: undefined, marginalCount: 2 }), rowM('collapse-reduced')]).some((p) => /2 counted changes/.test(p)));
check('a clip at exactly 3 on the primary reading is OVER GATE and does not hold', pM([rowM('collapse-normal', { verdict: 'OVER GATE', primary: 3 }), rowM('collapse-reduced')]).some((p) => /OVER GATE, not PASS/.test(p)));

// which set a change needs (docs/tools/release-set-plan.md)
check('a change to the camera needs the full set', setFor(['render/camera/split_rig.gd', 'docs/x.md']).set === 'FULL');
check('a change to the scenery data needs the full set', setFor(['data/biomes/lanes.json']).set === 'FULL');
check('a change to the simulation needs the AI seeds only', setFor(['sim/director/brawl.gd', 'tools/x.js']).set === 'AI');
check('a change to docs and tools needs none', setFor(['docs/x.md', 'tools/flash/a.mjs', 'README.md']).set === 'NONE');

// RL-131 (Legal's addendum 7): the capture's condition, the second capture, steadiness, the kind of re-capture, the HUD line and the seed pick
check('a row with no recorded capture condition does not hold', pM([rowM('collapse-normal', { guard: null }), rowM('collapse-reduced')]).some((p) => /no recorded capture condition/.test(p)));
check('a clip captured under 1 frame a second (a starved machine) is void', pM([rowM('collapse-normal', { guard: { ...GUARD, framesPerSecond: 0.4 } }), rowM('collapse-reduced')]).some((p) => /starved and the clip is void/.test(p)));
check('a clip at 2.0 or below needs no second capture', pM([rowM('collapse-normal', { primary: 2 }), rowM('collapse-reduced')]).length === 0);
check('a clip above 2.0 with no second capture does not hold', pM([rowM('collapse-normal', { primary: 2.5, areaLower: 2.5, stricter: 2.5 }), rowM('collapse-reduced')]).some((p) => /needs a second independent capture/.test(p)));
const withSecond = (extra) => rowM('collapse-normal', { primary: 2.5, areaLower: 2.5, stricter: 2.5, second: { primary: 2.5, areaLower: 2.5, stricter: 2.5, marginal: '0/5', guard: GUARD, ...extra } });
check('a clip above 2.0 with a steady second capture holds', pM([withSecond({}), rowM('collapse-reduced')]).length === 0);
check('two captures that differ by more than 0.5 are flagged and re-run', pM([withSecond({ primary: 2, areaLower: 2, stricter: 2 }), rowM('collapse-reduced')]).some((p) => /differ by 0\.5? ?|differ by [0-9.]+ \(more than 0\.5\)/.test(p)) || pM([withSecond({ primary: 1.5 }), rowM('collapse-reduced')]).some((p) => /more than 0\.5/.test(p)));
check('two captures 0.5 apart are steady', pM([withSecond({ primary: 2, areaLower: 2.5, stricter: 2.5 }), rowM('collapse-reduced')]).length === 0);
check('the worse reading counts: a second capture at 3 makes it OVER GATE', pM([rowM('collapse-normal', { primary: 2.5, areaLower: 2.5, stricter: 2.5, second: { primary: 3, areaLower: 3, stricter: 3, guard: GUARD, marginal: '0/6' } }), rowM('collapse-reduced')]).some((p) => /worse readings are OVER GATE/.test(p)));
check('a second capture taken on a starved machine is void', pM([withSecond({ guard: { ...GUARD, framesPerSecond: 0.5 } }), rowM('collapse-reduced')]).some((p) => /second capture was taken on a starved machine/.test(p)));
check('a sensitive clip re-captured as a later window (skip) of the same run does not count', pM([rowM('collapse-normal', { primary: 2, areaLower: 3.5, stricter: 2, recapture: { verdict: 'PASS', how: 'skip 600', primary: 2, areaLower: 2, stricter: 2, marginal: '0/4' } }), rowM('collapse-reduced')]).some((p) => /different run/.test(p)));
check('a sensitive clip re-captured at another seed or a variant counts', pM([rowM('collapse-normal', { primary: 2, areaLower: 3.5, stricter: 2, recapture: { verdict: 'PASS', how: 'variant 2', primary: 2, areaLower: 2, stricter: 2, marginal: '0/4' } }), rowM('collapse-reduced')]).length === 0);
check('a record with no HUD line does not hold', problemsWith({ ...now, seedPick: RECORD_LINES.seedPick, rows: ids.map((i) => row(i)) }, now, ids).some((p) => /no HUD line/.test(p)));
check('a HUD over 3 a second does not hold', problemsWith({ ...good, hud: { perSecond: 3.5 } }, now, ids).some((p) => /HUD's own rate is 3\.5/.test(p)));
check('a record that does not list its seeds does not hold', problemsWith({ ...good, seedPick: undefined }, now, ids).some((p) => /does not list the AI seeds/.test(p)));
check('the combined rule on three readings', verdictOf({ primary: 2.5, areaLower: 3, stricter: 3 }) === 'PASS' && verdictOf({ primary: 3, areaLower: 3, stricter: 3 }) === 'OVER GATE' && verdictOf({ primary: 2, areaLower: 3.5, stricter: 2 }) === 'FAIL');
check('effective readings are the worse of the two captures', JSON.stringify(effective({ primary: 2, areaLower: 2.5, stricter: 1, second: { primary: 2.5, areaLower: 2, stricter: 1.5 } })) === JSON.stringify({ primary: 2.5, areaLower: 2.5, stricter: 1.5, marginalCount: 0 }));

// the seed pick (RL-131 answers 2 and 3)
{
  const mk = (seed, sig, beams = { HIT: 1 }, ev = { building_fall: 0, shot_hit: 4, transform: 3 }) => ({ seed, sig, beams, ev });
  const scan = [];
  for (let s = 1; s <= 40; s++) scan.push(mk(s, s % 3 === 0 ? { A: 1, B: 1 } : s % 3 === 1 ? { A: 1 } : {}, s % 4 === 0 ? { CLASH: 1, HIT: 1 } : { HIT: 1 }));
  const one = { pairings: [{ key: 'A,B', slots: ['A', 'B'], scan }], total: 10 };
  const a = pickSeeds(one), b = pickSeeds(one);
  check('the seed pick is deterministic', JSON.stringify(a) === JSON.stringify(b));
  check('it picks the total, once each', a.seeds['A,B'].length === 10 && new Set(a.seeds['A,B']).size === 10);
  check('it prefers seeds that show both signatures', a.seeds['A,B'].every((s) => s % 3 === 0));
  const k = pickSeeds({ ...one, failed: [{ pairing: 'A,B', seed: 2 }], worst: [{ pairing: 'A,B', seed: 7 }, { pairing: 'A,B', seed: 11 }] });
  check('a failed seed and the worst seeds of the last release are kept, first', k.seeds['A,B'].slice(0, 3).join() === '2,7,11' && k.kept.failed.length === 1 && k.kept.worst.length === 2);
  const sigOnly = [];
  for (let s = 1; s <= 12; s++) sigOnly.push(mk(s, s <= 4 ? { A: 1 } : { B: 1 }));
  const cov = pickSeeds({ pairings: [{ key: 'A,B', slots: ['A', 'B'], scan: sigOnly }], total: 6 });
  check('every signature is in at least 2 of the matches when the scan allows', cov.warnings.length === 0 && cov.seeds['A,B'].filter((s) => s <= 4).length >= 2 && cov.seeds['A,B'].filter((s) => s > 4).length >= 2);
  const none = pickSeeds({ pairings: [{ key: 'A,B', slots: ['A', 'B'], scan: [mk(1, { A: 1 }), mk(2, { A: 1 })] }], total: 2 });
  check("a signature the scan never shows is a warning, not a silent pass", none.warnings.some((w) => /signature of B/.test(w)));
  const many = ['P', 'Q', 'R', 'S'].map((x, i) => ({ key: x + ',Z', slots: [x, 'Z'], scan: scan.slice(0, 6).map((r) => ({ ...r, sig: { [x]: 1, Z: 1 } })) }));
  const rot = pickSeeds({ pairings: many, total: 2, coverage: { 'P,Z': '2026-10-01', 'Q,Z': null, 'R,Z': '2026-09-01', 'S,Z': null } });
  check('with more pairings than seeds the uncaptured are taken first, one seed each', Object.keys(rot.seeds).sort().join() === 'Q,Z,S,Z'.split(',Z').join(',Z').replace(/^/, '') || (Object.keys(rot.seeds).length === 2 && Object.keys(rot.seeds).every((x) => x === 'Q,Z' || x === 'S,Z')));
  const rec = { rows: [{ id: 'ai-5-normal', primary: 2.5, areaLower: 2.5, stricter: 2 }, { id: 'ai-5-reduced', primary: 2, areaLower: 3, stricter: 2 }, { id: 'ai-9-normal', primary: 1, areaLower: 1, stricter: 1 }, { id: 'collapse-normal', primary: 3, areaLower: 3, stricter: 3 }] };
  const w = worstSeedsOf(rec, 'A,B');
  check('the worst seeds of a record are read from the ai rows by the worse reading', w.length === 2 && w[0].seed === 5 && w[0].reading === 3 && w[1].seed === 9);
  check('the scan output is parsed', parseScan('seed   6: 3600 ticks sig {"PROTAGONIST":1,"RIVAL":2} beams {"CLASH":1,"HIT":2} {"building_fall":4,"shot_hit":11,"transform":4}').length === 1);
}

console.log(failed ? `release-pass self-test FAILED: ${failed} of ${ran}` : `release-pass self-test ok: ${ran} checks`);
process.exit(failed ? 1 : 0);
