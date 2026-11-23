// Takes this PC's folder paths out of a build record before it goes into the repository (Tools, 2026-11-23; path to Alpha 1, job 7). The records of tools/desktop-local-build.mjs and of the other local builds name
// the scratch folder and the user's profile folder; the repository is public, so a record is cleaned before it is filed.
//   node tools/record-paths.mjs clean <in> [<out>]      writes the cleaned text (to <out>, or to the same file with --in-place)
//   node tools/record-paths.mjs check <file or folder>...   exit 1 when a file still holds a user's folder path (a Windows "C:\Users\<name>", "/c/Users/<name>", "/Users/<name>" or "/home/<name>")
// What each kind becomes: the repository folder -> <repo>; a scratch folder under the temp folder -> <scratch>; a user's profile folder -> <user> (so "C:\Users\<user>\AppData\Local\...", never the name).
// Node built-ins only.
import { readFileSync, readdirSync, statSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const SEP = '[\\\\/]';
// the segment after Users: anything but a separator, a quote, a space-then-more-path is NOT assumed (a folder name may hold a space: "Claude Proj"), so the user name is the one segment
const USER = `[^\\\\/\\s"'<>|:*?]+`;
const WIN_HOME = new RegExp(`[A-Za-z]:${SEP}Users${SEP}(?!<user>)${USER}`, 'g');
const POSIX_HOME = new RegExp(`(?:/[a-z])?/(?:Users|home)/(?!<user>)${USER}`, 'g');
const WIN_REPO = new RegExp(`<user-home>${SEP}Documents${SEP}Claude Proj${SEP}Breakers-Like`, 'g');
const SCRATCH = new RegExp(`<user-home>${SEP}AppData${SEP}Local${SEP}Temp${SEP}(?:claude${SEP}[^\\s"']*?${SEP}scratchpad|[^\\\\/\\s"']+)`, 'g');

/** The text with this PC's paths taken out. Pure. */
export function cleanPaths(text) {
  let t = String(text);
  t = t.replace(WIN_HOME, '<user-home>').replace(POSIX_HOME, '<user-home>');
  t = t.replace(WIN_REPO, '<repo>').replace(SCRATCH, '<scratch>');
  return t.replace(/<user-home>/g, '<user>');
}

/** The user folder paths still in the text: [{ line, text }]. Pure. */
export function leftover(text) {
  const out = [];
  String(text).split(/\r?\n/).forEach((l, i) => {
    WIN_HOME.lastIndex = 0; POSIX_HOME.lastIndex = 0;
    if (WIN_HOME.test(l) || POSIX_HOME.test(l)) out.push({ line: i + 1, text: l.trim().slice(0, 140) });
  });
  return out;
}

const textFile = (f) => /\.(txt|md|json|log|csv)$/i.test(f);
function* files(p) {
  const s = statSync(p);
  if (!s.isDirectory()) { yield p; return; }
  for (const f of readdirSync(p).sort()) { if (f === '.git' || f === 'node_modules') continue; yield* files(join(p, f)); }
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const [cmd, ...rest] = process.argv.slice(2);
  try {
    if (cmd === 'clean' && rest.length >= 1) {
      const inPlace = rest.includes('--in-place');
      const [a, b] = rest.filter((x) => x !== '--in-place');
      const out = inPlace ? a : b;
      if (!out) { console.error('record-paths clean: name an output file, or --in-place'); process.exit(2); }
      const before = readFileSync(a, 'utf8');
      const after = cleanPaths(before);
      writeFileSync(out, after);
      console.log(`record-paths: ${out}: ${before === after ? 'nothing to clean' : 'cleaned'}; ${leftover(after).length} path(s) left`);
      process.exit(leftover(after).length ? 1 : 0);
    } else if (cmd === 'check' && rest.length) {
      let bad = 0, n = 0;
      for (const p of rest) for (const f of files(p)) {
        if (!textFile(f)) continue;
        n++;
        const l = leftover(readFileSync(f, 'utf8'));
        for (const x of l) { bad++; console.log(`${f}:${x.line}: ${x.text}`); }
      }
      console.log(`record-paths: ${n} file(s) read, ${bad} line(s) with a user folder path`);
      process.exit(bad ? 1 : 0);
    } else { console.error('usage: node tools/record-paths.mjs clean <in> [<out>|--in-place]  |  check <file or folder>...'); process.exit(2); }
  } catch (e) { console.error(`record-paths: ${e.message}`); process.exit(2); }
}
