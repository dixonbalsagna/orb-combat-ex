#!/usr/bin/env node
// Builds the scratch web exports the audit measures, from HEAD, without touching the working tree. Node 24 built-ins plus git, tar and the Godot 4.7.2 console exe. Owner: Performance and Platform.
//
//   node docs/perf/tools/make-audit-sites.mjs --out <folder> [--only base,vfx,anim,both,anim8,baseprof,bothprof,depthprof,layerprof,lowprof] [--rev <commit>] [--godot <exe>] [--no-export]
//
// For each variant: git archive HEAD into <out>/<name>, apply the scratch hooks (docs/perf/tools/scratch-hooks/: they only add measuring code to render/tools/flash_capture.gd, and in
// the "prof" variants a few timers to render/core/main.gd and pane_world.gd), apply the parked patches that variant stands for, then `--headless --import` and `--export-release Web`
// (one Godot at a time, below-normal priority, a time limit), then lay out <out>/<name>/build/site/play for tools/machine/browser.mjs's server. Nothing here opens a window.
//   base       HEAD + perf hook + slice hook
//   vfx        base + VFX's docs/vfx/pending/energy-and-choreo/apply.patch
//   anim       base + Animation's five patches (docs/animation/pending/, in order)
//   both       vfx + the five Animation patches
//   baseprof   base + the profiling timers + the coarse slice modes
//   bothprof   both + the profiling timers
//   depthprof  baseprof + a page flag that turns fight-lane depth on (the lobby only runs with depth on)
//   layerprof  baseprof + layer cuts (window.__cut, including Camera's inset pane and the HUD) for the draw call and primitive breakdown
//   nowarm     base with the inset warm-up (Camera, 5fe08207) reversed: the A/B for the match-start hitch
//   evlog      base + the event-type log of each tick (what the sim did at a hitching tick)
//   lat        base + the input-latency scene (hook-latency.mjs; docs/perf/tools/latency-bench.mjs reads it)
//   strip      base + page flag sx= that switches off one piece of the strip at a time (hook-strip.mjs)
//   ring       base + main's own ring read (WorldPlanet.readSlice) behind window.__slicebench (k1200, k2400, k4800), for the old-laptop cost of World's ring read
//   p22f       base + Rendering's parked 22f (the ground by band)
//   p22h       base + Rendering's parked 22h (the scorch and the heat on their own small texture)
//   textwarm   base + UI's parked HUD text warm-up (docs/ui/pending/text-warm)
//   turn       base + the scenes turn and turnoff (a Half planet arena with the calm-moment turn on or off) and the tick of each arena_turn event (hook-turn.mjs)
//   evprof     evlog + the profiling timers (the CPU time of each section at a hitching tick)
//   aura       base + VFX's parked 3D aura (apply.patch, grant-fighter-view.patch) and a page flag aura=1 (auradem=1: both shells at full level)
//   lowprof    depthprof + a page flag lowq=1 (VFX quality low, automatic step off): the reduced-effects mode
// The parked patches are applied with `git apply --ignore-whitespace`; when HEAD has moved so far that one no longer applies, the variant is reported and skipped (say so in the audit).
import { spawn, spawnSync } from 'node:child_process';
import { copyFileSync, cpSync, existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { setPriority, constants } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const repo = resolve(here, '..', '..', '..');
const argv = process.argv.slice(2);
const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
const OUT = opt('--out');
if (!OUT) { console.error('usage: node docs/perf/tools/make-audit-sites.mjs --out <folder> [--only a,b] [--godot <exe>] [--no-export]'); process.exit(2); }
const only = opt('--only') ? opt('--only').split(',') : ['base', 'vfx', 'anim', 'both', 'baseprof', 'bothprof', 'depthprof', 'layerprof', 'lowprof', 'anim8'];
const GODOT = opt('--godot', 'C:\\Users\\itsha\\AppData\\Local\\Programs\\Godot\\4.7.2\\Godot_v4.7.2-stable_win64_console.exe');
const NOEXP = argv.includes('--no-export');
const REV = opt('--rev', 'HEAD');   // any commit: the audit of two builds (for example a build Orb played and the one after it) builds each into its own --out folder
const out = resolve(OUT);
mkdirSync(out, { recursive: true });
const hook = (name, dir, ...extra) => { const r = spawnSync(process.execPath, [join(here, 'scratch-hooks', name), dir, ...extra], { encoding: 'utf8' }); if (r.status) throw new Error(`${name}: ${r.stderr || r.stdout}`); };
const apply = (dir, patch) => { const rev = patch.startsWith('R:'); if (rev) patch = patch.slice(2); const r = spawnSync('git', ['apply', '--ignore-whitespace', ...(rev ? ['-R'] : []), resolve(repo, patch)], { cwd: dir, encoding: 'utf8' }); if (r.status) throw new Error(`git apply ${patch}: ${r.stderr}`); };
const VFX = 'docs/vfx/pending/energy-and-choreo/apply.patch';
const ANIM = ['many-bodies', 'runs-look', 'tenth-round', 'combat-pieces', 'homework4'].map((p) => `docs/animation/pending/${p}.patch`);
// Animation parked three more after the audit's brief (README order); on a HEAD where VFX's beam look has landed (47f402cb) the VFX patch no longer applies, so `anim8` is the whole parked stack for that HEAD
const ANIM8 = [...ANIM, 'pulled-frames', 'live-scan-and-tier', 'guard-pass'].map((p) => (p.startsWith('docs/') ? p : `docs/animation/pending/${p}.patch`));
const SLICE_LIB = resolve(repo, 'docs/world/scratch-build/planet-slice/planet2_lib.gd');
const SPEC = {
  base: { patches: [], hooks: ['perf', 'slice'] },
  vfx: { patches: [VFX], hooks: ['perf', 'slice'] },
  anim: { patches: ANIM, hooks: ['perf', 'slice'] },
  both: { patches: [VFX, ...ANIM], hooks: ['perf', 'slice'] },
  anim8: { patches: ANIM8, hooks: ['perf', 'slice'] },
  nowarm: { patches: ['R:docs/perf/tools/scratch-hooks/inset-warm.patch'], hooks: ['perf', 'slice'] },
  lat: { patches: [], hooks: ['perf', 'slice', 'latency'] },
  strip: { patches: [], hooks: ['perf', 'slice', 'strip'] },
  ring: { patches: [], hooks: ['perf', 'slice', 'ring'] },
  p22f: { patches: ['docs/rendering/pending/2026-10-22f/batch.diff'], hooks: ['perf', 'slice'] },
  p22h: { patches: ['docs/rendering/pending/2026-10-22h/batch.diff'], hooks: ['perf', 'slice'] },
  textwarm: { patches: ['docs/ui/pending/text-warm/text-warm.patch'], hooks: ['perf', 'slice'] },
  turn: { patches: [], hooks: ['perf', 'slice', 'turn'] },
  turn7b: { patches: [], hooks: ['calm7b', 'perf', 'slice', 'turn'] },
  turnprof: { patches: [], hooks: ['perf', 'slice', 'turn', 'turnprof'] },
  evlog: { patches: [], hooks: ['perf', 'slice', 'evlog'] },
  evprof: { patches: [], hooks: ['perf', 'slice', 'prof', 'slicec8', 'evlog'] },
  aura: { patches: ['docs/vfx/pending/aura3d/apply.patch', 'docs/vfx/pending/aura3d/grant-fighter-view.patch'], hooks: ['perf', 'slice', 'aura'] },
  baseprof: { patches: [], hooks: ['perf', 'slice', 'prof', 'slicec8'] },
  bothprof: { patches: [VFX, ...ANIM], hooks: ['perf', 'slice', 'prof'] },
  depthprof: { patches: [], hooks: ['perf', 'slice', 'prof', 'slicec8', 'depth'] },
  layerprof: { patches: [], hooks: ['perf', 'slice', 'prof', 'slicec8', 'layers'] },
  lowprof: { patches: [], hooks: ['perf', 'slice', 'prof', 'slicec8', 'depth', 'lowq'] },
};
const HOOK = { perf: ['hook-perf.mjs'], slice: ['hook-slice.mjs', SLICE_LIB], prof: ['hook-prof.mjs'], slicec8: ['hook-slice-c8.mjs'], depth: ['hook-depth.mjs'], layers: ['hook-layers.mjs'], lowq: ['hook-lowq.mjs'], aura: ['hook-aura.mjs'], evlog: ['hook-evlog.mjs'], latency: ['hook-latency.mjs'], strip: ['hook-strip.mjs'], ring: ['hook-ring.mjs'], turn: ['hook-turn.mjs'], calm7b: ['hook-calm7b.mjs'], turnprof: ['hook-turnprof.mjs'] };

function godot(dir, args, log, limitS) {
  return new Promise((ok) => {
    const p = spawn(GODOT, args, { cwd: dir, stdio: ['ignore', 'pipe', 'pipe'] });
    let text = '';
    p.stdout.on('data', (d) => { text += d; }); p.stderr.on('data', (d) => { text += d; });
    try { setPriority(p.pid, constants.priority.PRIORITY_BELOW_NORMAL); } catch { /* not allowed */ }
    const t = setTimeout(() => { try { process.kill(p.pid); } catch { /* gone */ } }, limitS * 1000);
    p.on('exit', (c) => { clearTimeout(t); writeFileSync(log, text); ok(c); });
  });
}

// one pristine copy of HEAD, then one folder per variant (a copy of it)
const pristine = join(out, '_head');
if (!existsSync(join(pristine, 'project.godot'))) {
  mkdirSync(pristine, { recursive: true });
  // tar runs inside the target folder with no path of its own: GNU tar reads "C:\..." as a remote host
  const r = spawnSync(`git -C "${repo}" archive ${REV} | tar -x`, { cwd: pristine, shell: true, encoding: 'utf8' });
  if (r.status) throw new Error('git archive failed: ' + r.stderr);
}
writeFileSync(join(out, 'HEAD.txt'), spawnSync('git', ['rev-parse', REV], { cwd: repo, encoding: 'utf8' }).stdout);
let imported = null;
for (const name of only) {
  const spec = SPEC[name];
  if (!spec) { console.error('unknown variant ' + name); continue; }
  const dir = join(out, name);
  if (existsSync(join(dir, 'build', 'site', 'play', 'index.html'))) { console.log(`${name}: already built, skipped`); continue; }
  console.log(`${name}: copy, hooks, patches`);
  cpSync(pristine, dir, { recursive: true });
  try {
    for (const p of spec.patches) apply(dir, p);
    for (const h of spec.hooks) hook(HOOK[h][0], dir, ...HOOK[h].slice(1));
  } catch (e) { console.error(`${name}: SKIPPED, ${e.message.slice(0, 300)}`); continue; }
  if (NOEXP) continue;
  if (imported && existsSync(join(imported, '.godot'))) cpSync(join(imported, '.godot'), join(dir, '.godot'), { recursive: true });
  console.log(`${name}: import and export`);
  const c1 = await godot(dir, ['--headless', '--path', '.', '--import'], join(out, `${name}-import.log`), 1500);
  mkdirSync(join(dir, 'build', 'web'), { recursive: true });
  const c2 = await godot(dir, ['--headless', '--path', '.', '--export-release', 'Web', 'build/web/index.html'], join(out, `${name}-export.log`), 1500);
  if (!existsSync(join(dir, 'build', 'web', 'index.wasm'))) { console.error(`${name}: export failed (import ${c1}, export ${c2}); see the logs in ${out}`); continue; }
  mkdirSync(join(dir, 'build', 'site'), { recursive: true });
  cpSync(join(dir, 'build', 'web'), join(dir, 'build', 'site', 'play'), { recursive: true });
  if (!imported) imported = dir;
  console.log(`${name}: built ${join(dir, 'build', 'site')}`);
}
