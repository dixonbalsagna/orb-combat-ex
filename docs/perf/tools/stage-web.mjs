// The stage timers on the WEB build, as the private preview serves it (standard template, single-threaded): exports a stage-timer tree (make-stage-tree.mjs) to Web, gives the page a bench entry (?frames=N&seed=S&planet=P), and runs it in Tools' guarded browser
// with the GPU of your choice. The game publishes its per-frame CSV to window.__perfcsv when the run ends; this writes it to --out. Below-normal priority, a real window (the GPU path is what is timed), one browser, gone when this ends.
//   node docs/perf/tools/stage-web.mjs export --tree <dir> --web <dir>
//   node docs/perf/tools/stage-web.mjs run --web <dir> --out <csv> [--seed 4] [--frames 3600] [--planet 7] [--stress 75] [--igpu] [--throttle 1] [--timeout 900] [--width 1280 --height 720]
import { spawn } from 'node:child_process';
import { closeSync, existsSync, mkdirSync, openSync, readFileSync, writeFileSync } from 'node:fs';
import { constants as osConstants, setPriority } from 'node:os';
import { join } from 'node:path';
import { Cdp, launchBrowser, serve, browserExe } from '../../../tools/machine/browser.mjs';

const argv = process.argv.slice(2);
const cmd = argv[0];
const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

if (cmd === 'export') {
  const tree = opt('--tree'), web = opt('--web');
  if (!tree || !web) { console.error('usage: stage-web.mjs export --tree <dir> --web <dir>'); process.exit(2); }
  mkdirSync(web, { recursive: true });
  const godot = process.env.GODOT || join(process.env.LOCALAPPDATA || '', 'Programs', 'Godot', '4.7.2', 'Godot_v4.7.2-stable_win64_console.exe');
  const fd = openSync(`${web}.export.log`, 'w');
  const child = spawn(godot, ['--headless', '--path', tree, '--export-release', 'Web', join(web, 'index.html')], { stdio: ['ignore', fd, fd], windowsHide: true });
  try { setPriority(child.pid, osConstants.priority.PRIORITY_BELOW_NORMAL); } catch { /* gone */ }
  const timer = setTimeout(() => { try { child.kill(); } catch { /* gone */ } }, 25 * 60 * 1000);
  const code = await new Promise((ok) => child.on('close', ok));
  clearTimeout(timer); closeSync(fd);
  if (code !== 0 || !existsSync(join(web, 'index.html'))) { console.error(`export exited ${code}; see ${web}.export.log`); process.exit(1); }
  let html = readFileSync(join(web, 'index.html'), 'utf8');
  if (!html.includes('"args":[]')) throw new Error('the exported page has no "args":[] to replace');
  html = html.replace('"args":[]', () => '"args":benchArgs()').replace('</head>', () => `<script>
function benchArgs() {
  const q = new URLSearchParams(location.search);
  const frames = Math.max(300, Math.min(30000, parseInt(q.get('frames') || '3600', 10) || 3600));
  const a = ['--fixed-fps', '60', '--', '--seed=' + (q.get('seed') || '4'), '--frames=' + frames, '--bench', '--perfout=x', '--vpw=' + (q.get('w') || '1280'), '--vph=' + (q.get('h') || '720')];
  if (q.get('planet')) a.push('--planet=' + q.get('planet'));
  if (q.get('stress')) a.push('--stress=' + q.get('stress'));
  if (q.get('arenacols')) a.push('--arenacols=' + q.get('arenacols'));
  if (q.get('ringcost')) a.push('--ringcost=1');
  if (q.get('turn')) a.push('--turn=1', '--turnk=' + (q.get('turnk') || '32'), '--turnfb=' + (q.get('turnfb') || '2.5'));
  return a;
}
</script></head>`);
  writeFileSync(join(web, 'index.html'), html);
  console.log(`exported to ${web}`);
  process.exit(0);
}

if (cmd === 'run') {
  const web = opt('--web'), out = opt('--out');
  if (!web || !out) { console.error('usage: stage-web.mjs run --web <dir> --out <csv> [...]'); process.exit(2); }
  const seed = opt('--seed', '4'), frames = opt('--frames', '3600'), planet = opt('--planet', '');
  const igpu = argv.includes('--igpu'), throttle = Number(opt('--throttle', 1)), timeoutS = Number(opt('--timeout', 900));
  const W = Number(opt('--width', 1280)), H = Number(opt('--height', 720));
  const server = await serve(web);
  const url = `http://127.0.0.1:${server.address().port}/index.html?frames=${frames}&seed=${seed}&w=${W}&h=${H}${planet ? `&planet=${planet}` : ''}${opt('--stress', '') ? `&stress=${opt('--stress')}` : ''}${opt('--arenacols', '') ? `&arenacols=${opt('--arenacols')}` : ''}${argv.includes('--ringcost') ? '&ringcost=1' : ''}${argv.includes('--turn') ? `&turn=1&turnk=${opt('--turnk', 32)}&turnfb=${opt('--turnfb', 2.5)}` : ''}`;
  let b, page; const meta = { out, seed, frames, planet, igpu, throttle, size: `${W}x${H}` };
  try {
    b = await launchBrowser({
      exe: browserExe('chrome'), session: process.env.MERIDIAN_SESSION || 'meridian-performance-platform', purpose: 'stage', timeoutS: timeoutS + 120, log: () => {}, cpuPercent: 0, priority: 'belownormal', headless: false,
      flags: ['--disable-gpu-vsync', '--disable-frame-rate-limit', '--disable-background-timer-throttling', '--disable-renderer-backgrounding', '--disable-backgrounding-occluded-windows', `--window-size=${W + 20},${H + 140}`, '--window-position=0,0', ...(igpu ? ['--force_low_power_gpu'] : [])],
    });
    page = await Cdp.open(b.target.webSocketDebuggerUrl);
    await page.send('Emulation.setDeviceMetricsOverride', { width: W, height: H, deviceScaleFactor: 1, mobile: false });
    if (throttle !== 1) await page.send('Emulation.setCPUThrottlingRate', { rate: throttle });
    await page.send('Page.addScriptToEvaluateOnNewDocument', { source: "window.__log=[];for(const k of ['log','info','warn','error']){const o=console[k];console[k]=function(){try{window.__log.push(k+': '+Array.from(arguments).join(' ').slice(0,300));if(window.__log.length>60)window.__log.shift();}catch(e){}o.apply(console,arguments);};}window.addEventListener('error',e=>window.__log.push('onerror: '+e.message));" });
    await page.send('Page.navigate', { url });
    const deadline = Date.now() + timeoutS * 1000;
    while (Date.now() < deadline) {
      await sleep(2000);
      const s = await page.eval('window.__perfcsv ? window.__perfcsv.length : 0').catch(() => 0);
      if (s > 0) break;
    }
    const csv = await page.eval('window.__perfcsv || ""').catch(() => '');
    meta.bench = JSON.parse((await page.eval('JSON.stringify(window.__benchResult || null)').catch(() => 'null')) || 'null');
    meta.gpu = await page.eval(`(() => { try { const gl = document.createElement('canvas').getContext('webgl2'); const e = gl && gl.getExtension('WEBGL_debug_renderer_info'); return e ? gl.getParameter(e.UNMASKED_RENDERER_WEBGL) : 'unavailable'; } catch (e) { return 'unavailable'; } })()`).catch(() => 'unavailable');
    if (!csv) meta.error = `no result within ${timeoutS} s`;
    else writeFileSync(out, csv);
    if (!csv) meta.log = await page.eval('JSON.stringify((window.__log||[]).slice(-25))').catch(() => '');
  } finally {
    try { page && page.close(); } catch { /* gone */ }
    if (b) await b.close();
    server.close();
  }
  writeFileSync(`${out}.json`, JSON.stringify(meta));
  console.log(`${meta.error || 'ok'} | ${meta.gpu} | ${meta.bench ? meta.bench.head : ''}`);
  process.exit(meta.error ? 1 : 0);
}
console.error('usage: stage-web.mjs export|run ...');
process.exit(2);
