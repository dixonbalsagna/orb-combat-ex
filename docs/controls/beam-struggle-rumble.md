# The beam struggle's rumble (the beam trial, Encounter's brief 2)

Owner: Controls. Park: `docs/controls/pending/beam-struggle-rumble/`. Switch: the trial's own, `data/director/interrupts.json` `beamPlays.space.enabled` (read as `SimHaptics.beam_trial_on()` through `DirBeamPlay.data()`), **off on main: every pulse maps as before.** No new switch, no data row of mine.

## What the pad does while the trial is on

| What the sim says (Encounter's cues) | Whose pad | Pulse | Shape |
|---|---|---|---|
| `beam_pulse` (the struggle's beat, 30 ticks apart); text `countin` on the first two | both fighters | `struggle_beat` (0.6 of it on a count-in) | one thud: strong 0.5, 45 ms |
| `beam_surge` (a caught surge, text `""` or `sharp`) | the pusher: `struggle_catch`; the other: `struggle_pushed` as today | `struggle_catch`, never under 0.7 of its strength | strong 0.85 for 55 ms, then a short tail: the strongest thing in the struggle |
| `struggle_hold` (the held stick that moved the line; text `both` when both hold) | the holder; both when `both` | `struggle_hold` | a low hum, strong 0.2, from 120 ms to 360 ms after the beat; the one pulse longer than 160 ms, and it ends before the next beat (500 ms) |
| `beam_surge` text `countin` (the count-in teaches; it moves nothing) | the presser only | the old light push at 0.4 if the press was on the pulse (the cue's `k` > 0), nothing if it was off | |
| `beam_end` `overwhelmed` | the loser | `struggle_lose`, unchanged | |

**The slot-wide gap.** The beat, the hum and a surge all arrive within a few ticks of a pulse. `struggle_catch` and `struggle_hold` override the 80 ms slot gap (their own gaps, 200 and 480 ms, still hold), so a surge is never lost to the beat and the hum is not dropped for arriving with it. The hum starts 120 ms in, after the beat's thud has finished.

## What it assumes

- The trial's pulses are 30 ticks (500 ms) apart. If Game Design moves the pulse closer than 360 ms, the hum's end overlaps the next beat (harmless: the beat replaces it) and its 480 ms gap drops every other hum.
- `struggle_hold` is sent once a pulse for whoever's hold moved the line, so "holding" is felt once a beat, not continuously; a continuous hum would need a per-tick cue.
- A pad holding the stick but winning nothing (both hold, the other stronger) gets no cue and no hum: Encounter's cue says who moved the line. When both hold, both hum (text `both`).

## Tested, and not

`sim/input/test/beam_trial_rumble_test.gd` (switch off is the old mapping; every row above; the gap rules). `haptics_test` knows the three kinds and the one that sustains. **Not tried on a pad by hand; the feel is unproven** until Orb plays the trial.
