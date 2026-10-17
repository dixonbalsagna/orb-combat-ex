// PROVISIONAL (Combat's roster pieces, a9e8f9cd, docs/combat/pending/roster/moveset.guard.json; docs/design/empress-guards.md section 4: "lights and mediums from the common pool, one heavy, a bolt"): the Empress's
// guards' two pieces and the mannequin's. Parked (--waves): nothing plays them until the roster does. Prefix gd.. The guards and the training dummy play the COMMON pool (data/anim/fighters.json `common`).
//   su_sole_fall   A falling sole to the chest (heavy, a launcher that sends down; named only): a trooper's blow, plain and heavy. Legal L6 (charged with one leg raised), W1 (28 ticks), D5 (the rise is the body
//                  straightening, the standing foot keeps its place, no leap): the knee is lifted to the hip with the foot above it, then the leg drives down and the sole is set on the chest.
//   bolt_palm      The measured bolt from an open palm, planted (a sequence, the energy press `bolt` of the common role): the open palm drawn back at the shoulder, thrown flat to shoulder height, the feet
//                  where they were. One hand, open and flat, never cupped, never at the hip, nothing between the fingers (Legal e01, R1).
const OPEN = { hands: { r: 'open', l: 'open' } };
const NEW = {
  su_sole_fall: { like: 'axe_kick', limb: 'foot', target: 'chest', weight: 'heavy', look: 'PROVISIONAL. The knee lifted to the hip with the foot above it, then the leg drives down and the sole is set on the chest; the standing foot keeps its place.' },
};
export function rows(wave1) {
  const by = Object.fromEntries(wave1.map(r => [r.id.replace('strike.', ''), r]));
  return Object.entries(NEW).map(([n, o]) => {
    const b = by[o.like];
    return { ...b, id: 'strike.' + n, limb: o.limb, limb2: null, uses: { legs: 1 }, target: o.target, weight: o.weight, look: o.look,
      range: { ...b.range, lunge: Math.round(b.range.lunge * 1.25), reach: Math.round(b.range.reach * 1.1) }, ticks: { load: 28, follow: 8, recover: 14 },
      _estimate: 'PROVISIONAL: range and ticks borrowed from strike.' + o.like + ' (lunge 1.25 times, reach 1.1 times); the load is the 28-tick wind-up of B' };
  });
}

export const strikes = {
  su_sole_fall: { named: true, tell_at: 0.5, squash_w: 0.0, drive: 'fall', kind: 'foot', target: 'chest', step_max: 12, legal: ['no_leap'],
    chamber: { family: 'upright', lean: -14, hips: [-4, 0, 0], spine: { lean: -12, twist: -6 }, head: { pitch: 4, yaw: 6 }, hand_r: [-8, 62, 20], hand_l: [8, 66, -18], foot_r: [6, 76, 8], pole_foot_r: [18, 44, 0], foot_l: [0, 2.5, -7], ...OPEN },
    contact: { family: 'upright_lunge', lean: -10, hips: [8, -2, 0], spine: { lean: -10 }, head: { pitch: 6 }, hand_r: [-6, 60, 20], hand_l: [6, 64, -18], foot_r: [34, 46, 6], pole_foot_r: [16, 30, 0], foot_l: [10, 2.5, -7], ...OPEN },
    follow: { lean: 3.5, hips: [5.5, -2, 0], foot_r: [14, 33, 7], hand_r: [4, 56.5, 16], hand_l: [13, 58, -11] },
    orig: 'PROVISIONAL: the knee lifted to the hip with the foot above it, then the leg drives down and the sole is set on the chest; the standing foot keeps its place' },
};
