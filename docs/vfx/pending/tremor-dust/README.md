# Parked: the tremor's dust (catastrophe tier, step 2; VFX, 2026-10-17)

Status: **parked, not applied.** Two patches, in this order, on top of **`docs/vfx/pending/warm-and-cat/apply.patch`** (the `cat` class and the hitch probe), which must be applied first (this one adds a check beside its `_cat_class`). `docs/vfx/tremor-dust.md` (in `apply.patch`) has the numbers and the measurements.

1. `apply.patch`: the tremor's dust, applied on HEAD with the warm-and-cat patch applied (checked with `git apply` in a scratch export, not in the tree).
2. `warmup-entries.patch`: **apply only after Rendering's parked batch** (`docs/rendering/pending/2026-10-17/`, which creates `render/core/warmup.gd`): it adds two lines to `RenderWarmup.SHADERS`, `dust.gdshader` (this effect's) and `hole.gdshader` (VFX's, missing from their list). `warmup.gd` is not in HEAD, so these two lines cannot ride in `apply.patch`.

## What is in `apply.patch`

| File | New or changed | What |
| :--- | :--- | :--- |
| `render/vfx/tremor.gd`, `dust_view.gd`, `shaders/dust.gdshader` (+ `.uid` each) | new | the tremor's state, envelope, calm form and rubble; the dust curtains (one MultiMesh, one draw call, at most 160 sprites) and their soft shader |
| `data/vfx/catastrophe.json`, `tools/schemas/vfx-catastrophe.schema.json`, `tools/schemas/map.json` | new, new, changed | the numbers, their schema, the map entry (the data file has built-in defaults that a check holds equal) |
| `render/vfx/vfx_hub.gd`, `render/vfx/trail_view.gd` | changed | the hub's `tremor` and `catastrophe_enabled`, three lines in `_consume`; the trail view's `dust_view` child, like the shots view |
| `render/vfx/tools/effects_check.gd` | changed | `_tremor` (18 checks) |
| `docs/vfx/tremor-dust.md`, `catastrophe-plan.md`, `README.md` | new, changed, changed | the page, the plan's "built" note, the table row |

No file of anyone else's (`warmup-entries.patch` is a patch to Rendering's parked file, for their batch). `transform_view.gd` and `vfx_layer.gd` are untouched. **Nothing draws until Simulation emits a `tremor` cue** (`n` = the tick it ends); a scratch scene injected it for the clips.

## Gates (scratch HEAD fba75d21 + warm-and-cat + this)

See `docs/vfx/tremor-dust.md` "Measured": `effects_check` (with `_tremor`), `hash_check` plain, `determinism`, `flash_reg_check`, `validate`; the flash clips of the tremor scene, both modes (PASS, red 0).

## For Tools

`vfx-catastrophe.schema.json` has no fixtures yet (`validate` passes without them): a valid case and three invalid ones (an `alpha_max` of 0.6, a `sprites` entry over 160, a `z` over -5) are the minimum for the coverage check.
