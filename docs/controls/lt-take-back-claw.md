# The flight strike's LT take-back: the claw check, and what Orb's presses say about the window (Controls, 2026-11-06; for Game Design's ruling)

For controller vision section 2: "A face button within about 8 ticks of LT turns it into the flight strike. The slip or dodge-cancel is taken back, with its energy and cooldown refunded. With no face press, LT does exactly what it does today." Controls' part is the claw check (docs/controls/claw-bot-gate.md): can a claw, paddles or a keyboard get anything a fast standard thumb cannot? The test is `sim/input/test/take_back_claw_test.gd` (55 checks, through the real layout); the park is `docs/controls/pending/lt-take-back-claw/`. Nothing in the game changes: this is a check and a recommendation.

## Verdict: no claw gain, as the rule is written
The rule under test, read off the intent the sim sees (after the strike law): the take-back happens when a face edge (X light, Y heavy, B signature) comes 0 to W ticks after the LT edge, W = 8. Three thumb models, as in the claw gate: CLAW (0 ticks), FAST (6), SLOW (13).

| Case | CLAW | FAST | SLOW |
| :--- | :--- | :--- | :--- |
| Stick at rest, LT then a face press at that gap | takes it back | takes it back | **does not** (13 is past 8) |
| A strike stick held out, LT and a face press behind it | **no take-back** (the face press waits behind the stick and, after the queue's 20 ticks, is dropped) | the same | the same: the face press goes on the same tick for all three |
| A flick ended on tick 12, LT on 14 | face press on 18 (the law's floor: stick end + L = 12 + 6), take-back | face on 20, take-back | face on 27, **no take-back** |
| The face press first, LT 1 to 8 ticks later | no take-back (the blow had started on its press tick) | the same | the same |
| LT and a face press on the same tick | take-back (LT is processed first) | needs luck | needs luck |
| The swapped (left-handed) layout | same ticks, same results | | |

Why there is nothing to gain: LT is the left index finger, the left stick the left thumb, a face button the right thumb. A standard grip does all three at once with no transfer, so a claw has nothing to save. The only place a claw saves anything is the right thumb moving between the right stick and a face button, and the **strike law already holds every face press behind a strike stick** (queued, then the lockout L after the stick lets go), for a claw, a keyboard and a paddle alike. So a flick or a charge on the right stick cannot be combined with a flight strike's face press any sooner by a claw than by a fast thumb (the checks above: the claw's face press never goes before stick end + L, and in the busy case no model gets one through at all).

## What Orb's own presses say about the window (a finding the claw check turned up)
Four of Orb's first-play files: 156 LT presses and 1,811 face presses in 82,262 ticks (`docs/controls/clips/read-orb-lt-face.cjs`, counts only). Orb mashes faces constantly (about one every 45 ticks overall, and about one every 20 near an LT press), so a window of 8 ticks after LT is often hit by accident:

| W (ticks after LT) | LT presses with a face press in 0 to W | By chance (the face rate near LT) | So the share that is intended |
| ---: | ---: | ---: | ---: |
| 0 | 15 of 156 (10%) | 5% | about 1 in 2 |
| 2 | 33 (21%) | 14% | about 1 in 3 |
| 3 | 40 (26%) | 19% | about 1 in 4 |
| 4 | 46 (29%) | 23% | about 1 in 5 |
| 6 | 60 (38%) | 30% | about 1 in 5 |
| 8 | 73 (47%) | 37% | **about 1 in 5** |

The excess over chance stays at about 7 to 10 points whatever the window, so **everything past a few ticks only adds accidental conversions**: at W = 8, close to half of Orb's LT presses (47%) would turn into flight strikes in the play we have, and about four in five of those would be mash, not intent. (Orb will change how they press once the move exists; this is the rate in the current mash-heavy play, and the rate to expect from anyone who mashes.) Two more findings from the same data:
- **Orb often presses the face button first and LT about 3 ticks later** (0.16 face presses per LT press at -3 ticks, against a chance level of 0.05). Under an LT-first rule those pairs, if they were meant, are never a flight strike (the blow has started). Whether they mean anything is unknown: today LT + X and LT + Y are moves of their own.
- The same-tick pair (offset 0) is 10 per 100 LT presses, twice chance: the one offset where intent shows clearly.

## Options for Game Design's ruling (none changes the no-gain verdict)
1. **Keep W = 8, require LT still down at the face press** (the vision's own grammar: "hold LT, point the left stick, press a face button"). A tap that was let go earlier is not converted. This needs the sim to see LT as held on that tick: the intent has the LT edge (`dodge`) and `sprint` only after a long hold, so **one new intent bit (`dodgeHeld`)** would carry it (the second word has 6 free bits; the 2v2 note would use 3). The data to size this is not in the old files: the black box's new `rawPad.triggers` records LT's pull and release, so the next play files can say how often a tap is released before the face press.
2. **Narrow the window to 3 or 4 ticks**: no new bit; about a quarter of LT presses convert in Orb's current play and roughly a third to a quarter of those are intended. A deliberate LT-then-X is a pair of two hands that a human lands inside 2 to 3 ticks.
3. **Both**: LT down at the press and W of 4. The conversion then needs an LT that is still held and a face press close behind it.
4. **Not recommended: a symmetric chord (face first or LT first).** A blow starts on its press tick (T1), so a face-first pair cannot be undone, and it would double the accidents (the -3 spike).

Whatever is ruled, **measure the window on the intent the sim sees (the post-law face edge), not on the raw press**, as the test does: a face press that the strike law held behind a stick is then never a take-back, which is what keeps the claw verdict true. The refund (energy and cooldown) is Encounter's; the law of the face press is unchanged.

## What was not done
No flight strike exists yet, so this checks the input half only (the rule over the real layout), as the claw gate does for its rows. The director's reading of the take-back and the refund are Encounter's and Game Design's. The press statistics are from four files of one player.
