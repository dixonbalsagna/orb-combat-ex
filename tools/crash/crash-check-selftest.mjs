// Self-test of the pure parts of tools/crash/crash-check.mjs (Tools, 2026-11-23). node tools/crash/crash-check-selftest.mjs
import { PROBE, REASON, withProbe, readCrash } from './crash-check.mjs';
let bad = 0, n = 0;
const check = (name, ok, extra) => { n++; if (!ok) { bad++; console.log(`FAIL ${name}${extra ? ': ' + extra : ''}`); } };
const p = withProbe('[application]\n\nconfig/name="x"\n');
check('the probe autoload is added once, as a new section when there is none', /\[autoload\]\n\nCrashProbe="\*res:\/\/crash_probe\.gd"/.test(p) && p.split('CrashProbe').length === 2);
check('an existing autoload section gets it too', /\[autoload\]\n\nCrashProbe=.*\nA="/.test(withProbe('[autoload]\nA="*res://a.gd"\n')) || withProbe('[autoload]\nA="*res://a.gd"\n').includes('CrashProbe'));
check('the probe crashes on request and says the reason, and hangs on request, one second in', PROBE.includes(`OS.crash("${REASON}")`) && /while true:/.test(PROBE) && PROBE.includes('create_timer(1.0)') && PROBE.includes('\t'));
const log = (t) => ({ name: 'godot.log', size: t.length, mtimeMs: 1, text: t });
let r = readCrash({ logs: [log(`Godot Engine v4.7.2.stable\n\nERROR: ${REASON}\n   at: crash (core/core_bind.cpp:349)\n`)], exit: 3221225501 });
check('a crashed run with a log that has the reason reads as died, logged, says why', r.died && r.logged && r.saysWhy && r.versionLine);
r = readCrash({ logs: [], exit: 3221225501 });
check('a crash that left no log reads as logged: false', r.died && !r.logged && !r.saysWhy);
r = readCrash({ logs: [log('Godot Engine v4.7.2.stable\n')], exit: 0 });
check('a clean exit is not a death, and a log without the reason does not say why', !r.died && !r.saysWhy);
console.log(`crash-check selftest: ${n} checks, ${bad} failed`);
process.exit(bad ? 1 : 0);
