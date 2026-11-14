# dodge-held: the intent bit for the LT take-back (Controls, 2026-11-06)

Game Design's ruling: a face press within 4 ticks after LT, LT still held at the face press, never button-first, on the post-law face edge. This adds `SimIntent.dodgeHeld` (the second word's bit 26, behind `switches.dodgeHeld`, off) so the sim can read "LT still held". Contract, files that are not Controls', and what Netcode and Simulation need: `docs/controls/dodge-held.md`.

## Files
`dodge-held.patch` (13 files, +321/-14), cut on top of the whole chain (apply after landing, stall-keep, impact-haptics, refusals, lt-take-back-claw, and **before** `landing/controls-switches-on.patch`, which was re-cut to apply after it with `dodgeHeld` still off):
- Controls': `sim/input/intent.gd` (the field, bit 26, `BITS2` 27, clear2 and applyIntent), `input_data.gd` (`dodge_held_on()`), `layout.gd` (`_dodge_phys_down()`, the finger's state, set in `_right_hand`), `data/input/timing.json` (`switches.dodgeHeld` false), `tools/schemas/input-timing.schema.json`, `sim/input/test/dodge_held_test.gd` (47 checks) with its `.uid`.
- **Netcode's (a grant):** `net/session.gd` (`predictWord` keeps LT held), `net/tools/word_check.gd` (the width at `BITS2`, the prediction), `net/bot.gd` and `net/tools/rollback_check.gd` (the new `--dodge-held` flag), `docs/net/rollback.md`.
- **Simulation's (a comment):** `sim/core/replay.gd` header, 26 bits to 27.

## Checked (headless, below normal priority, clean base plus the chain)
- dodge_held_test 47 of 47: the word (bit 26 alone is 1 << 26, round trip, a bit above the word refused, the strike and brace fields where they were, canon, applyIntent, clear2, an old word reads as LT not held); the layout's reading (on the press tick, every tick while down, off after the release, a tap between two builds is an edge with LT not held, a key, a toggled dodge by the finger, the swapped layout, the stream differs from the switch-off stream by the bit alone); the ruled take-back (every gap 0 to 9 ticks, LT let go before the press, let go after, face first never, same tick, X, Y and B, a held strike stick, the swapped layout) and the claw models; off writes nothing, and with `rightStick` off nothing either.
- `word_check` 623 checks and its negative control (9); `rollback_check --right-stick` and the new `--dodge-held` (3 sessions, 1,800 confirmed-tick hash comparisons) PASS; the old prediction would pass too but takes 240 and 209 rollbacks against 167 and 167; `parity.gd` golden passed; all 34 input tests; lint and validate clean.
- The patch applied to the verified chain gives the tested tree byte for byte.
