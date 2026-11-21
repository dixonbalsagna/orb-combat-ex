// Self-test of the flash count's split (the EP, 2026-11-21): the five sets of ci.yml's `flash-cases` matrix, written the way flash_worst.gd writes them, merged the way the `flash` job merges them
// (one folder, merge-multiple), and recounted as one by tools/flash/check-log.js. No Godot: the run files are synthetic, one per file name the real tool would write, each with the events its
// scenario exists to show. It proves the PARTITION (every scenario and every pairing seed in exactly one set, no file name written by two sets, the recount of the union passing, and the recount
// of the union without any one set failing), not the sim: whether a scene still shows its events on HEAD is what the real run says (run 44885894433 failed on that, not on the merge).
//   node tools/flash/split-merge-selftest.mjs
// The naming below is a copy of flash_worst.gd's `_run` (label from the slots, a seed suffix when the entry has more than one seed): if that changes, this changes with it.
import { spawnSync } from 'node:child_process';
import { mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, '..', '..');
const read = (f) => readFileSync(join(root, f), 'utf8').replace(/\r\n/g, '\n');
let bad = 0, n = 0;
const check = (name, ok, why = '') => { n++; if (!ok) { bad++; console.log(`FAIL  ${name}${why ? ': ' + why : ''}`); } else console.log(`ok    ${name}`); };

const ci = read('.github/workflows/ci.yml');
const sources = JSON.parse(read('tools/flash/sources.json'));
const roster = JSON.parse(read('data/fighters/roster.json'));

// ---- the matrix, from ci.yml
const jobText = (id) => { const m = ci.match(new RegExp(`\\n  ${id}:\\n[\\s\\S]*?(?=\\n  [A-Za-z0-9_-]+:\\n|$)`)); return m ? m[0] : ''; };
const cases = jobText('flash-cases');
const sets = [...cases.matchAll(/- \{ set: ([\w-]+), args: '([^']*)' \}/g)].map((m) => ({ set: m[1], args: m[2].trim().split(/\s+/) }));
check('flash-cases has a matrix of sets', sets.length >= 2, String(sets.length));
check('the sets have distinct names', new Set(sets.map((s) => s.set)).size === sets.length);
check('flash-cases uploads one artifact a set, named flash-run-<set>', /name: flash-run-\$\{\{ matrix\.set \}\}/.test(cases));
const merge = jobText('flash');
check('flash needs flash-cases, downloads flash-run-* merged into one folder, and recounts that folder', /needs: flash-cases/.test(merge) && /pattern: flash-run-\*/.test(merge) && /merge-multiple: true/.test(merge) && /check-log\.js "\$\{RUNNER_TEMP\}\/flash"/.test(merge) && /path: \$\{\{ runner\.temp \}\}\/flash/.test(merge));
check('every set writes its run files to the folder the upload reads', /--out="\$\{RUNNER_TEMP\}\/flash"/.test(cases) && /path: \$\{\{ runner\.temp \}\}\/flash\n/.test(cases));
const deploy = jobText('deploy');
check('deploy needs flash and flash-selftests', /needs: \[[^\]]*\bflash-selftests\b[^\]]*\]/.test(deploy) && /needs: \[[^\]]*\bflash\b[^\]]*\]/.test(deploy));

// ---- the file names a set writes (flash_worst.gd `_run`), and a run file for each
const opt = (args, name) => { const a = args.find((x) => x.startsWith(name + '=')); return a ? a.slice(name.length + 1).split(',') : []; };
function runsOf(args) {
  const only = opt(args, '--only'), slotsOverride = opt(args, '--slots'), seedOverride = opt(args, '--seeds').map(Number);
  const out = [];
  for (const sd of sources.scenarios) {
    if (only.length && !only.includes(sd.id)) continue;
    let runs;
    if (sd.pairings) runs = sources.pairings.map((p) => ({ slots: p.slots, seeds: p.seeds, need: p.needSignatures }));
    else if (sd.slotsList) runs = sd.slotsList.map((sl) => ({ slots: sl, seeds: [12345] }));
    else runs = [{ slots: [], seeds: [12345] }];
    if (slotsOverride.length) runs = [{ slots: slotsOverride, seeds: runs[0].seeds, need: (sources.pairings.find((p) => p.slots.join() === slotsOverride.join()) || {}).needSignatures }];
    for (const r of runs) {
      const defaultPair = r.slots.length === 0 || (r.slots.length === 2 && r.slots[0] === roster[0] && r.slots[1] === roster[1]);
      const label = defaultPair ? '' : '-' + r.slots.join('-');
      const seeds = seedOverride.length ? seedOverride : r.seeds;
      for (const seed of seeds) for (const reduced of [false, true]) {
        const name = `flash-${sd.id}-${reduced ? 'reduced' : 'normal'}${label}${r.seeds.length === 1 ? '' : '-' + seed}.json`;
        const events = { damage: 500, ...(sd.minEvents || {}) };
        for (const [k, v] of Object.entries(events)) events[k] = Math.max(v, 1) * 2;
        for (const id of r.need || []) events['sig:' + id] = 1;
        out.push({ name, run: { scenario: sd.id, seed, reduced, ticks: sd.ticks, slots: defaultPair ? [] : r.slots, asked: 1, rows: [[10, 0, 'body_hit', true, 'ok']], summary: { granted: 1, worst_second: 1, worst_weight: 1 }, events, reduce_flashing: reduced, flash_calm: reduced, reduced_seen: reduced } });
      }
    }
  }
  return out;
}
// the default pair (the roster's first two fighters) is handed to `_play` as [], and the run file records the slots it played: the pair, so an `ai` run of the default pair records it
const fixSlots = (r) => { if (r.run.scenario === 'ai' && !r.run.slots.length) r.run.slots = [roster[0], roster[1]]; return r; };

const dir = mkdtempSync(join(tmpdir(), 'flash-split-'));
try {
  const perSet = sets.map((s) => ({ ...s, files: runsOf(s.args).map(fixSlots) }));
  const owner = new Map();
  let collide = [];
  for (const s of perSet) for (const f of s.files) { if (owner.has(f.name)) collide.push(`${f.name} (${owner.get(f.name)} and ${s.set})`); owner.set(f.name, s.set); }
  check('no file name is written by two sets (a merge would silently overwrite one)', collide.length === 0, collide.slice(0, 4).join('; '));
  // what the one-job run (no --only) would write
  const whole = runsOf([]).map((f) => f.name).sort();
  const union = [...owner.keys()].sort();
  check('the sets together write exactly the files the one-job run writes', JSON.stringify(whole) === JSON.stringify(union), `one job ${whole.length}, sets ${union.length}`);
  check('every set writes at least one run', perSet.every((s) => s.files.length > 0));

  const write = (d, files) => { mkdirSync(d, { recursive: true }); for (const f of files) writeFileSync(join(d, f.name), JSON.stringify(f.run)); };
  const recount = (d) => spawnSync(process.execPath, [join(here, 'check-log.js'), d], { encoding: 'utf8' });
  // the five sets, each in its own folder (an artifact), merged into one (merge-multiple)
  for (const s of perSet) write(join(dir, 'artifact-' + s.set), s.files);
  const merged = join(dir, 'merged');
  for (const s of perSet) write(merged, s.files);
  const all = recount(merged);
  check('the merged recount passes (every scenario of the required set, every pairing seed, both modes)', all.status === 0, (all.stdout.match(/PROBLEM[^\n]*/g) || [all.stdout.slice(-200)]).slice(0, 3).join(' | '));
  // one set short: the recount must fail and name something missing
  for (const s of perSet) {
    const d = join(dir, 'without-' + s.set);
    for (const t of perSet) if (t.set !== s.set) write(d, t.files);
    const r = recount(d);
    check(`the recount fails without set ${s.set}`, r.status === 1 && /is missing|never show/.test(r.stdout));
  }
  // a scene that does not show its events fails the recount, as run 44885894433 did
  const weak = perSet.flatMap((s) => s.files).map((f) => (f.run.scenario === 'mashdummy' ? { ...f, run: { ...f.run, events: { ...f.run.events, launch: 0 } } } : f));
  const dw = join(dir, 'weak');
  write(dw, weak);
  const rw = recount(dw);
  check('a mashdummy that never launches fails the recount, naming the launch', rw.status === 1 && /scenario mashdummy seed 12345 \((normal|reduced)\) did not show launch/.test(rw.stdout));
} finally { rmSync(dir, { recursive: true, force: true }); }
console.log(`${n - bad} of ${n} checks passed`);
process.exit(bad ? 1 : 0);
