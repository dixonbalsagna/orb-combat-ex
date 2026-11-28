// A ratchet (Tools, 2026-11-28): no NEW script under tools/ or docs/*/tools may start the game except through the launcher (tools/godot-run.sh) or, in node, with the environment of tools/lib/userdata.mjs.
// The scripts that did before this rule are listed in tools/godot-launch-baseline.json; the list may only get shorter.
//   node tools/lint-godot-launch.mjs            check (CI)
//   node tools/lint-godot-launch.mjs --write    rewrite the baseline (only ever to remove names: a name that is not already there is refused)
// It reads text: it finds the usual ways of starting the engine, not every way there could be.
import { readFileSync, readdirSync, statSync, writeFileSync, existsSync } from 'node:fs';
import { join, relative, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const REPO = resolve(fileURLToPath(new URL('..', import.meta.url)));
export const BASELINE = 'tools/godot-launch-baseline.json';
const EXT = /\.(sh|bash|mjs|cjs|js|ps1|cmd|bat|py)$/i;
const SKIP = new Set(['tools/godot-run.sh', 'tools/lib/userdata.mjs', 'tools/lint-godot-launch.mjs', 'tools/lint-godot-launch-selftest.mjs']);

// "--headless" handed over as a word of its own is the surest sign (every run here has it); a browser's "--headless=new" is not it.
const STARTS = {
  shell: [/\s--headless(\s|$)/, /"?\$\{?(GODOT|GODOT_EXE|GODOT_BIN|G|GD|godot)\}?"?\s+(--?[a-z])/, /Godot_v[^\s"']*(\.exe|x86_64)["']?\s+--?[a-z]/, /(^|[;&|(]\s*)godot\s+--?[a-z]/],
  node: [/['"`]--headless['"`]\s*[,\]]/, /\b(spawn|spawnSync|execFile|execFileSync|exec|execSync|run)\s*\(\s*(this\.|g\.|opts?\.)?(godot|GODOT|godotExe|gd\b|engine)/, /\brunGodot\s*\(/, /\b(spawn|spawnSync|execFile|execFileSync)\s*\([^)\n]*process\.env\.GODOT/],
  power: [/--headless(?![=\w-])/, /&\s*\$\{?(env:)?godot[a-z_]*\}?/i, /Start-Process[^\n]*godot/i, /Godot_v[^\s"']*\.exe["']?\s+--?[a-z]/],
  python: [/['"]--headless['"]/, /(subprocess\.(run|Popen|call|check_output)|os\.system)\s*\([^\n]*godot/i],
};
const family = (f) => (/\.(sh|bash)$/i.test(f) ? 'shell' : /\.(ps1|cmd|bat)$/i.test(f) ? 'power' : /\.py$/i.test(f) ? 'python' : 'node');

/** Does this file's text start the game, and does it do so through the launcher? { starts, through }. Pure. */
export function readScript(name, text) {
  const fam = family(name);
  const comment = fam === 'node' ? /^\s*(\/\/|\*|\/\*)/ : fam === 'power' ? /^\s*(#|rem\b|::)/i : /^\s*#/;
  const code = text.split(/\r?\n/).filter((l) => !comment.test(l)).join('\n');
  const starts = code.split('\n').some((l) => STARTS[fam].some((re) => re.test(l)));
  const through = fam === 'node' ? /from\s+['"][./]*(lib\/)?userdata\.mjs['"]|from\s+['"][^'"]*\/lib\/userdata\.mjs['"]|godot-run\.sh/.test(code) : /godot-run\.sh/.test(code);
  return { starts, through };
}

/** The judgement: { problems, notes }. `found` = the offenders' paths now; `baseline` = the recorded ones. Pure. */
export function judge(found, baseline) {
  const problems = [], notes = [];
  for (const f of found) if (!baseline.includes(f)) problems.push(`${f}: starts the game without the launcher. Use bash tools/godot-run.sh (or, in node, userdataEnv from tools/lib/userdata.mjs)`);
  for (const f of baseline) if (!found.includes(f)) notes.push(`${f}: no longer starts the game outside the launcher: take it out of ${BASELINE} (--write)`);
  return { problems, notes };
}

function walk(dir, out) {
  if (!existsSync(dir)) return out;
  for (const n of readdirSync(dir)) {
    if (n === 'node_modules' || n === '.godot' || n === 'fixtures' || n === 'pending' || n === 'runs') continue;
    const p = join(dir, n);
    if (statSync(p).isDirectory()) walk(p, out); else if (EXT.test(n)) out.push(p);
  }
  return out;
}

function toolsFolders(dir, out) {
  if (!existsSync(dir)) return out;
  for (const n of readdirSync(dir)) {
    if (n === 'node_modules' || n === 'pending' || n === 'runs') continue;
    const p = join(dir, n);
    if (!statSync(p).isDirectory()) continue;
    if (n === 'tools') out.push(p); else toolsFolders(p, out);
  }
  return out;
}

export function offenders(root = REPO) {
  const files = walk(join(root, 'tools'), []);   // docs/tools is the Tools director's pages: it is searched below like any docs/<x>/tools
  for (const d of toolsFolders(join(root, 'docs'), [])) walk(d, files);
  const out = [];
  for (const p of files) {
    const name = relative(root, p).split('\\').join('/');
    if (SKIP.has(name)) continue;
    const r = readScript(name, readFileSync(p, 'utf8'));
    if (r.starts && !r.through) out.push(name);
  }
  return out.sort();
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  const found = offenders();
  const path = join(REPO, BASELINE);
  const baseline = existsSync(path) ? JSON.parse(readFileSync(path, 'utf8')).files : null;
  if (process.argv.includes('--write')) {
    const added = baseline ? found.filter((f) => !baseline.includes(f)) : [];
    if (added.length) { console.error(`godot launch ratchet: --write never adds a name: ${added.join(', ')}`); process.exit(1); }
    writeFileSync(path, JSON.stringify({ _about: 'Scripts that started the game outside tools/godot-run.sh before the rule (2026-11-28). Only gets shorter: node tools/lint-godot-launch.mjs.', files: found }, null, 2) + '\n');
    console.log(`wrote ${BASELINE}: ${found.length} script(s)`);
    process.exit(0);
  }
  if (!baseline) { console.error(`godot launch ratchet: no ${BASELINE}`); process.exit(1); }
  const r = judge(found, baseline);
  for (const n of r.notes) console.log('note: ' + n);
  for (const p of r.problems) console.error('godot launch: ' + p);
  console.log(r.problems.length ? `godot launch ratchet FAILED: ${r.problems.length} new script(s)` : `godot launch ratchet ok: ${found.length} against a baseline of ${baseline.length}`);
  process.exit(r.problems.length ? 1 : 0);
}
