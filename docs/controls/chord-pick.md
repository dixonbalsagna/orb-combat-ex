# Two attack buttons on one tick: the biggest goes, the smaller is told (Controls, 2026-11-07; from Encounter's refusal-reasons)

## The problem
`SimControl` takes one attack request a tick, in this order: the light, then the heavy, then the signature (`sim/input/control.gd`). A B pressed on the same tick as an X or a Y was therefore dropped, with no word: **the biggest press lost to the smallest** (14 of Orb's 100 silent presses on the 1229 save; 19 by Encounter's other trace).

## The ruling (Controls)
**A chord is one blow, the biggest: signature over heavy over light.** Each smaller press on that tick is let go of and told, not queued.
- Why the biggest: B (and Y) is the deliberate press; an X landing with it is the fat thumb, and it is the light that costs nothing to lose. The old order lost the one the player meant.
- Why told, not queued: a queued X would fire one tick into the signature's wind-up, as a stray light. The refusal is one knock and one word, **"One at a time"** (`chord`).
- One tick is the rule. X then B on the next tick is two presses, as ever (the strike law's own queue is for the stick).
- The held fields (`sigHeld`, `heavyHeld`, levels) are not touched; only the edges.

## How
`SimLayout._pick_chord`, run after the right hand's filter and before the intent is recorded, so **a replay carries the pick** (the chord is resolved in the layout, never in the sim). The dropped presses join the strike law's list in `take_dropped` with the code `chord`; the hub already turns that list into one `stick_refused` knock (reason `chord`) and one row for UI (`take_refusals`), needing `switches.hapticRefused`. Nothing in the sim or the director changes.

**Switch:** `switches.chordPick` (timing.json, off; independent of the right stick: the keyboard chords too). Off, both edges reach the director as before and nothing is told.

## Proof
`chord_pick_test.gd` (15 checks): B+X, B+Y, Y+X and all three on the pad and on the swapped pad (the pick and the told press), X alone and B alone (nothing told), X then B a tick apart (two presses), the solo keyboard, the hub (one knock with reason `chord`, one UI row), and off (both edges, nothing told).

## For others
- **UI:** the word for the code `chord` ("One at a time"), with the others in `SimHaptics.REFUSALS`.
- **Tools:** a page row `chordPick`.
- **Encounter:** nothing; `press_refused` for a chord is not sent, the layout never lets it through.
