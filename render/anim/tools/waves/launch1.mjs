// PROVISIONAL (the launcher's signal, brawl-plan.md section 10.3: the cues `launcher_open` and `launcher_close`; Combat's c2t-content.md section 1): "a close whose stagger is plain to see, since it is the signal for B".
// The staggered fighter, for the ticks the stagger lasts (cue `n`, the tick it ends): knocked back, then doubled over and dazed with his arms hanging low and loose in front of him and his head down, then
// coming up. It has to read at a glance as "he is out of it, hit him now", without any glow. A pose sequence fitted to the stagger's length by the cue handler (a `fit` sequence: the weights divide the ticks).
// Prefix lq. A reaction (class rest in the held lint): hands low and apart, never at the hip zone together, no light.
//   open   reel (the blow's push: the head snapped back, the arms thrown up and apart for a few ticks), daze (doubled over, hands hanging, head down: the long part), come-up (the head lifting, the guard returning)
export const sequences = {
  open: { dur: 30, legal: ['reaction'], phases: [
    { id: 'reel', w: 0.14, sketch: { family: 'upright', lean: -14, hips: [-8, 2, 0], spine: { lean: -10, twist: 0 }, head: { pitch: -16 }, hand_r: [8, 62, 16], hand_l: [10, 60, -16], foot_r: [-10, 2.5, 9], foot_l: [8, 2.5, -8], hands: { r: 'open', l: 'open' } },
      orig: 'PROVISIONAL: the push of the blow: the weight thrown back on the rear leg, the head snapped back, the arms flung up and apart for an instant' },
    { id: 'daze', w: 0.7, sketch: { family: 'crouched', lean: 26, hips: [-2, -16, 0], spine: { lean: 22, twist: 0 }, head: { pitch: 30 }, hand_r: [20, 32, 14], hand_l: [18, 34, -14], foot_r: [-8, 2.5, 9], foot_l: [12, 2.5, -8], hands: { r: 'relaxed', l: 'relaxed' } },
      orig: 'PROVISIONAL: dazed: doubled over with the knees bent, the arms hanging low and loose in front of him a shoulder width apart, the head down; nothing guarding him' },
    { id: 'come_up', w: 0.16, from: 'stance.aggressive', over: { lean: 10, hips: [-2, -6, 0], head: { pitch: 12 } },
      orig: 'PROVISIONAL: the head lifting and the guard coming back as the daze ends' },
  ] },
};
