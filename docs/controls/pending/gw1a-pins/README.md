# gw1a-pins (park, on HEAD 94ece92f): four input tests that fail on the GW1a stack

Controls, 2026-11-14, sprint A1, GW1a (the EP's brief: first job, it blocks GW1a). On the GW1a stack (main plus every 9 November switch group) four input tests fail: 16 rows. This park pins each row that tests the old path and says what it holds. **Tests only: four files in `sim/input/test/`, no sim, data, switch or schema change.** Records: `docs/controls/runs/94ece92f/gw1a-pins/` (CD-22; no user paths).

## Apply

`git -c core.autocrlf=false -c core.eol=lf apply docs/controls/pending/gw1a-pins/gw1a-pins.patch` (`b_no_beam_test`, `brake_ready_test`, `dash_handover_test`, `t1_latency_test`). It applies on main (94ece92f) and on the s422 copy, and reproduces the tested files byte for byte.

## Result

All 45 `sim/input/test` scripts pass **on the GW1a copy and on main with the patch** (`after-pins-suite.txt`; before: 16 rows fail, `before-pins-failures-s422.txt`). `b_no_beam_test` also passes all 103 rows on the GW1a copy with Encounter's stray-beams sim part applied, because the window rows then run.

## Row by row, and whether it is a change in Orb's game

**1. `b_no_beam_test`, 8 rows.**
- *The 2 rows at 80 units (RT + B, tap and held, "is still the signature beam"; got press_ack, grapple).* In the 9 November data grapple is on, so a match that opens 80 units apart opens in a clinch and the first press, B, only ends it. **In Orb's build: yes, for a start that close**; not a pad change (the pad sends the same B). Pinned by waiting the clinch out in the test's helper before RT and B (40 quiet ticks), so the rows test the pad's B.
- *The 6 rows at 212 units (B 15, 20 and 40 ticks into an RT channel "fires no signature"; got beam_charge, beam_fire).* **This is a real thing in Orb's 9 November build, and it is the known A-COMBAT-11:** RT + B past the 12-tick window is still the signature (Orb's tick 6617). Encounter's stray-beams park (GW1b rider) closes it. The rows are Encounter's fix's, so they now run only when the window code is in the tree (`DirBrawl.noteRt`); without it one row says so and the rest are not asserted. **Checked:** on the GW1a copy with the stray-beams sim part applied, all 103 rows pass (`after-pins-suite.txt`, last block), so the fix does close them; `stray_beams_input_test` (parked) holds the edge rows too. The rows inside the window (B 1, 3, 9 ticks after RT) pass on both.

**2. `brake_ready_test`, 1 row** ("with the brake off nothing rumbles"). The brake is on in the 9 November data (`data/fight/brake.json`). **In Orb's build: yes, by design.** The off row now asks for the off path in its setup (`{"brake": false}`), naming it.

**3. `dash_handover_test`, 1 row** ("a tap let go at tick 4 carries him less than 2 body heights beyond the stick alone", got 8.23). The sim rows were written for the model without the flat-out dash; the 9 November configuration (dash, kick, slip, arrival) is on in the data. **In Orb's build: yes, this is the slip's known state:** a 4-tick tap carries 8.2 body heights beyond the stick alone, not the ruled 1.5 (Simulation's and Game Design's lever; `docs/controls/dash-handover.md`, `runs/cc958c18/`). Pinned: the old rows run with the dash, kick, slip and arrival off (`_carry(..., false)`), and three new rows hold Orb's configuration: with the handover on a 4-tick tap carries under 60 percent of the handover-off lunge, under 10 body heights beyond the stick alone, and a held LT is the same either way.

**4. `t1_latency_test`, 6 rows** (light west, heavy north, signature east on the pad at 150 units: "acknowledged by press_ack on the press tick: never in 12 ticks"). **Not a change in the pad's own behaviour; a leak in the test's join, with one open question about the real start.** The pad is joined by an A press, and the harness left it latched, so the first intent of the match was a tap of A, which the 9 November data (`bands.taunt`: a tap of A is a taunt) opens as a taunt that eats the next press. Spending the join press off the sim (two idle hub ticks) gives 62 of 62. **Not traced here:** whether the host's start path (the menu press) leaves an A in the match's first intent, and whether a second player joining mid-match with A gets a taunt on their first intent. If either does, Orb would see a taunt where he expected the press; the host line is Rendering's (`render/core/sim_host.gd`, `take_joins`). Also: the key rows (J, K, L) never failed, only the pad's, which is the join.

## Not run

`parity.gd`, the director checks, `hud_check` (tests only; nothing in the sim or the data changes). The probe's `coverage_probe.gd` uses the same join spend (it found this first).
