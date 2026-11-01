# The bake's pace: the animation drain's p95 (Animation, 2026-10-31)

Owner: Animation. Performance's work order (`docs/perf/quality-range.md` 2.2, `swing-tick-2026-10-31.md`): the animation drain (`d_anim`, `RenderAnim.consume`) is 0.19 ms mean and **1.59 ms p95**, with a first-use hitch up to 6 ms; spread the layers' and the ragdoll's starts across ticks and pre-warm the first pose behind the intro; target -0.8 to -1.2 ms p95. Render only: no sim state, no hash, and every pose is the pose it was.

## What the drain is made of (measured, so the work goes where the time is)

A native probe times each part of `consume` (scratch timers) in a seeded AI match run the way the game runs (the lazy bake on), 1,800 frames, the minimum of three repeats for each frame (load only adds time; the machine was loaded by other sessions, so the absolute numbers read high and the ratios are the evidence):

| Part | Mean | p95 | Max |
| :--- | ---: | ---: | ---: |
| the whole drain | 0.41 ms | 2.00 | 8.1 |
| **the incremental bake's slice** | **0.27** | **1.85** | **7.5** |
| the fighters' tick (cloth springs, follow-through, the ragdoll step, the look) | 0.12 | 0.17 | 0.60 |
| of it the ragdoll step | 0.058 | 0.10 | 0.43 |
| after the queue is empty (from tick 300) | 0.14 | 0.27 | 0.40 |

**The layers and the ragdoll have no first-use hitch worth spreading:** their first starts cost at most 0.43 ms, and the drain after the queue is empty is 0.14 mean and 0.27 p95. **The whole excess is the bake of the pair's 932 poses** in the first 300 frames (a slice of 1.5 ms every frame, 4 ms in the intro). Inside it: the 932 poses cost 514 ms to bake (quiet), mean 0.55 ms each, but **116 of them take 1 ms or more, up to 9 ms** (the contact and follow keys of the strikes: `pr.cross.contact` 6.6 ms, `pu.su_blade_jaw.follow` 9.3, against 0.1 for a stance), because each limb's bend plane is searched; the 29 wave loads take 1 to 3.4 ms; the two pick-list builds 5.5 ms each. A slice stops after the item that takes it past its budget, so a frame with a 6 ms pose is a 6 ms frame, and a pose a blow asks for before the queue reaches it is baked on the spot (25 to 38 such first-use bakes in a match, 51 to 54 ms in all).

## The change

Data in `data/anim/bake_order.json`, switch `--no-bake-order` (the before). The order and the pace only: `bake_check` hash 2051599411 eager, lazy and lazy with the switch, the same as before.

1. **The queue bakes what a fight asks for first.** `first` is 418 poses: what six seeded AI matches and the nine cells ask for, the dear ones (65) first and then the cheap ones, each in the order a fight asks for them. A dear pose is the one that hitches when asked for on the spot, so it is baked in the first frames (behind the intro, or in the 100 frames a measurement leaves out); a cheap one asked for on the spot costs 0.1 to 0.5 ms and is no hitch.
2. **A slice does not start a pose that would take it past its budget** (`cost`: each pose's bake time on this PC, quiet, to 100 us), unless the slice has baked nothing, so a pose is never the second item of a frame that it overshoots. A dear pose gets a slice of its own.
3. **The play slice is 700 us** (`pair_live.json` `bake.play_us`, was 1,500; the intro's 4,000 stands). The queue then takes about 520 ticks instead of 250 to drain; with the order above the first-use bakes fall, not rise.

## What it measured (frames from 100, two seeds, 1,800 ticks, no intro: Performance's own plain AI match)

| | HEAD | now |
| :--- | ---: | ---: |
| drain p95 (seed 4 / seed 9) | 1.81 / 1.96 ms | **1.04 / 0.99** (-0.77 / -0.97) |
| p99 | 2.83 / 3.45 | 1.58 / 1.58 (-1.25 / -1.87) |
| worst frame | 8.1 / 11.3 | 5.4 / 3.1 |
| first-use bakes (count, time) | 25 / 38, 51 and 54 ms | 14 / 33, 6.2 and 14.0 ms |
| the queue empty at tick | 248 / 260 | 520 / 517 |

With an intro (299 frames, seed 4): the intro's frames p95 6.56 -> 4.63 ms, worst 11.1 -> 8.6; the queue is empty at tick 123 (HEAD) and 156 (now), inside the intro, so nothing is left to bake once the fight is on screen (the frames after it: p95 0.28 -> 0.22).

**Read the numbers as ratios:** the machine was not quiet (other sessions' captures and Godot jobs), so each frame is the minimum of two repeats, as Performance does, and absolute times read high. A run on a quiet machine is still owed; the target is met on the p95 (-0.8 and -0.97 against -0.8 to -1.2) and not past it.

## Proof

- `anim_check` `_test_bake_order`: the data names real poses and costs every pose of the pair; ranked poses bake first by rank and `--no-bake-order` keeps the queue's order; a pose that would overshoot waits for a slice of its own; every pose is the eager pose of the same sketch.
- `bake_check`: the same hash (2051599411) eager, lazy and lazy with `--no-bake-order`.
- The other gates and the cost are in the report.

## Not here (the next cuts, if more is wanted)

- **The contact and follow poses' bake cost** (`AnimPose._plan_limb`'s search for a legal bend plane, 2 to 9 ms a pose, 116 of the 932): the remaining p95 is these, each in a frame of its own. Cutting it must keep every pose bit for bit (the hash above); it is the one change that lowers the total as well as the spike.
- The two pick-list builds (5.5 ms each) and the wave loads (1 to 3.4 ms) happen in the first frames and could be split a wave at a time; they are in the first 40 frames, behind the intro, so they are not in the p95.
- The cost table is this PC's: another machine's poses take proportionally more or less, which only changes how slices are packed, never a pose.
- `data/anim/bake_order.json` needs Tools' schema: the draft is `schema-drafts/anim-bake-order.schema.json` (and a cross-reference that every id is a pose).
