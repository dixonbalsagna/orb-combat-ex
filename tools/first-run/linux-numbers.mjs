// The numbers half of the first run on Linux, for CI (Tools, 2026-11-23; path to Alpha 1, job 8's Linux half; Legal RL-270). Run by .github/workflows/linux-first-run.yml (dispatch only) on a GitHub runner's VIRTUAL display
// with nobody watching:
//   node tools/first-run/linux-numbers.mjs --exe <orb-combat-ex.x86_64> [--seed 4] [--limit 400] [--out <report.md>]
// It starts the LOCKED Linux program (warning and all, no bypass word, no switch of any kind added to the build), presses the warning's Return with xdotool (the first step of steps.json, which on a person's PC a
// person presses), then the rest of steps.json's keys, reads the program's own --print-fps lines and bake lines, and checks the program closes by itself within 7 s of "Close the game". It takes NO still, NO video, NO
// capture of the display (RL-270 condition 3); the report is text and numbers only. A performance reading, never a flash reading, never counted toward G4, G21 or a flash number (condition 4).
// Refuses to run unless GITHUB_ACTIONS is "true" and a virtual display is named (condition 2: it will not press a key on a person's screen). Node built-ins; xdotool on the runner.
import { spawn, spawnSync } from 'node:child_process';
import { existsSync, readdirSync, readFileSync, statSync, writeFileSync } from 'node:fs';
import { cpus, homedir, totalmem, release } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { fpsStats, parseFps, parseLoad, reportText, stepProblems } from './first-run.mjs';
import { cleanPaths } from '../record-paths.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const XKEY = { ALT_F4: 'alt+F4', ENTER: 'Return', ESC: 'Escape', SPACE: 'space', UP: 'Up', DOWN: 'Down', LEFT: 'Left', RIGHT: 'Right', P: 'p', F1: 'F1', TAB: 'Tab' };

/** The xdotool key names for steps.json's key names. Pure. */
export const xdotoolKeys = (keys) => keys.map((k) => { if (!XKEY[k]) throw new Error(`no xdotool name for key ${k}`); return XKEY[k]; });

/** Whether this run may press keys: only on a CI runner, on a virtual display. Pure. => '' when it may, else the reason. */
export function refusal(env) {
  if (env.GITHUB_ACTIONS !== 'true') return 'not a CI runner (GITHUB_ACTIONS is not "true"): this script never presses a key on a person\'s screen';
  if (!/^:\d+/.test(String(env.DISPLAY || ''))) return 'no X display named in DISPLAY';
  if (env.FIRST_RUN_VIRTUAL_DISPLAY !== '1') return 'FIRST_RUN_VIRTUAL_DISPLAY is not 1 (the workflow sets it when it has started Xvfb itself)';
  return '';
}

/** The frame rate in buckets of `n` seconds: [{ from, to, mean }] (the shape of the load and the play, for a run whose picture nobody sees). Pure. */
export function timeline(rows, n = 10) {
  const out = [];
  for (let i = 0; i < rows.length; i += n) { const c = rows.slice(i, i + n); out.push({ from: i, to: i + c.length, mean: Math.round((c.reduce((a, r) => a + r.fps, 0) / c.length) * 10) / 10 }); }
  return out;
}

/** The lines of the program's output that are not the frame-rate line, with folder paths taken out, at most `max`. Pure. */
export function ownLines(log, max = 40) {
  return String(log).split(/\r?\n/).filter((l) => l.trim() && !/Project FPS:/.test(l)).slice(0, max).map((l) => cleanPaths(l).slice(0, 200));
}

/** The game's data folder after the run: [{ path, size }] of every file under app_userdata (names and sizes only, never contents), at most `max`. A match's field cache and a saved report only appear once a match was built. */
export function dataFiles(root, max = 60) {
  const out = [];
  const walk = (d) => { for (const n of readdirSync(d).sort()) { const f = join(d, n); const st = statSync(f); if (st.isDirectory()) { if (n !== 'shader_cache') walk(f); } else if (out.length < max) out.push({ path: f.slice(root.length + 1).split(String.fromCharCode(92)).join('/'), size: st.size }); } };
  if (existsSync(root)) walk(root);
  return out;
}

/** Whether the data folder says a match was built: a field-cache file or a report file exists. Pure. */
export const matchInData = (files) => files.some((f) => f.path.split('/').some((part) => part === 'field-cache' || part === 'reports') && f.path.split('/').length > 1);

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const press = (keys, delay = 250) => { const r = spawnSync('xdotool', ['key', '--delay', String(delay), ...xdotoolKeys(keys)], { encoding: 'utf8' }); return r.status === 0 ? '' : String(r.stderr || r.error).trim().slice(0, 120); };

async function main() {
  const a = process.argv.slice(2);
  const opt = (n, d) => { const i = a.indexOf(n); return i >= 0 && i + 1 < a.length ? a[i + 1] : d; };
  const why = refusal(process.env);
  if (why) { console.error('linux-numbers: refused: ' + why); process.exit(2); }
  const exe = resolve(opt('--exe', ''));
  const steps = JSON.parse(readFileSync(join(HERE, 'steps.json'), 'utf8'));
  const bad = stepProblems(steps);
  if (bad.length) { console.error('linux-numbers: steps.json: ' + bad.join('; ')); process.exit(2); }
  spawnSync('xdotool', ['mousemove', '640', '360']);   // no window manager under Xvfb: the key goes to the window under the pointer
  // software GL on a runner draws about 14 frames a second, a fifth of what steps.json was written for: every wait and the gap between keys is stretched by --slow (default 3)
  const slow = Math.max(1, Number(opt('--slow', 3)));
  const t0 = Date.now();
  const at = () => `${((Date.now() - t0) / 1000).toFixed(0)} s`;
  const child = spawn(exe, ['--rendering-driver', 'opengl3', '--audio-driver', 'Dummy', '--resolution', '1280x720', '--print-fps', '--', `--seed=${opt('--seed', 4)}`], { cwd: dirname(exe), stdio: ['ignore', 'pipe', 'pipe'] });
  let log = '', exited = false, exitedAt = 0;
  child.stdout.on('data', (d) => { log += d; }); child.stderr.on('data', (d) => { log += d; });
  child.on('close', () => { exited = true; exitedAt = Date.now(); });
  const killer = setTimeout(() => { if (!exited) child.kill('SIGKILL'); }, Number(opt('--limit', 1000)) * 1000);
  const run = { size: 'default', steps: [], fps: null, load: null, loading: {}, closed: null, headless: false, wallS: null };
  const add = (s) => { run.steps.push(s); console.log(`${s.ok ? 'ok  ' : 'FAIL'} ${s.id}${s.detail ? ': ' + s.detail : ''}`); };
  // the first picture: the program prints its first frame-rate line once it is drawing
  for (let i = 0; i < 600 && !exited && parseFps(log).length < 1; i++) await sleep(500);   // up to 300 s: software GL boots slowly (the first run took over 2 minutes)
  const first = parseFps(log).length ? (Date.now() - t0) / 1000 : null;
  run.loading.firstPictureS = first;
  add({ id: 'first-picture', what: 'the program draws (its first frame-rate line)', ok: first !== null, detail: first !== null ? `after ${first.toFixed(1)} s` : 'no frame-rate line in 300 s' });
  for (let i = 0; i < 40 && !exited && parseFps(log).length < 4; i++) await sleep(500);   // the warning is up and drawing for a few seconds before the first key
  await sleep(4000 * slow);
  // no window manager under Xvfb: nobody gives the game's window the keyboard focus, and the game may ignore keys it did not get focus for (the second run: every key sent, no match ever built). So the window is
  // found by its name and focused with xdotool (XSetInputFocus: no window manager needed), before the keys and again before each step's.
  const focus = () => {
    const f = spawnSync('xdotool', ['search', '--onlyvisible', '--name', 'Orb Combat'], { encoding: 'utf8' });
    const id = String(f.stdout || '').trim().split(/\s+/).filter(Boolean)[0];
    if (!id) { const any = spawnSync('xdotool', ['search', '--onlyvisible', '--name', ''], { encoding: 'utf8' }); return { ok: false, detail: `no window named Orb Combat (${String(any.stdout || '').trim().split(/\s+/).filter(Boolean).length} visible windows)` }; }
    const w = spawnSync('xdotool', ['windowfocus', id], { encoding: 'utf8' });
    return { ok: w.status === 0, detail: w.status === 0 ? `window ${id} focused` : String(w.stderr).trim().slice(0, 100) };
  };
  const f0 = focus();
  add({ id: 'window-focus', what: 'the game\'s window is found and given the keyboard focus', ok: f0.ok, detail: `at ${at()}: ${f0.detail}` });
  for (const s of steps.steps) {
    if (exited) { add({ id: s.id, what: s.what, ok: false, detail: 'the program had already ended' }); continue; }
    // the warning's step: on this unwatched virtual display the workflow presses Return (RL-270); on a person's PC a person does
    const keys = s.human ? ['ENTER'] : (s.keys || []);
    if (keys.length) focus();
    const err = keys.length ? press(keys, 250 * slow) : '';
    await sleep(Number(s.settleMs ?? 1500) * slow);
    add({ id: s.id, what: s.what, ok: !err, detail: `at ${at()}${err ? ': ' + err : s.human ? ': Return pressed by the workflow on the virtual display' : keys.length ? `: ${keys.length} key(s)` : ''}` });
  }
  // the match was built: the program prints its pair-bake line when a match's pieces are made (the first run's keys may have met a game that never left the warning)
  const dataRoot = join(process.env.XDG_DATA_HOME || join(homedir(), '.local', 'share'), 'godot', 'app_userdata');
  const files = dataFiles(dataRoot);
  const logFile = files.find((f) => /logs[/]godot[.]log$/.test(f.path));
  const gameLog = logFile ? readFileSync(join(dataRoot, logFile.path), 'utf8').split(/\r?\n/).filter((l) => l.trim() && !/Project FPS:/.test(l)).slice(-80).map((l) => cleanPaths(l).slice(0, 220)) : ['(no godot.log in the data folder)'];
  const built = parseLoad(log).pairBakeMs !== null || matchInData(files);
  add({ id: 'match-built', what: 'a match was built after the keys (the program printed its pair-bake line, or its data folder holds a field cache or a report)', ok: built, detail: built ? `at ${at()}` : 'no pair-bake line and no field cache or report in the data folder: the keys did not get the game past its first screens' });
  const t1 = Date.now();
  for (let i = 0; i < 40 && !exited; i++) await sleep(250);
  run.closed = exited;
  add({ id: 'program-closes', what: 'the program closes by itself within 7 s of "Close the game"', ok: exited, detail: exited ? `${((exitedAt - t1) / 1000).toFixed(1)} s after the last key` : 'still running; stopped by the script' });
  // the keys did not close it: ask the window manager to close the window (Alt+F4, what the close button does), to tell "the keys did not get through" from "the game cannot close"
  if (!exited) {
    const wf = spawnSync('xdotool', ['getwindowfocus', 'getwindowname'], { encoding: 'utf8' });
    focus();
    press(['ALT_F4'], 250);
    for (let i = 0; i < 80 && !exited; i++) await sleep(250);
    add({ id: 'window-close-fallback', what: 'the window is closed the way its close button does (Alt+F4), after the keys failed', ok: exited, detail: `focused window before: "${String(wf.stdout || '').trim().slice(0, 60)}"; ` + (exited ? 'the game closed: it can close, so the pause, Quit and Close the game keys did not reach it' : 'the game did not close either') });
  }
  clearTimeout(killer);
  if (!exited) child.kill('SIGKILL');
  run.wallS = (Date.now() - t0) / 1000;
  run.fps = fpsStats(parseFps(log), 3);
  run.load = parseLoad(log);
  const build = { version: '', commit: '', date: '' };
  try { const bi = JSON.parse(readFileSync(join(dirname(exe), 'build_info.json'), 'utf8')); Object.assign(build, bi); } catch { /* none beside the program */ }
  const text = reportText({ date: new Date().toISOString().slice(0, 10), build, machine: { cpu: (cpus()[0] || {}).model || 'unknown cpu', gpu: 'virtual display, software GL (Mesa)', ramGb: Math.round(totalmem() / 2 ** 30), os: `Linux ${release()}` }, window: '1280x720 (Xvfb)', runs: [run] });
  const rows = parseFps(log);
  const shape = ['', 'Frames a second by ten-second stretch (from the start): ' + timeline(rows).map((b) => `${b.from}-${b.to} s: ${b.mean}`).join(', '), '', "The program's own other lines (folder paths taken out):", '```', ...ownLines(log), '```', '', "The game's data folder after the run (names and sizes, never contents):", '```', ...files.map((f) => `${f.size} ${f.path}`), '```', '', "The game's own log, its last 80 lines without the frame-rate lines (folder paths taken out; text only):", '```', ...gameLog, '```'].join('\n');
  const note = shape + '\n_A GitHub runner, a virtual display, no one watching, software GL: a performance reading only, never a flash reading (Legal RL-270). No still, video or capture was taken._\n';
  if (opt('--out')) writeFileSync(resolve(opt('--out')), cleanPaths(text + note) + '\n');
  console.log(cleanPaths(text + note));
  process.exit(run.steps.some((s) => !s.ok) ? 1 : 0);
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) main();
