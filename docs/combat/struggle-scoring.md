# The finisher's struggle: scoring that does not reward mashing

Owner: Combat and Choreography. Date: 2026-10-03. Status: **ruled on 2026-10-03: `perStray` −0.15 and `scoring.floor` 0.08.** Encounter applies both values in `data/combat/finishers.json` inside slice 13, under the EP's grant, with the code change that floors the press score before the tilts, and measures it. The numbers are Game Design's (`docs/design/spec-wounds.md` section 1). Written against HEAD `a50c87d`.

## The problem

Encounter traced QA's masher rows: a masher who floods presses through the struggle survives a finisher 21 to 27% of the time, and a player who does not press survives 5 to 7%. Orb's direction is that timing gives the edge and mashing is the weaker style.

**Why it happens.** The struggle has three beats, at ticks 18, 36 and 54 after it opens, and a press within 4 ticks of a beat is a hit (`data/combat/finishers.json`, `contest.struggle`). Each hit window is 9 ticks wide, so a press every 8 ticks lands in all three whatever its phase. The masher gets 3 hits and about 5 strays, and a stray costs half of what a hit pays: 23 + 30 − 26 = 27%.

## The proposal: a stray press voids a hit

| Number | Today | Proposed |
| :--- | ---: | ---: |
| `scoring.base` | 0.23 | 0.23 |
| `scoring.perHit` | +0.10 | +0.10 |
| `scoring.perMiss` | −0.05 | −0.05 |
| `scoring.perStray` | −0.05 | **−0.15** |
| `scoring.floor` | 0.0, and not read | **0.08**, read as the least the presses can make the score, before the tilts |

- **Why −0.15.** A hit turns a missed beat (−0.05) into a hit (+0.10), so it is worth 0.15. A stray now costs exactly that: each stray press cancels one hit. The score is 8% plus 15 points for each hit left after the strays are taken off.
- **Why the floor.** 0.08 is the score of a player who does not press (the base less three missed beats). With it, flooding the struggle can never do worse than not pressing, so a beginner who panics is not punished below doing nothing.
- **No cap is needed.** The floor is the only limit.
- **What the player learns:** three presses, on the beats, and nothing else.

## What each player gets

Survival before the tilts (each Rally used, each minute past 8:00, and the winner's flow all still come off afterwards, as today; they took 1 to 3 points off in Encounter's trace).

| Player | Hits and strays | Today | Proposed |
| :--- | :--- | ---: | ---: |
| No presses | 0 and 0 | 8% | 8% |
| A blind masher, a press every 8 ticks | 3 and about 5 | 27% (23 to 28 by phase) | **8%** |
| On every beat | 3 and 0 | 53% | 53% |
| On half the beats | 1 or 2, and 0 | 23% or 38% (31% on average) | the same |
| On every beat, with one stray | 3 and 1 | 48% | 38% |
| A faster masher, every 6 ticks | 3 and 8 | 13% | 8% |
| A slower one, every 10 ticks | 2.7 and about 4 | 29% | 8% |
| A blind press every 12 ticks | 2.2 and about 3 | 26% | 12% |
| The AI (hits each beat 60% of the time, never strays) | 1.8 and 0 | 35.0% | 35.0% |

So pressing on the beats beats mashing by 15 to 45 points, and mashing is no better than not pressing: one well-timed press (23%) is worth more than any flood.

**One case to know.** A blind press every 18 ticks, the struggle's own tempo, averages 26%: it scores 53% when its phase happens to be right and 8% when it is not. That is half of timing, not mashing: the count-in before the struggle gives the phase to a player who listens.

**A softer setting, if a slip should cost less:** `perStray` −0.10 with the same floor. The 8-tick masher still lands on 8%, slower metronomes reach 9 to 10%, and every beat with one stray is 43% in place of 38%.

## What it does overall

- **Finisher survival in QA's arms does not move.** The AI presses on the beat or not at all, so it never strays: its score is the same under both sets of numbers (35.0% before the tilts). QA's 27.3% stays where it is in the 25 to 40% band.
- **The second-breath reading (26.7% against a ceiling of 25%) is not moved by this.** It is a share of battered wear recovered, measured on the same AI arms. If it is to come down through finisher survival, the lever is the AI's `aiHitChance` (0.60 to 0.55 takes the AI from 35.0% to 32.8%), which is Encounter's, or the base, which is Game Design's.
- **Only scripted mashers change:** their survival falls from 21 to 27% to the no-press level, 5 to 7%. Their matches will end a little sooner, so QA's masher rows need a re-read: the masher against the medium AI is at 40% in a 35 to 50% band.
- **Goldens:** not expected to move, since the golden matches are AI against AI. Saved replays stop playing back, because the data hash changes.

## Keys for Tools, and what each director would do

- **Tools:** no new key. `scoring.floor` is already required by the schema; it only gains a meaning.
- **Encounter:** one change in the contest's branch: the press score is floored at `scoring.floor` before the tilts are taken off. Today the code reads `contest.floor` after the tilts and never reads `scoring.floor`.
- **Combat:** two numbers in `data/combat/finishers.json` (`perStray`, `floor`) and the note beside them, in a window. The parity profile ignores the struggle, so the frozen copy is not touched.
- **Game Design:** the ruling, and the choice between −0.15 and −0.10.
- **UI:** the struggle's prompt should show three beats and no meter that fills with presses, so it does not invite mashing.

## Stale mentions of the old base

The struggle's base has been 0.23 since Game Design raised it; three places still say 15.

| Where | Whose | State |
| :--- | :--- | :--- |
| `docs/combat/variety-pass.md` section 6, row 2 | Combat | fixed: the row now says 0.15 was the parked value and 0.23 is live |
| `sim/director/exchange.gd`, the comment above the contest's branch ("base 15, +10 per hit, -5 per missed beat or stray") | Encounter | to fix with slice 13, which edits that function: 23, +10, -5 a miss, -15 a stray, floored at 8 |
| `docs/director/q4-director-control-plan.md` section C ("base 15") | Encounter | a plan of its time; a note would do |
| `docs/design/spec-wounds.md`, the S4 ruling ("base 15%, up to +30") | Game Design | a dated ruling, superseded further up the same file; a note would do |
