// PROVISIONAL (energy in reach, slice C2t: docs/design/brawl-second-pass.md section 5b, Combat's pieces in docs/combat/pending/movegen/c2t-content.md section 2, Legal's screen docs/legal/launcher-and-reach-screen.md):
// the rival's point-blank bolts and blasts as strike key sets. A piece is a blow and a shot at once. His manner: a show of it, in straight lines: a blade hand driven in FLAT with the forearm plate behind it
// (never a pointed finger or two fingers: Legal e08), and the lit fist, a straight punch whose shot leaves the knuckle edges (Legal e06: allowed, shoulder height or lower, never at the face). The tell is held
// open to view with the limb drawn back, never arms spread (h07). One hand, never cupped, never at the hip. Parked (--waves): nothing plays them in a live match. Prefix rk.
//   bolt_blade   RB+X, bolt 1: a blade hand, a line, on the gut
//   bolt_fist    RB+X, bolt 2: the lit fist, a line, on the chest
//   bolt_flick   RB+X, bolt 3: a blade flick, an outward arc, on the gut
//   bolt_sweep   RB+X, bolt 4: a blade sweep, an inward arc, on the chest
//   blast_chest  RB+Y: the charged shot on a 12-tick wind-up, the lit fist on the chest (a held pose: shoulder height or lower, one hand)
//   blast_gut    RB+Y: the same on the gut
const OPEN = { hands: { r: 'open', l: 'open' } };
const FIST = { hands: { r: 'fist', l: 'open' } };
const NEW = {
  bolt_blade: { like: 'spear_hand', limb: 'hand', target: 'gut', weight: 'light', load: 2, look: 'PROVISIONAL. A flat blade hand driven in to the gut with the forearm plate behind it; the shot a thin edge off the flat of the hand at the contact.' },
  bolt_fist: { like: 'cross', limb: 'hand', target: 'chest', weight: 'light', load: 2, look: 'PROVISIONAL. The lit fist: a straight punch to the chest, the shot leaving the knuckle edges at the contact.' },
  bolt_flick: { like: 'hook', limb: 'hand', target: 'gut', weight: 'light', load: 2, look: 'PROVISIONAL. A blade flick: the flat hand carried in across him and let out in a short outward arc onto the gut, the shot at the contact.' },
  bolt_sweep: { like: 'hook', limb: 'hand', target: 'chest', weight: 'light', load: 2, look: 'PROVISIONAL. A blade sweep: the flat hand swept inward across the chest from the outside, the shot at the contact.' },
  blast_chest: { like: 'cross', limb: 'hand', target: 'chest', weight: 'heavy', load: 12, look: 'PROVISIONAL. The blast: the lit fist driven straight to the chest after a 12-tick gather held at the shoulder, the shot a cone that carries him.' },
  blast_gut: { like: 'spear_hand', limb: 'hand', target: 'gut', weight: 'heavy', load: 12, look: 'PROVISIONAL. The blast on the gut: the lit fist driven low after the same gather, the shot a cone that carries him.' },
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
  bolt_blade: { tip: 'blade', path: 'line', kind: 'hand', target: 'gut', step_max: 10,
    chamber: { family: 'upright', lean: 2, hips: [-4, -4, 0], spine: { lean: 4, twist: -14 }, head: { pitch: -4 }, hand_r: [4, 56, 14], pole_hand_r: [-10, 4, 10], hand_l: [14, 60, -8], foot_r: [-8, 2.5, 9], foot_l: [12, 2.5, -7], ...OPEN },
    contact: { family: 'upright_lunge', lean: 14, hips: [16, -6, 0], spine: { lean: 10, twist: 12 }, head: { pitch: 6 }, hand_r: [54, 44, 6], pole_hand_r: [2, -6, 6], hand_l: [14, 60, -8],
      foot_r: [-4, 2.5, 9], foot_l: [26, 2.5, -7], ...OPEN },
    follow_t: 0.7,
    orig: 'PROVISIONAL: a flat blade hand driven in to the gut, the forearm plate behind it, the other hand open in guard' },
  bolt_fist: { tip: 'fist', path: 'line', kind: 'hand', target: 'chest', step_max: 10,
    chamber: { family: 'upright', lean: 2, hips: [-4, -2, 0], spine: { lean: 2, twist: -14 }, head: { pitch: -4 }, hand_r: [4, 58, 14], pole_hand_r: [-10, 4, 10], hand_l: [14, 60, -8], foot_r: [-8, 2.5, 9], foot_l: [12, 2.5, -7], ...FIST },
    contact: { family: 'upright_lunge', lean: 12, hips: [16, -4, 0], spine: { lean: 8, twist: 14 }, head: { pitch: 4 }, hand_r: [54, 54, 6], pole_hand_r: [2, -2, 6], hand_l: [14, 60, -8],
      foot_r: [-4, 2.5, 9], foot_l: [26, 2.5, -7], ...FIST },
    follow_t: 0.7,
    orig: 'PROVISIONAL: the lit fist: a straight punch to the chest, the other hand open in guard' },
  bolt_flick: { tip: 'blade', path: 'arc_out', kind: 'hand', target: 'gut', step_max: 10,
    chamber: { family: 'upright', lean: 2, hips: [-4, -4, 0], spine: { lean: 2, twist: 20 }, head: { pitch: -2 }, hand_r: [14, 52, -2], pole_hand_r: [-4, 2, -2], hand_l: [20, 60, -14], foot_r: [-8, 2.5, 9], foot_l: [12, 2.5, -7], ...OPEN },
    contact: { family: 'upright_lunge', lean: 12, hips: [14, -6, 0], spine: { lean: 6, twist: -8 }, head: { pitch: 4 }, hand_r: [46, 46, 20], pole_hand_r: [4, -2, 12], hand_l: [14, 60, -8],
      foot_r: [-4, 2.5, 9], foot_l: [24, 2.5, -7], ...OPEN },
    follow_t: 0.7,
    orig: 'PROVISIONAL: a blade flick: the flat hand carried in across him and let out in a short outward arc onto the gut' },
  bolt_sweep: { tip: 'blade', path: 'arc_in', kind: 'hand', target: 'chest', step_max: 10,
    chamber: { family: 'upright', lean: 2, hips: [-4, -2, 0], spine: { lean: 2, twist: -24 }, head: { pitch: -2 }, hand_r: [12, 58, 30], pole_hand_r: [-4, 2, 16], hand_l: [14, 60, -8], foot_r: [-8, 2.5, 9], foot_l: [12, 2.5, -7], ...OPEN },
    contact: { family: 'upright_lunge', lean: 12, hips: [14, -4, 0], spine: { lean: 8, twist: 14 }, head: { pitch: 4 }, hand_r: [46, 54, -2], pole_hand_r: [4, -2, 6], hand_l: [14, 60, -8],
      foot_r: [-4, 2.5, 9], foot_l: [24, 2.5, -7], ...OPEN },
    follow_t: 0.7,
    orig: 'PROVISIONAL: a blade sweep: the flat hand swept inward across the chest from the outside' },
  blast_chest: { tip: 'fist', path: 'line', kind: 'hand', target: 'chest', step_max: 14,
    chamber: { family: 'upright', lean: -2, hips: [-6, -2, 0], spine: { lean: -2, twist: -16 }, head: { pitch: -6 }, hand_r: [2, 62, 14], pole_hand_r: [-10, 6, 10], hand_l: [14, 60, -8], foot_r: [-10, 2.5, 9], foot_l: [12, 2.5, -7], ...FIST },
    contact: { family: 'upright_lunge', lean: 16, hips: [22, -4, 0], spine: { lean: 12, twist: 14 }, head: { pitch: 6 }, hand_r: [58, 54, 6], pole_hand_r: [2, -2, 6], hand_l: [14, 60, -8],
      foot_r: [-4, 2.5, 9], foot_l: [30, 2.5, -7], ...FIST },
    follow_t: 0.6,
    orig: 'PROVISIONAL: the blast: a 12-tick gather with the lit fist held at the shoulder and the other hand open, then driven straight to the chest' },
  blast_gut: { tip: 'fist', path: 'line', kind: 'hand', target: 'gut', step_max: 14,
    chamber: { family: 'upright', lean: 0, hips: [-6, -4, 0], spine: { lean: 0, twist: -16 }, head: { pitch: -4 }, hand_r: [2, 60, 14], pole_hand_r: [-10, 4, 10], hand_l: [14, 60, -8], foot_r: [-10, 2.5, 9], foot_l: [12, 2.5, -7], ...FIST },
    contact: { family: 'upright_lunge', lean: 20, hips: [22, -8, 0], spine: { lean: 14, twist: 12 }, head: { pitch: 10 }, hand_r: [58, 44, 6], pole_hand_r: [2, -8, 6], hand_l: [14, 60, -8],
      foot_r: [-4, 2.5, 9], foot_l: [30, 2.5, -7], ...FIST },
    follow_t: 0.6,
    orig: 'PROVISIONAL: the blast on the gut: the same gather, the lit fist driven low as the body drops behind it' },
};
