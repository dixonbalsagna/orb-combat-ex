# Park: nightly windows that hold their event, and a check that keeps them so (Tools, 2026-11-26)

Cut on HEAD 4db9917b. **The two patches must land together** (the flash self-test fails if the headless and web stagings differ):

- `nightly-windows.patch` (Tools');
- `grant-rendering-clash-scene.patch`: `render/tools/flash_capture.gd` (Rendering's): the clash scene moved into `_clash()`, the same text as the headless one. Nothing in a player's build changes (`render/tools/` is the capture hook).

## What was wrong

Beside the four clash windows (no clash since about 11-21), **the two collapse windows held no falling building** either: in the scene, buildings fall only at ticks 93, 243 and 543. So six of the ten nightly clips were reading something else.

## What changes

- Clash scene: nothing for 90 ticks, then cycles of 500, so a clash falls at 140 (past the uncounted first 60) and another at 1140.
- Windows: clash and clash-night 1 to 240; collapse 1 to 300; signature and rushcity unchanged (they hold their events).
- `flash_worst.gd` records event ticks; `tools/flash/window-check.mjs` + self-test; two CI steps.

## Local readings (hardware, 960x540, main's game; for the EP only)

| Clip | New window | Full clip |
|---|---|---|
| clash-normal | 1 / 0 / 1 / 1 | **2.5 / 0 / 2.5 / 2.5** |
| clash-reduced | 1 / 0 / 1 / 1 | **2.5 / 0 / 2.5 / 2.5** |
| collapse-normal | 1 / 0 / 1 / 1 | 1 / 0 / 1 / 1 |
| collapse-reduced | 1 / 0 / 1 / 0.5 | 1 / 0 / 1 / 1 |

(primary / red / area-15% / two-second memory)

- **The clash clip's worst second is not the clash:** it is ticks 1454 to 1495, a melee in split screen, on our limit of 2.5. The nightly does not read it. Not checked: whether that moment is new with this scene.
- **The second clash (tick 1140) happens in split screen, and no flare shows** in the browser (the headless register counts one there). For Camera or Rendering if a clash across the split should show.

## Checks run

Flash self-test 101; window-check self-test 10; `window-check` passes on all ten windows from a fresh headless run; `check-log.js` passes on the new scenes; nightly-windows, workflow and script-table checks.

## Next

Baseline: after this lands, two dispatched flash nightlies, then the record is re-taken from them (the EP's word).
