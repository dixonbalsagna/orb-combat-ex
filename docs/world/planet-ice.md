# The stored planet, version 2: polar ice (World, 2026-10-16)

Owner: World and Environment. Orb, after picture A: "I want icecaps on the northern and southern poles, inspired by our real-life poles, a big icy landmass south, broken up icebergs, floes, sea ice on the north. show me a new prototype that iterates on the one I just looked at." **Paper and prototype only: nothing in the sim changed.** The idea and the slice picker are in `planet-slice.md`; this note is what ice adds.

Pictures (`docs/world/planet-slice/`): [A2](planet-slice/a2-planet-ice.svg) the planet stored with both poles (each pole seen from above); [F](planet-slice/f-polar-arena.svg) an arena through both poles, down to what one screen shows, to scale; [D2](planet-slice/d2-arena-holds-ice.svg) what three slices hold now that ice is a biome. Pictures A to E still describe the method (B and D were drawn on the planet before ice; their numbers are the earlier planet's). Scripts: `docs/world/scratch-build/planet-slice/` (`planet2_lib.gd` the planet, `planet2_dump.gd` the slices and numbers, `planet2_windows.gd`, `gen_svgs2.py`, `planet2.json`). Real poles are the inspiration only: no real map is used, and the shapes are generic noise.

## What stayed from A

The continents, the climate and 10 of A's 12 cities and 28 of its 31 towns are unchanged (the two cities and three towns that stood where the caps now are were placed again outside them; one city found no room, so 11 cities and 31 towns). The arena is still 153,600 units; the picker is unchanged. The planet is still a seed plus a function plus a short places list: **ice adds nothing to what is stored.**

## How ice works in the stored function

All of it is the same pure function of the point on the sphere (our hash noise, our own sin and cos and sqrt, float64, seed only). The inputs are the **latitude** (the y of the point, so a pole is y = 1 or -1), **the sea** (open water is below zero) and noise. No tables.

| | Rule (prototype numbers) | Result |
| :--- | :--- | :--- |
| **Where ice may be** | The caps begin at y = 0.72 (about 44 degrees from the pole): there the ordinary ground is blended down to deep ocean (north) or to the southern ocean. Cities and towns are kept out (y beyond 0.80) | Two caps, each about 14% of the planet's surface; the continents are untouched elsewhere |
| **North: sea ice** | The pack has a thickness `conc = (y - 0.88) / 0.10` plus noise: 0 at its edge (about 28 degrees, 12,000 units from the pole), about 1.2 at the pole. Floes are cells of a cellular noise (2,200 units across). A cell is ice with a chance that rises with `conc`, and its floe grows from 0.28 to 0.70 of the cell | Big, close floes at the pole; smaller and parted toward the edge; open water between. Floe top 10 to 38 units above the sea, thinner toward the edge |
| **Icebergs** | A second cellular noise (1,100 units), a small chance in a band round the pack's edge and round the south shelf | Single tall ice blocks, 45 to 215 units (a fighter is 75), alone in open water |
| **South: ice sheet** | A land mask `m = (ys - 0.91) / 0.07` plus noise (about 24 degrees, 10,400 units across, ragged). Inside it the ground is a dome: `180 + 1,500 m` plus relief, up to about 2,500 | One continent under an ice sheet, rising gently toward the pole |
| **Rock through the ice** | Where the dome is above 1,500 and a second noise is high | Bare rock tops (the mountains biome's tone) in the sheet |
| **Ice shelf** | Just outside the mask (about 2,000 units), flat at 36 units | A floating shelf that ends in a cliff of its height |

Two new biomes join ocean, plains, forest, desert and mountains: **ice sheet** (the south: land, a cold white slope) and **sea ice** (the north's floes and the bergs: a surface you can stand on over deep water).

## How an arena through ice reads (picture F)

- **A circle through a pole passes both poles** (a meridian). In the prototype one such arena holds 3 cities, 5 towns and 6 biomes, with 15% ice sheet and 8% sea ice. A circle that only clips a cap takes a shorter stretch (the clipping example: 15% sheet, 9% sea ice).
- **Sea ice, to scale** (3,000 units across, fighters 75 tall): a long low white slab a few units above dark water with gaps between floes; the water gap is a real gap in the ground (the ocean rules already exist: diving, hiding under the surface). An iceberg stands about twice a fighter. **No buildings and no people:** no collateral, so a polar fight is the purest brawl in the game, and the budget, menace and anguish are not touched.
- **Ice sheet, to scale:** a white slope that rises from 180 units at the coast to about 2,000 at the pole over 10,000 (gentle: the picture is near true scale), rock peaks through it, and at the coast the shelf: a flat white platform and then a cliff into the water. Also nothing built.
- **New rules ice would ask for (not built, for later windows):** ice is thin, so a crater through a floe should open the water under it (today water only exists where the original ground is below sea level); a floe should be able to break and drift; bergs are props that can be knocked or toppled. Rendering and Art: a cold palette, ice cracks, breath and wind, dark water: theirs.

## What ice does to the slice picker (picture D2; 300 touch-downs, 229 random circles)

| | Number |
| :--- | ---: |
| A random circle carries ice on at least 8% of its length | 47% |
| Touch-downs where the picker finds a slice meeting the minimum (the earlier planet: 92%) | 95% |
| Accepted arenas that carry at least 8% ice | 26% (and they hold 2.9 cities, as many as the rest) |
| A circle through both poles meets the minimum (2 cities, 3 towns, 3 biomes, half land) | 8% |
| ...meets a relaxed minimum (1 city, 2 towns, 3 biomes, 40% land) | 31% |

Rules that change: ice sheet and sea ice count as biomes (a polar arena easily has its three); sea ice is **not** land, ice sheet is (half of the length must still be land); the picker is otherwise as before, so ice only changes which circles pass. A polar arena is possible but rarely natural: a story level that wants one names the touch-down.

## Cost (this PC was busy: upper bounds)

An arena with no ice: 4,800 columns in about 1.0 s of GDScript (as before). An arena through both poles: about 1.9 s, because the floes are a 27-cell cellular noise and the prototype asks the function twice a column. One call a column and a coarse floe field (the cellular noise read every 8th column) are the obvious savings, not built. Done once, at touch-down.

## Questions for Orb (in `homework/22b-planet-ice.md`)

1. Should the ice caps be empty, or have a few small outposts (a research station, a mining camp) so a polar arena can have something to break?
2. Are the caps the right size (the north pack about 28 degrees from the pole, the south continent about 24; with the ocean round them each cap is about 14% of the planet's surface), or bigger, or smaller?
