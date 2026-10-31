// Self-test of tools/flash/nightly-seeds.mjs: the night's seeds (new, never repeated, none from the recorded set), what a run says and the take-down trigger. No browser. CI runs it.
//   node tools/flash/nightly-selftest.mjs
import { nextSeeds, readRun, reportLine, signatureOf, signatureText, TAKE_DOWN_ABOVE, TAKE_DOWN_ABOVE_OWNER, limitFor, limitFromRecord, modeOf, verdictOf, EXIT, ruleState, switchStates, switchFlips, buildInfoLine, loadSwitchTable, routeCheck } from './nightly-seeds.mjs';
import { readSignature, worseThan, gateProblems, REDUCED_MAX } from './signature-gate.mjs';
import { readFileSync, writeFileSync, mkdtempSync, mkdirSync, rmSync, existsSync } from 'node:fs';
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
check('the report line of a night with a REDUCED clip over the limit says TAKE DOWN and the clip', /TAKE DOWN: ai-1000-reduced reads 3\.5/.test(reportLine('2026-10-16', 'd3f1ca0e22f39110d69feceb4913ff799d11db5d', seeds, readRun([row(1000, 'reduced', 3.5), ...clean.filter((c) => c.id !== 'ai-1000-reduced')], seeds))));
check('a NORMAL clip over the limit alone is a FINDING in the report line, not a take-down (Legal RL-208)', (() => { const l = reportLine('2026-10-16', 'd3f1ca0e22f39110d69feceb4913ff799d11db5d', seeds, hot); return /FINDING \(normal mode.*ai-1000-normal reads 3\.5/.test(l) && !/TAKE DOWN/.test(l); })());
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


// ---- Legal RL-208: the exit codes, the route check and the watched switches
check('a clip id names its mode', modeOf('ai-1000-reduced') === 'reduced' && modeOf('ai-7-normal') === 'normal' && modeOf('signature') === null);
check('readRun splits what is over the limit by mode', (() => { const x = readRun([row(1, 'normal', 4), row(1, 'reduced', 4), row(2, 'normal', 1), row(2, 'reduced', 1)], [1, 2], 3.5); return x.over.length === 2 && x.overReduced.map((o) => o.id).join() === 'ai-1-reduced' && x.overNormal.map((o) => o.id).join() === 'ai-1-normal'; })());
const rr = (over) => readRun([row(1, 'normal', over === 'n' || over === 'b' ? 4 : 1), row(1, 'reduced', over === 'r' || over === 'b' ? 4 : 1)], [1], 3.5);
const okSig = { missing: [], worse: [] };
const PASS = { status: 'passed', problems: [] }, FAIL = { status: 'failed', problems: ['normal mode is reachable: F8'] }, NORUN = { status: 'not run', problems: [] };
const flip1 = [{ name: 'rally', state: 'on', expected: 'off', row: 'RL-183' }];
const V = (o) => verdictOf({ sig: okSig, routes: PASS, flips: [], ...o });
check('a clean night exits 0', V({ r: rr('') }).code === EXIT.clean && EXIT.clean === 0);
check('a REDUCED clip over the limit is the take-down (exit 1), route check or not', V({ r: rr('r') }).code === 1 && V({ r: rr('r'), routes: NORUN }).code === 1);
check('a NORMAL clip over the limit with the route check passed is a finding (exit 4), not a take-down', V({ r: rr('n') }).code === 4 && V({ r: rr('n') }).label === 'FINDING');
check('a NORMAL clip over the limit with the route check FAILED is a take-down on its own (addendum 12(c)), and says why', (() => { const v = V({ r: rr('n'), routes: FAIL }); return v.code === 1 && /route check FAILED/.test(v.lines.join(' ')) && /F8/.test(v.lines.join(' ')); })());
check('a NORMAL clip over the limit with the route check not run is a take-down: not run is never a pass', (() => { const v = V({ r: rr('n'), routes: NORUN }); return v.code === 1 && /did not run/.test(v.lines.join(' ')); })());
check('a failed route check is a take-down even with nothing over the limit (the lock may be reachable)', V({ r: rr(''), routes: FAIL }).code === 1);
check('a route check that did not run, with nothing over, is not itself a failure', V({ r: rr(''), routes: NORUN }).code === 0);
check('a clip not read is exit 2, whatever else is over', V({ r: { ...rr('r'), missing: ['ai-1-normal'] } }).code === 2 && V({ r: rr(''), sig: { missing: ['signature-reduced'], worse: [] } }).code === 2);
check('a watched switch that is ON when reviewed OFF is exit 5 and names its row and the batch it joins', (() => { const v = V({ r: rr(''), flips: flip1 }); return v.code === 5 && /rally is on, reviewed as off \(RL-183\).*clips join the batch/.test(v.lines[0]); })());
check('a take-down outranks a flipped switch, and a flipped switch outranks the signature and a finding', V({ r: rr('r'), flips: flip1 }).code === 1 && V({ r: rr(''), flips: flip1, sig: { missing: [], worse: ['x'] } }).code === 5 && V({ r: rr('n'), flips: flip1 }).code === 5);
check('the signature clip reading worse is exit 3, ahead of a finding', V({ r: rr(''), sig: { missing: [], worse: ['reduced primary 3 over 2.5'] } }).code === 3 && V({ r: rr('n'), sig: { missing: [], worse: ['x'] } }).code === 3);
check('the pixel run itself failing, with every clip read, is exit 2', V({ r: rr(''), runOk: false }).code === 2);
check('the six exit codes are distinct', new Set(Object.values(EXIT)).size === 6);

// the watched switches, on a fixture tree
{
  const d = mkdtempSync(join(tmpdir(), 'nightly-sw-'));
  try {
    const put = (p, text) => { const f = join(d, ...p.split('/')); mkdirSync(join(f, '..'), { recursive: true }); writeFileSync(f, text); };
    put('data/director/interrupts.json', JSON.stringify({ rally: { enabled: false }, water: { enabled: true } }));
    put('data/combat/rally.empress.json', '{}');
    put('data/combat/other.json', '{}');
    put('data/bad.json', '{ not json');
    const flag = (file, ...path) => ({ flag: { file, path } });
    check('a flag that is false reads off and one that is true reads on', ruleState(d, flag('data/director/interrupts.json', 'rally', 'enabled')) === 'off' && ruleState(d, flag('data/director/interrupts.json', 'water', 'enabled')) === 'on');
    check('a flag whose key, file or JSON is missing reads absent', ruleState(d, flag('data/director/interrupts.json', 'nope')) === 'absent' && ruleState(d, flag('data/none.json', 'x')) === 'absent' && ruleState(d, flag('data/bad.json', 'x')) === 'absent');
    check('a file glob that matches means the content landed (on); none means absent', ruleState(d, { files: ['data/combat/rally.*.json'] }) === 'on' && ruleState(d, { files: ['data/combat/energy.*.json', 'data/combat/energy/*.json'] }) === 'absent');
    check('a glob matches the whole name only (rally.* does not match other.json) and only files', ruleState(d, { files: ['data/combat/rally.*.json'] }) === 'on' && ruleState(d, { files: ['data/combat/ally.*.json'] }) === 'absent');
    check('any: on if any is on, else off if any is off, else absent', ruleState(d, { any: [flag('data/director/interrupts.json', 'rally', 'enabled'), { files: ['data/combat/rally.*.json'] }] }) === 'on' && ruleState(d, { any: [flag('data/director/interrupts.json', 'rally', 'enabled'), { files: ['data/combat/zzz*.json'] }] }) === 'off' && ruleState(d, { any: [{ files: ['data/q*.json'] }, { none: 'x' }] }) === 'absent');
    check('a rule with no hook is absent', ruleState(d, { none: 'no switch yet' }) === 'absent');
    const table = { switches: [{ name: 'kits', row: 'RL-179', expected: 'off', rule: { files: ['data/combat/energy.*.json'] } }, { name: 'rally', row: 'RL-183', expected: 'off', rule: { any: [flag('data/director/interrupts.json', 'rally', 'enabled'), { files: ['data/combat/rally.*.json'] }] } }, { name: 'water', row: 'RL-x', expected: 'on', rule: flag('data/director/interrupts.json', 'water', 'enabled') }] };
    const st = switchStates(d, table);
    check('every watched switch gets a state', JSON.stringify(st) === JSON.stringify({ kits: 'absent', rally: 'on', water: 'on' }), JSON.stringify(st));
    check('a switch ON that was reviewed OFF is a flip, named with its row; absent counts as off', JSON.stringify(switchFlips(st, table)) === JSON.stringify([{ name: 'rally', state: 'on', expected: 'off', row: 'RL-183' }]));
    check('a switch reviewed ON that is off or gone is a flip too', switchFlips({ kits: 'absent', rally: 'off', water: 'off' }, table).map((x) => x.name).join() === 'water' && switchFlips({ kits: 'absent', rally: 'off', water: 'on' }, table).length === 0);
    check('the build info line names the commit, the date and every switch', buildInfoLine({ commit: '257a766', date: '2026-10-19' }, st) === 'build info: commit 257a766, 2026-10-19; switches kits absent, rally on, water on' && /unknown/.test(buildInfoLine(null, {})));
    writeFileSync(join(d, 'bad-table.json'), JSON.stringify({ switches: [{ name: 'x', row: 'RL-1', expected: 'maybe', rule: {} }] }));
    check('a switch table with an odd entry is refused', (() => { try { loadSwitchTable(join(d, 'bad-table.json')); return false; } catch (e) { return /expected on or off/.test(e.message); } })());
  } finally { rmSync(d, { recursive: true, force: true }); }
}
{
  const real = loadSwitchTable();
  check('the real switch table names the five watched rows, each expected off', real.switches.map((s) => s.name).join() === 'kits,rapidFire,snareMine,grabCallouts,rally' && real.switches.every((s) => s.expected === 'off' && /^RL-\d+/.test(s.row)));
  const root = join(import.meta.dirname, '..', '..');
  const ralRule = real.switches.find((s) => s.name === 'rally').rule.any[0];
  check('the rally flag the table reads is really in the data (a rename would turn the watch blind): data/director/interrupts.json rally.enabled is a boolean', ['on', 'off'].includes(ruleState(root, ralRule)));
}
check('a skipped route check is "not run", never a pass', await routeCheck({ skip: true }).then((x) => x.status === 'not run' && x.notes.length === 1));

// the whole nightly, end to end, against a stand-in for the browser runs: the exit code, the build info, the switches and the history row (Legal RL-208)
{
  const d = mkdtempSync(join(tmpdir(), 'nightly-cli-'));
  try {
    const PIN = 'abcdef0'.padEnd(40, '1');
    const work = join(d, 'work'), pinDir = join(work, PIN.slice(0, 7));
    const put = (p, text) => { const f = join(pinDir, ...p.split('/')); mkdirSync(join(f, '..'), { recursive: true }); writeFileSync(f, text); };
    put('web/index.html', '<html></html>');
    put('tree/build_info.json', JSON.stringify({ commit: PIN.slice(0, 7), date: '2026-10-30' }));
    const setRally = (on) => put('tree/data/director/interrupts.json', JSON.stringify({ rally: { enabled: on } }));
    const stub = join(d, 'run-pixels-stub.mjs');
    writeFileSync(stub, [
      "import { mkdirSync, writeFileSync } from 'node:fs';",
      "import { join } from 'node:path';",
      "const a = process.argv.slice(2); const o = (n) => a[a.indexOf(n) + 1]; const out = o('--out'); mkdirSync(out, { recursive: true });",
      "const e = process.env;",
      "const row = (id, p, lower, two) => ({ id, result: { general: { flashes: p }, combined: { lower: lower ?? p }, cross: { general: { flashes: two ?? p } } } });",
      "let rows;",
      "if (a.includes('--clip')) rows = [row('signature-normal', 3.5, 5, 3), row('signature-reduced', 2.5, 3, 2)];",
      "else rows = o('--seeds').split(',').flatMap((s) => [row('ai-' + s + '-normal', Number(e.STUB_NORMAL || 2)), row('ai-' + s + '-reduced', Number(e.STUB_REDUCED || 2))]);",
      "writeFileSync(join(out, 'summary.json'), JSON.stringify(rows));",
    ].join('\n'));
    const hist = join(d, 'history.json');
    const run = (env) => { rmSync(hist, { force: true }); return spawnSync(process.execPath, [join(import.meta.dirname, 'nightly-seeds.mjs'), '--pin', PIN, '--no-export', '--no-route-check', '--count', '1', '--base', '9000', '--work', work, '--history', hist, '--run-pixels', stub], { encoding: 'utf8', env: { ...process.env, ...env } }); };
    setRally(false);
    const clean = run({});
    check('a clean night through the whole CLI exits 0 and prints the build info, the route check, the switches and the verdict', clean.status === 0 && /build info: commit abcdef0, 2026-10-30; switches kits absent, rapidFire absent, snareMine absent, grabCallouts absent, rally off/.test(clean.stdout) && /route check: not run/.test(clean.stdout) && /switches: .*; as reviewed/.test(clean.stdout) && /verdict: CLEAN \(exit 0\)/.test(clean.stdout), clean.stdout + clean.stderr);
    const row0 = JSON.parse(readFileSync(hist, 'utf8')).runs[0];
    check('the history row carries the switches, the route check and the verdict', row0.switches.rally === 'off' && row0.routes.status === 'not run' && row0.verdict.code === 0 && row0.verdict.label === 'CLEAN', JSON.stringify(row0));
    const red = run({ STUB_REDUCED: '4' });
    check('a reduced clip over 3.5 exits 1 (take-down)', red.status === 1 && /verdict: TAKE DOWN \(exit 1\)/.test(red.stdout), red.stdout);
    const nor = run({ STUB_NORMAL: '4' });
    check('a normal clip over 3.5 with the route check not run exits 1 too: not run is never a pass', nor.status === 1 && /did not run/.test(nor.stdout), nor.stdout);
    setRally(true);
    const fl = run({});
    check('a watched switch that is on (rally) exits 5, is named with its row, and shows in the build info', fl.status === 5 && /rally on/.test(fl.stdout) && /NOT AS REVIEWED: rally \(RL-183\)/.test(fl.stdout) && /verdict: SWITCH FLIPPED \(exit 5\)/.test(fl.stdout), fl.stdout);
    check('the flipped switch is in the history row', JSON.parse(readFileSync(hist, 'utf8')).runs[0].switches.rally === 'on');
  } finally { rmSync(d, { recursive: true, force: true }); }
}

console.log(failed ? `nightly seeds self-test FAILED: ${failed} of ${ran}` : `nightly seeds self-test ok: ${ran} checks`);
process.exit(failed ? 1 : 0);
