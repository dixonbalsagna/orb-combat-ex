// The one place this project starts a headless browser (CLAUDE.md, "Machine discipline"): every picture, clip or frame capture goes through launchBrowser() below, directly (tools/flash/
// capture-web.mjs) or through the small wrapper tools/machine/capture.mjs. Node 24 built-ins only; no install.
//
// What a browser started here carries (docs/tools/machine-captures.md):
//   - a hard TIME LIMIT (timeoutS, stated in the log): when it passes, the browser tree is killed, whatever the caller is doing;
//   - it cannot OUTLIVE its launcher: on Windows the tree runs in a Job Object with kill-on-close, held by tools/machine/capture-job.ps1, which also polls this process and ends the
//     job when it is gone (or on the deadline); elsewhere a detached watchdog shell does the same by the profile folder;
//   - BELOW-NORMAL priority, and a CPU CAP (default 25% of the machine, as an affinity mask on that share of the logical processors, the same ones for every capture: SwiftShader, the software renderer, takes every core it can get otherwise);
//   - a profile folder named cap-<session>-<purpose>-<id> in the temp folder, so its owner reads from the process list, and a registry entry in <temp>/meridian-captures/ that
//     tools/machine/captures.mjs lists (and reaps, when it is past its deadline and its launcher is gone).
// The session name comes from the `session` option or the MERIDIAN_SESSION environment variable. Never start Chrome from your own script.
import { spawn, spawnSync } from 'node:child_process';
import { createServer } from 'node:http';
import { existsSync, mkdirSync, readFileSync, rmSync, statSync, utimesSync, writeFileSync } from 'node:fs';
import { tmpdir, platform, cpus } from 'node:os';
import { join, extname, resolve, sep, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { randomBytes } from 'node:crypto';

const here = dirname(fileURLToPath(import.meta.url));
export const REGISTRY_DIR = join(tmpdir(), 'meridian-captures');
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
// the limit counts from the start of the launch, plus this much for a machine that is busy (the job helper's first start compiles a little C# and a loaded machine takes minutes over it)
const STARTUP_GRACE_S = 180;
export const slug = (s, d = 'x') => String(s || d).toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '').slice(0, 24) || d;

const EXES = {
  win32: { chrome: ['C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe', 'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe'], edge: ['C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe', 'C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe'] },
  darwin: { chrome: ['/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'], edge: ['/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge'] },
  linux: { chrome: ['/usr/bin/google-chrome', '/usr/bin/chromium', '/usr/bin/chromium-browser'], edge: ['/usr/bin/microsoft-edge'] },
};
/** The path of an installed browser, or undefined. */
export function browserExe(which = 'chrome') {
  return ((EXES[platform()] || EXES.linux)[which] || []).find((p) => existsSync(p));
}

const MIME = { '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript', '.wasm': 'application/wasm', '.png': 'image/png', '.jpg': 'image/jpeg', '.json': 'application/json', '.pck': 'application/octet-stream', '.css': 'text/css', '.svg': 'image/svg+xml' };
/** A static file server for a folder on a free local port; `isolation` adds the headers a threaded WebAssembly page needs. */
export function serve(root, { isolation = false } = {}) {
  const base = resolve(root);
  const server = createServer((req, res) => {
    let p = decodeURIComponent(new URL(req.url, 'http://x').pathname);
    if (p.endsWith('/')) p += 'index.html';
    const file = resolve(join(base, p));
    if (!(file === base || file.startsWith(base + sep)) || !existsSync(file) || !statSync(file).isFile()) { res.writeHead(404); res.end('not found'); return; }
    const h = { 'content-type': MIME[extname(file)] || 'application/octet-stream' };
    if (isolation) { h['cross-origin-opener-policy'] = 'same-origin'; h['cross-origin-embedder-policy'] = 'require-corp'; }
    res.writeHead(200, h);
    res.end(readFileSync(file));
  });
  return new Promise((ok) => server.listen(0, '127.0.0.1', () => ok(server)));
}

/** A DevTools protocol connection to one page. */
export class Cdp {
  static onSend = null;
  constructor(ws) {
    this.ws = ws; this.id = 0; this.pending = new Map(); this.callTimeoutMs = 600000;
    ws.addEventListener('message', (e) => {
      const m = JSON.parse(e.data);
      if (m.id && this.pending.has(m.id)) { const { ok, fail, timer } = this.pending.get(m.id); this.pending.delete(m.id); clearTimeout(timer); if (m.error) fail(new Error(m.error.message)); else ok(m.result); }
    });
    // a browser that dies or is ended takes the socket with it: every call waiting on it fails now (before 2026-10-12 they waited forever, and a capture whose browser was stopped by hand never ended)
    const gone = () => { for (const [, p] of this.pending) { clearTimeout(p.timer); p.fail(new Error('the DevTools connection closed (the browser is gone)')); } this.pending.clear(); };
    ws.addEventListener('close', gone);
    ws.addEventListener('error', gone);
  }
  static open(url) { return new Promise((ok, fail) => { const ws = new WebSocket(url); ws.addEventListener('open', () => ok(new Cdp(ws))); ws.addEventListener('error', () => fail(new Error('DevTools socket error'))); }); }
  /** One protocol call. It fails after callTimeoutMs (default 10 minutes: a page that hangs must not hang its capture) or when the connection closes. */
  send(method, params = {}) {
    const id = ++this.id;
    if (Cdp.onSend) Cdp.onSend();   // the launcher's heartbeat: a capture that stops talking to its browser is idle, and an idle one is ended
    return new Promise((ok, fail) => {
      const timer = setTimeout(() => { this.pending.delete(id); fail(new Error(`${method} got no answer in ${Math.round(this.callTimeoutMs / 1000)} s (the page or the browser is hung)`)); }, this.callTimeoutMs);
      this.pending.set(id, { ok, fail, timer });
      try { this.ws.send(JSON.stringify({ id, method, params })); } catch (e) { this.pending.delete(id); clearTimeout(timer); fail(e); }
    });
  }
  async eval(expression, awaitPromise = false) {
    const r = await this.send('Runtime.evaluate', { expression, returnByValue: true, awaitPromise });
    if (r.exceptionDetails) throw new Error(`page error: ${r.exceptionDetails.exception?.description || r.exceptionDetails.text}`);
    return r.result ? r.result.value : undefined;
  }
  close() { try { this.ws.close(); } catch { /* gone */ } }
}

/** The machine's CPU use over `ms`, in percent of all logical processors (all processes, this one included). */
export async function cpuLoad(ms = 1000) {
  const read = () => cpus().reduce((a, c) => { const t = c.times; const total = t.user + t.nice + t.sys + t.idle + t.irq; return { total: a.total + total, idle: a.idle + t.idle }; }, { total: 0, idle: 0 });
  const a = read();
  await sleep(ms);
  const b = read();
  const dt = b.total - a.total;
  return dt > 0 ? Math.round((100 * (dt - (b.idle - a.idle))) / dt) : 0;
}

function killTreeByProfile(profile) {
  if (platform() === 'win32') {
    spawnSync('powershell', ['-NoProfile', '-Command', `Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -like '*${profile.replace(/'/g, "''")}*' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }`], { stdio: 'ignore', timeout: 30000 });
  } else spawnSync('pkill', ['-9', '-f', profile], { stdio: 'ignore' });
}

/**
 * Starts a browser with the guards above and returns { target, port, close(), profile, id, deadlineMs }. `target` is the first page target (connect with Cdp.open(target.webSocketDebuggerUrl)).
 * Options: exe (path), flags (extra command line flags: window size, GPU flags), session, purpose, timeoutS (default 5400: the hard limit), cpuPercent (default 25; 0 is no cap),
 * exitOnDeadline (default true: the hard end also ends this process with exit code 124; false only for a test of the guard itself), priority ('below-normal' by default; 'normal' only for a check that must not wait behind a busy machine), log (a function), portWaitMs, attempts, graceS (start-up allowance on top of the limit, default 180), headless (default true).
 */
export async function launchBrowser(o = {}) {
  const exe = o.exe || browserExe('chrome');
  if (!exe) throw new Error('no browser executable found (pass exe)');
  const log = o.log || ((m) => console.log(`[capture] ${m}`));
  const session = slug(o.session || process.env.MERIDIAN_SESSION, 'nosession');
  const purpose = slug(o.purpose, 'capture');
  const timeoutS = Number(o.timeoutS || 5400);
  // Software rendering (SwiftShader) cannot take an affinity mask: a page under ANY mask (94%, 75%, 50%, 25% of the cores) never answers a screenshot, with the same page at no mask
  // done in 43 s (measured 2026-10-13). A software browser therefore runs on every core at IDLE priority, which yields to everything else and is still bounded by the time limit and the job.
  const software = o.software === true || (Array.isArray(o.flags) && o.flags.some((f) => /swiftshader/i.test(String(f))));
  const cpuPercent = software ? 0 : o.cpuPercent === undefined ? 25 : Number(o.cpuPercent);
  const priority = o.priority || (software ? 'idle' : 'belownormal');
  const portWaitMs = o.portWaitMs || 90000, attempts = o.attempts || 3;
  const idleS = o.idleS === undefined ? 900 : Number(o.idleS);   // no protocol call for this long (and the launcher still alive): the capture is done or stuck, so the browser is ended; 0 is off
  const win = platform() === 'win32';
  mkdirSync(REGISTRY_DIR, { recursive: true });
  let last = 'no attempt';
  let live = null;
  const stop = async () => {
    if (!live) return;
    const l = live; live = null;
    if (l.port) {
      try {
        const v = await (await fetch(`http://127.0.0.1:${l.port}/json/version`)).json();
        const c = await Cdp.open(v.webSocketDebuggerUrl);
        await Promise.race([c.send('Browser.close'), sleep(3000)]);
        c.close();
      } catch { /* gone, or never up */ }
    }
    try { if (l.helper && l.helper.pid) { if (win) spawnSync('taskkill', ['/PID', String(l.helper.pid), '/T', '/F'], { stdio: 'ignore', timeout: 15000 }); else l.helper.kill('SIGKILL'); } } catch { /* gone */ }
    killTreeByProfile(l.profile);
    for (let i = 0; i < 8; i++) { try { rmSync(l.profile, { recursive: true, force: true }); break; } catch { await sleep(400); } }
    try { rmSync(l.registry, { force: true }); } catch { /* gone */ }
    try { if (l.argsFile) rmSync(l.argsFile, { force: true }); } catch { /* gone */ }
  };
  const onExit = () => {
    if (!live) return;
    try { if (win && live.helper && live.helper.pid) spawnSync('taskkill', ['/PID', String(live.helper.pid), '/T', '/F'], { stdio: 'ignore', timeout: 10000 }); } catch { /* gone */ }
    try { killTreeByProfile(live.profile); } catch { /* gone */ }
  };
  process.once('exit', onExit);
  for (let attempt = 1; attempt <= attempts; attempt++) {
    const id = randomBytes(3).toString('hex');
    const profile = join(tmpdir(), `cap-${session}-${purpose}-${id}`);
    const registry = join(REGISTRY_DIR, `cap-${session}-${purpose}-${id}.json`);
    mkdirSync(profile, { recursive: true });
    const graceS = o.graceS === undefined ? STARTUP_GRACE_S : Number(o.graceS);
    const deadlineMs = Date.now() + (timeoutS + graceS) * 1000;
    const flags = [`--user-data-dir=${profile}`, '--remote-debugging-port=0', ...(o.headless === false ? [] : ['--headless=new']), '--no-first-run', '--no-default-browser-check', '--disable-extensions',
      '--disable-sync', '--disable-component-update', '--hide-scrollbars', '--mute-audio', ...(process.env.CI ? ['--no-sandbox'] : []), ...(o.flags || []), 'about:blank'];
    const entry = { session, purpose, id, profile, registry, exe, parentPid: process.pid, startedAt: Date.now(), deadlineMs, timeoutS, cpuPercent, state: 'running', cwd: process.cwd(), argv: process.argv.slice(1).join(' ').slice(0, 300) };
    writeFileSync(registry, JSON.stringify(entry, null, 2) + '\n');
    let helper;
    let failed = null;
    let up = false;
    if (win) {
      const argsFile = join(profile, '..', `cap-${session}-${purpose}-${id}.args.json`);
      writeFileSync(argsFile, JSON.stringify(flags));
      helper = spawn('powershell', ['-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', join(here, 'capture-job.ps1'), '-Exe', exe, '-ArgsFile', argsFile, '-ParentPid', String(process.pid),
        '-DeadlineMs', String(deadlineMs), '-CpuPercent', String(cpuPercent), '-Priority', priority === 'normal' ? 'Normal' : priority === 'idle' ? 'Idle' : 'BelowNormal', '-IdleSeconds', String(idleS), '-Registry', registry], { stdio: ['ignore', 'ignore', process.env.MERIDIAN_CAPTURE_DEBUG ? 'inherit' : 'ignore'], windowsHide: true });
      // the helper only ends before the browser is up when it was killed, failed to build the job or hit the deadline: that is a failed start, now
      helper.on('exit', (code) => { if (!up) failed = `the capture job helper ended (exit ${code}) before the browser was up`; });
      entry.argsFile = argsFile;
    } else {
      const sh = `"$@" & BR=$!; while kill -0 ${process.pid} 2>/dev/null && [ "$(date +%s)" -lt ${Math.ceil(deadlineMs / 1000)} ]; do sleep 2; done; pkill -9 -f '${profile}' 2>/dev/null; kill -9 $BR 2>/dev/null`;
      helper = spawn('sh', ['-c', `nice -n 10 ${sh}`, '--', exe, ...flags], { stdio: 'ignore', detached: true });
      helper.unref();
    }
    helper.on('error', (e) => { failed = e.message; });
    live = { helper, profile, registry, port: 0, argsFile: entry.argsFile };
    log(`browser ${slug(`${session}-${purpose}-${id}`)}: time limit ${timeoutS} s of work (hard end ${new Date(deadlineMs).toTimeString().slice(0, 8)}, with ${graceS} s allowed for a busy machine's start), ${cpuPercent > 0 ? `CPU cap ${cpuPercent}% of the machine` : 'no CPU cap'}, ${priority === 'normal' ? 'normal' : priority === 'idle' ? 'idle' : 'below-normal'} priority${software ? ' (software rendering: no affinity mask, it hangs under one)' : ''}, profile ${profile}`);
    const t0 = Date.now();
    let port;
    while (!port && !failed && Date.now() - t0 < portWaitMs) {
      const f = join(profile, 'DevToolsActivePort');
      if (existsSync(f)) { try { const n = Number(readFileSync(f, 'utf8').split('\n')[0]); if (n > 0) port = n; } catch { /* locked while it is written */ } }
      if (!port) await sleep(200);
    }
    if (port) {
      live.port = port;
      up = true;
      let target;
      const t1 = Date.now();
      while (!target && Date.now() - t1 < 30000) {
        try { target = (await (await fetch(`http://127.0.0.1:${port}/json/list`)).json()).find((x) => x.type === 'page'); } catch { /* not up yet */ }
        if (!target) await sleep(200);
      }
      if (target) {
        // the guards that live in this process: the hard deadline ends the browser AND this process even when it is stuck awaiting a page (the helper kills the browser regardless), and every
        // protocol call is the heartbeat the helper's idle limit reads (the registry file's modified time)
        let beat = 0;
        Cdp.onSend = () => { const n = Date.now(); if (n - beat > 5000) { beat = n; try { utimesSync(registry, new Date(n), new Date(n)); } catch { /* gone */ } } };
        const timer = setTimeout(() => { log(`time limit reached (${timeoutS} s): ending the browser and this process`); onExit(); if (o.exitOnDeadline !== false) process.exit(124); }, Math.max(1000, deadlineMs - Date.now()));
        timer.unref();
        const close = async () => { clearTimeout(timer); Cdp.onSend = null; process.removeListener('exit', onExit); await stop(); };
        return { target, port, profile, id, deadlineMs, close, entry };
      }
      last = 'the browser opened its DevTools port but offered no page target in 30 s';
    } else last = failed || `the browser did not open a DevTools port in ${portWaitMs / 1000} s`;
    log(`browser launch attempt ${attempt} of ${attempts} failed: ${last}${attempt < attempts ? '; trying again' : ''}`);
    await stop();
  }
  process.removeListener('exit', onExit);
  throw new Error(last);
}
