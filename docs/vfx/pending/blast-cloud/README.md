# Parked: the blast cloud (catastrophe tier, step 3; VFX, 2026-10-18)

Status: **parked, not applied; inert until a `blast_cloud` cue exists.** One patch, `apply.patch`, on HEAD 51b3be97 with warm-and-cat and tremor-dust already applied (checked with `git apply --check` in a scratch export, not in the tree). `docs/vfx/blast-cloud.md` (in the patch) has the numbers, the look and the measurements.

## What is in `apply.patch`

| File | New or changed | What |
| :--- | :--- | :--- |
| `render/vfx/blast_cloud.gd`, `cloud_view.gd` (+ `.uid` each) | new | the cue, the landing, the one ask of the `cat` class, the light envelope, the CPU mirrors; the view: a 400-sprite body in one draw call and a 16-sprite additive fireball, the sprite ladder |
| `render/vfx/shaders/cloud.gdshader`, `cloud_core.gdshader`, `cloud_curves.gdshaderinc` (+ `.uid` each) | new | the stateless vertex-shader curves, the fire-to-smoke ramp, the soft billowy edge |
| `data/vfx/catastrophe.json`, `tools/schemas/vfx-catastrophe.schema.json` | changed | the `blast_cloud` block and its closed schema block (the built-in defaults are held equal by a check) |
| `render/vfx/vfx_hub.gd`, `render/vfx/trail_view.gd` | changed | the hub's `blastcloud` and `ash` and three lines in `_consume` inside `catastrophe_enabled`; the trail view's `cloud_view` child |
| `render/core/warmup.gd` | changed (Rendering's file) | **two lines in `RenderWarmup.SHADERS`** for the two new shaders, as asked |
| `render/vfx/tools/effects_check.gd` | changed | `_blast_cloud` (17 check lines) |
| `docs/vfx/blast-cloud.md`, `catastrophe-plan.md`, `README.md` | new, changed, changed | the page, the plan's "built" note, the table row |

No other file of anyone else's. `transform_view.gd` and `vfx_layer.gd` are untouched.

## Gates

See the page: `effects_check` with `_blast_cloud`, `hash_check` plain, `determinism`, `depth_check`, `after_check`, `flash_reg_check`, `validate`; the flash clips of the blast cloud scene in both modes (PASS, red 0), and `collapse` in both modes with the code in and inert (PASS).

## For Tools

`vfx-catastrophe.schema.json` has the `blast_cloud` block: a fixture for it (one valid, three invalid, e.g. `alpha_max` 0.95, a `sprites` entry of 500, `core_radius_k` 0.5) is Tools'.
