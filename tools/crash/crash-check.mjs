// The forced-crash test of the built program (Tools, 2026-11-23; path to Alpha 1, job 14, X-28 "when the game dies, a file says why and the report folder picks it up"). One run per platform.
//   node tools/crash/crash-check.mjs [--rev HEAD] [--godot <exe>] [--keep] [--expect-report] [--out <file>]
// What it does, on a SCRATCH copy of the commit (git archive; the working tree is not read): adds a probe (an autoload, scratch only, never in the game) that, when the command line says `crashtest`, crashes the engine
// (OS.crash) one second in, or with `hangtest` spins forever; exports the host's desktop preset (Windows Desktop or Linux, release, as a player's build is); starts the PROGRAM headless with its data folders moved off
// the real ones (tools/smoke isolatedEnv), and reads what it left:
//   1 the program died (a non-zero exit, not a clean quit)               2 a log file exists in the game's data folder (user://logs)
//   3 that log says why (the engine's own error line with the reason)    4 the NEXT start keeps the dead run's log (the log is rotated to a dated file, not overwritten)
//   5 a hang is stopped by the harness at its time limit and its log shows the run started (what a hang leaves; nothing says WHY: a hang has no reason line, and that is reported, not hidden)
//   6 the report folder picks the log up (--expect-report; WAITING until UI's report folder copies the logs: the rows say so and do not fail the run without the flag)
// The record is written clean of folder paths. Nothing is uploaded. Godot runs headless at below-normal priority.
import { spawn, spawnSync } from 'node:child_process';
import { existsSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, rmSync, statSync, writeFileSync } from 'node:fs';
import { tmpdir, setPriority, constants as osConstants } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { cleanPaths } from '../record-paths.mjs';
import { isolatedEnv } from '../smoke/mode-smoke.mjs';

const REPO = resolve(dirname(fileURLToPath(import.meta.url)), '..', '..');
export const REASON = 'forced crash test (scratch)';

export const PROBE = `extends Node
## Scratch only (tools/crash/crash-check.mjs): never in the game. A crash or a hang on request, one second in.
func _ready() -> void:
\tvar a: PackedStringArray = OS.get_cmdline_user_args()
\tif a.has("crashtest") or a.has("--crashtest"):
\t\tawait get_tree().create_timer(1.0).timeout
\t\tOS.crash("${REASON}")
\tif a.has("hangtest") or a.has("--hangtest"):
\t\tawait get_tree().create_timer(1.0).timeout
\t\twhile true:
\t\t\tpass
`;

/** The project.godot text with the probe autoload added. Pure. */
export function withProbe(text) {
  if (/^\[autoload\]/m.test(text)) return text.replace(/^\[autoload\]\s*$/m, '[autoload]\n\nCrashProbe="*res://crash_probe.gd"');
  return text.replace(/\s*$/, '\n') + '\n[autoload]\n\nCrashProbe="*res://crash_probe.gd"\n';
}

/** The log files under a data folder: [{ name, size, mtimeMs, text }], newest first. A log is any .log under a "logs" folder. */
export function logsUnder(dir) {
  const out = [];
  const walk = (d) => { for (const n of readdirSync(d)) { const f = join(d, n); if (statSync(f).isDirectory()) walk(f); else if (/[\\/]logs$/.test(d) && /\.log$/i.test(n)) out.push({ name: n, size: statSync(f).size, mtimeMs: statSync(f).mtimeMs, text: readFileSync(f, 'utf8') }); } };
  if (existsSync(dir)) walk(dir);
  return out.sort((a, b) => b.mtimeMs - a.mtimeMs);
}

/** Reads what a crashed run left. `logs` as from logsUnder, `exit` the program's exit code (null when the harness stopped it). Pure.
 *  => { died, logged, saysWhy, versionLine, lines } */
export function readCrash({ logs, exit }) {
  const all = logs.map((l) => l.text).join('\n');
  return { died: exit !== 0, logged: logs.length > 0, saysWhy: all.includes(REASON), versionLine: /Godot Engine v[\d.]+/.test(all), lines: all.split(/\r?\n/).filter(Boolean).length, files: logs.length };
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

function run(exe, args, env, limitMs, cwd) {
  return new Promise((ok) => {
    const child = spawn(exe, args, { cwd, env, stdio: ['ignore', 'pipe', 'pipe'], windowsHide: true });
    try { setPriority(child.pid, osConstants.priority.PRIORITY_BELOW_NORMAL); } catch { /* gone */ }
    let out = '', stopped = false;
    child.stdout.on('data', (d) => { out += d; }); child.stderr.on('data', (d) => { out += d; });
    const t = setTimeout(() => { stopped = true; try { if (process.platform === 'win32') spawn('taskkill', ['/PID', String(child.pid), '/T', '/F'], { windowsHide: true }); else child.kill('SIGKILL'); } catch { /* gone */ } }, limitMs);
    child.on('error', (e) => { clearTimeout(t); ok({ code: -1, out: String(e), stopped }); });
    child.on('close', (code, sig) => { clearTimeout(t); ok({ code: stopped ? null : (code === null ? -1 : code), signal: sig, out, stopped }); });
  });
}

async function main() {
  const a = process.argv.slice(2);
  const opt = (n, d) => { const i = a.indexOf(n); return i >= 0 && i + 1 < a.length ? a[i + 1] : d; };
  const win = process.platform === 'win32';
  const platform = win ? 'windows' : 'linux';
  const preset = win ? 'Windows Desktop' : 'Linux';
  const { godotExe, runGodot } = await import(pathToFileURL(join(REPO, 'tools', 'preview', 'preview.mjs')).href);
  const godot = godotExe(opt('--godot'));
  const rev = opt('--rev', 'HEAD');
  const sha = spawnSync('git', ['-C', REPO, 'rev-parse', '--verify', `${rev}^{commit}`], { encoding: 'utf8' }).stdout.trim();
  if (!sha) { console.error(`crash-check: "${rev}" is not a commit`); process.exit(2); }
  const scratch = mkdtempSync(join(tmpdir(), 'crash-check-'));
  const tree = join(scratch, 'tree');
  const rows = [];
  const row = (name, ok, detail = '') => { rows.push({ name, ok, detail }); console.log(`${ok === null ? 'wait' : ok ? 'ok  ' : 'FAIL'} ${name}${detail ? ': ' + detail : ''}`); };
  try {
    mkdirSync(tree, { recursive: true });
    const tarFile = join(scratch, 'c.tar');
    spawnSync('git', ['-C', REPO, 'archive', '--format=tar', '-o', tarFile, sha]);
    const winTar = join(process.env.SystemRoot || 'C:\\Windows', 'System32', 'tar.exe');
    const x = win && existsSync(winTar) ? spawnSync(winTar, ['-xf', tarFile, '-C', tree]) : spawnSync('tar', ['-xf', tarFile, '-C', tree]);
    if (x.status !== 0) throw new Error('could not unpack the commit');
    writeFileSync(join(tree, 'crash_probe.gd'), PROBE);
    writeFileSync(join(tree, 'project.godot'), withProbe(readFileSync(join(tree, 'project.godot'), 'utf8')));
    let code = await runGodot({ godot }, ['--headless', '--path', tree, '--import'], join(scratch, 'import.log'), 15 * 60 * 1000);
    if (code !== 0) throw new Error('import failed');
    const exp = join(scratch, 'export'); mkdirSync(exp);
    const exe = join(exp, win ? 'orb-combat-ex.exe' : 'orb-combat-ex.x86_64');
    code = await runGodot({ godot }, ['--headless', '--path', tree, '--export-release', preset, exe], join(scratch, 'export.log'), 15 * 60 * 1000);
    if (!existsSync(exe)) throw new Error('export failed');
    if (!win) spawnSync('chmod', ['+x', exe]);
    row(`the "${preset}" release export with the probe`, true, `${statSync(exe).size} bytes`);

    const home = join(scratch, 'home'); mkdirSync(home);
    const env = isolatedEnv(process.env, home);
    const r1 = await run(exe, ['--headless', '--fixed-fps', '60', '--', '--seed=4', 'crashtest'], env, 120000, exp);
    const logs1 = logsUnder(home);
    const c = readCrash({ logs: logs1, exit: r1.code });
    row('1 the program died (not a clean quit)', c.died && !r1.stopped, `exit ${r1.code}${r1.signal ? ' signal ' + r1.signal : ''}`);
    row('2 a log file is in the game\'s data folder', c.logged, `${c.files} file(s), ${c.lines} lines`);
    row('3 the log says why (the engine\'s own error line with the reason)', c.saysWhy);
    const crashLog = logs1.find((l) => l.text.includes(REASON));
    const r2 = await run(exe, ['--headless', '--fixed-fps', '60', '--', '--seed=4', '--frames=30'], env, 120000, exp);
    const logs2 = logsUnder(home);
    const kept = logs2.some((l) => l.text.includes(REASON));
    row('4 the next start keeps the dead run\'s log (rotated to a dated file, not overwritten)', kept && logs2.length > logs1.length, `${logs1.length} then ${logs2.length} file(s); next start exit ${r2.code}`);
    const r3 = await run(exe, ['--headless', '--fixed-fps', '60', '--', '--seed=4', 'hangtest'], env, 25000, exp);
    const logs3 = logsUnder(home);
    row('5 a hang is stopped by the harness; its log shows the run started', r3.stopped && logs3.length >= logs2.length && logs3.some((l) => /Godot Engine v/.test(l.text) && !l.text.includes(REASON)), `${r3.stopped ? 'stopped at the limit' : 'it ended by itself: exit ' + r3.code}; a hang leaves no reason line`);
    const reports = join(home);
    const picked = (function find(d) { if (!existsSync(d)) return false; for (const n of readdirSync(d)) { const f = join(d, n); if (statSync(f).isDirectory()) { if (/reports$/.test(f) && readdirSync(f).some((m) => /\.log$/i.test(m) || /log/i.test(m))) return true; if (find(f)) return true; } } return false; })(reports);
    row('6 the report folder picks the log up', a.includes('--expect-report') ? picked : (picked ? true : null), picked ? 'a log is in user://reports' : 'nothing in user://reports (UI\'s report folder does not copy logs yet: waiting for a grant)');
    void crashLog;
  } catch (e) { row('the test could not run', false, e.message); }
  finally { if (!a.includes('--keep')) { try { rmSync(scratch, { recursive: true, force: true }); } catch { /* left */ } } }
  const failed = rows.filter((r) => r.ok === false).length;
  const text = cleanPaths([`# Forced-crash check, ${platform}, commit ${sha.slice(0, 8)} (${new Date().toISOString().slice(0, 10)})`, '', ...rows.map((r) => `- ${r.ok === null ? 'WAITING' : r.ok ? 'ok' : 'FAIL'}: ${r.name}${r.detail ? ' (' + r.detail + ')' : ''}`), '', `${failed} failed.`].join('\n'));
  if (opt('--out')) writeFileSync(resolve(opt('--out')), text + '\n');
  console.log(`\ncrash-check ${platform}: ${failed} failed`);
  process.exit(failed ? 1 : 0);
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) main();
void sleep;
