// Do the workflow files parse? (2026-10-27: an unquoted ': ' in a step name broke .github/workflows/ci.yml and nothing on a developer's PC said so before the push.) There is no YAML library in the
// repository (zero dependencies, node only), so this reads the SUBSET of YAML that workflow and action files use and fails on what GitHub's parser refuses or reads differently from the author:
//   - a tab in an indentation;
//   - a plain scalar that holds ': ' (a mapping value where none is allowed: the broken step name), or ends in ':' inside a sequence item's text, or starts with an indicator
//     (@ ` % * & ! | > { [ ? , # ' " are handled: only a started quote or bracket that is not closed is an error);
//   - an unclosed quote or flow bracket on a line;
//   - a duplicate key in one mapping;
//   - indentation that goes deeper where nothing opened a block, or that falls back to no enclosing level;
//   - a sequence item and a mapping key mixed at one level.
// Block scalars (| and >) and their content are skipped; comments are stripped outside quotes. It is a lint for the way these files are written here, not a YAML parser: a file it passes can still be
// refused by GitHub for a reason that is not syntax (an unknown key, a bad expression); a file it fails is wrong.
//   node tools/check-workflows.mjs [<file or folder>...]     default: .github/workflows and .github/actions (every .yml and .yaml)
import { existsSync, readFileSync, readdirSync, statSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

/** Strips a trailing comment (a # that starts the line or follows whitespace, outside quotes). */
function stripComment(s) {
  let q = null;
  for (let i = 0; i < s.length; i++) {
    const c = s[i];
    if (q) { if (c === '\\' && q === '"') i++; else if (c === q) { if (q === "'" && s[i + 1] === "'") i++; else q = null; } continue; }
    if ((c === '"' || c === "'") && (i === 0 || /[\s:\[{,-]/.test(s[i - 1]))) { q = c; continue; }
    if (c === '#' && (i === 0 || /\s/.test(s[i - 1]))) return s.slice(0, i);
  }
  return s;
}

/** Whether the quotes and flow brackets of a value are closed. */
function closed(v) {
  const s = v.trim();
  if (s[0] === '"') { const m = /^"(?:[^"\\]|\\.)*"\s*$/.test(s); return m; }
  if (s[0] === "'") { return /^'(?:[^']|'')*'\s*$/.test(s); }
  if (s[0] === '[' || s[0] === '{') {
    let depth = 0, q = null;
    for (let i = 0; i < s.length; i++) {
      const c = s[i];
      if (q) { if (c === '\\' && q === '"') i++; else if (c === q) q = null; continue; }
      if (c === '"' || c === "'") { q = c; continue; }
      if (c === '[' || c === '{') depth++;
      if (c === ']' || c === '}') depth--;
    }
    return depth === 0 && !q;
  }
  return true;
}

/** Splits "key: value" at the first ': ' (or a trailing ':') outside quotes; null when the text is not a mapping entry. */
function splitKey(s) {
  let q = null;
  for (let i = 0; i < s.length; i++) {
    const c = s[i];
    if (q) { if (c === '\\' && q === '"') i++; else if (c === q) q = null; continue; }
    if ((c === '"' || c === "'") && i === 0) { q = c; continue; }
    if (c === ':' && (i === s.length - 1 || s[i + 1] === ' ')) return { key: s.slice(0, i).trim().replace(/^["']|["']$/g, ''), value: s.slice(i + 1).trim() };
  }
  return null;
}

/** The problems of a YAML text (workflow subset): [{ line, message }]. */
export function lintYaml(text) {
  const problems = [];
  const err = (line, message) => problems.push({ line, message });
  const raw = String(text).replace(/\r\n/g, '\n').split('\n');
  const stack = [];          // { indent, kind: 'map' | 'seq', keys: Set }
  let blockParent = null;    // the indent of the line that opened a block scalar: deeper lines are its content
  let opens = false;         // the previous line opened a nested block (ended with ':' and no value, a lone '-', or '- key:')
  let prevIndent = -1;
  let prevAt = -1;           // the column where the previous line's content began (after any "- "): the next key of a sequence item's mapping sits there
  for (let n = 0; n < raw.length; n++) {
    const line = raw[n];
    const indent = line.length - line.trimStart().length;
    if (blockParent !== null) { if (line.trim() === '' || indent > blockParent) continue; blockParent = null; }
    const body = stripComment(line).trimEnd();
    if (body.trim() === '') continue;
    if (/^\s*\t/.test(line) || /^ *\t/.test(line)) { err(n + 1, 'a tab in the indentation'); continue; }
    if (body.trim() === '---' || body.trim() === '...') continue;
    // indentation: deeper only where a block was opened; a fall back must land on an enclosing level
    if (indent > prevIndent && prevIndent >= 0 && !opens && indent !== prevAt) { err(n + 1, 'the indentation goes deeper where nothing opened a block (a continuation line of a plain value, or a stray indent)'); }
    while (stack.length && stack[stack.length - 1].indent > indent) stack.pop();
    let text = body.trim();
    let at = indent;
    let seqItem = false;
    while (text.startsWith('- ') || text === '-') {   // one or more sequence markers: "- - x" is rare; "- key: v" opens a map inside the item
      seqItem = true;
      let top = stack[stack.length - 1];
      if (!top || top.indent < at) { top = { indent: at, kind: 'seq', keys: new Set() }; stack.push(top); }
      else if (top.indent === at && top.kind !== 'seq') { err(n + 1, 'a sequence item at the indentation of a mapping key (a mapping and a sequence mixed at one level)'); }
      const rest = text.slice(1);
      const pad = rest.length - rest.trimStart().length;
      text = rest.trimStart();
      at += 1 + pad;
      if (text === '') break;
    }
    let op = false;
    if (text !== '') {
      const kv = splitKey(text);
      if (kv && !/^[\[{"']/.test(text.slice(0, 1)) || (kv && /^["']/.test(text[0]))) {
        // a mapping entry
        let top = stack[stack.length - 1];
        if (!top || top.indent < at) { top = { indent: at, kind: 'map', keys: new Set() }; stack.push(top); }
        else if (top.indent === at && top.kind === 'seq') { err(n + 1, 'a mapping key at the indentation of a sequence item (a mapping and a sequence mixed at one level)'); }
        if (top.keys.has(kv.key)) err(n + 1, `the key "${kv.key}" is repeated in one mapping`);
        top.keys.add(kv.key);
        const v = kv.value;
        if (v === '') op = true;
        else if (/^[|>][+-]?\d*$/.test(v)) blockParent = indent;
        else {
          if (!closed(v)) err(n + 1, `an unclosed quote or bracket in the value of "${kv.key}"`);
          else if (!/^["'\[{]/.test(v) && /: /.test(v)) err(n + 1, `the plain value of "${kv.key}" holds ": " (a mapping value is not allowed here): quote it`);
          else if (!/^["'\[{]/.test(v) && /:$/.test(v)) err(n + 1, `the plain value of "${kv.key}" ends in ":" : quote it`);
        }
      } else if (seqItem) {
        // a plain scalar item ("- run: x" was a mapping entry above): ": " inside it is an error too
        if (!closed(text)) err(n + 1, 'an unclosed quote or bracket in a sequence item');
        else if (!/^["'\[{]/.test(text) && /: /.test(text)) err(n + 1, 'a plain sequence item holds ": ": quote it');
      } else if (!closed(text)) err(n + 1, 'an unclosed quote or bracket');
      else if (stack.length && !seqItem) err(n + 1, 'a line that is neither a mapping entry nor a sequence item');
    } else op = true;   // a lone '-' opens a block
    opens = op;
    prevIndent = indent;
    prevAt = seqItem ? at : -1;
  }
  return problems;
}

/** The yml/yaml files under a path (a file, or a folder searched downwards). */
function filesUnder(p) {
  if (!existsSync(p)) return [];
  if (statSync(p).isFile()) return [p];
  return readdirSync(p, { withFileTypes: true }).flatMap((e) => (e.isDirectory() ? filesUnder(join(p, e.name)) : /\.ya?ml$/i.test(e.name) ? [join(p, e.name)] : []));
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const args = process.argv.slice(2);
  const roots = args.length ? args : ['.github/workflows', '.github/actions'];
  const files = roots.flatMap((r) => filesUnder(resolve(r))).sort();
  if (!files.length) { console.error('check-workflows: no yml or yaml file found'); process.exit(2); }
  let bad = 0;
  for (const f of files) for (const p of lintYaml(readFileSync(f, 'utf8'))) { console.error(`${f}:${p.line}: ${p.message}`); bad++; }
  if (bad) { console.error(`check-workflows FAILED: ${bad} problem${bad === 1 ? '' : 's'} in ${files.length} files`); process.exit(1); }
  console.log(`check-workflows ok: ${files.length} files`);
}
