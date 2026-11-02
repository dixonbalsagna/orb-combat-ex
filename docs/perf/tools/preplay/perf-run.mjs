#!/usr/bin/env node
// Per-frame counters for a WHOLE recorded match on the page (Performance and Platform, 2026-11-01): the engine's tick, effects, view-update and render times and the view-update timers of hook-viewtimers.mjs, one row per
// animation frame, from tick 0 to --until, in auto mode (one tick a frame). Scratch export with hook-perf.mjs and hook-viewtimers.mjs applied. One browser, one job; real GPU, fresh profile, below-normal; INVALID above 60% load.
//   node docs/perf/tools/preplay/perf-run.mjs --file <orb json> --dir <scratch web export> --until 24000 --out <rows.json> [--query "planet=7&meteor=loud&tiles=1"]
// rows: [rAF ms, tick, tick ms, fx ms, view ms, render CPU ms, draw calls, pane._tiles.apply, planet.update, vfx_layer.update, audio cues, hud, v.update]
import { readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { Cdp, launchBrowser, serve, browserExe, cpuLoad } from '../../../../tools/machine/browser.mjs';
const argv = process.argv.slice(2);
const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
const FILE = opt('--file'), DIR = opt('--dir'), OUT = opt('--out'), UNTIL = Number(opt('--until', 24000)), QUERY = opt('--query', 'planet=7&meteor=loud&tiles=1');
if (!FILE || !DIR || !OUT) { console.error('usage: perf-run.mjs --file <orb json> --dir <web export> --until 24000 --out <rows.json>'); process.exit(2); }
const rp = JSON.parse(readFileSync(FILE, 'utf8')).replay;
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const server = await serve(resolve(DIR));
const url = `http://127.0.0.1:${server.address().port}/index.html?flashcap=1&preview=1&reel=1&replay=1&blackbox=off&${QUERY}`;
const result = { until: UNTIL, when: new Date().toISOString() };
let browser = null, page = null, code = 0;
try {
  result.loadBefore = Math.round(await cpuLoad(3000));
  browser = await launchBrowser({ exe: browserExe('chrome'), flags: ['--window-size=1280,720'], session: process.env.MERIDIAN_SESSION || 'meridian-performance-platform', purpose: 'perfrun', timeoutS: 1500, cpuPercent: 0, priority: 'belownormal', log: () => {} });
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
  // the page keeps the rows; they are read in slices so no single call is huge
  await page.eval(`(() => { const fc = window.__flashcap; window.__rows = []; fc.auto = true; let last = performance.now(); const f = (t) => { const p = fc.perf || {}, pv = p.pv || {}; window.__rows.push([+(t - last).toFixed(2), fc.tick, p.tick_ms, p.fx_ms, p.view_ms, p.rcpu, p.draws, pv['pane._tiles.apply'] || 0, pv['pane.planet.update'] || 0, pv['pane.vfx_layer.update'] || 0, pv['m.audio'] || 0, pv['m.hud'] || 0, pv['pane.v.update'] || 0]); last = t; if (fc.tick < ${UNTIL}) requestAnimationFrame(f); else fc.auto = false; }; requestAnimationFrame(f); })()`, true);
  const t0 = Date.now();
  let stuck = 0;
  for (;;) { await sleep(5000); const tk = await page.eval('window.__flashcap.tick').catch(() => -1); if (tk >= UNTIL || Date.now() - t0 > 1300 * 1000) break; if (tk <= 0 && ++stuck > 12) throw new Error('the page never ran a tick in 60 s (it may have refused the replay: its data hash differs from this build: window.__pr = ' + (await page.eval('JSON.stringify(window.__pr || null)').catch(() => '?')) + ')'); }
  const rows = [];
  const n = await page.eval('window.__rows.length');
  for (let a = 0; a < n; a += 4000) rows.push(...JSON.parse(await page.eval(`JSON.stringify(window.__rows.slice(${a}, ${a + 4000}))`)));
  result.rows = rows;
} catch (e) { console.log(`[perf-run] FAILED: ${e.message}`); result.error = e.message; code = 1; }
finally { try { if (page) page.close(); } catch { /* gone */ } try { if (browser) await browser.close(); } catch { /* gone */ } server.close(); }
if (code === 0) { result.loadAfter = Math.round(await cpuLoad(3000)); result.valid = result.loadBefore <= 60 && result.loadAfter <= 60; }
writeFileSync(resolve(OUT), JSON.stringify(result));
console.log(JSON.stringify({ frames: result.rows && result.rows.length, valid: result.valid, load: [result.loadBefore, result.loadAfter], error: result.error }));
process.exit(code);
