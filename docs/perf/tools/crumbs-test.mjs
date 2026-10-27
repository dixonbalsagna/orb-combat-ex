#!/usr/bin/env node
// Tests the freeze-breadcrumbs park (docs/perf/web-shell/ocx-crumbs.js) against Legal's five limits (docs/legal/crumbs-screen.md, p04), on a small stub page, in headless Chrome through the
// project's guarded launcher (tools/machine/browser.mjs: below-normal priority, a time limit, a session-named profile). No Godot, no network, one browser, about 90 s. Node 24 built-ins only.
// Owner: Performance and Platform.
//
//   node docs/perf/tools/crumbs-test.mjs [--out result.json] [--session meridian-performance-platform]
//
// The stub page has the shell's two elements the park watches (#status-progress, #status) and the park folded in exactly as web-head.mjs --crumbs folds it, so what runs is what ships.
import { mkdirSync, mkdtempSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { Cdp, launchBrowser, serve, browserExe } from '../../../tools/machine/browser.mjs';

const here = dirname(fileURLToPath(import.meta.url));
const argv = process.argv.slice(2);
const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
const SESSION = opt('--session', process.env.MERIDIAN_SESSION || 'meridian-performance-platform'), OUT = opt('--out');
const BUILD = 'ab12cd3 2026-10-26';
const TAIL = ' The game sends nothing. Copying puts it on your clipboard, and you choose where to paste it.';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const head = execFileSync(process.execPath, [join(here, 'web-head.mjs'), '--print', '--crumbs', '--build', BUILD], { encoding: 'utf8' }).trim();
const root = mkdtempSync(join(tmpdir(), 'crumbs-test-'));
mkdirSync(join(root, 'play'));
writeFileSync(join(root, 'play', 'index.html'), `<!doctype html><html><head><meta charset='utf-8'>${head}</head><body><progress id='status-progress' value='0' max='100'></progress><div id='status'>loading</div><canvas id='canvas'></canvas></body></html>`);

const KEY = 'ocx.crumbs.v1';
const results = [];
const check = (name, ok, detail) => { results.push({ name, ok: !!ok, detail: detail === undefined ? undefined : detail }); console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${detail === undefined ? '' : '  ' + JSON.stringify(detail).slice(0, 300)}`); };
const server = await serve(root);
const url = `http://127.0.0.1:${server.address().port}/play/index.html`;
let b, page;
try {
  b = await launchBrowser({ exe: browserExe('chrome'), session: SESSION, purpose: 'crumbs-test', timeoutS: 300, log: () => {}, flags: ['--window-size=915,412'] });
  page = await Cdp.open(b.target.webSocketDebuggerUrl);
  await page.send('Page.enable'); await page.send('Network.enable');
  await page.send('Emulation.setDeviceMetricsOverride', { width: 915, height: 412, deviceScaleFactor: 2.625, mobile: true });
  // Counts reads of the graphics string (the report may make them; boot must not).
  await page.send('Page.addScriptToEvaluateOnNewDocument', { source: `window.__gpuReads = 0; for (const C of [window.WebGLRenderingContext, window.WebGL2RenderingContext]) { if (!C) continue; const g = C.prototype.getExtension; C.prototype.getExtension = function (n) { if (n === 'WEBGL_debug_renderer_info') window.__gpuReads++; return g.call(this, n); }; }` });
  const ev = (js) => page.eval(js);
  const load = async () => { await page.send('Page.navigate', { url }); await sleep(900); };
  const key = async () => ev(`localStorage.getItem('${KEY}')`);
  // Puts a record in storage from a page of the same origin that is not the game page (the game page's own pagehide would clear its record after a dismiss or copy).
  const prime = async (text) => { await page.send('Page.navigate', { url: url.replace('/play/index.html', '/none') }); await sleep(500); await ev(`localStorage.setItem('${KEY}', ${JSON.stringify(text)}); 1`); await load(); };
  const boot = (extra) => `(() => { const p = document.getElementById('status-progress'); p.value = 100; ${extra || ''} })()`;

  // 1. A clean visit leaves no record. The progress bar moves, a 1 s busy spell (under the 3 s stall mark), the status overlay is removed, two flush periods pass.
  await load();
  const line1 = await ev(`document.getElementById('ocx-stage-line') && document.getElementById('ocx-stage-line').innerText`);
  const dur = await ev(`(() => { document.getElementById('status-progress').value = 40; return 1; })()`); await sleep(300);
  const line2 = await ev(`document.getElementById('ocx-stage-line').innerText`);
  await ev(boot()); await ev(`(() => { const t = performance.now(); while (performance.now() - t < 1000); })()`); await sleep(700);
  check('start line is up at the first paint, with the cleared sentence', line1 === 'Starting. The first start can take a minute or more on a phone, and the page may look stuck while it loads.', line1);
  check('start line follows the download', /^Downloading 40%. The first start can take/.test(line2 || ''), line2);
  const mid = await key();
  await ev(`document.getElementById('status').remove()`); await sleep(2600);
  check('a visit still starting keeps the record', mid && JSON.parse(mid).stage === 'starting', mid && JSON.parse(mid).stage);
  check('a clean visit (running, no long stall) leaves NO record', (await key()) === null, await key());
  check('the line is gone once running', (await ev(`getComputedStyle(document.getElementById('ocx-stage-line')).display`)) === 'none');
  check('no cookie set', (await ev('document.cookie')) === '' && (await page.send('Network.getCookies')).cookies.length === 0);
  check('no note on a clean next load', (await (async () => { await load(); return ev(`document.getElementById('ocx-crumbs-note')`); })()) === null);
  check('no graphics read on a visit with no note', (await ev('window.__gpuReads')) === 0, await ev('window.__gpuReads'));

  // 2. A stalled boot (a 6 s busy spell while starting) keeps the record; it carries no clock time, no page address, no identifier.
  await ev(boot()); await sleep(400); await ev('(() => { const t = performance.now(); while (performance.now() - t < 6000); })()'); await sleep(1500);
  await ev(`document.getElementById('status').remove()`); await sleep(2600);
  const rec = await key(); const r = rec && JSON.parse(rec);
  check('a 6 s stall keeps the record, with its stage', r && r.stalls.length === 1 && r.stalls[0][1] >= 5500 && r.stalls[0][2] === 'starting', r && r.stalls);
  check('record: no clock timestamp (no t0, no 12 to 13 digit number)', r && !('t0' in r) && !/[0-9]{12,}/.test(rec), r && Object.keys(r));
  check('record: no page address, query or hash', r && !('page' in r) && rec.indexOf('127.0.0.1') < 0 && rec.indexOf('/play') < 0, null);
  check('record: no cookie after the stall either', (await ev('document.cookie')) === '');

  // 3. The next load shows the note; the report is not made until asked (no graphics read at boot), is shown before it is copied, and the copy is that text.
  await load();
  const note = await ev(`(document.getElementById('ocx-crumbs-note') || {}).innerText || null`);
  const replaced = JSON.parse(await key());
  check('next load shows the note, with the cleared words', note && note.indexOf('Last time the game froze for 6 seconds.' + TAIL) === 0 && note.indexOf('Copy a report') > 0 && note.indexOf('Dismiss') > 0 && note.indexOf('This is exactly what will be copied:') > 0, note && note.slice(0, 200));
  check('the key now holds this visit only (replaced, not appended)', replaced && replaced.stage === 'page_loaded' && replaced.stalls.length === 0, replaced && replaced.stage);
  check('the report is on screen at once, before any copy', (await ev(`document.getElementById('ocx-crumbs-report') !== null`)) === true);
  check('the graphics string is read when a note is put up (the report is made)', (await ev('window.__gpuReads')) >= 1, await ev('window.__gpuReads'));
  await ev(`window.__copied = null; navigator.clipboard.writeText = (t) => { window.__copied = t; return Promise.resolve(); }; 1`); await sleep(100);
  const rep = await ev(`(document.getElementById('ocx-crumbs-report') || {}).innerText || null`);
  check('the report is shown as plain text before any copy', rep && rep.indexOf('browser:') >= 0 && (await ev('window.__copied')) === null, rep && rep.split(String.fromCharCode(10)).length + ' lines');
    check('report keeps the browser string and the graphics string', rep && /browser: Mozilla/.test(rep) && /graphics: /.test(rep), rep && rep.split(String.fromCharCode(10)).filter((l) => /^(browser|graphics)/.test(l)));
  const repLines = (rep || '').split(String.fromCharCode(10));
  check('report opens with the cleared line, then the build line (hash and the build date)', repLines[0] === 'Orb Combat EX freeze report, made on this device. It lists device details, timings and errors. The game sent nothing.' && repLines[1] === 'build: ' + BUILD, repLines.slice(0, 2));
  check('report: no web address, no clock time (the build date is the only date), no page path', rep && !/https?:/.test(rep) && !/[0-9]{12,}/.test(rep) && rep.indexOf('127.0.0.1') < 0 && rep.indexOf('/play') < 0 && repLines.slice(2).join(' ').search(/20[0-9]{2}-[0-9]{2}-[0-9]{2}/) < 0, null);
  check('report: stalls and the times are relative', rep && /stalls \(start ms, length ms, stage\): \[\[/.test(rep), (rep || '').split(String.fromCharCode(10)).find((l) => l.indexOf('stalls') === 0));
  const buttons = await ev(`Array.from(document.getElementById('ocx-crumbs-note').querySelectorAll('button')).map((x) => x.innerText + (x.offsetParent ? '' : ' (hidden)'))`);
  check('the note has exactly Copy a report and Dismiss, above the text', JSON.stringify(buttons) === JSON.stringify(['Copy a report', 'Dismiss']) && (await ev(`(() => { const n = document.getElementById('ocx-crumbs-note'); const b = n.querySelector('button').getBoundingClientRect().top; return b < document.getElementById('ocx-crumbs-report').getBoundingClientRect().top; })()`)), buttons);
  await ev(`Array.from(document.getElementById('ocx-crumbs-note').querySelectorAll('button')).find((x) => x.innerText === 'Copy a report').click(); 1`); await sleep(400);
  check('after a copy the button says Copied', (await ev(`document.getElementById('ocx-crumbs-note').querySelector('button').innerText`)) === 'Copied');
  const copied = await ev('window.__copied');
  check('Copy copies exactly the text that was shown', copied === rep, copied && copied.length + ' chars, shown ' + (rep || '').length);
  check('copying clears the record', (await key()) === null, await key());
  await sleep(2600);
  check('and this visit writes none again', (await key()) === null, await key());

  // 4. Dismiss clears the record. (Prime a stalled record, load, dismiss.)
  await prime(rec);
  check('a primed stalled record shows the note again', (await ev(`document.getElementById('ocx-crumbs-note') !== null`)) === true);
  await ev(`navigator.clipboard.writeText = () => Promise.reject(new Error('no')); document.execCommand = () => false; Array.from(document.getElementById('ocx-crumbs-note').querySelectorAll('button')).find((x) => x.innerText === 'Copy a report').click(); 1`); await sleep(500);
  check('a failed copy says how to select the text by hand', (await ev(`document.getElementById('ocx-crumbs-note').querySelector('button').innerText`)) === 'Couldn' + String.fromCharCode(39) + 't copy. Press and hold the text to select it.');
  await ev(`Array.from(document.getElementById('ocx-crumbs-note').querySelectorAll('button')).find((x) => x.innerText === 'Dismiss').click(); 1`); await sleep(2600);
  check('dismiss removes the note and clears the record for good', (await ev(`document.getElementById('ocx-crumbs-note')`)) === null && (await key()) === null, await key());

  // 5. A visit closed before the game was running (abandoned mid-boot) also offers the note.
  await prime(JSON.stringify({ v: 1, ua: 'x', dpr: 2.6, scr: [915, 412], inner: [915, 412], mem: 4, cores: 8, stage: 'starting', stageAt: 1000, beatAt: 8000, dl: 100, clean: false, stalls: [], long: [], vis: [], ctx: [], err: [] }));
  check('an abandoned mid-boot record shows the note', (await ev(`(document.getElementById('ocx-crumbs-note') || {}).innerText || ''`)).indexOf('Last time the game stopped before it finished starting.' + TAIL) === 0);

  // 6. A lost graphics context: the engine's alert is held back, the page says so and offers a reload, the record keeps it.
  await load(); await ev(boot()); await ev(`document.getElementById('status').remove()`); await sleep(500);
  await ev(`(() => { const c = document.getElementById('canvas'); window.__alerted = false; c.addEventListener('webglcontextlost', () => { window.__alerted = true; }); c.dispatchEvent(new Event('webglcontextlost', { cancelable: true })); return 1; })()`); await sleep(2600);
  const ov = await ev(`(document.getElementById('ocx-ctx-lost') || {}).innerText || null`);
  const rc = JSON.parse(await key());
  check('context loss: the engine handler is not reached (no alert)', (await ev('window.__alerted')) === false);
  check('context loss: a page notice with a reload button', ov && ov.indexOf('The game lost its graphics.') === 0 && /Reload/.test(ov), ov);
  check('context loss: kept in the record, even on an otherwise clean visit', rc && rc.ctx.length === 1 && rc.ctx[0][1] === 'lost', rc && rc.ctx);

  // 7. Errors are cut short and any web address in them to host and path (query and hash gone). The marker is assembled here so this file holds no address text either.
  await load();
  const msg = 'load failed at ' + 'https' + '://cdn.example.org/lib/a.js?token=SECRET#frag, then ' + 'x'.repeat(200);
  await ev(`window.dispatchEvent(new ErrorEvent('error', { message: ${JSON.stringify(msg)} })); 1`); await sleep(2600);
  const re = JSON.parse(await key()); const et = re.err[0] && re.err[0][1];
  check('error text: query, hash and scheme cut, host and path kept', et && et.indexOf('cdn.example.org/lib/a.js') >= 0 && et.indexOf('SECRET') < 0 && et.indexOf('#') < 0 && et.indexOf('https') < 0, et && et.slice(0, 80));
  check('error text: shortened to 120 characters', et && et.length <= 120, et && et.length);

  // 8. A web address in the browser string is cut the same way.
  await page.send('Emulation.setUserAgentOverride', { userAgent: 'Mozilla/5.0 (compatible; TestBot/1.0; +' + 'https' + '://bots.example.org/about?id=77#top)' });
  await load(); await sleep(2600);
  const ru = JSON.parse(await key());
  check('browser string: address cut to host and path', ru && ru.ua.indexOf('bots.example.org/about') >= 0 && ru.ua.indexOf('id=77') < 0 && ru.ua.indexOf('#top') < 0 && ru.ua.indexOf('https') < 0, ru && ru.ua);
  check('still no cookie at the end', (await page.send('Network.getCookies')).cookies.length === 0 && (await ev('document.cookie')) === '');
} catch (e) {
  check('test run completed', false, String(e && e.message || e)); process.exitCode = 1;
} finally {
  try { if (page) page.close(); } catch { /* gone */ }
  try { if (b) await b.close(); } catch { /* gone */ }
  server.close();
}
const failed = results.filter((r) => !r.ok);
console.log(`${results.length - failed.length} of ${results.length} passed${failed.length ? '; FAILED: ' + failed.map((f) => f.name).join(' | ') : ''}`);
if (OUT) { mkdirSync(dirname(resolve(OUT)), { recursive: true }); writeFileSync(OUT, JSON.stringify({ results }, null, 1) + '\n'); }
if (failed.length) process.exitCode = 1;
