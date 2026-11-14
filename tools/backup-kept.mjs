// The copy of Orb's kept builds and play files to a second place, and the way back (A-TOOLS-09, Tools, 2026-11-14). homework/Files is git-ignored and holds, with no other copy, every build Orb played, their saved
// matches and the reports (2.9 GB on 2026-11-13). One command copies them, one verifies the copy, one puts them back. Nothing is ever deleted: not from the source, not from the copy.
//
//   node tools/backup-kept.mjs --to <a folder on another disk or a stick> [--from homework/Files] [--include builds,play,reports] [--only <name part>] [--dry]
//   node tools/backup-kept.mjs --verify --to <the backup folder>                 re-read every file of the copy against the manifest (size and SHA-256)
//   node tools/backup-kept.mjs --restore --from <the backup folder> --to <homework/Files, or a new folder> [--only <name part>] [--dry]
//
// What is copied (--include, default all three): `builds` (every folder of builds/, each a kept build, its web build, its tree, or a LAN folder), `play` (the files of the top folder that are saved matches and
// results: orb-first-play-*.json and *-result-*.json), `reports` (the report folders and zips the report tool made). `--only` keeps the entries whose name has that text in it. The copy holds
// BACKUP-MANIFEST.json (what was copied, when, from where, each file's size and SHA-256). A second run copies only what is new or changed in the source; a file in the copy that differs from the manifest is named, never
// overwritten (a kept build is never changed: the folder that exists is the proof). A restore copies the files the target lacks, checks each against the manifest, and REFUSES to overwrite a different file there. The destination may not be
// inside the source, nor the source inside the destination. Node built-ins only; no network; nothing leaves the PC unless the folder named by --to is on a drive that does.
import { createHash } from 'node:crypto';
import { copyFileSync, createReadStream, existsSync, mkdirSync, readFileSync, readdirSync, renameSync, statSync, writeFileSync } from 'node:fs';
import { dirname, join, relative, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');
export const MANIFEST = 'BACKUP-MANIFEST.json';
export const SETS = ['builds', 'play', 'reports'];
const PLAY = /^(orb-first-play-.+|.+-result-.+)\.json$/i;

const norm = (p) => resolve(p).split(sep).join('/').toLowerCase().replace(/\/+$/, '');
/** Whether a path is the same as, or inside, another. */
export const inside = (child, parent) => { const c = norm(child), p = norm(parent); return c === p || c.startsWith(p + '/'); };

export function sha256File(file) {
  return new Promise((ok, no) => { const h = createHash('sha256'); createReadStream(file).on('data', (d) => h.update(d)).on('error', no).on('end', () => ok(h.digest('hex'))); });
}

function walk(dir, base, out) {
  for (const e of readdirSync(dir, { withFileTypes: true })) {
    const p = join(dir, e.name);
    if (e.isDirectory()) walk(p, base, out);
    else if (e.isFile()) out.push(relative(base, p).split(sep).join('/'));
  }
}

/** The files to back up under `from`: relative paths with forward slashes, for the sets and the --only text. Pure but for the folder reading. */
export function listFiles(from, include = SETS, only = '') {
  const out = [];
  const want = (name) => !only || name.includes(only);
  if (include.includes('builds') && existsSync(join(from, 'builds'))) for (const e of readdirSync(join(from, 'builds'), { withFileTypes: true })) if (e.isDirectory() && want(e.name)) walk(join(from, 'builds', e.name), from, out);
  if (include.includes('play')) for (const e of readdirSync(from, { withFileTypes: true })) if (e.isFile() && PLAY.test(e.name) && want(e.name)) out.push(e.name);
  if (include.includes('reports') && existsSync(join(from, 'reports'))) for (const e of readdirSync(join(from, 'reports'), { withFileTypes: true })) if (want(e.name)) { if (e.isDirectory()) walk(join(from, 'reports', e.name), from, out); else if (e.isFile()) out.push(`reports/${e.name}`); }
  return out.sort();
}

const readManifest = (to) => { try { return JSON.parse(readFileSync(join(to, MANIFEST), 'utf8')); } catch { return null; } };
const writeManifest = (to, m) => { const f = join(to, MANIFEST); writeFileSync(f + '.tmp', JSON.stringify(m, null, 1)); renameSync(f + '.tmp', f); };

/** Copies `from` into `to`. Returns { copied, same, differs: [path], total, bytes }. `log` gets one line a few hundred files. */
export async function backup({ from, to, include = SETS, only = '', dry = false, log = () => {} }) {
  if (inside(to, from) || inside(from, to)) throw new Error('the destination and the source may not be inside one another');
  const files = listFiles(from, include, only);
  const prior = readManifest(to) || { files: {} };
  const man = { made: prior.made || new Date().toISOString(), updated: new Date().toISOString(), source: 'homework/Files', files: { ...prior.files } };
  const r = { copied: 0, same: 0, differs: [], total: files.length, bytes: 0 };
  let n = 0;
  for (const rel of files) {
    const src = join(from, rel), dst = join(to, rel), size = statSync(src).size;
    if (++n % 400 === 0) log(`${n} of ${files.length}`);
    if (existsSync(dst)) {
      const have = man.files[rel];
      if (statSync(dst).size === size && have && have.size === size) { const h = await sha256File(dst); if (h === have.sha256 && (await sha256File(src)) === h) { r.same++; continue; } }
      if (statSync(dst).size === size && !have) { const [a, b] = [await sha256File(src), await sha256File(dst)]; if (a === b) { man.files[rel] = { size, sha256: a }; r.same++; continue; } }
      r.differs.push(rel); continue;   // a file in the copy that is not the source's: never overwritten
    }
    if (dry) { r.copied++; r.bytes += size; continue; }
    mkdirSync(dirname(dst), { recursive: true });
    copyFileSync(src, dst);
    const h = await sha256File(dst);
    if (h !== (await sha256File(src))) throw new Error(`the copy of ${rel} does not read back as the source`);
    man.files[rel] = { size, sha256: h };
    r.copied++; r.bytes += size;
  }
  if (!dry) { mkdirSync(to, { recursive: true }); writeManifest(to, man); }
  return r;
}

/** Re-reads the copy against its manifest. Returns { ok, checked, bad: [{ path, why }] }. */
export async function verify(to) {
  const m = readManifest(to);
  if (!m) return { ok: false, checked: 0, bad: [{ path: MANIFEST, why: 'no manifest: this is not a backup folder' }] };
  const bad = [];
  let checked = 0;
  for (const [rel, e] of Object.entries(m.files)) {
    const f = join(to, rel);
    if (!existsSync(f)) { bad.push({ path: rel, why: 'missing' }); continue; }
    if (statSync(f).size !== e.size) { bad.push({ path: rel, why: `size ${statSync(f).size}, the manifest says ${e.size}` }); continue; }
    if ((await sha256File(f)) !== e.sha256) bad.push({ path: rel, why: 'SHA-256 differs from the manifest' });
    checked++;
  }
  return { ok: bad.length === 0, checked, bad };
}

/** Puts the backup's files into `to` (a homework/Files, or a new folder): a file the target lacks is copied and checked; one that is there and the same is left; one that is there and different is REFUSED. */
export async function restore({ from, to, only = '', dry = false }) {
  const m = readManifest(from);
  if (!m) throw new Error(`${from} has no ${MANIFEST}: it is not a backup folder`);
  if (inside(to, from) || inside(from, to)) throw new Error('the destination and the backup may not be inside one another');
  const r = { copied: 0, same: 0, refused: [], total: 0 };
  for (const [rel, e] of Object.entries(m.files)) {
    if (only && !rel.includes(only)) continue;
    r.total++;
    const src = join(from, rel), dst = join(to, rel);
    if (!existsSync(src)) { r.refused.push({ path: rel, why: 'missing from the backup' }); continue; }
    if (existsSync(dst)) { if (statSync(dst).size === e.size && (await sha256File(dst)) === e.sha256) { r.same++; } else r.refused.push({ path: rel, why: 'a different file is there already: not overwritten' }); continue; }
    if (dry) { r.copied++; continue; }
    mkdirSync(dirname(dst), { recursive: true });
    copyFileSync(src, dst);
    if ((await sha256File(dst)) !== e.sha256) { r.refused.push({ path: rel, why: 'the restored file does not read back as the manifest says' }); continue; }
    r.copied++;
  }
  return r;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const a = process.argv.slice(2);
  const opt = (n, d) => { const i = a.indexOf(n); return i >= 0 && i + 1 < a.length ? a[i + 1] : d; };
  const mb = (b) => (b / 1048576).toFixed(1) + ' MB';
  try {
    const to = opt('--to');
    if (!to) { console.error('usage: node tools/backup-kept.mjs --to <folder> [--from homework/Files] [--include builds,play,reports] [--only <text>] [--dry]   |   --verify --to <backup>   |   --restore --from <backup> --to <target>'); process.exit(2); }
    if (a.includes('--verify')) {
      const v = await verify(resolve(to));
      for (const b of v.bad.slice(0, 30)) console.log(`BAD  ${b.path}: ${b.why}`);
      console.log(`backup verify: ${v.checked} files read, ${v.bad.length} problem(s): ${v.ok ? 'THE COPY IS WHOLE' : 'NOT whole'}`);
      process.exitCode = v.ok ? 0 : 1;
    } else if (a.includes('--restore')) {
      const r = await restore({ from: resolve(opt('--from', '')), to: resolve(to), only: opt('--only', ''), dry: a.includes('--dry') });
      for (const x of r.refused.slice(0, 30)) console.log(`REFUSED  ${x.path}: ${x.why}`);
      console.log(`restore${a.includes('--dry') ? ' (dry)' : ''}: ${r.copied} copied, ${r.same} already there and the same, ${r.refused.length} refused, of ${r.total}`);
      process.exitCode = r.refused.length ? 1 : 0;
    } else {
      const from = resolve(opt('--from', join(ROOT, 'homework', 'Files')));
      const r = await backup({ from, to: resolve(to), include: opt('--include', SETS.join(',')).split(','), only: opt('--only', ''), dry: a.includes('--dry'), log: (m) => console.log(m) });
      for (const x of r.differs.slice(0, 30)) console.log(`DIFFERS  ${x}: a different file is in the copy already: not overwritten`);
      console.log(`backup${a.includes('--dry') ? ' (dry)' : ''}: ${r.copied} files copied (${mb(r.bytes)}), ${r.same} already in the copy, ${r.differs.length} differ, of ${r.total}`);
      process.exitCode = r.differs.length ? 1 : 0;
    }
  } catch (e) { console.error(`backup-kept: ${e.message}`); process.exitCode = 2; }
}
