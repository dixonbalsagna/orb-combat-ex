#!/usr/bin/env node
// Frame cost of the web build on one of Tools' staged scenes, through the project's guarded browser launcher (tools/machine/browser.mjs: below-normal priority, a CPU cap,
// a time limit, a session-named profile). Node 24 built-ins only. Opens no Godot window. One run = one browser = one scene. Owner: Performance and Platform.
//
//   node docs/perf/tools/frame-bench.mjs --site <built site> --scene mashcity|signaturecity|ring|clash|collapse|ai --label base [--slots A,B,C] [--throttle 1|4|6] [--igpu]
//        [--ticks 600] [--warm 120] [--width 1280 --height 720] [--seed 12345] [--out run.json] [--session meridian-performance-platform] [--time-limit 900]
//
// How it measures: the page offers Tools' hook (/play/?flashcap=1). The driver starts the scene, then calls step() in a loop INSIDE the page: one sim tick, one drawn
// frame, resolved when the browser starts the next animation frame. The time of one step() is the cost of one frame (the tick, the view update, the draw and the
// browser's own present). vsync and the frame-rate limit are switched off so a fast machine is not held at 60. A scratch hook in the export (docs/perf/audit-2026-10-16.md,
// "Method") adds the game's own per-frame numbers: tick ms, fx+camera ms, view-update ms, draw calls, objects, primitives, live particles, video memory.
// --throttle N is Chrome's CPU throttle (Emulation.setCPUThrottlingRate): the browser's main thread and workers run N times slower. It is a stand-in for an older CPU, not
// a model of one (see the audit's "Method"): it does not slow the GPU, memory or a hot laptop.
//
// VALIDITY: the machine is shared. The driver samples the CPU use of every logical processor for 3 s before, during and for 3 s after the run. A run is marked
// valid:false when the machine was saturated: mean use over all processors above 60% before or after, or the capture's own cores (the highest-numbered 25%) above 70%.
// A run that is not valid still writes its numbers, as an upper bound; do not compare it with a budget.
import { spawnSync } from 'node:child_process';
import { mkdirSync, writeFileSync } from 'node:fs';
import { cpus } from 'node:os';
import { dirname, resolve } from 'node:path';
import { Cdp, launchBrowser, serve, browserExe, slug } from '../../../tools/machine/browser.mjs';

const argv = process.argv.slice(2);
const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
const SITE = opt('--site');
const SCENE = opt('--scene', 'mashcity');
const LABEL = opt('--label', 'run');
const THROTTLE = Number(opt('--throttle', 1));
const TICKS = Number(opt('--ticks', 600)), WARM = Number(opt('--warm', 120));
const W = Number(opt('--width', 1280)), H = Number(opt('--height', 720));
const SEED = opt('--seed') === undefined ? null : Number(opt('--seed'));
const SLOTS = opt('--slots') ? opt('--slots').split(',') : null;
const SESSION = opt('--session', process.env.MERIDIAN_SESSION || 'meridian-performance-platform');
const TIME_LIMIT = Number(opt('--time-limit', 900));
const OUT = opt('--out');
const SLICE = argv.includes('--slice');
const SLICE_MODES = (opt('--slice-modes', 'equator,poles')).split(',');   // add equator_c8,poles_c8 for the coarse variants (every 8th column, the rest interpolated; scratch hook only)   // time World's 4,800-column planet-slice strip read through the scratch hook (window.__slicebench) instead of a scene
const FREEZE = Number(opt('--freeze', 104));   // the tick a --layers run pauses the scene at (104: the signature scene's beam is up)
const LAYERS = argv.includes('--layers');   // also measure with each layer cut (scratch hook window.__cut; needs an export that carries it)
const PAGE_ARGS = opt('--page-args', '');   // extra page query, for example depth=1 (scratch hook: fight-lane depth on, which is what the lobby needs)
const REDUCED = argv.includes('--reduced');   // the hook's reduced mode: reduced motion and the flash register's reduced mode (Orb's Reduce flashing, locked on in the live demo)
const IGPU = argv.includes('--igpu');   // force the integrated GPU (Chrome's --force_low_power_gpu, as Research's engine spike did); the run refuses to report if the GPU string is not AMD or Radeon
if (!SITE) { console.error('usage: node docs/perf/tools/frame-bench.mjs --site <built site> --scene <id> --label <name> [--throttle N] [--slots A,B,C] [--out file.json]'); process.exit(2); }
const exe = opt('--browser-path') || browserExe('chrome');
if (!exe) { console.error('no Chrome found'); process.exit(2); }
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// ---- machine load: per-processor use between two reads
const read = () => cpus().map((c) => { const t = c.times; return { total: t.user + t.nice + t.sys + t.idle + t.irq, idle: t.idle }; });
function use(a, b) { return a.map((x, i) => { const dt = b[i].total - x.total; return dt > 0 ? 100 * (1 - (b[i].idle - x.idle) / dt) : 0; }); }
const mean = (v) => (v.length ? v.reduce((s, x) => s + x, 0) / v.length : 0);
async function sample(ms) { const a = read(); await sleep(ms); return use(a, read()); }
const capCores = (v) => v.slice(Math.floor(v.length * 0.75));   // the launcher's mask: the highest-numbered 25%

const pct = (arr, p) => { if (!arr.length) return null; const s = [...arr].sort((x, y) => x - y); return s[Math.min(s.length - 1, Math.max(0, Math.ceil(p * s.length) - 1))]; };
const dist = (arr) => (arr.length ? { n: arr.length, mean: +mean(arr).toFixed(3), p10: +pct(arr, 0.1).toFixed(3), p50: +pct(arr, 0.5).toFixed(3), p95: +pct(arr, 0.95).toFixed(3), p99: +pct(arr, 0.99).toFixed(3), max: +Math.max(...arr).toFixed(3) } : null);

function browserMemoryMB(profileHint) {
  // the working set and the private bytes of the browser's processes, in MB, by process type (renderer = the page and its wasm heap; gpu-process; browser; utility)
  if (process.platform !== 'win32') return null;
  const ps = "Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -like '*" + profileHint + "*' -and $_.Name -notlike 'powershell*' } | ForEach-Object { $t = 'browser'; if ($_.CommandLine -match '--type=([a-z-]+)') { $t = $Matches[1] }; $p = Get-Process -Id $_.ProcessId -ErrorAction SilentlyContinue; [pscustomobject]@{ t = $t; ws = $_.WorkingSetSize; pv = $(if ($p) { $p.PrivateMemorySize64 } else { 0 }) } } | ConvertTo-Json -Compress";
  const r = spawnSync('powershell', ['-NoProfile', '-Command', ps], { encoding: 'utf8', timeout: 30000 });
  try {
    const a = [].concat(JSON.parse(r.stdout || '[]')); const out = { total_ws: 0, total_private: 0 };
    for (const x of a) { out[x.t + '_ws'] = Math.round(((out[x.t + '_ws'] || 0) * 1048576 + x.ws) / 1048576); out[x.t + '_private'] = Math.round(((out[x.t + '_private'] || 0) * 1048576 + x.pv) / 1048576); out.total_ws += x.ws / 1048576; out.total_private += x.pv / 1048576; }
    out.total_ws = Math.round(out.total_ws); out.total_private = Math.round(out.total_private);
    return out;
  } catch { return null; }
}

// CPU time used by every process of this run's browser (the profile folder is in each command line), in ms, by process type. Wall time on a shared machine is inflated by the
// other sessions; CPU time is much less so, which makes it the figure that survives a busy PC (it is still affected by cache and hyper-threading sharing). Windows only.
function browserCpuMs(hint) {
  if (process.platform !== 'win32') return null;
  const ps = "Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -like '*" + hint + "*' -and $_.Name -notlike 'powershell*' } | ForEach-Object { $t = 'browser'; if ($_.CommandLine -match '--type=([a-z-]+)') { $t = $Matches[1] }; [pscustomobject]@{ t = $t; ms = ($_.KernelModeTime + $_.UserModeTime) / 10000 } } | ConvertTo-Json -Compress";
  const r = spawnSync('powershell', ['-NoProfile', '-Command', ps], { encoding: 'utf8', timeout: 30000 });
  try { const a = [].concat(JSON.parse(r.stdout || '[]')); const out = {}; for (const x of a) out[x.t] = (out[x.t] || 0) + x.ms; return out; } catch { return null; }
}

const server = await serve(SITE);
const url = `http://127.0.0.1:${server.address().port}/play/index.html?flashcap=1${PAGE_ARGS ? '&' + PAGE_ARGS : ''}`;
let b, page;
const result = { igpu: IGPU, label: LABEL, scene: SCENE, slots: SLOTS, pageArgs: PAGE_ARGS, reduced: REDUCED, throttle: THROTTLE, viewport: `${W}x${H}`, ticks: TICKS, warm: WARM, seed: SEED, node: process.version, session: SESSION };
try {
  const before = await sample(3000);
  result.loadBefore = { all: +mean(before).toFixed(0), cap: +mean(capCores(before)).toFixed(0) };
  b = await launchBrowser({
    exe, session: SESSION, purpose: 'framebench', timeoutS: TIME_LIMIT, log: () => {},
    flags: [`--window-size=${W},${H}`, '--disable-gpu-vsync', '--disable-frame-rate-limit', '--disable-background-timer-throttling', '--disable-renderer-backgrounding', '--disable-backgrounding-occluded-windows', '--enable-precise-memory-info', ...(IGPU ? ['--force_low_power_gpu'] : [])],
  });
  page = await Cdp.open(b.target.webSocketDebuggerUrl);
  await page.send('Page.enable');
  await page.send('Emulation.setDeviceMetricsOverride', { width: W, height: H, deviceScaleFactor: 1, mobile: false });
  await page.send('Page.navigate', { url });
  const t0 = Date.now();
  let ready = false;
  while (Date.now() < b.deadlineMs && !ready) { await sleep(500); ready = Boolean(await page.eval('!!(window.__flashcap && window.__flashcap.ready)').catch(() => false)); }
  if (!ready) throw new Error('the page never offered window.__flashcap.ready');
  result.loadSeconds = +((Date.now() - t0) / 1000).toFixed(1);
  result.gpu = await page.eval(`(() => { try { const gl = document.createElement('canvas').getContext('webgl2'); const e = gl.getExtension('WEBGL_debug_renderer_info'); return gl.getParameter(e.UNMASKED_RENDERER_WEBGL); } catch (e) { return 'unavailable'; } })()`);
  if (IGPU && !/AMD|Radeon/i.test(result.gpu)) throw new Error('--igpu asked for the integrated GPU but the page reports ' + result.gpu);
  if (THROTTLE !== 1) await page.send('Emulation.setCPUThrottlingRate', { rate: THROTTLE });
  if (SLICE) {
    result.slice = {};
    for (const mode of SLICE_MODES) {
      await page.eval(`window.__sliceResult = null; window.__slicebench(${JSON.stringify(mode)}, ${THROTTLE > 1 ? 2 : 3})`);
      const r = await page.eval('JSON.stringify(window.__sliceResult)');
      result.slice[mode] = JSON.parse(r);
    }
    const after1 = await sample(3000);
    result.loadAfter = { all: +mean(after1).toFixed(0), cap: +mean(capCores(after1)).toFixed(0) };
    result.loadDuring = result.loadBefore;
    result.valid = !(result.loadBefore.all > 60 || result.loadAfter.all > 60 || result.loadBefore.cap > 70 || result.loadAfter.cap > 70);
    result.validity = result.valid ? 'valid by the load rule' : 'INVALID: machine saturated before or after the run; an upper bound only';
    result.browserMemMB = browserMemoryMB(`cap-${slug(SESSION, 'nosession')}-framebench`);
    throw new Error('__slice_done__');
  }
  const startArgs = JSON.stringify({ reduced: REDUCED, ...(SEED === null ? {} : { seed: SEED }), ...(SLOTS ? { slots: SLOTS } : {}) });
  await page.eval(`window.__flashcap.start(${JSON.stringify(SCENE)}, ${startArgs})`);
  // the scene is up when its first step answers
  const during = [];
  let sampling = true;
  const sampler = (async () => { while (sampling) { during.push(await sample(2000)); } })();
  // AUTO mode (scratch hook): the game runs one tick on every animation frame by itself and this loop only reads the browser's frame timestamps (requestAnimationFrame), so a frame is the
  // interval between two of them: the cost of one tick plus one drawn frame, as in real play at 60 Hz with vsync off. (The first version stepped with step(), which ran a tick on every OTHER
  // frame: a step took two animation frames, the second only repeating the picture. Runs made that way are superseded; see the audit's Method.)
  const loopJs = (from, to, keep) => `(async () => {
    const fc = window.__flashcap; const rtt = [], rows = []; let last = null; const tick0 = fc.tick;
    fc.auto = true;
    for (let i = ${from}; i < ${to}; i++) {
      const t = await new Promise((r) => requestAnimationFrame(r));
      if (last !== null && ${keep}) { rtt.push(t - last); const p = fc.perf; rows.push(p ? [p.tick_ms, p.fx_ms, p.view_ms, p.draws, p.objects, p.prims, p.parts, p.vmem, p.tmem, p.smem, p.rcpu, p.rgpu, p.pt || null, p.ev || ""] : []); }
      last = t;
    }
    fc.auto = false;
    return JSON.stringify({ rtt, rows, frames: ${to} - ${from}, ticks: fc.tick - tick0, error: fc.error, tick: fc.tick, scenario: fc.scenario });
  })()`;
  await page.eval(loopJs(0, WARM, false), true);
  const hint = `cap-${slug(SESSION, 'nosession')}-framebench`;
  if (LAYERS) {
    // layer cuts (scratch hook window.__cut): run the scene to one tick, PAUSE it there (no more ticks: the same picture is drawn every frame), then hide layers one set at a time and
    // read the draw calls and primitives the engine reports and the frame time and CPU time per frame. The difference from the uncut picture is that layer's share of the SAME frame.
    await page.eval(`(async () => { const fc = window.__flashcap; fc.auto = true; while (fc.tick < ${FREEZE}) await new Promise((r) => requestAnimationFrame(r)); fc.auto = false; await new Promise((r) => requestAnimationFrame(r)); })()`, true);
    const pausedJs = (n) => `(async () => { const fc = window.__flashcap; const rtt = [], di = [], pr = []; let last = null, info = null; for (let i = 0; i < ${n}; i++) { const t = await new Promise((r) => requestAnimationFrame(r)); if (last !== null) { rtt.push(t - last); const q = fc.rinfo || {}; di.push(q.draws); pr.push(q.prims); info = q; } last = t; } return JSON.stringify({ rtt, di, pr, tick: fc.tick, info }); })()`;
    result.layers = []; result.freezeTick = FREEZE;
    for (const cut of ['', 'terrain', 'water', 'terrain,water', 'bld', 'bld0', 'bld,bld0', 'trees', 'crowd', 'fighters', 'beams', 'particles', 'vfx', 'bld,bld0,trees,crowd', 'terrain,water,bld,bld0,trees,crowd', 'terrain,water,bld,bld0,trees,crowd,fighters,beams,particles,vfx', 'hud', 'terrain,water,bld,bld0,trees,crowd,fighters,beams,particles,vfx,hud']) {
      await page.eval(`window.__cut = ${JSON.stringify(cut)}`);
      await page.eval(pausedJs(20), true);
      const c0 = browserCpuMs(hint);
      const rr = JSON.parse(await page.eval(pausedJs(61), true));
      const c1 = browserCpuMs(hint);
      const cpuf = {}; if (c0 && c1) for (const k of ['renderer', 'gpu-process']) cpuf[k] = +(((c1[k] || 0) - (c0[k] || 0)) / 60).toFixed(2);
      result.layers.push({ cut: cut || '(none)', frame_p10: +pct(rr.rtt, 0.1).toFixed(2), frame_p50: +pct(rr.rtt, 0.5).toFixed(2), draws: pct(rr.di.filter(Number.isFinite), 0.5), prims_k: +(pct(rr.pr.filter(Number.isFinite), 0.5) / 1000).toFixed(1), tickHeld: rr.tick, panes: rr.info && rr.info.panes, inset: rr.info && rr.info.inset, cpu_ms_per_frame: cpuf });
    }
    await page.eval('window.__cut = ""');
    await page.eval(`(async () => { const fc = window.__flashcap; fc.auto = true; for (let i = 0; i < 30; i++) await new Promise((r) => requestAnimationFrame(r)); fc.auto = false; })()`, true);
  }
  const cpu0 = browserCpuMs(hint);
  const raw = JSON.parse(await page.eval(loopJs(WARM, WARM + TICKS, true), true));
  const cpu1 = browserCpuMs(hint);
  if (cpu0 && cpu1) {
    result.cpu_ms_per_frame = {};
    for (const k of Object.keys(cpu1)) result.cpu_ms_per_frame[k] = +(((cpu1[k] || 0) - (cpu0[k] || 0)) / TICKS).toFixed(3);
    result.cpu_ms_per_frame.total = +Object.values(result.cpu_ms_per_frame).reduce((a, x) => a + x, 0).toFixed(3);
  }
  sampling = false; await sampler;
  result.error = raw.error || '';
  const col = (k) => raw.rows.map((r) => r[k]).filter((v) => Number.isFinite(v));
  result.frame_ms = dist(raw.rtt);
  // frames over 50 ms, as [tick of the scene, ms]: a hitch that comes at the same tick in every run is the engine or the page (a first-use shader compile, a pool built), not the machine
  // with the evlog hook: the sim event types of each hitching tick and the tick before it (row 13)
  result.hitchEvents = raw.rtt.map((x, i) => [raw.tick - raw.rtt.length + i, x, (raw.rows[i] || [])[13] || "", (raw.rows[i - 1] || [])[13] || ""]).filter((h) => h[1] > 50).slice(0, 12);
  // the whole row of each hitching frame (tick ms, fx ms, view ms, draws, objects, prims, particles, vmem, tmem, smem, renderer cpu, renderer gpu, profiling timers, events) and the one before
  result.hitchRows = raw.rtt.map((x, i) => [raw.tick - raw.rtt.length + i, x, raw.rows[i - 1] || [], raw.rows[i] || [], raw.rows[i + 1] || [], raw.rows[i + 3] || []]).filter((h) => h[1] > 50).slice(0, 4);
  // frames whose tick carried a crater (evlog/evprof hook): the frame time, the game's timers and the profiling counters' growth over the frame, to compare the first crater with a later one
  result.craterRows = raw.rows.map((r, i) => [raw.tick - raw.rtt.length + i, raw.rtt[i], r, raw.rows[i - 1] || []]).filter((x) => /crater/.test(x[2][13] || '')).slice(0, 14).map((x) => ({ tick: x[0], frame_ms: +x[1].toFixed(1), tick_ms: x[2][0], fx_ms: x[2][1], view_ms: x[2][2], particles: x[2][6], pt_us: Object.fromEntries(Object.keys(x[2][12] || {}).map((k) => [k, ((x[2][12][k] || 0) - ((x[3][12] || {})[k] || 0))])) }));
  result.hitches = raw.rtt.map((x, i) => [raw.tick - raw.rtt.length + i - 0, +x.toFixed(1)]).filter((h) => h[1] > 50).slice(0, 12);
  result.tick_ms = dist(col(0)); result.fx_ms = dist(col(1)); result.view_ms = dist(col(2));
  result.draws = dist(col(3)); result.objects = dist(col(4)); result.prims = dist(col(5)); result.particles = dist(col(6));
  result.video_mem_bytes = dist(col(7)); result.texture_mem_bytes = dist(col(8)); result.static_mem_bytes = dist(col(9));
  result.render_cpu_ms = dist(col(10)); result.render_gpu_ms = dist(col(11));
  // frame pacing (not the average): the worst 1%, the swing between consecutive frames, and spikes that come at a regular interval
  {
    const r = raw.rtt, n = r.length, med = pct(r, 0.5), sw = r.slice(1).map((x, i) => Math.abs(x - r[i]));
    const worst = [...r].sort((a, b) => b - a).slice(0, Math.max(1, Math.floor(n / 100)));
    const spikeT = med * 2 + 6;   // a frame that is more than twice the median and 6 ms over
    const idx = r.map((x, i) => (x > spikeT ? i : -1)).filter((i) => i >= 0);
    const gaps = idx.slice(1).map((v, i) => v - idx[i]);
    const hist = {}; for (const g of gaps) hist[g] = (hist[g] || 0) + 1;
    const top = Object.entries(hist).sort((a, b) => b[1] - a[1]).slice(0, 5).map(([g, c]) => [Number(g), c]);
    // a period: the most common gap that at least a third of the spikes repeat at (gaps within 1 frame count as the same)
    result.pacing = {
      frames: n, median: +med.toFixed(2), worst1pct_mean: +mean(worst).toFixed(2), worst1pct_min: +Math.min(...worst).toFixed(2), max: +Math.max(...r).toFixed(1),
      swing: dist(sw), swing_over_10: sw.filter((x) => x > 10).length, swing_over_16_7: sw.filter((x) => x > 16.7).length,
      over_16_7: r.filter((x) => x > 16.7).length, over_25: r.filter((x) => x > 25).length, over_33: r.filter((x) => x > 33.4).length, over_50: r.filter((x) => x > 50).length,
      spike_threshold_ms: +spikeT.toFixed(1), spikes: idx.length, spike_gap_top: top, first_spikes: idx.slice(0, 40).map((i) => [raw.tick - n + i, +r[i].toFixed(1)]),
      // the frames over 16.7 ms in blocks of 600 ticks (10 s at 60 Hz), to see a drift
      over_16_7_per_600: Array.from({ length: Math.ceil(n / 600) }, (_, b) => r.slice(b * 600, (b + 1) * 600).filter((x) => x > 16.7).length),
    };
  }
  // the turn scenes (hook-turn.mjs): the frames around each arena_turn event, in ticks -5 to +45
  try {
    const turns = JSON.parse(await page.eval('JSON.stringify(window.__turns || [])'));
    result.turnDebug = JSON.parse(await page.eval('JSON.stringify({ dbg: window.__dbg || null, asks: window.__asks || [], pick: window.__pick || null, bprof: window.__bprof || [], tprof: window.__tprof || [], bprof2: window.__bprof2 || [] })'));
    if (turns.length) {
      const base = raw.tick - raw.rtt.length;
      result.turns = turns;
      result.turnWindows = turns.map((t) => { const i0 = t - base; const sl = (a) => a.slice(Math.max(0, i0 - 5), i0 + 46); return { tick: t, frames: sl(raw.rtt).map((x) => +x.toFixed(1)), tick_ms: sl(raw.rows.map((r) => r[0])), fx_ms: sl(raw.rows.map((r) => r[1])), view_ms: sl(raw.rows.map((r) => r[2])), draws: sl(raw.rows.map((r) => r[3])), prims_k: sl(raw.rows.map((r) => Math.round(r[5] / 1000))) }; });
    }
  } catch { /* no turn scene */ }
  try { result.cull = JSON.parse(await page.eval('JSON.stringify(window.__cull || null)')); } catch { /* no cull hook */ }
  try { result.pbinfo = JSON.parse(await page.eval('JSON.stringify(window.__pbinfo || null)')); } catch { /* no pb scene */ }
  if (argv.includes('--save-rtt')) result.rtt = raw.rtt.map((x) => +x.toFixed(1));   // every frame time of the measured part, for an offline look at periods
  result.over_16_7 = raw.rtt.filter((x) => x > 16.7).length; result.over_25 = raw.rtt.filter((x) => x > 25).length;   // on a display-locked GPU run a frame is 16.7 or 33.3 ms: frames over 25 ms are the missed refreshes result.over_33_3 = raw.rtt.filter((x) => x > 33.3).length;
  result.tickReached = raw.tick;
  result.ticks_per_frame = +(raw.ticks / raw.frames).toFixed(3);   // 1 is one tick per animation frame, as in play
  const pts = raw.rows.map((r) => r[12]).filter(Boolean);   // the scratch profiling hook's per-frame component times (microseconds), when the export carries it
  // the hook's counters run up over the whole session (not reset per frame), so a frame's time is the difference of two consecutive readings
  if (pts.length > 1) { result.pt_ms = {}; for (const k of Object.keys(pts[pts.length - 1])) result.pt_ms[k] = dist(pts.slice(1).map((q, i) => ((q[k] || 0) - (pts[i][k] || 0)) / 1000)); }
  result.browserMemMB = browserMemoryMB(`cap-${slug(SESSION, 'nosession')}-framebench`);
  const duringAll = during.map((v) => mean(v)), duringCap = during.map((v) => mean(capCores(v)));
  const after = await sample(3000);
  result.loadDuring = { all: +mean(duringAll).toFixed(0), cap: +mean(duringCap).toFixed(0) };
  result.loadAfter = { all: +mean(after).toFixed(0), cap: +mean(capCores(after)).toFixed(0) };
  const bad = result.loadBefore.all > 60 || result.loadAfter.all > 60 || result.loadBefore.cap > 70 || result.loadAfter.cap > 70;
  result.valid = !bad;
  result.validity = bad ? 'INVALID: machine saturated before or after the run (all > 60% or capture cores > 70%); an upper bound only' : 'valid by the load rule';
} catch (e) {
  if (String(e.message) !== '__slice_done__') { result.failure = String(e.message || e); process.exitCode = 1; }
} finally {
  try { if (page) page.close(); } catch { /* gone */ }
  try { if (b) await b.close(); } catch { /* gone */ }
  server.close();
}
const text = JSON.stringify(result, null, 1);
if (OUT) { mkdirSync(dirname(resolve(OUT)), { recursive: true }); writeFileSync(OUT, text + '\n'); }
if (SLICE && result.slice) { console.log(`${LABEL} slice x${THROTTLE}: ${Object.entries(result.slice).map(([k, v]) => k + ' best ' + v.best_ms.toFixed(0) + ' ms').join(', ')} | load ${result.loadBefore?.all}/${result.loadAfter?.all}% ${result.validity}`); process.exit(0); }
console.log(`${LABEL} ${SCENE}${SLOTS ? '[' + SLOTS.length + ']' : ''} x${THROTTLE}: frame p50 ${result.frame_ms?.p50} p95 ${result.frame_ms?.p95} p99 ${result.frame_ms?.p99} max ${result.frame_ms?.max} ms | tick ${result.tick_ms?.p50} view ${result.view_ms?.p50} | draws ${result.draws?.p50} | particles ${result.particles?.p50} | load ${result.loadBefore?.all}/${result.loadDuring?.all}/${result.loadAfter?.all}% ${result.validity || result.failure}`);
