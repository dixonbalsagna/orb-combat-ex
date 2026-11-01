#!/usr/bin/env node
// The pre-play read (Performance and Platform, 2026-11-01; the EP's order): what a first playthrough costs on this PC's REAL GPU, from a fresh browser profile (a cold shader and file cache), with a scripted pad.
// Half 1 (this file): the guarded headless Chrome (tools/machine/browser.mjs: fresh profile each run, below-normal priority, a time limit, the session's name), NO software-GL flag, so WebGL is the machine's own GPU through ANGLE
// (the renderer string is recorded to prove it). It loads the page, connects a fake standard-mapping pad (the same one tools/preview/playtest.mjs uses), plays a seeded, repeatable pad script, and records from the first
// frame: every animation-frame time (own rAF loop at document start), the game's tick (window.__preview, ?preview=1) twice a second, and at the end the black box's replay (window.__bb_replay, if the page has it).
// Half 2 (replay_firsts.gd): runs that replay headless and prints the tick each kind of event first happens (beam, collapse, meteor ...); this file matches those ticks to its frame record (--firsts <file>).
//
//   node docs/perf/tools/preplay/preplay-read.mjs --url "http://127.0.0.1:8766/index.html?planet=7" --out <folder> [--seconds 90] [--start-at 36] [--script steps.json | --page-script scene.json] [--width 1280 --height 720] [--cores-cap 0]
//   node docs/perf/tools/preplay/preplay-read.mjs --report <folder> [--firsts <replay_firsts.json>]       (rebuild the plain-words report from a saved run; no browser)
//
// READ THE LIMITS: headless Chrome draws without the display's vsync, so a frame time here is the COST of the frame, not Opera's 240 Hz pacing; the first 60 s are measured on a fresh profile, which is what a first
// playthrough on a fresh browser is, but Orb's own Opera profile may already hold a shader cache. A run is VALID only on a quiet machine: CPU use over all logical processors is sampled for 3 s before and after;
// above 60% either time the run is marked invalid and its numbers are an upper bound. Opens no Godot window; the page is local (127.0.0.1); nothing is published or uploaded; the default pad script never leaves the page.
import { mkdirSync, readFileSync, writeFileSync, existsSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { Cdp, launchBrowser, browserExe, cpuLoad } from '../../../../tools/machine/browser.mjs';

const argv = process.argv.slice(2);
const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
const OUT = opt('--out') || opt('--report');
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const pct = (a, p) => { const s = [...a].sort((x, y) => x - y); return s.length ? s[Math.min(s.length - 1, Math.floor(s.length * p))] : NaN; };
const f1 = (x) => (Number.isFinite(x) ? x.toFixed(1) : 'n/a');

/** Frame times and the slow moments, from a saved run (also used by --report). */
export function summarise(run, firsts) {
  const t = run.frames;   // rAF timestamps, ms since the page's start
  const iv = [], at = [];
  for (let i = 1; i < t.length; i++) { iv.push(t[i] - t[i - 1]); at.push(t[i]); }
  const probe = run.probe;   // [[ms, tick], ...]
  const tickAt = (ms) => { let best = null; for (const p of probe) { if (p[1] >= 0 && p[0] <= ms) best = p; else if (p[0] > ms) break; } return best ? best[1] + Math.round((ms - best[0]) * 0.06) : -1; };   // 60 ticks a second between samples
  const firstPlay = probe.find((p) => p[1] > 0);   // the game's first running tick
  const t0 = run.startMs ? run.startMs : firstPlay ? firstPlay[0] : 0;   // the press on "I understand, start" when the driver made it, else the game's first running tick
  const noTick = !run.startMs && !firstPlay;   // "the first 60 s" count from the first tick, not from the page's download
  const win = (from, to) => { const a = []; for (let i = 0; i < iv.length; i++) if (at[i] >= from && at[i] < to) a.push(iv[i]); return a; };
  const stat = (a) => ({ n: a.length, median: pct(a, 0.5), p99: pct(a, 0.99), max: a.length ? Math.max(...a) : NaN, over33: a.filter((x) => x > 33.4).length, over50: a.filter((x) => x > 50).length, over100: a.filter((x) => x > 100).length });
  const first60 = stat(win(t0, t0 + 60000));
  const all = stat(iv);
  const all2 = iv.map((d, i) => ({ ms: d, atS: (at[i] - t0) / 1000, tick: tickAt(at[i]) }));
  const slow = all2.filter((x) => x.atS >= 0).sort((x, y) => y.ms - x.ms).slice(0, 15);   // in play
  const loadSlow = all2.filter((x) => x.atS < 0).sort((x, y) => y.ms - x.ms).slice(0, 6);   // before the press on start: the page's own loading
  const wins = [];
  for (let s = 0; s * 10000 < Math.max(0, (t[t.length - 1] || 0) - t0); s++) { const w = stat(win(t0 + s * 10000, t0 + (s + 1) * 10000)); wins.push({ from: s * 10, to: s * 10 + 10, median: w.median, p99: w.p99, max: w.max }); }
  const marks = [];
  if (firsts) {
    const want = [['beam', /beam/i], ['collapse', /collaps|crumble|topple|fall/i], ['meteor', /meteor/i], ['crater', /crater/i], ['clash', /clash/i]];
    const names = [...Object.entries(firsts.fx || {}).map(([k, v]) => ({ kind: 'fx', k, ...v })), ...Object.entries(firsts.feed || {}).map(([k, v]) => ({ kind: 'feed', k, ...v }))];
    for (const [label, re] of want) {
      const hit = names.filter((n) => re.test(n.k)).sort((a, b) => a.first - b.first)[0];
      if (!hit) { marks.push({ label, found: false }); continue; }
      // the slowest frame within 1.0 s of the event's tick (60 ticks)
      const near = iv.map((d, i) => ({ ms: d, tick: tickAt(at[i]), atS: (at[i] - t0) / 1000 })).filter((x) => x.tick >= hit.first - 6 && x.tick <= hit.first + 60).sort((a, b) => b.ms - a.ms)[0];
      marks.push({ label, found: true, via: `${hit.kind} "${hit.k}"`, tick: hit.first, worstFrameMs: near ? near.ms : NaN, atS: near ? near.atS : NaN });
    }
  }
  return { first60, all, slow, loadSlow, wins, marks, t0s: t0 / 1000, noTick };
}

export function plainWords(run, S) {
  const L = [];
  L.push(`Pre-play read, ${run.when}. Page ${run.url}`);
  L.push(`Browser: ${run.machine.ua}`);
  L.push(`Graphics: ${run.machine.renderer} (${run.machine.software ? 'SOFTWARE: not a real-GPU reading' : 'real GPU'}); fresh profile; ${run.machine.cores} logical processors; window ${run.machine.win}.`);
  L.push(`Machine load before / after: ${run.loadBefore}% / ${run.loadAfter}%. ${run.valid ? 'VALID (quiet machine).' : 'INVALID: the machine was busy, these numbers are an upper bound and must not be compared with a budget.'}`);
  L.push(`Frames are drawn without the display's vsync here, so a frame time is the cost of that frame, not Opera's 240 Hz pacing.`);
  L.push('');
  if (S.noTick) L.push('WARNING: the page never published a game tick (window.__preview): the game had not started when the run ended, or the page has no ?preview=1 probe. The numbers below count from the page start and include loading.');
  L.push(`First 60 s of play (from the game's first tick, at ${S.t0s.toFixed(1)} s after the page started): ${S.first60.n} frames, median ${f1(S.first60.median)} ms, 99th percentile ${f1(S.first60.p99)} ms, worst ${f1(S.first60.max)} ms; ${S.first60.over33} frames over 33 ms, ${S.first60.over50} over 50 ms, ${S.first60.over100} over 100 ms.`);
  L.push(`Whole run: ${S.all.n} frames, median ${f1(S.all.median)}, p99 ${f1(S.all.p99)}, worst ${f1(S.all.max)} ms.`);
  L.push('');
  L.push('Ten-second slices (median / p99 / worst ms):');
  for (const w of S.wins) L.push(`  ${String(w.from).padStart(3)}-${String(w.to).padEnd(3)} s   ${f1(w.median)} / ${f1(w.p99)} / ${f1(w.max)}`);
  L.push('');
  L.push('The 15 slowest frames in play (ms, seconds into play, game tick):');
  for (const s of S.slow) L.push(`  ${f1(s.ms).padStart(7)} ms   at ${s.atS.toFixed(1)} s   tick ${s.tick}`);
  if (S.loadSlow.length && S.loadSlow[0].atS < 0) { L.push(''); L.push('Before play (the page loading and compiling, before Start was pressed): the 6 longest freezes: ' + S.loadSlow.map((x) => `${f1(x.ms)} ms at ${(x.atS).toFixed(1)} s`).join(', ') + '.'); }
  if (S.marks.length) {
    L.push('');
    L.push('First time each thing happened (event tick from the replay) and the slowest frame within a second after it:');
    for (const m of S.marks) L.push(m.found ? `  ${m.label.padEnd(9)} tick ${m.tick} (${m.via}): worst frame ${f1(m.worstFrameMs)} ms at ${f1(m.atS)} s` : `  ${m.label.padEnd(9)} did not happen in this run`);
  }
  return L.join('\n');
}

if (argv.includes('--report')) {
  const run = JSON.parse(readFileSync(join(resolve(OUT), 'preplay.json'), 'utf8'));
  const fp = opt('--firsts');
  const S = summarise(run, fp && existsSync(fp) ? JSON.parse(readFileSync(fp, 'utf8')) : null);
  const txt = plainWords(run, S);
  writeFileSync(join(resolve(OUT), 'preplay.txt'), txt);
  console.log(txt);
  process.exit(0);
}

const URL0 = opt('--url');
if (!URL0 || !OUT) { console.error('usage: preplay-read.mjs --url <page> --out <folder> [--seconds 90] [--script steps.json] | --report <folder> [--firsts f.json]'); process.exit(2); }
const SECONDS = Number(opt('--seconds', 90)), W = Number(opt('--width', 1280)), H = Number(opt('--height', 720)), CAP = Number(opt('--cores-cap', 0));
const URL = `${URL0}${URL0.includes('?') ? '&' : '?'}preview=1`;   // the probe word (tick, hit points); the page is otherwise as a person gets it
mkdirSync(resolve(OUT), { recursive: true });

// A seeded, repeatable pad script (mulberry32): connect, take player 1 with A, then every 0.5 s a stick direction and a button from the set a fighter uses. Steps: {at: ms since the page start, do: 'connect'|'tap'|'stick', button, axes}.
const mul = (a) => () => { a |= 0; a = (a + 0x6D2B79F5) | 0; let t = Math.imul(a ^ (a >>> 15), 1 | a); t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t; return ((t ^ (t >>> 14)) >>> 0) / 4294967296; };
function defaultScript(seconds) {
  const START = Number(opt('--start-at', 0)) * 1000;   // press "I understand, start" at this time (the page needs ~25-35 s to load); 0 = never (the page sits on its card)
  const r = mul(20261101), s = [{ at: 2000, do: 'connect' }];
  if (START) s.push({ at: START, do: 'click', x: 640, y: 503 });   // the card's start button with 1 player (the default)
  const pads = [0, 1, 2, 3, 4, 5, 6, 7];   // face buttons, bumpers, triggers (standard mapping)
  for (let at = (START || 12000) + 5000; at < seconds * 1000; at += 500) {
    const a = r() * Math.PI * 2, m = r() < 0.7 ? 1 : 0;
    s.push({ at, do: 'stick', axes: [Math.cos(a) * m, Math.sin(a) * m * 0.6, 0, 0] });
    if (r() < 0.8) s.push({ at: at + 120, do: 'tap', button: pads[Math.floor(r() * pads.length)], hold: 120 + Math.floor(r() * 500) });
  }
  return s;
}
const WSCRIPT = opt('--page-script');   // a ?script=1 scene (Tools' clip format: {scene, events:[[tick, op, a, b]...]}) handed to the page as window.__script; the page then plays it through its real input path
const steps = WSCRIPT ? [{ at: 2000, do: 'connect' }, ...(Number(opt('--start-at', 0)) ? [{ at: Number(opt('--start-at', 0)) * 1000, do: 'click', x: 640, y: 503 }] : [])] : (opt('--script') ? JSON.parse(readFileSync(opt('--script'), 'utf8')) : defaultScript(SECONDS)).sort((a, b) => a.at - b.at);

const PAGE_SIDE = `
(() => {
  const st = { connected: false, buttons: Array.from({ length: 17 }, () => ({ pressed: false, touched: false, value: 0 })), axes: [0, 0, 0, 0], ts: 0 };
  window.__pad = st;
  const pad = () => ({ id: 'Xbox 360 Controller (STANDARD GAMEPAD Vendor: 045e Product: 028e)', index: 0, connected: true, mapping: 'standard', timestamp: ++st.ts, buttons: st.buttons, axes: st.axes, vibrationActuator: null });
  navigator.getGamepads = () => (st.connected ? [pad(), null, null, null] : [null, null, null, null]);
  window.__padConnect = () => { st.connected = true; const ev = new Event('gamepadconnected'); ev.gamepad = pad(); window.dispatchEvent(ev); };
  window.__padSet = (b, d) => { st.buttons[b] = { pressed: !!d, touched: !!d, value: d ? 1 : 0 }; };
  window.__padAxes = (a) => { st.axes = a.slice(); };
  const fr = []; window.__fr = fr;
  const loop = (ts) => { fr.push(ts); requestAnimationFrame(loop); };   // our own loop beside the game's: the time between its callbacks is the browser's frame interval
  requestAnimationFrame(loop);
  const pr = []; window.__pr = pr;
  let last = ''; setInterval(() => { const p = window.__preview; const ex = p ? JSON.stringify({ hp: p.hp, ko: p.ko, fst: p.fst, ln: p.ln, swing: p.swing && p.swing.on }) : ''; const row = [performance.now(), p && typeof p.tick === 'number' ? p.tick : -1]; if (ex !== last) { row.push(ex); last = ex; } pr.push(row); }, 100);
})();`;

const exe = browserExe('chrome');
const T0 = Date.now(), say = (m) => console.log(`[preplay ${((Date.now() - T0) / 1000).toFixed(1)}s] ${m}`);
let browser = null, page = null, code = 0;
const run = { when: new Date().toISOString(), url: URL, seconds: SECONDS, capCores: CAP, steps: steps.length };
try {
  run.loadBefore = Math.round(await cpuLoad(3000)); say('load before ' + run.loadBefore);
  browser = await launchBrowser({ exe, flags: [`--window-size=${W},${H}`], session: process.env.MERIDIAN_SESSION || 'meridian-performance-platform', purpose: 'preplay', timeoutS: SECONDS + 240, cpuPercent: CAP, priority: 'belownormal', log: (m) => console.log(`[preplay] ${m}`) });
  say('browser up'); page = await Cdp.open(browser.target.webSocketDebuggerUrl); say('cdp open');
  await page.send('Emulation.setDeviceMetricsOverride', { width: W, height: H, deviceScaleFactor: 1, mobile: false });
  await page.send('Page.enable'); await page.send('Runtime.enable'); say('enabled');
  const errors = [];
  page.ws.addEventListener('message', (ev) => { try { const m = JSON.parse(ev.data); if (m.method === 'Runtime.exceptionThrown') errors.push(String(m.params.exceptionDetails.text).slice(0, 200)); } catch { /* not json */ } });
  await page.send('Page.addScriptToEvaluateOnNewDocument', { source: PAGE_SIDE + (WSCRIPT ? `
window.__script = ${JSON.stringify(readFileSync(WSCRIPT, 'utf8'))};` : '') }); say('script added');
  await page.send('Page.navigate', { url: URL });
  say('navigated');
  const t0 = Date.now();
  for (const s of steps) {
    const wait = s.at - (Date.now() - t0);
    if (wait > 0) await sleep(wait);
    if (Date.now() - t0 > SECONDS * 1000) break;
    if (s.do === 'connect') say('pad connect');
    if (s.do === 'connect') await page.eval('window.__padConnect()', true);
    else if (s.do === 'stick') await page.eval(`window.__padAxes(${JSON.stringify(s.axes)})`, true);
    else if (s.do === 'click') { for (const type of ['mouseMoved', 'mousePressed', 'mouseReleased']) { await page.send('Input.dispatchMouseEvent', { type, x: s.x, y: s.y, button: 'left', buttons: type === 'mousePressed' ? 1 : 0, clickCount: 1 }); await sleep(80); } say(`click ${s.x},${s.y}`); if (!run.startMs) run.startMs = await page.eval('performance.now()'); }
    else if (s.do === 'shot') { const sh = await page.send('Page.captureScreenshot', { format: 'png' }); writeFileSync(join(resolve(OUT), `shot-${s.name || s.at}.png`), Buffer.from(sh.data, 'base64')); }
    else if (s.do === 'tap') { await page.eval(`window.__padSet(${s.button}, true)`, true); setTimeout(() => { page.eval(`window.__padSet(${s.button}, false)`, true).catch(() => {}); }, s.hold || 200); }
  }
  say('script done, reading the record');
  const rest = SECONDS * 1000 - (Date.now() - t0);
  if (rest > 0) await sleep(rest);
  await page.eval('window.__padAxes([0,0,0,0])', true);
  say('reading machine');
  run.machine = JSON.parse(await page.eval(`(() => { const c = document.createElement('canvas'); const g = c.getContext('webgl2') || c.getContext('webgl'); const e = g && g.getExtension('WEBGL_debug_renderer_info'); const r = e ? g.getParameter(e.UNMASKED_RENDERER_WEBGL) : 'unknown'; return JSON.stringify({ ua: navigator.userAgent, cores: navigator.hardwareConcurrency, win: innerWidth + 'x' + innerHeight, renderer: r, software: /swiftshader|llvmpipe|software/i.test(r) }); })()`));
  say('reading frames');
  run.frames = JSON.parse(await page.eval('JSON.stringify(window.__fr)'));
  run.probe = JSON.parse(await page.eval('JSON.stringify(window.__pr)'));
  run.globals = JSON.parse(await page.eval('JSON.stringify(Object.keys(window).filter((k) => /^__/.test(k)))'));
  run.ps = JSON.parse(await page.eval('JSON.stringify(window.__ps || null)') || 'null');
  run.bbState = JSON.parse(await page.eval('JSON.stringify(window.__bb_state || null)') || 'null');
  run.preview = JSON.parse(await page.eval('JSON.stringify(window.__preview || null)') || 'null');
  const bb = await page.eval('window.__bb_replay || ""');
  if (bb) { writeFileSync(join(resolve(OUT), 'replay.json'), typeof bb === 'string' ? bb : JSON.stringify(bb)); run.replay = true; } else run.replay = false;
  run.pageErrors = errors.slice(0, 10);
  try { await page.send('Page.captureScreenshot', { format: 'png' }).then((s) => writeFileSync(join(resolve(OUT), 'last.png'), Buffer.from(s.data, 'base64'))); } catch { /* optional */ }
} catch (e) { console.log(`[preplay] FAILED: ${e.message}`); run.error = e.message; code = 1; }
finally { try { if (page) page.close(); } catch { /* gone */ } try { if (browser) await browser.close(); } catch { /* gone */ } }
if (code === 0) {
  run.loadAfter = Math.round(await cpuLoad(3000));
  run.valid = run.loadBefore <= 60 && run.loadAfter <= 60 && !run.machine.software;
}
writeFileSync(join(resolve(OUT), 'preplay.json'), JSON.stringify(run));
if (code === 0) { const S = summarise(run, null); const txt = plainWords(run, S); writeFileSync(join(resolve(OUT), 'preplay.txt'), txt); console.log(txt); console.log(run.replay ? '\nreplay.json saved: run replay_firsts.gd on it, then --report with --firsts.' : '\nNo window.__bb_replay on this page: the beam/collapse/meteor ticks need another route (the page has no black box).'); }
process.exit(code);
