# Standing on deep water (Animation, 2026-10-30)

Owner: Animation. The EP's brief (Orb's push for the new planet): with World's floor on (`docs/world/lake-floor.md`), fighters on the surface of deep water (lake 120 and 600 deep) dropped their guard stance and took a different idle than at 20 and 60 deep. Fix it on Animation's lines.

## The cause

Not a swimming read: the render has none. Twelve places in `render/anim` ask how high the fighter is above the ground with `f.y - WorldTerrain.groundY(S, f.x, f.z)`. With the floor on, a fighter in water 75 deep or more stands on the sheet, so that number is the water's whole depth: 120 or 600, far past the airborne thresholds.

| read | threshold | what it did at 120 deep |
| :--- | :--- | :--- |
| the stance variants (`_air_w`, `stance.air`), `anim_fighter.gd` 2773 | 30 to 70 | full weight: the airborne idle instead of the ground stance, the hover bob on top |
| the ground locomotion's `grounded` (`_ground_layer`), 904 | under 6 | false: no walk, skid or stop on the water |
| the hover's breathing (`hv`), 724 | 4 to 16 | on |
| the taunt gates (`open` on the ground or in the air), 1489, 1491, 2921, 2923, and the close-air taunt, 1582 | 8 and 20 | the air taunts |
| the air-recovery's `min_air`, 851 | 40 | armed |
| the depth step, 2271 | 8 | off |
| the brace time of a falling body, 4525 | | counted from the bed |
| `RenderAnim` far-taunt moment `air`, `render_anim.gd` 537 | 20 | true |

At 20 deep the floor is the bed (37.5 and under) and at 60 it is 45 above it, which is why those held the stance (60 held it only part-way: `_air_w` 0.35 and 0.60 in the probe before the fix).

## The fix

Those twelve reads ask `WorldWater.floorAt(S, x, z)` instead: the level a fighter under his own control stands on. With the floor off it returns `groundY` to the bit (`floorAt` returns `g` when `WorldFill.floorOn()` is false), so nothing moves when the switch is off. The foot-on-slope solve (`_ground_feet`, 4639 on) keeps reading the bed: the surface is flat, and the stand test there (`abs(f.y - bed) < 8`) leaves the water alone as before.

A launched or dropped body is not on the floor (`SimFighter.floorFor` leaves it out), but the render's reads there only ask whether he is high in the air, and above the sheet he is. Under the sheet the number is negative and every ramp clamps to 0.

## Proof

- `anim_check` `_test_water_stance`: a match with nobody fighting, the pair set down on the ring's own water at the columns nearest 20, 60, 120 and 600 deep (the hand-made world's seed 7: 20, 60, 120 and 598), 60 ticks each, with the floor on and off. Neither is airborne (`_air_w` 0), both read `grounded`. Run against HEAD's render code the same test fails: `_air_w` 0.35 and 0.60 at 60 deep, 1.00 at 120 and 598, `grounded` false from 60 down.
- Floor off is byte-identical: `tick_bench` hashes of every drawn pose of the seeded AI matches are 100828914217182 (seed 4) and 136166552210321 (seed 11, 415 launched samples), the same as before the change (`tick-cost.md`).
- `anim_check` passes (9873 checks, the new test last in the run), `joint_scan --strict` and determinism (plain and `--intro`) pass.
- The look gate: `img/water-stance/d20`, `d60`, `d120`, `d600` (`-t00090.png` and `.gif`): Rendering's pb scene on gen 2 planet 7, coast, the pair set down on the lake column nearest each depth with the floor on (`docs/rendering/tools/lake-hook.mjs --floor`), HEAD before (left, blue bar) and with the fix (right, orange), tick 90. At 120 and 600 deep the pair goes from the airborne idle to the guard stance; at 60 the feet no longer lift; at 20 the two are the same.
- The collapse clip (`collapse`, seed 12345, 1500 ticks, headless Chrome through `tools/flash/capture-web.mjs`) in both modes on the fixed build: reduced PASS (2.5 general, 3 at the area threshold 15% lower); normal FAIL at 3.5. HEAD without this change, captured the same way, gives the same normal reading (3.5 general, 3.5 area, 0 red, 0 of 7 margin): the failure is not this change's, and with the floor off the render is byte-identical.

## Not here

- Where the fighter is drawn on the water (the root offset, a wake, splashes) is Rendering's and VFX's. Standing on the sheet now uses the ground stance and the ground locomotion; a walk on the water is the ground walk.
- The fighters' own idle in the water at 37.5 to 75 deep (the floor rising out of the water) uses the same stance as any other; nothing is added for wading.
