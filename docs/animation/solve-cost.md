# What the fighters' solve costs, and the first cut (Animation, 2026-10-31)

Owner: Animation. The work order (Performance, `docs/perf/fighter-pieces-2026-10-31.md`; the EP's addition): 87 per cent of `r_fighters` is `AnimFighter.solve`; profile inside `_contact_one` and `_exchange_layers`, suspect the dictionary and string work per limb in `_contact_one`, look at the ragdoll's `apply`, `_free_arm_slew`, `_loco_layer`, `_ground_layer`; target -0.4 to -0.6 ms at p95 and about -0.15 mean; no look change. Render only: no sim state, and every pose is bit for bit the pose it was.

## Method

A scratch stage tree of HEAD d34dbbc4 with Performance's timers (`make-stage-tree.mjs`, `hook-fighters.mjs fine`) and 40 more of mine inside `_exchange_layers` and `_contact_one` (one timer on each call and each stretch of lines). Native, headless, `--fixed-fps 60`, an AI match, seed 4, planet 7, 2,400 frames, frames from 100, the per-frame minimum of three runs, **one Godot at a time and the before and after runs taken in turn** (the machine's load was 77 to 86 per cent throughout, so the milliseconds read high; the before and after read the same load). Every figure is the pair's (two fighters), in microseconds.

## What the profile says

| | mean | p95 | share of `r_fighters` (mean 983, p95 1,631 loaded) |
| :--- | ---: | ---: | :--- |
| `_exchange_layers` | 227 | 569 | 23% (the biggest) |
| `_contact_ik` | 80 | 501 | 8%; **p95 is 31% of the frame's p95 alone** |
| ragdoll `apply` | 67 | 94 | 7%, flat: 97 per cent of frames, the same every frame |
| `_reaction_layer` | 57 | 139 | 6% |
| `_inertialise` | 47 | 131 | 5% |
| `_free_arm_slew` | 41 | 71 | 4%, flat |
| `_loco_layer`, `_ground_layer` | 33, 29 | 41, 37 | 3% each, flat |

**The suspect was wrong, and the real cost is in the plane search.** The dictionary and string work of `_contact_one` (the socket lookup, the limb name's `get_slice`/`substr`/`ends_with`, the region point, the surface, the latch) is **13 microseconds a frame in all** (1.4 per cent of the frame; the timers: prelude 4.3, region point 2.3, surface and target 1.3, socket lookup 0.7, surface 0.8, chain 1.0, latch 0.6), and nothing in it is a spike. **`AnimPose.ik_limb` is 45 of the contact solve's 80 (mean) and 430 of its 501 (p95).** When the pose's own bend plane is illegal for the target (the target is where the defender is, not where the key put the hand), `_plan_limb` tries all 72 planes round the root-to-end axis, and each try (`_plane_eval`) rebuilds a ball joint's twist, swing and limit through `excess_at`, `twist_of`, `swing_of`, `_limit_of` and `twist_range_at` (two dictionary lookups of the shape's scales in each) and then does the same sums again for the strain. That is the p95. It is also the cost of a contact or follow pose in the pose bake (2 to 9 ms a pose, `bake-pace.md`'s "next cut").

**What sets the frame's p95** (the 5 per cent of frames with the highest `r_fighters`, 1,660 against 935 for the rest): `_exchange_layers` +355 (its strike scan +175, of it `_press_prof` +85, `_part_prof` +25, `_press_style` +22: the scan runs for every strike of a long string every frame, and a flurry or a chain has six to ten), `_contact_ik` +99, `_reaction_layer` +62, `_inertialise` +49, the ragdoll +21.

## The change

1. **The plane search works things out once** (`anim_pose.gd`, `anim_joints.gd`). `_plan_limb` builds what every candidate plane shares once (the two axes, the joint's place along the axis, the end, the parent's inverse, the twist range at this flexion, the shape's swing scale); the 72 angles' cosines and sines come from a table (they are the same numbers every time); `AnimJoints.plan_eval` gives one candidate's excess, twist and strain with the twist, the swing quaternion and the limit worked out once instead of two or three times. The same operations in the same order, **so the same numbers** (single-float roundings included: the excess sum is of the two rounded halves, as `excess_at`'s was; found by the test).
2. **The search tries the plane nearest the asked-for one first and does not evaluate a plane that cannot win.** A plane's score is `excess * 100 + strain + 0.35 * distance`, and the first two are never negative, so a plane whose 0.35 * distance is already past the best score so far cannot beat it (or tie it); it is skipped. A tie still goes to the lowest table index. The chosen plane is the same one.
3. **`_inertialise`'s jump test** no longer looks up and joins three bone names (`"upper_arm_" + side` and two more) for each of the 27 bones every frame of a blow; the three indices are taken once.

## What it measured (before and after in turn, the same load)

| | before | after |
| :--- | ---: | ---: |
| `ik_limb` in the contact solve, mean / p95 | 44.9 / 430 | **21.4 / 166** (-24 / -264) |
| `_contact_ik`, mean / p95 | 79.9 / 501 | **56.6 / 236** (-23 / -265) |
| `r_fighters`, mean / p95 | 983 / 1,631 | **971 / 1,531** (-12 / -100) |

The step (3) is in the proof and the poses, not in these timings (the timed after tree held steps 1 and 2).

**The pose bake gets the same cut** (the contact and follow keys are solved through `ik_limb`): `bake_check`, the eager bake of both fighters' 932 poses, HEAD then the patch in turn, three each: **442, 545, 556 ms before; 260, 238, 250 ms after** (about -45 per cent), the pose hash the same (2051599411) in all six. That is the "next cut" of `bake-pace.md`, and it makes that patch's `cost` table (this PC's microseconds a pose) read high for the dear poses: it only decides how slices are packed, never a pose, and the table can be re-measured when both land.

**Against the target:** the contact solve's own p95 falls by 265 microseconds, but the frame's p95 by 100, because the 5 per cent of slowest frames are the ones where the exchange layers, the contact solve and the reactions all peak together, and the exchange layers are the larger share of them. **The target of -0.4 to -0.6 ms is not met by this cut; about a fifth of it is.** The mean falls 12 microseconds against the -150 asked for: the mean is spread over many flat layers (below), none of which is a hot spot.

## Proof

- `anim_check` `_test_plan_limb_same`: the new planner beside a copy of the old one (the reference is in the test file) on 2,160 seeded random limbs (arms and legs, six poses, six shapes, targets from near to past the reach, random poles), **1,067 of them through the 72-plane search**: every number of the plan (the joint's place, the end, the plane, the excess, the twist, the flexion) equal, not close.
- A digest of every drawn pose (both fighters' 27 rotations, hips and curl, after the solve) over a seeded AI match, **HEAD against the patch, seeds 4, 9 and 13, 1,800 ticks each: the three digests equal** (1195138463, 1341249606, 710498458).
- The other gates and the cost are in the report.

## What is left, and what each would cost

- **The exchange layers' strike scan** (+175 at the slowest frames): the loop runs `_press_style`, `_part_prof` and `_press_prof` for every strike of the exchange each frame, and only one of them can be drawn. Skipping the strikes that cannot be the drawn one needs a bound on how early a blow's window opens and how late it closes, and the window's size comes from the blow's own data (wind-ups up to 120 ticks, holds, recoveries), so a safe skip is a data-derived bound with a test over the data, not a constant. The strings' args are rewritten by the sim while an exchange runs (`brawl.gd` sets `charge`, `piece`, `trade`, `dur` on a beat that is already listed), so a cache of the scan's result per beat is not safe without a version the sim does not have. This is the next cut with the most in it (the p95's largest single share), and the one I would do next.
- **The flat layers** (the ragdoll 67, the free arm 41, loco 33, ground 29, limit 26, lead 17 microseconds): each is steady and small, set by what they do (a loop over the ragdoll's degrees of freedom; a dozen dictionary reads of data a frame). The ragdoll already skips a degree of freedom under 0.0005 rad; a bigger threshold changes the pose by a visible-in-principle fraction of a degree, which the work order's "no look change" does not allow without the look gate. They add to the mean (about 230 of 983 together) and none to the p95. Caching each layer's data reads on the fighter (as the follow-through already does with `_fw_read`) would take perhaps a fifth off them: -40 to -50 microseconds of mean, in a dozen small edits, each needing its own proof.
- **Reactions and the inertial join** peak with the hits (+62 and +49 at the slowest frames); the join's loops are over the 27 bones three times.
