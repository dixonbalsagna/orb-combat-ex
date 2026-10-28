#!/usr/bin/env node
// String inventory: every player-facing string in the game, with its key, source file and length, and a flag on the
// hard-coded ones that bypass ui/data. Accessibility and Localization (docs/accessibility/l10n-plan.md).
//
//   node tools/l10n/strings.mjs                 a summary by source and the hard-coded strings
//   node tools/l10n/strings.mjs --json          the whole inventory as JSON (pseudo.mjs reads this)
//   node tools/l10n/strings.mjs --md            the whole inventory as a Markdown table
//   node tools/l10n/strings.mjs --self-test     prove the tokenizer and the filters on fixed inputs
//
// Node built-ins only, no clock, sorted output: two runs on the same tree print the same bytes. Read only: it writes
// nothing. Run from the repository root.
//
// Three sources:
//   data   ui/data/*.json: the text leaves only (ids, colours, paths, choice values, notes and numbers are left out).
//   barks  data/narrative/combat_barks.json and audio/data/babble_captions.json: spoken lines and captions. No live
//          emitter sends them to the HUD yet (only ui/mock/ui_mock_feed.gd does), so their reach is "not shown yet".
//   code   string literals in GDScript that reach the screen: arguments of the draw and banner sinks below, and the
//          constants listed in INDIRECT. These bypass ui/data and are flagged hardcoded.
// Every row also says whether it is one of Legal's cleared lines (docs/legal/page-fixed-lines.md): those are never
// altered by any tool here.
import fs from 'node:fs';
import path from 'node:path';

const ROOT = process.cwd();
const rd = (rel) => fs.readFileSync(path.join(ROOT, rel), 'utf8');
const exists = (rel) => fs.existsSync(path.join(ROOT, rel));

// ---------------------------------------------------------------- ui/data

// Keys whose string values are never player text (ids, references, styling, notes).
const SKIP_KEYS = new Set([
  'schema', 'note', '_note', 'notes', '_about', 'id', 'ids', 'art', 'icon', 'col', 'colour', 'color', 'path', 'scheme',
  'group', 'default', 'action', 'actions', 'cell', 'kind', 'type', 'needs', 'choices', 'hidden', 'live', '_live',
  'profile', 'pos', 'pad', 'base', 'ego', 'crown', 'regions', 'rail', 'order', 'stance_ids', 'beat_ids', 'families',
  'expressions', 'default_expression', 'gesture_expression', 'kinds', 'finisher_counter', 'url', 'repo', 'style',
  'align', 'min', 'max', 'step', 'fighter_alias', 'presets', 'map', 'lanes', 'features', 'to', '_target', 'labels_of',
  'mood', 'face', 'face_expr', 'speaker', 'speaker_role', 'trigger', 'legal', 'gesture', 'keep', 'old', 'meter',
]);
// Files that hold no player text at all.
const SKIP_FILES = new Set(['features.json', 'colour_vision.json', 'faces.json', 'readout_profiles.json']);
// A key whose name ends like this is a note for people, not the player.
const NOTE_RE = /(^_?about$|note$|^_eight$|_eight$)/;

function isText(s) {
  if (typeof s !== 'string') return false;
  const t = s.trim();
  if (t === '') return false;
  if (/^#[0-9a-fA-F]{3,8}$/.test(t)) return false;            // a colour
  if (/^(res|user|https?|mailto):/.test(t)) return false;        // a path or a link
  if (/^[a-z0-9_\-.:/+]+$/.test(t)) return false;                // a lower-case id ("touch-simple", "b1", "kbd")
  return /\p{L}/u.test(t);                                       // it has a letter
}

// glyphs.json: the button letters (A, LB, L2) are the device's own marks and are never translated; key names that are
// words (Shift, Space, Start) are.
function glyphIsText(s) {
  return isText(s) && /[a-z]/.test(s) && s.length >= 3;
}

// Which screen a ui/data key shows on. First match wins; the default is the file's own surface.
const SURFACES = [
  [/^terms:prompt\.(photo_|menu_notice|menu_rf_)/, 'notice'],
  [/^terms:prompt\.(menu_|pause_menu|pause_again|pause_over)/, 'start menu'],
  [/^terms:prompt\.(pause_|not_yet)/, 'pause menu'],
  [/^terms:prompt\.load_/, 'loading'],
  [/^terms:prompt\.turn_/, 'turn your phone'],
  [/^terms:prompt\.(join|left|joined|remap_)/, 'join and leave'],
  [/^terms:prompt\.(over_|inc_)/, 'match over'],
  [/^terms:prompt\./, 'prompts and hints'],
  [/^terms:(stance|tier|meter|region|stage|internal_stage|chip_stage|station|card)\b/, 'wound cards and plates'],
  [/^terms:state\./, 'plates and chips'],
  [/^terms:toll\./, 'world toll'],
  [/^terms:banner_rename\./, 'banner'],
  [/^terms:caption\./, 'captions'],
  [/^terms:(planet|places)/, 'planet strip'],
  [/^howto:/, 'how to play'],
  [/^settings:remap\./, 'remap controls'],
  [/^settings:/, 'settings'],
  [/^options:/, 'settings'],
  [/^hints:/, 'control legend'],
  [/^stances:/, 'stances'],
  [/^reads:/, 'tutorial hints'],
  [/^feedback:/, 'feedback'],
  [/^send:/, 'feedback'],
  [/^glyphs:/, 'button glyphs'],
  [/^fighter_names:/, 'names'],
];

function surfaceOf(key) {
  for (const [re, s] of SURFACES) if (re.test(key)) return s;
  return 'other';
}

// Keys whose lower-case one-word values are words a player reads (the caption tags, the report's words, the steps of a
// remap), not ids.
const WORD_PATHS = [/^terms:caption\./, /^feedback:report\./, /^settings:remap\.move_steps\./];

function walkData(file, value, trail, out) {
  if (typeof value === 'string') {
    const leaf = trail[trail.length - 1];
    const key = `${file}:${trail.join('.')}`;
    const ok = file === 'glyphs' ? glyphIsText(value) : WORD_PATHS.some((re) => re.test(key)) ? /\p{L}/u.test(value) : isText(value);
    if (ok) out.push({ key, leaf: String(leaf), trail, text: value });
    return;
  }
  if (Array.isArray(value)) {
    value.forEach((v, i) => walkData(file, v, [...trail, String(i)], out));
    return;
  }
  if (value && typeof value === 'object') {
    for (const k of Object.keys(value)) {
      if (SKIP_KEYS.has(k) || NOTE_RE.test(k)) continue;
      // terms.json keeps the sim's English as banner_rename's keys and the player's words as its values: the walk
      // only ever reads values, so the sim's side is not a row here (it is a code row, from the sim's banner sink).
      walkData(file, value[k], [...trail, k], out);
    }
  }
}

function dataRows() {
  const rows = [];
  const dir = 'ui/data';
  for (const name of fs.readdirSync(path.join(ROOT, dir)).filter((n) => n.endsWith('.json')).sort()) {
    if (SKIP_FILES.has(name)) continue;
    const file = name.replace(/\.json$/, '');
    const found = [];
    walkData(file, JSON.parse(rd(`${dir}/${name}`)), [], found);
    for (const r of found) {
      rows.push({ source: 'data', key: r.key, path: r.trail, file: `${dir}/${name}`, surface: surfaceOf(r.key), reach: 'default',
        text: r.text, hardcoded: false });
    }
  }
  return rows;
}

// ---------------------------------------------------------------- barks and captions

function barkRows() {
  const rows = [];
  const add = (key, file, text, surface) => rows.push({ source: 'barks', key, file, surface,
    reach: 'not shown yet (no live emitter)', text, hardcoded: false });
  const bf = 'data/narrative/combat_barks.json';
  if (exists(bf)) {
    const found = [];
    const walk = (v, trail) => {
      if (typeof v === 'string') {
        const leaf = trail[trail.length - 1];
        if (['text', 'move_name', 'label', 'new'].includes(leaf) || /^\d+$/.test(leaf) && trail.includes('move_name_alternates')) {
          if (isText(v)) found.push([trail.join('.'), v]);
        }
        return;
      }
      if (Array.isArray(v)) { v.forEach((x, i) => walk(x, [...trail, String(i)])); return; }
      if (v && typeof v === 'object') for (const k of Object.keys(v)) if (!NOTE_RE.test(k) && k !== 'event_shape') walk(v[k], [...trail, k]);
    };
    walk(JSON.parse(rd(bf)), []);
    for (const [k, t] of found) add(`combat_barks:${k}`, bf, t, 'barks');
  }
  const cf = 'audio/data/babble_captions.json';
  if (exists(cf)) {
    const caps = JSON.parse(rd(cf)).captions || {};
    for (const who of Object.keys(caps)) {
      caps[who].forEach((c, i) => { if (isText(c.text)) add(`babble_captions:captions.${who}.${i}.text`, cf, c.text, 'barks'); });
    }
  }
  return rows;
}

// ---------------------------------------------------------------- GDScript literals

// A small GDScript tokenizer: strings (with their line), identifiers, numbers and single punctuation. Comments are
// dropped. StringName (&"x") and NodePath (^"x") literals are marked so they are never text.
export function tokenize(src) {
  const toks = [];
  let i = 0;
  let line = 1;
  const n = src.length;
  while (i < n) {
    const c = src[i];
    if (c === '\n') { line++; i++; continue; }
    if (c === ' ' || c === '\t' || c === '\r' || c === '\\') { i++; continue; }
    if (c === '#') { while (i < n && src[i] !== '\n') i++; continue; }
    if (c === '"' || c === "'") {
      const prefix = toks.length && (toks[toks.length - 1].v === '&' || toks[toks.length - 1].v === '^') && toks[toks.length - 1].adj === i;
      const triple = src.startsWith(c.repeat(3), i);
      const q = triple ? c.repeat(3) : c;
      const startLine = line;
      i += q.length;
      let s = '';
      while (i < n && !src.startsWith(q, i)) {
        if (src[i] === '\\' && i + 1 < n) {
          const e = src[i + 1];
          s += e === 'n' ? '\n' : e === 't' ? '\t' : e;
          i += 2;
          continue;
        }
        if (src[i] === '\n') { line++; if (!triple) break; }
        s += src[i];
        i++;
      }
      i += q.length;
      if (prefix) toks.pop();
      toks.push({ t: prefix ? 'name' : 'str', v: s, line: startLine });
      continue;
    }
    if (/[A-Za-z_]/.test(c)) {
      let j = i;
      while (j < n && /[A-Za-z0-9_]/.test(src[j])) j++;
      toks.push({ t: 'id', v: src.slice(i, j), line });
      i = j;
      continue;
    }
    if (/[0-9]/.test(c)) {
      let j = i;
      while (j < n && /[0-9A-Za-z_.]/.test(src[j])) j++;
      toks.push({ t: 'num', v: src.slice(i, j), line });
      i = j;
      continue;
    }
    const two = src.slice(i, i + 2);
    if (['==', '!=', '<=', '>=', '+=', ':=', '->', '&&', '||'].includes(two)) {
      toks.push({ t: 'p', v: two, line });
      i += 2;
      continue;
    }
    toks.push({ t: 'p', v: c, line, adj: i + 1 });
    i++;
  }
  return toks;
}

// Index of the token after the matching close bracket of the open bracket at `k`.
function closeOf(toks, k) {
  const open = toks[k].v;
  const close = open === '(' ? ')' : open === '[' ? ']' : '}';
  let d = 0;
  for (let j = k; j < toks.length; j++) {
    if (toks[j].t !== 'p') continue;
    if ('([{'.includes(toks[j].v)) d++;
    else if (')]}'.includes(toks[j].v)) { d--; if (d === 0) return j + 1; }
  }
  return toks.length;
}

// The argument token ranges of the call whose "(" is at `k`: [[from, to), ...].
function argsOf(toks, k) {
  const end = closeOf(toks, k) - 1;
  const out = [];
  let from = k + 1;
  let d = 0;
  for (let j = k + 1; j < end; j++) {
    const v = toks[j].t === 'p' ? toks[j].v : '';
    if ('([{'.includes(v) && v) d++;
    else if (')]}'.includes(v) && v) d--;
    else if (v === ',' && d === 0) { out.push([from, j]); from = j + 1; }
  }
  if (end > from) out.push([from, end]);
  return out;
}

// Calls a text literal may pass through and still be drawn as it is.
const PASS_CALLS = new Set(['str', 'String', 'to_upper', 'to_lower', 'strip_edges', 'display_text', 'banner', 'safe']);

// The literals in tokens [from, to) that would be drawn: not keys of a lookup, not compared, not inside a call that
// turns them into something else (UiData.t("key") gives the data's words, col("#fff") a colour).
export function textLiterals(toks, from, to) {
  const out = [];
  let j = from;
  while (j < to) {
    const tk = toks[j];
    if (tk.t === 'p' && tk.v === '(' && j > from && toks[j - 1].t === 'id' && !PASS_CALLS.has(toks[j - 1].v)) {
      j = closeOf(toks, j);
      continue;
    }
    if (tk.t === 'p' && tk.v === '[' && j > from && (toks[j - 1].t === 'id' || toks[j - 1].v === ']' || toks[j - 1].v === ')')) {
      j = closeOf(toks, j);   // a subscript: x["key"]
      continue;
    }
    if (tk.t === 'str') {
      const prev = j > from ? toks[j - 1].v : '';
      const next = j + 1 < to ? toks[j + 1].v : '';
      const compared = ['==', '!=', 'in'].includes(prev) || ['==', '!=', 'in'].includes(next) || next === ':';
      if (!compared && /\p{L}/u.test(tk.v)) out.push(tk);
    }
    j++;
  }
  return out;
}

// The draw and banner sinks: [object or null, function, index of the text argument(s)].
const SINKS = [
  ['UiText', 'draw', [1]],
  ['UiText', 'wrap', [0]],
  [null, '_text', [0]],
  [null, 'draw_string', [2]],
  [null, 'draw_string_outline', [2]],
  ['SimFx', 'banner', [1]],
  ['SimEvents', 'feed', [1, 2]],
];

// Text that reaches the screen through a helper or a variable, read by hand: a constant or variable by `name`, or a
// literal by its exact `text`. Each names its path to the screen.
const INDIRECT = [
  { file: 'render/core/look.gd', name: 'BOOT_WORDS', reach: 'default', surface: 'boot line', why: 'render/core/boot_entry.gd: RenderBoot.line(RenderLook.BOOT_WORDS) sets a Label' },
  { file: 'render/core/look.gd', name: 'STANCE_SHORT', reach: 'debug (F2 old HUD)', surface: 'old HUD', why: 'render/core/hud.gd _panel draws RenderLook.STANCE_SHORT' },
  { file: 'render/core/hud.gd', name: 'SYSTEM_KEYS', reach: 'debug (--keyhelp)', surface: 'debug key help', why: 'render/core/hud.gd _prompt wraps and draws it' },
  { file: 'render/core/hud.gd', name: 'msg', reach: 'debug (--keyhelp)', surface: 'debug key help', why: 'render/core/hud.gd _prompt draws msg[k] on a touch screen' },
  { file: 'ui/widgets/ui_licences.gd', text: 'Godot Engine', reach: 'default', surface: 'licences page', why: 'UiLicences.blocks() heading' },
  { file: 'ui/widgets/ui_licences.gd', text: 'Components built into Godot Engine', reach: 'default', surface: 'licences page', why: 'UiLicences.blocks() heading' },
  { file: 'ui/widgets/ui_licences.gd', text: 'Copyright %s. Licence: %s.', reach: 'default', surface: 'licences page', why: 'UiLicences.blocks() line per component' },
  { file: 'ui/widgets/ui_licences.gd', text: 'Licence texts', reach: 'default', surface: 'licences page', why: 'UiLicences.blocks() heading' },
  { file: 'ui/widgets/ui_glyphs.gd', text: 'Start', reach: 'default', surface: 'button glyphs', why: 'UiGlyphs: the Start button\'s label' },
  { file: 'ui/widgets/ui_glyphs.gd', text: 'Back', reach: 'default', surface: 'button glyphs', why: 'UiGlyphs: the Back button\'s label' },
  { file: 'ui/widgets/ui_split.gd', text: '%.1fk', reach: 'default', surface: 'split screen', why: '_dist_text: the distance chip (a number format)' },
  { file: 'ui/core/ui_stance.gd', text: ' (hold)', reach: 'default', surface: 'control legend', why: 'legend(): a stance\'s title + " (hold)" when its row has no _legend' },
  { file: 'ui/core/ui_data.gd', text: ' CHARGE', reach: 'default', surface: 'banner', why: 'UiData.banner(): a sim banner\'s " KI" becomes " CHARGE" in code' },
  { file: 'ui/hud/ui_hud.gd', text: ' vs ', reach: 'default', surface: 'feedback', why: 'the feedback report\'s setup line, shown in the review' },
];

// Where code text shows, by file. First match wins.
const CODE_REACH = [
  [/^render\/core\/hud\.gd$/, 'debug (F2 old HUD, --keyhelp, F3)', 'old HUD'],
  [/^sim\/.*/, 'default', 'banner'],
  [/^ui\/widgets\/ui_feed\.gd$/, 'debug (F4 feed)', 'director feed'],
  [/^ui\//, 'default', 'HUD'],
  [/^render\//, 'default', 'render'],
  [/^audio\//, 'default', 'audio'],
];

const SCAN_DIRS = ['ui', 'render', 'sim', 'audio'];
// Development-only folders: the demo, the mock feed and every tools/ or tests/ folder never ship text to a player.
const SKIP_DIR_RE = /(^|\/)(tools|tests|test|demo|mock|pending)(\/|$)/;

function gdFiles() {
  const out = [];
  const walk = (rel) => {
    for (const e of fs.readdirSync(path.join(ROOT, rel), { withFileTypes: true })) {
      const r = `${rel}/${e.name}`;
      if (e.isDirectory()) { if (!SKIP_DIR_RE.test(r)) walk(r); }
      else if (e.name.endsWith('.gd')) out.push(r);
    }
  };
  for (const d of SCAN_DIRS) if (exists(d)) walk(d);
  return out.sort();
}

function reachOf(file) {
  for (const [re, reach, surface] of CODE_REACH) if (re.test(file)) return { reach, surface };
  return { reach: 'default', surface: 'other' };
}

export function codeLiterals(src) {
  const toks = tokenize(src);
  const out = [];
  for (let k = 0; k < toks.length; k++) {
    const tk = toks[k];
    if (tk.t !== 'id' || !(k + 1 < toks.length && toks[k + 1].v === '(')) continue;
    for (const [obj, fn, argIdx] of SINKS) {
      if (tk.v !== fn) continue;
      const hasObj = k >= 2 && toks[k - 1].v === '.' && toks[k - 2].t === 'id';
      if (obj === null ? (hasObj && toks[k - 2].v !== 'self') : !(hasObj && toks[k - 2].v === obj)) continue;
      const args = argsOf(toks, k + 1);
      for (const a of argIdx) {
        if (a >= args.length) continue;
        const [from, to] = args[a];
        const parts = to - from > 1;
        for (const s of textLiterals(toks, from, to)) out.push({ line: s.line, text: s.v, sink: `${obj ? obj + '.' : ''}${fn}`, parts });
      }
    }
  }
  return out;
}

function namedLiterals(src, entry) {
  const toks = tokenize(src);
  if (entry.text !== undefined) return toks.filter((t) => t.t === 'str' && t.v === entry.text).slice(0, 1);
  for (let k = 0; k + 1 < toks.length; k++) {
    if ((toks[k].v !== 'const' && toks[k].v !== 'var') || toks[k + 1].v !== entry.name) continue;
    let j = k + 2;
    while (j < toks.length && toks[j].v !== '=' && toks[j].v !== ':=') j++;
    j++;
    if (j >= toks.length) return [];
    if (toks[j].t === 'str') return [toks[j]];
    if (toks[j].v === '[') return textLiterals(toks, j + 1, closeOf(toks, j) - 1);
  }
  return [];
}

// The English fallbacks in code: dict.get("key", "Words"), so a translation missing that key shows English. These are
// copies of data words, not new text, so they are counted apart from the rows.
export function fallbacks(src) {
  const toks = tokenize(src);
  const out = [];
  for (let k = 2; k + 1 < toks.length; k++) {
    if (toks[k].v !== 'get' || toks[k - 1].v !== '.' || toks[k + 1].v !== '(') continue;
    const args = argsOf(toks, k + 1);
    if (args.length < 2) continue;
    const [from, to] = args[1];
    if (to - from === 1 && toks[from].t === 'str' && /\p{L}{2}/u.test(toks[from].v) && /[A-Z ]/.test(toks[from].v)) {
      out.push({ line: toks[from].line, text: toks[from].v });
    }
  }
  return out;
}

function codeRows(fb) {
  const rows = [];
  for (const file of gdFiles()) {
    const src = rd(file);
    if (file.startsWith('ui/')) for (const f of fallbacks(src)) fb.push({ key: `${file}:${f.line}`, text: f.text });
    const { reach, surface } = reachOf(file);
    let fileReach = reach;
    let fileSurface = surface;
    for (const lit of codeLiterals(src)) {
      if (lit.sink === 'SimEvents.feed') { fileReach = 'debug (F4 feed)'; fileSurface = 'director feed'; }
      else { fileReach = reach; fileSurface = surface; }
      rows.push({ source: 'code', key: `${file}:${lit.line}`, file, surface: fileSurface, reach: fileReach, text: lit.text,
        hardcoded: true, sink: lit.sink, parts: lit.parts });
    }
  }
  for (const c of INDIRECT) {
    if (!exists(c.file)) continue;
    for (const s of namedLiterals(rd(c.file), c)) {
      rows.push({ source: 'code', key: `${c.file}:${s.line}`, file: c.file, surface: c.surface, reach: c.reach, text: s.v,
        hardcoded: true, sink: c.name ? `const ${c.name}` : 'indirect', parts: false, why: c.why });
    }
  }
  return rows;
}

// ---------------------------------------------------------------- Legal's cleared lines

const LEGAL_FILE = 'docs/legal/page-fixed-lines.md';

// Every line Legal has cleared word for word: the block quotes, and the quoted strings in the file (buttons, the AI
// line, the privacy and licence lines).
export function legalLines(md) {
  const out = new Set();
  for (const ln of md.split('\n')) {
    const m = ln.match(/^\s*>\s?(.*)$/);
    if (m && m[1].trim().length > 0) out.add(m[1].trim());
    for (const q of ln.matchAll(/"([^"]{4,})"/g)) out.add(q[1].trim());
  }
  return [...out];
}

const norm = (s) => s.replace(/\s+/g, ' ').trim();

// A string is cleared text when it is a cleared line, or every sentence of it sits inside one (the notice's title is
// the notice's first sentence). Short words ("safe") only count as a whole-string match.
export function isLegal(text, lines) {
  const t = norm(text);
  if (lines.includes(t)) return true;
  if (t.length < 20) return false;
  return lines.some((l) => l.length >= t.length && norm(l).includes(t));
}

// ---------------------------------------------------------------- the inventory

export function inventory() {
  const legal = exists(LEGAL_FILE) ? legalLines(rd(LEGAL_FILE)) : [];
  const fb = [];
  const rows = [...dataRows(), ...barkRows(), ...codeRows(fb)];
  for (const r of rows) {
    r.length = [...r.text].length;
    r.legal = isLegal(r.text, legal);
  }
  const order = { data: 0, barks: 1, code: 2 };
  rows.sort((a, b) => order[a.source] - order[b.source] || (a.key < b.key ? -1 : a.key > b.key ? 1 : 0) || (a.text < b.text ? -1 : 1));
  return { schema: 1, legal_file: LEGAL_FILE, rows, fallbacks: fb };
}

function summary(inv) {
  const rows = inv.rows;
  const by = (f) => rows.reduce((m, r) => { const k = f(r); m[k] = (m[k] || 0) + 1; return m; }, {});
  const lines = [];
  lines.push(`${rows.length} player-facing strings, ${rows.reduce((a, r) => a + r.length, 0)} characters.`);
  lines.push('');
  lines.push('By source:');
  for (const [k, v] of Object.entries(by((r) => r.source))) lines.push(`  ${k.padEnd(8)} ${v}`);
  lines.push('By surface:');
  for (const [k, v] of Object.entries(by((r) => r.surface)).sort()) lines.push(`  ${k.padEnd(24)} ${v}`);
  lines.push(`Legal's cleared lines (never altered): ${rows.filter((r) => r.legal).length}`);
  const hc = rows.filter((r) => r.hardcoded);
  lines.push('');
  lines.push(`Hard-coded strings that bypass ui/data: ${hc.length} (${hc.filter((r) => r.reach === 'default').length} in the default build)`);
  for (const r of hc) {
    lines.push(`  ${r.reach === 'default' ? 'LIVE ' : 'debug'}  ${r.key.padEnd(40)} ${(r.sink || '').padEnd(18)} ${JSON.stringify(r.text)}${r.parts ? '  (built from parts)' : ''}`);
  }
  lines.push('');
  lines.push(`English fallbacks in ui/ code (dict.get("key", "Words")): ${inv.fallbacks.length}. A translation that lacks the key shows these.`);
  return lines.join('\n');
}

function markdown(inv) {
  const esc = (s) => s.replace(/\|/g, '\\|').replace(/\n/g, '\\n');
  const out = ['| Key | Source file | Surface | Reach | Len | Flags | Text |', '| :-- | :-- | :-- | :-- | --: | :-- | :-- |'];
  for (const r of inv.rows) {
    const flags = [r.hardcoded ? 'HARDCODED' : '', r.parts ? 'parts' : '', r.legal ? 'LEGAL' : ''].filter(Boolean).join(' ');
    out.push(`| \`${r.key}\` | ${r.file} | ${r.surface} | ${r.reach} | ${r.length} | ${flags} | ${esc(r.text)} |`);
  }
  return out.join('\n');
}

// ---------------------------------------------------------------- self-test

function selfTest() {
  let fails = 0;
  const ok = (cond, msg) => { if (!cond) { fails++; console.log(`FAIL  ${msg}`); } };
  const lit = (src) => codeLiterals(src).map((l) => l.text);
  ok(JSON.stringify(lit('UiText.draw(ci, "Hello there", p, fs, c)')) === '["Hello there"]', 'a drawn literal is found');
  ok(lit('UiText.draw(ci, UiData.t("prompt.title"), p, fs, c)').length === 0, 'a lookup key is not text');
  ok(lit('UiText.draw(ci, x["label"], p, fs, c)').length === 0, 'a subscript is not text');
  ok(JSON.stringify(lit('_text("seed %d" % [a, "  PAUSED" if b else ""], v, 10, c, 1)')) === '["seed %d","  PAUSED"]', 'a format and its parts are found');
  ok(lit('UiText.draw(ci, "" if k == "mode" else y, p, fs, c)').length === 0, 'a compared string is not text, nor an empty one');
  ok(JSON.stringify(fallbacks('var w = str(d.get("close", "CLOSE"))').map((f) => f.text)) === '["CLOSE"]', 'an English fallback is found');
  ok(lit('# UiText.draw(ci, "commented", p, fs, c)').length === 0, 'a comment is skipped');
  ok(JSON.stringify(lit('SimFx.banner(S, "GUARD BREAK", "#ffd45a", 0.8)')) === '["GUARD BREAK"]', 'a sim banner is found and its colour is not');
  ok(JSON.stringify(lit('SimEvents.feed(S, "LAUNCH", "slam " + str(n))')) === '["LAUNCH","slam "]', 'both feed fields are found');
  ok(lit('UiText.draw(ci, &"name", p, fs, c)').length === 0, 'a StringName is not text');
  ok(lit('UiText.draw(ci, str(r["word"]), p, fs, c)').length === 0, 'a data word through str() is not a literal');
  ok(JSON.stringify(lit('UiText.draw(ci,\n  "two\\nlines",\n  p, fs, c)')) === '["two\\nlines"]', 'a call over lines and an escape');
  ok(codeLiterals('UiText.draw(ci,\n"a b",p,fs,c)')[0].line === 2, 'the literal keeps its own line');
  ok(lit('foo.draw_string(f, p, "not ours")').length === 0, 'draw_string on another object is not a sink');
  ok(isText('Hold Guard') && !isText('touch-simple') && !isText('#5aaaff') && !isText('res://x') && !isText('42'), 'the data filter');
  ok(!glyphIsText('LB') && glyphIsText('Space'), 'button letters stay, key names are text');
  const legal = legalLines('> This game contains flashing effects. It flashes.\nButtons: **"I understand, start"** and **"Not now"**.');
  ok(isLegal('This game contains flashing effects.', legal), 'a cleared sentence inside a cleared line');
  ok(isLegal('Not now', legal) && !isLegal('Not', legal), 'a cleared button is whole-string only');
  ok(!isLegal('Something the notice never says at all.', legal), 'other text is not cleared');
  const rows = [];
  walkData('t', { note: 'skip me', a: { label: 'Keep me', id: 'x_y', _about: 'skip', choices: ['off', 'On air'] } }, [], rows);
  ok(rows.length === 1 && rows[0].key === 't:a.label', 'notes, ids and choices are left out of data');
  const inv = inventory();
  ok(inv.rows.length > 500, `the live tree has its strings (${inv.rows.length})`);
  ok(inv.rows.some((r) => r.key === 'terms:prompt.menu_notice' && r.legal), 'the in-game notice is marked as Legal\'s');
  ok(inv.rows.some((r) => r.source === 'code' && r.text === 'Preparing the graphics'), 'the boot line is found');
  ok(JSON.stringify(inventory()) === JSON.stringify(inv), 'two runs give the same inventory');
  console.log(fails === 0 ? 'strings self-test: all passed' : `strings self-test: ${fails} failed`);
  return fails === 0 ? 0 : 1;
}

// ---------------------------------------------------------------- main

const isMain = process.argv[1] && path.resolve(process.argv[1]) === path.resolve(new URL(import.meta.url).pathname);
if (isMain) {
  const args = new Set(process.argv.slice(2));
  if (args.has('--self-test')) process.exit(selfTest());
  const inv = inventory();
  if (args.has('--json')) process.stdout.write(JSON.stringify(inv, null, 1) + '\n');
  else if (args.has('--md')) process.stdout.write(markdown(inv) + '\n');
  else process.stdout.write(summary(inv) + '\n');
}
