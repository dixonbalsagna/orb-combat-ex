// The one-click first run (Tools and Performance, 2026-11-23; path to Alpha 1, job 8). One script starts the BUILT program, plays one fixed match, saves stills at fixed moments, records the frame rate and the loading
// times, saves a report and closes the program.
//   node tools/first-run/first-run.mjs [--exe <orb-combat-ex.exe | a folder | a ORB-PRIVATE zip>] [--size default|small|medium|big|all] [--out <folder>] [--seed 4] [--no-window] [--frames 1800] [--limit 600] [--no-quit-check]
//   FIRST-RUN.cmd (beside this file) is the click: it runs this with the newest ORB-PRIVATE Windows zip in homework/Files/desktop.
// How it runs the game (read this before trusting a number):
//   * The program is started the way a player starts it: NO bypass word (a locked build honours none: ui/hud/ui_hud.gd bypass_allowed), so the game shows its own warning about flashing effects. The script never
//     presses through that warning: a person reads it and presses Enter in the game (the run waits for the picture to change). Only the program's own --print-fps is added (one "Project FPS" line a second),
//     and --seed=<n> so the match behind the menu is the same one every run.
//   * Stills and keys go through tools/first-run/window.ps1 (Windows PowerShell): one still of the game's window at each step of steps.json. The steps are DATA (what to press and when), a draft that UI confirms
//     on the first click; a step that goes wrong is a line of the report, never a stop (the numbers are still saved).
//   * Loading times: engine start to the first picture (the window is polled), the mode list's own picture, and "settled": the second at which the frame rate first reaches 80% of its steady value (from the
//     --print-fps lines). The game itself prints no load time; these are measured from outside and are called what they are.
//   * --no-window: the program is started --headless (no picture, no keys, no stills): the numbers pipeline only, ended by --frames=<n>. Frame rates of a headless run are NOT a measure of a window's.
//   * The size: --size names a row of sizes.json. Today only "default" has arguments; small, medium and big wait for GW1c, and the report says "not offered by this build" for them.
// The report (first-run-report.md and .json in --out) names the build's version and commit, the machine's CPU and graphics card (never the PC's name or a folder), each step's result, the stills, and the numbers. It
// is cleaned of folder paths. Performance reading only, never a flash reading.
// Node built-ins, PowerShell (Windows) and the program. Nothing is uploaded.
import { spawn, spawnSync } from 'node:child_process';
import { existsSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, rmSync, statSync, writeFileSync } from 'node:fs';
import { cpus, platform, release, tmpdir, totalmem, setPriority, constants as osConstants } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { cleanPaths } from '../record-paths.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = resolve(HERE, '..', '..');

// ---------------------------------------------------------------- pure parts

/** The "Project FPS: 99 (10.10 mspf)" lines of the program's --print-fps output, in order: [{ fps, mspf }]. Pure. */
export function parseFps(text) {
  const out = [];
  for (const m of String(text).matchAll(/Project FPS: (\d+) \(([\d.]+) mspf\)/g)) out.push({ fps: Number(m[1]), mspf: Number(m[2]) });
  return out;
}

const pct = (sorted, q) => (sorted.length ? sorted[Math.min(sorted.length - 1, Math.floor(sorted.length * q))] : null);

/** The frame-rate summary of a run's seconds. `skipS` seconds at the start are the load and are left out of the steady figures. Pure.
 *  => { seconds, steadySeconds, mean, median, min, p5, max, settledAtS, over30, over60 } (null fields when there are none) */
export function fpsStats(rows, skipS = 0) {
  const fps = rows.map((r) => r.fps);
  const steady = fps.slice(skipS);
  const sorted = [...steady].sort((a, b) => a - b);
  const median = pct(sorted, 0.5);
  const mean = steady.length ? steady.reduce((a, b) => a + b, 0) / steady.length : null;
  let settledAtS = null;
  if (median !== null) for (let i = 0; i < fps.length; i++) if (fps[i] >= 0.8 * median) { settledAtS = i; break; }
  return {
    seconds: fps.length, steadySeconds: steady.length, mean: mean === null ? null : Math.round(mean * 10) / 10, median, min: sorted.length ? sorted[0] : null, p5: pct(sorted, 0.05), max: sorted.length ? sorted[sorted.length - 1] : null,
    settledAtS, over30: steady.length ? steady.filter((v) => v >= 30).length / steady.length : null, over60: steady.length ? steady.filter((v) => v >= 58).length / steady.length : null,
  };
}

/** The two load lines the program prints that carry a time: the pair bake's ms and the tick at which the incremental bake drained. Pure. */
export function parseLoad(text) {
  const bake = /pair bake: (\d+) ms, (\d+) poses/.exec(String(text));
  const drained = /drained at tick (\d+)/.exec(String(text));
  return { pairBakeMs: bake ? Number(bake[1]) : null, poses: bake ? Number(bake[2]) : null, drainedAtTick: drained ? Number(drained[1]) : null };
}

/**
 * The game's own empty settings for a run, under `base`: the only thing written is that the How to play card has been seen. Why: on a new profile that card comes up after the flashing-effects warning and holds the
 * match, so the keys of steps.json go nowhere (found 2026-11-25); and the run must not read or change the settings and saved matches of the person at the PC. The warning itself is shown every session and is
 * not touched. Returns the environment to start the program with (the game's data folder follows APPDATA on Windows and XDG_DATA_HOME on Linux).
 */
export function ownProfile(base) {
  const env = { APPDATA: join(base, 'appdata'), LOCALAPPDATA: join(base, 'localappdata'), XDG_DATA_HOME: join(base, 'xdg') };
  for (const dir of [join(env.APPDATA, 'Godot', 'app_userdata', 'Orb Combat EX'), join(env.XDG_DATA_HOME, 'godot', 'app_userdata', 'Orb Combat EX')]) {
    mkdirSync(dir, { recursive: true });
    writeFileSync(join(dir, 'ui_prefs.json'), JSON.stringify({ howto_seen: true }));
  }
  mkdirSync(env.LOCALAPPDATA, { recursive: true });
  return env;
}
/** Whether the program offers a size on its setup row: its packed data/biomes/sizes.json (text inside the program) has the row with "offered": true. `default` and `medium` are what the setup starts on. Pure. */
export function offeredByBuild(bytes, name) {
  if (name === 'default' || name === 'medium') return true;
  return new RegExp(`"${name}"\\s*:\\s*\\{[^{}]*"offered"\\s*:\\s*true`).test(Buffer.from(bytes).toString('latin1'));
}
/** The sizes to run, from sizes.json's table and the --size value: [{ name, args, waiting }]. `all` is every row; an unknown name is an error. Pure. */
export function sizesFor(table, wanted) {
  const rows = table.sizes || {};
  const names = wanted === 'all' ? Object.keys(rows) : String(wanted).split(',').map((s) => s.trim()).filter(Boolean);
  for (const n of names) if (!rows[n]) throw new Error(`--size "${n}" is not a row of sizes.json (${Object.keys(rows).join(', ')})`);
  return names.map((n) => ({ name: n, args: Array.isArray(rows[n].args) ? rows[n].args.map(String) : null, keys: Array.isArray(rows[n].keys) ? rows[n].keys.map(String) : [], waiting: rows[n].waiting || '', what: rows[n].what || '' }));
}

const KEYS = ['ENTER', 'ESC', 'SPACE', 'UP', 'DOWN', 'LEFT', 'RIGHT', 'P', 'F1', 'TAB'];
/** The problems of a steps file: the key names the window helper knows, each step has an id and a plan. Pure. */
export function stepProblems(doc) {
  const out = [];
  if (!doc || !Array.isArray(doc.steps) || !doc.steps.length) return ['steps.json has no steps'];
  const seen = new Set();
  for (const s of doc.steps) {
    if (!s.id || typeof s.id !== 'string') { out.push('a step has no id'); continue; }
    if (seen.has(s.id)) out.push(`step "${s.id}" twice`);
    seen.add(s.id);
    for (const k of s.keys || []) if (!KEYS.includes(k)) out.push(`step "${s.id}": key "${k}" is not one of ${KEYS.join(' ')}`);
    if (s.shot && !/^[\w-]+$/.test(s.shot)) out.push(`step "${s.id}": the still's name "${s.shot}" has odd characters`);
    if (s.settleMs !== undefined && !(Number(s.settleMs) >= 0)) out.push(`step "${s.id}": settleMs is not a number`);
  }
  return out;
}

/** The report's Markdown. `r` = { build, machine, runs: [{ size, waiting, steps: [{ id, what, ok, detail, still }], fps, load, loading, closed, headless, wallS }], date }. Pure. */
export function reportText(r) {
  const L = [];
  const all = r.runs.flatMap((x) => x.steps || []);
  const failed = all.filter((s) => s.ok === false).length;
  L.push(`# First run, ${r.date}`, '');
  L.push(`Build: ${r.build.version || '?'} (commit ${r.build.commit || '?'}, ${r.build.date || '?'}). Machine: ${r.machine.cpu}, ${r.machine.gpu || 'graphics card not read'}, ${r.machine.ramGb} GB, ${r.machine.os}. Window ${r.window || 'none (headless)'}.`, '');
  L.push(`**${r.runs.some((x) => x.headless) ? 'Numbers pipeline only (no window): the frame rates below are NOT a window\'s.' : failed ? `${failed} step(s) did not go as planned (below).` : 'Every step went as planned.'}** A performance reading, never a flash reading.`, '');
  L.push('The game ran with its own empty settings (only the How to play card marked as seen): your settings and saved matches were not read or changed, so the match is the fixed first one.', '');
  for (const run of r.runs) {
    L.push(`## Size: ${run.size}`, '');
    if (run.waiting) { L.push(`Not run: ${run.waiting}. Nothing was run for it.`, ''); continue; }
    if (run.steps && run.steps.length) {
      L.push('| Step | What | Result | Still |', '| :--- | :--- | :--- | :--- |');
      for (const s of run.steps) L.push(`| ${s.id} | ${s.what || ''} | ${s.ok === null ? 'skipped' : s.ok ? 'ok' : 'FAILED'}${s.detail ? ': ' + s.detail : ''} | ${s.still || ''} |`);
      L.push('');
    }
    L.push('Loading and frame rate:', '');
    const f = run.fps;
    L.push(`- Engine start to the first picture: ${run.loading && run.loading.firstPictureS != null ? run.loading.firstPictureS.toFixed(1) + ' s' : 'not measured'}`);
    L.push(`- Frame rate settled (80% of steady) after: ${f && f.settledAtS != null ? f.settledAtS + ' s' : 'not measured'}`);
    L.push(`- Frames a second over ${f ? f.steadySeconds : 0} steady seconds: ${f && f.mean != null ? `mean ${f.mean}, median ${f.median}, slowest second ${f.min}, 5th percentile ${f.p5}, fastest ${f.max}; ${(f.over30 * 100).toFixed(0)}% of seconds at 30 or more, ${(f.over60 * 100).toFixed(0)}% at 58 or more` : 'none printed'}`);
    if (run.load && run.load.pairBakeMs != null) L.push(`- The game's own load lines: pair bake ${run.load.pairBakeMs} ms (${run.load.poses} poses), incremental bake drained at tick ${run.load.drainedAtTick ?? '?'}`);
    L.push(`- The program closed: ${run.closed === null ? 'not checked' : run.closed ? 'yes, by itself' : 'NO, it had to be stopped'}; the run took ${run.wallS != null ? run.wallS.toFixed(0) + ' s' : '?'}`, '');
  }
  return cleanPaths(L.join('\n'));
}

// ---------------------------------------------------------------- the machine and the build

function machine() {
  let gpu = '';
  if (platform() === 'win32') {
    const r = spawnSync('powershell', ['-NoProfile', '-NonInteractive', '-Command', '(Get-CimInstance Win32_VideoController | ForEach-Object { $_.Name }) -join "; "'], { encoding: 'utf8' });
    gpu = String(r.stdout || '').trim();
  }
  return { cpu: (cpus()[0] || {}).model ? cpus()[0].model.trim() : 'unknown cpu', cores: cpus().length, gpu, ramGb: Math.round(totalmem() / 2 ** 30), os: `${platform() === 'win32' ? 'Windows' : platform()} ${release()}` };
}

/** The program to run: an .exe, a folder holding one, or an ORB-PRIVATE zip (unpacked into `scratch`). */
export function findBuild(arg, scratch) {
  let p = arg;
  if (!p) {
    const dir = join(REPO, 'homework', 'Files', 'desktop');
    const zips = existsSync(dir) ? readdirSync(dir).flatMap((d) => { const f = join(dir, d); return statSync(f).isDirectory() ? readdirSync(f).filter((n) => /ORB-PRIVATE-windows-x86_64-[0-9a-f]+\.zip$/.test(n)).map((n) => join(f, n)) : []; }) : [];
    zips.sort((a, b) => statSync(b).mtimeMs - statSync(a).mtimeMs);
    if (!zips.length) throw new Error('no build: pass --exe <path>, or make one with node tools/desktop-local-build.mjs (it puts a zip in homework/Files/desktop)');
    p = zips[0];
  }
  p = resolve(p);
  if (!existsSync(p)) throw new Error(`no such file or folder: ${p}`);
  if (/\.zip$/i.test(p)) {
    const to = join(scratch, 'build');
    mkdirSync(to, { recursive: true });
    const r = spawnSync('powershell', ['-NoProfile', '-NonInteractive', '-Command', `Expand-Archive -Path '${p}' -DestinationPath '${to}' -Force`], { encoding: 'utf8' });
    if (r.status !== 0) throw new Error('could not unzip ' + p);
    p = to;
  }
  if (statSync(p).isDirectory()) {
    const find = (d) => readdirSync(d).flatMap((n) => { const f = join(d, n); return statSync(f).isDirectory() ? find(f) : /orb-combat-ex\.(exe|x86_64)$/.test(n) ? [f] : []; });
    const found = find(p);
    if (!found.length) throw new Error('no orb-combat-ex program in ' + p);
    p = found[0];
  }
  return p;
}

// ---------------------------------------------------------------- running

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

function helper(action, args) {
  const r = spawnSync('powershell', ['-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', join(HERE, 'window.ps1'), '-Action', action, ...args], { encoding: 'utf8', timeout: 60000 });
  let doc = null;
  try { doc = JSON.parse(String(r.stdout).trim().split(/\r?\n/).pop()); } catch { /* not json */ }
  return doc || { ok: false, error: String(r.stderr || r.stdout || r.error || 'no answer').trim().slice(0, 160) };
}

async function runOne({ exe, size, seed, headless, frames, limitS, outDir, steps, quitCheck, profile }) {
  const run = { size: size.name, waiting: '', steps: [], fps: null, load: null, loading: {}, closed: null, headless, wallS: null };
  const args = [...(headless ? ['--headless'] : ['--resolution', '1280x720']), '--print-fps', '--', `--seed=${seed}`, ...(headless ? [`--frames=${frames}`] : []), ...size.args];
  const t0 = Date.now();
  const child = spawn(exe, args, { cwd: dirname(exe), env: { ...process.env, ...ownProfile(profile) }, stdio: ['ignore', 'pipe', 'pipe'], windowsHide: false });
  try { setPriority(child.pid, osConstants.priority.PRIORITY_BELOW_NORMAL); } catch { /* gone */ }
  let log = '', exited = false, exitedAt = null;
  const keep = (d) => { log += d; if (log.length > 4e6) log = log.slice(-2e6); };
  child.stdout.on('data', keep); child.stderr.on('data', keep);
  child.on('close', () => { exited = true; exitedAt = Date.now(); });
  const killTimer = setTimeout(() => { if (!exited) { try { if (platform() === 'win32') spawn('taskkill', ['/PID', String(child.pid), '/T', '/F'], { windowsHide: true }); else child.kill('SIGKILL'); } catch { /* gone */ } } }, limitS * 1000);
  const add = (s) => { run.steps.push(s); console.log(`${s.ok === null ? 'skip' : s.ok ? 'ok  ' : 'FAIL'} ${s.id}${s.detail ? ': ' + s.detail : ''}`); };
  try {
    if (headless) {
      for (const s of steps) add({ id: s.id, what: s.what, ok: null, detail: 'no window (--no-window)' });
      while (!exited && Date.now() - t0 < limitS * 1000) await sleep(500);
    } else {
      // the first picture: poll the window until it shows something other than a blank
      let first = null, prev = null;
      for (let i = 0; i < 240 && !exited; i++) {
        const shot = join(outDir, '_probe.png');
        const c = helper('capture', ['-ProcessId', String(child.pid), '-Out', shot]);
        if (c.ok && c.colours >= 12) { first = (Date.now() - t0) / 1000; prev = c.signature; break; }
        await sleep(250);
      }
      run.loading.firstPictureS = first;
      add({ id: 'first-picture', what: 'the game opens a window with a picture', ok: first !== null, detail: first !== null ? `after ${first.toFixed(1)} s` : 'no picture in 60 s' });
      for (const s of steps) {
        if (exited) { add({ id: s.id, what: s.what, ok: false, detail: 'the program had already ended' }); continue; }
        let detail = '';
        if (s.human) {
          console.log(`\n>>> ${s.human}\n`);
          // first wait for the picture to hold still (a splash or a fade gives way to the warning), then for a change: the change is a person's key
          let same = 0;
          for (let i = 0; i < 80 && same < 3 && !exited; i++) {
            const c = helper('capture', ['-ProcessId', String(child.pid), '-Out', join(outDir, '_probe.png')]);
            if (c.ok && c.signature === prev) same++; else { same = 0; if (c.ok) prev = c.signature; }
            await sleep(750);
          }
          const until = Date.now() + (s.humanLimitS || 300) * 1000;
          let changed = false;
          while (Date.now() < until && !exited) {
            const c = helper('capture', ['-ProcessId', String(child.pid), '-Out', join(outDir, '_probe.png')]);
            if (c.ok && prev && c.signature !== prev) { changed = true; break; }
            await sleep(750);
          }
          detail = changed ? 'the picture changed' : 'nobody acted in time';
          if (!changed) { add({ id: s.id, what: s.what, ok: false, detail }); continue; }
        }
        // the planet size is picked before Start, with the setup's own row (sizes.json)
        if (s.id === 'match-start' && (size.keys || []).length) { const k = helper('keys', ['-ProcessId', String(child.pid), '-Keys', size.keys.join(',')]); if (!k.ok) detail = 'size keys: ' + (k.error || 'failed'); await sleep(1200); const f = join(outDir, `03b-size-${size.name}.png`); helper('capture', ['-ProcessId', String(child.pid), '-Out', f]); }
        if ((s.keys || []).length) { const k = helper('keys', ['-ProcessId', String(child.pid), '-Keys', s.keys.join(',')]); if (!k.ok) detail = (detail ? detail + '; ' : '') + 'keys: ' + (k.error || 'failed'); }
        await sleep(Number(s.settleMs ?? 1500));
        let still = '', ok = true;
        if (s.shot) {
          const file = join(outDir, `${s.shot}.png`);
          const c = helper('capture', ['-ProcessId', String(child.pid), '-Out', file, ...(s.crop ? ['-Crop', s.crop.join(',')] : [])]);
          ok = !!c.ok && c.colours >= 12;
          still = c.ok ? `${s.shot}.png` : '';
          if (!c.ok) detail = (detail ? detail + '; ' : '') + (c.error || 'no still');
          else if (c.colours < 12) detail = (detail ? detail + '; ' : '') + `the still is nearly one colour (${c.colours})`;
          if (c.ok) prev = c.signature;
          if (s.alsoCrop && c.ok) { const c2 = helper('capture', ['-ProcessId', String(child.pid), '-Out', join(outDir, `${s.alsoCrop.shot}.png`), '-Crop', s.alsoCrop.crop.join(',')]); if (c2.ok) still += `, ${s.alsoCrop.shot}.png`; }
        }
        add({ id: s.id, what: s.what, ok, detail, still });
        if (s.holdS) await sleep(s.holdS * 1000);
      }
      if (quitCheck && !exited) {
        const t1 = Date.now();
        for (let i = 0; i < 30 && !exited; i++) await sleep(250);
        run.closed = exited;
        add({ id: 'program-closes', what: 'the program closes by itself within 7 s of "Close the game"', ok: exited, detail: exited ? `${((exitedAt - t1) / 1000).toFixed(1)} s after the last key` : 'still running; stopped by the script' });
      }
    }
  } finally {
    clearTimeout(killTimer);
    if (!exited) { try { if (platform() === 'win32') spawn('taskkill', ['/PID', String(child.pid), '/T', '/F'], { windowsHide: true }); else child.kill('SIGKILL'); } catch { /* gone */ } }
  }
  if (run.closed === null && headless) run.closed = exited;
  run.wallS = (Date.now() - t0) / 1000;
  const rows = parseFps(log);
  run.fps = fpsStats(rows, 3);
  run.load = parseLoad(log);
  if (!headless || rows.length) { /* the program's own lines are the only source of the numbers */ }
  writeFileSync(join(outDir, `program-output-${size.name}.txt`), cleanPaths(log.split(/\r?\n/).filter((l) => /FPS|bake|hash|ERROR|WARNING|SCRIPT/.test(l)).slice(0, 400).join('\n')) + '\n');
  return run;
}

async function main() {
  const a = process.argv.slice(2);
  const opt = (n, d) => { const i = a.indexOf(n); return i >= 0 && i + 1 < a.length ? a[i + 1] : d; };
  const headless = a.includes('--no-window');
  if (platform() !== 'win32' && !headless) { console.error('first-run: the window half is Windows only for now (use --no-window for the numbers pipeline)'); process.exit(2); }
  const scratch = mkdtempSync(join(tmpdir(), 'first-run-'));
  let code = 0;
  try {
    const exe = findBuild(opt('--exe'), scratch);
    const sizes = sizesFor(JSON.parse(readFileSync(join(HERE, 'sizes.json'), 'utf8')), opt('--size', 'default'));
    const stepsDoc = JSON.parse(readFileSync(join(HERE, 'steps.json'), 'utf8'));
    const bad = stepProblems(stepsDoc);
    if (bad.length) { console.error('first-run: steps.json: ' + bad.join('; ')); process.exit(2); }
    const stamp = new Date().toISOString().replace(/[:T]/g, '-').slice(0, 16);
    const outDir = resolve(opt('--out', join(REPO, 'homework', 'Files', 'first-run', `first-run-${stamp}`)));
    mkdirSync(outDir, { recursive: true });
    let build = { version: '', commit: '', date: '' };
    try { const bi = JSON.parse(readFileSync(join(dirname(exe), 'build_info.json'), 'utf8')); build = { version: bi.version || '', commit: bi.commit || '', date: bi.date || '' }; } catch { /* no build_info beside the program */ }
    console.log(`first-run: ${headless ? 'no window (numbers pipeline only)' : 'with a window'}; sizes ${sizes.map((s) => s.name).join(', ')}; out ${outDir}`);
    const runs = [];
    for (const size of sizes) {
      if (!size.args) { runs.push({ size: size.name, waiting: size.waiting || 'its arguments are not set in sizes.json', steps: [] }); continue; }
      if (headless && size.keys.length) { runs.push({ size: size.name, waiting: 'a size is picked on the menu: it needs a window (without one the run would play medium)', steps: [] }); continue; }
      if (!offeredByBuild(readFileSync(exe), size.name)) { runs.push({ size: size.name, waiting: 'this program does not offer it', steps: [] }); continue; }
      runs.push(await runOne({ exe, size, profile: join(scratch, 'profile-' + size.name), seed: Number(opt('--seed', 4)), headless, frames: Number(opt('--frames', 1800)), limitS: Number(opt('--limit', 600)), outDir, steps: stepsDoc.steps, quitCheck: !a.includes('--no-quit-check') }));
    }
    const r = { date: new Date().toISOString().slice(0, 10), build, machine: machine(), window: headless ? null : '1280x720', runs };
    for (const f of readdirSync(outDir)) if (f === '_probe.png') rmSync(join(outDir, f), { force: true });
    writeFileSync(join(outDir, 'first-run-report.md'), reportText(r) + '\n');
    writeFileSync(join(outDir, 'first-run-report.json'), cleanPaths(JSON.stringify(r, null, 2)) + '\n');
    const failed = runs.flatMap((x) => x.steps).filter((s) => s.ok === false).length;
    console.log(`\nfirst-run: report saved: ${join(outDir, 'first-run-report.md')} (${failed} step(s) failed)`);
    code = failed ? 1 : 0;
  } catch (e) { console.error(`first-run: ${e.message}`); code = 2; }
  finally { try { rmSync(scratch, { recursive: true, force: true }); } catch { /* left */ } }
  process.exit(code);
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) main();
