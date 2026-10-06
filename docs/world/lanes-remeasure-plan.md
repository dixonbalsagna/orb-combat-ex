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
