# b-no-beam (park, recut on c7b0414b)

A player's B never starts a beam (Orb 2026-11-01; QA's replay of 1931a0f8). Design, the leak table and the measurements: `docs/controls/b-no-beam.md`. Records: `docs/controls/runs/c974e451/` (first cut) and `docs/controls/runs/c7b0414b/` (the recut with the interim and the 12-tick chord) (CD-22).

## Apply (first of the four patches of this batch; order: b-no-beam, director-isb, inert-knock, dash-handover; see `pending/dash-handover/README.md`)

1. `git apply docs/controls/pending/b-no-beam/b-no-beam.patch` (Controls' files: `data/input/timing.json`, the schema, `sim/input/input_data.gd`, the new `sim/input/test/b_no_beam_test.gd` and its `.uid`).
2. `git apply docs/controls/pending/b-no-beam/director-isb.patch` (**grant needed**: `sim/director/brawl.gd`, Encounter's; `DirBrawl.isB` gains one early return, 3 lines).

Both `git apply --check` clean on the working tree at c974e451. With only step 1 the switch exists and does nothing.

## Switch

`switches.bNoBeam`, off in the patch. Flip it on in the landing commit or by a Tools row. It reads nothing else.

## Tested

41 input tests pass (`b-no-beam-input-suite.txt`); `b_no_beam_test` 42 checks; negative control (director patch removed, switch on): 13 checks fail; `flight_strike_check` and `driver_check` pass with the switch off and on; lint and validate clean (321 files, 0 errors); byte for byte.

## The interim (the EP, 2026-11-08): `switches.bNoBeamKeepRt`

With `bNoBeam` and `bNoBeamKeepRt` both on, RT + B is still the signature **only as a chord, B within 12 ticks of RT's press** (so it is never unreachable; a B during an RT channel fires no signature, Game Design's condition) and everything else never fires a beam. One more clause in `DirBrawl.isB` (`director-isb.patch`; Encounter approved the first version: please re-approve the clause) and one more switch in `b-no-beam.patch`. When RT + right stick lands: switch `bNoBeamKeepRt` off, `strike.inertMasks` without 4, drop the `charging` knock.

## Updated 2026-11-08 for Game Design's ruling (b)

`b-no-beam.patch` now also carries `b_no_beam_layouts_test` (504 runs a switch state across every preset, eleven stance combinations, tap and held, three distances; 0 beams on, 198 off; negative control 198 leaks). The guarantee is at `DirBrawl.isB`, not the layout (B and a stance's signature are the same intent bit). **The signature on RT + right stick is not built**, so with the switch on nobody can fire the signature: see `docs/controls/b-no-beam.md`.

## Open

- QA's tick 3326 (B alone, mask 0, a beam) did not reproduce in 4 scripted matches; the leaks that did are RT + B and LT + B past the flight strike's window. If the intent's `mode` or the fighter's `act.mode` was 1 then, the same switch closes it. QA can replay 1931a0f8 with this park.
- Parity golden and the rest of the director checks with the switch on: not run.
