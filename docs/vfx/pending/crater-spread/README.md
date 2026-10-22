# Parked: the crack mesh waits two ticks after its crater (VFX, 2026-10-22)

EP's brief: the first crater is still a 67 to 69 ms frame on the old-laptop bound (x4); find what of VFX's runs heavy on it and spread it.

Status: **parked, not applied.** `apply.patch` on HEAD 44877a1c (`git apply --check` clean): `render/vfx/vfx_hub.gd` (a `made` tick on each crack set; `build_next_crack` leaves a set alone until `VfxLook.CRACK_BUILD_DELAY` ticks have passed), `render/vfx/vfx_look.gd` (the constant, 2), `render/vfx/tools/effects_check.gd` (two lines: a set queued this tick is not built this tick, and is due after two).

## What VFX's share of that frame is (native, headless, scratch timers, seed 12345 `ai`, first crater at tick 239)

| Piece | Where | Native |
| :--- | :--- | :--- |
| the crater's crack lines (`VfxCrackGen.crater_lines`, in `_sync_cracks`) | hub consume | 0.28 to 0.40 ms |
| the ejecta (`earth.on_crater_ejecta`) | hub consume | 0.35 to 0.57 ms |
| the crack set's mesh (`VfxCrackMesh.build`, a GDScript strip build, in the layer's `crack_view`) | layer, the same frame | 0.74 ms |
| the rest of the tick's events | hub consume | about 0.2 ms |

About 1.8 ms of a 6 to 8 ms native frame, which at the old laptop's factor of 6 to 8 is the 7 to 10 ms Rendering found.
- **It is not a first use.** The first crater costs what the later ones do (tick 863: lines 0.44, ejecta 0.39, plus the blast 0.20), so a boot pre-build cannot remove it; only moving the work off the crater's tick can.
- **VfxWarm.nodes() would not help here.** It warms drivers, and this is CPU work in GDScript.

## What this does

The crack set's mesh was built in the same frame its crater was queued. It now waits two ticks (a thirtieth of a second); the crack grows from its `born` time, so it is a crack two ticks into its growth when it first draws. Nothing else moves: the lines, the vents and the ejecta stay on the crater's tick (the ejecta draw from the shared debris RNG, so shifting them would reorder every later effect's random draws).

## Measured: Performance's repro at x4 (`frame-bench --scene ai --reduced --throttle 4 --ticks 400 --warm 0 --seed 12345`, web export of HEAD plus Performance's hook, RTX, every run valid by the load rule, runs alternated)

| | tick 238, each valid run (ms) | median | mean |
| :--- | :--- | :--- | :--- |
| HEAD | 76.1, 58.4, 95.3, 76.6, 61.8, 55.6 (a seventh run's tick 238 was under 50) | 68.9 | 70.6 |
| this park | 63.3, 72.5, 59.4, 57.2, 64.8, 53.9, 55.8 | 59.4 | 61.0 |

- **About 10 ms off the median of the first crater's frame**, with a run-to-run spread of 15 ms: seven runs each give a plain but not a sharp difference. Read it as 5 to 10 ms.
- **Not cleared:** the 50 to 60 ms frames at ticks 253 to 275 are in both (three to four a run each): they are other owners' work (Rendering's map: the ground, the beams, Camera's strip), not the crack mesh.
- Steady frames: p50 within 1 ms in the pairs. Checks: effects_check passes with the two new lines; depth, after, pane, flash, cue and flash_reg checks pass; validate 0 errors. No look change to show (a crack appears two ticks later).

## Not done

- The crack lines (0.3 to 0.4 ms) could wait a tick too (their own seeded RNG makes the result the same whenever they are made), at the price of several checks that read `crack_sets` right after a consume.
- The Radeon city-beam hitches (ticks 6, 36 and 82 in my runs of `signaturecity --igpu`, not 121 and 432): drawing the real meshes in Rendering's warm-up viewport changed none of them. Tick 36 is the first signature wind-up (an attack, a banner, a ring and an after-image on that tick); tick 6 has no events. Not VFX's alone; needs Rendering and UI's first draws (the banner's text, the after-image) tried on that GPU.
