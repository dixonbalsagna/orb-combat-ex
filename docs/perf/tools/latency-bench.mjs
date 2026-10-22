#!/usr/bin/env node
// Input-to-screen latency of the web build: from a real browser key event to the first changed picture, for a light, a dash (the dodge key) and a guard. Node 24 built-ins only; the
// browser comes from tools/machine/browser.mjs (guarded launcher). Needs a scratch export built with the `lat` variant of make-audit-sites.mjs (hook-latency.mjs). Owner: Performance and Platform.
//
//   node docs/perf/tools/latency-bench.mjs --site <built site> --label base [--igpu] [--throttle 4] [--trials 20] [--actions light,dash,guard] [--pace60] [--out run.json]
//
// A trial = a new `lat` match (the hook's scene: player one on the keyboard, the idle dummy 250 units away), a throwaway key press that claims the slot, a random wait (so the press lands
// at a random phase of the frame), then ONE press (light: J, dash: Space, guard: Shift held 500 ms) sent through Chrome's real input path (Input.dispatchKeyEvent), then the records
// the hook kept: the DOM keydown time, the frame and tick in which the game's _unhandled_input got it, the player's action state after every tick, and, per drawn frame, how much the
// picture changed. From these (all in the page's own clock):
//   browser_ms      DOM keydown to the game's handler               (the browser and Godot's web input queue)
//   wait_ticks      the tick the press waited for: handler tick+1 is 0                                   (host reads edges at the start of the tick)
//   sim_ticks       from the handler to the first tick whose action state differs (0 = the next tick)    (the sim's own share; the press_ack mark counts as a reaction too)
//   draw_frames     from the frame that ran that tick to the first frame whose picture changed beyond the idle noise (0 = the same frame)   (the render: interpolation and the draw)
//   total_ms        DOM keydown to the END of the first frame whose picture changed (the start of the next frame): button contact to the browser's canvas, excluding the browser's
//                   compositor and the display (about one display frame more on a real screen; headless cannot see it)
//   total_frames    the same as a count of frames from the handler's frame
import { mkdirSync, writeFileSync } from 'node:fs';
import { cpus } from 'node:os';
import { dirname, resolve } from 'node:path';
import { Cdp, launchBrowser, serve, browserExe, slug } from '../../../tools/machine/browser.mjs';

const argv = process.argv.slice(2);
const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
const SITE = opt('--site'), LABEL = opt('--label', 'run'), THROTTLE = Number(opt('--throttle', 1)), TRIALS = Number(opt('--trials', 20));
const ACTIONS = opt('--actions', 'light,dash,guard').split(',');
const W = Number(opt('--width', 1280)), H = Number(opt('--height', 720));
const SESSION = opt('--session', process.env.MERIDIAN_SESSION || 'meridian-performance-platform');
const TIME_LIMIT = Number(opt('--time-limit', 1500));
const HOLD = opt('--hold') === undefined ? null : Number(opt('--hold'));
const OUT = opt('--out'), IGPU = argv.includes('--igpu'), PACE = argv.includes('--pace60'), RAW = argv.includes('--raw');
if (!SITE) { console.error('usage: node docs/perf/tools/latency-bench.mjs --site <built site> --label <name> [--igpu] [--throttle N] [--trials N] [--out file.json]'); process.exit(2); }
const exe = opt('--browser-path') || browserExe('chrome');
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const read = () => cpus().map((c) => { const t = c.times; return { total: t.user + t.nice + t.sys + t.idle + t.irq, idle: t.idle }; });
const use = (a, b) => a.map((x, i) => { const dt = b[i].total - x.total; return dt > 0 ? 100 * (1 - (b[i].idle - x.idle) / dt) : 0; });
const mean = (v) => (v.length ? v.reduce((s, x) => s + x, 0) / v.length : 0);
const sample = async (ms) => { const a = read(); await sleep(ms); return use(a, read()); };
const capCores = (v) => v.slice(Math.floor(v.length * 0.75));
const pct = (arr, p) => { if (!arr.length) return null; const s = [...arr].sort((x, y) => x - y); return s[Math.min(s.length - 1, Math.max(0, Math.ceil(p * s.length) - 1))]; };
const dist = (a) => (a.length ? { n: a.length, mean: +mean(a).toFixed(2), p50: +pct(a, 0.5).toFixed(2), p95: +pct(a, 0.95).toFixed(2), max: +Math.max(...a).toFixed(2) } : null);

const KEYS = { light: { code: 'KeyJ', key: 'j', vk: 74, hold: 90 }, dash: { code: 'Space', key: ' ', vk: 32, hold: 90 }, guard: { code: 'ShiftLeft', key: 'Shift', vk: 16, hold: 500 } };

function analyse(action, d, domTimes) {
  const K = KEYS[action];
  const wantCode = action === 'guard' ? 'Shift' : action === 'dash' ? 'Space' : 'KeyJ';
  const kd = d.keys.find((k) => k[3] === wantCode && k[4] === true);
  if (!kd) return { error: 'the game never received the key' };
  const [kt0, kf, kticks] = kd; const off = d.off || 0; const kt = kt0 + off;
  const dom = domTimes.find((x) => x[1] === K.code && x[2] === 'keydown');
  const ticks = d.ticks, frames = d.frames;
  // the state before the press: the last tick row recorded before the handler's tick
  const before = [...ticks].reverse().find((t) => t[0] < kticks) || ticks[0];
  const sig = (t) => [t[3], t[4], t[5], t[6] >= 0, t[7], t[9], t[8] !== 0].join('|');
  const base = before ? sig(before) : '';
  const react = ticks.find((t) => t[0] >= kticks && sig(t) !== base);
  const out = { dom_to_handler_ms: dom ? +(kt - dom[0]).toFixed(2) : null, handler_frame: kf, handler_tick: kticks };
  if (!react) { out.error = 'the sim never changed player one\'s action state'; out.base = base; return out; }
  out.sim_react_tick = react[0]; out.sim_ticks = react[0] - kticks; out.react_state = sig(react); out.base_state = base;
  // the first frame that ran the reacting tick
  const simFrame = frames.find((f) => f[2] >= react[0] + 1);
  out.sim_frame = simFrame ? simFrame[0] : null;
  // idle noise: the picture change in the 40 frames before the press
  const pre = frames.filter((f) => f[0] < kf && f[0] >= kf - 40 && f.length > 5 && f[5] >= 0).map((f) => f[5]);
  const m = mean(pre), sd = Math.sqrt(mean(pre.map((x) => (x - m) ** 2)));
  const mx = pre.length ? Math.max(...pre) : 0; const thr = Math.max(m + 5 * sd, mx * 1.25, m + 0.05);
  out.noise = { mean: +m.toFixed(3), sd: +sd.toFixed(3), thr: +thr.toFixed(3) };
  const px = frames.find((f) => f[0] >= kf && f.length > 5 && f[5] > thr);
  if (!px) { out.error = 'no picture change beyond the idle noise'; return out; }
  out.px_frame = px[0]; out.px_value = px[5];
  const next = frames.find((f) => f[0] === px[0] + 1);
  out.draw_frames = simFrame ? px[0] - simFrame[0] : null;
  out.total_frames = px[0] - kf;
  out.total_ms = next && dom ? +(next[1] + off - dom[0]).toFixed(2) : (next ? +(next[1] + off - kt).toFixed(2) : null);
  out.wait_ticks_state = null;
  // the frame times around the press, for context
  out.frame_ms_around = frames.filter((f) => f[0] >= kf - 2 && f[0] <= px[0] + 1).map((f, i, a) => (i ? +(f[1] - a[i - 1][1]).toFixed(1) : null)).filter((x) => x !== null);
  return out;
}

const server = await serve(SITE);
const url = `http://127.0.0.1:${server.address().port}/play/index.html?flashcap=1${PACE ? '&lat60=1' : ''}${opt('--page-args') ? '&' + opt('--page-args') : ''}`;
let b, page;
const result = { label: LABEL, igpu: IGPU, throttle: THROTTLE, pace60: PACE, trials: TRIALS, viewport: `${W}x${H}`, session: SESSION, node: process.version, actions: {} };
try {
  const before = await sample(3000);
  result.loadBefore = { all: +mean(before).toFixed(0), cap: +mean(capCores(before)).toFixed(0) };
  b = await launchBrowser({
    exe, session: SESSION, purpose: 'latency', timeoutS: TIME_LIMIT, log: () => {},
    flags: [`--window-size=${W},${H}`, '--disable-gpu-vsync', '--disable-frame-rate-limit', '--disable-background-timer-throttling', '--disable-renderer-backgrounding', '--disable-backgrounding-occluded-windows', ...(IGPU ? ['--force_low_power_gpu'] : [])],
  });
  page = await Cdp.open(b.target.webSocketDebuggerUrl);
  await page.send('Page.enable');
  await page.send('Emulation.setDeviceMetricsOverride', { width: W, height: H, deviceScaleFactor: 1, mobile: false });
  await page.send('Page.navigate', { url });
  let ready = false;
  while (Date.now() < b.deadlineMs && !ready) { await sleep(500); ready = Boolean(await page.eval('!!(window.__flashcap && window.__flashcap.ready)').catch(() => false)); }
  if (!ready) throw new Error('the page never offered window.__flashcap.ready');
  result.gpu = await page.eval(`(() => { try { const gl = document.createElement('canvas').getContext('webgl2'); const e = gl.getExtension('WEBGL_debug_renderer_info'); return gl.getParameter(e.UNMASKED_RENDERER_WEBGL); } catch (e) { return String(e); } })()`);
  if (IGPU && !/AMD|Radeon/i.test(result.gpu)) throw new Error('--igpu asked for the integrated GPU but the page reports ' + result.gpu);
  if (THROTTLE !== 1) await page.send('Emulation.setCPUThrottlingRate', { rate: THROTTLE });
  await page.eval(`window.__dom = []; for (const t of ['keydown', 'keyup']) window.addEventListener(t, (e) => window.__dom.push([e.timeStamp, e.code, t, performance.now()]), true);`);
  const key = async (K, down) => page.send('Input.dispatchKeyEvent', { type: down ? 'keyDown' : 'keyUp', code: K.code, key: K.key, windowsVirtualKeyCode: K.vk, nativeVirtualKeyCode: K.vk });
  const dump = async () => { await page.eval('window.__latdump = null; window.__latcmd = "dump"'); for (let i = 0; i < 200; i++) { await sleep(50); const r = await page.eval('window.__latdump ? JSON.stringify(window.__latdump) : null'); if (r) return JSON.parse(r); } throw new Error('no dump'); };
  const rnd = (a, c) => a + Math.floor(Math.random() * (c - a));
  for (const action of ACTIONS) {
    const rows = [];
    for (let i = 0; i < TRIALS && Date.now() < b.deadlineMs - 20000; i++) {
      await page.eval(`window.__flashcap.start('lat', { reduced: true })`);
      await sleep(1500);
      await key({ code: 'KeyE', key: 'e', vk: 69 }, true); await sleep(60); await key({ code: 'KeyE', key: 'e', vk: 69 }, false);   // the throwaway press: claims player one
      await sleep(900);
      await dump();
      await page.eval('window.__dom = []');
      await sleep(rnd(300, 700));
      const K = { ...KEYS[action], ...(HOLD === null ? {} : { hold: HOLD }) };
      await key(K, true); await sleep(K.hold); await key(K, false);
      await sleep(700);
      const d = await dump();
      const dom = JSON.parse(await page.eval('JSON.stringify(window.__dom)'));
      const a = analyse(action, d, dom);
      a.n_frames = d.frames.length;
      if (RAW && i === 0) a.raw = { keys: d.keys, ticks: d.ticks.slice(-90), frames: d.frames.slice(-60), dom };
      rows.push(a);
    }
    const ok = rows.filter((r) => !r.error);
    result.actions[action] = {
      trials: rows.length, ok: ok.length, errors: rows.filter((r) => r.error).map((r) => r.error),
      browser_ms: dist(ok.map((r) => r.dom_to_handler_ms).filter((x) => x !== null)),
      sim_ticks: dist(ok.map((r) => r.sim_ticks)), draw_frames: dist(ok.filter((r) => r.draw_frames !== null).map((r) => r.draw_frames)),
      total_frames: dist(ok.map((r) => r.total_frames)), total_ms: dist(ok.map((r) => r.total_ms).filter((x) => x !== null)),
      over_3_frames: ok.filter((r) => r.total_frames > 3).length,
      rows,
    };
    const s = result.actions[action];
    console.log(`${LABEL} ${action}: ok ${s.ok}/${s.trials} | browser ${s.browser_ms ? s.browser_ms.p50 : '-'} ms | sim ticks p50 ${s.sim_ticks?.p50} max ${s.sim_ticks?.max} | draw frames p50 ${s.draw_frames?.p50} max ${s.draw_frames?.max} | total frames p50 ${s.total_frames?.p50} p95 ${s.total_frames?.p95} max ${s.total_frames?.max} | total ms p50 ${s.total_ms?.p50} p95 ${s.total_ms?.p95} max ${s.total_ms?.max}`);
  }
  const after = await sample(3000);
  result.loadAfter = { all: +mean(after).toFixed(0), cap: +mean(capCores(after)).toFixed(0) };
  const bad = result.loadBefore.all > 60 || result.loadAfter.all > 60 || result.loadBefore.cap > 70 || result.loadAfter.cap > 70;
  result.valid = !bad;
  result.validity = bad ? 'INVALID: machine saturated before or after the run; an upper bound only' : 'valid by the load rule';
} catch (e) {
  result.failure = String(e.message || e); process.exitCode = 1; console.error(result.failure);
} finally {
  try { if (page) page.close(); } catch { /* gone */ }
  try { if (b) await b.close(); } catch { /* gone */ }
  server.close();
}
if (OUT) { mkdirSync(dirname(resolve(OUT)), { recursive: true }); writeFileSync(OUT, JSON.stringify(result, null, 1) + '\n'); }
console.log(`${LABEL} latency x${THROTTLE}${IGPU ? ' igpu' : ''}${PACE ? ' pace60' : ''}: ${result.valid === undefined ? 'FAILED' : result.validity}`);
