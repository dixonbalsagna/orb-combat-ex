# The city's towers up close: palettes, facade types and the crown tower's stubs

Owner: Art Director. 2026-10-16. For Rendering's pitch (`docs/rendering/homework4-pitch.md`, steps B and C) and Orb's homework 4 ("a bunch of dark grid lines"). Concept art and data, working labels, **pending Legal review**; Tools adds the schema (`node tools/validate.js` warns "no schema" until then). **Sheet:** `art/concepts/city/city-palettes.svg`. **Data:** `data/art/city-looks.json`. Regenerate: `node art/concepts/city/gen.mjs`.

## The one rule that shapes it
On `downtown` and `mid_rise` a pane may differ from its wall by at most 0.085 of relative luminance (`PATTERN_BUDGET`, `building.gdshader` 7b), or the stripes flip on every shake of the camera. The shader pulls any pane back toward its wall by that rule, so a dark glass on a light wall loses its colour. So **the variety is hue and chroma at equal luminance, never value**: every tint's glass is the wall's mid tone less 0.07 (dark) and plus 0.07 (bright), at a different hue. Every fin, spandrel, base and cornice follows the same budget against the wall it sits on. Measured: all 12 tints have glass within 0.075 of the wall (cap 0.085) and a hue gap of 110 to 180 degrees to the wall.

## Palettes (data/art/city-looks.json "looks")
Six tints per look; each gives the wall's three tones, the dark and bright glass, the trim, the spandrel and the fin colour, all in hex. Chroma is low everywhere (wall 0.006 to 0.035, glass 0.012 to 0.045 in OKLCH), so a tower is a tinted grey, not a coloured mass. That keeps buildings off the fighters' lane hues (cyan, violet, the Empress's green, the Cyborg's mint), off blood red, fire orange and the sea's mid blue (`district-looks.md`).
- **downtown:** steel with bronze glass; limestone with slate glass; graphite with amber glass; sage with rose glass; sandstone with slate glass; rose granite with blue glass.
- **mid_rise** (one step lighter): buff brick; cream render; pale concrete with warm glass; dusty clay; slate green with rose glass; chalk blue-grey with warm glass.
- **Per tower:** pick the tint by a hash of the building and the district's weights (below). Step B of the pitch (value ±8%, hue ±10 degrees) can still ride on top: keep the value change inside the budget.

## Facade types (data "facades"; each tone an offset from the wall's mid tone, never over the budget)
1. **Ribbon windows:** continuous horizontal bands between thin piers (today's rhythm); spandrel 0.03 under the wall.
2. **Punched windows with spandrels:** separate panes in a grid with a darker band under each row (0.06 under the wall): reads as stone or brick, a heavier older building.
3. **Vertical fins:** tall glass between projecting fins one pane apart; fin 0.07 under the wall, 0.07 over on the sun side: a strongly vertical read.

**A base and a crown that differ from the shaft** (data "base_and_crown"): a lobby storey 1.6 floors tall in the wall's mid tone less 0.06 (never darker: its join with the shaft is a long edge), punched panes only; a crown of the top two floors set back 6 percent each side, a cornice band at the wall plus 0.05, bright glass. Lit panes are Rendering's and are not raised here (a flash change; the pitch's step D waits for Orb's stills).

## Which district takes which (data "districts")
| District | Look | Facades | Tints | Rule |
|---|---|---|---|---|
| downtown | downtown | ribbon 40%, punched 25%, fins 35% | steel, limestone, graphite, sage, sandstone, granite | fins on shafts of 40 floors or more; punched on stepped and crown towers; ribbon elsewhere |
| mid_rise_west | mid_rise | punched 55%, ribbon 30%, fins 15% | buff, cream, clay, concrete, slate | older: warm brick and render, punched windows |
| mid_rise_east | mid_rise | ribbon 55%, fins 25%, punched 20% | concrete, chalk, slate, cream, buff | newer: pale and cool, ribbon windows |
Industrial, the suburbs and the villages keep the looks in `district-looks.md`.

## The crown tower's stubs (homework 5; Legal's recommendation, RL-127)
Short corner stubs in the tower's own tone in place of the two thin pale spires (which read as horns). **The shape, if Rendering wants it:** four square prisms (no taper, no point), one on each corner of the crown's top, each 0.9 of a floor tall and 0.12 of the crown's width, in the wall's mid tone plus 0.05 (the cornice's), unlit. Nothing taller than the stubs, nothing pale, and no pair of them taller than wide, so that from the front they read as a battlement, not as horns or antennae.

## What Rendering needs
Read the tints and facades from the data (the looks table in `shapes.gd` becomes the data's first tint); choose a facade by hash and the district's weights; keep every tone inside the budget (a `shape_check`-style assert on the data is cheap: every offset is already within 0.085); stills of three streets for Orb before any lit-window change.
