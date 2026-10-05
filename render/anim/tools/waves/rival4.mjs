// The rival's first moveset slice (docs/combat/moveset-generator.md section 6: the martial arts stance for both fighters): 12 new lights and 1 new heavy, the shapes his
// cells ask for that no posed strike has. Authored as pose sketches over the rival's wave 1 bases; parked (--waves), nothing plays them live until Legal's go and the
// fighter's `more` list names this wave (docs/animation/moveset-parts.md). Identity (docs/combat/moveset-generator.md section 2): fists, plates and blades, straight lines
// and drops, the close limbs. Legal's lines: no hand chambered at the hip, no two fists clasped, no leap on a rising blow, no arm held raised after it, one turn at most.
//   elbow_drop    the point of the elbow dropped on the chest, a short light version of the dropping elbow
//   forearm_drop  the plate of the forearm dropped on the arm
//   fist_drop     a short fist dropped on the head: the light cousin of the hammer
//   gut_rise      a fist rising into the gut from a crouch
//   collar_chop   a blade hand chopped down onto the collar
//   elbow_thrust  the point of the elbow driven straight into the chest
//   hook_knee     the knee swung in on a short arc to the gut
//   plate_rise    the forearm plate smashed up under the chin
//   plate_sweep   the plate of the forearm swept in across the chest
//   heel_stamp    the heel stamped down the shin
//   rib_scythe    a blade hand scything in along the ribs
//   spear_rise    a blade hand thrust up under the chin
//   fist_rise     (heavy) a fist driven up into the chest from a low crouch
const LUNGE = { foot_r: [-6, 2.5, 9], foot_l: [26, 2.5, -7] };
const OPEN = { hands: { r: 'open', l: 'open' } };
const FIST = { hands: { r: 'fist', l: 'open' } };

const NEW = {
  elbow_drop: { like: 'dropping_elbow', limb: 'elbow', target: 'chest', weight: 'light', look: 'From above and short: the point of the elbow dropped onto the chest, the other hand holding the guard down.' },
  forearm_drop: { like: 'hammer', limb: 'hand', target: 'arm_r', weight: 'light', look: 'The plate of the forearm dropped across the rival\'s arm, the body folding over it.' },
  fist_drop: { like: 'hammer', limb: 'hand', target: 'head', weight: 'light', look: 'A short fist dropped onto the head, the elbow barely lifted.' },
  gut_rise: { like: 'spear_hand', limb: 'hand', target: 'gut', weight: 'light', look: 'A fist rising into the gut from a crouch, the shoulder under it.' },
  collar_chop: { like: 'hook', limb: 'hand', target: 'chest', weight: 'light', look: 'A blade hand chopped down onto the collar, the elbow bent through it.' },
  elbow_thrust: { like: 'short_elbow', limb: 'elbow', target: 'chest', weight: 'light', look: 'The point of the elbow driven straight into the chest, the other hand pulling the guard aside.' },
  hook_knee: { like: 'short_knee', limb: 'knee', target: 'gut', weight: 'light', look: 'The knee swung in on a short arc to the gut, the hands pulling the guard open.' },
  plate_rise: { like: 'rising_elbow', limb: 'hand', target: 'jaw', weight: 'light', look: 'The plate of the forearm smashed up under the chin, the body rising behind it.' },
  plate_sweep: { like: 'hook', limb: 'hand', target: 'chest', weight: 'light', look: 'The plate of the forearm swept in across the chest on a flat arc.' },
  heel_stamp: { like: 'low_kick', limb: 'foot', target: 'shins', weight: 'light', look: 'The heel stamped down the shin, the standing leg firm.' },
  rib_scythe: { like: 'hook', limb: 'hand', target: 'gut', weight: 'light', look: 'A blade hand scything in along the ribs, the hip turned through.' },
  spear_rise: { like: 'jab', limb: 'hand', target: 'jaw', weight: 'light', look: 'A blade hand thrust up under the chin, the feet planted.' },
  fist_rise: { like: 'uppercut', limb: 'hand', target: 'chest', weight: 'heavy', look: 'A fist driven up into the chest from a low crouch, the whole body rising behind it.' },
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
      hand_r: [44, 72, 6], pole_hand_r: [-6, 10, 8], hand_l: [16, 56, -8], ...LUNGE, ...FIST },
    orig: 'a short fist dropped onto the head from just above it, the elbow barely lifted' },
  gut_rise: { kind: 'hand', target: 'gut', step_max: 16,
    chamber: { family: 'crouched', lean: 12, hips: [2, -10, 0], spine: { lean: 8, twist: -14 }, hand_r: [16, 36, 10], pole_hand_r: [-8, -6, 8], hand_l: [22, 56, -8] },
    contact: { family: 'crouched', lean: 20, hips: [12, -10, 0], spine: { lean: 8, twist: 24 }, head: { pitch: 6 },
      hand_r: [46, 50, 8], pole_hand_r: [-4, -2, 8], hand_l: [12, 52, -6], foot_r: [-8, 2.5, 9], foot_l: [22, 2.5, -7], ...FIST },
    orig: 'a fist rising into the gut from a crouch, the shoulder under it, the other hand across the chest' },
  collar_chop: { kind: 'hand', target: 'chest',
    chamber: { lean: -2, hips: [-2, -2, 0], spine: { lean: -4, twist: -10 }, hand_r: [8, 80, 10], pole_hand_r: [-4, 8, 8] },
    contact: { family: 'upright_lunge', lean: 14, hips: [12, -4, 0], spine: { lean: 8, twist: 22 }, head: { pitch: 10 },
      hand_r: [40, 64, 8], pole_hand_r: [0, 12, 6], hand_l: [14, 56, -8], ...LUNGE, ...OPEN },
    orig: 'a blade hand chopped down onto the collar, the elbow bent through the chop' },
  elbow_thrust: { kind: 'elbow', target: 'chest', step_max: 16,
    chamber: { family: 'upright', lean: 8, hips: [-2, -4, 0], spine: { lean: 4, twist: -18 }, hand_r: [8, 52, 12], pole_hand_r: [-8, 0, 10], hand_l: [22, 56, -8] },
    contact: { family: 'upright_lunge', lean: 16, hips: [12, -4, 0], spine: { lean: 6, twist: 26 }, head: { pitch: 6 },
      hand_r: [30, 60, 8], pole_hand_r: [8, -2, 6], hand_l: [16, 56, -8], ...LUNGE, ...OPEN },
    orig: 'the point of the elbow driven straight into the chest, the other hand pulling the guard aside' },
  hook_knee: { kind: 'knee', target: 'gut', step_max: 16,
    chamber: { lean: 6, hips: [-2, -2, 0], hand_r: [18, 58, 12], hand_l: [22, 60, -8], foot_r: [-4, 14, 12] },
    contact: { family: 'upright_lunge', lean: -4, hips: [8, -2, 0], spine: { lean: -2, twist: 20 }, head: { pitch: 6 },
      hand_r: [24, 56, 12], hand_l: [30, 64, -8], foot_r: [18, 26, 16], pole_foot_r: [8, 1, 8], foot_l: [6, 2.5, -7], ...OPEN },
    orig: 'the knee swung in on a short arc to the gut, the hands pulling the guard open' },
  plate_rise: { kind: 'hand', target: 'jaw', step_max: 16,
    chamber: { family: 'crouched', lean: 10, hips: [0, -8, 0], spine: { lean: 6, twist: -10 }, hand_r: [14, 40, 10], pole_hand_r: [-6, -4, 10], hand_l: [22, 56, -8] },
    contact: { family: 'upright', lean: 6, hips: [10, 0, 0], spine: { lean: -6, twist: 22 }, head: { pitch: -8 },
      hand_r: [40, 80, 6], pole_hand_r: [6, 10, 6], hand_l: [14, 56, -8], foot_r: [-6, 2.5, 9], foot_l: [20, 2.5, -7], ...OPEN },
    orig: 'the plate of the forearm smashed up under the chin, the body rising behind it, the arm lowering at once' },
  plate_sweep: { from: 'hook', kind: 'hand', family: 'hand_arc', target: 'chest',
    contact: { family: 'upright_lunge', lean: 22, hips: [18, -4, 0], spine: { lean: 4, twist: 40 }, head: { pitch: 4 },
      hand_r: [48, 62, 14], pole_hand_r: [2, -2, 12], hand_l: [16, 56, -6], ...LUNGE, ...OPEN },
    orig: 'the plate of the forearm swept in across the chest on a flat arc, the elbow leading' },
  heel_stamp: { kind: 'foot', target: 'shins', step_max: 16,
    chamber: { foot_r: [6, 30, 10] },
    contact: { family: 'upright_lunge', lean: 6, hips: [10, -2, 0], spine: { lean: 2, twist: 8 }, head: { pitch: 6 },
      hand_r: [10, 58, 14], hand_l: [22, 60, -10], foot_r: [38, 12, 8], foot_l: [10, 2.5, -7], ...OPEN },
    orig: 'the heel stamped down the shin, the standing leg firm, the hands up' },
  rib_scythe: { from: 'hook', kind: 'hand', family: 'hand_arc', target: 'gut',
    contact: { family: 'upright_lunge', lean: 22, hips: [18, -6, 0], spine: { lean: 6, twist: 40 }, head: { pitch: 6 },
      hand_r: [50, 52, 14], pole_hand_r: [2, -6, 12], hand_l: [16, 54, -6], ...LUNGE, ...OPEN },
    orig: 'a blade hand scything in along the ribs, the hip turned through, the other hand back at his chest' },
  spear_rise: { from: 'upper', kind: 'hand', target: 'jaw',
    over: { all: { ...OPEN }, contact: { lean: 10, hips: [14, -2, 0], spine: { lean: -6, twist: 18 }, hand_r: [50, 82, 8] }, follow: { hand_r: [34, 70, 8] } },
    orig: 'a blade hand thrust up under the chin, the feet planted, the arm lowering at once' },
  fist_rise: { from: 'upper', kind: 'hand', target: 'chest', legal: ['no_leap', 'no_held_raise'],
    over: { all: { ...FIST }, chamber: { family: 'crouched', lean: 14, hips: [0, -12, 0], hand_r: [16, 30, 10] },
      contact: { family: 'crouched', lean: 22, hips: [20, -8, 0], spine: { lean: -2, twist: 34 }, head: { pitch: 0 }, hand_r: [54, 60, 8] }, follow: { hand_r: [34, 56, 8] } },
    orig: 'a fist driven up into the chest from a low crouch, the whole body rising behind it, the other arm low across the body' },
};
