# The lanes window: what is ready and what the re-lay moves (re-measure plan)

Owner: World and Environment. Status: scratch only, 2026-10-05, measured on HEAD b6a7e47. Nothing here is in the tree. The window is L1 with D1 (the lane table and the city re-lay) and then L3 (true collisions), both switched off in play as planned; the EP names it after the fighter rename.

## 1. The rebase is ready

- `docs/world/scratch-build/d1/d1_window.py` and `d1_window.diff` are rebased on b6a7e47. Two changes were needed: the building hash list now ends `"floors", "fmask", "wear"` (the shots window), and **`building_fall.landmark` is a bool** (Game Design's `mood.gd` already reads `e.get("landmark") == true`; with a float every golden match throws a script error). The diff dry-runs clean on a fresh export of HEAD; the README has the order and the notes.
- `l3.diff` (and `l3.diff.new`, re-diffed) applies on top with offsets only.
- On a scratch copy of HEAD with L1 with D1: `probe.gd`, `lane_check.gd` (186 buildings, no footprint outside its lane, no building across an avenue), `stagecheck.gd`, `blockcheck.gd`, `directcheck.gd`, `minecheck.gd` 0 failed; the golden regenerates with no script error; `npm test --prefix sim` 5 of 5. With L3 added: `probe_collide.gd` 0 failed and `npm test` 5 of 5. **L3 with `S.depthOn` off is neutral: 30 matches give the digest of L1 with D1 alone** (aa093466e244dd25 both). L1 with D1 is not neutral: the layout is `settlements.json` `enabled` true (false keeps today's layout and the light digests).
- Work left for the window itself: apply, `--import`, regenerate the golden once, the gates, the re-measure of section 3 (about half a day with QA's re-baseline), and Tools' schema for `settlements.json` and `lanes.json` (the validator rejects the data until it lands).

## 2. What the re-lay changes (a scratch copy of HEAD with and without L1 with D1, 100 matches on the default arm, seeds 1 to 100)

| | HEAD today | With L1 with D1 |
| :--- | ---: | ---: |
| Buildings | 196 (houses 59, towers 137) | 186 (houses 97, towers 89) |
| By row 0 / 1 / 2 / 3 | 11 / 80 / 66 / 39 | 17 / 65 / 65 / 39 |
| Mean height by row 1 / 2 / 3 | 1,773 / 2,393 / 3,825 | 2,439 / 2,693 / 4,505 |
| Tallest (floors) | 38 | 62 |
| Population at the start (`pop0`) | 390 | 1,800 |
| Reached from the fight plane by a blast or a shot (nearest face within `Z_REACH`) | 157 (rows 0 to 2) | 147 (rows 0 to 2) |
| Front row lost at the KO | 40.4% | 39.7% |
| All rows lost | 31.0% | 31.5% |
| Civilians lost (share) | 22.9% | 25.4% (people lost 99 against 488 a match) |
| Tier 1 / 3 / 4 structures a minute (all rows) | 0.06 / 3.60 / 6.76% | 0.03 / 3.38 / 7.21% |
| Shells at the KO, all rows (front row) | 13.0% (15.0%) | 11.4% (14.5%) |
| Buildings with a cut floor a match | 1.1 | 0.1 |
| Shots ending on a building (40 matches, a match) | 6.4 | 7.9 |
| Share of the fight volume blocked at the plane (1 to 10 bh up, anywhere) | 22.5% | 16.4% |
| Within 1,500 units of a building, blocked | 86.6% | 63.3% |
| Length, median / mean | (this build) | 449 s mean (HEAD 447) |
| C1 | clean | clean |

## 3. What each reader has to re-measure, and what moves

- **QA's front-row measure** (`rows['1'].lost / n`): the denominator goes from 80 to 65 buildings and the row holds taller towers (mean 2,439 against 1,773). The band (25 to 50) is held in this measure (39.7% against 40.4%), but the front row is a different set of buildings: re-baseline it, and the "wrecked" stat with it. The row labels are the lane table's (row 0 the foreground lane, 1 the front street, 2 the mid, 3 the back); the rows reachable from the plane are still 0 to 2.
- **Population:** `pop0` goes from 390 to 1,800 (4.6 times). Shares and budgets scale (C1 budgets are shares of `pop0`; the meters multiply by 425 / `pop0`; Game Design's `cas_popRef` reads it), and the civilians share moves 22.9 to 25.4% (band 12 to 30), but **any QA or harness number in absolute people moves 4.6 times** (the people lost in a match 99 to 488). Re-check every absolute threshold; C1 and the per-tier casualty rates are shares.
- **My stage numbers:** shells 13.0 to 11.4% (front row 15.0 to 14.5), tier 4 6.76 to 7.21% a minute (inside the band 6 to 20; tier 1 and 3 fall a little), **cut floors a match fall from 1.1 to 0.1.** The towers are fewer (89 against 137) and taller (up to 62 floors, a floor is weaker: `floorStr` is the core hp over the floors), and D1 keeps brunt candidates to rows 1 and 2: the floor cuts are rare enough that the stage 2 reading (a cut floor) will almost never fire. To look at before the window: whether the brunts reach the towers as often (launches into a building a match) and whether `cutFloorsStage` should key on a smaller cut, or the shells carry the stage 2 look. `leaveFrac` 0.10 is unchanged and still holds the front row inside the band.
- **Simulation's shot-against-building test** (`_building` in `shots.gd`: the exact swept test, the nearest face within `Z_REACH` of the shot's plane, the box from its ground to its current height): `Z_REACH` is 2,080 units, so rows 0, 1 and 2 are all "at the plane" in both layouts (157 and 147 reachable buildings) and a shot at depth 0 meets a row-2 building 1,900 units behind it. The re-lay changes nothing in the rule and **raises the hits**: 6.4 to 7.9 shots a match end on a building. It needs `directcheck.gd` and the parity check "shots: buildings, wild deflects, the spray, mines" re-run in the window, and a decision (Simulation's and Game Design's) whether the reach should shrink with the lanes (rows 0 and 1 only, so that depth reads as depth) once L3 or depth lanes are on.
- **`blockedAt`'s depth rule:** the same `Z_REACH` filter, so the same fiction. The blocked share of the fight volume falls from 22.5 to 16.4% (63.3% against 86.6% near a building): the layout is sparser and the streets are open (avenues, plazas), so the zip's exit-point slide meets fewer blocked points, and those it meets are taller buildings (62 floors; a shell or a cut floor is a rarer case). `blockcheck.gd` passes unchanged. When `S.depthOn` and L3 are on, the zip should pass its own lane depth as `z` (the function takes it) and the reach should be the lane's, not the 2,080 of the blast rule: a change for the window after.
- **Things L1 with D1 adds that need a reader:** the `lanes` table (`S.lanes`, derived, not hashed) for the ground shader and the props; `Building.district`, `shape` and `landmark` (hashed); `building_fall.landmark` (bool) for Game Design's `landmarkFall` mood impulse (dormant until now: a falling landmark will feed the mood, check the Frenzied share).

## 4. The plan for the window

1. Apply `d1_window.diff`, copy the data and `lanes.gd`, `--import`; apply `l3.diff` second, switched off (`depthOn` false).
2. Regenerate the golden once (the layout changes every match), `npm test --prefix sim` 5 of 5, `probe.gd`, `lane_check.gd`, `probe_collide.gd`, `stagecheck.gd`, `blockcheck.gd`, `directcheck.gd`, `minecheck.gd`, determinism plain and `--intro`, the seam sweep.
3. Re-measure on the default arm, 160 matches: front row, all rows, civilians, tier rates, shells, cut floors, shots on buildings, length, C1 (the table of section 2 is the baseline); and the light digests with `settlements.json` `enabled` false equal to HEAD's (the switch works).
4. Tell QA the row-1 denominator, the absolute-people factor and the new baseline; Simulation the shot-hit rate and the reach question; Encounter the blocked share for the zip; Game Design `landmarkFall`.
5. L3 on (`depthOn`) is a later window with its own measures (collisions, the brunt flights, the zip's depth); the probe set exists (`probe_collide.gd`).

## 5. Cut floors under the re-lay: why they fall, and the smallest change (scratch on HEAD b6a7e47, 2026-10-05)

**The figure and what it measures.** "Cut floors a match 1.1 to 0.1" counts towers still **standing** with a cut floor at the KO. What Rendering and VFX see are the events. Measured (40 to 60 matches, HEAD against L1 with D1): floors punched out 1.98 to **0.78** a match (floor hits including cracks and dents 2.33 to 1.08), stage events into stage 2 or more caused by a floor cut 1.37 to **0.35**, towers with a cut floor still standing at the KO 1.08 to 0.15, towers with a damaged floor 0.23 to 0.23. So the cut-floor look does still happen, about once a match, and rarely survives to the end.

**Why.** (1) **Fewer hits on towers:** a tower hit by a brunt or a shot 2.34 to 1.08 a match. BUILDING SMASH plans go 1.65 to 1.30 a match, towers are 48% of the buildings instead of 70% (89 against 137), and a smash that lands on a house ends the chain sooner (a guess; the chain length was not measured). (2) **More whole collapses:** of the tower hits, collapse (the tower falls whole) 8% to 44% (0.18 to 0.48 a match): the mid-rise towers of D1 stand at about 12 floors (6 to 22), short enough that a punch pancakes them to the ground; the tall ones (downtown, up to 62 floors) are few and are not in the planner's reach as often. (3) **The planner reads people as a count:** with 4.6 times the people every place reads "populated" and the hero's care term and the lure saturate (section 6); scaling those references brings the smashes back 1.30 to 1.50 a match and the cut events 0.35 to 0.63.

**What I tried, each against L1 with D1 alone** (events into stage 2 or more from a floor cut a match; towers cut or damaged at the KO; front row, all rows, civilians, tier 4 a minute at 100 matches):

| Change | Cut events | Alive towers cut or damaged at the KO | Front row / all / civilians / tier 4 |
| :--- | ---: | ---: | :--- |
| L1 with D1 alone | 0.35 | 0.38 | 39.7 / 31.5 / 25.4 / 7.21 |
| Data: suburbs 0.28 to 0.14 of Bellgate, mid-rise 0.28 to 0.42 | 0.53 | 0.72 | 40.4 / 31.4 / 25.9 / 6.88 |
| Code, `CORE_SHARE` 0.25 to 0.15 (towers keep cut floors longer) | 0.40 | 0.40 | 39.1 / 31.0 / 25.2 / 7.04 |
| Code, `CORE_SHARE` 0.10 | 0.33 | 0.37 | 38.7 / 30.7 / 25.2 / 6.97 |
| Code, a damaged floor (`fdmg`) also puts a tower in stage 2 | 0.35 plus the cracks (about 0.2 to 0.3) | 0.38 | 39.7 / 31.5 / 25.4 / 7.21 (no change to damage) |
| **Population references scaled by pop0 / 390** (`POP_NEAR_REF`, `BRUNT_POP_REF`, brunt candidate cap) | **0.63** | 0.30 | 41.5 / 32.9 / 26.9 / 7.14 |

**Proposal, the smallest set that gets about once a match or more: (a) scale the population references with the population (section 6; it is needed for the people count anyway) and (b) let a damaged floor of a tower (`fdmg` above 0) count for stage 2 as a cut one does** (3 lines in `WorldStructures.stage`, the same `cutFloorsStage` key). That is about 0.63 plus 0.2 to 0.3 a match, near one, and costs the stage numbers nothing: front row 41.5%, all rows 32.9%, tier 4 7.14% a minute, shells unchanged. `CORE_SHARE` and the district shares do not bring it back (the first lowers it and the damage with it; the second buys 0.2 for a Game Design layout). To go further than one a match the lever is the BUILDING SMASH baseline in the planner (Encounter's data), not the world.

## 6. Every consumer of a civilian count against a share (HEAD b6a7e47)

Population at the start goes from 390 to 1,800 under the re-lay; shares stay (22.9% to 25.4% lost), people lost per match 99 to 488. Each consumer, with whether it should scale. **Scale with pop0** means read it as a share of the starting population (at 390 the number is today's, so the frozen JS core's parity at today's scale is unchanged); **stay** means a count that is right as it is.

| Where | What it reads | Today | Ruling to ask for |
| :--- | :--- | :--- | :--- |
| `sim/world/collateral.gd:108, 119, 134` | the window budget, the ceiling and the set-piece allowance, `BUDGET` / `CEILING` / `EVENT_ALLOW` times `pop0` | shares already | stay (scales by itself) |
| `collateral.gd:210, 225` (`POP_REF` 425 over `pop0`) | the menace of an evacuee and the meters' feed per casualty (VORR's menace, KAI's anguish: `data/fighters/*/meters.json`) | normalised to 425 | stay: a casualty is worth 1 / 4.6 of what it was, so the meters read the same share |
| `collateral.gd:172, 257` | shelter cap and the district flight against the building's own `pop` | relative | stay |
| `sim/world/structures.gd:267`, `brunt.gd:95, 198` | deaths as a share of a building's `pop`; people on a floor | relative | stay |
| `sim/world/structures.gd:10, 439-445` `POP_NEAR_REF` (35 people) and `popNear` | "populated" reads 1 at 35 living civilians within the radius | absolute | **scale with pop0** (35 x pop0 / 390). Users: `sim/director/launch.gd:171, 198` (the planner's care term), `sim/director/location.gd:129, 135, 153` (the lure's population histogram, `LURE_START` 0.2), `sim/director/ai` lure through `popNear` |
| `sim/director/launch.gd:47` `BRUNT_POP_REF` (8) and `sim/world/brunt.gd:275` (`minf(popAlive, 8.0)`) | the occupancy term of BUILDING SMASH scoring and of the brunt candidate score saturate at 8 people a building ("at today's scale a building holds one to five") | absolute | **scale with pop0** (a building holds 9.7 on average under D1, 2.0 today) |
| `sim/core/mood.gd:385-386`, `data/fight/mood.json:34-36` | casualties as `perPerson 30 x popRef 425 x casualties / pop0` mood points | a share | stay |
| `sim/core/fighter.gd:383, 388` | `casSeen`: has the casualty count risen (the menace meter at its cap) | compares counts, no scale | stay |
| `sim/core/damage.gd:113` (and the JS twin) | the KO feed line "Casualties N" | an absolute count shown | **ruling (Game Design, Legal):** the displayed count moves 4.6 times (99 to 488); show a share, or scale to a reference population |
| `render/core/hud.gd:46`, `ui/core/ui_sim_bridge.gd:58`, `ui/core/ui_event_hub.gd:80, 123, 440`, `ui/data/terms.json:71` | "CIVILIANS LOST n / pop0" | an absolute count shown | same ruling: presentation of a count 4.6 times larger; bears on the age rating (Legal), not on play |
| `render/core/planet_view.gd:266, 292`, `render/core/crowd_flight.gd` | the figures drawn per building (`popAlive` against the figure capacity) and the runners of a flight | a count capped by the figure budget | **Rendering:** at 4.6 times the people every building is over its figure capacity: draw one figure per N people (N = pop0 / 390) or keep the cap; the flight's runners are capped by the pool |
| `qa/godot/bands.js:124, 164, 520`, `qa/godot/records.gd:174, 407-408` | the tests: bleed, per-tier split, C1 timeline, civPct | all shares (divided by `pop0`) | stay; re-check any harness number in absolute people |
| `qa/balance-report.js:125`, the pending C3/slide rows in `bands.js:268` | print `pop0`; casualties per slide as a share | shares | stay |
| `sim/director/ai.js`, `launch.js` (the frozen JS core) | `popNear` at 70 (scale 1) | parity oracle | stays valid if the scale is `pop0 / 390` (identical at 390) |

**What scaling does (scratch, 100 matches, L1 with D1):** BUILDING SMASH 1.30 to 1.50 a match, cut events 0.35 to 0.63, front row 39.7 to 41.5%, civilians 25.4 to 26.9%, tier 4 7.21 to 7.14% a minute, C1 clean. The people-as-count consumers that must change are three constants of the planner and the candidate score; everything that already divides by `pop0` is unchanged.

## 7. `building_fall.landmark`

HEAD has no `landmark` field at all: `FxEvent` has none, `SimFx.buildingFall` does not set it, and `mood.gd:374` reads `e.get("landmark") == true`, which is null and so false (dormant, as Game Design wrote it). The float existed only in the unlanded D1 patch and is fixed there (bool). **Nothing to land now:** the fix has no effect on HEAD and no golden moves; adding an unused `landmark: bool` to `FxEvent` and `buildingFall` ahead of D1 would also move no golden (the field is not in `FX_FIELDS`) but changes nothing either, so it lands with the window, in the patch.

## 8. Game Design's what-if: a punch does not pancake a tall tower at low tiers (scratch, 100 matches, 2026-10-05)

Base for every row: L1 with D1 with the two rulings (population references scaled by pop0 / 390; a damaged floor counts for stage 2), i.e. the set that goes into the window. Tower hits are brunts and shots on buildings of 5 floors or more; collapse is the tower falling whole.

**The rule as ruled has no effect.** Pancake of a tower of 8 floors or more only when the launcher is tier 3 or 4 or the cut is in the bottom two floors (6 lines in `WorldBrunt.pancake`, the one function the brunt and the shot paths share): the numbers are identical to the base to the last digit. Tower hits by tier (40 matches, a match): **tier 2 0.16, tier 3 0.34, tier 4 0.78**, so 93% of them are at tier 3 or 4, where the rule lets the tower come down as today; and pancakes are 0.03 a match whatever the rule. Collapses of towers are 0.38 a match, **0.23 of them in towers of 5 to 7 floors** (under the rule's 8) and 0.15 in taller ones, almost all at tiers 3 and 4.

**What does the collapsing is the core wear, not the pancake.** A floors hit also wears the building's core hit points by `CORE_SHARE` 0.25 of its damage (about 750 for a brunt at tier 3); a tower of 5 to 7 floors has 565 to 790 hit points, so one hit levels it whatever the floors did. A cap on how much of the core one floors hit may take does it:

| Setting | Collapse share of tower hits | Cut floors standing at the KO (cut or damaged) | Cut-floor events a match (n above 0) | Front row | All rows | Shells (all) | Tier 4 a minute | Civilians |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| The window's set (no what-if) | 33% (0.38 of 1.15) | 0.17 (0.30) | 0.63 | 41.5% | 32.9% | 11.2% | 7.14% | 26.9% |
| The tier rule on pancakes | 33% (no change) | 0.17 (0.30) | 0.63 | 41.5% | 32.9% | 11.2% | 7.14% | 26.9% |
| **Core cap: one floors hit takes at most 0.5 of the core** | **11%** (0.13) | **0.32 (0.47)** | 0.63 | 40.7% | 32.3% | 11.8% | 6.97% | 26.8% |
| Core cap 0.35 | 7% (0.08) | 0.37 (0.52) | 0.63 | 41.1% | 32.7% | 12.0% | 7.07% | 27.1% |

**Reading.** The target (whole collapses falling from 44% toward 8 to 20% of tower hits) is met by the **core cap 0.5**: 33% to 11% on this base (44% on L1 with D1 alone, before the references are scaled); the cut floors that stand at the KO double (0.17 to 0.32); front row 40.7% (inside the 40 to 48 target and the 25 to 50 band; it does not fall, because a tower that survives its cut still goes at the next blast), all rows 32.3, shells 11.8, tier 4 6.97 a minute (floor 6), civilians flat. Cut floors a match are more than one with the references scaled: floor hits (punch, crack, dent) 1.14 a match, punches 0.93, of which 0.63 are cut-floor stage events; the damaged-floor reading adds the cracks. **Cost:** the cap is two lines (`brunt.gd` `applyFloors` and `blast.gd` `_floors`: `b.hp -= minf(CORE_SHARE * oc.dmg, coreCap * b.maxhp)`) and one number; I would put the number in `data/biomes/stages.json` (`coreCapShare`, 0.5; 0 or 1 is off, one more key for Tools) with a loader line. **It can ride in the window** (it moves the goldens, and the window regenerates them anyway) with its own `stagecheck.gd` case (a tower of 5 floors hit by a tier-3 brunt survives its first cut at 50% of its hit points). The tier rule on pancakes is not worth its 6 lines: it changes nothing at the tiers where towers are hit.
