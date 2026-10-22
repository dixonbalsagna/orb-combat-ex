// The Protagonist's three finisher closing poses (docs/art/hero-forms-look.md section 3, Legal's h10 in docs/legal/rewards-and-lock-screen.md section 3), to be seen in motion before Orb judges them: Open Palm, Held Breath
// and Both Roads. Each is a short sequence on the one skeleton: the end (the blast over, planted, the arms still coming down) then the close, held. Poses only; the camera, the pulse and the colour are the study's scenario.
// h10: OPEN PALM one hand only, fingers together and still, the palm toward the fallen rival or sideways and never at the camera, held low (hip height or below) with the forearm out and never drawn to the hip, no smirk,
// never both arms. HELD BREATH nothing to taunt: the head bowed, looking back over the shoulder for the people. BOTH ROADS one open hand, palm out like a pledge, at shoulder height or lower (never above 82 and never above the head),
// fingers together, no light, glow or ring in or above the hand, no ball, one hand only. Prefix fn. Parked; originality: no franchise pose; every pose has an _orig line.
const OPEN = { hands: { r: 'open', l: 'open' } };

export const sequences = {
  open_palm: { dur: 150, phases: [
    { id: 'end', ticks: 14, sketch: { family: 'upright', lean: 8, hips: [2, -4, 0], spine: { lean: 6, twist: -8 }, head: { pitch: 8 }, hand_r: [10, 30, 14], hand_l: [4, 22, -14],
        foot_r: [-8, 2.5, 9], foot_l: [10, 2.5, -8], ...OPEN },
      orig: 'the blast over: planted, the weight forward, both arms still coming down, the head a little bowed toward the fallen rival' },
    { id: 'close', sketch: { family: 'upright', lean: 4, hips: [0, -2, 0], spine: { lean: 4, twist: 6 }, head: { pitch: 10 }, hand_r: [30, 26, 14], pole_hand_r: [4, 4, 12], hand_l: [4, 20, -14],
        foot_r: [-8, 2.5, 9], foot_l: [10, 2.5, -8], ...OPEN },
      orig: 'an open hand held out low toward the fallen rival, as an offer: one hand, fingers together and still, the forearm out and below the hip, the other arm hanging, the face quiet' },
  ] },
  held_breath: { dur: 150, phases: [
    { id: 'end', ticks: 14, sketch: { family: 'upright', lean: 8, hips: [2, -4, 0], spine: { lean: 6, twist: -8 }, head: { pitch: 8 }, hand_r: [10, 30, 14], hand_l: [4, 22, -14],
        foot_r: [-8, 2.5, 9], foot_l: [10, 2.5, -8], ...OPEN },
      orig: 'the blast over: planted, the weight forward, both arms still coming down' },
    { id: 'close', sketch: { family: 'upright', lean: 10, hips: [0, -6, 0], spine: { lean: 12, twist: -22 }, head: { pitch: 30, yaw: 44 }, hand_r: [6, 22, 13], hand_l: [4, 22, -12],
        foot_r: [-8, 2.5, 9], foot_l: [8, 2.5, -8], ...OPEN },
      orig: 'a held breath: the shoulders let down, the head bowed and turned back over the shoulder, looking for the people behind him, both hands open at his sides' },
  ] },
  both_roads: { dur: 150, phases: [
    { id: 'end', ticks: 14, sketch: { family: 'upright', lean: 8, hips: [2, -4, 0], spine: { lean: 6, twist: -8 }, head: { pitch: 8 }, hand_r: [10, 30, 14], hand_l: [4, 22, -14],
        foot_r: [-8, 2.5, 9], foot_l: [10, 2.5, -8], ...OPEN },
      orig: 'the blast over: planted, the weight forward, both arms still coming down' },
    { id: 'close', sketch: { family: 'upright', lean: -2, hips: [-2, -2, 0], spine: { lean: -2, twist: 4 }, head: { pitch: 0 }, hand_r: [14, 56, 18], pole_hand_r: [-6, 30, 14], hand_l: [4, 22, -14],
        foot_r: [-8, 2.5, 9], foot_l: [10, 2.5, -8], ...OPEN },
      orig: 'a promise in the future tense: one open hand raised to the shoulder, the palm out like a pledge, the fingers together, nothing in or above it, the other arm at his side' },
  ] },
};
