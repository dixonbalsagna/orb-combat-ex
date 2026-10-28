// Self-test of tools/flash/nightly-seeds.mjs: the night's seeds (new, never repeated, none from the recorded set), what a run says and the take-down trigger. No browser. CI runs it.
//   node tools/flash/nightly-selftest.mjs
import { nextSeeds, readRun, reportLine, signatureOf, signatureText, TAKE_DOWN_ABOVE, TAKE_DOWN_ABOVE_OWNER, limitFor, limitFromRecord } from './nightly-seeds.mjs';
import { readSignature, worseThan, gateProblems, REDUCED_MAX } from './signature-gate.mjs';
import { readFileSync, writeFileSync, mkdtempSync, rmSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

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

// the signature clip, both modes, every night, and the pin's gate on reduced (Legal RL-195 condition (a))
const sg = (id, p, lower, two) => ({ id, result: { general: { flashes: p }, combined: { lower }, cross: { general: { flashes: two } } } });
const sigOk = [sg('signature-normal', 3.5, 5, 3), sg('signature-reduced', 2.5, 3, 2)];
check('the pin limit for the signature clip, reduced, is 2.5 / 3 / 2', REDUCED_MAX.primary === 2.5 && REDUCED_MAX.area15 === 3 && REDUCED_MAX.twoSec === 2);
const s1 = signatureOf(sigOk);
check('both modes are read with their three readings (primary, area-15%, two-second memory)', s1.missing.length === 0 && s1.normal.primary === 3.5 && s1.normal.area15 === 5 && s1.reduced.twoSec === 2);
check('reduced exactly at 2.5 / 3 / 2 is within the limit (no worse)', s1.worse.length === 0);
check('reduced over on the primary is worse and says which reading', signatureOf([sigOk[0], sg('signature-reduced', 3, 3, 2)]).worse.join().includes('primary 3'));
check('reduced over on the area reading is worse', signatureOf([sigOk[0], sg('signature-reduced', 2.5, 3.5, 2)]).worse.join().includes('area15 3.5'));
check('reduced over on the two-second memory is worse', signatureOf([sigOk[0], sg('signature-reduced', 2.5, 3, 2.5)]).worse.join().includes('twoSec 2.5'));
check('normal being high does not make reduced worse (only reduced is the condition)', signatureOf([sg('signature-normal', 4.5, 5, 4), sigOk[1]]).worse.length === 0);
check('a missing or failed signature clip is not read (it is not a pass)', signatureOf([sigOk[0], { id: 'signature-reduced', error: 'capture failed' }]).missing.join() === 'signature-reduced' && signatureOf([]).missing.length === 2);
check('the report line carries the signature readings, and says WORSE when reduced is', reportLine('2026-10-27', 'd3f1ca0e22f39110d69feceb4913ff799d11db5d', seeds, a, 3.5, s1).includes('signature normal 3.5 / 5 / 3, reduced 2.5 / 3 / 2 (pin limit for reduced 2.5 / 3 / 2: within)') && (() => { const w = signatureText(signatureOf([sigOk[0], sg('signature-reduced', 3, 3, 2)])); return w.includes('reduced 3 / 3 / 2') && w.includes('WORSE, primary 3'); })());
check('the report line says NOT READ for a missing signature clip', /signature NOT READ: signature-reduced/.test(signatureText(signatureOf([sigOk[0]]))));
const PIN = 'a'.repeat(40), OTHER = 'b'.repeat(40);
const rec = { commit: PIN, reduced: { primary: 2.5, area15: 3, twoSec: 2 } };
check('a record for the pin with reduced within the limits allows the pin', gateProblems(rec, PIN).length === 0);
check('a record for another commit does not allow the pin (the reading must be taken on the new pin)', gateProblems(rec, OTHER).length === 1 && gateProblems(rec, OTHER)[0].includes('is for aaaaaaaa'));
check('a record with reduced worse does not allow the pin', gateProblems({ ...rec, reduced: { primary: 3, area15: 3, twoSec: 3 } }, PIN).length === 1);
check('a grandfathered record (the pin Legal ruled on before the condition) allows its own pin though it reads worse, and no other', gateProblems({ commit: PIN, grandfathered: true, reduced: { primary: 3, area15: 3, twoSec: 3 } }, PIN).length === 0 && gateProblems({ commit: PIN, grandfathered: true, reduced: { primary: 3, area15: 3, twoSec: 3 } }, OTHER).length === 1);
check('no record, or a pin that is not a full SHA, is a problem', gateProblems(null, PIN).length === 1 && gateProblems(rec, 'abc').length >= 1);
check('the real record in the tree is for the live pin', (() => { const r = JSON.parse(readFileSync(new URL('./signature-gate.json', import.meta.url), 'utf8')); const cfg = JSON.parse(readFileSync(new URL('../site.json', import.meta.url), 'utf8')); return gateProblems(r, cfg.pin).length === 0 || !cfg.pin; })());
// the command: it records a passing reading and refuses a worse or an incomplete one
{
  const d = mkdtempSync(join(tmpdir(), 'siggate-'));
  const run = (args) => spawnSync(process.execPath, [fileURLToPath(new URL('./signature-gate.mjs', import.meta.url)), ...args], { encoding: 'utf8' });
  try {
    const sum = join(d, 'summary.json'), file = join(d, 'gate.json');
    writeFileSync(sum, JSON.stringify(sigOk));
    const r1 = run(['--record', sum, '--commit', PIN, '--file', file, '--date', '2026-10-28']);
    check('--record writes the commit and both readings when reduced is within the limits', r1.status === 0 && (() => { const j = JSON.parse(readFileSync(file, 'utf8')); return j.commit === PIN && j.reduced.primary === 2.5 && j.normal.primary === 3.5 && j.date === '2026-10-28'; })(), (r1.stderr || '').slice(0, 200));
    const r2 = run(['--check', '--file', file, '--pin', PIN]);
    check('--check passes for the recorded pin and fails for another', r2.status === 0 && run(['--check', '--file', file, '--pin', OTHER]).status === 1);
    writeFileSync(sum, JSON.stringify([sigOk[0], sg('signature-reduced', 3, 3, 3)]));
    const file2 = join(d, 'gate2.json');
    const r3 = run(['--record', sum, '--commit', PIN, '--file', file2]);
    check('--record refuses a reduced reading that is worse and writes nothing', r3.status === 1 && r3.stderr.includes('worse than 2.5 / 3 / 2') && !existsSync(file2));
    writeFileSync(sum, JSON.stringify([sigOk[0]]));
    const r4 = run(['--record', sum, '--commit', PIN, '--file', file2]);
    check('--record refuses a run with a missing clip', r4.status === 1 && r4.stderr.includes('signature-reduced not read'));
  } finally { rmSync(d, { recursive: true, force: true }); }
}

console.log(failed ? `nightly seeds self-test FAILED: ${failed} of ${ran}` : `nightly seeds self-test ok: ${ran} checks`);
process.exit(failed ? 1 : 0);
