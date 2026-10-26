// The settle after an orbit by the cliff (from settle.js): the orbit sets his speed from its own path before rock(), so a
// release while he lags that path (held at the face, on the top or at the arena's edge) could settle him with the gap as
// his speed. Orbit holds by the cliff, let go at every other tick; each settle step against the orbit's own step.
// Reported: a settle step over 15 px (a fling). Not the law: the cliff's motion, kept for the port. node settle.js
'use strict';
const H = require('./harness.js');
function main() {
  const S = H.load({ cliff: true }), PP = [], VP = [], best = []; let runs = 0;
  for (const x of [650, 670, 690, 702]) for (const y of [200, 215, 240, 265]) PP.push([x, y]);
  for (const x of [600, 630, 646]) for (const y of [20, 100, 170, 199]) PP.push([x, y]);
  for (const x of [480, 560, 600, 630, 646]) for (const y of [20, 80, 140, 190]) VP.push([x, y]);
  for (const x of [670, 700]) for (const y of [210, 250]) VP.push([x, y]);
  for (const pp of PP) for (const vp of VP) for (const dy of [-1, 1]) for (let rel = 8; rel <= 70; rel += 2) {
    if (Math.hypot(pp[0] - vp[0], pp[1] - vp[1]) < 30) continue;
    const w = S.newWorld(null, 0, 'demo'); w.P.x = pp[0]; w.P.y = pp[1]; w.V.x = vp[0]; w.V.y = vp[1]; w.V.home = vp.slice(); runs++;
    let orbitStep = 0, lastFree = null, lastId = null, maxSettle = 0, at = -1;
    for (let t = 0; t < 28 + rel + 12; t++) {
      const P = w.P, p0 = [P.x, P.y]; P._log = [];
      S.stepWorld(w, { P: t >= 5 && t < 28 + rel ? { rx: 0, ry: dy * Math.min(1, (t - 4) / 20) } : {}, V: { gx: vp[0], gy: vp[1] } });
      const rk = P._log.find((e) => e.k === 'rock');
      if (rk && rk.src === 'orbit') { orbitStep = rk.id === lastId && lastFree ? Math.hypot(rk.free[0] - lastFree[0], rk.free[1] - lastFree[1]) : orbitStep; lastId = rk.id; lastFree = rk.free; }
      if (t > 28 + rel && rk && rk.src === 'settle') { const st = Math.hypot(P.x - p0[0], P.y - p0[1]); if (st > maxSettle) { maxSettle = st; at = t; } }
    }
    if (maxSettle > 0) best.push({ maxSettle, orbitStep, tag: `P ${pp} V ${vp} hold ${dy < 0 ? 'up' : 'down'}, let go at ${28 + rel}, the settle step at t${at}` });
  }
  best.sort((a, b) => b.maxSettle - a.maxSettle);
  const fling = best.filter((b) => b.maxSettle > 15).length;
  for (const b of best.slice(0, 5)) console.log(`  settle step ${b.maxSettle.toFixed(1)} px, the orbit's step ${b.orbitStep.toFixed(1)} | ${b.tag}`);
  console.log(`settle: ${runs} runs, ${best.length} with a settle, ${fling} settle steps over 15 px`);
  return { breaches: fling };
}
if (require.main === module) { H.below(); process.exitCode = main().breaches ? 1 : 0; }
module.exports = { main };
