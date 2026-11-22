# Parked, half-done: the GW1b landing review's Camera items (gw1b-landing-c1)

Camera, 2026-11-21. The stand-in's GW1b landing review (`docs/ep/reviews/GW1b-landing.md`), C-1 to C-4. **Stopped at Orb's safe pause:** see "Where it stopped". Nothing here is committed.

**Apply after gw1b-handover-ease** (cut on the 55-line stack, the EP's s426, which carries the three GW1b camera parks): `git -c core.autocrlf=false apply gw1b-landing-c1.patch` (sha1 74379857). Two files, mine.

| File | What |
| :--- | :--- |
| `render/camera/tests/split_sweep.gd` | **C-1:** the default opening and the four intro-resize rows play the planet (the data's default world), no longer pinned. The default opening's smallest size carries an owned ceiling, `OPENING_PLANET_CEIL` 0.046 (below) |
| `render/camera/split_rig.gd` | **C-1's fix:** `_drawn_off`. A fighter off the one view as drawn ends the split trigger's wait (the dwell and the wide hold), and the split opens at its own eased rate |

## C-1: what it was

- **Intro resize (4 rows) is a real fault, fixed.** On the planet the AI flings one fighter about 3,000 units in the first seconds. The one view's drawn zoom lags its aimed zoom at the comfort rate, so he was 94 px off the drawn screen while the aimed picture held him. The split trigger checks the aimed picture, so it kept waiting (the dwell plus the wide hold, 0.65 s). Now a fighter off the drawn screen ends the wait.
  - A first try counted him as "lost", which picks the urgent opening (0.2 s). That broke chase_rush (jolts of 0.158), split_share (the line stepping 0.033) and split_sweep's "scroll governor fast", on main too.
  - So it ends the wait only, and the urgent rate stays for a fighter off the aimed picture.
  - With it, all four intro-resize rows pass on the planet.
- **The default opening: an owned ceiling, not a fix tonight.** Until the AI's first dash apart, at about 2.8 s, the opening frames the pair at 0.087 to 0.118 of the height, over the rule's 0.075. The dash takes the pair 324 → 1,182 units apart in 12 ticks, and the one view widens for it to 0.047 before the split opens.
  - Holding 0.075 through that needs the split to open above Orb's split line (`R_SPLIT` 0.055, "Orb decides"), so it's Orb's number, not the camera's.
  - **Owner: Camera, decide by 2026-11-28:** Orb's split line, or a rule for the first seconds' framing. The ceiling may only rise.

## C-3: the five other pinned split_sweep rows, each a staging reason

| Rows | What they stage, and why the arena |
| :--- | :--- |
| launch split 26718, 45606 | a pair posed at fixed arena x and a staged send with a 9,000-unit split setup: the arena's flat strip |
| arena turn, one view (and split) | the hand-made arena's own ring-turn event (`arena_turn`); the planet has no such turn |
| depth foreground (one view, split; front street, mid row, back row, block row 2) | fighters posed at the arena's street-row depths (750, −600, −1,650, −2,025, −2,850) |
| dolly drift to the middle/back street, dolly launch across a street | the arena's street depths (−1,012, −2,025) and a staged building |
| crossing start (and staredown 72) | the arena's demo start "crossing" on its avenue, which no build opens on |

Planet copies would need the planet's own streets and places. The real matches already run on the planet, and the depth and dolly rows have planet copies owed with the planet's places (GW1c's ring at any angle).

## C-4: chase_rush's taps 35 → 55

The rule under test, the camera's step, jolt, framing and no flap through a four-catch chain, is unchanged. Only the staging's tap spacing follows GW1b's slower flight, so the chain it stages still has its catches (35 gave two of four).

## Where it stopped (Orb's safe pause, 2026-11-21)

- **C-1:** built and run. Every camera check on the 55-line stack with this park passes: chase_rush 130, cross_ko 21, flight_shots 632, launch_shots 1,029, own_pane 12, peak_retry 1, peak_shot 24, split_share 26, split_vision 13, swing_fight 10, swing_places 33, swing_read 14,420, swing_real 48, swing_shot 164.
- **Not finished:**
  - The full split_sweep on the stack with the final `_drawn_off`. It was stopped at the pause; `--only=intro` passes, which includes the default opening with its ceiling.
  - split_sweep on main with the rig changes (`wide_floor` + `drawn_off`).
- **C-2 (the side-by-side against the reference build d3f1ca0e, both flash modes):** not started. The export script is written (scratch `lg_prep.sh`: the reference, the stack before and after Camera's GW1b rig changes, scene ai seed 3), but no export or capture was run.
- **Next:** the full split_sweep on the stack and on main, then C-2's three exports and captures, one at a time through Tools' launcher.
