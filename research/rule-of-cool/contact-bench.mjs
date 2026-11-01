// Cost and a rough flash count for research/rule-of-cool/beam-contact-test.html, on a real GPU. One browser, through Tools' launcher.
//   node research/rule-of-cool/contact-bench.mjs [--igpu]
// Cost: milliseconds to draw a 400 x 400 pixel patch at the contact, 1280 x 720 canvas, best of 5 batches, less the same patch with only the backdrop. Flash: never a substitute for Tools' analyser.
import { launchBrowser, browserExe, Cdp } from '../../tools/machine/browser.mjs';
import { pathToFileURL } from 'node:url';
import { resolve } from 'node:path';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const igpu = process.argv.includes('--igpu'), url = pathToFileURL(resolve('research/rule-of-cool/beam-contact-test.html')).href;
const W = 1280, H = 900;
const b = await launchBrowser({ exe: browserExe('chrome'), session: 'research', purpose: 'contactbench', timeoutS: 200, cpuPercent: 0, priority: 'belownormal', headless: false, log: () => {},
  flags: ['--disable-gpu-vsync', '--disable-frame-rate-limit', '--disable-background-timer-throttling', '--disable-renderer-backgrounding', '--disable-backgrounding-occluded-windows', `--window-size=${W + 20},${H + 140}`, '--window-position=0,0', ...(igpu ? ['--force_low_power_gpu'] : [])] });
let code = 0;
try {
  const page = await Cdp.open(b.target.webSocketDebuggerUrl);
  await page.send('Page.enable'); await page.send('Runtime.enable');
  await page.send('Emulation.setDeviceMetricsOverride', { width: W, height: H, deviceScaleFactor: 1, mobile: false });
  await page.send('Page.navigate', { url });
  for (let i = 0; i < 40; i++) { await sleep(500); if (await page.eval('window.__ok>=1').catch(() => false)) break; }
  const js = `(function(){window.__hold=1;var gl=BT.gl,e=gl.getExtension('WEBGL_debug_renderer_info'),o={gpu:e?gl.getParameter(e.UNMASKED_RENDERER_WEBGL):'?',cost:{},flash:{}};function best(m){var b=1e9;for(var r=0;r<5;r++)b=Math.min(b,BT.cost(m,30));return b;}
var names={9:'backdrop',0:'today',1:'A flare',2:'B sheet',3:'C curl',4:'D puffs',5:'E feedback',6:'lite',7:'C one step'};var base=best(9);o.cost.backdrop=+base.toFixed(3);[0,1,2,3,4,5,6,7].forEach(function(m){o.cost[names[m]]=+(best(m)-base).toFixed(3);});base=best(9);o.cost.backdropAgain=+base.toFixed(3);
[0,2,3,4,5,6,7].forEach(function(m){o.flash[names[m]]=BT.flash(m,180);});return JSON.stringify(o);})()`;
  console.log(await page.eval(js));
} catch (e) { console.error(String(e)); code = 1; } finally { await b.close(); }
process.exit(code);
