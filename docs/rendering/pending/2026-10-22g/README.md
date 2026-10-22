# Parked: the first crater's own costs, pre-built (Rendering, 2026-10-22)

**Base:** HEAD 243d4b57 (the ground by band applied). Every check ran on copies of the commit, never on the tree.

**Apply** from the project root: `git -c core.autocrlf=false apply docs/rendering/pending/2026-10-22g/batch.diff`. Then delete this folder.

## What it changes

| File | Change |
| :--- | :--- |
| `render/core/beam_view.gd` | at boot: `VfxBeamLook.warm()` (the beam look's data) and the first beam slot (three layers, their materials, hidden); the slot builder is `_grow_pool` |
| `render/core/ground_field.gd` | the deform scan compares runs of 64 columns in the engine and walks only the runs that changed (the same columns, in the same order) |
| `docs/rendering/geometry-and-warmup.md` | "The first crater on an old laptop": the frame's sections, whose they are, what this changes |

## Checked

- **Native** (the AI scene as the hook plays it): the first crater's frame goes from 10.1 to 7.2 ms; the beams from 3.35 to 0.27 ms; the deform scan from 0.34 to 0.20.
- **Web, x4, the integrated GPU** (four runs, valid): the beams' share of the first crater falls from 2.6 to 3.9 ms to 2.0. The frame moves within these runs' noise.
- **What is left** of that frame is VFX's layer, the host's tick (the sim and its consumers), the ground's update and the strip's draws: see the docs.
- **Gates:** `gates9` (17 checks) and `cue_check` pass, with 0 script errors.
- **The look:** nothing on screen changes. The first slot is hidden until a beam uses it, as any slot is.
