# The planner's levers for buildings: staying in town, and aiming for one

Owner: Encounter Systems Director. Date: 2026-10-13. **Built in scratch and parked; read on main, not yet gated; not applied.** It answers Game Design's `docs/design/buildings.md` section 3 and the EP's "using the planet", on World's findings in `docs/world/destruction-hook.md`. It sits on the nine cells' chain (`brawl-c2.md` sections 14 to 17). Every number is a first value, and each is data.

## 1. What is built

All of it is in `sim/director/launch.gd`, read from a new block of `data/director/launch.json`, `town`. With the block absent the planner plays as before.

| Game Design's rule | As built | Data |
| :--- | :--- | :--- |
| A launch along a street stays in the street | From a settlement, SMASH ACROSS sets its force so the flight carries him `haulTarget` units and no further. It is kept while he lands inside the settlement, at least `haulMin` on, and not in water. Where the street does not run that far it is the long haul, as before | `haulTarget` 3,500; `haulMin` 2,400; `biomes` city and village |
| The distance bonus is halved in a settlement | A landing on open ground from a settlement scores `distMul` of the distance bonus | `distMul` 0.5 |
| The new-biome bonus is paid once in 60 s | The bonus is offered only when `newBiomeEveryS` of match time has passed since the planner last chose a launch that took it | `newBiomeEveryS` 60 |
| A building on the line is preferred from tier 2, with no stick | A building's score gains `bruntPrefer` from tier `bruntFromTier` when no stick is held | `bruntFromTier` 2; `bruntPrefer` 40 |
| With the stick toward it, it wins | When the stick's tilt keeps a building's plan in its cone, that plan gains `stickWins` | `stickWins` 200 |
| The AI votes by its care | Unchanged: a building's score already takes the people inside times the launcher's care | |
| The hero's lure | Unchanged | |

**State.** One number: the match time the new-biome bonus was last paid. It is kept after the slots' own in `S.dirS.craterT`, which the director owns, and the array grows by one only when the bonus is first paid.

## 2. What it reads

The AI against itself from the crossing start, 12 matches each, with my probe (`townprobe.gd`, scratch). A body into a building is a `building_hit`. A launch is a decision that chose neither to stay nor to knock back. Both columns are the nine cells' chain built on main (91b3722f and 8e2ee750, with World's wall slam in); the second has the levers, and the nine cells' pass 2 as well, which the AI never uses.

| Row | The chain, without | With the levers, `bruntPrefer` 40 | Game Design's bound |
| :--- | ---: | ---: | :--- |
| Bodies into buildings a match | 1.67 | 4.17 | 4 to 8 |
| Launches that take a building | 15 of 153, 10% | 35 of 160, 22% | 15 to 30%, in a settlement |
| Decisions with a building to vote on | 41 | 59 | |
| Fight time within 1,500 units of a building | 29.3% | 39.0% | 30 to 50% |
| Fight time outside every settlement | 63.5% | 50.9% | At least 25% |
| Fight time in the city | 20.4% | 27.1% | |
| The match's median | 457 s | 468 s | 360 to 480 s |
| People lost | 23.6% | 24.3% | 12 to 30% |
| Structures lost, of 118 | 42.8 | 49.2 | |
| What the floors took: dents, cracks, punched through | 7, 4, 2 | 12, 7, 4 | |

- **Bodies into buildings reaches its band, at its floor.** The street haul keeps the fight near buildings 39% of the time where it stayed 29%, and it is still out of every settlement for half the match. A building is on offer 59 times where it was 41, and the planner takes 35 of them.
- **The collateral holds.** People lost is level and structures lost is up by a seventh, both inside their bands on these 12 matches. An earlier read on f631d1b1 had the collateral falling by a fifth; that base had no wall slam. It wants QA's rows on 100 matches before anyone leans on either.
- **`bruntPrefer` at 40 is what I park.** On the earlier base 14 took a building half the times one was offered (21 of 129 launches, 2.17 bodies a match), which is not "preferred"; 40 took 27 of 43.
- **The ceiling is still how often World offers a plan:** 59 offers in 460 decisions, 4.9 a match. Buildings of rows 1 and 2, 720 to 10,400 units on, on the far side of the rival only, with a flight that enters them. To go from 4 toward 8 the offers have to rise; the vote cannot do it.

## 3. Not built, and what would lift the ceiling

| What | Whose | Why |
| :--- | :--- | :--- |
| More plans to vote on: a nearer least distance than 720 units, the side behind the launcher by a turning send, a plan from a brawl against a building's face | World, with the turning send (Combat) | 3.6 offers a match can't make 4 bodies |
| The send down an avenue (`WorldLanes.crossingAlong`) | Encounter, in depth slice D1c | It needs fighters in depth |
| The first move after a wall slam | Built, in the fourth round's lock: a fighter who comes off a wall is "sent" | |
| "Late and behind": the fighter who cares takes a full building when he is losing | Encounter, with Game Design's numbers for late and for behind | No number is ruled |

## 4. Gates and files

**Read, not yet gated.** The files are `sim/director/launch.gd` and `data/director/launch.json`, with one optional schema key (`town`) for Tools (`schema/schema9.cjs`). Neither file is touched by the nine cells' chain, so the two can go in either order; in one window they share one golden. The launch decisions change, so the golden is regenerated.
