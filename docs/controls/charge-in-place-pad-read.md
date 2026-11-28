# Pad read: charge in place (brief 1, `docs/design/grab-and-charges.md` section 2b, rules R1 to R7)

Controls, 2026-11-28, for the EP; the asks are Game Design's. Read from the rules, the parked code (`docs/director/pending/grab-charge/`) and **how long Orb's own thumbs held** in five saved plays (7 to 9 November). Counts (aggregates only, nothing of a play file is copied): `docs/controls/runs/0aa68c72/orb-hold-lengths.txt`. Not tried on a pad by hand.

## The rule in the code

At the end of the mid-band lunge's crouch (`bands.lunge.windupTicks`: B 10 ticks, the stick 6) the button or stick is read once: still held, he plants and charges; let go, he lunges. A release before full lunges with no second crouch.

## What the thumbs did

Held lengths in ticks of 1/60 s, no layer held (B n=811, the right stick off RB n=120):

| | 1 to 6 | 7 | 8 to 10 | 11 | 12 to 15 | 16 to 30 | 31 and up |
|---|---:|---:|---:|---:|---:|---:|---:|
| B (median 8) | 154 | 122 | 369 | 26 | 27 | 14 | 99 |
| Right stick (median 10) | 23 | 9 | 29 | 9 | 7 | 16 | 27 |

## B: the 10-tick crouch reads. Keep it.

- 80 in 100 B presses are over by tick 10: a tap lunges, as intended.
- 20 in 100 would plant (still held when the crouch ends). Twelve of those in 100 are long holds (31 ticks and up): the charges that were meant. Between 11 and 30 are 8 in 100: slow taps and short hesitations. They plant, then lunge on release, later than a clean tap by the extra ticks held (1 to 5 for the 11 to 15 group, 6.5 in 100).
- The cost of the slow tap is small, but a **charge flashing up for a few ticks and vanishing** would read as a stutter. Ask: the charge's look (pose, aura) starts about 4 ticks after he plants (tick 14), so a press let go by then never shows it. Animation and VFX, not a rule change.

## The stick: a crouch of 6 does not read. Ask Game Design to change it.

- **81 in 100** of the stick presses were still out when a 6-tick crouch ends (held 7 or more).
- **39 in 100 were quick strikes by the strike stick's own law** (let go before its 12-tick `dwell`: level 0, no charge) **and would still plant.** Each of those: he stops, goes to half speed, then lunges when the thumb comes back, up to 5 ticks later than a quicker flick. Two flicks that feel the same would behave differently, and a charge look would flicker on a third of ordinary flicks.
- It also contradicts what the pad says today: a stick let go between 6 and 11 ticks is the same press that buzzes "Hold longer" (`hold_short`, `docs/controls/charge-lost.md`), which here would come right after he planted and charged.
- **The ask:** for the stick, the plant reads at the strike stick's own line between a flick and a charge, **12 ticks** (`strike.dwell`), not at the 6-tick crouch. In words: at the crouch's end, if the stick is still out but younger than 12 ticks, wait for it; let go and he lunges at once (no second crouch), reach 12 and he plants. A flick of 7 to 11 ticks lunges up to 5 ticks later than a 6-tick one, with no charge look. A flick of 6 or less is unchanged.
- If that is too much code for the trial: keep the plant at 6 but show nothing (no pose, no aura, no cue) until 12, and treat a release before 12 as a plain lunge with no "charge in place" feed. The delay stays; the flicker and the contradiction go.

## The rest of R1 to R7 on the pad

- **R3 (half speed, drop with a dodge tap or guard):** right on the pad. The drop is a left-hand press (LT tap or LB), while the right thumb holds B or the stick, so nothing needs two thumbs on one side.
- **A pad signal for "he planted":** today nothing tells the hand that a held press became a charge in place until the flash at 32. Ask Encounter for a cue at the plant (one tick's event is enough); Controls maps it to a light pulse. It would settle the B case too. Not built (no cue exists).
- **R2, R4, R5, R6 (clock from the press, the release flies in, before full lunges, backed-off becomes the far charge):** nothing the pad needs; the release is the thumb coming up, as for every charge.
- **R7 (heavy winds up on arrival):** no input change. A quick B tap from the mid band now lands later by the travel; that is the design's intent.

## Limits

One person's habits, five plays on builds where holding B meant only the in-brawl charge; presses from every range, not just the mid band; the counts are of the intent's held ticks, not of the thumb. A trial build will say it better than this.
