# The water fill (Rendering, 2026-10-23; on water v2 2026-10-27)

Orb's brief (2026-10-23): water should visibly rush into holes, trenches and beam bores when the environment changes, keeping the pebble skip, as rule of cool and not fluid simulation, and costing nothing worth measuring.

World's water v2 (`sim/world/fill.gd`, `docs/world/water-v2.md`, behind `data/biomes/water.json`) does the filling: a new hole beside the sea, a lake or standing water, or under a wet biome's water table, tops its columns up toward a level, 9 units of depth every second tick, behind a front that runs from the source at about 2,900 units a second. `S.water` is the truth, and the water already draws it. This window draws the drama from World's cues, on the water and nowhere else. Render only: it never writes the sim.

## What it draws

- **The crest** (`water_fill`). A wedge of lift runs with the front over the water filling behind it, highest at the front and falling to nothing `WATER_FILL_T.x` seconds of the front's run behind it.
  - Its height is `WATER_CREST.x` (0.18) of the hole's depth, between 10 and 40 units.
  - Its foam is a thin hard line on the front (`WATER_FOAM_BAND.x`, 14 units, in `WATER_FOAM`, Art's sea accent). A band over the whole crest read as flat white slabs on this mesh.
  - It runs only along the hole's own run of columns: from the first column below the target surface past the open sea at the source, to the far wall (the first ground above the surface past World's reach of 36 columns, within which World feeds over a bump).
- **The pile.** Nearing the far wall the crest grows to `WATER_PILE` (1.6) times its height and slams into it.
  - Where two fronts come at each other, both runs end where the two arrive together, so both crests pile up on the same spot: the bore.
- **The slosh** (the overshoot and settle). At the wall the pile falls back and the pool tilts end to end, one end up and the other down, at a `WATER_FILL_T.y` (0.55 s) period. It settles over `WATER_FILL_T.z` (0.3 s), half the crest's height at first. The foam line stays on the pile while it stands over half its height.
- **The ring** (`water_wave`, a slam into standing water). A ring of lift `WATER_RING.x` (10) high and `.y` (50) wide runs out to World's radius (600 units) over at least `.z` (0.8 s), fast at first, then slowing. It sinks to nothing as it goes (a shape that ends, not a fade). Its foam is the same thin line on its crest for the first 60% of its run. World's push runs a fifth of a second; the ring outlasts it so it can be seen.
- **The waterline** (Art's flat facets), on every shore of the water, new and old:
  - a foam line `WATER_LINE.x` (1.5) pixels wide where the land rises through the surface;
  - a shallow band to `WATER_SHALLOW.x` (28 units) deep at `.y` (0.28) of the way to the foam colour;
  - both hard edged.
- **Where it lifts.** The crest, slosh and ring lift only wet water in the near rows (where the sim's water already stands), never below the floor, and never a shore vertex, so the shoreline stays on the ground's contour. Dry ground ahead of the front stays dry until the sim wets it.

A seeping water table (World's `cause` "table", no front) gets no crest: the hole simply fills from below as the sim has it.

## How

- `render/core/water_fill.gd` (`RenderWaterFill`):
  - takes each cue once, as the host drains it (the planet view queues it and reads it at its next update, with the ground);
  - reads that cue's run of columns once (at most twice World's window plus its reach);
  - keeps at most 4 fills (World's limit) and 2 rings;
  - drops each when it has run its course;
  - sends the uniforms to the water material only when one comes or goes. A second pane sends its source's.
- `render/shaders/water.gdshaderinc` (the body of `water.gdshader` and `water_far.gdshader`): `water_drama(x, z)` turns the live fills and rings into a lift and a foam flag. The vertex shader adds the lift to the near water; the fragment shader draws the foam and the waterline.
  - With nothing live, a uniform test skips the loops.
  - The loops run to the live counts (`wf_n`, `ww_n`, uniforms), so ANGLE's Direct3D compiler keeps one copy of each body (`boot.md`).
  - The waterline's `fwidth` is worked out outside any branch. There are no flat varyings.
- A fill's run is read on the ground the sim's water runs on (`WorldTerrain.lowD`: the lowest ground across the rows when depth is on).
- The clock is `crater_now` (the sim's time). A fill's start is set back one water step, where the sim's front first reaches.
- On (`RenderLook.WATER_FILL_ON`); main's `--nofill` turns the drama off (the waterline stays).

## Cost

- **CPU:** nothing per frame. A cue reads its own run of columns once (a few hundred reads), and the uniforms are set only when a fill or ring comes or goes.
- **GPU:** with nothing live, one uniform test per water vertex and fragment. While a fill runs, a loop over at most 4 fills and 2 rings in the near water's vertices and fragments: a few dozen operations each, for a second or two.
- **The waterline:** one `fwidth` and two compares per water fragment.

## Not yet

- The spray, the steam on a doused scar and the ring's splash are VFX's (`water_douse`, `water_wave`).
- The sea plane's three flat bands to the horizon (Art's item 1.6) wait for biome window 3.
- World's fill is on main but off (`data/biomes/water.json` `enabled`). Until it is switched on, no cue arrives and only the waterline shows. The drama was checked with it on in a scratch tree: the coast scene (a crater at tick 30, a trench from the sea at 150, a slam into the pool at 300), `img/lookgate/lookgate-water-fill.gif` (left without the drama, right with it).
