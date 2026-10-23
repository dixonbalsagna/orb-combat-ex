// The press-tick anticipation (docs/animation/press-ack.md; Encounter's press_ack "queued", the cue a player's press sends on its own tick when it has to wait for a cooldown): the first frames of a wind-up,
// one pose a button cell and a fighter, mixed in over the idle stance at a part weight (AnimFighter._ack_layer; data/anim/press_ack.json) until the exchange starts and the real wind-up takes over.
// x a light (a short lean in, the near hand set), y a heavy (the weight moving forward, one shoulder wound), b a signature or a big heavy (sunk, loaded). The Protagonist (_p) is compact and forward,
// the rival (_r) sits back a little with his chin up. Shallower than the held blows' bodies (ch.*): this is a press being committed to, not a charge. Prefix ak. Originality: every pose has an _orig line.
const O = { hands: { r: 'open', l: 'open' } };
export const sequences = {
  x_p: { dur: 6, phases: [{ id: 'set', ticks: 6, sketch: { family: 'upright', lean: 8, hips: [2, -3, 0], spine: { lean: 8, twist: -8 }, head: { pitch: 4 }, hand_r: [8, 60, 12], hand_l: [22, 58, -10], foot_r: [-8, 2.5, 10], foot_l: [14, 2.5, -8], ...O },
    orig: 'a light being committed to: the body leans in a little, the near hand drawn back to set, the weight forward before the beat lets it go' }] },
  x_r: { dur: 6, phases: [{ id: 'set', ticks: 6, sketch: { family: 'upright', lean: 3, hips: [-2, -4, 0], spine: { lean: 2, twist: -12 }, head: { pitch: -2 }, hand_r: [6, 62, 13], hand_l: [20, 60, -11], foot_r: [-10, 2.5, 10], foot_l: [14, 2.5, -8], ...O },
    orig: 'a light being committed to, his way: the weight sits back a little, the shoulder turns, the chin stays up' }] },
  y_p: { dur: 6, phases: [{ id: 'set', ticks: 6, sketch: { family: 'upright', lean: 12, hips: [0, -7, 0], spine: { lean: 11, twist: -14 }, head: { pitch: 6 }, hand_r: [6, 60, 12], hand_l: [22, 58, -10], foot_r: [-9, 2.5, 10], foot_l: [15, 2.5, -8], ...O },
    orig: 'a heavier blow being committed to: forward and patient, one shoulder wound back, the weight coming onto the front foot' }] },
  y_r: { dur: 6, phases: [{ id: 'set', ticks: 6, sketch: { family: 'upright', lean: 0, hips: [-4, -8, 0], spine: { lean: 0, twist: -18 }, head: { pitch: -5 }, hand_r: [4, 62, 14], hand_l: [20, 60, -12], foot_r: [-12, 2.5, 10], foot_l: [14, 2.5, -8], ...O },
    orig: 'a heavier blow being committed to, his way: the weight sunk back, the shoulder wound round, the chin up' }] },
  b_p: { dur: 6, phases: [{ id: 'set', ticks: 6, sketch: { family: 'crouched', lean: 10, hips: [-1, -12, 0], spine: { lean: 10, twist: -10 }, head: { pitch: 10 }, hand_r: [8, 58, 12], hand_l: [22, 56, -10], foot_r: [-12, 2.5, 10], foot_l: [17, 2.5, -9], ...O },
    orig: 'the big press being committed to: sinking, the shoulders starting to wind, the head down on him' }] },
  b_r: { dur: 6, phases: [{ id: 'set', ticks: 6, sketch: { family: 'crouched', lean: 6, hips: [-5, -14, 0], spine: { lean: 6, twist: -20 }, head: { pitch: 0 }, hand_r: [4, 62, 16], hand_l: [20, 58, -12], foot_r: [-16, 2.5, 10], foot_l: [17, 2.5, -10], ...O },
    orig: 'the big press being committed to, his way: sinking wide, the back starting to wind round, the chin level' }] },
};
