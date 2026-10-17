// PROVISIONAL (Combat's four missing pieces, a9e8f9cd, docs/combat/split-and-pieces.md section 5b; Legal has not screened these): three of the Protagonist's pieces, all NAMED ONLY (`named`: findable by the
// beat's `piece`, in no random pick list, so today's brawl is unchanged until Combat's pool is the hook). Parked (--waves): nothing plays them until the pool does. Prefix pv.
//   su_blade_fall   A falling blade hand to the chest: the second of his spike ender's launchers. Legal's conditions: L3 a dropping blow by ONE hand, the two hands apart and never clasped; L6 charged with one arm
//                   back at shoulder height; W1 a wind-up of 12 ticks or more (the tier's 28); D5 the rise is the body straightening, never a leap (both feet keep the ground), the limb stays at shoulder height until he starts down.
//                   Not su_drive: that one is a PALM that falls onto the chest with the body tall; this is the EDGE of the hand chopped down on a slant from the shoulder, the elbow high and the body folding behind it.
//   su_palm_arm     A stepping palm to the arm (heavy): the heel of the open palm set on the rival's arm as the body steps through; one hand, the other open in guard.
//   palm_turn       A turning palm-heel to the chest (a light, his perfect follow-up): the backfist's outward arc, re-aimed from the head to the chest. To read as a palm and not a backfist the PALM LEADS: the hand
//                   is open and the heel of it arrives first, the fingers up, the arm bent through the turn and not whipped to full length.
const OPEN = { hands: { r: 'open', l: 'open' } };
const NEW = {
  su_blade_fall: { like: 'double_hammer', limb: 'hand', target: 'chest', weight: 'heavy', look: 'PROVISIONAL. He rises tall with one blade hand cocked at the shoulder and the other hand up in guard, then folds down behind it and the edge of the hand falls on a slant onto the chest.' },
  su_palm_arm: { like: 'spear_hand', limb: 'hand', target: 'arm_r', weight: 'heavy', look: 'PROVISIONAL. A stepping palm: the striking hand drawn back close, then one straight line as the body steps through, the heel of the palm set on the rival arm.' },
  palm_turn: { like: 'backfist', limb: 'hand', target: 'chest', weight: 'light', look: 'PROVISIONAL. A turning palm-heel: the open hand carried out and round on the backfist arc and the heel of it set on the chest, the palm leading; he is turned away from the rival at the end of it.' },
};
export function rows(wave1) {
  const by = Object.fromEntries(wave1.map(r => [r.id.replace('strike.', ''), r]));
  return Object.entries(NEW).map(([n, o]) => {
    const b = by[o.like];
    if (o.weight === 'light') return { ...b, id: 'strike.' + n, limb: o.limb, target: o.target, weight: o.weight, look: o.look,
      _estimate: 'PROVISIONAL: range and ticks borrowed from strike.' + o.like + ' (the backfist)' };
    return { ...b, id: 'strike.' + n, limb: o.limb, limb2: null, uses: { arms: 1 }, target: o.target, weight: o.weight, look: o.look,
      range: { ...b.range, lunge: Math.round(b.range.lunge * 1.25), reach: Math.round(b.range.reach * 1.1) }, ticks: { load: 28, follow: 8, recover: 14 },
      _estimate: 'PROVISIONAL: range and ticks borrowed from strike.' + o.like + ' (lunge 1.25 times, reach 1.1 times); the load is the 28-tick wind-up of B (docs/design/brawl-second-pass.md)' };
  });
}

export const strikes = {
  // the blade hand cocked at the shoulder (L6: one arm back at shoulder height), the free hand up and apart (L3); the contact is lower and slanted where su_drive's palm falls straight
  su_blade_fall: { named: true, tell_at: 0.5, squash_w: 0.0, drive: 'fall', kind: 'hand', target: 'chest', step_max: 22, legal: ['hands_open_or_claw', 'no_held_raise', 'not_at_hip'],
    chamber: { family: 'upright', lean: -8, hips: [-2, 3, 0], spine: { lean: -8, twist: -10 }, head: { pitch: -4 }, hand_r: [-2, 66, 15], pole_hand_r: [-10, 10, 12], hand_l: [16, 58, -8],
      foot_r: [-6, 2.5, 9], foot_l: [8, 2.5, -8], ...OPEN },
    contact: { family: 'upright_lunge', lean: 34, hips: [26, -12, 0], spine: { lean: 24, twist: 14 }, head: { pitch: 22 }, hand_r: [56, 44, 7], pole_hand_r: [-2, 22, 10], hand_l: [20, 50, -11],
      foot_r: [-2, 4, 9], foot_l: [34, 2.5, -8], ...OPEN },
    follow: { lean: 28, hips: [22, -12, 0], spine: { lean: 24, twist: 8 }, head: { pitch: 22 }, hand_r: [38, 36, 8], hand_l: [26, 58, -12], foot_r: [-5, 3, 8] },
    orig: 'PROVISIONAL: he rises tall with one blade hand cocked at the shoulder and the other hand up in guard, then folds down behind it and the edge of the hand falls on a slant onto the chest' },
  // the stepping palm to the arm: the su_blade_jaw line carried lower, the palm open and flat
  su_palm_arm: { named: true, tell_at: 0.5, squash_w: 0.3, drive: 'step_through', kind: 'hand', target: 'arm_r', step_max: 22, legal: ['hands_open_or_claw', 'not_at_hip'],
    chamber: { family: 'upright', lean: -6, hips: [-6, -2, 0], spine: { lean: -4, twist: -18 }, head: { pitch: -2 }, hand_r: [0, 58, 14], pole_hand_r: [-10, 4, 10], hand_l: [16, 62, -8],
      foot_r: [-14, 2.5, 10], foot_l: [12, 2.5, -8], ...OPEN },
    contact: { family: 'upright_lunge', lean: 18, hips: [30, -8, 0], spine: { lean: 10, twist: 24 }, head: { pitch: 8 }, hand_r: [62, 56, 8], pole_hand_r: [2, 6, 8], hand_l: [8, 52, -12],
      foot_r: [-4, 6, 9], foot_l: [32, 2.5, -8], ...OPEN },
    follow: { hips: [24, -8, 0], hand_r: [42, 56, 6], hand_l: [8, 52, -12], foot_r: [-4, 4, 9] },
    orig: 'PROVISIONAL: a stepping palm: the striking hand drawn back close to him, then one straight line to the arm as the body steps through, the heel of the palm set on it; the lead hand open in guard' },
  // the backfist's arc, re-aimed to the chest: the arm stays bent through the turn (the palm leads, not the back of the fist) and the open hand arrives heel first
  palm_turn: { named: true, kind: 'hand', target: 'chest', legal: ['hands_open_or_claw', 'not_at_hip'],
    chamber: { family: 'upright', lean: 10, hips: [3, -4, 0], spine: { lean: 4, twist: -27.5, bend: 8 }, head: { pitch: 3, yaw: 8 }, hand_r: [10, 58, 25], pole_hand_r: [-4, -2, 12], hand_l: [20, 59, -6],
      foot_r: [-10, 2.5, 9], foot_l: [12, 2.5, -7], ...OPEN },
    contact: { family: 'upright_lunge', lean: 14, hips: [18, -3, 0], spine: { lean: 0, twist: -30, bend: -4 }, head: { pitch: 0, yaw: -10 }, hand_r: [44, 58, 11], pole_hand_r: [4, 4, 9], hand_l: [12, 61, -8],
      foot_r: [-6, 2.5, 9], foot_l: [26, 2.5, -7], ...OPEN },
    follow: { lean: 22, hips: [12, -4, 0], spine: { lean: 4, twist: 34.5 }, head: { pitch: 3, yaw: 4 }, hand_r: [32, 60, 10], hand_l: [18, 61, -6] },
    orig: 'PROVISIONAL: a turning palm-heel: the open hand carried out and round on the backfist arc, the arm bent through the turn, the heel of the palm set on the chest, the palm leading' },
};
