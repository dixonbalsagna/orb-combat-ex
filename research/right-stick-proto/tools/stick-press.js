// Stick, then press (from sweep4): a stick or D-pad command of every family and gesture, by every position, then a face
// press of every kind at gaps -3 to 8 after the thumb leaves the stick (the D-pad leaves the right thumb free, so every
// gap is one thumb's). The law (R30, gate A and C): a press starts no sooner than the end of every stick commitment in
// force: a flick commits L from its act (the lunge, its rush), a hold until release + L (the brawl cross-up, its arc; the
// beam sweep, nothing). The commitments are read from the run's own stick events, so a press that moved the stick's
// timing (it came first, item 13) is held to what the stick really did.
//   EARLY  any grip: a press starts inside a stick commitment
//   LATE   one thumb (the press 6 after the thumb leaves the stick, or after any D-pad command): starts after the law's tick
//   SILENT one thumb: the press never starts and nothing flickers in his hand (E3)
// node stick-press.js [--quick]
'use strict';
const H = require('./harness.js'), { L } = H.LAW;
const T0 = 20;
const POS = { close: [300, 60, 360, 60], range: [230, 60, 430, 80], far: [160, 60, 540, 80], brawl: [300, 60, 345, 60], cliff: [600, 30, 300, 130] };
const FAMS = { flight: {}, aim: { RB: 1 }, lay: { RB: 1, LB: 1 }, read: { LB: 1 }, rt: { RT: 1 }, lt: { LT: 1 } };
const PRESS = { X: { b: 'X', sh: {} }, bolt: { b: 'X', sh: { RB: 1 } }, lob: { b: 'Y', sh: { RB: 1 } }, Btap: { b: 'B', sh: { RB: 1 } }, Bheld: { b: 'B', sh: { RB: 1 }, len: 12 }, mine: { b: 'X', sh: { RB: 1, LB: 1 } } };
// gestures: kind, ticks out (the thumb leaves the stick when it is back at rest), on the D-pad or the stick
const GEST = { flick1: ['flick', 1], flick3: ['flick', 3], hold: ['hold', 20], slow: ['slow', 17], pad: ['flick', 1, true], padhold: ['hold', 20, true] };
let DIRS = [0, 90, 180, 270];
let S;
function one(pos, fam, gk, dir, pk, at) {
  const g = GEST[gk], pr = PRESS[pk], spec = { st: [], btn: {}, V: {} }, leave = T0 + g[1] + (gk === 'slow' ? 3 : 0), swap = at == null ? leave : Math.min(leave, at);
  for (const k of ['RB', 'LB', 'RT', 'LT']) { if (FAMS[fam][k]) H.hold(spec, k, 0, swap); if (pr.sh[k]) H.hold(spec, k, swap, 140); }
  if (at != null) H.hold(spec, pr.b, at, at + (pr.len || 1));
  H.gesture(spec, T0, g[0], dir, g[1], g[2]);
  const P = POS[pos];
  return H.run(S, 140, (w) => { w.P.x = P[0]; w.P.y = P[1]; w.V.x = P[2]; w.V.y = P[3]; if (pos === 'brawl') w.brawl = { t: 0, idle: -200 }; }, H.inp(spec), { trace: true });
}
function commit(r) { return r.E.filter((e) => e.k === 'S' || e.k === 'H' || e.k === 'Z' || e.k === 'K').map((e) => e.t + e.k).join(' '); }
function main(quick) {
  DIRS = quick ? [0, 90] : [0, 90, 180, 270];
  S = H.load();
  const T = H.tally(); let n = 0, breaches = 0;
  for (const pos in POS) for (const fam in FAMS) for (const gk in GEST) for (const dir of DIRS) for (const pk in PRESS) {
    const g = GEST[gk], pad = !!g[2], leave = T0 + g[1] + (gk === 'slow' ? 3 : 0);
    // (a gesture that does nothing here, under RT or LT, commits nothing: the press must start at once)
    for (let gap = -3; gap <= 8; gap++) {
      n++;
      const at = leave + gap, r = one(pos, fam, gk, dir, pk, at), st = r.E.find((e) => e.t >= at && e.k === 'P'), legal = pad || gap >= L;
      const want = H.freeAt(H.commitments(r), at), where = `${pos} ${fam} ${gk} ${dir} then ${pk} at ${at} (gap ${gap} after the thumb leaves at ${leave})`;
      if (!st) {
        const acked = r.E.some((e) => e.t >= at && e.k === 'N');
        if (legal && !acked && !r.trace.some((x) => x.t >= at && x.caught)) { breaches++; T.add(`SILENT ${pos} ${fam} ${gk} ${pk}`, `${where}: never starts, no flicker | stick ${commit(r)}`); }
        else T.add(`refused${legal ? '' : ' (claw)'} ${pk}`, `${where}: ${r.E.filter((e) => e.t >= at && e.k === 'N').map((e) => e.t + ' ' + e.what).join(', ')}`);
        continue;
      }
      if (st.t < want) { breaches++; T.add(`EARLY ${pos} ${fam} ${gk} ${pk}`, `${where}: starts ${st.t}, the law's ${want} | stick ${commit(r)}`); }
      else if (st.t > want && legal) { breaches++; T.add(`LATE ${pos} ${fam} ${gk} ${pk}`, `${where}: starts ${st.t}, the law's ${want} | stick ${commit(r)} | ${H.showE(r.E, at)}`); }
      else if (st.t > want) T.add(`slow claw ${pk}`, `${where}: starts ${st.t}, the law's ${want}`);
    }
  }
  T.print(4);
  console.log(`stick-press: ${n} cases, ${breaches} breaches`);
  return { breaches };
}
if (require.main === module) { H.below(); process.exitCode = main(process.argv.includes('--quick')).breaches ? 1 : 0; }
module.exports = { main };
