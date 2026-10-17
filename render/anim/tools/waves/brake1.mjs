// The mid-air skid (docs/animation/ragdoll-physics-paper.md section 3a): a launched fighter who brakes in the air is braced against his own velocity. Three shared poses on the one skeleton,
// mixed in by the sim's brake state (RenderAnim.air_brake, AnimFighter._air_brake_layer): the entry (the spin removed, arms flung wide), the brace (the torso leaned back against the way
// he travels, knees bent, one foot ahead, the forearms up and forward) and the exit (the arms drawing in). Parked behind the brake event: nothing plays them until the sim sends one.
// Prefix ab. Originality: no franchise pose; every pose has an _orig line.
const OPEN = { hands: { r: 'open', l: 'open' } };

export const sequences = {
  skid: { dur: 16, phases: [
    { id: 'enter', ticks: 4, sketch: { family: 'airborne_neutral', lean: -8, hips: [0, 0, 0], spine: { lean: -10 }, head: { pitch: -4 }, hand_r: [8, 56, 30], hand_l: [8, 54, -28],
        foot_r: [10, 0, 8], foot_l: [-6, 2, -7], ...OPEN },
      orig: 'the spin taken out of the body: the arms flung wide to catch the air, one leg reaching ahead' },
    { id: 'hold', sketch: { family: 'airborne_neutral', lean: -34, hips: [-4, -6, 0], spine: { lean: -12 }, head: { pitch: 6 }, hand_r: [30, 60, 18], hand_l: [28, 56, -16],
        foot_r: [22, -4, 9], foot_l: [10, -10, -8], ...OPEN },
      orig: 'braced against the way he travels: the torso leaned back, the knees bent and the feet reaching toward the travel, both forearms up and forward, the head up and looking along it' },
    { id: 'exit', ticks: 4, sketch: { family: 'airborne_neutral', lean: -8, hips: [0, -2, 0], spine: { lean: -4 }, head: { pitch: 2 }, hand_r: [20, 52, 16], hand_l: [18, 50, -14],
        foot_r: [6, -2, 8], foot_l: [-4, 0, -7], ...OPEN },
      orig: 'out of the brake: the arms drawing in, the feet coming under him' },
  ] },
};
