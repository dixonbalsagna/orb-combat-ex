// The EXPORTED public build, run (Legal's RL-196, 2026-10-27): on a public hostname, with every word that would start a run without the gate in the URL, the capture hook does not exist and the
// game's own gate words are dropped. Static scans (tools/site-routes.mjs) read the code; this reads the built site as a visitor's browser runs it.
//
//   node tools/check-site-hook.mjs --site <built site dir> [--host public.example] [--timeout 300] [--browser-path <exe>] [--path /play/] [--software]
//
// It serves the site on a local port, starts the browser through the guarded launcher (tools/machine/browser.mjs: time limit, below-normal priority, CPU cap) with that server as its proxy (and the public name treated as a secure context, which Godot's web export requires: the page runs on https in production), so
// a PUBLIC hostname (default public.example: not localhost, 127.0.0.1, [::1] or file:, the page-is-local test of UiHud.page_is_local) is answered by it, opens /play/ with
// ?flashcap=1&study=1&nointro=1&nonotice=1&staticsky=1&sky=1&skymood=1, clicks the gate's "I understand, start", waits until the engine is drawing (the canvas changes), and then:
//   - window.__flashcap must not exist (the hook's own object: the page's JS could call __flashcap.start('ai', { reduced: false }) to turn Reduce flashing off);
//   - the hostname the page saw is the public one (so a pass was not a local-host pass);
//   - the engine really ran: a check that never saw the game draw proves nothing, so that is a failure ("not proven"), not a pass.
// Exit 0 when all hold, 1 when one does not, 2 when there is no browser or the usage is wrong.
import { existsSync } from 'node:fs';
import { resolve, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';
import { Cdp, launchBrowser, serve, browserExe } from './machine/browser.mjs';

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
export const WORDS = ['flashcap=1', 'study=1', 'nointro=1', 'nonotice=1', 'staticsky=1', 'sky=1', 'skymood=1'];

/** Runs the check; resolves { ok, problems, notes }. Never throws for a failed check, only for a missing browser or a bad site folder. */
export async function checkHook({ site, host = 'public.example', timeoutS = 300, exe, path = '/play/', log = () => {}, words = WORDS, session = 'tools', software = false }) {
  const problems = [], notes = [];
  const dir = resolve(site);
  if (!existsSync(join(dir, path.replace(/^\//, ''), 'index.html'))) throw new Error(`${join(dir, path.replace(/^\//, ''), 'index.html')} does not exist: build the site first`);
  const browserPath = exe || browserExe('chrome') || browserExe('edge');
  if (!browserPath) throw Object.assign(new Error('no chrome or edge executable found (pass --browser-path)'), { code: 'NO_BROWSER' });
  const server = await serve(dir);
  const port = server.address().port;
  let browser = null, page = null;
  try {
    browser = await launchBrowser({ exe: browserPath, flags: [`--proxy-server=127.0.0.1:${port}`, '--proxy-bypass-list=<-loopback>', `--unsafely-treat-insecure-origin-as-secure=http://${host}`, '--window-size=960,540', ...(software ? ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] : [])], session, purpose: 'sitehook', timeoutS: timeoutS + 120, cpuPercent: 40, log });
    page = await Cdp.open(browser.target.webSocketDebuggerUrl);
    await page.send('Page.enable');
    await page.send('Emulation.setDeviceMetricsOverride', { width: 960, height: 540, deviceScaleFactor: 1, mobile: false });
    const url = `http://${host}${path}?${words.join('&')}`;   // port 80 of a public name: the browser's proxy (this check's own file server) answers for it
    log(`opening ${url}`);
    await page.send('Page.navigate', { url });
    const deadline = Date.now() + timeoutS * 1000;
    // the gate: the page's own button starts the engine (window.__startGame is called only from it)
    // the page is loaded and its scripts have run before the click (the gate's button is in the markup before its handler is bound: a click that comes first starts nothing)
    while (Date.now() < deadline && (await page.eval('document.readyState').catch(() => '')) !== 'complete') await sleep(300);
    await sleep(2500);
    // the gate's own picture, taken BEFORE the click: what counts as the engine drawing is a picture that is not this one (the engine can have drawn its settled notice before the first shot after the click,
    // so a count of pictures seen after the click alone can read 1 for a game that ran: the pinned build did on the runner, 2026-10-28), and whether this is a real engine page (the stock export's #status overlay, which the page removes when engine.startGame has resolved, i.e. when main has run)
    const gateShot = await page.send('Page.captureScreenshot', { format: 'jpeg', quality: 40 }).catch(() => null);
    const gateHash = gateShot && gateShot.data ? createHash('sha1').update(gateShot.data).digest('hex') : '';
    const hadStatus = await page.eval(`Boolean(document.getElementById('status'))`).catch(() => false);
    let clicked = false;
    while (!clicked && Date.now() < deadline) { clicked = await page.eval(`(() => { const b = document.getElementById('gate-start'); if (!b) return false; b.click(); return true; })()`).catch(() => false); if (!clicked) await sleep(500); }
    if (!clicked) { problems.push(`the page has no #gate-start button to click within ${timeoutS} s: the click-through is not where this check looks for it`); return { ok: false, problems, notes }; }
    // the engine is running when the canvas has been seen to change: a loading bar, a boot picture or the game. The hook (if it were attached) is made in the first scene's _ready, before any frame.
    // The game under a lock ends on a still picture (UI's flashing-effects notice, waiting for its own button), so: it drew (the picture changed from the gate's) and then
    // settled (the same big picture three shots running), or it keeps changing (four kinds). The notice is raised after the hook is decided, so a settled picture means main._ready has run.
    const seen = new Set();
    let ran = false, stable = 0, lastHash = '', lastBig = false, started = !hadStatus, fetched = 'no files';
    while (Date.now() < deadline && !ran) {
      await sleep(2500);
      const shot = await page.send('Page.captureScreenshot', { format: 'jpeg', quality: 40 }).catch(() => null);
      if (shot && shot.data) { const h = createHash('sha1').update(shot.data).digest('hex'); stable = h === lastHash ? stable + 1 : 0; lastHash = h; lastBig = shot.data.length > 20000; if (h !== gateHash) seen.add(h); else stable = 0; }   // a blank page is a few KB; the notice or the game is far more; the gate's own picture is not the engine drawing
      if (await page.eval('typeof window.__flashcap').catch(() => 'undefined') !== 'undefined') break;   // the hook exists: no need to wait on
      const res = await page.eval('JSON.stringify(performance.getEntriesByType("resource").map((r) => r.name))').catch(() => '[]');
      const engine = hadStatus ? /\.wasm/.test(res) && /\.pck/.test(res) : /\.wasm/.test(res) ? /\.pck/.test(res) : true;   // a real engine page has fetched its pack as well as its wasm (a stand-in page may have neither)
      fetched = `${/\.wasm/.test(res) ? 'wasm' : 'no wasm'}, ${/\.pck/.test(res) ? 'pck' : 'no pck'}`;
      if (hadStatus && !started) started = await page.eval(`!document.getElementById('status')`).catch(() => false);   // engine.startGame resolved: the page took its own overlay down
      ran = engine && started && (seen.size >= 4 || (seen.size >= 1 && stable >= 3 && lastBig));
    }
    const state = await page.eval(`JSON.stringify({ host: location.hostname, flashcap: typeof window.__flashcap, canvas: Boolean(document.querySelector('canvas')) })`).catch(() => null);
    const st = state ? JSON.parse(state) : {};
    if (st.host !== host) problems.push(`the page saw the hostname "${st.host}", not the public "${host}": this was not a public-host run`);
    if (st.flashcap !== 'undefined') problems.push(`window.__flashcap exists on the exported public build with ?flashcap=1 (typeof ${st.flashcap}): a visitor's console could call window.__flashcap.start('ai', { reduced: false }) and turn Reduce flashing off`);
    else if (!ran) problems.push(`not proven: the engine was not seen drawing within ${timeoutS} s (${seen.size} distinct pictures other than the gate's; the engine ${started ? 'had started' : 'had not started: the page never took its loading overlay down'}; ${fetched}), so the absence of window.__flashcap proves nothing`);
    else notes.push(`on the hostname ${host} with ${words.join(' ')}: window.__flashcap is undefined and the engine had started (the page took its loading overlay down) and drew ${seen.size} distinct picture${seen.size === 1 ? '' : 's'} other than the gate's`);
  } finally {
    try { if (page) page.close(); } catch { /* gone */ }
    if (browser) await browser.close();
    server.close();
  }
  return { ok: problems.length === 0, problems, notes };
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const args = process.argv.slice(2);
  const opt = (n, d) => { const i = args.indexOf(n); return i >= 0 ? args[i + 1] : d; };
  const site = opt('--site');
  if (!site) { console.error('usage: node tools/check-site-hook.mjs --site <built site dir> [--host public.example] [--timeout 300] [--browser-path <exe>] [--path /play/] [--software]'); process.exit(2); }
  try {
    const r = await checkHook({ site, host: opt('--host', 'public.example'), timeoutS: Number(opt('--timeout', 300)), exe: opt('--browser-path'), path: opt('--path', '/play/'), software: args.includes('--software'), log: (m) => console.log(`[site-hook] ${m}`) });
    if (!r.ok) { for (const p of r.problems) console.error(`site hook check FAILED: ${p}`); process.exit(1); }
    for (const n of r.notes) console.log(`site hook check ok: ${n}`);
    process.exit(0);
  } catch (e) {
    console.error(`site hook check: ${e.message}`);
    process.exit(e.code === 'NO_BROWSER' ? 2 : 1);
  }
}
