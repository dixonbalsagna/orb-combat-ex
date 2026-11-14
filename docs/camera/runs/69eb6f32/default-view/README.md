# The default view (Reduce flashing on): as played against the camera stack

Camera, 2026-11-14, the EP's window: (A) the launch-hold pair for Orb and (B) the default-view side-by-side, which is also VFX's camera control for the clash's worst second (`docs/vfx/runs/4327cfbb/heat-glow-control.txt`). For the EP only.

## The trees (scratch, from main 69eb6f32)

| Tree | What |
| :--- | :--- |
| ap | main + Rendering's globe-default, crater-look-default, foot-slice (+ its hash_check grant) + VFX's meteor-default: VFX's as-played stack |
| ac | ap + a-camera-01 + cd04: the GW1a camera (splitShare 0.7, as in Orb's 9 November builds); follows a fast launch close |
| ah | ac + launch-hold-reduced: a fast launch flight holds the frame, then one catch-up cut |
| st | ah + launch-wide + reduced-pace + reduced-floor: the whole stack |
| sw | st with `pieces.launchHoldReduced` false (scratch data only): launch-wide, reduced-pace and reduced-floor pull the pane wide instead of holding |

## How

A web export of each tree. Each clip was captured through Tools' `tools/flash/run-pixels.mjs` at `--jobs 1`, one at a time, below-normal priority, with four readings (960x540 and 1024x768, scale 1 and 2). None was starved or void: 11.0 to 11.3 fps. The run-pixels guard tags its browser `nosession`, because run-pixels doesn't pass `--session` to capture-web; that's for Tools. The native traces were clip_digest runs (`--clips=clash,signature --modes=reduced`) with a scratch-only print of whether each fighter's chest is in his own pane (`SplitFrame.sees`). The pixel check counts P1's teal pixels in his pane: zero means he's not in it.

## Readings, the worst of four (`readings.txt`)

| Clip, default view | ap (as played) | ac (GW1a camera) | ah (+ hold) | st (whole stack) | sw (pull wide, no hold) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| clash | 6.5 (at 1075) | 5.5 (1075) | **2.5** (108, 151) | **2.5** (1075, 108) | 4 (about 152) |
| signature | 4.5 (71 to 81) | | | **2, pass** (71, 78) | |
| collapse | 3.5 (1112) | | | 4 (1112) | |

## Does the launched fighter stay in his own pane? (clash, P1; `own-pane-pixels.txt`, `own-pane-native.txt`)

| Tree | First launch (ticks 150 to 280) | Blast (1040 to 1200) |
| :--- | :--- | :--- |
| ap | out 181 to 240 (60 ticks) | out 1103 to 1116 (14) |
| ac | kept (out 16 ticks at most, in blips) | kept (blips of 1 to 3) |
| ah, st | **out 167 to 254 (88), back by a cut at 255** | **out 1087 to 1152 (66), back by a cut at 1153** |
| sw | out in short pieces (11 ticks at most), drawn as small as 23 px at 720p | out 1087 to 1111 (25) |

The two measures agree for ah and st. For sw, the native trace has him out 157 to 191 on the first launch and in through the blast, while the pixels show 25 ticks out at the blast. The web clip and the native run follow slightly different paths there, so the pixels are the record for what is seen.

## What it says

1. **The clash's worst second is the camera's.** With nothing changed but the camera, it reads 6.5 as played, 5.5 with the GW1a camera, 4 when the pane pulls wide, and 2.5 when the pane holds. The worst second moves off tick 1075 once the camera stops following the blasted fighter at fight size.
2. **The hold's gain comes from not showing him.** With launch-hold-reduced, the player's own fighter is out of his pane for 1.5 s on the first launch and 1.1 s on the blast, and comes back by a cut. Its name says "hold", but the frame doesn't go wide: it stays put while he flies out of it. The checks don't catch this (launch_shots counts "off" only once a split is fully open; this is the known gap owed after Sunday).
3. **Pulling wide keeps him, at a cost.** sw keeps him in his pane, apart from 25 ticks at the blast, by drawing him small (down to 23 px). It reads 4, not 2.5.
4. **The signature passes on the stack** (2 against 4.5), with nobody lost more than as played. The cost is size: both fighters drawn at 25 to 29 px (p10) against 43 as played, which is reduced-floor at work.
5. **Collapse doesn't improve** (4 against 3.5). Its last second is a pull-out keeping a parting pair in frame.

## Pictures (git-ignored, fighters in shot)

- `docs/camera/img/launch-hold-orb/`: follow-vs-hold-* (ac left "a", ah right "b") and follow-vs-wide-* (ac left, sw right), first launch and blast, GIF and stills.
- `docs/camera/img/default-view-stack/`: clash, signature and collapse, ap left against st right, plus clash-worst-second (ticks 1060 to 1110).
