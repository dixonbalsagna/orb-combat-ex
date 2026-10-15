# Game Design's sixth and eighth rounds, read one change at a time, parked (2026-10-14)

Owner: Encounter Systems Director. `docs/design/brawl-second-pass.md` section 14, "The sixth round" and "The eighth round", the tune after the nine cells' chain. **Built and read in scratch on main (the chain in; no sim or data change since 3198301f). Not gated as a window, not applied.**

## What is in `s6.cjs`

- **The code** (`sim/director/brawl.gd`), two changes to the run, both inert without their data:
  - a landed heavy counts `flurry.runBy.heavy` on the run, as a medium counts `runBy.medium` (a strength not named counts 1, as before);
  - what a landed blow takes off the rival's run is `flurry.runOffBy` for the strengths it names, and otherwise the same as it adds (the eighth round's split).
- **Two optional schema keys** for Tools, which `s6.cjs` adds: `brawl.flurry.runBy.heavy` and `brawl.flurry.runOffBy`.
- **The data steps,** each a one-line edit: `node s6.cjs <root> data <step>...` with `pursue` (`firstMove.pursue` true), `lworth` (`launcher.worth` 3 to 6), `runbyheavy` (`runBy.heavy` 4), `split` (`runOffBy.heavy` 1: after `runbyheavy`), `runhalves` (`burst.runHalves` 1 to 2: every blow of a held X a full point), `digin` (the medium AI's `digIn` 0.55 to 0.45).

## The sixth round, one change at a time

Each step is on top of the last. The pair is QA's on one clock: the route (X every 8 ticks and B in every opening, the hammer included) and the same script's masher, 100 matches each against the medium AI, seed 1.

| Step | Route | Masher | Its own row |
| :--- | ---: | ---: | :--- |
| Main | 61 | 50 | B mashed 6 of 60; X held 0 of 60; double hits 1.18 a match, in 68 of 100 |
| + the pursuit | 82 | 43 | |
| + the launching blow worth 6 | 76 | 44 | |
| + a landed heavy counts 4 | 78 | 39 | B mashed 2 of 60 |
| + a held X's blows a full point | 80 | 40 | X held 0 of 60 |
| + the medium AI's `digIn` 0.45 | 82 | 44 | Double hits 1.10 a match, in 66 of 100, most 2 |

- **The route is over its masher before any change,** by 11. QA's route now presses B in every opening, so the hammer plays in it. The landing ×1.25 isn't needed, and would be Simulation's line (the landing damage is a constant in `sim/core/fighter.gd`).
- **The pursuit is the big mover,** 61 to 82, and the masher falls 50 to 43: the AI pursues after its own launches too.
- **A held X's full point moves nothing on QA's holder.** His closes stay at 19 a match and his hits rise 4%; he deals 6,600 a match and takes 10,100.
- **`digIn` 0.45 takes double hits from 68 matches of 100 to 66,** one over the band's top. The next value would be 0.4.

## B mashed, read again: the heavy's count was not the cause

My interim said a heavy counting 4 both ways drained the B masher's run (6 of 60 to 2). **That was noise.** 60 matches at 1 to 6 wins can't carry it. Read again on 120 matches each (seeds 1 to 120):

| Build | B mashed | He deals; takes a match | His heavies landed a match |
| :--- | ---: | :--- | ---: |
| Main | 13 of 120 | 5,683; 10,434 | 91.7 |
| The sixth round's end state (a heavy counts 4 both ways) | 6 of 120 | 5,871; 10,166 | 87.8 |
| The same, without the heavy's count | 5 of 120 | 5,889; 10,225 | 88.2 |
| The eighth round's build (below: the count split 4 up, 1 down) | 5 of 120 | | |

- **The heavy's count, both ways, split or absent, makes no difference:** 6, 5 and 5 of 120.
- **What took him from 13 to 5 is another step of the round.** The eighth round's build has no pursuit and still reads 5, so it is the launching blow at 6, the held X's full point or `digIn`. The blow is the likely one, since the B masher is launched about eight times a match. The read at 3 is below.
- **Main itself is under the band:** 13 of 120 is 11%, where B mashed wants 20 to 50%.

## The eighth round as one build

The launching blow at 6, a heavy that adds 4 to his run and takes 1 off the rival's, a held X's full point, `digIn` 0.45, and **no pursuit** (Game Design parked it). Same pair, same seed.

| Build | Route | Masher | Route over its masher | B mashed |
| :--- | ---: | ---: | ---: | ---: |
| The eighth round | 72 | 40 | 32 points | 5 of 120 |
| The same with the launching blow back at 3 | 66 | 39 | 27 points | 10 of 120 |

- **Without the pursuit the route is still over Game Design's new edge:** 32 points over its masher where the edge is 25, and 72% where the edge is 70%.
- **By Game Design's own order the blow goes back to 3 next.** Its row is the second line.
- **The blow at 3 brings the route to 66% and 27 points over:** inside the 70% edge, and 2 points over the 25-point one, which is within noise on 100 matches.
- **The blow at 6 is what halved the B masher:** 5 of 120 with it, 10 with it back at 3 (main reads 13).
- **The masher at 39 or 40 against main's 50 is neither the pursuit nor the blow.** It is one of the three steps left (the split, the full point, `digIn`), and I haven't isolated which. He is still inside 35 to 50%.

## For the window

Recommended as one window: the pursuit off (built, parked by Game Design), **the launching blow at 3** (at 6 the route is over both edges and B mashed halves), the heavy's count split as Game Design ruled (4 up, 1 down: no measurable effect on B mashed, and the rule as written), a held X's full point (the rule; nothing measured moves), `digIn` 0.45. Before it goes in: one read that isolates the masher's fall from 50 to 39, and Game Design's word on the route at 2 points over its edge. The golden moves; one regeneration.
