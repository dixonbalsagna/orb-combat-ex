// The wrapper directors use for any browser picture that is not the flash check's (docs/tools/machine-captures.md). It starts the one guarded browser of tools/machine/browser.mjs (time
// limit, below-normal priority, a CPU cap, a tidy profile folder, gone with this process), serves a built folder or opens a URL, and takes pictures. Nobody needs a Chrome launcher of their own.
//
//   node tools/machine/capture.mjs still  --dir <built site> [--path /index.html?x=1] | --url <page>  --out shot.png  [--wait-ms 3000 | --wait-js "window.__ready"]  [--init-js "window.__cap = 1"]
//                                         [--after-js "expression run before the picture"] [--width 1024 --height 768] [--format png|jpeg --quality 88]
//   node tools/machine/capture.mjs frames --dir <built site> | --url <page>  --out <folder>  --count 600  [--first 1]  --step-js "window.__adv = {n}"  --tick-js "window.__tick"
//                                         [--init-js ...] [--wait-js ...] [--info-js "expression saved beside each frame in index.txt"] [--format jpeg --quality 88] [--every 1]
//   node tools/machine/capture.mjs eval   --dir <built site> | --url <page>  --js "expression"  [--wait-js ...]     prints the value (for a probe; no picture)
//
//   still:  loads the page, waits (a pause, or until --wait-js is true), runs --after-js, saves one picture.
//   frames: for n from --first to --count: runs --step-js with {n} replaced by n, waits until --tick-js reads at least n, and saves frame n (a hook the page offers: a posed scene, a study
//           stepped one tick at a time). Frames are <out>/t00001.png ...; with --info-js, <out>/index.txt lists `frame info`.
//   --init-js runs before the page's own scripts (Page.addScriptToEvaluateOnNewDocument), so a scratch hook can be switched on by a global.
// Common: --session <name> (or MERIDIAN_SESSION; it is in the profile folder's name: use your own), --purpose <word> (default "still" or "frames"), --time-limit <seconds> (default 3600; the
// browser is killed when it passes), --cpu-cap <percent> (default 25), --software (software rendering: ONE software capture at a time per session), --browser-path <exe>, --isolation (the
// threaded-WebAssembly headers when serving a folder), --quiet.
import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { Cdp, launchBrowser, serve, browserExe, slug } from './browser.mjs';

const argv = process.argv.slice(2);
const cmd = argv[0];
const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
const has = (n) => argv.includes(n);
const usage = (m) => { if (m) console.error(m); console.error('usage: node tools/machine/capture.mjs (still | frames | eval) (--dir <built site> [--path /index.html] | --url <page>) ... (see the header of tools/machine/capture.mjs)'); process.exit(2); };
if (!['still', 'frames', 'eval'].includes(cmd)) usage();
const known = new Set(['--dir', '--path', '--url', '--out', '--wait-ms', '--wait-js', '--init-js', '--after-js', '--width', '--height', '--format', '--quality', '--count', '--first', '--step-js', '--tick-js',
  '--info-js', '--every', '--js', '--session', '--purpose', '--time-limit', '--cpu-cap', '--software', '--browser-path', '--isolation', '--quiet']);
for (const a of argv.slice(1)) if (a.startsWith('--') && !known.has(a)) usage(`unknown option ${a}`);
const DIR = opt('--dir'), URL_ = opt('--url');
if ((!DIR && !URL_) || (DIR && URL_)) usage('give --dir or --url');
const WIDTH = Number(opt('--width', 1024)), HEIGHT = Number(opt('--height', 768));
const FORMAT = opt('--format', 'png');
const quiet = has('--quiet');
const log = (m) => { if (!quiet) console.log(`[capture] ${m}`); };
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const exe = opt('--browser-path') || browserExe('chrome');
if (!exe) usage('no Chrome found: pass --browser-path');
if (cmd !== 'eval' && !opt('--out')) usage('--out is required');
if (cmd === 'eval' && !opt('--js')) usage('--js is required');

let server;
let url = URL_;
if (DIR) {
  server = await serve(DIR, { isolation: has('--isolation') });
  url = `http://127.0.0.1:${server.address().port}${opt('--path', '/index.html')}`;
}
const timeLimitS = Number(opt('--time-limit', 3600));
let b, page, code = 0;
try {
  b = await launchBrowser({
    exe, session: opt('--session'), purpose: opt('--purpose', cmd), timeoutS: timeLimitS, cpuPercent: Number(opt('--cpu-cap', 25)), log,
    flags: [`--window-size=${WIDTH},${HEIGHT}`, ...(has('--software') ? ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] : [])],
  });
  page = await Cdp.open(b.target.webSocketDebuggerUrl);
  await page.send('Page.enable');
  await page.send('Emulation.setDeviceMetricsOverride', { width: WIDTH, height: HEIGHT, deviceScaleFactor: 1, mobile: false });
  if (opt('--init-js')) await page.send('Page.addScriptToEvaluateOnNewDocument', { source: opt('--init-js') });
  await page.send('Page.navigate', { url });
  log(`${url}`);
  const waitJs = opt('--wait-js');
  if (waitJs) {
    let ok = false;
    while (Date.now() < b.deadlineMs && !ok) { await sleep(300); ok = Boolean(await page.eval(waitJs).catch(() => false)); }
    if (!ok) throw new Error(`the page never made ${waitJs} true within the time limit`);
  } else await sleep(Number(opt('--wait-ms', 3000)));
  const shot = async (file) => {
    const r = await page.send('Page.captureScreenshot', FORMAT === 'jpeg' ? { format: 'jpeg', quality: Number(opt('--quality', 88)) } : { format: 'png', fromSurface: true });
    mkdirSync(dirname(resolve(file)), { recursive: true });
    writeFileSync(file, Buffer.from(r.data, 'base64'));
  };
  if (cmd === 'eval') {
    const v = await page.eval(opt('--js'), true);
    console.log(typeof v === 'string' ? v : JSON.stringify(v));
  } else if (cmd === 'still') {
    if (opt('--after-js')) await page.eval(opt('--after-js'), true);
    await shot(opt('--out'));
    log(`wrote ${opt('--out')}`);
  } else {
    const out = opt('--out');
    mkdirSync(out, { recursive: true });
    const first = Number(opt('--first', 1)), count = Number(opt('--count', 100)), every = Number(opt('--every', 1));
    const step = opt('--step-js'), tick = opt('--tick-js');
    if (!step || !tick) usage('frames needs --step-js and --tick-js');
    const index = [];
    const ext = FORMAT === 'jpeg' ? 'jpg' : 'png';
    const t0 = Date.now();
    for (let n = first; n <= count; n++) {
      if (Date.now() > b.deadlineMs) throw new Error(`the time limit (${timeLimitS} s) passed at frame ${n}`);
      await page.eval(step.replace(/\{n\}/g, String(n)), true);
      let t = -1;
      for (let w = 0; w < 4000 && t < n; w++) { t = Number(await page.eval(tick)); if (!(t >= n)) await sleep(5); }
      if (!(t >= n)) throw new Error(`the page did not reach tick ${n} (it reads ${t})`);
      if ((n - first) % every !== 0) continue;
      const name = `t${String(n).padStart(5, '0')}.${ext}`;
      await shot(join(out, name));
      if (opt('--info-js')) index.push(`${name} ${await page.eval(opt('--info-js'))}`);
      if (n % 100 === 0) log(`frame ${n} of ${count} (${Math.round((Date.now() - t0) / 1000)} s)`);
    }
    if (index.length) writeFileSync(join(out, 'index.txt'), index.join('\n') + '\n');
    log(`wrote frames ${first} to ${count} to ${out}`);
  }
} catch (e) {
  console.error(`[capture] FAILED: ${e.message}`);
  code = 1;
} finally {
  if (page) page.close();
  if (b) await b.close();
  if (server) server.close();
}
void slug;
process.exit(code);
