# Park (GW1c): the relief cap of the small planet sizes (World, 2026-11-20; Art's ruling: 0.3 of the radius on tiny and small; re-cut after the stand-in's review, RC-01 to RC-06)

**The keys ship OFF.** The code patch changes nothing a player sees; the data row that turns the cap on is separate and waits for Rendering's stills of tiny and small in the default look, Art's word on the flat tops and the crease at the knee, and a side-by-side. Records: `docs/world/runs/relief-cap/`.

## Files, and what each stacks on (RC-05)

**The tree these were cut and run on** (World's scratch `s26`): main `6bb03b08` + `globe-step2` (with `grant-simulation-field` and `grant-tools-lint`), `a-world-01` (+ `grant-simulation-sim`), `planet-sizes` (+ `grant-simulation-sizes`), `gw1c-world` (+ `gw1c-world-fix`), and Rendering's `grant-world-field-size-key.patch`. That is the sizes stack on **main**. **It does not apply on the GW1a tree** (`globe-step2`, `planet-sizes` and the `gw1c-world-fix` need re-cutting after GW1a and GW1b: GW1c readiness C-07): this park is re-cut with the rest of the planet stack then, and its records are named for the tree above.

| File | What |
| :--- | :--- |
| `relief-cap.diff` | the code: `sim/world/size.gd` (`reliefCap`, `reliefClamp`, `reliefKey`, loader rules), `sim/world/planet.gd` (`surfAt` applies the cap where the ground is made, so the biome reads the capped height; the gen 2 fast path of `readColumns` sets its height itself and is capped too; a column's detail is clamped under the cap; the gen 1 mountain line and the ice dome's rock line are scaled; `dataHash` carries the cap's numbers), `sim/world/climate.gd` (the altitude lines and the lapse scaled, below), `sim/world/field.gd` (`_read` clamps after the detail), `sim/world/tools/relief_cap_check.gd` (new, verdict `RELIEFCAP`). No data and no Tools file. Strict-applies on the tree above |
| `relief-cap-data.diff` | **the GW1c row that flips it on**: `sizes.json` `maxReliefShare` 0.3 and `reliefKnee` 0.6 on tiny and small, `reliefRef` 11,000 and `reliefTop` 6,739. Needs the grant below first (the schema is closed). Strict-applies after it |
| `grant-tools-relief-cap.patch` | **Tools' files** (RC-06): `tools/schemas/biomes-sizes.schema.json` (`maxReliefShare`, `reliefKnee`, `reliefRef`) and `tools/world-checks.json` (the `relief_cap_check` line, after `struggle_meet_check`). Lands before the data row |

Order: sizes stack, `relief-cap.diff`, the grant, `relief-cap-data.diff` (the last when the stills are read).

## The finding behind it

The relief is the same absolute height at every size (tallest 6,739 on planet 7; p99 3,025), so on a small ball it is a share of the radius no planet can carry: tiny's tallest was **1.04 R**, small's 0.54 R, medium 0.28, big 0.14, huge 0.07 (`runs/relief-cap/relief-by-size.planet7.txt`). Rendering's small opening sat inside a 6,256-unit ridge. Only buildings were capped (`maxBuildingShare`).

## What the code does

Heights up to the knee (0.6 of the cap: 1,174 on tiny, 2,347 on small) are their own; from the knee to `reliefRef` (the tallest the relief makes: planet 3 reaches 10,344, planet 11 9,430, so 11,000) they are scaled in proportion into the knee-to-cap band, and above that the cap. Monotone and in proportion: no plateau (`RELIEFCAP` counts the columns held flat at the cap: 0). The relief above the knee is flatter by a factor (tiny 0.08, small 0.18): planet 7's tallest peak is about 1,600 on tiny and 3,200 on small. The slope changes at the knee (a crease): Art reads it in the stills. Medium, big and huge, and every size while the keys are off: `reliefCap` returns its argument, bit for bit.

Where it is applied: `surfAt` (the planet's height; the tiles and the ring read it); the gen 2 fast path of `readColumns` (RC-04: it sets the height from its own copy of the ground arithmetic and never passed through `surfAt`; without the cap there the tops sat flat at the clamp: the new row counts those columns); and a clamp after the surface detail the field and the columns add, so no point is over the cap by the detail's few units.

**The saved-planet caches** (RC-03): `WorldPlanet.dataHash` (which keys the field cache, the replay's data hash and the laid-places memo) ends with `WorldPlanetSize.reliefKey()`: **"" where there is no cap** (the key is then exactly what it was) and the cap, knee and ref where there is one. A row changes the knee and expects another key.

## The altitude lines (RC-02, Art's ruling `docs/art/relief-cap-ruling.md`)

**The biome is read from the CAPPED height, and each altitude line on tiny and small is medium's scaled by (the size's cap in units) / 6,739** (`reliefTop`, the tallest relief on medium): `WorldPlanetSize.linesScale()` is 0.290 on tiny and 0.580 on small, and 1.0 where there is no cap (medium, big, huge, and every size while the keys are off: the lines are exactly what they are). Scaled: the mountain line (3,200 on medium; 4,200 with Research's B plates, which are off), the highland line (3,000 and the B plates'), the volcanic floor, the ice dome's rock line and the gen 1 mountain line (all in `climate.gd` and `planet.gd`), and **the temperature's lapse with height**, which is what sets the snow and the tree line (a fall of 1.1232 over the cap on both sizes, as over medium's tallest relief). Not scaled: the beach and the wetland lines, which are near the sea and under the knee (the capped height is the height there). So the mountain line is 0.475 of the cap and the highland line 0.341 on both sizes, the same as on medium of its tallest relief, and the tallest ground of a small planet reaches the snow line. The land type stays whatever the capped height and its scaled lines give; I did not need the uncapped height for it. My first build read the biome from the uncapped height with unmoved lines: that is withdrawn.

One consequence Art should see in the stills: the lines sit lower in absolute height on a small planet (tiny's mountain biome begins at 929 units, under the knee at 1,174), so a larger part of a small planet's land is highland and mountain than on medium.

## Gates (the tree above; each record in `docs/world/runs/relief-cap/`)

| Gate | Result |
| :--- | :--- |
| `RELIEFCAP` (keys turned on in memory, so it tests the code whether or not the data row has landed) | 0 failed: no point of 20,000 on tiny (tallest 1,619 of 1,956) or small (3,204 of 3,911) is over 0.3 R, in the surface or in the field with its detail; the cap acts (without it 6,769 and 7,087); no column of a gen 2 ring match with B plates, a gen 2 match on the fast path (no B plates) or a gen 3 match is over the cap or held flat at it; the mountain and highland lines are the same share of the cap as on medium (0.475 and 0.341 on both sizes), the 100 tallest points of each are mountain biome, and the temperature falls over the cap as it does over medium's tallest relief; the 100 tallest keep their taper; medium, big and huge bit for bit; the squeeze is monotone; the data key follows the cap and is exactly what it was on medium |
| `--negative-control` (cap off) | 13 FAIL |
| the biome controls inside it | **the old lines** (the cap on, medium's lines unscaled): 0 of tiny's 100 tallest points are mountain biome, so the mountain row can fail; **the old reading** (medium's lines on the uncapped height) puts the mountain line at 0.682 of the cap on tiny and 0.639 on small, not one share (ruled 0.475 on both), so the share row can fail |
| the same without my fast-path line | 2 FAIL (the gen 2 fast-path rows at tiny and small: 288 and 66 columns held at the cap) |
| `SIZES`, with and without the data row | 0 failed |
| `validate` with the grant and the data row | 0 errors |

## NEEDS FROM EP

- **Tools**: `grant-tools-relief-cap.patch` and the cases: `maxReliefShare` valid 0.3 and 1, invalid 0, 1.5 and "0.3"; `reliefKnee` valid 0.6, invalid 0, 1; `reliefRef` valid 11000, invalid 999 and "x"; `reliefTop` valid 6739, invalid 999 and "x".
- **Rendering and Art**: the stills of tiny and small in the default look, a side-by-side, and Art's word on the flat tops and the crease (the biome reading is Art's ruling, built); then `relief-cap-data.diff` is the flip.
- **Re-cut** with the planet stack after GW1a and GW1b (this tree is main's).

## RISKS

- `surfAt` is hot (every node and bake read): one extra call and compare per read, not timed (shared machine); medium returns on the first test.
- With the keys on, **tiny and small change**: the heights, so the ring, lakes, places and the hash. Medium (Orb's build) does not.
- The river drainage reads the uncapped climate grid (monotone, so the drainage is the same); river levels read the field's capped ground. A river that rises into squeezed hills sits lower than its uncapped bed would: not checked on the pool; watch it in the stills.
- Rendering's tile bake reads `surfAt` and adds no detail, so its heights are under the cap by construction; the field's are clamped to it. The two differ by the detail (a few units) as they did before.
