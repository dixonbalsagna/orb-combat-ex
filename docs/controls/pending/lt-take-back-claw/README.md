# lt-take-back-claw: the claw check for the flight strike's LT take-back (Controls, 2026-11-06; job 6 of the controller-vision brief)

The result and the numbers are in `docs/controls/lt-take-back-claw.md`: **no claw gain** (LT is the left index finger and the strike law holds every face press behind a strike stick for all grips); and a finding for the window (at W = 8 close to half of Orb's LT presses would convert by accident).

## Files
`take-back-claw-test.patch`: `sim/input/test/take_back_claw_test.gd` (55 checks) and its `.uid`. A test only: no game code, no data. Apply after the earlier parks (cut on that tree; it uses only the landing's layout). `git apply docs/controls/pending/lt-take-back-claw/take-back-claw-test.patch`. The reader of Orb's files is `docs/controls/clips/read-orb-lt-face.cjs` (counts only).

## Checked
`take_back_claw_test` 55 of 55 through the real layout: every gap from 0 to 15 ticks with the stick at rest (the take-back exactly for 0 to 8; CLAW and FAST convert, SLOW does not); a held strike stick (no model converts, the face press goes on the same tick for all three: it is dropped behind the stick); a flick that ends on 12 (the claw's face press never goes before 12 + L = 18, never converts where FAST does not); the face first (no take-back); the same tick (a take-back); X, Y and B all read as face edges; the swapped layout on the same ticks. All 33 input tests pass.
