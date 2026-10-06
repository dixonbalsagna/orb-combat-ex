// PROVISIONAL (a wound blow that met nothing, brawl-plan.md section 10.3: the cue `miss`, text gave_ground, reach or dodge, `n` the ticks he is open): "a whiff that reads as a whiff".
// The attacker's blow goes through empty air: the arm out to its full length with nothing on it, the weight carried past his own feet, then a few ticks off balance and open, then the guard back. Three
// ways, for the three words: he gave ground (the blow fell short as he stepped back: the attacker stumbles forward), it was out of reach (the arm stretched at nothing, one foot lifting, the other arm
// out for balance), he dodged (the rival slipped past: the attacker carries on past him bent forward, the head turned back looking for him). A `fit` sequence: through, open (the long part), recover.
// Prefix mi. A reaction (class rest in the held lint): hands apart, never at the hip zone together, no light.
const THROUGH = { family: 'upright_lunge', lean: 24, hips: [20, -8, 0], spine: { lean: 18, twist: 14 }, head: { pitch: 10 }, hand_r: [60, 56, 6], pole_hand_r: [4, -4, 8], hand_l: [10, 50, -12],
  foot_r: [-2, 14, 8], foot_l: [34, 2.5, -8], hands: { r: 'open', l: 'open' } };
export const sequences = {
  gave_ground: { dur: 24, legal: ['reaction'], phases: [
    { id: 'through', w: 0.2, sketch: THROUGH, orig: 'PROVISIONAL: the blow through empty air: the arm at full length with nothing on it, the weight carried past his front foot' },
    { id: 'open', w: 0.62, sketch: { family: 'upright_lunge', lean: 20, hips: [16, -6, 0], spine: { lean: 14, twist: 8 }, head: { pitch: 4 }, hand_r: [44, 46, 8], hand_l: [20, 52, -14], foot_r: [12, 5, 9], foot_l: [30, 2.5, -8], hands: { r: 'open', l: 'open' } },
      orig: 'PROVISIONAL: stumbling on after a blow that fell short: the trailing foot catching up, the arms low and forward, open to anything' },
    { id: 'recover', w: 0.18, from: 'stance.aggressive', over: { lean: 8, head: { pitch: 4 } }, orig: 'PROVISIONAL: finding his feet, the guard coming back' },
  ] },
  reach: { dur: 24, legal: ['reaction'], phases: [
    { id: 'through', w: 0.2, sketch: { ...THROUGH, lean: 30, spine: { lean: 22, twist: 16 }, hand_r: [64, 58, 6] }, orig: 'PROVISIONAL: the arm stretched at nothing, the body leaning after it' },
    { id: 'open', w: 0.62, sketch: { family: 'upright_lunge', lean: 26, hips: [18, -6, 0], spine: { lean: 18, twist: 10 }, head: { pitch: 8 }, hand_r: [54, 54, 8], hand_l: [-4, 62, -18], foot_r: [4, 22, 8], foot_l: [30, 2.5, -8], hands: { r: 'open', l: 'open' } },
      orig: 'PROVISIONAL: out of reach: on one foot with the other lifting behind, the near arm stretched out and the other flung back for balance' },
    { id: 'recover', w: 0.18, from: 'stance.aggressive', over: { lean: 8, head: { pitch: 4 } }, orig: 'PROVISIONAL: the foot coming down, the guard coming back' },
  ] },
  dodge: { dur: 24, legal: ['reaction'], phases: [
    { id: 'through', w: 0.2, sketch: { ...THROUGH, lean: 28, hips: [26, -10, 0], spine: { lean: 22, twist: 24 }, head: { pitch: 6, yaw: 22 } }, orig: 'PROVISIONAL: the blow through where he was, the shoulders already turning past' },
    { id: 'open', w: 0.62, sketch: { family: 'upright_lunge', lean: 34, hips: [28, -14, 0], spine: { lean: 26, twist: 22 }, head: { pitch: 0, yaw: 38 }, hand_r: [40, 44, 10], hand_l: [26, 38, -12], foot_r: [8, 2.5, 10], foot_l: [38, 2.5, -10], hands: { r: 'open', l: 'open' } },
      orig: 'PROVISIONAL: carried on past him bent forward with the arms hanging low in front, the head turned back over the shoulder looking for him' },
    { id: 'recover', w: 0.18, from: 'stance.aggressive', over: { lean: 8, head: { pitch: 4 } }, orig: 'PROVISIONAL: turning back, the guard coming up' },
  ] },
};
