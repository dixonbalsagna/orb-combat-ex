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
  su_knee: { like: 'driving_knee', limb: 'knee', target: 'gut', weight: 'heavy', look: 'PROVISIONAL. A stepping knee: the striking side drawn back, the whole body travels a pace and the knee arrives in the gut as the foot lands.' },
  su_plate: { like: 'hook', limb: 'hand', target: 'head', weight: 'heavy', look: 'PROVISIONAL. A turning forearm: his back half turned with the forearm carried behind, then the hips and shoulders unwind through the head.' },
  su_hook: { like: 'overhand', limb: 'hand', target: 'jaw', weight: 'heavy', look: 'PROVISIONAL. A turning fist: the shoulders wound away in a low stance, then unwound through the jaw.' },
  su_elbow_heave: { like: 'rising_elbow', limb: 'elbow', target: 'jaw', weight: 'heavy', look: 'PROVISIONAL. A heaving elbow: sunk deep with the elbow loaded low, the other hand up; the legs drive him tall and the elbow up the centre line; his feet keep their place.' },
  su_fist_heave: { like: 'uppercut', limb: 'hand', target: 'gut', weight: 'heavy', look: 'PROVISIONAL. A heaving fist: sunk deep with the fist low in front, the legs drive it up into the gut; his feet keep their place.' },
  su_hammer: { like: 'hammer', limb: 'hand', target: 'head', weight: 'heavy', look: 'PROVISIONAL. A falling hammer fist: risen tall with the fist at his shoulder, then the whole body comes down and the fist falls on the head.' },
};
export function rows(wave1) {
  const by = Object.fromEntries(wave1.map(r => [r.id.replace('strike.', ''), r]));
  return Object.entries(NEW).map(([n, o]) => {
    const b = by[o.like];
    return { ...b, id: 'strike.' + n, limb: o.limb, target: o.target, weight: o.weight, look: o.look,
      range: { ...b.range, lunge: Math.round(b.range.lunge * 1.25), reach: Math.round(b.range.reach * 1.1) }, ticks: { load: 28, follow: 8, recover: 14 },
      _estimate: 'PROVISIONAL: range and ticks borrowed from strike.' + o.like + ' (lunge 1.25 times, reach 1.1 times); the load is the 28-tick wind-up of B (docs/design/brawl-second-pass.md) for the look study' };
  });
}

export const strikes = {
  su_ram: { tell_at: 0.5, squash_w: 0.4, drive: 'step_through', kind: 'hand', target: 'chest', step_max: 22,
    chamber: { family: 'crouched', lean: 12, hips: [-8, -14, 0], spine: { lean: 10, twist: -18 }, head: { pitch: 2 }, hand_r: [-8, 58, 16], pole_hand_r: [-12, 8, 12], hand_l: [16, 48, -8],
      foot_r: [-16, 2.5, 10], foot_l: [10, 2.5, -8], ...FIST },
    contact: { family: 'upright_lunge', lean: 44, hips: [34, -14, 0], spine: { lean: 24, twist: 20 }, head: { pitch: 12 }, hand_r: [66, 50, 6], pole_hand_r: [4, 4, 8], hand_l: [26, 50, -9],
      foot_r: [0, 11, 8], foot_l: [40, 2.5, -8], ...FIST },
    follow: { lean: 36, hips: [26, -12, 0], spine: { lean: 20, twist: 12 }, hand_r: [48, 50, 7], hand_l: [14.5, 48.5, -11], foot_r: [-5, 7, 8], foot_l: [32, 2.5, -8] },
    orig: 'PROVISIONAL: a long low lunge, the whole body behind one straight fist' },
  su_heel: { tell_at: 0.5, squash_w: 0.0, drive: 'fall', kind: 'foot', target: 'chest', step_max: 22,
    chamber: { family: 'upright', lean: -14, hips: [-4, 3, 0], spine: { lean: -12, twist: -6 }, head: { pitch: -6 }, hand_r: [6, 58, 14], hand_l: [12, 58, -12], foot_r: [2.5, 67, 7],
      foot_l: [6, 2.5, -8], ...OPEN },
    contact: { family: 'upright_lunge', lean: 30, hips: [16, -8, 0], spine: { lean: 22, twist: 4 }, head: { pitch: 20 }, hand_r: [18.5, 62, 18], hand_l: [22, 56, -10], foot_r: [46, 38, 8],
      foot_l: [10, 2.5, -8], ...OPEN },
    follow: { lean: 24, hips: [12, -6, 0], spine: { lean: 16, twist: 2 }, hand_l: [17, 52, -9], foot_r: [30, 22, 8], foot_l: [10, 2.5, -8] },
    orig: 'PROVISIONAL: the leg raised high, the heel dropped from above onto the chest, the body folding over it' },
  su_knee: { tell_at: 0.5, squash_w: 0.3, drive: 'step_through', kind: 'knee', target: 'gut', step_max: 22,
    chamber: { family: 'upright', lean: -6, hips: [-8, -2, 0], spine: { lean: -6, twist: -14 }, head: { pitch: -8 }, hand_r: [0, 58, 14], pole_hand_r: [-10, 6, 10], hand_l: [16, 60, -8],
      foot_r: [-16, 2.5, 10], foot_l: [14, 2.5, -8], ...OPEN },
    contact: { family: 'upright_lunge', lean: 10, hips: [34, -2, 0], spine: { lean: 8, twist: 10 }, head: { pitch: 6 }, hand_r: [16, 56, 12], hand_l: [24, 62, -8],
      foot_r: [32, 32, 8], pole_foot_r: [12, 1, 0], foot_l: [34, 2.5, -8], ...OPEN },
    follow: { hips: [28, -6, 0], hand_r: [14, 54, 12], foot_r: [24, 12, 8], foot_l: [30, 2.5, -8] },
    orig: 'PROVISIONAL: a stepping knee, the striking side drawn back at shoulder height and the other hand open toward the rival, the body carried a full pace behind the knee' },
  su_plate: { tell_at: 0.5, squash_w: 0.0, drive: 'turn', kind: 'hand', target: 'head', step_max: 22, legal: ['hands_open_or_claw'],
    chamber: { family: 'upright', lean: -2, hips: [-4, -2, 0], hip_twist: -30, spine: { lean: 0, twist: -64, bend: 6 }, head: { pitch: -6, yaw: 34 }, hand_r: [-12, 60, 28], pole_hand_r: [-10, 0, 14], hand_l: [16, 58, -8],
      foot_r: [-12, 2.5, 10], foot_l: [10, 2.5, -8], ...OPEN },
    contact: { family: 'upright_lunge', lean: 14, hip_twist: 30, hips: [26, -6, 0], spine: { lean: 8, twist: 58 }, head: { pitch: 4, yaw: -14 }, hand_r: [52, 82, 10], pole_hand_r: [-2, 10, 10], hand_l: [20, 58, -8],
      foot_r: [-6, 6, 9], foot_l: [28, 2.5, -8], ...OPEN },
    follow: { spine: { twist: 34 }, hand_r: [30, 66, -4], hand_l: [20, 58, -8], foot_r: [-4, 4, 9] },
    orig: 'PROVISIONAL: a turning forearm: his back half turned with the plated forearm carried behind at shoulder height, the hips and shoulders unwinding through the head, the forearm ending across his own centre' },
  su_hook: { tell_at: 0.5, squash_w: 0.0, drive: 'turn', kind: 'hand', target: 'jaw', step_max: 22,
    chamber: { family: 'crouched', lean: 22, hips: [-4, -12, 0], hip_twist: -26, spine: { lean: 18, twist: -56, bend: 10 }, head: { pitch: 6, yaw: 20 }, hand_r: [-6, 50, 28], pole_hand_r: [-10, 0, 14], hand_l: [16, 56, -8],
      foot_r: [-12, 2.5, 10], foot_l: [12, 2.5, -8], hands: { r: 'fist', l: 'open' } },
    contact: { family: 'upright_lunge', lean: 20, hip_twist: 26, hips: [24, -8, 0], spine: { lean: 12, twist: 56, bend: -8 }, head: { pitch: 6, yaw: -10 }, hand_r: [56, 76, 10], pole_hand_r: [0, 10, 10], hand_l: [18, 56, -8],
      foot_r: [-4, 10, 9], foot_l: [28, 2.5, -8], hands: { r: 'fist', l: 'open' } },
    follow: { spine: { twist: 30 }, hand_r: [30, 62, -4], hand_l: [18, 56, -8], foot_r: [-4, 4, 9] },
    orig: 'PROVISIONAL: a turning fist from a low stance, the shoulders wound away with the fist behind him, unwound through the jaw and ending across his own centre' },
  su_elbow_heave: { tell_at: 0.5, squash_w: 0.0, drive: 'heave', kind: 'elbow', target: 'jaw', step_max: 6,
    chamber: { family: 'crouched', lean: 6, hips: [-2, -16, 0], spine: { lean: 4, twist: -8 }, head: { pitch: -6 }, hand_r: [20, 40, 12], pole_hand_r: [-6, -6, 10], hand_l: [16, 64, -8],
      foot_r: [-14, 2.5, 10], foot_l: [14, 2.5, -8], hands: { r: 'fist', l: 'open' } },
    contact: { family: 'upright', lean: 4, hips: [8, 2, 0], spine: { lean: -6, twist: 14 }, head: { pitch: -8 }, hand_r: [4, 84, 6], pole_hand_r: [14, 4, 2], hand_l: [22, 62, -8],
      foot_r: [-14, 2.5, 10], foot_l: [14, 2.5, -8], hands: { r: 'fist', l: 'open' } },
    follow: { hips: [6, 0, 0], hand_r: [10, 70, 6], hand_l: [22, 62, -8] },
    orig: 'PROVISIONAL: a heaving elbow: sunk deep with the elbow loaded low and the other hand up in guard, both legs drive him tall with the elbow up the centre line; his feet keep their place' },
  su_fist_heave: { tell_at: 0.5, squash_w: 0.0, drive: 'heave', kind: 'hand', target: 'gut', step_max: 10, legal: ['no_leap'],
    chamber: { family: 'crouched', lean: 14, hips: [-2, -18, 0], spine: { lean: 12, twist: -8 }, head: { pitch: -2 }, hand_r: [24, 30, 10], pole_hand_r: [-6, -6, 10], hand_l: [16, 62, -8],
      foot_r: [-14, 2.5, 10], foot_l: [16, 2.5, -8], hands: { r: 'fist', l: 'open' } },
    contact: { family: 'upright_lunge', lean: 16, hips: [16, -12, 0], spine: { lean: 12, twist: 12 }, head: { pitch: 4 }, hand_r: [54, 46, 8], pole_hand_r: [6, -4, 8], hand_l: [24, 60, -8],
      foot_r: [-14, 2.5, 10], foot_l: [16, 2.5, -8], hands: { r: 'fist', l: 'open' } },
    follow: { hips: [10, -2, 0], hand_r: [34, 64, 8], hand_l: [24, 60, -8] },
    orig: 'PROVISIONAL: a heaving fist: sunk deep with the fist low in front of him, both legs drive the fist up into the gut; his feet keep their place' },
  su_hammer: { tell_at: 0.5, squash_w: 0.0, drive: 'fall', kind: 'hand', target: 'head', step_max: 16, legal: ['no_clasp', 'no_held_raise'],
    chamber: { family: 'upright', lean: -4, hips: [-2, 3, 0], spine: { lean: -4, twist: -8 }, head: { pitch: -6 }, hand_r: [4, 66, 10], pole_hand_r: [-8, 6, 8], hand_l: [16, 62, -8],
      foot_r: [-6, 2.5, 9], foot_l: [10, 2.5, -8], hands: { r: 'fist', l: 'open' } },
    contact: { family: 'upright_lunge', lean: 28, hips: [22, -14, 0], spine: { lean: 22, twist: 12 }, head: { pitch: 22 }, hand_r: [50, 78, 8], pole_hand_r: [-4, 14, 8], hand_l: [22, 58, -8],
      foot_r: [-4, 2.5, 9], foot_l: [28, 2.5, -8], hands: { r: 'fist', l: 'open' } },
    follow: { hips: [18, -14, 0], hand_r: [40, 52, 10], hand_l: [22, 58, -8] },
    orig: 'PROVISIONAL: a falling hammer fist: risen tall with the fist at his shoulder and the other hand up, then the whole body comes down and the fist falls on the head' },
};
