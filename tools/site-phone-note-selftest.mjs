// Self-test of the phone note in a real browser (Legal's RL-201, ADR 0011). The page is made of the real pieces of the site (tools/site-interim.mjs: gateOverlay with the phone note, GATE_SCRIPT) around a stand-in
// engine whose start only sets window.__started. Through the guarded launcher (tools/machine/browser.mjs), one browser, below-normal priority, a time limit:
//   - a PHONE (390 x 844, touch, a coarse main pointer): the note shows over the gate, the gate is held aside; the note's button takes the note away, the game has NOT started (the button is not the notice's button),
//     the gate with the flashing notice and the lock line is there, unchanged; only the gate's own button starts the game;
//   - a computer (1280 x 720, mouse): no note at all, the gate as before;
//   - a small desktop WINDOW (390 wide, a mouse, a 1920 x 1080 screen), a TABLET (768 x 1024, touch) and a TOUCH LAPTOP (1366 x 768, touch events and a mouse): no note.
// Needs Chrome or Edge (--require-browser makes its absence a failure). With --stills <dir> it also writes the pictures of the report: phone-note-phone.png (the note on a phone), phone-note-phone-after.png (after
// "Continue anyway": the notice) and phone-note-desktop.png (a computer: no note).
//   node tools/site-phone-note-selftest.mjs [--require-browser] [--browser-path <exe>] [--stills <dir>]
import { mkdtempSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { Cdp, launchBrowser, serve, browserExe } from './machine/browser.mjs';
import { gateOverlay, GATE_SCRIPT, PHONE_NOTE } from './site-interim.mjs';

const argv = process.argv.slice(2);
const opt = (n) => { const i = argv.indexOf(n); return i >= 0 ? argv[i + 1] : undefined; };
const exe = opt('--browser-path') || browserExe('chrome') || browserExe('edge');
if (!exe) { console.log(argv.includes('--require-browser') ? 'phone note self-test FAILED: no chrome or edge executable' : 'phone note self-test skipped: no chrome or edge executable'); process.exit(argv.includes('--require-browser') ? 1 : 0); }
const stills = opt('--stills');
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const words = JSON.parse(readFileSync(new URL('./site-interim-owner.json', import.meta.url), 'utf8'));
const page = `<!doctype html>
<html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, user-scalable=no"><title>Orb Combat EX</title></head>
<body>
${gateOverlay(words, { holding: '../', about: '../about/' })}
<canvas id="canvas" width="300" height="150"></canvas>
<script>window.__started = false; window.__startGame = function () { window.__started = true; };</script>
${GATE_SCRIPT}
</body></html>
`;

let ran = 0, failed = 0;
const check = (name, ok, extra) => { ran++; if (!ok) { failed++; console.log(`  FAIL ${name}${extra ? ': ' + extra : ''}`); } };

const tmp = mkdtempSync(join(tmpdir(), 'phone-note-'));
mkdirSync(join(tmp, 'site'), { recursive: true });
writeFileSync(join(tmp, 'site', 'index.html'), page);
const server = await serve(join(tmp, 'site'));
const url = `http://127.0.0.1:${server.address().port}/`;
let browser = null, cdp = null;
try {
  browser = await launchBrowser({ exe, flags: ['--window-size=1400,900'], session: 'tools', purpose: 'phonenote', timeoutS: 240, log: () => {} });
  cdp = await Cdp.open(browser.target.webSocketDebuggerUrl);
  await cdp.send('Page.enable');
  const state = () => cdp.eval(`JSON.stringify({
    note: (() => { const n = document.getElementById('phone-note'); return n ? { hidden: n.hidden, shown: n.getBoundingClientRect().height > 0, heading: n.querySelector('h1').innerText, body: n.querySelector('p').innerText, button: n.querySelector('button').innerText } : null; })(),
    gate: (() => { const g = document.getElementById('gate'); return g ? { inert: g.hasAttribute('inert'), text: g.innerText } : null; })(),
    started: window.__started,
    coarse: matchMedia('(pointer: coarse)').matches, screen: Math.min(screen.width, screen.height)
  })`).then((s) => JSON.parse(s));
  const open = async (o) => {
    await cdp.send('Emulation.clearDeviceMetricsOverride').catch(() => {});
    await cdp.send('Emulation.setTouchEmulationEnabled', { enabled: !!o.touch, maxTouchPoints: o.touch ? 5 : 1 }).catch(() => {});
    await cdp.send('Emulation.setDeviceMetricsOverride', { width: o.width, height: o.height, deviceScaleFactor: o.dpr || 1, mobile: !!o.mobile, screenWidth: o.screenWidth || o.width, screenHeight: o.screenHeight || o.height });
    await cdp.send('Page.navigate', { url });
    while ((await cdp.eval('document.readyState').catch(() => '')) !== 'complete') await sleep(100);
    await sleep(500);
  };
  const shot = async (name) => { if (!stills) return; mkdirSync(stills, { recursive: true }); const s = await cdp.send('Page.captureScreenshot', { format: 'png' }); writeFileSync(join(stills, name), Buffer.from(s.data, 'base64')); };
  const tap = async (id) => {   // a real touch at the middle of the element
    const r = JSON.parse(await cdp.eval(`(() => { const b = document.getElementById(${JSON.stringify(id)}).getBoundingClientRect(); return JSON.stringify({ x: b.left + b.width / 2, y: b.top + b.height / 2 }); })()`));
    await cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x: r.x, y: r.y }] });
    await cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
    await sleep(300);
  };

  // a phone
  await open({ width: 390, height: 844, dpr: 2, mobile: true, touch: true });
  let s = await state();
  check('a phone (390 x 844, touch) has a coarse main pointer in this browser, so the test is real', s.coarse === true && s.screen === 390, JSON.stringify(s));
  check('a phone sees the note, with Legal\'s three lines word for word', s.note && s.note.shown && s.note.heading === PHONE_NOTE.heading && s.note.body === PHONE_NOTE.body && s.note.button === PHONE_NOTE.button && s.note.heading === 'Best on a computer' && s.note.button === 'Continue anyway', JSON.stringify(s.note));
  check('the gate is under the note and held aside (inert) while the note is up; the game has not started', s.gate && s.gate.inert === true && s.started === false);
  await shot('phone-note-phone.png');
  await tap('phone-note-continue');
  s = await state();
  check('the note\'s button takes the note away', s.note === null, JSON.stringify(s.note));
  check('the note\'s button does not start the game: it does not count as seeing the notice', s.started === false);
  check('after the button the gate is there, no longer held aside, with the flashing notice and the lock line unchanged', s.gate && s.gate.inert === false && s.gate.text.includes(words.gate.blocks[0].p) && s.gate.text.includes(words.gate.under) && s.gate.text.includes(words.gate.button), JSON.stringify(s.gate && s.gate.text.slice(0, 120)));
  await shot('phone-note-phone-after.png');
  await tap('gate-start');
  s = await state();
  check('only the gate\'s own button starts the game', s.started === true && s.gate === null);

  // a computer
  await open({ width: 1280, height: 720 });
  s = await state();
  check('a computer sees no note at all, and the gate is as before', s.note === null && s.gate && s.gate.inert === false && s.started === false && s.gate.text.includes(words.gate.blocks[0].p), JSON.stringify(s));
  await shot('phone-note-desktop.png');
  await cdp.send('Emulation.setDeviceMetricsOverride', { width: 1280, height: 720, deviceScaleFactor: 1, mobile: false });
  await cdp.eval(`document.getElementById('gate-start').click()`);
  check('on a computer the gate\'s button starts the game as before', (await state()).started === true);

  // not phones
  await open({ width: 390, height: 800, screenWidth: 1920, screenHeight: 1080 });
  s = await state();
  check('a narrow desktop window (a mouse, a 1920 x 1080 screen) sees no note', s.note === null && s.coarse === false, JSON.stringify(s));
  await open({ width: 768, height: 1024, dpr: 2, mobile: true, touch: true });
  s = await state();
  check('a tablet (768 x 1024, touch) sees no note', s.coarse === true && s.screen === 768 && s.note === null, JSON.stringify(s));
  await open({ width: 1366, height: 768, touch: true });
  s = await state();
  check('a touch laptop (1366 x 768, touch events) sees no note', s.screen === 768 && s.note === null, JSON.stringify(s));
  await open({ width: 844, height: 390, dpr: 2, mobile: true, touch: true });
  s = await state();
  check('a phone held sideways (844 x 390) still sees the note', s.screen === 390 && s.note && s.note.shown, JSON.stringify(s));
} finally {
  try { if (cdp) cdp.close(); } catch { /* gone */ }
  if (browser) await browser.close();
  server.close();
  rmSync(tmp, { recursive: true, force: true });
}
console.log(failed ? `phone note self-test FAILED: ${failed} of ${ran}` : `phone note self-test ok: ${ran} checks`);
process.exit(failed ? 1 : 0);
