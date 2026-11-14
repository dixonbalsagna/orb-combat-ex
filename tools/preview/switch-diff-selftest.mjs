// Self-test of tools/preview/switch-diff.mjs (A-CODE-03 criterion 2): the comparison of the switch table between main's data and a build's packed data. Pure; node only.
//   node tools/preview/switch-diff-selftest.mjs
import { diffRows, keysOf, report } from './switch-diff.mjs';

let ran = 0, failed = 0;
const check = (name, ok, extra) => { ran++; if (!ok) { failed++; console.log(`  FAIL ${name}${extra ? ': ' + extra : ''}`); } };

const table = [
  { id: 'a', file: 'data/a.json', path: ['x', 'enabled'] },
  { id: 'b', file: 'data/b.json', path: ['on'] },
  { id: 'c', file: 'data/c.json', path: ['k'], more: [{ file: 'ui/data/f.json', path: ['features', 'f'] }] },
  { id: 'word', url: 'planet=7' },
  { id: 'd', file: 'data/d.json', path: ['gone'] },
];
const files = (o) => (f) => (f in o ? o[f] : null);
const main = files({ 'data/a.json': { x: { enabled: false } }, 'data/b.json': { on: true }, 'data/c.json': { k: 1 }, 'ui/data/f.json': { features: { f: false } }, 'data/d.json': { other: 1 } });
const build = files({ 'data/a.json': { x: { enabled: true } }, 'data/b.json': { on: true }, 'data/c.json': { k: 1 }, 'ui/data/f.json': { features: { f: true } }, 'data/d.json': { other: 1 } });
const d = diffRows(table, main, build);
check('a row whose key reads another value in main than in the build differs', d.rows.find((r) => r.id === 'a').differs);
check('a row that reads the same in both does not differ', !d.rows.find((r) => r.id === 'b').differs);
check('a row differs when only one of its `more` keys differs (c: its own key is the same, the ui key is not)', d.rows.find((r) => r.id === 'c').differs && d.rows.find((r) => r.id === 'c').keys.filter((k) => k.state === 'differs').length === 1);
check('a page word is not data: counted apart, not in the rows', d.apart === 1 && !d.rows.some((r) => r.id === 'word'));
check('a key absent in both is not a difference', !d.rows.find((r) => r.id === 'd').differs && d.rows.find((r) => r.id === 'd').keys[0].state === 'absent in both');
check('the totals: 2 of 4 data rows differ, one row apart', d.differ === 2 && d.data === 4 && d.apart === 1, JSON.stringify([d.differ, d.data, d.apart]));
const d2 = diffRows(table, files({ 'data/a.json': { x: { enabled: false } } }), files({ 'data/a.json': { x: {} }, 'data/b.json': { on: true } }));
check('a key only in main, or only in the build, is a difference', d2.rows.find((r) => r.id === 'a').differs && d2.rows.find((r) => r.id === 'a').keys[0].state === 'only in main' && d2.rows.find((r) => r.id === 'b').keys[0].state === 'only in the build');
check('a missing file is a missing key, not a crash', diffRows(table, () => null, () => null).differ === 0);
check('numbers compare as numbers, objects as JSON', diffRows([{ id: 'n', file: 'f', path: ['v'] }], files({ f: { v: 2 } }), files({ f: { v: 2.0 } })).differ === 0 && diffRows([{ id: 'o', file: 'f', path: ['v'] }], files({ f: { v: { a: 1 } } }), files({ f: { v: { a: 2 } } })).differ === 1);
check('keysOf: the row\'s own key then its more keys, none for a page word', keysOf(table[2]).length === 2 && keysOf(table[3]).length === 0);
const text = report(d, { list: true, buildName: 'b1', rev: 'HEAD' });
check('the report names the differing rows and ends with the count line', /a +data\/a.json x.enabled: main false, build true/.test(text) && /: 2 of 4 data rows \(1 more are page words/.test(text), text);

console.log(failed ? `switch-diff self-test FAILED: ${failed} of ${ran}` : `switch-diff self-test ok: ${ran} checks`);
process.exit(failed ? 1 : 0);
