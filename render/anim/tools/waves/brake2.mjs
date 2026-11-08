// The air brake's readable look (docs/animation/air-brake-looks-plan.md): a PLANT a fighter, mixed in by the sim's brake state exactly as brake1's skid is (data/anim/brake.json `fighters` names these per fighter; AnimFighter._air_brake_layer).
// The flight lead turns the body until its spine leans against the way he travels; the pose is the body as it stands in that frame, so the sketches are authored with the spine near upright and the limbs placed for the turn that follows:
// the leg that goes ahead toward the travel is the one thrown BACK and down in the sketch, the arm pressed out ahead of him on screen is the one swung back and up, and the knee of the trailing leg points the way he came from.
// Protagonist (prefix ax, names plant_p): open blades. Anti-hero (plant_r): fists, plates and knees, never a palm (RL-218 (2)). Originality: no franchise pose; every pose has an _orig line.
const OPEN = { hands: { r: 'open', l: 'open' } };
const FIST = { hands: { r: 'fist', l: 'fist' } };

export const sequences = {
  plant_p: { dur: 16, phases: [
    { id: 'dig', ticks: 5, sketch: { family: 'airborne_neutral', lean: -6, hips: [0, -10, 0], spine: { lean: -2, twist: 8 }, head: { pitch: -2 }, hand_r: [-18, 46, 16], hand_l: [24.9, 36.6, -13.8],
        foot_r: [-14, -2, 10], foot_l: [8, -8, -8], ...OPEN },
      orig: 'the first bite of the brake: the weight dropping, the near arm snapping out ahead of him, a heel reaching for the air' },
    { id: 'hold', sketch: { family: 'airborne_neutral', lean: 0, hips: [-2, -16, 0], spine: { lean: 4, twist: 14 }, head: { pitch: -4, yaw: 8 }, hand_r: [-23.9, 27.7, 15.5], hand_l: [24.9, 65.3, -15.7],
        foot_r: [-26, -6, 10], foot_l: [16.8, -10.2, -7.8], ...OPEN },
      orig: 'planted on the air: hips dropped, one leg thrown out ahead toward where he is going with the foot flat, the other knee bent behind it, the near arm pressed out ahead and the far arm swung back for the balance, the chest turned to the foe' },
    { id: 'exit', ticks: 5, sketch: { family: 'airborne_neutral', lean: -4, hips: [0, -6, 0], spine: { lean: 0, twist: 6 }, head: { pitch: 0 }, hand_r: [8, 50, 16], hand_l: [20, 40, -14],
        foot_r: [-6, -4, 9], foot_l: [7.8, -5, -7.9], ...OPEN },
      orig: 'out of the plant: the legs drawing under him, the arms coming in' },
  ] },
  plant_r: { dur: 16, phases: [
    { id: 'dig', ticks: 5, sketch: { family: 'airborne_neutral', lean: -6, hips: [0, -10, 0], spine: { lean: -2, twist: 8 }, head: { pitch: 4 }, hand_r: [-18, 46, 16], hand_l: [24.9, 36.6, -13.8],
        foot_r: [-14, -2, 10], foot_l: [8, -8, -8], ...FIST },
      orig: 'the first bite of the brake: the weight dropping, the near fist snapping out ahead of him, a heel reaching for the air' },
    { id: 'hold', sketch: { family: 'airborne_neutral', lean: 0, hips: [-2, -16, 0], spine: { lean: 4, twist: 14 }, head: { pitch: 4, yaw: 8 }, hand_r: [-23.9, 27.7, 15.5], hand_l: [24.9, 65.3, -15.7],
        foot_r: [-26, -6, 10], foot_l: [16.8, -10.2, -7.8], ...FIST },
      orig: 'planted on the air like a wall: hips dropped, one leg driven out ahead toward where he is going, the other knee bent behind it, the near fist braced out ahead and the far fist swung back, the chest turned to the foe' },
    { id: 'exit', ticks: 5, sketch: { family: 'airborne_neutral', lean: -4, hips: [0, -6, 0], spine: { lean: 0, twist: 6 }, head: { pitch: 2 }, hand_r: [8, 50, 16], hand_l: [20, 40, -14],
        foot_r: [-6, -4, 9], foot_l: [7.8, -5, -7.9], ...FIST },
      orig: 'out of the plant: the legs drawing under him, the fists coming in' },
  ] },
};

// The regain (control back in the air after a knockback or a send): a tuck of the knees with the hands drawn in, then the arms swept out and down and the legs dropped under him, the end of the sweep passing into the guard (a flourish, never held:
// the layer plays `tuck` over ticks 0 to 8 and `open` over 8 to 15 and lets it go by tick 28).
sequences.regain_p = { dur: 28, phases: [
  { id: 'tuck', ticks: 8, sketch: { family: 'airborne_neutral', lean: 12, hips: [2, -14, 0], spine: { lean: 10, twist: 6 }, head: { pitch: 8 }, hand_r: [16, 42, 12], hand_l: [14, 40, -10],
      foot_r: [12, 10, 9], foot_l: [6, 6, -8], ...OPEN },
    orig: 'the knees drawn up and the hands brought in, the weight gathered to turn' },
  { id: 'open', ticks: 8, sketch: { family: 'airborne_neutral', lean: -6, hips: [0, -4, 0], spine: { lean: -4, twist: -6 }, head: { pitch: -4 }, hand_r: [16.5, 36.1, 22.2], hand_l: [15.9, 34, -20.9],
      foot_r: [3.7, -3.6, 8.7], foot_l: [-1.8, -3.8, -7.7], ...OPEN },
    orig: 'the arms swept out and down, the legs dropped under him: he has the air back' },
] };
sequences.regain_r = { dur: 28, phases: [
  { id: 'tuck', ticks: 8, sketch: { family: 'airborne_neutral', lean: 12, hips: [2, -14, 0], spine: { lean: 10, twist: 6 }, head: { pitch: 10 }, hand_r: [16, 42, 12], hand_l: [14, 40, -10],
      foot_r: [12, 10, 9], foot_l: [6, 6, -8], ...FIST },
    orig: 'the knees drawn up and the fists brought in, the weight gathered to turn' },
  { id: 'open', ticks: 8, sketch: { family: 'airborne_neutral', lean: -6, hips: [0, -4, 0], spine: { lean: -4, twist: -6 }, head: { pitch: -2 }, hand_r: [16.5, 36.1, 22.2], hand_l: [15.9, 34, -20.9],
      foot_r: [3.7, -3.6, 8.7], foot_l: [-1.8, -3.8, -7.7], ...FIST },
    orig: 'the fists thrown out and down, the legs dropped under him: he has the air back' },
] };

// The skid landing (a brake that ends on the ground: the slide state): the feet dug in on the way he came from with the weight low, the near hand trailing near the floor and the far arm up toward the foe for the balance. Played in place of slide.brake only for a landing out of
// the brake (AnimFighter._ab_last_t); every other slide is slide.brake as before.
sequences.land_p = { dur: 16, phases: [
  { id: 'hold', sketch: { family: 'slide_brake', lean: 24, hips: [-6, -14, 0], spine: { lean: 6 }, head: { pitch: 6 }, hand_r: [-11.3, 19, 15.7], hand_l: [24, 48, -14],
      foot_r: [-26, 2.5, 9], foot_l: [-10, 2.5, -7], ...OPEN },
    orig: 'skidding in on the heels: the lead foot dug in far behind, the weight low over the bent knee, the near hand trailing near the floor and the far arm up toward the foe for the balance' },
] };
sequences.land_r = { dur: 16, phases: [
  { id: 'hold', sketch: { family: 'slide_brake', lean: 24, hips: [-6, -14, 0], spine: { lean: 6 }, head: { pitch: 8 }, hand_r: [-11.3, 19, 15.7], hand_l: [24, 48, -14],
      foot_r: [-26, 2.5, 9], foot_l: [-10, 2.5, -7], ...FIST },
    orig: 'skidding in on the heels like a dropped weight: the lead foot dug in far behind, the weight low over the bent knee, the near fist trailing near the floor and the far fist up toward the foe' },
] };
