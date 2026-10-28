// Self-test of tools/check-site-hook.mjs on small stand-in pages (no game, no Godot): a good public page (the engine draws, no window.__flashcap), a page whose hook object appears when the URL
// says flashcap (the failure), a page whose hook appears only on a local host (a pass: the check runs on a public hostname), a page where the engine never draws (not proven), and a page with no
// gate button. Needs Chrome or Edge (--require-browser makes its absence a failure; otherwise it says so and exits 0).
//   node tools/check-site-hook-selftest.mjs [--require-browser] [--browser-path <exe>]
import { mkdtempSync, mkdirSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { browserExe } from './machine/browser.mjs';
import { checkHook } from './check-site-hook.mjs';

const argv = process.argv.slice(2);
const exe = argv.indexOf('--browser-path') >= 0 ? argv[argv.indexOf('--browser-path') + 1] : browserExe('chrome') || browserExe('edge');
if (!exe) { console.log(argv.includes('--require-browser') ? 'site hook self-test FAILED: no chrome or edge executable' : 'site hook self-test skipped: no chrome or edge executable'); process.exit(argv.includes('--require-browser') ? 1 : 0); }

// the stand-in page: a gate button; after the click a canvas that changes every 300 ms (the "engine"); `hook` says when window.__flashcap is made
const page = (hook, { gate = true, engine = true } = {}) => `<!doctype html><meta charset="utf-8"><title>stand-in</title>
${gate ? '<button id="gate-start">I understand, start</button>' : '<p>no button</p>'}
<canvas id="canvas" width="300" height="200"></canvas>
<script>
const q = location.search;
function startGame() {
  ${engine ? "let n = 0; setInterval(() => { const c = document.getElementById('canvas').getContext('2d'); c.fillStyle = 'hsl(' + (n * 37 % 360) + ',60%,50%)'; c.fillRect(0, 0, 300, 200); n++; }, 300);" : ''}
  ${hook === 'url' ? "if (q.includes('flashcap=1')) window.__flashcap = { start() {} };" : hook === 'local' ? "if (q.includes('flashcap=1') && ['localhost', '127.0.0.1'].includes(location.hostname)) window.__flashcap = { start() {} };" : ''}
}
document.getElementById('gate-start') && document.getElementById('gate-start').addEventListener('click', startGame);
</script>`;

// the stand-in of the REAL export's shape (the stock page: a #status overlay the page removes when engine.startGame resolves, the .wasm and .pck fetched): on the click it fetches its files, takes the overlay down and draws ONE
// settled, big picture straight away, with no loading states in between, which is what the pinned build did on the runner (2026-10-28: the first shot after the click was already the settled notice)
const enginePage = ({ fetchWasm = true, fetchPck = true, removeStatus = true, draw = true } = {}) => `<!doctype html><meta charset="utf-8"><title>stand-in engine</title>
<style>html,body{margin:0;background:#101218}canvas{position:fixed;left:0;top:0;width:100vw;height:100vh}#status{position:fixed;left:0;top:0;width:100vw;height:100vh;background:#101218;color:#ccc}#gate{position:fixed;left:0;top:0;z-index:5;background:#223;color:#fff;width:100vw;height:100vh}</style>
<div id="gate"><button id="gate-start">I understand, start</button></div>
<canvas id="canvas" width="960" height="540"></canvas>
<div id="status">loading</div>
<script>
document.getElementById('gate-start').addEventListener('click', async () => {
  document.getElementById('gate').remove();
  ${fetchWasm ? "await fetch('x.wasm');" : ''} ${fetchPck ? "await fetch('x.pck');" : ''}
  ${draw ? "const c = document.getElementById('canvas').getContext('2d'); const im = c.createImageData(960, 540); for (let i = 0; i < im.data.length; i += 4) { const v = (i * 2654435761 >>> 24) & 255; im.data[i] = v; im.data[i + 1] = v ^ 85; im.data[i + 2] = 255 - v; im.data[i + 3] = 255; } c.putImageData(im, 0, 0);" : ''}
  ${removeStatus ? "document.getElementById('status').remove();" : ''}
});
</script>`;
const engineSite = (name, o) => { const d = site(name, enginePage(o)); writeFileSync(join(d, 'play', 'x.wasm'), 'wasm'); writeFileSync(join(d, 'play', 'x.pck'), 'pck'); return d; };

const tmp = mkdtempSync(join(tmpdir(), 'site-hook-'));
let ran = 0, failed = 0;
const check = (name, ok, extra) => { ran++; if (!ok) { failed++; console.log(`  FAIL ${name}${extra ? ': ' + extra : ''}`); } };
const site = (name, html) => { const d = join(tmp, name); mkdirSync(join(d, 'play'), { recursive: true }); writeFileSync(join(d, 'play', 'index.html'), html); return d; };
const run = (d, o = {}) => checkHook({ site: d, exe, timeoutS: 40, ...o });
try {
  const good = await run(site('good', page('none')));
  check('a public page whose engine draws and that has no window.__flashcap passes', good.ok && good.notes.length === 1, JSON.stringify(good.problems));
  const bad = await run(site('bad', page('url')));
  check('a page that makes window.__flashcap when the URL says flashcap fails, and says what a visitor could do', !bad.ok && /window\.__flashcap exists/.test(bad.problems.join()) && /reduced: false/.test(bad.problems.join()), JSON.stringify(bad.problems));
  const local = await run(site('local', page('local')));
  check('a page whose hook appears only on a local host passes: the check runs on a public hostname, not localhost', local.ok, JSON.stringify(local.problems));
  const localHost = await run(site('local2', page('local')), { host: 'localhost' });
  check('the same page run as localhost fails (the host option really changes what the page sees)', !localHost.ok && /window\.__flashcap exists/.test(localHost.problems.join()), JSON.stringify(localHost.problems));
  const dead = await run(site('dead', page('none', { engine: false })), { timeoutS: 25 });
  check('a page where the engine never draws is not proven, and fails', !dead.ok && /not proven/.test(dead.problems.join()), JSON.stringify(dead.problems));
  // the real export's shape: the settled picture is there before the first shot after the click
  const eng = await run(engineSite('engine', {}), { timeoutS: 40 });
  check('an engine that has drawn its one settled picture before the first shot after the click is proven (the gate picture taken before the click is the baseline, not a second picture)', eng.ok && eng.notes.length === 1, JSON.stringify(eng.problems));
  const engNoStart = await run(engineSite('engine-nostart', { removeStatus: false }), { timeoutS: 20 });
  check('an engine page that never takes its loading overlay down (startGame never resolved) is not proven, whatever it draws', !engNoStart.ok && /not proven/.test(engNoStart.problems.join()) && /had not started/.test(engNoStart.problems.join()), JSON.stringify(engNoStart.problems));
  const engNoPck = await run(engineSite('engine-nopck', { fetchPck: false }), { timeoutS: 20 });
  check('an engine page that never fetched its pack is not proven', !engNoPck.ok && /not proven/.test(engNoPck.problems.join()) && /no pck/.test(engNoPck.problems.join()), JSON.stringify(engNoPck.problems));
  const engNoFiles = await run(engineSite('engine-nofiles', { fetchWasm: false, fetchPck: false }), { timeoutS: 20 });
  check('an engine page that fetched neither file is not proven (a real engine page always has both)', !engNoFiles.ok && /not proven/.test(engNoFiles.problems.join()), JSON.stringify(engNoFiles.problems));
  const engNothing = await run(engineSite('engine-nothing', { draw: false }), { timeoutS: 20 });
  check('an engine page that started but drew nothing (a blank page after the gate) is not proven', !engNothing.ok && /not proven/.test(engNothing.problems.join()), JSON.stringify(engNothing.problems));
  const nogate = await run(site('nogate', page('none', { gate: false })), { timeoutS: 12 });
  check('a page with no gate button fails', !nogate.ok && /#gate-start/.test(nogate.problems.join()), JSON.stringify(nogate.problems));
  let threw = false;
  try { await run(join(tmp, 'nothing-here')); } catch (e) { threw = /does not exist/.test(e.message); }
  check('a site folder with no /play/ is an error, not a pass', threw);
} finally { rmSync(tmp, { recursive: true, force: true }); }
console.log(failed ? `site hook self-test FAILED: ${failed} of ${ran}` : `site hook self-test ok: ${ran} checks`);
process.exit(failed ? 1 : 0);
