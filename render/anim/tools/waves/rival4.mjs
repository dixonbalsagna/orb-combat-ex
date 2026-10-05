// The rival's first moveset slice, as Combat's review sheet asks for it (docs/combat/pending/movegen/review-sheet.md, "New key sets for Animation: 15" of the rival: 13 lights and 2 heavies; Legal's
// conditions L1 to L8 on the sheet). Pose sketches over the rival's wave 1 bases; parked (--waves), nothing plays them live until Legal's go on the poses and the fighter's `more` list names this
// wave (docs/animation/moveset-parts.md). Identity: fists on the heavies and blade or plate on the lights, never a palm (his row: no palm strike); straight lines, drops and rises. A rising blow
// keeps his feet down and no turn, and its hand is never drawn back to a hip (L1, L2); a dropping blow is one fist, blade or plate (L3). The move each realises (mv.rival.martial.<cell>.<n>):
//   elbow_drop x05    elbow point, drop, chest          forearm_drop x16  hand plate, drop, arm        fist_drop x17     hand fist, drop, head
//   short_uppercut x18  hand fist, rise, jaw (L1)       knee_lift x21     knee cap, rise, gut          arm_chop x22      hand blade, drop, arm (L3)
//   lift_kick x24     foot ball, rise, gut              fist_sweep x25    hand fist, arc out, arm      plate_drop x26    hand plate, drop, chest (L3)
//   low_thrust x27    foot sole, line, legs             gut_rise x28      hand fist, rise, gut (L1)    plate_hammer x29  hand plate, drop, head (L3)
//   knee_hook x30     knee cap, arc in, legs            fist_rise y03     (heavy) hand fist, rise, chest (L1, L6)     heel_backhand y15  (heavy) hand heel, arc out, arm (L6)
const LUNGE = { foot_r: [-6, 2.5, 9], foot_l: [26, 2.5, -7] };
const OPEN = { hands: { r: 'open', l: 'open' } };
const FIST = { hands: { r: 'fist', l: 'open' } };

const NEW = {
  elbow_drop: { like: 'dropping_elbow', limb: 'elbow', target: 'chest', weight: 'light', look: 'From above and short: the point of the elbow dropped onto the chest, the other hand holding the guard down.' },
  forearm_drop: { like: 'hammer', limb: 'hand', target: 'arm_r', weight: 'light', look: 'The plate of the forearm dropped across the rival\'s arm, the body folding over it.' },
  fist_drop: { like: 'hammer', limb: 'hand', target: 'head', weight: 'light', look: 'A short fist dropped onto the head, the elbow barely lifted.' },
  short_uppercut: { like: 'uppercut', limb: 'hand', target: 'jaw', weight: 'light', look: 'A short fist rising under the chin, the feet planted and the arm lowering at once.' },
  knee_lift: { like: 'short_knee', limb: 'knee', target: 'gut', weight: 'light', look: 'A short knee lifted into the gut, the hands pulling the guard down.' },
  arm_chop: { like: 'hook', limb: 'hand', target: 'arm_r', weight: 'light', look: 'A blade hand chopped down onto the rival\'s arm, the elbow bent through it.' },
  lift_kick: { like: 'front_kick', limb: 'foot', target: 'gut', weight: 'light', look: 'The ball of the foot lifted up into the belly from low, the body leaning back off the line.' },
  fist_sweep: { like: 'hook', limb: 'hand', target: 'arm_r', weight: 'light', look: 'A fist swung out and back across the rival\'s arm, the chest opened away.' },
  plate_drop: { like: 'hammer', limb: 'hand', target: 'chest', weight: 'light', look: 'The plate of the forearm dropped onto the chest, the body folding over it.' },
  low_thrust: { like: 'low_kick', limb: 'foot', target: 'legs', weight: 'light', look: 'The sole thrust straight into the thigh, the standing leg firm, the hands up.' },
  gut_rise: { like: 'spear_hand', limb: 'hand', target: 'gut', weight: 'light', look: 'A fist rising into the gut from a crouch, the shoulder under it.' },
  plate_hammer: { like: 'hammer', limb: 'hand', target: 'head', weight: 'light', look: 'The plate of the forearm dropped onto the head like a bar, one arm only.' },
  knee_hook: { like: 'short_knee', limb: 'knee', target: 'legs', weight: 'light', look: 'The knee swung in low on a short arc to the legs, the hands up for balance.' },
  fist_rise: { like: 'uppercut', limb: 'hand', target: 'chest', weight: 'heavy', look: 'A fist driven up into the chest from a low crouch, the whole body rising behind it.' },
  heel_backhand: { like: 'backfist', limb: 'hand', target: 'arm_r', weight: 'heavy', look: 'The back of the fist swung out hard across the rival\'s arm, the whole torso behind it.' },
};
export function rows(wave1) {
  const by = Object.fromEntries(wave1.map(r => [r.id.replace('strike.', ''), r]));
  return Object.entries(NEW).map(([n, o]) => {
    const b = by[o.like];
    return { ...b, id: 'strike.' + n, limb: o.limb, target: o.target, weight: o.weight, look: o.look, _estimate: 'range and ticks borrowed from strike.' + o.like + ' until Combat\'s rows land' };
  });
}

export const strikes = {
  elbow_drop: { kind: 'elbow', target: 'chest', step_max: 16,
    chamber: { hand_r: [6, 76, 8], pole_hand_r: [-4, 14, 6], lean: 4, hips: [-2, -2, 0], spine: { lean: -2, twist: -12 } },
    contact: { family: 'upright_lunge', lean: 12, hips: [8, -5, 0], spine: { lean: 8, twist: 16 }, head: { pitch: 10 },
      hand_r: [20, 66, 6], pole_hand_r: [12, -4, 4], hand_l: [28, 58, -10], foot_r: [-8, 2.5, 9], foot_l: [14, 2.5, -7], ...OPEN },
    orig: 'the point of the elbow dropped short onto the chest, the other hand holding the guard down' },
  forearm_drop: { kind: 'hand', target: 'arm_r',
    chamber: { lean: -4, hips: [-2, -2, 0], spine: { lean: -6, twist: -10 }, hand_r: [16, 80, 10], pole_hand_r: [-6, 6, 8] },
    contact: { family: 'upright_lunge', lean: 16, hips: [14, -5, 0], spine: { lean: 12, twist: 18 }, head: { pitch: 12 },
      hand_r: [40, 62, 8], pole_hand_r: [-2, 14, 6], hand_l: [14, 56, -8], ...LUNGE, ...OPEN },
    orig: 'the plate of the forearm dropped across the rival arm, the body folding over it' },
  fist_drop: { kind: 'hand',
    chamber: { lean: -4, hips: [-2, -2, 0], spine: { lean: -8, twist: -8 }, head: { pitch: -6 }, hand_r: [6, 84, 9], pole_hand_r: [-8, 2, 8] },
    contact: { family: 'upright_lunge', lean: 20, hips: [14, -4, 0], spine: { lean: 12, twist: 10 }, head: { pitch: 14 },
      hand_r: [42, 68, 6], pole_hand_r: [-6, 10, 8], hand_l: [16, 56, -8], ...LUNGE, ...FIST },
    orig: 'a short fist dropped onto the head from just above it, the elbow barely lifted' },
  short_uppercut: { from: 'upper', kind: 'hand', target: 'jaw', legal: ['no_leap', 'no_held_raise'],
    over: { all: { ...FIST }, chamber: { hand_r: [20, 28, 12] }, contact: { lean: 8, hips: [14, -2, 0], spine: { lean: -4, twist: 18 }, hand_r: [50, 80, 8] }, follow: { hand_r: [34, 70, 8] } },
    orig: 'a short fist rising under the chin, the feet planted, the arm lowering at once' },
  knee_lift: { kind: 'knee', target: 'gut', step_max: 16,
    chamber: { lean: 4, hips: [0, -4, 0], hand_r: [16, 66, 10], hand_l: [16, 66, -10], foot_r: [0, 6, 8] },
    contact: { family: 'upright_lunge', lean: -6, hips: [4, 2, 0], spine: { lean: -2 }, head: { pitch: 0 },
      hand_r: [22, 50, 10], hand_l: [22, 50, -10], foot_r: [22, 28, 8], pole_foot_r: [10, 1, 0], foot_l: [6, 4, -7], ...OPEN },
    orig: 'a short knee lifted into the gut, the hands pulling the guard down' },
  arm_chop: { kind: 'hand', target: 'arm_r',
    chamber: { lean: -2, hips: [-2, -2, 0], spine: { lean: -4, twist: -10 }, hand_r: [8, 80, 10], pole_hand_r: [-4, 8, 8] },
    contact: { family: 'upright_lunge', lean: 12, hips: [12, -4, 0], spine: { lean: 8, twist: 20 }, head: { pitch: 8 },
      hand_r: [38, 58, 8], pole_hand_r: [0, 10, 6], hand_l: [14, 56, -8], ...LUNGE, ...OPEN },
    orig: 'a blade hand chopped down onto the rival arm, the elbow bent through the chop' },
  lift_kick: { kind: 'foot', target: 'gut', step_max: 16,
    chamber: { foot_r: [6, 14, 8] },
    contact: { family: 'upright_lunge', lean: -8, hips: [8, 0, 0], spine: { lean: -4, twist: 10 }, head: { pitch: 4 },
      hand_r: [12, 60, 14], hand_l: [20, 62, -10], foot_r: [34, 38, 8], foot_l: [8, 2.5, -7], ...OPEN },
    orig: 'the ball of the foot lifted up into the belly from low, the body leaning back off the line' },
  fist_sweep: { from: 'hook', kind: 'hand', family: 'hand_arc', target: 'arm_r',
    contact: { family: 'upright_lunge', lean: 14, hips: [18, -3, 0], spine: { lean: -2, twist: -30 }, head: { pitch: 2, yaw: -12 },
      hand_r: [46, 60, 12], pole_hand_r: [2, 8, 10], hand_l: [12, 58, -8], ...LUNGE, ...FIST },
    orig: 'a fist swung out and back across the rival arm, the chest opened away from him' },
  plate_drop: { kind: 'hand', target: 'chest',
    chamber: { lean: -2, hips: [-2, -2, 0], spine: { lean: -6, twist: -10 }, hand_r: [18, 80, 10], pole_hand_r: [-6, 6, 8] },
    contact: { family: 'upright_lunge', lean: 24, hips: [18, -9, 0], spine: { lean: 18, twist: 12 }, head: { pitch: 18 },
      hand_r: [34, 58, 8], pole_hand_r: [-2, 12, 6], hand_l: [18, 50, -8], ...LUNGE, ...OPEN },
    orig: 'the plate of the forearm dropped onto the chest, the whole body folded over it from the waist' },
  low_thrust: { kind: 'foot', target: 'legs', step_max: 16,
    chamber: { foot_r: [6, 28, 10] },
    contact: { family: 'upright_lunge', lean: 4, hips: [10, -2, 0], spine: { lean: 2, twist: 8 }, head: { pitch: 6 },
      hand_r: [10, 58, 14], hand_l: [22, 60, -10], foot_r: [40, 16, 8], foot_l: [10, 2.5, -7], ...OPEN },
    orig: 'the sole thrust straight into the thigh, the standing leg firm, the hands up' },
  gut_rise: { kind: 'hand', target: 'gut', step_max: 16, legal: ['no_leap'],
    chamber: { family: 'crouched', lean: 12, hips: [2, -10, 0], spine: { lean: 8, twist: -14 }, hand_r: [18, 34, 10], pole_hand_r: [-8, -6, 8], hand_l: [22, 56, -8] },
    contact: { family: 'crouched', lean: 20, hips: [12, -10, 0], spine: { lean: 8, twist: 24 }, head: { pitch: 6 },
      hand_r: [46, 50, 8], pole_hand_r: [-4, -2, 8], hand_l: [12, 52, -6], foot_r: [-8, 2.5, 9], foot_l: [22, 2.5, -7], ...FIST },
    orig: 'a fist rising into the gut from a crouch, the shoulder under it, the other hand across the chest' },
  plate_hammer: { kind: 'hand',
    chamber: { lean: -4, hips: [-2, -2, 0], spine: { lean: -8, twist: -8 }, head: { pitch: -6 }, hand_r: [14, 83, 9], pole_hand_r: [-8, 2, 8] },
    contact: { family: 'upright_lunge', lean: 10, hips: [18, -2, 0], spine: { lean: 2, twist: 22 }, head: { pitch: 6 },
      hand_r: [48, 82, 10], pole_hand_r: [-4, 12, 8], hand_l: [8, 60, -12], ...LUNGE, ...OPEN },
    orig: 'the plate of the forearm dropped onto the head like a bar from a tall stance, one arm only, the other hand apart' },
  knee_hook: { kind: 'knee', target: 'legs', step_max: 16,
    chamber: { lean: 6, hips: [-2, -2, 0], hand_r: [18, 58, 12], hand_l: [22, 60, -8], foot_r: [-4, 14, 12] },
    contact: { family: 'upright_lunge', lean: -2, hips: [8, -4, 0], spine: { lean: 0, twist: 22 }, head: { pitch: 8 },
      hand_r: [22, 62, 12], hand_l: [28, 66, -8], foot_r: [20, 16, 16], pole_foot_r: [8, 1, 8], foot_l: [6, 2.5, -7], ...OPEN },
    orig: 'the knee swung in low on a short arc to the legs, the hands up for balance' },
  fist_rise: { from: 'upper', kind: 'hand', target: 'chest', legal: ['no_leap', 'no_held_raise'],
    over: { all: { ...FIST }, chamber: { family: 'crouched', lean: 14, hips: [0, -12, 0], hand_r: [20, 28, 10] },
      contact: { family: 'crouched', lean: 22, hips: [20, -8, 0], spine: { lean: -2, twist: 34 }, head: { pitch: 0 }, hand_r: [54, 60, 8] }, follow: { hand_r: [34, 56, 8] } },
    orig: 'a fist driven up into the chest from a low crouch, the whole body rising behind it, the other arm low across the body' },
  heel_backhand: { from: 'hook', kind: 'hand', family: 'hand_arc', target: 'arm_r',
    contact: { family: 'upright_lunge', lean: 18, hips: [20, -4, 0], spine: { lean: -2, twist: -34 }, head: { pitch: 2, yaw: -14 },
      hand_r: [52, 60, 12], pole_hand_r: [2, 8, 10], hand_l: [12, 58, -8], ...LUNGE, ...FIST },
    orig: 'the back of the fist swung out hard across the rival arm, the whole torso thrown round behind it' },
};
