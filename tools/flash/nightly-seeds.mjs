// The interim's nightly seed run (Legal, RL-137): while the playable build is up under an interim, a few NEW AI seeds are captured each night in both modes against the PINNED build,
// reading only the primary reading, and any clip over 3 on it is the take-down trigger (RL-136 item 3). Run by hand or by the machine's own scheduler; no CI cost.
//
//   node tools/flash/nightly-seeds.mjs [--count 8] [--base 1000] [--jobs 3] [--cpu-cap 25] [--work <dir>] [--history <file>] [--pin <sha>] [--dry-run] [--no-export]
//
// What it does, in order:
//   1. the pinned commit (tools/site-pin.mjs: the commit the pass file recorded) and its Web export, kept in <work>/<sha7>/web (exported once, then reused);
//   2. the night's seeds: the next --count integers from --base that are in neither the recorded set (tools/flash/sources.json) nor the history (tools/flash/nightly-seeds.json), so no seed
//      is read twice and the set never repeats; the pick is deterministic (the history is the only state);
//   3. tools/flash/run-pixels.mjs --seeds <those> in both modes through the guarded launcher (below-normal, the cap, a time limit), three at a time;
//   3b. the `signature` clip in both modes on the same export (Legal RL-195 condition (a)), every night, with its three readings (primary / area-15% / two-second memory) in the line and the row;
//   4. ONE report line, and an appended row in the history: the commit, the seeds, the largest primary reading and the clip, the clips over 3. Exit 0 when none is over 3, exit 1 when any is
//      (the take-down trigger: node tools/site-offline.mjs and tell the EP), exit 2 when the run itself failed (a clip missing is not a pass, the signature clip included), exit 3 when the signature clip reads, reduced, worse than 2.5 / 3 / 2 (Legal RL-195: tell the EP; not a take-down by itself).
// Only the primary reading is read here (Legal: "reading only the primary"); the full table of a run stays in <work>/<sha7>/<date>/clips (margins.mjs reads it if a clip is over).
// About 8 seeds x 2 modes x 15 minutes / 3 jobs: roughly 80 minutes, then the export once (about 3 minutes).
import { spawnSync } from 'node:child_process';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { exportPinned } from '../site-pin.mjs';
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
  return { clips: want.length, read: want.length - missing.length, missing, max, maxId, over };
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
  if (r.over.length) return `${head}; TAKE DOWN: ${r.over.map((o) => `${o.id} reads ${o.primary}`).join(', ')} on the primary reading (over ${limit})${signatureText(sig)}`;
  return `${head}; largest primary ${r.max} (${r.maxId}); none over ${limit}${signatureText(sig)}`;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const args = process.argv.slice(2);
  const opt = (n, d) => { const i = args.indexOf(n); return i >= 0 ? args[i + 1] : d; };
  const count = Number(opt('--count', 8));
  const base = Number(opt('--base', 1000));
  const jobs = opt('--jobs', '3');
  const cap = opt('--cpu-cap', '25');
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
  const out = join(work, date);
  const rp = spawnSync(process.execPath, [join(HERE, 'run-pixels.mjs'), '--dir', web, '--path', '/index.html?flashcap=1', '--out', join(out, 'clips'), '--jobs', jobs, '--cpu-cap', cap, '--seeds', seeds.join(',')], { stdio: 'inherit', env: { ...process.env, MERIDIAN_SESSION: process.env.MERIDIAN_SESSION || 'tools' } });
  let rows = [];
  try { rows = JSON.parse(readFileSync(join(out, 'clips', 'summary.json'), 'utf8')); } catch { /* reported as missing */ }
  // the signature clip, both modes, every night (Legal RL-195 condition (a)): on the same pinned export, a second run of the guarded launcher
  const rps = spawnSync(process.execPath, [join(HERE, 'run-pixels.mjs'), '--dir', web, '--path', '/index.html?flashcap=1', '--out', join(out, 'clips-signature'), '--jobs', '2', '--cpu-cap', cap, '--clip', 'signature-normal,signature-reduced'], { stdio: 'inherit', env: { ...process.env, MERIDIAN_SESSION: process.env.MERIDIAN_SESSION || 'tools' } });
  let sigRows = [];
  try { sigRows = JSON.parse(readFileSync(join(out, 'clips-signature', 'summary.json'), 'utf8')); } catch { /* reported as not read */ }
  const sig = signatureOf(sigRows);
  // 3.5 under the owner-approved interim (Legal's addendum 11); the record gives it when the site is offline or a pin was given, the live site.json when the interim is online
  const limit = opt('--pin') || config.offline === true || !config.interim ? limitFromRecord(words) : limitFor(config);
  const r = readRun(rows, seeds, limit);
  const line = reportLine(date, pin, seeds, r, limit, sig);
  console.log(line);
  hist.runs.push({ date, commit: pin, seeds, read: r.read, clips: r.clips, max: r.max, maxClip: r.maxId, over: r.over, missing: r.missing, signature: { normal: sig.normal, reduced: sig.reduced, missing: sig.missing, worse: sig.worse } });
  writeFileSync(HISTORY, JSON.stringify(hist, null, 2) + '\n');
  writeFileSync(join(out, 'report.txt'), line + '\n');
  // 2: a clip (a seed's or the signature clip) was not read; 1: the take-down trigger; 3: the signature clip reads worse, reduced, than the pin condition (2.5 / 3 / 2): not a take-down by itself, tell the EP
  void rps;
  process.exit(r.missing.length || sig.missing.length ? 2 : r.over.length ? 1 : sig.worse.length ? 3 : (rp.status === 0 || rp.status === 1 ? 0 : 2));
}
