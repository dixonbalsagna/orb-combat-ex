// The placeholder-name scan of a built site (Legal, RL-136 / photosensitivity-note.md addendum 8): no KAI, VORR, Meridian or Calamity as visible text on the published build.
// Two parts, both run by tools/check-site-interim.mjs:
//   - the site's own pages (HTML text, the licence texts of /about/ excluded): any hit is a failure;
//   - the game's pack (play/index.pck): the pack's directory is read (Godot pack format 2 and 3), every file whose bytes hold one of the words is listed with the word, and a hit in a
//     file that is not in the allowlist (tools/site-name-scan.json, with the reason each file is there) is a failure. The allowlist is a list of files whose hits are notes and
//     test data a player never sees; a new file with a hit, or a hit in a UI text file, fails the check.
//   - a compiled script (.gdc) is compressed bytecode, where a name can meet itself by chance between unrelated bytes ("KAI" in ui_hud.gdc, 2026-10-30, with no KAI in its source). With the
//     exported tree of the same commit to read, such a hit counts only when the script's source holds the word too (scanPack option `source`); with no tree, or no source for it, it stays a hit.
//   node tools/site-name-scan.mjs --pck <index.pck> [--allow <file>] [--tree <the exported tree of the pack's commit>]     prints every hit with its file; exit 1 on a hit outside the allowlist
import { existsSync, readFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

export const WORDS = ['KAI', 'VORR', 'Meridian', 'Calamity'];
const WORD_RE = new RegExp(`(?<![A-Za-z0-9_])(${WORDS.join('|')})(?![A-Za-z0-9_])`, 'g');

/** The files of a Godot 4 .pck: [{ path, offset, size }] (offsets absolute). Throws on a pack it cannot read. */
export function packFiles(buf) {
  if (buf.length < 64 || buf.toString('latin1', 0, 4) !== 'GDPC') throw new Error('not a Godot pack (no GDPC header)');
  const version = buf.readUInt32LE(4);
  if (version < 2 || version > 4) throw new Error(`pack format ${version} is not read by this scan (2 to 4 are)`);
  const flags = buf.readUInt32LE(20);
  const REL = 2;   // PACK_REL_FILEBASE
  let fileBase = Number(buf.readBigUInt64LE(24));
  let at;
  let dirOffset;
  if (version >= 3) { dirOffset = Number(buf.readBigUInt64LE(32)); at = dirOffset; } else { at = 32 + 16 * 4; }
  const count = buf.readUInt32LE(at);
  at += 4;
  if (version === 2 && (flags & REL) === 0) fileBase = 0;
  const out = [];
  for (let i = 0; i < count; i++) {
    const len = buf.readUInt32LE(at);
    at += 4;
    const path = buf.toString('utf8', at, at + len).replace(/\0+$/, '');
    at += len;
    const offset = Number(buf.readBigUInt64LE(at));
    const size = Number(buf.readBigUInt64LE(at + 8));
    at += 16 + 16 + 4;   // offset, size, md5, flags
    out.push({ path, offset: fileBase + offset, size });
  }
  return out;
}

/** Every hit in a pack: [{ word, path }]. `o.source(path)` gives the text of a file of the exported tree at that pack path, or null when there is none (the caller offers it only when the tree is
 *  the pack's own commit). With it, a hit in a compiled script (.gdc: compressed bytecode, where three letters can meet by chance) counts only when the script's source (the same path with .gd)
 *  holds the word too; one with no source to read stays a hit. The chance matches are returned in `chance` so a report can say so. */
export function scanPack(buf, o = {}) {
  const files = packFiles(buf);
  const hits = [], chance = [];
  for (const f of files) {
    const text = buf.toString('latin1', f.offset, f.offset + f.size);
    const seen = new Set();
    for (const m of text.matchAll(WORD_RE)) seen.add(m[1]);
    for (const w of seen) {
      if (o.source && /\.gdc$/.test(f.path)) {
        const src = o.source(f.path.replace(/\.gdc$/, '.gd'));
        if (typeof src === 'string' && !new RegExp(`(?<![A-Za-z0-9_])${w}(?![A-Za-z0-9_])`).test(src)) { chance.push({ word: w, path: f.path }); continue; }
      }
      hits.push({ word: w, path: f.path });
    }
  }
  return { files: files.length, hits, chance };
}

/** Hits in a page's visible text (the licence texts in <pre> are not the site's words). */
export function scanHtml(html) {
  const text = html.replace(/<pre>[\s\S]*?<\/pre>/g, '').replace(/<style>[\s\S]*?<\/style>/g, '').replace(/<[^>]+>/g, ' ');
  return [...new Set([...text.matchAll(WORD_RE)].map((m) => m[1]))];
}

/** The hits of a pack that are not in the allowlist ({ allow: [{ path, why }] }). */
export function unallowed(hits, allow) {
  const ok = new Set((allow && allow.allow ? allow.allow : []).map((a) => a.path));
  return hits.filter((h) => !ok.has(h.path.replace(/^res:\/\//, '')));
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const args = process.argv.slice(2);
  const opt = (n) => { const i = args.indexOf(n); return i >= 0 ? args[i + 1] : undefined; };
  const pck = opt('--pck');
  if (!pck) { console.error('usage: node tools/site-name-scan.mjs --pck <index.pck> [--allow <file>]'); process.exit(2); }
  const allow = JSON.parse(readFileSync(resolve(opt('--allow') || join(import.meta.dirname, 'site-name-scan.json')), 'utf8'));
  const tree = opt('--tree') ? resolve(opt('--tree')) : null;
  const r = scanPack(readFileSync(pck), tree ? { source: (p) => { const f = join(tree, p.replace(/^res:\/\//, '')); return existsSync(f) ? readFileSync(f, 'utf8') : null; } } : {});
  for (const h of r.hits) console.log(`${h.word}\t${h.path}`);
  for (const h of r.chance) console.log(`(chance: not in the script's source) ${h.word}\t${h.path}`);
  const bad = unallowed(r.hits, allow);
  console.log(`${r.files} files, ${r.hits.length} hits, ${bad.length} outside the allowlist`);
  process.exit(bad.length ? 1 : 0);
}
