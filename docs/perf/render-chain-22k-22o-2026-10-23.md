# Rendering's chain 22k to 22o, and UI's warm-marks (2026-10-23)

Owner: Performance and Platform, for the EP. Scratch exports of 671d850e (the chain applies on it): plain (with a cull counter and a desert scene added), then 22k and Camera's half-plane patch, plus 22l (the split culling), plus 22m (roll eases in), plus 22n (the biome ground look), plus 22o (the biome cover). Web export, Tools' hook in auto mode, reduced mode, the order of the four builds rotated between scenes, **all runs valid by the load rule** (the quiet window the EP gave: total load 5 to 24% during the runs). x4 is Chrome's 4 times slower CPU; "Radeon" is the integrated GPU. Scenes: the desert in one view (both fighters idle in the middle of the hand-made world's desert), an AI match of 1,800 ticks (split in 113 of them), the city beam of 600 ticks (split in 208). The 22n and 22o builds were run once at each config, plus two repeats at x4.

## 22l, the split culling: it works on the Radeon

Radeon at x1, plain then with 22l:

| Scene | p95 ms | Frames over 25 ms | Frames over 33 ms | p99 ms |
|---|---|---|---|---|
| AI match (split 113 of 1,800 ticks) | 11.7 then 11.3 | 18 then 4 | 7 then 1 | 28.1 then 14.5 |
| City beam (split 208 of 600) | 31.4 then 21.8 | 40 then 18 | 14 then 2 | 35.6 then 32.7 |
| Desert, one view | 12.5 then 11.9 | 2 then 3 | 1 then 1 | 16.3 then 16.2 |

- **The Radeon's slow split frames drop**: the AI match's frames over 33 ms from 7 to 1, the city beam's from 14 to 2 and its p95 by a third. The culling leaves out per frame about 14 to 76 items of the ground and water in pane 0 and 95 to 215 in pane 1.
- **Cost on the old-laptop CPU (x4)**: the engine's CPU per frame rises by 0.6 to 2.2 ms (2 to 8%): AI 29.6 then 30.2, beam 39.8 then 41.9, desert 25.7 then 27.9 on the RTX; the median frame is unchanged on the RTX (23.0 and 23.0 in the AI match). On the Radeon at x4 the median moved with the machine (AI 19.7, 23.0, 24.0 plain against 23.7, 23.2, 24.0 with 22l): no clear cost. x1 on the RTX: unchanged.
- Verdict: **keep**; it does what it was made for.

## 22m, the roll eases in over 0.5 s

Nothing measurable (the roll is off by default).

## 22n, the biome ground look: it triples the Radeon's frame time

Radeon at x1, p50 / p95 ms, then frames over 33 ms of the scene:

| Scene | plain | + 22l | + 22n | + 22o |
|---|---|---|---|---|
| AI match | 6.5 / 11.7; 7 | 6.5 / 11.3; 1 | **21.2 / 48.3; 145** | 21.1 / 47.8; 142 |
| Desert, one view | 6.6 / 12.5; 1 | 6.5 / 11.9; 1 | **20.9 / 46.8; 43** | 21.0 / 46.6; 46 |
| City beam | 9.2 / 31.4; 14 | 9.2 / 21.8; 2 | **24.3 / 61.9; 154** | 24.3 / 61.7; 153 |

- **The step is 22n**, on every scene: +14 ms a frame on the Radeon. Draw calls and primitives do not change (105 / 213 / 233 draws, 98 k / 109 k / 129 k), so it is fragment work, which the 2-CU Radeon cannot carry; the RTX at x1 is unchanged (4.5 ms, p95 +0.4).
- **At x4** it is worse in the tail: RTX AI match p95 34.0, 39.2, 34.9 (plain, three runs) against 44.3, 38.3, 51.2 (22n), engine CPU per frame 29.6, 30.8, 27.2 against 32.5, 30.4, 38.7; Radeon AI p95 34.1, 34.2, 41.6 against 50.4, 42.4, 39.8; desert on the Radeon p50 14.2, 22.8, 21.7 against 20.6, 21.0, 20.7. The desert on the RTX at x4 is unchanged (20.1, 21.0, 13.4 against 21.1, 20.9, 13.7; the three repeats ran at different speeds as the machine drifted, so compare within a repeat).
- **Cannot go on as it is for the old-GPU tier**: a Radeon that held 6.5 ms would run the ground at 21 ms (about 48 fps) with a p95 of 48 ms. Rendering needs a cheaper path for weak GPUs (fewer fetches a fragment, a per-vertex biome colour, or a quality step), and then I re-run. Owner: Rendering.

## Re-bench of the re-cut 22n and 22o (2026-10-26): the 3x is gone

Rendering found the 3x was ANGLE's emulation of flat varyings (provoking vertex), not the biome shading, and re-cut 22n and 22o with no flat varyings. Build: HEAD 3c8f6838 (which carries 22k, the half-plane, 22l and 22m) against HEAD plus the re-cut 22n, against HEAD plus 22n and 22o. Three interleaved repeats on the Radeon at x1, two at x4 and on the RTX, all valid (load 5 to 24% before each run), reduced mode. Median of the repeats, p50 / p95 ms; frames over 33 ms of 600 or 1,800:

| Scene (Radeon, x1) | main | + 22n | + 22n + 22o |
|---|---|---|---|
| Desert, one view | 6.7 / 12.0; 1 | 7.3 / 13.2; 1 | 7.3 / 13.1; 1 |
| AI match | 6.8 / 12.2; 1 | 7.3 / 12.8; 1 | 7.3 / 12.8; 1 |
| City beam | 9.4 / 28.8; 7 | 9.6 / 33.0; 18 | 9.6 / 32.8; 16 |

- **The re-cut costs about 0.5 to 0.6 ms a frame on the Radeon (+8%), against +14 ms before** (21.2 ms in the AI match). Draw calls: 105 / 213 / 233 on main, the same with 22n, +10 / +10 / +5 with 22o; 22o adds nothing in frame time on top of 22n.
- **The city beam is the one place it shows**: p95 28.8 to 33.0 (the 33 ms vsync step) and 7 to 18 frames of 600 over 33 ms (1.2% to 3%); the beam already had slow split frames on main.
- **Radeon at x4 (the old laptop's GPU and CPU)**: AI match p50 37.9 / 38.5 / 32.8 (main, 22n, 22n + 22o; the machine's drift between repeats is larger than the difference), desert 25.3 / 24.1 / 31.8 and 24.6 on the second repeat; the engine's CPU per frame within 3% (AI 47.1 and 47.4). Beam at x4 p95 85.5 / 104 / 86.2 (one of the two 22n repeats 85.2, the other 104).
- **RTX at x1 and x4**: unchanged (AI 5.6 / 5.8 / 5.7 at x1; desert 4.9 for all three).
- **Verdict for the old-laptop budget** (60 fps on the first tier, 30 fps floor on the second): **it fits.** On the Radeon every scene keeps p95 under 14 ms except the city beam, whose p95 sat on the 33 ms step before and still does; the cost is half a millisecond a frame. The beam's extra 33 ms frames (about 10 in 600) are the thing to watch.

## 22o, the biome cover (first cut)

- **Free in frame time.** Radeon x1 AI match 21.2 then 21.1 ms, desert 20.9 then 21.0; RTX x1 4.5, 4.5. At x4, three runs of the desert on the RTX: plain 20.1, 21.0, 13.4; 22o 14.7, 21.1, 13.7 (the first read 14.7 against three builds at about 21 in that repeat; the repeats do not repeat it, so noise).
- **Draw calls +10 and primitives +5 k**: 105 then 115 (AI), 213 then 223 (desert), 233 then 238 (beam); the engine's CPU per frame within 1 ms at x1.

## UI's warm-marks (docs/ui/pending/warm-marks): neutral to slightly worse

City beam on the Radeon, ticks 1 to 60 of the scene, four interleaved pairs, valid:

| | Tick 0 (the scene's first frame) | Tick 6 | Frames over 20 ms after tick 20 | Sum of ticks 1 to 60 |
|---|---|---|---|---|
| Plain | 446, 373, 376, 374 ms | 59 to 62 ms, every run | 32 ms frames at ticks 30, 35, 41, 46 in every run; tick 50: 48.8, 32.3, 32.4, 32.1 | 984, 981, 969, 971 ms |
| With warm-marks | 356, 355, 358, 356 ms | 60 to 61 ms, every run | the same 32 ms frames; tick 50: 31.7, 48.3, 49.7, 49.3 | 980, 976, 995, 989 ms |

- **It does not remove the tick-6 hitch** (60 ms in all eight runs). It trims the scene's first frame by about 18 ms (356 against 373 to 376; the 446 was an outlier).
- **Tick 50 is 16 ms longer in three of four patched runs** (one more vsync step on a frame that sits on the edge); the sum over 60 ticks is 976 then 985 ms (+1%, inside the spread). The 33 ms frames at ticks 30, 35, 41 and 46 are in both builds (a regular 5 or 6 tick beat in the city beam on this GPU; not the patch).
- Verdict: **neutral**; it moves a little cost from the first frame to the HUD's first marks. Not worth a switch unless the first frame matters.

## Not done

- The second-press latency runs (a light, heavy and signature pressed again 150, 350, 700 and 1,100 ms after the first, to catch a `queued` acknowledgement) all failed in the analysis (0 of 8 each): the bench cannot yet analyse a second press. Animation's anticipation on `queued` is therefore unmeasured.
- The Rendering chain was read at one build of each; 22n's x4 effect has two repeats and a spread of about 5 ms in p95.

## Files

`make-audit-sites.mjs` variants `basec`, `s22k`, `s22l`, `s22m`, `s22n`, `s22o`, `warmmarks`; `scratch-hooks/hook-cullstat.mjs`, `hook-desert.mjs`; `frame-bench.mjs` (`cull`). Raw runs are in my scratch folder.
