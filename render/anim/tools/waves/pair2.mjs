// The zip's grab poses both fighters share (docs/animation/zip.md; docs/design/melee-press-feel.md section 2c; Orb's prototype docs/ep/prototypes/lt-zip-v4.html): the tackle that carries the
// rival along the line, and the lift and throw of a held A. Everything else of the zip is played by poses that exist (the entries' dash, coil, spring and hop back). Hold poses, not strikes: each
// has an `_orig` line. Legal's lines: open hands only, both hands apart on a two-hand hold (wrists apart, no clasp), nothing lit, no arm held raised after a blow (the lift is a hold at chest and
// shoulder height, never overhead), no hand at the hip. Parked in the wave sense (baked with the pair's `more` list, played only by a zip). Prefix zp.
//   tackle   the attacker driving the rival along the line: shoulder first, both open hands forward at the chest, the body folded forward over the lead leg
//   carried  the rival carried: leaning back over the tackle, the arms limp, the heels dragging
//   lift     the attacker taking the rival's weight: knees bent, leaning back under it, both open hands at shoulder height and apart
//   lifted   the rival raised: leaning back and held at the chest, the feet clear of the floor, the arms limp
//   throw    the release: the arms thrown forward and down, the body following them
const OPEN = { hands: { r: 'open', l: 'open' } };
const L = ['hands_open_or_claw', 'wrists_apart', 'not_at_hip'];
export const holds = {
  tackle: { sketch: { family: 'upright_lunge', lean: 32, hips: [14, -8, 0], spine: { lean: 14, twist: 6 }, head: { pitch: 12 }, hand_r: [40, 52, 12], hand_l: [40, 52, -12],
      foot_r: [-8, 2.5, 9], foot_l: [24, 2.5, -7], ...OPEN, _legal: L },
    orig: 'the tackle: the shoulder driven in first, both open hands forward at the chest and apart, the body folded forward over the lead leg' },
  carried: { sketch: { family: 'upright', lean: -22, hips: [-6, -6, 0], spine: { lean: -6, twist: 0 }, head: { pitch: -8 }, hand_r: [14, 47, 15], hand_l: [13, 47, -15],
      foot_r: [-10, 5, 9], foot_l: [4, 4, -7], ...OPEN, _legal: ['hands_open_or_claw', 'not_at_hip'] },
    orig: 'carried along the line: leaning back over the tackle, the arms limp at his sides, the heels dragging' },
  lift: { sketch: { family: 'crouched', lean: -6, hips: [-2, -10, 0], spine: { lean: -6, twist: 0 }, head: { pitch: 6 }, hand_r: [25, 65, 12], hand_l: [25, 65, -12],
      foot_r: [-8, 2.5, 9], foot_l: [14, 2.5, -7], ...OPEN, _legal: L },
    orig: 'taking the weight: the knees bent, leaning back under it, both open hands at shoulder height and apart' },
  lifted: { sketch: { family: 'upright', lean: -26, hips: [-4, -2, 0], spine: { lean: -8, twist: 0 }, head: { pitch: -10 }, hand_r: [14, 48, 15], hand_l: [13, 48, -15],
      foot_r: [-8, 14, 9], foot_l: [2, 12, -7], ...OPEN, _legal: ['hands_open_or_claw', 'not_at_hip'] },
    orig: 'raised and held at the chest: leaning back, the feet clear of the floor, the arms limp' },
  throw: { sketch: { family: 'upright_lunge', lean: 26, hips: [14, -6, 0], spine: { lean: 12, twist: 14 }, head: { pitch: 10 }, hand_r: [42, 50, 12], hand_l: [40, 46, -12],
      foot_r: [-8, 2.5, 9], foot_l: [24, 2.5, -7], ...OPEN, _legal: L },
    orig: 'the release: both open hands thrown forward and down and apart, the body following them' },
};
export const sequences = {
  tackle: { dur: 22, legal: L, phases: [{ id: 'drive', ticks: 22, sketch: holds.tackle.sketch, orig: holds.tackle.orig }] },
  lift: { dur: 18, legal: L, phases: [{ id: 'raise', ticks: 18, sketch: holds.lift.sketch, orig: holds.lift.orig }] },
  throw: { dur: 12, legal: L, phases: [{ id: 'release', ticks: 12, sketch: holds.throw.sketch, orig: holds.throw.orig }] },
};
export const cues = {};
