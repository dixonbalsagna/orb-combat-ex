# The reworked arenas: where the band, the depth rows and the districts stand (status, 2026-10-11)

Owner: World and Environment. Written for the EP's answer to Orb ("I want to see the reworked arenas when they are ready": the band the fighters travel, extra Z-axis space for engaging and believable building layouts and destruction). Docs and scratch only; nothing here changes the tree. Sources: `fight-lanes-world.md`, `buildings-in-depth.md`, `districts-plan.md`, `lanes-remeasure-plan.md`, `staged-destruction.md`, `docs/architecture/fight-lanes.md`.

## a. Where each piece is

| Piece | State today | Where |
| :--- | :--- | :--- |
| **Buildings in depth (B2)**: every building has a row (0 foreground, 1 front street, 2 mid, 3 back), a depth `z` and a footprint depth `d`; brunts fly into row 1 and 2 buildings, punch or crack floors of a skyscraper, chain through up to four, pancake a cleared span | **Committed and running.** The city is the old layout: 196 buildings (59 houses, 137 towers), rows 11 / 80 / 66 / 39 | `sim/world/brunt.gd`, `structures.gd`, `terrain.gd` |
| **Staged destruction**: four stages derived from hit points and cut floors, the `building_stage` event, a blast cannot finish a standing building (`leaveFrac` 0.10), the hybrid of reach and slam, shots meeting buildings, point-clear read for the zip | **Committed and running**; Rendering and VFX draw every stage | `sim/world/structures.gd`, `data/biomes/stages.json`, `docs/world/staged-destruction.md` |
| **Depth plumbing and depth in the core (L0, L2)**: every position carries `z`, fighters ease to a target depth, `S.depthOn` | **Committed, switched off** (`depthOn` false; a setup may force it) | `sim/core/`, `fight-lanes.md` sections 14 to 15 |
| **Terrain rows (T)**: the ground is a heightfield per depth row, so a crater or a heap has a depth extent | **Committed, dormant** with `depthOn` off | `sim/world/terrain.gd`, `crater.gd` |
| **Settlements and districts data and generator (D1's first half)**: `settlements.json` (looks, shapes, landmarks, districts), `WorldSettle` generates a city as plain dictionaries | **Committed, not wired**: nothing in genWorld calls it | `sim/world/settlements.gd`, `data/biomes/settlements.json` |
| **Rendering's lane stand-in**: `RenderLanes` builds the lane table from today's buildings so streets and the lane cue can be painted | **Committed**, draws a stand-in | `render/core/lanes.gd` |
| **L1 with D1: the lane table and the re-laid city** (`lanes.json`, `S.lanes`, 186 buildings in districts: suburbs, industrial, mid-rise, downtown, villages, harbour; four rows; streets clear by construction; landmarks) | **Scratch only, rebased and proven on HEAD** (probes pass, `npm test` 5 of 5 on the scratch copy); one anchor changed since it was first built | `docs/world/scratch-build/d1/`, `l1d1/` |
| **L3: true collisions** (swept footprint test for bodies, blasts by plan distance) behind `depthOn` | **Scratch only**, applies on top of L1 with D1, neutral with `depthOn` off | `docs/world/scratch-build/l3/` |
| **The rulings for the lanes window** (population references scale with the people, a damaged floor counts for stage 2, the core cap 0.5) | **Ruled by Game Design; measured in scratch; not applied** | `lanes-remeasure-plan.md` sections 5 to 8 |
| **L4: the switch-on** (the director plans depth; collisions on) and **L5: beams in depth** | **Planned** (Encounter) | `fight-lanes.md` section 5 |
| **P1: props and traffic as blockers on the lanes** (cars, bikes, foot traffic) | **Planned** | `fight-lanes-world.md` |
| **Ground materials** (pavement cracks and shatters differently from dirt) and **the window record** (`wmask`) | **Planned**, designed (`staged-destruction.md` sections 2 and 3, `window-blowouts.md`) | |

**The band, in numbers (`data/biomes/lanes.json`, scratch):** 32 fighter heights deep (5 to -27), a front street of 9, a block row of 8, a back street of 6, a second block row of 9, scenery behind (row 3, 8 deep) and a foreground row (row 0, 5 deep) in front of the band; a sidewalk, kerb parking and a carriageway in each street. Bellgate is about 23,000 units long (310 fighter heights) with 3 avenues across its blocks (10 in all the settlements).

## b. The shortest path to something Orb can look at

**Now, from World alone (done, in `docs/world/stills/`):** the plan of the re-laid city (`bellgate-plan-overview`), one downtown block's plan and elevation (`bellgate-plan-downtown`, `bellgate-elevation-downtown`), the five stages of a house, a mid-rise and a tower (`bellgate-stage-strip`) and a staged-destruction sequence on one real downtown block taken from the sim (`bellgate-stages-0` to `3`). They are diagrams from the sim's own data, not Rendering's look. **They are for Orb's review here; none for a public page** (and none shows a tower falling or shedding glass: stages are still states).

**A build or stills with Rendering's look** (the district with the band, rows in front and behind, staged destruction in depth):

| # | Piece | Owner | Size |
| :--- | :--- | :--- | :--- |
| 1 | The lanes window: apply L1 with D1 (and the three rulings), regenerate the golden once, gates, re-measure | World, in the sim tree when it is free (Simulation's lines are granted); Tools for the `settlements.json` and `lanes.json` schemas | about half a day; the schemas an hour |
| 2 | District looks and building shapes in the renderer: the shapes `settlements.json` names (slab, block, shaft, stepped, spire, chimney, warehouse, house, shop), per-look facades, the row fog, the lane strips painted from `S.lanes` instead of the stand-in | Rendering (Art for the shape set if it is not drawn) | 1 to 2 days |
| 3 | Camera framing for the band: show rows 0 and 3 as scenery, keep the fighters in the street canyon, handle the foreground row so it never hides the fight | Camera | about 1 day |
| 4 | Staged destruction in the new city: stage reads per shape, a cut floor on 62-floor shafts, a shell for a stepped tower | Rendering and VFX (their stage work exists) | half a day to a day |
| 5 | A web build or a set of stills from a scratch copy (the web stage recipe) | Rendering, with World's scratch copy | half a day |

Fighters stay on one plane for a first look (depth is not switched on): the city is in depth, the fighters in the front street. Seeing the fighters travel the band needs L3, T (in) and L4 (Encounter's director): a later step with its own measures (the probe set exists).

## c. What needs Orb's eye or ruling before building

1. **Scale.** Downtown towers in the data have a median of 62 fighter heights (4,650 units) up to 150 for the landmark spire; a fighter is one sixtieth of a tower. The elevation still shows it: the fight is a canyon at the foot of walls. Is that the intended believability, or should downtown be 20 to 40 fighter heights with a few landmarks, so that the fight reads against the buildings? (It changes `height_bh` in `settlements.json`: data, no code.)
2. **How much depth.** The band is 32 fighter heights deep, two streets of 9 and 6. Is that the "extra Z-axis space" Orb means, wider (more block rows, so fighters can cross a block), or narrower (a clearer silhouette)?
3. **What may be destroyed in front of the band.** Row 0, the foreground, stands between the camera and the fight. Destroyable like any row, never destroyable (it would be a hole in the camera's view), or ghosted when it covers the fight?
4. **Layout believability.** Regular blocks and avenues (what the stills show) against a less regular layout; the district mix (suburbs, industrial, mid-rise, downtown; two villages, a harbour). The stills are the thing to judge.
5. **Cars, bikes and foot traffic** (ADR 0009's "believable city blocks") are P1, planned and not built: needed for the first look, or after?
6. **Stages in depth.** How much of a building's destruction shows through the rows behind it (a shell seen through a gap)? And the standing rule: towers never fall or shed glass in public pictures; buildings break in stages. Internal stills may show the state diagrams.
7. **People.** The re-lay multiplies the starting population by 4.6 (390 to 1,800); the share is the same. How the toll is shown to the player (a count, a share) is Orb's, with Legal.

## d. What I did not change

No edits to `sim/` or `data/` in the shared tree. The scratch copy (HEAD with L1 with D1 and L3) is mine; the scripts that make the stills are in `docs/world/scratch-build/stills/` (`lanesview.gd` dumps the city and the sequence from the sim, `mk_stills.py` draws the SVGs; run `lanesview.gd` in a scratch copy with L1 with D1, then the script).
