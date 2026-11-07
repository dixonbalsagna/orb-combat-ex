// The Protagonist's two flight-strike blows that the library did not have (docs/animation/flight-strikes.md; Game Design's docs/design/playable-build.md section 1: hold LT, point the left stick, press X, Y or B).
// Every other cell of the grammar is an existing key set; two had none that read right: a HEAVY blow for the arc under (Y, thrown low as he skims beneath the rival: the library's only heavy blows at the legs are the
// super tier's) and a LIGHT blow thrown while moving away (X on a parting shot: the library's lights that look back are standing spins). Prefix pl. Parked: the fighter's `more` list names this wave behind the flight-strike
// switch. His own sketches (open hands, the edge of the foot, the blade of the hand). Legal's lines (zip-screen.md): hands open or clawed, never at a hip, no leap (the body skims, it does not jump), no clasp, nothing held.
//   skim_heel       foot edge, arc out, legs      HEAVY  the arc under's Y: the edge of the foot swung through at shin height from a low skim, one hand trailing near the ground for the balance
//   trail_backhand  hand blade, arc out, chest    LIGHT  the parting shot's X: moving away, the body half turned back to him and the blade of the hand swung out over the shoulder as he goes
const OPEN = { hands: { r: 'open', l: 'open' } };
const FLY_X = { load: 6, follow: 4, recover: 4 };     // X in a flight strike: the 6-tick tell
const FLY_Y = { load: 10, follow: 6, recover: 8 };    // Y: the 10-tick tell

const NEW = {
  skim_heel: { like: 'roundhouse', limb: 'foot', target: 'legs', weight: 'heavy', ticks: FLY_Y, ground: 'no', look: 'Skimming low under him, the edge of the foot swung through at shin height with the whole body behind it and one hand trailing near the ground.' },
  trail_backhand: { like: 'backfist', limb: 'hand', target: 'chest', weight: 'light', ticks: FLY_X, ground: 'no', look: 'Going away, half turned back to him: the blade of the hand swung out over the shoulder across his chest as he leaves.' },
};
export function rows(wave1) {
  const by = Object.fromEntries(wave1.map(r => [r.id.replace('strike.', ''), r]));
  return Object.entries(NEW).map(([n, o]) => {
    const b = by[o.like];
    return { ...b, id: 'strike.' + n, limb: o.limb, target: o.target, weight: o.weight, ticks: { ...o.ticks }, ...(o.ground ? { ground: o.ground } : {}), look: o.look, _estimate: 'range borrowed from strike.' + o.like + ' until Combat\'s rows land; ticks are the flight strike\'s (playable-build.md section 1)' };
  });
}

export const strikes = {
  skim_heel: { kind: 'foot', target: 'legs', step_max: 14, named: true, legal: ['hands_open_or_claw', 'no_leap'],
    chamber: { family: 'crouched', lean: 30, hips: [-2, -26, 0], spine: { lean: 18, twist: -10 }, head: { pitch: 14, yaw: 6 }, hand_r: [14, 46, 14], hand_l: [22, 6, -10], foot_r: [-10, 5, 12], foot_l: [8, 2.5, -8], ...OPEN },
    contact: { family: 'crouched', lean: 26, hips: [8, -20, 0], spine: { lean: 10, twist: 12 }, head: { pitch: 10 }, hand_r: [14, 50, 14], hand_l: [22, 48, -8], foot_r: [38.5, 5.8, 16], foot_l: [-4, 3, -8], ...OPEN },
    follow: { hand_r: [12, 54, 12], foot_r: [24, 6, 14] },
    orig: 'skimming low under him, the edge of the foot swung through at shin height with the whole body behind it and one hand trailing near the ground' },
  trail_backhand: { from: 'hook', kind: 'hand', family: 'hand_arc', target: 'chest', named: true, legal: ['hands_open_or_claw', 'no_clasp', 'no_leap'],
    over: { all: { ...OPEN },
      chamber: { family: 'upright', lean: -8, hip_twist: -22, hips: [-8, -3, 0], spine: { lean: -6, twist: -34 }, head: { yaw: 16 }, hand_r: [8.5, 59.7, -2.7], pole_hand_r: [-4, 4, -4], hand_l: [22, 54, -8], foot_r: [-14, 2.5, 10], foot_l: [4, 2.5, -8] },
      contact: { family: 'upright', lean: -12, hip_twist: 28, hips: [-4, -2, 0], spine: { lean: -4, twist: 34 }, head: { yaw: -20 }, hand_r: [25, 59, 16], pole_hand_r: [6, 6, 12], hand_l: [12.9, 56, -9.4], foot_r: [-18, 2.5, 10], foot_l: [2, 2.5, -8] },
      follow: { hand_r: [26, 58, 20], hand_l: [28, 57, -6] } },
    orig: 'going away, half turned back to him: the blade of the hand swung out over the shoulder across his chest as he leaves' },
};
