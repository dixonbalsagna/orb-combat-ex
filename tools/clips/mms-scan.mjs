// A seed scan for a clip hunt (Tools, 2026-11-10; the MMS clips): no pictures, just the sim's own events of a scene for each seed, so a seed with a big launch, a long chain or a building falling can be picked by
// numbers. One page, one guarded browser, below-normal, a time limit.
//
//   node tools/clips/mms-scan.mjs --build <kept folder> --scene chase --words "planet=7&meteor=loud&tiles=1&nohud=1&blackbox=off" --seeds 1,2,3 --ticks 900 [--out <json>] [--limit 1200]
//
// Prints one line a seed: the count of each event kind and the first ticks of the interesting ones. --out writes the whole event list per seed.
import { writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { openPage, resolveBuild } from './make.mjs';

const a = process.argv.slice(2);
const opt = (n, d) => { const i = a.indexOf(n); return i >= 0 && i + 1 < a.length ? a[i + 1] : d; };
const build = resolveBuild(opt('--build'));
const scene = opt('--scene', 'ai'), words = opt('--words', 'planet=7&meteor=loud&tiles=1&nohud=1&blackbox=off');
const seeds = String(opt('--seeds', '12345')).split(',').map(Number);
const ticks = Number(opt('--ticks', 900)), limit = Number(opt('--limit', 1500));
const op = await openPage(build.web, words, 960, 540, limit);
const all = {};
try {
  for (const seed of seeds) {
    await op.page.eval(`window.__flashcap.start(${JSON.stringify(scene)}, { reduced: false, seed: ${seed} })`, true);
    const ev = [];
    for (let i = 0; i < ticks; i++) {
      const got = await op.page.eval('window.__flashcap.step().then((t) => ({ tick: t, ev: (window.__flashcap.events || []).splice(0), err: window.__flashcap.error || null }))', true);
      for (const e of got.ev || []) ev.push(e);
      if (got.err && !/no scenario/.test(got.err)) { console.log(`seed ${seed}: error ${got.err}`); break; }
    }
    all[seed] = ev;
    const by = {};
    for (const e of ev) { const k = e[1] + (e[2] ? ':' + e[2] : ''); (by[k] = by[k] || []).push(e[0]); }
    console.log(`seed ${seed}: ` + Object.entries(by).map(([k, t]) => `${k}=${t.length}@${t.slice(0, 4).join('/')}`).join(' '));
  }
} finally {
  try { op.page.close(); } catch { /* gone */ }
  try { await op.browser.close(); } catch { /* gone */ }
  op.server.close();
}
if (opt('--out')) writeFileSync(resolve(opt('--out')), JSON.stringify(all));
process.exit(0);
