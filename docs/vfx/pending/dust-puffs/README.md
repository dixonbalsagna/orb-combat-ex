# Parked: no grey blobs at landings (VFX, 2026-10-19, on HEAD 24dff419)

Orb: the "blur effects" and grey shapes beside the fighters. A native probe at tick 1739 (AI match, seed 4, Reduce flashing) showed three PUFF bits of 74 to 83 units at z -2, 1 s old, 20 to 60 units above the fighters: the smoke of the small blasts' explosion at a point-blank landing (explode.gd `at`, surface "fighter", via reach.gd `_land`, and its later `xwave` jobs), static grey scalloped puffs behind the fighters.

## Apply
`git apply docs/vfx/pending/dust-puffs/apply.patch` (checked with `git apply --check` on a clean HEAD export in scratch). Three files, all VFX's:
- render/vfx/explode.gd: `fighter_smoke(S, x, y)`: no smoke in the air (above 1.5 body heights) or in a beam struggle; on a body: one puff (was 2 to 9), half the size, standing 44 to 70 units clear of him; the later waves' smoke off for a body
- render/vfx/beamplay.gd: the landing dust (beam_arrive) only from a fighter near the ground (under 1.2 body heights) and not in a struggle; 2 or 3 puffs (was 4 or 7), 18 to 40 units over 0.5 to 0.8 s (was 30 to 66 over 0.7 to 1.2 s)
- render/vfx/tools/effects_check.gd: one check changed (one puff on the ground), three new

## Checks (scratch build of HEAD + patch)
effects_check, depth_check, flash_reg_check, after_check, pane_check, flash_check, cue_check pass; validate 0 errors. Side by side against d3f1ca0e at ticks 1672, 1700 and 1739 (homework/dust-puffs/, private).

## Honest limits
The cosmetic random stream (debris `_rd`, presentation only, never the sim) draws fewer numbers, so later flames and sparks in a match fall a little differently: not a defect, but a before and after of the same tick will not match in the flame shapes. The rest of the dust (earth.gd contacts, collapse debris, the tremor) is untouched. Flash readings not re-run; not a Legal clearance.
