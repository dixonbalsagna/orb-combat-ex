// Does the clash scene DRAW the press, and does its level change the picture? (Performance, 2026-10-31). Steps the hook's clash scene to the same tick on each page and hashes ONE screenshot per page IN MEMORY (nothing is
// saved or shown; a hash is all that leaves): equal hashes mean the same pixels. Through Tools' launcher, the Radeon with --igpu. Order of the RL-226 note: no clips, no pictures kept, no flash numbers.
//   node docs/perf/tools/swing-bench/press-drawn-check.mjs --a <siteA> --b <siteB> [--ticks 400]
import { createHash } from 'node:crypto';
import { Cdp, launchBrowser, serve, browserExe } from '../../../../tools/machine/browser.mjs';
const argv = process.argv.slice(2);
const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
const A = opt('--a'), B = opt('--b'), TICKS = Number(opt('--ticks', 400));
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
async function shot(site, query) {
  const server = await serve(site);
  const b = await launchBrowser({ exe: browserExe('chrome'), session: process.env.MERIDIAN_SESSION || 'meridian-performance-platform', purpose: 'presscheck', timeoutS: 420, log: () => {}, cpuPercent: 0, priority: 'belownormal', flags: ['--window-size=1280,720', '--force_low_power_gpu'] });
  const page = await Cdp.open(b.target.webSocketDebuggerUrl);
  try {
    await page.send('Page.enable'); await page.send('Emulation.setDeviceMetricsOverride', { width: 1280, height: 720, deviceScaleFactor: 1, mobile: false });
    await page.send('Page.navigate', { url: `http://127.0.0.1:${server.address().port}/play/index.html?flashcap=1${query ? '&' + query : ''}` });
    const t0 = Date.now(); let ready = false;
    while (Date.now() - t0 < 300000 && !ready) { await sleep(500); ready = Boolean(await page.eval('!!(window.__flashcap && window.__flashcap.ready)').catch(() => false)); }
    if (!ready) throw new Error('never ready');
    await page.eval(`window.__flashcap.start('clash', {reduced: false, seed: 4242})`);
    const out = [];
    let at = 0;
    for (const T of [60, 120, 180, 240, 300, 360, 420, 480, 540, 600, 700]) {
      await page.eval(`(async () => { for (let i = 0; i < ${T - at}; i++) await window.__flashcap.step(); return window.__flashcap.tick; })()`, true);
      at = T;
      await sleep(250);
      const r = await page.send('Page.captureScreenshot', { format: 'png' });
      out.push(createHash('sha1').update(r.data).digest('hex').slice(0, 6));
    }
    return out.join(' ');
  } finally { try { page.close(); } catch { /* gone */ } await b.close().catch(() => {}); server.close(); }
}
console.log('ticks        60     120    180    240    300    360    420    480    540    600    700');
for (const [label, site, q] of [['A (old flare)', A, ''], ['B level 0', B, 'pq=0'], ['B level 1', B, 'pq=1'], ['B level 2', B, 'pq=2']]) console.log(label.padEnd(13), await shot(site, q));
