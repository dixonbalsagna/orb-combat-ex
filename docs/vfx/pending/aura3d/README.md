# Parked: Orb's 3D auras (VFX, 2026-10-18)

Status: **parked, not applied; off by default** (`hub.aura3d_enabled` is false, `hub.set_aura3d(true)` turns it on and the old flat standing aura off). One patch, `apply.patch`, on HEAD 77ca29a4 (checked with `git apply --check` in a scratch export, not in the tree). `docs/vfx/aura3d.md` (in the patch) has the idea, the numbers and the limits. **Legal has not seen it** (the standing aura's earlier rule asked for a thin outline): it needs their re-screen before it is turned on.

Orb's private animated pictures are in `homework/auras-in-motion/` (git-ignored): two GIFs of the pair at tiers 1 to 4 and a close-up, with a short note.

## What is in `apply.patch`

| File | New or changed | What |
| :--- | :--- | :--- |
| `render/vfx/aura3d.gd`, `aura3d_view.gd` (+ `.uid` each) | new | the two inverted themes, the pure `params()` for every uniform, the colours and the rate bound; a sphere-mesh shell per fighter placed round his body, a child of the trail view |
| `render/vfx/shaders/aura3d.gdshader` (+ `.uid`) | new | the shell: object-space cellular pattern (the Protagonist's boil, the Anti-hero's facets), a fresnel rim, a travelling band, vertex undulation; alpha-blended, never additive |
| `data/vfx/aura3d.json`, `tools/schemas/vfx-aura3d.schema.json`, `tools/schemas/map.json` | new, new, changed | the numbers, their closed schema (rates capped at 2 Hz, alpha at 0.5), the map entry |
| `render/vfx/vfx_hub.gd`, `render/vfx/trail_view.gd` | changed | `aura3d_enabled`, `aura3d_demo`, `set_aura3d()`; the standing aura's ease also runs when it is on; the view child |
| `render/core/warmup.gd` | changed (Rendering's file) | one line in `RenderWarmup.SHADERS` for the new shader |
| `render/vfx/tools/effects_check.gd` | changed | `_aura3d`: 10 check lines (data = defaults; the eight inversions; rates; alpha; colours; params; calm form; off by default; the view builds hidden) |
| `docs/vfx/aura3d.md`, `README.md` | new, changed | the page, the table row |

No other file of anyone else's. `transform_view.gd` and `vfx_layer.gd` are untouched.

## Gates (scratch HEAD + this)

`effects_check` (with `_aura3d`), `hash_check` plain (register 379 granted / 9,027 refused, as on HEAD), `determinism`, `depth_check`, `after_check`, `flash_reg_check`, `validate` pass. Flash clips: a showcase of both auras at full level (the tier rising every 5 s, 1,250 ticks), both modes, 0 flashes, red 0; `collapse` both modes with the code in and inert PASS.

## For Tools and Legal

Tools: fixtures for `vfx-aura3d.schema.json` (one valid, three invalid: a `pulse_hz` of 2.5, an `alpha_max` of 0.6, a `froth` entry of 1.5). Legal: the aura re-screen (a shell with froth and facets in the lane colour, no flame, lightning, spikes, white, gold or red).
