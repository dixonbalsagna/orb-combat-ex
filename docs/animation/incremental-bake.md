# The incremental bake (Animation, 2026-10-27)

Owner: Animation. The EP's brief on the Android boot freeze: the first render view of a match took 655 to 690 ms, about 500 ms of it the pair bake ("pair bake: 663 poses"), which at x4 to x6 (a phone) is 2 to 3 s of still screen. Parked as `docs/animation/pending/incremental-bake.patch`. It is the plan of `split-bake-plan.md` (2026-10-03), built: an incremental bake with an on-demand fallback. It applies alone on current main, independent of the animation chain (checked both ways, see below).

## What the cost was

Natively on this PC (a quiet window): `AnimData.load_all` 110 to 155 ms (the base poses.json, 269 poses, and about 60 data files), then `ensure_fighter` 270 to 305 ms a fighter (the waves' sketches baked by IK and joint limits, 0.35 to 0.75 ms a pose, and their data files parsed): 932 poses in all. All of it before the first frame of the match could draw. Reading and parsing the 132 data files is about 48 ms of it; the bake is the rest.

## What it does now

In the game (any run that is not a `-s` script; the tools bake eagerly as they always did; `--lazy-bake` and `--eager-bake` force either):

1. `load_all` and `ensure_fighter` register everything that is cheap at once (the sketches, `raw`, the key sets) and **queue** the rest: each pose's bake, each of a fighter's waves' loads and his pick-list build. A queued pose exists (`pose_exists` is true) before it is baked.
2. `RenderAnim.consume`'s tick event runs `AnimData.bake_pending()`: queued waves and lists first, then poses in the order they were registered, until about `bake_slice_us` (4,000, in `data/anim/pair_live.json` under `bake`) have been spent; at least one piece a tick. The whole queue drains in about 95 ticks, inside the intro.
3. Anything that asks first is served first: `AnimData.pose(id)` bakes a queued pose on the spot (one pose, 0.4 to 0.75 ms); `AnimData.pair_ready(key)` (the pick lists, the entries, a piece by name) runs that fighter's queued work to the end; `pose_exists(id)` for a pose that is not there while waves are still queued runs the queued waves first (the pose may be in one of them).
4. Nothing reads wall time into the sim: the budget measures only how much of the queue is done this tick; the poses are the same whichever tick bakes them. The render never writes the sim.

## What it measures (native, this PC, headless)

`tools/bake_check.gd` (run once with `--eager-bake`, once with `--lazy-bake`): the hash of every pose's rotations and hips after everything is baked is identical (2051599411, 932 poses, five runs each way).

| | Before (eager) | After (incremental) |
| :--- | ---: | ---: |
| Match-start work in the first frame (median of 5) | 583 ms (load_all 118, both fighters 461) | 27.5 ms (`load_all`'s data files; both fighters 0.1) |
| Longest slice after that (median of 5) | (all at once) | 10.7 ms (a budget of 4 ms plus its last piece: one wave's load, about 10 ms at the worst, or one pose) |
| Draining the queue | 0 | about 110 ticks |
| Baked on demand, 900 ticks of a real match | | 4 poses; 0 times the queue run to the end for a missing pose |

At x4 (a guess: four times the native time): the first frame's work is about 110 ms, and no slice is over about 43 ms (4 x 10.7). So no part of the pair bake blocks the main thread for more than the 50 ms asked for at x4; **what is left in the first frame is `load_all`'s reading and parsing of about 60 small data files (about 27 ms here, about 110 ms at x4)**, which was never part of the pair bake. If that matters on the phone it is the next slice: queue the files that the first tick does not need (the forms, the winner, the intro tables...), and that needs a read of who touches them first. I could not run a phone: the x4 figures are the native ones times four.

## Gates

`anim_check` with no arguments, the scans `--strict` and the 4-body scans (all eager, as before: identical), determinism plain and `--intro` also with `--lazy-bake` (the render side in its incremental mode: same as the sim alone), `_test_incremental_bake` (a queued pose exists and is not baked, bakes in order, bakes on demand, is the eager pose, and a fighter's queued work runs when asked for).

## Files

`render/anim/anim_data.gd` (the queue, `bake_pending`, `bake_all`, `pair_ready`, `pose` and `pose_exists`, `_build_lists`), `render/anim/render_anim.gd` (the tick pump and the log line "pair bake incremental"), `render/anim/anim_fighter.gd` (the pick-list check and the one direct `AnimData.poses.has`), `data/anim/pair_live.json` (`bake.slice_us`), `render/anim/tools/anim_check.gd`, `render/anim/tools/bake_check.gd` (new).

## The schema request (Tools)

`tools/schemas/anim-pairlive.schema.json`: a required `bake` object `{slice_us: integer 500 to 50000}`.

## Not here

The pair's data files could also be read at build time into one binary file (option b): not needed once the hitch is spread, and it would add a generated file that can go stale. And the tools that read `AnimData.poses` directly stay eager, so none of them changed.
