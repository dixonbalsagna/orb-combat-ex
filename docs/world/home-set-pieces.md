# Home set pieces: four classes, as layouts (World, 2026-10-23)

Owner: World and Environment. The EP's ask: design the fighters' homes as layouts (names are placeholders: Narrative's Mendquay, Rankhold, Crownreach, Slagholt), built from what World already has, placed by the planet generator, with what can be destroyed, and **build the Cyborg's yard in scratch with a still**. Homework 39's plan: four fixed home set-piece classes per seed. Narrative's wording is `docs/narrative/planet-and-homes.md` §3, the claims are `data/narrative/opponent_grounds.json`, the earlier placement idea is `homes-and-arenas.md` §5. **Nothing here changes main.** The yard is built in scratch (`scratch-build/home-yard/`), seen in `stills/home-yard-in-play.png` and drawn from the generated state in `stills/home-yard-elevation.svg`.

## 1. What a home is

**A home is a place class**: a settlement the planet generator lays with its own plan instead of the town's or the city's, on ground that suits it, with a small recipe for the ground, the wear and the people. Same four classes on every seed, each with a fixed name (Narrative's) that the layout never reads: **names are data, layouts are classes**, so Orb's naming changes a string and nothing else.

**It is built only from parts World already has:**

| Part | What it gives a home | Where it lives |
| :--- | :--- | :--- |
| The settlement generator's districts | a plan: districts along the chord, each with a look, rows in depth (0 foreground to 3 back), a mix of building kinds and shapes, heights and widths in body heights (75 units), gaps, an avenue, landmarks | `data/biomes/settlements.json`, `WorldSettle.generate` |
| The shapes the renderer already draws | shaft, stepped, spire, slab, block, warehouse, sawtooth, chimney, house, shop, thatch, hall, chapel, shed, terrace (two stone steps up a slope), quay (a timber-piled wharf), mast, crane, lighthouse, crown | `render/core/shapes.gd` |
| Landmarks | bell_tower, chimney_stack, lighthouse, village_hall, hill_chapel, crown_tower, ledger_hall (stepped, 46 body heights): bigger, tougher (`hp_mult` 1.5 to 1.8), with their own people | the data's `landmarks` |
| The ground | a settlement's platform (lifted to a floor), the slope as the planet has it, craters, scorch, rubble heaps, cracks; water and the shore | `WorldTerrain`, `WorldCrater`, `WorldWater` |
| Wear | a building brought down leaves a heap; the same state change laid at generation is a ruin | `WorldStructures.collapse` and `_heap` |
| People and traffic | a district's `pop_density` (0 is nobody), the lane vehicles (bike, sedan, van, bus) | `WorldCollateral`, `props.json`, `lanes.json` |

**A class is a data entry**, in the settlement generator's own form, in a **new file `data/biomes/homes.json`** (a Tools schema beside `biomes-settlements`): the archetype (districts and landmarks) plus a small block of recipes (`biome: "keep"`, `people`, `wear`, `terrain`). It is a separate file on purpose: the hand-made world's settlement list and the golden stay as they are; only planet matches read homes.

## 2. Placement

**The planet generator lays each home by a keyed pass after the cities, towns and outposts, so nothing already placed moves** (`homes-and-arenas.md` §5), and the picker's stand-in home for each fighter becomes its class's place (until now the most populous city, the same for every claim).

**What the site rules find** (the strict rules of §5, run over the planet's existing *towns*; planets 1 to 30, 1,122 towns):

| Class | Rule | Towns that qualify, a planet | Planets with at least one |
| :--- | :--- | ---: | ---: |
| Cyborg's yard | desert here, desert on 6 of 8 bearings within 900 units | 8.5 | 30 of 30 |
| Empress's annex | plains here, plains on 7 of 8 within 900, plains or forest on 6 of 8 within 2,600 | 8.0 | 30 of 30 |
| Protagonist's pier | land that is not mountain, sea within 900 on 2 to 5 of 8, land on 3 of 8 within 2,600 | 0.7 | 17 of 30 |
| Rival's stair | mountain here or on 3 of 8 within 900, land on 6 of 8 | **0.0** | **0 of 30** (mountains on 2 of 8 within 2,600: 3 planets) |

**So existing towns will do for two classes, and not for the other two.** The generator puts towns on low, flat, dry ground and never on mountainsides, and rarely right on a harbour. Two ways to place the four, then:

1. **Recommended: homes are a fourth kind of place** (`KIND_HOME`, as `homes-and-arenas.md` §5 proposed, a town-sized disc of 2,440 units) found by a keyed candidate search among sites the planet function scores, **the same four on every seed, one mechanism for all**. §5's measure: all four found by the strict rule on 20 of 24 planets, the worst search 1,581 candidates (about a second of the time-sliced loader's work, a `PlaceJob`), and on the rest the best-scoring site, so a home always exists. The Rival's home is a place *on* a mountainside, which no town is.
2. **Interim (a few days, no new kind): the stand-in.** Give each fighter's class to the best existing town by score: the Cyborg and the Empress take a qualifying town (30 of 30), the Protagonist takes the best coastal one (sea within 2,600 on any bearing: 30 of 30, 7.9 a planet), and the Rival takes the town nearest to mountains and gets the Rank Stair **on flat ground** (the terrain recipe builds the stair itself, §3). The picker's stand-in home becomes the class's town at once. This is what the scratch yard uses.

Both keep these rules: one class to a place; never a polar outpost; deterministic (a pure function of the planet and its seed, so the same planet is the same four homes on every device); the order is scarcest first (Rival, Protagonist, Cyborg, Empress) so a scarce site is not taken by an easy class.

**Golden:** a planet world with homes is a different world, so the planet matches in the golden (Simulation's planet keys) move when it lands; it goes in behind a switch (`homes.on`, off) and Simulation regenerates the planet keys once, as for windows 0 and 1. Versus on the hand-made world is untouched.

## 3. The four layouts

A plan is districts along the chord, in order. The fighters start astride the middle (the home is the touch-down of its own first stage), so **the middle district is the one the fight is in**; the ends frame it.

### 3.1 The Rival's Rank Stair (Rankhold): the high ground

**Reads as:** a town you climb. Tiers of cold grey stone going up and back, each a landing, a standings wall at the top, nothing round: the silhouette is a staircase.
- **Site:** mountainside (§2).
- **Plan:** five **tiers** across the chord, each a `terrace`-house district stepping up (`terrace` is the shape the renderer already draws as two stone steps up a slope) with a `hall` on every landing (the "polished halls"); `row_h` rises with the row (0.5, 0.8, 1.1, 1.4) so the back rows stand over the front. The top district holds the **Ledger Hall** (the `ledger_hall` landmark, stepped, 46 body heights: the wall of standings). Look: `village_hill`, the cold palette.
- **Ground:** `terraces`, a **new World recipe**: the front street's ground is lifted in 5 flat landings (tiers 250 units long, each about 90 units above the one before), blended at the risers, so the fight climbs; on a real slope it follows the slope's grade, on flat ground it is the stair. Biome: its own (`keep`), not the village green.
- **People:** a lived-in town (`pop_density` 0.5 to 0.8), larger around the halls.
- **Needs beyond today:** the `terraces` recipe (World's); nothing from Art or Rendering.

### 3.2 The Empress's Annex (Crownreach): open ground

**Reads as:** a province set down on someone else's world. A flat, wide, clean forecourt, a tall records tower in the middle, two ranks of banner poles down an avenue, long low barracks either side, almost no clutter.
- **Site:** plains (§2); the recipe lifts the ground to one flat platform (the settlement platform, as today).
- **Plan:** **the avenue** (`avenue_bh` 16, twice a town's) is the middle district and the fight: a forecourt with `gap_bh` 12 and **masts** (`mast`, a timber pole with a yard-arm) in two ranks every 10 body heights, rows 1 and 2, about 20 of them (the banners: **the cloth is Art's and VFX's**; the poles stand in for them); the **Records Tower** (`crown_tower` landmark, 52 body heights) at the head of it; **barracks**, long low `warehouse` rows (3 body heights), on both flanks, a few `hall`s. Look: `downtown` toned down, pale stone.
- **Ground:** flat; biome `keep` (plains).
- **People:** the guard and clerks, thin (`pop_density` 0.3); the 3v1 guard line Narrative describes is a director matter, not World's.
- **Needs beyond today:** banner cloth and falling pages (Art for a banner look; VFX for paper as a debris tint, an option on the existing debris).

### 3.3 The Cyborg's Breaking Yard (Slagholt): wreckage, nobody home (BUILT in scratch)

**Reads as:** a place where machines come to be eaten. Low wide bays and wreck-hulks on bare sand, cranes standing among them, a smokestack at each end, heaps where the wreckage has already come down, and **no people at all** (Legal ln04: no bodies and no one in a fallen place; the Cyborg's line stays about wreckage).
- **Site:** desert (§2): 30 of 30 planets have a qualifying town.
- **Plan** (as built; `home-yard/homes.json`, five districts, 21 buildings on a 4,000-unit chord): **bays** (warehouses, sawtooth sheds, a smokestack landmark), **gantries** (cranes, 55 percent of the district), the **hulk field** in the middle where the fight is (low wide warehouses and sheds, 1.6 body heights, set close, with cranes among them), **gantries** again, and the **slag end** (chimneys, bays, a second smokestack landmark).
- **Wreckage:** about half of the buildings are already down at the start, each leaving its heap (the same `collapse` and `_heap` as a fight does). In scratch the hook does it after the match is built (11 of 21 down). **In the real thing it is the same state change laid at generation, quietly** (no debris, dust or shake), from a seeded mask on the plan: a ruin.
- **Ground:** biome `keep` (sand, not the village green), the settlement platform, a few craters (not built yet).
- **People: none.** `pop_density` 0 in every district and the place's people share 0; no civilian, no casualty, no menace or anguish to feed. **An open question for Game Design and Simulation:** a stage's collateral budget and tier ceilings are shares of the people present on the ring; a yard adds none, so a stage fought round a yard takes its budget from the other places on its ring (a Half ring holds 1.4 cities and 2.4 towns, so there are usually some), and a Close ring of the yard alone would have none.
- **What is built:** `home-yard/` has the data (`homes.json`), the scratch hook (`mk_yard.py`), a dump (`yard_dump.gd.txt`) and the picture. `stills/home-yard-in-play.png`: the fight in the yard on planet 5, a Close ring through town 12, sand, a row of warehouse bays, a crane on the right, a heap on the left (the camera is Camera's own; this is the real game). `stills/home-yard-elevation.svg`: the elevation drawn from the generated buildings (11 of 21 down, 0 people, the districts marked).
- **What still reads weak, and whose it is:** the crane draws as a thin pole with a short jib (Art's silhouette: a gantry crane wants a long jib and a counterweight); the hulks are plain boxes (a `hulk` shape: Art), the street the lane generator lays through the yard is paved asphalt where a yard has a dirt track (a `look` for the lanes), and derelict vehicles are not placed (the lane vehicles are driven; a static `derelict` placement is a small addition in `props.gd`).
- **Needs beyond today:** nothing for the plan; the quiet wreck at generation (World's); Art's three silhouettes.

### 3.4 The Protagonist's Mending Pier (Mendquay): the harbour quay

**Reads as:** a working harbour town mid-repair. Sheds and a workshop on a quay, masts and a crane, and a pier that stops halfway, scaffolds standing at its end.
- **Site:** a coast (§2).
- **Plan:** a **quay** district on the water side (`quay`, the wharf with timber piles, along the shore columns), **sheds** and a **workshop** (`hall`, the larger building), **masts and a crane** (the scaffold: masts at regular intervals and one `crane`) at the open end of the pier, so the quay is built for 60 percent of its length and then the scaffold: the half-built pier; a **practice yard** in the middle (a deliberate gap, `gap_bh` 10, nothing in it: the clear ground the fight needs); houses and shops (`house`, `shop`) behind; the `lighthouse` landmark at one end. Look: `harbour`, `village_harbour`.
- **Ground:** the settlement platform and the shore as the planet has it; a place's chord is trimmed to dry ground, so the pier is a wharf on the shoreline. A pier that reaches out over the water would be a `jetty` recipe (a narrow causeway of ground raised just above the water, five columns wide): an option, not needed for the read.
- **People:** a lived-in town (`pop_density` 0.5), the fixer's neighbours.
- **The promise ("the town rebuilds it after the fight"):** not World's state: it is a rule on the run's wear list (a home's wear is dropped when the next stage begins, so Mendquay is whole again). **Game Design and Simulation's question**, and one line in the run state.
- **Needs beyond today:** nothing from Art or Rendering for the read (the masts stand in for scaffold); the `jetty` recipe if Orb wants the pier over water.

## 4. What can be destroyed

**Everything standing, as any building.** A home has no immune part: its buildings take damage by shape and floors, a landmark is tougher (`hp_mult`) and falls last, a collapsed building leaves its heap, the ground takes craters, scorch, cracks and rubble. What differs per class:

| Class | What is special when it goes |
| :--- | :--- |
| **Rank Stair** | The tiers are ground: craters and heaps cut into a landing like any ground (a hit tier is lowered; the stair is never "intact" by rule). The Ledger Hall is a tower: it falls, and the town's standings go with it, which is Narrative's and the director's to dress |
| **Annex** | The banner poles are low-strength (a mast has few floors): they go first, in a line; the Records Tower falls last. Falling pages are VFX's |
| **Yard** | Half of it is already down: the rest comes down into the same sand. No people, so no casualties, no flight, and nothing the picker may count (Legal ln04: it scores wear state, never the toll) |
| **Mending Pier** | The quay and the scaffold go as buildings; the shoreline stays. The rebuild after the fight is the run's wear rule (above) |

**Persistence.** The wear a home takes is the run's wear list, as any place's (`planet-slice-core.md`). The one rule that is new is the Pier's: wear dropped at the next stage. **Legal.** No school, hospital or place of worship appears: the Rank Stair's halls are halls (`hall`), not the chapel shape; the plan uses no `chapel`.

## 5. What it takes, and who

| Who | What |
| :--- | :--- |
| **World** | `homes.json` and its schema; the class hook in `settle` (one lookup: a place with a class takes its archetype, `keep` skips the village biome, people 0 or the place's); the placement pass (`KIND_HOME` or the interim stand-in) and its picker hook (the stand-in home per fighter); the quiet wreck at generation; the `terraces` recipe (and `jetty` if wanted); `derelict` props. About a week of focused work for the data, the hook, the placement and the yard's wreck; the recipes a few days each. Golden: planet keys regenerate once, behind `homes.on` |
| **Art** | Three silhouettes for the Yard (a gantry crane with a long jib, a hulk, a slag heap's look), a banner for the Annex's masts, and a look pass on each home's districts (Narrative's sheets) |
| **Rendering** | Nothing for the read: every shape here is drawn today. A lane `look` (a dirt track) for the Yard |
| **VFX** | Paper as a debris tint for the Annex; nothing else |
| **Simulation** | The planet keys regenerated once; the wear rule for the Pier (drop a home's wear at the next stage's start) |
| **Game Design** | The Yard's collateral budget with no people (§3.3); whether a home is the first stage's home for that fighter and a Proving ground's ground for the opponent (Narrative asked) |
| **Tools** | A schema for `homes.json` (the settlements schema's districts, plus the recipe block) and a case |
| **Narrative** | The site rules (§2) and the names; whether the Rival's home may sit on flat ground in the interim |

## 6. What I would do next

1. The decision in §2: new places (recommended) or the interim stand-in. The yard works on either.
2. Park `homes.json`, its schema and the `settle` hook (golden unchanged: it only reads when `homes.on`), with the Yard as the first class and `homes.on` off.
3. The quiet wreck at generation, then the Annex (data only), then the Pier (data only), then the Stair (needs `terraces`).

Files: `scratch-build/home-yard/` (`mk_yard.py`, `homes.json`, `yard_dump.gd.txt`, `yard_svg.py`, `site_count.gd.txt`, `site_find.gd.txt`), `stills/home-yard-in-play.png`, `stills/home-yard-elevation.svg`.
