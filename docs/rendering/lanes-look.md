# The re-laid city's look (2026-10-11)

Owner: Rendering and Technical Art. For World's brief `docs/world/rendering-brief-lanes.md` (piece 2) and Art's `docs/art/district-looks.md`. Render only: it reads `S.lanes`, `S.buildings` and `data/biomes/settlements.json`, and writes nothing to the sim. The gameplay hash is unchanged.

## What is drawn now

- **The lane table is the sim's.** `RenderLanes.table` returns `S.lanes`; the stand-in is gone. A world with no table paints no streets.
- **Streets, avenues and lots.** The eight street strips are painted as before (sidewalk, kerb parking, carriageway), now from the real table. The ten avenues cross the two block lanes as a carriageway between two sidewalks. The ground of a block is paved in the looks that are paved (downtown, mid-rise, industrial, harbour) and stays the biome's ground in a suburb or a village (yards).
- **Shapes.** Each building is drawn by its `shape`, in parts: all 20 names have a builder. 13 are in today's world.
- **District looks.** Eight palettes and window patterns, from Art's table, chosen by the building's district.
- **Row haze.** The back block and the scenery row take the air's colour, so the three rows read as depth.
- **Stages** keep their four looks on every shape, and stage 2 gains broken-open bays so it reads from the street.

## How a shape is built

- **One box, deformed.** Every part of every building is an instance of one box in one MultiMesh. `building.gdshader` narrows a part's top (a taper: a frustum, a pyramid, or on one axis a gable's ridge) or slopes it down to one side (a lean: a shed's facet, a saw tooth). A plain box is untouched, to the bit.
- **Parts** come from `render/core/shapes.gd` (`RenderShapes.parts`): the body first, then tiers, caps and roofs. 169 buildings are 401 parts in today's world.
- **Art's rule holds by construction:** prisms and stacks of prisms, no curves.
- **The body keeps the building's own instance index,** so the stub, the porthole, the floor cut, the windows and the stage data work as they did. Each other part has its own texel of the same data.
- **Draw calls fall by two a copy:** the separate roof MultiMeshes are gone (a roof is a part).

| Shape | Drawn as | In today's world |
|---|---|---|
| shaft, slab, block | A box with a plant box on the roof, off centre | 27, 21, 5 |
| stepped | A core at 62% of the width with two skirts (setbacks at 45% and 74% of the height) | 18 |
| spire | A box under a four-sided pyramid | 13 |
| crown | A box under a frustum (the chamfered top) | none |
| house, shop | A box under a gable whose end faces the street (about 37 degrees); a shop has an awning | 65, 11 |
| thatch | As a house, about 55 degrees, deep eaves | none |
| terrace | Two steps, the upper under a steep roof | none |
| warehouse | A long box under a shallow gable, its slope to the street | 3 |
| sawtooth | A box under a row of leaning teeth | none |
| hall | A long gable with a porch | 1 |
| shed | A box under one leaning facet | 1 |
| chapel | A gable with a belfry tower at one end | 1 |
| chimney | A tapered stack with a flared cap | 2 |
| lighthouse | A tapered tower, one wide band, a gallery, a lantern room, a cone | 1 |
| quay, crane, mast | A low platform with posts; a mast with a jib and a cab; a pole with a yard arm | none |

**Landmarks.** The Gatebell is a pale stone shaft with slit windows, a dark belfry between two cornices, a spire, and a small stair bump on one side; no clock face. The stack has two soot bands and a short side flue; no red and white. The lighthouse has one wide slate band and a pale lantern room; no stripe, no beam. The hall has a ridge lantern. The chapel is the plain chapel.

## District looks

One facade palette and one window pattern a look (`RenderShapes.LOOK`, Art's hex values). The pattern is numbers the shader reads: a column of windows every so many units, the pane's span in its cell, strips a row, and flags for a clerestory, a door, shutters and door panels.

| Look | Windows as drawn |
|---|---|
| downtown | Continuous vertical glass bands between pale piers, a floor line every row |
| mid_rise | Two horizontal strips a storey |
| suburb | A grid of small windows, two or three a facade, a door |
| industrial | A clerestory strip under the roof, door panels along the ground |
| harbour | Few shuttered openings, a door |
| village_harbour | Small square windows with blue shutters, a door |
| village_workshop | Small square windows in brick, a door |
| village_hill | Tiny windows in stone, a door |

- **A floor taller than a row of windows carries several rows.** The sim caps a tower at 62 floors, so the tallest towers have floors nearly 300 units tall; windows stay about 150.
- **From the middle distance every pane is the glass's average,** and from far a wall is the average of wall and glass. A far tower is bands, not a sparkle that shimmers as the camera moves, and a wall does not change value as the camera pulls back.
- **A look World adds later** is drawn in the mid-rise table until Art gives it one; `shape_check` names it.

## Row haze

A part takes the air's colour by how far behind the fighter plane its front face stands (`RenderLook.ROW_HAZE`): none on the front block, 0.17 on the back block, 0.44 on the scenery row. The colour is the sky's toward the horizon in the pixel's own direction, so it follows the dynamic sky. Fighters, the crowd and the ground are not hazed by it.

## Stages at the new heights: what I see

Stills from the web build, the camera at fight framing in the downtown front street (towers of 60 floors behind the fighters).

- **Whole to windows out reads at once:** blue glass and lit panes become black bands between the pale piers.
- **Windows out to a part gone did not read from the street.** Stage 2's marks are a sheared top corner, which is thousands of units out of sight, and cracks, which are dark on a facade that is already mostly dark. **Added:** at stage 2 about a sixth of a facade's bays are broken open, wall and all (`RenderLook.DMG_HOLES`). It breaks the regular grid and reads at any height. It is subtle on a glass tower and strong on stone.
- **A shell reads by its frame:** the pale piers become thin grey posts and slabs.
- **A cut floor reads well:** a tunnel three floors tall is a dark opening as tall as seven fighters, and a stepped tower's skirt opens the same floors as its core.
- **Rubble** is unchanged (the ground's heap).
- **A tower's height loss does not read from the street,** for the same reason as the sheared corner: the top is out of the frame.

## The fight at the foot of the towers: what I see

- **The fighters read against the towers.** The ground floors behind them are dark glass and pale piers; nothing in the facade is a fighter's hue.
- **The crowd is what competes.** With 1,800 people the front sidewalk is a solid row of figures as tall as the fighters, in saturated colours, directly behind them. This is not new in this batch, but the denser city makes it constant downtown. It is Art's and World's to tune (density, size, saturation).
- **No sky shows downtown at fight framing.** The towers fill the frame, so depth comes only from the street and the row haze.
- **Lit panes are the brightest things behind the fighters** at dusk.

## Narrower than the sim's box (for World and Simulation)

Every part stays inside the sim's box: nothing stands higher than the sim's height, and no wall is wider than its width (`shape_check` asserts both; a roof's eaves overhang by at most 11% of the width). The reverse does not hold. A stepped tower's top tier is 62% of the sim's width, and a spire, a crown, a gable, a chimney and a lighthouse narrow toward the top. A fighter can collide with the sim's box where the drawn building has air, by up to a fifth of the width each side. If that matters, the sim's box for these shapes would take the upper width.

## For Art: stand-ins

- Octagonal shapes are four-sided: `chimney`, `lighthouse`, the Gatebell's spire.
- The Gatebell's belfry is a dark band, not four open arches with a bell inside.
- The lighthouse has one band where the brief has two.
- `crown`, `terrace`, `sawtooth`, `thatch`, `quay`, `crane` and `mast` are built but not in today's data, so they are checked for size only, not seen.
- Doors, shutters and awnings are flat colour.
- The palettes and window numbers are in `shapes.gd`; they belong in data once Art owns a file for them.
- Avenues do not open the sidewalks where they meet a street.

## Checks

- `render/tools/shape_check.gd` (headless, 10 checks): the table is the sim's and fits the shader's arrays; every look has its table; all 20 shapes build inside the sim's box; a part scales, is cut off and loses its caps as the sim's height says; an instance and a texel for every part; a damaged tower's top is the sim's; a cut tower's skirt opens the same floors; the rows' haze; the ground shader's avenues and block lanes.
- Unchanged and passing: determinism (plain and `--intro`), seam sweep, pane, stage, lane, sky, flash register, hud words, ground, after.
- **Not run:** `cull_check` needs a window. The vertex-stage culling was rewritten for deformed boxes and is judged by the web stills only.
- **Headless Godot compiles no shaders:** the look is proven by stills from the web build in headless Chrome.

## Limits

- **Cost is not measured.** The building fragment shader does more (the look's pattern), and there are 401 instances where there were about 250. The bench waits for a free machine.
- Row 0 is empty in the data. Its buildings would take the same shapes; they have not been seen.
- The world's light at night is not built: lit panes and facades are the dusk values at every hour.
