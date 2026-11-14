// Judges the scheduled flash reading (.github/workflows/flash-nightly.yml; corrective item CD-09, register row A-LEGAL-08; Tools, 2026-11-14).
//
//   node tools/flash/nightly-ci.mjs <folder with the run-pixels summary.json files, or one summary.json> [--md <file>] [--line 3]
//
// The scheduled reading plays a fixed set of clips on a build of main (both modes, the tile ground players see) and reads them with the same analyser as the release pass. This command turns the
// readings into the night's verdict. Everything it reads is DIRECT: the primary count, the area-15% reading, the two-second-memory reading and the red count are each taken from the analyser's own
// result, and the red count is compared with the line on its own (it is not folded into the general one).
//
// The take-down line is 3 flashes in the worst second (CD-09: "use 3 as the take-down line unless Orb sets another in writing"; WCAG 2.3.1). Our own gate is 2.5 on the primary reading.
//
// EXIT CODES (the workflow turns 1 and 2 into a red run, which GitHub emails to the repository owner):
//   0  every clip read, none over our gate
//   1  TAKE-DOWN LINE: a clip over the line on any reading (primary, area-15%, two-second memory, or red read directly)
//   2  a clip was not read (an error, no result, or the clip set is not the expected one): a missing clip is never a pass
//   3  FINDING: no clip over the line, but a clip over our gate of 2.5 on the primary reading (a warning on the run, not a red run)
// When more than one applies the smaller of 2, 1 comes first: 2, then 1, then 3.
import { existsSync, readdirSync, readFileSync, statSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

export const TAKE_DOWN_LINE = 3;
export const OUR_GATE = 2.5;
/** The clips every night reads: both modes of each, the night-sky clash among them (tools/flash/sources.json nightClips carries the same id). */
export const EXPECTED = ['clash-normal', 'clash-reduced', 'collapse-normal', 'collapse-reduced', 'signature-normal', 'signature-reduced', 'clash-night-normal', 'clash-night-reduced'];

const num = (v) => (typeof v === 'number' && Number.isFinite(v) ? v : null);

/** The four direct numbers of one summary row, or null when the row holds no result. Pure. */
export function readingOf(row) {
  const r = row && row.result;
  if (!r || !r.general || !r.red) return null;
  const c = r.combined || {};
  return { primary: num(r.general.flashes), red: num(r.red.flashes), area15: num(c.lower), twoSec: num(c.stricter) };
}

/**
 * The night's verdict from the summary rows ({ id, error?, result }). `expected` is the clip ids that must each be present and read (default EXPECTED), `line` the take-down line.
 * Returns { code, lines (the text), rows (what was read), problems }. Pure.
 */
export function judge(rows, { expected = EXPECTED, line = TAKE_DOWN_LINE } = {}) {
  const out = { code: 0, lines: [], rows: [], problems: [] };
  const byId = new Map((rows || []).map((r) => [r && r.id, r]));
  const notRead = [], over = [], finding = [];
  for (const id of expected) {
    const row = byId.get(id);
    if (!row) { notRead.push(`${id}: no row in the summary`); continue; }
    if (row.error) { notRead.push(`${id}: ${String(row.error).slice(0, 160)}`); continue; }
    const rd = readingOf(row);
    if (!rd) { notRead.push(`${id}: the row holds no analyser result`); continue; }
    if (rd.primary === null || rd.red === null) { notRead.push(`${id}: the primary or the red count is missing`); continue; }
    out.rows.push({ id, ...rd });
    for (const [name, v] of [['primary', rd.primary], ['area-15%', rd.area15], ['two-second memory', rd.twoSec], ['red', rd.red]]) if (v !== null && v > line) over.push(`${id}: ${name} reads ${v}, over the line of ${line}`);
    if (rd.primary > OUR_GATE && rd.primary <= line) finding.push(`${id}: primary reads ${rd.primary}, over our gate of ${OUR_GATE}`);
  }
  for (const id of byId.keys()) if (id && !expected.includes(id)) out.lines.push(`note: the summary also holds ${id}, which is not in tonight's set`);
  out.problems = [...notRead.map((m) => `NOT READ ${m}`), ...over.map((m) => `OVER THE LINE ${m}`), ...finding.map((m) => `FINDING ${m}`)];
  out.code = notRead.length ? 2 : over.length ? 1 : finding.length ? 3 : 0;
  return out;
}

/** The table, one line a clip, plus the verdict line. */
export function report(j, line = TAKE_DOWN_LINE) {
  const head = `${'clip'.padEnd(20)} ${'primary'.padStart(7)} ${'red'.padStart(4)} ${'area-15%'.padStart(8)} ${'2 s mem'.padStart(8)}`;
  const body = j.rows.map((r) => `${r.id.padEnd(20)} ${String(r.primary).padStart(7)} ${String(r.red).padStart(4)} ${String(r.area15 === null ? 'n/a' : r.area15).padStart(8)} ${String(r.twoSec === null ? 'n/a' : r.twoSec).padStart(8)}`);
  const verdict = { 0: 'flash reading clean', 1: `TAKE-DOWN LINE (${line}) CROSSED`, 2: 'A CLIP WAS NOT READ (never a pass)', 3: `FINDING: over our gate of ${OUR_GATE}, within the line` }[j.code];
  return [head, ...body, ...j.lines, ...j.problems, `nightly flash reading: ${verdict}`].join('\n');
}

/** Every run-pixels summary.json under `where` (a folder, searched one level down too, or a file), the rows concatenated. */
export function readSummaries(where) {
  const files = [];
  const p = resolve(where);
  if (!existsSync(p)) return [];
  if (statSync(p).isFile()) files.push(p);
  else {
    if (existsSync(join(p, 'summary.json'))) files.push(join(p, 'summary.json'));
    for (const d of readdirSync(p, { withFileTypes: true })) if (d.isDirectory() && existsSync(join(p, d.name, 'summary.json'))) files.push(join(p, d.name, 'summary.json'));
  }
  const rows = [];
  for (const f of files) {
    let j; try { j = JSON.parse(readFileSync(f, 'utf8')); } catch { continue; }
    for (const r of Array.isArray(j) ? j : Array.isArray(j.rows) ? j.rows : Array.isArray(j.clips) ? j.clips : []) rows.push(r);
  }
  return rows;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const a = process.argv.slice(2);
  const opt = (n, d) => { const i = a.indexOf(n); return i >= 0 && i + 1 < a.length ? a[i + 1] : d; };
  const where = a.find((x, i) => !x.startsWith('--') && !(i > 0 && a[i - 1].startsWith('--')));
  if (!where) { console.error('usage: node tools/flash/nightly-ci.mjs <folder with summary.json files, or one summary.json> [--md <file>] [--line 3] [--expect id,id]'); process.exit(2); }
  const line = Number(opt('--line', TAKE_DOWN_LINE));
  const expected = opt('--expect') ? opt('--expect').split(',') : EXPECTED;
  const j = judge(readSummaries(where), { expected, line });
  const text = report(j, line);
  console.log(text);
  if (opt('--md')) writeFileSync(resolve(opt('--md')), '```\n' + text + '\n```\n');
  if (process.env.GITHUB_ACTIONS && j.code === 3) for (const m of j.problems) console.log(`::warning::${m}`);
  process.exitCode = j.code;
}
