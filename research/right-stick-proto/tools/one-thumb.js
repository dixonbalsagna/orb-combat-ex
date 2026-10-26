// One-thumb play (from ot.js): random legal play for a standard grip. The right thumb is on the face buttons or the right
// stick and takes L = 6 ticks to move either way (from the press's last tick down, or from the tick the stick is back at
// rest); the left thumb taps or holds the D-pad at any time, inside a press's commitment too; LT and RT come in between.
// It looks for what one thumb loses under the law:
//   law checks   harness lawCheck (no press inside a stick commitment, no stick act inside a face commitment, nothing silent)
//   DEFERRED     a right-stick flick that waits: one thumb always arrives L after the press, so it never should
//   WAIT OVER    a D-pad tap that waited acts after the commitment's end (item 16: on the tick it ends, no extra tick)
//   LOST         a flick or D-pad tap that leaves nothing: no act, no refusal, no wait, no drop with an ack
// Counted, not breaches: FLICK DROPPED and FLICK REPLACED (newest wins), a queued press lapsing (W), refusals.
// node one-thumb.js [count] [seed]
'use strict';
const H = require('./harness.js'), { L, R: RL } = H.LAW;     // RL: the reverse commitment (main's R is the random source)
const POS = [[300, 60, 360, 60], [230, 60, 430, 80], [160, 60, 540, 80], [300, 60, 345, 60], [600, 30, 300, 130], [545, 0, 585, 0], [300, 4, 420, 60]];
const DIRS = [0, 45, 90, 180, 270, 200];
const FAMSH = { flight: {}, aim: { RB: 1 }, lay: { RB: 1, LB: 1 }, read: { LB: 1 }, rt: { RT: 1 } };
const PRESS = { X: ['X', {}], bolt: ['X', { RB: 1 }], lob: ['Y', { RB: 1 }], Btap: ['B', { RB: 1 }], Bheld: ['B', { RB: 1 }], mine: ['X', { RB: 1, LB: 1 }] };
function play(R) {
  const pick = (a) => a[Math.floor(R() * a.length)];
  const pos = pick(POS), spec = { st: [], btn: {}, V: {} }, plan = [], taps = [];
  let t = 20, thumb = 'btn', free = 20, lastPad = -99;
  for (let j = 0; j < 7; j++) {
    const u = R(), want = u < 0.42 ? 'btn' : u < 0.74 ? 'stick' : u < 0.92 ? 'pad' : u < 0.96 ? 'LT' : 'RT';
    if (want === 'btn' || want === 'stick') {
      if (thumb !== want) { t = Math.max(t, free + L); thumb = want; } else t = Math.max(t, free + 1) + pick([0, 1, 2, 4, 8]);
    } else t += pick([0, 1, 2, 4]);
    if (want === 'btn') {
      const k = pick(Object.keys(PRESS)), [b, sh] = PRESS[k], d = k === 'Bheld' ? pick([8, 31, 40]) : 1;
      for (const s in sh) H.hold(spec, s, t, t + d + 40);              // its shoulders stay down so it can still start from the queue
      H.hold(spec, b, t, t + d); plan.push(`${k}${d > 1 ? d : ''}@${t}`);
      free = t + d - 1; t += d;
    } else if (want === 'stick') {
      const fam = pick(['flight', 'flight', 'aim', 'lay', 'read', 'rt']), dir = pick(DIRS), g = pick(['flick1', 'flick2', 'flick3', 'hold', 'slow']);
      const d = g[0] === 'f' ? +g[5] : pick([12, 16, 24]), rise = g === 'slow' ? 3 : 0;
      for (const s in FAMSH[fam]) H.hold(spec, s, t, t + d + rise + 2);
      H.gesture(spec, t, g === 'slow' ? 'slow' : g === 'hold' ? 'hold' : 'flick', dir, d);
      plan.push(`${fam} ${g}${g[0] === 'f' ? '' : d} ${dir}@${t}`);
      if (g[0] === 'f') taps.push({ t, read: t + 2, pad: false, k: plan[plan.length - 1] });
      free = t + d + rise; t = free;
    } else if (want === 'pad') {
      const fam = pick(['flight', 'aim', 'lay', 'read']), dir = pick(DIRS), d = R() < 0.7 ? 1 : pick([12, 16]);
      t = Math.max(t, lastPad + 3);
      for (const s in FAMSH[fam]) H.hold(spec, s, t, t + Math.max(d, 3) + 1);
      H.gesture(spec, t, d > 1 ? 'hold' : 'flick', dir, d, true); plan.push(`${fam} pad${d} ${dir}@${t}`);
      if (d === 1) taps.push({ t, read: t + 2, pad: true, k: plan[plan.length - 1] });
      lastPad = t + d;
    } else if (want === 'LT') { const ld = pick([[0, 0], [1, 0], [-1, 0], [0, 1], [0, -1]]); H.hold(spec, 'LT', t, t + 2); H.hold(spec, 'lx', t, t + 2, ld[0]); H.hold(spec, 'ly', t, t + 2, ld[1]); plan.push(`LT ${ld}@${t}`); t += 2; }
    else { H.hold(spec, 'RT', t, t + 3); plan.push(`RT@${t}`); t += 3; }
  }
  const v = R(), vt = pick([25, 30, 35, 40, 60]);
  if (v < 0.4) spec.V.blow = [[vt, vt + 1, 'mid']]; else if (v < 0.6) spec.V.heavy = [[vt, vt + 1]]; else if (v < 0.72) spec.V.grab = [[vt, vt + 1]];
  return { pos, spec, plan, taps, len: t + 80 };
}
function main(count, seed) {
  const S = H.load(), R = H.rng(seed), T = H.tally(); let breaches = 0;
  const bad = (k, ex) => { breaches++; T.add(k, ex); };
  for (let i = 0; i < count; i++) {
    const p = play(R), P = p.pos;
    const r = H.run(S, p.len, (w) => { w.P.x = P[0]; w.P.y = P[1]; w.V.x = P[2]; w.V.y = P[3]; if (P[2] - P[0] === 45) w.brawl = { t: 0, idle: -400 }; }, H.inp(p.spec), { trace: true });
    const ex = () => `pos ${P} V ${JSON.stringify(p.spec.V)} | ${p.plan.join(', ')} | ${H.showE(r.E, 15)}`;
    for (const f of H.lawCheck(r, p.spec)) { if (f.info) T.add('info ' + f.k, f.why); else bad(f.k + ': ' + f.why.replace(/-?\d+/g, 'N'), `${f.why} | ${ex()}`); }
    const refs = H.faceRefs(r, p.spec);
    for (const tp of p.taps) {
      // what the flick left: the first stick event at or after its read (an act, a refusal, a wait, a drop)
      const e = r.E.find((x) => x.t >= tp.read && x.t <= tp.read + 1 && /^(S|S-|W|D|C)$/.test(x.k));
      if (!e) {
        if (r.trace.some((x) => x.t >= tp.t && x.t <= tp.read && (x.caught || x.dodge || x.rooted))) continue;    // caught, slipping, or rooted by his beam
        // why: the other device in use around it (the recognizer reads one at a time), the gesture before ending one tick
        // earlier (its family carries over), or the family's shoulder let go before the read
        const other = tp.pad ? p.spec.st.some((g) => g[0] <= tp.read && g[1] >= tp.t - 3) : ['du', 'dd', 'dl', 'dr'].some((k) => (p.spec.btn[k] || []).some((s) => s[0] <= tp.read && s[1] >= tp.t - 3));
        const close = !tp.pad && p.spec.st.some((g) => g[1] === tp.t - 1);
        const down = (k, t) => (p.spec.btn[k] || []).some((s) => t >= s[0] && t < s[1]);
        const gone = ['RB', 'LB'].some((k) => down(k, tp.t) && !down(k, tp.read));
        const why = other ? (tp.pad ? 'the stick' : 'the D-pad') + ' in use within 3 ticks' : close ? 'one tick of rest after the gesture before: its family carried over' : gone ? 'its shoulder let go between its onset and its read' : 'other';
        bad(`LOST ${tp.pad ? 'D-pad tap' : 'flick'} (${why})`, `${tp.k}: nothing at its read ${tp.read} | ${ex()}`);
        continue;
      }
      if (e.k !== 'W') continue;
      if (!tp.pad) {
        // one thumb's flick waits only behind a press that queued and counts from its start: info, unless it acts later than the law
        const f = refs.filter((x) => x.t <= tp.read && tp.read < x.until && x.ref + RL > tp.read).pop(), dn = r.E.find((x) => x.t > e.t && ((x.k === 'S' || x.k === 'S-') && x.waited === e.from || x.k === 'D' || x.k === 'C'));
        const lawT = Math.max(tp.read, ...refs.filter((g) => g.t <= tp.read && tp.read < g.until).map((g) => g.ref + RL));
        if (dn && (dn.k === 'S' || dn.k === 'S-') && dn.t > lawT) bad('WAIT OVER right-stick flick', `${tp.k}: acts ${dn.t}, the law's ${lawT} | ${ex()}`);
        else if (f && f.ref > f.t) T.add('info a right-stick flick waits behind a queued press (counted from its start, gate G)', `${tp.k}: waits from ${e.t} to ${dn ? dn.t : '?'}, the ${f.b} at ${f.t} counted from ${f.ref}`);
        else bad('DEFERRED right-stick flick', `${tp.k}: waits from ${e.t}${f ? `, behind the ${f.b} at ${f.t} counted from ${f.ref}` : ''} | ${ex()}`);
        continue;
      }
      const done = r.E.find((x) => x.t > e.t && ((x.k === 'S' || x.k === 'S-') && x.waited === e.from || x.k === 'D' || x.k === 'C'));
      const end = Math.max(tp.read, ...refs.filter((f) => f.t <= tp.read && tp.read < f.until).map((f) => f.ref + RL));
      const acted = done && (done.k === 'S' || done.k === 'S-'), newer = acted && refs.find((f) => f.t > tp.read && f.t < done.t);
      if (newer) bad('NOT DROPPED: a newer press queued while a D-pad tap waited, and the tap still acted', `${tp.k}: acts ${done.t}, after the ${newer.b} at ${newer.t} | ${ex()}`);
      else if (acted && done.t > end) bad('WAIT OVER D-pad tap', `${tp.k}: acts ${done.t}, the commitment ends ${end} | ${ex()}`);
      if (done && done.k === 'D') T.add('info ' + done.what, tp.k);
    }
    for (const e of r.E) if (e.k === 'N' && /LAPSES|QUEUED \w+ DROPPED/.test(e.what)) T.add('info ' + e.what.replace(/QUEUED \w+/, 'QUEUED *'), ex());
  }
  T.print(5);
  console.log(`one-thumb: ${count} runs (seed ${seed}), ${breaches} breaches`);
  return { breaches };
}
if (require.main === module) { H.below(); process.exitCode = main(+(process.argv[2] || 2000), +(process.argv[3] || 1)).breaches ? 1 : 0; }
module.exports = { main };
