// The rival's four new intro gestures (docs/narrative/dynamic-intros.md section 11.3). Formal and guarded: a chin dip, a half bow, a glance at his own forearm plate, a guard hand dropping. Each is a
// two-pose motion of 16 to 20 ticks played over whatever he is standing in, by a mask on the head, neck, spine and arms (data/anim/pair_live.json `gestures`). Open hands (blades), nothing pointed, no
// fist, no beckon, no crossed forearms, hands out of the hip zone; the defer's plate hand is laid on the coat, one hand only. Parked (--waves); played only by an intro_gesture event. Prefix ri.
// The other six of the ten he has already (the head tilt, the back turned, the dust brushed off the plate, the stillness, dropping the act, brace: pair_live.json).
//   acknowledge   a short chin dip, the eyes on the other
//   defer         a half bow, one open hand laid flat on the coat
//   check         a glance down at his own forearm plate, then up and aside
//   soften        the guard hand dropping, the head tilting back a little
const OPEN = { hands: { r: 'open', l: 'open' } };
const L = ['hands_open_or_claw', 'not_at_hip', 'no_cross_hold'];
const FEET = { foot_r: [-8, 2.5, 9], foot_l: [14, 2.5, -7] };
export const sequences = {
  acknowledge: { dur: 16, legal: L, phases: [
    { id: 'dip', ticks: 8, sketch: { family: 'upright', lean: 0, hips: [0, -2, 0], spine: { lean: 4, twist: 0 }, head: { pitch: 16, yaw: 0 }, hand_r: [18, 54, 12], hand_l: [14, 54, -10], ...FEET, ...OPEN, _legal: L },
      orig: 'a short dip of the chin, the eyes on him, the open hands where they were' },
    { id: 'up', ticks: 8, sketch: { family: 'upright', lean: 0, hips: [0, -2, 0], spine: { lean: 1, twist: 0 }, head: { pitch: 2, yaw: 0 }, hand_r: [18, 54, 12], hand_l: [14, 54, -10], ...FEET, ...OPEN, _legal: L },
      orig: 'the head back up, level' }] },
  defer: { dur: 20, legal: L, phases: [
    { id: 'bow', ticks: 10, sketch: { family: 'upright', lean: 8, hips: [1, -3, 0], spine: { lean: 12, twist: 0 }, head: { pitch: 18, yaw: 0 }, hand_r: [20, 48, 18], hand_l: [14, 58, 2], ...FEET, ...OPEN, _legal: L },
      orig: 'a half bow, one open hand laid flat on the coat, the other loose' },
    { id: 'rise', ticks: 10, sketch: { family: 'upright', lean: 3, hips: [0, -2, 0], spine: { lean: 4, twist: 0 }, head: { pitch: 6, yaw: 0 }, hand_r: [18, 54, 12], hand_l: [14, 54, -10], ...FEET, ...OPEN, _legal: L },
      orig: 'coming up, the hand leaving the coat' }] },
  check: { dur: 18, legal: L, phases: [
    { id: 'cuff', ticks: 9, sketch: { family: 'upright', lean: 0, hips: [0, -2, 0], spine: { lean: 4, twist: -4 }, head: { pitch: 26, yaw: -8 }, hand_r: [18, 54, 16], hand_l: [26, 56, -6], ...FEET, ...OPEN, _legal: L },
      orig: 'a glance down at his own forearm plate, the forearm raised a little in front of him' },
    { id: 'up', ticks: 9, sketch: { family: 'upright', lean: 0, hips: [0, -2, 0], spine: { lean: -1, twist: 2 }, head: { pitch: -4, yaw: 12 }, hand_r: [18, 54, 12], hand_l: [16, 54, -10], ...FEET, ...OPEN, _legal: L },
      orig: 'the look coming up and aside, the forearm lowering' }] },
  soften: { dur: 20, legal: L, phases: [
    { id: 'drop', ticks: 10, sketch: { family: 'upright', lean: 0, hips: [0, -2, 0], spine: { lean: 4, twist: 0 }, head: { pitch: -8, yaw: 6 }, hand_r: [16, 48, 18], hand_l: [14, 50, -14], ...FEET, ...OPEN, _legal: L },
      orig: 'the guard hand dropping, the head tilting back a little' },
    { id: 'rest', ticks: 10, sketch: { family: 'upright', lean: 0, hips: [0, -2, 0], spine: { lean: 2, twist: 0 }, head: { pitch: -2, yaw: 2 }, hand_r: [14, 52, 14], hand_l: [14, 54, -10], ...FEET, ...OPEN, _legal: L },
      orig: 'settling, the hands loose' }] },
};
export const cues = {};
