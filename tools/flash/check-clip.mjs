// One command to re-run one pixel clip (or a few) against your own change: exports the project's working tree as a web build (or HEAD with --head), plays the named clip(s) through
// headless Chrome, analyses them at the standard's reference size against the gate (2.5 flashes in any second, Legal's RL-119), keeps the frames of the worst second and of every dip,
// and prints the verdict. Zero cost, one Godot process (the export), headless only.
//
//   node tools/flash/check-clip.mjs --clip collapse-normal[,collapse-reduced] [--out <folder>] [--head] [--site <built site dir>] [--godot <exe>] [--jobs 2]
//
// Clip ids: mash, clash, signature, transform, collapse, ai-<seed> (and ai-<A>-<B>-<seed> for another pairing), each with -normal or -reduced (tools/flash/sources.json has the list).
// "Fixed" means this prints no failure for the clip in BOTH modes. Cost on a 16-thread PC with a GPU: the export about 40 s (with the import), then a 1,500-tick clip about 5 minutes
// (capture 4 and analysis 1) and an ai match (3,600 ticks) about 11; two clips in parallel cost about the same wall time as one. --site reuses an export you already have.
// The page needs the capture hook (/play/?flashcap=1, render/tools/flash_capture.gd); the staging in it must match tools/flash/flash_worst.gd (run-pixels.mjs checks).
import { spawn, spawnSync } from 'node:child_process';
import { existsSync, mkdirSync, mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir, platform } from 'node:os';
import { join, dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const root = resolve(here, '..', '..');
const argv = process.argv.slice(2);
const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
const CLIP = opt('--clip');
if (!CLIP) { console.error('usage: node tools/flash/check-clip.mjs --clip collapse-normal[,collapse-reduced] [--out <folder>] [--head] [--site <dir>] [--godot <exe>] [--jobs 2]'); process.exit(2); }
const OUT = resolve(opt('--out', join(tmpdir(), 'flash-check-clip')));
mkdirSync(OUT, { recursive: true });
const t0 = Date.now();
const secs = () => `${Math.round((Date.now() - t0) / 1000)} s`;

function godotExe() {
  const c = [opt('--godot'), process.env.GODOT];
  if (platform() === 'win32') for (const base of [process.env.LOCALAPPDATA && join(process.env.LOCALAPPDATA, 'Programs', 'Godot'), 'C:\\Program Files\\Godot']) {
    if (base && existsSync(base)) for (const v of ['4.7.2']) c.push(join(base, v, `Godot_v${v}-stable_win64_console.exe`));
  }
  c.push('godot', 'godot4');
  return c.find((x) => x && (x === 'godot' || x === 'godot4' ? spawnSync(x, ['--version'], { stdio: 'ignore' }).status === 0 : existsSync(x)));
}

let site = opt('--site');
if (!site) {
  const exe = godotExe();
  if (!exe) { console.error('no Godot found: pass --godot <exe> or set GODOT (4.7.2, with the web export templates)'); process.exit(2); }
  let project = root;
  if (argv.includes('--head')) {
    project = mkdtempSync(join(OUT, 'head-'));
    const ar = spawnSync('git', ['archive', 'HEAD'], { cwd: root, maxBuffer: 1 << 30 });
    const tar = spawnSync('tar', ['-x', '-C', project], { input: ar.stdout });
    if (ar.status !== 0 || tar.status !== 0) { console.error('git archive HEAD failed'); process.exit(1); }
  }
  console.log(`[check-clip] exporting the web build of ${argv.includes('--head') ? 'HEAD' : 'the working tree'} (${secs()})`);
  for (const args of [['--headless', '--path', project, '--import'], ['--headless', '--path', project, '--export-release', 'Web', join(OUT, 'site', 'index.html')]]) {
    if (args[3] === '--export-release') mkdirSync(join(OUT, 'site'), { recursive: true });
    const r = spawnSync(exe, args, { encoding: 'utf8', timeout: 900000 });
    if (r.status !== 0 && args.includes('--export-release')) { console.error(`the web export failed:\n${(r.stdout || '').split('\n').slice(-8).join('\n')}`); process.exit(1); }
  }
  site = join(OUT, 'site');
}
console.log(`[check-clip] capturing and analysing ${CLIP} (${secs()})`);
const child = spawn(process.execPath, [join(here, 'run-pixels.mjs'), '--dir', site, '--path', '/index.html?flashcap=1', '--out', join(OUT, 'clips'), '--clip', CLIP, '--jobs', opt('--jobs', '2'), '--keep-ranges'], { stdio: 'inherit', env: { ...process.env, MSYS_NO_PATHCONV: '1' } });
child.on('close', (code) => {
  console.log(`\n[check-clip] done in ${secs()}. Frames of the worst second and of every dip are in ${join(OUT, 'clips')}/<clip>/ (kept-ranges.json lists the ticks; frame-NNNNNN.png is tick NNNNNN).`);
  if (!argv.includes('--head') && !opt('--site')) console.log(`[check-clip] the export is in ${site} (delete it when you are done)`);
  process.exit(code ?? 1);
});
