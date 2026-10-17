#!/usr/bin/env node
// Turns folders of frame-bench JSON runs (docs/perf/tools/audit-run.mjs and the follow-up runs) into the markdown tables of the audit. Node built-ins only.
//   node docs/perf/tools/audit-summary.mjs <runs folder> [<more folders>...] [--only-valid]
// Each table row is one (site, scene, throttle, GPU) with the median over its repeats. A row built from runs that were not valid by the load rule is marked "inv".
import { readdirSync, readFileSync } from 'node:fs';
import { join, resolve } from 'node:path';

const dirs = process.argv.slice(2).filter((a) => !a.startsWith('--')).map((d) => resolve(d));
const onlyValid = process.argv.includes('--only-valid');
const runs = [];
for (const dir of dirs) for (const f of readdirSync(dir).filter((x) => x.endsWith('.json'))) runs.push({ f, ...JSON.parse(readFileSync(join(dir, f), 'utf8')) });
const ok = runs.filter((r) => !r.failure);
const med = (a) => { const v = a.filter((x) => Number.isFinite(x)).sort((x, y) => x - y); return v.length ? v[Math.floor(v.length / 2)] : NaN; };
const f1 = (x) => (Number.isFinite(x) ? x.toFixed(1) : '-');
const f2 = (x) => (Number.isFinite(x) ? x.toFixed(2) : '-');
const key = (r) => [r.label, r.slice ? 'slice' : r.layers ? 'layers:' + r.scene : r.scene + (r.slots ? '[' + r.slots.length + ']' : '') + (r.pageArgs ? '+' + r.pageArgs : ''), 'x' + r.throttle, r.igpu ? 'igpu' : 'dgpu'].join('|');
const groups = new Map();
for (const r of ok) { if (onlyValid && !r.valid) continue; const k = key(r); if (!groups.has(k)) groups.set(k, []); groups.get(k).push(r); }
const stat = (rs, field, s) => med(rs.map((r) => r[field] && r[field][s]));
const cpu = (rs, n) => med(rs.map((r) => r.cpu_ms_per_frame && r.cpu_ms_per_frame[n]));
const out = [];
const scenes = ['mashcity', 'signaturecity', 'ring[3]', 'ring[5]'];
const validAll = (rs) => (rs.every((r) => r.valid) ? 'yes' : 'inv');

out.push('### Frame cost, every (site, scene, throttle, GPU)\n');
out.push('Frame = the interval between two animation frames with the game running one tick a frame (vsync and the frame limit off). p10 is the best case on a busy machine. CPU ms/frame is the CPU time the browser\'s processes used per frame.\n');
out.push('| site | scene | throttle | GPU | frame p10 | p50 | p95 | p99 | max | tick | fx+cam | view | draws p50 | draws max | prims p50 (k) | prims max (k) | CPU renderer | CPU gpu proc | CPU total | valid |');
out.push('|---|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|');
for (const [k, rs] of [...groups.entries()].sort()) {
  const [label, scene, th, gpu] = k.split('|');
  if (scene === 'slice' || scene.startsWith('layers:')) continue;
  out.push(`| ${label} | ${scene} | ${th} | ${gpu} | ${f1(stat(rs, 'frame_ms', 'p10'))} | ${f1(stat(rs, 'frame_ms', 'p50'))} | ${f1(stat(rs, 'frame_ms', 'p95'))} | ${f1(stat(rs, 'frame_ms', 'p99'))} | ${f1(stat(rs, 'frame_ms', 'max'))} | ${f2(stat(rs, 'tick_ms', 'mean'))} | ${f2(stat(rs, 'fx_ms', 'mean'))} | ${f2(stat(rs, 'view_ms', 'mean'))} | ${f1(stat(rs, 'draws', 'p50'))} | ${f1(stat(rs, 'draws', 'max'))} | ${f1(stat(rs, 'prims', 'p50') / 1000)} | ${f1(stat(rs, 'prims', 'max') / 1000)} | ${f1(cpu(rs, 'renderer'))} | ${f1(cpu(rs, 'gpu-process'))} | ${f1(cpu(rs, 'total'))} | ${validAll(rs)} |`);
}

out.push('\n### Cost of each parked item against base (median over repeats)\n');
out.push('| scene | throttle | site | frame p10 | delta | frame p50 | delta | CPU renderer | delta | CPU total | delta | draws max | delta | prims max (k) | delta | valid |');
out.push('|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|');
for (const sc of scenes) for (const th of ['x1', 'x4']) {
  const b = groups.get(['base', sc, th, 'dgpu'].join('|'));
  if (!b) continue;
  const base = { p10: stat(b, 'frame_ms', 'p10'), p50: stat(b, 'frame_ms', 'p50'), cr: cpu(b, 'renderer'), ct: cpu(b, 'total'), dm: stat(b, 'draws', 'max'), pm: stat(b, 'prims', 'max') / 1000 };
  for (const l of ['base', 'vfx', 'anim', 'both']) {
    const g = groups.get([l, sc, th, 'dgpu'].join('|'));
    if (!g) continue;
    const v = { p10: stat(g, 'frame_ms', 'p10'), p50: stat(g, 'frame_ms', 'p50'), cr: cpu(g, 'renderer'), ct: cpu(g, 'total'), dm: stat(g, 'draws', 'max'), pm: stat(g, 'prims', 'max') / 1000 };
    const d = (a, c) => (l === 'base' ? '' : (a - c >= 0 ? '+' : '') + f2(a - c));
    out.push(`| ${sc} | ${th} | ${l} | ${f1(v.p10)} | ${d(v.p10, base.p10)} | ${f1(v.p50)} | ${d(v.p50, base.p50)} | ${f1(v.cr)} | ${d(v.cr, base.cr)} | ${f1(v.ct)} | ${d(v.ct, base.ct)} | ${f1(v.dm)} | ${d(v.dm, base.dm)} | ${f1(v.pm)} | ${d(v.pm, base.pm)} | ${validAll(g)} |`);
  }
}

const pieces = new Set();
for (const rs of groups.values()) for (const r of rs) if (r.pt_ms) for (const k of Object.keys(r.pt_ms)) pieces.add(k);
out.push('\n### Where the main thread\'s GDScript goes (mean ms per frame, from the profiling timers; baseprof = HEAD, bothprof = HEAD with every parked item)\n');
if (pieces.size) {
  const order = ['host_advance', 'fighters_update', 'hud_advance', 'planet_update', 'vfx_layer', 'particles', 'pane_pre', 'occlusion', 'beams', 'split_rig_frame', 'present'].filter((p) => pieces.has(p));
  out.push('| scene | site | ' + order.join(' | ') + ' |');
  out.push('|---|---|' + order.map(() => '---:').join('|') + '|');
  for (const sc of scenes) for (const l of ['baseprof', 'bothprof']) {
    const g = groups.get([l, sc, 'x1', 'dgpu'].join('|'));
    if (!g) continue;
    out.push(`| ${sc} | ${l} | ` + order.map((p) => f2(med(g.map((r) => r.pt_ms && r.pt_ms[p] && r.pt_ms[p].mean)))).join(' | ') + ' |');
  }
}

out.push('\n### Layer cuts: draw calls, primitives and frame time with each layer hidden (median over the run; difference from "(none)" is that layer\'s share)\n');
const ly = [...groups.entries()].filter(([k]) => k.split('|')[1].startsWith('layers:'));
for (const [k, rs] of ly.sort()) {
  const r0 = rs[0]; const base = r0.layers.find((x) => x.cut === '(none)');
  out.push(`\n**${k.split('|')[1].slice(7)}** (${validAll(rs)})\n`);
  out.push('| layers hidden | draws | draws removed | prims (k) | prims removed (k) | frame p50 ms | frame removed ms | view ms | CPU renderer / frame | CPU gpu proc / frame |');
  out.push('|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|');
  for (const l of r0.layers) out.push(`| ${l.cut} | ${f1(l.draws)} | ${f1(base.draws - l.draws)} | ${f1(l.prims_k)} | ${f1(base.prims_k - l.prims_k)} | ${f1(l.frame_p50)} | ${f1(base.frame_p50 - l.frame_p50)} | ${f2(l.view_ms)} | ${f1(l.cpu_ms_per_frame.renderer)} | ${f1(l.cpu_ms_per_frame['gpu-process'])} |`);
}

out.push('\n### Planet-slice strip read, 4,800 columns, best of reps (ms)\n');
const sl = [...groups.entries()].filter(([k]) => k.split('|')[1] === 'slice');
if (sl.length) {
  const modes = new Set();
  for (const [, rs] of sl) for (const r of rs) Object.keys(r.slice || {}).forEach((m) => modes.add(m));
  out.push('| site | throttle | GPU | ' + [...modes].join(' | ') + ' | valid |');
  out.push('|---|---|---|' + [...modes].map(() => '---:').join('|') + '|---|');
  for (const [k, rs] of sl.sort()) { const [label, , th, gpu] = k.split('|'); out.push(`| ${label} | ${th} | ${gpu} | ` + [...modes].map((m) => f1(med(rs.map((r) => r.slice && r.slice[m] && r.slice[m].best_ms)))).join(' | ') + ` | ${validAll(rs)} |`); }
}

out.push('\n### Memory (MB, at the end of a run; private bytes of each browser process type, and the engine\'s own video and texture memory)\n');
out.push('| site | scene | renderer private | gpu-process private | browser private | utility private | all private | all working set | engine video mem | engine texture mem |\n|---|---|---:|---:|---:|---:|---:|---:|---:|---:|');
for (const [k, rs] of [...groups.entries()].sort()) {
  const [label, scene, th, gpu] = k.split('|');
  if (scene === 'slice' || scene.startsWith('layers:') || th !== 'x1' || gpu !== 'dgpu') continue;
  const m = (n) => med(rs.map((r) => r.browserMemMB && r.browserMemMB[n]));
  out.push(`| ${label} | ${scene} | ${f1(m('renderer_private'))} | ${f1(m('gpu-process_private'))} | ${f1(m('browser_private'))} | ${f1(m('utility_private'))} | ${f1(m('total_private'))} | ${f1(m('total_ws'))} | ${f1(med(rs.map((r) => r.video_mem_bytes && r.video_mem_bytes.p50)) / 1048576)} | ${f1(med(rs.map((r) => r.texture_mem_bytes && r.texture_mem_bytes.p50)) / 1048576)} |`);
}

// noise: identical configurations repeated
const noise = ok.filter((r) => !r.slice && !r.layers && (r.label === 'base-noise' || (r.label === 'base' && r.scene === 'mashcity' && r.throttle === 1 && !r.igpu && !r.pageArgs)));
if (noise.length > 1) {
  out.push('\n### Noise: the same scene (base, city brawl, throttle 1) measured several times\n');
  out.push('| run | load before / during / after (%) | frame p10 | p50 | p95 | CPU renderer | CPU total | draws max | prims max (k) |\n|---|---|---:|---:|---:|---:|---:|---:|---:|');
  for (const r of noise) out.push(`| ${r.f} | ${r.loadBefore.all}/${r.loadDuring.all}/${r.loadAfter.all} | ${f1(r.frame_ms.p10)} | ${f1(r.frame_ms.p50)} | ${f1(r.frame_ms.p95)} | ${f1(r.cpu_ms_per_frame && r.cpu_ms_per_frame.renderer)} | ${f1(r.cpu_ms_per_frame && r.cpu_ms_per_frame.total)} | ${f1(r.draws.max)} | ${f1(r.prims.max / 1000)} |`);
  const spread = (xs) => { const v = xs.filter(Number.isFinite); return v.length > 1 ? (Math.max(...v) - Math.min(...v)) / med(v) * 100 : NaN; };
  out.push(`\nSpread (max minus min over the median): frame p10 ${f1(spread(noise.map((r) => r.frame_ms.p10)))}%, frame p50 ${f1(spread(noise.map((r) => r.frame_ms.p50)))}%, CPU renderer ${f1(spread(noise.map((r) => r.cpu_ms_per_frame && r.cpu_ms_per_frame.renderer)))}%, CPU total ${f1(spread(noise.map((r) => r.cpu_ms_per_frame && r.cpu_ms_per_frame.total)))}%, draws ${f1(spread(noise.map((r) => r.draws.max)))}%, primitives ${f1(spread(noise.map((r) => r.prims.max)))}%.`);
}
const bad = ok.filter((r) => !r.valid).length;
out.push(`\n${ok.length} runs read (${runs.length - ok.length} failed), ${bad} not valid by the load rule (mean use of all processors above 60% or of the capture's cores above 70% before or after the run).`);
console.log(out.join('\n'));
