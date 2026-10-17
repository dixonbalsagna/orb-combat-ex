# The planner's levers for buildings: staying in town, and aiming for one

Owner: Encounter Systems Director. Date: 2026-10-13. **Built in scratch, read and gated on main, parked; not applied.** It answers Game Design's `docs/design/buildings.md` section 3 and the EP's "using the planet", on World's findings in `docs/world/destruction-hook.md`. It sits on the nine cells' chain (`brawl-c2.md` sections 14 to 17). Every number is a first value, and each is data.

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

Two builds on main: the nine cells' chain alone (91b3722f), and the chain with the levers (8e2ee750; the sim is the same on both).

**From the crossing start,** the AI against itself, 12 matches each, with my probe (`townprobe.gd`, scratch). A body into a building is a `building_hit`. A launch is a decision that chose neither to stay nor to knock back.

| Row | The chain | With the levers, `bruntPrefer` 40 | Game Design's bound |
| :--- | ---: | ---: | :--- |
| Bodies into buildings a match | 1.67 | 3.58 | 4 to 8 |
| Launches that take a building | 15 of 153, 10% | 32 of 146, 22% | 15 to 30%, in a settlement |
| Decisions with a building to vote on | 41 | 47 | |
| Fight time within 1,500 units of a building | 29.3% | 29.9% | 30 to 50% |
| Fight time outside every settlement | 63.5% | 58.6% | At least 25% |
| Fight time in the city | 20.4% | 19.9% | |
| The match's median | 457 s | 435 s | 360 to 480 s |
| People lost | 23.6% | 21.7% | 12 to 30% |
| Structures lost, of 118 | 42.8 | 40.6 | |
| What the floors took: dents, cracks, punched through | 7, 4, 2 | 12, 8, 4 | |

**From the default start,** QA's default arm (200 matches on the chain, 100 with the levers).

| Row | The chain | With the levers | QA's band |
| :--- | ---: | ---: | :--- |
| Launches that end in a building first | 3.9% | 9.3% | 4 to 10% |
| Brunts a minute | 0.07 | 0.17 | 0.3 to 1.0 |
| Launches that pick a building, of those with one in reach | 44.1% | 97.0% | 35 to 60% |
| People lost | 21.3% | 21.5% | 12 to 30% |
| Front-row structures lost | 38.5% | 41.4% | 25 to 50% |
| Match median; 10th percentile | 440 s; 324 s | 434 s; 331 s | 360 to 480 s; 300 s or more |
| The X masher against the medium AI (seed 1, 100 matches) | 50 | 50 | |

- **Bodies into buildings more than double, and stop just short of the band.** 3.58 a match from the crossing, where the chain reads 1.67. A second build that also carried the nine cells' pass 2 read 4.17 on the same 12 seeds, with the fight near buildings 39% of the time, so 12 matches carry about half a body of noise. QA's 100 from the crossing settle it.
- **The vote is spent.** With a building in reach the planner now takes it 97 times in 100 from the default start, and 32 of 47 offers from the crossing (the fighter who cares turns the rest down for the people inside). QA's band for that share, 35 to 60%, was drawn for a planner with no preference: `bruntPrefer` 14 sits inside it (half the offers taken on an earlier base, 2.17 bodies a match), and Game Design's "preferred" does not. One of the two has to move.
- **The collateral holds.** People lost is level; front-row structures are up three points, inside their band.
- **The ceiling is how often World offers a plan:** 47 offers in 12 matches from the crossing, 1.3 a match from the default start. Buildings of rows 1 and 2, 720 to 10,400 units on, on the far side of the rival only, with a flight that enters them. To go from 4 toward 8 the offers have to rise; the vote cannot do it.
- **The street haul did not show on this build.** The fight is near a building 30% of the time with and without it (39% on the build with pass 2). I do not lean on it either way.

## 3. Not built, and what would lift the ceiling

| What | Whose | Why |
| :--- | :--- | :--- |
| More plans to vote on: a nearer least distance than 720 units, the side behind the launcher by a turning send, a plan from a brawl against a building's face | World, with the turning send (Combat) | About 4 offers a match can't make 4 to 8 bodies |
| The send down an avenue (`WorldLanes.crossingAlong`) | Encounter, in depth slice D1c | It needs fighters in depth |
| The first move after a wall slam | Built, in the fourth round's lock: a fighter who comes off a wall is "sent" | |
| "Late and behind": the fighter who cares takes a full building when he is losing | Encounter, with Game Design's numbers for late and for behind | No number is ruled |

## 4. Gates and files

**Gated in scratch on the chain with the levers (8e2ee750): 28 of 30,** the chain's own two failures and nothing new (Animation's two asserts, which its parked patch answers, and the flash count's one run at 2.50 of 2.5 on seed 7). The golden regenerated, parity, npm's stages, the loader on 200 matches, the nine input tests, determinism plain and with intros, the seam sweep, World's five, the HUD check, the validator and its self-test pass. QA's default arm on 100 matches: 89 pass, 21 fail, no hard test among them. Three rows change side with the levers: the launches that end in a building come into their band (3.9 to 9.3%), and the two that share a cause go out the other way (the share of launches that are brunts at 9.9% with its interval over 10, and the pick share at 97%).

**Files:** `sim/director/launch.gd` and `data/director/launch.json`, with one optional schema key (`town`) for Tools (`schema/schema9.cjs`). Neither file is touched by the nine cells' chain. By the EP's word it goes in after the chain as its own window, with its own golden.
