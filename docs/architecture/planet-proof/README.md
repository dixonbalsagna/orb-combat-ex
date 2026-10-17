# The planet function across two languages: the proof's scripts

Owner: Simulation and Engine. 2026-10-16. The proof for `../planet-slice-core.md` section 3. Scratch tools: nothing in the sim reads them, and `docs/` is hidden from Godot.

| File | What |
| :--- | :--- |
| `planet.mjs` | World's planet function (`docs/world/scratch-build/planet-slice/planet_lib.gd`) under the core's rules, in JS: float64 scalars, the frozen core's `sim/core/detmath.js` for sin and cos, the integer hash with `>>> 0`. One line a point (its three coordinates and its elevation as the hex of their float64 bits, its biome), then a full slice's hash |
| `p64lib.gd`, `planet64.gd` | The same in GDScript (`SimDetMath`, `SimRng.imul`), and the runner that also reads World's `Vector3` prototype at the same points |
| `planet_flip.gd` | Full slices read both ways (float64 scalars, `Vector3`), counting the columns whose biome differs |
| `cmp.py` | Compares the three outputs |
| `cross64.mjs` | World's crossing test (one point reached along two circles) in float64 |

**To run** (a clean export of HEAD, imported, so that the core's classes are known; never the repo itself):

1. Copy this folder's `.gd` files to `<export>/zplanet/`, with World's `planet_lib.gd` beside them.
2. `node planet.mjs <repo> > js.txt`
3. `godot --headless --path <export> --script res://zplanet/planet64.gd -- <out dir>` writes `gd64.txt` and `gdv3.txt`. Put `js.txt` in the same folder.
4. `python cmp.py <out dir>`
5. `godot --headless --path <export> --script res://zplanet/planet_flip.gd -- 40` (about 2 minutes)
6. `node cross64.mjs <repo>`

**Read on 2026-10-16** (an export of 4cdc8df6; this PC was busy, so the one timing is an upper bound):
- JS against GDScript, float64 scalars: **1,000 of 1,000 points bit-identical**; the full slice's hash `3ff71909` in both, and `6e41e11e` in both for the slice stored as float32 (as `S.base` stores heights).
- `Vector3` against float64: all 1,000 elevations differ, by up to 0.0026 units; no biome among the 1,000; over 40 full slices (192,000 columns), 1 column's biome differs, and heights by up to 0.0052 units.
- The crossing test in float64: 7.5e-12 units (World's `Vector3` test: 0.003).
- GDScript's float64 read of 4,800 columns, height and biome: 1.04 s.
