// Self-test of tools/preview/build-check.mjs (A-TOOLS-10): the embedded pack of a desktop game file, and each way a build's packed data can disagree with its commit. A small Godot pack is written here
// (format 2, absolute offsets), once alone and once embedded in a stand-in game file (bytes, then the pack, its size and GDPC). No Godot, no git, no browser. CI runs it.
//   node tools/preview/build-check-selftest.mjs
import { checkRows, packOf, report, gameFileOf } from './build-check.mjs';
import { packFiles } from '../site-name-scan.mjs';
import { packJson } from './pck-verify.mjs';
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

let ran = 0, failed = 0;
const check = (name, ok, extra) => { ran++; if (!ok) { failed++; console.log(`  FAIL ${name}${extra ? ': ' + extra : ''}`); } };

function makePack(files) {
  const names = Object.keys(files);
  const entryLen = (n) => 4 + Buffer.byteLength(n) + 8 + 8 + 16 + 4;
  const headLen = 96 + 4 + names.reduce((a, n) => a + entryLen(n), 0);
  const head = Buffer.alloc(headLen);
  head.write('GDPC', 0, 'latin1');
  head.writeUInt32LE(2, 4); head.writeUInt32LE(4, 8); head.writeUInt32LE(7, 12); head.writeUInt32LE(2, 16);
  head.writeUInt32LE(0, 20); head.writeBigUInt64LE(0n, 24);
  head.writeUInt32LE(names.length, 96);
  let at = 100, off = headLen;
  const datas = [];
  for (const n of names) {
    const data = Buffer.from(files[n], 'utf8');
    head.writeUInt32LE(Buffer.byteLength(n), at); at += 4;
    head.write(n, at, 'utf8'); at += Buffer.byteLength(n);
    head.writeBigUInt64LE(BigInt(off), at); head.writeBigUInt64LE(BigInt(data.length), at + 8);
    at += 16 + 16 + 4;
    off += data.length; datas.push(data);
  }
  return Buffer.concat([head, ...datas]);
}
const embed = (pack, before = 5000) => { const f = Buffer.alloc(12); f.writeBigUInt64LE(BigInt(pack.length), 0); f.write('GDPC', 8, 'latin1'); return Buffer.concat([Buffer.alloc(before, 0x7f), pack, f]); };
const J = (o) => JSON.stringify(o);

const pack = makePack({ 'res://data/a.json': J({ x: { enabled: true }, y: { enabled: false } }), 'res://data/b.json': J({ lodge: 'world', stop: 1 }), 'res://build_info.json': J({ commit: '6a30b4c', date: '2026-11-09' }) });
check('a bare pack is its own pack', packOf(pack) === pack);
const game = embed(pack);
const inner = packOf(game);
check('the embedded pack is found by the footer and read like a bare one', inner.length === pack.length && packJson(inner, packFiles(inner), 'data/a.json').x.enabled === true && packJson(inner, packFiles(inner), 'build_info.json').commit === '6a30b4c');
let msg = null; try { packOf(Buffer.alloc(40, 1)); } catch (e) { msg = e.message; }
check('a file with no pack is refused, naming why', msg !== null && /no pack/.test(msg));
const lie = Buffer.from(game); lie.writeBigUInt64LE(BigInt(game.length * 2), game.length - 12);
msg = null; try { packOf(lie); } catch (e) { msg = e.message; }
check('a footer whose size is not inside the file is refused', msg !== null && /size in the footer/.test(msg));

const table = [
  { id: 'on', file: 'data/a.json', path: ['x', 'enabled'], from: false, to: true, needs: [] },
  { id: 'off', file: 'data/a.json', path: ['y', 'enabled'], from: false, to: true, needs: [] },
  { id: 'two', file: 'data/b.json', path: ['lodge'], from: 'world', to: 'body', more: [{ path: ['stop'], from: 1, to: 0 }], needs: [] },
  { id: 'word', url: 'tiles=1', needs: [] },
];
const packJsonOf = (f) => packJson(inner, packFiles(inner), f);
const commit = { 'data/a.json': { x: { enabled: true }, y: { enabled: false } }, 'data/b.json': { lodge: 'world', stop: 1 } };
let r = checkRows(table, packJsonOf, (f) => commit[f] || null);
check('a build whose pack is the commit has no problem; the row at its "to" is ON, the others are off; a page word is not read', r.problems.length === 0 && r.on === 1 && r.data === 3 && r.rows.find((x) => x.id === 'on').on && !r.rows.find((x) => x.id === 'off').on && !r.rows.find((x) => x.id === 'two').on);
r = checkRows(table, packJsonOf, (f) => (f === 'data/a.json' ? { x: { enabled: false }, y: { enabled: false } } : commit[f]));
check('a row on in the pack and off in the commit is a problem naming the file, the key and both values', r.problems.length === 1 && /row on: data\/a.json x.enabled: the pack holds true, the commit false/.test(r.problems[0]), r.problems.join('|'));
r = checkRows(table, packJsonOf, (f) => (f === 'data/b.json' ? { lodge: 'world', stop: 1, extra: 1 } : commit[f]));
check('a key the commit has and the pack lacks (or the other way) is a problem; an extra unrelated key is not', r.problems.length === 0);
r = checkRows(table, (f) => (f === 'data/b.json' ? { lodge: 'world' } : packJsonOf(f)), (f) => commit[f] || null);
check('a missing key in the pack is a problem', r.problems.some((p) => /row two: data\/b.json stop: the pack holds no such key, the commit 1/.test(p)), r.problems.join('|'));
r = checkRows(table, () => null, (f) => commit[f] || null);
check('a data file missing from the pack is a problem for each row that reads it, not a crash', r.problems.length >= 3);
const text = report(checkRows(table, packJsonOf, (f) => commit[f] || null), { list: true, commit: '6a30b4c9c767', build: 'orb-combat-ex.x86_64' });
check('the report lists the rows and ends with the counts', /^on +ON /m.test(text) && /^off +off/m.test(text) && /3 data rows read from the pack, 1 ON, 2 off, 0 problem\(s\)$/.test(text), text);

const d = mkdtempSync(join(tmpdir(), 'build-check-'));
try {
  mkdirSync(join(d, 'win')); writeFileSync(join(d, 'win', 'readme.txt'), 'x'); writeFileSync(join(d, 'win', 'orb-combat-ex.exe'), game);
  mkdirSync(join(d, 'lin')); writeFileSync(join(d, 'lin', 'orb-combat-ex.x86_64'), game); writeFileSync(join(d, 'lin', 'orb-combat-ex.exe'), 'x');
  mkdirSync(join(d, 'none'));
  check('a build folder gives its game file (.x86_64 before .exe, a lone .exe, a file as it is)', gameFileOf(join(d, 'lin')).endsWith('.x86_64') && gameFileOf(join(d, 'win')).endsWith('.exe') && gameFileOf(join(d, 'win', 'readme.txt')).endsWith('readme.txt'));
  let e2 = null; try { gameFileOf(join(d, 'none')); } catch (e) { e2 = e.message; }
  check('a folder with no game file is refused', e2 !== null && /no game file/.test(e2));
} finally { rmSync(d, { recursive: true, force: true }); }

console.log(failed ? `build-check self-test: ${failed} of ${ran} FAILED` : `build-check self-test ok: ${ran} checks`);
process.exit(failed ? 1 : 0);
