// Claw chains (from chain5b): random chains of three or four inputs (presses, stick and D-pad commands, LT slips, RT with
// the D-pad, held B), each a tight claw gap after the last (0 to 5 ticks, or overlapping it), against a rival who may throw a
// blow, a heavy or a grab. Every run is held to the law's checks (harness lawCheck): no press inside a stick commitment, no
// stick or D-pad act inside a face press's commitment, nothing silent. node chains.js [count] [seed]
'use strict';
const H = require('./harness.js');
const POS = [[300, 60, 360, 60], [230, 60, 430, 80], [160, 60, 540, 80], [300, 60, 345, 60], [600, 30, 300, 130], [545, 0, 585, 0], [300, 4, 420, 60]];
const DIRS = [0, 45, 90, 180, 270, 200];
const FAMSH = { flight: {}, aim: { RB: 1 }, lay: { RB: 1, LB: 1 }, read: { LB: 1 }, rt: { RT: 1 } };
function chain(R) {
  const pick = (a) => a[Math.floor(R() * a.length)];
  // each element: k (its name), sh (shoulders held while it is made), dur (ticks on it), and what it does
  function elem() {
    const k = pick(['X', 'bolt', 'lob', 'Btap', 'Bheld', 'mine', 'flick', 'flick', 'hold', 'slow', 'pad', 'padhold', 'LT', 'RTpad']);
    const fam = pick(['flight', 'flight', 'aim', 'lay', 'read', 'rt']), dir = pick(DIRS), sh = FAMSH[fam];
    switch (k) {
      case 'X': return { k, sh: {}, dur: 1, btn: 'X' };
      case 'bolt': return { k, sh: { RB: 1 }, dur: 1, btn: 'X' };
      case 'lob': return { k, sh: { RB: 1 }, dur: 1, btn: 'Y' };
      case 'Btap': return { k, sh: { RB: 1 }, dur: 1, btn: 'B' };
      case 'Bheld': { const d = pick([6, 12, 31, 40]); return { k: k + d, sh: { RB: 1 }, dur: d, btn: 'B' }; }
      case 'mine': return { k, sh: { RB: 1, LB: 1 }, dur: 1, btn: 'X' };
      case 'flick': { const d = pick([1, 2, 3]); return { k: `${fam} flick${d} ${dir}`, sh, dur: d, g: ['flick', dir, d] }; }
      case 'hold': { const d = pick([12, 16, 24]); return { k: `${fam} hold${d} ${dir}`, sh, dur: d, g: ['hold', dir, d] }; }
      case 'slow': { const d = pick([14, 20]); return { k: `${fam} slow${d} ${dir}`, sh, dur: d + 3, g: ['slow', dir, d] }; }
      case 'pad': return { k: `${fam} pad ${dir}`, sh, dur: 1, g: ['flick', dir, 1, true] };
      case 'padhold': { const d = pick([12, 16]); return { k: `${fam} padhold${d} ${dir}`, sh, dur: d, g: ['hold', dir, d, true] }; }
      case 'LT': { const ld = pick([[0, 0], [1, 0], [-1, 0], [0, 1], [0, -1]]); return { k: `LT ${ld}`, sh: { LT: 1 }, dur: 2, lst: ld }; }
      case 'RTpad': return { k: `RT+pad ${dir}`, sh: { RT: 1 }, dur: 2, g: ['flick', dir, 2, true] };
    }
  }
  const n = R() < 0.5 ? 3 : 4, pos = pick(POS), spec = { st: [], btn: {}, V: {} }, plan = [];
  let t = 20;
  for (let j = 0; j < n; j++) {
    const el = elem(); el.t = t; plan.push(el.k + '@' + t);
    for (const s in el.sh) H.hold(spec, s, t, t + el.dur + (el.btn ? 40 : 0));     // a press keeps its shoulders, so it can still start from the queue
    if (el.btn) H.hold(spec, el.btn, t, t + el.dur);
    if (el.g) H.gesture(spec, t, el.g[0], el.g[1], el.g[2], el.g[3]);
    if (el.lst) { H.hold(spec, 'lx', t, t + el.dur, el.lst[0]); H.hold(spec, 'ly', t, t + el.dur, el.lst[1]); }
    t = Math.max(t, t + el.dur + pick([-2, -1, 0, 0, 1, 2, 3, 4, 5]));
  }
  const u = R(), vt = pick([10, 20, 25, 30, 35, 40]);
  if (u < 0.4) spec.V.blow = [[vt, vt + 1, 'mid']]; else if (u < 0.6) spec.V.heavy = [[vt, vt + 1]]; else if (u < 0.72) spec.V.grab = [[vt, vt + 1]];
  return { pos, spec, plan, len: t + 70 };
}
function main(count, seed) {
  const S = H.load(), R = H.rng(seed), T = H.tally(); let breaches = 0;
  for (let i = 0; i < count; i++) {
    const c = chain(R), P = c.pos;
    const r = H.run(S, c.len, (w) => { w.P.x = P[0]; w.P.y = P[1]; w.V.x = P[2]; w.V.y = P[3]; if (P[2] - P[0] === 45) w.brawl = { t: 0, idle: -300 }; }, H.inp(c.spec), { trace: true });
    for (const f of H.lawCheck(r, c.spec)) { if (!f.info) breaches++; T.add((f.info ? 'info ' : '') + f.k + ': ' + f.why.replace(/-?\d+/g, 'N'), `${f.why} | pos ${P} V ${JSON.stringify(c.spec.V)} | ${c.plan.join(', ')} | ${H.showE(r.E, 15)}`); }
  }
  T.print(5);
  console.log(`chains: ${count} chains (seed ${seed}), ${breaches} breaches`);
  return { breaches };
}
if (require.main === module) { H.below(); process.exitCode = main(+(process.argv[2] || 3000), +(process.argv[3] || 1)).breaches ? 1 : 0; }
module.exports = { main };
