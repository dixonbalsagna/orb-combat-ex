// Does the black box see a REAL KO? (Tools, 2026-11-01; the first cut read S.ko, which is not a field: it is S.game.ko.) Plays the hook's `ai` match on a built page (both fighters at full power with &peak=1, so it ends in a minute or two)
// until the box queues an `over` match, then saves what the page would save to <out>/match.json (the replay, the slow-frame record, the page's words) for blackbox-verify.mjs.
//
//   node tools/preview/blackbox-ko-check.mjs --dir <built web folder> --out <folder> [--query "planet=7&tiles=1&peak=1"] [--max 12000]
import { mkdirSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { Cdp, launchBrowser, serve, browserExe } from '../machine/browser.mjs';

const argv = process.argv.slice(2);
const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
const DIR = opt('--dir'), OUT = opt('--out');
if (!DIR || !OUT) { console.error('usage: node tools/preview/blackbox-ko-check.mjs --dir <built web folder> --out <folder>'); process.exit(2); }
const QUERY = opt('--query', 'planet=7&tiles=1&peak=1'), MAXT = Number(opt('--max', 12000)), SEED = Number(opt('--seed', 12345));
const log = (m) => console.log(`[bb-ko-check] ${m}`);
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
mkdirSync(OUT, { recursive: true });
const server = await serve(resolve(DIR));
const url = `http://127.0.0.1:${server.address().port}/index.html?flashcap=1&preview=1&reel=1&${QUERY}`;
let browser = null, page = null, code = 1;
try {
  browser = await launchBrowser({ exe: browserExe('chrome'), flags: ['--window-size=640,360'], session: process.env.MERIDIAN_SESSION || 'tools-pipeline', purpose: 'black box KO check', timeoutS: 1800, cpuPercent: 25, log });
  page = await Cdp.open(browser.target.webSocketDebuggerUrl);
  await page.send('Page.enable');
  await page.send('Emulation.setDeviceMetricsOverride', { width: 640, height: 360, deviceScaleFactor: 1, mobile: false });
  await page.send('Page.navigate', { url });
  const deadline = Date.now() + 900 * 1000;
  let ready = false;
  while (Date.now() < deadline && !ready) { await sleep(500); ready = await page.eval('Boolean(window.__flashcap && window.__flashcap.ready)').catch(() => false); }
  if (!ready) throw new Error('the page offers no window.__flashcap that becomes ready');
  await page.eval(`window.__flashcap.start("ai", { reduced: false, seed: ${SEED} })`, true);
  log(`${url}: stepping up to ${MAXT} ticks`);
  let found = null, t = 0;
  for (let i = 1; i <= MAXT && !found; i++) {
    const got = await page.eval('window.__flashcap.step().then((t) => ({ tick: t, err: window.__flashcap.error || null, q: (window.__bb_q || []).map((e) => ({ over: e.over, ended: e.ended, ticks: e.ticks, seed: e.seed, frames: e.frames || null, replay: e.replay })) }))', true);
    t = got.tick;
    if (got.err) throw new Error(`the page reported an error: ${got.err}`);
    found = got.q.find((e) => e.over) || null;
    if (i % 1200 === 0) log(`${i} ticks, the box has queued ${got.q.length} entr${got.q.length === 1 ? 'y' : 'ies'}`);
  }
  if (!found) { const st = await page.eval('JSON.stringify({ state: window.__bb_state || null, q: (window.__bb_q || []).length, replayChars: String(window.__bb_replay || "").length })').catch(() => null); log(`NO KO SEEN in ${t} ticks (the box queued nothing with over:true); the box itself: ${st}`); code = 3; }
  else {
    const rp = JSON.parse(found.replay);
    writeFileSync(join(OUT, 'match.json'), JSON.stringify({ kind: 'orb-first-play', note: 'saved by blackbox-ko-check', pageSearch: `?${QUERY}`, matchOver: true, answers: {}, frames: found.frames, replay: rp }));
    log(`KO SEEN: the box queued an over match of ${found.ticks} ticks (seed ${found.seed}); replay has ${rp.inputs.length} input entries, ${rp.checkpoints.length} checkpoints, final ${String(rp.final).slice(0, 12)}; frames record: ${found.frames ? `${found.frames.n} frames, ${found.frames.over33} over 33 ms` : 'none'}`);
    code = 0;
  }
} catch (e) { console.error(`[bb-ko-check] FAILED: ${e.message}`); }
finally {
  try { if (page) page.close(); } catch { /* gone */ }
  try { if (browser) await browser.close(); } catch { /* gone */ }
  server.close();
}
process.exit(code);
