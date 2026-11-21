# Park: ghost-tally-parts (VFX, 2026-11-21; GW1b, Rendering's find)

During a hitstop the fx view ages its particles by dt x 0.1 while VFX's ghost tally held its own countdown still, so on a freeze's last frames the tally counted an after-image that was no longer drawn (seed 8, tick 119: 1 drawn, the tally reads 2). Safe for Legal's m12, but it broke after_check's equality row.

**The fix (VFX's):** the tally reads Rendering's after-images from the reference fx view's own particle list (the list ParticleView draws): the parts of type "after" with age under min(life, AFTER_LIFE), in the list's order, so it is exact by construction. Files: `render/vfx/ghost_tally.gd` (`fx_src`; with none the old countdown stays, so tools without a host are unchanged), `render/vfx/vfx_hub.gd` (`fx_view`, passed to the tally each tick), `render/vfx/tools/effects_check.gd` (four rows: read from the drawn list, through a six-tick freeze, the tally's count is the view's, no host means the old way).

**The grant (Rendering's, one line):** `grant-rendering-fxview.patch` sets `vfx.fx_view = fxv` in `render/core/sim_host.gd` (after `fxv.reset(seed)`). Without it the hub has no view and nothing changes. Apply both; either order.

**Apply:** `git apply docs/vfx/pending/ghost-tally-parts/apply.patch` (sha1 4d208b611db6f5b78e64a13ada9b4ac9a4fab9bc) and `grant-rendering-fxview.patch` (sha1 1a6fa5ac4ab72ddb339114e62d7c532fa61c24d1), both clean on main ed1591cb.

**Checks** (docs/vfx/runs/ed1591cb/ghost-tally-parts.txt), on main + GW1b steps 1 to 6: after_check seed 8 failed before ("3 differ, first at seed 8, tick 119, fighter 1: 1 drawn, the tally reads 2") and passes after, with the default seed too; effects_check 1,173 ok, 0 failing; hash_check seeds 12345, 4 and 7 to tick 3,600, six ways, passes (hash_check has no host, so it still counts down).

**The picture:** nothing changes on screen. Only VFX's count of what Rendering draws changes, and it now equals it; the budget it hands VFX's own ghosts can differ by one on a freeze's last frames, which is the count catching up with what is drawn.
