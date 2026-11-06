// The beam's shove (Encounter's beam-hold park, docs/director/pending/beam-hold; Orb's first play: "the fighter should more or less remain stationary"). Firing from up close throws the other fighter back to the stand-off
// over 0.25 s, no damage and no stun, and he keeps his hands: the cue `beam_shove` on the one thrown. Until now he slid in a standing pose. The sim carries him (the rush); this is the body: thrown back at first,
// then digging in, leaning into the blast with the forearms up in front of the face and the weight low on a wide stance, then letting go as the slide ends. A pose sequence fitted to the slide's length by the cue handler (a
// `fit` sequence: the weights divide the ticks). Prefix sv. Legal: a forearm leads and the hands are fists on both fighters (no open palm: RL-218's catch rule); nothing above the shoulder; no pose held 12 ticks (the
// middle phase is the slide's own length, 9 ticks at 15).
const FIST = { hands: { r: 'fist', l: 'fist' } };
export const sequences = {
  shove: { dur: 15, legal: ['reaction', 'no_clasp'], phases: [
    { id: 'hit', w: 0.2, sketch: { family: 'upright', lean: -14, hips: [-8, -2, 0], spine: { lean: -10, twist: 0 }, head: { pitch: -14 }, hand_r: [15.6, 63.8, 15.5], hand_l: [16.5, 58.2, -11.7], foot_r: [-14, 2.5, 9], foot_l: [6, 2.5, -8], ...FIST },
      orig: 'the shock wave arriving: the weight thrown back onto the rear leg, the chest and head pushed back, the fists coming up out of the guard; three ticks, a recoil and not a stance' },
    { id: 'dig', w: 0.6, sketch: { family: 'crouched', lean: 14, hips: [4, -14, 0], spine: { lean: 12, twist: -6 }, head: { pitch: 16 }, hand_r: [32, 62, 8], pole_hand_r: [6, 2, 8], hand_l: [34, 55, -6], pole_hand_l: [6, 0, -8], foot_r: [-18, 2.5, 10], foot_l: [14, 2.5, -8], ...FIST },
      orig: 'digging in: the knees deep on a wide stance, the body leaning into the blast with the head tucked behind the forearms, both fists up in front of the face with the elbows low; the feet slide and the body does not give' },
    { id: 'settle', w: 0.2, from: 'stance.aggressive', over: { lean: 12, hips: [0, -6, 0], head: { pitch: 10 } },
      orig: 'the slide ending: the body coming up out of the dig into the aggressive stand, the guard still in front' },
  ] },
};
