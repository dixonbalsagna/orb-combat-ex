// SCRATCH HOOK (applied only to a scratch stage tree, after hook-stages.mjs; never to the repo): where r_fighters goes, by piece.
//   node hook-fighters.mjs <tree>          the coarse cut (run first)
//   node hook-fighters.mjs <tree> fine     then the calls inside AnimFighter.solve, one timer each (fa2_*), on the same tree
// FighterView.update is cut into fv_* timers (pose, solve, apply, look, damage, sockets, cue, materials, fx, badge and guard, anchor, under); AnimFighter.solve into fa_* timers (one per numbered stage of the function).
// Timers are INCLUSIVE and add into the frame's PerfT row (two fighters a frame, so each key is the pair's sum). fv_solve holds the fa_* stages; fv_apply is AnimBody.apply (one skeleton write a bone).
import { readFileSync, writeFileSync } from 'node:fs';

const root = process.argv[2];
if (!root) throw new Error('usage: node hook-fighters.mjs <tree>');
let uid = 0;
const files = new Map();
const text = (f) => { if (!files.has(f)) files.set(f, readFileSync(`${root}/${f}`, 'utf8')); return files.get(f); };
const put = (f, s) => files.set(f, s);

/** The line index range of a function: from its `func` line to the next top-level `func` or `static func` line. */
function range(lines, defStart) {
  const a = lines.findIndex((l) => l.startsWith(defStart));
  if (a < 0) throw new Error(`no ${defStart}`);
  let b = lines.length;
  for (let i = a + 1; i < lines.length; i++) if (/^(static )?func /.test(lines[i])) { b = i; break; }
  return [a, b];
}

/** A timer pair around the one line starting (after its tabs) with `start`, inside a function. */
function wrap(f, def, start, key) {
  const lines = text(f).split('\n');
  const [a, b] = range(lines, def);
  const at = [];
  for (let i = a; i < b; i++) if (lines[i].trimStart().startsWith(start)) at.push(i);
  if (at.length !== 1) throw new Error(`${f}: "${start.slice(0, 60)}" found ${at.length} times in ${def}`);
  const ind = lines[at[0]].match(/^\t*/)[0];
  const v = `_pw${++uid}`;
  lines.splice(at[0], 1, `${ind}var ${v}: int = Time.get_ticks_usec()`, lines[at[0]], `${ind}PerfT.t("${key}", ${v})`);
  put(f, lines.join('\n'));
}

/** Cuts a function at the lines starting with each marker (single-tab lines): before each, the elapsed segment is added under the name given and the clock restarts. `first`: the line after which the clock starts. `last`: the line before which the last segment ends. */
function cut(f, def, first, marks, last, lastKey) {
  const lines = text(f).split('\n');
  const [a, b] = range(lines, def);
  const find = (pfx, from = a) => {
    const at = [];
    for (let i = from; i < b; i++) if (lines[i].startsWith(pfx)) at.push(i);
    if (at.length !== 1) throw new Error(`${f}: "${pfx.slice(0, 60)}" found ${at.length} times in ${def}`);
    return at[0];
  };
  const ops = [];   // [index, insert-before lines]
  const i0 = find(first);
  ops.push([i0 + 1, ['\tvar _ps: int = Time.get_ticks_usec()']]);
  for (const [pfx, key] of marks) ops.push([find(pfx), [`\tPerfT.t("${key}", _ps)`, '\t_ps = Time.get_ticks_usec()']]);
  ops.push([find(last), [`\tPerfT.t("${lastKey}", _ps)`]]);
  ops.sort((x, y) => y[0] - x[0]);
  for (const [i, ins] of ops) lines.splice(i, 0, ...ins);
  put(f, lines.join('\n'));
}

if (process.argv[3] === 'fine') {
const S0 = 'func solve(S: SimState, f, prof: Dictionary)';
const fw = (start, key) => wrap('render/anim/anim_fighter.gd', S0, start, key);
for (const [st, k] of [
  ['update_face(S, f)', 'fa2_update_face'], ['_wound_read(f)', 'fa2_wound_read'], ['_depth_read(S, f, dt)', 'fa2_depth_read'], ['_target_base(S, f, T)', 'fa2_target_base'],
  ['_depth_step_layer(S, f)', 'fa2_depth_step'], ['_waiting_layer(S, f)', 'fa2_waiting'],
  ['AnimZip.layers(self, S, f, T, dt)', 'fa2_zip_layers'], ['_exchange_layers(S, f, ex, T)', 'fa2_exchange_layers'],
  ['_beam_layer(S, f, T)', 'fa2_beam'], ['_struggle_layer(S, f, dt)', 'fa2_struggle'], ['_look_at(S, f, dt)', 'fa2_look_at'],
  ['_reaction_layer(T)', 'fa2_reaction'], ['_ground_feet(S, f, dt)', 'fa2_ground_feet'], ['_contact_ik(S, f)', 'fa2_contact_ik'],
  ['_rd.apply(q, _rd.out_w', 'fa2_ragdoll_apply'], ['_flight_layers(T, f)', 'fa2_flight'], ['_win_layer(S, f, T)', 'fa2_win'],
  ['_personality_layer(T, int(f.stance)', 'fa2_personality'], ['_turn_layer(T)', 'fa2_turn'],
  ['_springs(f)', 'fa2_springs'], ['_follow_apply()', 'fa2_follow'], ['_inertialise(dt, prof)', 'fa2_inertialise'],
  ['_hold_feed(S, f, T)', 'fa2_hold_feed'], ['_grip_layer(S, f, dt)', 'fa2_grip'], ['_ack_layer(S, f, dt)', 'fa2_ack'], ['_loco_layer(S, f, dt)', 'fa2_loco'],
  ['_ground_layer(S, f, dt)', 'fa2_ground'], ['_pop_layer(S, f, dt)', 'fa2_pop'], ['_air_recover_layer(S, f, dt)', 'fa2_air_recover'], ['_air_brake_layer(S, f, dt)', 'fa2_air_brake'],
  ['_recoil_layer(S, f, dt)', 'fa2_recoil'], ['_lead_layer(S, f, dt)', 'fa2_lead'], ['AnimZip.orient(self, S, f, dt)', 'fa2_zip_orient'], ['_free_arm_slew(dt, String(f.state))', 'fa2_free_arm'],
  ['debug["limit_fix"] = AnimPose.limit_limbs(q, _rd.shape_key)', 'fa2_limit_limbs'], ['AnimPose.fk_chain(q, hips, gq, gp, SOCKET_CHAIN)', 'fa2_fk_sockets'],
]) fw(st, k);
} else {
// ---- AnimFighter.solve, by its numbered stages ----
const AF = 'render/anim/anim_fighter.gd';
cut(AF, 'func solve(S: SimState, f, prof: Dictionary)', '\tversion += 1', [
  ['\t# 1. the base pose', 'fa_0pre'],
  ['\t# 2. a cue pose', 'fa_1base'],
  ['\t# 3. the exchange', 'fa_2cue_seq_intro'],
  ['\t# 4. the signature beam', 'fa_3exchange'],
  ['\t# 4a. the head looks', 'fa_4beam'],
  ['\t# 4b. a broken arm', 'fa_4a_look'],
  ['\t# 5. reactions to blows', 'fa_4b_wounds'],
  ['\t# 5a. feet on the slope', 'fa_5react'],
  ['\t# 5b. the striking limb', 'fa_5a_feet'],
  ['\t# 5c. the active ragdoll', 'fa_5b_contact'],
  ['\t# 5d. polish', 'fa_5c_ragdoll'],
  ['\t# 6. moving hold', 'fa_5d_polish'],
  ['\t_inertialise(dt, prof)', 'fa_6hold_springs'],
  ['\t_hold_feed(S, f, T)', 'fa_6a_inertialise'],
  ['\t# 6b. the limb pass', 'fa_6a_layers'],
  ['\t# 7. sockets', 'fa_6b_limbs'],
], '\tframe = RenderAnim._frame_key(S)', 'fa_7_sockets_tail');

// ---- FighterView.update, by piece ----
const FV = 'render/core/fighter_view.gd';
const U = 'func update(S: SimState, f, pose: Vector3, vx: float, z: float)';
wrap(FV, U, 'var af: AnimFighter = RenderAnim.solve(S, f)', 'fv_solve');
wrap(FV, U, 'anim_body.apply(af.q, af.hips, af.curl, af.root_off)', 'fv_apply');
wrap(FV, U, 'anim_body.set_look(0.0, f.hidden)', 'fv_look');
wrap(FV, U, '_damage(f, dt)', 'fv_damage');
wrap(FV, U, 'head.position = af.head_center() + off', 'fv_sockets');
wrap(FV, U, 'arm_front.transform = Transform3D(Basis.IDENTITY, af.socket("hand_r") + off)', 'fv_sockets');
wrap(FV, U, '_pose_cue(T, m, th, front)', 'fv_cue');
wrap(FV, U, 'anim_body.set_anchor(anchor)', 'fv_setanchor');
wrap(FV, U, 'var under: float = GroundField.under_level(S, f.x, pose.y)', 'fv_underlevel');
wrap(FV, U, 'anim_body.set_under(under > GroundField.NO_SHORE * 0.5, under)', 'fv_setunder');
wrap(FV, U, '_turn = move_toward(_turn, RenderAnim.face_for(S, f), dt * 2.0 / RenderLook.TURN_TIME)', 'fv_face');
cut(FV, U, '\tvar T: float = S.T', [
  ['\tvar punch: bool', 'fv_pose'],
  ['\tif f.hidden != _faded or flash != _flash:', 'fv_rig_block'],
  ['\tvar fade: float', 'fv_materials'],
  ['\tbadge.visible = RenderLook.STANCE_BADGE_ON', 'fv_fx_aura_streaks_orb'],
  ['\t# The hybrid projection', 'fv_badge_guard_ripple'],
  ['\tif flashes_on:', 'fv_anchor_uniforms'],
], '\tif flashes_on:', 'fv_tail');

}

for (const [f, s] of files) writeFileSync(`${root}/${f}`, s);
console.log('hook-fighters applied to', root);
