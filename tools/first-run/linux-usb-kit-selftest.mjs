// Self-test of the USB-stick reading kit (tools/first-run/linux-usb-kit.mjs, linux-usb-reading.sh): the drive's folder is made, and the script is RUN with a stand-in program and a stand-in hidden screen.
//   node tools/first-run/linux-usb-kit-selftest.mjs
import { createHash } from 'node:crypto';
import { chmodSync, existsSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, rmSync, writeFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { tmpdir } from 'node:os';
import { delimiter, dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { makeDrive, READING_NAME, READING_TEMPLATE } from './linux-usb-kit.mjs';
import { targz } from '../lib/targz.mjs';

let ran = 0, failed = 0;
const check = (name, ok, extra) => { ran++; if (!ok) { failed++; console.log(`FAIL ${name}${extra ? ': ' + extra : ''}`); } };
const H = '0123456789abcdef', ARCHIVE = 'orb-combat-ex-linux-x86_64.tar.gz';

const text = readFileSync(READING_TEMPLATE, 'utf8').split('\r').join('');
const code = text.split('\n').filter((l) => !l.trim().startsWith('#')).join('\n');
check('the script deletes nothing and sends nothing (the one network use is apt, for the hidden screen)', !/(^|[;&|\s])(rm|curl|wget|nc|ssh|scp|sftp)\s/.test(code) && !/https?:\/\//.test(code));
check('the matches are drawn only on the hidden screen (its own display, X11 asked for, no Wayland)', /DISPLAY=":\$screen" WAYLAND_DISPLAY= "\$bin" --display-driver x11 /.test(code) && (code.match(/--write-movie/g) || []).length === 1);

const win = process.platform === 'win32';
const sh = win ? ['C:/Program Files/Git/usr/bin/sh.exe', 'C:/Program Files/Git/bin/sh.exe'].find((p) => existsSync(p)) : '/bin/sh';
const dir = mkdtempSync(join(tmpdir(), 'usb-kit-'));
try {
  // a stand-in program: the headless test prints the result; asked for a movie it writes N tiny "frames" (STAND_FRAMES overrides how many) and a renderer line
  const program = Buffer.from(`#!/bin/sh
movie=""; frames=0; prev=""
for a in "$@"; do case "$prev" in --write-movie) movie=$a ;; esac; case "$a" in --frames=*) frames=\${a#--frames=} ;; esac; prev=$a; done
case "$*" in
  *--write-movie*) echo "OpenGL API 4.5 stand-in - Compatibility"; n=\${STAND_FRAMES:-$frames}; i=0; d=$(dirname "$movie"); while [ "$i" -lt "$n" ]; do : > "$d/frame$(printf '%08d' "$i").png"; i=$((i+1)); done; echo "display=$DISPLAY" ;;
  *--bench*) echo "gameplay hash at tick 2400: ${H}" ;;
  *) exec sleep 30 ;;
esac
`);
  const archive = join(dir, ARCHIVE);
  writeFileSync(archive, targz([{ name: 'game', dir: true, mode: 0o755 }, { name: 'game/orb-combat-ex.x86_64', data: program, mode: 0o755 }]));
  const sum = createHash('sha256').update(readFileSync(archive)).digest('hex');
  const record = join(dir, 'build-record.txt');
  writeFileSync(record, ['file ' + ARCHIVE, 'size 1 bytes', 'sha256 ' + sum, 'version 0', 'bench gameplay hash at tick 2400: ' + H, ''].join('\n'));
  const drive = join(dir, 'drive');
  const names = makeDrive({ record, archive, out: drive });
  check('the drive gets the package, the first start and the reading script', names.length === 3 && names.every((n) => existsSync(join(drive, n))) && readFileSync(join(drive, READING_NAME), 'utf8').includes(`WANT_SUM="${sum}"`));
  const refuses = (o) => { try { makeDrive(o); return ''; } catch (e) { return e.message; } };
  const other = join(dir, 'other'); mkdirSync(other); writeFileSync(join(other, ARCHIVE), 'not the file');
  check('a package that is not the record\'s is not put on a drive', /not the file the record names/.test(refuses({ record, archive: join(other, ARCHIVE), out: join(dir, 'd2') })) && !existsSync(join(dir, 'd2')));
  check('a folder that holds a kit or a reading already is not written over', /nothing is overwritten/.test(refuses({ record, archive, out: drive })));
  if (!sh) console.log('note: no sh found: the script itself was not run');
  else {
    // a stand-in for the hidden screen, first on the PATH, so no real one is needed and nothing is fetched
    const bin = join(dir, 'bin'); mkdirSync(bin);
    writeFileSync(join(bin, 'Xvfb'), '#!/bin/sh\nexec sleep 60\n');
    try { chmodSync(join(bin, 'Xvfb'), 0o755); } catch { /* windows */ }
    const run = (name, env = {}) => {
      const at = join(dir, name);
      makeDrive({ record, archive, out: at });
      const r = spawnSync(sh, [join(at, READING_NAME).split('\\').join('/')], { encoding: 'utf8', input: '\ny\n', timeout: 180000,
        env: { ...process.env, PATH: `${bin}${delimiter}${process.env.PATH}`, ORB_FIRST_START_ANY_SYSTEM: '1', ORB_FIRST_START_WAIT: '2', ORB_READING_SCREEN_WAIT: '1', ORB_READING_ANY_SPACE: '1', ORB_READING_FRAMES: '12', ORB_READING_SEEDS: '5 6', DISPLAY: ':0', ...env } });
      const rec = existsSync(join(at, 'reading', 'record.txt')) ? readFileSync(join(at, 'reading', 'record.txt'), 'utf8') : '';
      return { r, at, out: `${r.stdout}${r.stderr}`, rec };
    };
    const a = run('good');
    check('a whole run: first start, two matches recorded, the record says each', a.r.status === 0 && /match 5: ended 0; frames 12 of 12 asked; OpenGL API 4\.5/.test(a.rec) && /match 6: ended 0; frames 12 of 12/.test(a.rec) && a.rec.includes(sum) && a.rec.includes(H) && existsSync(join(a.at, 'first-start-result.txt')), `${a.r.status} ${a.out}\n${a.rec}`);
    const frames = existsSync(join(a.at, 'reading', 'seed-5', 'frames')) ? readdirSync(join(a.at, 'reading', 'seed-5', 'frames')) : [];
    const log = existsSync(join(a.at, 'reading', 'seed-5', 'game.log')) ? readFileSync(join(a.at, 'reading', 'seed-5', 'game.log'), 'utf8') : '';
    check('the frames are on the drive with their clip file, drawn on the hidden screen and not the real one', frames.length === 13 && frames.includes('clip.json') && /display=:97/.test(log), `${frames.length} ${log}`);
    check('the record names no folder or computer', a.rec !== '' && !a.rec.includes(a.at) && !a.rec.includes(a.at.split('\\').join('/')), a.rec);
    const s = run('short', { STAND_FRAMES: '9' });
    check('a match that did not write every frame stops with a plain reason and keeps what there is', s.r.status === 1 && /did NOT write every frame \(9 of 12/.test(s.out) && /at least one match is short/.test(s.out) && /frames 9 of 12/.test(s.rec), s.out);
  }
} finally { rmSync(dir, { recursive: true, force: true }); }
console.log(failed ? `linux usb kit self-test FAILED: ${failed} of ${ran}` : `linux usb kit self-test ok: ${ran} checks`);
process.exit(failed ? 1 : 0);
