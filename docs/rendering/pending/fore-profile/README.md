# The foreground rule's line kept fresh

Parked by Rendering on 2026-11-07, from Orb's morning look ("feet sinking into the ground at the start", homework/Files/orb-shots-1107/, shot 1). **It stacks second, after `crater-clock`, and lands with it.** `fore_profile.diff` (sha1 46af8d55, 54 lines, cut on main e1397e5c with crater-clock applied) touches `render/core/tile_ground.gd` and `render/core/look.gd`. Render only, and only on the tile ground.

## The fault

The tile ground's foreground rule (`tile_fore`) keeps everything in front of the line below the sight line from the camera to the line's own ground. That ground is a 64-sample profile along the view (`_profile`), and the shader reads it from where the camera is now. It was read again only inside the tiles' walk, when the camera had moved or zoomed enough to choose tiles again. While the intro's camera eased in, no walk came for several frames, so the profile was an earlier, wider view's: coarser, and taken from another camera place. As each fighter landed, it sat about 40 units above his feet, so the ground in front of him could stand over the sight line to his feet and hide them.

## The two causes of Orb's sunk feet

- **crater-clock** (World's find): the landing's crater under each fighter was never drawn while `S.T` stood at 0.
- **This park:** with the bowl drawn, a stale profile still let the near ground cover the feet as they landed.

Each alone leaves covered feet. Together they leave about 2 units.

## The change

- **Out of a turn,** the profile is read again whenever it would be off. That's once the camera has moved `FORE_PROFILE_STEP` (8) along the line or zoomed by `FORE_PROFILE_ZOOM` (0.5%), or the store, the tiles' version or the heading changed. It no longer waits for the walk.
- **While the line turns,** it's unchanged: every `TILE_PROFILE_FRAMES` frames, or on a move of `TILE_PROFILE_MOVE`.
- Off a field world (the profile reads the sim's ground there) the 4-frame cadence stays as a fallback.

## Proof

**Orb's 12:29 play's start,** headless through the game's own main with the tile ground, 2000×1125, on a8bc66e2 with the kept build's sim and data (`tile_ground.gd` and `look.gd` are the same on a8bc66e2 and main). For each fighter, I compared the ground as the tile vertex draws it (the bowls from the tile material, opening included) and the foreground with the rule against the sight line to his feet. Output: `docs/rendering/runs/a8bc66e2/feet-probe.txt`. Worst over 420 frames:

| | as built | crater-clock | crater-clock + this park |
|---|---|---|---|
| the rule's line above the feet (F0, F1) | 40.0, 8.7 | 40.0, 41.3 | 2.7, 2.7 |
| the foreground over the sight line to the feet | 38.4, 7.0 | 38.4, 40.8 | 2.0, 1.8 |
| frames the profile was read again, of 420 | 101 | 97 | 144 |

The profile's refresh depends on when tiles arrive, which varies from run to run, so the as-built figures move between runs (F1 7.0 here, 35.6 in an earlier run). A read costs about 0.33 to 0.43 ms (64 tile and store reads). This park adds about 40 reads in 420 frames.

**Gates on main e1397e5c** with crater-clock and crater-store: `docs/rendering/runs/e1397e5c/sunday-stack.txt`. It imports clean, `golden.json` is byte-identical, the five checks pass, the render gates pass 20 of 20, and with no tile ground the off stills match main, 13 of 13.
