#!/usr/bin/env node
// Layer bisect on the page (Performance and Platform, 2026-11-01): which layer of a scene costs how much of the frame, at a chosen tick of a recorded match.
// Needs a scratch web export of the stack tree with docs/perf/tools/scratch-hooks/hook-layers2.mjs applied (window.__cut hides nodes by name; window.__dump lists the nodes it can hide; the hook also publishes the engine's
// draw calls and primitives and both fighters' x and y). The recorded match (a black box file) is played with Tools' capture hook one tick per step() to the chosen tick; the scene is then PAUSED there (the same picture
// is drawn every frame) and, one set of layers at a time, hidden while the animation-frame interval is measured over --frames frames. The difference from the uncut frame is that layer's share of the SAME frame.
//
//   node docs/perf/tools/preplay/layer-bisect.mjs --file <orb-first-play-....json> --dir <the scratch web export> --ticks 1590,2161 --out <result.json> [--discover] [--frames 150] [--cuts "a,b;c"]
//   --discover: only print the node names and the positions at each tick (to choose --cuts: a ';'-separated list of cuts, each a ','-separated list of node-name prefixes)
//
// Real GPU (no software flag), a fresh profile, below-normal priority, a time limit, the session's name (tools/machine/browser.mjs). INVALID when the CPU use of all processors is above 60% before or after.
import { readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { Cdp, launchBrowser, serve, browserExe, cpuLoad } from '../../../../tools/machine/browser.mjs';

const argv = process.argv.slice(2);
const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
const FILE = opt('--file'), DIR = opt('--dir'), OUT = opt('--out');
if (!FILE || !DIR) { console.error('usage: layer-bisect.mjs --file <black box json> --dir <scratch web export> --ticks 1590,2161 --out <result.json> [--discover] [--cuts "a,b;c"]'); process.exit(2); }
const TICKS = String(opt('--ticks', '1590')).split(',').map(Number), FRAMES = Number(opt('--frames', 150)), DISCOVER = argv.includes('--discover');
const QUERY = opt('--query', 'planet=7&meteor=loud&tiles=1');
const doc = JSON.parse(readFileSync(FILE, 'utf8'));
const rp = doc.replay || doc;
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const pct = (a, p) => { const s = [...a].sort((x, y) => x - y); return s.length ? s[Math.min(s.length - 1, Math.floor(s.length * p))] : NaN; };
const server = await serve(resolve(DIR));
const url = `http://127.0.0.1:${server.address().port}/index.html?flashcap=1&preview=1&reel=1&replay=1&blackbox=off&${QUERY}`;
const result = { url, file: FILE, frames: FRAMES, when: new Date().toISOString(), points: [] };
let browser = null, page = null, code = 0;
try {
  result.loadBefore = Math.round(await cpuLoad(3000));
  browser = await launchBrowser({ exe: browserExe('chrome'), flags: ['--window-size=1280,720'], session: process.env.MERIDIAN_SESSION || 'meridian-performance-platform', purpose: 'layerbisect', timeoutS: 900, cpuPercent: 0, priority: 'belownormal', log: () => {} });
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
  let names = null;
  for (const target of TICKS) {
    await page.eval(`(async () => { const fc = window.__flashcap; while (fc.tick < ${target}) { await fc.step(); } })()`, true);
    await page.eval('window.__cut = ""; window.__dump = 1', true);
    await sleep(1500);   // a few frames: the hook publishes on every poll
    const info = JSON.parse(await page.eval('JSON.stringify({ r: window.__flashcap.rinfo || null, n: window.__names || null, tick: window.__flashcap.tick })'));
    names = info.n || names;
    const pt = { target, tick: info.tick, rinfo: info.r, separation: info.r ? Math.abs(info.r.fx[0] - info.r.fx[1]) : null, cuts: [] };
    if (DISCOVER) { pt.names = info.n; result.points.push(pt); continue; }
    const cuts = String(opt('--cuts', '')).split(';').map((c) => c.trim());
    if (!cuts.includes('')) cuts.unshift('');
    for (const c of cuts) {
      await page.eval(`window.__cut = ${JSON.stringify(c)}`, true);
      await sleep(400);
      const m = JSON.parse(await page.eval(`(async () => { const ts = []; for (let i = 0; i < ${FRAMES + 6}; i++) await new Promise((r) => requestAnimationFrame((t) => { ts.push(t); r(); })); const iv = []; for (let i = 7; i < ts.length; i++) iv.push(ts[i] - ts[i - 1]); return JSON.stringify({ iv, rinfo: window.__flashcap.rinfo || null }); })()`, true));
      pt.cuts.push({ cut: c || '(none)', p50: +pct(m.iv, 0.5).toFixed(2), p95: +pct(m.iv, 0.95).toFixed(2), max: +Math.max(...m.iv).toFixed(2), draws: m.rinfo && m.rinfo.draws, primsK: m.rinfo && Math.round(m.rinfo.prims / 1000) });
    }
    await page.eval('window.__cut = ""', true);
    result.points.push(pt);
  }
  result.checkpoints = await page.eval('JSON.stringify(window.__pr_cp || [])').then((x) => JSON.parse(x || '[]')).catch(() => []);
} catch (e) { console.log(`[layer-bisect] FAILED: ${e.message}`); result.error = e.message; code = 1; }
finally { try { if (page) page.close(); } catch { /* gone */ } try { if (browser) await browser.close(); } catch { /* gone */ } server.close(); }
if (code === 0) { result.loadAfter = Math.round(await cpuLoad(3000)); result.valid = result.loadBefore <= 60 && result.loadAfter <= 60; }
if (OUT) writeFileSync(resolve(OUT), JSON.stringify(result, null, 1));
for (const pt of result.points) {
  console.log(`tick ${pt.tick} (asked ${pt.target}): fighters ${pt.separation} apart, x ${JSON.stringify(pt.rinfo && pt.rinfo.fx)} y ${JSON.stringify(pt.rinfo && pt.rinfo.fy)}; ${pt.rinfo && pt.rinfo.draws} draws, ${pt.rinfo && Math.round(pt.rinfo.prims / 1000)}k prims`);
  if (pt.names) console.log(pt.names.join('\n'));
  for (const c of pt.cuts) console.log(`  cut ${c.cut}: p50 ${c.p50} ms, p95 ${c.p95}, max ${c.max}; ${c.draws} draws, ${c.primsK}k prims`);
}
console.log(`valid: ${result.valid} (load ${result.loadBefore}/${result.loadAfter}); error: ${result.error || 'none'}`);
process.exit(code);
