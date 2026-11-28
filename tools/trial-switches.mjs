// Orb's trial switches (Tools, 2026-11-28; the EP's wave 1): the list in tools/trial-switches.json, what flipping it in a scratch tree means, and the proof from the built program.
//   node tools/trial-switches.mjs --list            the rows
//   node tools/trial-switches.mjs --check           does every row still fit this tree? (CI: each key exists and holds the row's from value, or its to value, which is said: main has turned it on)
// The flips are the private preview's (tools/preview/switches.mjs: the one value changes, the rest of the file as it was); the read-back is the pack check's (tools/preview/pck-verify.mjs) on the pack inside the
// program: every row asked for must hold its `to`, every other row its `from`. Node built-ins only.
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { flip, locate, parts } from './preview/switches.mjs';
import { verifyPack } from './preview/pck-verify.mjs';

const REPO = resolve(fileURLToPath(new URL('..', import.meta.url)));
export const LIST_FILE = 'tools/trial-switches.json';
/** Never a trial switch: they keep a build safe or say who it is for. */
export const FIXED = ['lock_reduce_flashing', 'reduce_flashing', 'capture_hook', 'testers_package'];

const dataFile = (f) => typeof f === 'string' && /^(data|ui\/data)\/[A-Za-z0-9_./-]+\.json$/.test(f) && !f.includes('..');

/** The rows of the list's text: { rows, problems }. Pure. */
export function loadList(text) {
  const problems = [];
  let doc = null;
  try { doc = JSON.parse(text); } catch (e) { return { rows: [], problems: [`${LIST_FILE} is not JSON: ${e.message}`] }; }
  const rows = Array.isArray(doc.rows) ? doc.rows : null;
  if (!rows) return { rows: [], problems: [`${LIST_FILE} has no rows list`] };
  const seen = new Set();
  rows.forEach((r, i) => {
    const at = `row ${i}${r && r.id ? ` (${r.id})` : ''}`;
    if (!r || typeof r.id !== 'string' || !/^[a-z][A-Za-z0-9_]*$/.test(r.id)) { problems.push(`${at}: needs an id of letters, digits and _`); return; }
    if (seen.has(r.id)) problems.push(`${at}: the id is there twice`);
    seen.add(r.id);
    if (typeof r.what !== 'string' || !r.what.trim() || typeof r.owner !== 'string' || !r.owner.trim()) problems.push(`${at}: needs "what" and "owner"`);
    for (const k of [r, ...(r.more || [])]) {
      const file = k.file || r.file;
      if (!dataFile(file)) problems.push(`${at}: "file" must be a .json under data/ or ui/data/ (got ${file})`);
      if (!Array.isArray(k.path) || !k.path.length || !('from' in k) || !('to' in k) || JSON.stringify(k.from) === JSON.stringify(k.to)) problems.push(`${at}: each key needs a path, a from and a different to`);
      else if (FIXED.includes(k.path[k.path.length - 1])) problems.push(`${at}: ${k.path[k.path.length - 1]} is a fixed switch (${FIXED.join(', ')}): never a trial`);
    }
  });
  for (const r of rows) for (const n of (r && r.needs) || []) if (!seen.has(n)) problems.push(`row ${r.id}: needs "${n}", which is not a row`);
  return { rows, problems };
}

/** The rows `wanted` names ('all' or a comma list), in the list's order; every row a chosen one needs must be chosen too. Throws with the reason. Pure. */
export function choose(rows, wanted) {
  const ids = rows.map((r) => r.id);
  const names = wanted === 'all' ? ids : String(wanted).split(',').map((s) => s.trim()).filter(Boolean);
  if (!names.length) throw new Error('no trial switch named (and the list may be empty: node tools/trial-switches.mjs --list)');
  for (const n of names) if (!ids.includes(n)) throw new Error(`"${n}" is not a trial switch (${ids.join(', ') || 'the list is empty'})`);
  for (const r of rows) if (names.includes(r.id)) for (const need of r.needs || []) if (!names.includes(need)) throw new Error(`"${r.id}" needs "${need}": name both`);
  return rows.filter((r) => names.includes(r.id));
}

/** Turns the chosen rows on in the tree at `root` (a scratch copy). Returns one line a key. Throws when a key is not there or holds neither value. */
export function applyRows(root, chosen) {
  const out = [];
  for (const row of chosen) {
    for (const { file, sw } of parts(row)) {
      const path = join(root, file);
      if (!existsSync(path)) throw new Error(`${row.id}: ${file} is not in this commit`);
      const r = flip(readFileSync(path, 'utf8'), sw);
      writeFileSync(path, r.text);
      out.push(`${row.id}: ${file} ${sw.path.join('.')} ${JSON.stringify(sw.from)} -> ${JSON.stringify(sw.to)}`);
    }
  }
  return out;
}

/** The pack inside an exported program (the pack, then its size in 8 bytes, then "GDPC"), or the bytes themselves when they are a pack already. Throws when there is none. Pure. */
export function embeddedPack(bytes) {
  if (bytes.length > 64 && bytes.toString('latin1', 0, 4) === 'GDPC') return bytes;
  const n = bytes.length;
  if (n < 76 || bytes.toString('latin1', n - 4) !== 'GDPC') throw new Error('the program carries no embedded pack (no GDPC at its end)');
  const size = Number(bytes.readBigUInt64LE(n - 12));
  const start = n - 12 - size;
  if (!(size > 64) || start < 0 || bytes.toString('latin1', start, start + 4) !== 'GDPC') throw new Error('the program\'s embedded pack could not be found where its size says');
  return bytes.subarray(start, n - 12);
}

/** Reads every row out of the built program: { ok, problems, lines }. A chosen row must hold its `to`, every other its `from`. */
export function readBack(programBytes, rows, chosen) {
  const table = rows.map((r) => ({ needs: [], ...r }));
  const v = verifyPack(embeddedPack(programBytes), table, chosen.map((r) => r.id));
  const problems = v.problems || [];
  if (!v.checked) problems.push('not one switch key was read out of the program: the read-back proves nothing');
  return { ok: !problems.length && v.ok !== false, problems, lines: v.lines || [] };
}

/** What a tree says about the rows: { problems, notes }. A key that is missing or holds neither value is a problem; one already at `to` is a note (main turned it on: take the row out). */
export function fits(root, rows) {
  const problems = [], notes = [];
  for (const row of rows) {
    for (const { file, sw } of parts(row)) {
      const path = join(root, file);
      if (!existsSync(path)) { problems.push(`${row.id}: ${file} is not in the tree`); continue; }
      const text = readFileSync(path, 'utf8');
      for (const k of [{ path: sw.path, from: sw.from, to: sw.to }, ...(sw.more || [])]) {
        const loc = locate(text, k.path);
        if (!loc) { problems.push(`${row.id}: ${file} has no key ${k.path.join('.')}`); continue; }
        const now = text.slice(loc.start, loc.end);
        if (now === JSON.stringify(k.to)) notes.push(`${row.id}: ${file} ${k.path.join('.')} is already ${now} on this tree: main has it on, take the row out`);
        else if (now !== JSON.stringify(k.from)) problems.push(`${row.id}: ${file} ${k.path.join('.')} is ${now}, neither the row's from nor its to`);
      }
    }
  }
  return { problems, notes };
}

export function readList(root = REPO) { return loadList(readFileSync(join(root, LIST_FILE), 'utf8')); }

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  const a = process.argv.slice(2);
  const { rows, problems } = readList();
  if (a.includes('--list')) {
    for (const r of rows) console.log(`${r.id.padEnd(24)} ${r.what} (${r.owner}; ${r.file} ${r.path.join('.')} ${JSON.stringify(r.from)} -> ${JSON.stringify(r.to)})`);
    if (!rows.length) console.log('(no trial switches)');
    process.exit(problems.length ? 1 : 0);
  }
  if (!a.includes('--check')) { console.error('usage: node tools/trial-switches.mjs --list | --check'); process.exit(2); }
  const f = problems.length ? { problems: [], notes: [] } : fits(REPO, rows);
  for (const n of f.notes) console.log('note: ' + n);
  for (const p of [...problems, ...f.problems]) console.error('trial switches: ' + p);
  const bad = problems.length + f.problems.length;
  console.log(bad ? `trial switches FAILED: ${bad} problem(s)` : `trial switches ok: ${rows.length} row(s) fit this tree`);
  process.exit(bad ? 1 : 0);
}
