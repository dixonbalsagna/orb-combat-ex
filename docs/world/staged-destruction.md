# The front-row hybrid, staged destruction and ground materials: plan and measurements

Owner: World and Environment. Status: plan with scratch measurements, 2026-10-04, on 9fcdf87. Nothing is in the tree. Orb's answer on the front-row ceiling: "hybrid of 2 + 3, pavement should crack and shatter differently from dirt, can windows shatter + multiple levels of dynamic destruction per building" (2 = cut the top tier's reach into buildings, 3 = soften landing blasts).

## 1. The hybrid, measured (160 matches a setting, seeds 1 to 160, default arm, 9fcdf87)

Shares at the KO of the front row (row 1) and of all rows; civilians lost; structures lost a minute at tier 4 (all rows, front row; band 6 to 20% all rows); C1 (QA's rolling 60 s budget at tier 1 and 2) failures. `reach` is `ladder.reach.structure[3]` in both fighters' `ladder.json` (2.8 today), `slam` is `area.slam` in `data/biomes/contact.json` (0.9 today).

| reach / slam | Front row | All rows | Civilians | Tier 4 a minute (all / front) | C1 |
| :--- | ---: | ---: | ---: | ---: | ---: |
| **2.8 / 0.9 (today)** | **52.1** | 40.6 | 23.9 | 10.15 / 12.88 | 0 |
| 2.8 / 0.6 | 49.6 | 38.6 | 23.7 | 9.86 / 12.53 | 0 |
| 2.4 / 0.6 | 49.3 | 38.2 | 23.6 | 9.52 / 12.16 | 0 |
| 2.0 / 0.9 | 49.0 | 38.1 | 22.8 | 9.12 / 11.60 | 0 |
| 2.0 / 0.75 | 48.0 | 37.3 | 22.7 | 9.12 / 11.60 | 0 |
| 2.0 / 0.6 | 47.9 | 37.2 | 23.2 | 9.17 / 11.71 | 0 |
| 2.0 / 0.5 | 48.1 | 37.5 | 23.5 | 9.14 / 11.63 | 0 |
| 2.0 / 0.45 | 47.5 | 37.1 | 23.7 | 9.17 / 11.62 | 0 |
| 1.8 / 0.9 | 48.0 | 37.2 | 22.6 | 8.59 / 10.93 | 0 |
| **1.8 / 0.75** | **47.7** | 37.0 | 22.2 | 8.75 / 11.18 | 0 |
| 1.8 / 0.6 | 46.8 | 36.3 | 22.8 | 8.62 / 11.02 | 0 |
| 1.6 / 0.9 | 46.1 | 35.6 | 22.1 | 8.16 / 10.42 | 0 |
| 1.6 / 0.75 | 45.9 | 35.5 | 21.7 | 8.42 / 10.78 | 0 |
| 1.6 / 0.6 | 44.5 | 34.3 | 22.1 | 8.16 / 10.50 | 0 |
| 1.3 / 0.9 | 44.3 | 34.1 | 22.1 | 7.77 / 9.97 | 0 |

Noise at 160 matches is about 1.5 points. **Reading.** Reach is the stronger lever: 2.8 to 1.8 alone takes the front row from 52.1 to 48.0, and slam below 0.75 buys about one point more for each 0.15, almost nothing once the reach is at 2.0 or less (2.0 / 0.6, 0.5, 0.45 are the same 48 within noise). The pair that puts the front row at 45 to 50 with the least loss of a slam's read: **reach 1.8, slam 0.75** (47.7%, all rows 37.0, civilians 22.2, tier 4 at 8.75% a minute, all in band, C1 clean). A softer slam than 0.75 is not worth its read. Reach 2.0 with slam 0.75 (48.0) is as good if Orb would rather the tier-4 reach stay wider. Tier 1 to 3 rates do not move with the reach (it only grows at tier 3 and 4; tier 3 at 4.27 to 4.48% a minute).

**A third lever that makes stages (not part of the pair): a blast cannot finish a standing building.** `damageArea` (every blast but the beams and the launches' brunts) may not take a building below a share `leave` of its hit points; the next blast finishes it. A landing then wrecks what it hits and leaves it standing as a wreck, and the front row falls without the slam's radius or damage changing (prototype in scratch: 4 lines in `damageArea`, one data number):

| reach / slam / leave | Front row | All rows | Civilians | Tier 4 a minute (all) |
| :--- | ---: | ---: | ---: | ---: |
| 2.8 / 0.9 / 0.15 | 41.1 | 32.0 | 24.5 | 9.07 |
| **2.8 / 0.9 / 0.25** | **44.3** | 34.4 | 24.0 | 9.86 |
| 2.8 / 0.9 / 0.40 | 42.0 | 32.4 | 23.2 | 9.73 |
| 2.8 / 0.75 / 0.25 | 44.0 | 34.2 | 23.8 | 9.69 |
| 2.4 / 0.9 / 0.25 | 41.6 | 32.4 | 23.3 | 8.93 |
| 2.0 / 0.9 / 0.25 | 40.1 | 31.2 | 22.4 | 8.74 |

With `leave` 0.25 the reach and the slam can stay as they are (44.3, just under the target band's foot, in the 25 to 50 band), the tier 1 and 2 rates halve (0.14 and 0.88% a minute, ceilings 2 and 4) and tier 4 does not move. Combined with the pair it undershoots (1.8 / 0.75 / 0.25 gives 38.8). So it is a choice, not an addition: the pair, or `leave` about 0.25 with the old reach.

## 2. Staged building destruction

**What a building is today.** `SimState.Building`: `x, w, h, d, z, row, kind, maxhp, hp, alive, pop, popAlive, seed, floors, fmask, fdmg` (lazy, per floor), `fled`. A building is `alive` or not; `hp` runs down and the standing height follows it (`curH`: 30% of the height at hp 0 for a house, the top standing floor for a skyscraper whose floors are cut). Floors (5 or more) are cut by a brunt or a shot (`fmask`). At hp 0 it is gone: the rubble heap, the `building_fall` event. Rendering reads `curH`, `alive`, `fmask` (the cut floors) and VFX's windows list (blown windows, pruned after 6 s). So there are two real states, standing and gone, with a shrinking height between.

**Where damage sits at the KO (40 matches, current build; stages by the fraction of hit points lost, intact under 10%, light under 35%, part under 65% or any floor cut, shell above, gone).** All rows: intact 48.6%, light 4.5%, part 3.6%, shell 5.9%, gone 37.4%. Front row: 36.5, 5.3, 3.6, 6.4, 48.2. **Damage is nearly binary: 85% of buildings are either untouched or gone,** because a blast does far more than a building's hit points (a landing 90 to 400 against a house's 160). The hybrid of section 1 does not change that (2.0 / 0.6: shell 7.5, gone 35.5). The `leave` rule does: `leave` 0.25 gives intact 44.4, light 3.9, part 3.8, **shell 14.6**, gone 33.3 (front row shell 17.3); `leave` 0.4 gives part 12.0, shell 4.1; `leave` 0.15 shell 19.2.

**The design: four stages, derived, no new state.** A pure function `WorldStructures.stage(b) -> int`:

| Stage | Name | By |
| :--- | :--- | :--- |
| 0 | Intact | hp at least 90% and no floor cut and no blown windows |
| 1 | Windows out | hp under 90%, or its windows blown (the shock record below) |
| 2 | A part gone | hp under 65%, or any floor cut (`fmask`), or a corner sheared (the render's reading of `fdmg`) |
| 3 | A shell | hp under 35%: the frame is bare, the standing height at its floor of 30 to 45%, the inside seen |
| 4 | Rubble | `alive` false (today's loss) |

The thresholds are data (`data/biomes/stages.json`, `biomes.stages/1`: `hpAt` [0.9, 0.65, 0.35]). **Sim state or a render reading? A function of the hashed state, so both:** the function is World's and pure; Rendering calls it every frame for a seek or a late join (nothing to save, nothing to hash), and the sim emits **one event on a change of stage**, so VFX knows when to burst glass, shed panels, drop a floor of debris: `building_stage {b, from, to, x, y, z, w, h, kind, cx, owner, n}` (`cx` the blast's x, `n` the floors lost in the step), sent by `damageBuilding` and the floor paths (`applyFloors`, `shotBuilding`) when the stage before and after differ. The cost is no state at all, one field list for the event in `hash.gd` (Simulation's) and about 40 lines in World; `stage()` is under a microsecond and there are at most four events a building, about a hundred buildings a match.

**Windows.** Two sources, both already in the design: damage windows (the facade of the floors a building has lost goes with them) need no record; **shock windows** (a crater's blast waves blow glass without hurting the building: VFX's list today, pruned) need the record of `window-blowouts.md`: `Building.wmask` (one integer, one bit a floor), hashed, set by `WorldStructures.blowWindows` from the crater, 196 integers of state, two lines in `state.gd` and `hash.gd` (a grant). With it, "windows out" (stage 1) holds across a seek and across a late join.

**Does a staged building count as lost? No.** `structuresLost` and QA's front-row share stay as today: a building is lost at stage 4. A new QA measure, **wrecked** (stage 3 or 4, from `stage()` at the KO), is for the new bands; if Game Design wants the ceiling to read wrecks, that is their number. The `leave` rule makes the two diverge on purpose: front row lost 44.3% with 17.3% more standing as shells.

**Behaviour a stage may carry later (not in the first slice, Game Design's call):** a stage 2 or 3 building takes more from the next blast (the weakened frame, x1.25), a shell's people are evacuated at the step (so wrecks do not hold a population), the casualty window counts the step's kills as it does today.

## 3. Ground material: pavement against dirt

**What exists.** `WorldContact.surfaceAt(S, x)` already classes every column: rubble heap, paving (inside a paved biome, city and village, and not dug below -3 units), the biome's own (soil, sand, rock). It is a derived query (a byte per column built from the biome at world generation, not saved state), and the brake and the tumble rule already differ by surface (`surfaces` in `contact.json`: paving brake 0.8, no tumble; soil and sand 1.3; rubble 1.3 and tumbles). Events carry it: `slide_dust` has the surface name, the slide event a `paved` or `ground` variant. The crack paint (`S.crack`, hashed, one float a column) exists and is written only by the knockback slide. **How much ground is paving (30 matches): 19% of craters (179 of 926) and 10% of slide samples (158 of 1,514)**, so about 6 craters and 5 skids a match.

**The material as a data table, not a flag.** The surface class stays derived from the biome (and, when the districts of D1 land, from its street columns: a paved street between buildings against the garden or the field, still a derived byte, no new saved state); what changes is what each surface does, as data: `surfaces.<name>` gets `digMul` (the bowl's depth), `radiusMul`, `crackR` (the crack paint's reach in crater radii), `rimBreak` (the rim's height share, the rest thrown as slabs), `furrowMul` (a skid's trench), `bounceMul`, `chips` (debris count and kind). First values to measure: paving `digMul` 0.8, `radiusMul` 1.15, `crackR` 1.8, `rimBreak` 0.6, `furrowMul` 0.5, `bounceMul` 1.15, chips x2 slabs; soil the reference (all 1.0, `crackR` 0); rock `digMul` 0.6, `crackR` 1.4; sand `digMul` 1.15, no crack, a lip that slumps.

**What each does differently on pavement.**
- **A crater** digs a shallower, wider bowl (the surface is hard), writes the crack paint out to 1.8 radii in a star (the cracked ring Rendering draws), throws broken slabs from the rim rather than a berm (lower rim, more and angular debris), and the floor of a bowl dug past -3 units is dirt (today's `dugBelow`: the pavement is gone there). On dirt: a deeper bowl, a smooth berm, soil debris, no cracks.
- **A skid** on pavement leaves a shallow scrape and a spray of chips and sparks (the surface name already goes to `slide_dust`; add the crack paint along the path at a low intensity, so a dragged body cracks a street), brakes less (0.8). On dirt: a deep furrow with a berm (today).
- **A landing** (a slam or a bounce) on pavement bounces higher (hard ground), digs less, and shatters: a ring of cracks from the contact and slabs thrown; on dirt it digs and sinks.

**Render and VFX.** A query: `WorldContact.surfaceAt(S, x)` (already there), plus the events: the `crater` event gets `surface` (today it has none; the existing `paved` variant belongs to the slide event) and `crackR`; `slide_dust` already has it; the landing events get `surface`. Rendering reads `S.crack` for the cracked paving it already reads for the knockback slide. Windows: the shock record above. Two new event fields, no new event.

**Cost.** State: none new (the byte per column is derived; `S.crack` exists and is hashed). Code: the `surfaces` keys read in `crater.gd` and `contact.gd` (about 50 lines), the crack write in `dig`. Goldens: any dig on paving moves.

## 4. The first slice, small enough for one window

**Slice 1 (one window, one golden regeneration): the pair and the stage function.**
1. Data: `ladder.reach.structure[3]` 2.8 to **1.8** (both fighters) and `area.slam` 0.9 to **0.75**: front row 52.1 to 47.7% (160 matches), all rows 40.6 to 37.0, tier 4 8.75% a minute, civilians 22.2%, C1 clean. No code.
2. `WorldStructures.stage(b)` and `data/biomes/stages.json` (`hpAt` [0.9, 0.65, 0.35]), and the `building_stage` event sent from `damageBuilding` and the floor paths. Needs from Simulation (a grant): the event's name and field list in `fx.gd` and `hash.gd`; from Tools: the schema `biomes.stages/1` and the event in `fx-events.md`; from Rendering and VFX: read `stage()` and the event (they can start on the function the day it lands).
3. QA: the measure "wrecked share at the KO" (stage 3 or 4) beside the lost share.
**Goldens:** one regeneration. The data pair changes every match with a blast near buildings (all nine golden matches and the replays move); the stage event adds events to the stream and nothing to the state. Gates: `npm test --prefix sim`, probe, the new checks (`stagecheck.gd`: stage thresholds by hp, floor cut, a blast that crosses two thresholds sends one event with `from` and `to`, no change on a miss), validate.

**Slice 2: the stage cap (`area.leaveFrac`, 0.25) in place of the pair, or after it with the pair loosened.** Four lines in `damageArea`, one number in `contact.json`; gives the shells (14.6% at the KO against 5.9%) and the front row at 44.3 with the old reach and slam. One regeneration. Decision for Orb with the numbers above.

**Slice 3: the ground materials.** The `surfaces` table keys, the crack write in `dig`, `surface` on the `crater` event, the landing event; measured on the 19% of craters on paving. One regeneration.

**Slice 4: the window record (`wmask`).** The plan in `window-blowouts.md` (grants: `state.gd`, `hash.gd`). One regeneration, no change to matches.

Slice 1 first (it answers Orb's front-row question and gives Rendering the stage function at once); slice 2 if Orb prefers stages to a smaller reach; 3 and 4 are independent of both.

## 5. Open points

- Game Design: whether a wreck (stage 3) takes more damage, whether its people evacuate at the step, and whether the front-row ceiling (25 to 50) should count wrecks.
- The `leave` rule leaves a building at 25% hp after one blast whatever its size; a skyscraper (hp 1,800 to 4,000) is rarely finished by one blast anyway, a house (160) always was. A share by kind (houses 0.25, towers 0) is possible if the towers should not change.
- The beams (32% of front-row kills at the last count) are outside every lever here: their tier gate is the fighter ladder's data.
- Measured on seeds 1 to 160, default arm only; QA's re-baseline decides the final pair.

Scratch: `hy.gd` (the hybrid measure), `stg.gd` (the stage mix at the KO), `mk_hv.sh` and `mk_leave.py` (the settings and the `leave` prototype), `mat.gd` (the paved shares) are in `docs/world/scratch-build/staged/`.

## 6. Slice 1 built in scratch (2026-10-04), and the list for VFX and Rendering

**Built and proven in a scratch copy of a995d16** (`docs/world/scratch-build/stage1/`: `mk_stage1.py` applies it to any tree, `stagecheck.gd`, `stages.json`). On the scratch copy: golden regenerated once, `npm test --prefix sim` 5 of 5, `probe.gd`, `probe_rows.gd`, `directcheck.gd`, `minecheck.gd`, `blastcheck.gd`, `stagecheck.gd` 0 failed, render determinism and the seam sweep pass, `node tools/validate.js` 0 errors and one warning (`stages.json` has no schema yet: Tools'). 100 matches, HEAD against slice 1: length 465.3 against 471.6 s, civilians 24% against 23%, structures 79.4 against 73.2 of 196, craters 34 against 35; 160 matches: front row 47.7%, all rows 37.0%, civilians 22.2%, tier 4 at 8.75% a minute, C1 clean (as section 1); stage mix at the KO (40 matches): intact 53.2%, windows out 2.8%, part 2.2%, shell 7.3%, rubble 34.5% (front row 41.8, 3.1, 2.1, 8.5, 44.5).

**Lines touched in Simulation's files (the grant):**
- `sim/core/fx.gd`: one function, `buildingStage(S, b, from_, to_, cx, owner, n, h)`, 7 lines, before `floorHit`.
- `sim/core/hash.gd`: one entry in `FX_FIELDS`: `"building_stage": ["b", "from", "to", "x", "y", "z", "w", "h", "kind", "cx", "owner", "n"]`. Every field already exists on `FxEvent`; `state.gd` is not touched.
- `sim/core/replay.gd`: one line in `dataHash()`: `h.text(WorldStructures.stagesHash())`.
- `sim/core/view/fx.gd`: `"building_stage"` added to the list of events the view passes over (one token; without it the view reports an unknown event).
World's: `structures.gd` (the loader, `stage`, `stageEmit`, the emission in `damageBuilding` when it is not a collapse called by a floors path), `brunt.gd` (`applyFloors` reports its stage change once; `_bits`), `blast.gd` (a shot's floors hit reports once), `data/biomes/stages.json`, both `ladder.json` (`reach.structure[3]` 1.8), `contact.json` (`area.slam` 0.75), `sim/world/tools/stagecheck.gd`, `golden.json`. Tools': the schema `biomes.stages/1` and its line in `tools/schemas/map.json`, the event in `fx-events.md`.

**For VFX and Rendering: the stage queries and events.**
- *Query, any time, seek-safe:* `WorldStructures.stage(b)` gives 0 intact, 1 windows out, 2 a part gone, 3 a shell, 4 rubble, from the building's hashed state; `WorldStructures.curH(b)` is the standing height, `b.fmask` the standing floors (a skyscraper), `b.fdmg` the damage on each floor, `b.hp / b.maxhp` the rest. Nothing about a stage is stored, so a replay seek or a late join reads the right look from the state.
- *Event, once a change:* `building_stage {b, from, to, x, y, z, w, h, kind, cx, owner, n}`: b the building's index (`S.buildings[b]`), from and to the stages (a blow past two thresholds is one event, 1 to 3; a building levelled at once 0 to 4), x its centre, y its ground, z its depth, w its width, h its standing height after the change, kind `house` or `tower`, cx the x of the blast or hit (glass and panels fly away from it), owner the causing fighter's slot, n the floors lost in the step (a skyscraper hit). To 4 it is sent beside `building_fall` (the fall's detail stays there).
- *Suggested reads (theirs to choose):* stage 1, the windows blow out (a glass shower from the floors that face `cx`; the shock record of section 2 will make this survive seeks); stage 2, a sheared corner or the cut floors (`floor_hit` and `floors_fall` carry the detail); stage 3, a shell: cladding stripped, the dark inside seen, smoke; stage 4 as today.
- *Slice 3's additions (not built):* the query `WorldContact.surfaceAt(S, x)` (exists today: paving, rock, soil, sand, rubble); `crater` gains `surface` and `crackR` (the cracked ring in crater radii); `land`, `bounce` and `slide_dust` already carry the surface name; Rendering already reads `S.crack` for cracked paving (the knockback slide writes it; craters and skids on paving will write it too).

## 7. Slice 2 measured: a gentle stage cap on a relaxed pair (scratch on HEAD a995d16, 160 matches each, shells on 40)

The cap (`leave`: one blast cannot take a standing building below that share of its hit points; beams and brunts excluded) with the reach and slam relaxed. Front row and all rows at the KO, civilians, tier 4 a minute (all rows), and the share of buildings in stage 3 (a shell) at the KO, all rows / front row. C1 is clean in every run.

| reach / slam / leave | Front row | All rows | Civilians | Tier 4 a minute | Shells (all / front) |
| :--- | ---: | ---: | ---: | ---: | ---: |
| 2.8 / 0.9 / none (today) | 52.1 | 40.6 | 23.9 | 10.15 | 5.9 / 6.4 |
| 1.8 / 0.75 / none (slice 1) | 47.7 | 37.0 | 22.2 | 8.75 | 7.3 / 8.5 |
| 2.0 / 0.9 / 0.10 | 39.4 | 30.6 | 23.7 | 8.78 | 14.3 / 17.1 |
| 2.2 / 0.9 / 0.10 | 39.9 | 31.0 | 24.4 | 9.09 | 15.4 / 18.3 |
| 2.2 / 0.9 / 0.15 | 38.4 | 29.7 | 23.9 | 8.04 | 17.9 / 21.6 |
| 2.4 / 0.9 / 0.10 | 41.1 | 31.8 | 24.7 | 9.27 | 15.9 / 18.8 |
| 2.4 / 0.9 / 0.15 | 39.1 | 30.4 | 23.6 | 8.34 | 19.2 / 23.1 |
| **2.8 / 0.9 / 0.10** | **42.2** | 32.9 | 25.3 | 9.50 | **16.1 / 19.3** |
| 3.2 / 1.0 / 0.10 | 44.7 | 34.7 | 25.1 | 10.11 | 14.8 / 17.3 |
| 3.6 / 0.9 / 0.10 | 44.9 | 34.9 | 26.2 | 10.11 | 17.7 / 21.3 |

**Reading.** The cap is a switch more than a dial: any `leave` from 0.10 to 0.40 turns "one blast kills" into "two blasts kill" and takes about 10 points off the front row, so a relaxed pair does not leave it at 45 to 50: every setting with reach 2.0 to 2.4 lands at 38 to 41%, under the band's foot (25 to 50 is the band; 45 to 50 was the target). **What it gives that the pair does not is the stages:** shells at the KO go from 5.9% to 14 to 19% of all buildings (6.4% to 17 to 23% of the front row), and the buildings that are left standing are wrecks. To bring the front row up to 45 with the cap the reach has to go **up** (3.2 to 3.6 with slam 0.9 to 1.0 gives 44.7 to 44.9, civilians 25 to 26%), which is the opposite of Orb's "cut the reach". **Recommendation: if Orb wants the stages, `leave` 0.10 with the reach and slam as they are today** (2.8 / 0.9 / 0.10: front row 42.2%, all rows 32.9%, tier 4 at 9.5% a minute, civilians 25.3%, shells 16.1%): under the ceiling of 50 with the slam's read untouched; the pair of slice 1 then stays out. If Orb wants both a lower reach and the stages, the front row falls to 38 to 40, and the lever to bring it back is a higher slam, not a lower one. Either way the stage function and event of slice 1 are the same; the choice is two data numbers (`reach.structure[3]` and `area.slam`) and the cap's one (`area.leaveFrac`, with its 4 lines in `damageArea`).
