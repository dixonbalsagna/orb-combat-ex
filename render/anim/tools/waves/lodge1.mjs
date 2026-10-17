// Lodged in a building and getting out (Game Design, docs/design/buildings.md sections 6.4 and 7.3: held 0.5 to 0.9 s, then he recovers inside): one shared sequence on the one skeleton, played by
// AnimFighter.on_lodge over the ragdoll from the sim's existing `lodge` event. The slump (held for the sim's hold), the climb (one hand on the edge of the breach, a knee up) and the stand (the guard coming up).
// Prefix lg. Legal: no arms crossed, no hand at a hip. Originality: no franchise pose; every pose has an _orig line.
const OPEN = { hands: { r: 'open', l: 'open' } };

export const sequences = {
  climb: { dur: 40, phases: [
    { id: 'slump', sketch: { family: 'crouched', lean: 24, hips: [0, -16, 0], spine: { lean: 20 }, head: { pitch: 24 }, hand_r: [10, 22, 14], hand_l: [6, 20, -12],
        foot_r: [-8, 2.5, 9], foot_l: [8, 2.5, -7], ...OPEN },
      orig: 'lodged in the breach: hanging forward where the wall holds him, the head down, both arms slack in front of him' },
    { id: 'push', ticks: 12, sketch: { family: 'crouched', lean: 14, hips: [4, -10, 0], spine: { lean: 10 }, head: { pitch: 12 }, hand_r: [26, 50, 14], hand_l: [10, 34, -12],
        foot_r: [-6, 2.5, 9], foot_l: [12, 8, -7], ...OPEN },
      orig: 'getting out: one hand set on the edge of the breach, the other reaching, a knee coming up' },
    { id: 'stand', ticks: 8, sketch: { family: 'upright', lean: 6, hips: [0, -4, 0], spine: { lean: 4 }, head: { pitch: 4 }, hand_r: [20, 54, 13], hand_l: [22, 52, -8],
        foot_r: [-9, 2.5, 8], foot_l: [11, 2.5, -7], ...OPEN },
      orig: 'standing out of it: the guard coming up, the weight on both feet' },
  ] },
};
