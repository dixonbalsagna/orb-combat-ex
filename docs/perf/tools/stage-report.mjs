// Turns the stage-timer CSVs of docs/perf/tools/stage-run.mjs into tables: where a frame's time goes, in all frames and in the classes the brief names (terrain deformation, high-speed launches), with p95 and worst frames.
//   node docs/perf/tools/stage-report.mjs --runs a.csv,b.csv,c.csv [--label x] [--warm 60] [--json out.json] [--fast 0.95]
// Several runs of the SAME match (same seed and world) are frame-for-frame the same work (the sim is deterministic), so the report takes each frame's MINIMUM across the runs: another session's load only adds time, so the
// minimum is the frame's own cost, and a spike that is real (the same frame in every run) stays. A stage's time is inclusive of what it calls. All times in ms.
import { readFileSync, writeFileSync } from 'node:fs';

const argv = process.argv.slice(2);
const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
const runs = (opt('--runs', '') || '').split(',').filter(Boolean);
if (!runs.length) { console.error('usage: node stage-report.mjs --runs a.csv,b.csv [--label x] [--warm 60] [--json out.json]'); process.exit(2); }
const WARM = Number(opt('--warm', 60)), FASTQ = Number(opt('--fast', 0.95));

const GAUGES = new Set(['cam_dx', 'craters', 'fillwin', 'launched', 'parts', 'swept', 'tick', 'ticks', 'tier', 'vmax', 'ring', 'nc', 'g_full', 'draws', 'rcpu', 'rgpu', 'frame', 'wall_ms']);
const isCount = (k) => k.startsWith('n_');

function load(path) {
  const lines = readFileSync(path, 'utf8').split(/\r?\n/).filter(Boolean);
  const keys = lines[0].split(',');
  const cols = {};
  keys.forEach((k) => { cols[k] = new Float64Array(lines.length - 1); });
  for (let i = 1; i < lines.length; i++) { const p = lines[i].split(','); for (let j = 0; j < keys.length; j++) cols[keys[j]][i - 1] = Number(p[j]); }
  return { keys, cols, n: lines.length - 1 };
}
const data = runs.map(load);
const n = Math.min(...data.map((d) => d.n));
const keys = data[0].keys;
const warnings = [];
for (const d of data.slice(1)) {
  let diff = 0;
  for (let i = WARM; i < n; i++) if (d.cols.tick[i] !== data[0].cols.tick[i] || d.cols.craters[i] !== data[0].cols.craters[i]) diff++;
  if (diff) warnings.push(`a run differs from the first in ${diff} frames' tick or crater count: not the same match; minimum taken anyway`);
}
// merged columns: gauges from the first run; times (and counters' last) the minimum over runs, in ms
const C = {};
for (const k of keys) {
  if (k === 'frame') continue;
  const a = new Float64Array(n);
  const timeCol = !GAUGES.has(k) && !isCount(k) || k === 'wall_ms';
  const scale = timeCol && k !== 'wall_ms' ? 1 / 1000 : 1;
  for (let i = 0; i < n; i++) {
    let v = data[0].cols[k][i];
    if (timeCol) for (const d of data) v = Math.min(v, d.cols[k][i]);
    a[i] = v * scale;
  }
  C[k] = a;
}
const g = (k) => C[k] || new Float64Array(n);
const sumCols = (ks) => { const a = new Float64Array(n); for (const k of ks) { const c = g(k); for (let i = 0; i < n; i++) a[i] += c[i]; } return a; };
C.work = sumCols(['f_advance', 'f_render', 'f_uihud', 'f_audioplay']);
C.sim = g('tick_us');   // already scaled by 1/1000 above (tick_us and fx_us are time columns in microseconds)
C.fxc = g('fx_us');

const pct = (arr, q) => { if (!arr.length) return 0; const s = Array.from(arr).sort((a, b) => a - b); return s[Math.min(s.length - 1, Math.floor(s.length * q))]; };
const mean = (arr) => (arr.length ? arr.reduce((a, b) => a + b, 0) / arr.length : 0);
const pick = (c, idx) => idx.map((i) => c[i]);

// ---- frame classes ----
const all = []; for (let i = WARM; i < n; i++) all.push(i);
const dcr = (i) => (i > 0 ? C.craters[i] - C.craters[i - 1] : 0);
const absdx = Array.from(C.cam_dx).map(Math.abs);
const fastThr = pct(all.map((i) => absdx[i]), FASTQ);
const vThr = pct(all.map((i) => C.vmax[i]), FASTQ);
const classes = {
  all,
  'a crater is dug (frames with a new crater)': all.filter((i) => dcr(i) > 0 || g('n_s_dig')[i] > 0),
  'the ground is re-sent (g_upload > 0)': all.filter((i) => g('g_upload')[i] > 0),
  'a full ground rebuild': all.filter((i) => g('n_g_rebuild')[i] > 0),
  'water fills (a fill window is open)': all.filter((i) => C.fillwin[i] > 0),
  [`camera fast (|dx| >= ${fastThr.toFixed(1)} units/frame, the top ${Math.round((1 - FASTQ) * 100)}%)`]: all.filter((i) => absdx[i] >= fastThr && fastThr > 0),
  [`a body fast (speed >= ${vThr.toFixed(0)}, the top ${Math.round((1 - FASTQ) * 100)}%)`]: all.filter((i) => C.vmax[i] >= vThr),
  'a body is launched': all.filter((i) => C.launched[i] > 0),
  'the slowest 1% of frames (by work)': (() => { const t = pct(all.map((i) => C.work[i]), 0.99); return all.filter((i) => C.work[i] >= t); })(),
};

// ---- the stage tree (inclusive times; the rest of a parent is "other") ----
const TREE = [
  ['work', [
    ['f_advance', [
      ['sim (SimCore.step)', 'tick_us', [['s_control'], ['s_fighters'], ['s_director'], ['s_beam'], ['s_shots'], ['s_water'], ['s_mood'], ['s_collateral']]],
      ['host (events, camera, cues)', 'fx_us', [['h_camstep'], ['h_fxv'], ['h_impact'], ['h_audiocues'], ['h_drained', [['d_splitrig'], ['d_planet'], ['d_anim'], ['d_ui'], ['d_barks'], ['d_haptics'], ['d_feed'], ['d_roll']]], ['h_vfx'], ['h_flashes'], ['h_flashask_b'], ['h_flashask_h'], ['h_hub']]],
    ]],
    ['f_render', [
      ['r_farmap'], ['r_splitrig'],
      ['r_panes', [['r_camrig'], ['r_panhaze'], ['r_skydrive'], ['r_forelow'], ['r_viewcues'], ['r_viewspan'], ['r_see'],
        ['r_planetupdate', [['p_ground', [['g_gcol'], ['g_shore'], ['g_rubble'], ['g_concat'], ['g_setdata'], ['g_texupdate'], ['g_uphot'], ['g_rebuild']]],
          ['p_refresh', [['p_visitlist'], ['p_visit'], ['p_grow'], ['p_trees'], ['p_props'], ['p_cuts']]], ['p_flightarr'], ['p_flightstep'], ['p_startle'], ['p_watershow'], ['p_wfapply']]],
        ['r_cull'], ['r_fighters'], ['r_occlusion'], ['r_vfxlayer'], ['r_beams'], ['r_particles']]],
      ['r_present'], ['r_uibridge'],
    ]],
    ['f_uihud'], ['f_audioplay'],
  ]],
];
const CROSS = ['s_dig', 's_relax', 's_dignbr', 's_fillopen', 's_lakerefill', 's_fillwin', 's_after', 's_fire'];

function colOf(name, key) { return key ? g(key) : g(name); }
function rows(node, depth, idx, out) {
  const [name, a, b] = node;
  const key = typeof a === 'string' ? a : null;
  const kids = Array.isArray(a) ? a : b;
  const c = key ? g(key) : g(name);
  const v = pick(c, idx);
  out.push({ depth, name: key ? `${name}` : name, mean: mean(v), p95: pct(v, 0.95), p99: pct(v, 0.99), max: Math.max(...v, 0) });
  if (kids && kids.length) {
    for (const k of kids) rows(k, depth + 1, idx, out);
    const own = pick(kids.reduce((acc, k) => { const kk = typeof k[1] === 'string' ? k[1] : k[0]; const kc = g(kk); for (let i = 0; i < n; i++) acc[i] += kc[i]; return acc; }, new Float64Array(n)), idx);
    const other = v.map((x, i) => Math.max(0, x - own[i]));
    out.push({ depth: depth + 1, name: 'other', mean: mean(other), p95: pct(other, 0.95), p99: pct(other, 0.99), max: Math.max(...other, 0) });
  }
}

const f2 = (x) => (x >= 100 ? x.toFixed(0) : x >= 10 ? x.toFixed(1) : x.toFixed(2));
const label = opt('--label', runs.map((r) => r.split(/[\\/]/).pop()).join(' + '));
const lines = [];
lines.push(`# Stage report: ${label}`);
lines.push(`runs: ${runs.length} (per-frame minimum), frames ${WARM}..${n - 1} (${all.length}), NC ${C.nc[WARM]}, planet ring ${C.ring[WARM] ? 'yes' : 'no'}`);
for (const w of warnings) lines.push(`WARNING: ${w}`);
const wallAll = pick(C.wall_ms, all);
lines.push(`wall frame (engine, with load): mean ${f2(mean(wallAll))} p95 ${f2(pct(wallAll, 0.95))} p99 ${f2(pct(wallAll, 0.99))} max ${f2(Math.max(...wallAll))}   (a single run's wall is skewed by load; read the minimum-based work below)`);
const json = { label, runs, frames: all.length, classes: {} };
for (const [cname, idx] of Object.entries(classes)) {
  if (!idx.length) { lines.push(`\n## ${cname}: no frames`); continue; }
  const w = pick(C.work, idx);
  lines.push(`\n## ${cname}: ${idx.length} frames (${(100 * idx.length / all.length).toFixed(1)}%)   work mean ${f2(mean(w))} p95 ${f2(pct(w, 0.95))} p99 ${f2(pct(w, 0.99))} max ${f2(Math.max(...w))}`);
  if (cname !== 'all' && !cname.startsWith('the slowest') && cname !== 'a body is launched') {
    // only the stages that differ from the other frames
  }
  const out = [];
  for (const t of TREE) rows(t, 0, idx, out);
  const cross = CROSS.map((k) => { const v = pick(g(k), idx); return { depth: 0, name: `(inclusive) ${k}`, mean: mean(v), p95: pct(v, 0.95), p99: pct(v, 0.99), max: Math.max(...v, 0) }; });
  json.classes[cname] = { frames: idx.length, rows: out.concat(cross) };
  lines.push('| stage | mean | p95 | p99 | max |');
  lines.push('|---|---|---|---|---|');
  for (const r of out.concat(cross)) {
    if (r.mean < 0.005 && r.max < 0.05) continue;
    lines.push(`| ${'  '.repeat(r.depth)}${r.name} | ${f2(r.mean)} | ${f2(r.p95)} | ${f2(r.p99)} | ${f2(r.max)} |`);
  }
  const wl = pick(C.wall_ms, idx), gp = idx.map((i) => Math.max(0, C.wall_ms[i] - C.work[i]));
  lines.push(`wall (frame to frame) mean ${f2(mean(wl))} p95 ${f2(pct(wl, 0.95))} p99 ${f2(pct(wl, 0.99))} max ${f2(Math.max(...wl))}; wall minus work (engine draw, GPU wait, browser) mean ${f2(mean(gp))} p95 ${f2(pct(gp, 0.95))} p99 ${f2(pct(gp, 0.99))} max ${f2(Math.max(...gp))}`);
  const ex = ['swept', 'craters', 'launched', 'parts', 'n_s_dig', 'n_fx'].map((k) => `${k} ${f2(mean(pick(g(k), idx)))}`).join(', ');
  lines.push(`means: ${ex}`);
}
// the worst frames, one line each: what they were made of (the leaf stages that took most), and what was going on
const LEAF = ['s_control', 's_fighters', 's_director', 's_beam', 's_shots', 's_water', 's_mood', 's_collateral', 'h_fxv', 'h_impact', 'h_audiocues', 'd_splitrig', 'd_planet', 'd_anim', 'd_ui', 'd_barks', 'd_haptics', 'd_feed', 'd_roll', 'h_vfx', 'h_flashes', 'r_farmap', 'r_splitrig', 'r_camrig', 'r_panhaze', 'r_skydrive', 'r_forelow', 'r_viewcues', 'r_viewspan', 'r_see',
  'g_gcol', 'g_shore', 'g_rubble', 'g_concat', 'g_setdata', 'g_texupdate', 'g_uphot', 'g_rebuild', 'p_visitlist', 'p_visit', 'p_grow', 'p_trees', 'p_props', 'p_cuts', 'p_flightarr', 'p_flightstep', 'p_startle', 'p_watershow', 'p_wfapply', 'r_cull', 'r_fighters', 'r_occlusion', 'r_vfxlayer', 'r_beams', 'r_particles', 'r_present', 'r_uibridge', 'f_uihud', 'f_audioplay'];
const worst = all.slice().sort((x, y) => C.work[y] - C.work[x]).slice(0, Number(opt('--worst', 20)));
lines.push(`\n## the ${worst.length} worst frames (work ms; the stages that took most; what was going on)`);
for (const i of worst) {
  const top = LEAF.filter((k) => C[k]).map((k) => [k, C[k][i]]).sort((p, q) => q[1] - p[1]).slice(0, 4).map(([k, v]) => `${k} ${f2(v)}`).join(', ');
  lines.push(`- frame ${i} tick ${C.tick[i]} work ${f2(C.work[i])}: ${top} | launched ${C.launched[i]} vmax ${C.vmax[i].toFixed(0)} cam_dx ${C.cam_dx[i].toFixed(1)} craters ${C.craters[i]}${dcr(i) > 0 ? ' (+' + dcr(i) + ')' : ''} fillwin ${C.fillwin[i]} swept ${C.swept[i]} ticks ${C.ticks[i]}`);
}
const text = lines.join('\n');
console.log(text);
if (opt('--json')) writeFileSync(opt('--json'), JSON.stringify(json));
