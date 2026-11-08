// The page's energy-model settings, checked in a real built page (Tools, 2026-11-07; Simulation's grant-tools-page.patch, G4): for each address the page is opened through the guarded launcher with the
// black box on, the match starts, and the black box's own record of the match's setup is read (window.__bb_replay: the setup EXACTLY as the match started), together with the two sliders.
//   node tools/preview/power-page-check.mjs --dir <the build's web folder> [--out <file>] [--limit 600]
// Expectations (Simulation's README): no word: setup.power true, travel 2, flatOut 5000, both sliders on the page; ?power=0 or ?power=off: setup.power false, no travel or flatOut key, no slider;
// ?travel=1.5 and ?flatout=6000: the setup carries them; out-of-range words are clamped by the page (travel 1.25 to 2, flatOut 3500 to 7000); a slider moved sets window.__travel / __flatout and is remembered.
// --only <text> runs the cases whose name contains it; --extra <words> adds page words to every address (the expectations are for the plain addresses: a shortcut's own words change what is read, so read the printed setup).
// Exit 1 on any miss. Node built-ins only. One browser at a time, below-normal, with a time limit.
import { writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { Cdp, launchBrowser, serve, browserExe } from '../machine/browser.mjs';

const a = process.argv.slice(2);
const opt = (n, d) => { const i = a.indexOf(n); return i >= 0 && i + 1 < a.length ? a[i + 1] : d; };
const DIR = opt('--dir');
if (!DIR) { console.error('usage: node tools/preview/power-page-check.mjs --dir <web folder> [--out <file>]'); process.exit(2); }
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const exe = browserExe('chrome');
if (!exe) { console.error('no chrome found'); process.exit(2); }
const BASE = 'planet=7&go=1&blackbox=1&preview=1';
const CASES = [
  { name: 'no power word', words: '', power: true, travel: 2, flatOut: 5000, sliders: true },
  { name: '?power=1 (the same as no word)', words: 'power=1', power: true, travel: 2, flatOut: 5000, sliders: true },
  { name: '?power=0', words: 'power=0', power: false, travel: undefined, flatOut: undefined, sliders: false },
  { name: '?power=off', words: 'power=off', power: false, travel: undefined, flatOut: undefined, sliders: false },
  { name: '?travel=1.5&flatout=6000', words: 'travel=1.5&flatout=6000', power: true, travel: 1.5, flatOut: 6000, sliders: true },
  { name: '?travel=9&flatout=100 (out of range)', words: 'travel=9&flatout=100', power: true, travel: 2, flatOut: 5000, sliders: true, note: 'an out-of-range word is ignored by the page head, so the slider stays at its own value' },
];
const lines = [];
const out = (s) => { lines.push(s); console.log(s); };
let bad = 0;
const server = await serve(resolve(DIR));
let browser = null;
try {
  for (const c of CASES.filter((x) => !opt('--only') || x.name.includes(opt('--only')))) {
    browser = await launchBrowser({ exe, flags: ['--window-size=1280,720'], session: process.env.MERIDIAN_SESSION || 'tools-pipeline', purpose: 'power page check', timeoutS: Number(opt('--limit', 600)), cpuPercent: 25, log: () => {} });
    const page = await Cdp.open(browser.target.webSocketDebuggerUrl);
    await page.send('Emulation.setDeviceMetricsOverride', { width: 1280, height: 720, deviceScaleFactor: 1, mobile: false });
    await page.send('Runtime.enable');
    const url = `http://127.0.0.1:${server.address().port}/index.html?${BASE}${c.words ? '&' + c.words : ''}${opt('--extra') ? '&' + opt('--extra') : ''}`;   // --extra: more page words on every address (the shortcut's own words: meteor=loud&tiles=1&audiolog=1&travel=1.5)
    await page.send('Page.navigate', { url });
    const deadline = Date.now() + 240 * 1000;
    let rec = null;
    // a fresh profile meets the How to play card and the flashing notice with the start menu: the match is held behind them (as tools/preview/smoke.mjs does): click through until the tick runs
    const click = async (x, y) => { await page.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x, y }); await page.send('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', clickCount: 1 }); await page.send('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', clickCount: 1 }); };
    const tick = async () => (await page.eval('(window.__preview && window.__preview.tick) || 0', true).catch(() => 0)) || 0;
    for (let tries = 0; tries < 30 && Date.now() < deadline; tries++) {
      const t0 = await tick(); await sleep(2500);
      if ((await tick()) > t0 + 30) break;
      await click(1099, 195); await sleep(1200); await click(640, 503); await sleep(1200);
    }
    while (Date.now() < deadline && !rec) {
      await sleep(1500);
      // the first records can be an empty setup (a demo before the start): wait for the match's own, which carries the planet
      rec = await page.eval('(function () { try { var s = window.__bb_replay ? JSON.parse(window.__bb_replay).setup : null; return s && s.planet !== undefined ? s : null; } catch (e) { return null; } })()', true).catch(() => null);
    }
    const dom = await page.eval('(function () { var r = [].slice.call(document.querySelectorAll("input[type=range]")).map(function (s) { return { min: s.min, max: s.max, value: s.value }; }); return { sliders: r, power: window.__travel, flat: window.__flatout, text: document.body.innerText.slice(-400) }; })()', true).catch(() => null);
    const got = rec || {};
    const check = (what, ok) => { if (!ok) bad++; return `${ok ? 'ok  ' : 'FAIL'} ${what}`; };
    out(`--- ${c.name}  (${url.replace(/^http:\/\/127\.0\.0\.1:\d+/, '')})`);
    out(`    black box setup: ${JSON.stringify({ power: got.power, travel: got.travel, flatOut: got.flatOut, planet: got.planet })}; sliders on page: ${dom ? dom.sliders.length : '?'}; window.__travel ${dom && dom.power}, __flatout ${dom && dom.flat}`);
    out('    ' + check(`setup.power is ${c.power}`, got.power === c.power));
    if (c.travel !== undefined) out('    ' + check(`setup.travel is ${c.travel}`, Number(got.travel) === c.travel)); else if (!c.power) out('    ' + check('no travel key in the setup with power off', got.travel === undefined));
    if (c.flatOut !== undefined) out('    ' + check(`setup.flatOut is ${c.flatOut}`, Number(got.flatOut) === c.flatOut)); else if (!c.power) out('    ' + check('no flatOut key in the setup with power off', got.flatOut === undefined)); else out(`    info setup.flatOut is ${JSON.stringify(got.flatOut)} (${c.note || ''})`);
    out('    ' + check(c.sliders ? 'both sliders are on the page (flat-out base, how far a launch carries)' : 'no slider on the page with power off', c.sliders ? dom && dom.sliders.length === 2 : dom && dom.sliders.length === 0));
    if (c.name === 'no power word') {   // the sliders: move each, the page's variable follows and is remembered
      const moved = await page.eval('(function () { var r = [].slice.call(document.querySelectorAll("input[type=range]")); if (r.length !== 2) return null; r[0].value = "6200"; r[0].dispatchEvent(new Event("input")); r[1].value = "1.55"; r[1].dispatchEvent(new Event("input")); return { flat: window.__flatout, travel: window.__travel, ls: [localStorage.getItem("orb_flatout"), localStorage.getItem("orb_travel")], text: document.body.innerText.slice(-300) }; })()', true).catch(() => null);
      out(`    sliders moved: ${JSON.stringify(moved && { flat: moved.flat, travel: moved.travel, remembered: moved.ls })}`);
      out('    ' + check('the flat-out slider sets window.__flatout and is remembered as orb_flatout', moved && moved.flat === 6200 && moved.ls[0] === '6200'));
      out('    ' + check('the travel slider sets window.__travel and is remembered as orb_travel', moved && moved.travel === 1.55 && moved.ls[1] === '1.55'));
      out('    ' + check('the labels read "how far a launch carries x1.55" and "flat-out flight base speed 6200"', moved && /how far a launch carries x1\.55/.test(moved.text) && /flat-out flight base speed 6200/.test(moved.text)));
    }
    try { page.close(); } catch { /* closed */ }
    await browser.close();
    browser = null;
  }
} finally {
  if (browser) { try { await browser.close(); } catch { /* stopped */ } }
  server.close();
}
out(`power page check: ${bad ? `FAILED, ${bad} miss(es)` : 'ok'}`);
if (opt('--out')) writeFileSync(resolve(opt('--out')), lines.join('\n') + '\n');
process.exitCode = bad ? 1 : 0;
