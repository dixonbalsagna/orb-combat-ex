# Prototype: the clock by body. Not for landing.

Simulation, 2026-11-01, for `docs/design/two-v-two.md`'s ruling on the clock. **It proves the mechanism; the build is still to do.** Behind a setup's `"holdBody"`, and only with more than two fighters. It sits on the gate tree s400. `clock.patch` is the patch, and `sim/core/tools/hold_check.gd`, in it, is the check.

## How it works

Today a hit-stop returns from the tick early, so everything stops. With this:

- **`f.held`:** seconds left of this body's hold. A tick skips a held body's control and step.
- **`f.clock`:** his own clock, a running sum of his live ticks. While the sim steps him it swaps `S.T` to it, so **the 123 reads of `S.T` don't change,** and a held body's timers wait for him. A sum rather than world time less time held, because the subtraction differs in the last digit.
- **The exchange** runs on its fighters' clock, and waits while they're held.
- **The world** (water, shots, collateral) runs on world time.
- **Writers don't change:** whatever wrote `S.dirS.stop` this tick is handed to the exchange's two fighters at the tick's end. That's a shortcut for a prototype with one exchange; the build has each writer name who it holds (`SimClock.hold`).

## What it showed

Planets 7 and 12 and the flat world, 3 seeds each, 3,600 ticks each, the first pair played by the AI and two others flown by script 40,000 units away.

| Check | Result |
| :--- | :--- |
| **The pair's position, health and state, against a plain 1v1 of the same seed, every tick** | **Identical on all 9 fights, 32,400 ticks,** across 6,071 held ticks. The world is under the pair's hold for this one, to compare like with like |
| A bystander moves while the pair's held | On all 6,071 |
| A second body held: he stays put, his clock waits, the pair goes on, then he moves | Pass |
| **The world and shots running on, as ruled** | Blows 2,993 against a 1v1's 3,076, launches 23 against 24, over the same 32,400 ticks |
| Two runs, one hash | Pass |
| **A rollback across holds: every tick of the re-run** | 0 of 800 differ, on the flat world and planet 7, with 161 and 204 held ticks |
| Off: golden | Regenerates byte-identical to the gate tree's |

## What it doesn't do

- **Two exchanges:** there's one here, so "the first pair" stands in for "the fight". Bystanders only fly.
- **A blow that reaches someone held lands the tick he's free** (ruled). Today a shot would hit him during his hold.
- **Signature and transformation pauses** still stop everything. Ruled to hold only that pair; the same mechanism.
- **The view:** `anim_fighter.gd` reads `S.dirS.stop` for its shiver, and the `tick` event says frozen for the whole picture. Each pane should follow its own fight's hold.
- **The freeze budget** (`SimHitstop`) counts per match, and should count per pair.
- **Swing:** a held pair's swing waits, as in the prototype, but with one line and swings resting while apart that only matters when all four are together.

## The size

**About 2 sessions, the low end of the 2 to 3.** The mechanism is here and it's about 90 lines. What's left is the writers (refactor 3 on the list), the shot rule, the pauses, the view's few reads and the budget.

After the build: delete this folder.
