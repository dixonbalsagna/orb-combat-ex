# The ground by band (22f) and the scorch and heat texture (22h), before and after (2026-10-23)

Owner: Performance and Platform, for the EP. Both are on main now, so each is measured as the commit before against the commit after, with the web export and Tools' hook (reduced mode), one browser at a time, interleaved with the order swapped between pairs, every run valid by the load rule. 22f: 243d4b57~1 (A) against 243d4b57 (B). 22h: d92cce64 (C, the docs-only parent of the apply) against 278bb83c (D). Frame times are the interval between two animation frames with vsync off (a free-running loop); x4 is Chrome's 4 times slower CPU (an old laptop's CPU, not its GPU); "Radeon" is the integrated GPU.

## 22f, the ground by band (the AI match for 6,000 ticks, the signature beam in the city for 600)

p50 / p95 ms; frames over 16.7 / 25 / 33 ms; the engine's CPU time per frame (renderer process); draw calls; median primitives.

| Scene, config | Before (A) | After (B) |
|---|---|---|
| **AI match, Radeon** | 9.4 / 22.6; 744 / 163 / 72 | **6.8 / 15.1; 232 / 74 / 39** |
| AI match, RTX | 5.1 / 7.0; 4 / 1 / 0 | 5.1 / 7.1; 5 / 1 / 0 |
| **AI match, RTX at x4** | 23.1 / 38.4; 5,611 / 2,255 / 598; cpu 30.5 ms | **21.6 / 33.6; 5,357 / 1,483 / 338; cpu 27.8 ms** |
| AI match, Radeon at x4 | 25.7 / 48.2; 5,890 / 3,231 / 1,117; cpu 34.5 | 25.9 / 46.9; 5,769 / 3,279 / 1,098; cpu 34.3 |
| **Beam in the city, Radeon** | 11.6 / 14.7; 16 / 4 / 3 | **8.8 / 11.7; 3 / 2 / 1** |
| Beam in the city, RTX | 5.4 / 8.0; 0 | 5.4 / 8.3; 0 |
| Beam in the city, RTX at x4 | 31.6 / 51.7; cpu 44.4 | 22.3 / 40.5; cpu 31.0 |
| Beam in the city, Radeon at x4 | 23.0 / 40.2; cpu 32.0 | 24.1 / 42.7; cpu 33.7 |

- Draw calls 105 to 113 (AI) and 222 to 228 (beam); median primitives 315 k to 107 k (AI) and 356 k to 127 k (beam).
- **Where the GPU is the limit it is a large gain**: on the Radeon the AI match's frames over 16.7 ms fall from 744 to 232 of 6,000 (a third), the median from 9.4 to 6.8 ms, and the city beam from 11.6 to 8.8 ms (the Radeon's slow stretches of the pacing note are mostly gone).
- **At x4 the 8 extra draw calls do not show.** On the RTX at x4 the AI match is better (p50 -1.5 ms, p95 -4.8, frames over 33 ms 598 to 338, CPU per frame -2.7 ms); the beam on the RTX at x4 is better by a lot in this pair (31.6 to 22.3 ms), but the earlier single pair at x4 (29.3 to 29.8) read the other way, so call it **neutral to better** with a spread of about 5 ms at x4 in that scene. On the Radeon at x4 (CPU bound) it is neutral: AI -0.2 ms, beam +1.1 ms and 5% more CPU per frame, inside the spread.
- No change at x1 on the RTX (the work there is the CPU's, not the ground's triangles).
- Verdict: **keep**. A big win on weak GPUs, no cost on a weak CPU within the measuring spread.

## 22h, the scorch and the heat on their own small texture (the AI repro, 800 ticks, three pairs per config)

p50 ms and the engine's CPU time per frame, before (C) then after (D), per pair:

| Config | p50 | CPU per frame | Pairs better |
|---|---|---|---|
| RTX | 4.5, 4.5, 4.7 then 4.5, 4.4, 4.4 | 4.86, 5.12, 5.02 then 4.63, 4.38, 4.63 (about -0.45 ms) | 3 of 3 |
| RTX at x4 | 19.0, 20.0, 18.7 then 18.3, 21.9, 18.1 | 24.9, 26.2, 25.1 then 24.7, 30.5, 24.3 | 2 of 3 (one pair 1.9 ms worse) |
| Radeon at x4 | 19.8, 25.8, 24.3 then 19.5, 21.0, 21.7 | 26.8, 34.7, 33.4 then 26.1, 28.9, 29.7 | 3 of 3 (0.3, 4.8, 2.6 ms) |

- Draw calls and primitives are identical (102, 94 k). **The gain is about 0.45 ms of engine CPU per frame at x1 (consistent) and 0.5 to 3 ms at x4**, in five of six x4 pairs, with a run-to-run spread of the same size (the Radeon x4 "before" ran 19.8, 25.8 and 24.3 on the same build). Consistent with the 1 ms the earlier timing build gave; it does not make anything worse.
- The tick-238 hitch (the first crater) is unchanged at x4 (66 to 73 ms before and after); this park does not touch it. One stray 208 ms frame at tick 390 in one "after" run on the Radeon at x4 did not repeat.
- Verdict: **keep**.

## The 33 ms frames on the Radeon since 74ee6b04: a wide shot in a changed match, not a regression of 7a

On main (b60d1913 to 570c3113) the city beam on the Radeon has bursts of 33 ms frames (two vsyncs): 31 to 35 frames over 25 ms in 1,200 (p95 18.2 to 18.9 against 10.1 to 10.5), at ticks 470 to 563 and 1162 to 1316. The Radeon bisect on the same scene: 22f, 22h, 5595363e, 0612b4fe and e90590b8 all read p95 10.1 to 10.5 with 1 to 2 frames over 25 ms; the step is 74ee6b04 (7a, whose golden regenerated the human replays, so the scene's match is a different one). RTX x1 and x4 did not move.

Layer cuts on the Radeon at those ticks (570c3113): the frame is 16.1 ms at tick 500 and 17.6 at tick 1,250 against about 8.7 ms elsewhere; **the terrain is 7.0 and 8.7 ms of it** (211 k and 205 k of the 323 k and 342 k primitives; the median frame has 132 k), buildings, trees and crowd 4.0 and 3.2 ms, everything else under 0.3 ms. So the bursts are, most likely, the **very wide shot** Rendering named as left over from 22f (about 7,800 units across, the coarsest stride's chunks all in view), now reached earlier in this scene (inferred from the terrain's primitives being 2.5 times the median; I did not read the camera's width). Owner: Rendering (a stride that coarsens with the zoom; needs a look decision, it would pop where it switches) with Camera (how wide the shot goes in a beam).

## Files

`make-audit-sites.mjs` builds any commit with `--rev` (here `243d4b57~1`, `243d4b57`, `d92cce64`, `278bb83c`, `--only base`); `frame-bench.mjs` runs them. Raw runs are in my scratch folder.
