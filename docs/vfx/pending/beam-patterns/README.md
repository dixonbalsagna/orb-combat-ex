# Parked: each fighter's beam made unmistakable (VFX, 2026-10-18)

**Re-cut 2026-10-22 on HEAD b3a3aa74** by a three-way merge with the struggle's shader waves and its effects_check changes (the earlier cut undid the 'old ring tests run with struggle_enabled off' lines): the struggle's `wv0`..`wv2` waves and the patterns' `pat*` live side by side in beam_core.gdshaderinc, and effects_check runs both `_beam_struggle_beams` and `_beam_pattern`. Applied after power-rings, effects_check passes (and depth, flash_reg, after, pane, flash, cue); a web capture of the clash shows the scallops and mosaic on the wave-capable beam.

**Re-cut 2026-10-19 on the crisp beam (HEAD cba28a55, `git apply --check` clean):** the patterns (the boil's scallops and bubble rings, the facets' zigzag and mosaic) now sit on the crisp, thinner beam the EP applied; effects_check, depth_check, flash_reg_check and after_check pass; validate 0 errors. Before and after (plain crisp beam against with patterns) in `homework/beams-distinct/` (3 and 4, private). The other parked patches (the scar, the struggle) edit some of the same files (beam_core.gdshaderinc, energy.json, its schema, effects_check): apply them one after another and tell VFX to re-cut the later ones if a hunk is refused.

Status: **parked, not applied.** One patch, `apply.patch`, on HEAD 77ca29a4 or later (checked with `git apply --check` in a scratch export, not in the tree). The text is `docs/vfx/beam-look.md`, "Distinct patterns" (in the patch). Orb's private stills are in `homework/beams-distinct/`.

**What it does.** The Protagonist's beam gets the **boil** (rounded scallops along its edge, bubble rings of the second tint inside) and the Anti-hero's the **facets** (a straight zigzag edge, a mosaic of two close hues): the same inversion as their auras (`docs/vfx/pending/aura3d/`), told apart by shape and by hue and never by a step in brightness. His thin needle and everyone else's beam stay plain.

**Within the flash register and Legal's fx03.** The pattern is on the body and the core only; it moves the alpha by 3% at most (the body's shimmer is 7%, together under a tenth: checked), the calm form (every beam under Reduce flashing) halves that and keeps the silhouette, the hue patterns are between two tints of the same luminance, everything travels slowly toward the head, the axis stays a straight line. **The new silhouettes have not been screened by Legal.**

## What is in `apply.patch`

| File | Changed | What |
| :--- | :--- | :--- |
| `render/vfx/shaders/beam_core.gdshaderinc` | yes | the `pat`, `pat_k`, `pat_a`, `pat_scale` uniforms, a 2D cellular function, the edge cut and the pattern, told apart by hue |
| `render/vfx/beam_look.gd` | yes | the defaults and `set_layer` pass the pattern; the sheath has none, the calm form halves the texture |
| `data/vfx/energy.json`, `tools/schemas/vfx-energy.schema.json` | yes | the Protagonist's and the Anti-hero's pattern, a `pat_w` per layer; the schema caps `pat_k` at 0.03 |
| `render/vfx/tools/effects_check.gd` | yes | `_beam_pattern` (7 check lines) |
| `docs/vfx/beam-look.md` | yes | the section |

No other file of anyone else's; `beam_view.gd` (Rendering's) is untouched.

## Gates (scratch HEAD + this)

`effects_check` (with `_beam_pattern`), `hash_check` plain (379 / 9,027, as on HEAD), `determinism`, `depth_check`, `after_check`, `flash_reg_check`, `validate` pass. Flash clips (Tools' path, both modes) are in `docs/vfx/beam-look.md` under "Distinct patterns": the edge cut was first built deeper (30% and 34%), which tipped clash normal's area reading from 3 to 3.5 (FAIL); at the built 18% and 20% clash normal and signature normal read 2 / 3 / 2, equal to the baseline (both already over the 2.5 gate without the pattern).
