# Park: five planet sizes (World, 2026-11-13; A1 brief item 2; Orb: "five different planet sizes")

Design, numbers and what is not built: `docs/world/planet-sizes.md`. Runs: `docs/world/runs/planet-sizes/`. Check: `sim/world/tools/size_check.gd` (`SIZES`, in CI). **Stacks after `globe-step2` and `a-world-01`** (it was built on both: three of its files, `store.gd`, `sim/core/sim.gd` and the two shared lists, carry their lines); the three apply in that order and reproduce the scratch tree byte for byte (checked from a clean export of HEAD def3445a). Nothing is applied. The state's fingerprint changes only for a match that names a size other than medium; **medium is byte for byte today's** (parity passes unchanged at 4,800).

| File | What |
| :--- | :--- |
| `planet-sizes.diff` | World's: `sim/world/size.gd` (`WorldPlanetSize`) with its `.uid`, `data/biomes/sizes.json` and `tools/schemas/biomes-sizes.schema.json` (+ the `tools/schemas/map.json` entry), the place counts per size read in `planet.gd`, the planet memo's key, the slice memo's key, `WorldField.cells()` and the bake stride by size, the grid keys of the store and the water records, the planet disk cache's key, `size_check.gd` and `size_probe.gd` with their `.uid`s and the two lines in `tools/world-checks.json` (the probe under leaveOut) |
| `grant-simulation-sizes.patch` | Simulation's: `constants.gd` (`PLANET_NC` a static, `PLANET_NC_MEDIUM`, `setPlanet`), `state.gd` (`planetNC`), `sim.gd` (set at the top of the match, bound again every piece and every tick like the arena's length, the arena's default), `field.gd` (the match key's memo), `planet_load.gd` (the host's loader asks and makes the planet at the setup's size and puts the host's static back) |
| `grant-rendering-meteor.patch` | Rendering's `render/vfx/meteor.gd`: a `const` radius from `PLANET_NC` (which is no longer a constant) becomes `SimField.R` |

## The five

**Tiny 1,280, small 2,560, medium 4,800, big 9,600, huge 19,200 columns round** (a column is 32 units: 41 thousand to 614 thousand units; radius 6.5 to 98 thousand; a lap flat out at base 8 s to 123 s). Colossal (38,400) stays a row of data with `offered: false`, unproven. I propose these because the plan's colossal needs three pieces that are not built (windowed places, a ring that is not a great circle, a coarser bake), and the field world cannot hold a ring shorter than the planet (the frame maps the line to a closed great circle): so the arena is the planet's whole round at every size, and huge's per-column state is 4 times medium's (672 KB). Selectable from data: the menu offers `WorldPlanetSize.names(true)`; a setup names one as `planetSize`; a different five is an edit of `sizes.json`.

## Against the brief

| | Result |
| :--- | :--- |
| Each size generates | `SIZES`: planet 7, touch 1, all five on a field world with a frame, fighters on finite ground, 600 ticks played, the same setup twice gives the same match hash (tiny and big), a size the data does not have plays medium |
| Medium unchanged | `SIZES`: medium named plays byte for byte the match medium unnamed plays (hash at tick 120). **parity passes with the golden as it is on main** (9 matches, 174,798 ticks identical; planet worlds identical), on the tree with this park, a-world-01 and globe-step2 |
| The host's strict loader | `SIZES` makes a big planet through `SimPlanetLoad` (not made, not ready, load, ready, a strict match starts with `planetNC` 9600), and every call leaves the host's own static as it found it |
| Negative control | the store's grid offset kept at medium's 64 on the huge planet: 1 FAIL (two boxes of the huge planet that share a key) |
| Frame cost per size | not measured: the machine was shared (Performance reads it in a quiet window). By count, tick cost does not grow with the size (0.3 to 1.2 ms at every size on a loaded machine; medium 0.7 at the same load). Start times, cold, one machine, loaded: tiny 1.9 s, small 0.9, big 3.4 to 7.6, huge 7.9 to 9.7 (planet make for big 3.3 s, 112 places): void as measurements |
| World checks (88 with these, shipped data) | all 88 pass, on the stack of globe-step2, a-world-01 and this park (`checks-verdicts-all-88.txt`); validate 0 errors (323 files) |

## Decisions I made (reverse any)

1. **Five: tiny, small, medium, big, huge** (above). Tiny and small are 1,280 and 2,560, not the plan's 1,200 and 2,400: a face edge is `cols / 16` nodes of 128 units and the 512-unit bake needs that to be a multiple of 4, so a size is a multiple of 64 columns (the loader says so).
2. **Place counts per size are by about the square root of the area**, not the area (`sizes.json` `places`): tiny 2 cities and 4 towns, small 4 and 12, medium 12 and 44, big 24 and 88, huge 48 and 176, with the ring's minimums lowered on tiny and small. A planet function has absolute feature sizes, so a tiny planet cannot hold twelve cities of 6,500 units radius; the plan's by-area counts (a quarter of a million buildings at colossal) are the windowed-places work I did not build. It is Game Design's call (the plan's 4.3), and a data edit.
3. **The arena is the planet's whole great circle at every size.** The plan wanted a ring cap on big and huge; the field world cannot have one. Netcode prices the snapshot (672 KB a column set at huge).
4. **A size is a distance.** Nothing else moves: a column is 32 units, speeds, launches and bodies are absolute, so a lap goes with the loop. Per-size tuning of launches and the swing's read budget is Game Design's (the plan's step 6).

## NEEDS FROM EP

- **Simulation:** `grant-simulation-sizes.patch` (five files). Before colossal is ever offered: `SimField._boxKey`'s offset (a radius past 131,000 units aliases), the same fix the store got.
- **Rendering:** `grant-rendering-meteor.patch`, and the look of every size. `render/core/tile_field.gd` hard-codes the medium planet (the face edge 38,400 and 300 cells at lines 371, 447, 456, 508 to 522, 624), `planet_view.gd` 570 to 575 (the copies of the planet), `look.gd` far-city counts. The sim plays big and huge; no picture of them has been made.
- **UI:** a size row in the menu (`WorldPlanetSize.names(true)`, the setup key `planetSize`); with a random quick match the size is the data's or the menu's.
- **Netcode:** the handshake's setup comparison names the size (it is in the setup), and the snapshot at huge.
- **Art and Game Design:** tiny's relief against its radius (a 4,875 tower on a 6,519 radius) and the per-size tuning.
- **Performance:** the frame, load and snapshot readings per size, in a quiet window.

## RISKS

- Start time at big and huge is 4 to 10 s cold on a loaded machine (the planet's make is most of it): a loading screen, not a hitch. The disk cache has per-size keys (medium's are unchanged).
- The picture is untested at every size but medium (above).
- Only planet 7 (touch 1) was played at every size, and planet 12 touch 2 at big through the loader: each size's own pool of planets that generate and play is a later check, like the quick match's pool.
- A planet at a size is a different planet from the same seed at medium (the function is absolute, so a tiny 7 is a small piece of the medium 7's land).

## NEXT

After the gate: Rendering's tile work, UI's row, Performance's readings. Then the world's ranges, rivers and coasts (the planet's engineering, planet-overhaul section 5) can be built on a size knob that exists.
