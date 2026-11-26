# Park: a dropped tile ground lets go of its materials (QA's hour run; Rendering, 2026-11-26)

## The file

| File | What |
|---|---|
| `mats_tracked.diff` (sha1 d5d3f75ecb55, 40 lines) | Changes `render/core/mats.gd` and `render/core/tile_ground.gd`. It applies strict on main (checked on dac1e0ec and 8bade29c). It also applies at the end of the whole stack: door-holds, cd04, sky-handover, feet-ground, marks-baked, rows-interp, fore-clamp, ground-link, tick0-craters, then Simulation's size-host grant. |

## What it does

QA's hour run found that `RenderMats._tracked` only grows. The cause:
- **Every match makes a new tile field, and with it a new `RenderTileGround`** (`PaneWorld`: its field is no longer the planet's, so it drops the old one).
- **Each new ground tracks two materials,** the tile ground's and its water's, in the pane's `RenderMats`.
- **`drop()` let the ground go, but `RenderMats` kept both materials.** It kept pushing every bend, sky and haze change to them, and held the old field's height and id texture arrays through them.

Now:
- **`RenderTileGround.drop()`** untracks its two materials.
- **`RenderMats.untrack(m)`** is new, and **`track(m)`** takes a material once, so tracking one again only brings it up to date.

Nothing is written to the sim.

## Proof

On main dac1e0ec: mt0 = main, mt1 = main plus this park. Record: `docs/rendering/runs/dac1e0ec/mats-tracked.txt`.

**A scratch probe: six matches through main with the split attached, each read after its load and 120 ticks.**

| | Match 1 | 2 | 3 | 4 | 5 | 6 |
|---|---|---|---|---|---|---|
| mt0, pane 0 tracked | 16 | 18 | 20 | 22 | 24 | 26 |
| mt1, pane 0 tracked | 14 | 14 | 14 | 14 | 14 | 14 |

- Pane 1 tracks 14 throughout, in both builds.
- **Earlier tile fields still alive:** one (the match just before) in both builds; none older.
- **Static memory** reads the same in both: +6.0 MiB after six matches. The textures the old materials held live in the renderer, and a headless run's renderer keeps none, so this probe can't weigh them. The proof here is the count, and the old field's texture arrays now have nothing holding them.

**Gates on mt1:**
- import 0, export clean;
- golden byte-identical to mt0;
- the five ground checks and drawn_check pass;
- the render gates: 20 of 20.

**Medium's collapse, worst of 4, both modes:** normal 1 and reduced 1.5, the same on both. It doesn't change what is drawn.

## `_wets` (QA's second item)

`RenderTileField._wets` is bounded, not leaking:
- **What it holds:** one entry per pool slot, refilled when the slot is reused. A wet layer holds 28 by 28 depths, and a dry one holds nothing.
- **Its bound:** 800 slots times 784 floats, about 2.39 MiB.
- **What the probe reads:** 48 to 52 wet layers, 0.14 to 0.16 MiB, flat from match 3 on. Each match's field starts empty.
