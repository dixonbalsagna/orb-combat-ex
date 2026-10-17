// PROVISIONAL (the tenth round, docs/design/brawl-second-pass.md section 14; docs/animation/tenth-round.md): three poses the new moves need that no pose of today is.
//   air_tech    the rival's tech in the air (cue `tech`; a guard press timed to the chaser's arrival breaks the chase): thrown open (arms flung apart, legs scissored: a flash's moment), then braced upright to land (Orb, homework 4: the old tuck made his legs look folded up and strange). A `fit` sequence.
//   interject   a ring guard's tell (Encounter's windup cue `interject`: the guard, the landing tick, the length): weight forward, the rear hand drawn back to the shoulder, the chin down on the one. A pose.
//   chase       the chaser's dive (cue `chase`): the body laid forward along the travel, the leading hand reaching, the rear leg trailing. A pose mixed over the travel.
// Prefix rt. Reactions and chambers: hands apart (never together at the hip), nothing above 80, no light.
const O = { hands: { r: 'open', l: 'open' } };
export const sequences = {
  air_tech: { dur: 14, legal: ['reaction'], phases: [
    { id: 'spread', w: 0.36, sketch: { family: 'upright', lean: -6, hips: [0, 2, 0], spine: { lean: -6, twist: 0 }, head: { pitch: -8 }, hand_r: [28, 72, 24], hand_l: [-24, 68, -24], foot_r: [16, 10, 10], foot_l: [-12, 12, -10], ...O },
      orig: 'PROVISIONAL: the air tech, first half: thrown open, the chest to the chaser, the arms flung apart (one up and forward, one up and back in the side-on view) and the legs scissored, one forward and one trailing, neither folded' },
    { id: 'brace', w: 0.64, sketch: { family: 'upright', lean: 8, hips: [0, -4, 0], spine: { lean: 8, twist: 0 }, head: { pitch: 6 }, hand_r: [22, 60, 16], hand_l: [8, 58, -16], foot_r: [10, 8, 9], foot_l: [-2, 5, -8], ...O },
      orig: 'PROVISIONAL: the air tech, second half: the body upright and braced to land, the knees only a little bent and the feet gathered under him, the arms coming in to guard; no tuck' },
  ] },
  interject: { dur: 10, phases: [
    { id: 'tell', ticks: 10, sketch: { family: 'upright_lunge', lean: 10, hips: [10, -4, 0], spine: { lean: 6, twist: -16 }, head: { pitch: -2 }, hand_r: [-6, 58, 14], pole_hand_r: [-10, 4, 10], hand_l: [20, 60, -10], foot_r: [-8, 2.5, 9], foot_l: [24, 2.5, -8], ...O },
      orig: 'PROVISIONAL: a ring guard stepping in: the weight forward on the front foot, the rear hand drawn back at the shoulder, the chin down' },
  ] },
  chase: { dur: 10, phases: [
    { id: 'dive', ticks: 10, sketch: { family: 'upright_lunge', lean: 34, hips: [20, -6, 0], spine: { lean: 26, twist: 8 }, head: { pitch: 14 }, hand_r: [40, 60, 8], hand_l: [-4, 54, -12], foot_r: [-20, 24, 8], foot_l: [12, 18, -8], ...O },
      orig: 'PROVISIONAL: the chaser in the air after his own send: the body laid forward along the travel, the leading hand reaching, the rear leg trailing' },
  ] },
};
