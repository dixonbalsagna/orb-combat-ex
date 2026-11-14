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

| `swing-readable.patch` 2be401e1 | `render/camera`, two checks; `render/core/main.gd`, one line | Mine, a line of Rendering's. Wide while a body's really flying, readable within about a second of it stopping. On with `tiles` |
| `swing-peak-retry.patch` d56f1a42 | `split_rig.gd`, a check | Mine. **The meteor's peak shot:** a launch sent in a hit-stop lost its shot. No switch: it's a fix inside the peak shot, which is on with `tiles` |
| `swing-12-sky.patch` 06416c08 | `render/camera`, a check | Mine. **Parked, off, not to land** (the EP's call): a close brawl with no sky decides once, tilt first, then size. In 4 AI fights it chose "sky" on all 29 locks, and on the flank too, which shows a strip of sky at its far side |

| `swing-in-frame.patch` | `split_rig.gd`, `camera_params.gd`, `launch_shots_check.gd` | Mine. A reveal needs land in its shot and keeps him at least 0.05 (0.03 with both at tier 3+); the check fails on a flying body out of his picture for over 12 ticks. Under `readable` |

| `swing-rush-follow.patch` | `split_rig.gd`, `launch_shots_check.gd` | Mine. A long rush's pane follows him instead of cutting ahead to the arrival. Under `readable` |

| `swing-share.patch` | `render/camera`, `data/camera/swing.json` and schema; `render/core/main.gd`, one line | Mine, a line of Rendering's, a Tools row. Against a CPU the player's pane takes `splitShare` of the split (off in data: a page word) |
| `swing-lead-ahead.patch` | `split_rig.gd`, `camera_params.gd` | Mine. `SplitRig.lead_ahead`, off. Flying fast, more of the pane ahead of him, in the large pane or an even split only |

| `swing-size-floor.patch` | `split_rig.gd`, `camera_params.gd` | Mine. Under `readable`, the scroll governor leaves a fast body at least 0.06 (43 px at 720p), against 0.032 and 0.05 |
| `swing-chase-air.patch` | `split_rig.gd`, `tests/chase_rush_check.gd` | Mine. **Needs Encounter's `docs/director/pending/chase-tap`, `chase-tap.diff` then `chase-ease.diff`, first** (the check calls `DirChaseTap`, and its limits are for the eased rush). A rush at a body in the air has no slam door: the split stays open and the pane follows him. Under `readable` |
| `swing-roster.patch` | `split_rig.gd`, `sim/director/swing_read.gd` | Mine (ee95c5c7). The two-fighter ratchet: the pair's middle and speed and the read's pair come from the roster (`_pair_mid`, `_pair_speed`, `S.fighters.slice(0, 2)`), byte-identical. **Needs Encounter's `docs/director/pending/ratchet-roster/` first: `ratchet-roster.diff` (or its `ratchet.py`), then `camera-swing-read.patch`**. Ratchet 369 against 386 with those; split_rig.gd 43, swing_read.gd 0 |

Order after 11: readable, peak-retry, in-frame, rush-follow, share, lead-ahead. Then chase-tap, chase-ease, chase-air, size-floor, then Encounter's ratchet-roster and camera-swing-read, then roster. All apply on field-place and power-core too. Those two were cut on main 07135713 + tile, near, far, water, sea, band, crater + 1 to 11.

8 to 11 go after 7, in order, each off with `tiles` off. Only these cuts are good: any earlier 8, 9 or 10 lacks two fixes. Apply `../split-vision/` after them, or on main alone; either order holds. Words: `docs/camera/launch-director.md`.

`flash-fore-tone.patch` is only the sketch I tested; Rendering's tile.diff now carries its own. Delete it when the tiles land. All off with `tiles` off.
