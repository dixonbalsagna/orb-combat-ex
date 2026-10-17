# Parked: the catastrophe light class and the hitch probe (VFX, 2026-10-17; revised the same day)

Status: **parked, not applied.** `apply.patch` applies on a clean export of HEAD (checked with `git apply --check` in a scratch export, not in the tree). `docs/vfx/warm-up.md` (in the patch) has the findings and numbers.

**Revision.** The first version of this patch also carried a dense-burst thinning of debris, built for city variety's blocked collapse window. The clips (section 2 of `warm-up.md`) show it does nothing for that window: the window is the same with every debris bit off and with the whole VFX hub off, and collapse reads PASS 2.5 / 2.5 / 0.5 in both modes with city variety on, with or without the thinning, on main 20b95092. `debris.gd` and `vfx_look.gd` are **out** of the patch.

## What is in `apply.patch`

| File | New or changed | What |
| :--- | :--- | :--- |
| `render/vfx/flash_registry.gd` | changed | the `cat` class (`ask_cat`, `cat_shape`, `cat_level`, `cat_peak_near`; a `far_impact` low source): behind nothing, nothing calls it yet |
| `render/vfx/tools/effects_check.gd` | changed | `_cat_class`: 25 checks |
| `render/vfx/tools/hitch_probe.gd` (+ `.uid`) | new | the headless frame-time probe |
| `docs/vfx/warm-up.md` | new | the hitches, the probe, the collapse window and the blastdummy, ring and ai-43 readings |
| `docs/vfx/flash-registry.md`, `docs/vfx/README.md`, `docs/vfx/catastrophe-plan.md` | changed | the class's rows, the probe's row, the plan's pointers |

No file of anyone else's. Gates on scratch HEAD with these files: `effects_check` passed again after the thinning came out; the rest (hash_check plain and press styles, determinism plain and `--intro`, flash_reg_check, depth_check, after_check, validate) passed with the larger first version, and nothing they read is touched by what is left.

## For Rendering (a line, not in the patch)

`RenderWarmup.SHADERS` (`render/core/warmup.gd`, in their parked batch) lacks `["res://render/vfx/shaders/hole.gdshader", "multimesh"]`.

## To apply

On the EP's go: `git apply docs/vfx/pending/warm-and-cat/apply.patch`, then commit. Delete this folder after.
