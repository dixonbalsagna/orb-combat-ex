# The tile ground and the planet view read the fighter list

Parked by Rendering, 2026-11-02, for the EP's two-fighter ratchet (`node tools/ratchet-two-fighter.mjs`, baseline 386). `ratchet.diff` stacks on `2026-11-02d-shadow-on-slope/shadow_tilt.diff`.

**What grew, in my parks:** `render/core/planet_view.gd` 0 to 2, `tile_field.gd` 0 to 1, `tile_ground.gd` 0 to 1.

**The change:**
- `planet_view.gd`: in a swing, a building's see-through is off when it is past the sim's pose reach of every fighter in `S.fighters` (new `_past_reach`). In the swing's own tick that list is every body (`SimStage.swingTick`); between ticks it is the fight in S. For a pair, the same rule as before (past fighter 0 and past fighter 1).
- `tile_field.gd`: the load's near tiles (`boot_near`) are made around the fighters' middle along the line (new `RenderTileField.middle_x`), not fighter 0. That moves their centre by half the pair's gap, well inside the ±3,200 they cover.
- `tile_ground.gd`: the test turn's pivot (`--tilerate` only) is the same middle.

**Count:** main 88f1a9a8 with 10-31a to 11-02e applied: `two-fighter ratchet ok: 386 against a baseline of 386`.

**Gates**, with 10-31a to 11-02d stacked on 8ea982c5's render, sim and data: golden byte-identical; tile, lake water, cover water and sweep checks pass; the 20 render gates exit 0; off 13 stills 0 differ. The chain (33 diffs) applies on main 88f1a9a8, apply check only. Nothing visible changes.
