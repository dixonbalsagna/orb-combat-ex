// The Anti-hero's right-stick class, parked (docs/animation/stick-class.md; Combat's list docs/combat/pending/stick/README.md "For Animation later"; the rulings docs/design/right-hand-attacks-rulings.md
// section 2): nine pieces of the class's own, a quick and a charged blow for each of the four directions and an air spike. Parked (--waves); nothing plays them live until Legal's go on the poses and the
// fighter's `more` list names this wave. His own identity: fists on the heavies and plates or blades on the lights, never a palm; straight lines, drops and rises, knees and elbows. Legal's lines
// (zip-screen.md): a rising blow keeps his feet down and no turn, its hand is never drawn back to a hip; a dropping blow is one fist, blade or plate, lowered at once (hold_t 1, ci_end 4); no leap, no clasp.
//
// The class's timing (rulings section 2): a quick blow lands on tick 12 from the request, a 10-tick wind-up: one motion. A charged blow is held at its CHAMBER by the stick (the held layer draws the key
// set's first key while the sim waits), so each charged piece's chamber IS the charge stance for its direction and has to read without a marker. The release is a 4-tick blow out of that chamber.
//   quick   up lift_fist       hand fist, rise, jaw       down skid_kick      foot sole, line, legs           toward short_ram    elbow point, line, gut     away swing_plate  hand plate, arc out, chest
//   charged up knee_launch     knee cap, rise, chest      down hammer_drop    hand fist, drop, head           toward plate_ram    hand plate, line, chest    away swing_elbow  elbow point, spin, head
//   air     spike_knee         knee cap, drop, head
// The charge stances: up is sunk low with the knee loaded and both fists down; down stands tall with one fist cocked beside the head, the elbow bent and back (never an arm straight up: a charge can be held for 68 ticks, Legal zip-screen section 4); toward is turned side-on, the weight back and the forearm drawn
// behind the shoulder, the other hand out toward him; away is wound right round, the elbow cocked and the back half to him.
const LUNGE = { foot_r: [-6, 2.5, 9], foot_l: [26, 2.5, -7] };
// Legal RL-218: the Anti-hero's hands are closed fists in every piece of this wave (no open hand to read as a palm): OPEN is the fist pair here
const OPEN = { hands: { r: 'fist', l: 'fist' } };
const FIST = { hands: { r: 'fist', l: 'fist' } };

const Q = { load: 10, follow: 4, recover: 4 };
const C = { load: 4, follow: 6, recover: 10 };

const NEW = {
  lift_fist: { like: 'uppercut', limb: 'hand', target: 'jaw', weight: 'light', ticks: Q, look: 'A short fist rising under the chin from a half crouch, the feet planted and the arm lowering at once.' },
  skid_kick: { like: 'low_kick', limb: 'foot', target: 'legs', weight: 'light', ticks: Q, look: 'The sole skidded straight along the ground into the shins, the standing leg firm and the fists up.' },
  short_ram: { like: 'short_elbow', limb: 'elbow', target: 'gut', weight: 'light', ticks: Q, look: 'The point of the elbow driven straight into the gut, the shoulder behind it, the other hand reaching out ahead.' },
  swing_plate: { like: 'hook', limb: 'hand', target: 'chest', weight: 'light', ticks: Q, look: 'The plate of the forearm swung out wide across the chest in a turn of the body, the chest opening away as it pushes past.' },
  knee_launch: { like: 'rising_knee', limb: 'knee', target: 'chest', weight: 'heavy', ticks: C, look: 'Sunk low with the knee loaded and both fists down, then the knee driven up into the chest and the whole body rising behind it.' },
  hammer_drop: { like: 'hammer', limb: 'hand', target: 'chest', weight: 'heavy', ticks: C, look: 'Tall with one fist cocked beside the head, the elbow bent and back, then brought down onto the chest in one stroke and lowered at once.' },
  plate_ram: { like: 'cross_arm_ram', limb: 'hand', target: 'chest', weight: 'heavy', ticks: C, look: 'Side-on with the weight back and the forearm drawn behind the shoulder, then the plate of the forearm rammed into the chest with a full lunge.' },
  swing_elbow: { like: 'spinning_elbow', limb: 'elbow', target: 'chest', weight: 'heavy', ticks: C, look: 'Wound right round with the elbow cocked and his back half to him, then the point of the elbow swung through to the chest in a full turn.' },
  spike_knee: { like: 'stomp', limb: 'knee', target: 'chest', weight: 'light', ticks: Q, ground: 'no', look: 'In the air: the knee drawn up, then driven straight down onto the chest of the rival below, the fists out for the balance.' },
};
export function rows(wave1) {
  const by = Object.fromEntries(wave1.map(r => [r.id.replace('strike.', ''), r]));
  return Object.entries(NEW).map(([n, o]) => {
    const b = by[o.like];
    return { ...b, id: 'strike.' + n, limb: o.limb, target: o.target, weight: o.weight, ticks: { ...o.ticks }, ...(o.ground ? { ground: o.ground } : {}), look: o.look, _estimate: 'range borrowed from strike.' + o.like + ' until Combat\'s rows land; ticks are the class\'s (rulings section 2)' };
  });
}

export const strikes = {
  // ---- up
  lift_fist: { from: 'upper', kind: 'hand', target: 'jaw', named: true, hold_t: 1, ci_end: 4, legal: ['no_leap', 'no_held_raise'],
    over: { all: { ...FIST }, chamber: { family: 'crouched', lean: 14, hips: [0, -10, 0], spine: { lean: 6, twist: -12 }, hand_r: [22, 34, 10], hand_l: [24, 54, -8] },
      contact: { lean: 8, hips: [12, -2, 0], spine: { lean: -4, twist: 18 }, hand_r: [47, 78, 8], hand_l: [28, 56, -8] }, follow: { hand_r: [34, 70, 8], hand_l: [26, 56, -8] } },
    orig: 'a short fist rising under the chin from a half crouch, the feet planted and the arm lowering at once' },
  knee_launch: { kind: 'knee', target: 'chest', step_max: 16, named: true, hold_w: 0.25,
    chamber: { family: 'crouched', lean: 18, hips: [0, -14, 0], spine: { lean: 10, twist: -8 }, head: { pitch: 10 }, hand_r: [20, 38, 10], hand_l: [22, 42, -8], foot_r: [0, 6, 8], pole_foot_r: [10, 1, 0], foot_l: [8, 2.5, -7], ...FIST },
    contact: { family: 'upright_lunge', lean: -6, hips: [6, 4, 0], spine: { lean: -2 }, head: { pitch: -2 }, hand_r: [22, 48, 10], hand_l: [24, 50, -10], foot_r: [26, 30, 8], pole_foot_r: [10, 1, 0], foot_l: [6, 5, -7], ...FIST },
    orig: 'sunk low with the knee loaded and both fists down, then the knee driven up into the chest and the whole body rising behind it' },
  // ---- down
  skid_kick: { kind: 'foot', target: 'legs', step_max: 16, named: true,
    chamber: { foot_r: [6, 26, 10] },
    contact: { family: 'upright_lunge', lean: 8, hips: [12, -4, 0], spine: { lean: 4, twist: 8 }, head: { pitch: 8 }, hand_r: [28, 58, 14], hand_l: [26, 60, -10], foot_r: [41, 13, 8], foot_l: [12, 2.5, -7], ...FIST },
    follow: { hand_r: [26, 57, 14] },
    orig: 'the sole skidded straight along the ground into the shins, the standing leg firm and the fists up' },
  hammer_drop: { kind: 'hand', target: 'chest', step_max: 14, named: true, hold_w: 0.25, hold_t: 1, ci_end: 4, legal: ['no_clasp', 'no_leap'],
    chamber: { family: 'upright', lean: -6, hips: [-4, 0, 0], spine: { lean: -8, twist: -8 }, head: { pitch: -6 }, hand_r: [6, 74, 10], pole_hand_r: [-12, 48, 8], hand_l: [24, 58, -10], foot_r: [-12, 2.5, 10], foot_l: [12, 3.5, -8], ...FIST },
    contact: { family: 'upright_lunge', lean: 24, hips: [16, -6, 0], spine: { lean: 14, twist: 12 }, head: { pitch: 16 }, hand_r: [46, 68, 6], pole_hand_r: [-4, 10, 8], hand_l: [44, 52, -8], ...LUNGE, ...FIST },
    follow: { hand_r: [32, 54, 8], pole_hand_r: [2, 6, 6], hand_l: [38, 52, -8] },
    orig: 'tall with one fist cocked beside the head, the elbow bent and back, then brought down onto the chest in one stroke and lowered at once' },
  // ---- toward
  short_ram: { kind: 'elbow', target: 'gut', step_max: 14, named: true, legal: ['no_leap'],
    chamber: { family: 'upright', lean: 8, hips: [-2, -4, 0], spine: { lean: 4, twist: -30 }, head: { pitch: 6, yaw: 8 }, hand_r: [8, 58, 11], pole_hand_r: [-10, 2, 10], hand_l: [22, 56, -7], foot_r: [-10, 2.5, 9], foot_l: [12, 2.5, -7], ...OPEN },
    contact: { family: 'upright_lunge', lean: 16, hips: [16, -6, 0], spine: { lean: 6, twist: 30 }, head: { pitch: 8 }, hand_r: [35, 54, 4], pole_hand_r: [14, 0, 4], hand_l: [36, 58, -10], foot_r: [-8, 2.5, 9], foot_l: [24, 2.5, -7], ...OPEN },
    follow: { hand_r: [34, 55, 8] },
    orig: 'the point of the elbow driven straight into the gut, the shoulder behind it, the other hand reaching out ahead' },
  plate_ram: { kind: 'hand', target: 'chest', step_max: 20, named: true, hold_w: 0.25, legal: ['no_leap', 'not_both_arms_back', 'wrists_apart'],
    chamber: { family: 'upright', lean: -4, hip_twist: 26, hips: [-6, -8, 0], spine: { lean: 0, twist: -24 }, head: { pitch: 2, yaw: 16 }, hand_r: [-2, 60, 20], pole_hand_r: [-14, 10, 18], hand_l: [26, 59, -10], foot_r: [-16, 2.5, 10], foot_l: [17, 3.5, -8], ...FIST },
    contact: { family: 'upright_lunge', lean: 18, hip_twist: 10, hips: [22, -8, 0], spine: { lean: 6, twist: 20 }, head: { pitch: 4 }, hand_r: [58, 60, 8], pole_hand_r: [4, 2, 8], hand_l: [40, 56, -12], foot_r: [-3.5, 4, 9], foot_l: [30, 2.5, -7], ...FIST },
    follow: { hand_l: [32, 54, -8] },
    orig: 'side-on with the weight back and the forearm drawn behind the shoulder, then the plate of the forearm rammed into the chest with a full lunge' },
  // ---- away
  swing_plate: { from: 'hook', kind: 'hand', family: 'hand_arc', target: 'chest', named: true, legal: ['no_clasp', 'no_leap'],
    over: { all: { ...OPEN },
      chamber: { hip_twist: -20, hand_r: [14, 62, -6], pole_hand_r: [-4, 4, -4], hand_l: [24, 54, -8], spine: { lean: 2, twist: -38 }, head: { yaw: 14 } },
      contact: { hip_twist: 30, lean: 8, hips: [14, -3, 0], spine: { lean: 0, twist: 36 }, head: { yaw: -18 }, hand_r: [42, 60, 26], pole_hand_r: [6, 6, 16], hand_l: [26, 54, -10], foot_r: [-4.5, 4, 9] },
      follow: { hand_r: [26, 58, 20], hand_l: [30, 57, -6] } },
    orig: 'the plate of the forearm swung out wide across the chest in a turn of the body, the chest opening away as it pushes past' },
  swing_elbow: { kind: 'elbow', target: 'chest', step_max: 14, named: true, hold_w: 0.25, legal: ['no_leap', 'single_turn'],
    chamber: { family: 'upright', lean: 8, hips: [-2, -4, 0], spine: { lean: 4, twist: -50 }, head: { pitch: 6, yaw: 8 }, hand_r: [8, 62, 11], pole_hand_r: [-10, 2, 10], hand_l: [42, 56, -7], foot_r: [-10, 2.5, 9], foot_l: [12, 2.5, -7], hip_twist: -24, ...OPEN },
    contact: { family: 'upright_lunge', lean: 10, hip_twist: 40, hips: [8, -2, 0], spine: { lean: 2, twist: 60 }, head: { pitch: 4, yaw: -30 }, hand_r: [30, 68, 12], pole_hand_r: [6, 2, 10], hand_l: [-8, 58, -14], foot_r: [-6, 2.5, 9], foot_l: [10, 2.5, -7], ...OPEN },
    follow: { hand_l: [12, 57, -11], hand_r: [35, 63, 12.5] },
    orig: 'wound right round with the elbow cocked and his back half to him, then the point of the elbow swung through to the chest in a full turn' },
  // ---- the air spike
  spike_knee: { kind: 'knee', target: 'chest', step_max: 10, named: true, hold_t: 1, ci_end: 4, legal: ['no_clasp'],
    chamber: { family: 'airborne_neutral', lean: 4, hips: [0, 12, 0], spine: { lean: 2, twist: -6 }, head: { pitch: 6 }, hand_r: [16, 62, 14], hand_l: [20, 60, -12], foot_r: [6, 34, 10], pole_foot_r: [10, 1, 0], foot_l: [2, 14, -7], ...FIST },
    contact: { family: 'airborne_neutral', lean: -10, hips: [8, 14, 0], spine: { lean: -4, twist: 6 }, head: { pitch: 8 }, hand_r: [8, 66, 20], hand_l: [22, 62, -14], foot_r: [18, 22, 8], pole_foot_r: [10, 1, 0], foot_l: [-4, 22, -7], ...FIST },
    follow: { foot_r: [10, 20, 8] },
    orig: 'in the air: the knee drawn up, then driven straight down onto the chest of the rival below, the fists out for the balance' },
};
