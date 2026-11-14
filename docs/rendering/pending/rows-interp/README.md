# The strip rows drawn the sim's way inside a column: the feet gate's last samples (A1 clipping)

Rendering, 2026-11-14, the EP's order item 4. `rows_interp.diff` (sha1 b36ee1a9, 30 lines) touches `render/core/ground_field.gd` (`offset_at`, the CPU twin) and `render/shaders/ground.gdshaderinc` (`ground_offset4`). It applies on main as it is, and its figures are on main 83a5b963 + `feet-ground` + `marks-baked`. It doesn't depend on those, but they're what made the last samples visible.

## The fault

The strip's deform (`S.deform`) is drawn by the rows: the listed craters' profiles at the exact x, plus a residual per column. The residual is the deform less those craters, taken at the column's start (`GroundField._g_col`).
- The sim interpolates a column's deform between its start and the next column's (`WorldTerrain.groundY`).
- The rows drew the residual flat across the column.

Where the deform drops sharply from one column to the next, as at a slide's trench lip (seed 1: 21.9 to about 0), the drawn ground and the sim's disagreed inside the column. The fighter's feet sat up to 19 units into the drawn ground (`runs/83a5b963/groove-remainder*.txt`, the last diagnosis).

## The change

Both twins interpolate the residual between this column's start and the next's, as the sim does. The shader's slope term is the interpolation's own slope.

At a column's start the value is as before, so the strip ground draws as before: its vertices sit at column starts, and `GroundField.ground_at` reads at them. The tile ground's vertices fall anywhere, and now follow the sim inside a column.

## Proof

`docs/rendering/runs/83a5b963/rows-interp.txt`:
- `golden.json` is byte-identical, the five ground checks pass, and the render gates pass 20 of 20;
- **the feet gate: 0 of 4,014 standing samples more than 8 units off, the worst 4.5; all ten seeds clean** (with `marks-baked` alone: 42, 1.0%, the worst 19.0).

The first reading, on seeds 1 and 7 alone: `rows-interp-probe.txt`.

With this landed, the feet gate's ratchet can drop to its floor: say at most 0.5% over 8, and nothing over 12. That's the EP's call.

## The look gate

Orb's 16:46 replay, the same ticks as the feet side-by-side (4,140 to 5,540), through Tools' blackbox-clip. Left is the feet build (6a30b4c9 as played + `feet-ground` + `marks-baked`, 1e50522a); right is the same + this (b36ee1a9). Pictures (uncommitted, they show fighters): `docs/rendering/img/lookgate/rows-orb-t*.png`, `rows-orb.gif`, and a close crop, `rows-orb-crop-t00112.png`.
- **95 of 141 frames are identical.**
- The rest are mostly frames 111 to 119 (ticks 5,240 to 5,320, after the beam of 5,220). The beam's groove walls and lips are shaped slightly differently inside each column, smoother where the deform steps. There's nothing else to see.

Flash: the change only reshapes a groove's wall within a column, so I don't expect it to move a reading. It isn't measured.
