# The move table: shares written down, X + Y, and held A in reach

Owner: Game Design. 2026-11-14, on Combat's spike S4 (`docs/combat/move-table-s4.md`, cells in `docs/combat/pending/move-table/coverage_cells.json`). Orb: "FULL TABLE ON BETA, KEEP ITERATING WHAT WE HAVE."

**The Alpha bar:** no dead cell; the martial and energy rows complete and distinct for each fighter; the LB, LT and RT rows may share where the design says so, written down. **This page writes the shares down,** so the probe can count them as by design (X-03). LB + A is being asked of Orb separately.

## 1. The 20 proposed shares, ruled

| Cells (tap, mash and hold unless named) | Ruling | Until |
| :--- | :--- | :--- |
| **LB + B** (3), and **LB + B in reach** (1) | **Written: LB + B is the push, as LB + Y.** Guarding and pressing your heaviest button shoves him off, which is a fair thing for it to do | The defensive counter art (25 ki), at Beta (`moveset-generator.md` §3) |
| **LT + X** (3) and **LT + Y** (3) | **Written, with one change:** <br>- **A fresh LT, then X or Y within 4 ticks with LT held,** is the flight strike (`playable-build.md` §1, the take-back), once `flightStrikes` is on, **in reach as well as out of it.** <br>- Otherwise, including in a held sprint past the 4 ticks, **X and Y are their own blows**, as alone (out of reach, the lunge). <br>**The flight strikes replace the step strike and the circle** (that's §1's ruling: one grammar replaces four systems). So S4's A7 (the step strike and circle in reach, 1.5M) should be re-cut as **the flight strikes switched on**, which are built and parked. That's the fold Orb asked for on 11-06: "refined, folded into the game, and recognizable as part of a player's toolset" | `flightStrikes` on. Beta adds the piloted lunge and heavy charge |
| **LT + B** (3), and **LT + B in reach** (1) | **Written:** <br>- a fresh LT, then B within 4 ticks, is **B's flight strike** (a stagger, never a send); <br>- LT held flat out beyond his well, then B, is **the long strike** (the arrival); <br>- otherwise **the plain heavy**, as B alone. <br>Controls keeps LT + B as B while flight strikes are on: today the layout sends it as Y | The tackle, dive grab and snatch, at Beta |
| **LT + A** (3) | **Written: LT + A plays A** | The terrain art (25 ki), at Beta |
| **X + Y together** (1) | **Written: X + Y plays Y,** the heavier, as the B + X chord does (`chordPick`). See §2 | No change planned |
| **A in the air** (1) | **Written: A in the air is the taunt.** Taunting mid-flight is fine (the rule of cool), and it never moves the fighter | The dive grab, at Beta |
| **LB + RB + A** (1) | **Written: it's the guard.** Holding guard with the energy layer and pressing A keeps you guarding, so nothing unsafe happens by accident | The kits' snare, at Beta |

**All 20 now count as by design.** The probe should print `by_design` on repeat lines too, or X-03 can't count them (Combat's note to Controls).

## 2. Should X + Y mean anything? No, for Alpha

**X + Y is Y: the heavier button wins,** as every chord does.
- **Each press is a blow.** Two buttons that land on one tick are one blow, the heavier. A mashing thumb that rolls across X and Y shouldn't throw a surprise move.
- **Orb's scheme puts the attacks on the right stick,** with the face buttons beside it. A face-button chord with its own meaning is a hidden input on a pad, and it would be the only one.
- **The table has plenty to fill at Beta,** in the specials on RT, the kits and LT's piloted moves, without inventing a chord.
- **The ideas log:** a two-button lift, if a fighter's style ever wants one, as that fighter's own art. Not a shared rule.

## 3. Held A in reach: yes, the snatch throw

**Combat's proposal is accepted for Alpha** (S4's A3, about 1M).
- **What it does:** hold A in reach and the catch goes straight into the grapple's throw. **The left stick picks where he goes** (the stick picks a launch's side, and the director never flips it: `overnight-2026-11-08.md` (a)).
- **The throw is the grapple's own,** with its own worth, so there's no new damage number.
- **He gets the grapple's usual tech to break it.**
- A tapped A in reach stays the plain catch.
- **Why:** it gives held A an outcome, so it's not a dead cell. It's aimed, so it's the player's choice where the fight goes. And it reuses a built throw.
- **The stamina model:** a grab that lands refills stamina as a heavy (`energy-stamina-body.md` §2).
- **QA reads** the snatch's share of grabs (no band at first) and that the throw's side follows the stick every time (a band of 100%).

## 4. Left for others

- **LB + A** goes to Orb as one question: Combat's counter stance, with S4's A1 as the recommendation. The cell stays a gap until Orb answers.
- **S4's other gaps are Encounter's builds,** as S4 lists them: Loupe's held Y, the RB stream, the RB Driver, the held mine's aim.
