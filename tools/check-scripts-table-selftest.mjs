// Self-test of tools/check-scripts-table.mjs (A-CODE-04): the classification of check scripts into CI, gate, not run and unreviewed, and the ratchet. Pure; node only. CI runs it.
//   node tools/check-scripts-table-selftest.mjs
import { classify, markdown, namedInGate, namedInWorkflows, namedInWorldList, problems, PATTERN } from './check-scripts-table.mjs';

let ran = 0, failed = 0;
const check = (name, ok, extra) => { ran++; if (!ok) { failed++; console.log(`  FAIL ${name}${extra ? ': ' + extra : ''}`); } };

const scripts = ['sim/core/tools/parity.gd', 'sim/world/tools/a_check.gd', 'sim/world/tools/b_check.gd', 'sim/input/test/hub_test.gd', 'sim/input/test/pad_test.gd', 'audio/tools/mix_check.gd', 'ui/tools/hud_check.gd', 'render/tools/soak_check.gd'];
check('the file pattern takes _check, check and _test scripts and nothing else', PATTERN.test('a/b_check.gd') && PATTERN.test('a/cuecheck.gd') && PATTERN.test('a/x_test.gd') && !PATTERN.test('a/x_check.mjs') && !PATTERN.test('a/checker.gd') && !PATTERN.test('a/testing.gd'));
const ci = new Set([...namedInWorkflows(['run: godot --script res://sim/core/tools/parity.gd', 'x: node tools/foo.mjs'], scripts), ...namedInWorldList({ run: ['a_check', 'not_there'] }, scripts)]);
check('a workflow naming the script by its res:// path puts it in CI; the world run list names scripts without folder or extension', ci.has('sim/core/tools/parity.gd') && ci.has('sim/world/tools/a_check.gd') && !ci.has('sim/world/tools/b_check.gd') && ci.size === 2);
check('a name in a world list matches only a script of sim/world/tools', !namedInWorldList({ run: ['hud_check'] }, scripts).has('ui/tools/hud_check.gd'));
const gate = namedInGate('for t in sim/input/test/*_test.gd; do echo $t; done\n"$G" --script res://ui/tools/hud_check.gd\nfor c in soak_checkX other; do :; done', scripts);
check('the gate names a script by its file name as a whole word, or by a folder glob', gate.has('ui/tools/hud_check.gd') && gate.has('sim/input/test/hub_test.gd') && gate.has('sim/input/test/pad_test.gd') && !gate.has('render/tools/soak_check.gd'));
check('a folder glob does not reach another folder', !namedInGate('sim/input/test/*_test.gd', ['ui/tools/hub_test.gd']).has('ui/tools/hub_test.gd'));
const t = classify(scripts, { ci, gate, reasons: { 'render/tools/soak_check.gd': 'a soak, run by hand' } });
check('classify: CI first, then gate, then a reason, else unreviewed', t.rows.find((r) => r.path === 'sim/core/tools/parity.gd').status === 'CI' && t.rows.find((r) => r.path === 'ui/tools/hud_check.gd').status === 'GATE' && t.rows.find((r) => r.path === 'render/tools/soak_check.gd').status === 'NOT RUN' && t.rows.find((r) => r.path === 'audio/tools/mix_check.gd').status === 'UNREVIEWED' && t.rows.find((r) => r.path === 'sim/world/tools/b_check.gd').status === 'UNREVIEWED');
check('the counts add up', t.total === 8 && t.ci + t.gate + t.notRun + t.unreviewed === 8 && t.ci === 2 && t.gate === 3 && t.notRun === 1 && t.unreviewed === 2, JSON.stringify([t.ci, t.gate, t.notRun, t.unreviewed]));
check('the ratchet: at the number, no problem', problems(t, { unreviewedMax: 2 }, { 'render/tools/soak_check.gd': 'x' }).length === 0);
check('the ratchet: one more unreviewed script than allowed fails, and says what to do', problems(t, { unreviewedMax: 1 }, {}).some((p) => /ratchet allows 1/.test(p)));
check('the ratchet only goes down: fewer unreviewed than the number says is a problem until it is lowered', problems(t, { unreviewedMax: 5 }, {}).some((p) => /lower unreviewedMax to 2/.test(p)));
check('a reason for a script that does not exist, or that IS run, is a problem', problems(t, { unreviewedMax: 2 }, { 'gone.gd': 'x' }).some((p) => /not a tracked/.test(p)) && problems(t, { unreviewedMax: 2 }, { 'sim/core/tools/parity.gd': 'x' }).some((p) => /IS run/.test(p)));
check('no ratchet number is a problem', problems(t, {}, {}).some((p) => /no unreviewedMax/.test(p)));
const md = markdown(t, '2026-11-14');
check('the markdown table has the counts, a row a folder and a row a script', /8 scripts/.test(md) && /\| sim\/world\/tools \| 2 \| 1 \| 0 \| 0 \| 1 \|/.test(md) && /\| render\/tools\/soak_check.gd \| NOT RUN \| a soak, run by hand \|/.test(md), md.slice(0, 600));

console.log(failed ? `check-scripts self-test: ${failed} of ${ran} FAILED` : `check-scripts self-test ok: ${ran} checks`);
process.exit(failed ? 1 : 0);
