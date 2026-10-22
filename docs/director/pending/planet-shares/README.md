# A planet's own biome shares for the location rules (parked, 2026-10-22)

Owner: Encounter Systems Director. The follow-up I named in my YES to World's window 1. On a planet's world, `DirLocation._planet` still came from the hand-made world's segments. `_planet` is each biome's share of the planet, which the hero's "overstayed" test and the villain's prowl read. It now comes from the planet's own columns (`WorldBiomes.planetCols`). The hand-made world is unchanged, and **the golden plays no planet, so it doesn't move.**

`node lp.cjs <root>` (`--check` writes nothing). One file, Encounter's: `sim/director/location.gd`.

## What it read (main 30fcaf28, in scratch)

| World | Before (the hand-made world's shares) | After |
| :--- | :--- | :--- |
| The hand-made world | city 0.156, ocean 0.26 ... | the same |
| Planet 7, the Whole | city 0.156, ocean 0.26 ... (wrong) | **city 0.238, ocean 0.387, mountains 0.123, plains 0.075, village 0.095, forest 0.057, desert 0.024** |
| Planet 7, the Half (2,400 columns) | the same, wrong | **mountains 0.342, city 0.324, forest 0.142, plains 0.117, village 0.052, desert 0.023, ocean 0** |

Each sums to 1. A 1,800-tick AI match plays on each. The golden regenerates byte-identical.
