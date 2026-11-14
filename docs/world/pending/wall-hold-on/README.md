# Park: the wall that holds him, switched on (World, 2026-11-14; A1 brief item 4, A-WORLD-10)

Orb, three plays (6 and 9 November and before): "the fighter that collided with a building bounced back into the plane we were fighting on like a ping pong ball." The code for it is built and on main (`docs/world/wall-hold.md`, `WALLHOLD`); the five numbers that turn it on are held off, waiting on a QA read. This park is the data flip and the check pins that go with it. Runs: `docs/world/runs/wall-hold-on/`. It stands alone (HEAD def3445a); `git apply --check` is clean.

| File | What |
| :--- | :--- |
| `wall-hold-on.diff` | `data/biomes/brunt.json`: `lodgeHold` "body", `wallRebound` 0, `wallStop` 0, `wallDepthHold` 1, `repeatMarks` 2; and the four checks that pin the old values re-pinned (`wall_hold_check`, `brunt_check`, `repeat_check`, `wall_check`) |

## What it does (measured by `WALLHOLD`, 16 slams: seeds 1 to 8, tiers 1 to 3, a send at a 9 to 15 floor tower on the front street)

| | Shipped | This park |
| :--- | ---: | ---: |
| The whole fight frozen at the hit | 0.50 s | **0.00 s** (only he is held) |
| Pushed off the face while he is stunned | 1,154 units (16 of 16 more than 150) | **18 units (0 of 16)** |
| His depth home | 53 ticks | 41 ticks, after he has stayed at the face for the hold |
| Three sends at one tower (24 towers) | 0 fall | **24 of 24 fall** (the building remembers: each send that struck it counts one tier higher for the next, at most two) |

So **a building breaks at every tier by repeating, not by the first send**: a tier-1 send at a tower is still a wall that holds him (`towerPunches[0]` is 0: the plan's open question, "does a tower hold early on", is Game Design's); the second and third send, tier for tier, take it down. A send that goes through (a tier 3 or 4, or a house) is unchanged.

## Gates

| Gate | Result |
| :--- | :--- |
| `WALLHOLD`, `BRUNT`, `REPEAT`, `WALL` re-pinned | 0 failed each (before the re-pin: 1, 1, 2, 1, every one a pin of the old value, plus `brunt_check`'s "the last hit holds the world for the tier's seconds", which is true only with `lodgeHold` world: with "body" the lodge holds him alone and the fight's freeze is the plain hit-stop, which `WALLHOLD` measures) |
| `INTERIOR`, `LANDMARKSPARE`, `THROUGH`, `COLLATERAL`, `BYSTANDERS`, `BLOCK`, `STAGE` (the others that read brunt.json) | 0 failed |
| All World checks (86, one at a time) | all 0 failed (`checks-verdicts-all-86.txt`) |
| **parity** | **moves, as meant: the golden's matches differ from the first wall hit (tick 8,280 to 15,480); planet worlds identical.** This is a hash window (the path puts A-WORLD-10 in GW2); Simulation regenerates once |

## NEEDS FROM EP

- **QA's read** of the wall slam (the park was held waiting on it): the `wall-hold.md` numbers are mine, on a staged set of 16.
- **A hash window** (GW2) and the golden's re-record by Simulation.
- **Game Design:** whether tier 1 should punch through one tower (`towerPunches[0]` 1), and what repeats count for a house.
- **Encounter** is looking into the launch rebound (the brief): this park is the building half; the outcrop and mountain bounces (A-WORLD-10's "outcrop", Orb's "six or seven times") are `contact.json settle` (on in Orb's build, off on main: it is in `data-switches-gw1a.diff`).
- **Camera:** "press the fight into the city" (Orb) is the street turn: step 7 of the terrain plan, not here.

## RISKS

- `repeatMarks` 2 also turns on the **old crater repeat on gen 1 and 2 worlds** (`WorldCrater._repeat`: a blow within half a radius of a recent impact crater widens it 1.25 times, twice): on the hand-made arena that is a change a player sees before GW1a. On the globe the crater repeat is its own switch (`craters.json globe.repeats`, shipped 0), so it does not move with this. If you want the building memory without the old crater repeat, say so and I split the key.
- Held at the face with his depth held: a body that stays at a tower face "slides down under gravity" while stunned; that is the feel Orb asked for ("press the fight into the city") but nobody has played it with the pad.

## NEXT

After QA's read and the window: re-pin the 41 checks of GW1a with the planet default; then A-WORLD-06 and A-WORLD-07 (the page `docs/world/destruction-a1.md`).
