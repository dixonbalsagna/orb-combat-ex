#!/usr/bin/env node
// A start with the pad alone: does every AudioContext of the page run? (Orb, 2026-11-07: "sound effects weren't audible until I paused the
// game the first time": both contexts sat suspended for 178 s of pad play and woke 120 ms after the first key; docs/audio/pad-start.md.)
// The page is a real Chrome with the browser's REAL autoplay policy (no --autoplay-policy flag), started only through Tools' launcher
// (tools/machine/browser.mjs: guarded headless, below-normal, a time limit, the session name in its profile). Before any page script runs,
// the shell snippet (docs/audio/pending/audio-resume/shell-snippet.js) is installed, as it is in the exported page's head, and a scripted
// pad is put behind navigator.getGamepads; then an "engine" context is made and the page-side player (AudioWeb.JS_SOURCE) is installed.
//   node audio/tools/pad_start_check.mjs
// Exit code 1 on a failure. A scripted pad is NOT a real pad: whether a browser counts a real pad press as a gesture is what Orb's next
// file answers (the counters "pad seen / asked / woke" in the audio status line). What is proven here: both players ask on every kind of
// input, the browser does what a gesture is allowed to do, and nothing throws.
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { Cdp, launchBrowser, serve, browserExe } from '../../tools/machine/browser.mjs';

const here = dirname(fileURLToPath(import.meta.url));
const gd = readFileSync(join(here, '..', 'audio_web.gd'), 'utf8');
const m = /const JS_SOURCE := """\r?\n([\s\S]*?)"""/.exec(gd);
if (!m) { console.error('no JS_SOURCE in audio/audio_web.gd'); process.exit(2); }
const JS = m[1];
const SHELL = readFileSync(join(here, '..', '..', 'docs', 'audio', 'pending', 'audio-resume', 'shell-snippet.js'), 'utf8');
const PAD = `(function () { window.__pad = null; navigator.getGamepads = function () { return window.__pad ? [window.__pad] : []; }; })();`;
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
let fails = 0;
const ok = (c, msg) => { console.log(`  ${c ? 'ok  ' : 'FAIL'}  ${msg}`); if (!c) fails++; };
const info = (msg) => console.log(`  --    ${msg}`);

const server = await serve(here);
let browser = null, page = null;
try {
  browser = await launchBrowser({ exe: browserExe('chrome'), flags: ['--window-size=800,600'], session: process.env.MERIDIAN_SESSION || 'meridian-audio-music', purpose: 'padstart', timeoutS: 300, cpuPercent: 0, priority: 'belownormal', log: () => {} });
  page = await Cdp.open(browser.target.webSocketDebuggerUrl);
  await page.send('Page.enable');
  await page.send('Page.addScriptToEvaluateOnNewDocument', { source: PAD });
  await page.send('Page.addScriptToEvaluateOnNewDocument', { source: SHELL });
  await page.send('Emulation.setFocusEmulationEnabled', { enabled: true });
  const url = `http://127.0.0.1:${server.address().port}/`;
  const load = async () => { await page.send('Page.navigate', { url }); await sleep(700); await page.send('Page.bringToFront'); };
  const states = async () => JSON.parse(await page.eval(`JSON.stringify(window.__audioShell.contexts.map(function (c) { return c.state; }))`));
  const boot = async () => { await page.eval(`window.__engineCtx = new AudioContext(); window.__engineCtx.createGain().connect(window.__engineCtx.destination)`); await page.eval(JS, true); await sleep(300); };
  const pad = async (down) => page.eval(`window.__pad = ${down ? `{ connected: true, buttons: [{ pressed: true, value: 1 }], axes: [0, 0] }` : 'null'}`);
  const key = async () => { await page.send('Input.dispatchKeyEvent', { type: 'keyDown', key: 'a', code: 'KeyA', windowsVirtualKeyCode: 65, text: 'a' }); await page.send('Input.dispatchKeyEvent', { type: 'keyUp', key: 'a', code: 'KeyA', windowsVirtualKeyCode: 65 }); };
  const click = async () => { await page.send('Input.dispatchMouseEvent', { type: 'mousePressed', x: 100, y: 100, button: 'left', clickCount: 1 }); await page.send('Input.dispatchMouseEvent', { type: 'mouseReleased', x: 100, y: 100, button: 'left', clickCount: 1 }); };
  const aweb = async () => JSON.parse(await page.eval(`JSON.stringify({ running: window.__aweb.ctx.state, pad: window.__aweb.pad })`));
  const shellPad = async () => JSON.parse(await page.eval(`JSON.stringify(window.__audioShell.pad)`));

  console.log('1. no gesture at all (the page as Orb opened it): both contexts start suspended, and the browser says so');
  await load(); await boot();
  let s = await states();
  ok(s.length === 2 && s.every((x) => x === 'suspended'), `the engine's context and the player's are both suspended (${s})`);
  ok(await page.eval(`navigator.userActivation.hasBeenActive`) === false, 'and the page has had no activation');
  await sleep(500);
  s = await states();
  ok(s.every((x) => x === 'suspended'), 'a context nobody asks stays suspended');

  console.log('2. a scripted pad press with no activation: both ask, and the browser decides');
  await pad(true); await sleep(600);
  const sp = await shellPad(), ap = await aweb();
  ok(sp.seen >= 1 && sp.asks >= 2, `the shell asks both contexts on the press (seen ${sp.seen}, asked ${sp.asks})`);
  ok(ap.pad.seen >= 1 && ap.pad.asks >= 1, `and so does the player (seen ${ap.pad.seen}, asked ${ap.pad.asks})`);
  s = await states();
  info(`Chrome's answer to a pad press that is not a user activation: ${s.join(', ')} (shell woke ${sp.woke}, player woke ${ap.pad.woke})`);
  await pad(false);

  console.log('3. then a key (what Orb pressed at 178 s): both run at once');
  await key(); await sleep(500);
  s = await states();
  ok(s.every((x) => x === 'running'), `a key press runs both (${s})`);
  ok(await page.eval(`navigator.userActivation.hasBeenActive`) === true, 'it made an activation');

  console.log('4. after one activation, a pad alone is enough (a context suspended again, a pad press)');
  await page.eval(`window.__audioShell.contexts.forEach(function (c) { c.suspend(); })`);
  await sleep(400);
  s = await states();
  ok(s.every((x) => x === 'suspended'), 'both suspended again');
  await pad(true); await sleep(700); await pad(false);
  s = await states();
  const sp4 = await shellPad(), ap4 = await aweb();
  ok(s.every((x) => x === 'running'), `a pad press alone runs both (${s}; shell woke ${sp4.woke}, player woke ${ap4.pad.woke})`);
  ok(sp4.woke >= 1 && ap4.pad.woke >= 1, 'and the counters say the pad did it');

  console.log('5. a mouse click is a gesture too');
  await load(); await boot();
  s = await states();
  ok(s.every((x) => x === 'suspended'), 'a fresh page: suspended');
  await click(); await sleep(500);
  s = await states();
  ok(s.every((x) => x === 'running'), `a click runs both (${s})`);

  console.log('6. a context made after the player has pressed something runs at once (sticky activation)');
  await load();
  await key(); await sleep(200);
  await boot();
  s = await states();
  ok(s.length === 2 && s.every((x) => x === 'running'), `made after a key, both run with no further press (${s})`);

  console.log('7. a pad that is never touched costs nothing');
  await load(); await boot(); await sleep(300);
  ok(await page.eval(`window.__aweb.pad.seen === 0 && window.__audioShell.pad.seen === 0 && window.__aweb.pad.asks === 0`), 'no press: nothing seen, nothing asked');
  const line = await page.eval(`window.__audioShell.state() + ' || ' + window.__aweb.status()`);
  ok(/pad seen 0 asked 0 woke 0/.test(line), `the status carries the counters (${line.slice(0, 200)})`);
} catch (e) { console.log('FAILED: ' + e.message); fails++; }
finally { try { if (page) page.close(); } catch { /* gone */ } try { if (browser) await browser.close(); } catch { /* gone */ } server.close(); }
console.log(`\npad start check ${fails === 0 ? 'passed' : 'FAILED (' + fails + ')'}`);
process.exit(fails === 0 ? 0 : 1);
