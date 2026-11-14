// How many switch rows still differ between main and a kept build's packed data (Tools, 2026-11-14; register rows A-CODE-03 criterion 2 and A-CODE-01, "the EP reads it every two days").
//
//   node tools/preview/switch-diff.mjs [--build <kept folder, or part of its name>] [--rev HEAD] [--list] [--json out.json] [--fail-over N]
//
// The kept build (default: orb-first-play-6a30b4c9-6627cb9d, the 9 November build Orb played) holds, inside its index.pck, the data the game ran on. main is the commit named by --rev (default HEAD):
// the committed files, never the working tree. For every data row of the switch table (tools/preview/switches.mjs) the value at the row's key (and at each of its `more` keys) is read from both and
// compared. A row DIFFERS when any of its keys holds another value in main than in the build, or exists in only one of them. A row that is not data (a page word, a setup key) is counted apart.
// As each owner's group lands on main (GW1a), its rows leave this list; the closing count is 0. Node built-ins and git only; nothing is built or run.
import { execFileSync } from 'node:child_process';
import { existsSync, readFileSync, readdirSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { packFiles } from '../site-name-scan.mjs';
import { packJson } from './pck-verify.mjs';
import { SWITCHES } from './switches.mjs';

const HERE = fileURLToPath(new URL('.', import.meta.url));
const ROOT = resolve(HERE, '..', '..');
export const DEFAULT_BUILD = 'orb-first-play-6a30b4c9-6627cb9d';

const at = (obj, path) => { let v = obj; for (const k of path) { if (v === null || typeof v !== 'object' || !(k in v)) return { found: false }; v = v[k]; } return { found: true, value: v }; };
const same = (a, b) => (typeof a === 'number' && typeof b === 'number' ? a === b : JSON.stringify(a) === JSON.stringify(b));

/** The data keys of a row: its own, then each `more` key (which may name another file). [{ file, path }] ; empty for a page word. Pure. */
export function keysOf(row) {
  const out = [];
  if (row.file && Array.isArray(row.path)) out.push({ file: row.file, path: row.path });
  for (const m of row.more || []) if (m && Array.isArray(m.path)) out.push({ file: m.file || row.file, path: m.path });
  return out;
}

/**
 * Compares the table's data rows between two sources. mainJson(file) and buildJson(file) give the parsed JSON of a data file or null. Returns
 * { rows: [{ id, differs, keys: [{ file, path, main, build, state }] }], differ, data, apart }. Pure.
 */
export function diffRows(table, mainJson, buildJson) {
  const rows = [];
  let apart = 0;
  for (const row of table) {
    const ks = keysOf(row);
    if (!ks.length) { apart++; continue; }
    const keys = ks.map((k) => {
      const a = mainJson(k.file), b = buildJson(k.file);
      const am = a === null ? { found: false } : at(a, k.path), bm = b === null ? { found: false } : at(b, k.path);
      const state = !am.found && !bm.found ? 'absent in both' : am.found && !bm.found ? 'only in main' : !am.found && bm.found ? 'only in the build' : same(am.value, bm.value) ? 'same' : 'differs';
      return { file: k.file, path: k.path, main: am.found ? am.value : undefined, build: bm.found ? bm.value : undefined, state };
    });
    rows.push({ id: row.id, differs: keys.some((k) => k.state === 'differs' || k.state === 'only in main' || k.state === 'only in the build'), keys });
  }
  return { rows, differ: rows.filter((r) => r.differs).length, data: rows.length, apart };
}

export function resolveBuild(want, buildsDir = join(ROOT, 'homework', 'Files', 'builds')) {
  const name = want || DEFAULT_BUILD;
  if (existsSync(name) && existsSync(join(name, 'web'))) return resolve(name);
  const hit = readdirSync(buildsDir, { withFileTypes: true }).filter((e) => e.isDirectory() && e.name.includes(name) && existsSync(join(buildsDir, e.name, 'web', 'index.pck')));
  if (!hit.length) throw new Error(`no kept build matching "${name}" with a web/index.pck in ${buildsDir}`);
  return join(buildsDir, hit.sort((x, y) => y.name.localeCompare(x.name))[0].name);
}

export function report(d, { list = false, buildName = '', rev = 'HEAD' } = {}) {
  const lines = [];
  if (list) for (const r of d.rows.filter((x) => x.differs)) for (const k of r.keys.filter((x) => x.state !== 'same' && x.state !== 'absent in both')) lines.push(`  ${r.id.padEnd(18)} ${k.file} ${k.path.join('.')}: main ${JSON.stringify(k.main)}, build ${JSON.stringify(k.build)} (${k.state})`);
  lines.push(`switch rows that differ between main (${rev}) and ${buildName || 'the build'}: ${d.differ} of ${d.data} data rows (${d.apart} more are page words or setup keys, not counted)`);
  return lines.join('\n');
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const a = process.argv.slice(2);
  const opt = (n, d) => { const i = a.indexOf(n); return i >= 0 && i + 1 < a.length ? a[i + 1] : d; };
  try {
    const dir = resolveBuild(opt('--build'));
    const rev = opt('--rev', 'HEAD');
    const buf = readFileSync(join(dir, 'web', 'index.pck'));
    const files = packFiles(buf);
    const cacheB = new Map(), cacheM = new Map();
    const buildJson = (f) => { if (!cacheB.has(f)) cacheB.set(f, packJson(buf, files, f)); return cacheB.get(f); };
    const mainJson = (f) => {
      if (!cacheM.has(f)) { let v = null; try { v = JSON.parse(execFileSync('git', ['show', `${rev}:${f}`], { cwd: ROOT, encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'], maxBuffer: 64 * 1024 * 1024 }).replace(/^﻿/, '')); } catch { /* not in main */ } cacheM.set(f, v); }
      return cacheM.get(f);
    };
    const d = diffRows(SWITCHES, mainJson, buildJson);
    console.log(report(d, { list: a.includes('--list'), buildName: dir.split(/[\\/]/).pop(), rev }));
    if (opt('--json')) writeFileSync(resolve(opt('--json')), JSON.stringify({ rev, build: dir.split(/[\\/]/).pop(), differ: d.differ, data: d.data, apart: d.apart, rows: d.rows.filter((r) => r.differs) }, null, 1));
    const lim = opt('--fail-over');
    if (lim !== undefined && d.differ > Number(lim)) process.exitCode = 1;
  } catch (e) { console.error(`switch-diff: ${e.message}`); process.exitCode = 2; }
}
