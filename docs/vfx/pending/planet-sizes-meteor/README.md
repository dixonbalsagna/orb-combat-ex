# Park: planet-sizes-meteor (VFX, 2026-11-14): World's grant, re-cut with the check

World's `docs/world/pending/planet-sizes/grant-rendering-meteor.patch` (the meteor line's radius from `SimField.R` instead of the compiled `R_PLANET`) is correct and approved for `render/vfx/meteor.gd`: `SimField.R` is a static var on main (`sim/core/field.gd:16`), and nothing else reads `R_PLANET`. One thing was missing: my own `render/vfx/tools/effects_check.gd` read `VfxMeteor.R_PLANET` (lines 6561 to 6563), so removing the constant would have stopped the check. This patch is World's hunk plus the check's three lines changed to `SimField.R`.

**Apply:** `git apply docs/vfx/pending/planet-sizes-meteor/apply.patch` against main (clean on main a0966bb0; sha1 9c9f808723d2a9c75b018171c8477abd3d8c4b8e). Two files. Lands in GW1c with the planet sizes.

**Checks** (on the GW1a stack, saved in `docs/vfx/runs/067baa03/planet-sizes-meteor-gates.txt`): `effects_check` 1,168 ok, 0 failing; `hash_check` seed 12345 to tick 3,600, six ways, passes (with the strip pin, see `hash-check-strip`). It also applies with `meteor-default` (disjoint hunks).
