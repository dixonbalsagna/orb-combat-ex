# Planet sizes: which five, and what it took (World, 2026-11-13; A1, Orb: "five different planet sizes")

Plan: `docs/world/planet-overhaul.md` section 4 (six sizes, tiny to colossal). Park: `docs/world/pending/planet-sizes/`. Check: `sim/world/tools/size_check.gd` (`SIZES`). Data: `data/biomes/sizes.json`. This changes the state's fingerprint for any match that names a size other than medium; **medium is byte for byte today's** (parity passes unchanged at 4,800).

## The five I propose

| | Tiny | Small | **Medium** | Big | Huge | (Colossal, off) |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| Columns round | 1,280 | 2,560 | **4,800** | 9,600 | 19,200 | 38,400 |
| Units round | 40,960 | 81,920 | **153,600** | 307,200 | 614,400 | 1,228,800 |
| Radius | 6,519 | 13,038 | **24,446** | 48,892 | 97,785 | 195,570 |
| Lap flat out at base (5,000 a second) | 8 s | 16 s | **31 s** | 61 s | 123 s | 246 s |
| Cities / towns laid | 2 / 4 | 4 / 12 | **12 / 44** | 24 / 88 | 48 / 176 | 96 / 352 |

**Tiny, small, medium, big, huge. Colossal stays a row of data that is off** (`offered: false`): it is unproven (the grid key in `SimField._boxKey` aliases past a radius of 131,000 units, and the sim has never held a quarter-million places), and the plan's own order put it last. Tiny and small are 1,280 and 2,560, not 1,200 and 2,400 as the plan said: a face edge is `cols / 16` nodes of 128 units, and the 512-unit bake needs that to be a multiple of 4, so a size is a multiple of 64 columns. The names still mean what they say (each about double the one before).

Why these: tiny is ADR 0013's weak-machine path and costs next to nothing; small and big are the two nearest medium; huge is the largest the shipped quality holds without the plan's windowed places, because places grow by the square root of the area, not the area (below). The sizes are in `sizes.json` as columns, so a different five is a data edit.

## What a size does

A size is a distance. `SimConst.PLANET_NC` is now a per-match setting (`SimConst.setPlanet`, set at the top of the match, bound again each tick like the arena's length, `S.planetNC`); `COL` is 32 units whatever the size, so every body, speed and launch stays as it is and a bigger planet is more ground. **On the field world the arena is the planet's whole great circle** (the frame maps the line to a closed great circle: an arena shorter than the planet has no frame), so a huge match's ring is 19,200 columns: four times medium's per-column state (672 KB against 168 KB). The plan's ring cap on big and huge needs a ring that is not a great circle, which the field world cannot hold; I did not build it. Netcode prices the snapshot (item 3 in the README's list).

What reads the size, all at call time: the six places that wrote the radius out (`SimField.R`, the store, the water records, collateral, contact, `WorldField`), `P.L`, the ring picker's whole test, the arena's bound, the loader's phase count; `WorldField.cells()` goes with the size so the nodes stay 128 units apart; the planet's memo key, the slice memo's key, the match-key hash's memo and the disk cache's key carry the size when it is not medium (medium's keys are as they were, so its cached planets stay good); the store's and the water records' grid keys take their offset from the radius (a 64 offset gives two boxes of the huge planet one key: `size_check` has the negative control). The place counts and the ring's minimums are per size in `sizes.json` (`places`): a planet function has absolute feature sizes (a continent is 30,000 units), so a smaller planet is a smaller continent and a bigger one has more of them, and the counts go with a size by the square root of the area (a tiny planet cannot fit twelve cities of 6,500 units radius).

## Measured (shared machine: every time here is void as a measurement; Performance reads them in a quiet window)

Planet 7, touch 1, cold, one AI match: start and 600 ticks tiny 1.9 s, small 0.9 s, medium 0.5 s (cache warm), big 3.4 s, huge 7.9 s. Planet make for big: 3.3 s, 112 places. Tick cost about 0.3 to 1.2 ms at every size on a loaded machine (medium 0.7 ms at the same load): it does not grow with the size. `SIZES` plays all five for 600 ticks, the same match twice, and checks medium named against medium unnamed.

## What is not built

- **The look at each size.** Rendering's tiles hard-code the medium planet (`render/core/tile_field.gd`: the face edge 38,400 and 300 cells at lines 371, 447, 456, 508 to 522, 624; `planet_view.gd` 570 to 575; `render/core/look.gd` far-city counts). The sim plays every size; the picture of big and huge, and tiny's relief against its radius (a 4,875 tower on a 6,519 radius), are Rendering's and Art's (listed in the README).
- **The menu's row and the replay header.** The setup key is `planetSize`; the replay already carries the whole setup, so a replay names its size. UI's menu row and Netcode's handshake line are theirs.
- **Colossal, the ring cap, windowed places, a places count by reachable window** (the plan's items 4 to 6): after Alpha.
- **Game Design's per-size tuning** of launches and the swing's read budget (the plan's step 6).
