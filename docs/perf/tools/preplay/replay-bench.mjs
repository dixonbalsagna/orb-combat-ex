#!/usr/bin/env node
// Frame cost of a stretch of a recorded match, on the page, with the page's own words changed one at a time (Performance and Platform, 2026-11-01): the layer bisect for the draw-bound stretch of Orb's first play.
// The black box file's replay is played on the kept build through Tools' capture hook in its auto mode (one tick per animation frame, no screenshots), the animation-frame intervals are recorded with the game tick
// of each, and the frames of the stretch (--from to --to) are set against the frames before and after it. The words (--query) are the page's own render words (tiles, nofore, craterlook, meteor ...): a word that
// changes nothing in the sim leaves the replay's checkpoints equal (the run says so); one that changes the sim is refused as a bisect (the match would not be the same).
//
//   node docs/perf/tools/preplay/replay-bench.mjs --file <orb-first-play-....json> --dir <built web folder> --query "planet=7&meteor=loud&tiles=1" --label A --out <result.json> [--from 1562 --to 1644 --until 1800] [--reps 1]
//
// Real GPU (no software flag), fresh profile each run, below-normal priority, a time limit, the session's name (tools/machine/browser.mjs). INVALID when the CPU use of all processors is above 60% before or after.
import { readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { Cdp, launchBrowser, serve, browserExe, cpuLoad } from '../../../../tools/machine/browser.mjs';

const argv = process.argv.slice(2);
const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
const FILE = opt('--file'), DIR = opt('--dir'), OUT = opt('--out');
if (!FILE || !DIR || !OUT) { console.error('usage: replay-bench.mjs --file <black box json> --dir <web folder> --query "<words>" --label X --out <result.json> [--from 1562 --to 1644 --until 1800]'); process.exit(2); }
const SIZE = String(opt('--size', '1280x720')).split('x').map(Number);
const FROM = Number(opt('--from', 1562)), TO = Number(opt('--to', 1644)), UNTIL = Number(opt('--until', 1800)), LABEL = opt('--label', 'run'), QUERY = opt('--query', '');
const doc = JSON.parse(readFileSync(FILE, 'utf8'));
const rp = doc.replay || doc;
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const pct = (a, p) => { const s = [...a].sort((x, y) => x - y); return s.length ? s[Math.min(s.length - 1, Math.floor(s.length * p))] : NaN; };
const stat = (a) => ({ n: a.length, p50: +pct(a, 0.5).toFixed(2), p95: +pct(a, 0.95).toFixed(2), max: +Math.max(...a).toFixed(2), over33: a.filter((x) => x > 33.4).length });
const words = String(QUERY).replace(/^\?/, '').split('&').filter(Boolean);
const server = await serve(resolve(DIR));
const RT = argv.includes('--realtime');   // the page runs the replay by itself in real time (no capture hook): our own rAF loop records every frame and the tick the page reports (?reel=1 publishes it every frame)
const url = `http://127.0.0.1:${server.address().port}/index.html?${RT ? 'go=1&' : 'flashcap=1&'}preview=1&reel=1&replay=1&blackbox=off${words.length ? '&' + words.join('&') : ''}`;
const result = { label: LABEL, words, url, from: FROM, to: TO, until: UNTIL, when: new Date().toISOString() };
let browser = null, page = null, code = 0;
try {
  result.loadBefore = Math.round(await cpuLoad(3000));
  browser = await launchBrowser({ exe: browserExe('chrome'), flags: [`--window-size=${SIZE[0]},${SIZE[1]}`], session: process.env.MERIDIAN_SESSION || 'meridian-performance-platform', purpose: 'replaybench', timeoutS: 420, cpuPercent: 0, priority: 'belownormal', log: () => {} });
  page = await Cdp.open(browser.target.webSocketDebuggerUrl);
  await page.send('Page.enable');
  await page.send('Emulation.setDeviceMetricsOverride', { width: SIZE[0], height: SIZE[1], deviceScaleFactor: 1, mobile: false });
  await page.send('Page.addScriptToEvaluateOnNewDocument', { source: `window.__replay = ${JSON.stringify(JSON.stringify(rp))};` });
  await page.send('Page.navigate', { url });
  let rec;
  if (RT) {
    await page.eval(`(() => { window.__rt = { ts: [], tk: [] }; const loop = (t) => { const p = window.__preview; window.__rt.ts.push(t); window.__rt.tk.push(p && typeof p.tick === 'number' ? p.tick : -1); requestAnimationFrame(loop); }; requestAnimationFrame(loop); })()`, true);
    const dl = Date.now() + 300 * 1000;
    for (;;) { await sleep(1000); const tk = await page.eval('(window.__preview && window.__preview.tick) || -1').catch(() => -1); if (tk >= UNTIL || Date.now() > dl) break; }
    rec = await page.eval('JSON.stringify({ ts: window.__rt.ts, tk: window.__rt.tk, cp: window.__pr_cp || null, pr: window.__pr || null })');
  } else {
    const deadline = Date.now() + 240 * 1000;
    let ready = false;
    while (Date.now() < deadline && !ready) { await sleep(500); ready = await page.eval('Boolean(window.__flashcap && window.__flashcap.ready)').catch(() => false); }
    if (!ready) throw new Error('the page offers no window.__flashcap that becomes ready');
    await page.eval(`window.__flashcap.start("ai", { reduced: false, seed: ${Number(rp.seed)} })`, true);
    // Tools' step(): one tick, resolved on a later animation frame (about two frames a step on this hook); our own rAF counter says how many, so the cost of a FRAME is the step's time over its frames
    rec = await page.eval(`(async () => {
      const fc = window.__flashcap, dt = [], tk = [], fr = [];
      let raf = 0; const loop = () => { raf++; requestAnimationFrame(loop); }; requestAnimationFrame(loop);
      const t0 = performance.now();
      while (fc.tick < ${UNTIL} && performance.now() - t0 < 230000) { const a = performance.now(), r0 = raf; await fc.step(); dt.push(performance.now() - a); fr.push(raf - r0); tk.push(fc.tick); }
      return JSON.stringify({ dt, tk, fr, err: fc.error || null, cp: window.__pr_cp || null, pr: window.__pr || null });
    })()`, true);
  }
  const r = JSON.parse(rec);
  if (RT) { r.dt = []; r.fr = []; r.tkk = []; for (let i = 1; i < r.ts.length; i++) { if (r.tk[i] < 0) continue; r.dt.push(r.ts[i] - r.ts[i - 1]); r.fr.push(1); r.tkk.push(r.tk[i]); } r.tk = r.tkk; }
  if (r.err) throw new Error(`the page reported an error: ${r.err}`);
  const iv = [], tick = [];
  for (let i = 0; i < r.dt.length; i++) { iv.push(r.dt[i] / Math.max(1, r.fr[i])); tick.push(r.tk[i]); }   // ms a frame
  const seg = (a, b) => iv.filter((_, i) => tick[i] >= a && tick[i] <= b);
  result.framesPerStep = +(r.fr.reduce((x, y) => x + y, 0) / r.fr.length).toFixed(2);
  result.before = stat(seg(FROM - 250, FROM - 1));
  result.stretch = stat(seg(FROM, TO));
  result.after = stat(seg(TO + 1, UNTIL));
  result.checkpointsOk = r.pr ? Boolean(r.pr.ok) : null;
  const want = new Map((rp.checkpoints || []).map((c) => [Number(c[0]), String(c[1])]));
  let cmp = 0, bad = -1; for (const [t, h] of (r.cp || [])) { if (!want.has(t)) continue; cmp++; if (want.get(t) !== h && bad < 0) bad = t; }
  result.checkpoints = { compared: cmp, firstDifferent: bad, page: (r.cp || []).slice(0, 4), recorded: [...want].slice(0, 4), pr: r.pr };
  result.frames = iv.length;
  result.slowInStretch = iv.map((d, i) => [tick[i], +d.toFixed(1)]).filter((x) => x[0] >= FROM && x[0] <= TO && x[1] > 33.4).length;
} catch (e) { console.log(`[replay-bench] FAILED: ${e.message}`); result.error = e.message; code = 1; }
finally { try { if (page) page.close(); } catch { /* gone */ } try { if (browser) await browser.close(); } catch { /* gone */ } server.close(); }
if (code === 0) { result.loadAfter = Math.round(await cpuLoad(3000)); result.valid = result.loadBefore <= 60 && result.loadAfter <= 60; }
writeFileSync(resolve(OUT), JSON.stringify(result, null, 1));
console.log(JSON.stringify({ label: result.label, words: result.words.join('&'), valid: result.valid, load: [result.loadBefore, result.loadAfter], framesPerStep: result.framesPerStep, before: result.before, stretch: result.stretch, after: result.after, cp: result.checkpoints, slowInStretch: result.slowInStretch, error: result.error }));
process.exit(code);
