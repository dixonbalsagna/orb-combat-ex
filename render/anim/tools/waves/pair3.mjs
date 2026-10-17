// The throws of the grapple on A (docs/combat/grapple-hybrid.md section 2, from wave 4: docs/combat/pending/wave4-grabs.md; Game Design docs/design/grapple.md): the thrower's own side of each throw, three poses
// each: the load (the rival held close in front, the grip taken), the release (the arm or arms thrown out along the send) and the follow (the arms coming back). The held body is the sim's and the ragdoll's: these are only
// the thrower. The grip hands sit where the rival's collar, waist or shoulders stand about 30 units ahead (the clinch's own distance, docs/animation/clinch-sizing.md); the grip layer (slice C2) will solve them onto the real body.
// Eight throws by the stick (Combat's table): across toward `hurl` (the Protagonist) and `sling` (the Anti-hero), across away `turn_throw` and `back_throw`, down `drive_down` and `spike`, up `lift` and `jolt`.
// Legal g03 to g08: the hands never lock or lace (wrists 16 or more apart), a hold on the collar, waist, shoulders or arms only, the body whole and in view, a throw a plain send. h09: no crossed forearms, a one-arm fold at most.
// Prefix zq. Parked: nothing plays them until the sim has a held state. Originality: no franchise pose; every pose has an _orig line.
const OPEN = { hands: { r: 'open', l: 'open' } };
const LEGAL = ['no_clasp', 'wrists_apart'];

export const sequences = {
  hurl: { dur: 14, legal: LEGAL, phases: [
    { id: 'load', ticks: 6, sketch: { family: 'crouched', lean: 18, hips: [8, -12, 0], spine: { lean: 14, twist: 40 }, head: { pitch: 8 }, hand_r: [30, 50, 12], hand_l: [26, 26, -12],
        foot_r: [-4, 2.5, 11], foot_l: [14, 2.5, -9], ...OPEN },
      orig: 'a hip throw loaded: his back turned into the rival, hips under theirs, one hand at the collar and one at the hip' },
    { id: 'release', ticks: 2, sketch: { family: 'upright_lunge', lean: 24, hips: [14, -14, 0], spine: { lean: 18, twist: -30 }, head: { pitch: 10 }, hand_r: [46, 40, 12], hand_l: [44, 36, -10],
        foot_r: [-2, 2.5, 11], foot_l: [22, 2.5, -9], ...OPEN },
      orig: 'the release: both arms thrown out in one long line after the rival, the body folding over the hip' },
    { id: 'follow', ticks: 6, sketch: { family: 'upright', lean: 12, hips: [8, -8, 0], spine: { lean: 8, twist: -10 }, head: { pitch: 6 }, hand_r: [30, 46, 13], hand_l: [26, 44, -8],
        foot_r: [-6, 2.5, 10], foot_l: [16, 2.5, -8], ...OPEN },
      orig: 'the follow-through: the arms coming back, the weight settling' },
  ] },
  sling: { dur: 14, legal: ['no_clasp'], phases: [
    { id: 'load', ticks: 6, sketch: { family: 'upright', lean: 8, hips: [4, -6, 0], spine: { lean: 6, twist: 24 }, head: { pitch: 4 }, hand_r: [24, 50, 16], hand_l: [14, 50, -2],
        foot_r: [-6, 2.5, 10], foot_l: [14, 2.5, -8], ...OPEN },
      orig: 'the sling loaded: the collar hand drawn in beside his shoulder, the other forearm a single fold across the body with the hand at the chin' },
    { id: 'release', ticks: 2, sketch: { family: 'upright_lunge', lean: 14, hips: [10, -8, 0], spine: { lean: 10, twist: -26 }, head: { pitch: 6 }, hand_r: [56, 48, 18], hand_l: [12, 52, -6],
        foot_r: [-4, 2.5, 10], foot_l: [20, 2.5, -8], ...OPEN },
      orig: 'the release at full reach: the arm straight like a thrown blade, the other hand staying at the chin' },
    { id: 'follow', ticks: 6, sketch: { family: 'upright', lean: 8, hips: [6, -4, 0], spine: { lean: 6, twist: -8 }, head: { pitch: 4 }, hand_r: [40, 48, 17], hand_l: [14, 50, -4],
        foot_r: [-6, 2.5, 10], foot_l: [16, 2.5, -8], ...OPEN },
      orig: 'the arm left out where it let go, the weight coming back' },
  ] },
  turn_throw: { dur: 18, legal: LEGAL, phases: [
    { id: 'load', ticks: 6, sketch: { family: 'upright', lean: 10, hips: [2, -6, 0], spine: { lean: 6, twist: 60 }, head: { pitch: 4, yaw: -20 }, hand_r: [22, 46, 18], hand_l: [6, 40, -14],
        foot_r: [-8, 2.5, 10], foot_l: [12, 2.5, -8], ...OPEN },
      orig: 'half a turn begun with the rival carried round him: the collar hand held at a bent arm on his outside, the shoulders turning' },
    { id: 'release', ticks: 2, sketch: { family: 'upright', lean: 8, hips: [0, -6, 0], spine: { lean: 6, twist: -50 }, head: { pitch: 4, yaw: 20 }, hand_r: [20, 48, 28], hand_l: [6, 44, -16],
        foot_r: [-10, 2.5, 10], foot_l: [10, 2.5, -8], ...OPEN },
      orig: 'let go with his back to where he first faced: the arm thrown out to the side' },
    { id: 'follow', ticks: 10, sketch: { family: 'upright', lean: 6, hips: [0, -4, 0], spine: { lean: 4, twist: -16 }, head: { pitch: 4 }, hand_r: [20, 52, 20], hand_l: [16, 50, -10],
        foot_r: [-8, 2.5, 10], foot_l: [10, 2.5, -8], ...OPEN },
      orig: 'settling out of the turn, the guard coming back up' },
  ] },
  back_throw: { dur: 16, legal: LEGAL, phases: [
    { id: 'load', ticks: 6, sketch: { family: 'crouched', lean: 22, hips: [4, -18, 0], spine: { lean: 18 }, head: { pitch: 10 }, hand_r: [26, 26, 14], hand_l: [26, 26, -14],
        foot_r: [-6, 2.5, 12], foot_l: [10, 2.5, -10], ...OPEN },
      orig: 'dropped under the rival: the knees bent, one hand on each side of their waist, never joined' },
    { id: 'release', ticks: 2, sketch: { family: 'upright', lean: -22, hips: [-4, -4, 0], spine: { lean: -20 }, head: { pitch: -8 }, hand_r: [8, 62, 20], hand_l: [8, 60, -18],
        foot_r: [-10, 2.5, 10], foot_l: [8, 2.5, -8], ...OPEN },
      orig: 'arched back: the arms swept up and over, the rival leaving over his shoulder' },
    { id: 'follow', ticks: 8, sketch: { family: 'upright', lean: -8, hips: [-2, -4, 0], spine: { lean: -8 }, head: { pitch: -4 }, hand_r: [16, 56, 16], hand_l: [16, 54, -14],
        foot_r: [-8, 2.5, 10], foot_l: [8, 2.5, -8], ...OPEN },
      orig: 'coming upright, the arms lowering' },
  ] },
  drive_down: { dur: 18, legal: LEGAL, phases: [
    { id: 'load', ticks: 6, sketch: { family: 'upright', lean: -6, hips: [0, -8, 0], spine: { lean: -4 }, head: { pitch: 0 }, hand_r: [24, 58, 14], hand_l: [24, 56, -12],
        foot_r: [-4, 2.5, 11], foot_l: [10, 2.5, -9], ...OPEN },
      orig: 'the rival lifted to shoulder height on both forearms: the forearms up and forward, the elbows in, the hands apart' },
    { id: 'release', ticks: 2, sketch: { family: 'upright_lunge', lean: 30, hips: [14, -14, 0], spine: { lean: 22 }, head: { pitch: 14 }, hand_r: [40, 16, 14], hand_l: [38, 14, -12],
        foot_r: [-2, 2.5, 11], foot_l: [24, 2.5, -9], ...OPEN },
      orig: 'driven down ahead of him: the arms thrust down and forward, his weight falling in behind them' },
    { id: 'follow', ticks: 10, sketch: { family: 'crouched', lean: 20, hips: [10, -16, 0], spine: { lean: 14 }, head: { pitch: 10 }, hand_r: [30, 24, 13], hand_l: [28, 22, -11],
        foot_r: [-4, 2.5, 11], foot_l: [16, 2.5, -9], ...OPEN },
      orig: 'following the drive down, low, the arms still reaching' },
  ] },
  spike: { dur: 16, legal: ['no_clasp'], phases: [
    { id: 'load', ticks: 6, sketch: { family: 'upright', lean: -4, hips: [0, -2, 0], spine: { lean: -4 }, head: { pitch: -2 }, hand_r: [14, 76, 12], hand_l: [14, 54, -12],
        foot_r: [-4, 4, 10], foot_l: [8, 4, -8], ...OPEN },
      orig: 'risen a body length with the rival hanging from the collar hand: the arm up beside his head, the other hand at his chest' },
    { id: 'release', ticks: 2, sketch: { family: 'upright_lunge', lean: 28, hips: [12, -12, 0], spine: { lean: 20 }, head: { pitch: 12 }, hand_r: [34, 10, 12], hand_l: [14, 52, -10],
        foot_r: [-2, 2.5, 10], foot_l: [20, 2.5, -8], ...OPEN },
      orig: 'the arm whipped down past his own knee, the body folding over it' },
    { id: 'follow', ticks: 8, sketch: { family: 'crouched', lean: 18, hips: [8, -14, 0], spine: { lean: 12 }, head: { pitch: 8 }, hand_r: [24, 20, 12], hand_l: [14, 50, -8],
        foot_r: [-4, 2.5, 10], foot_l: [14, 2.5, -8], ...OPEN },
      orig: 'low after the spike, the arm still down' },
  ] },
  lift: { dur: 16, legal: LEGAL, phases: [
    { id: 'load', ticks: 6, sketch: { family: 'upright', lean: -4, hips: [0, -8, 0], spine: { lean: -2 }, head: { pitch: 0 }, hand_r: [26, 52, 12], hand_l: [26, 52, -12],
        foot_r: [-4, 2.5, 11], foot_l: [10, 2.5, -9], ...OPEN },
      orig: 'open hands under the rival\'s arms at the shoulders: the hands apart, the knees bent to lift' },
    { id: 'release', ticks: 2, sketch: { family: 'upright', lean: -8, hips: [0, -2, 0], spine: { lean: -6, twist: 10 }, head: { pitch: -4 }, hand_r: [22, 78, 14], hand_l: [22, 76, -12],
        foot_r: [-4, 4, 10], foot_l: [8, 4, -8], ...OPEN },
      orig: 'a rising turn that sends him up: the arms thrown up, the legs straightening' },
    { id: 'follow', ticks: 8, sketch: { family: 'upright', lean: -2, hips: [0, -4, 0], spine: { lean: -2 }, head: { pitch: -2 }, hand_r: [22, 66, 14], hand_l: [22, 64, -12],
        foot_r: [-6, 2.5, 10], foot_l: [8, 2.5, -8], ...OPEN },
      orig: 'the arms coming down, watching him go up' },
  ] },
  jolt: { dur: 14, legal: ['no_clasp'], phases: [
    { id: 'load', ticks: 6, sketch: { family: 'crouched', lean: 10, hips: [4, -14, 0], spine: { lean: 8 }, head: { pitch: 6 }, hand_r: [26, 50, 12], hand_l: [14, 50, -2],
        foot_r: [-6, 2.5, 10], foot_l: [12, 2.5, -8], ...OPEN },
      orig: 'the plate set at the collar, low under it: the knees bent, the other forearm a single fold across the body, the hand at the chin' },
    { id: 'release', ticks: 2, sketch: { family: 'upright', lean: -10, hips: [4, -4, 0], spine: { lean: -8 }, head: { pitch: -4 }, hand_r: [30, 70, 14], hand_l: [14, 52, -4],
        foot_r: [-6, 2.5, 10], foot_l: [10, 2.5, -8], ...OPEN },
      orig: 'a straight shove upward from the hips: the legs straightening, the arm driving up' },
    { id: 'follow', ticks: 6, sketch: { family: 'upright', lean: -4, hips: [2, -4, 0], spine: { lean: -4 }, head: { pitch: -2 }, hand_r: [24, 60, 13], hand_l: [14, 52, -4],
        foot_r: [-6, 2.5, 10], foot_l: [10, 2.5, -8], ...OPEN },
      orig: 'the arm coming back down' },
  ] },
};
