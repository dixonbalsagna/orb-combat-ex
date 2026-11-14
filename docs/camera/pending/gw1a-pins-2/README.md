# Parked: split_sweep under GW1a's whole data (gw1a-pins-2)

Camera, 2026-11-15, for GW1a. **A fifth red camera check on the GW1a stack, not in the first list:** `split_sweep` fails 4 rows on s422 (with or without own-pane, gw1a-pins and gw1b-chase-measure). Both causes are off Orb's path. **Checks only.**

**Apply after split-sweep-energy-pins** (cut on main b1d9444e + split-sweep-energy-pins; that is exactly s422's `split_sweep.gd`): `git -c core.autocrlf=false apply gw1a-pins-2.patch` (sha1 e07a095b). One file, mine: `render/camera/tests/split_sweep.gd`.

| Rows | Cause | Pin |
| :--- | :--- | :--- |
| real match 3: full, pitch 49 full, full with the rig seeing slot 0 as the human, and with two humans (3 rows): "out of its pane for 1.20 s" | The same mechanism as split-sweep-energy-pins' real match 10. These rows run with the travel budget on, the sweep's own switch, and the game ships it off. With the dash, a fighter in free flight outruns the budget's travel cap, and the budget's one-second cooldown leaves him out of his pane. With `--budget=off` that row has no loss | the three rows get `{"dash": false}`, as real match 10 has (the energy model stays on) |
| crossing start: "the layout was not one view in the first 100 ticks" | **The kick** (`data/fight/kick.json`, on in the 9 November data; bisected to that one file): the collision's kick sends a fighter flying and the split opens inside the start's 100 ticks. The crossing start is a demo start no build opens on (`sim.gd`, default off); it's already pinned to the energy model off | its setup gets `"kick": false` |

## Proof (`docs/camera/runs/b1d9444e/gw1a-pins-2/`)

| Run | Result |
| :--- | :--- |
| s422 + own-pane + gw1a-pins + gw1b-chase-measure, before | split_sweep FAILED (4); the same 4 with the rig before gw1b-scape-side |
| the same + this park | **split sweep passed** |
| The same tree with main's data | see `runs.txt` |

## Owed (after GW1a, not for Orb's game)

The travel budget's handling of a flier faster than its cap is already owed from split-sweep-energy-pins. These three rows are the same item. The budget is off in the game.
