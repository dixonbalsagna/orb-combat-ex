// PROVISIONAL (fighters in depth, docs/animation/fighters-in-depth.md): the two phases of a step in depth, the sidestep's 1 bh in 15 ticks and a drift along a lane. The body moves across the street's
// line, so on screen the legs do the work: a crossover. Legs, pelvis and a little spine only (the arms stay whatever the fighter's guard is); mixed over the base pose by AnimFighter._depth_step_layer,
// alternating by the footfall of the distance moved (one a 36 units), mirrored for the other way. One phase each so the sequence never holds; prefix dp.
//   cross_a   the near foot lifts and crosses in front of the far one, the hips going over it, the weight on the far leg
//   cross_b   the far foot catches up wide, the hips settled low between them: a step round him, not a slide
const O = { hands: { r: 'open', l: 'open' } };
export const sequences = {
  cross_a: { dur: 8, phases: [{ id: 'step', ticks: 8, sketch: { family: 'upright', lean: 4, hips: [0, -5, 6], spine: { lean: 4, twist: 8 }, head: { pitch: 0 }, hand_r: [14, 56, 10], hand_l: [18, 58, -10], foot_r: [6, 6.5, -16], foot_l: [-6, 2.5, 14], ...O },
    orig: 'PROVISIONAL: a step in depth, first half: the near foot lifted and crossing in front of the far one, the hips going over' }] },
  cross_b: { dur: 8, phases: [{ id: 'step', ticks: 8, sketch: { family: 'upright', lean: 4, hips: [0, -8, -4], spine: { lean: 4, twist: -6 }, head: { pitch: 0 }, hand_r: [14, 56, 10], hand_l: [18, 58, -10], foot_r: [4, 2.5, -22], foot_l: [-4, 6.5, 8], ...O },
    orig: 'PROVISIONAL: a step in depth, second half: the far foot lifted and catching up wide, the hips settled low between the feet' }] },
};
