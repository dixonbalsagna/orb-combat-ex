# Two offers for the planner (World, 2026-10-15): parked patches, not applied

Encounter's ask (docs/world/destruction-hook.md section 9): more building plans for the planner to vote on. Built in scratch on main d5a2bd6f (`sim/world/brunt.gd` only; World's file; no data change, no schema). **Not applied**: the game stays frozen for the demo's flash run. Applying either is a golden regeneration (the planner's candidate set changes real matches) and the gates as for any World window.

| Patch | What | Apply |
| :--- | :--- | :--- |
| `offer-1-near-edge.diff` | `BR_MIN` 90 x WS (720 units) to 20 x WS (160): a building whose near edge is closer than 720 units is a candidate (the near edge of the building the brawl stands beside) | `git apply offer-1-near-edge.diff` |
| `offer-2-nearest-per-side.diff` | On top of offer 1: the nearest building on each side is always a candidate, beside the best two by the cheap score (which is tall and populated and never picks a house beside a tower) | after offer 1 |

Verified: both apply in that order on main d5a2bd6f (git apply on a clean export). Scratch gates on the result, all 0 failed: `probe` (plan equals outcome, no chain over the cap), `probe_collide`, `isect_check`, `brunt_check`, `depthreads_check`, `stagecheck`, `blockcheck`, `directcheck`, `minecheck`.

## The numbers (crossing start, 20 matches, seeds 1 to 20; the plans probe 8 seeds, every 3 s, both launchers, force 2000, tier 2)

| | Main | Offer 1 | Offers 1 and 2 |
| :--- | ---: | ---: | ---: |
| Candidates a sample | 2.32 | 2.33 | 2.94 |
| Plans a sample (ahead of the launcher / behind him) | 2.28 (1.14 / 1.14) | 2.29 (1.15 / 1.15) | 2.89 (1.45 / 1.44) |
| Plans whose near edge is within 720 units | 0 | 0.19 | 0.60 |
| Houses / towers among the plans | 0.58 / 1.70 | 0.58 / 1.71 | 0.71 / 2.18 |
| A cost of a call (candidates and aim) | 615 us | 607 us | 627 us |
| BUILDING SMASH chosen a match | 1.35 | 1.50 | 1.25 |
| Body hits a match | 1.8 | 2.35 | 1.8 |
| Chains of two buildings or more a match | 0.35 | 0.50 | 0.30 |
| Structures lost a match / people lost | 47.2 / 26% | 39.9 / 25% | 47.0 / 23% |
| Length | 463 s | 446 s | 428 s |
| Fight time within 1,500 units of a building, first 30 s / 30-60 s | 75% / 38% | 75% / 39% | 75% / 39% |

(The three columns are different matches after the first launch: the planner's choice moves the fight, so the sampled moments differ; read the supply rows, not the differences in the match rows, which are within the noise of 20 matches.) **What it says:** the offers raise the supply (+0.19 and +0.6 plans a sample within 720 units, +25% in all) and cost nothing, and the bodies into buildings do not move beyond noise, because the vote (`BRUNT_BASE`) and the number of launches decide; see section 9 of `destruction-hook.md` for the vote.

## What a third and a fourth body need from the world (Orb: refine toward multi-fighting)

Most of the world's code is already by slot and not by pair (events carry `actor`, `owner`, `victim` slots; `Fighter.splashed`, `flightHits` and the wall's stagger are per body; `hazard_telegraph` and the failing warning loop over every fighter). What is two-only or global:

| Where | Today | With 3 or 4 bodies | Fix |
| :--- | :--- | :--- | :--- |
| **The default launcher** | `SimRoster.opp(S, f)` is "the other one of two" (used when a flight has no `launchBy`: `brunt.hit`, `contact`, `slide`) | with four it names `fighters[0]` or `[1]`, whoever that is | by team: the nearest rival, or `launchBy` always set (the director sets it today; make it required) |
| **The set-piece token** | one global (`S.world.evtToken`, `evtKind`, `evtLeft`): a chain borrows its allowance by it | two chains at once (two bodies launched into buildings in the same second) overwrite each other's token: the first stops borrowing and its deaths count against the window | a small array of tokens (one a flight, `Fighter.chainEvt` already holds its own), or a rule that the second chain waits |
| **The lodge's hold** | `lodgeHold "world"`: a hit-stop of the whole sim | one lodge freezes the other three bodies for 0.5 to 0.9 s, and two lodges in a second freeze it for two | `lodgeHold "body"` (built; it stuns only the lodged body): it becomes the default with more than two, or the hold is a hit-stop of the pair involved (a bubble), which needs per-body time, not the sim's |
| **The wall slam** | per body (his `stunTicks`; double damage; the attacker's first move 45 ticks is Encounter's) | fine: a third body who lands the slam has the first move against the one who hit the wall; a body that meets a wall another body already marked reads the remembered walls (the building's, not the body's) | nothing for World; Encounter: whose first move |
| **The falling stack** (stage C) | `failHurt` is two numbers (slot 0 and 1); `failBy` the causer's slot; `failHurts "rival"` = not the one who brought it down | slot 2 or 3 under a landing floor indexes past the array; "rival" means not the causer's *team* | `failHurt` sized by the fighter count at the start; `failHurts` "enemy" by team; the cap of 100 stays per fighter per building. The warning already reads every fighter's hold and sends a `hazard_telegraph` to each |
| **More bodies near a building** | one body at a time is the flight (the chain, the lodge) | a body lodged in a tower is a body in the failing tower's footprint: the stack lands on him as on any other (buried 45 ticks); two bodies in one tower both give it their remaining energy (the core wears twice: it fails sooner) | nothing new; a probe for it |
| **Collateral and the budget** | the window and the ceiling are by the highest tier of the fighters; each casualty feeds the causer's menace or anguish | unchanged: more bodies, more launches, so the window binds sooner | Game Design: the budget by number of bodies (a 4-body fight at the 2-body window is twice the launches) |
| **The crossing start and the lanes** | the pair stands astride a crossing; `home`, `depthRoom`, `nearestFace` and `crossingAlong` are pure and per body | fine for any number | the start places N bodies along the street (`demoStartX(S, gap)` returns one x; N bodies need N spacings) |
| **Depth** | one brawl's centre drifts; the street is 5 fighter heights | four bodies in a 5 bh street (1 bh clear of the faces) is three bh of room: they overlap in depth | Game Design's: the street width, or the bodies spread over two streets (the three-street table has them) |

**The single biggest item is the set-piece token** (a correctness hole as soon as two flights overlap), then the default launcher (one line when `launchBy` is guaranteed), then the lodge's hold as a per-body bubble. All of them are World's to build on the EP's go; none is needed for the two-body demo.
