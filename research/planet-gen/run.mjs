// Render and measure one approach for the six seeds.
//   node research/planet-gen/run.mjs <base|A|B|C|Cb> [--seeds 7,11,23,42,101,2026] [--w 1024] [--out research/planet-gen]
// Writes img/<approach>/s<seed>-map.png (equirect, the fight ring dotted, the touch-down a red cross), -globe.png
// (orthographic, centred on the touch-down), -front.png and -back.png (fixed views), -ring.png (the 4,800 columns side-on) and stats/<approach>.json.
import { writeFileSync, mkdirSync } from 'node:fs';
import { join } from 'node:path';
import { performance } from 'node:perf_hooks';
import { sampleMap, colorMap, drawRingOnMap, drawRivers, globe, pickRing, readRing, ringStats, mapStats, ringStrip, ringPoint } from './lib/render.mjs';
import { NC, resetOct } from './lib/det.mjs';
import { surf } from './gen/base.mjs';
import { FROM_BASE } from './lib/biomes.mjs';
import { APPROACHES } from './gen/index.mjs';

const args = process.argv.slice(2);
const key = args[0];
const opt = (k, d) => { const i = args.indexOf('--' + k); return i >= 0 ? args[i + 1] : d; };
const seeds = opt('seeds', '7,11,23,42,101,2026').split(',').map(Number);
const W = Number(opt('w', 1024)), OUT = opt('out', 'research/planet-gen');
const A = APPROACHES[key];
if (!A) { console.error('approach?', Object.keys(APPROACHES).join(' ')); process.exit(1); }

const baseSample = (seed) => (x, y, z) => { const r = surf(seed, x, y, z); return [r[0], FROM_BASE[r[1]], 0]; };
function bestOf(n, fn) { let b = 1e18; for (let k = 0; k < n; k++) { const t0 = performance.now(); fn(); b = Math.min(b, performance.now() - t0); } return b; }

const report = { approach: key, title: A.title, params: A.params, seeds: {} };
for (const seed of seeds) {
  const t0 = performance.now();
  const st = A.init(seed);
  const initMs = performance.now() - t0;
  const sample = (x, y, z) => A.sample(st, x, y, z);
  const pick = pickRing(seed, sample);
  const ring = pick.ring;
  resetOct();
  const cold = () => { if (st.clim && st.clim.forget) st.clim.forget(); };   // every timed read starts with an empty memo
  const m0 = st.clim && st.clim.marchCount ? st.clim.marchCount() : 0;
  cold(); readRing(ring, sample);
  const marches = st.clim && st.clim.marchCount ? st.clim.marchCount() - m0 : 0;
  const ringMs = bestOf(5, () => { cold(); readRing(ring, sample); });
  const baseMs = bestOf(5, () => readRing(ring, baseSample(seed)));
  const S = readRing(ring, sample);
  const rs = ringStats(S);
  const t1 = performance.now();
  const M = sampleMap(sample, W, W / 2);
  const mapMs = performance.now() - t1;
  const img = colorMap(M, { rivers: !A.overlay });
  if (A.overlay) drawRivers(img, st.E);
  const gsrc = colorMap(M, { rivers: !A.overlay });
  if (A.overlay) drawRivers(gsrc, st.E);
  drawRingOnMap(img, ring);
  const dir = join(OUT, 'img', key);
  mkdirSync(dir, { recursive: true });
  img.save(join(dir, `s${seed}-map.png`));
  const t = ringPoint(ring, NC / 2);
  const lon = Math.atan2(-t[2], t[0]), lat = Math.max(-0.9, Math.min(0.9, Math.asin(t[1])));
  globe(gsrc, 480, lon, lat, ring).save(join(dir, `s${seed}-globe.png`));
  globe(gsrc, 480, 0.0, 0.35, null).save(join(dir, `s${seed}-front.png`));       // the same two views for every approach
  globe(gsrc, 480, Math.PI, 0.35, null).save(join(dir, `s${seed}-back.png`));
  ringStrip(S, `${A.title}  seed ${seed}  ring ${pick.k}${pick.ok ? '' : ' (no candidate met the minimum)'}  land ${rs.landPct}%  biomes ${rs.distinct}  rivers ${rs.rivers}`).save(join(dir, `s${seed}-ring.png`));
  const ms = mapStats(M);
  report.seeds[seed] = {
    map: ms, ring: { candidate: pick.k, metMinimum: pick.ok, ...rs },
    erosion: st.E ? { cells: st.E.cells, riverCells: st.E.riverCells, ms: Object.fromEntries(Object.entries(st.E.t).map(([k, v]) => [k, +v.toFixed(0)])) } : undefined,
    cost: { latticeMarchesPerRing: marches, initMs: +initMs.toFixed(1), ringReadMs: +ringMs.toFixed(1), baseRingReadMs: +baseMs.toFixed(1), perColumnVsToday: +(ringMs / baseMs).toFixed(2),
      initAsColumnsOfToday: +(initMs / (baseMs / NC)).toFixed(0), mapMs: +mapMs.toFixed(0) },
  };
  console.log(`${key} seed ${seed}: land ${ms.landPct}%  land biomes>1% ${ms.landBiomesOver1}  ring k${pick.k} ${pick.ok ? 'ok' : 'MISS'} land ${rs.landPct}% biomes ${rs.distinct} changes ${rs.changes} rivers ${rs.rivers}  init ${initMs.toFixed(0)} ms  ring ${ringMs.toFixed(0)} ms (today ${baseMs.toFixed(0)} ms, x${(ringMs / baseMs).toFixed(2)})  map ${mapMs.toFixed(0)} ms`);
}
mkdirSync(join(OUT, 'stats'), { recursive: true });
writeFileSync(join(OUT, 'stats', `${key}.json`), JSON.stringify(report, null, 1));
