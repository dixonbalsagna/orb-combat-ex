// ea.cjs: Game Design's rulings-2026-10-26 items 43 and 44, easy's answer share, on d7647634.
// ai.json levels.easy.brawl.anywhere.answer 0.2 to 0.25, and the brawl note says why. The share is drawn only under
// launch anywhere (DirBrawl._laAnswerPlan, called inside DirBrawl.anywhere()), which is off on main, so the golden
// doesn't move. rally.linkWorth stays 0.8.
//   node ea.cjs <checkout root> [--check]
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const opts = process.argv.slice(3);
for (const o of opts) if (o !== '--check') throw new Error('unknown option: ' + o);
if (!root || root.startsWith('--')) throw new Error('usage: node ea.cjs <checkout root> [--check]');
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
edit('data/director/ai.json', rep => {
  rep('"anywhere": {"launcher": 0.15, "inString": 0.05, "answer": 0.2}',
      '"anywhere": {"launcher": 0.15, "inString": 0.05, "answer": 0.25}');
  rep('times earnerUse, and the signature at sigPick"',
      'times earnerUse, and the signature at sigPick. anywhere.answer: the chance it guesses, when a rival\'s blow lands ' +
      'clean on it, that a launcher follows, and times its guard to it (interrupts.json brawl.launcher.anywhere.answer). ' +
      'Easy\'s is 0.25, from 0.2 (rulings-2026-10-26 items 43 and 44): the newcomer against easy read 97.0% at 0.2 with ' +
      'the pop dose, and 88.5% at 0.25 on 200 matches (Wilson 83.3 to 92.2, inside the 82 to 92 aimed at; ' +
      'docs/qa/rally-read-fa6f727a.md, fifth addendum)"');
});
