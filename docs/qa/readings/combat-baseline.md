# Combat-overhaul baseline: the "before" numbers for briefs 1, 2 and 5 (QA, 2026-11-28)

**For:** `docs/ep/proposals/combat-overhaul-directive.md`. **Tree:** main 0afd8f05 (the later commits up to this run changed no sim or data). Data hash Easy `3a5dcbce444bd716`, Medium `2e03e02606a81be4`. Headless, below normal, three jobs, data folders isolated.

**How.** A scripted player on the real input hub (slot 0) against the computer, on the game's default world, matches seeded 1 upward. `qa/godot/orbs_player.gd --solo --level=<level> --combat` with `qa/godot/combat_core.gd`; tabulated by `qa/combat-base.js`. Three players:
- **kit** (200 matches a level): strikes, held guard, a stick beam now and then, X taps, B charges. The nearest of the three to a person.
- **charge** (60): holds B again and again, no beams. For the grab and charge rows.
- **beams** (60): a stick beam every 120 ticks. For the beam and struggle rows.

**What a script is not.** None of the three times the struggle's pulses, none runs away, and none spaces itself before charging. Numbers about the player's choices are these scripts', not Orb's.

**Checks on the counting.** Grab tries and beam outcomes equal the director's own feed lines in every batch (last rows). The flying-away count was checked against a second count taken from positions: they agree when a pad flies straight away (399 against 413 ticks, 159 against 158); in fights the position count reads lower (hit-stop keeps velocity), so the table uses positions.

## The table

Full table with every row: `docs/qa/runs/0afd8f05/combat/table.md`. Rates are per minute of match; shares carry Wilson 95% intervals.

| | Easy kit | Medium kit | Easy charge | Medium charge | Easy beams | Medium beams |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Matches | 200 | 200 | 60 | 60 | 60 | 60 |
| Match length, median sim s | 368 | 340 | 320 | 394 | 670 (56 of 60 reach the 660 s time cap) | 442 |
| Scripted player wins | 81.5% | 15.0% | 95.0% | 36.7% | 35.0% | 0.0% |
| **Computer grab tries a minute** | 0.29 | 0.16 | **6.62** | **6.69** | 0 | 0 |
| Grab tries begun while the player winds or charges a heavy | 358 of 358 | 185 of 185 | 2,110 of 2,110 | 2,577 of 2,577 | | |
| Two computer grab tries inside 180 ticks | 0 of 202 | 0 of 64 | 16.3% (shortest 90) | 23.7% (shortest 90) | | |
| **Three heavies in a row, grabbed at least once** | 22.9% | 11.0% | **72.5%** | **65.8%** | | |
| Grab tries begun past 0.6 BH (largest) | 1.1% (0.73) | 3.2% (1.20) | 0.6% (1.19) | 0.9% (1.21) | | |
| Heavies the player winds, a match | 18.6 | 20.5 | 85.0 | 119.9 | | |
| ... interrupted | 14.2% | 15.1% | **47.9%** | **56.2%** | | |
| ... by a grab / a medium blow / lost with the brawl | 305 / 0 / 219 | 157 / 3 / 458 | 2,019 / 212 / 209 | 2,388 / 1,458 / 180 | | |
| ... interrupted before the charge flash | 82.9% | 98.4% | 95.7% | 96.9% | | |
| Player's beams: hit / guard / clash / deflect / dodge | 61.5 / 12.0 / 18.5 / 7.2 / 0.5% | 49.2 / 13.2 / 27.4 / 9.1 / 0.9% | | | 54.9 / 15.4 / 19.1 / 6.5 / 3.0% | 32.7 / 17.4 / 39.5 / 8.2 / 2.1% |
| Computer's beams: hit / clash | 81.9 / 18.1% | 84.2 / 15.8% | 100 / 0% | 100 / 0% | 70.1 / 29.9% | 62.5 / 37.5% |
| Struggles a match | 3.8 | 5.6 | 0 | 0 | 25.4 | 28.6 |
| **Struggles the scripted player wins** | **2 of 761** | **0 of 1,129** | | | **2 of 1,523** | **0 of 1,717** |
| Computer flies away beyond 12.5 BH, share of match time | 1.14% | 0.86% | 1.41% | 1.05% | 0.82% | 0.57% |
| Pair beyond 12.5 BH, share of match time | 8.8% | 10.9% | 7.9% | 9.1% | 41.9% | 39.7% |

## Against the directive's acceptance rows

| Row (brief) | Before | Note |
| :--- | :--- | :--- |
| No grab begins from outside 0.6 BH (1) | 0.6 to 3.2% begin past it, up to 1.21 BH | the game tests reach when the catch lands, not when it starts |
| No two grabs by one fighter inside 180 ticks (1) | 16 to 24% of the computer's tries against the charge player are inside it (shortest 90) | none for the kit player, whose charges are far apart |
| Easy, three heavies in a row: grabbed in under 15 of 100 (1) | 72.5 (charge), 22.9 (kit) | "grabbed" = at least one of the three stopped by a grab |
| A charge at 8 BH completes against a lunge; at 2 BH not (1) | **not measured here** | the EP's follow-up: the timing table |
| Match length on Easy and Medium (1) | 368 and 340 s median (kit) | |
| A script that only holds the stick beats Easy 40 to 60 (2) | today's scripts win 0.0 to 0.3% of struggles | there is no holding in today's struggle; none of these scripts times pulses |
| Beam rows on staying in or leaving the beam (2) | **not measurable today** | a beam's result is decided once, when its front arrives |
| Running away beyond mid range (5) | computer 0.6 to 1.4% of match time | the scripts do not run, so there is no player figure |

## What stands out

- **Orb's grab complaint is in the numbers:** every computer grab try in these runs began while the player was winding or charging a heavy, and almost all interruptions come before the charge even flashes.
- **On Medium, most of the kit player's lost charges are not grabs:** 458 of 619 are "lost with the brawl". A four-match diagnostic (19 such cases): 17 were the brawl ending, and in 15 the computer started a flight strike on that tick (`lost-windups-diagnostic.txt`). So the computer breaking away into a flight strike is an interrupter that brief 1 does not name.
- **Struggles are all but unwinnable without timing:** 4 won of 5,130. Orb: "I still don't think i've won any beam struggles."

## Limits

40 to 200 matches a column; intervals are in the full table. The charge and beams players are deliberately one-sided. The match records themselves are not kept (about 6 MB); `orbs-lines.txt` has each chunk's summary line. Records: `docs/qa/runs/0afd8f05/combat/`.
