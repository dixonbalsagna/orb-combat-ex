# Tundra's rock carries strata lines

Parked by Rendering, 2026-11-01. `strata.diff` stacks on `2026-11-01s-tile-level-word/layer.diff`, though it touches only `render/core/biome_look.gd`. Goes with Art's warmer tundra rock in `data/art/biomes.json` (uncommitted when this was shot: lit #8c8270, mid #777472, shade #504d4e).

**The fault.** Orb's "hollow mountain" colour half: on the hillside town a patch of tundra (id 9) lies under highland (id 13). Its rock was neutral grey with no strata, against warm tan with lines, so the lines stopped dead at the border and the patch read as a hole. Read at tick 481 down one column: the colour change lands on the biome change.

**The change.** `"tundra"` joins `STRATA` in `biome_look.gd`.

**Seen:** `docs/rendering/img/lookgate/tundra-strata-before-after.png`, ticks 421 and 541, left before, right with this, Art's rock, the pool and the level fix. The inner shape blends into the slope and the lines run through. The right column has all four together, so it doesn't show this word alone.

**Not checked:**
- It changes every tundra on the planet, tiles on or off. Off stills showed 0 of 13 differ, but tundra may simply not be in those frames, so that proves little for tundra itself.
- Whether tundra's flat ground reads well with lines on its steep parts elsewhere; only this town was looked at.

**Art's rock look (`rocklook`) doesn't replace this.** It's off by default, a much bigger change, and it would only carry lines across the border with its switch on. If it's ever turned on, it takes over from strata on slopes past its start, so this word stops mattering there.

**Gates:** as `2026-11-01s-tile-level-word`'s.
