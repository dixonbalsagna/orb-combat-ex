# Park (GW1c): the snow and the rock line by the size's relief (Rendering, 2026-11-22)

Art's ruling (`docs/art/relief-cap-ruling.md`, follow-up of 2026-11-22), as the EP briefed it: the snow line is 0.997 of each size's tallest capped peak (medium's own share, 6,720 of 6,739). The other altitude lines use the same factor. The values come from World's number, set per match, with medium unchanged.

**It stacks on World's `relief-cap-gw1c/relief-cap.diff`** (the re-cut of 19:41, knee 0.7), which adds `WorldPlanetSize.linesScaleFor` and `tallestCapped`. It does not touch the tile files, so it is independent of `planet-sizes` and `drawn-at`. **With the cap's data row off (as on main), every size draws as it does now, bit for bit.**

## The file

| File | What |
|---|---|
| `relief_snow.diff` (3c762331, 56 lines) | `render/core/planet_view.gd` and `render/shaders/terrain.gdshaderinc`. Cut on main 74c03fdb (the code is the same at c2154c69) plus World's stage 2 with the re-cut `relief-cap.diff` (sha256 3b2b17d7). |

## What it does

- `PlanetView._set_lines(S)`, called from `_bs_setup` on every match:
  - `lines_s` = `WorldPlanetSize.linesScaleFor(P)` for the match's planet. That is the planet's tallest capped peak over 6,739, and 1.0 where nothing is capped: medium, big, huge, and every size while the data row is off.
  - It sets `snow_from` = `SNOW_FROM` × `lines_s` and `snow_full` = `SNOW_FULL` × `lines_s` on the ground material. `SNOW_FROM` is 6,720, medium's 0.997 of 6,739, so the snow starts at 0.997 of the planet's own peak. No 0.997 is written anywhere.
  - It also sets `lines_s` on the same material.
- `terrain.gdshaderinc`: the rocky biomes' rock line (biome_look `ROCK_ABOVE`: mountains 900, highland 700) is multiplied by `lines_s`.
  - This is Art's "pale rock … scale by the same factor", and it is the only other altitude line Rendering draws. World scales the biome lines and the tree line.
  - On tiny, without the scale, mountain ground from 808 to 1,800 gets less rock on gentle slopes than any mountain on medium, where every mountain stands above 1,800.
- The ground material is made once, so the values are set per match, like `tile_l0`.
  - The strip ground and the far shader use this material; changing the shader keeps its values.
  - The tile ground copies it when its tiles are made, and every 30 frames after.
  - A second pane sets its own.

## Findings

1. **The plumbing.** I ran `lines_probe`, a scratch probe: five matches in one run (tiny, small, medium, small, big), with the tile ground on and off. Both materials hold the size's values from frame 1:
   - with the data row: tiny 1,696.45, small 3,347.24;
   - medium and big: 6,720.0 exactly;
   - with the data row off: 6,720.0 and `lines_s` 1.0 at every size.

   Record: `docs/rendering/runs/74c03fdb/relief-snow.txt`.
2. **Tiny shows no snow; small shows about as little as medium.** Scratch `snow_where` read every node of World's lattice, which is the ground the tiles draw. On tiny and small the tiles draw the lattice's triangles, so no drawn point stands higher than a node.

   | Size | Snow line | Drawn top (highest node) | Nodes over the line | Share of land |
   |---|---|---|---|---|
   | medium | 6,720 | 7,202 | 66 | 0.018% |
   | small | 3,347.2 | 3,383 | 20, all at one summit | 0.016% |
   | tiny | 1,696.5 | 1,674 | 0 | 0 |

   - `tallestCapped` reads the climate grid's highest cell (tiny 1,701.3, small 3,356.7). The drawn ground is the field with its surface detail, and the gap does not scale with the size: medium's detail lifts its top 463 over 6,739, while tiny's drawn top is 27 under World's figure.
   - If the peak were measured on the drawn ground instead (medium's line as 6,720 of 7,202), tiny would get 81 nodes (0.24% of land) and small 290 (0.23%). That is 13 times medium's snow.
   - So as built, small matches medium's rarity and tiny has none. Whether tiny should whiten is Art's call. If it should, the number to change is World's peak measure, or the rule could become a share of land; this park only reads World's number.
3. **Where small's snow stands:** the one summit (3,383) is at line x 37,939, about 2,031 in front of the line, between the line and the camera. Tiny's highest summit (1,674) is at x 21,736, 1,484 behind the line.

## Gates (`docs/rendering/runs/74c03fdb/relief-snow.txt`)

The tree: stage 2 + `planet-sizes` + `drawn-at` + this park, with the cap's data row off, as it would land.
- Import: 0 errors (also 0 with the data row).
- Golden: byte-identical to stage 2 alone. The record's first "DIFFERS" compared against a stale file and is corrected under it.
- The five ground checks pass, and so does `drawn_check`.
- The render gates: 20 of 20.

## The posed stills (b), cap on, knee 0.7: before and after

These are in `docs/rendering/img/sizes/gw1c/` (git-ignored: they show fighters), as `gw1c3-pose-<size>-<pose>-before-after.png`: tiny b-summit, small b-snow, small b-snow-high and small b-range. My reading is in `docs/rendering/runs/74c03fdb/gw1c-relief-stills.txt`.
- Tiny: the face of the summit reads more evenly pale (the rock line), and there is no snow (finding 2).
- Small: the snow summit is in front of the line, so the default foreground tone paints it flat grey. **On planet 7, no snow shows in the fight view on either small size.** On medium the snowy summit stands 6,031 behind the line, as a far peak.

## Flash (EP only; `docs/rendering/runs/74c03fdb/relief-snow-flash.txt`)

Collapse in both modes, read by Tools' `run-pixels` with the tile ground on (`tiles=1`), on builds before and after this park.

| | Cap on: before | Cap on: after | Cap off (control) |
|---|---|---|---|
| small, normal | PASS 2 | PASS 2 | not run |
| small, reduced | FAIL 4 (worst at tick 348) | FAIL 4 | FAIL 7 (worst at tick 991) |
| tiny, normal | FAIL 6 (worst at tick 759) | FAIL 6 | FAIL 3.5 |
| tiny, reduced | FAIL 8 (worst at tick 745) | FAIL 8 | PASS 2.5 |

- **This park changes no primary count.** On tiny, the area-15% reading is 1 to 1.5 higher in the after and the 2 s memory reading 0.5 lower. That is one run each, so I can't separate it from run-to-run variation.
- **Small's default (reduced) look fails collapse with or without the cap** (4 with it, 7 without), and small is in GW1c's menu.
- The cap moves the counts both ways (small better, tiny worse), so they follow the ground the scene plays over, not one layer. Main's medium reads 4 in reduced (calm-tones; arm A takes it to 3).
- I have not attributed small's or tiny's failures. That would be a full-clip event list per size, then switching layers off one at a time.

## NEEDS FROM EP

- The order: after World's `relief-cap.diff` (it calls `linesScaleFor`). The look change comes with World's data row; until then nothing changes.
- Art: finding 2 (no snow on tiny, by the figure World's number gives).

## RISKS

- `_set_lines` runs once a match (World caches the peak on the planet). Medium returns from `linesScaleFor` on its first test.
- A world without a frame (the hand-made strip) keeps 1.0.
