# The crowd, cars, and the building rules from homework 5 (World, 2026-10-16)

Owner: World and Environment. Paper only; nothing applied. Sources: `docs/ep/vision.md` (Orb's homework 5 and the city answers), `docs/design/buildings.md` section 6 (Game Design's rulings), `docs/world/fight-lanes-world.md`, and scratch measurements on main f9a06368 (`docs/world/scratch-build/planet-slice/crowd_probe.gd`; a 30-match batch each, on a busy PC, so only the aggregates are used).

## 1. "The crowd is a little too clustered": a spread

**Who places it.** The sim holds people as counts per building (`pop`, `popAlive`); Rendering draws one figure per living person on the street side of its building (`CROWD_GAP` 20, `CROWD_DEEP` 90 units out from the face, `look.gd`). So the placement of a *figure* is Rendering's, and the placement of *people* among buildings is mine.

**What the sim gives today (seed 1, 118 buildings, 1,800 people):**

| | People | Buildings | Mean / biggest |
| :--- | ---: | ---: | :--- |
| Front street (row 1, where the fighters are) | 296 (16%) | 50 | 5.9 / 34 |
| Mid row (row 2) | 977 (54%) | 46 | 21 / 102 |
| Back scenery row (row 3) | 527 (29%) | 22 | 24 / 60 |

The 10 fullest buildings hold 35% of everyone and the biggest holds 102 (the median building 6): a tower in the middle rows puts up to 100 figures along one face and its neighbours put 5. That is the clump. The densest 3,000 units of front street hold 74 people; the median stretch 12.

**Two levers, measured:**

| | What | Top-10 share | Biggest / median | Front street people | Casualties (30 matches) |
| :--- | :--- | ---: | :--- | ---: | :--- |
| Today | | 35% | 102 / 6 | 296 | 23% of civilians, 41.5 of 118 structures |
| `pop_height_exp` 0.3 to 0 (data only) | tall buildings no longer weigh more | 30% | 78 / 9 | 285 | not run: too small an effect to be the cure |
| **Cap of 25 a building** (sim, a loop in `settlements.gd`) | no building holds more than 25; the excess goes to the rest by weight | 14% | 25 / 17 | about 500 | 22% of civilians, 39.3 of 118 structures (noise at 30 matches) |

The cap evens the buildings out but **pushes people onto the front street** (296 to 500; the densest 3,000 units 74 to 93, the median stretch 12 to 24): the fighters' street gets busier, the opposite of what Orb asked. A row weight to empty the back row did not help (the cap's excess spreads to every row).

**Proposal (recommended): fix it at the figures, not the people.** Rendering draws at most one figure per 40 units of face (and at most 12 a building), spaced evenly with a seeded jitter along the sidewalk, and the rest of a building's people are inside it (the count the sim keeps: casualties, budgets and menace are untouched). Then no number in the sim moves: **no golden, no casualty change.** What I give Rendering: nothing new (`b.x`, `b.w`, `popAlive`, `row` are there). A second, smaller knob if the street is still busy: `crowd_share` per district in `settlements.json` (the share of a building's people drawn), data only, cosmetic.
**If Orb wants the sim spread instead:** the cap of 25 (and `row_pop` lowered on the front street to hold it near today's 296): one window, every digest moves once (pop is hashed per building), collateral share about the same.

## 2. Cars on the roads: a pitch

Orb: "cars on the roads for realism." ADR 0009 already says "believable city blocks, with cars, bikes and foot traffic" and `fight-lanes-world.md` section 3 has the plan: **moving traffic is cosmetic; parked cars are props.**

| | A. Moving and parked cars as dressing (recommended first) | B. Parked cars as props in the sim |
| :--- | :--- | :--- |
| What | Cars, vans and buses drive the front street's carriageway, turn at avenues, queue at crossings, stop at the kerb; parked ones line the kerb strips. From the planet seed and `S.T`, in Rendering | Parked cars in the kerb strips are state (hashed): throwable, crushable, a blocker the director can target |
| Cost | One instanced draw like the crowd's (`crowd_mesh.gd`): about 150 to 250 vehicles visible near the camera, none off it. No sim cost | A prop list in state (about 60 to 120 a city), a hash block, a collision with bodies and blasts; a golden. Planned as V1/P1, not built |
| Flash risk | Low: small, dark, steady; no bright lamps by day. Rule: a wreck smokes, it does not flash | The explosion of a car is a bright event: needs a no-flash wreck (smoke and a dent), checked with the collapse clip |
| Menace / anguish | None: no people in cars, so nothing is counted. Cars that scatter on `evacuate` and `crater` events read as people fleeing | None unless a car is a casualty source. Keep it so (a car holds no one), or the budget numbers move |
| Needs from World | `lanes.json` carriageway polylines (there), a `traffic` density per district (data, a few numbers) | The prop list, a golden window, the kerb slots by lane |
| Needs from Rendering | The vehicle layer, the scatter response, the seeded routes | Draw the props |
| Needs from Art | Four silhouettes (sedan, van, bus, bike) in the districts' tones, one wreck state each | The same, with damage states |

Recommendation: **A now** (Rendering and Art, no golden, no budget change), and B only when the director wants a car to throw (a launch ending in a parked car); the lanes plan already leaves the kerb strips clear of the fighters' corridor for it.

## 3. The building rules from homework 5: what is World's to build

Game Design's paper (`docs/design/buildings.md` section 6) is the spec. Mapped to my code:

| Rule (Orb's answer) | What exists | World's to build | Size, golden |
| :--- | :--- | :--- | :--- |
| **Towers are earned by power** (5b): a power send goes in at tier 1, through 1 at tier 2, 2 at tier 3, 3 and a crater at tier 4; a plain send is held or goes through fewer | The ladder by tier (`towerPunches`, `chainMax` in `brunt.json`), the lodge | Two ladders (power and plain) in `brunt.json` from Game Design's table; `WorldBrunt` reads a **power flag on the launch** (a `launchPower` the director sets: B in an opening, a full charged heavy, a finisher, a perfect B ender, the duel's send, a struggle overwhelm: Encounter's, not mine) | M; golden regenerates |
| **The wall slam** (5c) | **Done** (stage W, on main) | nothing; it becomes the plain send at tiers 1 and 2 | none |
| **Cover from a beam** (5c) | A beam carves structures along its path (`damageArea`, `beam`); cover for hiding is separate (`cover.gd`) | A query "the first building a beam meets along (x, z) and what is left of it" and the data (hold 0 / 0 / 1 s / 0 by tier, 0.7 of the power through at tier 4). **The beam stop itself is the beam owner's** (Simulation, with Encounter's beams in depth: "beams in depth and not before") | S (query and data) |
| **The falling stack** (5c) | Built and parked: breaches (stage B), the failing state (stage C: warning 1.5 s, 0.6 s over any hold, down over 2 s or more) | Re-cut on Game Design's wording: the core cracks from a tier-3 power send through it, a beam through its middle third, or its fourth mark; **pancakes 0.3 s apart in the order he went through (`failStagger`)**; the crater beyond levels towers within 1,200 units (`levelRadius`, the failing state with its warning) | M; golden regenerates once with C |
| **A falling building hurts only the fighter it was aimed at** (5d) | `failHurts` none / both / rival (rival = not the one who brought it down, and not his team: parked, in the N-body patch) | Replace the modes with **aimed**: a `failFor` slot, the target of the blow that cracked the core; never the attacker, never a guard. In a 1v1 it is "rival", so the default can flip to it | S |
| **Lodged in a building** (5f): `lodge.mode` brief or pinned | `lodgeHold` world / body / auto and a per-body pin (`holdT`, the N-body patch) | Rename to Game Design's `lodge.mode`; the two seconds tables (0.5 / 0.5 / 0.7 / 0.9 and 1.2 / 1.5 / 1.8); pinned also lodges any knock-back into a tower. The barrage window (shots can't miss, x1.5, carve) is **Shots'**; World exposes `holdT > 0` and the carve per shot (there) | S to M |
| **A live picture-in-picture of a dodged beam hitting a tower** | `building_stage`, `floors_fall` and `building_fall` events | Camera's paper (`docs/camera/damage-inset.md`) works out the significance itself from those events; it asks World only for **`floors` on the events** (the building's floor count), and Simulation or Encounter for the beam's id on them | S (one event field); no golden |
| **The budget leaves room for one full tier-4 chain** | Collateral windows by tier, `EVENT_ALLOW` | Verify and tune with the chain probe (data); Game Design owns the number | S, data |

**Order I would build them in** (each a scratch window, a test and the golden stated first): the parked N-body patch, B and C as they are; then `lodge.mode` and "aimed"; then the power ladder once the director's flag exists; then the beam query and the `floors` field. Needs from the EP: who sets `launchPower` (Encounter or Simulation) and who owns the beam stop.
