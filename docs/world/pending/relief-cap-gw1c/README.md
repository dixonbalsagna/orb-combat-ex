# Park (GW1c): the relief cap of the small planet sizes (World, 2026-11-20; Art's ruling: 0.3 of the radius on tiny and small; re-cut after the stand-in's review, RC-01 to RC-06)

**Code and check-list line landed in GW1c (2026-11-25); those two patches are removed from this folder. Still parked: `relief-cap-data.diff` (the tiny and small height caps), which waits for small's un-hide.**

**The keys ship OFF.** The code patch changes nothing a player sees; the data row that turns the cap on is separate and waits for Rendering's stills of tiny and small in the default look, Art's word on the flat tops and the crease at the knee, and a side-by-side. Records: `docs/world/runs/relief-cap/`.

## Files, and what each stacks on (RC-05)

**The tree these were cut and run on** (World's scratch `s26`): main `6bb03b08` + `globe-step2` (with `grant-simulation-field` and `grant-tools-lint`), `a-world-01` (+ `grant-simulation-sim`), `planet-sizes` (+ `grant-simulation-sizes`), `gw1c-world` (+ `gw1c-world-fix`), and Rendering's `grant-world-field-size-key.patch`. That is the sizes stack on **main**. **It does not apply on the GW1a tree** (`globe-step2`, `planet-sizes` and the `gw1c-world-fix` need re-cutting after GW1a and GW1b: GW1c readiness C-07): this park is re-cut with the rest of the planet stack then, and its records are named for the tree above.

| File | What |
| :--- | :--- |
| `relief-cap.diff` | the code: `sim/world/size.gd` (`reliefCap`, `reliefClamp`, `reliefKey`, loader rules), `sim/world/planet.gd` (`surfAt` applies the cap where the ground is made, so the biome reads the capped height; the gen 2 fast path of `readColumns` sets its height itself and is capped too; a column's detail is clamped under the cap; the gen 1 mountain line and the ice dome's rock line are scaled; `dataHash` carries the cap's numbers), `sim/world/climate.gd` (the altitude lines and the lapse scaled, below), `sim/world/field.gd` (`_read` clamps after the detail), `sim/world/tools/relief_cap_check.gd` (new, verdict `RELIEFCAP`). No data and no Tools file. Strict-applies on the tree above |
| `relief-cap-data.diff` | **the GW1c row that flips it on**: `sizes.json` `maxReliefShare` 0.3 and `reliefKnee` **0.7** (Art, 2026-11-22) on tiny and small, `reliefRef` 11,000 and `reliefTop` 6,739. Needs the grant below first (the schema is closed). Strict-applies after it |
| `grant-tools-relief-cap.patch` | **Tools' files** (RC-06): `tools/schemas/biomes-sizes.schema.json` (`maxReliefShare`, `reliefKnee`, `reliefRef`) and `tools/world-checks.json` (the `relief_cap_check` line, after `struggle_meet_check`). Lands before the data row |

Order: sizes stack, `relief-cap.diff`, the grant, `relief-cap-data.diff` (the last when the stills are read).

## The finding behind it

The relief is the same absolute height at every size (tallest 6,739 on planet 7; p99 3,025), so on a small ball it is a share of the radius no planet can carry: tiny's tallest was **1.04 R**, small's 0.54 R, medium 0.28, big 0.14, huge 0.07 (`runs/relief-cap/relief-by-size.planet7.txt`). Rendering's small opening sat inside a 6,256-unit ridge. Only buildings were capped (`maxBuildingShare`).

## What the code does

Heights up to the knee (0.7 of the cap: 1,369 on tiny, 2,738 on small) are their own; from the knee to `reliefRef` (the tallest the relief makes: planet 3 reaches 10,344, planet 11 9,430, so 11,000) they are scaled in proportion into the knee-to-cap band, and above that the cap. Monotone and in proportion: no plateau (`RELIEFCAP` counts the columns held flat at the cap: 0). The relief above the knee is flatter by a factor (tiny 0.08, small 0.18): planet 7's tallest peak is about 1,600 on tiny and 3,200 on small. The slope changes at the knee (a crease): Art reads it in the stills. Medium, big and huge, and every size while the keys are off: `reliefCap` returns its argument, bit for bit.

Where it is applied: `surfAt` (the planet's height; the tiles and the ring read it); the gen 2 fast path of `readColumns` (RC-04: it sets the height from its own copy of the ground arithmetic and never passed through `surfAt`; without the cap there the tops sat flat at the clamp: the new row counts those columns); and a clamp after the surface detail the field and the columns add, so no point is over the cap by the detail's few units.

**The saved-planet caches** (RC-03): `WorldPlanet.dataHash` (which keys the field cache, the replay's data hash and the laid-places memo) ends with `WorldPlanetSize.reliefKey()`: **"" where there is no cap** (the key is then exactly what it was) and the cap, knee and ref where there is one. A row changes the knee and expects another key.

## The altitude lines (RC-02; Art's ruling and its follow-up of 2026-11-22, `docs/art/relief-cap-ruling.md`)

**The biome is read from the CAPPED height, and each altitude line on tiny and small is medium's scaled by the planet's own TALLEST CAPPED PEAK over 6,739** (`reliefTop`, the tallest relief on medium). The first build scaled by the cap over 6,739; the squeeze only approaches the cap, so the real tops sit under it (planet 7: 1,701 on tiny against a cap of 1,956, 3,357 on small against 3,911) and every cap-scaled line sat above the tops: no snow, pale rock or trees at the top. `WorldPlanetSize.linesScaleFor(P)` is the peak over 6,739 (0.2524 on tiny, 0.4981 on small for planet 7), and 1.0 where there is no cap (medium, big, huge, and every size while the keys are off: the lines are exactly what they are).

**The peak** is `WorldPlanetSize.tallestCapped(P)` (public, for Rendering: its snow line is 0.997 of it): the planet's tallest ground, the highest cell of its climate grid (the gen 2 planet's own relief; a gen 1 planet has no grid and takes `reliefTop`), put through the cap. It is a pure function of the planet, computed once and kept on the planet (`Planet.peak`, read again when the cap's numbers are), and the grid's highest cell is within 1 percent of the highest of 20,000 sampled points (1,701 against 1,698 on tiny, 3,357 against 3,356 on small).

Scaled: the mountain line (3,200 on medium; 4,200 with Research's B plates, which are off), the highland line (3,000 and the B plates'), the volcanic floor, the ice dome's rock line, the gen 1 mountain line, and **the temperature's lapse with height**, which sets the snow and the tree line. Not scaled: the beach and the wetland lines (near the sea, under the knee). So the mountain line is 0.475 of the peak and the highland line 0.341 on both sizes, as on medium of its tallest relief, and the highest peak is as cold as medium's tallest relief (a fall of 1.1232 over it on both sizes): it reaches the snow line where medium's does. The land type stays whatever the capped height and its scaled lines give.

Art should see in the stills that the lines sit lower in absolute height on a small planet (tiny's mountain line is 808 units, under the knee at 1,369), so a larger part of a small planet's land is highland and mountain than on medium.

## Gates (the tree above; each record in `docs/world/runs/relief-cap/`)

| Gate | Result |
| :--- | :--- |
| `RELIEFCAP` (keys turned on in memory, so it tests the code whether or not the data row has landed) | 0 failed: no point of 20,000 on tiny or small is over 0.3 R, in the surface or in the field with its detail; the cap acts (without it 6,769 and 7,087); no column of a gen 2 ring match with B plates, a gen 2 match on the fast path (no B plates) or a gen 3 match is over the cap or held flat at it; the lines scale by the planet's tallest capped peak over 6,739 (the peak under the cap and within 5% of the 20,000 points' highest), the mountain and highland lines are the same share of the peak as on medium (0.475 and 0.341) and under it, the 100 tallest points of each are mountain biome, and the tallest capped peak is as cold as medium's tallest relief (the snow and the tree line reach the top); the 100 tallest keep their taper; medium, big and huge bit for bit; the squeeze is monotone; the data key follows the cap and is exactly what it was on medium |
| `--negative-control` (cap off) | 11 FAIL |
| the biome controls inside it | **the old lines** (the cap on, medium's lines unscaled): 0 of tiny's 100 tallest points are mountain biome, so the mountain row can fail; **Art's first scale** (by the cap over 6,739): the highest peak is only 0.977 colder than sea level on tiny and 0.964 on small, against 1.123 for medium's tallest relief: no snow at the top, so the temperature row can fail |
| the same without my fast-path line | 2 FAIL (the gen 2 fast-path rows at tiny and small: 288 and 66 columns held at the cap) |
| `SIZES`, with and without the data row | 0 failed |
| `validate` with the grant and the data row | 0 errors |

## NEEDS FROM EP

- **Tools**: `grant-tools-relief-cap.patch` and the cases: `maxReliefShare` valid 0.3 and 1, invalid 0, 1.5 and "0.3"; `reliefKnee` valid 0.7, invalid 0, 1; `reliefRef` valid 11000, invalid 999 and "x"; `reliefTop` valid 6739, invalid 999 and "x".
- **Rendering and Art**: the stills of tiny and small in the default look, a side-by-side, and Art's word on the flat tops and the crease (the biome reading is Art's ruling, built); then `relief-cap-data.diff` is the flip.
- **Re-cut** with the planet stack after GW1a and GW1b (this tree is main's).

## RISKS

- `surfAt` is hot (every node and bake read): one extra call and compare per read, not timed (shared machine); medium returns on the first test.
- With the keys on, **tiny and small change**: the heights, so the ring, lakes, places and the hash. Medium (Orb's build) does not.
- The river drainage reads the uncapped climate grid (monotone, so the drainage is the same); river levels read the field's capped ground. A river that rises into squeezed hills sits lower than its uncapped bed would: not checked on the pool; watch it in the stills.
- Rendering's tile bake reads `surfAt` and adds no detail, so its heights are under the cap by construction; the field's are clamped to it. The two differ by the detail (a few units) as they did before.

**2026-11-23 (the hold, `../planet-sizes/README.md`):** tiny and small are held as shipped, so `relief_cap_check` sets `WorldPlanetSize.heldOverride = true` (one line in `relief-cap.diff`), and `relief-cap-data.diff`'s two rows carry `"offered": false`. Same order, strict.
