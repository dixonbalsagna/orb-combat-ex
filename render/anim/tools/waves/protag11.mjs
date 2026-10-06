// PROVISIONAL (energy in reach, slice C2t: docs/design/brawl-second-pass.md section 5b, Combat's pieces in docs/combat/pending/movegen/c2t-content.md section 2, Legal's screen docs/legal/launcher-and-reach-screen.md):
// the Protagonist's point-blank bolts and blasts as strike key sets. A piece is a blow and a shot at once: the hand reaches him and the shot goes off at the contact. His manner: the heel of the palm
// SET on one point (the chest or the gut), never swung; compact, back in his guard at once. One hand, open and flat (the flat palm is posed as a hand here), never both palms, never cupped, never at the
// hip, shoulder height or lower, nothing at the face. Parked (--waves): nothing plays them in a live match; the sim names them when C2t lands. Prefix pk.
//   bolt_thrust   RB+X, bolt 1: a palm thrust, a line, on the chest
//   bolt_flat     RB+X, bolt 2: a flat palm, a line, on the gut
//   bolt_flick    RB+X, bolt 3: a palm flick, an outward arc, on the chest
//   bolt_sweep    RB+X, bolt 4: a flat palm sweep, an inward arc, on the gut
//   blast_chest   RB+Y: the charged shot on a 12-tick wind-up, the palm set on the chest (a held pose: shoulder height, one hand)
//   blast_gut     RB+Y: the same on the gut
const OPEN = { hands: { r: 'open', l: 'open' } };
const NEW = {
  bolt_thrust: { like: 'palm_heel', limb: 'hand', target: 'chest', weight: 'light', load: 2, look: 'PROVISIONAL. A palm thrust: the heel of the palm set on his chest, the shot let go as a short cone at the contact.' },
  bolt_flat: { like: 'spear_hand', limb: 'hand', target: 'gut', weight: 'light', load: 2, look: 'PROVISIONAL. A flat palm set on his gut, the forearm level, the shot let go at the contact.' },
  bolt_flick: { like: 'hook', limb: 'hand', target: 'chest', weight: 'light', load: 2, look: 'PROVISIONAL. A palm flick: the hand carried in across him and let out in a short outward arc onto the chest, the shot going off at the contact.' },
  bolt_sweep: { like: 'hook', limb: 'hand', target: 'gut', weight: 'light', load: 2, look: 'PROVISIONAL. A flat palm swept inward across the gut from the outside, the shot going off at the contact.' },
  blast_chest: { like: 'palm_heel', limb: 'hand', target: 'chest', weight: 'heavy', load: 12, look: 'PROVISIONAL. The blast: the palm set on his chest after a 12-tick gather held at the shoulder, the shot let go as a cone that carries him.' },
  blast_gut: { like: 'spear_hand', limb: 'hand', target: 'gut', weight: 'heavy', load: 12, look: 'PROVISIONAL. The blast on the gut: the palm set low after a 12-tick gather held at the shoulder, the shot a cone that carries him.' },
};
export function rows(wave1) {
  const by = Object.fromEntries(wave1.map(r => [r.id.replace('strike.', ''), r]));
  return Object.entries(NEW).map(([n, o]) => {
    const b = by[o.like];
    return { ...b, id: 'strike.' + n, limb: o.limb, target: o.target, weight: o.weight, look: o.look, ticks: { load: o.load, follow: 4, recover: o.weight === 'heavy' ? 10 : 5 },
      _estimate: 'PROVISIONAL: range borrowed from strike.' + o.like + '; the load is the beat of C2t (a bolt contacts at 2 ticks, a blast winds up 12)' };
  });
}

export const strikes = {
  bolt_thrust: { tip: 'palm', path: 'line', kind: 'hand', target: 'chest', step_max: 8, legal: ['hands_open_or_claw', 'not_at_hip'],
    chamber: { family: 'upright', lean: 2, hips: [-2, -2, 0], spine: { lean: 2, twist: -8 }, hand_r: [8, 58, 12], pole_hand_r: [-6, 4, 10], hand_l: [14, 60, -8], foot_r: [-6, 2.5, 9], foot_l: [12, 2.5, -7], ...OPEN },
    contact: { family: 'upright_lunge', lean: 10, hips: [12, -2, 0], spine: { lean: 6, twist: 10 }, head: { pitch: 4 }, hand_r: [48, 56, 8], pole_hand_r: [4, -2, 8], hand_l: [14, 60, -8],
      foot_r: [-4, 2.5, 9], foot_l: [22, 2.5, -7], ...OPEN },
    follow_t: 0.7,
    orig: 'PROVISIONAL: a palm thrust, the heel of the palm set on the chest, the other hand open in guard' },
  bolt_flat: { tip: 'palm', path: 'line', kind: 'hand', target: 'gut', step_max: 8, legal: ['hands_open_or_claw', 'not_at_hip'],
    chamber: { family: 'upright', lean: 4, hips: [-2, -4, 0], spine: { lean: 4, twist: -8 }, hand_r: [10, 54, 12], pole_hand_r: [-6, 2, 10], hand_l: [14, 60, -8], foot_r: [-6, 2.5, 9], foot_l: [12, 2.5, -7], ...OPEN },
    contact: { family: 'upright_lunge', lean: 14, hips: [12, -6, 0], spine: { lean: 8, twist: 8 }, head: { pitch: 8 }, hand_r: [48, 44, 8], pole_hand_r: [4, -6, 8], hand_l: [14, 60, -8],
      foot_r: [-4, 2.5, 9], foot_l: [22, 2.5, -7], ...OPEN },
    follow_t: 0.7,
    orig: 'PROVISIONAL: a flat palm set on the gut, the forearm level, the body a little lower behind it' },
  bolt_flick: { tip: 'palm', path: 'arc_out', kind: 'hand', target: 'chest', step_max: 8, legal: ['hands_open_or_claw', 'not_at_hip'],
    chamber: { family: 'upright', lean: 2, hips: [-2, -2, 0], spine: { lean: 2, twist: 18 }, hand_r: [14, 56, -2], pole_hand_r: [-4, 4, -2], hand_l: [20, 60, -14], foot_r: [-6, 2.5, 9], foot_l: [12, 2.5, -7], ...OPEN },
    contact: { family: 'upright_lunge', lean: 8, hips: [10, -2, 0], spine: { lean: 4, twist: -6 }, head: { pitch: 2 }, hand_r: [44, 56, 20], pole_hand_r: [4, 0, 12], hand_l: [14, 60, -8],
      foot_r: [-4, 2.5, 9], foot_l: [22, 2.5, -7], ...OPEN },
    follow_t: 0.7,
    orig: 'PROVISIONAL: a palm flick: the hand carried in across the body and let out in a short outward arc to the chest' },
  bolt_sweep: { tip: 'palm', path: 'arc_in', kind: 'hand', target: 'gut', step_max: 8, legal: ['hands_open_or_claw', 'not_at_hip'],
    chamber: { family: 'upright', lean: 4, hips: [-2, -4, 0], spine: { lean: 4, twist: -22 }, hand_r: [14, 52, 28], pole_hand_r: [-4, 0, 16], hand_l: [14, 60, -8], foot_r: [-6, 2.5, 9], foot_l: [12, 2.5, -7], ...OPEN },
    contact: { family: 'upright_lunge', lean: 12, hips: [12, -6, 0], spine: { lean: 8, twist: 14 }, head: { pitch: 6 }, hand_r: [44, 44, -2], pole_hand_r: [4, -6, 6], hand_l: [14, 60, -8],
      foot_r: [-4, 2.5, 9], foot_l: [22, 2.5, -7], ...OPEN },
    follow_t: 0.7,
    orig: 'PROVISIONAL: a flat palm swept inward across the gut from the outside' },
  blast_chest: { tip: 'palm', path: 'line', kind: 'hand', target: 'chest', step_max: 12, legal: ['hands_open_or_claw', 'not_at_hip'],
    chamber: { family: 'upright', lean: -2, hips: [-4, -2, 0], spine: { lean: -2, twist: -12 }, head: { pitch: -2 }, hand_r: [6, 62, 12], pole_hand_r: [-8, 6, 10], hand_l: [14, 60, -8], foot_r: [-8, 2.5, 9], foot_l: [12, 2.5, -7], ...OPEN },
    contact: { family: 'upright_lunge', lean: 14, hips: [18, -4, 0], spine: { lean: 10, twist: 12 }, head: { pitch: 8 }, hand_r: [52, 56, 8], pole_hand_r: [4, -2, 8], hand_l: [14, 60, -8],
      foot_r: [-4, 2.5, 9], foot_l: [26, 2.5, -7], ...OPEN },
    follow_t: 0.6,
    orig: 'PROVISIONAL: the blast: a 12-tick gather with the palm held at the shoulder and the other hand open in guard, then the palm set on the chest' },
  blast_gut: { tip: 'palm', path: 'line', kind: 'hand', target: 'gut', step_max: 12, legal: ['hands_open_or_claw', 'not_at_hip'],
    chamber: { family: 'upright', lean: 0, hips: [-4, -4, 0], spine: { lean: 0, twist: -12 }, head: { pitch: 0 }, hand_r: [6, 60, 12], pole_hand_r: [-8, 4, 10], hand_l: [14, 60, -8], foot_r: [-8, 2.5, 9], foot_l: [12, 2.5, -7], ...OPEN },
    contact: { family: 'upright_lunge', lean: 18, hips: [18, -8, 0], spine: { lean: 12, twist: 10 }, head: { pitch: 10 }, hand_r: [52, 44, 8], pole_hand_r: [4, -8, 8], hand_l: [14, 60, -8],
      foot_r: [-4, 2.5, 9], foot_l: [26, 2.5, -7], ...OPEN },
    follow_t: 0.6,
    orig: 'PROVISIONAL: the blast on the gut: the same gather, the palm set low as the body drops behind it' },
};
