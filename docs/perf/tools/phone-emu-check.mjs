#!/usr/bin/env node
// Phone-shaped checks of the web build in HEADLESS Chrome's device emulation. Node built-ins only. Opens no Godot window.
//
//   node docs/perf/tools/phone-emu-check.mjs --site <built site dir> [--shots <dir>] [--only iphone-portrait,android-landscape,...]
//
// <built site dir> is the output of tools/build-site.mjs (it holds /play/). Each scenario gets a fresh browser profile, an emulated phone screen
// (size, pixel ratio, touch, user agent), loads /play/ from a local static server, waits for the game to boot, and records:
//   - the page's phone state (window.__ocx: touch, phone, portrait, size, standalone)
//   - whether the canvas fills the visible area, and whether the page can scroll
//   - the manifest as Chrome parsed it, and Chrome's installability errors
//   - the full-screen call from a (simulated) tap: result, fullscreen element, orientation lock outcome
//   - a screenshot (the first screen must be the flashing-effects notice: look at the picture)
// WHAT THIS DOES NOT PROVE: an emulated phone is a desktop Chrome with a phone-sized window. It has no Safari, no notch, no browser bars, no
// Home Screen install and no system gestures. The "iphone" scenarios REMOVE the Fullscreen API before the page loads, to mimic iPhone Safari
// (caniuse: iPad only). Real phones decide everything listed under "real phone only" in docs/perf/phone-web-fullscreen.md.
import { spawn, spawnSync } from 'node:child_process';
import { createServer } from 'node:http';
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, statSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { extname, join, resolve, sep } from 'node:path';
import { platform } from 'node:process';

const args = process.argv.slice(2);
const opt = (n, d) => { const i = args.indexOf(n); return i >= 0 ? args[i + 1] : d; };
const site = opt('--site');
if (!site || !existsSync(join(resolve(site), 'play', 'index.html'))) { console.error('usage: node docs/perf/tools/phone-emu-check.mjs --site <built site dir> [--shots <dir>] [--only a,b]'); process.exit(2); }
const shots = opt('--shots');
if (shots) mkdirSync(shots, { recursive: true });
const only = opt('--only') ? opt('--only').split(',') : null;
const TIMEOUT_S = Number(opt('--timeout', '120'));

const EXES = { win32: ['C:/Program Files/Google/Chrome/Application/chrome.exe', 'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe'], darwin: ['/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'], linux: ['/usr/bin/google-chrome', '/usr/bin/chromium'] };
const exe = opt('--browser-path') || (EXES[platform] || EXES.linux).find((p) => existsSync(p));
if (!exe) { console.error('no Chrome or Edge found; pass --browser-path'); process.exit(2); }

const UA_IPHONE = 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1';
const UA_ANDROID = 'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Mobile Safari/537.36';
const SCENARIOS = [
  { name: 'iphone-portrait', w: 390, h: 844, dpr: 3, mobile: true, ua: UA_IPHONE, noFullscreenApi: true },
  { name: 'iphone-landscape-bars', w: 664, h: 270, dpr: 3, mobile: true, ua: UA_IPHONE, noFullscreenApi: true, note: 'about the visible size in the friend\'s screenshot (roughly 600 by 280)' },
  { name: 'iphone-landscape-full', w: 844, h: 390, dpr: 3, mobile: true, ua: UA_IPHONE, noFullscreenApi: true, note: 'home-screen app size (no browser bars), notch ignored' },
  { name: 'android-landscape', w: 915, h: 412, dpr: 2.625, mobile: true, ua: UA_ANDROID },
  { name: 'desktop', w: 1280, h: 720, dpr: 1, mobile: false, ua: null },
];

// --size 750x330 adds one extra iPhone-landscape scenario of that visible size (Safari with its bars, a small phone, ...)
if (opt('--size')) { const [w, h] = opt('--size').split('x').map(Number); SCENARIOS.push({ name: `iphone-${w}x${h}`, w, h, dpr: 3, mobile: true, ua: UA_IPHONE, noFullscreenApi: true }); }
const MIME = { '.html': 'text/html', '.js': 'text/javascript', '.wasm': 'application/wasm', '.png': 'image/png', '.json': 'application/json', '.webmanifest': 'application/manifest+json', '.pck': 'application/octet-stream' };
function serve(root) {
  const base = resolve(root);
  const server = createServer((req, res) => {
    let p = decodeURIComponent(new URL(req.url, 'http://x').pathname);
    if (p === '/__probe.html') {
      // a bare page holding only the phone block of the real page's head, to test calls made without a tap (no Godot needed)
      const html = readFileSync(join(base, 'play', 'index.html'), 'utf8');
      const a = html.indexOf('<!--ocx:begin-->'), b = html.indexOf('<!--ocx:end-->');
      res.writeHead(200, { 'content-type': 'text/html' });
      res.end('<!doctype html><html><head>' + (a >= 0 && b > a ? html.slice(a, b) : '') + '</head><body><canvas id="canvas" width="300" height="150"></canvas></body></html>');
      return;
    }
    if (p.endsWith('/')) p += 'index.html';
    const file = resolve(join(base, p));
    if (!(file === base || file.startsWith(base + sep)) || !existsSync(file) || !statSync(file).isFile()) { res.writeHead(404); res.end('not found'); return; }
    res.writeHead(200, { 'content-type': MIME[extname(file)] || 'application/octet-stream' });
    res.end(readFileSync(file));
  });
  return new Promise((ok) => server.listen(0, '127.0.0.1', () => ok(server)));
}

class Cdp {
  constructor(ws) { this.ws = ws; this.id = 0; this.pending = new Map(); ws.addEventListener('message', (e) => { const m = JSON.parse(e.data); if (m.id && this.pending.has(m.id)) { const { ok, fail } = this.pending.get(m.id); this.pending.delete(m.id); if (m.error) fail(new Error(m.error.message)); else ok(m.result); } }); }
  static open(url) { return new Promise((ok, fail) => { const ws = new WebSocket(url); ws.addEventListener('open', () => ok(new Cdp(ws))); ws.addEventListener('error', () => fail(new Error('DevTools socket error'))); }); }
  send(method, params = {}) { const id = ++this.id; return new Promise((ok, fail) => { this.pending.set(id, { ok, fail }); this.ws.send(JSON.stringify({ id, method, params })); }); }
  async eval(expression, gesture = false) { const r = await this.send('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true, userGesture: gesture }); if (r.exceptionDetails) throw new Error(r.exceptionDetails.text + ' ' + JSON.stringify(r.exceptionDetails.exception && r.exceptionDetails.exception.description)); return r.result ? r.result.value : undefined; }
  close() { try { this.ws.close(); } catch { /* closed */ } }
}
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function runScenario(sc, origin) {
  const profile = mkdtempSync(join(tmpdir(), 'phone-emu-'));
  const flags = [`--user-data-dir=${profile}`, '--remote-debugging-port=0', '--headless=new', '--no-first-run', '--no-default-browser-check', '--disable-extensions', '--disable-sync', '--disable-component-update', '--autoplay-policy=no-user-gesture-required', `--window-size=${sc.w},${sc.h}`, 'about:blank'];
  const child = spawn(exe, flags, { stdio: 'ignore' });
  const cleanup = () => {
    try { if (platform === 'win32') spawnSync('taskkill', ['/PID', String(child.pid), '/T', '/F'], { stdio: 'ignore', timeout: 15000 }); else child.kill('SIGKILL'); } catch { /* gone */ }
    for (let i = 0; i < 5; i++) { try { rmSync(profile, { recursive: true, force: true }); break; } catch { spawnSync(process.execPath, ['-e', 'setTimeout(()=>{},400)']); } }
  };
  const out = { name: sc.name, viewport: `${sc.w}x${sc.h} @${sc.dpr}`, note: sc.note || '' };
  let page;
  try {
    const portFile = join(profile, 'DevToolsActivePort');
    let port; for (let i = 0; i < 100 && !port; i++) { if (existsSync(portFile)) port = Number(readFileSync(portFile, 'utf8').split('\n')[0]); else await sleep(200); }
    if (!port) throw new Error('no DevTools port');
    let target; for (let i = 0; i < 50 && !target; i++) { try { target = (await (await fetch(`http://127.0.0.1:${port}/json/list`)).json()).find((t) => t.type === 'page'); } catch { /* wait */ } if (!target) await sleep(200); }
    page = await Cdp.open(target.webSocketDebuggerUrl);
    await page.send('Page.enable');
    await page.send('Emulation.setDeviceMetricsOverride', { width: sc.w, height: sc.h, deviceScaleFactor: sc.dpr, mobile: sc.mobile, screenWidth: sc.w, screenHeight: sc.h, screenOrientation: { type: sc.w > sc.h ? 'landscapePrimary' : 'portraitPrimary', angle: sc.w > sc.h ? 90 : 0 } });
    if (sc.mobile) await page.send('Emulation.setTouchEmulationEnabled', { enabled: true, maxTouchPoints: 5 });
    if (sc.ua) await page.send('Emulation.setUserAgentOverride', { userAgent: sc.ua });
    if (sc.noFullscreenApi) {
      // iPhone Safari has no element Fullscreen API (caniuse, read 2026-10-06): mimic that before any page script runs.
      await page.send('Page.addScriptToEvaluateOnNewDocument', { source: 'try{delete Element.prototype.requestFullscreen;Object.defineProperty(Document.prototype,"fullscreenEnabled",{get:function(){return false}});}catch(e){}' });
    }
    await page.send('Page.navigate', { url: `${origin}/play/index.html` });
    // wait for the engine to finish booting: the page removes #status when the game is running
    const deadline = Date.now() + TIMEOUT_S * 1000;
    let booted = false;
    while (Date.now() < deadline) { await sleep(1000); const s = await page.eval(`!!window.__ocx && !document.getElementById('status') && !!document.getElementById('canvas') && document.getElementById('canvas').width > 100`).catch(() => false); if (s) { booted = true; break; } }
    out.booted = booted;
    await sleep(2500); // let the first frames and the notice draw
    out.ocx = await page.eval(`(() => { const o = window.__ocx; return o ? { v: o.v, touch: o.touch, phone: o.phone, portrait: o.portrait, w: o.w, h: o.h, standalone: o.standalone, canFullscreen: o.canFullscreen, fs: o.fs } : null; })()`);
    out.layout = await page.eval(`(() => { const c = document.getElementById('canvas'); const r = c.getBoundingClientRect(); const b = getComputedStyle(document.body); const h = getComputedStyle(document.documentElement); return { inner: [innerWidth, innerHeight], canvasCss: [Math.round(r.width), Math.round(r.height)], canvasPx: [c.width, c.height], scroll: [document.documentElement.scrollWidth, document.documentElement.scrollHeight], bodyPosition: b.position, touchAction: [h.touchAction, b.touchAction, getComputedStyle(c).touchAction], viewportScale: window.visualViewport ? window.visualViewport.scale : null }; })()`);
    out.fillsViewport = !!out.layout && Math.abs(out.layout.canvasCss[0] - out.layout.inner[0]) <= 1 && Math.abs(out.layout.canvasCss[1] - out.layout.inner[1]) <= 1;
    out.noScroll = !!out.layout && out.layout.scroll[0] <= out.layout.inner[0] && out.layout.scroll[1] <= out.layout.inner[1];
    // manifest as Chrome sees it
    try {
      const m = await page.send('Page.getAppManifest', {});
      let parsed = null; try { parsed = JSON.parse(m.data || 'null'); } catch { /* not json */ }
      out.manifest = { url: m.url, errors: (m.errors || []).map((e) => e.message), display: parsed && parsed.display, orientation: parsed && parsed.orientation, start_url: parsed && parsed.start_url, icons: parsed && parsed.icons && parsed.icons.map((i) => i.src + ' ' + i.sizes) };
    } catch (e) { out.manifest = { error: String(e.message) }; }
    try { const ie = await page.send('Page.getInstallabilityErrors', {}); out.installabilityErrors = (ie.installabilityErrors || []).map((e) => e.errorId); } catch (e) { out.installabilityErrors = 'not available: ' + e.message; }
    // the first screen
    if (shots) { const s = await page.send('Page.captureScreenshot', { format: 'png' }); writeFileSync(join(shots, `${sc.name}-first-screen.png`), Buffer.from(s.data, 'base64')); }
    // full screen from a (simulated) tap: Runtime.evaluate with userGesture stands in for the tap on the notice's button
    const r1 = await page.eval(`(() => { const o = window.__ocx; const ret = o.enterFullscreen(); return ret; })()`, true);
    await sleep(1500);
    out.fullscreenCall = await page.eval(`(() => { const o = window.__ocx; return { returned: ${JSON.stringify(r1)}, fs: o.fs, fullscreenElement: document.fullscreenElement ? document.fullscreenElement.id || document.fullscreenElement.tagName : null, locked: o.locked, orientationType: screen.orientation && screen.orientation.type }; })()`);
    out.afterFullscreen = await page.eval(`(() => { const c = document.getElementById('canvas'); const r = c.getBoundingClientRect(); return { inner: [innerWidth, innerHeight], canvasCss: [Math.round(r.width), Math.round(r.height)], portraitFlag: window.__ocx.portrait }; })()`);
    // calls made without a tap, and the wake lock, on a bare page that holds only the phone block (a fresh page has no user activation)
    await page.send('Page.navigate', { url: `${origin}/__probe.html` });
    await sleep(800);
    out.withoutTap = await page.eval(`(() => { const o = window.__ocx; let threw = false; try { o.enterFullscreen(); } catch (e) { threw = true; } return new Promise((ok) => setTimeout(() => ok({ threw, fs: o.fs, fullscreenElement: !!document.fullscreenElement }), 800)); })()`, false);
    out.wakeLock = await page.eval(`(() => { const o = window.__ocx; o.keepAwake(); return new Promise((ok) => setTimeout(() => ok({ api: !!navigator.wakeLock, awake: o.awake }), 800)); })()`, true);
    return out;
  } catch (e) {
    out.error = String(e.message || e);
    return out;
  } finally {
    if (page) page.close();
    cleanup();
  }
}

const server = await serve(site);
const origin = `http://127.0.0.1:${server.address().port}`;
const results = [];
for (const sc of SCENARIOS) {
  if (only && !only.includes(sc.name)) continue;
  console.log(`[phone-emu] ${sc.name} ${sc.w}x${sc.h}`);
  results.push(await runScenario(sc, origin));
}
server.close();
console.log(JSON.stringify(results, null, 1));
process.exit(results.some((r) => r.error || r.booted === false) ? 1 : 0);
