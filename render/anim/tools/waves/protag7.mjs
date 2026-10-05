// The Protagonist's first moveset slice (docs/combat/moveset-generator.md section 6): 8 new lights, the shapes his cells ask for that no posed strike has. Authored as
// his own pose sketches (open hands, rounder arcs, a taller stance: data/anim/fighters.json shape P); parked (--waves), nothing plays them live until Legal's go and the
// fighter's `more` list names this wave (docs/animation/moveset-parts.md). Identity: palms, blade hands and heels, arcs in and out, edges of the foot, the elbow and knee.
// Legal's lines: every hand open or flat (no claw), no hand chambered at the hip, no leap, a single turn at most, kicks at the chest or below.
//   knee_hook      the knee swung in low on an arc to the legs
//   elbow_drop     the point of the elbow dropped on the chest
//   palm_slap      an open palm swung round on an arc to the head
//   palm_drop      a flat palm brought down onto the arm
//   blade_back     a blade hand swung back out across the chest, the back of the arm leading
//   palm_rise      the heel of the palm lifted into the gut
//   edge_crescent  the edge of the foot swept out and round into the gut
//   elbow_back     the point of the elbow swung back and round to the jaw
const OPEN = { hands: { r: 'open', l: 'open' } };

const NEW = {
  knee_hook: { like: 'short_knee', limb: 'knee', target: 'legs', weight: 'light', look: 'The knee swung in low on an arc to the legs, both open hands up for balance.' },
  elbow_drop: { like: 'dropping_elbow', limb: 'elbow', target: 'chest', weight: 'light', look: 'From above and short: the point of the elbow dropped onto the chest, the other open hand holding the guard down.' },
  palm_slap: { like: 'hook', limb: 'hand', target: 'head', weight: 'light', look: 'An open palm swung round on a wide arc to the head, the free hand up at his cheek.' },
  palm_drop: { like: 'hammer', limb: 'hand', target: 'arm_r', weight: 'light', look: 'A flat palm brought down onto the rival\'s arm, the elbow bent through it.' },
  blade_back: { like: 'backfist', limb: 'hand', target: 'chest', weight: 'light', look: 'A blade hand swung back out across the chest, the back of the forearm leading.' },
  palm_rise: { like: 'spear_hand', limb: 'hand', target: 'gut', weight: 'light', look: 'The heel of an open palm lifted into the gut from a low crouch.' },
  edge_crescent: { like: 'snap_round', limb: 'foot', target: 'gut', weight: 'light', look: 'The edge of the foot swept out and round into the belly, the hands up and open.' },
  elbow_back: { like: 'short_elbow', limb: 'elbow', target: 'jaw', weight: 'light', look: 'The point of the elbow swung back and round to the jaw, no turn of the body.' },
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
  elbow_drop: { kind: 'elbow', target: 'chest', step_max: 16,
    chamber: { hand_r: [6, 78, 8], pole_hand_r: [-4, 14, 6], lean: 4, hips: [-2, -2, 0], spine: { lean: -2, twist: -12 } },
    contact: { family: 'upright_lunge', lean: 12, hips: [8, -5, 0], spine: { lean: 8, twist: 16 }, head: { pitch: 12 },
      hand_r: [20, 66, 6], pole_hand_r: [12, -4, 4], hand_l: [28, 60, -10], foot_r: [-8, 2.5, 9], foot_l: [14, 2.5, -7], ...OPEN },
    orig: 'the point of the elbow dropped short onto the chest, the other open hand holding the guard down' },
  palm_slap: { from: 'hook', kind: 'hand', family: 'hand_arc', target: 'head',
    contact: { family: 'upright_lunge', lean: 22, hips: [18, -4, 0], spine: { lean: 6, twist: 50, bend: -6 }, head: { pitch: 6, yaw: 6 },
      hand_r: [52, 74, 16], pole_hand_r: [2, -4, 14], hand_l: [14, 74, -8], foot_r: [-6, 2.5, 9], foot_l: [26, 2.5, -7], ...OPEN },
    orig: 'an open palm swung round on a wide arc to the head, the free hand up at his cheek' },
  palm_drop: { kind: 'hand', target: 'arm_r',
    chamber: { lean: -2, hips: [-2, -2, 0], spine: { lean: -4, twist: -8 }, hand_r: [8, 80, 10], pole_hand_r: [-4, 6, 8] },
    contact: { family: 'upright_lunge', lean: 14, hips: [12, -4, 0], spine: { lean: 10, twist: 16 }, head: { pitch: 10 },
      hand_r: [40, 62, 8], pole_hand_r: [0, 12, 6], hand_l: [14, 58, -8], foot_r: [-6, 2.5, 9], foot_l: [24, 2.5, -7], ...OPEN },
    orig: 'a flat palm brought down onto the rival arm, the elbow bent through it' },
  blade_back: { from: 'hook', kind: 'hand', family: 'hand_arc', target: 'chest',
    contact: { family: 'upright_lunge', lean: 14, hips: [18, -3, 0], spine: { lean: -2, twist: -34 }, head: { pitch: 2, yaw: -14 },
      hand_r: [48, 62, 12], pole_hand_r: [2, 8, 10], hand_l: [12, 58, -8], foot_r: [-6, 2.5, 9], foot_l: [26, 2.5, -7], ...OPEN },
    orig: 'a blade hand swung back out across the chest, the back of the forearm leading, the chest opened away' },
  palm_rise: { kind: 'hand', target: 'gut', step_max: 16,
    chamber: { family: 'crouched', lean: 12, hips: [2, -10, 0], spine: { lean: 8, twist: -14 }, hand_r: [16, 36, 10], pole_hand_r: [-8, -6, 8], hand_l: [22, 56, -8] },
    contact: { family: 'crouched', lean: 20, hips: [12, -10, 0], spine: { lean: 6, twist: 24 }, head: { pitch: 6 },
      hand_r: [46, 52, 8], pole_hand_r: [-4, -2, 8], hand_l: [12, 54, -6], foot_r: [-8, 2.5, 9], foot_l: [22, 2.5, -7], ...OPEN },
    orig: 'the heel of an open palm lifted into the gut from a low crouch, the other hand across the chest' },
  edge_crescent: { from: 'round', kind: 'foot', target: 'gut',
    over: { all: { ...OPEN }, chamber: { foot_r: [8, 34, 6] },
      contact: { lean: -4, hips: [14, -2, 0], spine: { lean: -2, twist: 16 }, foot_r: [40, 48, 16], hand_r: [8, 66, 14], hand_l: [20, 66, -10], foot_l: [14, 2.5, -7] },
      follow: { foot_r: [14, 28, 9] } },
    orig: 'the edge of the foot swept out and round into the belly, the hands up and open' },
  elbow_back: { kind: 'elbow', target: 'jaw', step_max: 16,
    chamber: { family: 'upright', lean: 4, hips: [-2, -2, 0], spine: { lean: 0, twist: 24 }, hand_r: [18, 66, 18], pole_hand_r: [4, 4, 14], hand_l: [20, 58, -8] },
    contact: { family: 'upright_lunge', lean: 8, hips: [8, -2, 0], spine: { lean: 2, twist: -22 }, head: { pitch: 2, yaw: -16 },
      hand_r: [10, 68, 14], pole_hand_r: [10, 2, 8], hand_l: [14, 58, -8], foot_r: [-6, 2.5, 9], foot_l: [16, 2.5, -7], ...OPEN },
    orig: 'the point of the elbow swung back and round to the jaw, no turn of the body' },
};
