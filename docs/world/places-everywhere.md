# Buildings at every place (World, 2026-11-01)

The EP's top-priority order, from Encounter's measurement on four field worlds: about one place in seven has a building in the sim (6 to 11 of 54 or 55 places within 4,000 units; 2 of 12, 2 of 17, 3 of 15, 2 of 11 within 26,000 of the start), so a swing or a launch onto a town mostly arrives at empty ground. Goal: every place has real buildings the fight can hit, wherever the line goes. This page is the answer, the design and the costs; the experiment behind the numbers is in `pending/places-everywhere/` (not for landing).

## 1. Is this deliberate, and what does the view draw?

**Deliberate as a first cut, never finished.** Buildings are laid by `WorldPlanetWorld.settle` for `chordsOf(slice)`: the places in the slice's `held` list, those the first line passes within 0.6 (city) or 0.7 (town) of the place's radius, once, at match start. `WorldPlan` (places by plan) made each place a planet-fixed plan, a pure function of (planet, place), so that laying it later, or all at once, is possible; `ring-any-angle/world.md` 9.2 said "the 44 towns of a planet are 44 small plans, computed lazily when first in view". I laid the first ring and did not lay the rest, because `S.buildings` is constant for a match (snapshots share it, `bIdx` "never changes") and growing it needed a costed design. That is this page.

**What the player sees.** The view draws a town the sim does not have. The far land (`render/core/far_land.gd` `_make_towns`, from `WorldPlanet.farPlaces`) stands blocks at every place beside the ring, with town-coloured ground on the far map. It skips only a place the ring passes through ("the band's own"). The near plane draws only `S.buildings`. So the line arrives at a town that was scenery in the distance and finds town-coloured ground and nothing to hit.

## 2. What a planet holds

From `WorldPlan.geometry` (the plan before any lane or ground filter), five planets:

| planet | places | towns (buildings) | cities (buildings) | total | largest place |
| :-- | :-- | :-- | :-- | :-- | :-- |
| 7 | 54 | 43 (1,652) | 11 (2,742) | 4,394 | 262 |
| 12 | 55 | 43 (1,653) | 12 (2,991) | 4,644 | 262 |
| 21 | 51 | 40 (1,532) | 11 (2,742) | 4,274 | 262 |
| 3 | 54 | 42 (1,627) | 12 (3,016) | 4,643 | 270 |
| 30 | 52 | 40 (1,532) | 12 (2,989) | 4,521 | 262 |

**A planet holds 4,300 to 4,650 plan buildings**: a town about 38, a city about 250. A match lays 214 to 297 today along the first line. With the first line's places as now and every other place in full, planet 7 holds **3,565 buildings** (263 + 3,302), about 13 times today. Laying every plan cold costs 450 to 510 ms native, about 9 ms a place.

## 3. The experiment

`layFree` lays a place's whole plan at its planet points (planet's own yaw, no lane, no ground test), strip x and z read from the first ring, `dir` the planet point; the match appends them after the first ring's. Planet 7, touch 1, native on a shared PC, 900 AI-against-AI ticks, the same process three times (base, everywhere, base again):

| | base (263 buildings) | everywhere (3,565) |
| :-- | :-- | :-- |
| Laying the free places | | 470 ms (the plans' geometry; a pure function, cacheable) |
| `lotRecords` (World's lots) | 173 to 179 ms (117 lots) | **2,384 ms** (678 lots) |
| Everything else in the match start | about 640 ms | about 1,135 ms (the 470 above, bind and index +30) |
| Match start in all | 0.8 to 1.1 s | 3.5 s; **about 1.6 s with the lots lazy (section 4)** |
| State memory | | +4.9 MB (about 1.4 KB a building) |
| Full state hash (`SimHash.stateHash`, replay checkpoints only) | 23 to 30 ms | 190 to 206 ms (6.6 to 8 times) |
| Tick p50 | 365 to 386 us | 366 to 376 us |
| Tick p99 | 1.53 to 1.78 ms | 2.3 to 2.4 ms |

The tick mean and max in the probe carry the rematch's surface-table spike (the contact park) in both rows, so only p50 and p99 are fair. p99 rises about 0.8 ms: the x-bucket index now holds about 28 buildings a bucket instead of 2, and each query walks them (their z tests then drop them, `structures.gd` 151, 387, 412, 439). **Far buildings do not fight**: the structure tests compare the body's z with the building's, and a free building's z is its lateral offset from the line, thousands of units out of the lanes.

## 4. The design

**Lay every place's whole plan at match start, as planet-fixed buildings with `bDir`; make everything derived from a place lazy.**

1. **The buildings.** `WorldPlan.layFree` per place, in the load job one place (or one band of a place) a slice so no slice passes the 4 ms rule (a place is 9 ms; a band 2 to 3 ms). The geometry joins the planet cache (`WorldPlanetCache`, 4,400 buildings, about 0.4 MB) so a warm start reads it. Cold: +0.47 s native, about 1.2 to 1.5 s on the web (Performance's ratio, estimated, not measured).
2. **Poses.** Unchanged and already built: `S.bDir` from the plan, `bX`/`bZ` from the frame, a swing poses the buildings within `poseReach` by planet distance, a rest poses all. This is why laying everything is cheap for the swing: nothing is re-laid when a line turns.
3. **Lots and platforms, lazily.** A lot is a pure function of (planet, place, plan), not of the match, so it needs no place in `S.fieldRecs` at start: a per-place memo (like `WorldPlan.geometry`'s) computes a place's lots when the line first comes within a launch of it, a few buildings a tick (about 0.7 ms a building: a town 27 ms, a city up to 180 ms), and `applyRecords` reads the memo. Until then a place's ground is the field's (its platform record is a flat of one height round the centre, 54 records, cheap and laid at start). This removes the 2.4 s.
4. **Forgetting.** Nothing is. The buildings are state arrays, a broken building is `bAlive` 0 and its `hp`, a crater is a store record at a planet point, a wreck is a building. A broken town stays broken for the match by being the state. Across matches the campaign's place state (`setup.wear`, `WorldCampaign.applyWear`) already carries it.
5. **The cap.** No cap on buildings in state (3.6 k, 5 MB). What is in play is the pose list (`bList`: tens to about 150). The caps that scale with the count must change to count the first ring: `beam.gd:277` (a beam's cap is a share of `S.buildings.size()`: it would grow 13 times) and the collateral totals.

## 5. What it needs from others

- **Simulation (small, optional first):** index only buildings in the lanes' band (`_rebucket` on band entry and exit), which should bring p99 back; a hash that counts a free building only once it is not pristine (the full hash is 7 times slower; replay checkpoints only, so not urgent); `beam.gd:277` and `chase.gd:297`/`beamplay.gd:279` loops over `S.buildings` use a count of the first ring's, or `near()`.
- **Game Design:** the people. Free places can hold their people for the wear list and the evacuation, but `S.world.pop0` (the menace and anguish base) must stay the first ring's, or a strike on a distant town counts as a thousandth of a toll. Do the free places' people count toward menace when the fight arrives? My default: yes, in a place-by-place share, with pop0 growing as a place is first posed. Their call.
- **Rendering:** the far blocks at a place the line has not reached would double with the real town as it comes in range; they already skip a place the ring passes through, and the swing's `ring` for them is theirs.
- **Netcode:** the digest cost of 3.6 k buildings, if the net digest hashes them (the replay hash does).

## 6. Not chosen, and why

- **Lay on first approach (append to `S.buildings`).** A growing array breaks the snapshot's shared records and `bIdx`, orphans interiors and wreck ids (`simulation.md` "stable building slots"), and moves the lay into a tick unless it is sliced and committed on a tick boundary in the hash. It saves 0.5 s at load and 5 MB, and costs a Simulation change that touches every reader of `S.buildings`.
- **Only the places near the start.** That is today's state, one in seven.

## 7. Build

Behind `field.json plans.everywhere` (off), gen 3 only, byte-identical off. World: `WorldPlan.layFree`, the platform records for every place, the lazy lot memo, the cache entry, the first-ring-only counts for the caps World owns (`WorldCollateral`), `everywhere_check` (count by place, nothing dropped, the same state twice, the first ring's buildings and golden unchanged with it off, a swing onto a far town poses its buildings). Simulation's lines go as a grant patch.
