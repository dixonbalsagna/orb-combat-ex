# L1 with D1: the window's patch (rebased on HEAD b6a7e47, 2026-10-05)

Apply from the repo root, in this order:

```
patch -p1 < docs/world/scratch-build/d1/d1_window.diff          # state.gd, hash.gd, fx.gd, replay.gd, terrain.gd, settlements.gd, structures.gd, brunt.gd, probe.gd
cp docs/world/scratch-build/d1/lanes.json docs/world/scratch-build/d1/settlements.json data/biomes/
cp docs/world/scratch-build/d1/lanes.gd sim/world/lanes.gd
godot --headless --path . --script res://sim/core/tools/golden.gd
```

(`d1_window.py` and `l1d1.diff` are the same change as scripts, for a clean export.) The settlements data has `"enabled": true`; with `false` the old layout and brunt candidates are untouched (the light per-tick digests equal HEAD's).

What is in it: the lane layout and D1 generator wired into `genWorld`; the new Building fields `district`, `shape`, `landmark` (hashed; Simulation's `state.gd` and `hash.gd` lines are granted by the plan), `building_fall.landmark`; `WorldSettle.dataHash()` into the replay's data hash (one `replay.gd` line); the brunt candidates in rows 1 and 2 only when D1 is on; `S.lanes` (derived, not hashed) built by `WorldLanes.build`; the probe's heap-step check on the heap's own step.

Tools' schema work (the validator rejects the data until it lands; Tools' paths, not mine): `settlements.json` gains `enabled` (boolean), `looks` (the list of look names, every district's look in it), and each district swaps `depth_aspect` for `depth_fill` ([lo, hi], 0.1 to 1) and may carry `traffic` (number, 0 or more); `lanes.json` is new (`z_front`, `z_back`, `lanes` [name, kind street|block|scenery|ridge, top, bottom, row], `strips` [lane, kind sidewalk|kerb|carriageway, top, bottom], `d_min_bh`, optional `body` {rx_bh, ry_bh, rz_bh}); cross-checks: strip lanes exist and tile their street exactly, lane rows 0 to 3 appear once, every district look is in `looks`.

**Rebase notes (2026-10-05, HEAD b6a7e47).** `d1_window.diff` was regenerated from a fresh export of HEAD with `l1d1.diff`, the data files, `lanes.gd` and `d1_window.py` applied, and dry-runs clean on a fresh HEAD export; `d1_window.py` and `l1d1.diff` are the same change as scripts. Two changes since the first version: (1) the building hash list now ends `"floors", "fmask", "wear"` (the shots window), so the script's anchor and its replacement carry `"wear"`; (2) **`building_fall.landmark` is a bool**, not a float: Game Design's `mood.gd` already reads `e.get("landmark") == true` (a float there is a script error in every golden match), so `FxEvent.landmark` is `bool`, `SimFx.buildingFall` takes `landmark: bool` and `structures.gd` passes `b.landmark > 0`; the building's `landmark` stays the 1-based index. On a scratch copy of HEAD with it applied: `probe.gd`, `lane_check.gd`, `stagecheck.gd`, `blockcheck.gd`, `directcheck.gd`, `minecheck.gd` 0 failed, the golden regenerates without a script error and `npm test --prefix sim` passes 5 of 5. L3 (`l3.diff`, `l3_patch.py`) applies on top with offsets only and `probe_collide.gd` passes; `npm test` passes 5 of 5 with both. `l3.diff.new` is the same patch re-diffed against the rebased tree.
