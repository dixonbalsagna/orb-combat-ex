# Parked: Orb's 3D auras (VFX, 2026-10-18)

**Re-cut 2026-10-22 (second look gate, Legal's fx06 and Rendering's conditions), rebased on HEAD 14d10d94 **and on `warm-first-use`: apply that park first**, then apply.patch, then grant-fighter-view.patch (all three `git apply --check` clean in order); effects_check, depth, after, pane, flash, cue and flash_reg checks pass; validate 0 errors.**
- **No stroke inside the body (EP):** the fragment reads the opaque depth behind it and is discarded unless the scene is at least 60 units farther (`hull_gap`): the arm's and head's hull faces lying over the torso have the body just behind them and are gone; only the fringe outside the silhouette remains, even with a hand over the torso.
- **Transient (Legal fx06 1):** the aura runs as a BURST, not a standing glow: when a fighter starts charging or attacking and the last burst ended at least 4 seconds ago, it rises over 0.3 s, holds 0.9 s, falls over 0.8 s and is gone whatever he is doing, until a new start after the gap (aura.gd `burst`, data `burst_*` in aura.json with schema bounds). It does not grow with the tier (a constant 7 percent of his height off the body). No whole-aura pulse (the band's thickness and alpha no longer breathe), no tongues, no crackle.
- **Rendering's conditions:** the pass is chained after the outline only while its level is up (`grant-fighter-view.patch`, the lines the EP gave), the hull registry is pruned to the current fighters at each match's reset, and the hull draws before the water (render priority -1), so a submerged fighter's band takes the water's tint like his body.
- **Schema fixtures (Legal fx06 3):** `fixtures.json` beside this file proposes the cases (2.5 Hz pulse, 2.5 cell rate, alpha 0.6, burst gap and hold out of bounds, one valid) for Tools to add to tools/fixtures/cases.json (Tools' file); the schema bounds already reject them.
- **First draw warmed (Performance, 2026-10-22):** the aura's first draw hitched 50 to 110 ms although its shader was in the boot table (the pipeline is the shader on the SKINNED fighter mesh with the depth texture read). `VfxAura3D.warm_node()` (in apply.patch, called by the warm park's node list) stands a real `AnimBody` with the hull chained after its outline in the pane for the warm-up's frames. On Performance's signaturecity scene with the aura held up: the tick 6 and tick 82 hitches are gone, only the page-load tick 0 remains. Verdict from Performance stands: default-on only with this in.
- **FighterView (grant):** `grant-fighter-view.patch` now chains the hull only while its level is up, as Rendering asked; the file is unchanged (it still applies on HEAD 14d10d94).
- Still off by default; Legal passed it with these conditions (docs/legal/aura3d-screen.md); not in public material until Orb approves.



Status: **parked, not applied; off by default** (`hub.aura3d_enabled` is false, `hub.set_aura3d(true)` turns it on and the old flat standing aura off). One patch, `apply.patch`, on HEAD 77ca29a4 (checked with `git apply --check` in a scratch export, not in the tree). `docs/vfx/aura3d.md` (in the patch) has the idea, the numbers and the limits. **Legal passed it on 2026-10-22 with conditions (fx06, docs/legal/aura3d-screen.md), all built in below**: brief and one mark of the seven, no tongues or whole-aura pulse, nothing inside the outline, rates and alpha asserted, not in public material until Orb approves.

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
