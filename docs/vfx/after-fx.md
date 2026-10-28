# What a beam leaves in the ground (VFX, the aftermath looks)

World's aftermaths (`sim/world/after.gd`, `docs/world/after.md`, behind `data/biomes/after.json` `enabled`, **off**) mark terrain columns after a signature beam: `S.aftermath` is a kind byte a column, `S.aftermathT` the `waterTick` a timed kind ends at, `S.aftermathJobs` the work still running. This is what VFX draws from that state. With the switch off those arrays are empty and VFX draws nothing.

## What it draws (`render/vfx/after.gd`, `VfxAfter`)
Every unfrozen tick, from the state only (so a seek, a snapshot or a late join draws the same), for the strips within the framing's span of the pair (the nearest 40 columns of each kind):

| Kind (code) | Look | Ends |
| :--- | :--- | :--- |
| fire line, BURNING (4) | the pool's cel flames low along the strip (Art's orange, steady), a thin dark smoke, a few embers | dies down over its last 90 ticks (`aftermathT`) |
| glowing strip, EMBER (6) | steady embers rising from it (the pool's ember bit, Art's ramp) | dies down over its last 90 ticks |
| snow dump, SNOW (8) | a powder curtain falling over the groove (the pool's snow fleck), a pale puff at the ground | over its last 24 ticks |
| scree, SCREE (10) | while its run is still going (a live job in `S.aftermathJobs`): chunks tumbling down the slope in the ground's colours, dust | when the job ends; a settled heap draws nothing |
| parted sea, OPEN (13) | spray off the top of each water wall (the pool's water streak, kept under its cap), foam at the wall's face | while the trench stands |
| run-up shore, WET (11) | foam at the strip, strongest at the start of its wet time (`wet.age`, 80 ticks of the 240) | as it dries |
| split floe, SPLIT (12) | a pale, cool sea smoke over the open lead (none in reduced motion) | stays with the lead, very light |

**Not VFX's** (ground looks, Rendering's): glaze (the strip reads `ice`), cleared (the canopy gone, the trunks lying across), plates (a heave's step), flooded (the water itself), burnt (`ash`), crust, the wet sand's tint. World's `lookAt` and `surfaceAt` read the strips as glaze `ice`, a glowing or cooled ember strip `crust` (there is no separate `ember` look class: Combat's stripLooks), burnt grass `ash` and a flooded groove `water`; the ground-side tints are Rendering's. The glowing strip's embers here are drawn from the strip's own kind (EMBER, `hazardAt`), not from a look class. Those are listed in the report for the EP to route.

The walls of the parted sea are the columns at either end of the OPEN run that have water beside them (`WorldWater.surfaceAt`); spray is thrown up off the top, foam runs down the face. The wave when the sea rushes back is World's `water_wave` event (`render/core/water_fill.gd` draws its water); this does not draw a second one.

## Budgets and Legal
- Rates are per column per second at full strength (per wall for the walls), scaled by quality and halved in reduced motion, where there are also no puffs, foam or mist. Everything is data (`after` in `data/vfx/biome.json`, closed in `vfx-biome.schema.json`).
- Flames stay under `fire.cap` (26 alive; the explosions' cap is 40, the forest fire's 36 and this share the pool, so a burning forest and a fire line together can reach the pool's cap, never past it); embers under the pool's own cap and drawn-area limit; powder under `snow.cap` flecks (it counts with the biome ambient's); spray under the pool's streak cap; puffs and foam under the puff area budget (Legal).
- Steady and soft, never a flash: no star, no ring, no luminance step beyond a flame's own size; flames grow in and burn down in the pool, embers are the steady ramp, powder and mist are pale and slow.
- A fixed number of cosmetic draws a bit made or not, so the stream does not depend on a cap.
- Switch: `hub.after_enabled` (`VfxLook.AFTER_DEFAULT`, on); it draws nothing while `S.aftermath` has no arrays.

## Not done
- **The onset.** The state has no "just laid" mark (a persistent kind has no end time), so nothing marks the moment a beam leaves a strip; a short burst there (a glaze's glint, a heave's dust, a clearing's falling leaves) needs an event from the director at lay time, a small proposal in the report.
- Glints on a glazed strip and leaves on a cleared one would be steady looks forever for the rest of the match; held back for that reason.
- The look is first-pass and by eye (sizes, rates); the numbers are data.
