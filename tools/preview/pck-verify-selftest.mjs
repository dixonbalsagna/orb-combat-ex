// Self-test of tools/preview/pck-verify.mjs: a small Godot pack (format 2, absolute offsets) is written here with data files in it, and each way a built pack can disagree with its list must be found:
// a held or off row that is on in the data, an ON row that is off, a missing key or file, a key shared by two rows, a row over two files. No Godot, no browser. CI runs it.
//   node tools/preview/pck-verify-selftest.mjs
import { verifyPack } from './pck-verify.mjs';

let ran = 0, failed = 0;
const check = (name, ok, extra) => { ran++; if (!ok) { failed++; console.log(`  FAIL ${name}${extra ? ': ' + extra : ''}`); } };

/** A Godot 4 pack, format version 2, flags 0 (absolute offsets): files = { 'res://path': text }. */
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
const J = (o) => JSON.stringify(o, null, 2);
const table = [
  { id: 'plain', file: 'data/a.json', path: ['x', 'enabled'], from: false, to: true, needs: [] },
  { id: 'held', file: 'data/a.json', path: ['y', 'enabled'], from: false, to: true, needs: [], held: 'waiting' },
  { id: 'multi', file: 'data/b.json', path: ['lodge'], from: 'world', to: 'body', more: [{ path: ['stop'], from: 1, to: 0 }, { path: ['hold'], from: 0, to: 1 }], needs: [] },
  { id: 'two', file: 'data/a.json', path: ['z', 'enabled'], from: false, to: true, more: [{ file: 'data/c.json', path: ['sw', 'k1'], from: false, to: true }, { file: 'data/c.json', path: ['sw', 'shared'], from: false, to: true }], needs: [] },
  { id: 'sharedRow', file: 'data/c.json', path: ['sw', 'shared'], from: false, to: true, needs: [] },
  { id: 'word', url: 'tiles=1', needs: [] },
  { id: 'const', file: 'sim/x.gd', replace: { from: 'A', to: 'B' }, needs: [] },
];
const good = makePack({
  'res://data/a.json': J({ x: { enabled: true }, y: { enabled: false }, z: { enabled: false } }),
  'res://data/b.json': J({ lodge: 'body', stop: 0.0, hold: 1 }),
  'res://data/c.json': J({ sw: { k1: false, shared: true } }),
});
let r = verifyPack(good, table, ['plain', 'multi', 'sharedRow']);
check('a pack that matches its list: no problem, and the keys are read from the pack', r.ok && r.checked >= 8, JSON.stringify(r.problems));
check('a key shared with a row that is on is expected on (the two row has it, the sharedRow is on)', r.lines.some((l) => /two .*sw\.shared = true \(a key of a row that is on\)/.test(l)) && !r.problems.length);

const heldOn = makePack({
  'res://data/a.json': J({ x: { enabled: true }, y: { enabled: true }, z: { enabled: false } }),
  'res://data/b.json': J({ lodge: 'body', stop: 0, hold: 1 }),
  'res://data/c.json': J({ sw: { k1: false, shared: true } }),
});
r = verifyPack(heldOn, table, ['plain', 'multi', 'sharedRow']);
check('a held row that is ON in the data is a problem naming the row, the key and the value (the 2026-11-07 fault)', !r.ok && r.problems.some((p) => /^held: not on but data\/a\.json y\.enabled holds true, expected false/.test(p)), JSON.stringify(r.problems));

const onOff = makePack({
  'res://data/a.json': J({ x: { enabled: false }, y: { enabled: false }, z: { enabled: false } }),
  'res://data/b.json': J({ lodge: 'world', stop: 1, hold: 0 }),
  'res://data/c.json': J({ sw: { k1: false, shared: true } }),
});
r = verifyPack(onOff, table, ['plain', 'multi', 'sharedRow']);
check('an ON row whose keys are off in the data is a problem (each key of a several-key row)', !r.ok && r.problems.some((p) => /^plain: ON but/.test(p)) && r.problems.filter((p) => /^multi: ON but/.test(p)).length === 3, JSON.stringify(r.problems));

r = verifyPack(good, table, ['plain', 'multi', 'sharedRow', 'two']);
check('a row over two files: ON needs every key of every file at its "to" value (k1 is false: a problem)', !r.ok && r.problems.some((p) => /^two: ON but data\/c\.json sw\.k1 holds false/.test(p)) && r.problems.some((p) => /^two: ON but data\/a\.json z\.enabled holds false/.test(p)), JSON.stringify(r.problems));

const missingKey = makePack({ 'res://data/a.json': J({ x: {} }), 'res://data/b.json': J({}), 'res://data/c.json': J({ sw: {} }) });
r = verifyPack(missingKey, table, ['plain']);
check('an ON row whose key is not in the pack is a problem; an off row whose key is absent is fine', !r.ok && r.problems.length === 1 && /^plain: ON, but data\/a\.json x\.enabled is not in the pack/.test(r.problems[0]), JSON.stringify(r.problems));
const missingFile = makePack({ 'res://data/b.json': J({ lodge: 'world' }) });
r = verifyPack(missingFile, table, ['plain']);
check('an ON row whose file is not in the pack is a problem; the rows that are off need nothing', !r.ok && r.problems.length === 1 && /^plain: ON, but data\/a\.json is not readable in the pack/.test(r.problems[0]), JSON.stringify(r.problems));
r = verifyPack(good, table, []);
check('with nothing on, every key must hold its "from" value (the multi row reads "body": a problem each)', !r.ok && r.problems.length >= 3, JSON.stringify(r.problems));
check('page words and constants in a script are not read (no problem for them)', !verifyPack(good, table, ['plain', 'multi', 'sharedRow']).lines.some((l) => /^(word|const)/.test(l)));
let bad = null; try { verifyPack(Buffer.from('not a pack at all'.repeat(10)), table, []); } catch (e) { bad = e.message; }
check('a file that is not a pack throws, it is not read as clean', bad !== null && /GDPC|pack/.test(bad), String(bad));

console.log(failed ? `pck verify self-test FAILED: ${failed} of ${ran} checks` : `pck verify self-test ok: ${ran} checks`);
process.exit(failed ? 1 : 0);
