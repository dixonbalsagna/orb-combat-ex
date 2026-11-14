// The owner-private desktop build, made on Orb's own PC with one command (A-TOOLS-01; Legal RL-262 section 1: "on Orb's own PC with the same packaging script the outside package uses, with the same route scan, the
// same notices and the same warning"; the file is never made or kept by a CI run). Windows only today: the exported program is started here and plays the bench.
//   node tools/desktop-local-build.mjs [--commit <rev>] [--out <folder>] [--godot <exe>] [--frames 2400] [--keep-scratch] [--with-working-tools]
//   --with-working-tools: TEST ONLY, for trying a change to tools/desktop-package.mjs before it is committed: that one file is copied from the working tree into the scratch copy. The build record and the last
//   line say so, and the package is then not a build of the commit alone (do not hand it on).
// What it does, the way .github/workflows/desktop-builds.yml does for the owner-private audience, on a SCRATCH copy of the commit (`git archive <rev>`: the committed files, never your working tree, which it
// does not read or change):
//   1 lock Reduce flashing on, 2 put the version number into the export preset, 3 the routes check (lock, bypass words, no net/, feedback target not a public issue), 4 write build_info.json,
//   5 import, 6 export "Windows Desktop" (release), 7 the project's bench and the exported program's bench: both must print the SAME gameplay hash, 8 pack: the program, README.txt (with Orb's owner-approved
//   notice and the ORB-PRIVATE line), NOTICES.txt and build_info.json, zipped, 9 unzip somewhere new and verify the folder the way a player's PC finds it.
// It refuses (exit 1) at the first step that fails and says which. It writes: <out>/orb-combat-ex-ORB-PRIVATE-windows-x86_64-<commit8>.zip, its SHA-256 and a build-record.txt. Default <out>:
// homework/Files/desktop/<commit8>-ORB-PRIVATE (git-ignored). The file is for Orb and Orb 2 only: it moves by a drive, the home network or a private message, never a public link.
// Godot runs at below-normal priority and headless (no window). Node built-ins, git, tar and PowerShell only.
import { spawn, spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { cpSync, existsSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, rmSync, statSync, writeFileSync } from 'node:fs';
import { tmpdir, constants as osConstants } from 'node:os';
import { setPriority } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const REPO = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const OWNER_NOTICE = 'site-interim-owner.json';
const PRESET = 'Windows Desktop';

/** The names of the package, from the commit. Pure. */
export function names(commit8) {
  const folder = 'orb-combat-ex-ORB-PRIVATE-windows-x86_64';
  return { folder, zip: `${folder}-${commit8}.zip`, defaultOut: join(REPO, 'homework', 'Files', 'desktop', `${commit8}-ORB-PRIVATE`) };
}

/** The gameplay hash line of a bench's output, or null. Pure. */
export function hashLine(text) { const m = /^gameplay hash at tick \d+: [0-9a-f]+/m.exec(String(text)); return m ? m[0] : null; }

/** The Godot executable: --godot, GODOT, then the usual place on this PC. */
function godotExe(given) {
  const local = process.env.LOCALAPPDATA ? join(process.env.LOCALAPPDATA, 'Programs', 'Godot', '4.7.2', 'Godot_v4.7.2-stable_win64_console.exe') : '';
  const found = [given, process.env.GODOT, local].find((p) => p && existsSync(p));
  if (!found) throw new Error('no Godot executable: pass --godot <exe> or set GODOT (the 4.7.2 console build)');
  return found;
}

function run(cmd, args, { cwd, limitMs = 10 * 60 * 1000, below = false } = {}) {
  return new Promise((ok) => {
    const child = spawn(cmd, args, { cwd, stdio: ['ignore', 'pipe', 'pipe'], windowsHide: true });
    if (below) { try { setPriority(child.pid, osConstants.priority.PRIORITY_BELOW_NORMAL); } catch { /* gone */ } }
    let out = '';
    const keep = (d) => { out += d; if (out.length > 2e6) out = out.slice(-1e6); };   // bounded: the tail is what matters
    child.stdout.on('data', keep); child.stderr.on('data', keep);
    const timer = setTimeout(() => { try { if (process.platform === 'win32') spawn('taskkill', ['/PID', String(child.pid), '/T', '/F'], { windowsHide: true }); else child.kill('SIGKILL'); } catch { /* gone */ } }, limitMs);
    child.on('error', (e) => { clearTimeout(timer); ok({ code: -1, out: String(e) }); });
    child.on('close', (code) => { clearTimeout(timer); ok({ code, out }); });
  });
}

const sha256 = (f) => createHash('sha256').update(readFileSync(f)).digest('hex');
const ps = (script) => spawnSync('powershell', ['-NoProfile', '-NonInteractive', '-Command', script], { encoding: 'utf8' });

async function main() {
  const a = process.argv.slice(2);
  const opt = (n, d) => { const i = a.indexOf(n); return i >= 0 && i + 1 < a.length ? a[i + 1] : d; };
  if (process.platform !== 'win32') { console.error('desktop-local-build: Windows only for now (the exported program is started on this PC)'); process.exit(2); }
  const rev = opt('--commit', 'HEAD');
  const frames = String(opt('--frames', '2400'));
  const git = (...g) => spawnSync('git', ['-C', REPO, ...g], { encoding: 'utf8' });
  const r = git('rev-parse', '--verify', `${rev}^{commit}`);
  if (r.status !== 0) { console.error(`desktop-local-build: "${rev}" is not a commit of this repository`); process.exit(2); }
  const sha = r.stdout.trim(), c8 = sha.slice(0, 8), date = git('log', '-1', '--format=%cs', sha).stdout.trim();
  const onMain = git('merge-base', '--is-ancestor', sha, 'main').status === 0;
  const n = names(c8);
  const out = resolve(opt('--out', n.defaultOut));
  const godot = godotExe(opt('--godot'));
  const scratch = mkdtempSync(join(tmpdir(), 'orb-private-build-'));
  const tree = join(scratch, 'tree');
  const rec = [`Owner-private desktop build (tools/desktop-local-build.mjs)`, `commit ${sha} (${date}); ${onMain ? 'on main' : 'NOT on main (a local owner-private build may be of any commit)'}`, `made ${new Date().toISOString()}`, ''];
  const step = (name, ok, detail = '') => { const line = `${ok ? 'ok  ' : 'FAIL'} ${name}${detail ? ': ' + detail : ''}`; console.log(line); rec.push(line); if (!ok) { fail(name); } };
  const fail = (name) => { writeRecord(); console.error(`desktop-local-build FAILED at: ${name} (scratch copy kept for a look: ${scratch})`); process.exit(1); };
  const writeRecord = () => { try { mkdirSync(out, { recursive: true }); writeFileSync(join(out, 'build-record.txt'), rec.join('\n') + '\n'); } catch { /* the folder is not writable */ } };
  try {
    mkdirSync(tree, { recursive: true });
    const tarFile = join(scratch, 'commit.tar');
    const arch = spawnSync('git', ['-C', REPO, 'archive', '--format=tar', '-o', tarFile, sha], { encoding: 'utf8' });
    if (arch.status !== 0) step('git archive of the commit', false, String(arch.stderr).slice(0, 200));
    // Windows' own tar (bsdtar) reads "C:\..." paths; the GNU tar that Git for Windows puts on the PATH reads "C:" as a remote host, so it is named by path
    const winTar = join(process.env.SystemRoot || 'C:\\Windows', 'System32', 'tar.exe');
    const tarx = existsSync(winTar) ? spawnSync(winTar, ['-xf', tarFile, '-C', tree], { encoding: 'utf8' }) : spawnSync('tar', ['--force-local', '-xf', tarFile, '-C', tree], { encoding: 'utf8' });
    rmSync(tarFile, { force: true });
    step('the commit unpacked into a scratch copy (the working tree is not read)', tarx.status === 0, tarx.status === 0 ? tree : String(tarx.stderr || tarx.error).slice(0, 200));

    const pkgTool = join(tree, 'tools', 'desktop-package.mjs');
    const testOnly = a.includes('--with-working-tools');
    if (testOnly) {
      cpSync(join(REPO, 'tools', 'desktop-package.mjs'), pkgTool);
      rec.push("TEST ONLY: tools/desktop-package.mjs is the WORKING TREE copy, not the commit's: this is not a build of the commit alone");
      console.log('TEST ONLY: tools/desktop-package.mjs copied from the working tree');
    }
    const toolText = readFileSync(pkgTool, 'utf8');
    if (!toolText.includes('PRIVATE_LINE')) step('this commit\'s packaging tool knows the ORB-PRIVATE line', false, 'it is older than the owner-private change: build a newer commit');
    const node = (args, cwd = tree) => run(process.execPath, args, { cwd });
    let x = await node([pkgTool, 'lock', '--root', tree]); step('lock Reduce flashing on (scratch copy only)', x.code === 0, x.out.trim().split(/\r?\n/).pop());
    x = await node([pkgTool, 'version', '--root', tree]); step('version number into the export preset', x.code === 0, x.out.trim().split(/\r?\n/).pop());
    x = await node([pkgTool, 'routes', '--root', tree]); step('routes check (lock, bypass words, no net/, feedback target)', x.code === 0, x.out.trim().split(/\r?\n/).pop().slice(0, 160));
    x = await node([join(tree, 'tools', 'write-build-info.mjs'), '--commit', sha, '--date', date]); step('build_info.json written', x.code === 0, x.out.trim());
    const info = JSON.parse(readFileSync(join(tree, 'build_info.json'), 'utf8'));

    x = await run(godot, ['--headless', '--path', tree, '--import'], { below: true, limitMs: 10 * 60 * 1000 }); step('import', x.code === 0, `exit ${x.code}`);
    const exp = join(scratch, 'export'); mkdirSync(exp, { recursive: true });
    const exe = join(exp, 'orb-combat-ex.exe');
    x = await run(godot, ['--headless', '--path', tree, '--export-release', PRESET, exe], { below: true }); step(`export "${PRESET}" (release, Compatibility, x86_64, pck embedded)`, x.code === 0 && existsSync(exe), existsSync(exe) ? `${statSync(exe).size} bytes` : `exit ${x.code}: ${x.out.trim().split(/\r?\n/).pop()}`);
    const b1 = await run(godot, ['--headless', '--path', tree, '--fixed-fps', '60', '--', '--seed=4', `--frames=${frames}`, '--bench'], { below: true });
    const b2 = await run(exe, ['--headless', '--fixed-fps', '60', '--', '--seed=4', `--frames=${frames}`, '--bench'], { cwd: exp, below: true });
    const h1 = hashLine(b1.out), h2 = hashLine(b2.out);
    step('the project\'s bench and the exported program\'s bench print the same gameplay hash', !!h1 && h1 === h2, `${h1 || 'none'} | ${h2 || 'none'}`);

    const pkg = join(scratch, 'pkg', n.folder); mkdirSync(pkg, { recursive: true });
    const notice = ['--notice', OWNER_NOTICE, '--private'];
    x = await node([pkgTool, 'text', '--platform', 'windows', '--out', pkg, '--build-info', join(tree, 'build_info.json'), ...notice]); step('README.txt, NOTICES.txt and build_info.json (owner notice, ORB-PRIVATE line)', x.code === 0, x.out.trim().split(/\r?\n/).pop().slice(0, 120));
    cpSync(exe, join(pkg, 'orb-combat-ex.exe'));
    mkdirSync(out, { recursive: true });
    const zip = join(out, n.zip);
    rmSync(zip, { force: true });
    const z = ps(`Compress-Archive -Path '${pkg}' -DestinationPath '${zip}' -CompressionLevel Optimal`);
    step('zipped', z.status === 0 && existsSync(zip), existsSync(zip) ? `${statSync(zip).size} bytes` : String(z.stderr).slice(0, 160));
    const chk = join(scratch, 'check'); mkdirSync(chk, { recursive: true });
    const u = ps(`Expand-Archive -Path '${zip}' -DestinationPath '${chk}' -Force`);
    step('unzipped somewhere new, the way a player does', u.status === 0, '');
    x = await node([pkgTool, 'verify', '--platform', 'windows', '--dir', join(chk, n.folder), '--commit', sha, '--locked', ...notice]); step('the folder verifies (files, magic bytes, embedded pck, notices, lock, ORB-PRIVATE line)', x.code === 0, x.out.trim().split(/\r?\n/).pop().slice(0, 200));

    const sum = sha256(zip);
    writeFileSync(join(out, `${n.zip}.sha256.txt`), `${sum}  ${n.zip}\n`);
    rec.push('', `file ${n.zip}`, `size ${statSync(zip).size} bytes`, `sha256 ${sum}`, `version ${info.version || 'none'}`, `bench ${h1}`, '', 'For Orb and Orb 2 only. Move it by a drive, the home network or a private message. Never a public link.');
    writeRecord();
    if (testOnly) console.log("\nTEST ONLY: this package used the working tree's packaging tool and is not a build of the commit alone: do not hand it on.");
    console.log(`\nDONE: ${zip}\n  sha256 ${sum}\n  ${statSync(zip).size} bytes; commit ${c8}; version ${info.version || 'none'}\n  for Orb and Orb 2 only: a drive, the home network or a private message, never a public link`);
  } finally {
    if (!a.includes('--keep-scratch') && !process.exitCode) { try { rmSync(scratch, { recursive: true, force: true }); } catch { /* left for the OS */ } }
  }
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) main().catch((e) => { console.error(`desktop-local-build: ${e.message}`); process.exit(1); });
void readdirSync;
