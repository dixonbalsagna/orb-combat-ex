// The build check from packed data, for a DESKTOP build (A-TOOLS-10, Tools, 2026-11-14; the playbook's "check_build" step, now a tracked script). It reads the switch rows out of the data files inside the build's
// own pack and compares each with the commit the build was made from: the list says what was meant, the pack says what shipped.
//
//   node tools/preview/build-check.mjs --build <a desktop build's folder, its game file (.exe or .x86_64), or a .pck> [--rev <commit>] [--repo <repository>] [--list] [--json <file>]
//
// A desktop build is the commit as it is (no switch page flips anything), so every data row of tools/preview/switches.mjs must hold, in the pack, the value main's committed file holds at the commit:
// a row that differs is a PROBLEM (the build's data is not the commit's). The check also prints which rows are ON in the pack (the value is the row's "to"), so "the build is the game Orb played" is a count
// that can be read: `node tools/preview/switch-diff.mjs` says how many rows still differ between main and the 9 November build. The commit is the build's own stamp (res://build_info.json inside the pack),
// unless --rev names one. The embedded pack of a Windows or Linux export (the game file ends with the pack, its size and GDPC) and a separate .pck are both read. Exit 1 on any problem, 2 on a bad call.
// (The browser builds have their own, tools/preview/pck-verify.mjs, which compares a page build's pack with the page's own list of switches.) Node built-ins and git only.
import { execFileSync } from 'node:child_process';
import { existsSync, readFileSync, readdirSync, statSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { packFiles } from '../site-name-scan.mjs';
import { packJson } from './pck-verify.mjs';
import { SWITCHES } from './switches.mjs';
import { keysOf } from './switch-diff.mjs';

const ROOT = resolve(fileURLToPath(new URL('.', import.meta.url)), '..', '..');

/** The pack inside a file: the file itself when it starts with GDPC, else the embedded pack (the file ends with <size: 8 bytes><GDPC>). Throws, naming why, when there is none. Pure. */
export function packOf(buf) {
  if (buf.length >= 4 && buf.toString('latin1', 0, 4) === 'GDPC') return buf;
  if (buf.length < 16 || buf.toString('latin1', buf.length - 4) !== 'GDPC') throw new Error('the file holds no pack: it neither starts with GDPC nor ends with the embedded pack\'s footer');
  const size = Number(buf.readBigUInt64LE(buf.length - 12));
  if (!(size > 0) || size > buf.length - 12) throw new Error('the embedded pack\'s size in the footer is not inside the file');
  return buf.subarray(buf.length - 12 - size, buf.length - 12);
}

/** The game file of a build folder, or the path itself when it is a file. */
export function gameFileOf(p) {
  const abs = resolve(p);
  if (!existsSync(abs)) throw new Error(`${abs} does not exist`);
  if (statSync(abs).isFile()) return abs;
  const names = readdirSync(abs);
  const pick = names.find((n) => /\.x86_64$/.test(n)) || names.find((n) => /\.exe$/.test(n)) || names.find((n) => /\.pck$/.test(n));
  if (!pick) throw new Error(`no game file (.x86_64, .exe or .pck) in ${abs}`);
  return join(abs, pick);
}

const at = (obj, path) => { let v = obj; for (const k of path) { if (v === null || typeof v !== 'object' || !(k in v)) return { found: false }; v = v[k]; } return { found: true, value: v }; };
const same = (a, b) => (typeof a === 'number' && typeof b === 'number' ? a === b : JSON.stringify(a) === JSON.stringify(b));

/**
 * The comparison, pure: packJsonOf(file) and commitJsonOf(file) give the parsed JSON of a data file in the pack and in the commit, or null. Returns { rows: [{ id, on, problems: [..] }], problems: [..], on, data }.
 * A row is ON when every one of its keys holds the "to" value in the pack; a row with a key that differs from the commit is a problem.
 */
export function checkRows(table, packJsonOf, commitJsonOf) {
  const rows = [], problems = [];
  for (const row of table) {
    const ks = keysOf(row);
    if (!ks.length) continue;
    const toOf = (k, i) => (i === 0 ? row.to : (row.more || [])[i - 1]?.to);
    let on = true;
    const mine = [];
    ks.forEach((k, i) => {
      const a = packJsonOf(k.file), b = commitJsonOf(k.file);
      const pv = a === null ? { found: false } : at(a, k.path), cv = b === null ? { found: false } : at(b, k.path);
      if (pv.found !== cv.found || (pv.found && !same(pv.value, cv.value))) mine.push(`${k.file} ${k.path.join('.')}: the pack holds ${pv.found ? JSON.stringify(pv.value) : 'no such key'}, the commit ${cv.found ? JSON.stringify(cv.value) : 'no such key'}`);
      const to = toOf(k, i);
      if (!(pv.found && to !== undefined && same(pv.value, to))) on = false;
    });
    rows.push({ id: row.id, on, problems: mine });
    for (const m of mine) problems.push(`row ${row.id}: ${m}`);
  }
  return { rows, problems, on: rows.filter((r) => r.on).length, data: rows.length };
}

export function report(r, { list = false, commit = '', build = '' } = {}) {
  const lines = [];
  if (list) for (const x of r.rows) lines.push(`${x.id.padEnd(18)} ${x.on ? 'ON ' : 'off'}${x.problems.length ? '  DIFFERS FROM THE COMMIT' : ''}`);
  for (const p of r.problems) lines.push(`PROBLEM ${p}`);
  lines.push(`build check of ${build || 'the build'} against commit ${String(commit).slice(0, 8)}: ${r.data} data rows read from the pack, ${r.on} ON, ${r.data - r.on} off, ${r.problems.length} problem(s)`);
  return lines.join('\n');
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const a = process.argv.slice(2);
  const opt = (n, d) => { const i = a.indexOf(n); return i >= 0 && i + 1 < a.length ? a[i + 1] : d; };
  try {
    if (!opt('--build')) { console.error('usage: node tools/preview/build-check.mjs --build <folder | game file | .pck> [--rev <commit>] [--repo <repository>] [--list] [--json <file>]'); process.exit(2); }
    const file = gameFileOf(opt('--build'));
    const pck = packOf(readFileSync(file));
    const files = packFiles(pck);
    const stamp = packJson(pck, files, 'build_info.json');
    const repo = resolve(opt('--repo', ROOT));
    const want = opt('--rev') || (stamp && (stamp.id ? String(stamp.id).split('-')[0] : stamp.commit));
    if (!want || want === 'unknown') { console.error('the pack has no build_info.json with a commit, and no --rev was given'); process.exit(2); }
    const rev = execFileSync('git', ['rev-parse', '--verify', `${want}^{commit}`], { cwd: repo, encoding: 'utf8' }).trim();
    const cache = new Map();
    const commitJsonOf = (f) => {
      if (!cache.has(f)) { let v = null; try { v = JSON.parse(execFileSync('git', ['show', `${rev}:${f}`], { cwd: repo, encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'], maxBuffer: 64 * 1024 * 1024 }).replace(/^﻿/, '')); } catch { /* not in the commit */ } cache.set(f, v); }
      return cache.get(f);
    };
    const r = checkRows(SWITCHES, (f) => packJson(pck, files, f), commitJsonOf);
    console.log(report(r, { list: a.includes('--list'), commit: rev, build: file.split(/[\\/]/).pop() }));
    if (opt('--json')) writeFileSync(resolve(opt('--json')), JSON.stringify({ build: file.split(/[\\/]/).pop(), commit: rev, stamp, data: r.data, on: r.on, problems: r.problems, rows: r.rows }, null, 1));
    process.exitCode = r.problems.length ? 1 : 0;
  } catch (e) { console.error(`build-check: ${e.message}`); process.exitCode = 2; }
}
