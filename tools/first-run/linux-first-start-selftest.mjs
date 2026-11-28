// Self-test of the Linux first-start kit (tools/first-run/linux-first-start.{mjs,sh}): the record is read, and the script is RUN with a stand-in program in a real archive: right file, wrong file, different
// result, no desktop.   node tools/first-run/linux-first-start-selftest.mjs
import { createHash } from 'node:crypto';
import { existsSync, mkdtempSync, readFileSync, readdirSync, rmSync, writeFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { kitText, linuxEntry, KIT_NAME, TEMPLATE } from './linux-first-start.mjs';
import { targz } from '../lib/targz.mjs';

let ran = 0, failed = 0;
const check = (name, ok, extra) => { ran++; if (!ok) { failed++; console.log(`FAIL ${name}${extra ? ': ' + extra : ''}`); } };

const SUM = 'a'.repeat(64), H = '0123456789abcdef';
const record = ['Owner-private desktop build', 'commit abc', '', 'file orb-combat-ex-windows-x86_64.zip', 'size 1 bytes', `sha256 ${'b'.repeat(64)}`, 'version 0', 'bench gameplay hash at tick 2400: ffffffffffffffff', '', 'file orb-combat-ex-linux-x86_64.tar.gz', 'size 2 bytes', `sha256 ${SUM}`, 'version 0', `bench gameplay hash at tick 2400: ${H}`, ''].join('\r\n');
const e = linuxEntry(record);
check('the Linux archive\'s own name, checksum and expected result are read from a build record, not the Windows ones', e.archive === 'orb-combat-ex-linux-x86_64.tar.gz' && e.sum === SUM && e.hash === H && e.ticks === '2400', JSON.stringify(e));
const refuses = (t) => { try { linuxEntry(t); return false; } catch { return true; } };
check('a record with no Linux package, no checksum or no result is refused', refuses(record.split('file orb-combat-ex-linux')[0]) && refuses(record.replace(`sha256 ${SUM}`, '')) && refuses(record.replace(`bench gameplay hash at tick 2400: ${H}`, '')));
const template = readFileSync(TEMPLATE, 'utf8');
check('a value that is not the shape it should be is never written into the script', (() => { try { kitText(template, { ...e, archive: 'x"; echo.tar.gz' }); return false; } catch { return true; } })());
const code = template.split('\n').filter((l) => !l.trim().startsWith('#')).join('\n');
check('the script deletes nothing and has no way to send anything', !/(^|[;&|\s])(rm|curl|wget|nc|ssh|scp|sftp)\s/.test(code) && !/https?:\/\//.test(code));

const win = process.platform === 'win32';
const sh = win ? ['C:/Program Files/Git/usr/bin/sh.exe', 'C:/Program Files/Git/bin/sh.exe'].find((p) => existsSync(p)) : '/bin/sh';
if (!sh) console.log('note: no sh found: the script itself was not run');
else {
  const dir = mkdtempSync(join(tmpdir(), 'first-start-'));
  const fwd = (p) => p.split('\\').join('/');
  try {
    const archive = 'orb-combat-ex-linux-x86_64.tar.gz';
    // a stand-in program: the bench prints a result; otherwise it leaves a mark that it was opened and waits to be closed
    const program = (hash) => Buffer.from(`#!/bin/sh\ncase "$*" in *--bench*) echo noise; echo "gameplay hash at tick 2400: ${hash}" ;; *) : > "$(dirname "$0")/opened"; exec sleep 30 ;; esac\n`);
    const run = (name, { hash = H, want = H, sum = null, display = ':0', input = '\ny\n', withArchive = true } = {}) => {
      const at = join(dir, name);
      const box = mkdtempSync(at + '-');
      const bytes = targz([{ name: 'game', dir: true, mode: 0o755 }, { name: 'game/orb-combat-ex.x86_64', data: program(hash), mode: 0o755 }]);
      if (withArchive) writeFileSync(join(box, archive), bytes);
      const real = createHash('sha256').update(bytes).digest('hex');
      writeFileSync(join(box, KIT_NAME), kitText(template, { archive, sum: sum || real, hash: want, ticks: '2400' }));
      const env = { ...process.env, ORB_FIRST_START_ANY_SYSTEM: '1', ORB_FIRST_START_WAIT: '2', DISPLAY: display, WAYLAND_DISPLAY: '' };
      const r = spawnSync(sh, [fwd(join(box, KIT_NAME))], { encoding: 'utf8', input, env, timeout: 120000 });
      const unpacked = readdirSync(box).filter((n) => n.startsWith('first-start-') && !n.endsWith('.txt'));
      const result = existsSync(join(box, 'first-start-result.txt')) ? readFileSync(join(box, 'first-start-result.txt'), 'utf8').trim() : '';
      const opened = unpacked.length > 0 && existsSync(join(box, unpacked[0], 'game', 'opened'));
      return { r, out: `${r.stdout}${r.stderr}`, result, unpacked, opened, real, box };
    };
    const a = run('good');
    check('the right file: the test runs, the game is opened and closed by the script, and the one line says so', a.r.status === 0 && a.opened && a.result === `G23 first start | archive sha256 ${a.real} | bench ${H} (same) | warning appeared: yes | closed at the warning: yes, by this script | a Linux x86_64 desktop`, `${a.r.status} [${a.result}] ${a.out}`);
    check('the line to send holds no folder or computer name', a.result !== '' && !a.result.includes(a.box) && !a.result.includes(fwd(a.box)) && !/\/(home|tmp|c)\//i.test(a.result), a.result);
    const w = run('wrong', { sum: SUM });
    check('another file than the one Orb made is not unpacked or run', w.r.status === 1 && /not the file Orb made/.test(w.out) && w.unpacked.length === 0 && w.result === '', w.out);
    const d = run('different', { hash: 'deadbeefdeadbeef', input: '\nn\n' });
    check('a different result and a missing warning are said, not hidden', /\(DIFFERENT\)/.test(d.result) && /warning appeared: no/.test(d.result), d.result);
    const n = run('nodisplay', { display: '', input: '' });
    check('with no desktop the game is not opened and the line says it was not tried', n.r.status === 0 && !n.opened && /warning appeared: not tried \| closed at the warning: not tried/.test(n.result), `${n.result} ${n.out}`);
    const m = run('missing', { withArchive: false });
    check('with no game file it stops and says which file it needs', m.r.status === 1 && /I cannot find orb-combat-ex-linux/.test(m.out), m.out);
  } finally { rmSync(dir, { recursive: true, force: true }); }
}
console.log(failed ? `linux first start self-test FAILED: ${failed} of ${ran}` : `linux first start self-test ok: ${ran} checks`);
process.exit(failed ? 1 : 0);
