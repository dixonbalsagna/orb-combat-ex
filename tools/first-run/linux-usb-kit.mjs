// What goes on the second drive for the Linux reading from a USB stick (Tools, 2026-11-28; docs/tools/linux-usb-kit.md).
//   node tools/first-run/linux-usb-kit.mjs --record <build-record.txt> --archive <the Linux .tar.gz of that record> --out <folder on the drive>
// Writes into --out: the archive (a copy, only when its checksum is the record's), FIRST-START.sh and RUN-READING.sh with the record's values. It builds nothing and sends nothing. It overwrites nothing.
import { createHash } from 'node:crypto';
import { chmodSync, copyFileSync, existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { basename, dirname, join, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { kitText, linuxEntry, KIT_NAME, TEMPLATE } from './linux-first-start.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
export const READING_TEMPLATE = join(HERE, 'linux-usb-reading.sh');
export const READING_NAME = 'RUN-READING.sh';

/** Writes the drive's folder. Returns the names written. Throws when the archive is not the record's, or a name is taken. */
export function makeDrive({ record, archive, out }) {
  const e = linuxEntry(readFileSync(record, 'utf8'));
  if (basename(archive) !== e.archive) throw new Error(`the record's Linux package is ${e.archive}, not ${basename(archive)}`);
  const sum = createHash('sha256').update(readFileSync(archive)).digest('hex');
  if (sum !== e.sum) throw new Error(`${e.archive} is not the file the record names (its checksum is different): a reading of it would not count`);
  const dir = resolve(out);
  const names = [e.archive, KIT_NAME, READING_NAME];
  mkdirSync(dir, { recursive: true });
  for (const n of [...names, 'reading', 'first-start-result.txt']) if (existsSync(join(dir, n))) throw new Error(`${join(dir, n)} is there already: give a new folder (nothing is overwritten)`);
  copyFileSync(archive, join(dir, e.archive));
  writeFileSync(join(dir, KIT_NAME), kitText(readFileSync(TEMPLATE, 'utf8'), e));
  writeFileSync(join(dir, READING_NAME), kitText(readFileSync(READING_TEMPLATE, 'utf8'), e));
  for (const n of [KIT_NAME, READING_NAME]) { try { chmodSync(join(dir, n), 0o755); } catch { /* Windows, or a drive with no modes: the page says "sh RUN-READING.sh" */ } }
  return names;
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  const argv = process.argv.slice(2);
  const opt = (n) => { const i = argv.indexOf(n); return i >= 0 ? argv[i + 1] : undefined; };
  const record = opt('--record'), archive = opt('--archive'), out = opt('--out');
  if (!record || !archive || !out) { console.error('usage: node tools/first-run/linux-usb-kit.mjs --record <build-record.txt> --archive <linux .tar.gz> --out <folder on the drive>'); process.exit(2); }
  try {
    const names = makeDrive({ record, archive, out });
    console.log(`written to ${resolve(out)}: ${names.join(', ')}. On the Linux stick: open a terminal in that folder and run  sh ${READING_NAME}`);
  } catch (e) { console.error(`linux usb kit: ${e.message}`); process.exit(1); }
}
