#!/usr/bin/env node
// Per-frame cost inside a stretch of a recorded match, with the engine's own counters (Performance and Platform, 2026-11-01): the sim tick, the effects and camera, the view update, the render's CPU and GPU time.
// Needs a scratch web export with docs/perf/tools/scratch-hooks/hook-perf.mjs (window.__flashcap.perf each frame, and AUTO mode: one tick on every animation frame, as the game runs at 60 Hz, not two frames a step).
// The recorded match is played in auto mode from tick 0; for every animation frame the driver notes the hook's perf record and the tick; the stretch (--from to --to) is set against the frames before and after it.
//
//   node docs/perf/tools/preplay/perf-stretch.mjs --file <orb json> --dir <scratch web export> --from 1562 --to 1644 --out <result.json> [--query "planet=7&meteor=loud&tiles=1"]
// Real GPU, fresh profile, below-normal, a time limit; INVALID when the machine's CPU use is above 60% before or after.
import { readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { Cdp, launchBrowser, serve, browserExe, cpuLoad } from '../../../../tools/machine/browser.mjs';

const argv = process.argv.slice(2);
const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
const FILE = opt('--file'), DIR = opt('--dir'), OUT = opt('--out'), FROM = Number(opt('--from', 1562)), TO = Number(opt('--to', 1644));
const QUERY = opt('--query', 'planet=7&meteor=loud&tiles=1');
if (!FILE || !DIR) { console.error('usage: perf-stretch.mjs --file <orb json> --dir <web export with hook-perf> --from 1562 --to 1644 --out <result.json>'); process.exit(2); }
const rp = JSON.parse(readFileSync(FILE, 'utf8')).replay;
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const pct = (a, p) => { const s = [...a].sort((x, y) => x - y); return s.length ? s[Math.min(s.length - 1, Math.floor(s.length * p))] : NaN; };
const mean = (a) => a.length ? a.reduce((x, y) => x + y, 0) / a.length : NaN;
const server = await serve(resolve(DIR));
const url = `http://127.0.0.1:${server.address().port}/index.html?flashcap=1&preview=1&reel=1&replay=1&blackbox=off&${QUERY}`;
const result = { from: FROM, to: TO, when: new Date().toISOString() };
let browser = null, page = null, code = 0;
try {
  result.loadBefore = Math.round(await cpuLoad(3000));
  browser = await launchBrowser({ exe: browserExe('chrome'), flags: ['--window-size=1280,720'], session: process.env.MERIDIAN_SESSION || 'meridian-performance-platform', purpose: 'perfstretch', timeoutS: 600, cpuPercent: 0, priority: 'belownormal', log: () => {} });
  page = await Cdp.open(browser.target.webSocketDebuggerUrl);
  await page.send('Page.enable');
  await page.send('Emulation.setDeviceMetricsOverride', { width: 1280, height: 720, deviceScaleFactor: 1, mobile: false });
  await page.send('Page.addScriptToEvaluateOnNewDocument', { source: `window.__replay = ${JSON.stringify(JSON.stringify(rp))};` });
  await page.send('Page.navigate', { url });
  const dl = Date.now() + 300 * 1000;
  let ready = false;
  while (Date.now() < dl && !ready) { await sleep(500); ready = await page.eval('Boolean(window.__flashcap && window.__flashcap.ready)').catch(() => false); }
  if (!ready) throw new Error('the page offers no window.__flashcap that becomes ready');
  await page.eval(`window.__flashcap.start("ai", { reduced: false, seed: ${Number(rp.seed)} })`, true);
  const rec = JSON.parse(await page.eval(`(async () => {
    const fc = window.__flashcap, rows = [];
    fc.auto = true;
    let last = performance.now();
    const t0 = last;
    while (fc.tick < ${TO + 60} && performance.now() - t0 < 240000) {
      await new Promise((r) => requestAnimationFrame((t) => { const p = fc.perf || {}; rows.push([t - last, fc.tick, p.tick_ms, p.fx_ms, p.view_ms, p.rcpu, p.rgpu, p.draws, p.prims, p.frame_ms, p.pv || null]); last = t; r(); }));
    }
    fc.auto = false;
    return JSON.stringify(rows);
  })()`, true));
  const col = (i, a, b) => rec.filter((r) => r[1] >= a && r[1] <= b && typeof r[i] === 'number').map((r) => r[i]);
  const names = ['rAF ms', 'tick', 'tick ms', 'fx+camera ms', 'view update ms', 'render CPU ms', 'render GPU ms', 'draw calls', 'prims', 'frame ms'];
  result.segments = {};
  for (const [nm, a, b] of [['before', FROM - 60, FROM - 1], ['stretch', FROM, TO], ['after', TO + 1, TO + 60]]) {
    result.segments[nm] = {};
    for (const i of [0, 2, 3, 4, 5, 6, 7, 8, 9]) { const v = col(i, a, b); result.segments[nm][names[i]] = { mean: +mean(v).toFixed(2), p95: +pct(v, 0.95).toFixed(2), max: +Math.max(...v).toFixed(2) }; }
    result.segments[nm].frames = col(0, a, b).length;
    const pvs = rec.filter((r) => r[1] >= a && r[1] <= b && r[10]).map((r) => r[10]); const keys = new Set(); for (const o of pvs) for (const k of Object.keys(o)) keys.add(k);
    result.segments[nm].pv = {}; for (const k of keys) { const v = pvs.map((o) => Number(o[k] || 0)); result.segments[nm].pv[k] = +mean(v).toFixed(2); }
  }
  result.frames = rec.length;
} catch (e) { console.log(`[perf-stretch] FAILED: ${e.message}`); result.error = e.message; code = 1; }
finally { try { if (page) page.close(); } catch { /* gone */ } try { if (browser) await browser.close(); } catch { /* gone */ } server.close(); }
if (code === 0) { result.loadAfter = Math.round(await cpuLoad(3000)); result.valid = result.loadBefore <= 60 && result.loadAfter <= 60; }
if (OUT) writeFileSync(resolve(OUT), JSON.stringify(result, null, 1));
console.log(JSON.stringify(result));
process.exit(code);
