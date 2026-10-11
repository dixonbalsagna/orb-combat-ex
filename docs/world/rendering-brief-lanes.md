# Brief for Rendering: piece 2, the re-laid city's look (district looks, shapes, row fog, lane strips from `S.lanes`)

From World, 2026-10-11, after the lanes window. Read with `docs/world/arenas-status.md` and the stills in `docs/world/stills/` (review pictures of what the data is; not Rendering's look and not for a public page).

## What is in the sim now

- **The city is re-laid** (`data/biomes/settlements.json` `enabled` true): 169 buildings (houses 81, towers 88) in 11 districts of 4 settlements, west to east: a harbour and its village; **Bellgate** (suburb, industrial, mid-rise, downtown, mid-rise, suburb); a workshop village with a suburb; a hill village. Rows: 1 front block 65, 2 back block 65, 3 scenery 39. **Row 0 (the foreground) is empty on purpose** (`"foreground": false`): it stands between the camera and the fight until Camera frames it. The generator supports it; switching it on is one data flag and will add about 17 low buildings in front of the front street.
- **`S.lanes`** (derived, not hashed, rebuilt with the world): a flat `PackedFloat32Array`, world units, z positive toward the camera. Header of 13 floats: version, nLanes, nStrips, nDistricts, nAvenues, nRows, rowZ0, rowStep, zFront, zBack, offLanes, offStrips, offDistricts. Then lanes (4 each: zTop, zBottom, kind 0 street / 1 block / 2 scenery / 3 ridge, row), strips (4 each: lane, zTop, zBottom, kind 0 sidewalk / 1 kerb parking / 2 carriageway), districts (6 each: x0, x1, look index, lane mask, traffic, settlement), avenues (3 each: x0, x1, district). `RenderLanes.table(S)` returns it as soon as it is non-empty, so the stand-in (`RenderLanes.stub()`) can go; `strips()` and `districts()` already read this layout.
- **Lanes (units, z from the camera):** foreground 938 to 562 (row 0), **front street 375 to -300** (sidewalk 375 to 300, kerb 300 to 210, carriageway 210 to -135, kerb, sidewalk to -300), **block 1 -300 to -900** (row 1), **back street -900 to -1350** (sidewalk, carriageway -975 to -1275, sidewalk), **block 2 -1350 to -2025** (row 2), scenery -2550 to -3150 (row 3). The fighters' band is 375 to -2025 (`zFront`, `zBack`).
- **Per building** (`S.buildings[i]`): `x`, `w`, `h` (full height), `z` (centre depth), `d`, `row`, `kind` (house or tower), **`shape`** (one of 20: shaft, stepped, spire, slab, block, warehouse, chimney, house, shop, hall, shed, crane, lighthouse, chapel, crown, terrace, sawtooth, thatch, quay, mast), **`district`** (index into the districts of `S.lanes`, west to east), **`landmark`** (1-based index into `settlements.json` `landmarks`: bell_tower 150 fighter heights, chimney_stack 45, lighthouse 40, village_hall 9, hill_chapel 14; 0 none), `floors`, `fmask`, `fdmg`, `hp`, `maxhp`, `wear`.
- **Looks** (the district's `look` index into `settlements.json` `looks`): harbour, village_harbour, suburb, industrial, mid_rise, downtown, village_workshop, village_hill. **Scale to design for:** downtown towers have a median of 62 fighter heights (4,650 units) up to 150 for the bell tower (11,250 units); mid-rise about 12 floors; suburb houses 3 to 6 fighter heights. A tower is up to 62 floors of 150 units.
- **Stages** are as before: `WorldStructures.stage(b)` (0 intact, 1 windows out, 2 a part gone or a damaged floor, 3 a shell, 4 rubble), `curH(b)`, `fmask`, the `building_stage` event; `building_fall` now carries `landmark` (bool).
- **Not in the sim yet:** cars, bikes, foot traffic, props (P1); `traffic` in the districts is data for them. Fighters stay on one plane (`depthOn` false) in the front street.

## What Rendering does (piece 2)

1. **Shapes.** Draw each building by `shape` from the 20 names (Art's concept shapes if drawn; a plain prism with the right silhouette until then), with width `w`, depth `d`, height `h` and the cut floors by `fmask`; the roof silhouette matters most (spire, stepped, crown, sawtooth, thatch). A landmark gets its own treatment (the index tells which).
2. **District looks.** One facade palette and window pattern per look (8), seen at the scale above; the district's `look` index is in the table and on the building (`district`).
3. **Row fog.** Atmospheric depth by row or by `z` (row 3 hazier than row 2 than row 1): it makes the depth read from the camera. Row 0, when switched on, must not hide the fight (Camera frames it).
4. **Lane strips from `S.lanes`.** Paint the strips (sidewalk, kerb parking, carriageway) from the real table (the ground shader already takes them), the avenues as gaps in the blocks, and the district edges. The stand-in goes.
5. **Stages in the new city.** The five stages on the new shapes (a 62-floor shaft, a stepped tower, a hall): reads exist; check them at the new heights.

## Acceptance

`render/tools/ground_check.gd`, `stage_check.gd`, `lane_check.gd` and render determinism (plain and `--intro`) stay green; the render never writes the sim and never changes the gameplay hash; stills of a downtown block and of a village are the review pictures; public pictures keep the rule: no towers falling or shedding glass, buildings break in stages.

## Open for Orb (the values are data and can change without a code change)

Downtown scale (62 fighter heights median), the band's depth (32), whether row 0 returns and how it is framed, how regular the layout is, traffic, and how the casualty count is shown (the starting population is now 1,800 against 390: shares are the same).
