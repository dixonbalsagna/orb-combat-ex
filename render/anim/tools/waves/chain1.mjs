// The chain inside a tower (docs/animation/ragdoll-physics-paper.md section 4; Game Design's values, docs/design/buildings.md section 7.3): the body's shape at a ceiling. Two shared sequences on the one skeleton,
// played by AnimFighter.on_interior_contact over the ragdoll: the slam (the body compressed against the underside of a slab for a few ticks, then the give as the ceiling goes) and the rebound (falling away, limp,
// the limbs trailing up). Parked: nothing plays them until World sends an `interior_contact` event. Prefix ce. Originality: no franchise pose; every pose has an _orig line.
const OPEN = { hands: { r: 'open', l: 'open' } };

export const sequences = {
  slam: { dur: 6, phases: [
    { id: 'compress', ticks: 3, sketch: { family: 'tumble', lean: 30, hips: [0, -4, 0], spine: { lean: 26 }, head: { pitch: 24 }, hand_r: [14, 60, 16], hand_l: [14, 58, -14],
        foot_r: [8, 22, 8], foot_l: [4, 20, -7], ...OPEN },
      orig: 'the body met by the underside of a floor: the knees drawn up, the back hunched, the head tucked and both hands up to cover it' },
    { id: 'give', ticks: 3, sketch: { family: 'airborne_extended', lean: -20, hips: [0, 2, 0], spine: { lean: -18 }, head: { pitch: -14 }, hand_r: [-6, 74, 26], hand_l: [-6, 70, -24],
        foot_r: [-8, 12, 8], foot_l: [-10, 8, -6], ...OPEN },
      orig: 'the ceiling giving way: the spine arching back, the arms flung out and up, the legs trailing' },
  ] },
  rebound: { dur: 8, phases: [
    { id: 'drop', sketch: { family: 'airborne_extended', lean: -10, hips: [0, 2, 0], spine: { lean: -8 }, head: { pitch: -10 }, hand_r: [-10, 72, 22], hand_l: [-8, 70, -20],
        foot_r: [-8, 12, 8], foot_l: [-10, 8, -6], ...OPEN },
      orig: 'falling away from the slab: limp, the limbs trailing up behind the fall' },
  ] },
};
