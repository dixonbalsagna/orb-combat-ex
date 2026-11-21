# X-06 first reading: Orb's scheme at Easy, Medium and Hard on the 9 November build's own data (QA, 2026-11-14)

**What was read.** A scripted pad on Orb's scheme (Tools' `tools/feel/gauntlet.gd --arm=orbs`: a right-stick strike every 30 to 48 ticks, LB held from the foe's wind-up until contact, the left stick walking at the foe; no face button, no beam) plays slot 0 against the computer, whole seeded matches to the KO. **Build:** the kept 9 November build **6a30b4c9** (the Monday polish batch), folder `6627cb9d70b784fa-ug+soundMoments+soundCarry-tb28ef5e9-e921fb3-sa90aad-p1aa485`, tree `homework/Files/builds/orb-first-play-6a30b4c9-6627cb9d/tree` copied to scratch with **nothing patched over its sim or data**; only the scripts were added (`qa/godot/qa_planet.gd`, `tools/feel/gauntlet.gd` from main). **Data hash read: `90c61a45b1011721`, equal to `data` in Orb's own saved play file of that build** (`qa/godot/data_hash.gd`, run on the tree against the file's setup). **Setup:** planet 7, touch 3, generation 3, 4,800 columns, the one energy model on, travel 1.5, flat-out the data's default (5,000), no intro. **Seeds:** 1 to 200 a cell, in three chunks (1 to 67, 68 to 134, 135 to 200), one level at a time, below normal priority; the machine was 56 to 77% loaded by other sessions (a deterministic sim: load changes time, not numbers). **Interval:** Wilson score, 95% (`docs/qa/sample-size.md`). **Bands:** the proposed ones of X-06 (Easy 60 to 80, Medium 35 to 55, Hard 10 to 30).

| Level | Matches | Won | Win rate | 95% interval | Proposed band | Reading | Median match, s | Pad without control | Pad's beams | Foe's beams |
| :--- | ---: | :--- | ---: | :--- | :--- | :--- | ---: | ---: | ---: | ---: |
| Easy | 200 | 108 (lost 92, draws 0, timeouts 0) | **54.0%** | 47.1 to 60.8% | 60 to 80% | outside by the point, the interval reaches the band | 564 | 90.9% | 0 | 2165 |
| Medium | 200 | 0 (lost 200, draws 0, timeouts 0) | **0.0%** | 0.0 to 1.9% | 35 to 55% | outside the band | 285 | 92.4% | 0 | 726 |
| Hard | 200 | 0 (lost 200, draws 0, timeouts 0) | **0.0%** | 0.0 to 1.9% | 10 to 30% | outside the band | 255 | 90.8% | 0 | 637 |
"Pad without control" counts the ticks the pad's fighter was locked, launched, down or stunned; a fighter in a brawl is "locked", so it is not a measure of lost control by itself. The gauntlet's output is long (its bounded-output fix is pending); the nine chunk lines are saved in `x06-gauntlet-lines.txt`.

## What it says

- **Easy: 54.0% (47.1 to 60.8%), below the proposed 60 to 80%.** The point is 6 points under the band; the interval reaches its edge, so by QA's own rule (`sample-size.md`: within 7 points of an edge) it is **extended to 400 matches** with fresh seeds, queued next.
- **Medium: 0 of 200 (0 to 1.9%) and Hard: 0 of 200 (0 to 1.9%).** Both are far outside the proposed bands (35 to 55 and 10 to 30). The scripted pad took about three hits for each one it landed at Medium (61,151 landed, 190,531 taken) and four at Hard (48,553 and 194,983).
- **The pad fires no beam (0 in every cell)** and uses no face button; it plays the strike stick and the guard only. A person who plays Orb's way also uses X, Y and RB beams, so these are the floor of "plays like Orb", not Orb's own rate. Orb's own matches against Easy (the files of 8 and 9 November) were played to a win or a loss by the same person, not read here.
- A first reading, saved; the criterion is the reading, not a pass.

## Risks, in one plain line

**Medium and Hard are at 0% for this scripted pad: no win in 200 at either level, so the proposed bands cannot be told from "the pad cannot win here" until a player that also uses face buttons and beams (`qa/godot/orbs_player.gd`) is read.**

## Easy extended to 400 (seeds 201 to 400, same tree, same method; run 03:27 to 04:06)

QA's own rule (`docs/qa/sample-size.md`) extends a cell within 7 points of a band edge. Easy's first 200 read 54.0%, so 200 fresh seeds were added.

| Easy | Matches | Won | Win rate | 95% interval (Wilson) |
| :--- | ---: | ---: | ---: | :--- |
| Seeds 1 to 200 | 200 | 108 | 54.0% | 47.1 to 60.8% |
| Seeds 201 to 400 | 200 | 136 | 68.0% | 61.2 to 74.1% |
| **All 400** | **400** | **244** | **61.0%** | **56.1 to 65.7%** |

- **Against the proposed 60 to 80%: the point (61.0%) is inside the band, 1 point above its lower edge, and the interval crosses the edge (56.1 is under 60).** It cannot be called in or out at 400; it is "on the edge", as the sample-size page says of a reading within 3 points of an edge.
- **The two halves of the seeds differ by 14 points** (68.0 against 54.0; Newcombe 95% for the difference: 4.8 to 23.6, which excludes 0). The matches are seeded and deterministic, so this is not machine load; it says the win rate moves with the seed set more than independent matches of one rate would, and **the combined interval above is likely too narrow**. Read Easy as "about 54 to 68%, centre 61%".
- Medium and Hard (0 of 200 each) are not extended: a rate of 0 of 200 has an interval top of 1.9% and no extension changes which band they are in.

## Is the 0% the pad script or the game? (run 2026-11-20, same tree, same seeds 1 to 60, Medium)

The gauntlet's other arms were run at Medium on the same 6a30b4c9 tree: the **masher** (X every 8 ticks and nothing else) and the **beam** pad (RB and the right stick held to throw a beam, X every 8 ticks otherwise). Lines saved in `x06-pad-or-game-lines.txt`.

| Pad at Medium (60 matches, seeds 1 to 60) | Won | Rate | 95% interval (Wilson) | Hits landed / taken | Pad's beams |
| :--- | ---: | ---: | :--- | ---: | ---: |
| Orb's scheme (`orbs`: stick strikes and the LB guard, no face button) | 0 of 200 | 0.0% | 0.0 to 1.9% | 61,151 / 190,531 | 0 |
| Masher (X only) | 5 of 60 | 8.3% | 3.6 to 18.1% | 128,404 / 60,970 | 0 |
| Beam pad (RB beam and X) | 4 of 60 | 6.7% | 2.6 to 15.9% | 59,118 / 41,517 | 2,859 |

**Answer: both.**
- **The script is the weakest of the pads.** `orbs` plays the strike stick and the guard only; it throws no beam and presses no X, Y or B. The X-masher, which only mashes X, wins 8.3% against the same Medium and lands about twice the hits it takes; the beam pad throws 2,859 beams. A stick-only pad has lost to Medium in every reading QA has made (0 of 60 on 2026-11-06 on an earlier build, against 26.7% for the masher). So the 0 of 200 is largely what the script leaves out of "plays like Orb".
- **The game is also hard at Medium, whichever pad.** The best pads QA has win 6.7% and 8.3% at Medium on this build, against a proposed band of 35 to 55%. An earlier build gave the masher 49.7% at Medium (300 matches, 2026-11-07, main with the page's switches); the same pad wins 8.3% here, so Medium is harder on 6a30b4c9 for a mashing pad, or the setup differs (this run: planet 7, the energy model on, travel 1.5). No scripted pad is inside the proposed Medium band.
- **What is not known:** what a person who plays like Orb wins at Medium. Orb's own saved plays against Easy were won (the 1646 file: slot 0 won; the earlier 1714 and 1726 files too), but Orb's play at Medium is not in a file. The proposed bands cannot be judged from scripted pads alone; the next reading is a player that mixes strikes, face buttons, the guard and beams (`qa/godot/orbs_player.gd` plays that scheme on both slots, and a single-pad version against the computer is the next change).

## A single-pad player on Orb's scheme against the computer, with the beam (run 2026-11-20, same tree, seeds 1 to 100)

`qa/godot/orbs_player.gd --solo`: one pad, slot 0, against the computer: a right-stick strike every 30 to 48 ticks, LB held from the foe's wind-up to contact, the left stick at the foe, **and a right-stick beam every 420 ticks (hold 50)**, no face button. Lines in `x06-single-pad-lines.txt`.

| Level | Matches | Won | Win rate | 95% interval (Wilson) | Proposed band | Pad's beams (a match) | Computer's beams |
| :--- | ---: | ---: | ---: | :--- | :--- | ---: | ---: |
| Easy | 100 | 100 | **100.0%** | 96.3 to 100.0% | 60 to 80% | 2,695 (27) | 856 |
| Medium | 100 | 6 | **6.0%** | 2.8 to 12.5% | 35 to 55% | 2,404 (24) | 245 |

**What it says.** Adding the beam to the stick-and-guard pad takes Easy from 61.0% (the gauntlet's `orbs`, no beam) to **100.0%: every one of 100 matches** (above the proposed 60 to 80%), and Medium from 0 of 200 to 6 of 100, **still far under the 35 to 55% band.** So the beam is what makes Orb's scheme win at Easy, and Medium is a cliff: 100% at Easy, 6% at Medium for the same pad. The computer lands almost 3 hits for each one the pad lands at Medium (77,911 against 28,899). Hard was not run for this pad; the stick-only pad's 0 of 200 and the masher's under 10% at Medium make any Hard win unlikely.
