#!/usr/bin/env node
// First load of a built web page, phase by phase, on a desktop browser (Performance and Platform, 2026-10-31). Node 24 built-ins only. No Godot window; the browser is Tools' guarded launcher
// (tools/machine/browser.mjs: below-normal priority, a time limit, a session-named profile). One browser, one fresh profile (so load 1 is a COLD first visit: empty HTTP cache, empty
// GPU/ANGLE shader cache); load 2 is the same page again in the same browser (warm), unless --no-reload.
//
//   node docs/perf/tools/load-probe.mjs --site <built folder> --query "planet=7&meteor=loud&tiles=1" --label x --out run.json [--width 1920 --height 1080] [--seconds 150] [--no-reload] [--cap 0]
//
// What it records, in the page's own clock (a script injected before the page's own):
//   - the game's breadcrumb stages (a stand-in window.__ocx.crumbs.stage, which main.gd and boot_entry.gd call on a web build): first_frame, scripts, loading, compiling, card, intro, playing;
//   - every long task (50 ms and over) and a requestAnimationFrame heartbeat (every gap between two frames over 100 ms is a freeze, tagged with the stage it began in);
//   - the WebGL calls that block the main thread: linkProgram, getProgramParameter, getShaderParameter, compileShader, draws, uploads (texImage2D, bufferData ...), each summed per stage, with
//     every single call over 25 ms listed and, for programs, a tag read from their source (the user uniforms) so the slow ones can be named;
//   - when the wasm download/compile began and ended, and the resource timings (download).
// And from outside the page, every 250 ms and independent of the page's main thread: the CPU seconds of the browser's renderer and GPU processes (CDP SystemInfo.getProcessInfo) and the machine's busy share, so
// a block that was slow because the machine was loaded reads as CPU well below wall time and is not mistaken for the page's cost.
import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { cpus } from 'node:os';
import { Cdp, launchBrowser, serve, browserExe } from '../../../tools/machine/browser.mjs';

const argv = process.argv.slice(2);
const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
const SITE = opt('--site'), QUERY = opt('--query', ''), LABEL = opt('--label', 'run'), OUT = opt('--out');
const W = Number(opt('--width', 1920)), H = Number(opt('--height', 1080)), SECONDS = Number(opt('--seconds', 150)), CAP = Number(opt('--cap', 0));
const LOADS = argv.includes('--no-reload') ? 1 : Number(opt('--loads', 2));   // load 1 is cold (fresh profile); every later load is a reload in the same browser
const SESSION = opt('--session', process.env.MERIDIAN_SESSION || 'meridian-performance-platform');
if (!SITE) { console.error('usage: node docs/perf/tools/load-probe.mjs --site <built folder> --query "planet=7" --label x --out run.json'); process.exit(2); }
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const INJECT = `(() => {
  const P = window.__lp = { t0: performance.now(), origin: performance.timeOrigin, stages: [], long: [], gaps: [], frames: 0, last: performance.now(), stage: 'page', gl: {}, glStage: {}, big: [], progs: [], bp: [], errors: [] };
  const now = () => +performance.now().toFixed(1);
  window.__ocx = window.__ocx || {};
  window.__ocx.crumbs = window.__ocx.crumbs || {};
  const prev = window.__ocx.crumbs.stage;
  window.__ocx.crumbs.stage = function (s) { P.stages.push([s, now()]); P.stage = s; if (prev) try { prev(s); } catch (e) {} };
  try { new PerformanceObserver((l) => { for (const e of l.getEntries()) P.long.push([+e.startTime.toFixed(0), +e.duration.toFixed(0)]); }).observe({ type: 'longtask', buffered: true }); } catch (e) {}
  const beat = () => { const t = performance.now(); const g = t - P.last; if (g > 100) P.gaps.push([+P.last.toFixed(0), +g.toFixed(0), P.stage]); P.last = t; P.frames++; requestAnimationFrame(beat); };
  requestAnimationFrame(beat);
  window.addEventListener('error', (e) => P.errors.push([now(), String(e.message).slice(0, 160)]));
  try {
    for (const k of ['instantiate', 'instantiateStreaming']) {
      const f = WebAssembly[k]; if (!f) continue;
      WebAssembly[k] = function (...a) { P.bp.push(['wasm_' + k + '_begin', now()]); return f.apply(this, a).then((r) => { P.bp.push(['wasm_' + k + '_end', now()]); return r; }); };
    }
  } catch (e) {}
  // WebGL: time the calls that can block. A per-stage sum and a per-method sum; any single call over 25 ms is kept with its program's tag.
  const ids = new WeakMap(); let nid = 0; const tags = new WeakMap(); const srcs = new WeakMap();
  const progInfo = new Map();   // id -> {tag, link_ms, calls, vlen, flen}
  const idOf = (p) => { if (!p) return 0; let i = ids.get(p); if (!i) { i = ++nid; ids.set(p, i); } return i; };
  const tagOf = (src) => { const seen = []; const re = /\\bm_[A-Za-z0-9_]+/g; let x; while ((x = re.exec(src)) && seen.length < 8) if (!seen.includes(x[0])) seen.push(x[0]); const defs = []; const rd = /#define\\s+(USE_\\w+|MODE_\\w+|DISABLE_\\w+|RENDER_\\w+|SHADOW\\w*|USE_\\w+)/g; while ((x = rd.exec(src)) && defs.length < 6) if (!defs.includes(x[1])) defs.push(x[1]); return seen.join(',') + (defs.length ? ' | ' + defs.join(',') : ''); };
  let cur = 0;
  const addTo = (o, k, ms) => { const r = o[k] || (o[k] = { n: 0, ms: 0, max: 0 }); r.n++; r.ms += ms; if (ms > r.max) r.max = ms; };
  const wrap = (proto, name, kind) => {
    const f = proto[name]; if (typeof f !== 'function') return;
    proto[name] = function (...a) {
      const t = performance.now(); const r = f.apply(this, a); const d = performance.now() - t;
      addTo(P.gl, name, d); (P.glStage[P.stage] || (P.glStage[P.stage] = {})); addTo(P.glStage[P.stage], kind, d);
      if (name === 'useProgram') cur = idOf(a[0]);
      let pid = 0;
      if (name === 'linkProgram' || name === 'getProgramParameter') pid = idOf(a[0]);
      else if (kind === 'draw') pid = cur;
      if (pid && (name === 'linkProgram' || name === 'getProgramParameter')) { const pi = progInfo.get(pid) || { link_ms: 0, calls: 0 }; pi.link_ms += d; pi.calls++; progInfo.set(pid, pi); }
      if (kind === 'draw' && d > 3 && pid) { const pi = progInfo.get(pid) || { link_ms: 0, calls: 0 }; pi.draw_stall_ms = (pi.draw_stall_ms || 0) + d; pi.draw_stalls = (pi.draw_stalls || 0) + 1; progInfo.set(pid, pi); }
      if (d > 25) P.big.push([+(t - P.t0 + 0).toFixed(0), name, +d.toFixed(0), pid, P.stage]);
      return r;
    };
  };
  for (const C of [window.WebGL2RenderingContext, window.WebGLRenderingContext]) {
    if (!C) continue; const p = C.prototype;
    for (const n of ['linkProgram', 'getProgramParameter', 'getShaderParameter', 'compileShader', 'validateProgram', 'getProgramInfoLog']) wrap(p, n, 'compile');
    for (const n of ['drawElements', 'drawArrays', 'drawElementsInstanced', 'drawArraysInstanced', 'drawRangeElements']) wrap(p, n, 'draw');
    for (const n of ['texImage2D', 'texSubImage2D', 'texImage3D', 'texSubImage3D', 'compressedTexImage2D', 'compressedTexSubImage2D', 'bufferData', 'bufferSubData', 'generateMipmap', 'texStorage2D', 'texStorage3D']) wrap(p, n, 'upload');
    for (const n of ['readPixels', 'finish', 'clientWaitSync', 'getError', 'flush']) wrap(p, n, 'sync');
    for (const n of ['useProgram']) wrap(p, n, 'use');
    const ss = p.shaderSource; p.shaderSource = function (sh, src) { srcs.set(sh, src); return ss.call(this, sh, src); };
    const as = p.attachShader; p.attachShader = function (pr, sh) { const l = tags.get(pr) || []; l.push(sh); tags.set(pr, l); return as.call(this, pr, sh); };
    const lp = p.linkProgram; p.linkProgram = function (pr) {
      const t = performance.now(); const r = lp.call(this, pr); const d = performance.now() - t;
      const id = idOf(pr); const l = tags.get(pr) || []; let v = 0, fr = 0, src = '';
      for (const sh of l) { const s = srcs.get(sh) || ''; if (/gl_Position/.test(s)) { v = s.length; src += s; } else { fr = s.length; src += s; } }
      const pi = progInfo.get(id) || { link_ms: 0, calls: 0 }; pi.vlen = v; pi.flen = fr; pi.tag = tagOf(src); pi.t = +(t - P.t0).toFixed(0); progInfo.set(id, pi);
      return r;
    };
  }
  P.dump = () => { const o = {}; progInfo.forEach((v, k) => { o[k] = v; }); return o; };
})();`;

const sample = { t: [], pi: [], load: [] };   // node-side timeline
const cpuSnap = () => cpus().reduce((a, c) => { const t = c.times; return { total: a.total + t.user + t.nice + t.sys + t.idle + t.irq, idle: a.idle + t.idle }; }, { total: 0, idle: 0 });

const server = await serve(SITE);
const base = `http://127.0.0.1:${server.address().port}/index.html${QUERY ? '?' + QUERY : ''}`;
const exe = opt('--browser-path') || browserExe('chrome');
const result = { label: LABEL, query: QUERY, size: `${W}x${H}`, session: SESSION, node: process.version, cap: CAP, loads: [] };
let b, page, br, timer;
try {
  b = await launchBrowser({ exe, session: SESSION, purpose: 'load', timeoutS: SECONDS * LOADS + 120, log: () => {}, cpuPercent: CAP, priority: 'belownormal', flags: [`--window-size=${W},${H}`] });
  page = await Cdp.open(b.target.webSocketDebuggerUrl);
  const ver = await (await fetch(`http://127.0.0.1:${b.port}/json/version`)).json();
  br = await Cdp.open(ver.webSocketDebuggerUrl);
  await page.send('Page.enable');
  await page.send('Performance.enable').catch(() => {});
  await page.send('Emulation.setDeviceMetricsOverride', { width: W, height: H, deviceScaleFactor: 1, mobile: false });
  await page.send('Page.addScriptToEvaluateOnNewDocument', { source: INJECT });
  // the outside timeline, every 250 ms: process CPU seconds and the machine's busy share
  let snap = cpuSnap();
  timer = setInterval(async () => {
    try {
      const r = await br.send('SystemInfo.getProcessInfo');
      const s2 = cpuSnap(); const busy = s2.total > snap.total ? 1 - (s2.idle - snap.idle) / (s2.total - snap.total) : 0; snap = s2;
      sample.t.push(Date.now()); sample.pi.push(r.processInfo.map((p) => [p.type, p.id, +p.cpuTime.toFixed(3)])); sample.load.push(+(100 * busy).toFixed(0));
    } catch { /* browser busy or gone */ }
  }, 250);
  for (let load = 1; load <= LOADS; load++) {
    const k0 = sample.t.length;
    const wall0 = Date.now();
    await page.send('Page.navigate', { url: base });
    let doneAt = null;
    while ((Date.now() - wall0) / 1000 < SECONDS && Date.now() < b.deadlineMs - 15000) {
      await sleep(500);
      const st = await page.eval('(window.__lp && window.__lp.stage) || "none"').catch(() => null);
      const bd = await page.eval('!!(window.__lp && window.__lp.bp.some((x) => x[0] === "boot_done"))').catch(() => false);   // a hooked scratch build says it (hook-loadmarks.mjs)
      if (((st && ['card', 'intro', 'playing'].includes(st)) || bd) && doneAt === null) doneAt = Date.now();
      if (doneAt !== null && Date.now() - doneAt > 12000) break;
    }
    const L = { n: load, wall0, k0, k1: sample.t.length, reachedStage: doneAt !== null };
    L.bpd = await page.eval('JSON.stringify(window.__bpd || null)').then(JSON.parse).catch(() => null);   // main.gd's per-step totals (hook-loadmarks.mjs)
    L.bp = await page.eval('JSON.stringify(window.__bp || null)').then(JSON.parse).catch(() => null);
    // what the page has put in the browser's own storage: every IndexedDB (Godot's user:// is /userfs, store FILE_DATA), and the size of each entry whose path holds "cache"
    L.idb = await page.eval(`(async () => { try { const dbs = await indexedDB.databases(); const out = []; for (const d of dbs) { const db = await new Promise((ok, no) => { const r = indexedDB.open(d.name); r.onsuccess = () => ok(r.result); r.onerror = () => no(r.error); }); for (const s of Array.from(db.objectStoreNames)) { const st = db.transaction(s, 'readonly').objectStore(s); const keys = await new Promise((ok) => { const r = st.getAllKeys(); r.onsuccess = () => ok(r.result); }); const rows = []; for (const k of keys) { if (!/cache/i.test(String(k))) continue; const v = await new Promise((ok) => { const r = st.get(k); r.onsuccess = () => ok(r.result); }); rows.push([String(k), v && v.contents ? v.contents.length : (v && v.length) || 0]); } out.push([d.name, s, keys.length, rows]); } db.close(); } return JSON.stringify(out); } catch (e) { return 'ERR ' + e; } })()`, true).then((x) => { try { return JSON.parse(x); } catch { return x; } }).catch((e) => 'ERR ' + e);
    L.origin = await page.eval('window.__lp ? window.__lp.origin : null').catch(() => null);
    const raw = await page.eval('JSON.stringify(Object.assign({}, window.__lp, { dump: window.__lp.dump() }))').catch((e) => null);
    L.p = raw ? JSON.parse(raw) : null;
    L.resources = await page.eval("JSON.stringify(performance.getEntriesByType('resource').map((e) => [e.name.split('/').pop().split('?')[0], Math.round(e.startTime), Math.round(e.responseEnd), e.transferSize, e.encodedBodySize]))").then(JSON.parse).catch(() => null);
    L.nav = await page.eval("JSON.stringify(performance.getEntriesByType('navigation').map((e) => [Math.round(e.responseEnd), Math.round(e.domContentLoadedEventEnd), Math.round(e.loadEventEnd)]))").then(JSON.parse).catch(() => null);
    L.metrics = await page.send('Performance.getMetrics').then((r) => Object.fromEntries(r.metrics.map((m) => [m.name, +m.value.toFixed(3)]))).catch(() => null);
    L.gpu = await page.eval(`(() => { try { const gl = document.createElement('canvas').getContext('webgl2'); const e = gl.getExtension('WEBGL_debug_renderer_info'); return gl.getParameter(e.UNMASKED_RENDERER_WEBGL); } catch (e) { return String(e); } })()`).catch(() => null);
    if (load === 1) { try { const r = await page.send('Page.captureScreenshot', { format: 'jpeg', quality: 55 }); if (OUT) { mkdirSync(dirname(resolve(OUT)), { recursive: true }); writeFileSync(resolve(OUT).replace(/\.json$/, '') + `-load${load}.jpg`, Buffer.from(r.data, 'base64')); } } catch { /* busy */ } }
    result.loads.push(L);
  }
  result.sample = sample;
} catch (e) {
  result.failure = String(e.message || e); process.exitCode = 1;
} finally {
  clearInterval(timer);
  try { if (page) page.close(); } catch { /* gone */ }
  try { if (br) br.close(); } catch { /* gone */ }
  try { if (b) await b.close(); } catch { /* gone */ }
  server.close();
  if (OUT) { mkdirSync(dirname(resolve(OUT)), { recursive: true }); writeFileSync(resolve(OUT), JSON.stringify(result)); }
}
console.log(`load-probe: ${result.failure ? 'FAILED ' + result.failure : 'done'}; loads ${result.loads.length}${OUT ? ', ' + OUT : ''}`);
