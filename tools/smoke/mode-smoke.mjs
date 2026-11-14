// The mode smoke's runner (A-MODES-08; Tools, 2026-11-14): runs tools/smoke/mode_smoke.gd, headless, once per mode, with the game's data folder pointed at a scratch one (the game saves its menu
// choices as it is played; a smoke must never touch Orb's own), and writes one result file per mode and platform.
//   node tools/smoke/mode-smoke.mjs [--godot <exe>] [--mode solo|two|both] [--path <project dir>] [--out <dir>] [--cap <ticks>] [--limit <seconds>]
//   --godot: default the GODOT environment variable. --path: default the repository. --out: default docs/tools/runs/<commit8>/ (one file: mode-smoke-<mode>-<platform>.json).
//   Exit 0 when every step of every mode passed; 1 when a step failed; 2 when the game did not start or wrote no result (a run that reads nothing is not a pass).
//   Under a Godot run the game can leave a Godot process behind if it hangs: the run is stopped by its own PID after --limit seconds (default 240).
// A row that a build does not have (the start menu's "quit" today) counts as ok with the detail "not built": the result file says so, and docs/tools/mode-smoke.md lists what is not built.
import { spawn, execFileSync } from 'node:child_process';
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
const ROOT = resolve(HERE, '..', '..');

/** Reads a smoke's result document and says what it holds. Pure. => { ok, failed: [names], notBuilt: [names], problems: [text] } */
export function readResult(doc, mode) {
  const problems = [];
  if (!doc || typeof doc !== 'object') return { ok: false, failed: [], notBuilt: [], problems: ['no result document'] };
  if (doc.mode !== mode) problems.push(`the result is of mode "${doc.mode}", not "${mode}"`);
  const steps = Array.isArray(doc.steps) ? doc.steps : [];
  if (!steps.length) problems.push('the result has no steps');
  const failed = steps.filter((s) => !s.ok).map((s) => s.name);
  const notBuilt = steps.filter((s) => s.ok && s.detail === 'not built').map((s) => s.name);
  // a smoke that stopped early (the last step is not the way back to the menu / the quit row) did not get through
  const names = steps.map((s) => String(s.name));
  if (steps.length && !names.some((n) => /quit/.test(n))) problems.push('the run stopped before its last step (the start menu\'s quit row was never looked for)');
  return { ok: !problems.length && !failed.length && doc.pass === true, failed, notBuilt, problems };
}

/** The isolated environment for one run: the data folder of the game on each platform pointed into `dir`. Pure. */
export function isolatedEnv(base, dir) {
  return { ...base, APPDATA: join(dir, 'appdata'), LOCALAPPDATA: join(dir, 'localappdata'), XDG_DATA_HOME: join(dir, 'xdg'), HOME: join(dir, 'home') };
}

function opt(argv, name, dflt = null) { const i = argv.indexOf(name); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : dflt; }

function runOne({ godot, path, mode, cap, limitS, scratch }) {
  return new Promise((done) => {
    const out = join(scratch, `${mode}.json`);
    const dir = join(scratch, mode);
    mkdirSync(dir, { recursive: true });
    const args = ['--headless', '--fixed-fps', '60', '--path', path, '--script', 'res://tools/smoke/mode_smoke.gd', '--', `--mode=${mode}`, `--out=${out}`];
    if (cap) args.push(`--cap=${cap}`);
    const child = spawn(godot, args, { env: isolatedEnv(process.env, dir), stdio: ['ignore', 'pipe', 'pipe'], windowsHide: true });
    let log = '';
    child.stdout.on('data', (d) => { log += d; });
    child.stderr.on('data', (d) => { log += d; });
    let timedOut = false;
    const timer = setTimeout(() => { timedOut = true; try { child.kill(); } catch { /* gone */ } }, limitS * 1000);
    child.on('error', (e) => { clearTimeout(timer); done({ mode, doc: null, log: String(e), timedOut }); });
    child.on('close', () => {
      clearTimeout(timer);
      let doc = null;
      try { doc = JSON.parse(readFileSync(out, 'utf8')); } catch { /* no result */ }
      done({ mode, doc, log, timedOut });
    });
  });
}

async function main() {
  const argv = process.argv.slice(2);
  const godot = opt(argv, '--godot', process.env.GODOT || '');
  if (!godot) { console.error('mode-smoke: no Godot (--godot <exe> or the GODOT variable)'); process.exit(2); }
  const path = resolve(opt(argv, '--path', ROOT));
  const modeArg = opt(argv, '--mode', 'both');
  const modes = modeArg === 'both' ? ['solo', 'two'] : [modeArg];
  if (modes.some((m) => m !== 'solo' && m !== 'two')) { console.error('mode-smoke: --mode is solo, two or both'); process.exit(2); }
  let commit = 'unknown';
  try { commit = execFileSync('git', ['-C', path, 'rev-parse', '--short=8', 'HEAD'], { encoding: 'utf8' }).trim(); } catch { /* an export has no git */ }
  const outDir = resolve(opt(argv, '--out', join(ROOT, 'docs', 'tools', 'runs', commit)));
  const platform = process.platform === 'win32' ? 'windows' : process.platform === 'darwin' ? 'macos' : 'linux';
  const scratch = mkdtempSync(join(tmpdir(), 'mode-smoke-'));
  let code = 0;
  try {
    mkdirSync(outDir, { recursive: true });
    for (const mode of modes) {
      const r = await runOne({ godot, path, mode, cap: opt(argv, '--cap', null), limitS: Number(opt(argv, '--limit', 240)), scratch });
      const read = readResult(r.doc, mode);
      const tail = r.log.split(/\r?\n/).filter((l) => /^(ok|FAIL|mode_smoke)/.test(l)).join('\n');
      console.log(tail || r.log.split(/\r?\n/).slice(-12).join('\n'));
      if (!r.doc) { code = Math.max(code, 2); console.error(`mode-smoke: ${mode}: no result file${r.timedOut ? ' (stopped at the time limit)' : ''}`); continue; }
      if (!read.ok) code = Math.max(code, 1);
      const record = { ...r.doc, platform, commit, checked: read.ok ? 'pass' : 'fail', problems: read.problems, notBuilt: read.notBuilt };
      writeFileSync(join(outDir, `mode-smoke-${mode}-${platform}.json`), JSON.stringify(record, null, 2) + '\n');
      console.log(`mode-smoke: ${mode} on ${platform}: ${read.ok ? 'PASS' : 'FAIL'}${read.failed.length ? ' (failed: ' + read.failed.join('; ') + ')' : ''}${read.problems.length ? ' (' + read.problems.join('; ') + ')' : ''}`);
    }
  } finally {
    try { rmSync(scratch, { recursive: true, force: true }); } catch { /* left for the OS */ }
  }
  process.exit(code);
}

if (import.meta.url === pathToFileURL(process.argv[1] || '').href) main();
