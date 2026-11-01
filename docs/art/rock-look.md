# Close rock that reads as a mountain (Art, 2026-11-01)

Brief: the EP's. A steep mountain flank fills the frame in big flat grey. It is dull, and Orb said hills look strange close up. Flat colour only, nothing noisy, no fade or blur, cheap on an old laptop. Rendering draws it.

Mock-up: `docs/art/img/rock-look-mockup.png`. Left, the frame as built (top right of `docs/rendering/img/lookgate/crater-scar-frames.png`). Right, the same frame with the rock repainted. The HUD, sky, buildings, fighters, stones and the scar keep their pixels; only the grey rock changes.

## What makes it read as rock: three cheap things, all flat

1. **Height bands.** Cut the slope into about six steps by height above the base, with ragged, slightly slanted edges. Low steps lean to earth and scree (mix about 14 to 48 percent of `#7a644e`), the middle stays grey, high steps lean pale and cool (mix about 6 to 32 percent of `#b2b8ce`). Each step is one flat colour per facet, so nothing is a gradient. Height is the one signal a close hill is missing: today the top and the foot are the same colour.
2. **Facets pushed apart by facing.** Stretch each facet's lightness about 35 percent from the middle, then warm the lit ones (a few points of red, fewer of blue) and cool the shaded ones. Neighbouring planes then read as different planes, not one grey wall. This is a per-facet colour, so it costs nothing per pixel.
3. **A few strata lines.** Thin (3 pixel), broken, slightly darker lines (about 25 percent) along every other band edge, with a rarer fainter one between. Dashes about 250 long, gaps about 130, offset per band so they don't line up. They run along the contour, so they follow the slope's tilt. Few and long, not many and short: short ones read as rain.

## Rules for Rendering

- The band edges and dash offsets come from a seed (the column and the band index), never from a per-frame value, so nothing crawls as the camera moves.
- Take the earth and pale tones from the biome's palette (subsoil and snow or haze triples in `data/art/biomes.json`), not the hexes above; these are for this grey night slope.
- If the strata must go in a shader, one step function of height and one dashed line function of the band edge are enough. No texture.
- Not done: no flash check (the bands are static in world space, so they should be quiet, but the lines move across the screen when the camera turns; Rendering should run the check on them). I painted over one frame, so a slope seen from below or from the other side is untested.
