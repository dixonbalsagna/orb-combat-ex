# The button map: what the trial found

A short note for Orb by Orb's stand-in, 2026-11-20. It sums up Combat's trial page (`docs/combat/move-table-s4.md`) and Controls' reading (`docs/controls/coverage-probe.md`). Nothing here is built or decided.

## In one line

The audit said your build had 18 button presses that do nothing and 65 that repeat another press. When the team pressed every one on your 9 November build, **one press does nothing (LB + A), and about 32 repeat another press, most of them on purpose.**

## What was tried

A scripted pad pressed every combination in a live match on the build you played, for both fighters. The combinations are: each face button, on its own or with LB, LT, RT or RB held, pressed three ways (tapped, held and mashed); the right-stick attacks; and six two-button presses. That first pass covered 101 combinations per fighter. A later, fuller pass added presses made in reach of the rival, in the air, while charging and while dodging, for 116.

## What it found, per fighter

| What a press does | First pass (101) | Fuller pass (116) |
| :--- | ---: | ---: |
| Its own move | 52 or 53 | 62 or 63 |
| The same as another press | 32 | 37 |
| The same move with a small difference | 11 or 12 | 11 or 12 |
| Refused with a word on screen | 2 | 2 |
| Nothing at all | 3 | 3 |

- **The three "nothing" presses are all one button:** hold LB and press A, tapped, held or mashed. Nothing happens and nothing tells you why.
- **The two refused presses** are the right stick pushed while RT is held. The screen says "Charging". That input is kept for the signature moves, which come in a later milestone.
- **Most repeats are intended.** Holding LB, LT or RT and pressing a face button often gives the plain move, and Game Design has now written down which of these are meant (`docs/design/move-table-shares.md`). Seven or eight per fighter are still unexplained.

## Why the audit's numbers were different

The audit counted from the data files: a press counted as dead when no entry in the move table named it. The trial pressed the buttons. A held or mashed X, Y or B has no entry of its own, yet it still throws blows in a close fight, so a player gets something. Both counts are honest; the trial's is what you feel on the pad.

## What still falls short before Alpha

Besides LB + A, Combat lists these as gaps, in plain words:
- one fighter's held Y has no charged version of its own;
- holding A in reach should become a throw you aim with the stick;
- RB with X held fires one bolt, where the design says a stream;
- RB with B mashed should fire again and again at a steady beat;
- RB with A held should aim where you push;
- LT with X or Y in reach (a stepping strike and a circling move) is built but was switched off in your build.

## What it would cost

| | Rough size |
| :--- | :--- |
| Closing those gaps for Alpha | about 8.5M tokens, 11M with a margin |
| The full table, both fighters | about 58M tokens (45M to 70M), which is about a week and a half of the whole team's work on its own |

Your answer on record fits this: "FULL TABLE ON BETA, KEEP ITERATING WHAT WE HAVE." (`docs/ep/vision.md:1799`).

## One question for you

**Hold LB and press A does nothing today. What should it do?**

- **A. A counter** (Combat's pick). You set yourself for half a second. If the rival hits you in that time, you throw them off. If they don't, you have wasted a moment.
- **B. Leave it for now.** It stays a press that does nothing until the full table.
- **C. Something else** you name.

I think you would want A: LB is already your guard, so a counter on it is easy to remember, and a button that does nothing is the one thing the Alpha's bar rules out.
