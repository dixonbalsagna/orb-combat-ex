// PROVISIONAL (the brawl look study, 2026-10-06; Legal has not screened these): the Protagonist's super-heavy tier, B's blows, "a whole-body blow that reads as far bigger than a medium at a glance"
// (docs/animation/flurry-study.md). Two pieces for the study; a full set is listed there. Parked (--waves): nothing plays them in a live match, and the fighter's `more` list does not name this wave. Prefix pu.
// His own shape: open palms and blades, rounder arcs. A fall is ONE falling palm (Legal, three-strengths-screen.md: two palms overhead fails; the limb stays at shoulder height until he starts down); a turn is one blade hand.
//   su_drive   (the fall: he rises tall, one palm at shoulder height, the other hand up in guard; then the body comes down and the palm falls onto the chest)
//   su_turn    (a full turn of the body, one blade hand swung out at the end of it, the rear foot trailing off the ground)
const OPEN = { hands: { r: 'open', l: 'open' } };
const NEW = {
  su_drive: { like: 'double_hammer', limb: 'hand', target: 'chest', weight: 'heavy', look: 'PROVISIONAL. He rises tall with one palm at his shoulder, the other hand up in guard, then comes down with his whole weight and the palm falls onto the chest.' },
  su_turn: { like: 'haymaker', limb: 'hand', target: 'chest', weight: 'heavy', look: 'PROVISIONAL. A full turn of the body, one blade hand swung out at the end of it, the rear foot trailing.' },
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
  su_drive: { kind: 'hand', target: 'chest', step_max: 22, legal: ['hands_open_or_claw', 'no_held_raise', 'not_at_hip'],
    chamber: { family: 'upright', lean: -8, hips: [-2, 1, 0], spine: { lean: -8, twist: -4 }, head: { pitch: -4 }, hand_r: [8, 62, 12], pole_hand_r: [-8, 6, 10], hand_l: [24, 58, -8],
      foot_r: [-6, 2.5, 9], foot_l: [8, 2.5, -8], ...OPEN },
    contact: { family: 'upright_lunge', lean: 38, hips: [28, -12, 0], spine: { lean: 26, twist: 4 }, head: { pitch: 24 }, hand_r: [54, 50, 8], pole_hand_r: [-4, 14, 10], hand_l: [20, 48, -11],
      foot_r: [-2, 8, 9], foot_l: [34, 2.5, -8], ...OPEN },
    follow: { lean: 32, hips: [24, -13, 0], spine: { lean: 28, twist: 2 }, head: { pitch: 26 }, hand_r: [34, 42, 9], hand_l: [30, 61, -13], foot_r: [-5, 5, 8] },
    orig: 'PROVISIONAL: he rises tall with one palm at his shoulder and the other hand up in guard, then comes down with his whole weight and the palm falls onto the chest' },
  su_turn: { kind: 'hand', target: 'chest', step_max: 22, legal: ['hands_open_or_claw'],
    chamber: { family: 'upright', lean: 12, hips: [-6, -6, 0], spine: { lean: 10, twist: -70, bend: 8 }, head: { pitch: 6, yaw: 26 }, hand_r: [-14, 58, 26.5], hand_l: [31.5, 54, -6], pole_hand_r: [-10, -2, 14],
      foot_r: [-14, 2.5, 10], foot_l: [12, 2.5, -8], ...OPEN },
    contact: { family: 'upright_lunge', lean: 30, hips: [28, -6, 0], spine: { lean: 10, twist: 66, bend: -8 }, head: { pitch: 4, yaw: -10 }, hand_r: [62, 62, 20], hand_l: [14, 56, -6], pole_hand_r: [4, -2, 14],
      foot_r: [-5, 18, 8], foot_l: [34, 2.5, -8], ...OPEN },
    follow: { lean: 26, hips: [20, -5, 0], spine: { lean: 8, twist: 38 }, hand_r: [40, 66, 10], hand_l: [18, 56, -6], foot_r: [-7, 8, 8], foot_l: [26, 2.5, -8] },
    orig: 'PROVISIONAL: a full turn of the body, one blade hand swung out at the end of it, the rear foot trailing off the ground' },
};
