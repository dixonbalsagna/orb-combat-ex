# The World checks on the GW1a data (World, 2026-11-14)

On a scratch tree of HEAD def3445a with globe-step2 and a-world-01 applied and `data-switches-gw1a.diff` plus `data-switches-gw1a-others.patch` (the lines in the director's and the planner's files that the water module and the calm turn need to load) applied: the data as the 9 November build had it, and `world.json` mode `planet`. One Godot at a time, the run list of `tools/world-checks.json` as it stands (87 checks, of which `world_default_check` is new). **44 pass unchanged, 41 fail, 2 gave no verdict.** A failing check is one whose own assertion names what the flip changed: nearly all are the data's shipped value pinned ("ships off", "default generation is 1", "a setup without a planet is today's world"), or a hash recorded on the hand-made arena. Each needs re-pinning to the new default in GW1a (a World job: it is the check's expected value, not the sim); none found a fault in the sim. The first failing line of each:

| Check | Verdict | First failing line |
| :--- | :--- | :--- |
| `floor_check` | FLOOR: 8 check(s) failed | the floor ships off, and wade.below is 75 |
| `lane_check` | LANES: 3 check(s) failed |  |
| `after_check` | AFTER: 8 check(s) failed | heave: a step of plates, 2 columns each side, marked PLATES (rim 0.0 to 0.0; the rise 0.00 in, 0.00 out, over the wall rule's 0.80) |
| `arena_check` | ARENA: 4 check(s) failed | the Planet slice (planet 7, touch 3) is today's: hash d0f86ade, 4,800 columns |
| `brunt_check` | BRUNT: 2 check(s) failed | every flight ends held at a wall or lodged in its last building (211 of 212; 126 held, 85 lodged) |
| `climate_check` | CLIMATE: 2 check(s) failed | climate.json is clean and the default generation is 1 ([]) |
| `power_world_check` | POWERWORLD: 1 check(s) failed | off: the bounces a send may take go with the tier (tier 4: 1, tier 1: 0) |
| `control_check` | CONTROL: 4 check(s) failed | plains: the reference ground is itself, so control returns at its own stop (tick 65), with no skate |
| `craters_check` | CRATERS CHECK: 14 failed | mud: a slam in wetland digs 0.90 x the radius, 1.40 x the depth and 0.50 x the rim of today's bowl (the row: 0.8, 1.2, 0.2) |
| `deepencheck` | DEEPEN: 3 check(s) failed | deepen by 1.2 makes the crater 1.2 times as deep (86.2 to 17.2 units) |
| `demostart_check` | DEMOSTART: 2 check(s) failed | the default start is START_X (76350) and the gap as before |
| `depthreads_check` | no verdict (stopped: still running after an hour on a shared machine) |  |
| `epoch_check` | EPOCH: 6 check(s) failed | the turn's data stands at Game Design's caps (4 turns, 60 s apart, 40 degrees of drift) and is off |
| `far_check` | FAR: 2 check(s) failed | at z = 0 farColumn is the slice's own column: the same height (to float32) and biome at 50 columns of the Planet slice |
| `farmap_check` | FARMAP: 1 check(s) failed | the map's far field against the exact read over 7 rings (7/2400, 3/4800, 3/2400, 3/1200, 25/4800, 25/2400, 25/1200): worst mean /dh/ 30.0 units, worst share of heights ov |
| `farsites_check` | FARSITES: 2 check(s) failed | a planet match with the turn off keeps its ring in S.planetRing, the one a turning match keeps in its epoch (the axis, the touch-down point, the columns, the seed) |
| `field_water_check` | FIELDWATER: 1 check(s) failed | on the line the records hold the ring's water: 42 columns, 0 missed, depth differs by 0.802 at most (19 columns skipped where the ring's ground and the field plus platfor |
| `field_lot_check` | FIELDLOT: 3 check(s) failed | the buildings of a lot stand on its plane (climbing with the street and leaning across it by at most the data's grades): 315 of 1390 lots spread over a unit (largest 3170 |
| `fill_check` | FILL: 9 check(s) failed | the switch (data/biomes/water.json enabled) is off in the data |
| `fire_check` | FIRE: 1 check(s) failed | forest burns (1), desert does not (0) |
| `gen2_state_check` | STATE: 5 check(s) failed | a gen 1 and a gen 2 match on the same explicit ring are told apart by the memo: gen 1 afebf9f3 both times, gen 2 afebf9f3 both times |
| `ground_check` | GROUND: 11 check(s) failed | gen 1 planet matches (seeds 7, 3, 25, 11; rings of 2400, 1200, 4800, 2400) hash as they did before window 2 |
| `ground_props_check` | GROUNDPROPS: 1 check(s) failed | the hand-made world: propsNear is [] even with the switch on |
| `isect_check` | ISECT: 2 check(s) failed | at least two avenues cross each street near downtown's centre (0 crossings) |
| `lakes_check` | LAKES: 1 check(s) failed | lakes.json is clean ([]) and the data's generation is still 1 |
| `land_check` | LAND: 1 check(s) failed | land.json is clean and the data's generation is still 1 ([]) |
| `planet_check` | PLANET: 3 check(s) failed | planet 7 has the places of picture A2 (0 of 42; the module has 54) |
| `planet_world_check` | PLANETWORLD: 1 check(s) failed | a setup without a planet is today's world (118 buildings, the city at x 50,000) |
| `repeat_check` | REPEAT: 2 check(s) failed | off: see the next line; on, the first two repeats widen it by 1.25 ([160.0]) |
| `ringpick_check` | RINGPICK: 3 check(s) failed | a coastal home (planet 3, city 8: the ring round it is 68% land): the first ring turns to a ring through the home that meets Close's minimum with 69% land, the home on it |
| `sea_rules_check` | SEARULES: 4 check(s) failed | on a world without a lake seaTop is exactly 0 over the sea and NO_SEA elsewhere (so every line reads as it did) |
| `sites_check` | SITES: 1 check(s) failed | sites.json is clean ([]) and the data's generation is still 1 |
| `skate_check` | SKATE: 3 check(s) failed | on: on ice the get-up begins at the reference stop (tick 49, the lookahead's 74; off it began at 49) |
| `step_check` | STEP: 1 check(s) failed | a gen 2 planet with the B plates on made by the job at 250 units is the one make gives, bit for bit (494 calls, the longest 98.5 ms) |
| `surface_check` | SURFACE: 2 check(s) failed | the surfacing rule ships off, at 30 ticks |
| `surface_follow_check` | SURFFOLLOW: 1 check(s) failed | a world with no frame has its table built at match build |
| `wrecks_check` | no verdict (stopped: still running after an hour on a shared machine) |  |
| `street_axis_check` | STREETAXIS: 5 check(s) failed | at the start a front street runs along the line: alongSin under 0.02 (worst 1.0000), lineSin over 0.99 (worst 0.0005) |
| `water_warm_check` | WATERWARM: 1 check(s) failed | off in the data as shipped (flowWarm.cols 0) |
| `struggle_meet_check` | STRUGGLEMEET: 1 check(s) failed | max: every standing tower within the glass radius has its windows out (5 of 9) |
| `struggle_dir_check` | STRUGGLEDIR: 2 check(s) failed | FAIL: seed 4 on: a bowl is a record of the cue radius dug in the cue tick ([] vs 0.0) |
| `globe_check` | GLOBE: 1 check(s) failed | a trench cut on from the coast carries the sea's level along its length ([36.3539299526859, 36.3539299526859, 36.3539299526859]) |
| `floor_walk_probe` | FLOORWALK: 1 check(s) failed | the hand-made world has a beach to walk out from (0) |

The 44 that pass unchanged on the flipped data: `burial_check`, `props_wet_check`, `b_check`, `blastcheck`, `blockcheck`, `calm_read_check`, `campaign_check`, `collateral_check`, `density_check`, `directcheck`, `field_check`, `field_plan_check`, `field_crater_check`, `everywhere_check`, `far_people_check`, `places_cache_check`, `field_crack_check`, `field_scorch_check`, `field_trench_check`, `field_cache_check`, `planet_cache_check`, `field_load_check`, `field_records_check`, `store_check`, `host_check`, `interior_check`, `minecheck`, `noise_check`, `props_check`, `rivers_check`, `beam_grid_check`, `stagecheck`, `meteor_crater_check`, `through_check`, `switchon_check`, `wall_check`, `water_read_check`, `landmark_spare_check`, `lot_reach_check`, `relax_check`, `node_warm_check`, `wall_hold_check`, `world_default_check`, `bystanders_check`.
