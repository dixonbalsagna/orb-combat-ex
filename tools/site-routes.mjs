// The routes that could lift Reduce flashing's lock in the interim export (Legal's RL-195 condition (b), 2026-10-27): "normal mode is unreachable by any route: no URL word, saved setting or
// debug key lifts lock_reduce_flashing". A STATIC scan of the exported tree's GDScript (ui/ and render/, not the tools, tests and demos folders: they are not in a player's build path);
// it names the routes it knows and fails on each one that is not shut. It cannot prove there is no other route: a new way in is a new rule here.
//
//   routes of a visitor: a URL word (the page's `?word`), a saved setting (the prefs file), a screen or key (the settings screen, a debug key), the capture hook.
//   1. the flag itself: UiData.rf_locked() reads features.lock_reduce_flashing; no production code overrides a feature (UiData.set_feature);
//   2. the option: every production write of "reduce_flashing" (set_option, settings_set, opts[...] =) that is not the literal true sits in a function that asks UiData.rf_locked();
//   3. the register: no production code sets reduced_flashing, force_reduced or flash_calm to a literal false or to a negation (the copy from the option is the only way);
//   4. a debug key: flash_legacy (F8, "the flashes' shapes before Legal's conditions") is not written in a function that does not ask UiData.rf_locked();
//   5. the capture hook (?flashcap=1: window.__flashcap.start(...) sets the option by itself) is attached only under `UiData.feature("capture_hook") or not UiData.rf_locked()`, and the
//      export's ui/data/features.json does not set capture_hook true: a build-time feature (the nightly's measurement export sets it; the public export does not), never a URL word or a
//      console flag;
//   6. the URL words: what a public page honours is URL_ARGS minus LOCAL_ONLY_ARGS, and that is exactly the reviewed look words of tools/site-url-words.json (skyreact, panhaze, nopanhaze,
//      keyhelp); the words that start a run with no gate or intro (study, flashcap, nointro) are local-only. What the EXPORTED build does with them is tools/check-site-hook.mjs.
import { existsSync, readFileSync, readdirSync } from 'node:fs';
import { join, relative, sep } from 'node:path';

const SKIP = /(^|\/)(tools|tests|test|demo)(\/|$)/;

function gdFiles(root) {
  const out = [];
  const walk = (d) => {
    let ents = [];
    try { ents = readdirSync(d, { withFileTypes: true }); } catch { return; }
    for (const e of ents) {
      const p = join(d, e.name);
      const rel = relative(root, p).split(sep).join('/');
      if (e.isDirectory()) { if (!SKIP.test(rel + '/')) walk(p); }
      else if (e.name.endsWith('.gd')) out.push(rel);
    }
  };
  walk(join(root, 'ui'));
  walk(join(root, 'render'));
  return out;
}

/** The text of the function that holds position `at` of `text` (from its `func` line to the next column-0 line that is not a continuation). */
function enclosing(text, at) {
  const head = text.slice(0, at);
  const start = Math.max(head.lastIndexOf('\nfunc '), head.lastIndexOf('\nstatic func '));
  const tail = text.slice(at);
  const m = /\n(?:static func |func |class |var |const |signal |@)/.exec(tail);
  return text.slice(start < 0 ? 0 : start, at + (m ? m.index : tail.length));
}

const lineOf = (text, at) => text.slice(0, at).split('\n').length;

/** The problems of a tree (an array of strings, empty when every known route is shut). */
export function scanRoutes(root, opts = {}) {
  const problems = [];
  const files = gdFiles(root);
  const text = new Map(files.map((f) => [f, readFileSync(join(root, f), 'utf8')]));
  const bad = (m) => problems.push(m);

  // 1. the flag
  const ud = text.get('ui/core/ui_data.gd');
  if (!ud || !/func rf_locked\(\)\s*->\s*bool:\s*\n\s*return feature\("lock_reduce_flashing"\)/.test(ud)) bad('ui/core/ui_data.gd: rf_locked() is not "return feature(\\"lock_reduce_flashing\\")" (the flag the lock reads)');
  for (const [f, t] of text) {
    if (f === 'ui/core/ui_data.gd') continue;
    const m = /\bset_feature\s*\(/.exec(t);
    if (m) bad(`${f}:${lineOf(t, m.index)} calls set_feature: a production override of a feature flag could lift the lock`);
  }

  // 2. the option's writers
  const writers = [
    /set_option\(\s*"reduce_flashing"\s*,\s*([^\n]*?)\)\s*(?:#.*)?$/gm,
    /settings_set\(\s*"reduce_flashing"\s*,\s*([^\n]*?)\)\s*(?:#.*)?$/gm,
    /\[\s*"reduce_flashing"\s*\]\s*=(?!=)\s*([^\n#]*)/g,
  ];
  for (const [f, t] of text) for (const re of writers) {
    re.lastIndex = 0;
    let m;
    while ((m = re.exec(t))) {
      if (/^\s*true\s*$/.test(m[1])) continue;   // writing On never lifts it
      if (!/rf_locked\(\)/.test(enclosing(t, m.index))) bad(`${f}:${lineOf(t, m.index)} writes the "reduce_flashing" option (${m[1].trim().slice(0, 40)}) in a function that does not ask UiData.rf_locked()`);
    }
  }

  // 2b. the saved setting and the screen: the two doors every saved or chosen value goes through ask the lock
  const hud = text.get('ui/hud/ui_hud.gd');
  for (const fn of ['load_saved_options', 'settings_set']) {
    const i = hud ? hud.indexOf(`\nfunc ${fn}(`) : -1;
    if (i < 0) bad(`ui/hud/ui_hud.gd has no ${fn}(): the saved setting's door is not where the scan looks for it`);
    else if (!/rf_locked\(\)/.test(enclosing(hud, i + 7))) bad(`ui/hud/ui_hud.gd:${lineOf(hud, i + 1)} ${fn}() does not ask UiData.rf_locked(): a saved Off or a chosen Off could lift the lock`);
  }

  // 3. the register
  for (const [f, t] of text) {
    const re = /\b(reduced_flashing|force_reduced|flash_calm)\s*=(?!=)\s*([^\n#]*)/g;
    let m;
    while ((m = re.exec(t))) {
      const before = t.slice(t.lastIndexOf('\n', m.index) + 1, m.index);
      if (/^\s*(static\s+)?var\s/.test(before) || /^\s*(static\s+)?var\s*$/.test(before)) continue;   // a declaration's default
      if (/^\s*false\s*$/.test(m[2]) || /^\s*not\s/.test(m[2])) bad(`${f}:${lineOf(t, m.index)} sets ${m[1]} to "${m[2].trim().slice(0, 40)}": the register's reduced mode would be lifted by code, not by the locked option`);
    }
  }

  // 4. a debug key
  for (const [f, t] of text) {
    const re = /\bflash_legacy\s*=(?!=)/g;
    let m;
    while ((m = re.exec(t))) {
      const before = t.slice(t.lastIndexOf('\n', m.index) + 1, m.index);
      if (/^\s*(static\s+)?var\s/.test(before)) continue;
      if (!/rf_locked\(\)/.test(enclosing(t, m.index))) bad(`${f}:${lineOf(t, m.index)} a debug key writes flash_legacy (the flashes' shapes before Legal's conditions) in a function that does not ask UiData.rf_locked()`);
    }
  }

  // 5. a URL word: the capture hook
  const main = text.get('render/core/main.gd');
  if (main) {
    const i = main.indexOf('FlashCapture.new(');
    if (i >= 0) {
      const lines = main.slice(0, i).split('\n');
      const guard = lines.slice(-3).join('\n');   // the `if` above it and the one before
      if (!/UiData\.feature\("capture_hook"\)/.test(guard) || !/rf_locked\(\)/.test(guard)) bad(`render/core/main.gd:${lineOf(main, i)} attaches the capture hook (?flashcap=1) without \`UiData.feature("capture_hook") or not UiData.rf_locked()\`: a locked export could attach it, and window.__flashcap.start turns Reduce flashing off`);
    }
  }
  let feat = null;
  try { feat = JSON.parse(readFileSync(join(root, 'ui/data/features.json'), 'utf8')).features || {}; } catch { /* the lock check reports an unreadable file */ }
  if (feat && feat.capture_hook === true) bad('ui/data/features.json features.capture_hook is true: the public export carries the capture hook (the measurement export sets it, not this one)');

  // 6. the URL words
  if (main) {
    const list = (name) => { const m = new RegExp(`^const ${name}: Array = \\[([^\\]]*)\\]`, 'm').exec(main); return m ? [...m[1].matchAll(/"([^"]+)"/g)].map((x) => x[1]) : null; };
    const urlArgs = list('URL_ARGS'), localOnly = list('LOCAL_ONLY_ARGS');
    let words = opts.words;
    if (!words) { try { words = JSON.parse(readFileSync(join(opts.toolsDir || import.meta.dirname, 'site-url-words.json'), 'utf8')); } catch { words = null; } }
    if (!urlArgs || !localOnly) bad('render/core/main.gd: URL_ARGS or LOCAL_ONLY_ARGS could not be read (the URL words of a public page are not where the scan looks for them)');
    else if (!words || !Array.isArray(words.public)) bad('tools/site-url-words.json is missing or has no "public" list: the reviewed URL words of a public page');
    else {
      for (const w of urlArgs.filter((x) => !localOnly.includes(x))) if (!words.public.includes(w)) bad(`render/core/main.gd: the URL word "${w}" is honoured on a public page and is not reviewed (tools/site-url-words.json): gate it in LOCAL_ONLY_ARGS, or have it reviewed and run the flash clips like any look change`);
      for (const w of words.bypass || ['study', 'flashcap', 'nointro']) if (urlArgs.includes(w) && !localOnly.includes(w)) bad(`render/core/main.gd: the URL word "${w}" starts a run with no gate or intro and is not in LOCAL_ONLY_ARGS`);
    }
  }
  return problems;
}
