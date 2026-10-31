// The interim's nightly seed run (Legal, RL-137): while the playable build is up under an interim, a few NEW AI seeds are captured each night in both modes against the PINNED build,
// reading only the primary reading, and any clip over 3 on it is the take-down trigger (RL-136 item 3). Run by hand or by the machine's own scheduler; no CI cost.
//
//   node tools/flash/nightly-seeds.mjs [--count 8] [--base 1000] [--jobs 3] [--cpu-cap 25] [--work <dir>] [--history <file>] [--pin <sha>] [--dry-run] [--no-export] [--no-route-check] [--no-hook-check] [--run-pixels <script>]
//
// What it does, in order:
//   1. the pinned commit (tools/site-pin.mjs: the commit the pass file recorded) and its Web export, kept in <work>/<sha7>/web (exported once, then reused);
//   2. the night's seeds: the next --count integers from --base that are in neither the recorded set (tools/flash/sources.json) nor the history (tools/flash/nightly-seeds.json), so no seed
//      is read twice and the set never repeats; the pick is deterministic (the history is the only state);
//   3. tools/flash/run-pixels.mjs --seeds <those> in both modes through the guarded launcher (below-normal, the cap, a time limit), three at a time;
//   3b. the `signature` clip in both modes on the same export (Legal RL-195 condition (a)), every night, with its three readings (primary / area-15% / two-second memory) in the line and the row;
//   3c. the build info of the pinned export (its commit and date, and the state of every watched switch in ITS data: tools/flash/nightly-switches.json, Legal RL-208 (2): kits, rapid fire,
//      snares and mines, grab call-outs, rally), and the exported-build ROUTE CHECK (RL-208 (1)): the pin's PUBLIC export (lock on, capture_hook off) scanned for every route that could lift the
//      Reduce flashing lock and run in a browser on a public hostname (the interim check's routes scan and tools/check-site-hook.mjs). --no-route-check / --no-hook-check skip them: "not run" is never a pass.
//   4. ONE report line, a build info line, the route check, the switches and a verdict, and an appended row in the history. EXIT CODES (Legal RL-208): 0 clean; 1 TAKE DOWN: a REDUCED clip (the mode players
//      get) over the limit, or a normal one while the route check failed or did not run, or the route check failed (node tools/site-offline.mjs and tell the EP); 2 the run itself failed (a clip not read,
//      the signature clip included: a missing clip is not a pass); 3 the signature clip reads, reduced, worse than 2.5 / 3 / 2 (RL-195: tell the EP; not a take-down by itself); 4 FINDING: a NORMAL clip over
//      the limit while the route check passed (recorded, not a trigger); 5 a watched switch is not as Legal reviewed it (its row's own clips join the batch).
// Only the primary reading is read here (Legal: "reading only the primary"); the full table of a run stays in <work>/<sha7>/<date>/clips (margins.mjs reads it if a clip is over).
// About 8 seeds x 2 modes x 15 minutes / 3 jobs: roughly 80 minutes, then the export once (about 3 minutes).
import { spawnSync } from 'node:child_process';
import { existsSync, mkdirSync, readdirSync, readFileSync, statSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { exportPinned } from '../site-pin.mjs';
import { scanRoutes } from '../site-routes.mjs';
import { readSignature, worseThan, readingText } from './signature-gate.mjs';

const HERE = import.meta.dirname;
const DEFAULT_HISTORY = join(HERE, 'nightly-seeds.json');
export const TAKE_DOWN_ABOVE = 3;   // primary reading, flashes in the worst second (RL-136 item 3)
export const TAKE_DOWN_ABOVE_OWNER = 3.5;   // under Orb's owner-approved interim (Legal's addendum 11, RL-161): a new scene over 3.5 on the primary reading is the trigger

/** The limit the nightly applies for a site config: 3.5 while the interim is the owner's decision, else 3. */
export function limitFor(config) { return config && config.interim && typeof config.interim.owner === 'string' && config.interim.owner.trim() ? TAKE_DOWN_ABOVE_OWNER : TAKE_DOWN_ABOVE; }

/** The limit from the interim's own record (tools/site-interim-owner.json "record".take_down_above), used when the site is offline or a pin is given: site.json then says nothing about the
 *  interim (offline, interim null), and reading it would apply 3 where the owner-approved limit is 3.5. A missing or odd record gives 3, the stricter limit. Pure. */
export function limitFromRecord(words) {
  const v = words && words.record && words.record.take_down_above;
  return typeof v === 'number' && Number.isFinite(v) && v >= TAKE_DOWN_ABOVE ? v : TAKE_DOWN_ABOVE;
}

/** The next `count` seeds from `base` that are in neither the recorded set nor the history. Pure. */
export function nextSeeds(count, base, recorded, used) {
  const taken = new Set([...recorded, ...used]);
  const out = [];
  for (let s = base; out.length < count && s < base + 100000; s++) if (!taken.has(s)) out.push(s);
  return out;
}

/** What a run says, from the summary rows (run-pixels summary.json: { id, error?, result: { general: { flashes } } }). Pure. */
export function readRun(rows, seeds, limit = TAKE_DOWN_ABOVE) {
  const want = seeds.flatMap((s) => [`ai-${s}-normal`, `ai-${s}-reduced`]);
  const have = new Map(rows.filter((r) => !r.error && r.result && r.result.general).map((r) => [r.id, r.result.general.flashes]));
  const missing = want.filter((id) => !have.has(id));
  let maxId = null, max = -1;
  for (const [id, v] of have) if (want.includes(id) && v > max) { max = v; maxId = id; }
  const over = [...have].filter(([id, v]) => want.includes(id) && v > limit).map(([id, v]) => ({ id, primary: v }));
  return { clips: want.length, read: want.length - missing.length, missing, max, maxId, over, overReduced: over.filter((o) => modeOf(o.id) === 'reduced'), overNormal: over.filter((o) => modeOf(o.id) !== 'reduced') };
}

/** The mode a clip id names ("ai-1000-reduced" is reduced), or null. */
export function modeOf(id) { const m = /-(normal|reduced)$/.exec(String(id)); return m ? m[1] : null; }

// Legal RL-208 (2026-10-30), on the nightly's exit code: only REDUCED (the mode players get) is the take-down trigger. A NORMAL clip over the limit is a finding while the same run's exported-build
// route check passes (the lock flag true, capture_hook off, F8 refused, the debug words local-only, no command-line word reaches normal); if that check fails, or was not run, the lock may be
// reachable and a normal reading is a trigger on its own (addendum 12(c)). The nightly keeps reading normal for the record (a restore or a release needs it).
//   0 clean   1 take-down   2 the run itself failed (a clip not read)   3 the signature clip reads worse, reduced, than 2.5 / 3 / 2   4 finding (normal over the limit, route check passed)
//   5 a watched switch is not as Legal reviewed it (its row's clips join the batch)
export const EXIT = { clean: 0, takeDown: 1, runFailed: 2, signatureWorse: 3, finding: 4, switchFlipped: 5 };

/** The verdict of a night. `routes`: { status: 'passed' | 'failed' | 'not run', problems: [] }; `flips`: switchFlips(); `runOk`: run-pixels itself ended 0 or 1. Pure. Returns { code, label, lines }. */
export function verdictOf({ r, sig, routes = { status: 'not run', problems: [] }, flips = [], runOk = true }) {
  const lines = [];
  if (r.missing.length || (sig && sig.missing.length)) return { code: EXIT.runFailed, label: 'RUN FAILED', lines: [`a clip was not read (${[...r.missing, ...(sig ? sig.missing : [])].join(', ')}): a missing clip is not a pass`] };
  const reduced = r.over.filter((o) => modeOf(o.id) === 'reduced'), normal = r.over.filter((o) => modeOf(o.id) !== 'reduced');
  const why = routes.status === 'failed' ? `FAILED (${routes.problems.slice(0, 3).join(' | ')})` : 'did not run';
  if (reduced.length) lines.push(`reduced, the mode players get, reads over the limit: ${reduced.map((o) => `${o.id} ${o.primary}`).join(', ')}`);
  if (normal.length && routes.status !== 'passed') lines.push(`normal reads over the limit (${normal.map((o) => `${o.id} ${o.primary}`).join(', ')}) and the exported-build route check ${why}: the lock may be reachable, so normal is a trigger on its own (RL-208, addendum 12(c))`);
  if (routes.status === 'failed' && !normal.length) lines.push(`the exported-build route check ${why}: the lock may be reachable (RL-195 condition (b))`);
  if (lines.length) return { code: EXIT.takeDown, label: 'TAKE DOWN', lines };
  if (flips.length) return { code: EXIT.switchFlipped, label: 'SWITCH FLIPPED', lines: flips.map((f) => `${f.name} is ${f.state}, reviewed as ${f.expected} (${f.row}): ${f.state === 'on' ? "its row's own clips join the batch (flash register, 3 white bursts a second, rally cap)" : 'it was reviewed ON and is off now: say so'}`) };
  if (sig && sig.worse.length) return { code: EXIT.signatureWorse, label: 'SIGNATURE WORSE', lines: [`the signature clip reads worse, reduced, than 2.5 / 3 / 2: ${sig.worse.join(', ')}`] };
  if (normal.length) return { code: EXIT.finding, label: 'FINDING', lines: [`normal mode reads over the limit: ${normal.map((o) => `${o.id} ${o.primary}`).join(', ')}; not a trigger while the route check passes (RL-208): recorded`] };
  if (!runOk) return { code: EXIT.runFailed, label: 'RUN FAILED', lines: ['the pixel run itself failed'] };
  return { code: EXIT.clean, label: 'CLEAN', lines: [] };
}

// ---- the watched switches (Legal RL-208 (2): the rows RL-177, 179, 180 and 183 apply only to content that is ON in the exported build)
const ON = 'on', OFF = 'off', ABSENT = 'absent';

function globFiles(tree, pattern) {
  const parts = pattern.split('/'), last = parts.pop();
  const dir = join(tree, ...parts);
  if (!existsSync(dir)) return [];
  const re = new RegExp(`^${last.replace(/[.+^${}()|[\]\\]/g, '\\$&').replace(/\*/g, '.*')}$`);
  return readdirSync(dir).filter((f) => re.test(f) && statSync(join(dir, f)).isFile()).map((f) => [...parts, f].join('/'));
}

/** One rule's state in an exported tree: 'on', 'off' or 'absent' (nothing of it in this tree). Rules: { flag: { file, path } } a boolean in a data file; { files: [globs] } any such file is there
 *  (on) or none is (absent); { any: [rules] } on if any is on, else off if any is off, else absent; { none: why } no switch exists in this tree yet (absent). */
export function ruleState(tree, rule) {
  if (rule.any) { const s = rule.any.map((x) => ruleState(tree, x)); return s.includes(ON) ? ON : s.includes(OFF) ? OFF : ABSENT; }
  if (rule.files) return rule.files.some((g) => globFiles(tree, g).length) ? ON : ABSENT;
  if (rule.flag) {
    let j;
    try { j = JSON.parse(readFileSync(join(tree, ...rule.flag.file.split('/')), 'utf8')); } catch { return ABSENT; }
    let v = j;
    for (const k of rule.flag.path) v = v == null ? undefined : v[k];
    return v === true ? ON : v === false ? OFF : ABSENT;
  }
  return ABSENT;
}

/** The states of every watched switch: { name: 'on' | 'off' | 'absent' }. */
export function switchStates(tree, table) { return Object.fromEntries(table.switches.map((s) => [s.name, ruleState(tree, s.rule)])); }

/** The switches that are not as Legal reviewed them: [{ name, state, expected, row }]. 'absent' counts as off. */
export function switchFlips(states, table) {
  return table.switches.filter((s) => { const st = states[s.name] || ABSENT; return s.expected === ON ? st !== ON : st === ON; }).map((s) => ({ name: s.name, state: states[s.name] || ABSENT, expected: s.expected, row: s.row }));
}

/** The build info line: the export's commit and date, then each switch's state. */
export function buildInfoLine(info, states) {
  return `build info: commit ${String((info && info.commit) || 'unknown')}, ${(info && info.date) || 'unknown date'}; switches ${Object.entries(states).map(([k, v]) => `${k} ${v}`).join(', ')}`;
}

export function loadSwitchTable(file = join(HERE, 'nightly-switches.json')) {
  const t = JSON.parse(readFileSync(file, 'utf8'));
  if (!Array.isArray(t.switches) || t.switches.some((s) => !s.name || !s.row || !['on', 'off'].includes(s.expected) || !s.rule || typeof s.rule !== 'object')) throw new Error(`${file}: every switch needs a name, a row, expected on or off, and a rule`);
  return t;
}

/** The signature clip's part of a night (Legal RL-195 condition (a)): it is read in both modes every night, and reduced is compared with 2.5 / 3 / 2. { normal, reduced, missing, worse }. Pure. */
export function signatureOf(rows) {
  const s = readSignature(rows);
  return { ...s, worse: s.reduced ? worseThan(s.reduced) : [] };
}

/** The signature clause of the report line. */
export function signatureText(sig) {
  if (!sig) return '';
  if (sig.missing.length) return `; signature NOT READ: ${sig.missing.join(', ')} (a missing clip is not a pass)`;
  return `; signature normal ${readingText(sig.normal)}, reduced ${readingText(sig.reduced)} (pin limit for reduced 2.5 / 3 / 2${sig.worse.length ? `: WORSE, ${sig.worse.join(', ')}` : ': within'})`;
}

/** The one report line. */
export function reportLine(date, commit, seeds, r, limit = TAKE_DOWN_ABOVE, sig = null) {
  const head = `nightly seeds ${date} on the pinned ${commit.slice(0, 8)}: seeds ${seeds.join(',')} x 2 modes, ${r.read} of ${r.clips} clips read`;
  if (r.missing.length) return `${head}; NOT COMPLETE: ${r.missing.join(', ')} not read (a missing clip is not a pass)${signatureText(sig)}`;
  const red = r.overReduced || r.over, nor = r.overNormal || [];
  if (red.length) return `${head}; TAKE DOWN: ${red.map((o) => `${o.id} reads ${o.primary}`).join(', ')} on the primary reading (over ${limit})${nor.length ? `; normal over too: ${nor.map((o) => o.id).join(', ')}` : ''}${signatureText(sig)}`;
  if (nor.length) return `${head}; FINDING (normal mode, not the mode players get; a trigger only if the route check fails): ${nor.map((o) => `${o.id} reads ${o.primary}`).join(', ')} on the primary reading (over ${limit})${signatureText(sig)}`;
  return `${head}; largest primary ${r.max} (${r.maxId}); none over ${limit}${signatureText(sig)}`;
}

/** The exported-build route check of a night (Legal RL-208 (1)): the PUBLIC export of the pin (lock on, capture_hook off, the measurement export's hook is not in it) is scanned for every route that could
 *  lift the Reduce flashing lock (tools/site-routes.mjs, the same scan the interim check runs, with RL-196's one grandfathered pin), then built into the site and run in a browser on a public hostname
 *  (tools/check-site-hook.mjs: no window.__flashcap, the debug words dropped). { status: 'passed' | 'failed' | 'not run', problems, notes }: 'not run' (skipped, no browser, the export or the site failed)
 *  is never a pass. */
export async function routeCheck(o) {
  const notes = [];
  if (o.skip) return { status: 'not run', problems: [], notes: ['skipped (--no-route-check)'] };
  const tree = join(o.work, 'public-tree'), web = join(o.work, 'public-web'), site = join(o.work, 'public-site');
  try {
    if (!existsSync(join(web, 'index.html'))) exportPinned(o.pin, web, { tree, godot: o.godot, lock: true, hook: false });
  } catch (e) { return { status: 'not run', problems: [], notes: [`the public export failed: ${e.message}`] }; }
  let problems = scanRoutes(tree);
  let gf = null;
  try { gf = JSON.parse(readFileSync(join(HERE, '..', 'site-routes-grandfather.json'), 'utf8')); } catch { /* none */ }
  if (problems.length && gf && gf.commit === o.pin) { notes.push(`${problems.length} open route${problems.length === 1 ? '' : 's'} on this pin, which ${gf.ruling} lets stay up while the fix lands (tools/site-routes-grandfather.json)`); problems = []; }
  if (problems.length) return { status: 'failed', problems, notes };
  if (o.skipHook) return { status: 'not run', problems: [], notes: [...notes, 'the static scan is clean; the browser half was skipped (--no-hook-check)'] };
  const b = spawnSync(process.execPath, [join(HERE, '..', 'build-site.mjs'), '--web', web, '--out', site, '--commit', o.pin], { encoding: 'utf8' });
  if (b.status !== 0) return { status: 'not run', problems: [], notes: [...notes, `the site could not be built to run the hook check: ${String(b.stderr || b.stdout).trim().split('\n').slice(-2).join(' ')}`] };
  try {
    const { checkHook } = await import('../check-site-hook.mjs');
    const h = await checkHook({ site, software: true, timeoutS: 420, session: process.env.MERIDIAN_SESSION || 'tools' });
    notes.push(...(h.notes || []));
    return h.ok ? { status: 'passed', problems: [], notes } : { status: 'failed', problems: h.problems, notes };
  } catch (e) { return { status: 'not run', problems: [], notes: [...notes, `the hook check could not run: ${e.message}`] }; }
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const args = process.argv.slice(2);
  const opt = (n, d) => { const i = args.indexOf(n); return i >= 0 ? args[i + 1] : d; };
  const count = Number(opt('--count', 8));
  const base = Number(opt('--base', 1000));
  const jobs = opt('--jobs', '3');
  const cap = opt('--cpu-cap', '25');
  const RUN_PIXELS = resolve(opt('--run-pixels', join(HERE, 'run-pixels.mjs')));   // the self-test passes a stand-in for the two browser runs
  const date = new Date().toISOString().slice(0, 10);
  // the pinned commit: tools/site-pin.mjs (the recorded one), or --pin <sha> (a test or a recorded run not yet flipped online)
  let config = {};
  try { config = JSON.parse(readFileSync(join(HERE, '..', 'site.json'), 'utf8')); } catch { /* no config: the default limit */ }
  // --pin <sha> works while the site is offline: the export is made from that commit directly (not through site.json, which has no pin to give when offline) and the limit comes from the
  // interim's record (tools/site-interim-owner.json), not from site.json
  let words = null;
  try { words = JSON.parse(readFileSync(resolve(opt('--record', join(HERE, '..', 'site-interim-owner.json'))), 'utf8')); } catch { /* no record: the stricter limit */ }
  const pinRun = opt('--pin') ? { status: 0, stdout: opt('--pin'), stderr: '' } : spawnSync(process.execPath, [join(HERE, '..', 'site-pin.mjs')], { encoding: 'utf8' });
  const pin = (pinRun.stdout || '').trim();
  if (pinRun.status !== 0 || !/^[0-9a-f]{40}$/.test(pin)) { console.error(`nightly seeds: no pinned commit (the site is offline, or the pass file has no usable record): ${(pinRun.stderr || '').trim()}`); process.exit(2); }
  const work = resolve(opt('--work', join(tmpdir(), 'nightly-seeds')), pin.slice(0, 7));
  const web = join(work, 'web');
  const src = JSON.parse(readFileSync(join(HERE, 'sources.json'), 'utf8'));
  const recorded = new Set((src.pairings || []).flatMap((p) => p.seeds || []));
  const HISTORY = resolve(opt('--history', DEFAULT_HISTORY));
  const hist = existsSync(HISTORY) ? JSON.parse(readFileSync(HISTORY, 'utf8')) : { _why: 'The nightly seed run of the interim (tools/flash/nightly-seeds.mjs): one row a night, the seeds read, so none is read twice.', runs: [] };
  const used = hist.runs.flatMap((r) => r.seeds);
  const seeds = nextSeeds(count, base, recorded, used);
  console.log(`nightly seeds: pinned ${pin.slice(0, 8)}, seeds ${seeds.join(',')}`);
  if (args.includes('--dry-run')) process.exit(0);
  mkdirSync(work, { recursive: true });
  if (!existsSync(join(web, 'index.html')) && !args.includes('--no-export')) {
    if (opt('--pin')) {
      try {
        const tree = exportPinned(pin, web, { tree: join(work, 'tree'), godot: opt('--godot') || process.env.GODOT, lock: true, hook: true });   // lock: the interim's export, as the site would serve it; hook: the measurement export (capture_hook true, Legal RL-196), never the one deployed
        console.log(`pinned ${pin.slice(0, 8)} exported to ${web} (tree ${tree})`);
      } catch (e) { console.error(`nightly seeds: the pinned export failed (is $GODOT set?): ${e.message}`); process.exit(2); }
    } else {
      const ex = spawnSync(process.execPath, [join(HERE, '..', 'site-pin.mjs'), '--export', web, '--tree', join(work, 'tree'), '--hook'], { stdio: 'inherit', env: process.env });
      if (ex.status !== 0) { console.error('nightly seeds: the pinned export failed (is $GODOT set?)'); process.exit(2); }
    }
  }
  // the build info of the pinned export: its commit and date, and the state of every watched switch in ITS data (Legal RL-208 (2))
  const table = loadSwitchTable();
  const treeDir = join(work, 'tree');
  let info = null;
  try { info = JSON.parse(readFileSync(join(treeDir, 'build_info.json'), 'utf8')); } catch { /* an export without its tree: states are unknown */ }
  const treeKnown = existsSync(join(treeDir, 'data'));
  const states = treeKnown ? switchStates(treeDir, table) : Object.fromEntries(table.switches.map((s) => [s.name, 'unknown']));
  const flips = treeKnown ? switchFlips(states, table) : [];
  console.log(buildInfoLine(info, states));
  const out = join(work, date);
  const rp = spawnSync(process.execPath, [RUN_PIXELS, '--dir', web, '--path', '/index.html?flashcap=1', '--out', join(out, 'clips'), '--jobs', jobs, '--cpu-cap', cap, '--seeds', seeds.join(',')], { stdio: 'inherit', env: { ...process.env, MERIDIAN_SESSION: process.env.MERIDIAN_SESSION || 'tools' } });
  let rows = [];
  try { rows = JSON.parse(readFileSync(join(out, 'clips', 'summary.json'), 'utf8')); } catch { /* reported as missing */ }
  // the signature clip, both modes, every night (Legal RL-195 condition (a)): on the same pinned export, a second run of the guarded launcher
  const rps = spawnSync(process.execPath, [RUN_PIXELS, '--dir', web, '--path', '/index.html?flashcap=1', '--out', join(out, 'clips-signature'), '--jobs', String(Math.min(2, Number(jobs))), '--cpu-cap', cap, '--clip', 'signature-normal,signature-reduced'], { stdio: 'inherit', env: { ...process.env, MERIDIAN_SESSION: process.env.MERIDIAN_SESSION || 'tools' } });
  let sigRows = [];
  try { sigRows = JSON.parse(readFileSync(join(out, 'clips-signature', 'summary.json'), 'utf8')); } catch { /* reported as not read */ }
  const sig = signatureOf(sigRows);
  // 3.5 under the owner-approved interim (Legal's addendum 11); the record gives it when the site is offline or a pin was given, the live site.json when the interim is online
  const limit = opt('--pin') || config.offline === true || !config.interim ? limitFromRecord(words) : limitFor(config);
  const r = readRun(rows, seeds, limit);
  const routes = await routeCheck({ pin, work, godot: opt('--godot') || process.env.GODOT, skip: args.includes('--no-route-check'), skipHook: args.includes('--no-hook-check') });
  const runOk = rp.status === 0 || rp.status === 1;
  const v = verdictOf({ r, sig, routes, flips, runOk });
  const line = reportLine(date, pin, seeds, r, limit, sig);
  console.log(line);
  console.log(`route check: ${routes.status}${routes.problems.length ? ` (${routes.problems.slice(0, 3).join(' | ')})` : ''}${routes.notes.length ? `; ${routes.notes.join('; ')}` : ''}`);
  console.log(`switches: ${Object.entries(states).map(([k, s]) => `${k} ${s}`).join(', ')}${flips.length ? `; NOT AS REVIEWED: ${flips.map((x) => `${x.name} (${x.row})`).join(', ')}` : '; as reviewed'}`);
  console.log(`verdict: ${v.label} (exit ${v.code})${v.lines.length ? `: ${v.lines.join('; ')}` : ''}`);
  hist.runs.push({ date, commit: pin, seeds, read: r.read, clips: r.clips, max: r.max, maxClip: r.maxId, over: r.over, missing: r.missing, signature: { normal: sig.normal, reduced: sig.reduced, missing: sig.missing, worse: sig.worse }, switches: states, routes: { status: routes.status, problems: routes.problems, notes: routes.notes }, verdict: { code: v.code, label: v.label } });
  writeFileSync(HISTORY, JSON.stringify(hist, null, 2) + '\n');
  writeFileSync(join(out, 'report.txt'), [buildInfoLine(info, states), line, `verdict: ${v.label} (exit ${v.code})${v.lines.length ? `: ${v.lines.join('; ')}` : ''}`].join('\n') + '\n');
  // exit codes (Legal RL-208): 0 clean, 1 take-down (a REDUCED clip over the limit, or a normal one while the route check failed or did not run), 2 a clip was not read, 3 the signature clip reads worse,
  // reduced, than 2.5 / 3 / 2, 4 finding (a NORMAL clip over the limit, route check passed), 5 a watched switch is not as reviewed
  void rps;
  process.exit(v.code);
}
