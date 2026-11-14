# Encounter's answers for Tools' unreviewed check scripts (A-CODE-04; `docs/tools/check-scripts.md`, 2026-11-14)

37 of `sim/director/tools/` are marked UNREVIEWED.
- Every one passes on main def3445a: the stray-beams gate run of 2026-11-13, records in `docs/director/runs/def3445a/stray-beams/`.
- The times below are from that run, on a machine other sessions were loading, and include Godot's start (about 5 s).
- Each ends on a verdict line that `tools/gate.mjs --verdict` reads (`<NAME>: N check(s) failed`, or `passed`).

**My answer: CI for all but two.** `launch_cost_check` and `loader_check` are gate only, because of their length.

| Script | Answer | Time | Note |
| :--- | :--- | ---: | :--- |
| `a_press_check` | CI | 7 s | |
| `arc_check` | CI | 11 s | |
| `arrive_check` | CI | 25 s | the arrival, and with slip-arrive the slip's carry and hold |
| `beam_ai_check` | **CI** | 9 s | the computer's hold-and-release beam. The EP flagged that it isn't run anywhere |
| `beam_front_check` | **CI** | 9 s | the front's answer window. Same |
| `beam_move_check` | **CI** | 6 s | the stick beam's own move. Same. **Its `_gate` and `_late` rows assert today's wait (the lit hand holds), so spike S1's beam (option A) rewrites them either way** |
| `carry_round_check` | CI | 6 s | |
| `city_push_check` | CI | 10 s | |
| `driver_check` | CI | 11 s | |
| `ending_check` | CI | 14 s | |
| `ending_team_check` | CI | 7 s | |
| `flick_keep_check` | CI | 7 s | |
| `flight_strike_check` | CI | 10 s | |
| `follow_check` | CI | 16 s | |
| `full_send_check` | CI | 8 s | |
| `knock_wall_check` | CI | 9 s | |
| `launch_cost_check` | **gate only** | 449 s | lockstep on/off over 320 planned launches. With `--negative-control` add about 5 minutes. Too long for every push |
| `launch_cuts_check` | CI | 15 s | |
| `loader_check` | **gate only** | about 30 to 40 min | not in that run. Run it last in a landing gate, and nightly if Tools has a slot |
| `location_check` | CI | 10 s | |
| `morning_fixes_check` | CI | 6 s | |
| `outside_check` | CI | 8 s | |
| `pace_check` | CI | 6 s | |
| `phrase_check` | CI | 9 s | |
| `press_answers_check` | CI | 6 s | |
| `push_mode_check` | CI | 6 s | |
| `reads_check` | CI | 8 s | |
| `refusal_reasons_check` | CI | 6 s | |
| `relief_check` | CI | 5 s | |
| `stance_check` | CI | 11 s | |
| `stick_check` | CI | 15 s | (its old six failures on main are long fixed) |
| `stick_lunge_check` | CI | 7 s | |
| `strike_stages_check` | CI | 6 s | |
| `sure_reach_check` | CI | 6 s | |
| `swing_check` | CI | 39 s | |
| `swing_legal_check` | CI | 77 s | |
| `walk_check` | CI | 22 s | |

**New with the A1 parks:** `stray_beam_check` (CI, 7 s, in `pending/stray-beams/`). Tools adds it when the park lands.

**The CI cost** of the 35: about 7 minutes in one job on this machine's numbers, so less on a CI runner. If that's too much for every push, `swing_legal_check` (77 s) and `swing_check` (39 s) can go to the gate as well, and the rest stay.
