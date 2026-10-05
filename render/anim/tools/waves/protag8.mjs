// The Protagonist's two signature sketches of the first moveset slice (docs/combat/moveset-generator.md sections 3.2 and 6.1): the tell the frame opens with (at least 30 ticks) and the held
// end after the launcher. Open hands only (no claw), no hand chambered at the hip, no crossed arms, no arm held raised after a blow. Held poses are screened by eye every time (Legal).
// Parked (--waves): nothing plays them live until the signature frame's slots land (Encounter).
const OPEN = { hands: { r: 'open', l: 'open' } };
export const holds = {
  // the open hands low and wide with the palms down, the knees bent, the weight on the front foot: a circling step coiled before it goes
  sig_tell: { sketch: { family: 'crouched', lean: 6, hips: [4, -8, 0], spine: { lean: 4, twist: 10 }, head: { pitch: 6 }, hand_r: [26, 46, 22], hand_l: [22, 46, -20],
      foot_r: [-10, 2.5, 11], foot_l: [18, 2.5, -9], ...OPEN, _legal: ['hands_open_or_claw', 'not_at_hip'] },
    orig: 'the tell: the open hands low and wide with the palms down, the knees bent, the weight on the front foot, a circling step coiled before it goes' },
  // after the launcher: the feet settled, the open hands loose at his sides, a slight bow of the head toward the rival
  sig_end: { sketch: { family: 'upright', lean: 0, hips: [0, -2, 0], spine: { lean: 2, twist: 0 }, head: { pitch: 12 }, hand_r: [18, 42, 14], hand_l: [18, 42, -12],
      foot_r: [-6, 2.5, 9], foot_l: [6, 2.5, -7], ...OPEN, _legal: ['hands_open_or_claw', 'not_at_hip'] },
    orig: 'the held end: the feet settled, the open hands loose at his sides, a slight bow of the head toward the rival' },
};
// the two as sequences too, so the signature frame can play them as they are: the tell held 36 ticks, the end held 24 (the frame's own timing is Encounter's)
export const sequences = {
  tell: { dur: 36, legal: ['hands_open_or_claw'], phases: [{ id: 'coil', ticks: 36, sketch: holds.sig_tell.sketch, orig: holds.sig_tell.orig }] },
  end: { dur: 24, legal: ['hands_open_or_claw'], phases: [{ id: 'settle', ticks: 24, sketch: holds.sig_end.sketch, orig: holds.sig_end.orig }] },
};
export const cues = {};
