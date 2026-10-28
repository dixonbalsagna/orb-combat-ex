# Props on gen 2 planets (W5)

Owner: World and Environment. Date: 2026-10-28. Code: `sim/world/ground.gd` (`propsIn`, `propsNear`). Data: `data/biomes/ground.json` (the provisional rows, `provisionalProps` **false**). Check: `sim/world/tools/ground_props_check.gd`.

W4 added the berg and lone-tree rows as plain keyed draws. W5 places them the way PROP SMASH (`docs/combat/biomes.md` section 3) needs, and gives Combat the query. Everything here waits on `provisionalProps`, which stays off until Art sets the sizes.

## Bergs

- **The planet's own berg cells.** planet.json's bergs stand on the sea as sea ice columns from `bergH0` (45) to 215 units high. No floe stands that high (at most 38), so a run of sea ice columns at least `bergH0` high is a berg cell. Each cell gets one berg, at its highest column (on a tie, the one nearest the run's west end), and the berg's size is its height in fighter heights (75 units), held to the row's range. The prop carries `"cell": true`: the terrain already stands there as the berg.
- **Drawn bergs.** The row's keyed draw (the same key as W4's) runs on the floes and in open water (ocean below sea level) within one berg cell (planet.json `bergCell`, 1,100 units, 35 columns) of the pack's ice. A drawn berg is never within its largest size (7 columns) of a cell. Open water far from the ice gets none.
- A berg stands on the sea or on the ice, so the `minGround` test of dry ground does not apply to it.

## Lone trees

- A drawn lone tree (savanna, beach) stands only when none of the ring's trees (`S.trees`) is within its gap, and no lake holds its column.
- Each tree's gap is a keyed draw in its row's range, in feature units (WS).
- Where two drawn trees are closer than the larger of their two gaps, the one with the higher keyed priority stands. So the trees that stand are always at least their own gap apart.
- Every test reads the columns around the tree, across the seam, and never the range asked for. So any split of the ring lays the same trees, and the renderer can ask for a window.
- **The gaps are now 40 to 100 (savanna) and 50 to 120 (beach) feature units, cut from W4's 120 to 300 and 160 to 400.** The ring's own savanna trees stand about 155 feature units apart on average, so W4's gaps left almost no room: about one lone tree per arena of savanna. The new gaps keep a lone tree 4 to 13 fighter heights clear of any other tree. These are still provisional, and Art sets the final numbers.

## propsNear(S, x, reachBh)

- Returns PROP SMASH's targets within `reachBh` fighter heights of `x`, measured by shortest arc: lone trees, boulders and bergs (`outcrop` too, once a row has one). Each comes as `{x, kind, size, col, d}`, where `d` is the signed offset from `x`. Nearest first.
- It lays only the columns within reach (plus the gap margin inside `propsIn`), split at the seam when the window crosses it.
- Its seed is the planet's (`S.planetRing.seed`), not the ring's slice hash. A column's props depend on its index, its ground and the trees around it. The columns a turn keeps keep their index, ground and trees, so they keep their props with nothing carried in the state.
- It returns `[]` on a world with no fine ground (gen 1, the hand-made world) and while `provisionalProps` is off.
- Nothing in the sim calls it. PROP SMASH (Combat's and Encounter's) calls it behind its own switch.

## What stays the same

- With `provisionalProps` off, `propsIn` lays exactly what it laid before, and the new `trees` and `lakes` arguments change nothing.
- With it on, the other rows also lay exactly what they laid before.
- No hashed state was added, and nothing in a match reads the props. A gen 2 match plays bit for bit the same with the switch on (checked over 600 ticks).
