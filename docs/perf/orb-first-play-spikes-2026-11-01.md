# Orb's first play: where the frame spikes come from (Performance and Platform, 2026-11-01)

For the EP. Source: Orb's own recording (`homework/Files/orb-first-play-20261101-1424.json`, kept there, private): 91,574 frames in 688 s (about 133 fps on a 240 Hz display), 157 frames over 33 ms, 49 over 50 ms, 5 over 100 ms, worst 137.7 ms at tick 11586. Orb's words: "launches seem to cause frame spikes" and "frametime spikes when I knocked my opponent into a hill".

Method: the recorded match was replayed natively on the stack tree Tools kept for key dc01cd6e4c43 (data hash 2d6f4984752cbcb7 equal to the recording's; every checkpoint and the final hash 630154cb09579ddc REPRODUCED, so it is Orb's match tick for tick). One Godot job, below-normal priority; machine load 32 to 35% (valid under the 60% rule, but other sessions were running: the native times are an upper bound). Every tick's own sim time was recorded and set against Orb's slow frames; for the slow stretches, what happened (events, hit points, positions) and the field memo's rebinds. Tool: `docs/perf/tools/preplay/replay_prof.gd`. Native sim time is not page time (the page runs the sim as WebAssembly, slower; and draws): it tells where the sim is the cost, and where it is not.

## In plain words

The spikes are **three different things**, and the first is not the game at all.

| What | Share of Orb's 157 slow frames | Sim or draw | Evidence |
| :--- | :--- | :--- | :--- |
| **1. The recorder's checkpoint** | 36 (23%), one every 600 ticks, 38 to 58 ms | the recorder's hash of the whole sim state | Every one falls on tick 599, 1199, 1799 ... Hashing the state natively costs 27 to 44 ms (mean 35.5). Only the private page's black box does it. |
| **2. The terrain memo re-laid on every change** | about 27 sim-heavy frames in the two worst stretches (11534 to 11594: 58 to 138 ms; 13478 to 13605: 41 to 113 ms) and the frames between them (the in-between 31), and the cost inside the launch ticks below | **sim** | During a beam sweep the store changes every tick and the field memo is rebuilt every tick (rebind counter 296, 297, 298 ... on consecutive ticks); every second tick then costs 19 to 26 ms natively (the tick between costs 1.5 ms). 27 of the 32 heavy ticks I looked at (8 ms or more natively) sit on a rebind. |
| **3. Launch and first-swing ticks** | 6 single or paired spikes (ticks 252, 2751, 12246, 18753, 19500, 21731) of 31 to 62 ms | **sim** | Native tick cost 25 to 43 ms at each: a launch plan (`launch_plan`, `LAUNCH`) or a swing start, in each case the first read of the terrain ring after the memo was laid again. At tick 2751 (a launch into buildings: building_fall, debris, slide dust) the page frame was 87 ms. |
| **4. Draw-bound stretches** | 55 (35%): 29 frames of 33 to 50 ms at ticks 1562 to 1644, 20+ more beside the beam sweeps | **draw** | The sim is 1 to 5 ms in those ticks while the page took 37 to 50 ms a frame for 82 ticks in a row (a swing start and rest, nothing exploding). Cause not found: the sim says it is not the sim; which draw layer needs a bisect on the page. |

The remaining 31 frames are in between (the sim 4 to 8 ms natively).

**What Orb saw.** "Launches": number 3 (and number 2, which fires inside most launches: the landing of a launch carves the ground, so the memo is re-laid). "Knocked into a hill": the launch ends in a carve or collapse (ticks 2751, 19642 to 19683, 21731 to 21777, 21894 show craters, building_fall, debris at the landing) and pays numbers 2 and 3 together.

## Top three causes and fixes

1. **The field memo is thrown away whole when anything in the store changes** (`SimField._bind`: `_serial += 1`, `_coarse` and `_bHave` memos start empty; a coarse column miss is about 50 µs, 600 columns in the ring, about 30 ms). A beam sweep, a crater or a collapse changes the store every tick or every few ticks, and the next read of the ring or of the buildings near the fight pays the cold cost again. **Fix: invalidate by place**, not whole: a change only dirties the columns and buildings it touched (the store already knows which). That removes causes 2 and most of 3 together. Owner: Simulation (`sim/core/field.gd`; the same note I made on 2026-11-01 as "invalidating by place"). Acceptance test I can run: the whole of Orb's replay (22,102 ticks, 36 checkpoints, final hash 630154cb09579ddc) must reproduce, and the ticks over 8 ms natively (75 now, with the bake done first) must drop to a handful (75 with the bake done first; 77 without).
2. **Launch and first-swing ticks** (cause 3): if cause 1 is too big for now, my already-measured warm-up patch (`docs/perf/tools/swing-bench/fix-ring-warm.py`, bit-identical, off by default) takes a launch tick from 30 to 8 ms, but it waits for 6 quiet ticks and so does nothing inside a beam sweep. It is the interim fix for launches only; it is with Simulation.
3. **The draw-bound stretches** (cause 4): not a sim cost. Next step is a layer bisect on the page with Orb's own replay (Tools' `blackbox-clip.mjs` plays the file on the page): the swing's view (Camera's second world / inset pane was 770 k primitives in the 2026-10-16 audit), the tile ground, the crowd. I have not done it; it needs the quiet machine.

And, separately, **the recorder's checkpoint (cause 1 of the table)**: it is only on the private page, so it is not what Orb's players will get, but it makes the page worse than the game: moving the checkpoint from every 600 to every 1800 ticks (the EP's change) leaves one 35 ms hitch every 30 s. Better: no mid-match checkpoints at all; the final hash alone proves a replay (the file still verifies), or compute the hash in slices over many ticks.

## Limits

- Native sim times, one run each (a second run of the first 13,700 ticks gave 35 to 43 ms for the same launch tick: a 20% spread); the machine at 32 to 35% load. Page frame cost is not derived from them.
- The frame record keeps ticks and times of the SLOW frames only (157), so the draw-bound claim is "the sim was cheap there", not a measurement of what the draw did.
- Which draw layer causes cause 4: not found.
- Nothing in the repo's `sim/` or the kept tree was changed; the tree was copied (sim, data, net) into my scratch folder and imported there.

## The draw-bound stretch, ticks 1562 to 1644 (follow-up, same day)

**What the replay says (native, valid: the sim's own state, not a timing).** The stretch is exactly one swing (the director turning the view's frame): swing active ticks 1560 to 1642, the frame moves on 82 of its 83 ticks, and 28 of Orb's slow frames fall inside it (33 to 50 ms, flat). But a swing alone is not the cause: the swing at ticks 2480 to 2546 moves the frame on 56 ticks and the one at 21251 to 21284 on 31, and neither has a single slow frame. What is different at 1560 to 1642: **the fighters are far apart and one is high up**. At 1560 one fighter is at x 76,408, y 1,256 and the other at x 110,165, y 362; by tick 1575 the other is at y 1,485 and by 1590 at y 1,861 and x 105,263: 29,000 to 34,000 units apart, one at nearly 1,900 units up. In the other two swings the fighters are 60 to 250 units apart on the ground. Over all the slow frames I could place (those inside the replayed windows): **the draw-bound ones (sim under 4 ms) have a median separation of 15,191 units and the sim-heavy ones 19,562, against 2,336 for all ticks in the windows.** So the draw-bound frames are the ones where the camera has to frame two fighters very far apart (a launched fighter, a long beam) and so shows far more of the world at once: the draw cost follows the separation, not the sim.

**What I could not do: a measured layer bisect on the page.** The page runs of Orb's replay (Tools' capture hook, then a real-time try) were not usable: the hooked page costs about 20 ms a frame even outside the stretch (Tools' hook, one tick every other frame), the stretch was 40% slower (median 28 ms against 20), the replay's checkpoints did not reproduce on the words I could give it (first different at tick 600: so it was not the same match), the real-time replay never ran, and the machine was at 45 to 73% CPU (other sessions, Orb): INVALID by the 60% rule. A layer bisect needs a scratch export with the layer cut hook (`window.__cut`, `docs/perf/tools/scratch-hooks`) and a quiet machine; the frame-bench `--layers` scene at a far separation is the cheaper way (set up the signature or ring scene with the fighters 30,000 units apart). Not done.

**Fix direction (Rendering or Camera, not mine):** at far separation draw a reduced world (the tile ground and the crowd at a coarser level, fewer buildings, no fine terrain), or cap how far the camera pulls out, because the far view is where the frame time goes. Tool for the check: `docs/perf/tools/preplay/replay-bench.mjs` (plays Orb's replay on a page and times the stretch against the frames around it) once a hook that reproduces the checkpoints is in hand.

## Correction, same day: the tool now bakes first (Simulation's note, `docs/architecture/pending/ceil-table/README.md`)

`replay_prof.gd` started without the planet's bake, which the page's load does before the first tick; a far read then computes its nodes on the spot (Simulation: about 100 us where the page pays about 33). The tool now runs `WorldClimate.useGen(3)` and `WorldField.bakeStep(WorldField.of(WorldPlanet.make(planet)), 1 << 40)` before `SimCore.createSim()`. Re-run on Orb's replay (whole match, reproduces 630154cb09579ddc), machine load 12 to 26%:

| | no bake (first run) | with the bake |
| :--- | ---: | ---: |
| Native ticks over 8 ms / over 16 ms | 77 / 17 | 75 / 17 |
| Worst tick | 42.8 ms | 42.9 ms |
| Launch tick 2751 | 42.8 ms | 42.9 ms |
| Ticks 252, 12246, 18753, 19500 | 35.1, 31.7, 36.0, 31.0 | 38.5, 35.2, 31.5, 37.3 |
| Beam sweep, every second tick (11580 to 11594) | 19 to 26 ms | 20 to 25 ms |
| Checkpoint hash | 35.5 ms mean | 31.2 ms mean |
| Slow frames: sim 8 ms or more / 4 to 8 / under 4 (draw) | 35 / 31 / 55 | 34 / 24 / 63 |

**It did not change my picture on this copy, and Simulation's 51 ticks over 8 ms does not reproduce here (75).** Why I cannot say: my copy is sim, data and net of Tools' tree only, a first match in a fresh process (in my kit runs a first match's `newMatch` already comes out with the bake done, `bake 0 ms`, where a rematch does not), so my "no bake" run may already have had it. The beam sweep's 20 to 25 ms every second tick is about what 600 ring columns at the page's 33 us a miss add up to (19.8 ms), so my first run was not paying 100 us a read either. The conclusions above stand as written; the 51 against 75 is an open difference between our two copies (a possible cause: their clean copy of the whole tree, or load).

## Acceptance of `field-place` plus Encounter's grant (same day; the EP's order)

`docs/architecture/pending/field-place/field-place.patch`, then `grant-encounter-standing.patch`, applied with `git apply` to a copy of my copy (sim, data, net of Tools' tree for key dc01cd6e4c43, identical to it: `diff -rq` of the three folders shows only a `blackbox_verify.gd.uid` that Godot wrote in my copy; the patched copy adds `sim/core/tools/memo_check.gd` and its `.uid`). My tool (`replay_prof.gd`, bake first), Orb's whole replay, one Godot job, below-normal, run back to back A, B, A, B on the same machine (load 8 to 36%, the other sessions): **every run reproduces every checkpoint and the final hash 630154cb09579ddc, and the data hash is the recording's.**

| | Ticks over 8 ms | Over 16 ms | Worst | Mean tick |
| :--- | ---: | ---: | ---: | ---: |
| As it was, run 1 / run 2 | 74 / 73 | 17 / 17 | 42.0 / 47.7 ms | 568 / 587 us |
| With `field-place` and the grant, run 1 / run 2 | **11 / 11** | 8 / 8 | 42.3 / 40.2 ms | 565 / 558 us |

The number: **74 and 73 ticks over 8 ms become 11 and 11; over 16 ms 17 becomes 8.** The worst tick does not move (40 to 48 ms either way): what is left at the top is not the memo: ticks 11548 and 11570 (the water window at a beam's start, 23 to 42 ms), 252 (the first swing, 35 to 40), 2751, 18753 and 19500 (launches, 26 to 37). The beam sweeps at 11580 to 11594 and 13478 to 13605 are gone from the list. Simulation's own table (82 / 78 down to 10 / 10) and mine (74 / 73 down to 11 / 11) agree; the "51" I could not reproduce was the ceil-table's with-bake figure, a different patch.

## Rendering's lead: is it the two pictures of an open split? (same day; page, `nosplit` against none)

`docs/perf/tools/preplay/replay-bench.mjs` on Orb's replay, ticks 1562 to 1644, Tools' capture hook at 960 x 540, real GPU, load 12 to 23% (valid), page words `planet=7&meteor=loud&tiles=1` with and without `nosplit=1`, two runs each. Median frame cost (ms) before the stretch / in it / after it: none 16.1 / 22.9 / 15.2 and 15.8 / 23.1 / 15.1; `nosplit` 16.2 / 22.8 / 15.2 and 15.1 / 21.3 / 14.3. **`nosplit` does not take the stretch under 16 ms (22.8 and 21.3 against 22.9 and 23.1: 0 to 8% lower), so the two pictures are not the cost of it.** Caveats: the page's own checkpoints differ from the recording's (first at tick 600; the page ran the same match in all four runs, but not Orb's), so tick 1562 to 1644 on the page may not be the same event as Orb's; this hook's frame cost is about 15 ms outside the stretch (a step is two frames); I could not verify that `nosplit=1` acted on the web page. The window on the page IS 45% slower than the frames around it, in all four runs.
