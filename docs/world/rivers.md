# Rivers for gen 2: a design on paper (World, 2026-10-23)

Written during the EP's quiet window (no Godot run). Nothing here is built. Inputs: Research's round-2 C (`docs/research/planet-gen.md` sections 2 and 5, `research/planet-gen/gen/erosion.mjs`), Game Design's 23b row 13 (crossings closer than 640 units merge into one span; at most one span in any 3,000 units; lakes and rivers follow the sea's rules: launches skim or sink, shallow water is waded), window 5's lakes, window 10's water v2.

## The idea in one paragraph

Route the rain over the grid gen 2 already makes. The climate grid (192 by 96 cells, about 800 units a cell, equal-area) already holds the ground's height and the carried moisture of every cell, so a river router costs no new ground reads: fill the depressions from the sea inward, send each cell to its lowest neighbour, add up the rain downstream, and a cell with enough flow is a river. A fight ring is a great circle through the planet; where it crosses a river's line, the ring's own ground (already known) says where the valley floor is, so the river is *snapped to the valley floor* and planted there as a narrow channel: the ring's bed is cut, the channel is filled with a flat water surface exactly as a window 5 lake is. The sim needs no new water machinery: a river span is a lake that is narrow, shallow and authorised by the drainage.

## Why not Research's whole C

Research's C builds its own 64 to 128 cell grid per face with 4 erosion passes and curves along the valleys. That is 1 to 5 s of GDScript (unmeasured; its routing and heap loops were not timed in GDScript) on top of gen 2's second, and what it buys that we need is only where a river crosses a ring. The ring is 32-unit columns; a river's curve inside an 800-unit cell is below what a ring can show. The erosion carve (valleys) is optional and nothing in the fights needs it. So: take C's *routing* idea (priority flood, steepest descent, accumulate), run it on the climate grid's cells, and leave the carve and the curves out. If Orb wants the map to show rivers as ribbons (far land, the planet picture), that is Rendering reading the same flow field, drawn with C's curve code later; it does not change the sim.

## What is built, step by step (windows, each parked behind a switch `data/biomes/rivers.json`, off)

**R1: the flow field.** After the grid's moisture carry, one more job step: priority flood from the sea (cells below 0 are the sea), receivers, rain accumulated downstream (rain per cell from the grid's carried moisture and the orographic term the climate already computes), a cell with flow over `riverFlow` is a river cell. Cost: 18,432 cells; JS-class work, an estimated 50 to 150 ms in GDScript, stepped like the grid (budget units of cells), carried on the planet (`P.flow`, a Float32 per cell and a receiver per cell). Frozen rivers: no river on an ice sheet or a snowcap (Research's rule), none on `desert` unless the flow is large (exotic river through a desert: a design call). A map tool overlay (`planet_map.gd --rivers`) to look at them against Research's compare images before anything else is built. Check: every river cell reaches the sea or a lake (no dead ends); flow is monotone downstream; the same twice.

**R2: crossings of a ring.** For a ring (a great circle sampled at 32-unit columns), find the river cells it passes through, and for each crossing the position along the ring of the river's line: the segment from a river cell's centre to its receiver's. Then *snap*: slide each crossing to the lowest ground column within the cell's reach (about 400 units each way) that is a local minimum of the ring's height; a crossing with no valley floor in reach (the ring crosses the river on a rise: the river is out of the ring's valley) is dropped. Rules from Game Design row 13: spans closer than 640 units merge into one (the bigger flow's), and of what remains at most one span in any 3,000 units (the greatest flow stays). A river that runs along the ring (a comb of crossings, Research's seed 23: 9 crossings, the closest 2 columns apart) is exactly the case the merge rule covers. Pure functions of the ring's ground and the flow field; no draw.

**R3: the span as water.** A span has a width, a depth and a level:
- width in columns from the flow, `4 + 3 * sqrt(flow / riverFlow)`, capped at 24 (about 130 to 770 units): Research's real widths (14 to 40 units a half-width) are a line at ring scale, below one column. The fight scale needs a stream a fighter reads as a stream; this is a data number.
- depth `riverDepth0 + riverDepth1 * sqrt(flow / riverFlow)`, capped below `HIDE_MIN_DEPTH` (100): a river is always waded (water v2's wade rule, below 75: no drag, no sink, a splash and a look), never deep enough to hide in or to sink a launch. A river that Game Design wants deep enough to skim is a number; row 13 says follow the sea's rules, which depth decides.
- level: the mean of the two banks' heights less a freeboard; the surface is flat across the span (as a lake), the bed cut to level minus depth with a taper over the outer fifth, so a bank never has a step.
- planted at the match's start by `WorldLakes.apply`'s own path: rivers are entries in `S.planetRing["lakes"]` with a `kind` field, so `refill`, the calm turn's carry (`onlyKept` / `onlyNew`), the tree exclusion (`dryTrees`), the dug-bed refill and water v2's fill (a river is "water already standing", so a hole dug beside it fills to its level: nothing new) all work unchanged. The hash carries the rivers' data only while the switch is on.

**R4: the look and the cue.** Rendering draws the water from `S.water` as it does a lake; the planet picture and the far land can draw the flow field as ribbons from the same data (World gives the cells and their flow; the drawing is Rendering's). Audio and VFX get no new event: a river is the existing wading and splash.

## Numbers I would start from (all data)

`riverFlow` 60 (Research's), width 4 + 3*sqrt, depth 20 + 10*sqrt capped 90, freeboard 6, taper a fifth of the width, merge 640, spacing 3,000 (row 13). To be tuned by eye on the maps and by counting: Research's rings cross 6 to 27 rivers on a planet-wide ring, which row 13's rules cut to about one a 3,000 units, so a 4,800-column (153,600 unit) ring may hold up to 50, usually 6 to 12 after merging; a *match's* ring (2,400 columns, 76,800 units) a handful. That is a lot of water in a match, so the switch will need a density knob (`maxPerRing`).

## Questions

For Game Design (row 13 follow-ups): (a) is a river span a fight's *scenery* only, or does it get a behavior beyond the wade (a current that carries a body along the ring, a bridge, a ford)? I assume scenery. (b) the width: a stream a fighter can step across, or one that fills a screen? I assume 4 to 24 columns. (c) may a river cross a city or town? Lakes keep a 10-column margin from a settlement; I assume the same, the river is dropped or moved to the next valley.

For Orb: whether rivers are wanted at all in the first gen 2 flip, or after the planet picture ships (they are the one thing in gen 2 that only exists to look right).

## Not in this design

Erosion carving, deltas and floodplains, tides, a river that changes course in a fight (water v2's fill is the only water that moves), and any ring-length river (a river along the ring is merged to one span by the rules).
