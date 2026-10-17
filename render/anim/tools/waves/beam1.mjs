// PROVISIONAL (VFX's thick beams, docs/vfx/beam-look.md "Open for Orb": the Protagonist's beam "from the heel of the palm" needs Animation's palm pose at the beam's origin; the Empress's guards' measured bolt,
// docs/combat/pending/roster/moveset.guard.json energy.x.01). Legal has not screened these; the rule for them is Legal's franchise rule: NO BALL CHARGING IN THE HAND. Parked (--waves). Prefix bm.
//   holds (the beam layer: data/anim/pair_live.json roles.<fighter>.beam, read by AnimFighter._beam_layer):
//     charge_protagonist / fire_protagonist   The Protagonist's cast. Charging: side-on, the weight back, ONE arm drawn back with the elbow out and the OPEN palm at the shoulder facing forward, flat, the fingers
//                                             together and up, nothing in it and nothing between the palm and the other hand; the other hand open and held out toward the rival as the aim, shoulder height (never together
//                                             with it, never cupped, never at the hip). Firing: the arm thrown straight out at shoulder height with the HEEL of the palm leading (the beam leaves the heel of the palm),
//                                             the fingers up, the body lunged behind it, the other hand open and low at the rear.
//     charge_antihero / fire_antihero         The Anti-hero's cast, in his straight lines. Charging: the CLOSED fist drawn back along the shoulder line with the forearm plate up, the rear hand open and forward in guard
//                                             (never pointing); firing: the fist driven straight out at shoulder height, the forearm plate behind it (the light sits on the plate and the knuckle edges, VFX).
//   sequences:
//     guard_bolt   The guards' measured bolt from an open palm, planted: the palm drawn back to the shoulder (4 ticks), thrown flat to shoulder height (3), back to the stance (5).
const OPEN = { hands: { r: 'open', l: 'open' } };
const FIST = { hands: { r: 'fist', l: 'open' } };
const WIDE = { foot_r: [-14, 2.5, 10], foot_l: [14, 2.5, -8] };
export const holds = {
  charge_protagonist: { sketch: { family: 'upright', lean: -2, hip_twist: 34, hips: [-4, -6, 0], spine: { lean: 2, twist: -26 }, head: { pitch: 2, yaw: 18 }, hand_r: [-8, 64, 24], pole_hand_r: [-16, 10, 20], hand_l: [34, 60, -10], ...WIDE, ...OPEN,
      _legal: ['hands_open_or_claw', 'not_at_hip', 'not_both_arms_back', 'wrists_apart'] },
    orig: 'PROVISIONAL: the Protagonist charging a beam: side-on with the weight back, one arm drawn back at shoulder height and the open palm at the shoulder facing forward, flat, the other hand open in guard at the chest a shoulder width away; nothing held in the hand' },
  fire_protagonist: { sketch: { family: 'upright_lunge', lean: 14, hip_twist: 18, hips: [16, -8, 0], spine: { lean: 6, twist: 16 }, head: { pitch: 0, yaw: 4 }, hand_r: [58, 62, 9], pole_hand_r: [4, 2, 8], hand_l: [10, 48, -12],
      foot_r: [-12, 2.5, 10], foot_l: [24, 2.5, -8], ...OPEN, _legal: ['hands_open_or_claw', 'not_at_hip', 'wrists_apart'] },
    orig: 'PROVISIONAL: the Protagonist casting: the arm thrown straight out at shoulder height with the heel of the open palm leading, the fingers up, the body lunged behind it, the other hand open and low at the rear' },
  charge_antihero: { sketch: { family: 'upright', lean: 4, hip_twist: 30, hips: [-2, -6, 0], spine: { lean: 4, twist: -24 }, head: { pitch: 2, yaw: 16 }, hand_r: [-8, 64, 22], pole_hand_r: [-16, 10, 18], hand_l: [34, 60, -8], ...WIDE, ...FIST,
      _legal: ['not_at_hip', 'not_both_arms_back', 'wrists_apart'] },
    orig: 'PROVISIONAL: the Anti-hero charging a beam: side-on, the closed fist drawn back along the shoulder line with the forearm plate up, the rear hand open and forward in guard, never pointing; nothing held in the hand' },
  fire_antihero: { sketch: { family: 'upright_lunge', lean: 14, hip_twist: 20, hips: [16, -8, 0], spine: { lean: 6, twist: 20 }, head: { pitch: 0, yaw: 4 }, hand_r: [58, 63, 8], pole_hand_r: [4, 2, 8], hand_l: [14, 54, -8],
      foot_r: [-12, 2.5, 10], foot_l: [24, 2.5, -8], ...FIST, _legal: ['not_at_hip', 'wrists_apart'] },
    orig: 'PROVISIONAL: the Anti-hero casting: the closed fist driven straight out at shoulder height, the forearm plate behind it, the other hand open in guard' },
};

export const sequences = {
  guard_bolt: { dur: 12, legal: ['hands_open_or_claw', 'not_at_hip'], phases: [
    { id: 'wind', ticks: 4, sketch: { family: 'upright', lean: 4, hips: [0, -4, 0], spine: { lean: 2, twist: -14 }, head: { pitch: 2, yaw: 4 }, hand_r: [10, 60, 18], pole_hand_r: [-4, 4, 14], hand_l: [16, 54, -8], ...WIDE, ...OPEN },
      orig: 'PROVISIONAL: the guard readying a measured bolt: the open palm drawn back to the shoulder, the other hand open at his chest, both feet planted' },
    { id: 'fire', ticks: 3, sketch: { family: 'upright', lean: 8, hips: [4, -4, 0], spine: { lean: 2, twist: 16 }, head: { pitch: 0, yaw: 4 }, hand_r: [48, 60, 10], pole_hand_r: [2, 0, 8], hand_l: [14, 54, -8], ...WIDE, ...OPEN },
      orig: 'PROVISIONAL: the bolt leaving: the open palm thrown flat to shoulder height, the feet where they were' },
    { id: 'settle', ticks: 5, from: 'stance.aggressive', over: { lean: 8, ...OPEN }, orig: 'PROVISIONAL: back to the stance, the hand open' },
  ] },
};
