// The Protagonist's first moveset slice, as Combat's review sheet asks for it (docs/combat/pending/movegen/review-sheet.md, "New key sets for Animation: 8", all lights; Legal's conditions L1 to L8 on
// the sheet). His own pose sketches (open hands, rounder arcs, a taller stance: data/anim/fighters.json shape P); parked (--waves), nothing plays them live until Legal's go on the poses and the
// fighter's `more` list names this wave (docs/animation/moveset-parts.md). Identity: palms, blade hands and heels, arcs, the edge of the foot. A rising blow keeps his feet down and no turn, the arm
// lowering at once, and a palm is a blow only: never chambered at a hip, never a clawed hand on the face (L1, L2); a dropping blow is one fist or blade (L3). The move each realises
// (mv.protagonist.martial.x.<n>):
//   knee_hook x05  knee cap, arc in, legs          back_chop x15   hand blade, arc out, arm     palm_rise x18  hand palm, rise, gut (L1, L2)   palm_lift x19  hand palm, rise, jaw (L1, L2, L8)
//   lift_kick x24  foot ball, rise, gut            edge_crescent x27  foot edge, arc out, gut   fist_chop x28  hand fist, drop, arm (L3)       palm_heave x29 hand palm, rise, chest (L1, L2)
const OPEN = { hands: { r: 'open', l: 'open' } };
const FIST = { hands: { r: 'fist', l: 'open' } };

const NEW = {
  knee_hook: { like: 'short_knee', limb: 'knee', target: 'legs', weight: 'light', look: 'The knee swung in low on an arc to the legs, both open hands up for balance.' },
  back_chop: { like: 'backfist', limb: 'hand', target: 'arm_r', weight: 'light', look: 'A blade hand swung back out across the rival\'s arm, the back of the forearm leading.' },
  palm_rise: { like: 'spear_hand', limb: 'hand', target: 'gut', weight: 'light', look: 'The heel of an open palm lifted into the gut from a low crouch, the feet planted.' },
  palm_lift: { like: 'jab', limb: 'hand', target: 'jaw', weight: 'light', look: 'The heel of an open palm lifted under the chin, the body rising behind it, no turn, the arm lowering at once.' },
  lift_kick: { like: 'front_kick', limb: 'foot', target: 'gut', weight: 'light', look: 'The ball of the foot lifted up into the belly from low, the hands up and open.' },
  edge_crescent: { like: 'snap_round', limb: 'foot', target: 'gut', weight: 'light', look: 'The edge of the foot swept out and round into the belly, the hands up and open.' },
  fist_chop: { like: 'hammer', limb: 'hand', target: 'arm_r', weight: 'light', look: 'One fist brought down on the rival\'s arm, the elbow bent through it, the other hand open and apart.' },
  palm_heave: { like: 'cross', limb: 'hand', target: 'chest', weight: 'light', look: 'The heel of an open palm lifted into the chest from low, the feet planted, no turn.' },
};
export function rows(wave1) {
  const by = Object.fromEntries(wave1.map(r => [r.id.replace('strike.', ''), r]));
  return Object.entries(NEW).map(([n, o]) => {
    const b = by[o.like];
    return { ...b, id: 'strike.' + n, limb: o.limb, target: o.target, weight: o.weight, look: o.look, _estimate: 'range and ticks borrowed from strike.' + o.like + ' until Combat\'s rows land' };
  });
}

export const strikes = {
  knee_hook: { kind: 'knee', target: 'legs', step_max: 16,
    chamber: { lean: 6, hips: [-2, -2, 0], hand_r: [18, 60, 12], hand_l: [20, 62, -8], foot_r: [-4, 14, 12] },
    contact: { family: 'upright_lunge', lean: -2, hips: [8, -4, 0], spine: { lean: 0, twist: 22 }, head: { pitch: 8 },
      hand_r: [22, 62, 12], hand_l: [28, 66, -8], foot_r: [20, 16, 16], pole_foot_r: [8, 1, 8], foot_l: [6, 2.5, -7], ...OPEN },
    orig: 'the knee swung in low on an arc to the legs, both open hands up for balance' },
  back_chop: { from: 'hook', kind: 'hand', family: 'hand_arc', target: 'arm_r',
    contact: { family: 'upright_lunge', lean: 14, hips: [18, -3, 0], spine: { lean: -2, twist: -34 }, head: { pitch: 2, yaw: -14 },
      hand_r: [46, 58, 12], pole_hand_r: [2, 8, 10], hand_l: [12, 58, -8], foot_r: [-6, 2.5, 9], foot_l: [26, 2.5, -7], ...OPEN },
    orig: 'a blade hand swung back out across the rival arm, the back of the forearm leading, the chest opened away' },
  palm_rise: { kind: 'hand', target: 'gut', step_max: 16, legal: ['hands_open_or_claw', 'not_at_hip', 'no_leap'],
    chamber: { family: 'crouched', lean: 12, hips: [2, -10, 0], spine: { lean: 8, twist: -10 }, hand_r: [22, 22, 10], pole_hand_r: [-8, -6, 8], hand_l: [22, 56, -8] },
    contact: { family: 'crouched', lean: 20, hips: [12, -10, 0], spine: { lean: 6, twist: 18 }, head: { pitch: 6 },
      hand_r: [46, 52, 8], pole_hand_r: [-4, -2, 8], hand_l: [12, 54, -6], foot_r: [-8, 2.5, 9], foot_l: [22, 2.5, -7], ...OPEN },
    orig: 'the heel of an open palm lifted into the gut from a low crouch, the other hand across the chest' },
  palm_lift: { from: 'upper', kind: 'hand', target: 'jaw', legal: ['hands_open_or_claw', 'not_at_hip', 'no_leap', 'no_held_raise'],
    over: { all: { ...OPEN }, chamber: { hand_r: [22, 26, 12] }, contact: { lean: 8, hips: [14, -2, 0], spine: { lean: -4, twist: 14 }, hand_r: [50, 80, 8] }, follow: { hand_r: [34, 70, 8] } },
    orig: 'the heel of an open palm lifted under the chin, the body rising behind it, no turn, the arm lowering at once' },
  lift_kick: { kind: 'foot', target: 'gut', step_max: 16,
    chamber: { foot_r: [6, 14, 8] },
    contact: { family: 'upright_lunge', lean: -8, hips: [8, 0, 0], spine: { lean: -4, twist: 10 }, head: { pitch: 6 },
      hand_r: [12, 62, 14], hand_l: [20, 64, -10], foot_r: [34, 38, 8], foot_l: [8, 2.5, -7], ...OPEN },
    orig: 'the ball of the foot lifted up into the belly from low, the hands up and open' },
  edge_crescent: { from: 'round', kind: 'foot', target: 'gut',
    over: { all: { ...OPEN }, chamber: { foot_r: [8, 34, 6] },
      contact: { lean: -4, hips: [14, -2, 0], spine: { lean: -2, twist: 16 }, foot_r: [40, 48, 16], hand_r: [8, 66, 14], hand_l: [20, 66, -10], foot_l: [14, 2.5, -7] },
      follow: { foot_r: [14, 28, 9] } },
    orig: 'the edge of the foot swept out and round into the belly, the hands up and open' },
  fist_chop: { kind: 'hand', target: 'arm_r', legal: ['no_clasp'],
    chamber: { lean: -2, hips: [-2, -2, 0], spine: { lean: -6, twist: -8 }, hand_r: [16, 80, 10], pole_hand_r: [-6, 6, 8] },
    contact: { family: 'upright_lunge', lean: 14, hips: [12, -4, 0], spine: { lean: 10, twist: 16 }, head: { pitch: 10 },
      hand_r: [40, 60, 8], pole_hand_r: [0, 12, 6], hand_l: [14, 58, -8], foot_r: [-6, 2.5, 9], foot_l: [24, 2.5, -7], ...FIST },
    orig: 'one fist brought down on the rival arm, the elbow bent through it, the other hand open and apart' },
  palm_heave: { kind: 'hand', target: 'chest', step_max: 16, legal: ['hands_open_or_claw', 'not_at_hip', 'no_leap'],
    chamber: { family: 'crouched', lean: 12, hips: [2, -8, 0], spine: { lean: 8, twist: -10 }, hand_r: [22, 24, 10], pole_hand_r: [-8, -6, 8], hand_l: [22, 56, -8] },
    contact: { family: 'upright_lunge', lean: 14, hips: [12, -6, 0], spine: { lean: 4, twist: 18 }, head: { pitch: 4 },
      hand_r: [46, 62, 8], pole_hand_r: [-2, 0, 8], hand_l: [12, 56, -6], foot_r: [-8, 2.5, 9], foot_l: [22, 2.5, -7], ...OPEN },
    orig: 'the heel of an open palm lifted into the chest from low, the feet planted, the other hand across the chest' },
};
