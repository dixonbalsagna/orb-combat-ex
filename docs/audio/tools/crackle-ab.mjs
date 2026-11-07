#!/usr/bin/env node
// A/B for the web crackle (Audio and Music, 2026-11-06; docs/audio/crackle.md): force a main-thread stall of a chosen length right after a tick that plays several cues, RECORD what each
// of the page's AudioContexts sends to the speakers (an AudioWorklet on the audio thread, so a stalled page does not make holes in the recording), and measure the holes in the sound.
// Same set-up as docs/perf/tools/preplay/audio-stall-test.mjs (a scratch copy of the build's web folder; its worklet reports every skipped block; Tools' capture hook steps an AI match).
//
//   node docs/audio/tools/crackle-ab.mjs --dir <web folder> --out <folder> [--query "webvoices=1"] [--seed 7] [--ticks auto|1500,1700,...] [--stalls 0,40,100,150] [--label after]
//
// Per trial: the blocks the engine's worklet skipped, the holes in the recorded output (exact silence of 1 ms or more with sound within 8 ms on both sides: a click at each edge), the longest hole, and the cues
// the page started itself (window.__aweb.started, when the build has the page player). The trial's recording is written as a WAV (the output, both contexts mixed) for the ear.
// The browser starts only through Tools' launcher (tools/machine/browser.mjs). INVALID above 60% load before or after.
import { chmodSync, cpSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { join, resolve, dirname } from 'node:path';
import { tmpdir } from 'node:os';
import { fileURLToPath } from 'node:url';
import { Cdp, launchBrowser, serve, browserExe, cpuLoad } from '../../../tools/machine/browser.mjs';

const argv = process.argv.slice(2);
const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
const DIR = opt('--dir'), OUT = opt('--out'), QUERY = opt('--query', ''), SEED = Number(opt('--seed', '7')), LABEL = opt('--label', 'run');
const STALLS = opt('--stalls', '0,40,100,150').split(',').map(Number);
const TICKS_ARG = opt('--ticks', 'auto');
if (!DIR || !OUT) { console.error('usage: crackle-ab.mjs --dir <web folder> --out <folder> [--query ...] [--ticks auto|a,b,c] [--stalls 0,40,100,150]'); process.exit(2); }
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
mkdirSync(resolve(OUT), { recursive: true });
const SCRATCH = join(tmpdir(), `crackle-ab-${process.pid}`);
mkdirSync(SCRATCH, { recursive: true });
cpSync(resolve(DIR), SCRATCH, { recursive: true });
const wp = join(SCRATCH, 'index.audio.worklet.js');
chmodSync(wp, 0o666);
const wk = readFileSync(wp, 'utf8');
const line = "// this.port.postMessage('Output buffer has not enough frames! Skipping output frame.'); // Uncomment this line to debug output buffer.";
if (!wk.includes(line)) throw new Error('the worklet has no "Output buffer has not enough frames" line: another engine version');
writeFileSync(wp, wk.replace(line, "this.port.postMessage({ cmd: 'dbg_under', t: currentTime });"));

// the page-side tap, before the engine: every AudioContext gets a recorder worklet fed by a fan-out of whatever connects to its destination (the sound that reaches the speakers), and the engine worklet's skip messages are counted
const TAP = String.raw`(() => {
  window.__under = []; window.__rec = { ctxs: [] };
  const code = "class R extends AudioWorkletProcessor { process(i) { var c = i[0]; if (c && c[0]) { this.port.postMessage({ f: currentFrame, l: c[0].slice(), r: (c[1] || c[0]).slice() }); } return true; } } registerProcessor('crk-rec', R);";
  const url = URL.createObjectURL(new Blob([code], { type: 'text/javascript' }));
  const AC = window.AudioContext, oc = AudioNode.prototype.connect;
  window.AudioContext = new Proxy(AC, { construct(t, a) {
    const ctx = Reflect.construct(t, a, t);
    const rec = { ctx, id: window.__rec.ctxs.length, rate: ctx.sampleRate, blocks: [], tapIn: ctx.createGain(), perf0: performance.now(), ctx0: ctx.currentTime, started: false };
    ctx.__crk = rec; window.__rec.ctxs.push(rec);
    ctx.audioWorklet.addModule(url).then(() => {
      const n = new AudioWorkletNode(ctx, 'crk-rec', { numberOfInputs: 1, numberOfOutputs: 1, outputChannelCount: [2] });
      n.port.onmessage = (e) => rec.blocks.push(e.data);
      oc.call(rec.tapIn, n); const z = ctx.createGain(); z.gain.value = 0; oc.call(n, z); oc.call(z, ctx.destination); rec.started = true;
    });
    return ctx;
  } });
  AudioNode.prototype.connect = function (dest) {
    try { if (dest && window.AudioDestinationNode && dest instanceof AudioDestinationNode && dest.context.__crk) { oc.call(this, dest.context.__crk.tapIn); } } catch (e) { /* never break the page */ }
    return oc.apply(this, arguments);
  };
  const A = window.AudioWorkletNode;
  window.AudioWorkletNode = function (ctx, name, opts) { const n = new A(ctx, name, opts); if (name === 'godot-processor') n.port.addEventListener('message', (e) => { if (e.data && e.data.cmd === 'dbg_under') window.__under.push(performance.now()); }); return n; };
  window.AudioWorkletNode.prototype = A.prototype;
})();`;

const server = await serve(SCRATCH);
const url = `http://127.0.0.1:${server.address().port}/index.html?flashcap=1&preview=1&audiolog=1&${QUERY}`;
const result = { label: LABEL, query: QUERY, seed: SEED, when: new Date().toISOString(), trials: [] };
let browser = null, page = null, code = 0;
try {
  result.loadBefore = Math.round(await cpuLoad(3000));
  browser = await launchBrowser({ exe: browserExe('chrome'), flags: ['--window-size=1280,720', '--autoplay-policy=no-user-gesture-required'], session: process.env.MERIDIAN_SESSION || 'meridian-audio-music', purpose: 'crackleab', timeoutS: 1200, cpuPercent: 0, priority: 'belownormal', log: () => {} });
  page = await Cdp.open(browser.target.webSocketDebuggerUrl);
  await page.send('Page.enable');
  await page.send('Emulation.setDeviceMetricsOverride', { width: 1280, height: 720, deviceScaleFactor: 1, mobile: false });
  await page.send('Page.addScriptToEvaluateOnNewDocument', { source: TAP });
  await page.send('Page.navigate', { url });
  let ready = false; const dl = Date.now() + 300 * 1000;
  while (Date.now() < dl && !ready) { await sleep(500); ready = await page.eval('Boolean(window.__flashcap && window.__flashcap.ready)').catch(() => false); }
  if (!ready) throw new Error('the page offers no window.__flashcap that becomes ready');
  await page.eval(`window.__flashcap.start("ai", { reduced: false, seed: ${SEED} })`, true);
  result.hasWebPlayer = await page.eval('Boolean(window.__aweb && window.__aweb.ready)');
  result.contexts = await page.eval('window.__rec.ctxs.length');
  // the ticks: given, or the first ones where the page player starts several cues at once
  let TICKS = [];
  if (TICKS_ARG === 'auto') {
    TICKS = JSON.parse(await page.eval(`(async () => {
      const fc = window.__flashcap, out = [], need = ${STALLS.length};
      let last = -9999, prev = window.__aweb ? window.__aweb.started : 0;
      while (out.length < need && fc.tick < 9000) {
        await fc.step();
        const s = window.__aweb ? window.__aweb.started : 0;
        if (s - prev >= 3 && fc.tick - last > 240) { out.push(fc.tick); last = fc.tick; }
        prev = s;
      }
      return JSON.stringify(out);
    })()`, true));
    if (TICKS.length < STALLS.length) throw new Error('found only ' + TICKS.length + ' ticks with several cues at once (is this a build with the page player?)');
    // go back to a fresh match so the trials see the same ticks again
    await page.eval(`window.__flashcap.start("ai", { reduced: false, seed: ${SEED} })`, true);
    for (let w = 0; w < 100; w++) { await sleep(100); if (await page.eval('window.__flashcap.tick') === 0) break; }
    await sleep(500);
  } else TICKS = TICKS_ARG.split(',').map(Number);
  result.ticks = TICKS; result.stalls = STALLS;
  console.log('ticks', TICKS.join(','), 'stalls', STALLS.join(','), 'contexts', result.contexts, 'web player', result.hasWebPlayer);
  for (let i = 0; i < TICKS.length; i++) {
    const L = STALLS[i % STALLS.length];
    await page.eval(`(async () => { const fc = window.__flashcap; while (fc.tick < ${TICKS[i] - 1}) await fc.step(); })()`, true);
    await sleep(1500);
    const t = JSON.parse(await page.eval(`(async () => {
      const fc = window.__flashcap, rs = window.__rec.ctxs;
      const before = window.__under.length, started0 = window.__aweb ? window.__aweb.started : 0;
      const ctx0 = rs.map((r) => r.ctx.currentTime);
      const pre = ctx0.slice();
      await fc.step();                       // the tick that plays the cues
      await new Promise((r) => setTimeout(r, 90));   // let them start: the stall then lands on sounds that are playing
      const t0 = performance.now();
      const startedAfter = window.__aweb ? window.__aweb.started - started0 : null;
      const stallCtx = rs.map((r) => r.ctx.currentTime);
      if (${L} > 0) { while (performance.now() - t0 < ${L}) { /* the stall */ } }
      const t1 = performance.now();
      await new Promise((r) => setTimeout(r, 1300));
      const mine = window.__under.filter((x) => x >= t0 - 30 && x <= t1 + 1300);
      return JSON.stringify({ tick: fc.tick, stallMs: ${L}, startedByThePage: startedAfter, engineBlocksSkipped: mine.length, ctxStart: ctx0, pre, stallCtx, endCtx: rs.map((r) => r.ctx.currentTime), rates: rs.map((r) => r.rate) });
    })()`, true));
    // pull the recorded slices of each context for this trial: from 300 ms before the stall to 1.2 s after its end
    const ctxs = [];
    for (let c = 0; c < t.rates.length; c++) {
      const from = t.stallCtx[c] - 0.3, to = t.endCtx[c] - 0.05;
      const raw = JSON.parse(await page.eval(`(() => { const r = window.__rec.ctxs[${c}], rate = r.rate, f0 = Math.floor(${from} * rate), f1 = Math.floor(${to} * rate), L = [], R = [];
        for (const b of r.blocks) { if (b.f + 128 <= f0 || b.f >= f1) continue; for (let k = 0; k < 128; k++) { L.push(Math.round(b.l[k] * 32767)); R.push(Math.round(b.r[k] * 32767)); } }
        return JSON.stringify({ n: L.length, L, R }); })()`, true));
      ctxs.push({ rate: t.rates[c], L: raw.L, R: raw.R });
    }
    const analysis = analyse(ctxs, t.pre.map((p, c) => p - (t.stallCtx[c] - 0.3)));
    Object.assign(t, analysis.summary, { ctxStart: undefined, pre: undefined, stallCtx: undefined, endCtx: undefined, rates: undefined });
    result.trials.push(t);
    console.log(JSON.stringify(t));
    writeFileSync(resolve(OUT, `${LABEL}-tick${t.tick}-stall${L}.wav`), analysis.wav);
  }
} catch (e) { console.log(`[crackle-ab] FAILED: ${e.message}`); result.error = e.message; code = 1; }
finally { try { if (page) page.close(); } catch { /* gone */ } try { if (browser) await browser.close(); } catch { /* gone */ } server.close(); }
if (code === 0) { result.loadAfter = Math.round(await cpuLoad(3000)); result.valid = result.loadBefore <= 60 && result.loadAfter <= 60; }
writeFileSync(resolve(OUT, `${LABEL}.json`), JSON.stringify(result, null, 1));
console.log(JSON.stringify({ valid: result.valid, load: [result.loadBefore, result.loadAfter], error: result.error }));
process.exit(code);

// the recorded slices of the contexts (Int16 samples, each at its own rate) mixed at 48 kHz into one stereo WAV, and the holes in the mix: silence of 1 ms or more with sound within 8 ms on each side
function analyse(ctxs, preOffsets) {
  const RATE = 48000;
  const n = Math.max(...ctxs.map((c) => Math.floor(c.L.length / c.rate * RATE)));
  const L = new Float32Array(n), R = new Float32Array(n);
  for (const c of ctxs) {
    const m = Math.floor(c.L.length / c.rate * RATE);
    for (let i = 0; i < m; i++) { const s = i * c.rate / RATE, k = Math.floor(s); L[i] += c.L[k] / 32768; R[i] += c.R[k] / 32768; }
  }
  const mono = new Float32Array(n);
  for (let i = 0; i < n; i++) mono[i] = (Math.abs(L[i]) + Math.abs(R[i])) * 0.5;
  // a hole is a run of at least 1 ms of EXACT silence (under one 16-bit step: a skipped block writes zeros; a real tail never does) with sound (over 0.003) within 8 ms before and after it
  const zero = 2e-5, loudT = 0.003, win = Math.floor(RATE * 0.008), minRun = Math.floor(RATE * 0.001);
  const lastLoud = new Int32Array(n); let ll = -1e9;
  for (let i = 0; i < n; i++) { if (mono[i] > loudT) ll = i; lastLoud[i] = ll; }
  const nextLoud = new Int32Array(n); let nl = 1e9;
  for (let i = n - 1; i >= 0; i--) { if (mono[i] > loudT) nl = i; nextLoud[i] = nl; }
  const holes = []; let i = 0;
  while (i < n) {
    if (mono[i] > zero) { i++; continue; }
    let j = i; while (j < n && mono[j] <= zero) j++;
    if (j - i >= minRun && i > 0 && j < n && i - lastLoud[i] <= win && nextLoud[j - 1] - (j - 1) <= win + 1) holes.push({ at: +(i / RATE).toFixed(3), ms: +((j - i) / RATE * 1000).toFixed(1) });
    i = j;
  }
  // onset: from the call that steps the tick (the cues start inside it) to the first sound in the mix
  const preIdx = Math.max(0, Math.floor(Math.min(...preOffsets) * RATE)); let onset = null;
  for (let k = preIdx; k < n; k++) { if (mono[k] > loudT) { onset = +((k - preIdx) / RATE * 1000).toFixed(0); break; } }
  let peak = 0; for (let k = 0; k < n; k++) { peak = Math.max(peak, Math.abs(L[k]), Math.abs(R[k])); }
  const pcm = Buffer.alloc(44 + n * 4);
  pcm.write('RIFF', 0); pcm.writeUInt32LE(36 + n * 4, 4); pcm.write('WAVEfmt ', 8); pcm.writeUInt32LE(16, 16); pcm.writeUInt16LE(1, 20); pcm.writeUInt16LE(2, 22); pcm.writeUInt32LE(RATE, 24); pcm.writeUInt32LE(RATE * 4, 28); pcm.writeUInt16LE(4, 32); pcm.writeUInt16LE(16, 34); pcm.write('data', 36); pcm.writeUInt32LE(n * 4, 40);
  for (let k = 0; k < n; k++) { pcm.writeInt16LE(Math.max(-32768, Math.min(32767, Math.round(L[k] * 32767))), 44 + k * 4); pcm.writeInt16LE(Math.max(-32768, Math.min(32767, Math.round(R[k] * 32767))), 46 + k * 4); }
  return { wav: pcm, summary: { onsetMs: onset, seconds: +(n / RATE).toFixed(2), peak: +peak.toFixed(3), holes: holes.length, holeMs: +holes.reduce((a, h) => a + h.ms, 0).toFixed(1), longestHoleMs: holes.length ? Math.max(...holes.map((h) => h.ms)) : 0, firstHoles: holes.slice(0, 6) } };
}
