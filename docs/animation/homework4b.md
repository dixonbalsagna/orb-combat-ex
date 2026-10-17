# Homework 4, the second pass: the pulled frames at their source, the wide net for bad bends, and the styles by measurement (Animation, 2026-10-16; parked)

Owner: Animation. Brief (the EP; Orb "keeps naming" the arms and the styles): (1) fix the pulled frames at their source poses and layers, target 0 over 30 degrees and then report what is left at 20; (2) a wider net than the chicken wing, one scan for each kind of bend that reads as wrong, run over the nine cells at the frame rate, and fix what it finds; (3) the styles' distinctness by a measurement with a justified threshold, the closest pairs pushed apart, and the sim's ask for the held medium written precisely; (4) before and after clips. **Built and gated in scratch, parked as the sixth patch (`docs/animation/pending/pulled-frames.patch`, README there), on top of the five. It is the "pulled frames" patch of the first part of the night (`docs/animation/pulled-frames.md`) re-made with this pass in it: a superset of that version, so it replaces it.** Render side only: no sim file, no hash.

## 1. The pulled frames: 0 over 30 degrees, and what is left at 20

The yardstick is `_fix_scan`, now a permanent test (`_test_pulled`): every key set of both fighters (120, the bolts and blasts included), once at the study's 60 units and once at its own striking range, counting the frames on which the last pass of the joint limits pulled a joint by more than 30, 20 and 10 degrees.

| | Before | After |
| :--- | ---: | ---: |
| at 60 units: over 30 / over 20 / over 10 | 39 / 47 / 100 | **0 / 1 / 4** |
| at its own range: over 30 / over 20 / over 10 | 35 / 51 / 115 | **0 / 1 / 4** |
| the four live AI matches (`joint_scan --only=live`, 24,000 fighter-frames): over 60 / 30 to 60 / 10 to 30 | 71 / 69 / 684 (at the start of the day) | **0 / 8 / 289** |

**What was wrong, in source order, and what fixed it:**

| Source | What it did | Fix |
| :--- | :--- | :--- |
| **The contact solve** judged a bend plane legal and left the limb past a limit (the frame the held point is latched, a hand target no plane reaches) | the striking arm twisted 60 to 80 degrees for a frame or three | `AnimPose.ik_limb` takes `clamp_excess`: when no legal plane reaches the end it is the nearest legal limb with the lower joint refolded, the end a little short, not a limb the last pass pulls; and a clamp on the blended bones after it |
| **The elbow and knee blows** (`aim` mode: the whole upper bone turned at the target) | an elbow, a knee, a shoulder blow turned the upper arm or thigh to the target with no limit | the turn stops at the limit (`AnimJoints.clamp_bone`) |
| **The join smoothing** (`_inertialise`) added the old pose's bend onto the new one | on a jointed bone the sum went past the limit (an upper arm twisted 60 degrees for a few ticks in a follow-through or a return): the largest class of the study's frames | the offset is trimmed on that bone until the sum is no worse than the pose itself |
| **A kick whose hips are past its target**, and now **a hand blow whose target is behind the shoulder** | the thigh (the arm) swung back through its limit | the body gives ground (data `sockets.json` limbs `min_fwd` and `retreat_max`: foot 28 and 30, hand 14 and 20), never so far the end no longer reaches |
| **The free arm of a blow** (the arm that is not striking) | the blend from the guard to a key's own plane turned it 60 to 120 degrees in two ticks, and swung back through the shoulder's blind spot | `_free_arm_slew`: it may turn 30 degrees a tick (data `joints.json` `slew`), is held inside its limits and out of the blind spot as it goes; the striking arm keeps its own timing |
| **A beam's aim** (earlier in this patch) | an upper arm twisted 77 degrees | the aim is shortened until both arms stay legal |

**Honest note on the number.** Some of what the last pass did now happens one step earlier (the arm-back squeeze and the clamp on the free arm are the same rules as the pass's), so "pulled by the last pass" falls partly because the correction moved. That is why the bend scan below measures the *final* output (jerk, flip, wing), which a correction made earlier or later cannot hide. The frames over 20 that remain are one, an arm swing in the follow of `ru.su_edge_legs` (22 degrees, a single frame at each range). The live frames over 30 that remain are eight: `pk.bolt_sweep` (six, the point-blank palm sweep's arm across the body, which Legal's e09 poses fix) and `pr.backfist` (two).

## 2. The wide net: one scan for each kind of bend

`_test_bends` runs the nine cells (tap, mash and hold of X, Y and B, both fighters) at 60 Hz and samples every tick: the joints of both arms and legs in the model's frame, the wrist's and upper arm's rotations, what the layers left past a limit before the last pass (the audit's stage D), the last pass's correction, and which arm is striking.

| Kind | What counts | Before | After | |
| :--- | :--- | ---: | ---: | :--- |
| **Elbow or knee bent the wrong way** (hyperextension) | a hinge below its minimum | 0 | 0 | nothing found |
| **Folded past its end** | a hinge past its maximum | 4 | **0** | the aim blows' limbs |
| **Shoulder past the limits in motion** | what the layers leave past a limit before the last pass (stage D) | 115 | **0** | mostly the arm swung back through the shoulder's blind spot |
| **Chicken wing** | elbow up and behind its shoulder, the forearm hanging down | 58 (19 on the free arm) | 54 (17 free) | the rest are cocked strike arms in a heavy's chamber, meant |
| **Upper arm snapped** | an upper arm turned 45 degrees in one tick | 151 | 140 | 58 of the 65 free-arm snaps are in the last two ticks to a contact (below) |
| **Elbow plane flipped** | the elbow's direction turned 80 degrees in one tick | 64 | 59 | 27 of the 29 free-arm flips likewise |
| **Planted knee in** | a planted foot's knee 5 units in off the hip-to-foot line, bent | 0 | 0 | (a kick's own knee legitimately crosses the body: roundhouse, edge kicks; the scan judges the planted leg) |
| **Frames the last pass corrected by over 20 degrees** | | 38 | **0** | |

**What the scan says about the free arm, and what I could not change.** Outside the last two ticks to a blow's contact the free arm barely snaps at all (4 frames before, 3 after, 0 elbow flips): the snaps are **the free arm's arrival**. The sim announces most blows fewer than four ticks ahead (498 of 514 in the standard match) and a light's load is two ticks, so the arm has two ticks to go from the guard to the key's plane, 60 to 120 degrees, and that reads as a snap. I tried a rate limit on the free arm (30 degrees a tick); it removed the snaps (70 to 10) and **failed `tech consistency`** (a blow's pose must be the key whatever the body came from, within 0.15 rad: the limit left the arm 0.63 rad behind after a zip), so the limit is now bounded by the deadline (the arm may turn as much as it takes to be there on the contact tick) and the rate limit does its work in the follow-through and the return. The real fix is in the poses: a contact key whose free arm stays near the guard has nothing to snap; the baked wing fix (now on the chambers too) is the first of that. **A free arm caught in a wing between two keys is drawn toward the guard arm** by how much of a wing it is (`joints.json` `wing.runtime`, in over a few ticks and out over a few more). Not touched: the striking arm's snap at the contact tick (the blow) and the cocked arm of a heavy's chamber (the wind-up). The assert thresholds (`_test_bends`) sit just above the "after" column.

## 3. The styles by measurement

**The metric.** A cell is one scene (a button's tap, mash or hold, one fighter) with every style of a button throwing **the same piece**, so what differs is the style and not the piece (the first measure, with each style on its own pieces, said every pair was far apart and was measuring the pieces). Over the blows' window, from 12 ticks before the first blow to 14 after the last, each cell has: the mean and the spread of nine joints about the pelvis (pose); how far and how low the pelvis goes (travel); the hand-speed peaks a second, the hand's speed and the pelvis's bob (rhythm). The distance of two cells is pose (RMS of the means over 4 units plus RMS of the spreads over 2) plus travel (range over 6, mean height over 3, lowest over 4, averaged) plus rhythm (peak rate over 2 Hz, speed over 2, bob over 1, averaged).

**The threshold, 2.5, and why.** Orb said the fighters "move like different people" and that the styles are "not distinct enough": the same cell thrown by the two fighters is the yardstick of "distinct enough to be accepted", and it is 1.6 apart at the median. The nearest two different buttons (the cross-button pairs, which nobody confuses) are 4.3 apart. A style pair has to read half as far apart again as the fighters do (2.5 against 1.6) and more than half as far as the nearest two buttons (2.5 against 4.3). `_test_styles` asserts it for all 18 pairs.

**The closest pairs, before and after** (protagonist and Anti-hero):

| Pair | Before | After |
| :--- | ---: | ---: |
| Y tap and Y hold | 1.43 and 1.64 | **2.71 and 3.72** |
| Y mash and Y hold | 2.27 and 2.53 | **3.14 and 4.19** |
| B tap and B hold (Anti-hero) | 1.44 | **2.83** |
| B tap and B hold (Protagonist) | 4.42 | 6.23 |
| Y tap and Y mash | 2.81 and 2.85 | unchanged (the nearest left: 2.71) |
| the other eleven (X tap, mash, hold; B tap and mash; B mash and hold) | 3.7 to 7.2 | unchanged or above |

**What moved them:** the **hold** rows of the medium and the heavy (`press_styles.json` `styles.<style>.hold`): the coil deeper (squash 0.45 to 1.1 for the medium, 0.6 to 1.25 for the heavy), the lean back 0.08 to 0.28 and 0.12 to 0.34, **the shoulders wind back the way the blow will come from** (`twist_back`, 36 and 32 degrees, new) and **the body shakes with what it holds** (`tremor`, 0.6 and 0.8 units a tick at the full coil, new, halved under reduced motion). So a held blow is a body straining at its coil, not a tap that is only slower. The mash pushes of the earlier patch (the beat, the lean, the march) are in the figures.

**What the sim has to give the held medium (the ask for Encounter and Simulation).** The body is ready: `styles.medium.hold` and `_hold_coil` read the beat's `windup` (ticks held) exactly as a held heavy's. On main a held Y is still a medium that goes by itself (`brawl.gd` `_wound`: the branch `kind == BIG and f.ki >= more`, the else `_letGo`), so none of this shows in a match. Precisely:
1. **Encounter** (`sim/director/brawl.gd`, pass 2's charged medium, parked): the charge branch takes a medium too, when `f.ki` pays the charged medium's price (`brawl-second-pass.md`: 4 ki over the tap). It must then set `CHG` and re-piece the blow (`_repiece(S, ex, f, MEDIUM, "mediumHeld")`: the held cell's pool, Combat's `recipes.held-only.json`), and send the same cues as the held heavy with source `"y"`: `windup` `start` (target, `n` the contact tick, `dur`), `windup` `charge` (`n` the tick of the full flash: `fullTicks` for a medium, the design says 44) and `windup` `end` (`how`).
2. **The strike beat of the held medium** must carry `windup` (the ticks held, 12 to 70) and `charge` (0 to 1: the share of the full charge), the fields a held heavy's beat has (`args.windup`, `args.charge`), and **its contact must come `windupGrace`-style, 4 ticks after the release**, as the heavy's does, so the body can finish the coil and the blow lands on the sim's tick.
3. **Simulation:** the medium's charge slot and price in the data the sim reads (`c.medium.charge.ki`, `fullTicks`), and the new beat fields in the hash's list if they are hashed. I need one answer from each: the held medium's `fullTicks` (44?) and whether the charge is cancelled by a hit (then the body must let go: the `windup` `end` with `how` 2 does it).

## 4. Clips and sheets for Orb (this PC only, uncommitted, `art/animation/review/homework4b/`)

Before on the left and after on the right, one cell and one fighter each, at fight distance (before is the tree with the earlier patches, after adds this one): the arms (`x-tap-`, `x-mash-`, `x-hold-`, `y-mash-` and `b-mash-` `<fighter>-before-after.gif`), the styles pushed apart (`y-hold-` and `b-hold-` `<fighter>-before-after.gif`: the strain and the wound-back shoulders; `b-tap-` for the tap beside it) (the 18 pairs' distances are in section 3).

## 5. Gates

See the report: `anim_check` (the new `_test_pulled`, `_test_bends` and `_test_styles`), `joint_scan --strict`, `lead_scan --strict`, `held_scan --strict`, determinism plain and `-- --intro --seeds=2 --ticks=900`, the flash count, and the four-body scans.

## 6. For others

- **Tools (schema):** `joints.json` `slew` (`free_arm_deg`) and `wing` (`runtime`, with the keys of the last patch); `press_styles.json` `styles.<style>.hold` `tremor` and `twist_back` (and `squash` above 1); `sockets.json` limbs `min_fwd` and `retreat_max` for `hand` and `foot`.
- **Encounter, Simulation:** section 3's ask. Nothing else.
- **Legal:** the held blow's tremor is under a unit and halved under reduced motion; it is a body shake and not a flash.
- **VFX:** a body that gives ground on a close kick or punch shifts its root back by up to 30 or 20 units for the contact (a smear anchored to the foot follows the foot).
