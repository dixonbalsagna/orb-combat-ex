# The polar outposts: a research station and a mining camp (2026-10-18)

Owner: Art Director. For World (`docs/world/planet-ice.md`; Orb's homework 5 asked for a remote research station on the ice caps, and a mining camp). **Buildings only, no characters.** City and environment art, so it may be public; concept art, working labels, **pending Legal review**; Tools adds the schema. **Sheet:** `art/concepts/world/polar-outposts.svg`. **Data:** `data/art/outposts.json`. Regenerate: `node art/concepts/world/outposts.mjs`.

## What they are
Both are built only from World's existing shapes (prisms and stacks of prisms, no curves: the round things are octagons), in the polar palette (`polar-palette.md`): weathered timber and steel for walls, dark roofs, soot and rock for heaps, the city's one warm lit window colour (steady). Nothing orange (fire's), teal or mid blue.
- **The research station** (760 units wide, 14 parts, about 360 triangles, an estimate): a long main module on posts above the snow (a `slab` on posts), two sleeping modules (a `shed` each), a generator house with a stack (a block with a `chimney`), an instrument mast with a cross yard and two stays (a `mast`), five fuel drums (octagonal), a corridor between the modules and a snow ramp to the main door. A few steady lit windows at night.
- **The mining camp** (900 units wide, 16 parts, about 420 triangles, an estimate): a headframe over a shaft (a `crane` with an octagonal wheel), an ore bunker (a `warehouse` with a shallow gable), a conveyor on posts to a stepped stockpile of dark rock (a stepped block, the darkest and biggest shape on the white), a stack of containers (two over one), three short octagonal fuel tanks, a heater shed with a flue.

## Read on the ice (the world-light ground tint applied, worst case over every key)
The walls (timber, containers) are 14.6 or more from the white at every key and 17 or more from the slate by day; the steel (posts, tanks, small parts) is 11.4 from both, so it carries small areas only; the roofs are 19 from the white and stand against the sky, not the slate. At night everything is dark and a building's base melts into the slate: it stands against the sky, as a real one would. Details are in `data/art/outposts.json` `measured_against_the_ice_dE00`.

## Notes for World and Rendering
- No people and no buildings of any other kind in a polar arena (`planet-ice.md`); an outpost is the one thing there to break, so its parts should break like the city's (the stages), and its lit windows follow the city's rule (steady; a change in the lit share is a flash change measured before it ships).
- A scale bar on the sheet is one fighter (75 units). The station's mast is the tallest part (230 units); the camp's headframe 245.
