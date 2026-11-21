# GW1b pins: the water-stance row holds the hand-made arena too (Animation, 2026-11-21, parked)

GW1a landed (b0e20f9a) with the gw1a-pins in; that folder is cleared. For GW1b: World's stage-1 stack (`docs/world/planet-stack-recut.md`: a-world-01 with its flip, the floor rise, lake-places, water-everywhere) plays planet 7 for a match that names no planet, so one pin of mine stops being enough.

## What failed, and the one-row fix

On World's stage-1 copy with my parks (step-up, its schema and Tools' cases, water-tile-check) `anim_check` ran 10,557 checks and **one failed**: `standing on the water` (`_test_water_stance`). Its pin ran the row on the strip ground (`RenderTileGround.on = false`), but after the flip a match with no planet is planet 7 whatever the ground, and a planet slice's `S.water` is all zero, so the row again found no water. The fix is the same pin holding the hand-made arena too (`WorldDefault.setForTest("arena", false)`, the setter World's `WorldPin.arena()` uses) and giving the mode back after.

`gw1b-pins.patch` (sha1 aed02606): `render/anim/tools/anim_check.gd` only, 2 hunks: `_pin_strip_ground` and its restore now hold and return `[RenderTileGround.on, WorldDefault.mode(), WorldDefault.K_RANDOM]`, plus the pin's comment. It applies as text on main's file (ed1591cb) and on World's stage-1 tree; **it needs `WorldDefault`, which World's a-world-01 park adds, so it lands with or after it** (on main today the class does not exist). No data, schema or sim file.

## Result (World's stage-1 tree + my parks; `records/`)

| | before the pin | with it |
| :--- | :--- | :--- |
| `anim_check` | 10,557 checks, 1 failed (standing on the water) | **10,557 checks, 0 failed**, including `_test_step_up` (crouch 5.4 over 12 ticks, both fighters) and `_test_water_stance_globe` (deep sea, lake and wade grounded, 0.0 off the floor) |
| `water_tile_check --strict` | passed: sea 51 (0.0), dry 149 (1.8), wade 23, lake 17 of 17 at 0.0; shore rows: the same 4 shores (456.2, 795.6, 246.2, 424.2) | (not affected) |
| validate | 0 errors, 2 warnings (323 files) | |
| self-test | 10,135 of 10,136, 1 failed: `coverage: biomes-world.schema.json: at least three invalid cases` | **not mine**: World's own tree fails the same row (10,122 of 10,123); the schema is a-world-01's |
| two-fighter ratchet | 365 against 365 | |

Also checked on that tree: step-up.patch, step-up-schema.patch, Tools' step-up-cases.patch and water-tile-check.patch all apply as is (the last one, re-cut today, no longer carries `docs/animation/water-tile-check.md`: main tracks it).

## For the landing (steps 16 and 18 of the GW1b review)

- Step 18 (step-up) still applies on main and on stage 1 untouched; B-08's retake is done and passed (docs/animation/runs/dbe17b79/step-up-globe/README.md; the pictures are git-ignored).
- Order: `gw1b-pins.patch` with or after a-world-01.
