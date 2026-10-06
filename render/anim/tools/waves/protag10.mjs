// PROVISIONAL (the brawl look study, 2026-10-06; Legal has not screened these): the Protagonist's super-heavy tier, B's blows, "a whole-body blow that reads as far bigger than a medium at a glance"
// (docs/animation/flurry-study.md). Two pieces for the study; a full set is listed there. Parked (--waves): nothing plays them in a live match, and the fighter's `more` list does not name this wave. Prefix pu.
// His own shape: open palms and blades, rounder arcs. A fall is ONE falling palm (Legal, three-strengths-screen.md: two palms overhead fails; the limb stays at shoulder height until he starts down); a turn is one blade hand.
//   su_drive   (the fall: he rises tall, one palm at shoulder height, the other hand up in guard; then the body comes down and the palm falls onto the chest)
//   su_turn    (a full turn of the body, one blade hand swung out at the end of it, the rear foot trailing off the ground)
const OPEN = { hands: { r: 'open', l: 'open' } };
const NEW = {
  su_drive: { like: 'double_hammer', limb: 'hand', target: 'chest', weight: 'heavy', look: 'PROVISIONAL. He rises tall with one palm at his shoulder, the other hand up in guard, then comes down with his whole weight and the palm falls onto the chest.' },
  su_turn: { like: 'haymaker', limb: 'hand', target: 'chest', weight: 'heavy', look: 'PROVISIONAL. A full turn of the body, one blade hand swung out at the end of it, the rear foot trailing.' },
  su_edge_step: { like: 'front_kick', limb: 'foot', target: 'gut', weight: 'heavy', look: 'PROVISIONAL. A stepping kick with the edge of the foot: compact, hands up, the whole body carried a pace behind one straight leg to the gut.' },
  su_blade_jaw: { like: 'spear_hand', limb: 'hand', target: 'jaw', weight: 'heavy', look: 'PROVISIONAL. A stepping blade hand: the striking side drawn back close to him, then one straight line to the jaw as the body steps through; a strike, never a grip.' },
  su_edge_unwind: { like: 'roundhouse', limb: 'foot', target: 'gut', weight: 'heavy', look: 'PROVISIONAL. An unwinding kick with the edge of the foot: the leg crossed over his own centre, the chin over his shoulder, the body opening out as the foot comes back through the gut.' },
  su_palm_heave: { like: 'uppercut', limb: 'hand', target: 'chest', weight: 'heavy', look: 'PROVISIONAL. A heaving palm: sunk deep with the palm loaded low and the other hand up, both legs drive it up into the chest; no leap, the arm lowers at once.' },
  su_ball_heave: { like: 'front_kick', limb: 'foot', target: 'gut', weight: 'heavy', look: 'PROVISIONAL. A heaving kick with the ball of the foot: sunk deep on the standing leg, the legs drive him up and the foot up into the gut; the standing foot keeps its place.' },
  su_hammer_arm: { like: 'hammer', limb: 'hand', target: 'arm_r', weight: 'heavy', look: 'PROVISIONAL. A falling hammer fist to the arm: risen tall with one fist at his shoulder, the body comes down and the fist drops onto the rival arm; back in his guard at once.' },
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
  su_drive: { tell_at: 0.5, squash_w: 0.0, drive: 'fall', kind: 'hand', target: 'chest', step_max: 22, legal: ['hands_open_or_claw', 'no_held_raise', 'not_at_hip'],
    chamber: { family: 'upright', lean: -8, hips: [-2, 3, 0], spine: { lean: -8, twist: -4 }, head: { pitch: -4 }, hand_r: [2, 64, 12], pole_hand_r: [-8, 6, 10], hand_l: [16, 58, -8],
      foot_r: [-6, 2.5, 9], foot_l: [8, 2.5, -8], ...OPEN },
    contact: { family: 'upright_lunge', lean: 38, hips: [28, -12, 0], spine: { lean: 26, twist: 4 }, head: { pitch: 24 }, hand_r: [54, 50, 8], pole_hand_r: [-4, 14, 10], hand_l: [20, 48, -11],
      foot_r: [-2, 8, 9], foot_l: [34, 2.5, -8], ...OPEN },
    follow: { lean: 32, hips: [24, -13, 0], spine: { lean: 28, twist: 2 }, head: { pitch: 26 }, hand_r: [34, 42, 9], hand_l: [30, 61, -13], foot_r: [-5, 5, 8] },
    orig: 'PROVISIONAL: he rises tall with one palm at his shoulder and the other hand up in guard, then comes down with his whole weight and the palm falls onto the chest' },
  su_turn: { tell_at: 0.5, squash_w: 0.0, drive: 'full_turn', kind: 'hand', target: 'chest', step_max: 22, legal: ['hands_open_or_claw'],
    chamber: { family: 'upright', lean: 12, hips: [-6, -6, 0], spine: { lean: 10, twist: -70, bend: 8 }, head: { pitch: 6, yaw: 26 }, hand_r: [-14, 58, 26.5], hand_l: [16, 54, -6], pole_hand_r: [-10, -2, 14],
      foot_r: [-14, 2.5, 10], foot_l: [12, 2.5, -8], ...OPEN },
    contact: { family: 'upright_lunge', lean: 30, hips: [28, -6, 0], spine: { lean: 10, twist: 66, bend: -8 }, head: { pitch: 4, yaw: -10 }, hand_r: [62, 62, 20], hand_l: [14, 56, -6], pole_hand_r: [4, -2, 14],
      foot_r: [-5, 18, 8], foot_l: [34, 2.5, -8], ...OPEN },
    follow: { lean: 26, hips: [20, -5, 0], spine: { lean: 8, twist: 38 }, hand_r: [40, 66, 10], hand_l: [18, 56, -6], foot_r: [-7, 8, 8], foot_l: [26, 2.5, -8] },
    orig: 'PROVISIONAL: a full turn of the body, one blade hand swung out at the end of it, the rear foot trailing off the ground' },
  su_edge_step: { tell_at: 0.5, squash_w: 0.3, drive: 'step_through', kind: 'foot', target: 'gut', step_max: 22,
    chamber: { family: 'upright', lean: -4, hips: [-4, -2, 0], spine: { lean: -2, twist: -10 }, head: { pitch: -2 }, hand_r: [6, 60, 12], hand_l: [16, 60, -8],
      foot_r: [-4, 30, 10], pole_foot_r: [8, 8, 2], foot_l: [10, 2.5, -8], ...OPEN },
    contact: { family: 'upright_lunge', lean: -16, hips: [30, -2, 0], spine: { lean: -12, twist: 20 }, head: { pitch: 0 }, hand_r: [10, 62, 14], hand_l: [22, 64, -10],
      foot_r: [58, 40, 8], foot_l: [30, 2.5, -8], ...OPEN },
    follow: { hips: [26, -2, 0], foot_r: [44, 16, 8], foot_l: [28, 2.5, -8] },
    orig: 'PROVISIONAL: a stepping kick with the edge of the foot: the leg chambered close, hands up, the body carried a pace behind one straight leg into the gut' },
  su_blade_jaw: { tell_at: 0.5, squash_w: 0.3, drive: 'step_through', kind: 'hand', target: 'jaw', step_max: 22, legal: ['hands_open_or_claw'],
    chamber: { family: 'upright', lean: -6, hips: [-6, -2, 0], spine: { lean: -4, twist: -18 }, head: { pitch: -2 }, hand_r: [0, 62, 14], pole_hand_r: [-10, 6, 10], hand_l: [16, 62, -8],
      foot_r: [-14, 2.5, 10], foot_l: [12, 2.5, -8], ...OPEN },
    contact: { family: 'upright_lunge', lean: 18, hips: [32, -6, 0], spine: { lean: 12, twist: 24 }, head: { pitch: 6 }, hand_r: [66, 82, 6], pole_hand_r: [2, 8, 8], hand_l: [8, 50, -12],
      foot_r: [-4, 6, 9], foot_l: [34, 2.5, -8], ...OPEN },
    follow: { hips: [26, -6, 0], hand_r: [44, 62, 4], hand_l: [8, 50, -12], foot_r: [-4, 4, 9] },
    orig: 'PROVISIONAL: a stepping blade hand: the striking side drawn back close to him, then one straight line to the jaw as the body steps through; the lead hand open' },
  su_edge_unwind: { tell_at: 0.5, squash_w: 0.0, drive: 'unwind', kind: 'foot', target: 'gut', step_max: 12,
    chamber: { family: 'upright', lean: 2, hips: [-4, -2, 0], hip_twist: -24, spine: { lean: 2, twist: -40 }, head: { pitch: 0, yaw: -10 }, hand_r: [10, 60, 14], hand_l: [14, 58, -10],
      foot_r: [6, 14, -12], pole_foot_r: [4, 6, -2], foot_l: [10, 2.5, -8], ...OPEN },
    contact: { family: 'upright_lunge', lean: -8, hip_twist: 46, hips: [16, -2, 0], spine: { lean: -4, twist: 44 }, head: { yaw: -24 }, hand_r: [10, 62, 16], hand_l: [18, 66, -12],
      foot_r: [48, 40, 16], foot_l: [14, 2.5, -8], ...OPEN },
    follow: { hip_twist: 20, spine: { twist: 20 }, foot_r: [34, 12, 12], hand_r: [12, 60, 14], hand_l: [18, 62, -10] },
    orig: 'PROVISIONAL: an unwinding kick with the edge of the foot: the leg crossed over his own centre with the chin over his shoulder, the body opening out as the foot comes back through the gut' },
  su_palm_heave: { tell_at: 0.5, squash_w: 0.0, drive: 'heave', kind: 'hand', target: 'chest', step_max: 8, legal: ['hands_open_or_claw', 'no_leap'],
    chamber: { family: 'crouched', lean: 8, hips: [-2, -16, 0], spine: { lean: 6, twist: -8 }, head: { pitch: -4 }, hand_r: [22, 36, 12], pole_hand_r: [-6, -6, 10], hand_l: [16, 62, -8],
      foot_r: [-14, 2.5, 10], foot_l: [14, 2.5, -8], ...OPEN },
    contact: { family: 'upright_lunge', lean: 8, hips: [12, -4, 0], spine: { lean: 6, twist: 10 }, head: { pitch: 0 }, hand_r: [54, 56, 10], pole_hand_r: [6, -2, 8], hand_l: [22, 62, -8],
      foot_r: [-14, 2.5, 10], foot_l: [14, 2.5, -8], ...OPEN },
    follow: { hips: [8, 0, 0], hand_r: [34, 66, 8], hand_l: [22, 62, -8] },
    orig: 'PROVISIONAL: a heaving palm: sunk deep with the palm loaded low in front and the other hand up in guard, both legs drive it up into the chest; his feet keep their place' },
  su_ball_heave: { tell_at: 0.5, squash_w: 0.0, drive: 'heave', kind: 'foot', target: 'gut', step_max: 8, legal: ['no_leap'],
    chamber: { family: 'crouched', lean: 8, hips: [-2, -16, 0], spine: { lean: 6 }, head: { pitch: -2 }, hand_r: [4, 56, 14], hand_l: [24, 64, -14],
      foot_r: [-10, 6, 10], foot_l: [12, 2.5, -8], ...OPEN },
    contact: { family: 'upright_lunge', lean: -10, hips: [10, 2, 0], spine: { lean: -6 }, head: { pitch: 0 }, hand_r: [12, 64, 14], hand_l: [22, 66, -10],
      foot_r: [46, 44, 8], foot_l: [14, 2.5, -8], ...OPEN },
    follow: { hips: [8, 0, 0], foot_r: [30, 18, 8], hand_r: [12, 62, 14] },
    orig: 'PROVISIONAL: a heaving kick with the ball of the foot: sunk deep on the standing leg, both legs drive him up and the foot up into the gut; the standing foot keeps its place' },
  su_hammer_arm: { tell_at: 0.5, squash_w: 0.0, drive: 'fall', kind: 'hand', target: 'arm_r', step_max: 14, follow_t: 0.7, legal: ['no_clasp', 'no_held_raise'],
    chamber: { family: 'upright', lean: -2, hips: [-2, 2, 0], spine: { lean: -2, twist: -6 }, head: { pitch: -4 }, hand_r: [6, 66, 10], pole_hand_r: [-8, 6, 8], hand_l: [16, 60, -8],
      foot_r: [-6, 2.5, 9], foot_l: [10, 2.5, -8], hands: { r: 'fist', l: 'open' } },
    contact: { family: 'upright_lunge', lean: 18, hips: [16, -8, 0], spine: { lean: 12, twist: 12 }, head: { pitch: 12 }, hand_r: [42, 64, 10], pole_hand_r: [-2, 12, 8], hand_l: [20, 58, -8],
      foot_r: [-4, 2.5, 9], foot_l: [22, 2.5, -8], hands: { r: 'fist', l: 'open' } },
    orig: 'PROVISIONAL: a falling hammer fist to the arm: risen tall with one fist at his shoulder, the body comes down and the fist drops onto the rival arm; back in his guard at once' },
};
