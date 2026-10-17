# Parked: the catastrophe light class, the dense-burst thinning and the hitch probe (VFX, 2026-10-17)

Status: **parked, not applied.** Built and gated in a scratch export of HEAD af5151b5; my files are unchanged on HEAD 754afbeb, so `apply.patch` applies there (checked with `git apply --check` in a clean export, not in the tree). `docs/vfx/warm-up.md` (in the patch) has the findings and the numbers.

## What is in `apply.patch`

| File | New or changed | What |
| :--- | :--- | :--- |
| `render/vfx/flash_registry.gd` | changed | the `cat` class (`ask_cat`, `cat_shape`, `cat_level`, `cat_peak_near`; a `far_impact` low source): behind nothing, nothing calls it yet |
| `render/vfx/tools/effects_check.gd` | changed | `_cat_class`: 25 checks (the floors, the calm form, the ash, the 119 / 120 tick edge, one answer per id, the small split, red, the calm repeat, a 4,000-tick hammer in both modes, determinism) |
| `render/vfx/debris.gd`, `render/vfx/vfx_look.gd` | changed | the dense-burst thinning (`DENSE_START` 90, `DENSE_KEEP_MIN` 0.35) for the collapse clip's blocked debris run |
| `render/vfx/tools/hitch_probe.gd` (+ `.uid`) | new | the headless frame-time probe |
| `docs/vfx/warm-up.md` | new | the hitches, the probe, the thinning; what the numbers are and are not |
| `docs/vfx/flash-registry.md`, `docs/vfx/README.md`, `docs/vfx/catastrophe-plan.md` | changed | the class's rows, the probe's row, the plan's pointers |

No file of anyone else's. `transform_view.gd` and `vfx_layer.gd` are untouched.

## Gates (scratch HEAD af5151b5 + these files)

`effects_check` passed; `hash_check` plain passed (flash register in real matches 385 granted, 9,027 refused: the same as on HEAD); `hash_check -- --press-styles` passed; `determinism` plain and `-- --intro` passed; the negative control failed as it must; `flash_reg_check`, `depth_check`, `after_check` passed; `node tools/validate.js` 192 files, 0 errors, 0 warnings. **No on-screen look changed except a collapse with 195 flying shards where it had 234 (and only when more than 90 are alive at once)**; `collapse` both modes is Tools' to read once captures are allowed, before and after, with city variety off and on (the target is a fullest window of at most 19,600 pixels at ticks 124 to 130; HEAD reads 22,479 with city variety on).

## For Rendering (a line, not in the patch)

`RenderWarmup.SHADERS` (`render/core/warmup.gd`, in their parked batch) lacks `["res://render/vfx/shaders/hole.gdshader", "multimesh"]`.

## To apply

In the tree, on the EP's go: `git apply docs/vfx/pending/warm-and-cat/apply.patch` (it also leaves the new `.uid`), then commit. Delete this folder after.
