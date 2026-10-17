# The city's towers up close: palettes, facade types and the crown tower's stubs

Owner: Art Director. 2026-10-16; tints re-cut 2026-10-17 (below). For Rendering's pitch (`docs/rendering/homework4-pitch.md`, steps B and C) and Orb's homework 4 ("a bunch of dark grid lines"). Concept art and data, working labels, **pending Legal review**; Tools adds the schema (`node tools/validate.js` warns "no schema" until then). **Sheet:** `art/concepts/city/city-palettes.svg`. **Data:** `data/art/city-looks.json`. Regenerate: `node art/concepts/city/gen.mjs`.

## The one rule that shapes it
On `downtown` and `mid_rise` a pane may differ from its wall by at most 0.085 of relative luminance (`PATTERN_BUDGET`, `building.gdshader` 7b), or the stripes flip on every shake of the camera. The shader pulls any pane back toward its wall by that rule, so a dark glass on a light wall loses its colour. So **the variety is hue and chroma at equal luminance, never value**: every tint's glass is the wall's mid tone less 0.04 (dark) and plus 0.04 (bright), at a different hue. **The budget holds between neighbouring elements too (Legal's w05, RL-144): every tone (glass, spandrel, fin, trim, cornice, base) is within 0.04 of the wall's mid, so no two elements that can touch differ by more than 0.08.** The first cut had glass and fins at plus and minus 0.07, which put a bright glass beside a sun-side fin 0.14 apart. Measured, over every pair of tones in all 12 tints: at most 0.083 (cap 0.085), asserted by `gen.mjs` (it fails otherwise), and a hue gap of 70 to 180 degrees between wall and glass.

## Re-cut of 2026-10-17: the tints as the render masses them
Rendering masses a tower in the look's **shadow** tone (`building.gdshader` 7b; `docs/rendering/city-variety.md`): every tone is scaled by lum(shadow) / lum(mid) in linear light, x0.375 on downtown and x0.4 on mid_rise. In OKLab that scales lightness and chroma together, so the hue holds and **the chroma falls to about 0.72 of the wall's**. The first cut's warm walls (buff, clay, cream, sandstone, limestone, sage: hue 55 to 130, chroma 0.014 to 0.035) came out at chroma 0.010 to 0.026 and a dark warm near-grey reads as brown or olive; the closest pair of walls as massed was 1.2 CIEDE2000 apart (buff and clay), so six tints were barely two. The re-cut: **no wall or glass between hue 45 and 130**, the warm family becomes brick, terracotta and rose (hue 8 to 35, chroma 0.045 to 0.065), the rest are cool or plum (pine, spruce, teal, slate blue, steel, plum, mauve, concrete, graphite), glass sits in rose, teal and plum, and the massed walls keep chroma 0.023 or more except the two neutrals. `gen.mjs` computes every tone as massed, names what it reads as at that tone (grey, brick, rose, brown, olive, pine, slate, blue-grey, plum) and records it per tint in the data (`_as_massed`); the sheet shows it beside the tint. Result: **no wall or glass reads olive or brown at the mass tone; the closest pair of walls as massed is 5.6 (downtown: pine and teal) and 5.9 (mid_rise: rose and mauve) CIEDE2000**, so the six are six. The luminance budget is untouched (neighbours at most 0.082). A cost: the proposed streets are cooler and more mauve than the first cut's buff and cream; Orb should see a street of them lit before the set is final.

## Palettes (data/art/city-looks.json "looks")
Six tints per look; each gives the wall's three tones, the dark and bright glass, the trim, the spandrel and the fin colour, all in hex. Chroma is still modest (wall 0.006 to 0.065, glass 0.030 to 0.040 in OKLCH; massed, 0.72 of that), so a tower is a tinted grey, not a coloured mass. That keeps buildings off the fighters' lane hues (cyan, violet, the Empress's green, the Cyborg's mint), off blood red, fire orange and the sea's mid blue (`district-looks.md`).
- **downtown:** steel with plum glass; brick with teal glass; graphite with teal glass; pine with plum glass; plum with teal glass; teal slate with rose glass.
- **mid_rise** (one step lighter): terracotta with teal glass; dusty rose with teal glass; pale concrete with plum glass; spruce with plum glass; mauve with teal glass; slate blue with rose glass.
- **Per tower:** pick the tint by a hash of the building and the district's weights (below). Step B of the pitch (value ±8%, hue ±10 degrees) can still ride on top: keep the value change inside the budget.

## Facade types (data "facades"; each tone an offset from the wall's mid tone, never over the budget)
1. **Ribbon windows:** continuous horizontal bands between thin piers (today's rhythm); spandrel 0.02 under the wall.
2. **Punched windows with spandrels:** separate panes in a grid with a darker band under each row (0.03 under the wall): reads as stone or brick, a heavier older building.
3. **Vertical fins:** tall glass between projecting fins one pane apart; fin 0.03 under the wall, 0.03 over on the sun side: a strongly vertical read.

**A base and a crown that differ from the shaft** (data "base_and_crown"): a lobby storey 1.6 floors tall in the wall's mid tone less 0.03 (never darker: its join with the shaft is a long edge), punched panes only; a crown of the top two floors set back 6 percent each side, a cornice band at the wall plus 0.03, bright glass. Lit panes are Rendering's and are not raised here (a flash change; the pitch's step D waits for Orb's stills).

## Which district takes which (data "districts")
| District | Look | Facades | Tints | Rule |
|---|---|---|---|---|
| downtown | downtown | ribbon 40%, punched 25%, fins 35% | steel, brick, graphite, pine, plum, teal | fins on shafts of 40 floors or more; punched on stepped and crown towers; ribbon elsewhere |
| mid_rise_west | mid_rise | punched 55%, ribbon 30%, fins 15% | terracotta, rose, concrete, spruce, mauve, slate blue | older: brick, rose and terracotta, punched windows |
| mid_rise_east | mid_rise | ribbon 55%, fins 25%, punched 20% | concrete, slate blue, spruce, mauve, rose, terracotta | newer: pale and cool, ribbon windows |
Industrial, the suburbs and the villages keep the looks in `district-looks.md`.

## The crown tower's stubs (homework 5; Legal's recommendation, RL-127)
Short corner stubs in the tower's own tone in place of the two thin pale spires (which read as horns). **The shape, if Rendering wants it:** four square prisms (no taper, no point), one on each corner of the crown's top, each 0.9 of a floor tall and 0.12 of the crown's width, in the wall's mid tone plus 0.03 (the cornice's), unlit. Nothing taller than the stubs, nothing pale, and no pair of them taller than wide, so that from the front they read as a battlement, not as horns or antennae.

## What Rendering needs
Read the tints and facades from the data (the looks table in `shapes.gd` becomes the data's first tint); choose a facade by hash and the district's weights; keep every tone inside the budget (a `shape_check`-style assert on the data is cheap: every offset is already within 0.085); stills of three streets for Orb before any lit-window change.
