// Proves the capture guards on this machine (docs/tools/machine-captures.md): `node tools/machine/selftest.mjs [--quick]`. Starts real browsers through tools/machine/browser.mjs and checks:
//   0  (no browser; --quote-only runs just this) the launcher's quoting: the flags survive Windows quoting exactly (a flag with a space, a quote, a trailing backslash), the PowerShell helper's dry run builds the same line, and a flag that cannot be
//      passed safely is refused before any browser or helper exists (2026-11-01: a flag with a space made Chrome's whole command line its data directory and put a box on Orb's screen)
//   1  a normal launch and close leaves no process and no profile folder behind
//   1b the profile folder is made and proven writable before a browser starts (a folder that cannot be made is a plain error naming it), the browser carries --noerrdialogs, and a start that fails leaves
//      no folder behind (2026-10-27: "Failed To Create Data Directory", a modal on a desktop)
//   2  a capture past its time limit is ended by the guard itself (the caller does nothing)
//   3  a capture whose launcher is killed mid-run is gone within the watchdog's interval (Windows: the job helper polls the parent; elsewhere a watchdog shell)
//   3b the launcher's own hard deadline ends the browser AND the launcher, even when it is stuck awaiting a page
//   3c a capture that stops talking to its browser is ended as idle (the capture is done, or stuck)
//   4  the CPU cap holds: a page that keeps every core busy uses about the cap's share, not the machine
// Exit 0 when every check passes. Takes about a minute (--quick skips check 4).
import { spawn, spawnSync } from 'node:child_process';
import { existsSync, mkdtempSync, readFileSync, readdirSync, rmSync, writeFileSync } from 'node:fs';
import { platform, cpus, tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { Cdp, launchBrowser, prepareProfile, processesWithProfile, winQuote, winSplit, assertSafeFlags } from './browser.mjs';

const here = dirname(fileURLToPath(import.meta.url));
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const quick = process.argv.includes('--quick');
const win = platform() === 'win32';
let failed = 0;
const check = (name, ok, detail = '') => { console.log(`${ok ? 'ok  ' : 'FAIL'} ${name}${detail ? ' (' + detail + ')' : ''}`); if (!ok) failed++; };

/** Processes whose command line carries the profile folder (pids), and their CPU seconds (user + kernel). */
function treeOf(profile) {
  if (win) {
    const r = spawnSync('powershell', ['-NoProfile', '-Command', `$p = Get-CimInstance Win32_Process | Where-Object { $_.Name -eq 'chrome.exe' -and $_.CommandLine -like '*${profile.replace(/'/g, "''")}*' }; if ($p) { ConvertTo-Json -Compress @($p | ForEach-Object { @{ pid = $_.ProcessId; cpu = ($_.UserModeTime + $_.KernelModeTime) / 1e7 } }) } else { '[]' }`], { encoding: 'utf8', timeout: 150000 });
    try { return JSON.parse(r.stdout.trim() || '[]'); } catch { return []; }
  }
  const r = spawnSync('pgrep', ['-f', profile], { encoding: 'utf8' });
  return r.stdout.split('\n').filter(Boolean).map((p) => ({ pid: Number(p), cpu: 0 }));
}
async function waitGone(profile, ms) {
  const t0 = Date.now();
  while (Date.now() - t0 < ms) { if (treeOf(profile).length === 0) return Date.now() - t0; await sleep(1000); }
  return -1;
}

// 0
{
  const prof = 'C:\\Users\\<user> two\\AppData\\Local\\Temp\\cap-selftest-quote-000000';   // a profile folder with a space in its name (a placeholder: the content screen allows <user>)
  const CASES = {
    'the launcher\'s own flags': [`--user-data-dir=${prof}`, '--remote-debugging-port=0', '--headless=new', '--no-first-run', 'about:blank'],
    'a profile path with a space': [`--user-data-dir=${prof}`, '--remote-debugging-port=0', 'about:blank'],
    'a flag with a space (a user agent)': ['--user-data-dir=C:\\t\\cap-x', '--user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/156', 'about:blank'],
    'a flag with quotes': ['--user-data-dir=C:\\t\\cap-x', '--x=a "b" c', 'about:blank'],
    'a trailing backslash and a space': ['--user-data-dir=C:\\Old PC\\Temp\\cap-x\\', '--remote-debugging-port=0', 'about:blank'],
    'backslashes before a quote': ['--a=b\\\\"c d', 'about:blank'],
    'one flag': ['about:blank'],
    'an empty argument': ['--x', '', 'about:blank'],
  };
  const jsBad = Object.entries(CASES).filter(([, f]) => { const b = winSplit(winQuote(f)); return b.length !== f.length || b.some((a, i) => a !== f[i]); }).map(([n]) => n);
  check('0 every case reads back from its quoted line as exactly its flags (the launcher\'s own check, winQuote and winSplit)', jsBad.length === 0, jsBad.join('; '));
  if (win) {
    const dir = mkdtempSync(join(tmpdir(), 'qt-'));
    const names = Object.keys(CASES);
    const lines = [], errs = [];
    for (const n of names) {
      const f = join(dir, `a-${lines.length}.json`);
      writeFileSync(f, JSON.stringify(CASES[n]));
      const r = spawnSync('powershell', ['-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', join(here, 'capture-job.ps1'), '-Exe', 'x.exe', '-ArgsFile', f, '-ParentPid', '1', '-DeadlineMs', '1', '-DryRun'], { encoding: 'utf8', timeout: 60000 });
      if (r.status !== 0) errs.push(`${n}: exit ${r.status} ${String(r.stderr).trim().slice(0, 100)}`);
      lines.push(String(r.stdout || '').replace(/\r?\n$/, ''));
    }
    // the Windows parser itself (shell32 CommandLineToArgvW), one call for every line: what Chrome would be given
    const lf = join(dir, 'lines.json'), pf = join(dir, 'parse.ps1');
    writeFileSync(lf, JSON.stringify(lines));
    writeFileSync(pf, [
      "param([string]$F)",
      "Add-Type -TypeDefinition @'",
      "using System; using System.Runtime.InteropServices;",
      "public static class CL { [DllImport(\"shell32.dll\", SetLastError = true)] static extern IntPtr CommandLineToArgvW([MarshalAs(UnmanagedType.LPWStr)] string cl, out int n);",
      "  public static string[] Split(string cl) { int n; IntPtr p = CommandLineToArgvW(\"x.exe \" + cl, out n); string[] r = new string[n - 1]; for (int i = 1; i < n; i++) r[i - 1] = Marshal.PtrToStringUni(Marshal.ReadIntPtr(p, i * IntPtr.Size)); return r; } }",
      "'@",
      "$all = Get-Content -LiteralPath $F -Raw | ConvertFrom-Json",
      "$out = @(); foreach ($l in $all) { $out += ,@([CL]::Split([string]$l)) }",
      "ConvertTo-Json -InputObject $out -Compress -Depth 4",
    ].join('\n'));
    const rp = spawnSync('powershell', ['-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', pf, '-F', lf], { encoding: 'utf8', timeout: 60000 });
    let parsed = [];
    try { parsed = JSON.parse(rp.stdout.trim()); } catch { /* reported below */ }
    const winBad = names.filter((n, i) => { const want = CASES[n]; const got = Array.isArray(parsed[i]) ? parsed[i] : (parsed[i] === undefined ? [] : [parsed[i]]); return got.length !== want.length || got.some((a, k) => a !== want[k]); });
    check('0 the PowerShell helper\'s dry run builds a line Windows reads back as exactly the flags, on every case (a flag with a space made one argument of them all before the fix)', errs.length === 0 && winBad.length === 0 && parsed.length === names.length, [...errs, ...winBad].join('; ') || `${names.length} cases`);
    const bad = join(dir, 'bad.json');
    writeFileSync(bad, JSON.stringify(['--a', ['--nested', 'x'], 'about:blank']));
    const rb = spawnSync('powershell', ['-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', join(here, 'capture-job.ps1'), '-Exe', 'x.exe', '-ArgsFile', bad, '-ParentPid', '1', '-DeadlineMs', '1', '-DryRun'], { encoding: 'utf8', timeout: 60000 });
    check('0 the helper refuses an argument that is not a plain string (exit 3, a message, no line built)', rb.status === 3 && /refusing to start/.test(String(rb.stderr)) && !String(rb.stdout).trim(), `exit ${rb.status}`);
    rmSync(dir, { recursive: true, force: true });
  }
  const refuse = (flags) => { try { assertSafeFlags(flags); return ''; } catch (e) { return e.message; } };
  check('0 a flag that is not a string, is empty, has a line break or NUL, or sets --user-data-dir is refused before any browser exists', /not a non-empty string/.test(refuse([{ a: 1 }])) && /not a non-empty string/.test(refuse([''])) && /line break/.test(refuse(['--x\ny'])) && /line break/.test(refuse(['--x\u0000y'])) && /belongs to the launcher/.test(refuse(['--user-data-dir=C:\\x'])) && /not a list/.test(refuse('--x')) && refuse(['--user-agent=a b', '--x="q"']) === '');
  const foldersBefore = readdirSync(tmpdir()).filter((x) => x.startsWith('cap-selftest-')).length;
  let msg = '';
  try { await launchBrowser({ exe: join(tmpdir(), 'no-such-browser.exe'), session: 'selftest', purpose: 'refuse', flags: ['--ok', 'bad\nflag'], timeoutS: 30, log: () => {} }); } catch (e) { msg = e.message; }
  const foldersAfter = readdirSync(tmpdir()).filter((x) => x.startsWith('cap-selftest-')).length;
  check('0 a launch with an unsafe flag throws before it makes a profile folder or starts a helper', /refused before any browser was started/.test(msg) && foldersAfter === foldersBefore, `${msg.slice(0, 80)}; folders ${foldersBefore} to ${foldersAfter}`);
}
if (process.argv.includes('--quote-only')) { console.log(failed ? `capture quoting: ${failed} FAILED` : 'capture quoting ok'); process.exit(failed ? 1 : 0); }

// 1
{
  const b = await launchBrowser({ session: 'selftest', purpose: 'normal', timeoutS: 120, log: () => {} });
  const page = await Cdp.open(b.target.webSocketDebuggerUrl);
  const two = await page.eval('1 + 1');
  page.close();
  const upBefore = treeOf(b.profile).length;
  await b.close();
  const left = treeOf(b.profile).length;
  check('1 a browser starts, answers and is closed without a trace', two === 2 && upBefore > 0 && left === 0 && !existsSync(b.profile), `${upBefore} processes before, ${left} after, profile ${existsSync(b.profile) ? 'left' : 'removed'}`);
}
// 1b
{
  const base = mkdtempSync(join(tmpdir(), 'selftest-profile-'));
  try {
    const good = join(base, 'cap-selftest-good-000001');
    let ok1 = false, err = '';
    try { prepareProfile(good); ok1 = existsSync(good); writeFileSync(join(good, 'x'), 'y'); } catch (e) { err = e.message; }
    check('1b the profile folder is made and writable before the start', ok1 && !err, err);
    const file = join(base, 'a-file');
    writeFileSync(file, 'not a folder');
    let msg = '';
    try { prepareProfile(join(file, 'cap-selftest-bad-000002')); } catch (e) { msg = e.message; }
    check('1b a folder that cannot be made is a plain error that names it (the launch counts it a failed attempt)', /cannot be created or written/.test(msg) && msg.includes('cap-selftest-bad-000002'), msg.slice(0, 120));
    check('1b nothing carries a folder nobody started a browser in', processesWithProfile(join(base, 'cap-selftest-nothing-000003')) === 0);
  } finally { rmSync(base, { recursive: true, force: true }); }
  const b = await launchBrowser({ session: 'selftest', purpose: 'noerr', timeoutS: 90, log: () => {} });
  let cl = '';
  if (win) cl = spawnSync('powershell', ['-NoProfile', '-Command', `(Get-CimInstance Win32_Process | Where-Object { $_.Name -eq 'chrome.exe' -and $_.CommandLine -like '*${b.profile.replace(/'/g, "''")}*' } | Select-Object -First 1).CommandLine`], { encoding: 'utf8' }).stdout;
  else cl = spawnSync('pgrep', ['-af', b.profile], { encoding: 'utf8' }).stdout;
  check('1b the browser is started with --noerrdialogs (a failure exits quietly, no modal box on the desktop)', cl.includes('--noerrdialogs'), cl.slice(0, 100));
  await b.close();
  // a start that fails (no such browser): the error is raised, and no folder or registry entry of the attempts is left
  const before = new Set(readdirSync(tmpdir()).filter((n) => n.startsWith('cap-selftest-badexe')));
  let threw = false;
  try { await launchBrowser({ exe: join(tmpdir(), 'no-such-browser.exe'), session: 'selftest', purpose: 'badexe', timeoutS: 30, portWaitMs: 4000, attempts: 2, graceS: 30, log: () => {} }); } catch { threw = true; }
  const after = readdirSync(tmpdir()).filter((n) => n.startsWith('cap-selftest-badexe') && !before.has(n));
  check('1b a start that fails raises its error and leaves no profile folder behind', threw && after.length === 0, `threw ${threw}, left ${after.join(',') || 'nothing'}`);
}
// 2
{
  const b = await launchBrowser({ session: 'selftest', purpose: 'limit', timeoutS: 45, graceS: 0, exitOnDeadline: false, log: () => {} });
  const t0 = Date.now();
  const gone = await waitGone(b.profile, 120000);
  const reg = existsSync(b.entry.registry) ? JSON.parse(readFileSync(b.entry.registry, 'utf8').replace(/^﻿/, '')) : {};
  check('2 a capture past its time limit is ended by the guard', gone >= 0 && (Date.now() - t0) < 75000 && (reg.ended === 'deadline' || reg.ended === undefined), `limit 45 s from the launch, gone after ${gone < 0 ? 'never' : Math.round((Date.now() - t0) / 1000) + ' s'}${reg.ended ? ', reason ' + reg.ended : ''}`);
  await b.close();
}
// 3
{
  const child = spawn(process.execPath, [fileURLToPath(new URL('./selftest-child.mjs', import.meta.url))], { stdio: ['ignore', 'pipe', 'inherit'] });
  let profile = '';
  child.stdout.on('data', (d) => { const m = /PROFILE (.+)/.exec(String(d)); if (m) profile = m[1].trim(); });
  for (let i = 0; i < 120 && !profile; i++) await sleep(500);
  await sleep(1500);
  const up = profile ? treeOf(profile).length : 0;
  if (win) spawnSync('taskkill', ['/PID', String(child.pid), '/F'], { stdio: 'ignore' }); else child.kill('SIGKILL');
  const t0 = Date.now();
  const gone = profile ? await waitGone(profile, 30000) : -1;
  check('3 a capture whose launcher is killed mid-run leaves no browser', up > 0 && gone >= 0, `${up} processes up, gone ${gone < 0 ? 'never' : 'after ' + Math.round((Date.now() - t0) / 1000) + ' s'}`);
}
// 3b
{
  const child = spawn(process.execPath, [fileURLToPath(new URL('./selftest-child.mjs', import.meta.url))], { stdio: ['ignore', 'pipe', 'inherit'], env: { ...process.env, CHILD_TIMEOUT: '30', CHILD_GRACE: '0' } });
  let profile = '';
  let exitCode = null;
  child.on('exit', (c) => { exitCode = c; });
  child.stdout.on('data', (d) => { const m = /PROFILE (.+)/.exec(String(d)); if (m) profile = m[1].trim(); });
  const t0 = Date.now();
  for (let i = 0; i < 360 && exitCode === null; i++) await sleep(500);
  const gone = profile ? await waitGone(profile, 30000) : -1;
  check("3b the launcher's own deadline ends the browser and the launcher", exitCode === 124 && gone >= 0, `child exit ${exitCode} after ${Math.round((Date.now() - t0) / 1000)} s, browser ${gone >= 0 ? 'gone' : 'still up'}`);
  if (exitCode === null) { try { child.kill(); } catch { /* gone */ } }
}
// 3c
{
  const b = await launchBrowser({ session: 'selftest', purpose: 'idle', timeoutS: 600, graceS: 0, idleS: 25, log: () => {} });
  const page = await Cdp.open(b.target.webSocketDebuggerUrl);
  await page.eval('1');
  const t0 = Date.now();
  const gone = await waitGone(b.profile, 150000);
  const reg = existsSync(b.entry.registry) ? JSON.parse(readFileSync(b.entry.registry, 'utf8').replace(/^﻿/, '')) : {};
  check('3c a capture that goes quiet is ended as idle', gone >= 0 && reg.ended === 'idle', `idle limit 25 s, gone after ${gone < 0 ? 'never' : Math.round((Date.now() - t0) / 1000) + ' s'}, reason ${reg.ended || '?'}`);
  page.close();
  await b.close();
}
// 4
if (!quick) {
  const cores = cpus().length;
  const measure = async (cpuPercent) => {
    const b = await launchBrowser({ session: 'selftest', purpose: 'cpu', timeoutS: 120, cpuPercent, portWaitMs: 240000, attempts: 1, flags: ['--window-size=640,360'], log: () => {} });   // no software-rendering flags: a software browser takes no mask (check 4b)
    const page = await Cdp.open(b.target.webSocketDebuggerUrl);
    // one busy worker for every core, twice
    await page.eval(`(() => { const src = 'for(;;){}'; const u = URL.createObjectURL(new Blob([src])); window.__w = []; for (let i = 0; i < ${cores * 2}; i++) window.__w.push(new Worker(u)); return 1; })()`);
    await sleep(4000);
    const a = treeOf(b.profile).reduce((s, p) => s + p.cpu, 0), t0 = Date.now();
    await sleep(10000);
    const c = treeOf(b.profile).reduce((s, p) => s + p.cpu, 0);
    const perSec = (c - a) / ((Date.now() - t0) / 1000);
    page.close();
    await b.close();
    return perSec;
  };
  const capped = await measure(25);
  const free = await measure(0);
  const want = cores * 0.25;
  check('4 the CPU cap holds (25% of the machine)', capped <= want * 1.35 && free > capped * 1.5, `${cores} cores: capped ${capped.toFixed(1)} cores busy (cap ${want.toFixed(1)}), uncapped ${free.toFixed(1)}`);
  // 4b: software rendering (SwiftShader) never gets an affinity mask, because a page under one never answers (measured 2026-10-13): it runs unmasked at idle priority instead
  {
    const sw = await launchBrowser({ session: 'selftest', purpose: 'sw', timeoutS: 90, cpuPercent: 25, portWaitMs: 240000, attempts: 1, flags: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist', '--window-size=640,360'], log: () => {} });
    const asked = sw.entry && sw.entry.cpuPercent;
    await sw.close();
    check('4b software rendering is started without an affinity mask (cpuPercent 0 in its registry entry although 25 was asked)', asked === 0, `cpuPercent ${asked}`);
  }
}
console.log(failed ? `capture guards: ${failed} FAILED` : 'capture guards ok');
process.exit(failed ? 1 : 0);
