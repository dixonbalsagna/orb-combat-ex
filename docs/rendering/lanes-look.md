# The re-laid city's look (2026-10-11; the shorter city, fuller tops and street grid 2026-10-12)

Owner: Rendering and Technical Art. For World's brief `docs/world/rendering-brief-lanes.md` (piece 2) and Art's `docs/art/district-looks.md`. Render only: it reads `S.lanes`, `S.buildings` and `data/biomes/settlements.json`, and writes nothing to the sim. The gameplay hash is unchanged.

## What is drawn now

- **The lane table is the sim's.** `RenderLanes.table` returns `S.lanes`; the stand-in is gone. A world with no table paints no streets.
- **Streets, avenues and lots.** The street strips are painted from the table (sidewalk, kerb parking, carriageway): up to sixteen, so three streets of five strips fit (World's street grid, 2026-10-12; `STREET_STRIPS`). Up to 24 avenues cross the block lanes as a carriageway between two sidewalks (`STREET_AVENUES`). **Where an avenue meets a street the street's sidewalk and kerb give way to road:** a crossing. The ground of a block is paved in the looks that are paved (downtown, mid-rise, industrial, harbour) and stays the biome's ground in a suburb or a village (yards).
- **Shapes.** Each building is drawn by its `shape`, in parts: all 20 names have a builder. The table says which are in the re-laid city. **The shapes fill the sim's box** and their spires, gems and ridges stand above it (2026-10-12: see "Filling the sim's box").
- **District looks.** Eight palettes and window patterns, from Art's table, chosen by the building's district.
- **Row haze.** The back block and the scenery row take the air's colour, so the three rows read as depth.
- **Stages** keep their four looks on every shape, and stage 2 gains broken-open bays so it reads from the street.
- **Tall towers are tone on tone** (the contrast budget, added the same day after the first version failed the flash check: see below).

## How a shape is built

- **One box, deformed.** Every part of every building is an instance of one box in one MultiMesh. `building.gdshader` narrows a part's top (a taper: a frustum, a pyramid, or on one axis a gable's ridge) or slopes it down to one side (a lean: a shed's facet, a saw tooth). A plain box is untouched, to the bit.
- **Parts** come from `render/core/shapes.gd` (`RenderShapes.parts`): the body first, then tiers, caps, roofs and ornaments. About 120 buildings are 270 to 300 parts in the re-laid city (`shape_check` prints the count).
- **Art's rule holds by construction:** prisms and stacks of prisms, no curves.
- **The body keeps the building's own instance index,** so the stub, the porthole, the floor cut, the windows and the stage data work as they did. Each other part has its own texel of the same data.
- **Draw calls fall by two a copy:** the separate roof MultiMeshes are gone (a roof is a part).

| Shape | Drawn as | In the re-laid city (2026-10-12) |
|---|---|---|
| shaft, slab, block | The sim's box, with a plant box above it, off centre | yes |
| stepped | A core at 86% of the width for the whole height, with two skirts (setbacks at 45% and 74% of the height) and a plant box above | yes |
| spire | The sim's box with a four-sided pyramid above it | yes (one is the bell tower) |
| crown | The box to a chamfer that keeps 86% of the width at the sim's height, and a cut gem above | only as the crown tower |
| house, shop | A box under a gable whose end faces the street (about 37 degrees where the height allows): the ridge above the sim's height, the eaves at most a tenth under it; a shop has an awning | yes |
| thatch | As a house, about 55 degrees, deep eaves | none |
| terrace | Two steps, the upper under a steep roof (thin by nature) | none |
| warehouse | A long box under a shallow gable, its slope to the street | yes |
| sawtooth | A box under a row of leaning teeth | none |
| hall | A long gable with a porch | the village hall |
| shed | A box under one leaning facet | one |
| chapel | A gable with a belfry tower at one end (thin by nature) | the hill chapel |
| chimney | A stack tapering to 86% of its width, with a flared cap above | two (one is the stack) |
| lighthouse | A tower tapering to 86%, one wide band; a gallery, a lantern room and a cone above | the lighthouse |
| quay, crane, mast | A low platform with posts; a mast with a jib and a cab; a pole with a yard arm (thin by nature) | none |

**Landmarks** are drawn by their key in the data (`RenderShapes.landmark_key`), each on its own shape. **The bell tower** (the Gatebell) is a pale stone shaft with slit windows, a dark belfry between two cornices, a spire above the sim's height, and a small stair bump on one side; no clock face. **The ledger hall** (new) is a broad stepped hall of pale stone: a dark arcade at the street, a pale ledge at each setback, and a low two-step cap above. **The crown tower** (new) is a glass tower with a pale band under its chamfer and a crown above it: a low gem between four short square stubs in the tower's own tone, as a battlement (Legal's recommendation, RL-127: four thin pale points read as two horns from the front; Art's shape, `docs/art/city-facades.md`; 2026-10-16, Orb's homework 5 left to us; `img/city/crown-tower-stubs.png`, uncommitted). The stack has two soot bands and a short side flue; no red and white. The lighthouse has one wide slate band and a pale lantern room; no stripe, no beam. The hall has a ridge lantern. The chapel is the plain chapel. The ledger hall and the crown tower are Rendering's own, from parts that existed, and generic by intent (no real building): Art has not drawn them and Legal has not seen them. **On World's files as they landed on 2026-10-12 (the street grid) the generator places neither:** five landmarks stand. Their looks were seen on the files before the grid, and `shape_check` prints the landmarks of the world it runs on.

## District looks

One facade palette and one window pattern a look (`RenderShapes.LOOK`, Art's hex values). The pattern is numbers the shader reads: a column of windows every so many units, the pane's span in its cell, strips a row, and flags for a clerestory, a door, shutters and door panels.

| Look | Windows as drawn |
|---|---|
| downtown | Continuous vertical glass bands between piers, a floor line every row; tone on tone (the contrast budget) |
| mid_rise | Two horizontal strips a storey; tone on tone (the contrast budget) |
| suburb | A grid of small windows, two or three a facade, a door |
| industrial | A clerestory strip under the roof, door panels along the ground |
| harbour | Few shuttered openings, a door |
| village_harbour | Small square windows with blue shutters, a door |
| village_workshop | Small square windows in brick, a door |
| village_hill | Tiny windows in stone, a door |

- **A floor taller than a row of windows carries several rows.** The sim caps a tower at 62 floors, so the tallest towers have floors nearly 300 units tall; windows stay about 150.
- **From the middle distance every pane is the glass's average,** and from far a wall is the average of wall and glass. A far tower is bands, not a sparkle that shimmers as the camera moves, and a wall does not change value as the camera pulls back.
- **A look World adds later** is drawn in the mid-rise table until Art gives it one; `shape_check` names it.

## The contrast budget (downtown and mid-rise)

**What went wrong.** The first version drew downtown as Art's table reads: pale piers, dark glass. At fight framing that is stripes, a column every 46 units, and once a tower's windows were out the stripes were pale against black. The collapse flash clip went from 2 to 5.5 in reduced mode. The cause was screen shake in a hit-stop: the sim is frozen, the camera moves a few pixels, and 14% of the screen turned brighter and 14% darker on every tick. With the old dark walls it was 1%.

**The rule now** (`RenderLook.PATTERN_BUDGET`, 0.085 of relative luminance; `building.gdshader` 7b), on a look whose windows cover more than three tenths of its wall:
- A pane takes its glass's colour only as far as the budget from its wall. The bands are there, faintly.
- A row whose panes are out has its wall as dark as they are: a burnt-out floor is a dark band, a burnt-out tower is dark.
- The towers are massed in the look's shadow tone (`#4a5261` downtown), so a whole tower and a damaged one are close in value. The lighter tones are trim.
- Lit panes are few and keep their light.

**What it costs the look.** Downtown and mid-rise are dark slate with faint glass and warm lit panes, close in value to the old city, in Art's hues. The pale piers of Art's table are gone from the towers; the Gatebell keeps its pale stone and stands out for it. Art should see this: the alternative is a pale city whose every camera shake counts.

**Measured** (hit-stop of the collapse clip, ticks 1419 to 1426, pixels turning a tick): old look about 8,000 each way; first version about 110,000 each way; with the budget about 9,000 each way.

The collapse clip still fails for another reason, Camera's zoom after a launch: `lanes-camera-flash.md`.

## Row haze

A part takes the air's colour by how far behind the fighter plane its front face stands (`RenderLook.ROW_HAZE`): none on the front block, 0.17 on the back block, 0.44 on the scenery row (with World's three streets the back block stands nearer, and they are 0.14 and 0.49). The colour is the sky's toward the horizon in the pixel's own direction, so it follows the dynamic sky. Fighters, the crowd and the ground are not hazed by it.

## Stages at the new heights: what I see

Stills from the web build, the camera at fight framing in the downtown front street (towers of 60 floors behind the fighters). Seen on the first re-lay. On the shorter city of 2026-10-12 the stages were not looked at again: a tower's top is still far out of the frame (18 fighter heights and more against a frame 8 tall), so the same is expected, and `stage_check` passes.

- **Whole to windows out reads:** the lit panes go out and the slate-blue tower turns near black. It is a step in value, not a pattern, so it holds at any distance.
- **Windows out to a part gone barely reads from the street on a tower.** Stage 2's marks are a sheared top corner, which is thousands of units out of sight, and cracks and broken-open bays (`RenderLook.DMG_HOLES`, added in this work), which are dark on dark. On stone and plaster (the Gatebell, a house) the broken bays are strong.
- **A shell reads by its frame:** thin grey posts and slabs with the dark inside between.
- **A cut floor reads well:** a tunnel three floors tall is a dark opening as tall as seven fighters, and a stepped tower's skirt opens the same floors as its core.
- **Rubble** is unchanged (the ground's heap).
- **A tower's height loss does not read from the street,** for the same reason as the sheared corner: the top is out of the frame.

## The fight at the foot of the towers: what I see

- **The fighters read against the towers.** The ground floors behind them are dark slate with faint glass; nothing in the facade is a fighter's hue.
- **The crowd was what competed,** and is changed: see "The crowd, thinned and muted" below.
- **Sky shows downtown only through a gap** (looked at again on World's shorter, broader city, 2026-10-12). At a close brawl the camera stands 1,170 units in front of the plane and 175 above the street (measured: zoom 1.15 at 720p). The frame is about 8 fighter heights tall and 15 wide on the plane, and its top is about 7 above the street at the front block's face. The shortest downtown tower is 18. So no tower shows sky over it, at any height World could choose. An avenue does, from the far roofs to the top of the frame, and so does a gap between two towers. With World's street grid downtown has five avenues, 11 to 13 fighter heights apart, and a part of one is in the frame at nine tenths of the camera's places (eight tenths in mid-rise). More sky than that is Camera's (a lower camera that looks up) or World's (a low front block).
- **Lit panes are the brightest things behind the fighters** at dusk.

## The crowd, thinned and muted (2026-10-11)

Orb, shown the downtown stills: "Thin and mute it". World thins the number on the fight's sidewalk in data. Rendering's half is how a figure is drawn.

- **Smaller than a fighter.** A figure was 85 units tall against a fighter's 75. It is 59 now, about four fifths of his height (`RenderLook.CROWD_SCALE`).
- **Grey, in its street's colours.** Shirts were eight saturated colours, several of them close to the fighters' lane hues (teal, orchid, coral). Each is now one of eight quiet greys leaned 35% toward its district's wall tone (`CROWD`, `CROWD_DISTRICT`). No tone is a fighter's hue; lane colours stay the fighters' alone.
- **A softer outline** than a fighter's keyline (`CROWD_OUTLINE`).
- **Never larger than a fighter when the camera pulls back.** Figures still grow to stay about 12 pixels tall, but the growth stops at a fighter's own height (`CROWD_BOOST_MAX` 1.25, was 2).
- Runners and startled figures use the same size and colours.

Before and after, the downtown front street and a suburb street at fight framing (review stills, not committed): `img/lanes/crowd-downtown-before.png`, `crowd-downtown-after.png`, `crowd-suburb-before.png`, `crowd-suburb-after.png`.

**What I see.** Downtown the row behind the fighters goes from a band of red, blue, green and orange as tall as they are to small dark figures against the tower's foot, and the fighters are the only colour on the street. In the suburb the figures read as people on a pavement, not as a third and fourth fighter.

## Filling the sim's box (World's rule, 2026-10-12)

The sim's box stays a rectangle, and every blast, shot and flight reads it. A shape used to narrow inside the box (a stepped tower's top tier was 62% of the width), so a fighter could hit air beside a narrow top. Now the shapes fill the box and the silhouette stands on top of it:

- **At the sim's height the walls are 85% of its width or more** (`RenderShapes.FILL`). A stepped tower's top tier is 86%. A crown's chamfer, a stack's taper and a lighthouse's taper end at 86%.
- **What makes the silhouette stands above the sim's height,** as an ornament that does not collide (flag `ORN`): a spire, a crown's gem and stubs, a ridge, a plant box, a lantern room, a flared cap. A fighter flies through it.
- **An ornament is at most 15% of the height** (`ORN_MAX`), so a spire is a cap and never a needle.
- **A gable** has its ridge above the sim's height and its eaves at most a tenth under it. So the box still has air in it beside a ridge: a wedge over each eave, at most a tenth of the building's height (on a house, about 20 units). The ridge stands over the box by at most 15%.
- **No wall is wider than the box.** A roof's eaves overhang by 4% of the width in the re-laid city (13% is allowed).
- **Ornaments go with the caps:** a tower whose top floors are gone has none, and a shell has none.
- **Thin by nature, outside the fill rule, listed for World:** `chapel` (a nave at 72% of the height beside a belfry a quarter of the width), `terrace` (two steps), `crane`, `mast`, `quay`. The hill chapel is the only one in the re-laid city. If hitting air beside its belfry matters, the chapel's box should be the nave's.

`shape_check` asserts all of it: on each shape at three sizes, and on every building of a real world.

## For Art: stand-ins

- Octagonal shapes are four-sided: `chimney`, `lighthouse`, the Gatebell's spire.
- The Gatebell's belfry is a dark band, not four open arches with a bell inside.
- The lighthouse has one band where the brief has two.
- `terrace`, `sawtooth`, `thatch`, `quay`, `crane` and `mast` are built but not in today's data, so they are checked for size only, not seen. So is a plain `crown` (the one crown in the data is the crown tower).
- Doors, shutters and awnings are flat colour.
- The palettes and window numbers are in `shapes.gd`; they belong in data once Art owns a file for them.
- A crossing is plain road: no painted crossing, no stop line.
- The ledger hall and the crown tower are Rendering's looks (see Landmarks), not Art's.

## Checks

- `render/tools/shape_check.gd` (headless, 12 checks): the table is the sim's and fits the shader's arrays (16 strips, 16 districts, 24 avenues); every look has its table; a look of stripes carries the contrast budget; all 20 shapes build with no wall outside the sim's box, fill it near the top, and keep their ornaments to 15% above it; the same on every building of a real world; each landmark in the world has its own treatment; a part scales, is cut off and loses its caps and ornaments as the sim's height says; an instance and a texel for every part; a damaged tower's top is the sim's; a cut tower's skirt opens the same floors; the rows' haze; the ground shader's strips, avenues and block lanes.
- Unchanged and passing: determinism (plain and `--intro`), seam sweep, pane, stage, lane, sky, flash register, hud words, ground, after.
- **Not run:** `cull_check` needs a window. The vertex-stage culling was rewritten for deformed boxes and is judged by the web stills only.
- **Headless Godot compiles no shaders:** the look is proven by stills from the web build in headless Chrome.

## Limits

- **Cost is not measured.** The building fragment shader does more (the look's pattern), and there are about 300 instances (401 on the first re-lay, about 250 before it). The bench waits for a free machine.
- Row 0 is empty in the data. Its buildings would take the same shapes; they have not been seen.
- The world's light at night is not built: lit panes and facades are the dusk values at every hour.
