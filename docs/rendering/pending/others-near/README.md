# 2v2: the other fight's bodies with --others, its light only with the effects word, its hub only when near

Parked by Rendering on 2026-11-07: step A of `docs/rendering/2v2-drawn-plan.md` (the EP's brief on Orb's first 2v2, Legal RL-249's drawn case). `others_near.diff` (sha1 e07fddb4, 91 lines) is cut against main c5b42dc1. It touches `render/core/sim_host.gd`, `render/core/pane_world.gd`, `render/core/main.gd` and `render/core/beam_view.gd`. With `--others` off (the default), and in every 1v1, nothing changes.

## What changes

- **`--others` alone draws the other fight's bodies and shadows,** as on main (within `OTHER_VIEW_MARGIN` half-widths plus `OTHER_VIEW_PAD` of a pane's view), and none of its light.
- **Its beams now need the effects word too** (`VfxHub.other_fights_enabled`, today only `?otherfights=1` on a local page). On main they were drawn calm, outside any register, which RL-249 (2) rules out ("calm is not an exemption").
- **Its hub takes its events only while a pane drew one of its bodies the frame before** (`SimHost.other_near`, `saw_other`, `near_done`, `other_events_near`). A fight round the planet runs no effects, so nothing of it is counted, and nothing pops in mid-effect as it swings into view (RL-249 (4)). Audio's other-fight call still reads every fight, `other_events`.

## Proof

**Unverified (CD-22):** the probe's output behind the table below was deleted with the scratch at the 2026-11-07 pause. It's re-run with the gates (the EP's item 2), and the outputs are saved under `docs/rendering/runs/`.

**A 2v2 together match** (net/lan.gd SETUP2X, four computers, seed 12345, tile ground, `--others`), 2,400 frames, the effects word off and then on. Scratch probe, with the other pair put beside the first at the start, because computer pairs stay half a ring apart:

| | main | this park |
|---|---|---|
| frames a pane drew the other fight's bodies | 2,089 | 2,089 |
| effects word off: frames its beam was drawn, of 82 with one | 82 | 0 |
| effects word on: frames its beam was drawn | 82 | 82 |
| its hub's events after frames no pane drew it (word on) | 449 | 0 |
| its hub's events after frames a pane drew it (word on) | 3,797 | 3,797 |

Left where they start, half a ring apart, no pane drew the other fight in 2,400 frames, on either tree. Main still drew its beams (136 frames) and fed its hub 4,034 events. The park does neither until the word is on, and then feeds nothing while it's far.

**Gates not run yet** (stopped at Orb's pause on 2026-11-07): it applies on main c5b42dc1 and imports clean. Golden, the checks, the render gates and the off stills are still to run.

## Not in this (the plan's later steps)

- The other fight's light asking the one register (VFX's, then Rendering step B).
- Camera framing all four when the pairs are near (Camera).
- The desktop switch (UI) and the LAN kit passing `--others` (Netcode, Tools).
