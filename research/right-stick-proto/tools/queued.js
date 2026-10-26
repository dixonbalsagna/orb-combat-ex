// A queued press, then the stick (from sweep5): a press made while something holds him (a press under way, a lunge, a
// slip, a stick commitment, a bolt's gap) waits in the queue; then a stick or D-pad gesture at gaps -2 to 8 after the
// thumb leaves that press. The law: a press still waiting commits the stick too, counted from its press (or from the stick
// commitment's end it was made in, or a held B's last tick down); a stick input inside waits and acts at that + L
// (items 13, 16); and the queued press, when it starts, still waits out any stick commitment then in force (R30).
//   EARLY        any grip: a stick result before the floor, or the queued press starting inside a stick commitment
//   LATE         one thumb (the stick 6 after the thumb leaves the press, or the D-pad): a stick result later than
//                max(the same run with no queued press, the floor)
//   PRESS LATE   one thumb: the queued press starts later than its start with no gesture, pushed past the stick's own
//                commitments (the law allows only those)
// node queued.js [--quick]
'use strict';
const H = require('./harness.js'), { L, R, hold: HOLDT, rise: RISE } = H.LAW;
const POS = { close: [300, 60, 360, 60], far: [160, 60, 540, 80] };
// the blocker from 20; Q: the queued press's tick; from: where its commitment counts from (Q, or the stick commitment's end)
const BLOCK = {
  Xclose: { pos: 'close', btn: { X: [[20, 21]] }, Q: 25 },
  Xfar: { pos: 'far', btn: { X: [[20, 21]] }, Q: 26 },
  slip: { pos: 'close', btn: { LT: [[20, 22]] }, Q: 24 },
  aimflick: { pos: 'close', btn: { RB: [[18, 23]] }, st: [[18, 20, 90]], Q: 22, from: 26 },     // the press inside a stick commitment
  bolt2: { pos: 'close', btn: { X: [[20, 21]], RB: [[19, 140]] }, Q: 22 },                     // a bolt, then another inside its gap
};
const PRESS = { bolt: { b: 'X', sh: { RB: 1 } }, lob: { b: 'Y', sh: { RB: 1 } }, Btap: { b: 'B', sh: { RB: 1 } }, Bheld: { b: 'B', sh: { RB: 1 }, len: 10 }, mine: { b: 'X', sh: { RB: 1, LB: 1 } }, X: { b: 'X', sh: {} } };
const FAMS = { flight: {}, aim: { RB: 1 }, lay: { RB: 1, LB: 1 }, read: { LB: 1 } };
const GEST = { flick1: ['flick', 1], flick2: ['flick', 2], hold: ['hold', 24], slow: ['slow', 21], pad: ['flick', 1, true], padhold: ['hold', 14, true] };
let DIRS = [0, 90, 180, 270];
let S;
const cache = new Map();
function one(bk, pk, fam, gk, dir, at, noQ) {
  const key = [bk, pk, noQ ? 1 : 0, fam, gk, dir, at].join('|'); if (cache.has(key)) return cache.get(key);
  const B = BLOCK[bk], pr = PRESS[pk], spec = { st: (B.st || []).slice(), btn: JSON.parse(JSON.stringify(B.btn)), V: {} }, Q = B.Q;
  if (!noQ) H.hold(spec, pr.b, Q, Q + (pr.len || 1));
  for (const s in pr.sh) H.hold(spec, s, Q - 1, Q + 60);           // kept in the control too, so the gesture's family is the same
  if (gk) { const g = GEST[gk]; for (const s in FAMS[fam]) H.hold(spec, s, at - 1, at + g[1] + 7); H.gesture(spec, at, g[0], dir, g[1], g[2]); }
  const P = POS[B.pos];
  const r = H.run(S, 130, (w) => { w.P.x = P[0]; w.P.y = P[1]; w.V.x = P[2]; w.V.y = P[3]; }, H.inp(spec), { trace: true });
  const res = { r, stick: r.E.find((e) => e.t >= at && (e.k === 'S' || e.k === 'S-' || e.k === 'H')), press: r.E.find((e) => e.t >= Q && e.k === 'P' && e.q) };
  if (cache.size > 3000) cache.clear(); cache.set(key, res); return res;
}
function main(quick) {
  DIRS = quick ? [90, 180] : [0, 90, 180, 270];
  S = H.load(); cache.clear();
  const T = H.tally(); let n = 0, breaches = 0;
  const bad = (k, ex) => { breaches++; T.add(k, ex); };
  for (const bk in BLOCK) for (const pk in PRESS) for (const fam in FAMS) for (const gk in GEST) for (const dir of DIRS) {
    const B = BLOCK[bk], g = GEST[gk], len = PRESS[pk].len || 1, qEnd = B.Q + len - 1;
    const alone = one(bk, pk, fam, null, dir, 0);                       // the queued press with no gesture
    if (!alone.press) continue;                                          // it never queues (refused, or started at once)
    for (let gap = -2; gap <= 8; gap++) {
      n++;
      const at = qEnd + gap, c = one(bk, pk, fam, gk, dir, at), ctl = one(bk, pk, fam, gk, dir, at, true), legal = !!g[2] || gap >= L;
      const where = `${bk} then ${pk} queued at ${B.Q}, then ${fam} ${gk} ${dir} at ${at} (gap ${gap})`;
      // a held press counts from its last tick down (the README's rule for a held B), queued or not
      const from = Math.max(B.from || B.Q, qEnd);
      const cs = H.commitments(c.r), pst = c.press, queuedHere = c.r.E.some((e) => e.k === 'Q' && e.t === B.Q);
      if (pst && H.inside(cs, pst.t)) bad(`EARLY PRESS ${bk} ${pk} ${fam} ${gk}`, `${where}: the queued press starts ${pst.t} inside the stick's commitment ${JSON.stringify(H.inside(cs, pst.t))} | ${H.showE(c.r.E, B.Q)}`);
      const b = ctl.stick, a = c.stick;
      if (!b || b.t < B.Q || at < B.Q) continue;                          // nothing to time, or the gesture came before the press
      // a press made with the stick (or the D-pad) already out counts from the stick's act instead: no floor on that act
      const out = at === B.Q && !(gk === 'slow') && !/^pad/.test(gk), pressFrom = queuedHere && !out ? from : -99;
      const hold = b.k === 'H', floor = hold ? pressFrom + L + HOLDT + (gk === 'slow' && at < pressFrom + L ? RISE : 0) : pressFrom + R, want = Math.max(b.t, floor);
      if (a && a.k !== 'S-' && a.t < (hold ? pressFrom + L + HOLDT : pressFrom + R)) bad(`EARLY ${bk} ${pk} ${fam} ${gk}`, `${where}: ${a.t} ${a.what || a.cmd}, floor ${floor} | ${H.showE(c.r.E, B.Q)}`);
      else if (legal && a && a.t > want && (a.what || a.cmd) === (b.what || b.cmd)) bad(`LATE ${bk} ${pk} ${fam} ${gk}`, `${where}: ${a.t} ${a.what || a.cmd}, the law's ${want} | ${H.showE(c.r.E, B.Q)} | no queued press: ${H.showE(ctl.r.E, B.Q)}`);
      // (R28: a press under way takes no flight command, so a hold that meets one is not lost)
      else if (legal && !a && b.k !== 'S-' && !c.r.trace.some((x) => x.t >= at && (x.rooted || x.caught || (fam === 'flight' && (x.seq || x.blow))))) bad(`LOST ${bk} ${pk} ${fam} ${gk}`, `${where}: nothing, alone ${b.t} ${b.what || b.cmd} | ${H.showE(c.r.E, B.Q)}`);
      // the queued press against its start with no gesture, pushed only by what the stick really committed
      if (legal && pst && alone.press) { const s = H.freeAt(cs, alone.press.t); if (pst.t > s) bad(`PRESS LATE ${bk} ${pk} ${fam} ${gk}`, `${where}: the queued press starts ${pst.t}, the law's ${s} (alone ${alone.press.t}) | ${H.showE(c.r.E, B.Q)}`); }
    }
  }
  T.print(4);
  console.log(`queued: ${n} cases, ${breaches} breaches`);
  return { breaches };
}
if (require.main === module) { H.below(); process.exitCode = main(process.argv.includes('--quick')).breaches ? 1 : 0; }
module.exports = { main };
