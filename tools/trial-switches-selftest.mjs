// Self-test of tools/trial-switches.mjs: the list's rules, choosing, flipping a scratch tree, and the read-back from a made-up program with an embedded pack.   node tools/trial-switches-selftest.mjs
import { mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { applyRows, choose, embeddedPack, fits, loadList, readBack, readList, FIXED } from './trial-switches.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
let ran = 0, failed = 0;
const check = (name, ok, extra) => { ran++; if (!ok) { failed++; console.log(`FAIL ${name}${extra ? ': ' + extra : ''}`); } };
const row = (o = {}) => ({ id: 'a_switch', what: 'w', owner: 'o', file: 'data/x.json', path: ['on'], from: false, to: true, ...o });
const L = (...rows) => loadList(JSON.stringify({ rows }));

const real = readList();
check('the list in the tree has no problem and every row fits the tree', real.problems.length === 0 && fits(join(HERE, '..'), real.rows).problems.length === 0, [...real.problems, ...fits(join(HERE, '..'), real.rows).problems].join('; '));
check('a good row passes; no id, a double id, no owner, a file outside data, no from and to, and the same from and to are named', L(row()).problems.length === 0 && [[row({ id: 'A B' })], [row(), row()], [row({ owner: '' })], [row({ file: 'project.godot' })], [row({ file: 'data/../tools/x.json' })], [row({ from: undefined, to: undefined })], [row({ to: false })]].every((r) => L(...r).problems.length >= 1));
check('the fixed switches are never rows', FIXED.every((f) => L(row({ file: 'ui/data/features.json', path: ['features', f] })).problems.some((p) => /fixed switch/.test(p))));
const two = L(row(), row({ id: 'b_switch', path: ['b'], needs: ['a_switch'] })).rows;
const throws = (fn, re) => { try { fn(); return false; } catch (e) { return re.test(e.message); } };
check('choose: all, one, a list; an unknown name, an empty ask and a missing need are refused', choose(two, 'all').length === 2 && choose(two, 'a_switch').length === 1 && choose(two, 'b_switch,a_switch').map((r) => r.id).join() === 'a_switch,b_switch' && throws(() => choose(two, 'zz'), /not a trial switch/) && throws(() => choose(two, ''), /no trial switch/) && throws(() => choose(two, 'b_switch'), /needs "a_switch"/));

const dir = mkdtempSync(join(tmpdir(), 'trial-'));
try {
  mkdirSync(join(dir, 'data'), { recursive: true });
  const file = join(dir, 'data', 'x.json');
  const NL = String.fromCharCode(10);
  const before = '{' + NL + '  "note": "on is a word here",' + NL + '  "on": false,' + NL + '  "b": 2' + NL + '}' + NL;
  writeFileSync(file, before);
  applyRows(dir, [row()]);
  check('applying a row changes the one value and nothing else', readFileSync(file, 'utf8') === before.replace('"on": false', '"on": true'));
  check('applying again is harmless; a value that is neither is refused; a missing key and a missing file are refused', (() => { applyRows(dir, [row()]); writeFileSync(file, '{"on": 7}'); const a = throws(() => applyRows(dir, [row()]), /./); const b = throws(() => applyRows(dir, [row({ path: ['gone'] })]), /./); const c = throws(() => applyRows(dir, [row({ file: 'data/none.json' })]), /not in this commit/); return a && b && c; })());
  writeFileSync(file, '{"on": true}');
  check('fits: already on is a note, not a problem; neither value and a missing key are problems', (() => { const a = fits(dir, [row()]); writeFileSync(file, '{"on": 7}'); const b = fits(dir, [row()]); const c = fits(dir, [row({ path: ['gone'] })]); return a.problems.length === 0 && a.notes.length === 1 && b.problems.length === 1 && c.problems.length === 1; })());
} finally { rmSync(dir, { recursive: true, force: true }); }

// a made-up program: junk, then a version-2 pack holding data/x.json, then the pack's size and the magic
function pack(path, text) {
  const body = Buffer.from(text, 'utf8');
  const name = Buffer.from(path, 'utf8');
  const head = Buffer.alloc(32 + 16 * 4);
  head.write('GDPC', 0, 'latin1'); head.writeUInt32LE(2, 4); head.writeUInt32LE(4, 8); head.writeUInt32LE(7, 12); head.writeUInt32LE(0, 16);
  const entry = Buffer.alloc(4 + 4 + name.length + 8 + 8 + 16 + 4);
  const dirLen = 4 + entry.length - 4;
  const base = head.length + dirLen;
  entry.writeUInt32LE(1, 0); entry.writeUInt32LE(name.length, 4); name.copy(entry, 8);
  entry.writeBigUInt64LE(BigInt(base), 8 + name.length); entry.writeBigUInt64LE(BigInt(body.length), 16 + name.length);
  return Buffer.concat([head, entry, body]);
}
const program = (p) => { const size = Buffer.alloc(8); size.writeBigUInt64LE(BigInt(p.length)); return Buffer.concat([Buffer.alloc(500, 1), p, size, Buffer.from('GDPC', 'latin1')]); };
const on = program(pack('res://data/x.json', '{"on": true}')), off = program(pack('res://data/x.json', '{"on": false}'));
check('the embedded pack is found by its size, and bytes without one are refused', embeddedPack(on).toString('latin1', 0, 4) === 'GDPC' && throws(() => embeddedPack(Buffer.alloc(200)), /no embedded pack/));
check('read-back: asked on and holding on passes; asked on but off, and off but on, are named', readBack(on, [row()], [row()]).ok && !readBack(off, [row()], [row()]).ok && !readBack(on, [row()], []).ok && readBack(off, [row()], []).ok, JSON.stringify(readBack(on, [row()], [row()])));
check('read-back: a row whose file the program does not hold proves nothing and fails', !readBack(on, [row({ file: 'data/other.json' })], [row({ file: 'data/other.json' })]).ok);
console.log(failed ? `trial switches self-test FAILED: ${failed} of ${ran}` : `trial switches self-test ok: ${ran} checks`);
process.exit(failed ? 1 : 0);
