// PROVISIONAL (the nine cells, docs/animation/nine-cells.md): the legs, pelvis and spine of a held medium and a held heavy, so the two holds each have a body of their own (Game Design's section 15: "a held Y and a held B
// each with a pose of their own and a flash at full"; on the phone Attack is read by how long it is held, so the body teaches the difference). Mixed into the held blow's own tell by the press style's `hold` row
// (`pose` by fighter: only the bones of `squash_pose.bones` are taken, so the arms stay the piece's chamber). One phase each, so the sequence never holds; prefix ch.
//   y_p, y_r   the charged medium: patient and forward, one shoulder wound back, the weight coming onto the front foot: a close being prepared (the Protagonist's compact, the rival's chin up)
//   b_p, b_r   the charged heavy: sunk wide and low, the shoulders wound round, everything loaded: the big read (the Protagonist's controlled, the rival's open)
const O = { hands: { r: 'open', l: 'open' } };
export const sequences = {
  y_p: { dur: 10, phases: [{ id: 'load', ticks: 10, sketch: { family: 'upright', lean: 12, hips: [0, -6, 0], spine: { lean: 10, twist: -14 }, head: { pitch: 6 }, hand_r: [6, 60, 12], hand_l: [22, 58, -10], foot_r: [-8, 2.5, 10], foot_l: [14, 2.5, -8], ...O },
    orig: 'PROVISIONAL: the charged medium: forward and patient, one shoulder wound back, the weight moving onto the front foot' }] },
  y_r: { dur: 10, phases: [{ id: 'load', ticks: 10, sketch: { family: 'upright', lean: -2, hips: [-4, -8, 0], spine: { lean: 0, twist: -20 }, head: { pitch: -6 }, hand_r: [4, 62, 14], hand_l: [20, 60, -12], foot_r: [-12, 2.5, 10], foot_l: [14, 2.5, -8], ...O },
    orig: 'PROVISIONAL: the charged medium, his way: the weight sunk back a little, the shoulder wound round, the chin up' }] },
  b_p: { dur: 10, phases: [{ id: 'load', ticks: 10, sketch: { family: 'crouched', lean: 14, hips: [-2, -16, 0], spine: { lean: 14, twist: -10 }, head: { pitch: 12 }, hand_r: [8, 58, 12], hand_l: [22, 56, -10], foot_r: [-14, 2.5, 10], foot_l: [18, 2.5, -9], ...O },
    orig: 'PROVISIONAL: the charged heavy: sunk wide and low, the shoulders wound, the head down on him, everything loaded' }] },
  b_r: { dur: 10, phases: [{ id: 'load', ticks: 10, sketch: { family: 'crouched', lean: 8, hips: [-6, -18, 0], spine: { lean: 8, twist: -24 }, head: { pitch: 0 }, hand_r: [4, 62, 16], hand_l: [20, 58, -12], foot_r: [-18, 2.5, 10], foot_l: [18, 2.5, -10], ...O },
    orig: 'PROVISIONAL: the charged heavy, his way: sunk very wide and low, the whole back wound round, the chin level and the limb drawn back in plain view' }] },
};
