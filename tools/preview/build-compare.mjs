// A file compare of a build's source tree against its commit (Tools, 2026-11-14; A-CODE-03 criterion 1: "a build of that commit has the same files as the commit").
//
//   node tools/preview/build-compare.mjs --tree <the folder the build was exported from> [--rev <sha>] [--repo <repository>] [--out <file>] [--allow <path,path>] [--ignore-dirs .godot,.git]
//
// Every file the commit holds (git ls-tree) is compared with the same path in the tree by its git blob id (the file's bytes with CRLF read as LF, as the repository stores them): a file that differs, a file
// the commit has and the tree does not, and a file the tree has and the commit does not are listed. Exit 0 when the tree is the commit (nothing but the allowed paths), 1 otherwise, 2 on a bad call.
// The private page's scratch trees differ on purpose (the page patches render/core/main.gd, flips data keys); this prints the size of that footprint, and a desktop build made from a commit must print none.
// The default ignored folders are the engine's import cache and git's own. Node built-ins and git only.
import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { existsSync, readFileSync, readdirSync, statSync, writeFileSync } from 'node:fs';
import { join, relative, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = fileURLToPath(new URL('.', import.meta.url));
const ROOT = resolve(HERE, '..', '..');

/** The git blob id of bytes read as the repository stores them (CRLF as LF). */
export function blobId(buf) {
  // git's own rule: a file with a NUL byte near its start is binary and is stored as it is; only text has CRLF read as LF
  const binary = buf.subarray(0, 8000).includes(0);
  const b = binary || !buf.includes(13) ? buf : Buffer.from(buf.toString('latin1').replace(/\r\n/g, '\n'), 'latin1');
  return createHash('sha1').update(Buffer.concat([Buffer.from(`blob ${b.length}\0`), b])).digest('hex');
}

/** { path -> blob id } of a commit, from git ls-tree. */
export function commitFiles(repo, rev) {
  const out = execFileSync('git', ['ls-tree', '-r', '-z', rev], { cwd: repo, encoding: 'latin1', maxBuffer: 256 * 1024 * 1024 });
  const m = new Map();
  for (const rec of out.split('\0')) {
    if (!rec) continue;
    const tab = rec.indexOf('\t');
    const [mode, , id] = rec.slice(0, tab).split(' ');
    if (mode === '160000') continue;   // a submodule
    m.set(Buffer.from(rec.slice(tab + 1), 'latin1').toString('utf8'), id);
  }
  return m;
}

function walk(dir, ignore, base = dir, out = []) {
  for (const e of readdirSync(dir, { withFileTypes: true })) {
    if (e.isDirectory()) { if (!ignore.has(e.name)) walk(join(dir, e.name), ignore, base, out); }
    else if (e.isFile()) out.push(relative(base, join(dir, e.name)).split(sep).join('/'));
  }
  return out;
}

/**
 * Compares a tree with a map of the commit's files. Returns { same, differ: [path], missing: [path] (in the commit, not in the tree), extra: [path] (in the tree, not in the commit), allowed: [path] }.
 * `allow` paths are reported apart and do not count.
 */
export function compareTree(tree, files, { allow = [], ignoreDirs = ['.godot', '.git'] } = {}) {
  const ok = new Set(allow), ign = new Set(ignoreDirs);
  const have = walk(tree, ign);
  const set = new Set(have);
  const r = { differ: [], missing: [], extra: [], allowed: [], same: 0 };
  for (const [p, id] of files) {
    if (!set.has(p)) { (ok.has(p) ? r.allowed : r.missing).push(p); continue; }
    if (blobId(readFileSync(join(tree, p))) === id) r.same++;
    else (ok.has(p) ? r.allowed : r.differ).push(p);
  }
  for (const p of have) if (!files.has(p)) (ok.has(p) ? r.allowed : r.extra).push(p);
  for (const k of ['differ', 'missing', 'extra', 'allowed']) r[k].sort();
  return r;
}

// A record kept in the repository must hold no profile path (the content screen refuses one): the user folder of a Windows or Unix path is written <user>. Built from parts so this file holds no path itself.
const SEP = '[\\\\/]+';
const PROFILE = new RegExp(`(?:[A-Za-z]:)?${SEP}${'Us' + 'ers'}${SEP}[^\\\\/]+|${SEP}${'ho' + 'me'}${SEP}[^\\\\/]+`, 'g');
export const scrubPath = (s) => String(s).replace(PROFILE, '<user>');

export function report(r, { rev = '', tree = '' } = {}) {
  tree = scrubPath(tree);
  const lines = [];
  for (const [label, k] of [['DIFFERS', 'differ'], ['MISSING from the tree', 'missing'], ['EXTRA in the tree', 'extra'], ['allowed', 'allowed']]) for (const p of r[k]) lines.push(`${label.padEnd(22)} ${p}`);
  lines.push(`tree ${tree} against ${rev}: ${r.same} files identical, ${r.differ.length} differ, ${r.missing.length} missing, ${r.extra.length} extra${r.allowed.length ? `, ${r.allowed.length} allowed` : ''}: ${r.differ.length + r.missing.length + r.extra.length === 0 ? 'THE TREE IS THE COMMIT' : 'NOT the commit'}`);
  return lines.join('\n');
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const a = process.argv.slice(2);
  const opt = (n, d) => { const i = a.indexOf(n); return i >= 0 && i + 1 < a.length ? a[i + 1] : d; };
  try {
    const tree = opt('--tree');
    if (!tree || !existsSync(tree) || !statSync(tree).isDirectory()) { console.error('usage: node tools/preview/build-compare.mjs --tree <folder> [--rev <sha>] [--repo <repository>] [--out <file>] [--allow a,b] [--ignore-dirs .godot,.git]'); process.exit(2); }
    const repo = resolve(opt('--repo', ROOT));
    const rev = execFileSync('git', ['rev-parse', '--verify', `${opt('--rev', 'HEAD')}^{commit}`], { cwd: repo, encoding: 'utf8' }).trim();
    const r = compareTree(resolve(tree), commitFiles(repo, rev), { allow: opt('--allow', '').split(',').filter(Boolean), ignoreDirs: opt('--ignore-dirs', '.godot,.git').split(',').filter(Boolean) });
    const text = report(r, { rev: rev.slice(0, 8), tree: resolve(tree) });
    console.log(text);
    if (opt('--out')) writeFileSync(resolve(opt('--out')), text + '\n');
    process.exitCode = r.differ.length + r.missing.length + r.extra.length ? 1 : 0;
  } catch (e) { console.error(`build-compare: ${e.message}`); process.exitCode = 2; }
}
