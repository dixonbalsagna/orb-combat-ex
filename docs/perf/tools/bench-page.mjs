#!/usr/bin/env node
// The game's own bench on the web build, in Tools' guarded launcher, with the choice of GPU (tools/bench-web.mjs has none): the /bench/ page of a built site (tools/build-site.mjs) runs the AI match
// seed 4 at a fixed 60 fps and prints frame-time stats at the end (window.__benchResult), the same run as the desktop build's `-- --seed=4 --frames=N --bench`. Node 24 built-ins only. Owner: Performance and Platform.
//   node docs/perf/tools/bench-page.mjs --site <built site> --label x --out run.json [--frames 2400] [--throttle 1] [--igpu] [--width 1280 --height 720] [--timeout 600]
// Below-normal priority, no CPU cap (a bench measures the machine), a real window (the GPU path is what is timed; the launcher places it at 0,0), one browser at a time, gone when this ends.
import { writeFileSync } from 'node:fs';
import { Cdp, launchBrowser, serve, browserExe } from '../../../tools/machine/browser.mjs';
const argv = process.argv.slice(2);
const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
const SITE = opt('--site'), LABEL = opt('--label', 'run'), OUT = opt('--out');
const FRAMES = Number(opt('--frames', 2400)), THROTTLE = Number(opt('--throttle', 1)), IGPU = argv.includes('--igpu');
const W = Number(opt('--width', 1280)), H = Number(opt('--height', 720)), TIMEOUT = Number(opt('--timeout', 600));
if (!SITE || !OUT) { console.error('usage: node docs/perf/tools/bench-page.mjs --site <built site> --out run.json [--label x] [--frames 2400] [--throttle 1] [--igpu]'); process.exit(2); }
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const exe = browserExe('chrome');
const server = await serve(SITE);
const PAGE = opt('--page', '/bench/index.html');   // a page that starts the game with `-- --seed=4 --frames=N --bench` (the site's /bench/, or an export's index.html with those arguments)
const url = `http://127.0.0.1:${server.address().port}${PAGE}?frames=${FRAMES}`;
let b, page; const result = { label: LABEL, throttle: THROTTLE, igpu: IGPU, frames: FRAMES, size: `${W}x${H}` };
try {
  b = await launchBrowser({
    exe, session: process.env.MERIDIAN_SESSION || 'meridian-performance-platform', purpose: 'bench', timeoutS: TIMEOUT + 120, log: () => {}, cpuPercent: 0, priority: 'belownormal', headless: false,
    flags: ['--disable-gpu-vsync', '--disable-frame-rate-limit', '--disable-background-timer-throttling', '--disable-renderer-backgrounding', '--disable-backgrounding-occluded-windows', `--window-size=${W + 20},${H + 140}`, '--window-position=0,0', ...(IGPU ? ['--force_low_power_gpu'] : [])],
  });
  page = await Cdp.open(b.target.webSocketDebuggerUrl);
  await page.send('Emulation.setDeviceMetricsOverride', { width: W, height: H, deviceScaleFactor: 1, mobile: false });
  if (THROTTLE !== 1) await page.send('Emulation.setCPUThrottlingRate', { rate: THROTTLE });
  await page.send('Page.navigate', { url });
  const deadline = Date.now() + TIMEOUT * 1000;
  while (Date.now() < deadline) {
    await sleep(1000);
    const s = await page.eval('JSON.stringify(window.__benchResult || null)').catch(() => null);
    if (s && s !== 'null') { result.bench = JSON.parse(s); break; }
  }
  result.gpu = await page.eval(`(() => { try { const gl = document.createElement('canvas').getContext('webgl2'); const e = gl && gl.getExtension('WEBGL_debug_renderer_info'); return e ? gl.getParameter(e.UNMASKED_RENDERER_WEBGL) : 'unavailable'; } catch (e) { return 'unavailable'; } })()`).catch(() => 'unavailable');
  if (!result.bench) result.error = `no result within ${TIMEOUT} s`;
  if (IGPU && !/AMD|Radeon/i.test(result.gpu)) result.error = 'asked for the integrated GPU, the page reports ' + result.gpu;
} finally {
  try { page && page.close(); } catch { /* gone */ }
  if (b) await b.close();
  server.close();
}
writeFileSync(OUT, JSON.stringify(result, null, 1));
console.log(`${LABEL}: ${result.error || 'ok'} | ${result.gpu} | ${result.bench ? result.bench.head : ''}`);
process.exit(result.error ? 1 : 0);
