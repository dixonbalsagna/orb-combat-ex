// Boot-and-play smoke check of a private preview build (tools/preview/preview.mjs, docs/tools/preview.md). It serves the built folder on localhost, starts the one guarded browser of
// tools/machine/browser.mjs (time limit, below-normal priority, a CPU cap, a profile folder with its owner's name), opens the page with ?planet=N&preview=1, and checks:
//   1. it boots: the game's own probe (window.__preview, put in the scratch copy's main.gd) appears, and the page raised no error (a script exception, a console error);
//   2. it plays: the probe's tick advances, keys sent to the page leave it running, and the canvas is drawn;
//   3. the switches read as asked: every switch the probe reports equals what the preview turned on or off, the planet is a generated planet of the right generation, and the water loader's own
//      errors list is empty.
// A failure names the switch it points at, when the error names a file or module that belongs to one (switches.mjs errorSwitch).
//
//   node tools/preview/smoke.mjs --dir <built web folder> [--on gen2,biome,water,surface,interrupts,floor] [--planet 7] [--timeout 240] [--shot file.png] [--session tools-preview] [--browser-path <exe>]
//   Exit 0 passed, 1 failed (the problems are printed), 2 usage or no browser.
import { existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { dirname, resolve, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { Cdp, launchBrowser, serve, browserExe } from '../machine/browser.mjs';
import { IDS, errorSwitch } from './switches.mjs';

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

/** What the probe must read, given the switches that are on. Pure. */
export function expectations(on, { planet = true } = {}) {
  const set = new Set(on);
  return {
    planet,
    planetGen: set.has('gen2') ? 2 : 1,
    dataGen: set.has('gen2') ? 2 : 1,
    biome: set.has('biome'), water: set.has('water'), surface: set.has('surface'), floor: set.has('floor'), interrupts: set.has('interrupts'),
  };
}

/** The problems with a probe reading against the expectations, each naming its switch. Pure. */
export function probeProblems(probe, want) {
  const out = [];
  if (!probe) return ['the page never published its state (window.__preview): the game did not get as far as its first frames'];
  for (const k of ['planetGen', 'dataGen']) if (probe[k] !== want[k]) out.push({ sw: 'gen2', text: `${k} reads ${probe[k]}, expected ${want[k]}` });
  if ((probe.fine > 0) !== (want.planetGen === 2)) out.push({ sw: 'gen2', text: `the planet has ${probe.fine} fine-biome columns, expected ${want.planetGen === 2 ? 'some (a gen 2 planet)' : 'none (the stored planet)'}` });
  if (probe.planet !== want.planet) out.push({ sw: 'gen2', text: `the match ${probe.planet ? 'is' : 'is not'} a generated planet, expected ${want.planet ? 'one' : 'the hand-made world'}` });
  for (const k of ['biome', 'water', 'surface', 'floor', 'interrupts']) if (probe[k] !== want[k]) out.push({ sw: k, text: `${k} reads ${probe[k]} in the running game, expected ${want[k]}` });
  for (const e of probe.errors || []) out.push({ sw: errorSwitch(e) || 'water', text: `water loader: ${e}` });
  return out.map((p) => (typeof p === 'string' ? { sw: null, text: p } : p));
}

const KEYS = [  // [key, code, windowsVirtualKeyCode]: the game's keyboard layout for player 1 (move, dash, the three strengths)
  ['d', 'KeyD', 68], ['a', 'KeyA', 65], ['w', 'KeyW', 87], [' ', 'Space', 32], ['x', 'KeyX', 88], ['c', 'KeyC', 67], ['v', 'KeyV', 86],
];

/** Runs the check; resolves { ok, problems: [{ sw, text }], notes, probe, shot }. Throws only for a missing browser or a missing folder. */
export async function smoke({ dir, on = IDS, planet = 7, timeoutS = 240, shot, session = 'tools-preview', exe, log = () => {}, extraQuery = '' }) {
  const root = resolve(dir);
  if (!existsSync(join(root, 'index.html'))) throw new Error(`${join(root, 'index.html')} does not exist: build the preview first`);
  const browserPath = exe || browserExe('chrome') || browserExe('edge');
  if (!browserPath) throw Object.assign(new Error('no chrome or edge executable found (pass --browser-path)'), { code: 'NO_BROWSER' });
  const want = expectations(on);
  const problems = [], notes = [];
  const add = (sw, text) => problems.push({ sw: sw || null, text });
  const server = await serve(root);
  const port = server.address().port;
  let browser = null, page = null, probe = null;
  const consoleErrors = [];
  try {
    browser = await launchBrowser({ exe: browserPath, session, purpose: 'preview', timeoutS: timeoutS + 120, cpuPercent: 25, log, flags: ['--window-size=1280,720', '--autoplay-policy=no-user-gesture-required'] });
    page = await Cdp.open(browser.target.webSocketDebuggerUrl);
    await page.send('Page.enable'); await page.send('Runtime.enable'); await page.send('Log.enable');
    await page.send('Emulation.setDeviceMetricsOverride', { width: 1280, height: 720, deviceScaleFactor: 1, mobile: false });
    page.ws.addEventListener('message', (e) => {
      const m = JSON.parse(e.data);
      if (m.method === 'Runtime.exceptionThrown') consoleErrors.push(`exception: ${m.params.exceptionDetails.exception?.description || m.params.exceptionDetails.text}`);
      if (m.method === 'Runtime.consoleAPICalled' && m.params.type === 'error') consoleErrors.push(`console.error: ${m.params.args.map((a) => a.value ?? a.description ?? '').join(' ')}`);
      if (m.method === 'Log.entryAdded' && m.params.entry.level === 'error' && !/favicon|manifest\.webmanifest|Failed to load resource: the server responded with a status of 404/i.test(m.params.entry.text + (m.params.entry.url || ''))) consoleErrors.push(`log: ${m.params.entry.text}`);
    });
    const url = `http://127.0.0.1:${port}/index.html?planet=${planet}&preview=1${extraQuery ? `&${extraQuery}` : ''}`;
    log(`opening ${url}`);
    await page.send('Page.navigate', { url });
    const deadline = Date.now() + timeoutS * 1000;
    const read = async () => { try { const v = await page.eval('window.__preview ? JSON.stringify(window.__preview) : ""'); return v ? JSON.parse(v) : null; } catch { return null; } };
    // 1. boot: the probe appears and the match has ticks
    let p = null;
    while (Date.now() < deadline) { p = await read(); if (p) break; await sleep(500); }
    if (!p) { add(null, `the game did not boot within ${timeoutS} s (no window.__preview)`); }
    else {
      notes.push(`booted at tick ${p.tick}`);
      // 2. play: focus the canvas, press keys in turn for a while, and see the match go on
      const click = async (x, y) => { await page.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x, y }); await page.send('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', clickCount: 1 }); await page.send('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', clickCount: 1 }); };
      const press = async (k, ms) => {
        const text = k[0] === 'Enter' ? '\r' : k[0].length === 1 ? k[0] : undefined;   // a key that types a character carries it; the protocol refuses a name in `text`
        await page.send('Input.dispatchKeyEvent', { type: text === undefined ? 'rawKeyDown' : 'keyDown', key: k[0], code: k[1], windowsVirtualKeyCode: k[2], ...(text === undefined ? {} : { text }) });
        await sleep(ms);
        await page.send('Input.dispatchKeyEvent', { type: 'keyUp', key: k[0], code: k[1], windowsVirtualKeyCode: k[2] });
      };
      // a fresh profile meets the How to play card (its close button) and the flashing notice with the start menu ("I understand, start"): the match is held behind them, so click through and
      // watch the tick; the planet match is made at the start (one synchronous call), so it may take a few seconds to come up
      for (let tries = 0; tries < 30 && Date.now() < deadline; tries++) {
        const before = (await read()) || p;
        await sleep(2500);
        const after = (await read()) || before;
        if (after.tick > before.tick + 30) { notes.push(`the match was running after ${tries} rounds of clicks`); break; }
        await click(1099, 195); await sleep(1200); await click(640, 503); await sleep(1200);   // each round: close a card if one is up, start if the menu is up (a click on the running game does nothing)
      }
      const t1 = ((await read()) || p).tick;
      const playUntil = Math.min(deadline, Date.now() + 20000);
      for (let i = 0; Date.now() < playUntil; i++) { await press(KEYS[i % KEYS.length], 250); await sleep(150); }
      p = (await read()) || p;
      notes.push(`after play: tick ${p.tick} (${p.tick - t1} more in the keys' 20 s), hp ${JSON.stringify(p.hp)}`);
      if (p.tick - t1 < 120) add(null, `the match did not play on: ${p.tick - t1} ticks in about 20 s of keys (it was at tick ${t1}; the How to play card or the start menu may still be up)`);
      probe = p;
      for (const x of probeProblems(p, want)) add(x.sw, x.text);
      const lit = await page.eval('(() => { const c = document.querySelector("canvas"); return !!c && c.width > 0 && c.height > 0; })()');
      if (!lit) add(null, 'no canvas on the page');
      if (shot) {
        const r = await page.send('Page.captureScreenshot', { format: 'png' });
        mkdirSync(dirname(resolve(shot)), { recursive: true });
        writeFileSync(resolve(shot), Buffer.from(r.data, 'base64'));
        notes.push(`picture ${resolve(shot)}`);
      }
    }
    const seen = [...new Set(consoleErrors)];
    for (const e of seen.slice(0, 12)) add(errorSwitch(e), e.slice(0, 300));
    if (seen.length > 12) notes.push(`${seen.length - 12} more errors not listed`);
  } finally {
    try { page && page.close(); } catch { /* gone */ }
    try { browser && (await browser.close()); } catch { /* gone */ }
    server.close();
  }
  return { ok: problems.length === 0, problems, notes, probe, shot: shot ? resolve(shot) : null };
}

/** The report lines of a result: the problems grouped under the switch they point at. */
export function describe(r) {
  const lines = [];
  for (const n of r.notes) lines.push(`  ${n}`);
  if (r.ok) { lines.push('  smoke check passed'); return lines; }
  const bySw = new Map();
  for (const p of r.problems) { const k = p.sw || 'unattributed'; bySw.set(k, [...(bySw.get(k) || []), p.text]); }
  for (const [k, texts] of bySw) {
    lines.push(`  FAILED${k === 'unattributed' ? '' : ` — points at the switch "${k}"`}:`);
    for (const t of texts) lines.push(`    ${t}`);
  }
  return lines;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const a = process.argv.slice(2);
  const opt = (n, d) => { const i = a.indexOf(n); return i >= 0 && i + 1 < a.length ? a[i + 1] : d; };
  if (!opt('--dir')) { console.error('usage: node tools/preview/smoke.mjs --dir <built web folder> [--on ids] [--planet 7] [--timeout 240] [--shot file.png] [--session name] [--browser-path exe]'); process.exit(2); }
  try {
    const r = await smoke({ dir: opt('--dir'), on: opt('--on') !== undefined ? opt('--on').split(',').filter(Boolean) : IDS, planet: Number(opt('--planet', 7)), timeoutS: Number(opt('--timeout', 240)), shot: opt('--shot'), session: opt('--session', 'tools-preview'), exe: opt('--browser-path'), log: (m) => console.log(`[smoke] ${m}`) });
    for (const l of describe(r)) console.log(l);
    process.exit(r.ok ? 0 : 1);
  } catch (e) { console.error(`smoke: ${e.message}`); process.exit(e.code === 'NO_BROWSER' ? 2 : 1); }
}
