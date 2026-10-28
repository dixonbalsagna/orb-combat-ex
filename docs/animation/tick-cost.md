# The tick's cost: the per-tick cuts and the frame-aware bake slice (Animation, 2026-10-27)

Owner: Animation. The EP's brief: Rendering profiled the gen 2 coast at x4 (a phone stand-in) and `RenderAnim.consume` (main's `_on_drained`) was the largest per-frame item, 4.5 ms a tick at x4 against about 1 at x1; `RenderAnim.solve` another 1.2 ms a frame. Goal: cut it with identical poses. Parked as `docs/animation/pending/tick-cost.patch`.

## The cause, found before the fix

Two things sit in `consume`'s time, and they are not the same size.

1. **The incremental bake's slice (`incremental-bake.md`).** `consume` called `AnimData.bake_pending()` on every tick, a wall-clock budget of 4 ms (`bake.slice_us`). The queue is about 440 ms of native work, so on the web at x4 it is more than a thousand ticks of 4 ms, and a frame that runs two or three ticks (a slow device catching up) took a slice for each. Rendering's window (ticks 120 to 720 at x4) sat inside the drain; at x1 the drain is nearly over by tick 120. The scratch timers say so: at x4 the bake is 10.3 of consume's 12.1 ms a frame (HEAD), and once the queue is empty consume costs 1.0 ms (0.87 of it the fighters' tick).
2. **The fighters' tick (`AnimFighter.on_tick`)**, the steady cost: about 130 us a tick native, 1 ms at x4. Measured by section (native, a seeded AI match, scratch timers): the ragdoll step 60 us (it runs on every tick for both fighters; 23 us a call), the cloth springs 18 (twenty literal arrays allocated a call, the same sine worked out twice), the follow-through 16 (`parts.keys()`, dictionary reads in the inner loop), the facing 10, the wound read 7. Events are small (a damage event is about 100 us but rare).

## What it does now

1. **The per-tick work, worked out once** (`RenderAnim.tick_fast`, `--no-tick-fast` is the version before): `AnimRagdoll.step` works out each joint's spring term, target and drive once and runs the two half steps on the joint (the joints do not touch each other), leaves out a shape's term when its weight is exactly zero (the sum keeps its order), and `energy_over` stops summing when the idle test is answered; `_spring_tick` reads constant tables and works each spring's goal out once; the follow-through reads flat arrays made from the data once per fighter (`_fw_read`, rebuilt only if the data or the fighter changes) instead of dictionaries every tick, in `_follow_tick`, `_follow_kick` and `_follow_apply`. The originals are kept as `_step_ref`, `_spring_tick_ref`, `_follow_tick_ref`, `_follow_kick_ref` and `_follow_apply_ref`, and the bench's before is the switch.
2. **One bake slice per drawn frame, sized by the frame** (`RenderAnim._bake_tick`, `--no-bake-frame` is the version before). The first tick of a drawn frame bakes; the others in that frame do not. The slice is `bake.slice_us` (4000) while the intro plays (the queue has to be done before the fight), `bake.play_us` (1500) after it, and `bake.over_us` (500) when the time since the last slice was over `bake.over_ms` (20): the device is already behind. One piece is baked at least, so the queue always drains; anything asked for before it is baked is baked on the spot, so the poses are the same whichever tick bakes them. The render's wall clock never reaches the sim. The log line gains the slices taken, how many were over budget and the tick the queue was empty at ("drained at tick N").
3. `RenderAnim.consume_usec` and `consume_count` count wall time inside `consume` beside `solve_usec`, for the benches.

## Identical poses

`tools/tick_bench.gd` draws one seeded AI match both ways and hashes every bone rotation, the hips, the root offset, the ragdoll's angles and speeds and both spring sets after every frame. The hashes are equal (seed 4: 100828914217182, no launch; seed 11: 136166552210321, 415 launched samples, so the flail is in it), and equal to HEAD's hash from before any edit. `_test_tick_fast` in `anim_check` repeats the seed 11 comparison (1200 ticks) and asserts the match launches someone. The bake hash is unchanged (`bake_check.gd`, 2051599411, eager and lazy; the bake order is the same, only the ticks it runs on move).

## What it measures

Native, this PC, headless, a seeded AI match, `tick_bench.gd` (minimum of the rounds; the machine was shared, so read the ratio):

| | before (`--no-tick-fast`) | now |
| :--- | ---: | ---: |
| `consume` a call, seed 4 | 134.8 us | 109.8 us |
| `consume` a call, seed 11 (a launch) | 132.3 us | 106.4 us |

Web, the gen 2 coast (`pb`, planet 7, gen 2, coast, ticks 120 to 720, Performance's `frame-bench.mjs` with scratch timers in a build of HEAD and of this patch). **The machine was loaded by other sessions (load 59 to 90%) and every run is marked invalid by the load rule: these are upper bounds, good for the ratio inside one session and for nothing else.** Mean ms a frame:

| | HEAD | per-tick cuts only | cuts + frame-aware slice |
| :--- | ---: | ---: | ---: |
| x4 `consume` | 12.1 | 10.5 | 3.6 |
| x4 of it the bake | 10.3 | 9.1 | 2.9 |
| x4 of it the fighters' tick | 1.7 | 1.25 | 0.58 |
| x1 `consume` | 1.51 | 1.52 | 1.21 |
| x1 of it the bake | 1.37 | 1.40 | 1.08 |

After the drain at x4 (warm 1800 ticks, HEAD): `consume` 1.04 ms, the fighters' tick 0.87. The `solve` means (3.6, 3.2, 1.4 ms at x4) move with the machine's load between runs and are not a result; `solve` is not changed here except `_follow_apply`'s tables.

A trap kept for the next run: the first build of the third variant read three times the consume time because my scratch hook had been applied to `main.gd` three times; read the hook's lines in `render/core/main.gd` before a profile.

## Not here

- The 60 poses of `load_all` and the demand-drain (`AnimData.pose_exists` runs the whole queued wave work the first time anything asks for a pose that does not exist, for example the optional `gc.hold.brace_tumble`): at x4 that is one long frame, and the counters for it (`bake_drains`, `bake_demand`) are not in the web numbers above. A next step is to ask the queue's keys instead of draining it.
- `solve` (463 us a call native, 2 calls a frame): not looked at beyond the follow-through. The fighter methods take an untyped `f`; typed parameters were tried in a scratch tree and not measured to the end.
- A baked pose cache read at start (option b of `incremental-bake.md`): with the slice at 1.5 ms after the intro, a phone's drain is long (the queue is 12 times the native 440 ms at x4); a generated file would end it, but it needs a freshness check in CI. For the EP to decide.

## The schema request (Tools)

`tools/schemas/anim-pairlive.schema.json`, `bake`: three optional integer keys beside `slice_us`: `play_us` (500 to 50000), `over_ms` (5 to 1000), `over_us` (100 to 50000). Without them the data job fails (`data/anim/pair_live.json` carries them).

## Files

`render/anim/anim_ragdoll.gd`, `render/anim/anim_fighter.gd`, `render/anim/anim_data.gd`, `render/anim/render_anim.gd`, `render/anim/tools/anim_check.gd`, `render/anim/tools/tick_bench.gd` (new), `data/anim/pair_live.json`, `docs/animation/tick-cost.md`, `docs/animation/incremental-bake.md` (a note).
