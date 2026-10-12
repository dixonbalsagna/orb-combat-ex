// Lists the project's capture browsers and, on request, ends the abandoned ones (docs/tools/machine-captures.md).
//
//   node tools/machine/captures.mjs                 the listing: one row per capture browser, with its owner tag, age, CPU seconds, whether its launcher is alive and whether it is past its deadline
//   node tools/machine/captures.mjs --json          the same as JSON
//   node tools/machine/captures.mjs --reap          ends those past their deadline AND whose launcher is gone (by process tree, then their profile folder), and says what it did
//   node tools/machine/captures.mjs --reap --dry    says what --reap would do
//   node tools/machine/captures.mjs --reap --legacy-minutes 90   also ends browsers with an old-style profile folder (flash-cap-, stepcap-, no registry entry) older than this, when no node
//                                                   process that started before them is still running; default: they are listed and never reaped
// A capture browser is any Chrome or Edge whose --user-data-dir is a cap-* folder in the temp folder (launched by tools/machine/browser.mjs, which also writes a registry entry in
// <temp>/meridian-captures/), or a folder of an older launcher (flash-cap-*, stepcap-*): those have no deadline, so their deadline is taken as start + --legacy-minutes (default 90).
// The owner reads from the folder name: cap-<session>-<purpose>-<id>. Windows PowerShell 5.1 and Node 24 built-ins only.
import { spawnSync } from 'node:child_process';
import { existsSync, readdirSync, readFileSync, rmSync, statSync } from 'node:fs';
import { tmpdir, platform } from 'node:os';
import { join, basename } from 'node:path';

const argv = process.argv.slice(2);
const has = (n) => argv.includes(n);
const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
const REGISTRY = join(tmpdir(), 'meridian-captures');
const LEGACY_MIN = Number(opt('--legacy-minutes', 90));
const now = Date.now();

function processes() {
  if (platform() === 'win32') {
    const script = "Get-CimInstance Win32_Process | Where-Object { $_.Name -in 'chrome.exe','msedge.exe','chrome','msedge' -and $_.CommandLine -like '*user-data-dir*' } | ForEach-Object { [pscustomobject]@{ pid = $_.ProcessId; ppid = $_.ParentProcessId; started = ([DateTimeOffset]$_.CreationDate).ToUnixTimeMilliseconds(); cpu = ($_.UserModeTime + $_.KernelModeTime) / 1e7; cmd = $_.CommandLine } } | ConvertTo-Json -Compress -AsArray";
    // Windows PowerShell 5.1 has no -AsArray: wrap by hand
    const s5 = script.replace(' -AsArray', '');
    const r = spawnSync('powershell', ['-NoProfile', '-Command', `$o = @(${s5.replace(' | ConvertTo-Json -Compress', '')}); if ($o.Count -eq 0) { '[]' } else { ConvertTo-Json -Compress -InputObject $o }`], { encoding: 'utf8', timeout: 180000, maxBuffer: 1 << 26 });
    try { return JSON.parse(r.stdout.trim() || '[]'); } catch { return []; }
  }
  const r = spawnSync('ps', ['-eo', 'pid,ppid,lstart,cputimes,args', '--no-headers'], { encoding: 'utf8', maxBuffer: 1 << 26 });
  const out = [];
  for (const line of r.stdout.split('\n')) {
    const m = /^\s*(\d+)\s+(\d+)\s+(.{24})\s+(\d+)\s+(.*)$/.exec(line);
    if (m && /chrom|msedge/.test(m[5]) && m[5].includes('user-data-dir')) out.push({ pid: +m[1], ppid: +m[2], started: Date.parse(m[3]), cpu: +m[4], cmd: m[5] });
  }
  return out;
}
const alive = (pid) => {
  if (!pid) return false;
  try { process.kill(pid, 0); return true; } catch (e) { return e.code === 'EPERM'; }
};
function nodeProcessesStartedBefore(ms) {
  if (platform() !== 'win32') return [];
  const r = spawnSync('powershell', ['-NoProfile', '-Command', "Get-CimInstance Win32_Process -Filter \"Name='node.exe'\" | ForEach-Object { [pscustomobject]@{ pid = $_.ProcessId; started = ([DateTimeOffset]$_.CreationDate).ToUnixTimeMilliseconds(); cmd = $_.CommandLine } } | ConvertTo-Json -Compress -InputObject @($input)"], { encoding: 'utf8', timeout: 60000 });
  try { const a = JSON.parse(r.stdout.trim() || '[]'); return (Array.isArray(a) ? a : [a]).filter((p) => p.started < ms && /capture|stepcap|run-pixels|check-clip|shot|frames/i.test(p.cmd || '')); } catch { return []; }
}

const reg = new Map();
if (existsSync(REGISTRY)) {
  for (const f of readdirSync(REGISTRY)) {
    if (!f.endsWith('.json')) continue;
    try { const o = JSON.parse(readFileSync(join(REGISTRY, f), 'utf8').replace(/^﻿/, '')); reg.set(basename(o.profile || f.replace(/\.json$/, '')).toLowerCase(), { ...o, file: join(REGISTRY, f) }); } catch { /* unreadable: skip */ }
  }
}
const groups = new Map();
for (const p of processes()) {
  const m = /--user-data-dir=("([^"]+)"|(\S+))/.exec(p.cmd || '');
  if (!m) continue;
  const profile = (m[2] || m[3]).replace(/\\$/, '');
  const name = basename(profile).toLowerCase();
  if (!/^(cap-|flash-cap-|stepcap-)/.test(name)) continue;
  if (!groups.has(name)) groups.set(name, { name, profile, pids: [], cpu: 0, started: Infinity, roots: [] });
  const g = groups.get(name);
  g.pids.push(p.pid); g.cpu += p.cpu; g.started = Math.min(g.started, p.started);
  if (!/--type=/.test(p.cmd)) g.roots.push(p);
}
const rows = [];
for (const g of groups.values()) {
  const r = reg.get(g.name);
  const legacy = !/^cap-/.test(g.name);
  const parts = /^cap-([^-]+(?:-[^-]+)*?)-([a-z0-9]+)-([0-9a-f]{6})$/.exec(g.name);
  const owner = r ? `${r.session}/${r.purpose}` : legacy ? `legacy ${g.name.split('-')[0]}` : parts ? `${parts[1]}/${parts[2]}` : 'unknown';
  const parentPid = r ? r.parentPid : (g.roots[0] ? g.roots[0].ppid : 0);
  const parentAlive = alive(parentPid);
  const deadline = r ? r.deadlineMs : g.started + LEGACY_MIN * 60000;
  rows.push({
    name: g.name, owner, registered: Boolean(r), legacy, processes: g.pids.length, ageMin: Math.round((now - g.started) / 60000), cpuSeconds: Math.round(g.cpu),
    parentPid, parentAlive: r ? parentAlive : parentAlive ? true : null, pastDeadline: now > deadline, deadline: new Date(deadline).toTimeString().slice(0, 8), pids: g.pids, profile: g.profile, entry: r || null,
    note: r ? '' : legacy ? `no registry entry: deadline taken as start + ${LEGACY_MIN} min; its parent pid is a guess (a recent Chrome's launcher exits at once)` : 'no registry entry',
  });
}
rows.sort((a, b) => b.cpuSeconds - a.cpuSeconds);

if (has('--json') && !has('--reap')) { console.log(JSON.stringify(rows, null, 2)); process.exit(0); }
if (!has('--reap')) {
  if (!rows.length) console.log('no capture browsers running');
  else {
    console.log(['owner'.padEnd(26), 'procs'.padStart(5), 'age min'.padStart(8), 'cpu s'.padStart(7), 'launcher'.padEnd(12), 'deadline'.padEnd(9), 'state'.padEnd(26), 'folder'].join(' '));
    for (const r of rows) {
      const launcher = r.registered ? (r.parentAlive ? `${r.parentPid} alive` : `${r.parentPid} GONE`) : (r.parentAlive ? '? alive' : '? gone');
      const state = r.pastDeadline ? (r.registered && !r.parentAlive ? 'PAST DEADLINE, ORPHAN' : r.registered ? 'past its deadline' : 'old (legacy)') : r.registered && !r.parentAlive ? 'ORPHAN (guard ends it)' : 'running';
      console.log([r.owner.padEnd(26), String(r.processes).padStart(5), String(r.ageMin).padStart(8), String(r.cpuSeconds).padStart(7), launcher.padEnd(12), r.deadline.padEnd(9), state.padEnd(26), r.name].join(' '));
    }
  }
  const stale = existsSync(REGISTRY) ? readdirSync(REGISTRY).length : 0;
  console.log(`\n${rows.length} capture browser${rows.length === 1 ? '' : 's'}; ${stale} registry entr${stale === 1 ? 'y' : 'ies'} in ${REGISTRY}`);
  process.exit(0);
}

// --reap
const dry = has('--dry');
const done = [];
for (const r of rows) {
  let why = null;
  if (r.registered && r.pastDeadline && !r.parentAlive) why = `past its deadline (${r.deadline}) and its launcher ${r.parentPid} is gone`;
  else if (!r.registered && r.legacy && has('--legacy-minutes') && r.ageMin >= LEGACY_MIN) {
    const earlier = nodeProcessesStartedBefore(Date.now() - r.ageMin * 60000 + 60000);
    if (!earlier.length) why = `a legacy capture ${r.ageMin} min old and no capture script of an earlier start is running`;
  }
  if (!why) { done.push(`kept   ${r.name} (${r.owner}, ${r.processes} processes, ${r.cpuSeconds} cpu s): ${r.pastDeadline ? 'past its deadline but its launcher is alive or unknown' : 'not past its deadline'}`); continue; }
  if (dry) { done.push(`would end ${r.name} (${r.owner}, ${r.processes} processes, ${r.cpuSeconds} cpu s): ${why}`); continue; }
  for (const pid of r.pids) spawnSync(platform() === 'win32' ? 'taskkill' : 'kill', platform() === 'win32' ? ['/PID', String(pid), '/T', '/F'] : ['-9', String(pid)], { stdio: 'ignore' });
  for (let i = 0; i < 5; i++) { try { rmSync(r.profile, { recursive: true, force: true }); break; } catch { spawnSync(process.execPath, ['-e', 'setTimeout(()=>{},500)']); } }
  if (r.entry && r.entry.file) { try { rmSync(r.entry.file, { force: true }); } catch { /* gone */ } }
  done.push(`ended  ${r.name} (${r.owner}, ${r.processes} processes, ${r.cpuSeconds} cpu s): ${why}`);
}
// registry entries and profile folders nothing is running on any more
if (existsSync(REGISTRY)) {
  const running = new Set(rows.map((r) => r.name));
  for (const f of readdirSync(REGISTRY)) {
    if (!f.endsWith('.json')) continue;
    const n = f.replace(/\.json$/, '').toLowerCase();
    if (running.has(n)) continue;
    const full = join(REGISTRY, f);
    if (now - statSync(full).mtimeMs < 10 * 60000) continue;
    if (dry) done.push(`would remove the stale registry entry ${f}`); else { try { rmSync(full, { force: true }); done.push(`removed the stale registry entry ${f}`); } catch { /* in use */ } }
  }
}
for (const d of readdirSync(tmpdir())) {
  if (!/^cap-/.test(d) || [...groups.keys()].includes(d.toLowerCase())) continue;
  const full = join(tmpdir(), d);
  try { if (!statSync(full).isDirectory() || now - statSync(full).mtimeMs < 15 * 60000) continue; } catch { continue; }
  if (dry) done.push(`would remove the abandoned profile folder ${d}`); else { try { rmSync(full, { recursive: true, force: true }); done.push(`removed the abandoned profile folder ${d}`); } catch { /* in use */ } }
}
console.log(done.length ? done.join('\n') : 'nothing to do');
