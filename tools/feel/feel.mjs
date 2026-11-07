// Feel replays (docs/tools/feel.md): plays one of Orb's saved matches with a candidate rule swapped in, forking at each press of interest, and prints a before/after table.
//   node tools/feel/feel.mjs <saved match.json> --switch quickRead[=false] | --override <file:dotted.path=json> ... [--overrides-file f.json] [--tree <tree folder>] [--window 240] [--interest rsStart,sig,special] [--max-forks 120] [--no-fork] [--no-whole] [--json out.json] [--godot exe]
// Counts, for slot 0 (the pad): beams fired, refusals by reason, side swaps, seconds without control, hits and clean hits (a hit with none taken in the 30 ticks before). Two tables:
//   FORKED  at every press of interest, the next `window` ticks played from the recorded inputs with the rule on, against the same ticks of Orb's real match (the baseline);
//   WHOLE   the match replayed from the first tick with the rule on, against the baseline (open loop: it drifts from what Orb pressed, so read it as a rough run, the forks as the fair one).
// An override of data/input/timing.json or data/director/interrupts.json is applied in memory and can fork. Any other data file is patched into a scratch copy of the tree and runs WHOLE only.
import { writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';
import { readMatch, treeFor, workCopy, runGd, parseOverride, parseSwitch, overridesFromFile, patchTree, SUPPORTED_FILES } from './lib.mjs';

export const METRICS = [['beams', 'beams fired'], ['foeBeams', "his beams fired"], ['driverFires', 'driver fires'], ['refused', 'presses refused'], ['hits', 'hits landed'], ['cleanHits', 'clean hits'], ['hitsTaken', 'hits taken'], ['noControl', 'seconds without control'], ['swaps', 'side swaps']];

const secs = (k, v) => (k === 'noControl' ? Math.round((v / 60) * 10) / 10 : v);
const fmt = (n) => (Number.isInteger(n) ? String(n) : n.toFixed(1));
const sgn = (n) => (n > 0 ? '+' + fmt(n) : fmt(n));

/** A before/after table of two metric objects. */
export function table(title, base, cand) {
  const keys = [...METRICS.map((m) => m[0])];
  const reasons = [...new Set([...Object.keys(base), ...Object.keys(cand)].filter((k) => k.startsWith('refused:')))].sort();
  const rows = [];
  for (const [k, label] of METRICS) rows.push([label, secs(k, base[k] || 0), secs(k, cand[k] || 0)]);
  for (const r of reasons) rows.push(['  ' + r.slice(8), base[r] || 0, cand[r] || 0]);
  const w = Math.max(...rows.map((r) => r[0].length), 10);
  const out = [title, `${'metric'.padEnd(w)}  before  after  change`];
  for (const [label, b, c] of rows) out.push(`${label.padEnd(w)}  ${String(fmt(b)).padStart(6)}  ${String(fmt(c)).padStart(5)}  ${sgn(c - b).padStart(6)}`);
  return out.join('\n');
}

/** Counts how the forked presses changed: per row, beams fired / refused before and after. */
export function pressChanges(rows) {
  const c = { presses: rows.length, refusedToFired: 0, firedToRefused: 0, moreBeams: 0, fewerBeams: 0, fewerRefusals: 0, moreRefusals: 0 };
  for (const r of rows) {
    const bb = r.base.beams || 0, cb = r.cand.beams || 0, br = r.base.refused || 0, cr = r.cand.refused || 0;
    if (cb > bb) c.moreBeams++; else if (cb < bb) c.fewerBeams++;
    if (cr < br) c.fewerRefusals++; else if (cr > br) c.moreRefusals++;
    if (br > 0 && bb === 0 && cb > 0) c.refusedToFired++;
    if (bb > 0 && cb === 0 && cr > 0) c.firedToRefused++;
  }
  return c;
}

export async function feelReplay({ match, tree, overrides, window = 240, interest = 'rsStart,sig,special', maxForks = 120, fork = true, whole = true, slot, godot, limitMs }) {
  const { doc } = readMatch(match);
  const base = treeFor(doc, tree);
  const supported = overrides.every((o) => SUPPORTED_FILES.includes(o.file));
  const work = workCopy(base);
  const gdArgs = (extra) => [resolve(match), '--mode=replay', ...(slot !== undefined ? [`--slot=${slot}`] : []), `--window=${window}`, `--interest=${interest}`, `--max-forks=${maxForks}`, ...extra];
  const res = { match, tree: base, overrides, supported, window, interest };
  if (supported) {
    const ovf = resolve(work, '..', `feel-overrides-${process.pid}.json`);
    writeFileSync(ovf, JSON.stringify(overrides));
    const r = await runGd(work, gdArgs([`--overrides=${ovf}`, ...(fork ? [] : ['--no-fork']), ...(whole ? [] : ['--no-whole'])]), { godot, limitMs });
    if (!r.line) throw new Error('the replay gave no result:\n' + r.text.split(/\r?\n/).slice(-12).join('\n'));
    Object.assign(res, r.line);
  } else {
    // other data files: a patched scratch copy, the whole match only
    const cand = workCopy(base, '-cand-' + Buffer.from(JSON.stringify(overrides)).toString('base64').replace(/[^A-Za-z0-9]/g, '').slice(0, 12));
    patchTree(cand, overrides);
    const rb = await runGd(work, gdArgs(['--no-fork']), { godot, limitMs });
    const rc = await runGd(cand, gdArgs(['--no-fork']), { godot, limitMs });
    if (!rb.line || !rc.line) throw new Error('the replay gave no result:\n' + (rb.line ? rc : rb).text.split(/\r?\n/).slice(-12).join('\n'));
    Object.assign(res, rb.line);
    res.candidateWhole = rc.line.baselineWhole;
    res.candidateFinal = rc.line.recorded.got;
  }
  return res;
}

export function report(res) {
  const out = [];
  out.push(`match ${res.match} on ${res.tree} (the pad is slot ${res.slot})`);
  out.push(`recorded match: ${!res.recorded.checked ? 'cut short, so it saved no final hash to compare; the baseline is the replay of it on this tree' : res.recorded.exact ? 'REPRODUCED exactly (the final hash is the saved one)' : 'NOT reproduced on this tree (got ' + res.recorded.got + ', saved ' + res.recorded.final + '): the baseline is the replay on this tree, not the match as played'}`);
  out.push(`rule: ${res.overrides.map((o) => `${o.file}:${o.path.join('.')}=${JSON.stringify(o.value)}`).join('; ') || '(none)'}`);
  if (res.forks && res.forks.count) {
    out.push('');
    out.push(table(`FORKED: ${res.forks.count} presses (${res.interest.join ? res.interest.join(',') : res.interest}), ${res.window} ticks each`, res.forks.baseline, res.forks.candidate));
    const pc = pressChanges(res.forks.rows);
    out.push(`  presses: ${pc.refusedToFired} refused before and fired after, ${pc.firedToRefused} fired before and refused after; beams up in ${pc.moreBeams}, down in ${pc.fewerBeams}; refusals down in ${pc.fewerRefusals}, up in ${pc.moreRefusals}`);
  } else if (res.supported === false) out.push('\n(no forks: this rule edits a data file the forks cannot swap in memory; the whole match runs on a patched copy)');
  if (res.candidateWhole) {
    out.push('');
    out.push(table('WHOLE MATCH (open loop)', res.baselineWhole, res.candidateWhole));
    out.push(`  final state: ${res.candidateFinal === res.recorded.got ? 'identical to the baseline (the rule changed nothing in this match)' : 'differs from the baseline'}`);
  }
  const same = (a, b) => JSON.stringify(Object.entries(a || {}).sort()) === JSON.stringify(Object.entries(b || {}).sort());
  const nothing = (!res.forks || !res.forks.count || same(res.forks.baseline, res.forks.candidate)) && (!res.candidateWhole || res.candidateFinal === res.recorded.got);
  if (nothing && res.overrides.length) out.push('\nNOTHING CHANGED. Either the rule does not act on these presses, or it lives in the input hub (the layer that turns the pad into intents): a replay feeds the recorded intents straight to the sim and skips the hub, so a hub rule such as quickRead cannot show here. Test those with the scheme gauntlet (tools/feel/gauntlet.mjs), which plays a scripted pad through the hub.');
  return out.join('\n');
}

async function main() {
  const argv = process.argv.slice(2);
  const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
  const all = (n) => argv.flatMap((a, i) => (a === n && argv[i + 1] ? [argv[i + 1]] : []));
  const flagsWithValue = new Set(['--slot', '--switch', '--override', '--overrides-file', '--tree', '--window', '--interest', '--max-forks', '--json', '--godot']);
  const match = argv.find((a, i) => !a.startsWith('--') && !flagsWithValue.has(argv[i - 1]));
  if (!match) { console.error('usage: node tools/feel/feel.mjs <saved match.json> --switch name | --override file:path=value [--tree <folder>] [--window 240] [--interest rsStart,sig,special] [--no-fork] [--no-whole] [--json out.json]'); process.exit(2); }
  const overrides = [...all('--switch').map(parseSwitch), ...all('--override').map(parseOverride), ...(opt('--overrides-file') ? overridesFromFile(opt('--overrides-file')) : [])];
  const res = await feelReplay({ match, tree: opt('--tree'), overrides, window: Number(opt('--window', 240)), interest: opt('--interest', 'rsStart,sig,special'), maxForks: Number(opt('--max-forks', 120)), slot: opt('--slot') !== undefined ? Number(opt('--slot')) : undefined, fork: !argv.includes('--no-fork'), whole: !argv.includes('--no-whole'), godot: opt('--godot') });
  console.log(report(res));
  if (opt('--json')) writeFileSync(opt('--json'), JSON.stringify(res, null, 1));
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) main().catch((e) => { console.error('[feel] FAILED: ' + e.message); process.exit(1); });
