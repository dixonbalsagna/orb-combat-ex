// Self-test of tools/flash/nightly-seeds.mjs: the night's seeds (new, never repeated, none from the recorded set), what a run says and the take-down trigger. No browser. CI runs it.
//   node tools/flash/nightly-selftest.mjs
import { nextSeeds, readRun, reportLine, TAKE_DOWN_ABOVE, TAKE_DOWN_ABOVE_OWNER, limitFor, limitFromRecord } from './nightly-seeds.mjs';
import { readFileSync } from 'node:fs';

let ran = 0, failed = 0;
const check = (name, ok, extra) => { ran++; if (!ok) { failed++; console.log(`  FAIL ${name}${extra ? ': ' + extra : ''}`); } };
const row = (seed, mode, p) => ({ id: `ai-${seed}-${mode}`, result: { general: { flashes: p } } });

check('the first night takes the first seeds from the base', JSON.stringify(nextSeeds(3, 1000, new Set([12345]), [])) === '[1000,1001,1002]');
check('a seed in the recorded set is never taken', JSON.stringify(nextSeeds(3, 1000, new Set([1001]), [])) === '[1000,1002,1003]');
check('a seed already read on an earlier night is never taken again', JSON.stringify(nextSeeds(3, 1000, new Set(), [1000, 1001, 1005])) === '[1002,1003,1004]');
check('the same inputs give the same pick', JSON.stringify(nextSeeds(8, 1000, new Set([1003]), [1000])) === JSON.stringify(nextSeeds(8, 1000, new Set([1003]), [1000])));
check('eight nights of eight never overlap', (() => { const used = []; for (let n = 0; n < 8; n++) used.push(...nextSeeds(8, 1000, new Set(), used)); return new Set(used).size === 64; })());

const seeds = [1000, 1001];
const clean = [row(1000, 'normal', 2), row(1000, 'reduced', 2.5), row(1001, 'normal', 1.5), row(1001, 'reduced', 3)];
const a = readRun(clean, seeds);
check('a run with nothing over 3 reads all four clips and names the largest', a.read === 4 && a.clips === 4 && a.max === 3 && a.maxId === 'ai-1001-reduced' && a.over.length === 0);
check('the owner-approved interim raises the trigger to over 3.5 (Legal addendum 11); otherwise over 3', limitFor({ interim: { owner: 'Orb 2026-10-18' } }) === TAKE_DOWN_ABOVE_OWNER && TAKE_DOWN_ABOVE_OWNER === 3.5 && limitFor({ interim: { legal: 'RL-136' } }) === 3 && limitFor({ interim: null }) === 3 && limitFor({ interim: { owner: ' ' } }) === 3);
check('the limit comes from the interim record when the site is offline: 3.5 from the record, 3 for a missing, odd or lower value (never site.json)', limitFromRecord({ record: { take_down_above: 3.5 } }) === 3.5 && limitFromRecord(null) === 3 && limitFromRecord({}) === 3 && limitFromRecord({ record: { take_down_above: 'x' } }) === 3 && limitFromRecord({ record: { take_down_above: 2 } }) === 3 && limitFromRecord(JSON.parse(readFileSync(new URL('../site-interim-owner.json', import.meta.url), 'utf8'))) === 3.5);
check('a 3.5 reading is not the trigger under the owner limit, and a 4 is', readRun([{ id: 'ai-1-normal', result: { general: { flashes: 3.5 } } }, { id: 'ai-1-reduced', result: { general: { flashes: 4 } } }], [1], 3.5).over.length === 1);
check('exactly 3 is not the trigger (over 3 is)', TAKE_DOWN_ABOVE === 3 && a.over.length === 0);
const hot = readRun([row(1000, 'normal', 3.5), ...clean.slice(1)], seeds);
check('a clip over 3 on the primary reading is the trigger and is named', hot.over.length === 1 && hot.over[0].id === 'ai-1000-normal' && hot.over[0].primary === 3.5);
const miss = readRun([row(1000, 'normal', 2), { id: 'ai-1000-reduced', error: 'capture failed' }, row(1001, 'normal', 1), row(1001, 'reduced', 1)], seeds);
check('a clip that was not read is reported as missing (it is not a pass)', miss.missing.join() === 'ai-1000-reduced' && miss.read === 3);
check('the report line of a clean night names the commit, the seeds and the largest reading', /pinned d3f1ca0e: seeds 1000,1001 x 2 modes, 4 of 4 clips read; largest primary 3 \(ai-1001-reduced\); none over 3/.test(reportLine('2026-10-16', 'd3f1ca0e22f39110d69feceb4913ff799d11db5d', seeds, a)));
check('the report line of a hot night says TAKE DOWN and the clip', /TAKE DOWN: ai-1000-normal reads 3\.5/.test(reportLine('2026-10-16', 'd3f1ca0e22f39110d69feceb4913ff799d11db5d', seeds, hot)));
check('the report line of an incomplete night says so', /NOT COMPLETE: ai-1000-reduced/.test(reportLine('2026-10-16', 'd3f1ca0e22f39110d69feceb4913ff799d11db5d', seeds, miss)));

console.log(failed ? `nightly seeds self-test FAILED: ${failed} of ${ran}` : `nightly seeds self-test ok: ${ran} checks`);
process.exit(failed ? 1 : 0);
