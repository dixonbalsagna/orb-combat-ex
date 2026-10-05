// The striking surface (tip) and the angle the limb travels (path) of every posed strike, as the posed contact key shows them (docs/combat/moveset-generator.md
// sections 1 and 5.1: the part table the generator reads). wave_gen.mjs writes both onto every manifest row and stops if a strike has no entry here.
//   tip   hand: fist, blade (the open hand edge-on, the thrust and the chop), palm (the open palm or its heel), heel (the back or the bottom of the fist), plate (the forearm leads)
//         foot: ball, heel, instep, edge, sole.   elbow: point.   knee: cap.   shoulder: plate.   head: brow
//   path  line, arc_in (toward the centre line: the hook), arc_out (away from it: the backfist, the crescent), rise, drop, spin (one turn)
// A key is the strike's short name; an entry under `<prefix>.<name>` (pr, w1, rb, ph) overrides it for that fighter. The tip is the posed one: a hand-state swap
// (data/anim/tips.json) can show another on the same key set.
export const TIP_PATH = {
  // hands, light
  jab: { tip: 'blade', path: 'line' },
  cross: { tip: 'blade', path: 'line' },
  hook: { tip: 'plate', path: 'arc_in' },
  backfist: { tip: 'heel', path: 'arc_out' },
  palm_heel: { tip: 'palm', path: 'line' },
  spear_hand: { tip: 'blade', path: 'line' },
  twin_spear: { tip: 'blade', path: 'line' },
  ridge_hand: { tip: 'blade', path: 'arc_in' },
  knife_chop: { tip: 'blade', path: 'drop' },
  hammer_fist: { tip: 'heel', path: 'drop' },
  // hands, heavy
  uppercut: { tip: 'fist', path: 'rise' },
  hammer: { tip: 'fist', path: 'drop' },
  overhand: { tip: 'blade', path: 'drop' },
  haymaker: { tip: 'blade', path: 'arc_in' },
  double_palm: { tip: 'palm', path: 'line' },
  double_hammer: { tip: 'plate', path: 'drop' },
  palm_push: { tip: 'palm', path: 'line' },
  rising_palm: { tip: 'palm', path: 'rise' },
  body_hook: { tip: 'blade', path: 'arc_in' },
  rib_shot: { tip: 'blade', path: 'line' },
  // elbows, knees, shoulders, head
  short_elbow: { tip: 'point', path: 'arc_in' },
  rising_elbow: { tip: 'point', path: 'rise' },
  spinning_elbow: { tip: 'point', path: 'spin' },
  dropping_elbow: { tip: 'point', path: 'drop' },
  cross_arm_ram: { tip: 'plate', path: 'line' },
  short_knee: { tip: 'cap', path: 'line' },
  rising_knee: { tip: 'cap', path: 'rise' },
  driving_knee: { tip: 'cap', path: 'line' },
  shoulder_check: { tip: 'plate', path: 'line' },
  body_ram: { tip: 'plate', path: 'line' },
  headbutt: { tip: 'brow', path: 'line' },
  // feet
  front_kick: { tip: 'ball', path: 'line' },
  side_kick: { tip: 'edge', path: 'line' },
  low_kick: { tip: 'instep', path: 'arc_in' },
  snap_round: { tip: 'instep', path: 'arc_in' },
  roundhouse: { tip: 'instep', path: 'arc_in' },
  sweep: { tip: 'instep', path: 'arc_in' },
  axe_kick: { tip: 'heel', path: 'drop' },
  spinning_heel: { tip: 'heel', path: 'spin' },
  stomp: { tip: 'sole', path: 'drop' },
  drop_kick: { tip: 'sole', path: 'line' },
  crescent_kick: { tip: 'edge', path: 'arc_out' },
  hook_kick: { tip: 'heel', path: 'arc_out' },
  spinning_back_kick: { tip: 'heel', path: 'spin' },
  // the first moveset slice (rival4, protag7)
  elbow_drop: { tip: 'point', path: 'drop' },
  forearm_drop: { tip: 'plate', path: 'drop' },
  fist_drop: { tip: 'fist', path: 'drop' },
  gut_rise: { tip: 'fist', path: 'rise' },
  collar_chop: { tip: 'blade', path: 'drop' },
  elbow_thrust: { tip: 'point', path: 'line' },
  hook_knee: { tip: 'cap', path: 'arc_in' },
  plate_rise: { tip: 'plate', path: 'rise' },
  plate_sweep: { tip: 'plate', path: 'arc_in' },
  heel_stamp: { tip: 'heel', path: 'drop' },
  rib_scythe: { tip: 'blade', path: 'arc_in' },
  spear_rise: { tip: 'blade', path: 'rise' },
  fist_rise: { tip: 'fist', path: 'rise' },
  knee_hook: { tip: 'cap', path: 'arc_in' },
  palm_slap: { tip: 'palm', path: 'arc_in' },
  palm_drop: { tip: 'palm', path: 'drop' },
  blade_back: { tip: 'blade', path: 'arc_out' },
  palm_rise: { tip: 'palm', path: 'rise' },
  edge_crescent: { tip: 'edge', path: 'arc_out' },
  elbow_back: { tip: 'point', path: 'arc_out' },
  // the rival's blades on the lights are posed; the Protagonist's open hands read as palms on the thrusts and the push
  'pr.jab': { tip: 'blade', path: 'line' },
  'pr.palm_heel': { tip: 'palm', path: 'line' },
  'pr.twin_spear': { tip: 'palm', path: 'line' },
};
export function tipPath(prefix, name) {
  return TIP_PATH[prefix + '.' + name] || TIP_PATH[name];
}
