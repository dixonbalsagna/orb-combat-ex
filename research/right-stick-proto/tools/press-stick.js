// Press, then stick (from sweep3b): a face press of every kind (taps, held buttons, B's charge and beam, the mine, a blow
// into a brawl), then a stick or D-pad command of every family, gesture and direction, its onset swept across the press's
// commitment. The law (items 13 and 16): the press commits the stick and the D-pad for L from `from` (the press, or a held
// B's last tick down, or the tick a charge fires with B still held); a flick read inside waits and acts at from + L, with no
// extra tick; a hold counts its 10 ticks from from + L (plus the 3-tick rise when a slow gesture left rest inside it).
//   EARLY  any grip: a stick result before that floor
//   LATE   one thumb (the stick 6 after the thumb leaves the button, or the D-pad at any onset): a result later than
//          max(the same gesture alone, the floor); LOST: nothing, where the gesture alone acted and he was free to
//   (counted, not breaches: SLOW, the claw's waiting flick acting after the floor; ROOTED, nothing while his beam roots him)
// node press-stick.js [--quick]
'use strict';
const H = require('./harness.js'), { L, hold: HOLDT, rise: RISE } = H.LAW;
const T0 = 20;
// btn: the press at T0; sh: shoulders held to `end`; from: where its commitment counts from; leave: the thumb's last tick on it
const PRESSES = {
  Xclose: { P: [300, 60, 360, 60], btn: { X: [[0, 1]] }, sh: {}, end: 1, from: 0, leave: 0 },
  Xrange: { P: [160, 60, 540, 80], btn: { X: [[0, 1]] }, sh: {}, end: 1, from: 0, leave: 0 },
  Xheld: { P: [300, 60, 360, 60], btn: { X: [[0, 20]] }, sh: {}, end: 20, from: 0, leave: 19 },
  XheldR: { P: [160, 60, 540, 80], btn: { X: [[0, 20]] }, sh: {}, end: 20, from: 0, leave: 19 },
  bolt: { P: [230, 60, 430, 80], btn: { X: [[0, 1]] }, sh: { RB: 1 }, end: 1, from: 0, leave: 0 },
  boltHeld: { P: [230, 60, 430, 80], btn: { X: [[0, 15]] }, sh: { RB: 1 }, end: 15, from: 0, leave: 14 },
  lob: { P: [230, 60, 430, 80], btn: { Y: [[0, 1]] }, sh: { RB: 1 }, end: 1, from: 0, leave: 0 },
  Yheld: { P: [230, 60, 430, 80], btn: { Y: [[0, 15]] }, sh: { RB: 1 }, end: 15, from: 0, leave: 14 },
  Btap: { P: [230, 60, 430, 80], btn: { B: [[0, 1]] }, sh: { RB: 1 }, end: 1, from: 0, leave: 0 },
  Bheld: { P: [230, 60, 430, 80], btn: { B: [[0, 20]] }, sh: { RB: 1 }, end: 20, from: 19, leave: 19 },
  Bbeam: { P: [230, 60, 600, 80], btn: { B: [[0, 32]] }, sh: { RB: 1 }, end: 32, from: 31, leave: 31 },
  BheldRB: { P: [230, 60, 430, 80], btn: { B: [[0, 26]] }, sh: { RB: 1 }, end: 20, from: 20, fromRB: 25, leave: 25 },   // RB let go at 20 fires it
  // (fromRB: a family that keeps RB held keeps the charge, so it fires when B is let go)
  mine: { P: [230, 60, 430, 80], btn: { X: [[0, 1]] }, sh: { RB: 1, LB: 1 }, end: 1, from: 0, leave: 0 },
  brawl: { P: [300, 60, 345, 60], btn: { X: [[0, 1]] }, sh: {}, end: 1, from: 0, leave: 0 },
};
const FAMS = { flight: {}, aim: { RB: 1 }, lay: { RB: 1, LB: 1 }, read: { LB: 1 }, rt: { RT: 1 }, lt: { LT: 1 } };
const GEST = [['flick', 1], ['flick', 3], ['hold', 30], ['slow', 30]];
let DIRS = [0, 90, 180, 270, 200, 45];
const isAct = (e) => e && (e.k === 'S' || e.k === 'H');
let S;
const cache = new Map();
function one(pk, fam, g, dir, on, pad, noPress) {
  const key = [noPress ? '-' : pk, noPress ? JSON.stringify([PRESSES[pk].P, PRESSES[pk].sh, PRESSES[pk].end, pk === 'brawl']) : '', fam, g, dir, on, pad].join('|');
  if (cache.has(key)) return cache.get(key);
  const p = PRESSES[pk], spec = { st: [], btn: {}, V: {} }, end = T0 + p.end;
  if (!noPress) for (const k in p.btn) for (const [a, b] of p.btn[k]) H.hold(spec, k, T0 + a, T0 + b);
  for (const k of ['RB', 'LB', 'RT', 'LT']) { if (p.sh[k]) H.hold(spec, k, 0, end); if (FAMS[fam][k]) H.hold(spec, k, end, 130); }
  H.gesture(spec, on, g[0], dir, g[1], pad);
  const r = H.run(S, 130, (w) => { w.P.x = p.P[0]; w.P.y = p.P[1]; w.V.x = p.P[2]; w.V.y = p.P[3]; if (noPress && pk === 'brawl') w.brawl = { t: 0, idle: 0 }; }, H.inp(spec), { trace: true });
  const first = r.E.find((e) => e.t >= Math.min(on, T0) && (e.k === 'S' || e.k === 'S-' || e.k === 'H'));
  const firstH = r.E.find((e) => e.t >= Math.min(on, T0) && e.k === 'H');
  const res = { first, firstH, trace: r.trace, E: r.E };
  if (cache.size > 4000) cache.clear();
  cache.set(key, res); return res;
}
function main(quick) {
  DIRS = quick ? [0, 90, 180, 270] : [0, 90, 180, 270, 200, 45];
  S = H.load(); cache.clear();
  const T = H.tally(); let n = 0, breaches = 0;
  const say = (k, breach, ex) => { T.add(k, ex); if (breach) breaches++; };
  for (const pk in PRESSES) for (const fam in FAMS) for (const g of GEST) for (const dir of DIRS) for (const pad of [false, true]) {
    if (pad && (g[1] === 3 || g[0] === 'slow')) continue;          // the D-pad has one tap and one hold
    const p = PRESSES[pk], from = T0 + (FAMS[fam].RB && p.fromRB != null ? p.fromRB : p.from), lock = from + L, oneThumb = T0 + p.leave + L;
    const onsets = []; for (let d = -3; d <= 8; d++) onsets.push(from + d); for (let d = 0; d <= 2; d++) if (onsets.indexOf(oneThumb + d) < 0) onsets.push(oneThumb + d);
    for (const on of onsets) {
      n++;
      const c = one(pk, fam, g, dir, on, pad), ctl = one(pk, fam, g, dir, on, pad, true), legal = pad || on >= oneThumb;
      const cf = c.first, bf = ctl.first, where = `${pk} ${fam} ${g[0]}${g[1]} ${dir}${pad ? ' D-pad' : ''} onset ${on} (press ${T0}, commitment from ${from})`;
      if (!bf || bf.t <= T0) continue;                            // alone it does nothing, or it acts before the press: gate A's case
      const holdFirst = bf.k === 'H', slowIn = g[0] === 'slow' && on < lock;
      const floor = holdFirst ? lock + HOLDT + (slowIn ? RISE : 0) : lock, want = Math.max(bf.t, floor);
      if (isAct(cf) && cf.t < (holdFirst ? lock + HOLDT : lock)) { say(`EARLY ${pk} ${fam} ${g[0]}${pad ? ' D-pad' : ''}`, true, `${where}: ${cf.t} ${cf.what || cf.cmd} before the law's ${floor} | alone ${bf.t} ${bf.what || bf.cmd}`); continue; }
      // a hold after its flick (the sharp hold): its own start against the floor
      const ch = c.firstH, bh = ctl.firstH;
      if (!holdFirst && ch && bh && ch.t < lock + HOLDT) say(`EARLY hold ${pk} ${fam} ${g[0]}${pad ? ' D-pad' : ''}`, true, `${where}: hold ${ch.t} ${ch.cmd} before the law's ${lock + HOLDT}`);
      if (!cf) {
        const tr = c.trace.find((x) => x.t === want) || {};
        if (tr.beam || tr.caught) { T.add(`ROOTED ${pk} ${fam}`, where); continue; }
        if (legal && isAct(bf)) say(`LOST ${pk} ${fam} ${g[0]}${pad ? ' D-pad' : ''}`, true, `${where}: nothing, alone ${bf.t} ${bf.what || bf.cmd}`);
        continue;
      }
      if (cf.t > want && c.trace.some((x) => x.t >= want && x.t < cf.t && x.rooted)) { T.add(`ROOTED ${pk} ${fam}`, where); continue; }
      if (cf.t > want) {
        if (legal && cf.k === bf.k && (cf.what || cf.cmd) === (bf.what || bf.cmd)) say(`LATE ${pk} ${fam} ${g[0]}${pad ? ' D-pad' : ''}`, true, `${where}: ${cf.t} ${cf.what || cf.cmd}, law ${want}, alone ${bf.t}`);
        else if (!legal && !holdFirst && cf.k !== 'S-') T.add(`SLOW claw ${pk} ${fam} ${g[0]}`, `${where}: ${cf.t} ${cf.what || cf.cmd}, the law's ${want}`);
      }
      if (legal && bh && ch && ch.cmd === bh.cmd && ch.t > Math.max(bh.t, lock + HOLDT) && !c.trace.some((x) => x.t >= Math.max(bh.t, lock + HOLDT) && x.t < ch.t && x.rooted)) say(`LATE hold ${pk} ${fam} ${g[0]}${pad ? ' D-pad' : ''}`, true, `${where}: hold ${ch.t} ${ch.cmd}, law ${Math.max(bh.t, lock + HOLDT)}`);
    }
  }
  T.print(4);
  console.log(`press-stick: ${n} cases, ${breaches} breaches`);
  return { breaches };
}
if (require.main === module) { H.below(); process.exitCode = main(process.argv.includes('--quick')).breaches ? 1 : 0; }
module.exports = { main };
