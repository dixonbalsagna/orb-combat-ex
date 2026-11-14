// Self-test of tools/flash/nightly-ci.mjs, the verdict of the scheduled flash reading (CD-09; A-LEGAL-08). Node built-ins only; no browser, no build.
//   node tools/flash/nightly-ci-selftest.mjs
import { spawnSync } from 'node:child_process';
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { EXPECTED, judge, readingOf, readSummaries, report } from './nightly-ci.mjs';

const here = dirname(fileURLToPath(import.meta.url));
let ran = 0, failed = 0;
const check = (name, ok, extra) => { ran++; if (!ok) { failed++; console.log(`  FAIL ${name}${extra ? ': ' + extra : ''}`); } };

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

// the command, end to end, on a folder of summary files
const d = mkdtempSync(join(tmpdir(), 'nightly-ci-'));
try {
  mkdirSync(join(d, 'a')); mkdirSync(join(d, 'b'));
  writeFileSync(join(d, 'a', 'summary.json'), JSON.stringify(clean().slice(0, 3)));
  writeFileSync(join(d, 'b', 'summary.json'), JSON.stringify(clean().slice(3)));
  check('summaries in sub-folders are read together', readSummaries(d).length === 6);
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
} finally { rmSync(d, { recursive: true, force: true }); }

console.log(failed ? `nightly-ci self-test FAILED: ${failed} of ${ran}` : `nightly-ci self-test ok: ${ran} checks`);
process.exit(failed ? 1 : 0);
