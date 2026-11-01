// Bisect a headless check over the stack's parks (the EP, 2026-10-31: "bisect by park and name the first park that causes each, with the failing lines, one job at a time"). The stack is the commit plus the parks in the order
// of tools/preview/stack.json; the check is run on HEAD alone and on the first k parks, and the smallest k where it fails names the first park that causes it (assuming it stays failing: the report says so when it does not).
// One Godot job at a time, below-normal priority; each probe is a fresh scratch tree (the commit, k parks, the import, the check). Never touches the repository.
//
//   node tools/preview/bisect.mjs --check anim|cover|lake|<res://path/to/check.gd> [--args "-- --seeds=4"] [--repo <dir>] [--manifest <file>] [--out <scratch>] [--rev <commit>] [--parks id,id] [--lo 0] [--hi N] [--switches id,id|none] [--with-switches-anyway] [--limit-min 40]
//
// Known checks: anim = render/anim/tools/anim_check.gd, cover = render/tools/cover_water_check.gd, lake = render/tools/lake_water_check.gd. A check prints "FAIL  <what>" lines and ends on a verdict line; its exit code is 0 when it passes.
// Output: for each probe the k, the result and the failing lines; then "FIRST FAILING PARK: <id> (<owner>) at k" with the failing lines at k and the ones that are new at k against k-1.
import { readFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { godotExe, runGodot } from './preview.mjs';
import { loadManifest, runStack } from './stack.mjs';

const HERE = fileURLToPath(new URL('.', import.meta.url));
const REPO = resolve(HERE, '..', '..');
const CHECKS = { anim: 'res://render/anim/tools/anim_check.gd', cover: 'res://render/tools/cover_water_check.gd', lake: 'res://render/tools/lake_water_check.gd' };

const argv = process.argv.slice(2);
const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
const has = (n) => argv.includes(n);
if (has('--help') || !opt('--check')) { console.log(readFileSync(fileURLToPath(import.meta.url), 'utf8').split('\n').filter((l) => l.startsWith('//')).slice(0, 11).map((l) => l.slice(3)).join('\n')); process.exit(has('--help') ? 0 : 2); }

const repo = resolve(opt('--repo', REPO));
const manifest = opt('--manifest');
const checkName = opt('--check');
const script = CHECKS[checkName] || checkName;
const extra = (opt('--args', '') || '').split(' ').filter(Boolean);
const base = resolve(opt('--out', join(tmpdir(), 'meridian-bisect')));
const limitMs = Number(opt('--limit-min', 40)) * 60 * 1000;
const log = (m) => console.error(`[bisect] ${m}`);
const man = loadManifest(readFileSync(resolve(manifest || join(HERE, 'stack.json')), 'utf8'));
if (man.problems.length) { console.error(man.problems.join('; ')); process.exit(2); }
const PARKS = (opt('--parks', '') || '').split(',').filter(Boolean);   // --parks a,b,c: bisect over just these, in the manifest's order (a stack of someone else's: "main + World 08-15 + field-pads + ...")
const parks = PARKS.length ? man.parks.filter((p) => PARKS.includes(p.id)) : man.parks.filter((p) => p.ready !== false);
if (PARKS.length && parks.length !== PARKS.length) { console.error(`--parks names ${PARKS.filter((x) => !man.parks.some((p) => p.id === x)).join(', ') || 'a park twice'}, which the manifest does not have`); process.exit(2); }
const godot = godotExe(opt('--godot'));
// These five read the switches AS SHIPPED (Combat, 2026-11-01; found here with --switches): with the stack's switches on they fail on the commit alone, so by default they are run with the switches off, and run with them on only when told.
const SHIPPED_ONLY = /(?:^|\/)(?:parity|launchbiome_probe|cover_water_check|lake_water_check|anim_check)\.gd$/;
let SW = opt('--switches');   // which preview switches are on in every probe: a list, 'none', or absent (all, as the stack has them)
if (SHIPPED_ONLY.test(script)) {
  if (SW === undefined) { SW = 'none'; console.error('[bisect] this check reads the switches AS SHIPPED (golden, launchbiome_probe, cover/lake water, anim_check fail with the stack\'s switches on, on main alone): running it with the switches OFF; pass --switches <list> --with-switches-anyway to vary them'); }
  else if (SW !== 'none' && !has('--with-switches-anyway')) { console.error(`refusing: ${script} reads the switches AS SHIPPED, so it fails on any tree with switches on (${SW}) whatever the parks are; use --switches none, or add --with-switches-anyway if you are tracing which switch does it`); process.exit(2); }
}
const switches = SW === undefined ? null : SW === 'none' ? [] : SW.split(',').filter(Boolean);
const memo = new Map();

/** Runs the check on the commit plus the first k parks. { fail: bool, lines: [failing lines], verdict, code, errors } */
async function probe(k) {
  if (memo.has(k)) return memo.get(k);
  const ids = parks.slice(0, k).map((p) => p.id);
  log(`k=${k}: ${k ? `the first ${k} park(s), the last ${ids[k - 1]}` : 'the commit alone'}`);
  // a prefix of the stack: the stack tool with only those parks and no matches (it still imports the project), its tree kept
  const out = join(base, 'trees');
  const s = await runStack({ repo, manifest, rev: opt('--rev', 'main'), only: ids.length ? ids : ['(none)'], noSmoke: true, keepTree: true, force: true, switches, out, state: join(base, `last-${k}.json`), godot: opt('--godot'), log: () => {} });
  const r = s.report;
  const tree = join(out, `${r.commit.slice(0, 8)}-${r.key}`, 'tree');
  const conflicts = r.parks.filter((p) => p.status !== 'applied').map((p) => `${p.id}:${p.status}`);
  const logFile = join(base, `check-${checkName.replace(/[^a-z0-9]/gi, '_')}-${k}${SW === undefined ? '' : `-sw-${SW.replace(/[^a-z0-9]/gi, '_')}`}.log`);
  const code = await runGodot({ godot, godotNode: null }, ['--headless', '--path', tree, '--script', script, ...(extra.length ? ['--', ...extra] : [])], logFile, limitMs);
  const text = (() => { try { return readFileSync(logFile, 'utf8'); } catch { return ''; } })();
  const lines = text.split('\n').filter((l) => /^FAIL\b/.test(l)).map((l) => l.trim());
  const verdict = (text.match(/^.*(?:check|checks) (?:passed|FAILED[^\n]*)\s*$/m) || [''])[0].trim();
  const res = { k, park: k ? ids[k - 1] : '(the commit alone)', fail: code !== 0, code, lines, verdict, conflicts };
  rmSync(join(out, `${r.commit.slice(0, 8)}-${r.key}`), { recursive: true, force: true });   // one tree at a time
  memo.set(k, res);
  console.log(`k=${String(k).padStart(2)}  ${switches === null ? '' : `[switches: ${switches.join(',') || 'none'}] `}${res.fail ? 'FAILS' : 'passes'}  (${res.park})  ${res.verdict}${conflicts.length ? `  [parks not applied: ${conflicts.join(', ')}]` : ''}`);
  for (const l of lines.slice(0, 14)) console.log(`        ${l}`);
  return res;
}

const N = parks.length;
let lo = Number(opt('--lo', 0)), hi = Number(opt('--hi', N));
const a = await probe(lo);
if (a.fail) { console.log(`\nThe check already fails at k=${lo} (${a.park}): nothing to bisect above it.`); process.exit(0); }
const b = await probe(hi);
if (!b.fail) { console.log(`\nThe check passes at k=${hi} too (all ${hi} parks): no failure to find.`); process.exit(0); }
while (hi - lo > 1) {
  const mid = Math.floor((lo + hi) / 2);
  const m = await probe(mid);
  if (m.fail) hi = mid; else lo = mid;
}
const first = memo.get(hi), before = memo.get(lo);
console.log(`\nFIRST FAILING PARK: ${first.park} (${(parks[hi - 1] || {}).owner || '?'}) at k=${hi}; it passes with the first ${lo} parks (${before.park}).`);
const was = new Set(before.lines);
const fresh = first.lines.filter((l) => !was.has(l));
console.log(`${first.lines.length} failing line(s) at k=${hi}, ${fresh.length} new against k=${lo}:`);
for (const l of first.lines) console.log(`  ${was.has(l) ? '  ' : '+ '}${l}`);
console.log('(Assumes the check keeps failing above k: a later park can mask or add to it. The probes above are the evidence.)');
