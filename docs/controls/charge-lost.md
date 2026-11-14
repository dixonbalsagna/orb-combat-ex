# A lost charge is felt (switches.chargeLostCue)

Owner: Controls. Park: `docs/controls/pending/charge-lost/`. Records: `docs/controls/runs/592a807b/` (CD-22). From the EP's polish brief of 2026-11-09, piece 2, after QA's charge read (`docs/qa/runs/c974e451/README.md` section 3): Orb felt charges were "interrupted arbitrarily".

## What QA found (Orb's 1726 file, 34 charges)

- Nothing was ended by the game at its maximum hold. 3 of 17 heavy charges were **taken from the player**: one stopped by the foe's blow, two lost to a stagger or the brawl's end.
- 5 right-stick holds were let go of at 6 to 10 ticks, before stage 1 (12 ticks): they threw a quick beam.
- The "late" and "soon" refusals are not tied to a charge.

The screen already marks a lost heavy (UI's grey cross or ring on B, from the `windup` cue's end). The pad said nothing of it: the blow's own thud (`hit_taken`) is the same for a blow that took a charge and one that did not, and a stagger or the brawl's end came with no buzz at all.

## What it does

Three new pad pulses, **the charger's pad only, nothing on screen, nothing that flashes**, all on the low motor (Orb: chunky, never tinny), each over inside 160 ms:

| What happened | Cue read | Pulse | Shape | Word for UI |
|---|---|---|---|---|
| The foe's blow took the charge (a heavy's, a stick strike's, a beam hold's) | `windup` end, source `b`, k 2; `stick_refused` source `hit` or `taken` | `charge_broken` | the thud cut short, then two dying echoes (45, 30, 30 ms) | "Charge broken" |
| Lost with nobody's blow on it: a stagger, or the brawl's end | `windup` end, source `b`, k 3 | `charge_lapsed` | no punch: a slow sag in two steps (60, 60 ms) | "Charge lost" |
| A right-stick hold let go of before stage 1, held at least `strike.shortHoldTicks` (6) | the hub's own intent (`rsRelease` at level 0) | `hold_short` | one faint low tap (25 ms) | "Hold longer" |

"Who took it" is the pair: the foe's blow (`charge_broken`) or nobody's (`charge_lapsed`). A thrown charge (k 1) and a miss (k 4) are the player's own and say nothing; so does a Y (it has no charge), the guard or dodge cancelling a charge (the player's own, `cancel`), and the wait for a free target (`soon`).

`charge_broken` and `charge_lapsed` have `overrides`: they play even inside the 80 ms slot-wide gap, because they arrive on the same tick as the blow's thud and must replace it, not lose to it (either order: if the thud comes first the lost-charge pulse starts at 0 ms and replaces it; if the pulse comes first the thud is dropped by the gap). Their own gap (300 ms) still holds, so two never buzz in a row. `hold_short` does not override: the faintest tap never covers another pulse (gap 400 ms).

The rows for UI: `hold_short` is added to `take_refusals()` like the other hub rows; the two cue-side codes ride on the request's `reason`, and the three codes have their words in `SimHaptics.REFUSALS` (UI owns the final strings).

## Where the hold's length is read

A push of N ticks is the settle (2) plus N - 2 ticks held (`rsHeld`). A push of 8 or more ticks (held 6) is told; 3 to 7 is a flick and says nothing; a push of 14 or more reaches stage 1, and the ladder's own pulse is the answer. So QA's "6 to 10 ticks" (start to release) are all told. The number is `strike.shortHoldTicks` in `timing.json`.

## On Orb's 1726 file (from QA's charge trace, not the raw file)

Would have given: 1 `charge_broken`, 2 `charge_lapsed`, 5 `hold_short` in 5 minutes 4 seconds, and nothing for the other 26 charges.

## Switch

`switches.chargeLostCue`, off. Independent of the other haptic switches (the shipped data has `hapticImpact`, `hapticRefused` and `rightStick` on already). Flip it by a Tools row or in the landing commit.

## Not done

- No sound and no screen mark: Audio's and UI's, and UI's grey mark exists for the heavy.
- The pad's feel of these shapes is unproven on hardware here; the tests prove plumbing, distinctness, the 160 ms bound and the duty cycle. Orb's thumbs are the test.
