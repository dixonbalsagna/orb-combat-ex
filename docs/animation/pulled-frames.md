# The pulled frames: what the last pass was correcting, and what is fixed (Animation, 2026-10-16; parked)

Owner: Animation. Brief (the EP): "chase the 38 pulled frames that `_fix_scan` lists (the free arm's twist in held keys, the heavies' legs)". **Built and gated in scratch, parked as a sixth patch (`docs/animation/pending/pulled-frames.patch`, README there); nothing in the tree.** It applies after the five before it. Render side only: no sim file, no hash.

## 1. What "pulled" means, and the number that matters

The last pass of the joint limits (`AnimJoints.enforce`) pulls any joint that a layer has taken past its limit back inside. A big pull is a frame where something upstream asked for an impossible bend; the pass makes the body legal, but the arm or leg is then where the pass put it and not where the pose meant it, and from one frame to the next the correction can jump. `_fix_scan` (a probe in my scratch copy) counted 38 such frames across 106 key sets in the study's scenes at the study's fixed 60 units. **That is the wrong yardstick**: the study stages every piece at one distance. The live scan (`joint_scan --only=live`, four seeded AI matches, 24,000 fighter-frames) is the right one, and it said:

| Final-pass corrections in the live matches | Before | After |
| :--- | ---: | ---: |
| over 60 degrees | 71 | **22** |
| 30 to 60 degrees | 69 | **37** |
| in all over 30 | 140 | **59** |

Zero frames reach the screen past a limit either way (the pass sees to that); these are the frames where it had to work hard.

## 2. The three causes found, and the fixes

| Cause | Where it showed | Fix |
| :--- | :--- | :--- |
| **A kick whose hips are already past its target.** The key poses of a kick carry the body's own lunge, and the contact solve adds more when the foot is short; a defender closer than the blow's range, or a pose whose lunge is more than the range, leaves the pelvis ahead of the point the foot must reach, and the thigh would have to swing back through its limit (a front kick's thigh pulled 93 to 126 degrees for four to six frames; a snap round 124 to 132; `pu.su_edge_step` 83 to 130 for twelve) | `AnimFighter._contact_one`: **the body gives ground**: when the foot's target is less than `min_fwd` ahead of the hip, the body steps back by the shortfall, at most `retreat_max` (data `sockets.json` `limbs.foot`: 28 and 30 units; `RenderAnim.kick_retreat` false is the before). Asserted: three kicks at 38 units pull the last pass over 30 degrees on 55 frames without it and 0 with it |
| **A beam's aim turned an upper arm past its limit.** `_aim_arms` swings both upper arms by the aim angle (up to 69 degrees); on top of a cast pose's own arm the twist went to 77 degrees for three frames (live seed 4, tick 1121, and 37 frames in the whole scan, "locked, no part, no sequence") | `_aim_arms` shortens the turn (by 0.7 a try, six tries) until neither upper arm is past its limit. Asserted on both fighters' cast poses and the generic pair at five aim angles |
| **Three heavies authored for a longer range than their rows said.** `su_edge_step` (a step through, the baked lunge 30), `su_edge_unwind` and `su_heel` were staged at the range of the kick they were borrowed from; the body lunged past the point and the leg was pulled in 19, 4 and 11 frames at their own distance | Their rows' `range.offset` is the range their poses were drawn for: `su_edge_step` 54 to 66, `su_edge_unwind` 50 to 58, `su_heel` 48 to 72 (`reach.json` re-measured: 63 to 51, 46 to 38, 36 to 12). Asserted at their own range: 0 frames |

## 3. What is left, honestly

59 live frames over 30 degrees (0.25% of the frames): **an arm blow to a target the arm cannot reach by any legal bend**: a jab or a rising elbow or a short elbow thrown at a head that is high or close, and a bolt's sweep. The contact solve keeps the hand on the target with an illegal plane, and the pass then pulls the upper arm's twist 30 to 80 degrees (a held jab: 80 for three frames). The fix would be the arm's own version of the retreat (a hand blow gives ground, or the target slides), which touches every punch and the closing rule's range numbers; it needs Combat's and Encounter's word on the range before I do it. In the study's own scenes the free arm's twist in a held contact key is the same cause, with the follow-through's join smoothing on top (`_inertialise` adds an offset the pass then trims). None of them is a wrong *bend*: the arm is legal on screen.

## 4. Gates

See the report and the README's line; the batch is `anim_check` (the new `_test_pulls`: 8 checks), `joint_scan --strict`, `lead_scan --strict`, `held_scan --strict`, determinism plain and `-- --intro --seeds=2 --ticks=900`, the flash count, and the four-body scans. The scan numbers above are from `joint_scan --only=live`.

## 5. For others

- **Combat and Encounter:** the three heavies' `range.offset` changed in the manifests (`pu.su_edge_step` 66, `pu.su_edge_unwind` 58, `ru.su_heel` 72). They are my provisional pieces, but your tables read the manifests. A kick closer than its range now steps the body back (up to 30 units of root shift): the closing rule's range is unchanged.
- **Tools (schema):** `sockets.json` `limbs.<kind>.min_fwd` and `retreat_max` (numbers, 0 or absent: off).
- **VFX:** the body's root can shift back during a kick's contact (`AnimFighter` `_step_x` negative); a smear anchored to the foot follows the foot.
