// The owner-private desktop build, made on Orb's own PC with one command (A-TOOLS-01; Legal RL-262 section 1: "on Orb's own PC with the same packaging script the outside package uses, with the same route scan, the
// same notices and the same warning"; the file is never made or kept by a CI run). Windows and Linux (the Linux half added 2026-11-23, path to Alpha 1 job 7).
//   node tools/desktop-local-build.mjs [--platform windows|linux|both] [--commit <rev>] [--out <folder>] [--godot <exe>] [--frames 2400] [--keep-scratch] [--with-working-tools]
//   --platform: default both. The Linux package is a .tar.gz written by tools/lib/targz.mjs (the program 0755, the rest 0644: Windows' own tar cannot give a file an executable bit). The Linux program is an ELF and is
//   PLAYED only on a Linux machine; on this PC it is exported, packed, unpacked and read (magic bytes, pck, notices, lock, the executable bit in the archive), and its record says it was not played here
//   (the desktop-builds.yml run plays it on a Linux runner and compares the hash with the project's).
//   --with-working-tools: TEST ONLY, for trying a change to tools/desktop-package.mjs before it is committed: that one file is copied from the working tree into the scratch copy. The build record and the last
//   line say so, and the package is then not a build of the commit alone (do not hand it on).
// What it does, the way .github/workflows/desktop-builds.yml does for the owner-private audience, on a SCRATCH copy of the commit (`git archive <rev>`: the committed files, never your working tree, which it
// does not read or change):
//   1 lock Reduce flashing on, 2 put the version number into the export preset, 3 the routes check (lock, bypass words, no net/, feedback target not a public issue), 4 write build_info.json,
//   5 import, 6 export "Windows Desktop" (release), 7 the project's bench and the exported program's bench: both must print the SAME gameplay hash, 8 pack: the program, README.txt (with Orb's owner-approved
//   notice and the ORB-PRIVATE line), NOTICES.txt and build_info.json, zipped, 9 unzip somewhere new and verify the folder the way a player's PC finds it.
// It refuses (exit 1) at the first step that fails and says which. It writes: <out>/orb-combat-ex-ORB-PRIVATE-windows-x86_64-<commit8>.zip and/or ...-linux-x86_64-<commit8>.tar.gz, their SHA-256 and a build-record.txt
// (with this PC's folder paths taken out: tools/record-paths.mjs, so the record can go into the repository). Default <out>:
// homework/Files/desktop/<commit8>-ORB-PRIVATE (git-ignored). The file is for Orb and Orb 2 only: it moves by a drive, the home network or a private message, never a public link.
// Godot runs at below-normal priority and headless (no window). Node built-ins, git, tar and PowerShell only.
import { spawn, spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { cpSync, existsSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, rmSync, statSync, writeFileSync } from 'node:fs';
import { tmpdir, constants as osConstants } from 'node:os';
import { setPriority } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { cleanPaths } from './record-paths.mjs';
import { folderEntries, readTarGz, targz } from './lib/targz.mjs';

const REPO = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const OWNER_NOTICE = 'site-interim-owner.json';
const PRESETS = { windows: 'Windows Desktop', linux: 'Linux' };
const PROGRAMS = { windows: 'orb-combat-ex.exe', linux: 'orb-combat-ex.x86_64' };

/** The names of the package, from the commit. Pure. `zip` is the archive's name whatever its kind (.zip for Windows, .tar.gz for Linux). */
export function names(commit8, platform = 'windows') {
  const folder = `orb-combat-ex-ORB-PRIVATE-${platform}-x86_64`;
  const zip = `${folder}-${commit8}.${platform === 'linux' ? 'tar.gz' : 'zip'}`;
  return { folder, zip, archive: zip, defaultOut: join(REPO, 'homework', 'Files', 'desktop', `${commit8}-ORB-PRIVATE`) };
}

/** The platforms a --platform value names; null when it names none. Pure. */
export function platformsOf(v) { return v === 'both' ? ['windows', 'linux'] : v === 'windows' || v === 'linux' ? [v] : null; }

/** The Windows hosts can start a Windows program and a Linux host a Linux one; a Mac neither. Pure. */
export function canPlay(platform, host) { return (platform === 'windows' && host === 'win32') || (platform === 'linux' && host === 'linux'); }

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
  const platforms = platformsOf(opt('--platform', 'both'));
  if (!platforms) { console.error('desktop-local-build: --platform is windows, linux or both'); process.exit(2); }
  if (process.platform === 'darwin') { console.error('desktop-local-build: Windows and Linux hosts only for now'); process.exit(2); }
  const rev = opt('--commit', 'HEAD');
  const frames = String(opt('--frames', '2400'));
  const git = (...g) => spawnSync('git', ['-C', REPO, ...g], { encoding: 'utf8' });
  const r = git('rev-parse', '--verify', `${rev}^{commit}`);
  if (r.status !== 0) { console.error(`desktop-local-build: "${rev}" is not a commit of this repository`); process.exit(2); }
  const sha = r.stdout.trim(), c8 = sha.slice(0, 8), date = git('log', '-1', '--format=%cs', sha).stdout.trim();
  const mtime = Number(git('log', '-1', '--format=%ct', sha).stdout.trim()) || 0;
  const onMain = git('merge-base', '--is-ancestor', sha, 'main').status === 0;
  const out = resolve(opt('--out', names(c8).defaultOut));
  const godot = godotExe(opt('--godot'));
  const scratch = mkdtempSync(join(tmpdir(), 'orb-private-build-'));
  const tree = join(scratch, 'tree');
  const rec = [`Owner-private desktop build (tools/desktop-local-build.mjs), ${platforms.join(' and ')}`, `commit ${sha} (${date}); ${onMain ? 'on main' : 'NOT on main (a local owner-private build may be of any commit)'}`, `made ${new Date().toISOString()}`, `made on ${process.platform === 'win32' ? 'Windows' : 'Linux'}`, ''];
  const step = (name, ok, detail = '') => { const line = `${ok ? 'ok  ' : 'FAIL'} ${name}${detail ? ': ' + detail : ''}`; console.log(line); rec.push(line); if (!ok) { fail(name); } };
  const fail = (name) => { writeRecord(); console.error(`desktop-local-build FAILED at: ${name} (scratch copy kept for a look: ${scratch})`); process.exit(1); };
  // the record is cleaned of this PC's folder paths as it is written (tools/record-paths.mjs): the scratch folder is <scratch>, a user's folder <user>
  const writeRecord = () => { try { mkdirSync(out, { recursive: true }); writeFileSync(join(out, 'build-record.txt'), cleanPaths(rec.join('\n')) + '\n'); } catch { /* the folder is not writable */ } };
  const results = [];
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
    x = await node([pkgTool, 'version', '--root', tree]); step('version number into the export presets', x.code === 0, x.out.trim().split(/\r?\n/).pop());
    x = await node([pkgTool, 'routes', '--root', tree]); step('routes check (lock, bypass words, no net/, feedback target)', x.code === 0, x.out.trim().split(/\r?\n/).pop().slice(0, 160));
    x = await node([join(tree, 'tools', 'write-build-info.mjs'), '--commit', sha, '--date', date]); step('build_info.json written', x.code === 0, x.out.trim());
    const info = JSON.parse(readFileSync(join(tree, 'build_info.json'), 'utf8'));

    x = await run(godot, ['--headless', '--path', tree, '--import'], { below: true, limitMs: 10 * 60 * 1000 }); step('import', x.code === 0, `exit ${x.code}`);
    // the project's own bench: the hash every exported program must print (the same game data, the same seed)
    const b1 = await run(godot, ['--headless', '--path', tree, '--fixed-fps', '60', '--', '--seed=4', `--frames=${frames}`, '--bench'], { below: true });
    const h1 = hashLine(b1.out);
    step('the project\'s own bench prints a gameplay hash', !!h1, h1 || 'none');

    for (const platform of platforms) {
      const n = names(c8, platform), program = PROGRAMS[platform];
      const exp = join(scratch, 'export-' + platform); mkdirSync(exp, { recursive: true });
      const bin = join(exp, program);
      x = await run(godot, ['--headless', '--path', tree, '--export-release', PRESETS[platform], bin], { below: true });
      step(`export "${PRESETS[platform]}" (release, Compatibility, x86_64, pck embedded)`, x.code === 0 && existsSync(bin), existsSync(bin) ? `${statSync(bin).size} bytes` : `exit ${x.code}: ${x.out.trim().split(/\r?\n/).pop()}`);
      let benchLine = '';
      if (canPlay(platform, process.platform)) {
        const b2 = await run(bin, ['--headless', '--fixed-fps', '60', '--', '--seed=4', `--frames=${frames}`, '--bench'], { cwd: exp, below: true });
        const h2 = hashLine(b2.out);
        step(`the ${platform} program's bench prints the same gameplay hash as the project's`, !!h1 && h1 === h2, `${h1 || 'none'} | ${h2 || 'none'}`);
        benchLine = `bench ${h2} (the program was played here)`;
      } else {
        benchLine = `bench: the ${platform} program was NOT played on this PC (it is not a ${process.platform === 'win32' ? 'Windows' : 'Linux'} program); the project's own bench here printed ${h1}, and the desktop-builds.yml run plays the Linux program on a Linux runner and compares its hash`;
        console.log(`note ${benchLine}`);
        rec.push(`note ${benchLine}`);
      }

      const pkg = join(scratch, 'pkg-' + platform, n.folder); mkdirSync(pkg, { recursive: true });
      const notice = ['--notice', OWNER_NOTICE, '--private'];
      x = await node([pkgTool, 'text', '--platform', platform, '--out', pkg, '--build-info', join(tree, 'build_info.json'), ...notice]); step(`${platform}: README.txt, NOTICES.txt and build_info.json (owner notice, ORB-PRIVATE line)`, x.code === 0, x.out.trim().split(/\r?\n/).pop());
      cpSync(bin, join(pkg, program));
      mkdirSync(out, { recursive: true });
      const archive = join(out, n.archive);
      rmSync(archive, { force: true });
      const chk = join(scratch, 'check-' + platform); mkdirSync(chk, { recursive: true });
      if (platform === 'windows') {
        const z = ps(`Compress-Archive -Path '${pkg}' -DestinationPath '${archive}' -CompressionLevel Optimal`);
        step('windows: zipped', z.status === 0 && existsSync(archive), existsSync(archive) ? `${statSync(archive).size} bytes` : String(z.stderr).slice(0, 160));
        const u = ps(`Expand-Archive -Path '${archive}' -DestinationPath '${chk}' -Force`);
        step('windows: unzipped somewhere new, the way a player does', u.status === 0, '');
      } else {
        writeFileSync(archive, targz(folderEntries(pkg, n.folder, [program]), mtime));
        step('linux: archived as .tar.gz (the program 0755, the rest 0644)', existsSync(archive), `${statSync(archive).size} bytes`);
        const modes = readTarGz(readFileSync(archive));
        const prog = modes.find((e) => e.name === `${n.folder}/${program}`);
        step('linux: the program has its executable bit inside the archive', !!prog && (prog.mode & 0o111) === 0o111, prog ? prog.mode.toString(8) : 'the program is not in the archive');
        const tx = existsSync(winTar) && process.platform === 'win32' ? spawnSync(winTar, ['-xzf', archive, '-C', chk], { encoding: 'utf8' }) : spawnSync('tar', ['-xzf', archive, '-C', chk], { encoding: 'utf8' });
        step('linux: unpacked somewhere new with the system tar, the way a player does', tx.status === 0, tx.status === 0 ? '' : String(tx.stderr).slice(0, 160));
      }
      x = await node([pkgTool, 'verify', '--platform', platform, '--dir', join(chk, n.folder), '--commit', sha, '--locked', ...notice]); step(`${platform}: the folder verifies (files, magic bytes, embedded pck, notices, lock, ORB-PRIVATE line)`, x.code === 0, x.out.trim().split(/\r?\n/).pop().slice(0, 200));

      const sum = sha256(archive);
      writeFileSync(join(out, `${n.archive}.sha256.txt`), `${sum}  ${n.archive}\n`);
      rec.push('', `file ${n.archive}`, `size ${statSync(archive).size} bytes`, `sha256 ${sum}`, `version ${info.version || 'none'}`, benchLine, '');
      results.push({ platform, archive, sum, size: statSync(archive).size });
    }
    rec.push('For Orb and Orb 2 only. Move it by a drive, the home network or a private message. Never a public link.');
    writeRecord();
    if (testOnly) console.log("\nTEST ONLY: this package used the working tree's packaging tool and is not a build of the commit alone: do not hand it on.");
    for (const q of results) console.log(`\nDONE (${q.platform}): ${q.archive}\n  sha256 ${q.sum}\n  ${q.size} bytes; commit ${c8}; version ${info.version || 'none'}`);
    console.log('\n  for Orb and Orb 2 only: a drive, the home network or a private message, never a public link');
  } finally {
    if (!a.includes('--keep-scratch') && !process.exitCode) { try { rmSync(scratch, { recursive: true, force: true }); } catch { /* left for the OS */ } }
  }
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) main().catch((e) => { console.error(`desktop-local-build: ${e.message}`); process.exit(1); });
void readdirSync;
