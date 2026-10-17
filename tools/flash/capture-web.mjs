// Captures a worst-case clip from a web page, one PNG per sim tick, for tools/flash/analyse-frames.js. Node 24 built-ins only; drives headless Chrome (or Edge) over the
// DevTools protocol, with a fresh temporary profile that is always deleted. The browser comes from tools/machine/browser.mjs (guards: docs/tools/machine-captures.md).
//
//   node tools/flash/capture-web.mjs --dir <built site dir> --path /play/ --scenario mash --ticks 1800 --out <folder> [--reduced] [--width 960 --height 540]
//   node tools/flash/capture-web.mjs --url <page url> --scenario mash ...        a page that is already served
//   node tools/flash/capture-web.mjs --mock --scenario strobe4 --out <folder>    the self-test page (tools/flash/mock-page/), which flashes on purpose
//
// THE CONTRACT (what a page must offer so a clip is exactly one tick a frame; the build does not offer it yet, docs/tools/flash-check.md):
//   (the game's hook, Rendering's, is offered at /play/?flashcap=1 and also gives in_window, the register's count after each step, and error; both are recorded)
//   window.__flashcap = {
//     ready:  true once the scene is built and the first frame is up,
//     start:  (scenario, { reduced }) => void   sets the scene up as tools/flash/flash_worst.gd does and PAUSES the sim,
//     step:   () => Promise<number>             runs exactly one sim tick, draws it, and resolves with the tick once that frame is on screen,
//     tick:   number                            the sim tick now shown,
//   }
// The driver calls start(), then for each of `ticks` ticks step() followed by Page.captureScreenshot, so no frame is skipped or doubled whatever the machine's speed.
// Output: <out>/frame-000001.png ... and <out>/clip.json ({ scenario, reduced, fps: 60, ticks, width, height, page }).
import { existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { Cdp, launchBrowser, serve, browserExe, cpuLoad } from '../machine/browser.mjs';   // the one guarded launcher (docs/tools/machine-captures.md)

const argv = process.argv.slice(2);
const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
const has = (n) => argv.includes(n);
const usage = () => {
  console.error('usage: node tools/flash/capture-web.mjs (--dir <site dir> [--path /play/] | --url <page url> | --mock) --scenario <id> --out <folder>\n' +
    '       [--ticks 1800] [--reduced] [--seed N] [--slots A,B] [--skip N] [--width 960] [--height 540] [--software] [--browser chrome|edge] [--browser-path <exe>] [--timeout 900]\n       [--session <name>] [--time-limit <hard limit, seconds>] [--cpu-cap 25]');
  process.exit(2);
};
const known = new Set(['--dir', '--path', '--url', '--mock', '--scenario', '--out', '--ticks', '--reduced', '--seed', '--slots', '--skip', '--variant', '--width', '--height', '--software', '--budget', '--hold', '--merge-zoom', '--legacy-hook', '--browser', '--browser-path', '--timeout', '--session', '--purpose', '--time-limit', '--cpu-cap']);
for (const a of argv) if (a.startsWith('--') && !known.has(a)) { console.error(`unknown option ${a}`); usage(); }
const here = dirname(fileURLToPath(import.meta.url));
const DIR = has('--mock') ? join(here, 'mock-page') : opt('--dir');
const URL_ = opt('--url');
const SCENARIO = opt('--scenario');
const OUT = opt('--out');
if (!SCENARIO || !OUT || (!DIR && !URL_) || (DIR && URL_)) usage();
const TICKS = Number(opt('--ticks', 1800));
const WIDTH = Number(opt('--width', 960)), HEIGHT = Number(opt('--height', 540));
const REDUCED = has('--reduced');
const SEED = opt('--seed') === undefined ? null : Number(opt('--seed'));
const SLOTS = opt('--slots') ? opt('--slots').split(',') : null;      // a pairing: two roster ids (the hook may not offer it yet)
const VARIANT = opt('--variant') === undefined ? 0 : Number(opt('--variant'));   // a different run of a fixed scene (the hook's variant)
const SKIP = opt('--skip') === undefined ? null : Number(opt('--skip'));   // ticks to run without drawing before the clip starts (the hook may not offer it yet)
const TIMEOUT_S = Number(opt('--timeout', 900));
const BROWSER = opt('--browser', 'chrome');
const exe = opt('--browser-path') || browserExe(BROWSER);
if (!exe) { console.error(`no ${BROWSER} executable found; pass --browser-path`); process.exit(2); }
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const log = (m) => console.log(`[capture-web] ${m}`);

let server;
let pageUrl = URL_;
if (DIR) {
  server = await serve(DIR);   // no cross-origin isolation headers: this page has always been served without them
  pageUrl = `http://127.0.0.1:${server.address().port}${has('--mock') ? '/' : opt('--path', '/play/')}`;
}
// Camera's travel budget (SplitRig.travel_budget, off by default): the page's `budget=1` switches it on for the hook (render/tools/flash_capture.gd), so a run with and without it is the same sim
if (has('--budget') && !has('--mock')) pageUrl += (pageUrl.includes('?') ? '&' : '?') + 'budget=1';
// Camera's launch hold (SplitRig.launch_hold, off by default): the page's `hold=1`, read by the hook the same way
if (has('--hold') && !has('--mock')) pageUrl += (pageUrl.includes('?') ? '&' : '?') + 'hold=1';
// Camera's merge-zoom limit (SplitRig.merge_zoom_limit, off by default): the page's `mergezoom=1`
if (has('--merge-zoom') && !has('--mock')) pageUrl += (pageUrl.includes('?') ? '&' : '?') + 'mergezoom=1';
mkdirSync(OUT, { recursive: true });
// The browser is started by tools/machine/browser.mjs: a hard time limit (--time-limit, default the page timeout plus 5 minutes), below-normal priority, a CPU cap (--cpu-cap, default 25% of the
// machine), a profile folder cap-<session>-flash-<id>, gone when this process is. A cold machine can take far longer than a warm one to open its DevTools port; it waits up to 90 s and tries 3 times.
const extraFlags = [`--window-size=${WIDTH},${HEIGHT}`, ...(has('--software') ? ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] : [])];
let browser = null;
async function launchBrowserGuarded() {
  browser = await launchBrowser({ exe, flags: extraFlags, session: opt('--session'), purpose: opt('--purpose', 'flash'), timeoutS: Number(opt('--time-limit', TIMEOUT_S + 300)), cpuPercent: Number(opt('--cpu-cap', 25)), log });
  return browser.target;
}
const cleanup = async () => {
  if (browser) await browser.close();
  browser = null;
  if (server) server.close();
};
let page, code = 0;
let applied = null;   // the switches the page reports it set (budget, hold)
try {
  const loadBefore = await cpuLoad(1000);   // the machine's load before this capture starts: a recorded condition of a release pass (a starved machine voids a clip)
  const target = await launchBrowserGuarded();
  page = await Cdp.open(target.webSocketDebuggerUrl);
  await page.send('Emulation.setDeviceMetricsOverride', { width: WIDTH, height: HEIGHT, deviceScaleFactor: 1, mobile: false });
  await page.send('Page.navigate', { url: pageUrl });
  const deadline = Date.now() + TIMEOUT_S * 1000;
  let ready = false;
  while (Date.now() < deadline && !ready) { await sleep(500); ready = await page.eval('Boolean(window.__flashcap && window.__flashcap.ready)').catch(() => false); }
  if (!ready) throw new Error(`the page offers no window.__flashcap that becomes ready (the contract is at the top of tools/flash/capture-web.mjs); the build does not have it yet`);
  await page.eval(`window.__flashcap.start(${JSON.stringify(SCENARIO)}, { reduced: ${REDUCED}${SEED === null ? '' : ', seed: ' + SEED}${SLOTS ? ', slots: ' + JSON.stringify(SLOTS) : ''}${SKIP === null ? '' : ', skip: ' + SKIP}${VARIANT ? ', variant: ' + VARIANT : ''} })`);
  log(`${pageUrl}: ${SCENARIO}${REDUCED ? ' (reduced)' : ''}, ${TICKS} ticks at ${WIDTH}x${HEIGHT}`);
  let last = -1;
  const tStart = Date.now();
  const inWindow = [];
  let modeRead = null;   // the mode the running game reports after its first tick: UI's Reduce flashing and the calm look (Legal addendum 10: read back, per clip)
  const probe = {};      // md5 of the frame at a few ticks: the pass file compares a clip's two modes with them (a pair that shows the same pictures was not measured in two modes)
  for (let i = 1; i <= TICKS; i++) {
    if (Date.now() > deadline) throw new Error(`timed out after ${i - 1} ticks`);
    const got = await page.eval('window.__flashcap.step().then((t) => ({ tick: t, win: window.__flashcap.in_window, err: window.__flashcap.error || null, sw: window.__flashcap.switches || null, mode: window.__flashcap.mode || null }))', true);
    const tick = got && got.tick;
    if (got && got.err) throw new Error(`the page reported an error: ${got.err}`);
    if (i === 1) {
      // a switch asked for and not applied is a clip of the wrong build, not a clip of the switch: the hook reports what it set (render/tools/flash_capture.gd `switches`).
      // (Until docs/tools/pending/flash-capture-page-flags.patch the hook read main.args, which keeps only URL_ARGS: budget=1 and hold=1 never reached it.)
      applied = got && got.sw ? got.sw : null;
      for (const [flag, key] of [['--budget', 'budget'], ['--hold', 'hold'], ['--merge-zoom', 'mergezoom']]) {
        if (has(flag) && !has('--mock') && !(applied && applied[key] === true)) throw new Error(`${flag} was asked for and the page did not apply it (the hook reports ${JSON.stringify(applied)}): the build's hook is older than flash-capture-page-flags.patch`);
      }
    }
    if (i === 1 && !has('--mock') && !has('--legacy-hook')) {
      // the clip's mode is UI's Reduce flashing and the calm look, not only the register's cap (the option defaults to ON: until flash-capture-reduce-flashing.patch a normal clip was the calm look).
      // A hook that does not report it, or reports the other mode, makes a clip of the wrong look: refuse it.
      if (!(applied && applied.reduce_flashing === REDUCED) || !(got && got.mode && got.mode.reduce_flashing === REDUCED && got.mode.flash_calm === REDUCED)) throw new Error(`the page did not take the clip's mode (${REDUCED ? 'reduced' : 'normal'}): it reports ${JSON.stringify({ applied: applied && applied.reduce_flashing, mode: got && got.mode })}; the build's hook is older than flash-capture-reduce-flashing.patch`);
    }
    if (i === 1) modeRead = got && got.mode ? got.mode : null;
    inWindow.push(got && typeof got.win === 'number' ? got.win : null);
    if (typeof tick !== 'number' || tick <= last) throw new Error(`step() returned ${tick} after ${last}: the page did not advance exactly one tick`);
    last = tick;
    const shot = await page.send('Page.captureScreenshot', { format: 'png', fromSurface: true });
    const png = Buffer.from(shot.data, 'base64');
    if (i === 60 || i === 180 || i === 300 || i === 600 || i === 1200 || i === 2400) probe[i] = createHash('md5').update(png).digest('hex');
    writeFileSync(join(OUT, `frame-${String(i).padStart(6, '0')}.png`), png);
  }
  const loadAfter = await cpuLoad(1000);
  const guard = browser ? { tag: String(browser.profile).split(/[\\/]/).pop(), session: browser.entry.session, purpose: browser.entry.purpose, cpuPercent: browser.entry.cpuPercent, timeoutS: browser.entry.timeoutS, priority: 'below-normal', hardEndMs: browser.deadlineMs } : null;
  writeFileSync(join(OUT, 'clip.json'), JSON.stringify({ scenario: SCENARIO, seed: SEED, reduced: REDUCED, fps: 60, inWindow, ticks: TICKS, width: WIDTH, height: HEIGHT, mode: modeRead, probe, budget: has('--budget'), hold: has('--hold'), mergeZoom: has('--merge-zoom'), applied, variant: VARIANT, page: pageUrl, guard, loadBefore, loadAfter, framesPerSecond: Math.round((TICKS / Math.max(1, (Date.now() - tStart) / 1000)) * 100) / 100 }, null, 2) + '\n');
  log(`${TICKS} frames in ${Math.round((Date.now() - tStart) / 1000)} s of capture (${(TICKS / Math.max(1, (Date.now() - tStart) / 1000)).toFixed(2)} frames a second${has('--software') ? ', software rendering' : ''})`);
  log(`wrote ${TICKS} frames to ${OUT}; next: node tools/flash/analyse-frames.js ${OUT}`);
} catch (e) {
  console.error(`[capture-web] FAILED: ${e.message}`);
  code = 1;
} finally {
  if (page) page.close();
  await cleanup();
}
process.exit(code);
