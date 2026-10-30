# The campaign's route on the ring: World's part of the first slice (2026-10-25)

For the EP's brief (campaign step 1; `docs/design/campaign.md` sections 1.4, 2 and 7). Built in `sim/world/campaign.gd` (`WorldCampaign`), data `data/biomes/campaign.json` (**`enabled: false`**: with it off nothing runs and the golden is as it was), proof `sim/world/tools/campaign_check.gd`. Parked in `docs/world/pending/campaign-route/`.

## What it does, in plain words

The route is the ring the pair are flying. When a stage ends, World answers one question for the next column: *which places lie within 10 to 25 seconds of flight of where the pair stand, and should the ring turn so a better set lies along it?* A column offers two or three places (a seeded draw from the episode seed): settled places (a city or town the ring crosses) and stretches of open ground, chosen so the choice is real: at least 5 s of flight between two of them, a new kind of ground preferred, a town or city always among column 4's (a defence needs one). Every turn the data allows (15, 30, 45, 60 degrees, either way) is tried against staying on the ring, and the best set wins; a turn must be worth at least a little (`turn.minGain`) so the ring does not turn for nothing. The climax (column 5) is the boss's home: the ring becomes the whole circle through the pair and the home, and the flight to it is the build-up. A side story's place is one standing city or town on the current ring within the usual flight, with a Close ring round it for the filler episode. The planet's wounds are a band 0 to 3 for each place and nothing else.

## The interface (all pure; a ring travels as the setup's `arena`, JSON-safe)

| Call | Returns |
| :--- | :--- |
| `WorldCampaign.column(planetSeed, epSeed, col, arena, pc, opts)` | `{ok, col, turn (null or {deg, from}), arena, start, pc, cols, resize, sites, score, notes}` |
| `WorldCampaign.beginColumn(...)` | the same in steps: `job.step(1)` a frame (9 rings at 11 ms the longest here); `job.result` when `step` returns true |
| `WorldCampaign.side(planetSeed, arcSeed, n, arena, pc, opts)` | `{ok, site, place, arena}` (the Close ring round the place), or `{ok: false, why}` |
| `WorldCampaign.wearOf(S)` | `{place id as text: band}`, from a finished stage's fallen buildings (never people) |
| `WorldCampaign.mergeWear(prev, now)` | the worse band of each place |
| `WorldCampaign.standingOf(P, wear)`, `damagedOf(wear)` | the ring picker's `standing` bytes (0 for a fallen place) and `damaged` ids |
| `WorldCampaign.applyWear(S, wear)` | lays a place's wear on a stage's buildings; the match setup's `wear` key does it at the start (WorldPlanetWorld.gen) |
| `WorldEpoch.askCampaign(S, pivotX, deg, due)` | the ring turn in a running sim: the same machinery as a fight's turn, one candidate, none of its caps |

`opts`: `used` (place ids the episode has used), `wear` (the run's place state), `pin` (the climax's home place id), `turn` (false: stay on the ring), `minS`/`maxS`. A **site** is `{id, kind (city, town, open), place (planet place id or -1), arc (signed columns from the pair), entry (columns to its near edge), half, dir (-1 or 1), flightS (seconds to its edge), settled, biome, fine, feats, wear, fallen}`. `start` is the returned ring with its touch-down at the pair's point, which is what the next stage's `setup.arena` wants (the pair start at the touch-down); `arc` is frame-free, so an in-sim consumer uses `pc + arc`.

**Simulation's side (to match):** the arc block holds the run's `wear` (place state) and `used` (place ids), and passes `epSeed = H(run, "episode", n, 0)` and the pair's column. `places_for_column(seed, col)` is `column(planetSeed, epSeed, col, arena, pc, opts)` with the state added.

## What I decided, and what I need confirmed

1. **The flight speed.** "10 to 25 s of boosted flight" is read as the melee dash, 430 x 2.4 = 1,032 units a second (`flight.speed`), with the traversal multiplier left out: with it a lap of the planet is 15 s, so 10 to 25 s would be a lap or more and no ring could hold a place that far. At 1,032 u/s the band is 322 to 806 columns each way, which fits a Close ring (1,200 columns, half-ring 600) only just and a Half ring (2,400) well. *Game Design: confirm, or give the speed.*
2. **The turn's frame.** A turn is about the pair's point, so the pair's column does not move and `arc` is the same before and after. The planner works outside any match (`SimConst.NC` is not its ring's), so it does its own middle column (`WorldEpoch.turned` takes it as an optional last argument; its default is as it was).
3. **The climax changes the ring's length** (to the whole circle, 4,800 columns), which a running sim cannot do (a match's `NC` is fixed): `resize: true` means a new stage match on `start`. Columns 1 to 4 keep the length and may be turned in the sim by `askCampaign` or begun as a new match.
4. **A campaign turn is not one of the fight's four** (`E.n` is not counted) and has none of the fight's caps; the swap's own rules (calm, the ground under a fighter moves at most `moveMax`) still apply.
5. **Wear is place state only** (mc02): a band from the share of a place's buildings that fell; no count of people anywhere. A worn stage lays its place's buildings already fallen (35% at band 2, 70% at band 3; their people gone and not counted as the stage's casualties, `pop0` lowered by them) and weakens the rest. A fallen place (band 3) is not standing for the ring picker. Nothing is healed here; healing between episodes is Game Design's to say.
6. **A side story may find no place** on a ring (21 of 32 rings of planet 7 had one in reach): then none is offered and the arc's own draw is spent. Say if it should widen the band or turn the ring instead.

## Cost and proof

A column reads nine rings (the ring as it is and eight turns): 180 ms on gen 1 and 500 ms on gen 2 on this busy machine, so `beginColumn` stepped a ring a call: at most 11 ms a call here. The climax is no read. `campaign_check.gd` (30 checks): every place of columns 1 to 4 within the band on both generations (4 planets, 4 columns each: 16 of 16 had every place they ask for), the column's places apart, the town in column 4, the same twice, ten episode seeds giving ten different sets, used places not offered again, every turned ring through the pair's point at the same length within the bearings, the climax's ring through the pair and the home (lateral distance 0), a side place and its ring, the wear chain, a worn stage is a deterministic different stage and a campaign-off setup's `wear` is ignored, and a 40-degree turn in a running sim happens on a calm tick without moving the pair's point or counting against the fight's four.

## Amendments of 2026-10-26 (Game Design `rulings-2026-10-26.md` items 1, 2 and 5; window 16)

- **The band is in columns.** A column's places lie 322 to 806 columns from the pair, each way (`flight.minCols`, `maxCols`; the seconds a site reports are columns at the 1,032 u/s dash). Columns 1 to 4 run on Half rings; on a Close ring the band ends at the far side (600). Separation and the side story's clearance are columns too (`sites.sepCols` 161, `side.sepCols` 97).
- **A side story always names a place.** `side()` tries, in order: a named city or town in the band; any named place on the ring (`how: "widened"`); the ring turned by the smallest bearing, either way, that brings one along it (`how: "turned"`, a campaign turn, outside the fight's four, with `turn` and the turned `ring` in the answer); and if all fail `{ok: false, spent: true}` and the arc's draw is spent. Never an unnamed site. On planet 7's 32 test rings: 21 in the band, 6 widened, 5 turned, none empty.
- **The ring turns in about half the columns.** Measured by `campaign_turns.gd` (the share for any pair of the two numbers, from one planner run) and asserted by a `campaign_check.gd` row: with `turn.minGain` raised from 0.2 to 0.45 and the bonus kept at 0.30, 47% of 96 columns (both generations, 6 planets, 2 rings, columns 1 to 4) turn. The share falls as 94% (0.20), 86% (0.30), 59% (0.40), 31% (0.50), 10% (0.70).
