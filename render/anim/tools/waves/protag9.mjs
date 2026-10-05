// The Protagonist's six new intro gestures (docs/narrative/dynamic-intros.md section 11.3: a gesture intent is a meaning; Animation maps it to the fighter's own small motion). Each is a two-pose
// motion of 16 to 24 ticks played over whatever he is standing in, by a mask on the head, neck, spine and arms (data/anim/pair_live.json `gestures`), easing in and out. Open hands only, hands apart
// and outside the hip zone, nothing pointed, no fist, no beckon, nothing that reads as a taunt (the claim and the dismiss are a breath and a turned head, not a challenge). Parked (--waves); played
// only by an intro_gesture event. Prefix pi. The other four of the ten he has already (nod, brace, bounce, fist-palm: pair_live.json).
//   appraise   a slow look over the other: the head pitching down and then up, level
//   dismiss    the head turned away and a small shake, the hands open and still
//   defer      a short bow from the waist, the hands open and low at his sides
//   claim      the chest up and a breath, the feet planted wide, the hands open and away from the body
//   check      a glance up and aside, the chin lifted, then back
//   soften     the shoulders dropping, both open palms turning outward a little
const OPEN = { hands: { r: 'open', l: 'open' } };
const L = ['hands_open_or_claw', 'not_at_hip'];
const FEET = { foot_r: [-8, 2.5, 9], foot_l: [14, 2.5, -7] };
export const sequences = {
  appraise: { dur: 22, legal: L, phases: [
    { id: 'low', ticks: 10, sketch: { family: 'upright', lean: 2, hips: [0, -2, 0], spine: { lean: 4, twist: 0 }, head: { pitch: 20, yaw: 0 }, hand_r: [16, 50, 16], hand_l: [16, 50, -16], ...FEET, ...OPEN, _legal: L },
      orig: 'looking him over: the head down, the open hands loose at his sides' },
    { id: 'high', ticks: 12, sketch: { family: 'upright', lean: 0, hips: [0, -1, 0], spine: { lean: -4, twist: 0 }, head: { pitch: -8, yaw: 0 }, hand_r: [16, 50, 16], hand_l: [16, 50, -16], ...FEET, ...OPEN, _legal: L },
      orig: 'the look coming back up to level: the chin a little raised, the chest open' }] },
  dismiss: { dur: 16, legal: L, phases: [
    { id: 'turn', ticks: 8, sketch: { family: 'upright', lean: 0, hips: [0, -2, 0], spine: { lean: 0, twist: 10 }, head: { pitch: -2, yaw: 38 }, hand_r: [16, 48, 18], hand_l: [16, 48, -18], ...FEET, ...OPEN, _legal: L },
      orig: 'the head turned away from him, the shoulders a little round, the open hands still' },
    { id: 'shake', ticks: 8, sketch: { family: 'upright', lean: 0, hips: [0, -2, 0], spine: { lean: 0, twist: 6 }, head: { pitch: 2, yaw: 26 }, hand_r: [16, 48, 18], hand_l: [16, 48, -18], ...FEET, ...OPEN, _legal: L },
      orig: 'a small shake of the head, still turned away' }] },
  defer: { dur: 20, legal: L, phases: [
    { id: 'bow', ticks: 10, sketch: { family: 'upright', lean: 12, hips: [2, -4, 0], spine: { lean: 14, twist: 0 }, head: { pitch: 22, yaw: 0 }, hand_r: [22, 38, 15], hand_l: [22, 38, -15], ...FEET, ...OPEN, _legal: L },
      orig: 'a short bow from the waist, the open hands low and apart at his sides' },
    { id: 'rise', ticks: 10, sketch: { family: 'upright', lean: 4, hips: [0, -2, 0], spine: { lean: 4, twist: 0 }, head: { pitch: 8, yaw: 0 }, hand_r: [16, 50, 16], hand_l: [16, 50, -16], ...FEET, ...OPEN, _legal: L },
      orig: 'coming up from the bow, the eyes back on him' }] },
  claim: { dur: 24, legal: L, phases: [
    { id: 'plant', ticks: 10, sketch: { family: 'upright', lean: -4, hips: [0, 0, 0], spine: { lean: -6, twist: 0 }, head: { pitch: -4, yaw: 0 }, hand_r: [10, 52, 26], hand_l: [10, 52, -26], foot_r: [-12, 2.5, 12], foot_l: [14, 3, -11], ...OPEN, _legal: L },
      orig: 'taking the space: the feet planted wide, the chest up, the open hands away from the body' },
    { id: 'breath', ticks: 14, sketch: { family: 'upright', lean: -2, hips: [0, -1, 0], spine: { lean: -3, twist: 0 }, head: { pitch: 0, yaw: 0 }, hand_r: [12, 50, 22], hand_l: [12, 50, -22], foot_r: [-12, 2.5, 12], foot_l: [14, 3, -11], ...OPEN, _legal: L },
      orig: 'a breath out, the shoulders settling, the stance held' }] },
  check: { dur: 16, legal: L, phases: [
    { id: 'up', ticks: 8, sketch: { family: 'upright', lean: 0, hips: [0, -1, 0], spine: { lean: -4, twist: 8 }, head: { pitch: -24, yaw: 30 }, hand_r: [16, 50, 16], hand_l: [16, 50, -16], ...FEET, ...OPEN, _legal: L },
      orig: 'a glance up and aside, the chin lifted' },
    { id: 'back', ticks: 8, sketch: { family: 'upright', lean: 0, hips: [0, -1, 0], spine: { lean: -2, twist: 2 }, head: { pitch: -4, yaw: 10 }, hand_r: [16, 50, 16], hand_l: [16, 50, -16], ...FEET, ...OPEN, _legal: L },
      orig: 'the glance coming back, nearly level' }] },
  soften: { dur: 20, legal: L, phases: [
    { id: 'drop', ticks: 10, sketch: { family: 'upright', lean: 2, hips: [0, -3, 0], spine: { lean: 6, twist: 0 }, head: { pitch: 6, yaw: 0 }, hand_r: [20, 46, 24], hand_l: [20, 46, -24], ...FEET, ...OPEN, _legal: L },
      orig: 'the shoulders dropping, both open palms turned out a little and apart' },
    { id: 'rest', ticks: 10, sketch: { family: 'upright', lean: 1, hips: [0, -2, 0], spine: { lean: 3, twist: 0 }, head: { pitch: 3, yaw: 0 }, hand_r: [16, 48, 20], hand_l: [16, 48, -20], ...FEET, ...OPEN, _legal: L },
      orig: 'settling, the hands loose and open' }] },
};
export const cues = {};
