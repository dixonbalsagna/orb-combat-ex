// The two ends of the grip contest (docs/animation/grip-stages.md): the clinch's grip has five steps (two behind, one behind, even, one ahead, two ahead; Game Design's grip grades), and the grip layer (data/anim/clinch.json)
// mixes the three authored poses of wave cl1 (behind, seat, ahead) by the grade. These two poses are the top of each end, mixed in over them only at the last step:
//   set   the leader at two ahead sets his hips: sunk and wide under the other's weight, the shoulders over the hands, the lift or the throw about to go. The throw can only come from here (Game Design's grapple.md).
//   cave  the one at two behind caves: up on the heels, the shoulders rolled back, the hands holding on as he is walked back.
// Same rules as cl1 (Legal's g06 to g08 and h09): the partner about 30 units ahead, hands never lock or lace (16 or more apart where both are used), heads and torsos a forearm apart, no crossed forearms. Prefix cs;
// poses are `cs.hold.<name>`. Originality: no franchise pose; every pose has an _orig line.
const OPEN = { hands: { r: 'open', l: 'open' } };

export const sequences = {};

export const holds = {
  set: { sketch: { family: 'upright', lean: 6, hips: [2, -10, 0], spine: { lean: 8, twist: 12 }, head: { pitch: 4 }, hand_r: [28, 56, 8], hand_l: [26, 44, -12],
      foot_r: [-10, 2.5, 11], foot_l: [15, 2.5, -9], ...OPEN },
    orig: 'the leader setting his hips: sunk and wide under the other\'s weight, the shoulders over the hands, the feet set to lift or turn him' },
  cave: { sketch: { family: 'upright', lean: -8, hips: [-4, -4, 0], spine: { lean: -8, twist: -2 }, head: { pitch: -2 }, hand_r: [24, 52, 10], hand_l: [22, 38, -14],
      foot_r: [-2, 2.5, 9], foot_l: [6, 2.5, -7], ...OPEN },
    orig: 'the grip lost: up on the heels, the shoulders rolled back, the head back, the hands holding on as he is walked back' },
};
