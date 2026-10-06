// PROVISIONAL (the brawl look study, 2026-10-06; Legal has not screened these): the rival's super-heavy tier, B's blows, "a whole-body blow that reads as far bigger than a medium at a glance"
// (docs/animation/flurry-study.md). Two pieces for the study; a full set is listed there. Parked (--waves): nothing plays them in a live match, and the fighter's `more` list does not name this wave. Prefix ru.
// His own shape: fists and plates, straight lines, drops and rises, a crouched wedge. A ram is one fist on a long low line; a heel drop is one leg and never a leap.
//   su_ram    (a long low lunge, the whole body behind one straight fist)
//   su_heel   (the leg raised high, the heel dropped from above onto the chest, the body folding over it)
const OPEN = { hands: { r: 'open', l: 'open' } };
const FIST = { hands: { r: 'fist', l: 'open' } };
const NEW = {
  su_ram: { like: 'overhand', limb: 'hand', target: 'chest', weight: 'heavy', look: 'PROVISIONAL. A long low lunge, the whole body behind one straight fist.' },
  su_heel: { like: 'axe_kick', limb: 'foot', target: 'chest', weight: 'heavy', look: 'PROVISIONAL. The leg raised high, the heel dropped from above onto the chest, the body folding over it.' },
};
export function rows(wave1) {
  const by = Object.fromEntries(wave1.map(r => [r.id.replace('strike.', ''), r]));
  return Object.entries(NEW).map(([n, o]) => {
    const b = by[o.like];
    return { ...b, id: 'strike.' + n, limb: o.limb, target: o.target, weight: o.weight, look: o.look,
      range: { ...b.range, lunge: Math.round(b.range.lunge * 1.25), reach: Math.round(b.range.reach * 1.1) }, ticks: { load: 18, follow: 8, recover: 12 },
      _estimate: 'PROVISIONAL: range and ticks borrowed from strike.' + o.like + ' (lunge 1.25 times, reach 1.1 times, a load of 18) for the look study' };
  });
}

export const strikes = {
  su_ram: { kind: 'hand', target: 'chest', step_max: 22,
    chamber: { family: 'crouched', lean: 22, hips: [-8, -14, 0], spine: { lean: 20, twist: -18 }, head: { pitch: 10 }, hand_r: [-8, 58, 16], pole_hand_r: [-12, 8, 12], hand_l: [20, 50, -8],
      foot_r: [-16, 2.5, 10], foot_l: [10, 2.5, -8], ...FIST },
    contact: { family: 'upright_lunge', lean: 44, hips: [34, -14, 0], spine: { lean: 24, twist: 20 }, head: { pitch: 12 }, hand_r: [66, 50, 6], pole_hand_r: [4, 4, 8], hand_l: [26, 50, -9],
      foot_r: [0, 11, 8], foot_l: [40, 2.5, -8], ...FIST },
    follow: { lean: 36, hips: [26, -12, 0], spine: { lean: 20, twist: 12 }, hand_r: [48, 50, 7], hand_l: [14.5, 48.5, -11], foot_r: [-5, 7, 8], foot_l: [32, 2.5, -8] },
    orig: 'PROVISIONAL: a long low lunge, the whole body behind one straight fist' },
  su_heel: { kind: 'foot', target: 'chest', step_max: 22,
    chamber: { family: 'upright', lean: -14, hips: [-4, 0, 0], spine: { lean: -12, twist: -6 }, head: { pitch: -6 }, hand_r: [12, 62, 12], hand_l: [20, 64, -10], foot_r: [2.5, 67, 7],
      foot_l: [6, 2.5, -8], ...OPEN },
    contact: { family: 'upright_lunge', lean: 30, hips: [16, -8, 0], spine: { lean: 22, twist: 4 }, head: { pitch: 20 }, hand_r: [18.5, 62, 18], hand_l: [22, 56, -10], foot_r: [46, 38, 8],
      foot_l: [10, 2.5, -8], ...OPEN },
    follow: { lean: 24, hips: [12, -6, 0], spine: { lean: 16, twist: 2 }, hand_l: [17, 52, -9], foot_r: [30, 22, 8], foot_l: [10, 2.5, -8] },
    orig: 'PROVISIONAL: the leg raised high, the heel dropped from above onto the chest, the body folding over it' },
};
