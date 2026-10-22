// The clinch's shared poses (docs/animation/clinch-sizing.md section 3; Legal's g06 to g08 and h09): thirteen holds on the one skeleton, the holder's own side only. The partner stands about 30 units ahead (the grip's
// distance, 27 or more by g06); the grip layer (AnimFighter._grip_layer, data/anim/clinch.json) solves each gripping hand onto its region of the real partner and mixes these by the sim's read: the tie-up's three grades
// (behind, even, ahead), the pummel's two hands, the brace, the pin and the pinned body's brace (g07: vertical against a surface, feet bearing weight, struggling), the carry and its strain, the refused grip and the push apart.
// g06: hands never lock or lace (16 or more apart where both are used), free hands never limp or bound; h09: no crossed forearms, a one-arm fold at most. Prefix cl; poses are `cl.hold.<name>`.
// Parked; originality: no franchise pose; every pose has an _orig line.
const OPEN = { hands: { r: 'open', l: 'open' } };

export const sequences = {};

export const holds = {
  tie_reach: { sketch: { family: 'upright_lunge', lean: 12, hips: [6, -4, 0], spine: { lean: 8, twist: 10 }, head: { pitch: 4 }, hand_r: [34, 54, 10], hand_l: [20, 50, -12],
      foot_r: [-6, 2.5, 10], foot_l: [12, 2.5, -8], ...OPEN },
    orig: 'the reach for the collar: one hand out to take it, the other held up at his own chest, the weight coming forward' },
  seat: { sketch: { family: 'upright', lean: 2, hips: [0, -6, 0], spine: { lean: 2, twist: 6 }, head: { pitch: 0 }, hand_r: [26, 54, 8], hand_l: [24, 40, -14],
      foot_r: [-6, 2.5, 10], foot_l: [10, 2.5, -8], ...OPEN },
    orig: 'the tie-up at an even grip: one hand at the side of the collar and the other at the elbow, the heads apart, the feet set' },
  ahead: { sketch: { family: 'upright', lean: 6, hips: [3, -8, 0], spine: { lean: 6, twist: 10 }, head: { pitch: 2 }, hand_r: [28, 56, 8], hand_l: [26, 44, -12],
      foot_r: [-8, 2.5, 11], foot_l: [14, 2.5, -9], ...OPEN },
    orig: 'a grip a step ahead: the weight forward, the shoulders over the hands, the rival being walked back' },
  behind: { sketch: { family: 'upright', lean: -4, hips: [-2, -4, 0], spine: { lean: -4, twist: 0 }, head: { pitch: 0 }, hand_r: [24, 52, 10], hand_l: [22, 38, -14],
      foot_r: [-4, 2.5, 10], foot_l: [8, 2.5, -8], ...OPEN },
    orig: 'a grip a step behind: upright and pushed back on the heels, the hands holding on' },
  pummel_l: { sketch: { family: 'upright', lean: 10, hips: [5, -6, 0], spine: { lean: 8, twist: 8 }, head: { pitch: 4 }, hand_r: [24, 54, 10], hand_l: [28, 34, -8],
      foot_r: [-6, 2.5, 10], foot_l: [12, 2.5, -8], ...OPEN },
    orig: 'the pummel on the left: the free hand swimming in low under his arm for the better grip' },
  pummel_r: { sketch: { family: 'upright', lean: 10, hips: [5, -6, 0], spine: { lean: 8, twist: 8 }, head: { pitch: 4 }, hand_r: [28, 34, 8], hand_l: [24, 54, -10],
      foot_r: [-6, 2.5, 10], foot_l: [12, 2.5, -8], ...OPEN },
    orig: 'the pummel on the right: the other hand swimming in low for the better grip' },
  brace: { sketch: { family: 'crouched', lean: 4, hips: [-2, -10, 0], spine: { lean: 8, twist: 0 }, head: { pitch: 10 }, hand_r: [24, 50, 10], hand_l: [22, 44, -12],
      foot_r: [-10, 2.5, 12], foot_l: [12, 2.5, -10], ...OPEN },
    orig: 'the brace: low and wide, the elbows in, the head down, waiting out a stronger grip' },
  pin: { sketch: { family: 'upright_lunge', lean: 16, hips: [8, -6, 0], spine: { lean: 14, twist: 20 }, head: { pitch: 6 }, hand_r: [28, 52, 12], hand_l: [20, 42, -12],
      foot_r: [-8, 2.5, 11], foot_l: [14, 2.5, -9], ...OPEN },
    orig: 'the pin: the shoulder leading in, one hand at the collar side and the forearm along the shoulder, never across the throat, the hips apart, the feet driving' },
  pin_brace: { sketch: { family: 'upright', lean: -6, hips: [-4, -4, 0], spine: { lean: -6, twist: 0 }, head: { pitch: 4 }, hand_r: [22, 50, 12], hand_l: [20, 46, -12],
      foot_r: [-6, 2.5, 10], foot_l: [8, 2.5, -8], ...OPEN },
    orig: 'the pinned body bracing: his back to the surface, both feet bearing weight, both hands up and pushing against the hold, struggling' },
  carry: { sketch: { family: 'upright', lean: 18, hips: [10, -10, 0], spine: { lean: 14, twist: 8 }, head: { pitch: 8 }, hand_r: [22, 44, 10], hand_l: [18, 40, -12],
      foot_r: [-10, 2.5, 11], foot_l: [14, 2.5, -9], ...OPEN },
    orig: 'the carry: leaning into the drive with one hand at the collar and one at the waist, the legs pushing' },
  strain: { sketch: { family: 'crouched', lean: 22, hips: [6, -16, 0], spine: { lean: 18, twist: 4 }, head: { pitch: 14 }, hand_r: [20, 38, 10], hand_l: [16, 36, -12],
      foot_r: [-10, 2.5, 12], foot_l: [10, 2.5, -10], ...OPEN },
    orig: 'the carry at its cap: low and straining, the head down, the hands holding on' },
  whiff: { sketch: { family: 'upright_lunge', lean: 20, hips: [10, -6, 0], spine: { lean: 14, twist: 10 }, head: { pitch: 6 }, hand_r: [40, 52, 12], hand_l: [14, 40, -12],
      foot_r: [-4, 2.5, 10], foot_l: [20, 2.5, -8], ...OPEN },
    orig: 'a refused grip: the hand closing on nothing, over-reached, the weight a step too far forward' },
  apart: { sketch: { family: 'upright', lean: -4, hips: [-4, -4, 0], spine: { lean: -4, twist: 0 }, head: { pitch: 2 }, hand_r: [24, 50, 10], hand_l: [24, 48, -12],
      foot_r: [-8, 2.5, 10], foot_l: [8, 2.5, -8], ...OPEN },
    orig: 'pushing apart: both open hands pressing off, the weight going back' },
};
