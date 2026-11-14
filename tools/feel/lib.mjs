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

/** What a child process printed, kept in bounds (2026-11-14; the heap out-of-memory of 9 November came from buffering about 22 MB of one repeated SCRIPT ERROR line for 16 minutes): the first headBytes and the
 *  last tailBytes, every line that starts with one of `keep` (the result lines, FEEL and GAUNTLET, at most keepBytes), counts of bytes and lines, and the FIRST script error line. Pure. */
export class OutputKeeper {
  constructor({ headBytes = 16 * 1024, tailBytes = 64 * 1024, keepBytes = 64 * 1024, keep = ['FEEL ', 'GAUNTLET '] } = {}) {
    Object.assign(this, { headBytes, tailBytes, keepBytes, keep, bytes: 0, lines: 0, head: '', tail: '', kept: [], keptBytes: 0, firstError: null, repeats: new Map(), rest: '' });
  }
  /** Adds a chunk (a string or Buffer). Returns the first script error line when this chunk is the one that carried it, else null. */
  push(chunk) {
    const s = typeof chunk === 'string' ? chunk : chunk.toString('utf8');
    this.bytes += Buffer.byteLength(s);
    if (this.head.length < this.headBytes) this.head += s.slice(0, this.headBytes - this.head.length);
    this.tail = (this.tail + s).slice(-this.tailBytes);
    let found = null;
    const parts = (this.rest + s).split(/\r?\n/);
    this.rest = parts.pop().slice(0, 4096);   // an unfinished line waits for its end (and a line with no end is cut)
    for (const l of parts) {
      this.lines++;
      if (this.keep.some((k) => l.startsWith(k)) && this.keptBytes < this.keepBytes) { this.kept.push(l); this.keptBytes += l.length + 1; }
      if (/^\s*(SCRIPT ERROR:|Parse Error:|ERROR: Failed to load script)/.test(l)) {
        if (this.firstError === null) { this.firstError = l.trim().slice(0, 400); found = this.firstError; }
        if (this.repeats.size < 200 || this.repeats.has(l)) this.repeats.set(l, (this.repeats.get(l) || 0) + 1);
      }
    }
    return found;
  }
  /** The text handed to callers: what a short run printed whole, or the head, a line saying how much was left out, the kept lines and the tail. */
  text() {
    const NL = String.fromCharCode(10);
    if (this.bytes <= this.headBytes) return this.head;
    if (this.bytes <= this.tailBytes) return this.tail;
    const top = [...this.repeats].sort((a, b) => b[1] - a[1]).slice(0, 3).map(([l, n]) => `  ${n} x ${l.trim().slice(0, 200)}`).join(NL);
    return [this.head, `[... ${this.bytes} bytes and ${this.lines} lines in all; the middle is left out; the result lines and the tail follow ...]`, this.kept.join(NL), top ? 'most repeated script errors:' + NL + top : '', this.tail].filter((x) => x !== '').join(NL);
  }
  /** The first kept line that starts with `word`, or null. */
  line(word) { return this.kept.find((l) => l.startsWith(word)) ?? null; }
}

/** Runs godot on a scratch tree with args after `--`; resolves { code, text, line, bytes, lines, killedOn } where line is the JSON of the FEEL line (or null). The output is kept in bounds (OutputKeeper), and with
 *  failFast (the default) the child is stopped, by its own PID, at the FIRST script error and the result names it in killedOn: a scratch tree that does not compile fails at once, not after minutes of the same error. */
export function runGd(tree, scriptArgs, { godot, limitMs = 15 * 60 * 1000, script = FEEL_GD, tag = 'feel', failFast = true } = {}) {
  const exe = godotExe(godot);
  return new Promise((ok) => {
    const keeper = new OutputKeeper();
    const child = spawn(exe, ['--headless', '--path', resolve(tree), '--script', script, '--', ...scriptArgs], { stdio: ['ignore', 'pipe', 'pipe'], windowsHide: true });
    try { setPriority(child.pid, osConstants.priority.PRIORITY_BELOW_NORMAL); } catch { /* gone */ }
    const stop = () => { try { if (process.platform === 'win32') spawn('taskkill', ['/PID', String(child.pid), '/T', '/F'], { windowsHide: true }); else child.kill('SIGKILL'); } catch { /* gone */ } };
    let killedOn = null;
    const onData = (d) => { const e = keeper.push(d); if (e && failFast && killedOn === null) { killedOn = e; stop(); } };
    child.stdout.on('data', onData);
    child.stderr.on('data', onData);
    const timer = setTimeout(stop, limitMs);
    child.on('error', () => { clearTimeout(timer); ok({ code: -1, text: 'spawn failed', line: null, bytes: 0, lines: 0, killedOn: null }); });
    child.on('close', (code) => {
      clearTimeout(timer);
      const l = keeper.line('FEEL ');
      let line = null;
      try { line = l ? JSON.parse(l.slice(5)) : null; } catch { /* bad line */ }
      ok({ code, text: keeper.text(), line, bytes: keeper.bytes, lines: keeper.lines, killedOn });
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
