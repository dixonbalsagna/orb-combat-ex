# B never fires a beam (switches.bNoBeam)

Owner: Controls (input side); one grant in `sim/director/brawl.gd` (Encounter's). Park: `docs/controls/pending/b-no-beam/`. Records: `docs/controls/runs/c974e451/` (CD-22). From the EP's overnight brief of 2026-11-08, item 1, and QA's replay `docs/qa/runs/1931a0f8/README.md` section 1.

Orb's rule of 2026-11-01: beams come only from the right stick (RB + the stick). B must never start one.

## Game Design's ruling of 2026-11-08 (docs/design/overnight-2026-11-08.md (b)) and where it lands

No press of B fires a beam or a signature, alone or with any shoulder, in any stance or layout. Beams are RB + the right stick; the signature is RT + the right stick. Controls was asked for the layout fix. B's identity in the intent is the `sig` bit (`sigHeld`), the one the director reads as B (`DirBrawl.isB`); a stance's signature and B are the same bit, and the layout cannot tell the director which it meant without a new intent field (the intent is packed for rollback). So the guarantee is at the one place every path reads, `isB`, which Encounter approved, and the layout test below runs the real layout of every preset into the sim to prove it.

**Decided by the EP (2026-11-08): the end state is Orb's rule (beams on RB + stick, the signature on RT + stick, RT + B out), with an interim so the signature is never unreachable.** `switches.bNoBeamKeepRt` (off; needs `bNoBeam`): with both on, B alone, with LB, RB or LT (past the flight strike window), and in an energy mode are never a beam, but **RT + B is still the signature, as a chord only: B within 12 ticks (`tapHold.holdStart`) of RT's press**, before RT's hold becomes the channel (Game Design's condition, `overnight-2026-11-08.md` (b)). A B pressed during an RT channel is the heavy and fires no signature. The director reads it from the fighter: the layout has already cleared the intent's `charge` on the tick B is pressed (a face press voids the channel), but the fighter is still `charging`, so the clause is `stanceMask has RT and state != charging`. This holds until RT + right stick lands. Then: turn `bNoBeamKeepRt` off (RT + B is the big blow), take 4 out of `strike.inertMasks`, drop the `charging` knock; `warding` stays. Tonight's page rows: `bNoBeam` and `bNoBeamKeepRt` together.

The interim in the tests (`runs/c7b0414b/`): `b_no_beam_test` has 103 checks. Rows: B alone, LB, RB, LT past the window and LT + LB + B start no beam; RT then B 1, 3 and 9 ticks later (inside the window) is the signature, tapped and held; B 15, 20 and 40 ticks into an RT channel fires no signature, at 80, 212 and 800 units, tapped and held; the stick's own beam fires. The layouts scan (504 runs a state): interim with B 10 ticks after the stances finds 150 beams from B, all with RT in the combination; with B 30 ticks after (an RT channel), 0. Negative controls: no chord condition, the 18 channel rows fail; no interim, the 12 RT + B rows fail; `isB` as HEAD has it, 37 fail (`b-no-beam-negative-control-a/b/c.txt`).

**Before the interim (the finding that led to it):** the signature on RT + right stick is not built. RT + stick is inert today (strike.inertMasks), and RT + B is the only way a signature fires. With `bNoBeam` on, RT + B is the big blow, so **a player has no way to fire the signature** until RT + right stick is built (Encounter's stick path and a Controls read of the stick under RT; `docs/design/beam-answers.md`). See inert-knock.md: its `charging` knock on RT + stick is the opposite of that rule.

## What leaks (measured on HEAD 397a7adf, the real hub into the sim, a standing rival)

`b_probe2` (`runs/c974e451/b-leak-probe-flightstrikes-*.txt`), signatureRtOnly on, 120 ticks per press:

| B pressed with | flight strikes off | flight strikes on (Sunday build) |
|---|---|---|
| nothing held | heavy blow | heavy blow |
| LB or RB | heavy / blast | heavy / blast |
| **LT held past the 4-tick take-back window** | heavy blow | **beam: 160 damage at 80 units, 143 at 212, 150 at 800** |
| **RT held** | **beam** | **beam** |

1. **LT + B, flight strikes on.** `switches.flightStrikeB` leaves LT + B as a `sig` press for the flight strike to read. The director takes it only inside the take-back window (LT pressed at most 4 ticks ago) or in a chain. Outside both, `DirZip._fsTakes` returns false, the press goes on as a plain signature (`DirBrawl.isB` is false with a stance held), and it starts the beam. That is QA's tick 8096 (B with the dodge held, mask 8).
2. **RT + B.** `signatureRtOnly` deliberately leaves RT + B as the signature (the `(mask & CHARGING) == 0` exemption in `layout.gd`). It is a beam in every build.
3. **B alone (QA's tick 3326, mask 0).** I could not make it fire a beam: B alone was the heavy in every scripted press (a standing rival at 80, 212 and 800 units; 4 medium matches of a pad tapping B every 90 ticks; `runs/c974e451/b-beam-probe-matches.txt`). `DirBrawl.isB` reads it as the heavy when no stance is held and no energy mode is on. The replay's input record does not print the intent's `mode` or the fighter's `act.mode`; if the energy mode was on at 3326 (a latch), `isB` is false and B is the beam, which the rule below also closes. QA can confirm by replaying with this park.

## The fix

`switches.bNoBeam` (off): `DirBrawl.isB` is true for every player's B press (not the computer's; not the stick's own beam, which comes through `requestAttack` with `DirStick.firing` set and is not a press of B). With it, B is the heavy lunge or blow whatever he holds: RT + B, LT + B past the window, B in an energy mode. The flight strike still takes LT + B inside its window first (`DirZip.takes` runs before the heavy fallback), so the strike is unchanged.

Why the director and not the layout: B alone has to stay the big blow (`isB`'s heavy), and the layout converts B to Y's heavy, a weaker blow. The layout also cannot see the take-back window or a chain. `isB` is the one place all the paths read.

Files: `data/input/timing.json` (the switch), the schema, `sim/input/input_data.gd` (`b_no_beam()`, and `pin_switches_off`), `sim/input/test/b_no_beam_test.gd` (new, 42 checks) in `b-no-beam.patch`; `sim/director/brawl.gd` (`isB`, 3 lines) in `director-isb.patch` (needs the grant).

## Tested

- `b_no_beam_layouts_test` (new, for the ruling): 504 runs a switch state across every pad, keyboard and touch preset (arena, arena-swapped, simple-pad, kb-solo, kb-solo-swapped, kb-shared-p1, kb-shared-p2, touch-full), eleven stance combinations (none, LB, RB, RT, LT, LB+RB, LT+LB, RT+LT, RB+LT, RT+RB, RT+LB), B tapped and held, at 80, 212 and 800 units, flight strikes on, the real layout built tick by tick into the sim: with the switch on, 0 beams; off, 198 beams from B (`runs/3aaf0df3/b-no-beam-layouts-scan.txt`). Negative control (director patch removed): the on-scan finds 198 leaks (`b-no-beam-layouts-negative-control.txt`).
- `b_no_beam_test` (42): with the switch on and the flight strikes on, B alone, LB, RB, LT past the window, RT and LT + LB + B, tapped and held, at 80, 212 and 800 units, start no beam; B alone and RT + B are still a blow; the right stick's own beam (RB held, the stick pushed and released) still fires. Off, the control: RT + B and LT + B past the window are the signature beam, B alone is not.
- Negative control: with `brawl.gd` put back, 13 of the on-checks fail (`b-no-beam-negative-control.txt`).
- All 41 input tests pass; lint and validate clean; `flight_strike_check` and `driver_check` pass with the switch off and on; the patches reproduce the tested tree byte for byte.
- Not run: the parity golden (a human's B only; flip the switch with a golden check), the other director checks with the switch on, `hud_check`.

## To turn it on

Flip `switches.bNoBeam` (a Tools page row, or the data in the landing commit; Orb's rule is a rule, so on by default is reasonable). With it on, a player's RT + B is the big blow and the signature beam is the right stick only. UI text that says "RT + B" for the beam must go (not checked).
