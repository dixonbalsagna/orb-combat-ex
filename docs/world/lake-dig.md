# The lake dig (World, GW2, 2026-11-20)

The generator's lakes are valleys on the ring's one line; with `plans.lakeSpill` they sit at the level their real basin holds, which is almost no lake (docs/world/lake-shore.md). `plans.lakeDig` cuts each lake's planned footprint into a bowl instead, with no wall: ground at most 300 over the lake's level and joined to its seed is dug, falling from the new shore at no more than 1 in 3 to at most 300 under the level; higher ground stays shore or island; the ground beyond a pass (and the nodes touching it) keeps its height so the level holds; a lake whose dug water is under `minNodes` (40 nodes, a lake a fight can cross) is not dug.

Park, numbers, the finding (6 of 12 lakes dig at `minNodes` 40) and what is open: `docs/world/pending/lake-dig/README.md`. Check: `sim/world/tools/lake_dig_check.gd` (`LAKEDIG`). Data: `data/biomes/field.json` `plans.lakeDig`.
