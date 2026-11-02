# Orb's second first-play: where the frame spikes come from (Performance and Platform, 2026-11-01, overnight)

For the EP. Source: `homework/Files/orb-first-play-20261101-2130.json` (kept there, private): 37,167 frames in 415.5 s (about 89 a second), 284 over 33 ms, 116 over 50, 10 over 100, worst 150 ms at tick 21827; the replay is 24,552 ticks (seed 3830001, final hash c130250f9f984886). The page: `orb-first-play-018b4edf-fc994af8`, key a0e90e2f576d, 57 parks, **Sample audio** (it lacks the `sound-stream-mode` park of the first play's build, and nothing else: I diffed the two parks' and switches' lists).

## In plain words

**The biggest cause is one routine: the swing director looks at every building to decide whether to offer a swing, about once every 72 ticks, and each look costs 8 to 16 ms.** It is in the match from tick 851 to the end (139 of the 194 ticks that cost 9 ms or more natively). The fix is already written and parked (Encounter's `grant-encounter-standing.patch` with Simulation's `field-place.patch`): applied to this match it cuts the ticks of 9 ms or more from 194 to 24 and the time in them from 2,530 ms to 375 ms. **It is not in the build Orb played.** What is left after it: the first swing of the match (35 to 41 ms at tick 583), the launches (8 to 28 ms, with one cold `predictFlight` of 17.6 ms at tick 13713), and two of World's.

The other half of the picture is the page: during long stretches (ticks 3570 to 3705, 5643 to 5711, 7501 to 7574, 3425 to 3475, 185 to 219) the tile ground's per-frame work and the planet view update are two to four times their usual cost, which is what makes up to 36 slow frames in a row. That is Rendering's (`RenderTileGround.apply` again), and my page reading of it is not valid on a loaded machine (below).

## The 284 slow frames, by what the sim was doing on the same tick (replay, native, one Godot job, below-normal)

| What | Frames | Share |
| :--- | ---: | ---: |
| The recorder's checkpoint (ticks 599, 1199 ...; 41 to 50 ms; this build still hashes every 600 ticks) | 40 | 14% |
| The sim tick itself 8 ms or more natively | 34 | 12% |
| The sim 4 to 8 ms natively (mostly the swing offers, with the stretches' draw on top) | 120 | 42% |
| The sim under 4 ms: draw-bound | 90 | 32% |

The first play (before): 36 / 35 / 31 / 55. The swing offers are what has grown (the replay is 2,450 ticks longer, and the offers recur every 72 ticks).

## Top causes by call, with owners (native sim timers on a scratch copy; the replay reproduces every checkpoint and the final hash c130250f9f984886 on it)

| # | Call | Cost | Where | Owner and fix |
| ---: | :--- | :--- | :--- | :--- |
| 1 | `DirSwing._brawlTick` -> `_offer` -> `scored` -> `candidates` -> `_standing` (walks every building record at each swing offer) | 8 to 16 ms a tick, every 72 ticks from tick 851; 139 ticks, 1.5 s in the match | the sim, on the main thread | **Encounter** (`DirSwing._standing`): `grant-encounter-standing.patch`, parked. With it and field-place: ticks of 9 ms or more 194 -> 24 |
| 2 | **Launches**: `chooseLaunch` 7 to 28 ms (`predictFlight` 17.6 ms at tick 13713, 10 ms at others), `DirSwing.atLaunch` and `_launchPick` 4 to 7 ms; ticks 2171, 6585, 11097, 13713, 16226, 20825, 22892, 23761 (22 to 47 ms before the patch, 13 to 33 after) | per launch | the sim | **Simulation** (`predictFlight`'s cold ground reads: the ceil table, parked) and **Encounter** (`atLaunch`, `_launchPick`: they walk the buildings again) |
| 3 | The first swing of the match: `DirSwing.scored` 34.6 ms at tick 583 (41 before the patch, 35 after) | once a match | the sim | **Encounter**: build the places once at match start, behind the intro, or spread it over ticks |
| 4 | `RenderTileGround.apply` and `PlanetView.update` in the long stretches | the stretches' view update 10 to 26 ms against a 6.5 ms median; tile ground 8 to 14.5 ms against 1.7 | the page | **Rendering** (`render/core/tile_ground.gd`): same as `orb-first-play-spikes-2026-11-01.md`, the far-separation section |
| 5 | The recorder's checkpoint hash | 27 to 44 ms each, 40 frames | the recorder, the private page only | **Tools**: no mid-match checkpoint (the final hash proves a replay), or hash in slices |
| 6 | `WorldWater.step` at a beam's window; `beamStep` 7 to 9 ms at ticks 15672 to 15674 and 24032; `WorldCollateral.tick` 11.6 ms at tick 2802; `stepFighter` 11 to 13 ms at ticks 18252 and 20871 (a body meeting a falling building or the ground) | 8 to 16 ms each, single ticks | the sim | **World** (water, collateral), **Combat** (beam, stepFighter) |

## World's `water-window-warm` (`flowWarm.cols` 48), tested on Orb's two matches

Applied to a copy (the sim and data parts of the diff on the same trees), `cols` 48, replay up to the window, `WorldWater.step` at the window's tick. **It does not take the window's cost down.**

| Match | Window tick | As played | `cols` 48 |
| :--- | :--- | ---: | ---: |
| First play (replay of 1424) | 11548 / 11570 | 32.9 / 25.1 ms | 30.8 (the window now starts at tick 11550) / 19.4 ms |
| Second play, run 1 | 18056 | 15.5 ms | 21.3 ms |
| Second play, run 2 | 18056 | 12.4 ms | 11.0 ms |

(Two runs each on the second match; one on the first, which reproduces every checkpoint up to the window with and without it. On the second the warmed copy diverges from the recording from the window on, as the park says: the checkpoint at tick 18000 is the first different one.) The first window of each match costs what it costs with or without it, so the 19 to 27 ms (now 12 to 33) are not the columns the warm reads; the rest of that tick in `WorldWater.step` is what is slow. Machine load 37 to 71% during these runs (marked, see below).

## Sample audio against Stream audio

Orb's first play (the `sound-stream-mode` park, Stream) averaged 7.5 ms a frame (133 a second) with 157 slow frames in 688 s; this one (Sample) 11.2 ms (89 a second) with 284 slow in 415 s. **That cannot be put on the audio mode:** the matches differ (24,552 against 22,102 ticks, different fights), and the machine was not the same machine (my own load readings through the evening were 40 to 99% from the other sessions' jobs). In my page recording the audio-cue call per frame is under 0.1 ms and the engine reports 0 ms of audio on the main thread. A clean A/B (the same replay on two scratch exports, with and without `default_playback_type.web=0`, on a quiet machine) would settle it; not done.

## Validity, and what to distrust

- **Load: INVALID by the 60% rule for almost every number above as an absolute.** The machine ran at 62 to 99% (the overnight workloads) during the native runs and 78/59% during the page recording; the sim's native times are CPU times of one below-normal process under that load, so their absolute values are upper bounds. The comparisons (as played against patched, the same ticks, the shares by call) are what carry: both sides of each pair ran under similar load, the replay reproduces on both, and the patch's effect (194 to 24 heavy ticks, 2,530 to 375 ms) is far beyond the spread (233 and 153 over 8 ms in two as-played runs; 50 and 53 in two patched).
- **The page reading uses Tools' rebuilt tree** (`base-a0e9`, key c7ac4ecb49c1: the same 57 parks re-cut, `ladder.json` and `meteor.json` restored): its sim reproduces Orb's hashes, but **its page-side code may differ from what Orb ran**. The page recording (50,776 frames in auto mode, one tick a frame, a 17 s stall in it) is marked invalid and read only for which counters rise in Orb's stretches, not for milliseconds.
- The page's frames in this harness are 20 to 60 ms against Orb's 7 to 11: only the shape carries.
- The sim attribution used the first play's tree for the sim files (same data hash 7718f9da7cb66d26 as the new recording; it reproduces every checkpoint and the final hash), with timers added on a scratch copy.

## Tools

`docs/perf/tools/preplay/`: `replay_prof.gd` (the native per-tick profile; the timed copies are scratch), `perf-run.mjs` (the whole match on the page, per-frame counters), `perf-stretch.mjs`, `layer-bisect*.mjs`; `docs/perf/tools/scratch-hooks/`: `hook-layers2.mjs`, `hook-perf.mjs` (existing), `hook-viewtimers.mjs` (the view update's timers). **The old-PC kit stays ready to rebuild** (`build-kit.mjs`, default `homework/Files/oldpc-kit-<build>`) when the EP says the next build is kept.
