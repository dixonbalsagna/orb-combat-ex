# Parked: warm every first draw in the real pane (VFX, 2026-10-22)

Performance's brief (docs/perf/inset-hitches-aura-2026-10-22.md): the first hit (tick 131, about 93 ms) and the match's first crater (tick 238, about 163 ms) hitch on a cold cache, and the aura's first draw (50 to 110 ms) does too.

Status: **parked, not applied.** `apply.patch` on HEAD 14d10d94 (`git apply --check` clean in a scratch export); re-checked 2026-10-30 on HEAD b7b7693c: still applies clean, and `effects_check` passes with it and with the aura3d re-cut stacked on it. Waiting on the EP's grant for Rendering's `render/core/warmup.gd` (below) and on Performance's re-run of the cold repro on the old-laptop path. Apply it **before** `docs/vfx/pending/aura3d/` (that park's `warmup.gd` hunk and its `WarmBody` node sit on this one).

## What was wrong

The warm-up drew every shader once, but in its own 64 pixel SubViewport. The driver sets a pipeline up per viewport, so the pane's own first use of a mesh, material and instance format still hitched. Its quads also sat half a unit apart along x, mostly outside the camera frustum, where nothing is drawn. Tried and found useless: MultiMesh copies in the warm viewport (w1), a frustum grid there (w2), synthetic damage events at boot (w3).

## What it does

For the warm-up's three frames, behind the flashing-effects notice, in the REAL pane at the fighter's height:
- a copy of every `MultiMeshInstance3D` the views built (same mesh, instance format, buffer size and `material_override`; one instance at alpha 0), found by walking the pane;
- `VfxWarm.nodes()` (new, `render/vfx/warm.gd`): a real crack mesh (float CUSTOM0, the crack material) and the beam's three prisms (16 sides, 24 rings, `VfxBeamLook` material at strength 0);
- then they are freed. Nothing is visible (alpha 0 / strength 0); no flash, no sim read beyond the fighter's y.

## Measured (Performance's cold repro: `frame-bench --scene ai --reduced --ticks 400`, web export)

| Build | Hitches | Worst frame |
| :--- | :--- | :--- |
| HEAD | 131 (about 93 ms), 238 (about 163 ms); on some runs also 71, 74 | 163 ms |
| This park, reduced, two runs | none | 35 to 45 ms |
| This park, full mode | none | 35 ms |

Only on that repro: native Godot cannot show these hitches (the driver cost is the web build's), so the claim is the web build's, on this machine, not a general one. Please have Performance re-run it on the old-laptop path.

## Checks

`effects_check` passes with two new lines (`_warm_check`: the crack mesh and the three prisms are cut as the views cut them); validate 0 errors; depth, after, pane, flash, cue and flash_reg checks pass; with the aura park applied after it all of those still pass.

## NEEDS FROM EP

Rendering's file `render/core/warmup.gd`: `_process` is replaced (about 45 lines: `_real`, `real_nodes`, `_real_nodes`). Nothing else of anyone's.
