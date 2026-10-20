# Parked: the scar a beam leaves in the air (VFX, 2026-10-19, on HEAD 4bb10168)

Orb's homework-6 note on the beam's tail: "it should look like it's burned a trail into the very space it passed through, some kind of lingering effect." The design and numbers: docs/vfx/beam-scar.md (inside the patch).

## Apply
`git apply docs/vfx/pending/beam-scar/apply.patch` (checked with `git apply --check` on a clean HEAD export in scratch). New: render/vfx/beam_scar.gd, scar_view.gd, shaders/beam_scar.gdshader (+ their .uid), docs/vfx/beam-scar.md. Edited: render/vfx/vfx_hub.gd (`scars`, `scar_enabled` on), render/vfx/trail_view.gd (a child view), data/vfx/energy.json and tools/schemas/vfx-energy.schema.json (a `scar` block), render/vfx/tools/effects_check.gd (12 checks), and ONE LINE in Rendering's render/core/warmup.gd (the shader added to the boot warm-up; needs the EP's grant for that line).

## Checks (scratch build of HEAD + patch)
effects_check passed (12 new), depth_check, flash_reg_check, after_check, pane_check, flash_check, cue_check passed; tools/validate.js 0 errors. Side by side against d3f1ca0e (side-by-side.mjs, seed 4, Reduce flashing) at ticks 1215, 1260, 1320, 1380 and 1739 to 1900, with GIFs in homework/beam-scar/ (private).

## Honest limits
Not a Legal clearance (dark with a lane-coloured rim, nothing quicker than a 1.2 s cooling, no pulse). Flash readings not re-run. A clash's beams are not scarred (no tail); the struggle work decides what the meeting leaves.
