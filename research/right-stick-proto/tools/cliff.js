// The cliff sweep (from csweep): P on the cliff's top or by its face, V anywhere around it (still, or flying across), and
// every command family near the cliff: holds (orbit, dash, skim, climb, wall run, the brawl's give and take back, the
// cross-up), flicks (lunge, step, hop, drop), X (the close, the press lunge), LT slips, D-pad taps, free flight eight ways.
// Each step is measured against its own move's free step (harness cliff hooks). Reported: a snap (a step 15 px or more past
// its own step), a step of more than 12 px with no rock() call, a tween ending more than 20 px short of an end he could
// reach and a close that ends inside 0.4 bh of him (both noted, not breaches), a body inside the rock, an arc that ends on
// the side it began.
// Not the law: it is the cliff's geometry, kept here for the port. node cliff.js [stride]   (stride 1 is the full set)
'use strict';
const H = require('./harness.js');
const STRIDE = +(process.argv[2] || 1);
const PP = [], VP = [];
for (const x of [650, 664, 680, 692, 702]) for (const y of [200, 206, 225, 260]) PP.push([x, y]);
for (const x of [600, 620, 636, 646]) for (const y of [10, 100, 180, 199]) PP.push([x, y]);
for (const x of [420, 520, 580, 610, 630, 640, 646]) for (const y of [0, 60, 120, 170, 199, 240]) VP.push([x, y]);
for (const x of [660, 680, 702]) for (const y of [200, 230, 265]) VP.push([x, y]);
const slow = (dx, dy, a, b) => (t) => (t >= a && t < b ? { rx: dx * Math.min(1, (t - a + 1) / 20), ry: dy * Math.min(1, (t - a + 1) / 20) } : {});
const flick = (dx, dy, at) => (t) => (t >= at && t < at + 3 ? { rx: dx, ry: dy } : {});
const span = (a, b, o) => (t) => (t >= a && t < b ? o : {});
const G = {
  holdU: slow(0, -1, 5, 80), holdD: slow(0, 1, 5, 80), holdL: slow(-1, 0, 5, 80), holdR: slow(1, 0, 5, 80),
  flU: flick(0, -1, 5), flD: flick(0, 1, 5), flL: flick(-1, 0, 5), flR: flick(1, 0, 5),
  X: (t) => (t === 5 ? { X: true } : {}), X2: (t) => (t === 5 || t === 30 ? { X: true } : {}),
  ltN: span(5, 7, { LT: true }), ltL: span(5, 7, { LT: true, lx: -1 }), ltR: span(5, 7, { LT: true, lx: 1 }), ltU: span(5, 7, { LT: true, ly: -1 }),
  dL: span(5, 8, { dl: true }), dR: span(5, 8, { dr: true }), dD: span(5, 8, { dd: true }), dHoldL: span(5, 60, { dl: true }),
  fDL: span(3, 60, { lx: -1, ly: 1 }), fD: span(3, 60, { ly: 1 }), fL: span(3, 60, { lx: -1 }), fUL: span(3, 60, { lx: -1, ly: -1 }), fR: span(3, 60, { lx: 1 }),
  flLthenX: (t) => Object.assign(t >= 5 && t < 8 ? { rx: -1, ry: 0 } : {}, t === 14 ? { X: true } : {}),
};
const VM = { still: null, across: (t, v0) => ({ gx: v0[0] < 646 ? 702 - (v0[0] - 420) * 0.1 : 500, gy: v0[1] < 200 ? 250 : 60, gs: 3 }) };
function main(stride) {
  const S = H.load({ cliff: true }), res = {}; let runs = 0, ticks = 0, idx = 0, breaches = 0;
  // a tween ending short and a close ending near him are the cliff's geometry (noted); the rest are breaches
  const hit = (k, v, where) => { const r = res[k] || (res[k] = { n: 0, max: -1e9, where: '' }); r.n++; if (!/^a tween ends|^a close ends/.test(k)) breaches++; if (v > r.max) { r.max = v; r.where = where; } };
  for (const brawl of [false, true]) for (const pp of PP) for (const vp of VP) for (const gk in G) for (const vk in VM) {
    if (idx++ % stride) continue;
    const d0 = Math.hypot(pp[0] - vp[0], pp[1] - vp[1]); if (d0 < 20 || (brawl && d0 > 4.4 * 56)) continue;
    const w = S.newWorld(null, 0, 'demo'); w.P.x = pp[0]; w.P.y = pp[1]; w.V.x = vp[0]; w.V.y = vp[1]; w.V.home = vp.slice(); if (brawl) w.brawl = { t: 0, idle: 0 };
    let lastId = null, lastFree = null, prevCross = null, side = 0; runs++;
    const tag = (t) => `${brawl ? 'brawl ' : ''}${gk} ${vk} P ${pp} V ${vp} t${t}`;
    for (let t = 0; t < 90; t++) {
      const P = w.P, p0 = [P.x, P.y], v0 = [w.V.x, w.V.y], mv0 = P.mv; P._log = [];
      S.stepWorld(w, { P: G[gk](t) || {}, V: VM[vk] ? VM[vk](t, vp) : { gx: vp[0], gy: vp[1] } }); ticks++;
      const act = Math.hypot(P.x - p0[0], P.y - p0[1]); let free = null; const srcs = [];
      for (const e of P._log) if (e.k === 'rock') { const ref = e.id && e.id === lastId && lastFree ? lastFree : e.o; free = (free || 0) + Math.hypot(e.free[0] - ref[0], e.free[1] - ref[1]); srcs.push(e.src); if (e.id) { lastId = e.id; lastFree = e.free; } }
      if (!P._log.some((e) => e.k === 'rock' && e.id)) { lastId = null; lastFree = null; }
      const what = srcs.join('+') || (P.cmd || 'none').replace(/(up|down|toward|away)$/, '');
      if (!Number.isFinite(P.x + P.y)) hit('NaN', 1, tag(t));
      if (P.y < 200 - 1e-6 && P.x > 646 + 1e-6) hit('inside the rock', P.x - 646, `${tag(t)} ${P.x.toFixed(2)},${P.y.toFixed(2)}`);
      if (free != null) { if (act - free > 15 && act > 0.6 * 56) hit(`a snap, 15 px past its own step (${what})`, act - free, `${tag(t)} ${act.toFixed(1)} vs ${free.toFixed(1)}`); }
      else if (act > 12) hit(`a step of more than 12 px with no rock() call (${what})`, act, tag(t));
      if (mv0 && P.mv !== mv0 && mv0.t >= mv0.dur) {
        const ex = mv0.x1, ey = mv0.y1, reach = !(ey < 200 && ex > 646) && !(mv0.y0 < 200 && ex > 646) && ex >= 18 && ex <= 702 && ey >= 0 && ey <= 270, sh = Math.hypot(P.x - ex, P.y - ey);
        if (reach && sh > 20) hit(`a tween ends 20 px short (${mv0.k})`, sh, `${tag(t)} at ${P.x.toFixed(1)},${P.y.toFixed(1)} end ${ex.toFixed(1)},${ey.toFixed(1)}`);
        if (mv0.k === 'close' && Math.hypot(P.x - w.V.x, P.y - w.V.y) < 0.4 * 56) hit('a close ends inside 0.4 bh of him', -Math.hypot(P.x - w.V.x, P.y - w.V.y), tag(t));
      }
      if (P.cross && P.cross !== prevCross) side = Math.sign(p0[0] - v0[0]);
      if (prevCross && !P.cross && (w.rd.log[0] || {}).text === 'SIDES SWAPPED' && Math.sign(P.x - w.V.x) === side && Math.abs(P.x - w.V.x) > 10) hit('an arc ends on the side it began', 1, tag(t));
      prevCross = P.cross;
    }
  }
  for (const k of Object.keys(res).sort()) console.log(`${String(res[k].n).padStart(5)} ${k}: max ${res[k].max.toFixed(2)}, e.g. ${res[k].where}`);
  console.log(`cliff: ${runs} runs, ${ticks} ticks (stride ${stride}), ${breaches} breaches (the tween and close lines are notes)`);
  return { breaches };
}
if (require.main === module) { H.below(); process.exitCode = main(STRIDE).breaches ? 1 : 0; }
module.exports = { main };
