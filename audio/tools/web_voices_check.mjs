#!/usr/bin/env node
// Does the page-side player (AudioWeb.JS_SOURCE in audio/audio_web.gd) do its job in a real browser, and does a main-thread stall leave a hole in what it plays?
// docs/audio/crackle.md. The browser is started only through Tools' launcher (tools/machine/browser.mjs): guarded headless Chrome, below-normal, a time limit, the session name in its profile.
// The page's output is recorded at the end of its graph (the soft clip before the destination), so what is tested is what would reach the speakers.
//   node audio/tools/web_voices_check.mjs [--out <folder for the recordings>]
// Exit code 1 on a failure. A test with the machine over 60% load is not trusted for timing (the stall holes are measured against the same page, so they hold).
import { readFileSync, mkdirSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { Cdp, launchBrowser, serve, browserExe, cpuLoad } from '../../tools/machine/browser.mjs';

const here = dirname(fileURLToPath(import.meta.url));
const argv = process.argv.slice(2);
const OUT = argv.indexOf('--out') >= 0 ? resolve(argv[argv.indexOf('--out') + 1]) : null;
const gd = readFileSync(join(here, '..', 'audio_web.gd'), 'utf8');
const m = /const JS_SOURCE := """\r?\n([\s\S]*?)"""/.exec(gd);
if (!m) { console.error('no JS_SOURCE in audio/audio_web.gd'); process.exit(2); }
const JS = m[1];
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
let fails = 0;
const ok = (c, msg) => { console.log(`  ${c ? 'ok  ' : 'FAIL'}  ${msg}`); if (!c) fails++; };

const server = await serve(here);   // any folder: the page is about:blank plus our evals
let browser = null, page = null;
try {
  const loadBefore = Math.round(await cpuLoad(2000));
  browser = await launchBrowser({ exe: browserExe('chrome'), flags: ['--window-size=800,600', '--autoplay-policy=no-user-gesture-required'], session: process.env.MERIDIAN_SESSION || 'meridian-audio-music', purpose: 'webvoices', timeoutS: 300, cpuPercent: 0, priority: 'belownormal', log: () => {} });
  page = await Cdp.open(browser.target.webSocketDebuggerUrl);
  await page.send('Page.enable');
  await page.send('Page.navigate', { url: `http://127.0.0.1:${server.address().port}/` });
  await sleep(800);
  await page.eval(JS, true);
  console.log('1. installed');
  ok(await page.eval('Boolean(window.__aweb && window.__aweb.ready)'), 'the player installs (window.__aweb ready)');
  await sleep(300);
  ok(await page.eval('window.__aweb.running'), 'its context runs (autoplay open in this test)');
  await page.eval('window.__first = window.__aweb');
  await page.eval(JS, true);
  ok(await page.eval('window.__aweb === window.__first'), 'a second install does nothing');
  console.log('2. setup');
  const setup = `(function () {
    var W = window.__aweb, rate = 44100, i;
    function pcm(n, f) { var a = new Int16Array(n); for (i = 0; i < n; i++) { a[i] = Math.max(-32768, Math.min(32767, Math.round(f(i) * 32767))); } return a.buffer; }
    W.put('tone#0', pcm(rate * 0.6, function (k) { return 0.5 * Math.sin(2 * Math.PI * 220 * k / rate); }), rate);
    var seed = 12345; function rnd() { seed = (seed * 1664525 + 1013904223) >>> 0; return seed / 4294967296 * 2 - 1; }
    W.put('noise#0', pcm(rate * 0.6, function () { return 0.9 * rnd(); }), rate);
    ['Sfx', 'SfxMuffled', 'Voice', 'Alert'].forEach(function (b) { W.bus(b, 1); });
    W.master(1);
    return true;
  })()`;
  await page.eval(setup);
  await sleep(100);

  // analysis helpers run in the page: record, then read back the samples
  const record = (ms) => page.eval(`new Promise(function (res) { window.__aweb.record().then(function () { setTimeout(function () { res(true); }, ${ms}); }); })`, true);
  const grab = async () => JSON.parse(await page.eval(`(function () {
    var r = window.__aweb.rec, L = r.L, n = 0, k; for (k = 0; k < L.length; k++) { n += L[k].length; }
    var all = new Float32Array(n), o = 0; for (k = 0; k < L.length; k++) { all.set(L[k], o); o += L[k].length; }
    // peak, and the longest run of near-silence inside the part that has sound
    var first = -1, last = -1; for (k = 0; k < n; k++) { if (Math.abs(all[k]) > 0.01) { if (first < 0) { first = k; } last = k; } }
    var runMax = 0, run = 0; for (k = Math.max(first, 0); k <= last; k++) { if (Math.abs(all[k]) < 0.002) { run++; if (run > runMax) { runMax = run; } } else { run = 0; } }
    var peak = 0; for (k = 0; k < n; k++) { var a = Math.abs(all[k]); if (a > peak) { peak = a; } }
    var rms = 0, c = 0; for (k = Math.max(first, 0); k <= last; k++) { rms += all[k] * all[k]; c++; } rms = c ? Math.sqrt(rms / c) : 0;
    return JSON.stringify({ n: n, rate: r.rate, first: first, last: last, peak: peak, rms: rms, silentRunMs: runMax / r.rate * 1000, durMs: (last - first) / r.rate * 1000 });
  })()`));

  console.log('2. a sound plays whole, and a main-thread stall leaves no hole in it');
  for (const stall of [0, 40, 100, 150, 300]) {
    await record(200);
    const r0 = await page.eval(`(async function () {
      var W = window.__aweb; W.play(0, 'tone#0', 0.5, 0, 1, 'Sfx', 0, '');
      var t0 = performance.now(); if (${stall} > 0) { while (performance.now() - t0 < ${stall}) { /* the stall */ } }
      await new Promise(function (r) { setTimeout(r, 900); }); return 1;
    })()`, true);
    const g = await grab();
    // the tone is 600 ms long; a 220 Hz sine crosses zero every 2.3 ms, so near-silence for 3 samples at 0.002 is a crossing; a hole is far longer
    ok(g.durMs > 560 && g.durMs < 640 && g.silentRunMs < 1.0, `${stall} ms stall: the 600 ms tone is ${g.durMs.toFixed(0)} ms long with its longest silence ${g.silentRunMs.toFixed(2)} ms (peak ${g.peak.toFixed(2)})`);
    await sleep(100);
  }

  console.log('3. the graph does its parts');
  // limiter and soft clip: eight full-scale noise voices at unity gain must not pass 0.98 at the end of the graph
  await record(200);
  await page.eval(`(async function () { var W = window.__aweb, s; for (s = 0; s < 8; s++) { W.play(s, 'noise#0', 1, 0, 1, 'Sfx', 0, ''); } await new Promise(function (r) { setTimeout(r, 500); }); return 1; })()`, true);
  const lim = await grab();
  ok(lim.peak <= 0.98, `eight loud voices at once: the output peaks at ${lim.peak.toFixed(3)} (never above 0.98)`);
  await sleep(700);
  // the muffled bus: noise through the 900 Hz low-pass has far less energy than without it (same gain)
  await record(200);
  await page.eval(`(async function () { var W = window.__aweb; W.play(0, 'noise#0', 0.2, 0, 1, 'Sfx', 0, ''); await new Promise(function (r) { setTimeout(r, 700); }); return 1; })()`, true);
  const bright = await grab();
  await sleep(300);
  await record(200);
  await page.eval(`(async function () { var W = window.__aweb; W.play(0, 'noise#0', 0.2, 0, 1, 'SfxMuffled', 900, ''); await new Promise(function (r) { setTimeout(r, 700); }); return 1; })()`, true);
  const dull = await grab();
  ok(dull.rms < bright.rms * 0.5, `the muffled low-pass takes the noise from rms ${bright.rms.toFixed(3)} to ${dull.rms.toFixed(3)}`);
  // bus gain: half the level on a bus halves the rms
  await sleep(300);
  await page.eval(`window.__aweb.bus('Voice', 0.5)`);
  await sleep(100);
  await record(200);
  await page.eval(`(async function () { var W = window.__aweb; W.play(0, 'tone#0', 0.4, 0, 1, 'Voice', 0, ''); await new Promise(function (r) { setTimeout(r, 800); }); return 1; })()`, true);
  const half = await grab();
  await sleep(200);
  await record(200);
  await page.eval(`(async function () { var W = window.__aweb; W.play(0, 'tone#0', 0.4, 0, 1, 'Sfx', 0, ''); await new Promise(function (r) { setTimeout(r, 800); }); return 1; })()`, true);
  const full = await grab();
  ok(Math.abs(half.rms / full.rms - 0.5) < 0.08, `a bus at 0.5 gives half the level (${(half.rms / full.rms).toFixed(2)})`);
  // groups and slots: stopGroup fades a voice out; a new voice in the same slot replaces the old one
  await sleep(300);
  await record(200);
  await page.eval(`(async function () { var W = window.__aweb; W.play(3, 'tone#0', 0.5, 0, 1, 'Sfx', 0, 'g.test'); await new Promise(function (r) { setTimeout(r, 100); }); W.stopGroup('g.test', 30); await new Promise(function (r) { setTimeout(r, 700); }); return 1; })()`, true);
  const cut = await grab();
  ok(cut.durMs < 250 && cut.durMs > 60, `stopGroup cuts a 600 ms tone after about 100 ms (${cut.durMs.toFixed(0)} ms)`);
  // a suspended context plays nothing and says so (no queue to dump at the first click)
  await page.eval(`window.__aweb.ctx.suspend()`, true);
  await sleep(200);
  const refused = await page.eval(`window.__aweb.play(0, 'tone#0', 0.5, 0, 1, 'Sfx', 0, '')`);
  ok(refused === 0 && await page.eval('window.__aweb.notrunning') >= 1, 'a suspended context refuses the cue (and counts it)');
  await page.eval(`window.__aweb.ctx.resume()`, true);
  await sleep(300);
  ok(await page.eval('window.__aweb.play(0, "tone#0", 0.5, 0, 1, "Sfx", 0, "")') === 1, 'and plays again once it runs');
  ok(await page.eval(`window.__aweb.play(0, 'nothing#0', 0.5, 0, 1, 'Sfx', 0, '')`) === 0 && await page.eval('window.__aweb.missing') >= 1, 'a sound the page was never given is refused and counted');
  const loadAfter = Math.round(await cpuLoad(2000));
  console.log(`\nmachine load before ${loadBefore}% after ${loadAfter}%` + (Math.max(loadBefore, loadAfter) > 60 ? ' (over 60%: the timing is not trusted)' : ''));
} catch (e) { console.log('FAILED: ' + e.message); fails++; }
finally { try { if (page) page.close(); } catch { /* gone */ } try { if (browser) await browser.close(); } catch { /* gone */ } server.close(); }
console.log(`\nweb voices check ${fails === 0 ? 'passed' : 'FAILED (' + fails + ')'}`);
process.exit(fails === 0 ? 0 : 1);
