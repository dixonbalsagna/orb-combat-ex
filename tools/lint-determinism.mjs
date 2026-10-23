// Determinism lint: the simulation must use our own math, RNG and clock, never the engine's (the engine's sin, cos, atan2, PI, randf or clock differ between platforms, builds and runs,
// and one of them in a hashed path breaks parity, replays and rollback). Twice in one week sim code used the engine's trig (epoch.gd sin/PI, calm.gd sin(deg_to_rad)); this makes it a failure.
//
//   node tools/lint-determinism.mjs [--root <repo root>] [--allow <file>] [--all] [--list] [--json]
//
// Scans every .gd file under sim/core, sim/director, sim/world and sim/input (not their tools/ and test/ folders, which are checks and run headless outside a match: --all includes them) and fails
// (exit 1) on a bare use of:
//   trig       sin cos tan asin acos atan atan2 sinh cosh tanh deg_to_rad rad_to_deg
//   constants  PI TAU
//   random     randf randi randf_range randi_range randfn rand_range randomize shuffle (a bare call or Array.shuffle / pick_random)  -- the sim has SimRng
//   clock      Time.<anything>, OS.get_ticks_msec, OS.get_ticks_usec, OS.get_unix_time, OS.get_system_time_*, OS.delay_*, Engine.get_frames_drawn, Engine.get_physics_frames
// "Bare" means not after a dot or a name: SimDetMath.sin(x), SimMathx.PI and rng.randf() are our own and pass. A function definition ("func sin(") is not a use.
// Comments and the inside of strings are ignored. Allowed:
//   - a whole file: tools/determinism-allow.json { "files": [ { "path": "sim/core/detmath.gd", "why": "..." } ] } (the wrappers themselves, where the engine's function may be the thing wrapped)
//   - a single line: a "# det-ok: <reason>" comment on the line or on the line directly above (a reason is required)
// Used by tools/validate.js (--lint) and CI.
import { existsSync, readdirSync, readFileSync } from 'node:fs';
import { join, relative, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const DIRS = ['sim/core', 'sim/director', 'sim/world', 'sim/input'];
const SKIP_DIRS = new Set(['tools', 'test']);

const TRIG = ['sin', 'cos', 'tan', 'asin', 'acos', 'atan', 'atan2', 'sinh', 'cosh', 'tanh', 'deg_to_rad', 'rad_to_deg'];
const RANDOM = ['randf', 'randi', 'randf_range', 'randi_range', 'randfn', 'rand_range', 'randomize'];
const NOT_AFTER = '(?<![.\\w$])';   // not a method of something, not part of a longer name
const RULES = [
  { id: 'engine-trig', re: new RegExp(`${NOT_AFTER}(${TRIG.join('|')})\\s*\\(`), what: "the engine's trig", use: 'SimDetMath' },
  { id: 'engine-pi', re: new RegExp(`${NOT_AFTER}(PI|TAU)(?![\\w(])`), what: "the engine's PI/TAU", use: 'SimMathx.PI / SimMathx.TAU' },
  { id: 'engine-random', re: new RegExp(`${NOT_AFTER}(${RANDOM.join('|')})\\s*\\(`), what: "the engine's random numbers", use: 'SimRng' },
  { id: 'engine-random', re: /\.(shuffle|pick_random)\s*\(/, what: "the engine's random shuffle/pick (Array.shuffle, pick_random)", use: 'SimRng' },
  { id: 'engine-vector-trig', re: /\.(angle|angle_to|angle_to_point|rotated|from_angle|slerp|looking_at)\s*\(|(?<![.\w$])(lerp_angle|rotate_toward)\s*\(/, what: "a vector's angle or rotation (the engine's sin, cos and atan2 inside)", use: 'SimDetMath on the components' },
  { id: 'engine-random', re: /RandomNumberGenerator/, what: "the engine's RandomNumberGenerator", use: 'SimRng' },
  { id: 'engine-clock', re: /(?<![.\w$])Time\s*\./, what: "the engine's Time clock", use: 'the tick count' },
  { id: 'engine-clock', re: /(?<![.\w$])OS\s*\.\s*(get_ticks_msec|get_ticks_usec|get_unix_time|get_system_time_secs|get_system_time_msecs|get_datetime|get_time|delay_msec|delay_usec)\s*\(/, what: "an OS clock", use: 'the tick count' },
  { id: 'engine-clock', re: /(?<![.\w$])Engine\s*\.\s*(get_frames_drawn|get_physics_frames|get_process_frames)\s*\(/, what: "the engine's frame counter", use: 'the tick count' },
];

/** The code of a line: comments and the inside of strings blanked (so a word in a note or a message is not a use). Returns { code, comment }. */
export function splitLine(line) {
  let code = '', i = 0, q = null;
  while (i < line.length) {
    const ch = line[i];
    if (q) {
      if (ch === '\\') { code += '  '; i += 2; continue; }
      if (ch === q) { q = null; code += ch; } else code += ' ';
      i++; continue;
    }
    if (ch === '"' || ch === "'") { q = ch; code += ch; i++; continue; }
    if (ch === '#') return { code, comment: line.slice(i + 1) };
    code += ch; i++;
  }
  return { code, comment: '' };
}

const DEF_HEAD = /^\s*(static\s+)?func\s+\w+\s*\([^)]*\)\s*(->\s*[\w\[\], .]+)?\s*:/;
const WAIVER = /\bdet-ok:\s*(\S.*)$/;

/** Findings of one file's text: [{ line, rule, what, use, text }]. Pure. */
export function scan(text) {
  const lines = text.split(/\r?\n/);
  const parts = lines.map(splitLine);
  const out = [];
  for (let n = 0; n < lines.length; n++) {
    // a function definition ("static func sin(x: float) -> float:") is not a use: take its head off, and look at what follows it on the line
    const code = parts[n].code.replace(DEF_HEAD, ' ');
    if (!code.trim()) continue;
    const here = parts[n].comment, above = n > 0 && !parts[n - 1].code.trim() ? parts[n - 1].comment : '';
    const waived = (WAIVER.test(here) || WAIVER.test(above));
    for (const r of RULES) {
      const m = r.re.exec(code.replace(/^\s*func\s+\w+\s*\([^)]*\)\s*(->\s*[\w\[\], ]+)?\s*:/, ' '));
      if (m && !waived) out.push({ line: n + 1, rule: r.id, what: r.what, use: r.use, text: lines[n].trim().slice(0, 140), found: m[0].trim() });
    }
    // a waiver without a reason is itself a finding
    if (/\bdet-ok:\s*$/.test(here)) out.push({ line: n + 1, rule: 'waiver-reason', what: 'a det-ok waiver with no reason', use: '# det-ok: <why this is safe>', text: lines[n].trim().slice(0, 140), found: 'det-ok:' });
  }
  return out;
}

function walk(dir, all, out = []) {
  let names = [];
  try { names = readdirSync(dir, { withFileTypes: true }); } catch { return out; }
  for (const e of names) {
    const p = join(dir, e.name);
    if (e.isDirectory()) { if (all || !SKIP_DIRS.has(e.name)) walk(p, all, out); }
    else if (e.name.endsWith('.gd')) out.push(p);
  }
  return out;
}

/** All findings under a repo root: [{ file, line, ... }]. */
export function lintTree(root, { allow = [], all = false } = {}) {
  const skip = new Set(allow.map((a) => a.path));
  const findings = [];
  for (const d of DIRS) {
    for (const f of walk(join(root, d), all).sort()) {
      const rel = relative(root, f).split(sep).join('/');
      if (skip.has(rel)) continue;
      for (const x of scan(readFileSync(f, 'utf8'))) findings.push({ file: rel, ...x });
    }
  }
  return findings;
}

export function loadAllow(file) {
  if (!existsSync(file)) return [];
  const j = JSON.parse(readFileSync(file, 'utf8'));
  const files = Array.isArray(j.files) ? j.files : [];
  for (const a of files) if (!a.path || !a.why) throw new Error(`${file}: every allowed file needs a path and a why`);
  return files;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const args = process.argv.slice(2);
  const opt = (n, d) => { const i = args.indexOf(n); return i >= 0 ? args[i + 1] : d; };
  const root = resolve(opt('--root', join(import.meta.dirname, '..')));
  let allow;
  try { allow = loadAllow(resolve(opt('--allow', join(import.meta.dirname, 'determinism-allow.json')))); } catch (e) { console.error(`lint-determinism: ${e.message}`); process.exit(2); }
  const findings = lintTree(root, { allow, all: args.includes('--all') });
  if (args.includes('--json')) console.log(JSON.stringify(findings, null, 1));
  else if (findings.length) {
    const byFile = new Map();
    for (const f of findings) { if (!byFile.has(f.file)) byFile.set(f.file, []); byFile.get(f.file).push(f); }
    for (const [file, fs] of byFile) {
      console.error(`${file}`);
      for (const f of fs) console.error(`  ${f.line}: ${f.rule}: ${f.what} ("${f.found}"); use ${f.use}, or add "# det-ok: <reason>" if this never reaches a hashed path\n      ${f.text}`);
    }
    console.error(`determinism lint FAILED: ${findings.length} use(s) of the engine's math, random numbers or clock in ${byFile.size} file(s) of ${DIRS.join(', ')}`);
  } else console.log(`determinism lint ok: no engine trig, PI/TAU, random numbers or clock in ${DIRS.join(', ')}${allow.length ? ` (${allow.length} file(s) allowed: ${allow.map((a) => a.path).join(', ')})` : ''}`);
  process.exit(findings.length ? 1 : 0);
}
