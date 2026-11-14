// Self-test of the words-only child's record in tools/flash/signature-gate.mjs (Legal RL-209 (b)): a child inherits its pin's grandfathering only if no reading is worse. Node built-ins only.
import { spawnSync } from 'node:child_process';
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { CHILD_CLIPS, childProblems, readingsOf, worstNumbers, gateProblems } from './signature-gate.mjs';

const here = dirname(fileURLToPath(import.meta.url));
let failed = 0;
const check = (name, ok, detail) => { console.log(`${ok ? 'ok  ' : 'FAIL'} ${name}${ok || !detail ? '' : '\n     ' + detail}`); if (!ok) failed++; };

const PIN = 'a'.repeat(40), CHILD = 'b'.repeat(40);
const reading = (size, scale, primary, red, area15, twoSec) => ({ size, scale, primary, red, area15, twoSec });
// a row's four readings: [960x540 full, 960x540 half, 1024x768 full, 1024x768 half]
const row = (id, nums) => ({ id, readings: ['960x540:1', '960x540:2', '1024x768:1', '1024x768:2'].map((k, i) => reading(k.split(':')[0], Number(k.split(':')[1]), ...nums[i])) });
const base = { 'signature-reduced': [[3, 0, 3, 3], [3, 0, 3, 3], [2.5, 0, 3, 2], [2.5, 0, 3, 2]], 'signature-normal': [[1.5, 0, 2.5, 1.5], [2.5, 0, 2.5, 1.5], [2.5, 0, 2.5, 3], [2, 0, 2.5, 1]], 'collapse-reduced': [[2.5, 0, 2.5, 0.5], [2.5, 0, 2.5, 2.5], [2, 0, 2.5, 2], [2, 0, 2.5, 1]], 'collapse-normal': [[3.5, 0, 3.5, 1], [2.5, 0, 3.5, 2], [2, 0, 3.5, 1], [2, 0, 3.5, 1]] };
const rows = (tweak = {}) => CHILD_CLIPS.map((id) => row(id, tweak[id] || base[id]));

check('a child that reads exactly as its pin has no problem', childProblems(rows(), rows()).length === 0);
check('a child that reads lower on some numbers has none either', childProblems(rows({ 'collapse-normal': [[3, 0, 3, 1], [2.5, 0, 3.5, 1], [2, 0, 3, 1], [1.5, 0, 3.5, 1]] }), rows()).length === 0);
const worse = childProblems(rows({ 'signature-reduced': [[3, 0, 3, 3], [3, 0, 3, 3], [2.5, 0, 3, 2], [2.5, 0, 3.5, 2]] }), rows());
check('one number worse in one reading is a problem that names the clip, the size, the scale and the number', worse.length === 1 && /signature-reduced at 1024x768 scale 2: area15 reads 3\.5 on the child, worse than the pin's 3/.test(worse[0]), worse.join('\n'));
check('a worse red count counts too', childProblems(rows({ 'collapse-reduced': [[2.5, 1, 2.5, 0.5], ...base['collapse-reduced'].slice(1)] }), rows()).some((m) => /red reads 1/.test(m)));
check('a clip missing from the child is a problem (a missing clip is not a pass)', childProblems(rows().filter((r) => r.id !== 'collapse-normal'), rows()).some((m) => /collapse-normal: the child's summary has no readings/.test(m)));
check('a clip missing from the pin is a problem', childProblems(rows(), rows().filter((r) => r.id !== 'signature-normal')).some((m) => /signature-normal: the pin's summary has no readings/.test(m)));
check('a reading the child lacks at a size and scale is a problem', (() => { const c = rows(); c[0].readings = c[0].readings.slice(1); return childProblems(c, rows()).some((m) => /no reading at 960x540 scale 1/.test(m)); })());
check('a row with an error or no readings has none', readingsOf({ id: 'x', error: 'boom', readings: [{}] }) === null && readingsOf({ id: 'x' }) === null && readingsOf(null) === null);
check('the worst-of-four numbers of a row: the largest of each', JSON.stringify(worstNumbers(row('signature-reduced', base['signature-reduced']))) === JSON.stringify({ primary: 3, area15: 3, twoSec: 3 }));

// the command, end to end
const d = mkdtempSync(join(tmpdir(), 'sig-gate-'));
try {
  const w = (name, v) => { const f = join(d, name); writeFileSync(f, JSON.stringify(v)); return f; };
  const gate = w('gate.json', { _why: 'w', commit: PIN, date: '2026-10-27', grandfathered: true, limits: { primary: 2.5, area15: 3, twoSec: 2 }, engineFlip: { ruling: 'RL-202', commit: PIN, template: { tag: 't', sha512: 's' }, until: '2026-11-15' } });
  const run = (child, extra = []) => spawnSync(process.execPath, [join(here, 'signature-gate.mjs'), '--record-child', child, '--pin-summary', w('pin.json', rows()), '--commit', CHILD, '--of', PIN, '--file', gate, '--date', '2026-10-31', ...extra], { encoding: 'utf8' });
  let r = run(w('child-bad.json', rows({ 'signature-reduced': [[3.5, 0, 3, 3], ...base['signature-reduced'].slice(1)] })));
  check('a worse child exits 1, says it does not inherit the grandfathering, and writes nothing', r.status === 1 && /does not inherit the grandfathering/.test(r.stderr) && JSON.parse(readFileSync(gate, 'utf8')).commit === PIN, r.stderr);
  r = run(w('child.json', rows()));
  const rec = JSON.parse(readFileSync(gate, 'utf8'));
  check('a child that reads no worse is recorded: its commit, grandfathered, the pin it is of, the ruling', r.status === 0 && rec.commit === CHILD && rec.grandfathered === true && rec.child.of === PIN && rec.child.ruling === 'RL-209', r.stderr + r.stdout);
  check('the record keeps the PIN\'s worst-of-four numbers as reduced and normal', JSON.stringify(rec.reduced) === JSON.stringify({ primary: 3, area15: 3, twoSec: 3 }) && JSON.stringify(rec.normal) === JSON.stringify({ primary: 2.5, area15: 2.5, twoSec: 3 }), JSON.stringify([rec.reduced, rec.normal]));
  check('it holds the pin\'s and the child\'s readings of every clip, four each', CHILD_CLIPS.every((id) => rec.pinReadings[id].length === 4 && rec.childReadings[id].length === 4));
  check('the engine-flip entry (RL-202) is re-pointed at the child, the template and the end date kept', rec.engineFlip.commit === CHILD && rec.engineFlip.template.tag === 't' && rec.engineFlip.until === '2026-11-15' && rec.engineFlip.ruling === 'RL-202');
  check('the gate passes the child as the pin and refuses the old pin (the record is for the child)', gateProblems(rec, CHILD).length === 0 && gateProblems(rec, PIN).some((m) => /on record is for bbbbbbbb/.test(m)));
  // CD-09: --check says EXCEPTION for a grandfathered record (exit 0, never the word ok) and ok for a record that passes the limits
  { const okRec = w('ok.json', { _why: 'w', commit: PIN, date: '2026-11-13', reduced: { primary: 2, area15: 2.5, twoSec: 1.5 } });
    const gf = w('gf.json', { _why: 'w', commit: PIN, date: '2026-10-27', grandfathered: true, reduced: { primary: 3, area15: 3, twoSec: 3 } });
    const rg = spawnSync(process.execPath, [join(here, 'signature-gate.mjs'), '--check', '--file', gf, '--pin', PIN], { encoding: 'utf8' });
    check('--check on a grandfathered record exits 0 and says EXCEPTION, never ok', rg.status === 0 && /signature gate EXCEPTION \(grandfathered, NOT a pass/.test(rg.stdout) && !/signature gate ok/.test(rg.stdout), rg.stdout + rg.stderr);
    const ro = spawnSync(process.execPath, [join(here, 'signature-gate.mjs'), '--check', '--file', okRec, '--pin', PIN], { encoding: 'utf8' });
    check('--check on a record that reads within the limits says ok', ro.status === 0 && /signature gate ok/.test(ro.stdout) && !/EXCEPTION/.test(ro.stdout), ro.stdout + ro.stderr); }
  r = spawnSync(process.execPath, [join(here, 'signature-gate.mjs'), '--record-child', join(d, 'child.json')], { encoding: 'utf8' });
  check('missing arguments are refused with the usage', r.status === 2 && /usage/.test(r.stderr));
} finally { rmSync(d, { recursive: true, force: true }); }

console.log(failed ? `signature-gate self-test FAILED (${failed})` : 'signature-gate self-test passed');
process.exit(failed ? 1 : 0);
