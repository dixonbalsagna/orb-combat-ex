#!/usr/bin/env node
// Tries the kit's browser half on THIS PC with a headless Chrome from Tools' launcher (Performance and Platform, 2026-11-01): waits for RUN-TEST.cmd's loopback server, opens its page, clicks the page's
// Start, then the game's own flashing-effects notice and how-to card (only this trial clicks them; the real page never does), and waits for the page to say Done. Nothing leaves the PC.
//   set OLDPC_NO_OPEN=1 and start the kit:   cmd /c "<kit>\RUN-TEST.cmd"          (a second window of this session; the kit opens no browser of its own with that variable set)
//   node docs/perf/oldpc/kit/kit-trial.mjs [--port 8790] [--measure 20] [--seconds 420] [--games game,game2]
import { Cdp, launchBrowser, browserExe } from '../../../../tools/machine/browser.mjs';
const argv = process.argv.slice(2);
const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
const PORT = Number(opt('--port', 8790)), MEASURE = Number(opt('--measure', 20)), SECONDS = Number(opt('--seconds', 420));
const GAMES = opt('--games', '');   // a two-fights kit: --games game,game2 (the kit's own page address carries it)
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const click = async (page, x, y) => { await page.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x, y }); await page.send('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', clickCount: 1 }); await page.send('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', clickCount: 1 }); };
const t0 = Date.now();
for (;;) {   // the kit's first half (the sim, no window) runs before the server starts
  try { const r = await fetch(`http://127.0.0.1:${PORT}/oldpc/ping`); if (r.ok) break; } catch { /* not up yet */ }
  if (Date.now() - t0 > SECONDS * 1000) { console.log('the kit server never came up'); process.exit(1); }
  await sleep(2000);
}
console.log(`server up after ${Math.round((Date.now() - t0) / 1000)} s`);
const b = await launchBrowser({ exe: browserExe('chrome'), session: process.env.MERIDIAN_SESSION || 'meridian-performance-platform', purpose: 'kit-trial', timeoutS: SECONDS + 60, log: () => {}, cpuPercent: 0, priority: 'belownormal',
  flags: ['--window-size=1280,820'] });
const page = await Cdp.open(b.target.webSocketDebuggerUrl);
let out = {};
try {
  await page.send('Page.enable'); await page.send('Emulation.setDeviceMetricsOverride', { width: 1280, height: 720, deviceScaleFactor: 1, mobile: false });
  await page.send('Page.navigate', { url: `http://127.0.0.1:${PORT}/oldpc/?m=${MEASURE}${GAMES ? '&games=' + GAMES : ''}` });
  await sleep(2500);
  console.log('gate shown:', await page.eval('document.getElementById("panel").className'));
  await page.eval('document.getElementById("begin").click()');
  let clicks = 0, phase = '', msg = '';
  while (Date.now() - t0 < SECONDS * 1000) {
    const st = await page.eval('JSON.stringify({ phase: (window.__oldpc && window.__oldpc.steps ? window.__oldpc.steps.map(function (s) { return s[0]; }).slice(-1)[0] : ""), msg: document.getElementById("msg").textContent, h1: (document.querySelector("#panelBody h1") || {}).textContent || "" })').then(JSON.parse).catch(() => ({}));
    if (st.msg !== msg) { msg = st.msg; console.log(`${Math.round((Date.now() - t0) / 1000)} s  ${st.phase} | ${st.msg}`); }
    if (/^Done/.test(st.h1)) break;
    if (/Waiting for you to click|The game is up/.test(st.msg) && clicks < 10) { await click(page, 1099, 229); await sleep(900); await click(page, 640, 537); clicks++; }
    await sleep(2000);
  }
  out = await page.eval('JSON.stringify({ done: /^Done/.test((document.querySelector("#panelBody h1") || {}).textContent || ""), sent: (document.getElementById("sent") || {}).textContent || "", verdict: window.__oldpc && window.__oldpc.verdict, nsteps: window.__oldpc && window.__oldpc.steps.length })').then(JSON.parse).catch((e) => ({ err: String(e) }));
  out.clicks = clicks;
} finally { try { page.close(); } catch { /* gone */ } await b.close().catch(() => {}); }
console.log('trial:', JSON.stringify(out));
