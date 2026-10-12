// Captures a worst-case clip from a web page, one PNG per sim tick, for tools/flash/analyse-frames.js. Node 24 built-ins only; drives headless Chrome (or Edge) over the
// DevTools protocol, with a fresh temporary profile that is always deleted.
//
//   node tools/flash/capture-web.mjs --dir <built site dir> --path /play/ --scenario mash --ticks 1800 --out <folder> [--reduced] [--width 960 --height 540]
//   node tools/flash/capture-web.mjs --url <page url> --scenario mash ...        a page that is already served
//   node tools/flash/capture-web.mjs --mock --scenario strobe4 --out <folder>    the self-test page (tools/flash/mock-page/), which flashes on purpose
//
// THE CONTRACT (what a page must offer so a clip is exactly one tick a frame; the build does not offer it yet, docs/tools/flash-check.md):
//   (the game's hook, Rendering's, is offered at /play/?flashcap=1 and also gives in_window, the register's count after each step, and error; both are recorded)
//   window.__flashcap = {
//     ready:  true once the scene is built and the first frame is up,
//     start:  (scenario, { reduced }) => void   sets the scene up as tools/flash/flash_worst.gd does and PAUSES the sim,
//     step:   () => Promise<number>             runs exactly one sim tick, draws it, and resolves with the tick once that frame is on screen,
//     tick:   number                            the sim tick now shown,
//   }
// The driver calls start(), then for each of `ticks` ticks step() followed by Page.captureScreenshot, so no frame is skipped or doubled whatever the machine's speed.
// Output: <out>/frame-000001.png ... and <out>/clip.json ({ scenario, reduced, fps: 60, ticks, width, height, page }).
import { spawn, spawnSync } from 'node:child_process';
import { createServer } from 'node:http';
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, statSync, writeFileSync } from 'node:fs';
import { tmpdir, platform } from 'node:os';
import { join, extname, resolve, sep, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const argv = process.argv.slice(2);
const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
const has = (n) => argv.includes(n);
const usage = () => {
  console.error('usage: node tools/flash/capture-web.mjs (--dir <site dir> [--path /play/] | --url <page url> | --mock) --scenario <id> --out <folder>\n' +
    '       [--ticks 1800] [--reduced] [--seed N] [--slots A,B] [--skip N] [--width 960] [--height 540] [--software] [--browser chrome|edge] [--browser-path <exe>] [--timeout 900]');
  process.exit(2);
};
const known = new Set(['--dir', '--path', '--url', '--mock', '--scenario', '--out', '--ticks', '--reduced', '--seed', '--slots', '--skip', '--width', '--height', '--software', '--budget', '--browser', '--browser-path', '--timeout']);
for (const a of argv) if (a.startsWith('--') && !known.has(a)) { console.error(`unknown option ${a}`); usage(); }
const here = dirname(fileURLToPath(import.meta.url));
const DIR = has('--mock') ? join(here, 'mock-page') : opt('--dir');
const URL_ = opt('--url');
const SCENARIO = opt('--scenario');
const OUT = opt('--out');
if (!SCENARIO || !OUT || (!DIR && !URL_) || (DIR && URL_)) usage();
const TICKS = Number(opt('--ticks', 1800));
const WIDTH = Number(opt('--width', 960)), HEIGHT = Number(opt('--height', 540));
const REDUCED = has('--reduced');
const SEED = opt('--seed') === undefined ? null : Number(opt('--seed'));
const SLOTS = opt('--slots') ? opt('--slots').split(',') : null;      // a pairing: two roster ids (the hook may not offer it yet)
const SKIP = opt('--skip') === undefined ? null : Number(opt('--skip'));   // ticks to run without drawing before the clip starts (the hook may not offer it yet)
const TIMEOUT_S = Number(opt('--timeout', 900));
const BROWSER = opt('--browser', 'chrome');
const EXES = {
  win32: { chrome: ['C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe', 'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe'], edge: ['C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe', 'C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe'] },
  darwin: { chrome: ['/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'], edge: ['/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge'] },
  linux: { chrome: ['/usr/bin/google-chrome', '/usr/bin/chromium', '/usr/bin/chromium-browser'], edge: ['/usr/bin/microsoft-edge'] },
};
const exe = opt('--browser-path') || ((EXES[platform()] || EXES.linux)[BROWSER] || []).find((p) => existsSync(p));
if (!exe) { console.error(`no ${BROWSER} executable found; pass --browser-path`); process.exit(2); }
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const log = (m) => console.log(`[capture-web] ${m}`);

const MIME = { '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript', '.wasm': 'application/wasm', '.png': 'image/png', '.json': 'application/json', '.pck': 'application/octet-stream' };
function serve(root) {
  const base = resolve(root);
  const server = createServer((req, res) => {
    let p = decodeURIComponent(new URL(req.url, 'http://x').pathname);
    if (p.endsWith('/')) p += 'index.html';
    const file = resolve(join(base, p));
    if (!(file === base || file.startsWith(base + sep)) || !existsSync(file) || !statSync(file).isFile()) { res.writeHead(404); res.end('not found'); return; }
    res.writeHead(200, { 'content-type': MIME[extname(file)] || 'application/octet-stream' });
    res.end(readFileSync(file));
  });
  return new Promise((ok) => server.listen(0, '127.0.0.1', () => ok(server)));
}

class Cdp {
  constructor(ws) {
    this.ws = ws; this.id = 0; this.pending = new Map();
    ws.addEventListener('message', (e) => {
      const m = JSON.parse(e.data);
      if (m.id && this.pending.has(m.id)) { const { ok, fail } = this.pending.get(m.id); this.pending.delete(m.id); if (m.error) fail(new Error(m.error.message)); else ok(m.result); }
    });
  }
  static open(url) { return new Promise((ok, fail) => { const ws = new WebSocket(url); ws.addEventListener('open', () => ok(new Cdp(ws))); ws.addEventListener('error', () => fail(new Error('DevTools socket error'))); }); }
  send(method, params = {}) { const id = ++this.id; return new Promise((ok, fail) => { this.pending.set(id, { ok, fail }); this.ws.send(JSON.stringify({ id, method, params })); }); }
  async eval(expression, awaitPromise = false) {
    const r = await this.send('Runtime.evaluate', { expression, returnByValue: true, awaitPromise });
    if (r.exceptionDetails) throw new Error(`page error: ${r.exceptionDetails.exception?.description || r.exceptionDetails.text}`);
    return r.result ? r.result.value : undefined;
  }
  close() { try { this.ws.close(); } catch { /* gone */ } }
}

let server;
let pageUrl = URL_;
if (DIR) {
  server = await serve(DIR);
  pageUrl = `http://127.0.0.1:${server.address().port}${has('--mock') ? '/' : opt('--path', '/play/')}`;
}
// Camera's travel budget (SplitRig.travel_budget, off by default): the page's `budget=1` switches it on for the hook (render/tools/flash_capture.gd), so a run with and without it is the same sim
if (has('--budget') && !has('--mock')) pageUrl += (pageUrl.includes('?') ? '&' : '?') + 'budget=1';
mkdirSync(OUT, { recursive: true });
// The browser is started by launchBrowser(): a cold machine (a fresh CI runner, a first launch after an update) can take far longer than a warm one to open its DevTools port, and
// a launch can simply fail, so it waits up to 90 s for the port and, on a failure or an early exit, kills that browser, clears its profile and tries again (3 attempts in all).
const baseFlags = ['--remote-debugging-port=0', '--headless=new', '--no-first-run', '--no-default-browser-check', '--disable-extensions', '--disable-sync', '--disable-component-update',
  '--hide-scrollbars', '--mute-audio', ...(process.env.CI ? ['--no-sandbox'] : []), `--window-size=${WIDTH},${HEIGHT}`, ...(has('--software') ? ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] : []), 'about:blank'];
const PORT_WAIT_MS = 90000, LAUNCH_ATTEMPTS = 3;
let child = null, profile = null, browserPort = null;
/** Closes the browser this run started: through DevTools (Browser.close), then by process (the launcher exe of a recent Chrome on Windows exits at once and the browser runs on under another PID, so a PID kill is not enough: it is found by its profile folder). */
async function killBrowser() {
  if (browserPort) {
    try {
      const v = await (await fetch(`http://127.0.0.1:${browserPort}/json/version`)).json();
      const c = await Cdp.open(v.webSocketDebuggerUrl);
      await Promise.race([c.send('Browser.close'), sleep(3000)]);
      c.close();
    } catch { /* gone, or never up */ }
  }
  browserPort = null;
  try {
    if (platform() === 'win32') {
      if (profile) spawnSync('powershell', ['-NoProfile', '-Command', `Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -like '*${profile.replace(/'/g, "''")}*' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }`], { stdio: 'ignore', timeout: 30000 });
      if (child) spawnSync('taskkill', ['/PID', String(child.pid), '/T', '/F'], { stdio: 'ignore', timeout: 15000 });
    } else if (child) child.kill('SIGKILL');
  } catch { /* gone */ }
  child = null;
  if (profile) for (let i = 0; i < 8; i++) { try { rmSync(profile, { recursive: true, force: true }); break; } catch { await sleep(400); } }
  profile = null;
}
async function launchBrowser() {
  let lastError = 'no attempt';
  for (let attempt = 1; attempt <= LAUNCH_ATTEMPTS; attempt++) {
    profile = mkdtempSync(join(tmpdir(), 'flash-cap-'));
    let failed = null;
    child = spawn(exe, [`--user-data-dir=${profile}`, ...baseFlags], { stdio: 'ignore', detached: false });
    // an exit with code 0 is the launcher handing over (a recent Chrome on Windows); any other exit before the port is a failed start
    child.on('exit', (code, sig) => { if (code !== 0 && code !== null) failed = `the browser exited with code ${code}`; else if (sig) failed = `the browser was killed by ${sig}`; });
    child.on('error', (e) => { failed = e.message; });
    const t0 = Date.now();
    let port;
    while (!port && !failed && Date.now() - t0 < PORT_WAIT_MS) {
      const f = join(profile, 'DevToolsActivePort');
      // the browser may still hold the file open as it writes it (Windows: EBUSY, 2026-10-11): that is "not yet", the next poll reads it
      if (existsSync(f)) { try { const n = Number(readFileSync(f, 'utf8').split('\n')[0]); if (n > 0) port = n; } catch { /* locked while it is written */ } }
      if (!port) await sleep(200);
    }
    if (port) {
      let target;
      const t1 = Date.now();
      while (!target && Date.now() - t1 < 30000) {
        try { target = (await (await fetch(`http://127.0.0.1:${port}/json/list`)).json()).find((x) => x.type === 'page'); } catch { /* not up yet */ }
        if (!target) await sleep(200);
      }
      if (target) { browserPort = port; return target; }
      browserPort = port;
      lastError = 'the browser opened its DevTools port but offered no page target in 30 s';
    } else lastError = failed || `the browser did not open a DevTools port in ${PORT_WAIT_MS / 1000} s`;
    log(`browser launch attempt ${attempt} of ${LAUNCH_ATTEMPTS} failed: ${lastError}${attempt < LAUNCH_ATTEMPTS ? '; trying again' : ''}`);
    await killBrowser();
  }
  throw new Error(lastError);
}
const cleanup = async () => {
  await killBrowser();
  if (server) server.close();
};
let page, code = 0;
try {
  const target = await launchBrowser();
  page = await Cdp.open(target.webSocketDebuggerUrl);
  await page.send('Emulation.setDeviceMetricsOverride', { width: WIDTH, height: HEIGHT, deviceScaleFactor: 1, mobile: false });
  await page.send('Page.navigate', { url: pageUrl });
  const deadline = Date.now() + TIMEOUT_S * 1000;
  let ready = false;
  while (Date.now() < deadline && !ready) { await sleep(500); ready = await page.eval('Boolean(window.__flashcap && window.__flashcap.ready)').catch(() => false); }
  if (!ready) throw new Error(`the page offers no window.__flashcap that becomes ready (the contract is at the top of tools/flash/capture-web.mjs); the build does not have it yet`);
  await page.eval(`window.__flashcap.start(${JSON.stringify(SCENARIO)}, { reduced: ${REDUCED}${SEED === null ? '' : ', seed: ' + SEED}${SLOTS ? ', slots: ' + JSON.stringify(SLOTS) : ''}${SKIP === null ? '' : ', skip: ' + SKIP} })`);
  log(`${pageUrl}: ${SCENARIO}${REDUCED ? ' (reduced)' : ''}, ${TICKS} ticks at ${WIDTH}x${HEIGHT}`);
  let last = -1;
  const tStart = Date.now();
  const inWindow = [];
  for (let i = 1; i <= TICKS; i++) {
    if (Date.now() > deadline) throw new Error(`timed out after ${i - 1} ticks`);
    const got = await page.eval('window.__flashcap.step().then((t) => ({ tick: t, win: window.__flashcap.in_window, err: window.__flashcap.error || null }))', true);
    const tick = got && got.tick;
    if (got && got.err) throw new Error(`the page reported an error: ${got.err}`);
    inWindow.push(got && typeof got.win === 'number' ? got.win : null);
    if (typeof tick !== 'number' || tick <= last) throw new Error(`step() returned ${tick} after ${last}: the page did not advance exactly one tick`);
    last = tick;
    const shot = await page.send('Page.captureScreenshot', { format: 'png', fromSurface: true });
    writeFileSync(join(OUT, `frame-${String(i).padStart(6, '0')}.png`), Buffer.from(shot.data, 'base64'));
  }
  writeFileSync(join(OUT, 'clip.json'), JSON.stringify({ scenario: SCENARIO, seed: SEED, reduced: REDUCED, fps: 60, inWindow, ticks: TICKS, width: WIDTH, height: HEIGHT, budget: has('--budget'), page: pageUrl }, null, 2) + '\n');
  log(`${TICKS} frames in ${Math.round((Date.now() - tStart) / 1000)} s of capture (${(TICKS / Math.max(1, (Date.now() - tStart) / 1000)).toFixed(2)} frames a second${has('--software') ? ', software rendering' : ''})`);
  log(`wrote ${TICKS} frames to ${OUT}; next: node tools/flash/analyse-frames.js ${OUT}`);
} catch (e) {
  console.error(`[capture-web] FAILED: ${e.message}`);
  code = 1;
} finally {
  if (page) page.close();
  await cleanup();
}
process.exit(code);
