#!/usr/bin/env node
// Reproduces "the page froze during the intro" on a phone, in headless Chrome through the project's guarded launcher (tools/machine/browser.mjs: below-normal priority, a core mask, a time limit,
// a session-named profile). Node 24 built-ins only. Owner: Performance and Platform. No Godot window.
//
//   node docs/perf/tools/freeze-probe.mjs --site <built site> --label x --out run.json
//        [--throttle 4] [--dpr 2.6] [--width 915 --height 412] [--swiftshader] [--igpu] [--seconds 90] [--taps "t:x:y,t:x:y"]
//        [--hide "t:ms"]  (a visibilitychange to hidden at t seconds for ms)   [--rotate "t"]  (swap width and height at t seconds)   [--shots 1]  (save a screenshot a second into --shotdir)
//
// What it records, in the page's own clock, from a script injected before the page loads (nothing in the export changes):
//   - every long task (PerformanceObserver "longtask": 50 ms and over) and a requestAnimationFrame heartbeat: every gap between two frames over 250 ms ("stall");
//   - the AudioContext's state changes (the page's own contexts are found by patching the constructor), WebGL context lost and restored events (found by patching getContext), visibility changes,
//     console errors, the JS heap and, when the engine exposes it, the wasm memory size.
// The probe taps the page by coordinates at the given times (touch events through CDP), as a person on a phone would (the click-through is a separate page; /play/ shows the game's own notice and card).
// A stall over 5 s is flagged: Android Chrome may call the page unresponsive from there.
import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { Cdp, launchBrowser, serve, browserExe, slug } from '../../../tools/machine/browser.mjs';

const argv = process.argv.slice(2);
const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
const SITE = opt('--site'), LABEL = opt('--label', 'run'), OUT = opt('--out');
const THROTTLE = Number(opt('--throttle', 1)), DPR = Number(opt('--dpr', 2.625));
const W = Number(opt('--width', 915)), H = Number(opt('--height', 412));
const SWIFT = argv.includes('--swiftshader'), IGPU = argv.includes('--igpu'), SECONDS = Number(opt('--seconds', 90));
const TAPS = (opt('--taps', '') || '').split(',').filter(Boolean).map((s) => s.split(':').map(Number));   // [t seconds, x, y]
const HIDE = opt('--hide') ? opt('--hide').split(':').map(Number) : null, ROTATE = opt('--rotate') ? Number(opt('--rotate')) : null;
const AFTER_BP = opt('--after-bp', null);   // the tap times count from the moment this boot mark (window.__bp, the bootprof build) appears plus 2 s, so a slow phone is tapped when its card is up, not on a clock
const RELOAD = opt('--reload-at') ? Number(opt('--reload-at')) : null;   // navigate to the page again this many seconds in (a visitor who gave up mid-boot comes back): the breadcrumbs note should show
const PRIME = opt('--prime', null);   // a JSON record put into localStorage ocx.crumbs.v1 before the page's scripts run: a visit that was abandoned mid-boot (the breadcrumbs note should show)
const LOSE = opt('--lose-context-at') ? Number(opt('--lose-context-at')) : null;   // lose the game canvas's WebGL context this many seconds in (the WEBGL_lose_context extension), as a phone may
const EVALS = (opt('--eval-at', '') || '').split(';;').filter(Boolean).map((x) => { const i = x.indexOf(':'); return [Number(x.slice(0, i)), x.slice(i + 1)]; });   // 't:js;;t:js': a page expression run at t seconds (after the taps' clock), its value kept in result.evals (the crumbs tests click the note's buttons and read storage this way)
const TRACE = argv.includes('--trace');   // a Chrome trace of the main thread (devtools.timeline, v8, wasm): which slices are the long tasks
const SHOTS = argv.includes('--shots'), SHOTDIR = opt('--shotdir', '.');
const SESSION = opt('--session', process.env.MERIDIAN_SESSION || 'meridian-performance-platform');
const PAGE = opt('--page', '/play/index.html');
if (!SITE) { console.error('usage: node docs/perf/tools/freeze-probe.mjs --site <built site> --label <name> [--throttle N] [--dpr N] [--swiftshader] [--taps "t:x:y,..."] [--out file.json]'); process.exit(2); }
const exe = opt('--browser-path') || browserExe('chrome');
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const INJECT = `(() => {
  const P = window.__probe = { t0: performance.now(), long: [], stalls: [], audio: [], gl: [], vis: [], errors: [], frames: 0, lastFrame: performance.now(), memory: [], notes: [] };
  const now = () => +(performance.now() - P.t0).toFixed(0);
  try { new PerformanceObserver((l) => { for (const e of l.getEntries()) P.long.push([+(e.startTime - P.t0).toFixed(0), +e.duration.toFixed(0)]); }).observe({ type: 'longtask', buffered: true }); } catch (e) { P.notes.push('no longtask: ' + e); }
  const beat = () => { const t = performance.now(); const gap = t - P.lastFrame; if (gap > 250) P.stalls.push([+(P.lastFrame - P.t0).toFixed(0), +gap.toFixed(0)]); P.lastFrame = t; P.frames++; requestAnimationFrame(beat); };
  requestAnimationFrame(beat);
  document.addEventListener('visibilitychange', () => P.vis.push([now(), document.visibilityState]));
  window.addEventListener('error', (e) => P.errors.push([now(), String(e.message).slice(0, 200)]));
  window.addEventListener('unhandledrejection', (e) => P.errors.push([now(), 'rejection ' + String(e.reason).slice(0, 200)]));
  for (const k of ['AudioContext', 'webkitAudioContext']) {
    const C = window[k]; if (!C) continue;
    window[k] = function (...a) { const c = new C(...a); P.audio.push([now(), 'created', c.state, c.sampleRate]); c.addEventListener('statechange', () => P.audio.push([now(), 'state', c.state])); return c; };
    window[k].prototype = C.prototype;
  }
  const gc = HTMLCanvasElement.prototype.getContext;
  HTMLCanvasElement.prototype.getContext = function (type, ...a) {
    const c = gc.call(this, type, ...a);
    if (c && /webgl/.test(type) && !this.__probed) { this.__probed = true; this.addEventListener('webglcontextlost', () => P.gl.push([now(), 'lost'])); this.addEventListener('webglcontextrestored', () => P.gl.push([now(), 'restored'])); P.gl.push([now(), 'context ' + type]); }
    return c;
  };
  setInterval(() => { try { P.memory.push([now(), performance.memory ? Math.round(performance.memory.usedJSHeapSize / 1048576) : null, window.Module && Module.HEAP8 ? Math.round(Module.HEAP8.length / 1048576) : null]); } catch (e) {} }, 2000);
})();`;

const server = await serve(SITE);
const url = `http://127.0.0.1:${server.address().port}${PAGE}`;
const result = { label: LABEL, throttle: THROTTLE, dpr: DPR, size: `${W}x${H}`, swiftshader: SWIFT, igpu: IGPU, taps: TAPS, session: SESSION, node: process.version };
let b, page;
try {
  b = await launchBrowser({
    exe, session: SESSION, purpose: 'freeze', timeoutS: SECONDS + 240, log: () => {}, software: SWIFT,
    flags: [`--window-size=${W},${H}`, ...(SWIFT ? ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--disable-gpu'] : []), ...(IGPU ? ['--force_low_power_gpu'] : []), '--autoplay-policy=document-user-activation-required'],
  });
  page = await Cdp.open(b.target.webSocketDebuggerUrl);
  await page.send('Page.enable');
  await page.send('Emulation.setDeviceMetricsOverride', { width: W, height: H, deviceScaleFactor: DPR, mobile: true, screenOrientation: { type: 'landscapePrimary', angle: 90 } });
  await page.send('Emulation.setTouchEmulationEnabled', { enabled: true, maxTouchPoints: 5 });
  await page.send('Emulation.setUserAgentOverride', { userAgent: 'Mozilla/5.0 (Linux; Android 13; Pixel 6a) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Mobile Safari/537.36', platform: 'Linux armv8l' });
  await page.send('Page.addScriptToEvaluateOnNewDocument', { source: INJECT });
  if (PRIME) await page.send('Page.addScriptToEvaluateOnNewDocument', { source: `try { if (!sessionStorage.getItem('ocxprimed')) { sessionStorage.setItem('ocxprimed', '1'); localStorage.setItem('ocx.crumbs.v1', ${JSON.stringify(PRIME)}); } } catch (e) {}` });
  result.primed = !!PRIME;
  if (THROTTLE !== 1) await page.send('Emulation.setCPUThrottlingRate', { rate: THROTTLE });
  const traceEvents = [];
  let traceDone = null;
  if (TRACE) {
    traceDone = new Promise((ok) => page.ws.addEventListener('message', (e) => { const m = JSON.parse(e.data); if (m.method === 'Tracing.dataCollected') traceEvents.push(...m.params.value); if (m.method === 'Tracing.tracingComplete') ok(); }));
    await page.send('Tracing.start', { categories: 'devtools.timeline,v8,v8.wasm,disabled-by-default-v8.compile,blink.user_timing', transferMode: 'ReportEvents' });
  }
  await page.send('Page.navigate', { url });
  const t0 = Date.now();
  const tap = async (x, y) => { for (const type of ['touchStart', 'touchEnd']) { await page.send('Input.dispatchTouchEvent', { type, touchPoints: type === 'touchStart' ? [{ x, y, id: 1 }] : [] }); await sleep(60); } };
  const done = new Set();
  let shot = 0;
  let base = null;
  while ((Date.now() - t0) / 1000 < SECONDS && Date.now() < b.deadlineMs - 20000) {
    let t = (Date.now() - t0) / 1000;
    if (AFTER_BP) {
      if (base === null) { const seen = await page.eval("!!(window.__bp && window.__bp.some((x) => x[0] === '" + AFTER_BP + "'))").catch(() => false); if (seen) { base = t + 2; result.boot_card_up_at_s = +t.toFixed(1); } }
      t = base === null ? -1 : t - base;
    }
    for (const [i, [at, x, y]] of TAPS.entries()) if (t >= at && !done.has('t' + i)) { done.add('t' + i); await tap(x, y); }
    for (const [i, [at, js]] of EVALS.entries()) if (t >= at && !done.has('e' + i)) { done.add('e' + i); (result.evals ||= []).push([at, js.slice(0, 60), await page.eval(js).catch((x) => 'ERR ' + String(x))]); }
    if (HIDE && t >= HIDE[0] && !done.has('hide')) { done.add('hide'); await page.send('Emulation.setFocusEmulationEnabled', { enabled: false }).catch(() => {}); await page.send('Page.setWebLifecycleState', { state: 'frozen' }).catch(() => {}); await sleep(HIDE[1]); await page.send('Page.setWebLifecycleState', { state: 'active' }).catch(() => {}); }
    if (RELOAD !== null && t >= RELOAD && !done.has('reload')) { done.add('reload'); await page.send('Page.navigate', { url }); await sleep(2000); result.after_reload = await page.eval("JSON.stringify({ note: (document.getElementById('ocx-crumbs-note') || {}).innerText || null, line: (document.getElementById('ocx-stage-line') || {}).innerText || null, prev: window.__ocx && window.__ocx.crumbs ? window.__ocx.crumbs.previous() : null })").then((x) => JSON.parse(x)).catch((e) => ({ error: String(e) })); }
    if (LOSE !== null && t >= LOSE && !done.has('lose')) { done.add('lose'); result.lose = await page.eval("(() => { const c = document.getElementById('canvas'); const gl = c && c.getContext('webgl2'); const e = gl && gl.getExtension('WEBGL_lose_context'); if (e) e.loseContext(); return !!e; })()").catch((x) => String(x)); await sleep(1500); result.after_lose = await page.eval("JSON.stringify({ overlay: (document.getElementById('ocx-ctx-lost') || {}).innerText || null, crumbs: window.__ocx && window.__ocx.crumbs ? window.__ocx.crumbs.record().ctx : null })").then((x) => JSON.parse(x)).catch((x) => ({ error: String(x) })); }
    if (ROTATE !== null && t >= ROTATE && !done.has('rot')) { done.add('rot'); await page.send('Emulation.setDeviceMetricsOverride', { width: H, height: W, deviceScaleFactor: DPR, mobile: true, screenOrientation: { type: 'portraitPrimary', angle: 0 } }); await sleep(3000); await page.send('Emulation.setDeviceMetricsOverride', { width: W, height: H, deviceScaleFactor: DPR, mobile: true, screenOrientation: { type: 'landscapePrimary', angle: 90 } }); }
    if (SHOTS) { try { const r = await page.send('Page.captureScreenshot', { format: 'jpeg', quality: 50 }); mkdirSync(SHOTDIR, { recursive: true }); writeFileSync(join(SHOTDIR, `${LABEL}-${String(Math.round(t)).padStart(3, '0')}.jpg`), Buffer.from(r.data, 'base64')); shot++; } catch { /* page busy */ } }
    await sleep(SHOTS ? 800 : 400);
  }
  if (TRACE) {
    await page.send('Tracing.end'); await Promise.race([traceDone, sleep(60000)]);
    const main = traceEvents.find((e) => e.ph === 'M' && e.name === 'thread_name' && e.args && e.args.name === 'CrRendererMain');
    const byName = {};
    if (main) for (const e of traceEvents) if (e.ph === 'X' && e.pid === main.pid && e.tid === main.tid) { const o = (byName[e.name] ||= { n: 0, total_ms: 0, max_ms: 0 }); o.n++; o.total_ms += e.dur / 1000; o.max_ms = Math.max(o.max_ms, e.dur / 1000); }
    const top = Object.entries(byName).filter(([, o]) => o.max_ms > 50).sort((a, b) => b[1].max_ms - a[1].max_ms).slice(0, 25).map(([k, o]) => ({ name: k, n: o.n, total_ms: +o.total_ms.toFixed(0), max_ms: +o.max_ms.toFixed(0) }));
    const big = traceEvents.filter((e) => e.ph === 'X' && main && e.pid === main.pid && e.tid === main.tid && e.dur > 500000).sort((a, b) => b.dur - a.dur).slice(0, 12).map((e) => ({ name: e.name, start_ms: +((e.ts - (traceEvents.find((x) => x.name === 'navigationStart')?.ts || 0)) / 1000).toFixed(0), dur_ms: +(e.dur / 1000).toFixed(0), args: e.args && (e.args.data ? JSON.stringify(e.args.data).slice(0, 160) : undefined) }));
    result.trace = { events: traceEvents.length, main_found: !!main, top, big };
  }
  const probe = await page.eval('JSON.stringify(window.__probe)').catch((e) => null);
  result.probe = probe ? JSON.parse(probe) : null;
  result.gpu = await page.eval(`(() => { try { const gl = document.createElement('canvas').getContext('webgl2'); const e = gl.getExtension('WEBGL_debug_renderer_info'); return gl.getParameter(e.UNMASKED_RENDERER_WEBGL) + ' | max texture ' + gl.getParameter(gl.MAX_TEXTURE_SIZE) + ' | max varyings ' + gl.getParameter(gl.MAX_VARYING_VECTORS); } catch (e) { return String(e); } })()`).catch(() => null);
  result.note = await page.eval("JSON.stringify({ note: (document.getElementById('ocx-crumbs-note') || {}).innerText || null, line: (document.getElementById('ocx-stage-line') || {}).innerText || null, report: window.__ocx && window.__ocx.crumbs ? window.__ocx.crumbs.report() : null })").then((x) => JSON.parse(x)).catch(() => null);
  result.bpreport = await page.eval('JSON.stringify(window.__bpreport || null)').then((x) => JSON.parse(x)).catch(() => null);   // the audio bank's named skipped-cue report (hook-warmmarks-audio2.mjs)
  result.bpskip = await page.eval('JSON.stringify(window.__bpskip || null)').then((x) => JSON.parse(x)).catch(() => null);
  result.bp = await page.eval('JSON.stringify(window.__bp || null)').then((x) => JSON.parse(x)).catch(() => null);
  result.shots = shot;
} catch (e) {
  result.failure = String(e.message || e); process.exitCode = 1;
} finally {
  try { if (page) page.close(); } catch { /* gone */ }
  try { if (b) await b.close(); } catch { /* gone */ }
  server.close();
}
const p = result.probe;
if (p) {
  result.summary = {
    frames: p.frames, long_tasks: p.long.length, longest_task_ms: Math.max(0, ...p.long.map((x) => x[1])), stalls_over_250: p.stalls.length, longest_stall_ms: Math.max(0, ...p.stalls.map((x) => x[1])),
    stalls_over_5s: p.stalls.filter((x) => x[1] > 5000), audio: p.audio, gl: p.gl, vis: p.vis, errors: p.errors.slice(0, 8), memory_last: p.memory.slice(-1)[0] || null,
  };
}
if (OUT) { mkdirSync(dirname(resolve(OUT)), { recursive: true }); writeFileSync(OUT, JSON.stringify(result, null, 1) + '\n'); }
console.log(`${LABEL} x${THROTTLE} dpr ${DPR}${SWIFT ? ' swiftshader' : ''}: ${result.failure ? 'FAILED ' + result.failure : JSON.stringify(result.summary).slice(0, 700)}`);
