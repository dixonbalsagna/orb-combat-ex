// Self-test of tools/gate.mjs: a command that prints SCRIPT ERROR lines and exits 0 must fail the gate; a clean one passes; the command's own failure is kept; an allowed line and --max are honoured.
//   node tools/gate-selftest.mjs
import { spawnSync } from 'node:child_process';
import { writeFileSync, mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { scriptErrors, verdictProblems } from './gate.mjs';
import { verifyProblems } from './world-checks.mjs';

let ran = 0, failed = 0;
const check = (name, ok, extra) => { ran++; if (!ok) { failed++; console.log(`  FAIL ${name}${extra ? ': ' + extra : ''}`); } };
const here = import.meta.dirname;
const gate = (args) => spawnSync(process.execPath, [join(here, 'gate.mjs'), ...args], { encoding: 'utf8' });
const say = (lines, code = 0) => ['-e', `console.log(${JSON.stringify(lines.join('\n'))}); process.exit(${code})`];

check('a SCRIPT ERROR line is counted', scriptErrors('hello\nSCRIPT ERROR: Invalid call. Nonexistent function.\n   at: x (res://a.gd:1)').length === 1);
check('a Parse Error line is counted', scriptErrors('Parse Error: Expected new line.').length === 1);
check('a failed script load is counted', scriptErrors('ERROR: Failed to load script "res://x.gd" with error "Parse error".').length === 1);
check('a warning and the at-exit leak lines are not counted', scriptErrors('WARNING: 62 ObjectDB instances were leaked at exit\nERROR: 4 resources still in use at exit (run with --verbose for details).\n').length === 0);
check('an allowed line is not counted', scriptErrors('SCRIPT ERROR: known thing', [{ match: 'known thing' }]).length === 0);
const bad = gate(['--', process.execPath, ...say(['all fine', 'SCRIPT ERROR: Invalid call', 'SCRIPT ERROR: Invalid call again'])]);
check('a command that exits 0 with SCRIPT ERROR lines fails the gate', bad.status === 1 && /2 SCRIPT ERROR line/.test(bad.stderr), `${bad.status} ${bad.stderr}`);
check('its output is still streamed', /all fine/.test(bad.stdout));
const good = gate(['--', process.execPath, ...say(['all fine'])]);
check('a clean command passes', good.status === 0 && /no SCRIPT ERROR lines/.test(good.stdout), `${good.status} ${good.stdout}`);
const failing = gate(['--', process.execPath, ...say(['nothing wrong in the log'], 3)]);
check("the command's own failure is kept (exit 3)", failing.status === 3);
check('--max lets a counted number of lines through', gate(['--max', '2', '--', process.execPath, ...say(['SCRIPT ERROR: a', 'SCRIPT ERROR: b'])]).status === 0 && gate(['--max', '1', '--', process.execPath, ...say(['SCRIPT ERROR: a', 'SCRIPT ERROR: b'])]).status === 1);
const dir = mkdtempSync(join(tmpdir(), 'gate-'));
try {
  const allow = join(dir, 'allow.json'), log = join(dir, 'run.log');
  writeFileSync(allow, JSON.stringify({ allow: [{ match: 'known thing', why: 'accepted' }] }));
  check('an --allow file lets a known line through', gate(['--allow', allow, '--', process.execPath, ...say(['SCRIPT ERROR: known thing'])]).status === 0);
  writeFileSync(log, 'ok\nSCRIPT ERROR: x\nSCRIPT ERROR: y\n');
  check('--log checks a saved log', gate(['--log', log]).status === 1 && /2 SCRIPT ERROR/.test(gate(['--log', log]).stderr));
  writeFileSync(log, 'ok\nnothing\n');
  check('--log passes a clean log', gate(['--log', log]).status === 0);
} finally { rmSync(dir, { recursive: true, force: true }); }
// --verdict: World's checks end on a plain quit() (exit 0), so the verdict line is the result
check('a clean verdict line passes', verdictProblems('ARENA: 0 check(s) failed').length === 0 && verdictProblems('CRATERS CHECK: 0 failed').length === 0);
check('a verdict line that counts failures is reported', verdictProblems(['x', 'ARENA: 2 check(s) failed', 'y'].join('\n')).length === 1 && /ARENA: 2/.test(verdictProblems('ARENA: 2 check(s) failed')[0]));
check('no verdict line is reported (a script that quit early)', verdictProblems(['some output', 'only'].join('\n')).length === 1 && /no verdict line/.test(verdictProblems('')[0]));
const vbad = gate(['--verdict', '--', process.execPath, ...say(['ARENA: 3 check(s) failed'])]);
check('--verdict fails a command that exits 0 and reports failures', vbad.status === 1 && /ARENA: 3/.test(vbad.stderr), `${vbad.status} ${vbad.stderr}`);
check('--verdict fails a command that exits 0 and prints no verdict', gate(['--verdict', '--', process.execPath, ...say(['hello'])]).status === 1);
check('--verdict passes a clean verdict', gate(['--verdict', '--', process.execPath, ...say(['ARENA: 0 check(s) failed'])]).status === 0);
check('without --verdict the same failing verdict still exits 0 (the option is opt-in)', gate(['--', process.execPath, ...say(['ARENA: 3 check(s) failed'])]).status === 0);
check('--verdict does not hide a SCRIPT ERROR', gate(['--verdict', '--', process.execPath, ...say(['SCRIPT ERROR: x', 'ARENA: 0 check(s) failed'])]).status === 1);
// tools/world-checks.json: every script in sim/world/tools is classified
check('world checks: the real classification holds', verifyProblems().length === 0, verifyProblems().join(' | '));
check('world checks: an unclassified script is reported', verifyProblems({ run: ['a_check'], leaveOut: { p: 'a probe' } }, ['a_check.gd', 'p.gd', 'new_check.gd']).some((m) => /new_check.gd is in neither/.test(m)));
check('world checks: a listed script that is gone is reported', verifyProblems({ run: ['a_check', 'gone_check'], leaveOut: {} }, ['a_check.gd']).some((m) => /gone_check/.test(m)));
check('world checks: a script in both lists, one listed twice and a leaveOut with no reason are reported', verifyProblems({ run: ['a', 'a', 'b'], leaveOut: { b: 'x', c: ' ' } }, ['a.gd', 'b.gd', 'c.gd']).length === 3);
check('a command that is not there exits 2', gate(['--', 'no-such-command-xyz']).status === 2);
console.log(failed ? `gate self-test FAILED: ${failed} of ${ran} checks` : `gate self-test ok: ${ran} checks`);
process.exit(failed ? 1 : 0);
