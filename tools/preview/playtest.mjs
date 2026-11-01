// The first minutes of the private page as a person meets them, on the REAL address (no capture hook, no probe words unless asked) with a scripted gamepad: what appears, what a button press does, and
// whether a pad takes player 1 by itself. The EP's order, 2026-11-01. A stills folder and a record, never published.
//
//   node tools/preview/playtest.mjs --url "http://127.0.0.1:8766/index.html?planet=7&meteor=loud&tiles=1" --out <folder> [--script steps.json] [--width 1280 --height 720] [--probe]
//
// A step is { "at": seconds since the last step, "do": "shot" | "press" | "release" | "stick" | "wait", "name": "label", "button": 0-15, "axes": [lx, ly, rx, ry] }; the default script just looks for 60 s,
// then presses A, then looks. --probe adds &preview=1 so window.__preview can be read (the tick, who is human): the address then differs from the real one by that word only.
import { mkdirSync, writeFileSync, readFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { Cdp, launchBrowser, browserExe, serve } from '../machine/browser.mjs';

const argv = process.argv.slice(2);
const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
const DIR = opt('--dir'), OUT = opt('--out');
const server = DIR ? await serve(resolve(DIR)) : null;   // --dir: a built page folder served here, the address is then given by its words only (--query)
const URL0 = DIR ? `http://127.0.0.1:${server.address().port}/index.html?${opt('--query', 'planet=7&meteor=loud&tiles=1')}` : opt('--url');
if (!URL0 || !OUT) { console.error('usage: node tools/preview/playtest.mjs --url <address> --out <folder> [--script steps.json] [--probe]'); process.exit(2); }
const W = Number(opt('--width', 1280)), H = Number(opt('--height', 720));
const URL = argv.includes('--probe') ? `${URL0}${URL0.includes('?') ? '&' : '?'}preview=1` : URL0;
const steps = opt('--script') ? JSON.parse(readFileSync(opt('--script'), 'utf8')) : [
  { at: 4, do: 'shot', name: 'load-4s' }, { at: 8, do: 'shot', name: 'load-12s' }, { at: 12, do: 'shot', name: 'load-24s' }, { at: 20, do: 'shot', name: 'load-44s' }, { at: 16, do: 'shot', name: 'load-60s' },
];
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const log = (m) => console.log(`[playtest] ${m}`);
const exe = process.env.PLAYTEST_EXE || browserExe('chrome');   // PLAYTEST_EXE: another Chromium (Opera GX, Edge), headless, to see whether the page behaves in the browser Orb's shortcut opens
mkdirSync(OUT, { recursive: true });

// a fake standard-mapping pad: window.__pad holds its state, navigator.getGamepads reads it, and gamepadconnected is fired by hand
const FAKE = `
(() => {
  const state = { connected: false, buttons: Array.from({ length: 17 }, () => ({ pressed: false, touched: false, value: 0 })), axes: [0, 0, 0, 0], ts: 0 };
  window.__pad = state;
  const pad = () => ({ id: 'Xbox 360 Controller (STANDARD GAMEPAD Vendor: 045e Product: 028e)', index: 0, connected: true, mapping: 'standard', timestamp: ++state.ts, buttons: state.buttons, axes: state.axes, vibrationActuator: null });
  navigator.getGamepads = () => (state.connected ? [pad(), null, null, null] : [null, null, null, null]);
  window.__padConnect = () => { state.connected = true; const ev = new Event('gamepadconnected'); ev.gamepad = pad(); window.dispatchEvent(ev); };
  window.__padSet = (btn, down) => { state.buttons[btn] = { pressed: !!down, touched: !!down, value: down ? 1 : 0 }; };
  window.__padAxes = (a) => { state.axes = a.slice(); };
})();`;

const BB_EVAL = `JSON.stringify({ state: window.__bb_state || null, replay: window.__bb_replay || null, last: (function () { try { return (localStorage.getItem('orb-blackbox-last') || '').length; } catch (e) { return -1; } })() })`;
const record = { url: URL, steps: [] };
let browser = null, page = null, code = 0;
try {
  browser = await launchBrowser({ exe, flags: [`--window-size=${W},${H}`], session: process.env.MERIDIAN_SESSION || 'tools-pipeline', purpose: 'playtest', timeoutS: 1500, cpuPercent: 25, log });
  page = await Cdp.open(browser.target.webSocketDebuggerUrl);
  await page.send('Emulation.setDeviceMetricsOverride', { width: W, height: H, deviceScaleFactor: 1, mobile: false });
  await page.send('Page.enable');
  await page.send('Runtime.enable');
  const consoleLines = [];
  page.ws.addEventListener('message', (ev) => { try { const m = JSON.parse(ev.data); if (m.method === 'Runtime.consoleAPICalled') consoleLines.push(m.params.type + ': ' + m.params.args.map((a) => a.value ?? a.description ?? '').join(' ').slice(0, 300)); } catch { /* not json */ } });
  record.consoleLines = consoleLines;
  await page.send('Page.addScriptToEvaluateOnNewDocument', { source: FAKE });
  await page.send('Page.navigate', { url: URL });
  log(`${URL} at ${W}x${H}; the pad is connected only when a step says so`);
  const t0 = Date.now();
  let n = 0;
  for (const s of steps) {
    await sleep((s.at || 0) * 1000);
    const secs = ((Date.now() - t0) / 1000).toFixed(1);
    if (s.do === 'connect') await page.eval('window.__padConnect()', true);
    else if (s.do === 'press') await page.eval(`window.__padSet(${s.button}, true)`, true);
    else if (s.do === 'release') await page.eval(`window.__padSet(${s.button}, false)`, true);
    else if (s.do === 'tap') { await page.eval(`window.__padSet(${s.button}, true)`, true); await sleep(250); await page.eval(`window.__padSet(${s.button}, false)`, true); }
    else if (s.do === 'click') { for (const type of ['mouseMoved', 'mousePressed', 'mouseReleased']) { await page.send('Input.dispatchMouseEvent', { type, x: s.x, y: s.y, button: 'left', buttons: type === 'mousePressed' ? 1 : 0, clickCount: 1 }); await sleep(80); } }
    else if (s.do === 'bb') { const r = await page.eval(BB_EVAL); const o = JSON.parse(r || '{}'); writeFileSync(join(OUT, 'blackbox-' + (s.name || 'grab') + '.json'), JSON.stringify({ kind: 'orb-first-play', state: o.state, localStorageBytes: o.last, replay: o.replay ? JSON.parse(o.replay) : null })); record.bb = { state: o.state, localStorageBytes: o.last, hasReplay: !!o.replay }; }
    else if (s.do === 'snap') { const r = await page.eval('JSON.stringify((function () { if (!window.__bbf_snap) return null; var o = window.__bbf_snap(); return { rsCount: o.rsCount, rsPad: o.rsPad, first: (o.rs || []).slice(0, 14), last: (o.rs || []).slice(-6), frames: o.n, over33: o.over33 }; })())'); writeFileSync(join(OUT, 'snap-' + (s.name || 'grab') + '.json'), r || 'null'); log('snap ' + String(r).slice(0, 500)); }
    else if (s.do === 'forceover') { await page.eval('window.__bb_state = Object.assign({}, window.__bb_state || {}, { over: true, at: Date.now() })', true); }
    else if (s.do === 'stick') await page.eval(`window.__padAxes(${JSON.stringify(s.axes)})`, true);
    else if (s.do === 'key') { await page.send('Input.dispatchKeyEvent', { type: 'keyDown', key: s.key, code: s.code || s.key, windowsVirtualKeyCode: s.vk || 0 }); await sleep(120); await page.send('Input.dispatchKeyEvent', { type: 'keyUp', key: s.key, code: s.code || s.key, windowsVirtualKeyCode: s.vk || 0 }); }
    let probe = null;
    if (argv.includes('--probe')) probe = await page.eval('window.__preview ? JSON.stringify({ tick: window.__preview.tick, hp: window.__preview.hp, p1human: window.__preview.p1human, swing: window.__preview.swing && window.__preview.swing.on, fst: window.__preview.fst }) : null').catch(() => null);
    let file = null;
    if (s.shot !== false) {
      const shot = await page.send('Page.captureScreenshot', { format: 'png', fromSurface: true });
      file = `${String(++n).padStart(2, '0')}-${s.name || s.do}.png`;
      writeFileSync(join(OUT, file), Buffer.from(shot.data, 'base64'));
    }
    record.steps.push({ at: Number(secs), do: s.do, name: s.name || null, button: s.button ?? null, file, probe });
    log(`${secs}s ${s.do}${s.button !== undefined ? ' ' + s.button : ''}${s.name ? ' (' + s.name + ')' : ''}${probe ? ' ' + probe : ''}`);
  }
} catch (e) { log(`FAILED: ${e.message}`); record.error = e.message; code = 1; }
finally { if (server) server.close(); writeFileSync(join(OUT, 'playtest.json'), JSON.stringify(record, null, 2)); try { if (page) page.close && page.close(); } catch { /* gone */ } try { if (browser) await browser.close(); } catch { /* gone */ } }
process.exit(code);
