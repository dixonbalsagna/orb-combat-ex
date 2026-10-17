// PROVISIONAL (the launcher's signal, brawl-plan.md section 10.3: the cues `launcher_open` and `launcher_close`; Combat's c2t-content.md section 1): "a close whose stagger is plain to see, since it is the signal for B".
// The staggered fighter, for the ticks the stagger lasts (cue `n`, the tick it ends): knocked back, then doubled over and dazed with his arms hanging low and loose in front of him and his head down, then
// coming up. It has to read at a glance as "he is out of it, hit him now", without any glow. A pose sequence fitted to the stagger's length by the cue handler (a `fit` sequence: the weights divide the ticks).
// Prefix lq. A reaction (class rest in the held lint): hands low and apart, never at the hip zone together, no light.
//   open   snap (the head snapped back, the arms flung open: 4 ticks) and open (the arms coming in: 3 ticks), daze (doubled over, hands hanging, head down: the long part), come-up (the head lifting, the guard returning)
export const sequences = {
  open: { dur: 30, legal: ['reaction'], phases: [
    { id: 'snap', ticks: 4, sketch: { family: 'upright', lean: -16, hips: [-10, 2, 0], spine: { lean: -14, twist: 0 }, head: { pitch: -28 }, hand_r: [12, 80, 24], hand_l: [-26, 70, -24], foot_r: [-12, 2.5, 10], foot_l: [8, 2.5, -8], hands: { r: 'open', l: 'open' } },
      orig: 'PROVISIONAL (the eleventh round, Orb: "his head snaps back and his arms fly open"): the push of the blow at its peak: the weight thrown back on the rear leg, the head snapped well back, the arms flung apart in the side-on view, one up and forward, one up and back, the palms open; four ticks, a recoil and not a stance' },
    { id: 'open', ticks: 3, sketch: { family: 'upright', lean: -10, hips: [-6, 0, 0], spine: { lean: -8, twist: 0 }, head: { pitch: -18 }, hand_r: [14, 68, 26], hand_l: [-22, 62, -26], foot_r: [-10, 2.5, 9], foot_l: [8, 2.5, -8], hands: { r: 'open', l: 'open' } },
      orig: 'PROVISIONAL: the arms still open at shoulder height and coming in, the head still back, the chest bare to the rival; three ticks, then the daze takes him (the open arms never last 12 ticks: Legal h07)' },
    { id: 'daze', w: 0.7, sketch: { family: 'crouched', lean: 26, hips: [-2, -16, 0], spine: { lean: 22, twist: 0 }, head: { pitch: 30 }, hand_r: [20, 32, 14], hand_l: [18, 34, -14], foot_r: [-8, 2.5, 9], foot_l: [12, 2.5, -8], hands: { r: 'relaxed', l: 'relaxed' } },
      orig: 'PROVISIONAL: dazed: doubled over with the knees bent, the arms hanging low and loose in front of him a shoulder width apart, the head down; nothing guarding him' },
    { id: 'come_up', w: 0.16, from: 'stance.aggressive', over: { lean: 10, hips: [-2, -6, 0], head: { pitch: 12 } },
      orig: 'PROVISIONAL: the head lifting and the guard coming back as the daze ends' },
  ] },
};
