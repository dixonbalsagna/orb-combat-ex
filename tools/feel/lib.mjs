// Shared helpers of the feel tools (docs/tools/feel.md): find the tree a saved match was recorded on, make a scratch copy of it, run tools/feel/feel.gd in it under Godot (headless, below-normal, with a time limit), and read its one JSON line.
import { existsSync, readFileSync, writeFileSync, mkdirSync, cpSync, readdirSync, rmSync } from 'node:fs';
import { join, resolve, dirname, basename } from 'node:path';
import { tmpdir } from 'node:os';
import { fileURLToPath } from 'node:url';
import { spawn } from 'node:child_process';
import { createHash } from 'node:crypto';
import { setPriority, constants as osConstants } from 'node:os';

export const HERE = dirname(fileURLToPath(import.meta.url));
export const ROOT = resolve(HERE, '..', '..');
export const FEEL_GD = join(HERE, 'feel.gd');
export const WORK = join(tmpdir(), 'meridian-feel');

export function godotExe(given) {
  const local = process.env.LOCALAPPDATA ? join(process.env.LOCALAPPDATA, 'Programs', 'Godot', '4.7.2', 'Godot_v4.7.2-stable_win64_console.exe') : '';
  const found = [given, process.env.GODOT, local].find((p) => p && existsSync(p));
  if (!found) throw new Error('no Godot executable: pass --godot <exe> or set GODOT (4.7.2 console build)');
  return found;
}

/** A saved match file (the page's orb-first-play json) or a bare replay: { doc, replay }. */
export function readMatch(file) {
  const doc = JSON.parse(readFileSync(file, 'utf8'));
  return { doc, replay: doc.replay || doc };
}

/** The kept tree a saved match was recorded on: homework/Files/builds/orb-first-play-<commit8>-<folder8>/tree, named by the file's `build`. */
export function keptTreeOf(doc, root = ROOT) {
  const b = doc.build;
  if (!b || !b.commit || !b.folder) return null;
  const dir = join(root, 'homework', 'Files', 'builds', `orb-first-play-${String(b.commit).slice(0, 8)}-${String(b.folder).slice(0, 8)}`, 'tree');
  return existsSync(join(dir, 'project.godot')) ? dir : null;
}

/** A scratch copy of a tree (the kept folders are never touched), made once and reused: <tmp>/meridian-feel/<name>-<hash of the path>. */
export function workCopy(tree, tag = '') {
  const src = resolve(tree);
  const name = basename(dirname(src)) + tag + '-' + createHash('sha1').update(src).digest('hex').slice(0, 6);
  const dst = join(WORK, name);
  if (!existsSync(join(dst, '.copied'))) {
    rmSync(dst, { recursive: true, force: true });
    mkdirSync(WORK, { recursive: true });
    cpSync(src, dst, { recursive: true });
    writeFileSync(join(dst, '.copied'), new Date().toISOString());
  }
  return dst;
}

/** Runs godot on a scratch tree with args after `--`; resolves { code, text, line } where line is the JSON of the FEEL line (or null). */
export function runGd(tree, scriptArgs, { godot, limitMs = 15 * 60 * 1000, script = FEEL_GD, tag = 'feel' } = {}) {
  const exe = godotExe(godot);
  return new Promise((ok) => {
    const chunks = [];
    const child = spawn(exe, ['--headless', '--path', resolve(tree), '--script', script, '--', ...scriptArgs], { stdio: ['ignore', 'pipe', 'pipe'], windowsHide: true });
    try { setPriority(child.pid, osConstants.priority.PRIORITY_BELOW_NORMAL); } catch { /* gone */ }
    child.stdout.on('data', (d) => chunks.push(d));
    child.stderr.on('data', (d) => chunks.push(d));
    const timer = setTimeout(() => {
      try { if (process.platform === 'win32') spawn('taskkill', ['/PID', String(child.pid), '/T', '/F'], { windowsHide: true }); else child.kill('SIGKILL'); } catch { /* gone */ }
    }, limitMs);
    child.on('error', () => { clearTimeout(timer); ok({ code: -1, text: 'spawn failed', line: null }); });
    child.on('close', (code) => {
      clearTimeout(timer);
      const text = Buffer.concat(chunks).toString('utf8');
      const l = text.split(/\r?\n/).find((x) => x.startsWith('FEEL '));
      let line = null;
      try { line = l ? JSON.parse(l.slice(5)) : null; } catch { /* bad line */ }
      ok({ code, text, line });
    });
  });
}

// ---------------------------------------------------------------- overrides

const parseValue = (s) => { try { return JSON.parse(s); } catch { return s; } };

/** "data/input/timing.json:switches.quickRead=true" -> { file, path: ['switches','quickRead'], value: true }. */
export function parseOverride(spec) {
  const m = /^([^:=]+):([^=]+)=(.*)$/.exec(spec);
  if (!m) throw new Error(`override "${spec}": expected file:dotted.path=value (value JSON)`);
  return { file: m[1], path: m[2].split('.'), value: parseValue(m[3]) };
}

/** A switch is an override of data/input/timing.json switches.<name> (true when no value is given). */
export function parseSwitch(spec) {
  const [n, v] = spec.split('=');
  return { file: 'data/input/timing.json', path: ['switches', n], value: v === undefined ? true : parseValue(v) };
}

/** Overrides from a JSON file: a list of { file, path, value } or an object { "file:path": value }. */
export function overridesFromFile(f) {
  const j = JSON.parse(readFileSync(f, 'utf8'));
  if (Array.isArray(j)) return j.map((o) => ({ file: o.file, path: Array.isArray(o.path) ? o.path : String(o.path).split('.'), value: o.value }));
  return Object.entries(j).map(([k, v]) => { const m = /^([^:]+):(.+)$/.exec(k); return { file: m[1], path: m[2].split('.'), value: v }; });
}

export const SUPPORTED_FILES = ['data/input/timing.json', 'data/director/interrupts.json'];

/** Writes a file even when the copy kept the read-only mark of the kept folder it came from (the old file is removed first). */
export function putFile(p, data) {
  rmSync(p, { force: true });
  writeFileSync(p, data);
}

/** Writes overrides into JSON files of a scratch tree (any data file: the slower, whole-match route). */
export function patchTree(tree, overrides) {
  for (const o of overrides) {
    const p = join(tree, o.file);
    const j = JSON.parse(readFileSync(p, 'utf8'));
    let d = j;
    for (const k of o.path.slice(0, -1)) { if (typeof d[k] !== 'object' || d[k] === null) d[k] = {}; d = d[k]; }
    d[o.path[o.path.length - 1]] = o.value;
    putFile(p, JSON.stringify(j, null, 2));
  }
}

/** The match's tree: --tree, else the kept tree its build field names; throws a plain message when neither exists. */
export function treeFor(doc, given) {
  const t = given ? resolve(given) : keptTreeOf(doc);
  if (!t || !existsSync(join(t, 'project.godot'))) throw new Error(given ? `no tree at ${given}` : 'this match file names a build whose kept tree is not on this PC (homework/Files/builds/...): pass --tree <a tree folder>');
  return t;
}

export function matchFiles(dir = join(ROOT, 'homework', 'Files')) {
  return readdirSync(dir).filter((n) => /^orb-first-play-.*\.json$/.test(n)).map((n) => join(dir, n));
}
