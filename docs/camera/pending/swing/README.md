# The swing's camera: six parks (Camera, 2026-10-31)

What they are: `docs/camera/swing-view.md`. Cut on main 66654335. **Apply order:** Rendering's `2026-10-31a-tile-ground/tile.diff` (d8b3df78), Encounter's `docs/director/pending/swing/swing.diff` (b290939d), then these six in order. Apply with `git -c core.autocrlf=false apply`. The first three and park 5 need neither of those two at compile time, but were tested only on them; park 4 needs Encounter's data file; park 6 needs the tile park.

| Park | Files | Whose |
| :--- | :--- | :--- |
| `swing-1-places.patch` | `render/camera`: `cam_places.gd` (new), `split_rig.gd`, `split_frame.gd`, `split_view.gd`, a check | Mine |
| `swing-2-shot.patch` | `render/camera`: `split_rig.gd`, `camera_params.gd`, a check | Mine |
| `swing-3-peak.patch` | `render/camera`: `split_rig.gd`, `split_view.gd`, `camera_params.gd`, a check | Mine |
| `swing-4-sim.patch` | `sim/director/swing_read.gd` (new, by grant), a check; the `read` block in Encounter's `data/director/swing.json` and schema | The EP's grant |
| `swing-5-real.patch` | `render/camera`; `data/camera/swing.json` and its schema (new), `tools/schemas/map.json` | Mine, a Tools row |
| `swing-6-grant.patch` | `render/core/main.gd`, `render/core/tile_ground.gd` | **Rendering's: a grant** |

| `swing-7-director.patch` | `render/camera`, a check; `render/core/main.gd`, one line | Mine, a line of Rendering's. `docs/camera/launch-director.md`. Off byte-identical |

| `swing-8-flat.patch` 6bc69662 | `render/camera`, a check; `render/core/main.gd`, one line | Mine, a line of Rendering's. Flat sends past 10,000 units a second |
| `swing-9-reveal.patch` a3bbef1f | The same | The same. A long flight opens out in its middle |
| `swing-10-overshoot.patch` 0c912fef | The same | The same. A fast stop carries the frame on a little |
| `swing-11-close.patch` 55fb48b8 | The same | The same. A locked brawl frames closer. **Land it after the building wall's fix:** a closer shot lets one wall fill more of the frame |

8 to 11 go after 7, in order, each off with `tiles` off. Only these cuts are good: any earlier 8, 9 or 10 lacks two fixes. Apply `../split-vision/` after them, or on main alone; either order holds. Words: `docs/camera/launch-director.md`.

`flash-fore-tone.patch` is only the sketch I tested; Rendering's tile.diff now carries its own. Delete it when the tiles land. All off with `tiles` off.
