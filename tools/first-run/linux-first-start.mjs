// The one-click kit for the first start of the Linux program (Tools, 2026-11-28; gate G23, Legal RL-278 and RL-280; docs/tools/linux-first-start.md).
//   node tools/first-run/linux-first-start.mjs --record <build-record.txt> --out <folder>
// Reads the testers' (or owner's) build record: the Linux archive's name and checksum and the bench's gameplay hash. Writes <out>/FIRST-START.sh with them filled in. It builds nothing and sends nothing.
import { chmodSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { join, resolve, dirname } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
export const TEMPLATE = join(HERE, 'linux-first-start.sh');
export const KIT_NAME = 'FIRST-START.sh';

/** { archive, sum, hash, ticks } of the Linux package in a build record's text. Throws, saying what is missing. Pure. */
export function linuxEntry(record) {
  const lines = String(record).split(/\r?\n/);
  const at = lines.findIndex((l) => /^file \S*linux\S*\.tar\.gz$/.test(l));
  if (at < 0) throw new Error('the record names no Linux .tar.gz (was it built with --platform linux or both?)');
  const archive = lines[at].slice(5);
  let sum = '', hash = '', ticks = '';
  for (let i = at + 1; i < lines.length && lines[i] !== '' && !lines[i].startsWith('file '); i++) {
    const s = /^sha256 ([0-9a-f]{64})$/.exec(lines[i]);
    const b = /^bench gameplay hash at tick (\d+): ([0-9a-f]+)$/.exec(lines[i]);
    if (s) sum = s[1];
    if (b) { ticks = b[1]; hash = b[2]; }
  }
  if (!sum) throw new Error('the record has no sha256 line for the Linux archive');
  if (!hash) throw new Error('the record has no bench hash line for the Linux archive');
  return { archive, sum, hash, ticks };
}

/** The kit's text: the template with the four values in. LF line ends, whatever the checkout's. Pure. */
export function kitText(template, e) {
  if (!/^[A-Za-z0-9._-]+\.tar\.gz$/.test(e.archive) || !/^[0-9a-f]{64}$/.test(e.sum) || !/^[0-9a-f]{8,}$/.test(e.hash) || !/^\d+$/.test(e.ticks)) throw new Error('a value for the kit is not the shape it should be');
  const out = template.replace(/\r\n/g, '\n').replace('ARCHIVE_NAME="@ARCHIVE@"', `ARCHIVE_NAME="${e.archive}"`).replace('WANT_SUM="@SUM@"', `WANT_SUM="${e.sum}"`).replace('WANT_HASH="@HASH@"', `WANT_HASH="${e.hash}"`).replace('TICKS="@TICKS@"', `TICKS="${e.ticks}"`);
  if (/^[A-Z_]+="@[A-Z]+@"$/m.test(out)) throw new Error('the template has a value that was not filled');
  return out;
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  const argv = process.argv.slice(2);
  const opt = (n) => { const i = argv.indexOf(n); return i >= 0 ? argv[i + 1] : undefined; };
  const record = opt('--record'), out = opt('--out');
  if (!record || !out) { console.error('usage: node tools/first-run/linux-first-start.mjs --record <build-record.txt> --out <folder>'); process.exit(2); }
  try {
    const e = linuxEntry(readFileSync(record, 'utf8'));
    mkdirSync(out, { recursive: true });
    const file = join(resolve(out), KIT_NAME);
    writeFileSync(file, kitText(readFileSync(TEMPLATE, 'utf8'), e));
    try { chmodSync(file, 0o755); } catch { /* Windows */ }
    console.log(`${KIT_NAME} written for ${e.archive} (sha256 ${e.sum}, bench ${e.hash} at tick ${e.ticks}): ${file}`);
  } catch (err) { console.error(`linux first start kit: ${err.message}`); process.exit(1); }
}
