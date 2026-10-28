#!/usr/bin/env node
// Pseudo-locale: a test translation of ui/data made from the string inventory (strings.mjs). Every player-facing
// string is accented, about 40% longer and bracketed, so a build that loads it shows at a glance which text is not
// translatable (it stays plain English), which text is cut off (a bracket is missing) and which screens overflow.
//
//   node tools/l10n/pseudo.mjs              what would be written, and the expansion by surface
//   node tools/l10n/pseudo.mjs --write      write localization/pseudo/ui/data/*.json
//   node tools/l10n/pseudo.mjs --check      exit 1 when the written files are missing or stale
//   node tools/l10n/pseudo.mjs --self-test  prove the transform on fixed inputs
//
// The output keeps each file's shape byte for byte apart from the text leaves the inventory lists: ids, keys, choice
// values, numbers and notes are copied. Placeholders ({action}, %d, %.1f) and line breaks are kept as they are.
// Legal's cleared lines (docs/legal/page-fixed-lines.md) are never altered: they stay English in the pseudo-locale,
// as they must in any real locale until Legal clears a translation. Node built-ins only; no clock.
//
// A build shows it only through the opt-in switch (off by default): see docs/accessibility/l10n-plan.md, "The
// pseudo-locale switch". Nothing in the default build reads localization/.
import fs from 'node:fs';
import path from 'node:path';
import { inventory } from './strings.mjs';

const ROOT = process.cwd();
export const OUT_DIR = 'localization/pseudo/ui/data';

// Accents inside Latin-1 Supplement and Latin Extended-A only: the game's one font (Godot's built-in Open Sans
// SemiBold, docs/ui/font-note.md) has these, so the pseudo-locale tests length and hard-coding, not missing glyphs.
const MAP = {
  a: 'á', c: 'ç', d: 'ď', e: 'é', g: 'ĝ', h: 'ĥ', i: 'í', j: 'ĵ', k: 'ķ', l: 'ĺ', n: 'ñ', o: 'ö', r: 'ŕ', s: 'š',
  t: 'ţ', u: 'ü', w: 'ŵ', y: 'ý', z: 'ž',
  A: 'Å', C: 'Ç', D: 'Ď', E: 'É', G: 'Ĝ', H: 'Ĥ', I: 'Î', J: 'Ĵ', K: 'Ķ', L: 'Ĺ', N: 'Ñ', O: 'Ö', R: 'Ŕ', S: 'Š',
  T: 'Ţ', U: 'Ü', W: 'Ŵ', Y: 'Ý', Z: 'Ž',
};
const VOWELS = 'aeiouyAEIOUY';
// Kept as they are: {placeholders}, printf formats, line breaks.
const PROTECT = /(\{[A-Za-z0-9_]+\}|%[-+ 0-9.]*[a-zA-Z%]|\n)/;
export const GROWTH = 0.4;

// The pseudo form of one string: vowels doubled (spread through the words, so wrapping is tested as a longer language
// wraps, not as one long tail) until it is about 40% longer, at least two letters longer, then bracketed.
export function pseudo(text) {
  const parts = text.split(PROTECT);
  // Only the words grow: a placeholder is filled by another string, which grows by itself.
  const n = parts.filter((p, i) => i % 2 === 0).reduce((a, p) => a + [...p].length, 0);
  let extra = Math.max(2, Math.round(n * GROWTH)) - 2;   // the brackets are two of the extra letters
  // The vowels that may be doubled, in order, across the unprotected parts.
  const slots = [];
  parts.forEach((p, pi) => { if (pi % 2 === 0) [...p].forEach((ch, ci) => { if (VOWELS.includes(ch)) slots.push([pi, ci]); }); });
  const twice = new Set();
  if (slots.length > 0) {
    // Every k-th vowel, so the growth is spread through the string rather than piled at its start.
    const take = Math.min(extra, slots.length);
    for (let i = 0; i < take; i++) {
      const s = slots[Math.floor((i * slots.length) / take)];
      twice.add(`${s[0]}:${s[1]}`);
    }
    extra -= take;
  }
  let out = '';
  parts.forEach((p, pi) => {
    if (pi % 2 === 1) { out += p; return; }
    [...p].forEach((ch, ci) => {
      const m = MAP[ch] ?? ch;
      out += twice.has(`${pi}:${ci}`) ? m + m : m;
    });
  });
  return `[${out}${extra > 0 ? ' ' + '~'.repeat(Math.max(0, extra - 1)) : ''}]`;
}

function setAt(obj, trail, value) {
  let cur = obj;
  for (let i = 0; i < trail.length - 1; i++) cur = cur[Array.isArray(cur) ? Number(trail[i]) : trail[i]];
  const last = trail[trail.length - 1];
  cur[Array.isArray(cur) ? Number(last) : last] = value;
}

// The pseudo files: { 'name.json': text }, plus what was kept for Legal.
export function build(inv = inventory()) {
  const byFile = new Map();
  for (const r of inv.rows) {
    if (r.source !== 'data') continue;
    if (!byFile.has(r.file)) byFile.set(r.file, []);
    byFile.get(r.file).push(r);
  }
  const files = {};
  const kept = [];
  for (const [file, rows] of [...byFile.entries()].sort()) {
    const obj = JSON.parse(fs.readFileSync(path.join(ROOT, file), 'utf8'));
    for (const r of rows) {
      if (r.legal) { kept.push(r.key); continue; }
      setAt(obj, r.path, pseudo(r.text));
    }
    files[path.basename(file)] = JSON.stringify(obj, null, 2) + '\n';
  }
  return { files, kept };
}

function report(inv, built) {
  const lines = [];
  const data = inv.rows.filter((r) => r.source === 'data');
  lines.push(`${Object.keys(built.files).length} files for ${OUT_DIR}/, ${data.length} strings, ${built.kept.length} of Legal's cleared lines kept in English:`);
  for (const k of built.kept) lines.push(`  ${k}`);
  lines.push('');
  lines.push('Expansion by surface (characters, longest string): source -> pseudo');
  const surf = new Map();
  for (const r of data) {
    const p = r.legal ? r.length : [...pseudo(r.text)].length;
    const s = surf.get(r.surface) || { n: 0, src: 0, ps: 0, maxSrc: 0, maxPs: 0 };
    s.n++; s.src += r.length; s.ps += p; s.maxSrc = Math.max(s.maxSrc, r.length); s.maxPs = Math.max(s.maxPs, p);
    surf.set(r.surface, s);
  }
  for (const [k, s] of [...surf.entries()].sort()) {
    lines.push(`  ${k.padEnd(24)} ${String(s.n).padStart(4)} strings  ${String(s.src).padStart(6)} -> ${String(s.ps).padStart(6)} (+${Math.round((s.ps / s.src - 1) * 100)}%)  longest ${s.maxSrc} -> ${s.maxPs}`);
  }
  const hc = inv.rows.filter((r) => r.hardcoded && r.reach === 'default');
  lines.push('');
  lines.push(`${hc.length} hard-coded strings in the default build stay plain English in the pseudo-locale (strings.mjs lists them).`);
  lines.push('Layout check (Godot, the real font and the real layout): godot --headless --path . --script res://tools/l10n/overflow_check.gd');
  return lines.join('\n');
}

function selfTest() {
  let fails = 0;
  const ok = (c, m) => { if (!c) { fails++; console.log(`FAIL  ${m}`); } };
  const p = pseudo('Press the key for {action}.  Esc cancels.');
  ok(p.startsWith('[') && p.endsWith(']'), 'bracketed');
  ok(p.includes('{action}'), 'a placeholder is kept');
  ok(!/[aeiou]/.test(p.replace('{action}', '')), 'every mapped letter is accented');
  const n = [...'Press the key for .  Esc cancels.'].length;
  const grown = [...p].length - '{action}'.length;
  ok(grown >= Math.round(n * 1.35) && grown <= Math.round(n * 1.45) + 1, `the words are about 40% longer (${n} -> ${grown})`);
  ok(pseudo('{region}: {stage}') === '[{region}: {stage}]', 'a template of placeholders only gains its brackets');
  ok(pseudo('COMBO ×%d').includes('%d') && pseudo('%6.1f  %s').includes('%6.1f'), 'printf formats are kept');
  ok(pseudo('Two\nlines').includes('\n'), 'a line break is kept');
  ok([...pseudo('On')].length === 4, 'a short word grows by two at least (the brackets)');
  ok([...pseudo('Off')].length >= 5, 'a short word with few vowels still grows');
  ok(pseudo('XYZ') === pseudo('XYZ'), 'deterministic');
  ok([...pseudo('BRB 123')].length >= Math.round(7 * 1.4), 'no vowels to double: padded');
  const inv = inventory();
  const b = build(inv);
  ok(Object.keys(b.files).length >= 8, `the files are built (${Object.keys(b.files).length})`);
  ok(b.kept.includes('terms:prompt.menu_notice'), 'Legal\'s notice is kept');
  const terms = JSON.parse(b.files['terms.json']);
  const src = JSON.parse(fs.readFileSync(path.join(ROOT, 'ui/data/terms.json'), 'utf8'));
  ok(terms.prompt.menu_notice === src.prompt.menu_notice && terms.prompt.photo_start === src.prompt.photo_start, 'Legal\'s lines are byte-identical');
  ok(terms.stance_ids.join() === src.stance_ids.join() && Object.keys(terms.banner_rename).join() === Object.keys(src.banner_rename).join(), 'ids and keys are kept');
  ok(terms.card['rally.protagonist'] !== src.card['rally.protagonist'] && terms.card['rally.protagonist'].startsWith('['), 'a key with a dot in it is found');
  const opt = JSON.parse(b.files['options.json']);
  ok(opt.options.colour_vision.choices.join() === 'off,protan,deutan,tritan' && opt.options.colour_vision.default === 'off', 'choices and defaults are kept');
  const set = JSON.parse(b.files['settings.json']);
  ok(set.labels.thickness['0.75'].startsWith('[') && set.sections[0].items[0] === 'pad_preset', 'a label keyed by a number is set; an item id is kept');
  ok(JSON.stringify(build(inv)) === JSON.stringify(b), 'two builds are identical');
  console.log(fails === 0 ? 'pseudo self-test: all passed' : `pseudo self-test: ${fails} failed`);
  return fails === 0 ? 0 : 1;
}

const isMain = process.argv[1] && path.resolve(process.argv[1]) === path.resolve(new URL(import.meta.url).pathname);
if (isMain) {
  const args = new Set(process.argv.slice(2));
  if (args.has('--self-test')) process.exit(selfTest());
  const inv = inventory();
  const built = build(inv);
  if (args.has('--write')) {
    fs.mkdirSync(path.join(ROOT, OUT_DIR), { recursive: true });
    for (const [name, text] of Object.entries(built.files)) fs.writeFileSync(path.join(ROOT, OUT_DIR, name), text);
    console.log(`wrote ${Object.keys(built.files).length} files to ${OUT_DIR}/`);
  } else if (args.has('--check')) {
    const stale = Object.entries(built.files).filter(([name, text]) => {
      const f = path.join(ROOT, OUT_DIR, name);
      return !fs.existsSync(f) || fs.readFileSync(f, 'utf8') !== text;
    }).map(([name]) => name);
    console.log(stale.length === 0 ? `pseudo-locale is current (${Object.keys(built.files).length} files)` : `pseudo-locale is stale: ${stale.join(', ')} (run node tools/l10n/pseudo.mjs --write)`);
    process.exit(stale.length === 0 ? 0 : 1);
  } else {
    console.log(report(inv, built));
  }
}
