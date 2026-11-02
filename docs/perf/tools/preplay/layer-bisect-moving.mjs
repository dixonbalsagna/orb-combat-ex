#!/usr/bin/env node
// Layer bisect on the MOVING stretch (Performance and Platform, 2026-11-01): the same layers as layer-bisect.mjs, but measured while the recorded match runs through the stretch (not paused): a paused picture was
// cheap (4 to 5 ms a frame at the far tick), so what costs in Orb's stretch happens only while ticks run (the view following a frame that moves). One browser per cut (a fresh profile, the match from tick 0 so every
// run sees the same ticks); the cut is set before the first step and stays. Frame cost = a step's time over the animation frames it took (Tools' capture hook: about two frames a step).
//
//   node docs/perf/tools/preplay/layer-bisect-moving.mjs --file <orb json> --dir <scratch web export with hook-layers2> --cut "p1:root" --from 1562 --to 1644 --out <result.json>
// Output: one JSON line: the cut, the median / p95 / max ms a frame before (from-45 .. from-1), in (from .. to) and after (to+1 .. to+60) the stretch, the checkpoints compared, the machine load before and after.
import { readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { Cdp, launchBrowser, serve, browserExe, cpuLoad } from '../../../../tools/machine/browser.mjs';

const argv = process.argv.slice(2);
const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
const FILE = opt('--file'), DIR = opt('--dir'), OUT = opt('--out'), CUT = opt('--cut', ''), FROM = Number(opt('--from', 1562)), TO = Number(opt('--to', 1644));
const QUERY = opt('--query', 'planet=7&meteor=loud&tiles=1');
if (!FILE || !DIR) { console.error('usage: layer-bisect-moving.mjs --file <orb json> --dir <web export> --cut "<names>" --from 1562 --to 1644 --out <result.json>'); process.exit(2); }
const rp = (JSON.parse(readFileSync(FILE, 'utf8'))).replay;
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const pct = (a, p) => { const s = [...a].sort((x, y) => x - y); return s.length ? s[Math.min(s.length - 1, Math.floor(s.length * p))] : NaN; };
const stat = (a) => ({ n: a.length, p50: +pct(a, 0.5).toFixed(2), p95: +pct(a, 0.95).toFixed(2), max: +Math.max(...a).toFixed(2) });
const server = await serve(resolve(DIR));
const url = `http://127.0.0.1:${server.address().port}/index.html?flashcap=1&preview=1&reel=1&replay=1&blackbox=off&${QUERY}`;
const result = { cut: CUT || '(none)', from: FROM, to: TO, when: new Date().toISOString() };
let browser = null, page = null, code = 0;
try {
  result.loadBefore = Math.round(await cpuLoad(3000));
  browser = await launchBrowser({ exe: browserExe('chrome'), flags: ['--window-size=1280,720'], session: process.env.MERIDIAN_SESSION || 'meridian-performance-platform', purpose: 'layermoving', timeoutS: 600, cpuPercent: 0, priority: 'belownormal', log: () => {} });
  page = await Cdp.open(browser.target.webSocketDebuggerUrl);
  await page.send('Page.enable');
  await page.send('Emulation.setDeviceMetricsOverride', { width: 1280, height: 720, deviceScaleFactor: 1, mobile: false });
  await page.send('Page.addScriptToEvaluateOnNewDocument', { source: `window.__replay = ${JSON.stringify(JSON.stringify(rp))}; window.__cut = ${JSON.stringify(CUT)};` });
  await page.send('Page.navigate', { url });
  const dl = Date.now() + 300 * 1000;
  let ready = false;
  while (Date.now() < dl && !ready) { await sleep(500); ready = await page.eval('Boolean(window.__flashcap && window.__flashcap.ready)').catch(() => false); }
  if (!ready) throw new Error('the page offers no window.__flashcap that becomes ready');
  await page.eval(`window.__flashcap.start("ai", { reduced: false, seed: ${Number(rp.seed)} })`, true);
  const rec = JSON.parse(await page.eval(`(async () => {
    const fc = window.__flashcap, dt = [], tk = [], fr = [];
    let raf = 0; const loop = () => { raf++; requestAnimationFrame(loop); }; requestAnimationFrame(loop);
    while (fc.tick < ${TO + 60}) { const a = performance.now(), r0 = raf; await fc.step(); dt.push(performance.now() - a); fr.push(Math.max(1, raf - r0)); tk.push(fc.tick); }
    return JSON.stringify({ dt, fr, tk, cp: window.__pr_cp || [], rinfo: window.__flashcap.rinfo || null });
  })()`, true));
  const per = rec.dt.map((d, i) => d / rec.fr[i]);
  const seg = (a, b) => per.filter((_, i) => rec.tk[i] >= a && rec.tk[i] <= b);
  result.before = stat(seg(FROM - 45, FROM - 1)); result.stretch = stat(seg(FROM, TO)); result.after = stat(seg(TO + 1, TO + 60));
  result.rinfo = rec.rinfo;
  const want = new Map((rp.checkpoints || []).map((c) => [Number(c[0]), String(c[1])]));
  let cmp = 0, bad = -1; for (const [t, h] of rec.cp) { if (!want.has(t)) continue; cmp++; if (want.get(t) !== h && bad < 0) bad = t; }
  result.checkpoints = { compared: cmp, firstDifferent: bad };
} catch (e) { console.log(`[layer-bisect-moving] FAILED: ${e.message}`); result.error = e.message; code = 1; }
finally { try { if (page) page.close(); } catch { /* gone */ } try { if (browser) await browser.close(); } catch { /* gone */ } server.close(); }
if (code === 0) { result.loadAfter = Math.round(await cpuLoad(3000)); result.valid = result.loadBefore <= 60 && result.loadAfter <= 60; }
if (OUT) writeFileSync(resolve(OUT), JSON.stringify(result));
console.log(JSON.stringify({ cut: result.cut, valid: result.valid, load: [result.loadBefore, result.loadAfter], before: result.before, stretch: result.stretch, after: result.after, cp: result.checkpoints, error: result.error }));
process.exit(code);
