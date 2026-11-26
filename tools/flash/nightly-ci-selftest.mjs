// Self-test of tools/flash/nightly-ci.mjs, the verdict of the scheduled flash reading (CD-09; A-LEGAL-08). Node built-ins only; no browser, no build.
//   node tools/flash/nightly-ci-selftest.mjs
import { spawnSync } from 'node:child_process';
import { mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { EXPECTED, judge, readingOf, readSummaries, report } from './nightly-ci.mjs';
import { requiredClips } from './clips.mjs';

const here = dirname(fileURLToPath(import.meta.url));
let ran = 0, failed = 0;
const check = (name, ok, extra) => { ran++; if (!ok) { failed++; console.log(`  FAIL ${name}${extra ? ': ' + extra : ''}`); } };

// the night clips (CD-09 item 5): every night's expected clip exists in the required set, with its own page words, so a clip the reading expects can be captured
{
  const ids = new Map(requiredClips().map((c) => [c.id, c]));
  check('every clip the night reads is in the required set (sources.json)', EXPECTED.every((id) => ids.has(id)), EXPECTED.filter((id) => !ids.has(id)).join());
  const n = ids.get('clash-night-reduced');
  check('the night clash is the clash scene under the page word sky=night, both modes', !!n && n.scenario === 'clash' && n.words === 'sky=night' && n.reduced === true && ids.get('clash-night-normal').reduced === false);
  check('no other clip carries page words', [...ids.values()].filter((c) => c.words).map((c) => c.id).join() === 'clash-night-normal,clash-night-reduced');
}

// the workflow's matrix, this verdict's list and the windows name the same clips (a clip added to one and not the others is a job that cannot be judged)
{
  const m = readFileSync(join(here, '..', '..', '.github', 'workflows', 'flash-nightly.yml'), 'utf8').match(/clip: \[([^\]]*)\]/);
  const matrix = m ? m[1].split(',').map((s) => s.trim()).filter(Boolean) : [];
  check('the nightly workflow reads exactly the clips this verdict expects', JSON.stringify(matrix) === JSON.stringify(EXPECTED), matrix.join());
  const win = JSON.parse(readFileSync(join(here, 'nightly-windows.json'), 'utf8')).clips;
  check('every clip the night reads has its own window (not the speed trial default)', EXPECTED.every((id) => win[id] && win[id].ticks > 0), EXPECTED.filter((id) => !win[id]).join());
}

const row = (id, primary, red = 0, area15 = primary, twoSec = primary) => ({ id, result: { general: { flashes: primary }, red: { flashes: red }, combined: { lower: area15, stricter: twoSec } } });
const clean = () => EXPECTED.map((id) => row(id, 1.5));

check('a night where every expected clip reads under our gate is clean (exit 0)', judge(clean()).code === 0);
check('the four direct numbers of a row are the primary, the red, the area-15% and the two-second-memory readings', JSON.stringify(readingOf(row('x', 2, 1, 2.5, 3))) === JSON.stringify({ primary: 2, red: 1, area15: 2.5, twoSec: 3 }));
check('a row with no result reads as null', readingOf({ id: 'x' }) === null && readingOf(null) === null);

let rows = clean(); rows[0] = row('clash-normal', 2.5);
check('exactly our gate of 2.5 is clean', judge(rows).code === 0);
rows[0] = row('clash-normal', 3);
check('3 on the primary reading is a finding (3), not the take-down: the line is "over 3"', judge(rows).code === 3);
rows[0] = row('clash-normal', 3.5);
check('3.5 on the primary reading crosses the line (1)', judge(rows).code === 1 && /OVER THE LINE clash-normal: primary reads 3.5/.test(judge(rows).problems.join('\n')));
rows[0] = row('clash-normal', 2, 0, 3.5, 2);
check('the area-15% reading over the line counts although the primary does not', judge(rows).code === 1 && /area-15%/.test(judge(rows).problems.join('')));
rows[0] = row('clash-normal', 2, 0, 2, 3.5);
check('the two-second-memory reading over the line counts', judge(rows).code === 1 && /two-second memory/.test(judge(rows).problems.join('')));
rows[0] = row('clash-normal', 1, 3.5);
check('red read directly: a red count over the line crosses it even with a calm general count', judge(rows).code === 1 && /red reads 3.5/.test(judge(rows).problems.join('')));
rows[0] = row('clash-normal', 1, 3);
check('a red count of exactly 3 does not cross the line', judge(rows).code === 0);

rows = clean().filter((r) => r.id !== 'signature-reduced');
check('a missing clip is exit 2 and says which: a missing clip is never a pass', judge(rows).code === 2 && /signature-reduced: no row/.test(judge(rows).problems.join('')));
rows = clean(); rows[1] = { id: 'clash-reduced', error: 'the page offers no window.__flashcap' };
check('a clip with an error is exit 2', judge(rows).code === 2 && /clash-reduced/.test(judge(rows).problems.join('')));
rows = clean(); rows[2] = { id: 'collapse-normal', result: {} };
check('a row with an empty result is exit 2', judge(rows).code === 2);
rows = clean(); rows[1] = row('clash-reduced', 5); rows[2] = { id: 'collapse-normal', error: 'x' };
check('a clip not read outranks a clip over the line (2 before 1)', judge(rows).code === 2);
check('a night with no rows at all is exit 2', judge([]).code === 2 && judge(null).code === 2);
rows = clean(); rows.push(row('mash-normal', 9));
check('a clip that is not in the expected set is noted and does not change the verdict', judge(rows).code === 0 && judge(rows).lines.some((l) => /mash-normal/.test(l)));
check('the line is a parameter', judge([row('clash-normal', 2.7)], { expected: ['clash-normal'], line: 2.5 }).code === 1);
check('the expected set is a parameter (the night-sky clip joins it later)', judge(clean(), { expected: [...EXPECTED, 'nightsky-normal'] }).code === 2);

const text = report(judge(clean()));
check('the report is a table with a verdict line', /^clip +primary +red +area-15% +2 s mem/.test(text) && /nightly flash reading: flash reading clean$/.test(text));

// the expected-over baseline (the EP, 2026-11-21): red when worse than recorded, new, or not read; green when every clip equals or beats its recorded value; the line of 3 is not what it asks
{
  const bl = Object.fromEntries(EXPECTED.map((id) => [id, { primary: 4.5, red: 0, area15: 4.5, twoSec: 4.5 }]));
  const equal = () => EXPECTED.map((id) => row(id, 4.5));
  check('baseline: every clip exactly at its recorded value is green (0) although 4.5 is over the line of 3', judge(equal(), { baseline: bl }).code === 0 && judge(equal(), { baseline: bl }).lines.some((l) => /as recorded/.test(l)));
  rows = equal(); rows[0] = row('clash-normal', 2);
  check('baseline: a clip that reads better is green and says so', judge(rows, { baseline: bl }).code === 0 && judge(rows, { baseline: bl }).lines.some((l) => /better than its recorded/.test(l)));
  for (const [what, r] of [['primary', row('clash-normal', 5, 0, 4.5, 4.5)], ['area-15%', row('clash-normal', 4.5, 0, 5, 4.5)], ['two-second memory', row('clash-normal', 4.5, 0, 4.5, 5)], ['red', row('clash-normal', 4.5, 0.5, 4.5, 4.5)]]) {
    rows = equal(); rows[0] = r;
    check(`baseline: ${what} one step worse than recorded is red (4)`, judge(rows, { baseline: bl }).code === 4 && new RegExp(`WORSE THAN RECORDED clash-normal: ${what.replace('%', '%')}`).test(judge(rows, { baseline: bl }).problems.join('\n')), judge(rows, { baseline: bl }).problems.join(' | '));
  }
  rows = equal(); rows.push(row('mash-normal', 1));
  check('baseline: a clip with no recorded value is red (5) when it is expected', judge(rows, { baseline: bl, expected: [...EXPECTED, 'mash-normal'] }).code === 5 && /NEW CLIP mash-normal/.test(judge(rows, { baseline: bl, expected: [...EXPECTED, 'mash-normal'] }).problems.join('')));
  rows = equal().filter((r) => r.id !== 'signature-reduced');
  check('baseline: a missing clip is still red (2)', judge(rows, { baseline: bl }).code === 2);
  rows = equal(); rows[2] = { id: 'collapse-normal', result: { general: { flashes: 4.5 }, red: { flashes: 0 }, combined: {} } };
  check('baseline: a missing area-15% or two-second-memory reading is red (2), never a pass', judge(rows, { baseline: bl }).code === 2 && /reading is missing/.test(judge(rows, { baseline: bl }).problems.join('')));
  rows = equal(); rows[0] = row('clash-normal', 5); rows[1] = { id: 'clash-reduced', error: 'x' };
  check('baseline: not read outranks worse (2 before 4), and worse outranks nothing else here', judge(rows, { baseline: bl }).code === 2);
  check('baseline: without it the verdict is the absolute line as before', judge(equal()).code === 1 && judge(equal(), { baseline: null }).code === 1);
  const t2 = report(judge(equal(), { baseline: bl }));
  check('baseline: the report says what it compared', /nightly flash reading: every clip equals or beats its recorded value$/.test(t2));
  check('baseline: the report of a worse reading says so', /A CLIP READS WORSE THAN ITS RECORDED VALUE$/.test(report(judge([row('clash-normal', 5, 0, 4.5, 4.5), ...EXPECTED.slice(1).map((id) => row(id, 4.5))], { baseline: bl }))));
  // the real file: every clip the night reads has all four recorded numbers, and a night that reads exactly those numbers is green
  const real = JSON.parse(readFileSync(join(here, 'nightly-baseline.json'), 'utf8')).clips;
  check('the real baseline file records all four readings of every clip the night reads', EXPECTED.every((id) => real[id] && ['primary', 'red', 'area15', 'twoSec'].every((k) => typeof real[id][k] === 'number')) && Object.keys(real).length === EXPECTED.length);
  const atReal = EXPECTED.map((id) => row(id, real[id].primary, real[id].red, real[id].area15, real[id].twoSec));
  check('the real baseline: a night that reads exactly the recorded values is green', judge(atReal, { baseline: real }).code === 0);
  const worseReal = atReal.map((r) => ({ ...r })); worseReal[0] = row(EXPECTED[0], real[EXPECTED[0]].primary + 0.5, real[EXPECTED[0]].red, real[EXPECTED[0]].area15, real[EXPECTED[0]].twoSec);
  check('the real baseline: half a step worse on one clip is red', judge(worseReal, { baseline: real }).code === 4);
  const cn = real['collapse-normal'];
  check('the real baseline records collapse-normal at what it reads (2 primary and area, 1.5 memory, re-recorded 2026-11-26), so a slip to 2.5 is red (the EP, 2026-11-21: no allowance)', cn.primary === 2 && cn.area15 === 2 && cn.twoSec === 1.5 && judge([row('collapse-normal', 2.5, 0, 2, 1.5)], { baseline: real, expected: ['collapse-normal'] }).code === 4);
  check('the real baseline keeps collapse-reduced at 3 and under: its reading of 4 is not recorded, so the nightly stays red on it', real['collapse-reduced'].primary === 3 && judge([row('collapse-reduced', 4, 0, 4, 3)], { baseline: real, expected: ['collapse-reduced'] }).code === 4);
}

{
  // the baseline's invalid_note is said on the night's page and changes no verdict
  const real = JSON.parse(readFileSync(join(here, 'nightly-baseline.json'), 'utf8'));
  const night = EXPECTED.map((id) => row(id, real.clips[id].primary, real.clips[id].red, real.clips[id].area15, real.clips[id].twoSec));
  const j = judge(night, { baseline: real.clips });
  const text = report(j, 3, real.invalid_note || null);
  check('the baseline says which readings are invalid, the page says it above the table and beside the verdict, and the verdict code is the same', typeof real.invalid_note === 'string' && /no building/.test(real.invalid_note) && text.startsWith('WARNING: SOFTWARE READINGS OF BUILDINGS ARE INVALID') && /readings of buildings are invalid\)$/.test(text) && j.code === 0 && !/WARNING/.test(report(j, 3)));
}

// the command, end to end, on a folder of summary files
const d = mkdtempSync(join(tmpdir(), 'nightly-ci-'));
try {
  mkdirSync(join(d, 'a')); mkdirSync(join(d, 'b'));
  writeFileSync(join(d, 'a', 'summary.json'), JSON.stringify(clean().slice(0, 3)));
  writeFileSync(join(d, 'b', 'summary.json'), JSON.stringify(clean().slice(3)));
  check('summaries in sub-folders are read together', readSummaries(d).length === EXPECTED.length);
  let r = spawnSync(process.execPath, [join(here, 'nightly-ci.mjs'), d], { encoding: 'utf8' });
  check('the command exits 0 on a clean night', r.status === 0 && /flash reading clean/.test(r.stdout), r.stdout + r.stderr);
  const bad = clean(); bad[0] = row('clash-normal', 4);
  writeFileSync(join(d, 'a', 'summary.json'), JSON.stringify(bad.slice(0, 3)));
  r = spawnSync(process.execPath, [join(here, 'nightly-ci.mjs'), d], { encoding: 'utf8' });
  check('the command exits 1 when a clip crosses the line', r.status === 1 && /TAKE-DOWN LINE/.test(r.stdout), r.stdout + r.stderr);
  rmSync(join(d, 'b'), { recursive: true });
  r = spawnSync(process.execPath, [join(here, 'nightly-ci.mjs'), d], { encoding: 'utf8' });
  check('the command exits 2 when half the clips are missing', r.status === 2, r.stdout + r.stderr);
  r = spawnSync(process.execPath, [join(here, 'nightly-ci.mjs')], { encoding: 'utf8' });
  check('no folder given: the usage and exit 2', r.status === 2 && /usage/.test(r.stderr));
  // --baseline, end to end: the real file, a night that reads exactly the recorded values (green), one reading half a step worse (4), a baseline that cannot be read (2)
  const realB = JSON.parse(readFileSync(join(here, 'nightly-baseline.json'), 'utf8')).clips;
  const atB = EXPECTED.map((id) => row(id, realB[id].primary, realB[id].red, realB[id].area15, realB[id].twoSec));
  mkdirSync(join(d, 'c')); writeFileSync(join(d, 'c', 'summary.json'), JSON.stringify(atB));
  r = spawnSync(process.execPath, [join(here, 'nightly-ci.mjs'), join(d, 'c'), '--baseline', join(here, 'nightly-baseline.json')], { encoding: 'utf8' });
  check('the command with --baseline exits 0 on a night that reads exactly the recorded values', r.status === 0 && /equals or beats its recorded value/.test(r.stdout), r.stdout + r.stderr);
  atB[0] = row(EXPECTED[0], realB[EXPECTED[0]].primary + 0.5, 0, realB[EXPECTED[0]].area15, realB[EXPECTED[0]].twoSec); writeFileSync(join(d, 'c', 'summary.json'), JSON.stringify(atB));
  r = spawnSync(process.execPath, [join(here, 'nightly-ci.mjs'), join(d, 'c'), '--baseline', join(here, 'nightly-baseline.json')], { encoding: 'utf8' });
  check('the command with --baseline exits 4 when a clip reads worse than recorded', r.status === 4 && /WORSE THAN RECORDED/.test(r.stdout), r.stdout + r.stderr);
  r = spawnSync(process.execPath, [join(here, 'nightly-ci.mjs'), join(d, 'c'), '--baseline', join(d, 'nope.json')], { encoding: 'utf8' });
  check('a baseline that cannot be read is exit 2', r.status === 2 && /cannot be read/.test(r.stderr));
} finally { rmSync(d, { recursive: true, force: true }); }

console.log(failed ? `nightly-ci self-test FAILED: ${failed} of ${ran}` : `nightly-ci self-test ok: ${ran} checks`);
process.exit(failed ? 1 : 0);
