// The right stick's beam poses, parked (docs/animation/stick-class.md; Combat's list "A beam-firing pose by aim: up and down at 45 degrees and behind him" and "A snap-beam pose"; the rulings
// docs/design/right-hand-attacks-rulings.md section 3: RB + stick is the beam, the aim latched at the settle: toward is at him, up and down are 45 degrees, away is behind him; level 0 is the snap-beam).
// Parked (--waves); read by AnimFighter._beam_layer from data/anim/pair_live.json `roles.<fighter>.beam` (`fire_up`, `fire_down`, `fire_back`, `snap`) when the ids are there, and nothing changes when they are not.
// Legal's franchise rule for a cast stands (beam1.mjs): ONE hand, open or closed, nothing held in it, between the hands or at the hip, never a ball charging in a palm, wrists apart, the other hand never
// cupped; the Protagonist's beam leaves the HEEL of the open palm, the Anti-hero's the fist with the forearm plate behind it. Prefix bn.
//   fire_up      the arm thrown up and forward at 45 degrees, the chest opened under it, the weight on the rear foot
//   fire_down    the arm thrown down and forward at 45 degrees, the body folded over it, the head following the line
//   fire_back    the beam goes behind him: the body turned right round on the spot with the arm thrown out past the shoulder along the line, the other hand open and low in front
//   snap         the snap-beam: a short flat snap from the shoulder, elbow tucked, no lunge: the quick one
const OPEN = { hands: { r: 'open', l: 'open' } };
// Legal RL-218: the Anti-hero's hands are closed fists (no open hand to read as a palm)
const FIST = { hands: { r: 'fist', l: 'fist' } };
const WIDE = { foot_r: [-14, 2.5, 10], foot_l: [14, 2.5, -8] };

export const holds = {
  fire_up_protagonist: { sketch: { family: 'upright_lunge', lean: -4, hip_twist: 14, hips: [10, -8, 0], spine: { lean: -12, twist: 14 }, head: { pitch: -10, yaw: 4 }, hand_r: [35, 78, 9], pole_hand_r: [10, 60, 8], hand_l: [26, 44, -12],
      foot_r: [-12, 2.5, 10], foot_l: [20, 2.5, -8], ...OPEN, _legal: ['hands_open_or_claw', 'not_at_hip', 'wrists_apart'] },
    orig: 'PROVISIONAL: the Protagonist casting up: the arm thrown up and forward at 45 degrees with the heel of the open palm leading, the chest opened under it, the other hand open and low' },
  fire_down_protagonist: { sketch: { family: 'upright_lunge', lean: 22, hip_twist: 18, hips: [16, -12, 0], spine: { lean: 14, twist: 14 }, head: { pitch: 14, yaw: 4 }, hand_r: [57, 36, 9], pole_hand_r: [8, 40, 8], hand_l: [12, 62, -12],
      foot_r: [-12, 2.5, 10], foot_l: [26, 2.5, -8], ...OPEN, _legal: ['hands_open_or_claw', 'not_at_hip', 'wrists_apart'] },
    orig: 'PROVISIONAL: the Protagonist casting down: the arm thrown down and forward at 45 degrees, the heel of the palm leading, the body folded over it, the other hand open and up behind' },
  fire_back_protagonist: { sketch: { family: 'upright', lean: 2, hip_twist: -50, hips: [-2, -8, 0], spine: { lean: 4, twist: -70 }, head: { pitch: 0, yaw: 50 }, hand_r: [-28.4, 58, 18.5], pole_hand_r: [-14, 52, 12], hand_l: [29, 56, -4.4],
      foot_r: [-12, 2.5, 10], foot_l: [14, 2.5, -8], ...OPEN, _legal: ['hands_open_or_claw', 'not_at_hip', 'wrists_apart', 'single_turn'] },
    orig: 'PROVISIONAL: the Protagonist casting behind him: turned right round on the spot, the arm thrown out past the shoulder along the line with the heel of the palm leading, the other hand open in front' },
  snap_protagonist: { sketch: { family: 'upright', lean: 8, hip_twist: 12, hips: [6, -6, 0], spine: { lean: 4, twist: 12 }, head: { pitch: 0, yaw: 4 }, hand_r: [40, 62, 10], pole_hand_r: [4, 6, 10], hand_l: [24, 56, -10],
      ...WIDE, ...OPEN, _legal: ['hands_open_or_claw', 'not_at_hip', 'wrists_apart'] },
    orig: 'PROVISIONAL: the Protagonist snapping a short beam: the open palm flicked flat from the shoulder, the elbow tucked, the weight planted, no lunge' },
  fire_up_antihero: { sketch: { family: 'upright_lunge', lean: -4, hip_twist: 16, hips: [10, -8, 0], spine: { lean: -12, twist: 16 }, head: { pitch: -10, yaw: 4 }, hand_r: [35, 78, 8], pole_hand_r: [10, 60, 8], hand_l: [26, 44, -12],
      foot_r: [-12, 2.5, 10], foot_l: [20, 2.5, -8], ...FIST, _legal: ['not_at_hip', 'wrists_apart'] },
    orig: 'PROVISIONAL: the Anti-hero casting up: the fist driven up and forward at 45 degrees, the forearm plate behind it, the chest opened under it, the other hand open and low' },
  fire_down_antihero: { sketch: { family: 'upright_lunge', lean: 22, hip_twist: 20, hips: [16, -12, 0], spine: { lean: 14, twist: 18 }, head: { pitch: 14, yaw: 4 }, hand_r: [60, 36, 8], pole_hand_r: [8, 40, 8], hand_l: [12, 62, -12],
      foot_r: [-12, 2.5, 10], foot_l: [26, 2.5, -8], ...FIST, _legal: ['not_at_hip', 'wrists_apart'] },
    orig: 'PROVISIONAL: the Anti-hero casting down: the fist driven down and forward at 45 degrees, the forearm plate behind it, the body folded over, the other hand open and up behind' },
  fire_back_antihero: { sketch: { family: 'upright', lean: 2, hip_twist: -50, hips: [-2, -8, 0], spine: { lean: 4, twist: -70 }, head: { pitch: 0, yaw: 50 }, hand_r: [-28.4, 58, 18.5], pole_hand_r: [-14, 52, 12], hand_l: [29, 56, -4.4],
      foot_r: [-12, 2.5, 10], foot_l: [14, 2.5, -8], ...FIST, _legal: ['not_at_hip', 'wrists_apart', 'single_turn'] },
    orig: 'PROVISIONAL: the Anti-hero casting behind him: turned right round on the spot, the fist driven out past the shoulder along the line, the forearm plate behind it, the other hand open in front' },
  snap_antihero: { sketch: { family: 'upright', lean: 8, hip_twist: 14, hips: [6, -6, 0], spine: { lean: 4, twist: 14 }, head: { pitch: 0, yaw: 4 }, hand_r: [40, 63, 9], pole_hand_r: [4, 6, 10], hand_l: [24, 56, -8],
      ...WIDE, ...FIST, _legal: ['not_at_hip', 'wrists_apart'] },
    orig: 'PROVISIONAL: the Anti-hero snapping a short beam: the fist driven flat from the shoulder, the elbow tucked, the weight planted, no lunge' },
};

export const sequences = {};
