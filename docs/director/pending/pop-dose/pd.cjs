// pd.cjs: Game Design's rulings-2026-10-26 items 42 and 43, the pop dose, on c2a0dba2.
// brawl.launcher.anywhere.pop: full 0.8 to 0.72, stringPoints 2 to 3, and the pop's _note says why. The pop is read only
// with launch anywhere on (DirBrawl.popOn), which is off on main, so the golden doesn't move. Easy's answer share
// (item 43's second value, ai.json) is not in this park: QA reads it first.
//   node pd.cjs <checkout root> [--check]
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const opts = process.argv.slice(3);
for (const o of opts) if (o !== '--check') throw new Error('unknown option: ' + o);
if (!root || root.startsWith('--')) throw new Error('usage: node pd.cjs <checkout root> [--check]');
const check = opts.includes('--check');
function edit(rel, fn) {
  const p = path.join(root, rel);
  let t = fs.readFileSync(p, 'utf8');
  const crlf = t.includes('\r\n');
  if (crlf) t = t.replace(/\r\n/g, '\n');
  const rep = (a, b) => {
    const n = t.split(a).length - 1;
    if (n !== 1) throw new Error(rel + ': expected 1 match, got ' + n + ' for: ' + a.slice(0, 90));
    t = t.replace(a, () => b);
  };
  fn(rep);
  if (!check) {
    JSON.parse(t);
    fs.writeFileSync(p, crlf ? t.replace(/\n/g, '\r\n') : t);
  }
  console.log(rel + (check ? ': anchors ok' : ': ok'));
}
edit('data/director/interrupts.json', rep => {
  rep('"pop": {"enabled": true, "full": 0.8, "bh": [1.5, 3.0],',
      '"pop": {"enabled": true, "full": 0.72, "bh": [1.5, 3.0],');
  rep('"fallTicks": 6, "stringPoints": 2, "freeAt": 12, "spike"',
      '"fallTicks": 6, "stringPoints": 3, "freeAt": 12, "spike"');
  rep('With it, no string armour (hardFromChain is not read). false: every launcher sends, as before"',
      'With it, no string armour (hardFromChain is not read). false: every launcher sends, as before. ' +
      'rulings-2026-10-26 items 42 and 43: full 0.8 to 0.72 and stringPoints 2 to 3, so more of a long string\'s ' +
      'launchers send instead of popping again, and the shortest matches reach 300 s (p10 306 s on 200 matches, from 284: ' +
      'QA\'s reads in docs/qa/rally-read-fa6f727a.md)"');
});
