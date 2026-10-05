// The rival's two signature sketches of the first moveset slice (docs/combat/moveset-generator.md sections 3.2 and 6.1: the martial arts signature is a rush of his own strikes that ends in a launch):
// the tell the frame opens with (at least 30 ticks) and the held end after the launcher. Held poses are screened by eye every time (Legal): no hand chambered at the hip, no crossed arms,
// no arm held raised after a blow. Parked (--waves): nothing plays them live until the signature frame's slots land (Encounter).
const OPEN = { hands: { r: 'open', l: 'open' } };
export const holds = {
  // weight sunk onto the rear leg and the body turned side-on, the lead blade hand out at eye height as if measuring the distance, the rear hand folded at the chest, the head low
  sig_tell: { sketch: { family: 'crouched', lean: 10, hips: [-6, -10, 0], spine: { lean: 6, twist: -20 }, head: { pitch: 4, yaw: 4 }, hand_r: [29, 64, 10], pole_hand_r: [4, 4, 8], hand_l: [14, 52, -8],
      foot_r: [-12, 2.5, 9], foot_l: [16, 2.5, -7], ...OPEN, _legal: ['hands_open_or_claw', 'not_at_hip'] },
    orig: 'the tell: weight sunk onto the rear leg, the body turned side-on, the lead blade hand out at eye height measuring the distance, the other hand folded at his chest, the head low' },
  // the launcher thrown: the striking arm lowered and open, the other hand at the chest, the weight settled, the head turned up after the rival
  sig_end: { sketch: { family: 'upright', lean: -2, hips: [2, -2, 0], spine: { lean: -2, twist: 10 }, head: { pitch: -8, yaw: 6 }, hand_r: [16, 44, 12], hand_l: [10, 54, -8],
      foot_r: [-8, 2.5, 9], foot_l: [10, 2.5, -7], ...OPEN, _legal: ['hands_open_or_claw', 'not_at_hip'] },
    orig: 'the held end: the striking arm lowered and open, the other hand at his chest, the weight settled, the head turned up after the rival' },
};
// the two as sequences too, so the signature frame can play them as they are: the tell held 36 ticks, the end held 24 (the frame's own timing is Encounter's)
export const sequences = {
  tell: { dur: 36, legal: ['hands_open_or_claw'], phases: [{ id: 'coil', ticks: 36, sketch: holds.sig_tell.sketch, orig: holds.sig_tell.orig }] },
  end: { dur: 24, legal: ['hands_open_or_claw'], phases: [{ id: 'settle', ticks: 24, sketch: holds.sig_end.sketch, orig: holds.sig_end.orig }] },
};
export const cues = {};
