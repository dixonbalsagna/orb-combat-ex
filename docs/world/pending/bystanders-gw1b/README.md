# Park: bystanders_check re-read for GW1b's zeroed feeds (World, 2026-11-14; EP order)

Simulation's `gw1b-energy` park zeroes every meter feed and rides the energy model. On that stack (HEAD with a1-owed, energy-on, gates-shipped, meters-zero and gw1b-energy applied, in the README's order) `bystanders_check` fails 2 rows. A check, nothing else: `bystanders-gw1b.diff` is `sim/world/tools/bystanders_check.gd`. It applies to HEAD and passes on shipped data too. Runs: `docs/world/runs/bystanders-gw1b/`.

| Row | Why it failed | Re-read |
| :--- | :--- | :--- |
| "the villain fed on the wreck, capped" | It asked for menace and power above 10 after a wreck. With every feed at 0 (`menaceDestroyed`, `menaceEmptied`, `worldPower`) the wreck feeds neither, so both stay at the 10 they began with | Either-state: with a feed on, the meter must rise and stay at most 100 (as before); with it at 0, it stays at 10. The row reads the villain's own feed numbers, so it still means "he is fed by what the data says", and the cap still stands where there is a feed |
| "at least one of the matches brought a building down" | Not the feeds: the check forces the villain to bring down his two nearest buildings within 15,000 units at ticks 150, 450, ... and **under the energy model the fight is 19,046 units from the nearest standing building at tick 151** (flies out over the sea), so nothing was in reach and 0 fell, in both seeds. The row was written for a fight that stays near the city | The reach is a whole lap (`SimConst.W`): the two nearest standing buildings fall wherever the fight has flown to. 16 structures lost in each seed (was 0). The identity it exists for (the same fighters, meters, structures and craters with and without people) is unchanged |

## Gates

| | |
| :--- | :--- |
| On the GW1b stack, before | 2 FAIL (`before-on-the-gw1b-stack.txt`) |
| On the GW1b stack, after | 0 failed (`after-on-the-gw1b-stack.txt`) |
| On shipped data (main's feeds, energy model off), after | 0 failed |
| With only the zeroed feeds (no energy stack), after | 0 failed; the second row had passed there (8 structures lost in seed 7) |

## NEEDS FROM EP

- Land with GW1b (it is either-state, so it can land before).

## RISKS

- The zeroed-feed row now asserts "stays at 10", which would hide a feed that was wrongly left on at an amount 0 in `md` but wired elsewhere; the sim's parity row for the wired amounts (Simulation's) is the check for that.
