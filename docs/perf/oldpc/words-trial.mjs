#!/usr/bin/env node
// What the game's page reads at a "local" address and at a non-local one (Performance and Platform). Nothing leaves this PC: the server runs on 127.0.0.1 and the browser's DNS maps a
// made-up name to 127.0.0.1, so http://oldpc.test:PORT/ is a non-local, insecure origin, exactly as http://10.0.0.135:PORT/ is. Tools' launcher (tools/machine/browser.mjs, the fix of d7935bf5
// for flags with spaces). Start the server first:
//     node docs/perf/oldpc/oldpc-server.mjs --site <build> --bind 127.0.0.1 --alias oldpc.test --port 8781 --go
//   node docs/perf/oldpc/words-trial.mjs --port 8781 [--alias oldpc.test] [--seconds 150]
import { Cdp, launchBrowser, browserExe } from '../../../tools/machine/browser.mjs';
const argv = process.argv.slice(2);
const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
const PORT = Number(opt('--port', 8781)), ALIAS = opt('--alias', 'oldpc.test'), SECONDS = Number(opt('--seconds', 150));
const QUERY = 'planet=7&preview=1&tiles=1&meteor=loud';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const click = async (page, x, y) => { await page.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x, y }); await page.send('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', clickCount: 1 }); await page.send('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', clickCount: 1 }); };
const ONLY = opt('--only', '');   // 'local' or 'alias'
const INJECT = `window.__errs = []; window.addEventListener('error', (e) => window.__errs.push(String(e.message).slice(0, 200))); window.addEventListener('unhandledrejection', (e) => window.__errs.push('rejection: ' + String(e.reason).slice(0, 200))); const ce = console.error; console.error = function () { window.__errs.push(Array.from(arguments).join(' ').slice(0, 300)); return ce.apply(console, arguments); }; const cw = console.warn; console.warn = function () { window.__errs.push('warn: ' + Array.from(arguments).join(' ').slice(0, 200)); return cw.apply(console, arguments); };`;
for (const origin of [`http://127.0.0.1:${PORT}`, `http://${ALIAS}:${PORT}`].filter((o) => !ONLY || (ONLY === 'local') === o.includes('127.0.0.1'))) {
  const t0 = Date.now(); const r = { origin };
  const b = await launchBrowser({ exe: browserExe('chrome'), session: process.env.MERIDIAN_SESSION || 'meridian-performance-platform', purpose: 'words-trial', timeoutS: SECONDS + 120, log: () => {}, cpuPercent: 0, priority: 'belownormal',
    flags: ['--window-size=1280,820', `--host-resolver-rules=MAP ${ALIAS} 127.0.0.1`] });
  const page = await Cdp.open(b.target.webSocketDebuggerUrl);
  try {
    await page.send('Page.enable'); await page.send('Emulation.setDeviceMetricsOverride', { width: 1280, height: 720, deviceScaleFactor: 1, mobile: false });
    await page.send('Page.addScriptToEvaluateOnNewDocument', { source: INJECT });
    await page.send('Page.navigate', { url: `${origin}/game/index.html?${QUERY}` });
    let probe = null, clicks = 0;
    while (Date.now() - t0 < SECONDS * 1000) {
      probe = await page.eval('window.__preview ? JSON.stringify(window.__preview) : null').then((v) => v && JSON.parse(v)).catch(() => null);
      if (probe && probe.tick > 90) break;
      if (probe && clicks < 8) { await click(page, 1099, 195); await sleep(900); await click(page, 640, 503); clicks++; }
      await sleep(1500);
    }
    r.seconds = Math.round((Date.now() - t0) / 100) / 10;
    r.facts = await page.eval('JSON.stringify({host: location.host, secure: window.isSecureContext, sw: "serviceWorker" in navigator, subtle: !!(window.crypto && crypto.subtle), gamepads: typeof navigator.getGamepads})').then(JSON.parse).catch(() => null);
    r.probe = probe && { tick: probe.tick, meteor: probe.meteor, planet: probe.planet, planetGen: probe.planetGen, swings: probe.swings };
    r.clicks = clicks;
    r.errs = await page.eval('JSON.stringify(window.__errs || []).slice(0, 1500)').then(JSON.parse).catch(() => null);
    r.state = await page.eval('JSON.stringify({canvas: !!document.querySelector("canvas"), status: (document.getElementById("status") || {}).style && document.getElementById("status").style.visibility, notice: (document.getElementById("status-notice") || {}).textContent, title: document.title})').then(JSON.parse).catch(() => null);
  } finally { try { page.close(); } catch { /* gone */ } await b.close().catch(() => {}); }
  console.log(JSON.stringify(r));
}
