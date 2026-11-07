// The Anti-hero's two flight-strike blows that the library did not have (docs/animation/flight-strikes.md; docs/design/playable-build.md section 1): a HEAVY blow for the arc under (Y, thrown low as he skims
// beneath the rival) and a LIGHT blow thrown while moving away (X on a parting shot). His identity: fists, plates, knees and elbows, never a palm; straight lines and drops. Prefix rl. Parked: the fighter's `more`
// list names this wave behind the flight-strike switch. Legal's lines (zip-screen.md): no open hand, never a hand at a hip, no leap (the body skims, it does not jump), no clasp, nothing held.
//   slide_knee    knee cap, line, legs         HEAVY  the arc under's Y: the knee driven into the legs from a low skim, both fists tucked in front of him
//   trail_elbow   elbow point, arc out, chest  LIGHT  the parting shot's X: going away, the point of the elbow thrown back across his chest as he turns off
const FIST = { hands: { r: 'fist', l: 'fist' } };
const FLY_X = { load: 6, follow: 4, recover: 4 };
const FLY_Y = { load: 10, follow: 6, recover: 8 };

const NEW = {
  slide_knee: { like: 'rising_knee', limb: 'knee', target: 'legs', weight: 'heavy', ticks: FLY_Y, ground: 'no', look: 'Skimming low under him, the knee driven into his legs with the shoulder behind it, both fists tucked in close.' },
  trail_elbow: { like: 'short_elbow', limb: 'elbow', target: 'chest', weight: 'light', ticks: FLY_X, ground: 'no', look: 'Going away, turning off from him: the point of the elbow thrown back across his chest as he leaves.' },
};
export function rows(wave1) {
  const by = Object.fromEntries(wave1.map(r => [r.id.replace('strike.', ''), r]));
  return Object.entries(NEW).map(([n, o]) => {
    const b = by[o.like];
    return { ...b, id: 'strike.' + n, limb: o.limb, target: o.target, weight: o.weight, ticks: { ...o.ticks }, ...(o.ground ? { ground: o.ground } : {}), look: o.look, _estimate: 'range borrowed from strike.' + o.like + ' until Combat\'s rows land; ticks are the flight strike\'s (playable-build.md section 1)' };
  });
}

export const strikes = {
  slide_knee: { kind: 'knee', target: 'legs', step_max: 14, named: true, legal: ['no_clasp'],
    chamber: { family: 'crouched', lean: 22, hips: [0, -18, 0], spine: { lean: 12, twist: -8 }, head: { pitch: 12 }, hand_r: [20, 40, 12], hand_l: [22, 42, -8], foot_r: [0, 8, 8], pole_foot_r: [10, 1, 0], foot_l: [8, 2.5, -7], ...FIST },
    contact: { family: 'upright_lunge', lean: 8, hips: [8, -18, 0], spine: { lean: 14, twist: 8 }, head: { pitch: 14 }, hand_r: [14, 52, 10], hand_l: [24, 46, -10], foot_r: [24, 20, 10], pole_foot_r: [10, 1, 0], foot_l: [6, 3, -7], ...FIST },
    follow: { foot_r: [10, 8, 8], hand_r: [22, 46, 10], hand_l: [24.9, 41.4, -6.9] },
    orig: 'skimming low under him, the knee driven into his legs with the shoulder behind it, both fists tucked in close' },
  trail_elbow: { kind: 'elbow', target: 'chest', step_max: 12, named: true, legal: ['no_leap', 'no_clasp'],
    chamber: { family: 'upright', lean: -6, hips: [-8, -3, 0], spine: { lean: -4, twist: -30 }, head: { yaw: 14 }, hand_r: [10, 56, 10], pole_hand_r: [-6, 2, 8], hand_l: [20, 54, -8], foot_r: [-14, 2.5, 10], foot_l: [4, 2.5, -8], ...FIST },
    contact: { family: 'upright', lean: -10, hips: [-4, -2, 0], spine: { lean: -2, twist: 32 }, head: { yaw: -18 }, hand_r: [25.1, 54.2, 19.6], pole_hand_r: [4, 6, 14], hand_l: [18.9, 56.1, -10], foot_r: [-18, 2.5, 10], foot_l: [2, 2.5, -8], ...FIST },
    follow: { hand_r: [16, 54, 14] },
    orig: 'going away, turning off from him: the point of the elbow thrown back across his chest as he leaves' },
};
