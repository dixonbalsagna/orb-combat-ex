// The two-fighter ratchet (the EP's order, 2026-11-01; for the 2v2 restructure): a count of the places shipped code names exactly two fighters, which may only go down, so that code stops growing while the game is restructured for four.
//
//   node tools/ratchet-two-fighter.mjs                check: the total may not exceed tools/ratchet-two-fighter.json's; exit 1 when it does, 2 on bad use
//   node tools/ratchet-two-fighter.mjs --list         every file's count against its baseline
//   node tools/ratchet-two-fighter.mjs --write        lower the baseline to today's count (refuses to raise it)
//   node tools/ratchet-two-fighter.mjs --root <dir>   count a tree other than the repository (a stack tree, a test)
//
// What is counted: the four spellings `S.dirS.ex`, `fighters[0]`, `fighters[1]` and `SimRoster.opp`, in the shipped GDScript under sim/, render/, ui/, net/ and audio/. NOT counted: tests, tools, probes and checks (a directory named test, tests, tools, probe or
// probes, or a file ending _check, _test, _probe or _bench), docs, data. The ratchet is on the TOTAL, so moving a reference between files is free and an honest fix, which removes one, only ever lowers it. A rise names the files that grew.
// After a batch of parks lands, run --write: the baseline was taken from the stack with the parks applied (so landings do not go red), which leaves the slack between main and the stack; --write takes the slack back.
import { readdirSync, readFileSync, writeFileSync, existsSync } from 'node:fs';
import { join, resolve, relative, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

export const SPELLINGS = [
  { name: 'S.dirS.ex', re: /\bS\.dirS\.ex\b/g },
  { name: 'fighters[0]', re: /\bfighters\[0\]/g },
  { name: 'fighters[1]', re: /\bfighters\[1\]/g },
  { name: 'SimRoster.opp', re: /\bSimRoster\.opp\b/g },
];
export const ROOTS = ['sim', 'render', 'ui', 'net', 'audio'];
const SKIP_DIRS = new Set(['test', 'tests', 'tools', 'probe', 'probes', 'node_modules', '.git', '.godot']);
const SKIP_FILE = /(_check|_test|_probe|_bench)\.gd$/;

/** Counts the spellings in shipped files under `root`: { files: { 'sim/core/x.gd': n }, total, bySpelling }. */
export function count(root) {
  const files = {}, bySpelling = Object.fromEntries(SPELLINGS.map((s) => [s.name, 0]));
  let total = 0;
  const walk = (dir) => {
    let ents;
    try { ents = readdirSync(dir, { withFileTypes: true }); } catch { return; }
    for (const e of ents) {
      if (e.isDirectory()) { if (!SKIP_DIRS.has(e.name)) walk(join(dir, e.name)); continue; }
      if (!e.name.endsWith('.gd') || SKIP_FILE.test(e.name)) continue;
      const text = readFileSync(join(dir, e.name), 'utf8');
      let n = 0;
      for (const s of SPELLINGS) { const m = text.match(s.re); if (m) { n += m.length; bySpelling[s.name] += m.length; } }
      if (n) { files[relative(root, join(dir, e.name)).split(sep).join('/')] = n; total += n; }
    }
  };
  for (const r of ROOTS) walk(join(root, r));
  return { files, total, bySpelling };
}

/** The verdict of a count against a baseline: { ok, total, baseline, grew: [[file, was, now]], shrank }. */
export function judge(now, base) {
  const grew = [], shrank = [];
  for (const [f, n] of Object.entries(now.files)) { const was = base.files[f] || 0; if (n > was) grew.push([f, was, n]); }
  for (const [f, was] of Object.entries(base.files)) { const n = now.files[f] || 0; if (n < was) shrank.push([f, was, n]); }
  return { ok: now.total <= base.total, total: now.total, baseline: base.total, grew, shrank };
}

const here = fileURLToPath(new URL('.', import.meta.url));
function main() {
  const argv = process.argv.slice(2);
  const known = new Set(['--list', '--write', '--root', '--baseline']);
  for (const a of argv) if (a.startsWith('--') && !known.has(a)) { console.error(`unknown option ${a}`); process.exit(2); }
  const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
  const root = resolve(opt('--root', join(here, '..')));
  const basePath = resolve(opt('--baseline', join(here, 'ratchet-two-fighter.json')));
  const now = count(root);
  const base = existsSync(basePath) ? JSON.parse(readFileSync(basePath, 'utf8')) : null;
  if (argv.includes('--write')) {
    if (base && now.total > base.total) { console.error(`two-fighter ratchet: refusing to RAISE the baseline (${base.total} to ${now.total}); fix the code, not the number`); process.exit(1); }
    const out = { schema: 'ratchet.two-fighter/1', _about: 'The places shipped code names exactly two fighters (tools/ratchet-two-fighter.mjs). May only go down; lower it with --write after a fix or a landing.', spellings: SPELLINGS.map((s) => s.name), total: now.total, bySpelling: now.bySpelling, files: Object.fromEntries(Object.entries(now.files).sort()) };
    writeFileSync(basePath, JSON.stringify(out, null, 2) + '\n');
    console.log(`two-fighter ratchet: baseline written, ${now.total} (${base ? `was ${base.total}` : 'first'})`);
    return;
  }
  if (!base) { console.error('two-fighter ratchet: no baseline (run --write once)'); process.exit(2); }
  const v = judge(now, base);
  if (argv.includes('--list')) {
    for (const [f, n] of Object.entries(now.files).sort()) console.log(`${String(n).padStart(4)}  ${String(base.files[f] || 0).padStart(4)}  ${f}`);
    console.log(`now ${now.total}, baseline ${base.total}; by spelling ${JSON.stringify(now.bySpelling)}`);
  }
  if (!v.ok) {
    console.log(`two-fighter ratchet FAILED: ${v.total} places name exactly two fighters, the baseline is ${v.baseline}. Files that grew:`);
    for (const [f, was, n] of v.grew) console.log(`  ${f}: ${was} to ${n}`);
    console.log('Fix: take the second fighter from the list (S.fighters, the roster) instead of fighters[0], fighters[1], SimRoster.opp or S.dirS.ex. Do not raise the baseline.');
    process.exit(1);
  }
  console.log(`two-fighter ratchet ok: ${v.total} against a baseline of ${v.baseline}${v.total < v.baseline ? ` (${v.baseline - v.total} below it: run --write to take it back)` : ''}`);
}
if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) main();
