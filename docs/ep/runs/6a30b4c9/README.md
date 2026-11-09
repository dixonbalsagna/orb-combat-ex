# Gate records for 6a30b4c9 (Monday polish batch, 2026-11-09; CD-22)

- `gate-full-s415.txt`: full gate on dash-slip, charge-lost, charge-lost-row and UI's Rail files (switch off). Clean except the two `ci_flash_worst` mirror lines, which fail only because the local mirror passes CI's literal `${RUNNER_TEMP}` path ("wrote 0 run files"), as in earlier gates.
- `gate-full-s416-with-globe.txt`: everything plus hitstop-any and terrain step 2 (globe-step2). Camera's `chase_rush_check` failed 4 of 130 rows (a 0.14-0.15 jolt at the tick 96 split; `chase-rush-fail-with-globe.log`).
- `bisect.sh.txt`: on the s415 tree, hitstop-any alone passes chase_rush_check, and globe-step2 alone fails it. Step 2 was held out and returned to World.
- `gate-focused-s419.txt`: the landed set (`apply-order.sh.txt`, the s417 setup minus globe-step2): Rendering's gates, golden compared, split_sweep, sweep, hud_check, two_states, xproc, input tests, all 84 CI Godot scripts and every CI node step. Clean except the same two mirror lines.
- s417 (with slip-arrive and globe) failed the same chase_rush rows. Its other results matched s419's.
- The commit was made from the s419 tree with commit-tree on a side branch, so Tools could build from the sha while the focused gate ran. main was fast-forwarded to it after the gate came back clean.
