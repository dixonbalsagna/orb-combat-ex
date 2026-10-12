// Proves the capture guards on this machine (docs/tools/machine-captures.md): `node tools/machine/selftest.mjs [--quick]`. Starts real browsers through tools/machine/browser.mjs and checks:
//   1  a normal launch and close leaves no process and no profile folder behind
//   2  a capture past its time limit is ended by the guard itself (the caller does nothing)
//   3  a capture whose launcher is killed mid-run is gone within the watchdog's interval (Windows: the job helper polls the parent; elsewhere a watchdog shell)
//   3b the launcher's own hard deadline ends the browser AND the launcher, even when it is stuck awaiting a page
//   3c a capture that stops talking to its browser is ended as idle (the capture is done, or stuck)
//   4  the CPU cap holds: a page that keeps every core busy uses about the cap's share, not the machine
// Exit 0 when every check passes. Takes about a minute (--quick skips check 4).
import { spawn, spawnSync } from 'node:child_process';
import { existsSync, readFileSync } from 'node:fs';
import { platform, cpus } from 'node:os';
import { fileURLToPath } from 'node:url';
import { Cdp, launchBrowser } from './browser.mjs';

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
    const b = await launchBrowser({ session: 'selftest', purpose: 'cpu', timeoutS: 120, cpuPercent, portWaitMs: 240000, attempts: 1, flags: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist', '--window-size=640,360'], log: () => {} });
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
}
console.log(failed ? `capture guards: ${failed} FAILED` : 'capture guards ok');
process.exit(failed ? 1 : 0);
