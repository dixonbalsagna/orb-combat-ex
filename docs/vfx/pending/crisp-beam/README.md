# Parked: the crisp beam under Reduce flashing (VFX, 2026-10-18, on HEAD 7d93624e)

Orb's "wide, soft-edged, blurry blue block" at tick 1739 (AI match, seed 4, Reduce flashing on). Details and numbers: the new section "Crisp, not a block" in docs/vfx/beam-look.md (inside the patch).

## Apply
`git apply docs/vfx/pending/crisp-beam/apply.patch` (checked with `git apply --check` on a clean HEAD export in scratch). Seven files:
- render/vfx/beam_look.gd: `thickness(..., length)` caps each layer at `len_k` times the beam's length; layers thinner and crisper (defaults)
- data/vfx/energy.json and tools/schemas/vfx-energy.schema.json: the new `len_k` per layer, new k / px / alpha / soft
- render/vfx/shaders/beam_core.gdshaderinc: rounded ends at most 14% of the length each
- render/core/beam_view.gd (RENDERING'S FILE, one token: `VfxBeamLook.thickness(who, w, j, z, short, l)`; needs the EP's grant for that line)
- render/vfx/tools/effects_check.gd: two new checks, one loosened ("real width" 1.6 to 1.05 times the old look)
- docs/vfx/beam-look.md

## Checks (scratch build of HEAD + patch)
effects_check passed, depth_check passed, tools/validate.js 229 files 0 errors. Side by side against d3f1ca0e with Tools' tools/flash/side-by-side.mjs at ticks 1672, 1739, 1760 and 1130, 1167, 1200 (stills and GIFs in homework/crisp-beam/, private).

## Honest limits
Not a Legal clearance. Flash readings were not re-run (Orb paused that work); the beam is plainer and its edge steeper, so fx03's margin should only grow. The beam-patterns park (docs/vfx/pending/beam-patterns) is untouched and not yet rebased onto this: it needs a re-cut after this applies.
