// A tar.gz writer and reader for the Linux package (Tools, 2026-11-23; path to Alpha 1, job 7). Node built-ins only.
// Why it exists: the Linux package is a .tar.gz on purpose (a zip drops the executable bit, a tar keeps it), and on a Windows PC the only tar is bsdtar, which gives every file the mode Windows has (no executable
// bit). So the archive is written here, with the mode of each file named: 0755 for the program, 0644 for the rest. Names are the plain POSIX ustar form (a name of 100 characters or less), the time is a fixed one
// (the commit's date), the owner is 0: the same inputs give the same bytes, so a rebuild of a commit is the same file.
import { gzipSync, gunzipSync } from 'node:zlib';
import { readdirSync, readFileSync, statSync } from 'node:fs';
import { join } from 'node:path';

const BLOCK = 512;
const oct = (n, width) => n.toString(8).padStart(width - 1, '0') + '\0';

/** One 512-byte ustar header. Pure. */
export function header({ name, size, mode, mtime, dir = false }) {
  if (Buffer.byteLength(name) > 100) throw new Error(`targz: "${name}" is longer than 100 bytes (the plain ustar form)`);
  const h = Buffer.alloc(BLOCK, 0);
  h.write(name, 0, 'utf8');
  h.write(oct(mode, 8), 100, 'ascii');
  h.write(oct(0, 8), 108, 'ascii');
  h.write(oct(0, 8), 116, 'ascii');
  h.write(oct(dir ? 0 : size, 12), 124, 'ascii');
  h.write(oct(mtime, 12), 136, 'ascii');
  h.write('        ', 148, 'ascii');   // the checksum counts itself as eight spaces
  h.write(dir ? '5' : '0', 156, 'ascii');
  h.write('ustar\0', 257, 'ascii');
  h.write('00', 263, 'ascii');
  let sum = 0;
  for (const b of h) sum += b;
  h.write(sum.toString(8).padStart(6, '0') + '\0 ', 148, 'ascii');
  return h;
}

/** The tar of `entries` ([{ name, data (Buffer; absent for a folder), mode, dir }]), mtime in seconds. Pure. */
export function tarBuffer(entries, mtime = 0) {
  const parts = [];
  for (const e of entries) {
    const data = e.dir ? Buffer.alloc(0) : e.data;
    parts.push(header({ name: e.dir ? e.name.replace(/\/?$/, '/') : e.name, size: data.length, mode: e.mode, mtime, dir: !!e.dir }));
    if (data.length) { parts.push(data); const pad = (BLOCK - (data.length % BLOCK)) % BLOCK; if (pad) parts.push(Buffer.alloc(pad, 0)); }
  }
  parts.push(Buffer.alloc(BLOCK * 2, 0));
  return Buffer.concat(parts);
}

export const targz = (entries, mtime = 0) => gzipSync(tarBuffer(entries, mtime), { level: 9 });

/** What a tar holds: [{ name, size, mode, dir }]. Pure; checks every header's checksum. */
export function readTar(buf) {
  const out = [];
  let at = 0;
  while (at + BLOCK <= buf.length) {
    const h = buf.subarray(at, at + BLOCK);
    if (h.every((b) => b === 0)) break;
    const name = h.toString('utf8', 0, 100).replace(/\0.*$/s, '');
    const field = (from, len) => parseInt(h.toString('ascii', from, from + len).replace(/\0.*$/s, '').trim() || '0', 8);
    const stored = field(148, 8);
    let sum = 0;
    for (let i = 0; i < BLOCK; i++) sum += i >= 148 && i < 156 ? 32 : h[i];
    if (sum !== stored) throw new Error(`targz: bad checksum for "${name}"`);
    const size = field(124, 12), dir = h.toString('ascii', 156, 157) === '5';
    out.push({ name, size, mode: field(100, 8), dir });
    at += BLOCK + Math.ceil(size / BLOCK) * BLOCK;
  }
  return out;
}

export const readTarGz = (buf) => readTar(gunzipSync(buf));

/** The entries of a folder tree, under `top` (the folder's name inside the archive), sorted by name. `executables`: file names (relative, with /) that get 0755. */
export function folderEntries(dir, top, executables = []) {
  const out = [{ name: top, dir: true, mode: 0o755 }];
  const walk = (rel) => {
    for (const f of readdirSync(join(dir, rel)).sort()) {
      const r = rel ? `${rel}/${f}` : f, p = join(dir, r);
      if (statSync(p).isDirectory()) { out.push({ name: `${top}/${r}`, dir: true, mode: 0o755 }); walk(r); }
      else out.push({ name: `${top}/${r}`, data: readFileSync(p), mode: executables.includes(r) ? 0o755 : 0o644 });
    }
  };
  walk('');
  return out;
}
