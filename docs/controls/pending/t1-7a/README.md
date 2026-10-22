# T1 tightened (parked, fails on main until Encounter's 7a lands)

Controls, 2026-10-22, for the EP's brief: T1 read 38 of 38 although the opening-cooldown skip never runs (the exchange's drain returns before it). The old detector counted any non-`tick` event as a reaction, so the `press_ack` ("queued") on the press tick passed for a start.

`t1_latency_test.gd` here replaces `sim/input/test/t1_latency_test.gd`. Same scene (real hub, the host's v2 setup, an idle dummy at 80, 150 and 250 units, held and tapped, solo keyboard and Arena pad). Changes:

- **A start is** an exchange (`S.dirS.ex`), the fighter's `rush`, a `rush` event, or the fighter's state, velocity or position changing on the press tick. A `press_ack`, a `lunge_*` or a windup cue is an announcement and does **not** count.
- **A separate ACK row** for each light, heavy and signature case: a `press_ack` for slot 0 appears on the press tick. 24 ACK rows plus 24 START rows plus 14 dodge and guard rows = **62 checks**.

**Today on main:** 62 checks, **24 failed**: every START row first starts at tick 5; all 24 ACK rows and the 14 dodge and guard rows pass. So the acknowledgement is on the press tick and the start is not, which is exactly what the old T1 could not tell apart.

**To land it:** with Encounter's 7a, copy this file over `sim/input/test/t1_latency_test.gd`, run it from a clean export (62 checks, 0 failed), and update the T1 row in `docs/controls/input-gates.md` (38 becomes 62). It is parked under `docs/` so main's input gates stay green meanwhile.
