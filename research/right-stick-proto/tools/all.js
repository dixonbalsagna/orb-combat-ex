// The fast set: the gate, the three sweeps at their quick size, the two random checkers and a short fuzz, in about a
// minute at below-normal priority. Each prints its own findings; a summary closes it. Exits 1 on any breach.
// node all.js [--cliff]        (--cliff adds the cliff and settle sweeps, which are geometry, not the law)
// RS_SIM=<file> node all.js    (another copy of the sim: an .html with the markers, or a .js that defines S)
'use strict';
const H = require('./harness.js');
H.below();
const steps = [
  ['gate', () => require('./gate.js').main()],
  ['press-stick --quick', () => require('./press-stick.js').main(true)],
  ['stick-press --quick', () => require('./stick-press.js').main(true)],
  ['queued --quick', () => require('./queued.js').main(true)],
  ['chains 1000', () => require('./chains.js').main(1000, 1)],
  ['one-thumb 1000', () => require('./one-thumb.js').main(1000, 1)],
  ['fuzz all 2 x 1500', () => require('./fuzz.js').main(2, 1500)],
];
if (process.argv.includes('--cliff')) steps.push(['cliff 8', () => require('./cliff.js').main(8)], ['settle', () => require('./settle.js').main()]);
console.log('sim:', H.SIM);
const rows = [];
for (const [name, fn] of steps) {
  const t0 = Date.now(); let r;
  console.log(`\n== ${name}`);
  try { r = fn(); } catch (e) { console.log('THROWS', e.stack); r = { breaches: 1 }; }
  rows.push([name, r.breaches, ((Date.now() - t0) / 1000).toFixed(1)]);
}
console.log('\n== summary');
for (const [name, n, s] of rows) console.log(`${name.padEnd(22)} ${String(n).padStart(6)} breaches  ${s} s`);
const total = rows.reduce((a, r) => a + r[1], 0);
console.log(total ? `FAIL: ${total} breaches` : 'PASS: no breaches');
process.exitCode = total ? 1 : 0;
