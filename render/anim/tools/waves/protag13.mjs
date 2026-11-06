// The Protagonist's right-stick class, parked (docs/animation/stick-class.md; Combat's list docs/combat/pending/stick/README.md "For Animation later"; the rulings docs/design/right-hand-attacks-rulings.md
// section 2): nine pieces of the class's own, a quick and a charged blow for each of the four directions and an air spike. Parked (--waves); nothing plays them live until Legal's go on the poses
// and the fighter's `more` list names this wave. His own sketches (open hands, palms and blades, heels, round arcs, the edge of the foot). Legal's lines (zip-screen.md): a palm is a blow only, never
// chambered at a hip and never held up after it; a rising blow keeps his feet down and no turn; a dropping blow is one fist or blade, lowered at once (hold_t 1, ci_end 4); no leap, no clasp.
//
// The class's timing (rulings section 2): a quick blow lands on tick 9 from the request, a 7-tick wind-up (Game Design's ruling, data/director/stick.json windTicks 7; it was 10); it is a flick, one motion. A charged blow is held at its CHAMBER by the stick (the held
// layer draws the key set's first key while the sim waits), so each charged piece's chamber IS the charge stance for its direction, and it has to read without a marker: the silhouette says
// which way the blow goes. The release is a 4-tick blow that blends out of that chamber.
//   quick   up flick_rise      hand palm, rise, jaw       down scythe_sweep   foot edge, arc out, shins       toward heel_thrust  hand palm, line, gut       away wheel_blade  hand blade, arc out, chest
//   charged up lifting_heave   hand palm, rise, chest     down plunge_blade   hand blade, drop, head          toward drive_palm   hand palm, line, chest     away turning_edge foot edge, spin, chest
//   air     spike_heel         foot heel, drop, head
// The charge stances: up is sunk low with the near palm low and forward under him (never at the hip); down stands tall on the rear foot with the blade hand cocked beside the head, the elbow bent and back (never an arm straight up: a charge can be held for 68 ticks, Legal zip-screen section 4); toward is turned
// side-on with the weight back and the palm drawn to the shoulder, the other hand out toward him; away is wound right round with his back half to him and the head over the shoulder.
const OPEN = { hands: { r: 'open', l: 'open' } };
const FIST = { hands: { r: 'fist', l: 'open' } };
const LEGAL_PALM = ['hands_open_or_claw', 'not_at_hip', 'no_leap'];

const Q = { load: 7, follow: 4, recover: 4 };   // the quick blow: the 7-tick wind-up, 11 from the request with the recovery
const C = { load: 4, follow: 6, recover: 10 };   // the charged release: the 4-tick blow out of the held chamber

const NEW = {
  flick_rise: { like: 'uppercut', limb: 'hand', target: 'jaw', weight: 'light', ticks: Q, look: 'A flick of the open palm up under the chin from a loose stand, the wrist snapping it, the feet planted and the arm lowering at once.' },
  scythe_sweep: { like: 'sweep', limb: 'foot', target: 'shins', weight: 'light', ticks: Q, look: 'The edge of the foot scythed out low across the shins from a crouch, one hand down for the balance.' },
  heel_thrust: { like: 'spear_hand', limb: 'hand', target: 'gut', weight: 'light', ticks: Q, look: 'The heel of the palm driven straight into the belly from the shoulder, the weight going in behind it.' },
  wheel_blade: { like: 'backfist', limb: 'hand', target: 'chest', weight: 'light', ticks: Q, look: 'A blade hand swung out wide across the chest in a turn of the whole body, the chest opening away as it pushes past.' },
  lifting_heave: { like: 'uppercut', limb: 'hand', target: 'chest', weight: 'heavy', ticks: C, look: 'Sunk low with the palm under him, then the heel of the palm heaved up into the chest and the whole body rising behind it.' },
  plunge_blade: { like: 'hammer', limb: 'hand', target: 'chest', weight: 'heavy', ticks: C, look: 'Tall on the rear foot with the blade hand cocked beside the head, the elbow bent and back, then brought down onto the chest in one stroke and lowered at once.' },
  drive_palm: { like: 'spear_hand', limb: 'hand', target: 'chest', weight: 'heavy', ticks: C, look: 'Side-on with the weight back and the palm at the shoulder, then the heel of the palm driven into the chest with a full lunge behind it.' },
  turning_edge: { like: 'roundhouse', limb: 'foot', target: 'chest', weight: 'heavy', ticks: C, look: 'Wound right round with his back half to him, then the edge of the foot swung through in a full turn that carries the rival past.' },
  spike_heel: { like: 'axe_kick', limb: 'foot', target: 'chest', weight: 'light', ticks: Q, ground: 'no', look: 'In the air: the knee drawn up, then the heel stabbed straight down onto the chest of the rival below, the hands open and out for the balance.' },
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
  flick_rise: { from: 'upper', kind: 'hand', target: 'jaw', named: true, hold_t: 1, ci_end: 4, legal: [...LEGAL_PALM, 'no_held_raise'],
    over: { all: { ...OPEN }, chamber: { family: 'upright', lean: 6, hips: [0, -4, 0], spine: { lean: 4, twist: -10 }, hand_r: [26, 40, 12], hand_l: [20, 58, -8] },
      contact: { lean: 6, hips: [10, 0, 0], spine: { lean: -2, twist: 12 }, head: { pitch: -8 }, hand_r: [43, 82, 8], foot_r: [-7, 4.5, 9], foot_l: [20, 2.5, -7] },
      follow: { lean: 4, hips: [6, -1, 0], hand_r: [30, 68, 8] } },
    orig: 'a flick of the open palm up under the chin from a loose stand, the wrist snapping it, the feet planted and the arm lowering at once' },
  lifting_heave: { from: 'upper', kind: 'hand', target: 'chest', named: true, hold_w: 0.25, hold_t: 1, ci_end: 4, legal: [...LEGAL_PALM, 'no_held_raise'],
    over: { all: { ...OPEN },
      chamber: { family: 'crouched', lean: 22, hips: [2, -16, 0], spine: { lean: 12, twist: -14 }, head: { pitch: 12 }, hand_r: [24, 20, 12], pole_hand_r: [-4, -4, 10], hand_l: [26, 48, -8], foot_r: [-12, 2.5, 10], foot_l: [14, 2.5, -8] },
      contact: { lean: 10, hips: [16, -6, 0], spine: { lean: 2, twist: 20 }, head: { pitch: -2 }, hand_r: [52, 66, 8], pole_hand_r: [-2, 4, 8], hand_l: [31, 56, -8] },
      follow: { lean: 6, hips: [9, -3, 0], spine: { lean: -2, twist: 12 }, hand_r: [34, 62, 8], hand_l: [22, 56, -8] } },
    orig: 'sunk low with the palm under him, then the heel of the palm heaved up into the chest and the whole body rising behind it' },
  // ---- down
  scythe_sweep: { kind: 'foot', target: 'shins', step_max: 14, named: true, legal: ['hands_open_or_claw', 'no_leap'],
    chamber: { family: 'crouched', lean: 20, hips: [0, -20, 0], spine: { lean: 12, twist: -6 }, head: { pitch: 4, yaw: 6 }, hand_r: [18, 38, 14], hand_l: [20, 8, -10], foot_r: [-4, 4, 12], foot_l: [4, 2.5, -8] },
    contact: { family: 'crouched', lean: 34, hips: [6, -26, 0], spine: { lean: 20, twist: 10 }, head: { pitch: 14 }, hand_r: [12, 40, 18], hand_l: [26, 4, -10], foot_r: [34, 6, 18], foot_l: [-2, 3, -8], ...OPEN },
    orig: 'the edge of the foot scythed out low across the shins from a crouch, one hand down for the balance' },
  plunge_blade: { kind: 'hand', target: 'chest', step_max: 14, named: true, hold_w: 0.25, hold_t: 1, ci_end: 4, legal: ['no_clasp', 'no_leap', 'wrists_apart'],
    chamber: { family: 'upright', lean: -8, hips: [-4, 0, 0], spine: { lean: -10, twist: -8 }, head: { pitch: -4 }, hand_r: [4, 74, 12], pole_hand_r: [-14, 50, 10], hand_l: [24, 58, -10], foot_r: [-12, 2.5, 10], foot_l: [12, 3.5, -8], ...OPEN },
    contact: { family: 'upright_lunge', lean: 22, hips: [14, -6, 0], spine: { lean: 14, twist: 12 }, head: { pitch: 14 }, hand_r: [44, 66, 8], pole_hand_r: [-2, 14, 6], hand_l: [36, 54, -8], foot_r: [-8, 2.5, 9], foot_l: [24, 2.5, -7], ...OPEN },
    follow: { hand_r: [30, 52, 9], pole_hand_r: [4, 6, 6], hand_l: [32, 54, -8] },
    orig: 'tall on the rear foot with the blade hand cocked beside the head, the elbow bent and back, then brought down onto the chest in one stroke and lowered at once' },
  // ---- toward
  heel_thrust: { kind: 'hand', target: 'gut', step_max: 16, named: true, hold_t: 1, legal: LEGAL_PALM,
    chamber: { family: 'upright', lean: 4, hips: [-2, -6, 0], spine: { lean: 2, twist: -16 }, head: { pitch: 2 }, hand_r: [10, 60, 16], pole_hand_r: [-10, 8, 12], hand_l: [22, 54, -8], foot_r: [-12, 2.5, 10], foot_l: [14, 2.5, -8], ...OPEN },
    contact: { family: 'upright_lunge', lean: 12, hips: [14, -6, 0], spine: { lean: 4, twist: 16 }, head: { pitch: 6 }, hand_r: [50, 52, 8], pole_hand_r: [-2, 0, 8], hand_l: [29, 56, -8], foot_r: [-8, 2.5, 9], foot_l: [24, 2.5, -7], ...OPEN },
    follow: { hand_l: [22, 56, -8] },
    orig: 'the heel of the palm driven straight into the belly from the shoulder, the weight going in behind it' },
  drive_palm: { kind: 'hand', target: 'chest', step_max: 20, named: true, hold_w: 0.25, hold_t: 1, legal: [...LEGAL_PALM, 'not_both_arms_back', 'wrists_apart'],
    chamber: { family: 'upright', lean: -4, hip_twist: 26, hips: [-6, -8, 0], spine: { lean: 0, twist: -24 }, head: { pitch: 2, yaw: 16 }, hand_r: [-2, 62, 20], pole_hand_r: [-14, 10, 18], hand_l: [25, 59, -10], foot_r: [-16, 2.5, 10], foot_l: [17, 3.5, -8], ...OPEN },
    contact: { family: 'upright_lunge', lean: 18, hip_twist: 10, hips: [22, -8, 0], spine: { lean: 6, twist: 20 }, head: { pitch: 4 }, hand_r: [58, 62, 8], pole_hand_r: [4, 2, 8], hand_l: [40, 56, -12], foot_r: [-3.5, 4, 9], foot_l: [30, 2.5, -7], ...OPEN },
    follow: { hand_l: [32, 54, -8] },
    orig: 'side-on with the weight back and the palm at the shoulder, then the heel of the palm driven into the chest with a full lunge behind it' },
  // ---- away
  wheel_blade: { from: 'hook', kind: 'hand', family: 'hand_arc', target: 'chest', named: true, legal: ['hands_open_or_claw', 'no_clasp'],
    over: { all: { ...OPEN },
      chamber: { hip_twist: -20, hand_r: [14, 62, -6], pole_hand_r: [-4, 4, -4], hand_l: [24, 54, -8], spine: { lean: 2, twist: -38 }, head: { yaw: 14 } },
      contact: { hip_twist: 30, lean: 8, hips: [12, -3, 0], spine: { lean: 0, twist: 36 }, head: { yaw: -18 }, hand_r: [40, 60, 26], pole_hand_r: [6, 6, 16], hand_l: [24, 54, -10] },
      follow: { hand_r: [26, 58, 20], hand_l: [30, 57, -6] } },
    orig: 'a blade hand swung out wide across the chest in a turn of the whole body, the chest opening away as it pushes past' },
  turning_edge: { kind: 'foot', target: 'chest', step_max: 18, named: true, hold_w: 0.25, legal: ['hands_open_or_claw', 'no_clasp'],
    chamber: { family: 'upright', lean: -6, hip_twist: -34, hips: [-2, -3, 0], spine: { lean: -4, twist: -52 }, head: { pitch: 2, yaw: 24 }, hand_r: [13, 58, 12], hand_l: [16, 59.5, -10], foot_r: [-6, 26, 12], foot_l: [2, 2.5, -7], ...OPEN },
    contact: { family: 'upright_lunge', lean: -12, hip_twist: 74, hips: [12, -1, 0], spine: { lean: -4, twist: 62 }, head: { yaw: -40 }, hand_r: [2, 63, 15], hand_l: [19.5, 60, -16], foot_r: [44, 47, 16], foot_l: [6, 2.5, -7], ...OPEN },
    follow: { hand_r: [16, 60, 16] },
    orig: 'wound right round with his back half to him, then the edge of the foot swung through in a full turn that carries the rival past' },
  // ---- the air spike
  spike_heel: { kind: 'foot', target: 'chest', step_max: 10, named: true, hold_t: 1, ci_end: 4, legal: ['hands_open_or_claw'],
    chamber: { family: 'airborne_neutral', lean: 4, hips: [0, 12, 0], spine: { lean: 2, twist: -6 }, head: { pitch: 6 }, hand_r: [14, 66, 16], hand_l: [18, 62, -12], foot_r: [6, 34, 10], foot_l: [2, 14, -7], ...OPEN },
    contact: { family: 'airborne_neutral', lean: -16, hips: [10, 14, 0], spine: { lean: -8, twist: 6 }, head: { pitch: 8 }, hand_r: [4, 70, 20], hand_l: [20, 66, -14], foot_r: [24, 16, 8], foot_l: [-4, 22, -7], ...OPEN },
    follow: { foot_r: [13, 8, 8] },
    orig: 'in the air: the knee drawn up, then the heel stabbed straight down onto the chest of the rival below, the hands open and out for the balance' },
};
