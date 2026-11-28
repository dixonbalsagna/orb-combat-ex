// Other people's code in the game, and its notices (Tools, 2026-11-28; Legal RL-289). The list is tools/third-party.json; tools/desktop-package.mjs writes the notices and checks packages against it.
//   node tools/third-party.mjs --check     CI: a copy of a listed snippet in a shipped file that its row does not name fails; a row whose code is gone is said (take it out)
//   node tools/third-party.mjs --list      where each snippet is now
// It finds the listed snippets by a line of their code. It cannot find code nobody has listed.
import { existsSync, readFileSync, readdirSync } from 'node:fs';
import { join, relative, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const REPO = resolve(fileURLToPath(new URL('..', import.meta.url)));
export const LIST = join(REPO, 'tools', 'third-party.json');
/** The folders whose files go into a built game (export_presets.cfg leaves the rest out). */
export const SHIPPED = ['audio', 'data', 'net', 'render', 'sim', 'ui'];
const TEXT = /\.(gd|gdshader|gdshaderinc|tres|tscn|json|cfg)$/i;
const LEFT_OUT = new Set(['tools', 'pending', 'runs', '.godot', 'node_modules']);

export const MIT_TEXT = `Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.`;

export function loadSnippets(file = LIST) {
  const rows = JSON.parse(readFileSync(file, 'utf8')).snippets;
  for (const r of rows) {
    if (!r.id || !r.title || !r.author || typeof r.marker !== 'string' || r.marker.length < 12 || !Array.isArray(r.files)) throw new Error(`third-party.json: row "${r.id}" needs a title, an author, a marker of 12 characters or more and files`);
    if (r.license !== null && !(r.license === 'MIT' && r.copyright && r.source)) throw new Error(`third-party.json: row "${r.id}": a license is MIT (with its copyright line and source) or null (none known)`);
  }
  return rows;
}

function shippedFiles(root) {
  const out = [];
  const walk = (dir) => {
    for (const e of readdirSync(dir, { withFileTypes: true })) {
      if (e.isDirectory()) { if (!LEFT_OUT.has(e.name)) walk(join(dir, e.name)); }
      else if (TEXT.test(e.name)) out.push(join(dir, e.name));
    }
  };
  for (const d of SHIPPED) if (existsSync(join(root, d))) walk(join(root, d));
  return out;
}

/** Where each row's code is in the tree at `root`: a Map of row id to the files holding its marker. */
export function inTree(root, rows = loadSnippets()) {
  const found = new Map(rows.map((r) => [r.id, []]));
  for (const f of shippedFiles(root)) {
    const text = readFileSync(f, 'utf8');
    for (const r of rows) if (text.includes(r.marker)) found.get(r.id).push(relative(root, f).split('\\').join('/'));
  }
  return found;
}

/** The rows whose code a built program (or its pack) holds. Shader sources are stored in the pack as text. */
export function inProgram(bytes, rows = loadSnippets()) { return rows.filter((r) => bytes.includes(Buffer.from(r.marker, 'utf8'))); }

/** The NOTICES.txt section for the rows that carry a license; '' when there are none. Pure. */
export function noticeSection(rows) {
  const mine = rows.filter((r) => r.license);
  if (!mine.length) return '';
  const out = ['SHADER CODE BY OTHER PEOPLE', 'Parts of the drawing code in this game were written by the people below and are used under the MIT License:', ''];
  for (const r of mine) out.push(`- ${r.title}, by ${r.author} (${r.source})`, `  ${r.copyright}`);
  out.push('', MIT_TEXT, '');
  return out.join('\n');
}

/** What is wrong with a package whose program holds `held` rows and whose NOTICES.txt is `notices`. Pure. */
export function noticeProblems(held, notices, { testers = false } = {}) {
  const out = [];
  const body = String(notices).split('\r').join('');
  for (const r of held) {
    if (!r.license) { if (testers) out.push(`the game holds code with no known terms (${r.title}, row ${r.id}): an outside-testers package cannot be made until it is replaced (RL-292)`); continue; }
    if (!body.includes(r.title) || !body.includes(r.author) || !body.includes(r.copyright)) out.push(`NOTICES.txt does not carry the notice for the ${r.title} by ${r.author}, which the game holds (RL-289)`);
    else if (!body.includes(MIT_TEXT)) out.push(`NOTICES.txt names the ${r.title} but not the MIT License's words (RL-289)`);
  }
  return out;
}

/** The ratchet: { problems, notes } for the tree at `root`. */
export function check(root = REPO, rows = loadSnippets()) {
  const problems = [], notes = [];
  const found = inTree(root, rows);
  for (const r of rows) {
    const at = found.get(r.id);
    for (const f of at) if (!r.files.includes(f)) problems.push(`${f} holds the ${r.title} (row ${r.id} of tools/third-party.json), which does not name it: copied code is listed and credited, or replaced (RL-296)`);
    if (!at.length) notes.push(`row ${r.id}: no copy is left in the shipped folders: take the row out of tools/third-party.json`);
    else for (const f of r.files) if (!at.includes(f)) notes.push(`row ${r.id}: ${f} no longer holds it: take it out of the row's files`);
  }
  return { problems, notes };
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  if (process.argv.includes('--list')) {
    for (const [id, files] of inTree(REPO)) console.log(`${id}: ${files.join(', ') || 'no copy left'}`);
    process.exit(0);
  }
  const r = check();
  for (const n of r.notes) console.log('note: ' + n);
  for (const p of r.problems) console.error('third party: ' + p);
  console.log(r.problems.length ? `third-party code check FAILED: ${r.problems.length}` : `third-party code check ok: ${loadSnippets().length} listed snippet(s), no unlisted copy of them`);
  process.exit(r.problems.length ? 1 : 0);
}
