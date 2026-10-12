// Picks the AI seeds of a release pass (Legal's RL-131, answers 2 and 3): 20 in all, deterministic, recorded. Reads seed_scan.gd's output for each pairing and the history of
// earlier releases; prints the pick, the rule's reasons and any rule it could not meet.
//
//   godot --headless --path . --script res://tools/flash/seed_scan.gd -- --from=1 --to=120 --slots=PROTAGONIST,RIVAL > scan.txt
//   node tools/flash/pick-seeds.mjs --scan PROTAGONIST,RIVAL=scan.txt [--scan A,B=other.txt ...] [--total 20] [--previous tools/flash/release-pass.json]
//                                   [--history tools/flash/seed-history.json] [--out pick.json] [--write]
//
// The rule (all of it deterministic: the same inputs give the same pick):
//   1. kept first: every seed that FAILED in an earlier candidate (the history's `failed`, until its cause is fixed and recorded) and the FIVE WORST seeds of the previous release
//      (by the worse of their readings, either mode);
//   2. pairings: with more pairings than seeds, the pairings captured longest ago (or never: "uncaptured first") are taken, at least one seed each; otherwise the seeds are shared
//      out evenly, the uncaptured first getting the remainder. (A pairing new in a release is captured at least 3 times: it gets at least 3 seeds.)
//   3. fill by the scan: seeds that show BOTH signatures first, then variety (beam outcomes, building falls, transformations, shots), then the lower seed number;
//   4. coverage: every signature appears in at least 2 of the pairing's matches and every fighter in at least 5 matches over the pick; what cannot be met is a warning.
// --write puts the pick into tools/flash/sources.json (pairings[].seeds), in the order of the pick.
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
export const MIN_SIGNATURES = 2;
export const MIN_MATCHES_PER_FIGHTER = 5;
export const NEW_PAIRING_MIN = 3;
export const WORST_KEPT = 5;

/** The rows of seed_scan.gd's output: { seed, sig: { FIGHTER: count }, beams: { KIND: count }, ev: { building_fall, shot_hit, transform } }. */
export function parseScan(text) {
  const rows = [];
  for (const l of text.split('\n')) {
    const m = /^seed\s+(\d+): (\d+) ticks sig (\{.*?\}) beams (\{.*?\}) (\{.*\})/.exec(l.trim());
    if (m) rows.push({ seed: Number(m[1]), sig: JSON.parse(m[3]), beams: JSON.parse(m[4]), ev: JSON.parse(m[5]) });
  }
  return rows;
}

const variety = (r) => Object.keys(r.beams).length * 3 + (r.ev.building_fall > 0 ? 2 : 0) + (r.ev.transform >= 4 ? 1 : 0) + Math.min(3, (r.ev.shot_hit || 0) / 4);

/**
 * input: { pairings: [{ key: "A,B", slots: ["A","B"], scan: rows }], total, failed: [{ pairing, seed }], worst: [{ pairing, seed }], coverage: { key: "date" | null } }
 * returns: { rule, seeds: { key: [seed...] }, kept: { worst: [...], failed: [...] }, why: [string], warnings: [string] }
 */
export function pickSeeds(input) {
  const total = input.total || 20;
  const coverage = input.coverage || {};
  const why = [], warnings = [];
  const P = input.pairings;
  // pairings in the order the rolling cycle wants them: uncaptured first, then the longest ago, then by key
  const order = [...P].sort((a, b) => {
    const ca = coverage[a.key] || '', cb = coverage[b.key] || '';
    return ca < cb ? -1 : ca > cb ? 1 : a.key < b.key ? -1 : a.key > b.key ? 1 : 0;
  });
  const chosen = order.slice(0, Math.min(order.length, total));
  const seedsOf = {};
  const base = Math.floor(total / chosen.length);
  let extra = total - base * chosen.length;
  const quota = {};
  for (const p of chosen) { quota[p.key] = base + (extra > 0 ? 1 : 0); if (extra > 0) extra--; }
  for (const p of chosen) {
    const isNew = !coverage[p.key] && P.length > 1 && Object.keys(coverage).length > 0;
    if (isNew && quota[p.key] < NEW_PAIRING_MIN) quota[p.key] = NEW_PAIRING_MIN;
  }
  if (order.length > chosen.length) why.push(`${order.length - chosen.length} pairing${order.length - chosen.length === 1 ? '' : 's'} wait for a later release (the cycle takes the uncaptured and the longest ago first)`);
  const keptWorst = [], keptFailed = [];
  for (const p of chosen) {
    const have = new Set(p.scan.map((r) => r.seed));
    const out = [];
    const push = (s, reason) => { if (!out.includes(s)) { out.push(s); why.push(`${p.key}: seed ${s} (${reason})`); } };
    for (const f of (input.failed || []).filter((x) => x.pairing === p.key).map((x) => x.seed).sort((a, b) => a - b)) { push(f, 'failed in an earlier candidate: kept until its cause is fixed and recorded'); keptFailed.push({ pairing: p.key, seed: f }); }
    for (const w of (input.worst || []).filter((x) => x.pairing === p.key).slice(0, WORST_KEPT)) { push(w.seed, 'one of the five worst of the previous release'); keptWorst.push({ pairing: p.key, seed: w.seed }); }
    const both = (r) => p.slots.every((s) => r.sig[s]);
    const cand = p.scan.filter((r) => !out.includes(r.seed)).sort((a, b) => (both(b) - both(a)) || (variety(b) - variety(a)) || (a.seed - b.seed));
    for (const r of cand) { if (out.length >= quota[p.key]) break; push(r.seed, both(r) ? 'shows both signatures, ' + Object.keys(r.beams).join('/') : 'fills the quota'); }
    // signature coverage: swap the weakest filled seeds for ones that show a missing signature
    const have2 = (s) => p.scan.find((r) => r.seed === s);
    for (const slot of p.slots) {
      const count = () => out.filter((s) => have2(s) && have2(s).sig[slot]).length;
      let guard = 0;
      while (count() < MIN_SIGNATURES && guard++ < 10) {
        const pool = p.scan.filter((r) => !out.includes(r.seed) && r.sig[slot]).sort((a, b) => (both(b) - both(a)) || (variety(b) - variety(a)) || (a.seed - b.seed));
        const protectedSeeds = new Set([...keptFailed, ...keptWorst].filter((k) => k.pairing === p.key).map((k) => k.seed));
        const weakest = [...out].reverse().find((s) => !protectedSeeds.has(s) && !(have2(s) && have2(s).sig[slot]));
        if (!pool.length || weakest === undefined) break;
        out[out.indexOf(weakest)] = pool[0].seed;
        why.push(`${p.key}: seed ${pool[0].seed} replaces ${weakest} (the signature of ${slot} must show in at least ${MIN_SIGNATURES} matches)`);
      }
      if (count() < MIN_SIGNATURES) warnings.push(`${p.key}: the signature of ${slot} shows in ${count()} of ${out.length} picked matches (the rule is ${MIN_SIGNATURES})`);
    }
    if (out.length < quota[p.key]) warnings.push(`${p.key}: only ${out.length} of ${quota[p.key]} seeds could be picked (the scan has ${have.size})`);
    seedsOf[p.key] = out;
  }
  // every fighter in at least 5 matches over the whole pick
  const perFighter = {};
  for (const p of chosen) for (const s of p.slots) perFighter[s] = (perFighter[s] || 0) + (seedsOf[p.key] || []).length;
  for (const [f, n] of Object.entries(perFighter)) if (n < MIN_MATCHES_PER_FIGHTER) warnings.push(`${f} is in ${n} picked matches (the rule is ${MIN_MATCHES_PER_FIGHTER})`);
  return {
    rule: `pick-seeds.mjs: ${total} seeds in all; kept first (failed in an earlier candidate; the ${WORST_KEPT} worst of the previous release), then both signatures and variety by the scan, every signature at least ${MIN_SIGNATURES} times and every fighter at least ${MIN_MATCHES_PER_FIGHTER} matches; pairings rotate (uncaptured first)`,
    seeds: seedsOf, kept: { worst: keptWorst, failed: keptFailed }, why, warnings,
  };
}

/** The five worst seeds of a recorded pass: by the worse of a seed's readings in either mode. Rows are { id: "ai-<seed>-normal" | "ai-<A>-<B>-<seed>-reduced", primary, areaLower, stricter, second }. */
export function worstSeedsOf(record, defaultPairing, n = WORST_KEPT) {
  const best = new Map();
  for (const r of (record && record.rows) || []) {
    const m = /^ai(?:-([A-Z0-9_]+-[A-Z0-9_]+))?-(\d+)-(normal|reduced)$/.exec(r.id);
    if (!m) continue;
    const key = m[1] ? m[1].replace('-', ',') : defaultPairing;
    const vals = [r.primary, r.areaLower, r.stricter, r.second && r.second.primary, r.second && r.second.areaLower, r.second && r.second.stricter].filter((v) => typeof v === 'number');
    const worse = vals.length ? Math.max(...vals) : 0;
    const k = `${key}#${m[2]}`;
    best.set(k, Math.max(best.get(k) || 0, worse));
  }
  return [...best.entries()].map(([k, v]) => ({ pairing: k.split('#')[0], seed: Number(k.split('#')[1]), reading: v })).sort((a, b) => b.reading - a.reading || a.seed - b.seed).slice(0, n);
}

function main(argv) {
  const all = (n) => argv.flatMap((a, i) => (a === n && argv[i + 1] ? [argv[i + 1]] : []));
  const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
  const scans = all('--scan');
  if (!scans.length) { console.error('usage: node tools/flash/pick-seeds.mjs --scan A,B=scan.txt [--scan ...] [--total 20] [--previous record.json] [--history seed-history.json] [--out pick.json] [--write]'); return 2; }
  const pairings = scans.map((s) => { const [key, file] = s.split('='); return { key, slots: key.split(','), scan: parseScan(readFileSync(file, 'utf8')) }; });
  const histFile = opt('--history', join(here, 'seed-history.json'));
  const history = existsSync(histFile) ? JSON.parse(readFileSync(histFile, 'utf8')) : { failed: [], coverage: {} };
  const prevFile = opt('--previous');
  const previous = prevFile && existsSync(prevFile) ? JSON.parse(readFileSync(prevFile, 'utf8')) : null;
  const worst = worstSeedsOf(previous, pairings[0].key);
  const pick = pickSeeds({ pairings, total: Number(opt('--total', 20)), failed: (history.failed || []).filter((f) => !f.fixed), worst, coverage: history.coverage || {} });
  console.log(JSON.stringify(pick, null, 2));
  if (opt('--out')) writeFileSync(opt('--out'), JSON.stringify(pick, null, 2) + '\n');
  if (argv.includes('--write')) {
    const sf = join(here, 'sources.json');
    const raw = readFileSync(sf, 'utf8');
    const src = JSON.parse(raw);
    for (const p of src.pairings) { const k = p.slots.join(','); if (pick.seeds[k]) p.seeds = pick.seeds[k]; }
    writeFileSync(sf, JSON.stringify(src, null, 2) + (raw.endsWith('\n') ? '\n' : ''));
    console.error(`wrote the pick into ${sf}`);
  }
  return pick.warnings.length ? 1 : 0;
}

if (process.argv[1] && process.argv[1].endsWith('pick-seeds.mjs')) process.exit(main(process.argv.slice(2)));
