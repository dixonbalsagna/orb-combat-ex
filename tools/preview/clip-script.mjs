// Captures a scripted-input scene on the page, one side (the EP's order, 2026-11-01; Controls' hit-stop A/B script, docs/controls/clips/hitstop-ab.md): the capture hook steps one tick per frame, the page's `?script=1` word feeds the script's pad events
// through the real input path, the inputs are drawn at the frame's edge from the overlay file, and every tick is a picture.
//
//   node tools/preview/clip-script.mjs --dir <built web folder> --script <script.json> --overlay <overlay.json> --hitstop on|off --out <folder> [--seed 5] [--scale 0.5] [--query "..."]
//
// Output: <out>/frames/f-000001.jpg ..., <out>/clip.json (the scene, the held ticks per segment as the page reports them, the overlay used). Both sides use the same seed, script and overlay: only `hitstop` differs. Private.
import { mkdirSync, writeFileSync, readFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { Cdp, launchBrowser, serve, browserExe } from '../machine/browser.mjs';

const argv = process.argv.slice(2);
const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
const DIR = opt('--dir'), OUT = opt('--out'), SCRIPT = opt('--script'), OVERLAY = opt('--overlay'), HS = opt('--hitstop', 'off');
if (!DIR || !OUT || !SCRIPT) { console.error('usage: node tools/preview/clip-script.mjs --dir <web> --script <script.json> --overlay <overlay.json> --hitstop on|off --out <folder>'); process.exit(2); }
const LABEL = opt('--label', ''), SEED = Number(opt('--seed', 5)), SCALE = Number(opt('--scale', 0.5)), W = 960, H = 540;
const script = JSON.parse(readFileSync(SCRIPT, 'utf8'));
const overlay = OVERLAY ? JSON.parse(readFileSync(OVERLAY, 'utf8')) : null;
const TICKS = Number(script.scene && script.scene.ticks) || 760;
const QUERY = opt('--query', `script=1&hitstop=${HS === 'on' ? '1' : 'off'}&blackbox=off`);
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const log = (m) => console.log(`[clip-script] ${m}`);
const exe = browserExe('chrome');
mkdirSync(join(OUT, 'frames'), { recursive: true });
const server = await serve(resolve(DIR));
const url = `http://127.0.0.1:${server.address().port}/index.html?flashcap=1&preview=1&reel=1&${QUERY}`;
// the overlay bar, a DOM element the screenshots include: the controls held, the stick, the segment, and the clip's side
const OVERLAY_JS = `
(() => {
  const d = document.createElement('div'); d.id = 'ov';
  Object.assign(d.style, { position: 'fixed', left: '0', right: '0', bottom: '0', zIndex: 99999, background: 'rgba(0,0,0,0.72)', color: '#fff', font: 'bold 20px sans-serif', padding: '6px 14px', display: 'flex', gap: '24px' });
  const mk = (id, w) => { const s = document.createElement('span'); s.id = id; s.style.minWidth = w; d.appendChild(s); return s; };
  mk('ov-side', '210px'); mk('ov-held', '300px'); mk('ov-rs', '200px'); mk('ov-seg', '300px');
  const add = () => document.body && document.body.appendChild(d);
  if (document.body) add(); else window.addEventListener('DOMContentLoaded', add);
})();`;
let browser = null, page = null, code = 0;
const record = { url, seed: SEED, hitstop: HS, ticks: TICKS, holdTicks: 0, holdBySegment: {}, segments: overlay ? overlay.segments : [] };
try {
  browser = await launchBrowser({ exe, flags: [`--window-size=${W},${H}`], session: process.env.MERIDIAN_SESSION || 'tools-pipeline', purpose: 'hitstop clip', timeoutS: 1800, cpuPercent: 25, log });
  page = await Cdp.open(browser.target.webSocketDebuggerUrl);
  await page.send('Page.enable');
  await page.send('Emulation.setDeviceMetricsOverride', { width: W, height: H, deviceScaleFactor: 1, mobile: false });
  await page.send('Page.addScriptToEvaluateOnNewDocument', { source: `window.__script = ${JSON.stringify(JSON.stringify(script))};\n${OVERLAY_JS}` });
  await page.send('Page.navigate', { url });
  const deadline = Date.now() + 900 * 1000;
  let ready = false;
  while (Date.now() < deadline && !ready) { await sleep(500); ready = await page.eval('Boolean(window.__flashcap && window.__flashcap.ready)').catch(() => false); }
  if (!ready) throw new Error('the page offers no window.__flashcap that becomes ready');
  await page.eval(`window.__flashcap.start("ai", { reduced: false, seed: ${SEED} })`, true);
  log(`${url}: ${TICKS} ticks, hit-stop ${HS}`);
  const segAt = (t) => { let s = ''; for (const g of (overlay ? overlay.segments : [])) if (t >= g.from) s = g.name; return s; };
  for (let i = 1; i <= TICKS; i++) {
    const got = await page.eval('window.__flashcap.step().then((t) => ({ tick: t, err: window.__flashcap.error || null, ps: window.__ps || null }))', true);
    if (got && got.err) throw new Error(`the page reported an error: ${got.err}`);
    const t = i - 1;   // the script tick this step ran (its events were set before it)
    const fr = overlay && overlay.frames && overlay.frames[t] ? overlay.frames[t] : null;
    const held = fr ? fr.held.join(' + ') : '';
    const rs = fr && fr.rs ? `stick ${fr.rs[0] > 0 ? 'RIGHT' : fr.rs[0] < 0 ? 'LEFT' : ''}${fr.rs[1] > 0 ? ' UP' : fr.rs[1] < 0 ? ' DOWN' : ''}` : '';
    await page.eval(`(() => { const g = (id) => document.getElementById(id); if (!g('ov-side')) return; g('ov-side').textContent = ${JSON.stringify(`${LABEL || ('HIT-STOP ' + HS.toUpperCase())}  tick ${t}`)}; g('ov-held').textContent = ${JSON.stringify(held ? 'HELD: ' + held : 'HELD: -')}; g('ov-rs').textContent = ${JSON.stringify(rs)}; g('ov-seg').textContent = ${JSON.stringify(fr ? fr.segment : segAt(t))}; })()`, true);
    const hold = !!(got.ps && got.ps.hold);
    if (hold) { record.holdTicks++; const sn = fr ? fr.segment : segAt(t); record.holdBySegment[sn] = (record.holdBySegment[sn] || 0) + 1; }
    const shot = await page.send('Page.captureScreenshot', { format: 'jpeg', quality: 70, fromSurface: true, clip: { x: 0, y: 0, width: W, height: H, scale: SCALE } });
    writeFileSync(join(OUT, 'frames', `f-${String(i).padStart(6, '0')}.jpg`), Buffer.from(shot.data, 'base64'));
    if (i % 100 === 0) log(`${i} of ${TICKS} ticks, ${record.holdTicks} held so far`);
  }
  log(`done: ${record.holdTicks} of ${TICKS} ticks held (the sim's own count, from the script probe: 38 off, 69 on)`);
} catch (e) { console.error(`[clip-script] FAILED: ${e.message}`); record.error = e.message; code = 1; }
finally {
  writeFileSync(join(OUT, 'clip.json'), JSON.stringify(record, null, 2));
  try { if (page) page.close(); } catch { /* gone */ }
  try { if (browser) await browser.close(); } catch { /* gone */ }
  server.close();
}
process.exit(code);
