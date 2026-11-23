// SCRATCH (Rendering): the terrain fragment's parts on the Radeon. For each ?tcut=<variant> (tcut_hook.py), load the gen 2
// coast (planet 7, Performance's pb scene), run it in the hook's auto mode to tick 60 (the wide opening) and to 500 (the
// settled shot), pause there and time 60 drawn frames (vsync off): p50 and p95 of the frame. Through Tools' launcher.
//   node tcut.mjs <repo> <site> <out.json> <variants,comma> [rounds]
import { pathToFileURL } from 'node:url';
import { join } from 'node:path';
import { writeFileSync } from 'node:fs';
const [repo, site, out, list, roundsS] = process.argv.slice(2);
const { Cdp, launchBrowser, serve, browserExe } = await import(pathToFileURL(join(repo, 'tools/machine/browser.mjs')).href);
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const pct = (a, p) => { const s = [...a].sort((x, y) => x - y); return +s[Math.min(s.length - 1, Math.max(0, Math.ceil(p * s.length) - 1))].toFixed(2); };
const server = await serve(site);
const port = server.address().port;
const variants = list.split(',');
const rounds = Number(roundsS || 1);
const res = { gpu: null, rows: [] };
let b = null;
try {
  b = await launchBrowser({ exe: browserExe('chrome'), session: 'rendering', purpose: 'tcut', timeoutS: 300 + variants.length * rounds * 150, log: () => {},
    flags: ['--window-size=1280,720', '--disable-gpu-vsync', '--disable-frame-rate-limit', '--disable-background-timer-throttling', '--disable-renderer-backgrounding', '--disable-backgrounding-occluded-windows', '--force_low_power_gpu'] });
  const page = await Cdp.open(b.target.webSocketDebuggerUrl);
  await page.send('Page.enable');
  await page.send('Emulation.setDeviceMetricsOverride', { width: 1280, height: 720, deviceScaleFactor: 1, mobile: false });
  for (let r = 0; r < rounds; r++) {
    for (const v of variants) {
      const url = `http://127.0.0.1:${port}/play/index.html?flashcap=1&nointro=1&pgen=2&pbiome=coast&pplanet=7&tcut=${v}`;
      await page.send('Page.navigate', { url });
      const t0 = Date.now();
      while (!(await page.eval('!!(window.__flashcap && window.__flashcap.ready)').catch(() => false))) { await sleep(500); if (Date.now() - t0 > 180000) throw new Error('never ready: ' + v); }
      if (!res.gpu) res.gpu = await page.eval(`(() => { try { const gl = document.createElement('canvas').getContext('webgl2'); const e = gl.getExtension('WEBGL_debug_renderer_info'); return gl.getParameter(e.UNMASKED_RENDERER_WEBGL); } catch (e) { return 'unavailable'; } })()`);
      await page.eval(`window.__flashcap.start('pb', {seed: 4, reduced: true})`);
      await sleep(1500);
      const row = { v, round: r, tcut: null };
      for (const tick of [60, 500]) {
        await page.eval(`(async () => { const fc = window.__flashcap; fc.auto = true; while (fc.tick < ${tick}) await new Promise((r) => requestAnimationFrame(r)); fc.auto = false; for (let i = 0; i < 20; i++) await new Promise((r) => requestAnimationFrame(r)); })()`, true);
        const rtt = JSON.parse(await page.eval(`(async () => { const a = []; let last = null; for (let i = 0; i < 61; i++) { const t = await new Promise((r) => requestAnimationFrame(r)); if (last !== null) a.push(t - last); last = t; } return JSON.stringify(a); })()`, true));
        row['t' + tick] = { p50: pct(rtt, 0.5), p95: pct(rtt, 0.95) };
      }
      row.tcut = await page.eval('window.__tcut || "none"');
      res.rows.push(row);
      console.log(v, 'round', r, 'shader', row.tcut, '| wide (tick 60) p50', row.t60.p50, 'p95', row.t60.p95, '| settled (500) p50', row.t500.p50, 'p95', row.t500.p95);
    }
  }
} catch (e) { console.log('error', String(e)); res.error = String(e); }
finally { if (b) await b.close().catch(() => {}); server.close(); writeFileSync(out, JSON.stringify(res, null, 1)); console.log('gpu', res.gpu); }
