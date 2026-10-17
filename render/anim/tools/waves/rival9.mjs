// PROVISIONAL (Combat's pieces, a9e8f9cd, docs/combat/split-and-pieces.md sections 5 and 5b; Legal has not screened these): the Anti-hero's fists, all NAMED ONLY (`named`: findable by the beat's `piece`, in no
// random pick list, so today's brawl is unchanged until Combat's pool is the hook). Parked (--waves): nothing plays them until the pool does. Prefix rq.
//   jab_fist, cross_fist, spear_fist   The jab, the cross and the spear hand as FISTS: the same three poses as wave 1's blade versions, the hand closed (a hand-state swap, so the line, the step and the reach are
//                                      the same), the forearm plate behind the fist. The jab is the straight light of his perfect follow-up. They are different pieces from the blade versions, which stay.
//   su_fist_unwind                     An unwinding fist to the jaw (heavy): the body coiled with the fist carried across to the far shoulder, then unwound so the fist swings out and round level at the jaw; one turn.
//                                      The arm is bent through the swing and the elbow leads the turn: it is a fist and not a backfist.
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
const W1 = JSON.parse(readFileSync(fileURLToPath(new URL('../../../../data/anim/waves/wave1.poses.json', import.meta.url)), 'utf8')).poses;
const FIST = { hands: { r: 'fist', l: 'open' } };
const OPEN = { hands: { r: 'open', l: 'open' } };
// a wave 1 key as it is, the striking hand closed
const w1 = (name, part) => { const p = JSON.parse(JSON.stringify(W1[`w1.${name}.${part}`])); for (const k of Object.keys(p)) if (k.startsWith('_')) delete p[k]; return { ...p, ...FIST }; };
const NEW = {
  jab_fist: { like: 'jab', limb: 'hand', target: 'head', weight: 'light', look: 'PROVISIONAL. The jab as a fist: a straight fist from the lead shoulder, the forearm plate behind it, the arm one line with the rear leg.' },
  cross_fist: { like: 'cross', limb: 'hand', target: 'chest', weight: 'light', look: 'PROVISIONAL. The cross as a fist: the rear fist driven through the chest with the hips turned full, the lead forearm folded across the ribs.' },
  spear_fist: { like: 'spear_hand', limb: 'hand', target: 'gut', weight: 'light', look: 'PROVISIONAL. The spear hand as a fist: a low straight fist from the crouch into the gut, the spine and the arm one long diagonal.' },
  su_fist_unwind: { like: 'haymaker', limb: 'hand', target: 'jaw', weight: 'heavy', look: 'PROVISIONAL. An unwinding fist: coiled with the fist carried across to the far shoulder, then the body opens out and the fist comes round level at the jaw; one turn, never two.' },
};
export function rows(wave1) {
  const by = Object.fromEntries(wave1.map(r => [r.id.replace('strike.', ''), r]));
  return Object.entries(NEW).map(([n, o]) => {
    const b = by[o.like];
    if (o.weight === 'light') return { ...b, id: 'strike.' + n, limb: o.limb, target: o.target, weight: o.weight, look: o.look,
      _estimate: 'PROVISIONAL: range and ticks are strike.' + o.like + ' (a hand-state swap)' };
    return { ...b, id: 'strike.' + n, limb: o.limb, limb2: null, uses: { arms: 1 }, target: o.target, weight: o.weight, look: o.look,
      range: { ...b.range, lunge: Math.round(b.range.lunge * 1.25), reach: Math.round(b.range.reach * 1.1) }, ticks: { load: 28, follow: 8, recover: 14 },
      _estimate: 'PROVISIONAL: range and ticks borrowed from strike.' + o.like + ' (lunge 1.25 times, reach 1.1 times); the load is the 28-tick wind-up of B' };
  });
}

export const strikes = {
  jab_fist: { named: true, kind: 'hand', target: 'head', chamber: w1('jab', 'chamber'), contact: w1('jab', 'contact'), follow: w1('jab', 'follow'),
    orig: 'PROVISIONAL: the jab as a fist: a straight fist from the lead shoulder, the forearm plate behind it' },
  cross_fist: { named: true, kind: 'hand', target: 'chest', chamber: w1('cross', 'chamber'), contact: w1('cross', 'contact'), follow: w1('cross', 'follow'),
    orig: 'PROVISIONAL: the cross as a fist: the rear fist driven through the chest, the hips turned full' },
  spear_fist: { named: true, kind: 'hand', target: 'gut', chamber: w1('spear_hand', 'chamber'), contact: w1('spear_hand', 'contact'), follow: w1('spear_hand', 'follow'),
    orig: 'PROVISIONAL: the spear hand as a fist: a low straight fist from the crouch into the gut' },
  su_fist_unwind: { named: true, tell_at: 0.5, squash_w: 0.0, drive: 'unwind', kind: 'hand', target: 'jaw', step_max: 14,
    chamber: { family: 'upright', lean: 4, hips: [-4, -4, 0], hip_twist: -22, spine: { lean: 2, twist: -56 }, head: { pitch: 0, yaw: -14 }, hand_r: [14, 64, -10], pole_hand_r: [-4, 8, -2], hand_l: [10, 42, -19],
      foot_r: [-10, 2.5, 9], foot_l: [10, 2.5, -8], ...FIST },
    contact: { family: 'upright_lunge', lean: 12, hip_twist: 40, hips: [18, -4, 0], spine: { lean: 4, twist: 50 }, head: { pitch: 2, yaw: -16 }, hand_r: [46, 74, 22], pole_hand_r: [10, 8, 14], hand_l: [12, 60, -9],
      foot_r: [-6, 2.5, 9], foot_l: [28, 2.5, -7], ...FIST },
    follow: { hip_twist: 18, spine: { twist: 22 }, hips: [14, -4, 0], hand_r: [30, 66, 12], hand_l: [16, 60, -9] },
    orig: 'PROVISIONAL: an unwinding fist: coiled with the fist carried across to the far shoulder, the body opening out so the fist comes round level at the jaw, the elbow leading the turn; one turn' },
};
