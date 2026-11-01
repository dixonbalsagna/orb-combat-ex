// Plays a black box file back as a clip (the EP, 2026-11-01: "plays Orb's real match back as a clip through the existing replay path"). The page's `replay=1` word starts the recorded match again and steps it with the recorded intents exactly as SimReplay.play does;
// the capture hook films it one tick per frame (every --every ticks a picture). The recorded checkpoints are compared with the page's own hashes as it goes, so the clip says whether it IS the match that was played.
//
//   node tools/preview/blackbox-clip.mjs --file <orb-first-play-....json> --dir <built web folder> --out <folder> [--every 2] [--scale 0.5] [--max 20000] [--from N --to N]
//
// Output: <out>/frames/f-000001.jpg ..., <out>/index.html (a player: Space pauses, arrows step, a slider), <out>/clip.json (the ticks, the checkpoints compared: ok or the first tick that differs, the answers Orb gave). Private.
// The file's replay needs the build it was recorded on: a replay carries a data hash, and the page refuses a different one (the clip then says so).
import { mkdirSync, writeFileSync, readFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { Cdp, launchBrowser, serve, browserExe } from '../machine/browser.mjs';

const argv = process.argv.slice(2);
const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
const FILE = opt('--file'), DIR = opt('--dir'), OUT = opt('--out');
if (!FILE || !DIR || !OUT) { console.error('usage: node tools/preview/blackbox-clip.mjs --file <saved match.json> --dir <built web folder> --out <folder> [--every 2]'); process.exit(2); }
const EVERY = Math.max(1, Number(opt('--every', 2))), SCALE = Number(opt('--scale', 0.5)), MAXT = Number(opt('--max', 20000)), W = 960, H = 540;
const doc = JSON.parse(readFileSync(FILE, 'utf8'));
const rp = doc.replay || doc;
const fr = doc.frames || null;   // the slow frames of the real play (the page's own frame gaps): [tick, ms, seconds in]
const marks = fr && Array.isArray(fr.slow) ? fr.slow : [];
const FROM = Math.max(0, Number(opt('--from', 0))), TO = Number(opt('--to', 0));   // a window: pictures only from FROM, and the match is played no further than TO (0: to its end)
const TICKS = Math.min(Number(rp.ticks) || 0, MAXT, TO > 0 ? TO : Infinity);
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const log = (m) => console.log(`[blackbox-clip] ${m}`);
const exe = browserExe('chrome');
mkdirSync(join(OUT, 'frames'), { recursive: true });
const server = await serve(resolve(DIR));
const words = String(opt('--query', doc.pageSearch || '')).replace(/^\?/, '').split('&').filter((w) => w && !/^(go|blackbox|script|replay|flashcap|preview|reel|sticks|peak|tier)=/.test(w));
const url = `http://127.0.0.1:${server.address().port}/index.html?flashcap=1&preview=1&reel=1&replay=1&blackbox=off${words.length ? `&${words.join('&')}` : ''}`;
const OVERLAY_JS = `(() => { const d = document.createElement('div'); d.id = 'ov'; Object.assign(d.style, { position: 'fixed', left: '0', right: '0', bottom: '0', zIndex: 99999, background: 'rgba(0,0,0,0.6)', color: '#fff', font: 'bold 18px sans-serif', padding: '4px 12px' }); const add = () => document.body && document.body.appendChild(d); if (document.body) add(); else window.addEventListener('DOMContentLoaded', add); })();`;
let browser = null, page = null, code = 0;
const record = { build: doc.build || null, source: FILE, seed: rp.seed, ticks: rp.ticks, played: 0, every: EVERY, answers: doc.answers || null, checkpoints: { recorded: (rp.checkpoints || []).length, compared: 0, firstBad: -1 }, ok: null };
try {
  browser = await launchBrowser({ exe, flags: [`--window-size=${W},${H}`], session: process.env.MERIDIAN_SESSION || 'tools-pipeline', purpose: 'black box clip', timeoutS: 3600, cpuPercent: 25, log });
  page = await Cdp.open(browser.target.webSocketDebuggerUrl);
  await page.send('Page.enable');
  await page.send('Emulation.setDeviceMetricsOverride', { width: W, height: H, deviceScaleFactor: 1, mobile: false });
  await page.send('Page.addScriptToEvaluateOnNewDocument', { source: `window.__replay = ${JSON.stringify(JSON.stringify(rp))};\n${OVERLAY_JS}` });
  await page.send('Page.navigate', { url });
  const deadline = Date.now() + 900 * 1000;
  let ready = false;
  while (Date.now() < deadline && !ready) { await sleep(500); ready = await page.eval('Boolean(window.__flashcap && window.__flashcap.ready)').catch(() => false); }
  if (!ready) throw new Error('the page offers no window.__flashcap that becomes ready');
  await page.eval(`window.__flashcap.start("ai", { reduced: false, seed: ${Number(rp.seed)} })`, true);
  log(`${url}: ${TICKS} ticks of ${rp.ticks}, a picture every ${EVERY}`);
  let n = 0, started = false;
  for (let i = 1; i <= TICKS; i++) {
    const got = await page.eval('window.__flashcap.step().then((t) => ({ tick: t, err: window.__flashcap.error || null, pr: window.__pr || null }))', true);
    if (got && got.err) throw new Error(`the page reported an error: ${got.err}`);
    if (!started && got.pr) { started = true; if (!got.pr.ok) throw new Error('the page refused the replay (another format, version or intent schema)'); }
    record.played = i;
    if ((i % EVERY === 0 || i === TICKS) && i >= FROM) {
      await page.eval(`(() => { const g = document.getElementById('ov'); if (g) g.textContent = ${JSON.stringify(`your match, tick ${i} of ${rp.ticks}  (${(i / 60).toFixed(1)} s)`) + (marks.some((m) => m[0] > i - EVERY && m[0] <= i) ? ` + ' — SLOW FRAME on your PC: ' + ${JSON.stringify(marks.filter((m) => m[0] > i - EVERY && m[0] <= i).map((m) => Math.round(m[1]) + ' ms').join(', '))}` : '')}; })()`, true);
      const shot = await page.send('Page.captureScreenshot', { format: 'jpeg', quality: 70, fromSurface: true, clip: { x: 0, y: 0, width: W, height: H, scale: SCALE } });
      n++;
      writeFileSync(join(OUT, 'frames', `f-${String(n).padStart(6, '0')}.jpg`), Buffer.from(shot.data, 'base64'));
    }
    if (i % 600 === 0) log(`${i} of ${TICKS}`);
  }
  // the checkpoints the page hashed against the recorded ones
  const cp = await page.eval('JSON.stringify(window.__pr_cp || [])');
  const mine = JSON.parse(cp || '[]'), want = new Map((rp.checkpoints || []).map((c) => [Number(c[0]), String(c[1])]));
  for (const [t, h] of mine) { if (!want.has(t)) continue; record.checkpoints.compared++; if (want.get(t) !== h && record.checkpoints.firstBad < 0) record.checkpoints.firstBad = t; }
  record.ok = record.checkpoints.compared > 0 ? record.checkpoints.firstBad < 0 : null;
  record.frames = n;
  record.slowFrames = fr ? { over33: fr.over33, over50: fr.over50, over100: fr.over100, worst: fr.worst, worstTick: fr.worstTick, of: fr.n, away: fr.away, marks: marks.length } : null;
  log(`done: ${n} pictures; checkpoints compared ${record.checkpoints.compared}, ${record.ok === null ? 'none to compare' : record.ok ? 'ALL EQUAL: the clip is the match that was played' : `FIRST DIFFERENT at tick ${record.checkpoints.firstBad}`}`);
  const html = readFileSync(new URL('./clip-player.html', import.meta.url), 'utf8').replace('__FRAMES__', String(n)).replace('__FPS__', String(Math.round(60 / EVERY))).replace('__SLOW__', fr ? (fr.n ? `While you played, ${fr.over33} of ${fr.n} frames took over 33 ms on your PC (${fr.over50} over 50 ms, ${fr.over100} over 100 ms; worst ${Math.round(fr.worst)} ms at tick ${fr.worstTick}). ${marks.length ? 'The slow ones, by tick (ms): ' + marks.slice(0, 60).map((m) => m[0] + ' (' + Math.round(m[1]) + ')').join(', ') + (marks.length > 60 ? ', and more in the file' : '') + '. Each is also written on the picture where it happened.' : ''}` : 'No frame times were recorded.') : 'This file has no frame times (it was saved by an earlier page).');
  writeFileSync(join(OUT, 'index.html'), html);
} catch (e) { console.error(`[blackbox-clip] FAILED: ${e.message}`); record.error = e.message; code = 1; }
finally {
  writeFileSync(join(OUT, 'clip.json'), JSON.stringify(record, null, 2));
  try { if (page) page.close(); } catch { /* gone */ }
  try { if (browser) await browser.close(); } catch { /* gone */ }
  server.close();
}
process.exit(code);
