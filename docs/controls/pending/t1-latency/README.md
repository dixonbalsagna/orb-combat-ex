# T1 latency test (parked, fails on main until Encounter's melee-start fix)

Controls, 2026-10-22, for the EP's brief after Performance's `docs/perf/input-latency-2026-10-22.md`: a light press produces nothing visible for 5 ticks, every trial.

`t1_latency_test.gd` drives **real presses through the real hub into SimCore** (the host's own v2 setup, an idle dummy at 80, 150 and 250 units, each press held and tapped) and asserts the sim reacts **on the press tick**:

- **Solo keyboard:** J light, K heavy, L signature, Space dodge, Shift guard. **Arena pad:** west, north, east, LB.
- **Dodge and guard** are read from the act record (`dodgeTick`, `guardSince` equal to the tick of the press). Light, heavy and signature must show a reaction the sim makes: an exchange, a rush, a state or velocity change, or any event but the tick mark (`press_ack`, `rush`, a windup or lunge cue).
- The queued request alone (`act.queue` growing at the press tick) does not count: it is invisible. That is the whole defect.

**Today on main:** 38 checks, 24 failed. Every light, heavy and signature case (all distances, held and tapped, keyboard and pad) first reacts at **tick 5** (a `rush` and a `lunge_*` cue); dodge and guard pass at tick 0. This reproduces Performance's 5 ticks and shows it is the same for the heavy and the signature.

**To land it:** after Encounter's fix, copy `t1_latency_test.gd` to `sim/input/test/`, run it from a clean export (it should read 38 checks, 0 failed), and add it to the input gates. It is parked here (and `docs/` is not scanned by Godot) so main's input gates stay green meanwhile. If the fix reacts with an event this detector does not know, nothing needs changing: any event but `tick` on the press tick counts.

Run: `godot --headless --path . --script res://sim/input/test/t1_latency_test.gd` (once moved).
