// The signature clip's gate on a pin move (Legal's RL-195 condition (a), 2026-10-27): the pin can move only if the `signature` clip, REDUCED, reads no worse than 2.5 on the primary reading,
// 3 with the area threshold 15% lower, and 2 on the two-second memory. The nightly seeds run reads the clip in both modes every night too (tools/flash/nightly-seeds.mjs).
//
//   node tools/flash/signature-gate.mjs --record <run-pixels summary.json> --commit <full sha> [--file <signature-gate.json>] [--date YYYY-MM-DD]
//        reads signature-normal and signature-reduced from a run of that commit, and writes tools/flash/signature-gate.json: the commit and both readings. It REFUSES (exit 1, nothing
//        written) when reduced is worse than the limits, or a clip is missing or failed. Run it on the candidate pin BEFORE tools/site.json "pin" moves to it.
//   node tools/flash/signature-gate.mjs --check [--file <signature-gate.json>] [--pin <full sha>]
//        exit 1 unless the record is for the pin (tools/site.json "pin" by default) and reduced is within the limits (or the record is the standing pin's grandfathered one).
//   tools/check-site-interim.mjs runs the same check on the owner-approved site, so a pin moved without a reading fails the deploy.
//   node tools/flash/signature-gate.mjs --record-child <child summary.json> --pin-summary <pin summary.json> --commit <child sha> --of <pin sha> [--file <f>] [--date YYYY-MM-DD]
//        Legal RL-209 (b): a WORDS-ONLY CHILD of the grandfathered pin (tools/pin-child.mjs) inherits the pin's grandfathering when its signature and collapse clips, both modes, read no worse than the pin's on
//        EVERY reading (each size and scale of the four, each of primary, red, area-15% and the two-second memory). It REFUSES (exit 1, nothing written) when one is worse or missing. Both summaries are run-pixels
//        summary.json files (their rows carry `readings`, tools/flash/readings.mjs). Writes this file for the child: grandfathered, the pin's worst-of-four numbers as `reduced` and `normal`, the pin's and the
//        child's readings, and the engine-flip entry (RL-202) re-pointed at the child.
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = import.meta.dirname;
export const DEFAULT_FILE = join(HERE, 'signature-gate.json');
export const REDUCED_MAX = { primary: 2.5, area15: 3, twoSec: 2 };   // RL-195 (a): "no worse than 2.5 / 3 / 2"

/** One clip's three readings from a run-pixels summary row: the primary, the area-15% lower one and the two-second memory (what run-pixels prints). null when the row has none. Pure. */
export function readingOf(row) {
  const r = row && !row.error && row.result;
  if (!r || !r.general || !r.combined) return null;
  const twoSec = r.cross && r.cross.general ? r.cross.general.flashes : undefined;
  if (typeof r.general.flashes !== 'number' || typeof r.combined.lower !== 'number' || typeof twoSec !== 'number') return null;
  return { primary: r.general.flashes, area15: r.combined.lower, twoSec };
}

/** The signature clip in both modes from the summary rows: { normal, reduced, missing }. Pure. */
export function readSignature(rows) {
  const by = new Map((rows || []).map((r) => [r.id, r]));
  const normal = readingOf(by.get('signature-normal'));
  const reduced = readingOf(by.get('signature-reduced'));
  const missing = [...(normal ? [] : ['signature-normal']), ...(reduced ? [] : ['signature-reduced'])];
  return { normal, reduced, missing };
}

/** Whether a reduced reading is worse than the limits on any of the three; the names of what is. Pure. */
export function worseThan(reduced, max = REDUCED_MAX) {
  if (!reduced) return ['not read'];
  return Object.keys(max).filter((k) => reduced[k] > max[k]).map((k) => `${k} ${reduced[k]} (over ${max[k]})`);
}

/** The clips a words-only child must read no worse than its pin on (RL-209 (b)): the signature and the collapse clips, both modes. */
export const CHILD_CLIPS = ['signature-normal', 'signature-reduced', 'collapse-normal', 'collapse-reduced'];
const NUMBER_KEYS = ['primary', 'red', 'area15', 'twoSec'];

/** The readings of a summary row, [{ size, scale, primary, red, area15, twoSec }], or null when the row has none (RL-209: four readings a clip). Pure. */
export function readingsOf(row) {
  return row && !row.error && Array.isArray(row.readings) && row.readings.length ? row.readings : null;
}

/** Why a child does not inherit its pin's grandfathering: every reading of every clip must exist and be no worse than the pin's. An array; empty when it does. Pure. */
export function childProblems(childRows, pinRows) {
  const out = [];
  const by = (rows) => new Map((rows || []).map((r) => [r.id, r]));
  const c = by(childRows), p = by(pinRows);
  for (const id of CHILD_CLIPS) {
    const pr = readingsOf(p.get(id)), cr = readingsOf(c.get(id));
    if (!pr) { out.push(`${id}: the pin's summary has no readings for it`); continue; }
    if (!cr) { out.push(`${id}: the child's summary has no readings for it (a missing clip is not a pass)`); continue; }
    for (const a of pr) {
      const b = cr.find((x) => x.size === a.size && x.scale === a.scale);
      if (!b) { out.push(`${id}: the child has no reading at ${a.size} scale ${a.scale}`); continue; }
      for (const k of NUMBER_KEYS) {
        const pv = typeof a[k] === 'number' ? a[k] : 0, cv = typeof b[k] === 'number' ? b[k] : 0;
        if (cv > pv) out.push(`${id} at ${a.size} scale ${a.scale}: ${k} reads ${cv} on the child, worse than the pin's ${pv}`);
      }
    }
  }
  return out;
}

/** The worst-of-four numbers of a row, the way a record keeps them: { primary, area15, twoSec } (the same as readingOf of its merged result). Pure. */
export function worstNumbers(row) {
  const rs = readingsOf(row);
  if (!rs) return null;
  const max = (k) => Math.max(...rs.map((x) => (typeof x[k] === 'number' ? x[k] : 0)));
  return { primary: max('primary'), area15: max('area15'), twoSec: max('twoSec') };
}

/** The text of a reading, for a report line. */
export function readingText(x) { return x ? `${x.primary} / ${x.area15} / ${x.twoSec}` : 'not read'; }

/** Why a record does not allow `pin` (an array; empty when it does). Pure. */
export function gateProblems(record, pin) {
  const out = [];
  if (!record || typeof record !== 'object') return ['tools/flash/signature-gate.json is missing or unreadable: no signature reading is recorded for the pin (Legal RL-195 condition (a): run the signature clip on the candidate and node tools/flash/signature-gate.mjs --record)'];
  if (!/^[0-9a-f]{40}$/.test(String(pin))) out.push('the pin is not a full SHA');
  else if (record.commit !== pin) out.push(`the signature reading on record is for ${String(record.commit).slice(0, 8)}, the pin is ${pin.slice(0, 8)}: read the signature clip on the new pin (both modes) and record it before the pin moves (Legal RL-195 condition (a))`);
  if (record.grandfathered === true) return out;   // the pin Legal ruled on before the condition: kept as it was measured, not a pass of the limits
  const worse = worseThan(record.reduced);
  if (worse.length) out.push(`signature reduced reads worse than 2.5 / 3 / 2 on the record: ${worse.join(', ')}`);
  return out;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const args = process.argv.slice(2);
  const opt = (n, d) => { const i = args.indexOf(n); return i >= 0 ? args[i + 1] : d; };
  const file = resolve(opt('--file', DEFAULT_FILE));
  if (args.includes('--check')) {
    let record = null;
    try { record = JSON.parse(readFileSync(file, 'utf8')); } catch { /* reported */ }
    let pin = opt('--pin');
    if (!pin) { try { pin = JSON.parse(readFileSync(join(HERE, '..', 'site.json'), 'utf8')).pin; } catch { /* reported */ } }
    const p = gateProblems(record, pin);
    if (p.length) { for (const m of p) console.error(`signature gate FAILED: ${m}`); process.exit(1); }
    // CD-09 (2026-11-13): a grandfathered record is an exception that exits 0 so the standing pin is not broken, and it is never printed as "ok": a reader of the log must not take it for a pass of the limits.
    if (record.grandfathered) console.log(`signature gate EXCEPTION (grandfathered, NOT a pass of the limits 2.5 / 3 / 2): ${String(pin).slice(0, 8)}; reduced ${readingText(record.reduced)}; the pin Legal ruled on before the condition`);
    else console.log(`signature gate ok: ${String(pin).slice(0, 8)}; reduced ${readingText(record.reduced)} (limit 2.5 / 3 / 2)`);
    process.exit(0);
  }
  if (args.includes('--record-child')) {
    const childFile = opt('--record-child'), pinFile = opt('--pin-summary'), child = opt('--commit'), of = opt('--of');
    if (!childFile || !pinFile || !/^[0-9a-f]{40}$/.test(String(child)) || !/^[0-9a-f]{40}$/.test(String(of))) { console.error('usage: node tools/flash/signature-gate.mjs --record-child <child summary.json> --pin-summary <pin summary.json> --commit <child sha> --of <pin sha> [--file <f>] [--date YYYY-MM-DD]'); process.exit(2); }
    let childRows, pinRows;
    try { childRows = JSON.parse(readFileSync(resolve(childFile), 'utf8')); pinRows = JSON.parse(readFileSync(resolve(pinFile), 'utf8')); } catch (e) { console.error(`signature gate: a summary could not be read: ${e.message}`); process.exit(2); }
    const bad = childProblems(childRows, pinRows);
    if (bad.length) { for (const m of bad) console.error(`signature gate: ${m}`); console.error(`signature gate: the child ${child.slice(0, 8)} reads worse than its pin ${of.slice(0, 8)} or has a reading missing; nothing recorded (it does not inherit the grandfathering)`); process.exit(1); }
    const prevC = existsSync(file) ? (() => { try { return JSON.parse(readFileSync(file, 'utf8')); } catch { return null; } })() : null;
    const table = (rows) => Object.fromEntries(CHILD_CLIPS.map((id) => [id, readingsOf(rows.find((r) => r.id === id)).map(({ size, scale, primary, red, area15, twoSec }) => ({ size, scale, primary, red, area15, twoSec }))]));
    const date = opt('--date', new Date().toISOString().slice(0, 10));
    const pinSig = (id) => worstNumbers(pinRows.find((r) => r.id === id));
    const recordC = {
      _why: prevC && prevC._why ? prevC._why : 'The signature clip read on the pin (Legal RL-195 condition (a)); written by tools/flash/signature-gate.mjs --record, checked by tools/check-site-interim.mjs.',
      commit: child, date, grandfathered: true,
      child: { of, ruling: 'RL-209', words: 'tools/pin-child.json', clips: CHILD_CLIPS },
      _grandfathered: `The words-only child ${child.slice(0, 8)} of the live pin ${of.slice(0, 8)} (Legal RL-209 (b)): the pin's own code plus only the cleared ui/data words. It inherits the pin's grandfathering because every reading (both sizes, both scales) of the signature and collapse clips, both modes, is no worse than the pin's. \`reduced\` and \`normal\` are the PIN's worst of four, kept as measured; the next pin has to pass the limits and replaces this record.`,
      limits: REDUCED_MAX, reduced: pinSig('signature-reduced'), normal: pinSig('signature-normal'),
      pinReadings: table(pinRows), childReadings: table(childRows),
    };
    if (prevC && prevC.engineFlip) recordC.engineFlip = { ...prevC.engineFlip, commit: child };
    writeFileSync(file, JSON.stringify(recordC, null, 2) + '\n');
    console.log(`signature gate: recorded the child ${child.slice(0, 8)} of ${of.slice(0, 8)}: no reading of the signature or collapse clips, either mode, is worse than the pin's (reduced signature ${readingText(recordC.reduced)}, normal ${readingText(recordC.normal)}, the pin's worst of four)`);
    process.exit(0);
  }
  const summary = opt('--record');
  const commit = opt('--commit');
  if (!summary || !/^[0-9a-f]{40}$/.test(String(commit))) { console.error('usage: node tools/flash/signature-gate.mjs --record <summary.json> --commit <full sha> [--file <signature-gate.json>] [--date YYYY-MM-DD]  |  --check [--file <f>] [--pin <sha>]'); process.exit(2); }
  let rows = [];
  try { rows = JSON.parse(readFileSync(resolve(summary), 'utf8')); } catch (e) { console.error(`signature gate: ${summary} could not be read: ${e.message}`); process.exit(2); }
  const s = readSignature(rows);
  if (s.missing.length) { console.error(`signature gate: ${s.missing.join(', ')} not read in ${summary} (a missing clip is not a pass); nothing recorded`); process.exit(1); }
  const worse = worseThan(s.reduced);
  if (worse.length) { console.error(`signature gate: signature reduced reads ${readingText(s.reduced)} on ${commit.slice(0, 8)}, worse than 2.5 / 3 / 2: ${worse.join(', ')}; nothing recorded (the pin must not move to it)`); process.exit(1); }
  const date = opt('--date', new Date().toISOString().slice(0, 10));
  const prev = existsSync(file) ? (() => { try { return JSON.parse(readFileSync(file, 'utf8')); } catch { return null; } })() : null;
  const record = { _why: prev && prev._why ? prev._why : 'The signature clip read on the pin (Legal RL-195 condition (a)); written by tools/flash/signature-gate.mjs --record, checked by tools/check-site-interim.mjs.', commit, date, limits: REDUCED_MAX, reduced: s.reduced, normal: s.normal };
  writeFileSync(file, JSON.stringify(record, null, 2) + '\n');
  console.log(`signature gate: recorded ${commit.slice(0, 8)}: reduced ${readingText(s.reduced)} (limit 2.5 / 3 / 2), normal ${readingText(s.normal)}`);
}
