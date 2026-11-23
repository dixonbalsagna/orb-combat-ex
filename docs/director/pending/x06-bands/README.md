# X-06: landed (8006fe3d, 2026-11-23)

**Landed on main in 8006fe3d,** with Simulation's golden re-record (32bba08a), after a clean s428 gate:
- **Medium matches the player's pace as Easy does.** `paceMatch`, with `noHuman` 8 so that computer-against-computer fights keep Medium's pace. It perfect-blocks a full charge at 0.3.
- **The computer answers a visible hold during the hold, by repetition** (`levels.<level>.brawl.holdAnswer`):
  - Medium: `{300, [0, 0.4, 0.9]}`.
  - Easy: `{420, [0, 0.3, 0.65]}`.
  - Hard: 0.95.
  - A lone hold is never answered.
- **How it answers:** a grab in reach, or closing in to grab before the first flash. The grab is a hold-break: its throw is worth 1.5 times a throw, and noRegrab doesn't start. Otherwise it slips the release: no energy, no cooldown, and R34's third-slip rule (`holdSlip`).
- **The check:** `sim/director/tools/hold_answer_check.gd`, 21 rows.

**QA's three cells** (`docs/qa/readings/`, 2e3407dc):
- **The Medium charge pad: 45%.** It passes the 55% ceiling, so the charge exploit is closed.
- **Marked for human play: the Easy charge pad, 90%** (target 60 to 75%).
- **Marked for human play: the Medium kit, 10%** (floor 25%).
- Game Design rules on those two after Orb's play.

The working record (the candidate, every re-cut, the probes and the director checks) is in this folder's git history and in `docs/director/runs/01367c97/x06-hold-answer/`.
