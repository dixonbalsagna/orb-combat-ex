# Tile footings kept by the tiles they read

Parked by Rendering on 2026-11-07, from the EP's brief after planet-stalls. `tile_keys.diff` (sha1 703552ff, 182 lines) stacks on `planet-stalls/planet_stalls.diff`. It was cut against main 27aa456a + planet-stalls and applies on 85884449 + planet-stalls. It is render only: `render/core/tile_field.gd` and `render/core/planet_view.gd`.

## What it does

Planet-stalls kept a building's tile footing reads, and its figures' placement, until any tile anywhere was stored (`RenderTileField.version`). Tiles are stored all the time as the camera moves, so most kept reads were thrown away.

Now each read rests on the tiles it actually looked at:

- **`RenderTileField.key_ver`:** per tile key, the version that last stored that tile or let it go (`_store`: the new tile, and the one whose layer it took).
- **`height_keys(d, keys)`:** `height_at`'s read, same arithmetic. It also records the keys it looked at: finest level first, down to the level it found (all five if it found none).
- **`kept_since(keys, v)`:** whether reads made at version `v` still stand, meaning none of their tiles was stored or let go since.
- **The view:** `_footing` keeps each building's keys (`_ft_keys`), and `_set_crowd` keeps its figures' keys (`_cv_keys`). A kept read is used while `kept_since` says so.

**Exact:** `height_at`'s answer depends only on which of those keys are present and on the found tile's heights. Only `_store` changes either, and it bumps the keys it touches.

## Result

**Small in time, and honest about why.** Performance's recording method (perf-run on Orb's third play to tick 11,100, valid runs only):

- **The blow frame at tick 8033:** 13 to 16 ms with this park, against 12 to 17 with planet-stalls alone, so no measurable change. The figures' re-placements there went from 117 to 0 (0.1 to 0.3 ms). The footings still cost 3 to 5 ms.
- **Why the footings still cost:** a moved footing also asks the sim for the building's base (`WorldStructures.baseY`: the highest ground over its footprint, a loop over depth rows and columns, about 40 µs a building). That has to be asked again whenever the ground under the building changed, so it can't be kept from the render side.
- **Frames over 15 and 30 ms:** 2 and 1 in one run, 1 and 1 in the other. Planet-stalls alone gave 2/1 and 4/4, so tile-keys moves neither count.

What it does buy: kept reads survive the tile stores that go on all the time as the camera moves. In the oracle's runs, 4,431 and 5,023 kept reads were ones the single version would have read again. For opening-feet, it means the load's footings survive tiles stored between the load and the first frame (none were stored in this replay).

## Proof

The sweep check doesn't run the tile ground, so this park brings its own proof.

- **The tile oracle** (scratch: `tile_oracle.gd` with a hook). AI against AI on the tile ground (planet 7), headless, seeds 4 and 12345, 3,000 frames each. Every footing taken from what was kept is read again fresh at its nine points, and every figure placement skipped because its tiles stand is checked against a fresh read at each figure's spot.
  - Kept footings checked: 6,332 + 12,558. **Differing: 0.**
  - Of those, 4,431 + 5,023 are reads that the single version number would have done again.
  - Skipped figure placements: only 14 occurred, 0 differing.
  - **Its control** (kept reads always stand) fails as it must: 4,517 + 11,071 kept footings differ, by up to 915 units.
- **On a scratch copy of main 27aa456a with planet-stalls, this park and opening-feet:** `golden.json` is byte-identical to main's; the tile, lake water, cover water and sweep checks pass; the render gates pass 20 of 20; off stills match main + planet-stalls, 13 of 13.
