// A reel of a real AI match on the stack page (the EP, 2026-10-31: "I can't watch the page: my pane is hidden and its rAF stalls"): the page's build is stepped one tick a frame through Tools' guarded
// launcher (the flash capture hook, ?flashcap=1, as tools/flash/capture-web.mjs does it), a still every 30 ticks, and the page's own state probe (?preview=1&reel=1) is read after every step, so each still says
// what the swing is doing and why. Private: the output is a folder of contact sheets and a record, never published. Node 24 built-ins only.
//
//   node tools/preview/reel.mjs --dir <built web folder> --out <folder> [--seed 12345] [--every 30] [--swings 2] [--launches 1] [--cap 6000] [--margin 60] [--width 960 --height 540] [--planet 7] [--query "meteor=loud&tiles=1"]
//
// It plays the hook's `ai` scenario (a real AI match) on the page's planet until it has seen --swings complete swings and --launches launch(es), then --margin more ticks, or --cap ticks. Stills are kept for the
// ticks within --margin of a swing or a launch. Output: <out>/sheet-1.png ... (contact sheets of 12, the corner of each still reading the tick, the swing's state, rate, degrees left and cause, and the fighters'
// states), <out>/reel.json (every swing and launch with its ticks, the picture list, the page's build), <out>/stills/ (the individual JPEGs).
import { mkdirSync, writeFileSync, rmSync, existsSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { Cdp, launchBrowser, serve, browserExe } from '../machine/browser.mjs';

const argv = process.argv.slice(2);
const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
const DIR = opt('--dir'), OUT = opt('--out');
if (!DIR || !OUT) { console.error('usage: node tools/preview/reel.mjs --dir <built web folder> --out <folder> [--seed N] [--every 30] [--swings 2] [--launches 1] [--cap 6000] [--margin 60]'); process.exit(2); }
const SEED = Number(opt('--seed', 12345)), EVERY = Number(opt('--every', 30)), NSWING = Number(opt('--swings', 2)), NLAUNCH = Number(opt('--launches', 1));
const CAP = Number(opt('--cap', 6000)), MARGIN = Number(opt('--margin', 60));
const W = Number(opt('--width', 960)), H = Number(opt('--height', 540)), PLANET = Number(opt('--planet', 7));
const QUERY = opt('--query', 'meteor=loud&tiles=1');
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const log = (m) => console.log(`[reel] ${m}`);
const exe = browserExe('chrome');
if (!exe) { console.error('no chrome found'); process.exit(2); }

mkdirSync(join(OUT, 'stills'), { recursive: true });
const server = await serve(resolve(DIR));
const url = `http://127.0.0.1:${server.address().port}/index.html?flashcap=1&preview=1&reel=1&planet=${PLANET}&${QUERY}`;
let browser = null, page = null, code = 0;
const record = { url, seed: SEED, every: EVERY, swings: [], launches: [], pictures: [], ticks: 0, planetGen: null, note: '' };
try {
  browser = await launchBrowser({ exe, flags: [`--window-size=${W},${H}`], session: process.env.MERIDIAN_SESSION || 'tools-pipeline', purpose: 'reel', timeoutS: 1500, cpuPercent: 25, log });
  page = await Cdp.open(browser.target.webSocketDebuggerUrl);
  await page.send('Emulation.setDeviceMetricsOverride', { width: W, height: H, deviceScaleFactor: 1, mobile: false });
  await page.send('Page.navigate', { url });
  const deadline = Date.now() + 900 * 1000;
  let ready = false;
  while (Date.now() < deadline && !ready) { await sleep(500); ready = await page.eval('Boolean(window.__flashcap && window.__flashcap.ready)').catch(() => false); }
  if (!ready) throw new Error('the page offers no window.__flashcap that becomes ready (is it an export with the capture hook, and ?flashcap=1 allowed?)');
  await page.eval(`window.__flashcap.start("ai", { reduced: false, seed: ${SEED} })`, true);
  log(`${url}: the hook's ai scenario, seed ${SEED}, ${W}x${H}, until ${NSWING} swing(s) and ${NLAUNCH} launch(es) have been seen`);
  let last = -1, curSwing = null, lastLn = [0, 0], doneAt = -1;
  const shots = new Map();   // tick -> { file, pv }
  for (let i = 1; i <= CAP; i++) {
    if (Date.now() > deadline) throw new Error(`timed out after ${i - 1} ticks`);
    const got = await page.eval('window.__flashcap.step().then((t) => ({ tick: t, err: window.__flashcap.error || null, pv: window.__preview || null }))', true);
    if (got && got.err) throw new Error(`the page reported an error: ${got.err}`);
    const tick = got && got.tick;
    if (typeof tick !== 'number' || tick <= last) throw new Error(`step() returned ${tick} after ${last}`);
    last = tick;
    const pv = got.pv;
    if (pv && record.planetGen === null) { record.planetGen = pv.planetGen; if (pv.swing === undefined) record.note = 'the page reports no swing state (not a field world, or the swing switch is off in this build)'; }
    // events, from the probe read after this tick
    if (pv && pv.swing) {
      if (pv.swing.on && !curSwing) { curSwing = { start: tick, end: null, cause: pv.swing.cause, kind: pv.swing.kind, maxRate: 0, n: pv.swings }; record.swings.push(curSwing); }
      if (pv.swing.on && curSwing) { curSwing.maxRate = Math.max(curSwing.maxRate, Math.abs(pv.swing.rate)); if (!curSwing.cause) curSwing.cause = pv.swing.cause; }
      if (!pv.swing.on && curSwing) { curSwing.end = tick; curSwing = null; }
    }
    if (pv && pv.ln) { for (let k = 0; k < 2; k++) if (pv.ln[k] > lastLn[k]) record.launches.push({ tick, fighter: k, n: pv.ln[k], states: pv.fst }); lastLn = pv.ln; }
    if (tick % EVERY === 0) {
      const shot = await page.send('Page.captureScreenshot', { format: 'jpeg', quality: 72, fromSurface: true });
      const file = `still-${String(tick).padStart(6, '0')}.jpg`;
      writeFileSync(join(OUT, 'stills', file), Buffer.from(shot.data, 'base64'));
      shots.set(tick, { file, pv: pv ? { swing: pv.swing || null, swings: pv.swings, fst: pv.fst || null, ln: pv.ln || null, hp: pv.hp || null, pz: pv.pz || null, mv: pv.mv === undefined ? null : pv.mv } : null });
    }
    const swingsDone = record.swings.filter((s) => s.end !== null).length;
    if (doneAt < 0 && swingsDone >= NSWING && record.launches.length >= NLAUNCH) doneAt = tick;
    if (doneAt >= 0 && tick >= doneAt + MARGIN) break;
  }
  record.ticks = last;
  if (curSwing) curSwing.end = null;
  // which stills to keep: those within MARGIN of a swing (start to end) or a launch
  const keep = [];
  for (const [tick, s] of [...shots.entries()].sort((a, b) => a[0] - b[0])) {
    const near = record.swings.some((w) => tick >= w.start - MARGIN && tick <= (w.end === null ? last : w.end) + MARGIN) || record.launches.some((l) => Math.abs(tick - l.tick) <= MARGIN);
    if (near) keep.push({ tick, ...s });
  }
  record.pictures = keep.map((k) => ({ tick: k.tick, file: `stills/${k.file}`, swing: k.pv && k.pv.swing, fighters: k.pv && k.pv.fst, launchN: k.pv && k.pv.ln, pause: k.pv && k.pv.pz, moving: k.pv && k.pv.mv }));
  log(`${last} ticks played: ${record.swings.length} swing(s), ${record.launches.length} launch(es), ${keep.length} stills kept of ${shots.size}`);
  // the contact sheets: an HTML page of the stills, the caption in each still's corner, shot by the same browser
  const label = (k) => {
    const sw = k.pv && k.pv.swing;
    const on = sw && sw.on;
    const evL = record.launches.filter((l) => Math.abs(l.tick - k.tick) < EVERY / 2 + 15).map((l) => `LAUNCH #${l.n} (fighter ${l.fighter + 1})`);
    return [`tick ${k.tick}`,
      sw ? (on ? `SWING ON  ${sw.rate} deg/s  ${sw.left} left` : 'swing at rest') : 'no swing state',
      sw && on ? `cause: ${sw.cause || '?'}` : (k.pv && k.pv.swings >= 0 ? `swings so far ${k.pv.swings}` : ''),
      k.pv && k.pv.fst ? `A ${k.pv.fst[0]} / B ${k.pv.fst[1]}` : '',
      k.pv && k.pv.pz ? `pause.left ${k.pv.pz[0]}  dirS.stop ${k.pv.pz[1]}${k.pv.mv === null || k.pv.mv === undefined ? '' : `  moving ${k.pv.mv}`}` : '', ...evL].filter(Boolean);
  };
  const PER = 12;
  const sheets = [];
  for (let s = 0; s * PER < keep.length; s++) {
    const cells = keep.slice(s * PER, (s + 1) * PER).map((k) => `<figure><img src="stills/${k.file}"><figcaption>${label(k).map((l, i) => (i === 0 ? `<b>${l}</b>` : l)).join('<br>')}</figcaption></figure>`).join('');
    const html = `<!doctype html><meta charset="utf-8"><style>body{margin:0;background:#10131a;font:12px/1.35 Consolas,monospace;color:#e8ecf4}.g{display:grid;grid-template-columns:repeat(4,480px);gap:4px;padding:4px}figure{margin:0;position:relative;width:480px;height:270px}img{width:480px;height:270px;display:block}figcaption{position:absolute;left:6px;bottom:6px;background:rgba(8,10,16,.78);padding:4px 7px;border-radius:3px}</style><div class="g">${cells}</div>`;
    writeFileSync(join(OUT, `sheet-${s + 1}.html`), html);
    sheets.push(`sheet-${s + 1}`);
  }
  const sheetServer = await serve(resolve(OUT));
  const rows = (n) => Math.ceil(n / 4);
  for (let s = 0; s < sheets.length; s++) {
    const n = Math.min(PER, keep.length - s * PER);
    await page.send('Emulation.setDeviceMetricsOverride', { width: 4 * 484 + 4, height: rows(n) * 274 + 8, deviceScaleFactor: 1, mobile: false });
    await page.send('Page.navigate', { url: `http://127.0.0.1:${sheetServer.address().port}/${sheets[s]}.html` });
    await sleep(1200);
    const shot = await page.send('Page.captureScreenshot', { format: 'png', fromSurface: true });
    writeFileSync(join(OUT, `${sheets[s]}.png`), Buffer.from(shot.data, 'base64'));
    rmSync(join(OUT, `${sheets[s]}.html`), { force: true });
  }
  sheetServer.close();
  writeFileSync(join(OUT, 'reel.json'), `${JSON.stringify(record, null, 2)}\n`);
  log(`wrote ${sheets.length} contact sheet(s) and reel.json to ${OUT}`);
} catch (e) {
  console.error(`[reel] FAILED: ${e.message}`);
  code = 1;
} finally {
  if (page) page.close();
  if (browser) await browser.close();
  server.close();
}
process.exit(code);
