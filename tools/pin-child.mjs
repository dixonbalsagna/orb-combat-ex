// The words-only child of the live pin (Legal RL-209 (b)): the pin's commit plus ONLY the cleared words of the game's ui/data strings, listed in tools/pin-child.json, and nothing else.
//
//   node tools/pin-child.mjs --check                       lists the strings the child changes and proves nothing else in ui/data differs from the pin
//   node tools/pin-child.mjs --patch <file>                the same, plus a patch against the pin's commit (git apply, a/ and b/ prefixes)
//   node tools/pin-child.mjs --tree <dir>                  writes the changed files into <dir> (a checkout or export of the pin): ui/data/<file> only
//   node tools/pin-child.mjs --commit-id                   the child commit's id, computed in a throwaway object directory (the repo is not written): author, dates and message are fixed in the config
//   node tools/pin-child.mjs --recipe --tree <dir>         prints the git plumbing that makes that same commit for real, without touching the work tree, the index or a branch (the EP runs it; <dir> = --tree's files)
//   [--root <repo>] [--config <tools/pin-child.json>]
// How: each entry names a string in the pin's file (a JSON pointer, or the item with a key of a value and its field) and the same string, as the cleared words, in the commit `from`. The pin's TEXT is
// edited (the old string as JSON, which must occur once in the file, becomes the new one), so the formatting is untouched. Then the child's parsed JSON is compared with the pin's parsed JSON with
// only the listed strings changed: any other difference fails. Exit 0 when it holds, 1 when it does not, 2 on bad input.
import { execFileSync } from 'node:child_process';
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { isDeepStrictEqual } from 'node:util';

const here = dirname(fileURLToPath(import.meta.url));
export const CONFIG = join(here, 'pin-child.json');

const parts = (pointer) => pointer.split('/').slice(1).map((p) => p.replace(/~1/g, '/').replace(/~0/g, '~'));
/** The value at a JSON pointer, or undefined. */
export function getAt(obj, path) {
  let v = obj;
  for (const k of path) { if (v === null || typeof v !== 'object' || !(k in v)) return undefined; v = v[k]; }
  return v;
}
/** The path (an array of keys) of an entry: its pointer, or the first object anywhere with `locate.key === locate.equals`, then `field`. */
export function pathOf(obj, entry) {
  if (entry.pointer) return parts(entry.pointer);
  const found = [];
  const walk = (v, p) => {
    if (v && typeof v === 'object') {
      if (!Array.isArray(v) && v[entry.locate.key] === entry.locate.equals) found.push(p);
      for (const k of Object.keys(v)) walk(v[k], [...p, Array.isArray(v) ? Number(k) : k]);
    }
  };
  walk(obj, []);
  if (found.length !== 1) throw new Error(`${entry.file}: ${found.length} items with ${entry.locate.key} ${entry.locate.equals} (exactly one expected)`);
  return [...found[0], entry.field];
}
const setAt = (obj, path, value) => { const parent = getAt(obj, path.slice(0, -1)); parent[path[path.length - 1]] = value; };

/**
 * The child's files. `readPin(file)` and `readFrom(file)` return a file's text at the pin and at the source commit. Returns { texts: { file: text }, changes: [{ file, where, old, new, row }] }.
 * Throws when a string is missing, equal, or not found exactly once in the pin's text.
 */
export function buildChild(readPin, readFrom, config) {
  const byFile = new Map();
  for (const e of config.words) { if (!byFile.has(e.file)) byFile.set(e.file, []); byFile.get(e.file).push(e); }
  const texts = {};
  const changes = [];
  for (const [file, entries] of byFile) {
    let text = readPin(file);
    const pinObj = JSON.parse(text), fromObj = JSON.parse(readFrom(file));
    for (const e of entries) {
      const pp = pathOf(pinObj, e), fp = pathOf(fromObj, e);
      const oldV = getAt(pinObj, pp), newV = getAt(fromObj, fp);
      const where = `${file} ${pp.join('/')}`;
      if (typeof oldV !== 'string') throw new Error(`${where}: not a string in the pin`);
      if (typeof newV !== 'string') throw new Error(`${where}: not a string in ${config.from.slice(0, 8)} (${fp.join('/')})`);
      if (oldV === newV) throw new Error(`${where}: the same in both (nothing to change; remove the entry)`);
      const a = JSON.stringify(oldV), n = text.split(a).length - 1;
      if (n !== 1) throw new Error(`${where}: the pin's text holds that string ${n} times (exactly one expected)`);
      text = text.replace(a, () => JSON.stringify(newV));
      changes.push({ file, where, old: oldV, new: newV, row: e.row });
    }
    texts[file] = text;
  }
  return { texts, changes };
}

/** Proves the child's parsed files equal the pin's parsed files with only the listed strings changed. Returns the problems (empty when it holds). */
export function proveWordsOnly(readPin, config, texts, readFrom) {
  const problems = [];
  const byFile = new Map();
  for (const e of config.words) { if (!byFile.has(e.file)) byFile.set(e.file, []); byFile.get(e.file).push(e); }
  for (const [file, entries] of byFile) {
    const expect = JSON.parse(readPin(file));
    const fromObj = JSON.parse(readFrom(file));
    for (const e of entries) setAt(expect, pathOf(expect, e), getAt(fromObj, pathOf(fromObj, e)));
    let child;
    try { child = JSON.parse(texts[file]); } catch (err) { problems.push(`${file}: the child's text is not JSON (${err.message})`); continue; }
    if (!isDeepStrictEqual(child, expect)) problems.push(`${file}: the child differs from the pin by more than the listed strings`);
  }
  return problems;
}

const git = (root, args) => execFileSync('git', args, { cwd: root, encoding: 'utf8', maxBuffer: 1 << 28 });

/** A unified diff of the pin's files against the child's, as `git apply` takes it (a/ and b/ prefixes). */
export function patchOf(readPin, texts) {
  const d = mkdtempSync(join(tmpdir(), 'pin-child-'));
  try {
    for (const [file, text] of Object.entries(texts)) {
      for (const side of ['a', 'b']) { const f = join(d, side, ...file.split('/')); mkdirSync(dirname(f), { recursive: true }); writeFileSync(f, side === 'a' ? readPin(file) : text); }
    }
    let out = '';
    try { out = execFileSync('git', ['-c', 'core.autocrlf=false', 'diff', '--no-index', '--no-color', 'a', 'b'], { cwd: d, encoding: 'utf8', maxBuffer: 1 << 26 }); } catch (e) { out = e.stdout || ''; }   // exit 1 means "there are differences"
    return out.replace(/^diff --git a\/a\/(\S+) b\/b\/(\S+)$/gm, 'diff --git a/$1 b/$2').replace(/^--- a\/a\//gm, '--- a/').replace(/^\+\+\+ b\/b\//gm, '+++ b/');
  } finally { rmSync(d, { recursive: true, force: true }); }
}

const identity = (c) => ({ GIT_AUTHOR_NAME: c.name, GIT_AUTHOR_EMAIL: c.email, GIT_AUTHOR_DATE: c.date, GIT_COMMITTER_NAME: c.name, GIT_COMMITTER_EMAIL: c.email, GIT_COMMITTER_DATE: c.date });

/**
 * The id of the child commit, made WITHOUT writing to the repo: every object goes to a throwaway object directory that reads the repo's through an alternate. The author, committer, dates and
 * message are fixed by the config, so the same commit made for real by the recipe has the same id (a pin can name it before the commit exists). `texts` are the changed files' text.
 */
export function childCommitId(root, config, texts) {
  const tmp = mkdtempSync(join(tmpdir(), 'pin-child-objects-'));
  try {
    const objects = resolve(root, git(root, ['rev-parse', '--git-path', 'objects']).trim());
    const env = { ...process.env, ...identity(config.commit), GIT_OBJECT_DIRECTORY: tmp, GIT_ALTERNATE_OBJECT_DIRECTORIES: objects, GIT_INDEX_FILE: join(tmp, 'index') };
    const run = (args, input) => execFileSync('git', ['-c', 'commit.gpgsign=false', '-c', 'core.autocrlf=false', ...args], { cwd: root, env, encoding: 'utf8', input, maxBuffer: 1 << 26 }).trim();
    run(['read-tree', config.pin]);
    for (const [file, text] of Object.entries(texts)) {
      const mode = run(['ls-tree', config.pin, '--', file]).split(/\s+/)[0];
      const blob = run(['hash-object', '-w', '--no-filters', '--stdin'], text);
      run(['update-index', '--cacheinfo', `${mode},${blob},${file}`]);
    }
    const tree = run(['write-tree']);
    return run(['commit-tree', tree, '-p', config.pin, '-m', config.commit.message]);
  } finally { rmSync(tmp, { recursive: true, force: true }); }
}

/** The git plumbing that makes the child commit from the pin for real, without touching the work tree, the index or a branch: it prints the same id as childCommitId. `dir` holds the changed files at their paths. */
export function recipe(config, dir) {
  const files = [...new Set(config.words.map((w) => w.file))];
  const c = config.commit;
  return [
    `# the child commit: the pin's tree with ${files.length} ui/data files replaced; run in the repo root with Git Bash. Nothing here touches the work tree, the index or a branch.`,
    `export GIT_AUTHOR_NAME="${c.name}" GIT_AUTHOR_EMAIL="${c.email}" GIT_AUTHOR_DATE="${c.date}" GIT_COMMITTER_NAME="${c.name}" GIT_COMMITTER_EMAIL="${c.email}" GIT_COMMITTER_DATE="${c.date}"`,
    `export GIT_INDEX_FILE="$(mktemp -u)"`,
    `git read-tree ${config.pin}`,
    ...files.map((f) => `git update-index --cacheinfo 100644,$(git -c core.autocrlf=false hash-object -w --no-filters "${dir}/${f}"),${f}`),
    `TREE=$(git write-tree)`,
    `COMMIT=$(git -c commit.gpgsign=false commit-tree "$TREE" -p ${config.pin} -m "${c.message}")`,
    `rm -f "$GIT_INDEX_FILE"; unset GIT_INDEX_FILE; echo "$COMMIT"`,
    `# then keep it reachable: git branch pin-child "$COMMIT"  (the site pin names this id; CI's export reads it with git archive)`,
  ].join('\n');
}

function main(argv) {
  const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
  const root = resolve(opt('--root', join(here, '..')));
  const config = JSON.parse(readFileSync(resolve(opt('--config', CONFIG)), 'utf8'));
  const readPin = (f) => git(root, ['show', `${config.pin}:${f}`]);
  const readFrom = (f) => git(root, ['show', `${config.from}:${f}`]);
  let built;
  try { built = buildChild(readPin, readFrom, config); } catch (e) { console.error(`pin-child: ${e.message}`); return 1; }
  const problems = proveWordsOnly(readPin, config, built.texts, readFrom);
  for (const c of built.changes) console.log(`${c.row}: ${c.where}\n   - ${c.old.slice(0, 120)}\n   + ${c.new.slice(0, 120)}`);
  if (problems.length) { for (const p of problems) console.error(`pin-child: ${p}`); return 1; }
  console.log(`pin-child: ${built.changes.length} strings in ${Object.keys(built.texts).length} files; nothing else in them differs from the pin ${config.pin.slice(0, 8)}`);
  if (opt('--patch')) { writeFileSync(resolve(opt('--patch')), patchOf(readPin, built.texts)); console.log(`pin-child: patch written to ${opt('--patch')}`); }
  if (opt('--tree')) {
    const tree = resolve(opt('--tree'));
    for (const [file, text] of Object.entries(built.texts)) { const f = join(tree, ...file.split('/')); if (!existsSync(dirname(f))) mkdirSync(dirname(f), { recursive: true }); writeFileSync(f, text); }
    console.log(`pin-child: ${Object.keys(built.texts).length} files written under ${tree}`);
  }
  if (argv.includes('--commit-id')) console.log(`pin-child: the child commit's id is ${childCommitId(root, config, built.texts)} (computed in a throwaway object directory; nothing written to the repo)`);
  if (argv.includes('--recipe')) console.log(recipe(config, opt('--tree', '<dir of the written files>')));
  return 0;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) process.exit(main(process.argv.slice(2)));
