// The fighter-specific code ratchet (A-ENERGY-06, Tools, 2026-11-14), beside the two-fighter ratchet (tools/ratchet-two-fighter.mjs, which counts places that name exactly TWO fighters: it does not measure X-15,
// "no system is written for one named fighter"). This one counts the places the code of the energy, stamina, body and forms systems names a fighter by his id, which may only go down.
//
//   node tools/ratchet-fighter-specific.mjs              check: the total may not exceed tools/ratchet-fighter-specific.json's; exit 1 when it does, 2 on bad use
//   node tools/ratchet-fighter-specific.mjs --list       every file's count, by system, against its baseline
//   node tools/ratchet-fighter-specific.mjs --write      lower the baseline to today's count (refuses to raise it)
//   node tools/ratchet-fighter-specific.mjs --root <dir> count a tree other than the repository
//
// What is counted: a fighter's id (every id of data/fighters/roster.json, and the old placeholder names KAI and VORR) as a whole word, in the CODE of the files each system lists in the JSON file (the comments of
// a line, from # on, are not counted; a name inside a string is, because a string is how a branch on a fighter is written). The systems and their files: `energy` (the one energy model, the beams and the blast),
// `stamina` (none exists in the sim on 2026-11-13: the list is empty and the count is 0, which the ratchet keeps at 0), `body` (the fighter, his data, damage, hiding, the mood meters) and `forms` (transformations and
// boons). The lists are the first reading's; an owner who says a file belongs to a system (or that one is missing) gets it added, and the baseline taken again. A file that does not exist is skipped, not an error.
// The ratchet is on the TOTAL: moving a name between files is free and a fix only lowers it. Node built-ins only.
import { existsSync, readFileSync, readdirSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const BASE = join(ROOT, 'tools', 'ratchet-fighter-specific.json');
export const PLACEHOLDERS = ['KAI', 'VORR'];

/** The ids to count: the roster's, plus the placeholder names. */
export function namesOf(root) {
  let roster = [];
  try { roster = JSON.parse(readFileSync(join(root, 'data', 'fighters', 'roster.json'), 'utf8')); } catch { /* none */ }
  return [...new Set([...roster.filter((x) => typeof x === 'string' && x), ...PLACEHOLDERS])];
}

/** The code of a GDScript text with each line's comment removed (a # outside a string starts one). Pure. */
export function codeOf(text) {
  return text.split('\n').map((l) => {
    let q = null;
    for (let i = 0; i < l.length; i++) {
      const c = l[i];
      if (q) { if (c === '\\') i++; else if (c === q) q = null; }
      else if (c === '"' || c === "'") q = c;
      else if (c === '#') return l.slice(0, i);
    }
    return l;
  }).join('\n');
}

/** How many times any of `names` occurs as a whole word in `text`'s code. Pure. */
export function countIn(text, names) {
  if (!names.length) return 0;
  const re = new RegExp(`\\b(?:${names.map((n) => n.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')).join('|')})\\b`, 'g');
  return (codeOf(text).match(re) || []).length;
}

/** The files a list of paths and `dir/prefix*.gd` globs stands for, under root. */
export function expand(root, list) {
  const out = [];
  for (const p of list) {
    if (!p.includes('*')) { if (existsSync(join(root, p))) out.push(p); continue; }
    const dir = dirname(p), pre = p.slice(dir.length + 1).split('*')[0];
    let names = [];
    try { names = readdirSync(join(root, dir)); } catch { /* none */ }
    for (const n of names.sort()) if (n.startsWith(pre) && n.endsWith('.gd')) out.push(`${dir}/${n}`);
  }
  return [...new Set(out)];
}

const SKIP_DIRS = new Set(['test', 'tests', 'tools', 'probe', 'probes', 'node_modules', '.git', '.godot']);
const SKIP_FILE = /(_check|_test|_probe|_bench).gd$/;

/** The shipped GDScript files under sim, render, ui, net and audio (not tests, tools, probes or checks), as paths relative to root. */
export function shippedFiles(root) {
  const out = [];
  const walk = (dir) => {
    let ents; try { ents = readdirSync(join(root, dir), { withFileTypes: true }); } catch { return; }
    for (const e of ents) {
      if (e.isDirectory()) { if (!SKIP_DIRS.has(e.name)) walk(`${dir}/${e.name}`); continue; }
      if (e.name.endsWith('.gd') && !SKIP_FILE.test(e.name)) out.push(`${dir}/${e.name}`);
    }
  };
  for (const r of ['sim', 'render', 'ui', 'net', 'audio']) walk(r);
  return out.sort();
}

/** Elsewhere (not ratcheted, for the reader): the places the OTHER shipped files name a fighter by id: { total, files }. */
export function elsewhere(root, systems) {
  const inSystems = new Set(Object.values(systems).flatMap((l) => expand(root, l)));
  const names = namesOf(root), files = {};
  let total = 0;
  for (const f of shippedFiles(root)) {
    if (inSystems.has(f)) continue;
    const n = countIn(readFileSync(join(root, f), 'utf8'), names);
    if (n) { files[f] = n; total += n; }
  }
  return { total, files };
}

/** { bySystem: { energy: n, ... }, files: { path: n }, total }. */
export function count(root, systems) {
  const names = namesOf(root), bySystem = {}, files = {};
  let total = 0;
  for (const [sys, list] of Object.entries(systems)) {
    bySystem[sys] = 0;
    for (const f of expand(root, list)) {
      const n = countIn(readFileSync(join(root, f), 'utf8'), names);
      if (n) { files[f] = (files[f] || 0) + n; bySystem[sys] += n; total += n; }
    }
  }
  return { bySystem, files, total };
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const a = process.argv.slice(2);
  try {
    const ri = a.indexOf('--root');
    const root = ri >= 0 ? resolve(a[ri + 1]) : ROOT;
    const base = JSON.parse(readFileSync(BASE, 'utf8'));
    const now = count(root, base.systems);
    if (a.includes('--list')) { for (const [f, n] of Object.entries(now.files).sort()) console.log(`${String(n).padStart(4)}  ${f}  (baseline ${base.files[f] || 0})`); }
    const els = elsewhere(root, base.systems);
    console.log(`outside the four systems (not ratcheted): ${els.total} places in ${Object.keys(els.files).length} files${Object.keys(els.files).length ? ' (' + Object.entries(els.files).map(([k, v]) => `${k} ${v}`).join(', ') + ')' : ''}`);
    console.log(`fighter-specific code: ${now.total} places (${Object.entries(now.bySystem).map(([k, v]) => `${k} ${v}`).join(', ')}); the baseline is ${base.total}`);
    if (a.includes('--write')) {
      if (now.total > base.total) { console.error(`refused: the count rose (${now.total} against ${base.total}); a ratchet is only lowered`); process.exitCode = 1; }
      else { writeFileSync(BASE, JSON.stringify({ ...base, total: now.total, bySystem: now.bySystem, files: now.files }, null, 2) + '\n'); console.log(`baseline written: ${now.total}`); }
    } else if (now.total > base.total) {
      const rose = Object.entries(now.files).filter(([f, n]) => n > (base.files[f] || 0)).map(([f, n]) => `${f} ${base.files[f] || 0} to ${n}`);
      console.error(`the count rose from ${base.total} to ${now.total}: a system must not be written for one named fighter (X-15). It rose in: ${rose.join('; ') || '(see --list)'}`);
      process.exitCode = 1;
    }
  } catch (e) { console.error(`ratchet-fighter-specific: ${e.message}`); process.exitCode = 2; }
}
