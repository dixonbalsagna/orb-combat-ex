// Pad lab self-test:  node tools/padlab/padlab-selftest.mjs     (exit code 0 = pass; the last line is "padlab self-test ok" or "FAILED")
//   (a) core.js on synthetic data, (b) a scan of index.html and core.js for anything that could send data, (c) serve.mjs,
//   (d) the page itself in headless Chrome with FAKE gamepads (started only through tools/machine/browser.mjs: one browser, below-normal priority, a time limit).
// If no browser can be launched the browser part says so and is skipped; the other parts still decide pass or fail.
import { readFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { startServer } from './serve.mjs';

const here = dirname(fileURLToPath(import.meta.url));
const require = createRequire(import.meta.url);
const C = require('./core.js');
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const failures = [];
let checks = 0;
const check = (cond, msg) => { checks++; if (!cond) { failures.push(msg); console.log('  FAIL: ' + msg); } };
const near = (a, b, tol, msg) => check(Number.isFinite(a) && Math.abs(a - b) <= tol, `${msg}: got ${typeof a === 'number' ? a.toFixed(4) : a}, expected ${b} +- ${tol}`);
const section = (s) => console.log(s);

// a small seeded generator, so the test is the same every run
function rng(seed) {
  let a = seed >>> 0;
  const u = () => { a = (a + 0x6d2b79f5) >>> 0; let t = a; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; };
  const g = () => { let x = 0; while (x === 0) x = u(); return Math.sqrt(-2 * Math.log(x)) * Math.cos(2 * Math.PI * u()); };
  return { u, g };
}
const FRAME = 1000 / 60;

// ---------------------------------------------------------------- (a) core.js on synthetic data
function unitTests() {
  section('(a) core.js on synthetic data');
  // rest: known offset and noise
  {
    const r = rng(1);
    const S = [];
    for (let i = 0; i < 180; i++) S.push({ t: i * FRAME, x: 0.03 + (r.u() - 0.5) * 0.02, y: -0.02 + (r.u() - 0.5) * 0.02 });
    const q = C.restStats(S);
    near(q.offset.x, 0.03, 0.003, 'rest offset x'); near(q.offset.y, -0.02, 0.003, 'rest offset y');
    const worst = Math.max(...S.map((s) => Math.hypot(s.x, s.y)));
    const expect = Math.max(0.05, Math.ceil(worst * 1.5 * 100 - 1e-9) / 100);
    near(q.deadzone, expect, 1e-9, 'rest dead zone (noise ceiling x 1.5, rounded up to 0.01)');
    check(q.noise.std > 0.003 && q.noise.std < 0.01, 'rest noise std in range: ' + q.noise.std);
    near(q.drift.mag, 0, 0.004, 'no drift in a steady rest cloud');
    // a clean stick is held to the 0.05 floor
    const clean = []; for (let i = 0; i < 60; i++) clean.push({ t: i * FRAME, x: 0.001 * r.g(), y: 0.001 * r.g() });
    near(C.restStats(clean).deadzone, 0.05, 1e-9, 'dead zone floor');
    // slow drift of 0.02 over 3 s: the mean of the last second minus the first second is about 0.0133
    const drift = []; for (let i = 0; i < 180; i++) drift.push({ t: i * FRAME, x: 0.02 * (i / 180), y: 0 });
    near(C.restStats(drift).drift.x, 0.0133, 0.003, 'drift between first and last second');
  }
  // flicks: known 10%-90% time (80 ms), known release and overshoot (0.2), known spring-back (175 ms)
  {
    const p = (tau) => (tau < 0 ? 0 : tau < 100 ? tau / 100 : tau < 160 ? 1 : tau < 210 ? 1 - (tau - 160) / 50 : tau < 250 ? -0.2 * (tau - 210) / 40 : tau < 350 ? -0.2 * (1 - (tau - 250) / 100) : 0);
    for (const phase of [0, 5, 11]) {
      const r = rng(7 + phase);
      const dirx = Math.cos(0.5), diry = -Math.sin(0.5);
      const S = [];
      for (let t = -120 + phase; t < 700; t += FRAME) S.push({ t, x: 0.02 + dirx * p(t) + 0.003 * r.g(), y: 0.01 + diry * p(t) + 0.003 * r.g() });
      const q = C.flickStats(S, { rest: { x: 0.02, y: 0.01, band: 0.02 } });
      check(q.ok, 'flick measured (phase ' + phase + '): ' + (q.reason || ''));
      if (!q.ok) continue;
      near(q.riseMs, 80, FRAME, 'flick rise 10-90% (phase ' + phase + ')');
      near(q.springMs, 175, FRAME, 'flick spring-back (phase ' + phase + ')');
      near(q.overshoot, 0.2, 0.03, 'flick overshoot share (phase ' + phase + ')');
      near(q.peak, 1, 0.02, 'flick peak');
      check(q.settled, 'flick settled');
    }
    // a stick held at the end is not a measurable flick
    const held = []; for (let t = 0; t < 400; t += FRAME) held.push({ t, x: Math.min(1, t / 100), y: 0 });
    check(!C.flickStats(held).ok, 'a flick that is never let go is refused');
    check(!C.flickStats([{ t: 0, x: 0.05, y: 0 }, { t: 16, x: 0.06, y: 0 }, { t: 33, x: 0.05, y: 0 }, { t: 50, x: 0.05, y: 0 }]).ok, 'a tiny push is refused');
  }
  // aim: known bias and spread, samples below the magnitude limit ignored, wrap-around at left
  {
    const r = rng(3);
    const angles = [90, 45, 0, -45, -90, -135, 180, 135];
    const S = [];
    angles.forEach((a, i) => {
      const bias = i === 2 ? 10 : 3;
      for (let k = 0; k < 60; k++) { const th = ((a + bias + 2 * r.g()) * Math.PI) / 180; S.push({ t: k * FRAME, x: 0.9 * Math.cos(th), y: -0.9 * Math.sin(th), dir: i }); }
      for (let k = 0; k < 10; k++) S.push({ t: k * FRAME, x: 0.3, y: 0.3, dir: i });   // below 0.7: not counted
    });
    const q = C.aimStats(S, angles, { minMag: 0.7 });
    check(q.ok && q.n === 480, 'aim counted only the strong samples: ' + q.n);
    near(q.spreadDeg, 2, 0.35, 'aim spread');
    near(q.perDir[0].meanErr, 3, 0.8, 'aim mean error up'); near(q.perDir[6].meanErr, 3, 0.8, 'aim mean error left (wrap-around)');
    near(q.perDir[2].meanErr, 10, 1, 'aim mean error right (biased)');
    check(q.worst.index === 2, 'worst direction is right: ' + q.worst.index);
    // without dir the nearest nominal angle is used
    const q2 = C.aimStats(S.map(({ t, x, y }) => ({ t, x, y })), angles, { minMag: 0.7 });
    near(q2.spreadDeg, q.spreadDeg, 0.01, 'aim without dir indexes');
  }
  // recommend: same units as data/input/timing.json
  {
    const rec = C.recommend({ rest: { ok: true, deadzone: 0.12 }, rise: { n: 3, median: 81.6 }, spring: { n: 3, median: 176 }, aim: { ok: true, spreadDeg: 2.1 } });
    check(rec.deadzone === 0.12 && rec.awayDead >= 0.18 && rec.triggerOn === 0.35 && rec.triggerOff === 0.25 && rec.flickRiseMs === 82 && rec.aimToleranceDeg === 5 && rec.isSuggestion, 'recommend: ' + JSON.stringify(rec));
    const rec2 = C.recommend({ rest: { ok: true, deadzone: 0.05 }, triggerRestMax: 0.2 });
    check(rec2.triggerOff === 0.35 && rec2.triggerOn === 0.45, 'recommend: triggers follow their resting value ' + JSON.stringify(rec2));
  }
  // phantom report: a jittering pad, a pad that mirrors another, a quiet pad
  {
    const r = rng(11);
    const mkPad = (index, axes, id) => ({ index, id: id || 'pad ' + index, mapping: 'standard', connected: true, axes, buttons: new Array(17).fill(0) });
    const idle = [];
    for (let i = 0; i < 90; i++) idle.push({ t: i * FRAME, pads: [
      mkPad(0, [0.002 * r.g(), 0.002 * r.g(), 0.002 * r.g(), 0.002 * r.g()]),
      mkPad(1, [0.02 * r.g(), 0.02 * r.g(), (r.u() - 0.5) * 0.14, 0.02 * r.g()], 'jittery'),
      mkPad(2, [0.001, 0.001, 0.001, 0.001]),
      mkPad(3, [0.22, 0, 0, 0], 'stuck'),
    ] });
    const active = [];
    for (let i = 0; i < 120; i++) {
      const a = [Math.sin(i / 8), Math.cos(i / 8), 0.5 * Math.sin(i / 5), 0];
      active.push({ t: 5000 + i * FRAME, pads: [mkPad(0, a), mkPad(1, [0.02 * r.g(), 0, (r.u() - 0.5) * 0.14, 0]), mkPad(2, a.slice()), null] });
    }
    const q = C.phantomReport({ idle, active }, {});
    const by = (i) => q.pads.find((p) => p.index === i);
    check(by(1).movesByItself, 'the jittering pad is flagged "moves by itself"');
    check(!by(0).movesByItself && !by(0).offCenter && by(0).flags.length === 0, 'the quiet pad 0 is not flagged: ' + JSON.stringify(by(0).flags));
    check(!by(2).movesByItself && !by(2).offCenter, 'the quiet pad 2 is not flagged by the idle test');
    check(by(3).offCenter && !by(3).movesByItself, 'a pad stuck away from zero is flagged "sits off centre"');
    check(q.mirrors.length === 1 && q.mirrors[0].pad === 2 && q.mirrors[0].of === 0, 'pad 2 is flagged "mirror of pad 0": ' + JSON.stringify(q.mirrors));
    check(!by(0).mirrorOf && !by(1).mirrorOf, 'pads 0 and 1 are not mirrors');
    check(q.defaultPad && q.defaultPad.index === 0, 'the default pad is the one that moved most, not the phantom or the copy: ' + JSON.stringify(q.defaultPad));
    check(q.summary.some((s) => /Pad 1 .*moves by itself/.test(s)) && q.summary.some((s) => /mirror of pad 0/.test(s)), 'the findings are in words: ' + q.summary.join(' | '));
    check(by(1).peakRange < 0.3 && by(0).peakRange > 1, 'best push range: ' + by(1).peakRange + ' vs ' + by(0).peakRange);
    // moving right now
    check(q.moving.leader === 0, 'the pad moving now is pad 0: ' + JSON.stringify(q.moving));
    // no idle frames, nothing pushed: says so
    const e = C.phantomReport({ idle: [], active: active.slice(0, 2).map((f) => ({ t: f.t, pads: [mkPad(0, [0, 0, 0, 0]), null] })) }, {});
    check(e.summary.some((s) => /idle test has not been run/.test(s)), 'before the idle test the report says it has not run');
  }
  console.log('  core.js checks done');
}

// ---------------------------------------------------------------- (b) nothing is sent
function scan() {
  section('(b) scan for anything that could send data');
  const files = { 'index.html': readFileSync(join(here, 'index.html'), 'utf8'), 'core.js': readFileSync(join(here, 'core.js'), 'utf8') };
  const bad = [
    [/\bfetch\s*\(/, 'fetch('], [/XMLHttpRequest/, 'XMLHttpRequest'], [/WebSocket/, 'WebSocket'], [/sendBeacon/, 'sendBeacon'], [/EventSource/, 'EventSource'],
    [/\bimport\s*\(/, 'import()'], [/\bimport\s+[^;\n]*\bfrom\b/, 'static import'], [/https?:\/\//i, 'an http(s) address'], [/(^|[^:\w])\/\/[a-z0-9.-]+\.[a-z]{2,}\//i, 'a protocol-relative address'],
    [/<link\b/i, '<link>'], [/<img\b/i, '<img>'], [/<iframe\b/i, '<iframe>'], [/<form\b/i, '<form>'], [/\bnew\s+Worker\b/, 'Worker'], [/importScripts/, 'importScripts'], [/<script[^>]*\ssrc\s*=\s*["']?(?!core\.js["'\s>])[^"'\s>]/i, 'a script src other than core.js'],
    [/navigator\.\w*[Ss]end/, 'a navigator send'], [/\bnew\s+Image\b/, 'new Image'], [/\bnew\s+Request\b/, 'new Request'],
  ];
  // the scan itself must bite: each of these bad snippets has to be caught
  const samples = ['fetch("/x")', 'new XMLHttpRequest()', 'new WebSocket(u)', 'navigator.sendBeacon(u)', 'new EventSource(u)', 'import("x.js")', '<script src="https://cdn.example/x.js"></script>', '<script src="other.js"></script>', '<link rel="stylesheet" href="a.css">', '<img src="a.png">'];
  for (const smp of samples) check(bad.some(([re]) => re.test(smp)), 'the scan catches: ' + smp);
  for (const [name, text] of Object.entries(files)) for (const [re, label] of bad) check(!re.test(text), `${name} contains ${label}`);
  check(/<script src="core\.js"><\/script>/.test(files['index.html']), 'index.html loads only core.js next to it');
  check(/Nothing is sent anywhere/.test(files['index.html']), 'the page says in one line that nothing is sent');
  console.log('  scan done');
}

// ---------------------------------------------------------------- (c) the one-command server
async function serverTest() {
  section('(c) serve.mjs');
  const s = await startServer({ port: 0 });
  try {
    const port = s.address().port;
    check(s.address().address === '127.0.0.1', 'listens on 127.0.0.1 only: ' + s.address().address);
    const get = async (p) => { const r = await fetch(`http://127.0.0.1:${port}${p}`); return { status: r.status, text: await r.text(), type: r.headers.get('content-type') }; };
    const a = await get('/'), b = await get('/core.js'), c = await get('/serve.mjs'), d = await get('/../../CLAUDE.md'), e = await get('/%2e%2e/%2e%2e/CLAUDE.md');
    check(a.status === 200 && /Pad lab/.test(a.text), 'serves the page at /');
    check(b.status === 200 && /PadLabCore/.test(b.text), 'serves core.js');
    check(c.status === 404 && d.status === 404 && e.status === 404, 'serves nothing else');
  } finally { await new Promise((r) => s.close(r)); }
  console.log('  server checks done');
}

// ---------------------------------------------------------------- (d) the page in headless Chrome with fake gamepads
// Pad 0: a real pad whose sticks the script drives. Pad 1: a phantom whose axes jitter. Slot 2: empty (null) until the mirror test makes it a copy of pad 0. Slot 3: null.
const FAKE = `(() => {
  let seed = 987654321;
  const rnd = () => { seed = (seed * 1664525 + 1013904223) >>> 0; return seed / 4294967296; };
  const gauss = () => { let u = 0; while (u === 0) u = rnd(); return Math.sqrt(-2 * Math.log(u)) * Math.cos(2 * Math.PI * rnd()); };
  const OFF = { right: [0.06, -0.04], left: [-0.01, 0.005] };
  const F = window.__fake = { mode: { left: 'rest', right: 'rest' }, t0: { left: 0, right: 0 }, deg: { left: 0, right: 0 }, bias: { left: -2, right: 3 }, mirror: false };
  const pFlick = (tau) => (tau < 0 ? 0 : tau < 100 ? tau / 100 : tau < 160 ? 1 : tau < 210 ? 1 - (tau - 160) / 50 : tau < 250 ? -0.2 * (tau - 210) / 40 : tau < 350 ? -0.2 * (1 - (tau - 250) / 100) : 0);
  F.rest = (s) => { F.mode[s] = 'rest'; };
  F.flick = (s, deg) => { F.mode[s] = 'flick'; F.t0[s] = performance.now(); F.deg[s] = deg; };
  F.aim = (s, deg) => { F.mode[s] = 'aim'; F.deg[s] = deg; };
  F.sweep = (s, on) => { F.mode[s] = on ? 'sweep' : 'rest'; };
  const stick = (s, now) => {
    const o = OFF[s], nz = () => (rnd() - 0.5) * 0.008;
    let x = 0, y = 0;
    if (F.mode[s] === 'flick') {
      const tau = now - F.t0[s];
      if (tau > 360) F.mode[s] = 'rest';
      else { const p = pFlick(tau), d = F.deg[s] * Math.PI / 180; x = Math.cos(d) * p; y = -Math.sin(d) * p; }
    } else if (F.mode[s] === 'aim') {
      const th = (F.deg[s] + F.bias[s] + 2 * gauss()) * Math.PI / 180;
      x = 0.95 * Math.cos(th); y = -0.95 * Math.sin(th);
      return [x, y];
    } else if (F.mode[s] === 'sweep') { x = 0.9 * Math.cos(now / 150); y = 0.9 * Math.sin(now / 150); return [x, y]; }
    return [o[0] + x + nz(), o[1] + y + nz()];
  };
  const btns = () => Array.from({ length: 17 }, () => ({ pressed: false, touched: false, value: 0 }));
  const mkpad = (index, id, axes) => ({ index, id, connected: true, mapping: 'standard', timestamp: performance.now(), axes, buttons: btns(), vibrationActuator: null });
  navigator.getGamepads = () => {
    const now = performance.now();
    const l = stick('left', now), r = stick('right', now);
    const real = [l[0], l[1], r[0], r[1]];
    const ph = [0.04 * (rnd() - 0.5), 0.04 * (rnd() - 0.5), 0.14 * (rnd() - 0.5), 0.04 * (rnd() - 0.5)];
    return [mkpad(0, 'Fake Real Pad (STANDARD GAMEPAD Vendor: 0001 Product: 0001)', real), mkpad(1, 'Phantom Virtual Pad (STANDARD GAMEPAD Vendor: 0002 Product: 0002)', ph), F.mirror ? mkpad(2, 'Mirror Copy Pad (STANDARD GAMEPAD)', real.slice()) : null, null];
  };
  // catch the download instead of writing a file
  const origCreate = URL.createObjectURL.bind(URL);
  const blobs = new Map();
  URL.createObjectURL = (b) => { const u = origCreate(b); blobs.set(u, b); return u; };
  HTMLAnchorElement.prototype.click = function () {
    if (this.download) { const b = blobs.get(this.href); window.__savedName = this.download; if (b) b.text().then((t) => { window.__saved = t; }); return; }
    return HTMLElement.prototype.click.call(this);
  };
})();`;

async function browserPart() {
  section('(d) the page in headless Chrome with fake gamepads');
  if (process.env.PADLAB_SKIP_BROWSER) { console.log('  browser part skipped: PADLAB_SKIP_BROWSER is set'); return; }
  let machine;
  try { machine = await import('../machine/browser.mjs'); } catch (e) { console.log('  browser part skipped: tools/machine/browser.mjs could not be loaded (' + e.message + ')'); return; }
  const { launchBrowser, Cdp, browserExe } = machine;
  const exe = browserExe('chrome') || browserExe('edge');
  if (!exe) { console.log('  browser part skipped: no Chrome or Edge is installed at the usual places'); return; }
  let server = null, browser = null, page = null;
  try {
    server = await startServer({ port: 0 });
    try {
      browser = await launchBrowser({ exe, flags: ['--window-size=1280,1000'], session: process.env.MERIDIAN_SESSION || 'tools-pipeline', purpose: 'padlab selftest', timeoutS: 150, log: (m) => console.log('  [browser] ' + m.slice(0, 200)) });
    } catch (e) { console.log('  browser part skipped: Chrome could not be launched (' + e.message.slice(0, 300) + ')'); return; }
    page = await Cdp.open(browser.target.webSocketDebuggerUrl);
    const pageErrors = [];
    page.ws.addEventListener('message', (e) => { try { const m = JSON.parse(e.data); if (m.method === 'Runtime.exceptionThrown') pageErrors.push(m.params.exceptionDetails.exception ? m.params.exceptionDetails.exception.description : m.params.exceptionDetails.text); } catch { /* not json */ } });
    await page.send('Page.enable'); await page.send('Runtime.enable');
    await page.send('Page.addScriptToEvaluateOnNewDocument', { source: FAKE });
    await page.send('Page.navigate', { url: `http://127.0.0.1:${server.address().port}/index.html?fast=1` });

    const state = () => page.eval('window.__padlab && window.__padlab.state()');
    const waitFor = async (fn, what, ms = 8000) => {
      const t0 = Date.now(); let last;
      while (Date.now() - t0 < ms) { try { last = await state(); if (last && (await fn(last))) return last; } catch (e) { last = { err: e.message }; } await sleep(40); }
      throw new Error(`timed out waiting for ${what}; last state: ${JSON.stringify(last).slice(0, 600)}`);
    };
    const space = () => page.eval("window.dispatchEvent(new KeyboardEvent('keydown', { key: ' ', code: 'Space', bubbles: true, cancelable: true })); true");
    const fake = (code) => page.eval('(() => { ' + code + ' })()');

    // both pads listed, the null slots shown as empty
    let st = await waitFor((s) => s.cards.length >= 4 && s.cards[0].text.includes('Fake Real Pad') && s.cards[1].text.includes('Phantom Virtual Pad'), 'the pad cards');
    check(st.cards[0].text.includes('Fake Real Pad') && st.cards[1].text.includes('Phantom Virtual Pad'), 'both pads are listed on the page');
    check(st.cards[2].empty && st.cards[3].empty && /empty/.test(st.cards[2].text), 'the empty slots are listed as empty');
    check(/mapping: standard/.test(st.cards[0].text) && /buttons: 17/.test(st.cards[0].text) && /axes: 4/.test(st.cards[0].text), 'a card shows mapping, button count and axis count: ' + st.cards[0].text.slice(0, 160));

    // step 1: the idle test (hands off): the phantom must be flagged, the real pad not
    st = await waitFor((s) => s.step === 0 && s.phase === 'idle', 'step 1 ready');
    await space();
    st = await waitFor((s) => s.step === 0 && s.phase === 'done', 'the idle test to finish', 12000);
    const by = (s, i) => s.report.pads.find((p) => p.index === i);
    check(by(st, 1) && by(st, 1).movesByItself, 'the idle test flags the phantom pad as moving by itself');
    check(by(st, 0) && !by(st, 0).movesByItself && !by(st, 0).offCenter, 'the idle test does not flag the real pad: ' + JSON.stringify(by(st, 0)));
    check(st.report.summary.some((x) => /Pad 1 .*moves by itself/.test(x)), 'the page says it in words: ' + st.report.summary.join(' | '));

    // step 2: push a stick around: the pad that changed is named, and is the default pad to measure
    await space();
    await waitFor((s) => s.step === 1 && s.phase === 'idle', 'step 2 ready');
    await fake("__fake.sweep('right', true);");
    await space();
    await waitFor((s) => s.step === 1 && s.phase === 'run', 'the push step to run');
    await sleep(300);
    const mid = await state();
    check(mid.moving && mid.moving.leader === 0, 'while the real stick moves, the pad named as moving now is pad 0: ' + JSON.stringify(mid.moving));
    st = await waitFor((s) => s.step === 1 && s.phase === 'done', 'the push step to finish');
    await fake("__fake.sweep('right', false);");
    check(!st.leaders.includes(1) && st.leaders.includes(0), 'pad 1 is never named as the mover, pad 0 is: ' + JSON.stringify([...new Set(st.leaders)]));
    check(st.tested.index === 0 && !st.tested.picked, 'the real pad is the default pad to measure: ' + JSON.stringify(st.tested));
    check(st.report.defaultPad && st.report.defaultPad.index === 0, 'the report names pad 0 as the one that moved most');

    // guided steps for both sticks
    const DEG = [90, 45, 0, -45, -90, -135, 180, 135];
    for (const stick of ['right', 'left']) {
      const base = stick === 'right' ? 2 : 5;
      await space(); await waitFor((s) => s.step === base && s.phase === 'idle', stick + ' rest step ready');
      await space(); await waitFor((s) => s.step === base && s.phase === 'done', stick + ' rest step done', 10000);
      await space(); await waitFor((s) => s.step === base + 1 && s.phase === 'idle', stick + ' flick step ready');
      await space(); await waitFor((s) => s.step === base + 1 && s.phase === 'run', stick + ' flick step running');
      for (let n = 1; n <= 2; n++) {
        await fake(`__fake.flick('${stick}', ${n === 1 ? 20 : 200});`);
        await waitFor((s) => (s.flicks || 0) >= n, `flick ${n} of the ${stick} stick to be recorded`, 6000);
        await sleep(120);
      }
      await waitFor((s) => s.step === base + 1 && s.phase === 'done', stick + ' flick step done');
      await space(); await waitFor((s) => s.step === base + 2 && s.phase === 'idle', stick + ' aim step ready');
      await space(); await waitFor((s) => s.step === base + 2 && s.phase === 'run', stick + ' aim step running');
      for (let i = 0; i < 8; i++) {
        st = await waitFor((s) => s.phase === 'done' || (s.aim && s.aim.i === i && s.aim.mode === 'wait'), `${stick} aim direction ${i} ready`, 6000);
        await fake(`__fake.aim('${stick}', ${DEG[i]});`);
        await waitFor((s) => s.phase === 'done' || (s.aim && s.aim.i > i), `${stick} aim direction ${i} held`, 6000);
        await fake(`__fake.rest('${stick}');`);
      }
      st = await waitFor((s) => s.step === base + 2 && s.phase === 'done', stick + ' aim step done');
    }

    // measured values land near what the fake pad produced
    const fm = st.frameMs, tolRise = Math.max(40, 3 * fm), tolSpring = Math.max(70, 4 * fm);
    console.log(`  frame time on this run: ${fm.toFixed(1)} ms`);
    for (const stick of ['right', 'left']) {
      const r = st.results[stick];
      const off = stick === 'right' ? [0.06, -0.04] : [-0.01, 0.005];
      check(r.rest && r.rest.ok, stick + ': rest measured');
      if (r.rest && r.flick && r.aim && r.aim.ok) console.log(`  ${stick}: dead zone ${r.rest.deadzone}, offset ${r.rest.offset.x.toFixed(3)},${r.rest.offset.y.toFixed(3)} (truth ${off}); rise ${r.flick.rise.median.toFixed(0)} ms (80), spring-back ${r.flick.spring.median.toFixed(0)} ms (175), overshoot ${r.flick.overshoot.median.toFixed(2)} (0.20), aim spread ${r.aim.spreadDeg.toFixed(1)} deg (2), bias ${r.aim.biasRmsDeg.toFixed(1)} deg (${stick === 'right' ? 3 : 2})`);
      near(r.rest.offset.x, off[0], 0.01, stick + ' rest offset x'); near(r.rest.offset.y, off[1], 0.01, stick + ' rest offset y');
      const worst = Math.hypot(off[0], off[1]) + 0.006;
      near(r.rest.deadzone, Math.max(0.05, Math.ceil(worst * 150) / 100), 0.02, stick + ' suggested dead zone');
      check(r.flick && r.flick.n === 2, stick + ': two flicks recorded');
      near(r.flick.rise.median, 80, tolRise, stick + ' rise time (truth 80 ms)');
      near(r.flick.spring.median, 175, tolSpring, stick + ' spring-back (truth 175 ms)');
      near(r.flick.overshoot.median, 0.2, 0.06, stick + ' overshoot (truth 0.2)');
      check(r.aim && r.aim.ok && r.aim.directionsMeasured === 8, stick + ': all eight directions measured: ' + JSON.stringify(r.aim));
      const bias = stick === 'right' ? 3 : 2;
      near(r.aim.biasRmsDeg, bias, 1.3, stick + ' aim bias (truth ' + bias + ' degrees)');
      near(r.aim.spreadDeg, 2, 1.3, stick + ' aim spread (truth 2 degrees)');
    }
    check(st.results.right.rest.deadzone > st.results.left.rest.deadzone, 'the right stick (bigger rest offset) gets the bigger dead zone');

    // a pad that copies pad 0 is flagged "mirror of pad 0"
    await fake("__fake.mirror = true; __fake.sweep('right', true);");
    st = await waitFor((s) => s.report && by(s, 2) && by(s, 2).mirrorOf === 0, 'pad 2 to be flagged as a mirror of pad 0', 6000);
    await fake("__fake.sweep('right', false);");
    check(by(st, 2).mirrorOf === 0 && by(st, 0).mirrorOf === null && by(st, 1).mirrorOf === null, 'only the copy is flagged as a mirror');

    // save the profile
    await page.eval("document.getElementById('save').click(); true");
    await waitFor(() => page.eval('typeof window.__saved === "string"'), 'the profile to be saved');
    const text = await page.eval('window.__saved'), name = await page.eval('window.__savedName');
    check(/^orb-pad-profile-\d{8}-\d{4}\.json$/.test(name), 'the file name has a date and time: ' + name);
    let prof = null;
    try { prof = JSON.parse(text); } catch (e) { check(false, 'the saved file is JSON: ' + e.message); }
    if (prof) {
      check(prof.kind === 'orb-pad-profile' && prof.version === 1, 'profile kind and version');
      check(typeof prof.savedAt === 'string' && !Number.isNaN(Date.parse(prof.savedAt)), 'profile savedAt');
      check(typeof prof.userAgent === 'string' && prof.userAgent.length > 5, 'profile userAgent');
      check(/Nothing was sent/.test(prof.note), 'profile carries the "nothing was sent" note');
      check(Array.isArray(prof.padsSeen) && prof.padsSeen.length >= 3 && prof.padsSeen.some((p) => p.index === 0 && /Fake Real Pad/.test(p.id)) && prof.padsSeen.some((p) => p.index === 1 && /Phantom/.test(p.id)), 'profile lists the pads seen with ids and indices');
      check(prof.testedPad && prof.testedPad.index === 0 && /Fake Real Pad/.test(prof.testedPad.id), 'profile names the tested pad');
      check(prof.phantom && prof.phantom.idleTestRun === true && prof.phantom.pads.find((p) => p.index === 1).movesByItself === true && !prof.phantom.pads.find((p) => p.index === 0).movesByItself, 'profile has the phantom findings');
      check(prof.phantom.mirrors.some((m) => m.pad === 2 && m.mirrorOf === 0), 'profile records the mirror');
      for (const s of ['right', 'left']) {
        const k = prof.sticks[s];
        check(k && k.rest && typeof k.rest.recommendedDeadzone === 'number' && k.rest.offset && k.rest.noise && k.rest.drift, s + ' stick: rest numbers saved');
        check(k.flicks && k.flicks.riseMs.n === 2 && k.flicks.springBackMs.median > 0 && Number.isFinite(k.flicks.overshoot.median), s + ' stick: flick numbers saved');
        check(k.aim && Number.isFinite(k.aim.spreadDeg) && k.aim.perDirection.length === 8 && k.aim.worst && k.aim.worst.name, s + ' stick: aim numbers saved');
        check(k.recommended && k.recommended.deadzone >= 0.05 && k.recommended.isSuggestion === true && 'awayDead' in k.recommended && 'triggerOn' in k.recommended, s + ' stick: recommended values saved');
      }
      check(prof.suggested && prof.suggested.isSuggestion && prof.suggested.deadzone >= 0.05, 'profile has combined suggestions');
    }
    const stored = await page.eval("(() => { try { return localStorage.getItem('orb-pad-profile:last'); } catch (e) { return 'ERR'; } })()");
    check(stored === text, 'a copy of the profile is kept in localStorage');

    // nothing went anywhere but this page's own files
    const urls = await page.eval('performance.getEntriesByType("resource").map((r) => r.name)');
    check(urls.every((u) => u.startsWith(`http://127.0.0.1:${server.address().port}/`) || u.startsWith('blob:')), 'every request the page made was to its own files: ' + JSON.stringify(urls));
    check(pageErrors.length === 0, 'no script errors in the page: ' + pageErrors.join(' | ').slice(0, 300));
    console.log('  browser checks done');
  } catch (e) {
    check(false, 'browser part: ' + (e && e.message ? e.message : e));
  } finally {
    try { if (page) page.close(); } catch { /* gone */ }
    try { if (browser) await browser.close(); } catch { /* gone */ }
    try { if (server) await new Promise((r) => server.close(r)); } catch { /* gone */ }
  }
}

// ---------------------------------------------------------------- run
try {
  unitTests();
  scan();
  await serverTest();
  await browserPart();
} catch (e) { failures.push('unexpected error: ' + (e && e.stack ? e.stack : e)); }
console.log(`${checks} checks, ${failures.length} failed`);
if (failures.length) { for (const f of failures) console.log(' - ' + f); console.log('FAILED'); process.exit(1); }
console.log('padlab self-test ok');
process.exit(0);
