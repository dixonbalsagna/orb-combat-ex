// A trial web export (Tools, 2026-11-28; docs/tools/clips.md, "Trial clips"): the committed tree, plus named parks that are not landed yet, plus named trial switches on, exported for the web in a SCRATCH
// folder with the clip scenes in its capture hook. The repository is only read. Never published: a build for Tools' own captures.
//
//   node tools/clips/trial-web.mjs --out <scratch folder> [--switches grab_charge,beam_trial] [--park docs/director/pending/grab-charge --park ...] [--rev HEAD] [--godot <exe>]
//
// Order: git archive of --rev; each --park's patches in the order given (its *.diff first, then its *.patch by name); the switches (tools/trial-switches.json AS IT IS IN THAT TREE, so a park may bring its own row);
// the clip scene driver and the hook lines; import and Web export with the standard template, every folder the engine writes to inside <out>/userdata. Output: <out>/web, <out>/tree (kept: the headless probe runs
// on it), <out>/trial.json (commit, parks with their sha1s, switches, keys flipped).
import { spawn } from 'node:child_process';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { copyFileSync, existsSync, mkdirSync, openSync, closeSync, readFileSync, readdirSync, writeFileSync } from 'node:fs';
import { setPriority, constants as osConstants } from 'node:os';
import { join, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { exportRevision } from '../flash/head-export.mjs';
import { linkTemplates, userdataEnv } from '../lib/userdata.mjs';
import { applyRows, choose, loadList, LIST_FILE } from '../trial-switches.mjs';

const REPO = resolve(fileURLToPath(new URL('../..', import.meta.url)));
export const HOOK_FILE = 'render/tools/flash_capture.gd';
export const DRIVER_IN_BUILD = 'render/tools/clip_driver.gd';   // tools/ is not exported to the web: the driver rides beside the hook, in the scratch tree only

/** The lines the capture hook gets in a scratch tree: the scene "script", driven by the script the page holds in window.__clipScript. Every anchor must be there exactly once. Pure. */
export function patchClipHook(text) {
  const crlf = text.includes('\r\n');
  let h = text.replace(/\r\n/g, '\n');
  const once = (from, to, what) => {
    if (h.split(from).length !== 2) throw new Error(`the capture hook changed near ${what}: "${from.split('\n')[0].slice(0, 60)}"`);
    h = h.replace(from, () => to);
  };
  once('const FILM_SCENES: Dictionary = {', 'const ClipDriver = preload("res://render/tools/clip_driver.gd")\nvar _clip = null\nconst FILM_SCENES: Dictionary = {"script": [false, false], ', 'the film scenes');
  once('func drive(sc: String, t: int, S: SimState) -> void:\n', 'func drive(sc: String, t: int, S: SimState) -> void:\n\tif sc == "script":\n\t\t_clip.drive(main, t)\n\t\treturn\n', 'drive()');
  once('\tvar su: Dictionary = _film_setup()\n', '\tvar su: Dictionary = _film_setup()\n\t_clip = null\n\tif sc == "script":\n\t\t_clip = ClipDriver.new()\n\t\t_clip.load_text(str(JavaScriptBridge.eval("window.__clipScript || \'\'", true)))\n\t\tsu.merge(_clip.setup(), true)\n\t\tai = _clip.computer_slots()\n\t\tai_set = {"p1": ai[0], "p2": ai[1]}\n', 'the film setup');
  once('func _on_drained(events: Array, _lines) -> void:\n', 'func _on_drained(events: Array, _lines) -> void:\n\tif _clip != null:\n\t\t_clip.seen(events, main.host.ticks)\n', 'the event log');
  return crlf ? h.replace(/\n/g, '\r\n') : h;
}

/** A park's patches in apply order: *.diff first, then *.patch, each by name. */
export function parkPatches(dir) {
  const names = readdirSync(dir).sort();
  return [...names.filter((n) => n.endsWith('.diff')), ...names.filter((n) => n.endsWith('.patch'))].map((n) => join(dir, n));
}

export function godotExe(given) {
  const local = process.env.LOCALAPPDATA ? join(process.env.LOCALAPPDATA, 'Programs', 'Godot', '4.7.2', 'Godot_v4.7.2-stable_win64_console.exe') : '';
  const found = [given, process.env.ORB_GODOT_EXE, process.env.GODOT, local].find((p) => p && !/godot-run\.sh$/i.test(p) && existsSync(p));
  if (!found) throw new Error('no Godot executable: pass --godot <exe> or set GODOT (the 4.7.2 console build, with the Web export templates)');
  return found;
}

/** One engine run at below-normal priority, its folders inside the scratch data folder, output to a file. Resolves the exit code. */
export function engine(godot, args, userdata, logFile, limitMs = 25 * 60 * 1000) {
  return new Promise((ok) => {
    const fd = openSync(logFile, 'w');
    const child = spawn(godot, ['--headless', ...args], { stdio: ['ignore', fd, fd], windowsHide: true, env: userdataEnv(userdata) });
    try { setPriority(child.pid, osConstants.priority.PRIORITY_BELOW_NORMAL); } catch { /* already gone */ }
    const timer = setTimeout(() => { try { child.kill(); } catch { /* gone */ } }, limitMs);
    child.on('error', () => { clearTimeout(timer); closeSync(fd); ok(-1); });
    child.on('close', (code) => { clearTimeout(timer); closeSync(fd); ok(code === null ? -2 : code); });
  });
}

const errorsIn = (file) => readFileSync(file, 'utf8').split(/\r?\n/).filter((l) => /SCRIPT ERROR|Parse Error|Compile Error/.test(l)).slice(0, 8);

export async function buildTrial({ out, rev = 'HEAD', parks = [], switches = [], godot, repo = REPO, log = () => {} }) {
  const dir = resolve(out), tree = join(dir, 'tree'), web = join(dir, 'web'), userdata = join(dir, 'userdata');
  if (existsSync(tree)) throw new Error(`${tree} is there already: give a new --out folder`);
  mkdirSync(web, { recursive: true });
  const sha = spawnSync('git', ['rev-parse', '--verify', `${rev}^{commit}`], { cwd: repo, encoding: 'utf8' }).stdout.trim();
  if (!sha) throw new Error(`no commit "${rev}"`);
  const ex = exportRevision(repo, tree, sha);
  if (!ex.ok) throw new Error(ex.message);
  const record = { commit: sha, parks: [], switches, flips: [] };
  for (const p of parks) {
    const abs = resolve(repo, p);
    if (!existsSync(abs)) throw new Error(`--park ${p}: not there (landed already? then leave it out)`);
    for (const f of parkPatches(abs)) {
      const r = spawnSync('git', ['apply', '--ignore-whitespace', '--whitespace=nowarn', f], { cwd: tree, encoding: 'utf8' });
      if (r.status !== 0) throw new Error(`${f.slice(repo.length + 1)} does not apply on ${sha.slice(0, 8)}: ${String(r.stderr || r.error).trim().split('\n')[0]}`);
      record.parks.push({ file: f.slice(resolve(repo).length + 1).replace(/\\/g, '/'), sha1: createHash('sha1').update(readFileSync(f)).digest('hex') });
      log(`applied ${record.parks.at(-1).file}`);
    }
  }
  if (switches.length) {
    const list = loadList(readFileSync(join(tree, ...LIST_FILE.split('/')), 'utf8'));
    if (list.problems.length) throw new Error(list.problems.join('; '));
    record.flips = applyRows(tree, choose(list.rows, switches.join(',')));
    for (const l of record.flips) log(l);
  }
  copyFileSync(join(repo, 'tools', 'clips', 'script_driver.gd'), join(tree, ...DRIVER_IN_BUILD.split('/')));
  mkdirSync(join(tree, 'tools', 'clips'), { recursive: true });
  for (const f of ['script_driver.gd', 'script_probe.gd']) copyFileSync(join(repo, 'tools', 'clips', f), join(tree, 'tools', 'clips', f));
  const hook = join(tree, ...HOOK_FILE.split('/'));
  writeFileSync(hook, patchClipHook(readFileSync(hook, 'utf8')));
  writeFileSync(join(tree, 'build_info.json'), `${JSON.stringify({ commit: sha.slice(0, 7), trial: switches })}\n`);
  const exe = godotExe(godot);
  if (linkTemplates(userdata) === null) throw new Error('no export templates installed (Godot 4.7.2: Editor, Manage Export Templates)');
  log('importing (Godot, below-normal priority)');
  const importLog = join(dir, 'import.log'), exportLog = join(dir, 'export.log');
  let code = await engine(exe, ['--path', tree, '--import'], userdata, importLog);
  if (code !== 0) throw new Error(`the import exited ${code}: see ${importLog}`);
  log('exporting Web');
  code = await engine(exe, ['--path', tree, '--export-release', 'Web', join(web, 'index.html')], userdata, exportLog);
  if (code !== 0 || !existsSync(join(web, 'index.html'))) throw new Error(`the Web export exited ${code}: see ${exportLog}`);
  record.scriptErrors = [...errorsIn(importLog), ...errorsIn(exportLog)];
  if (record.scriptErrors.length) throw new Error(`script errors in the build: ${record.scriptErrors[0]} (see ${exportLog})`);
  writeFileSync(join(dir, 'trial.json'), `${JSON.stringify(record, null, 2)}\n`);
  return { dir, tree, web, userdata, record };
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  const argv = process.argv.slice(2);
  const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
  const all = (n) => argv.map((a, i) => (a === n ? argv[i + 1] : null)).filter(Boolean);
  const out = opt('--out');
  if (!out) { console.error('usage: node tools/clips/trial-web.mjs --out <scratch folder> [--switches a,b] [--park <folder> ...] [--rev HEAD] [--godot <exe>]'); process.exit(2); }
  try {
    const b = await buildTrial({ out, rev: opt('--rev', 'HEAD'), parks: all('--park'), switches: String(opt('--switches', '')).split(',').filter(Boolean), godot: opt('--godot'), log: (m) => console.log(`[trial-web] ${m}`) });
    console.log(`[trial-web] OK: ${b.web} (commit ${b.record.commit.slice(0, 8)}, ${b.record.parks.length} patches, switches ${b.record.switches.join(', ') || 'none'})`);
  } catch (e) { console.error(`[trial-web] FAILED: ${e.message}`); process.exit(1); }
}
