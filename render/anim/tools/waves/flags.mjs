// The pose flags of a strike key set (docs/combat/pending/movegen/README.md section 3: the twelve flags the moveset generator reads from a manifest row's `flags`, which Legal's banned
// shapes name). Read off the three key poses' geometry with the same numbers pose_lint.gd's Legal rules use (hip zone: x 8 or less for a closed fist and 14 or less for an open hand, height 24 to 44 (see inHip); a raised hand: above 80; a leap:
// both feet above 6; one turn: hip and spine twist under 140 degrees), but without needing the `_legal` tag: a flag is present when a key pose shows it. Conservative on purpose: the
// generator REFUSES a move whose key set lists a flag, so a flag is listed only where the geometry says it plainly; what the poses cannot show is left to Legal's eye (the sheet's
// conditions).
//   leap                       both feet off the floor in a key pose
//   spin                       a blow that is not a spin (path other than `spin`) with a turn of 100 degrees or more at the contact: the body turns round like a spin
//   multi_turn                 hip and spine twist together over 140 degrees in any key pose
//   travelling                 never from the poses: a spin that travels is a motion, not a pose (an entry or a rush), and no strike key set carries one
//   clasped                    both hands fists within 6 units of each other
//   wrists_together            both wrists within 7 units of each other in the contact (a two-hand blow's hands are meant to be a hand apart: a chamber is not tested)
//   two_hand_chamber           both hands within 10 units of each other in the wind-up
//   cupped_at_hip              an open or clawed striking hand in the hip zone in the wind-up
//   hip_chamber                the striking hand in the hip zone in the wind-up, whatever its state
//   drawn_to_hip_then_thrust   hip_chamber, and the contact hand 36 or more units ahead (a line out of the hip)
//   held_raise_overhead        a hand above 80 in the follow-through (a pose held after a blow)
//   passes_through             never from the poses: it is the contact solve's (it solves the tip onto the surface of the defender, so it cannot pass it); see docs/animation/moveset-parts.md
const FLAGS = ['leap', 'spin', 'multi_turn', 'travelling', 'clasped', 'wrists_together', 'two_hand_chamber', 'cupped_at_hip', 'hip_chamber', 'drawn_to_hip_then_thrust', 'held_raise_overhead', 'passes_through'];
const d3 = (a, b) => Math.hypot(a[0] - b[0], a[1] - b[1], a[2] - b[2]);
// the hand drawn back to the hip (Legal, RL-076 and docs/legal/movegen-banned.json): the zone is x 8 or less for a closed fist in a transient wind-up and x 14 or less for an open hand, a palm or any
// held pose (a held heavy's hold frame also keeps the hand at or below 80 high), at hip height (24 to 44). A fist dips low in front of the hip in an uppercut's wind-up (x 12) and is cleared; an open
// hand there is the cupped hand Legal rules out. The generator refuses a move on a flag, so a flag is listed only where the pose shows it plainly.
const inHip = (t, closed) => t && t[0] <= (closed ? 8 : 14) && t[0] >= -14 && t[1] >= 24 && t[1] <= 44;
const twist = p => Math.abs(p.hip_twist || 0) + Math.abs(p.spine?.twist || 0);
export function poseFlags(chamber, contact, follow, ks, path) {
  const out = new Set();
  for (const p of [chamber, contact, follow]) {
    if (p.foot_r && p.foot_l && p.foot_r[1] > 6 && p.foot_l[1] > 6) out.add('leap');
    if (p.family === 'airborne_neutral') out.add('leap');
    if (twist(p) > 140) out.add('multi_turn');
  }
  if (path !== 'spin' && twist(contact) >= 100) out.add('spin');
  const L = ks.limb || '';
  const side = L.endsWith('_l') ? 'l' : 'r';
  const hand = L.startsWith('hand') ? 'hand_' + side : null;
  for (const p of [chamber, contact, follow]) {
    const hs = p.hands || {};
    if (p.hand_r && p.hand_l && d3(p.hand_r, p.hand_l) < 6 && hs.r === 'fist' && hs.l === 'fist') out.add('clasped');
  }
  if (contact.hand_r && contact.hand_l && d3(contact.hand_r, contact.hand_l) < 7) out.add('wrists_together');
  if (chamber.hand_r && chamber.hand_l && d3(chamber.hand_r, chamber.hand_l) < 10) out.add('two_hand_chamber');
  if (hand) {
    const st = (chamber.hands || {})[side];
    if (inHip(chamber[hand], st === 'fist')) {
      out.add('hip_chamber');
      if (st === 'open' || st === 'claw') out.add('cupped_at_hip');
      if (contact[hand] && contact[hand][0] >= 36) out.add('drawn_to_hip_then_thrust');
    }
  }
  if (follow.hand_r && follow.hand_r[1] > 80 || follow.hand_l && follow.hand_l[1] > 80) out.add('held_raise_overhead');
  return FLAGS.filter(f => out.has(f));
}
export { FLAGS };
