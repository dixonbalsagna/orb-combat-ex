# Park: a capture draws the same reel every run (Rendering, 2026-11-23)

The EP's step 1 of the collapse attribution. A capture's render work used the wall clock: the tile fill, its jobs, the things' feet, the off-screen building visits, and the crowd's animation (the only shader that read `TIME`). A capture's frames are slow and uneven, depending on the machine's load. So which tiles and visits were done by a given tick changed from run to run, and so did the figures' steps. The same build then drew a different reel each time:
- Small's collapse clip, reduced, failed 2 runs in 3 and passed the third (FAIL 7 or PASS 2.5).
- Single runs of a switch couldn't attribute anything.
- Medium's PASS on main might have been luck.

**This changes nothing in play.** Everything turns on `RenderTileField.steady_fill`, which the flash hook sets for its captures.

## The file

| File | What |
|---|---|
| `capture_steady.diff` (711943c2, 216 lines) | `render/core/tile_field.gd`, `tile_ground.gd`, `planet_view.gd`, `look.gd`, `render/shaders/crowd.gdshader`. Cut on main 2e3407dc. It applies on main 4d214270 and on the GW1c stack (after planet-sizes and drawn-at) as it is. |

## What it does

- **The work clock.** `RenderTileField.clock_us()` returns the wall's microseconds in play. In a capture (`steady_fill`) it returns a clock that only `RenderTileField.spend()` moves, by a fixed cost for each piece of work:
  - a tile node: `TILE_STEADY_NODE_US`, 40;
  - a thing's foot: `TILE_STEADY_FOOT_US`, 15;
  - a building's visit: `VISIT_STEADY_US`, 150.

  Every budget in the tile field reads it (the fill, a job's slices, the near list, the boot, the feet), and so does the planet view's off-screen visits (`VISIT_SPARE_US`).
- **A capture's slice.** `RenderTileGround._fill_slice` sized each frame's slice from the wall time between frames. A capture's slow frames therefore got the least, 750 µs, while play with room gets up to 6,000. With `steady_fill` the slice is now `TILE_FILL_STEADY_US`, 5,000: play's at a frame of about 8 ms.
- **The crowd's clock.** `crowd.gdshader` takes a `crowd_time` uniform:
  - In a capture, `PlanetView.update` sets it to the sim's clock (`S.T`) every frame.
  - In play it stays at -1, and the shader keeps its own `TIME`.

## Proof

`docs/rendering/runs/2e3407dc/capture-steady.txt`: one size (960x540), every frame kept and compared across three runs of the same build.

| Clip | Frames differing in any pixel | Verdict, all three runs |
|---|---|---|
| Small (the GW1c tree, cap off), collapse reduced | 0 of 1,100 | OVER GATE 3 (inside the standard's 3, over our 2.5) |
| Medium (main 2e3407dc), collapse reduced | 0 of 1,500 | PASS 2 |
| Medium (main 2e3407dc), collapse normal | 0 of 1,500 | PASS 2 |

Before the crowd's clock, medium's runs differed in the first 185 ticks: the figures stood differently. Before the work clock, small's runs were bimodal.

## Gates

On main 4d214270 plus this change: `docs/rendering/runs/4d214270/capture-steady-gates.txt`.
- Import: 0 errors.
- Golden: byte-identical to main's committed file.
- The five ground checks pass.
- The render gates: 20 of 20, `flash` and `flashreg` included. They capture through the same hook, now on the work clock.
- Medium's collapse with the change, Tools' two sizes (the verdict's four readings): normal PASS 2, reduced PASS 2.

## What it means for others (through the EP)

- **Tools and QA:** the flash nightlies and every look gate capture through this hook. Their readings become repeatable, and some will move. A clip that passed or failed by luck now reads the same every time.
- **The cost constants** are a fair guess at the web build's speed (a tile node about 40 µs). If a reel should show a slower machine, they're the knob.
